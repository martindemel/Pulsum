import Foundation
@preconcurrency import CoreData
import HealthKit
@preconcurrency import PulsumData
import PulsumML
import PulsumServices
import PulsumTypes

public struct FeatureVectorSnapshot: Sendable {
    public let date: Date
    public let wellbeingScore: Double
    public let contributions: [String: Double]
    public let imputedFlags: [String: Bool]
    public let featureVectorObjectID: NSManagedObjectID
    public let features: [String: Double]
}

public struct ScoreBreakdown: Sendable {
    public struct MetricDetail: Identifiable, Sendable {
        public enum Kind: String, Sendable {
            case objective
            case subjective
            case sentiment
        }

        public struct Coverage: Sendable {
            public let daysWithSamples: Int
            public let sampleCount: Int
        }

        public let id: String
        public let name: String
        public let kind: Kind
        public let value: Double?
        public let unit: String?
        public let zScore: Double?
        public let contribution: Double
        public let baselineMedian: Double?
        public let baselineEwma: Double?
        public let baselineMad: Double?
        public let rollingWindowDays: Int?
        public let explanation: String
        public let notes: [String]
        public let coverage: Coverage?
    }

    public let date: Date
    public let wellbeingScore: Double
    public let metrics: [MetricDetail]
    public let generalNotes: [String]
}

actor DataAgent {
    private let healthKit: any HealthKitServicing
    private let calendar = Calendar(identifier: .gregorian)
    private let estimatorStore: EstimatorStateStoring
    private var stateEstimator: StateEstimator
    private let context: NSManagedObjectContext
    private var observers: [String: HealthKitObservationToken] = [:]
    private let requiredSampleTypes: [HKSampleType]
    private let sampleTypesByIdentifier: [String: HKSampleType]
    private let notificationCenter: NotificationCenter
    private let backfillStore: BackfillStateStoring
    private var backfillProgress: BackfillProgress
    private var pendingSnapshotUpdate: Task<Void, Never>?
    private var backgroundBackfillTask: Task<Void, Never>?
    private var cachedReadAccess: (timestamp: Date, results: [String: ReadAuthorizationProbeResult])?
    private let readProbeCacheTTL: TimeInterval = 30
    private var diagnosticsTraceId: UUID?

    // Phase 1: small foreground window for fast first score; Phase 2: full context restored in background.
    private let warmStartWindowDays = 7
    private let fullAnalysisWindowDays = 30
    private let bootstrapWindowDays = 2
    private let sleepDebtWindowDays = 7
    private let backgroundBackfillBatchDays = 5
    private let sedentaryThresholdStepsPerHour: Double = 30
    private let sedentaryMinimumDuration: TimeInterval = 30 * 60

    init(healthKit: any HealthKitServicing = PulsumServices.healthKit,
         container: NSPersistentContainer = PulsumData.container,
         notificationCenter: NotificationCenter = .default,
         estimatorStore: EstimatorStateStoring = EstimatorStateStore(),
         backfillStore: BackfillStateStoring = BackfillStateStore()) {
        self.healthKit = healthKit
        self.estimatorStore = estimatorStore
        self.backfillStore = backfillStore
        self.stateEstimator = StateEstimator()
        self.context = container.newBackgroundContext()
        self.context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        self.context.name = "Pulsum.DataAgent"
        self.notificationCenter = notificationCenter
        self.requiredSampleTypes = HealthKitService.orderedReadSampleTypes
        var dictionary: [String: HKSampleType] = [:]
        for type in requiredSampleTypes {
            dictionary[type.identifier] = type
        }
        self.sampleTypesByIdentifier = dictionary

        if let persistedBackfill = backfillStore.loadState() {
            self.backfillProgress = persistedBackfill
        } else {
            self.backfillProgress = BackfillProgress()
        }

        if let persisted = estimatorStore.loadState() {
            self.stateEstimator = StateEstimator(state: persisted)
        }
    }

    // MARK: - Lifecycle

    func setDiagnosticsTraceId(_ traceId: UUID?) async {
        diagnosticsTraceId = traceId
    }

    func start() async throws {
        let span = Diagnostics.span(category: .dataAgent,
                                    name: "data.start",
                                    traceId: diagnosticsTraceId)
        let initialStatus = await currentHealthAccessStatus()
        try await configureObservation(for: initialStatus, resetRevokedAnchors: false)

        // Always re-request to refresh HealthKit's internal state; authorized paths return immediately.
        do {
            try await healthKit.requestAuthorization()
            logDiagnostics(level: .info,
                           category: .healthkit,
                           name: "data.healthkit.authorization",
                           fields: ["state": .safeString(.stage("authorized", allowed: ["authorized", "failed"]))])
            invalidateReadAccessCache()
        } catch {
            logDiagnostics(level: .error,
                           category: .healthkit,
                           name: "data.healthkit.authorization",
                           fields: ["state": .safeString(.stage("failed", allowed: ["authorized", "failed"]))],
                           error: error)
            span.end(error: error)
            throw error
        }

        let refreshedStatus = await currentHealthAccessStatus()
        try await configureObservation(for: refreshedStatus, resetRevokedAnchors: true)
        await bootstrapFirstScore(for: refreshedStatus)
        scheduleBackfill(for: refreshedStatus)
        span.end(error: nil)
    }

    @discardableResult
    func startIngestionIfAuthorized() async throws -> HealthAccessStatus {
        let status = await currentHealthAccessStatus()
        await DebugLogBuffer.shared.append("startIngestionIfAuthorized status: \(statusSummary(status))")
        try await configureObservation(for: status, resetRevokedAnchors: false)
        scheduleBackfill(for: status)
        return status
    }

    @discardableResult
    func restartIngestionAfterPermissionsChange() async throws -> HealthAccessStatus {
        invalidateReadAccessCache()
        let status = await currentHealthAccessStatus()
        await DebugLogBuffer.shared.append("restartIngestionAfterPermissionsChange status: \(statusSummary(status))")
        try await configureObservation(for: status, resetRevokedAnchors: true)
        await bootstrapFirstScore(for: status)
        scheduleBackfill(for: status)
        return status
    }

    @discardableResult
    func requestHealthAccess() async throws -> HealthAccessStatus {
        try await healthKit.requestAuthorization()
        invalidateReadAccessCache()
        let status = await currentHealthAccessStatus()
        await DebugLogBuffer.shared.append("requestHealthAccess refreshed status: \(statusSummary(status))")
        try await configureObservation(for: status, resetRevokedAnchors: true)
        await bootstrapFirstScore(for: status)
        scheduleBackfill(for: status)
        return status
    }

    func currentHealthAccessStatus() async -> HealthAccessStatus {
        if !healthKit.isHealthDataAvailable {
            let unavailable = HealthAccessStatus(required: requiredSampleTypes,
                                                 granted: [],
                                                 denied: [],
                                                 notDetermined: [],
                                                 availability: .unavailable(reason: "Health data is not available on this device."))
            return unavailable
        }

        var granted: Set<HKSampleType> = []
        var denied: Set<HKSampleType> = []
        var pending: Set<HKSampleType> = []
        var probeResults: [String: ReadAuthorizationProbeResult] = [:]

        let requestStatus = await healthKit.requestStatusForAuthorization(readTypes: Set(requiredSampleTypes))

        if requestStatus == .shouldRequest || requestStatus == nil {
            pending = Set(requiredSampleTypes)
        } else {
            probeResults = await readAuthorizationProbeResults()
            for type in requiredSampleTypes {
                switch probeResults[type.identifier] ?? .notDetermined {
                case .authorized:
                    granted.insert(type)
                case .denied:
                    denied.insert(type)
                case .notDetermined, .protectedDataUnavailable, .healthDataUnavailable, .error:
                    pending.insert(type)
                }
            }
        }

        let status = HealthAccessStatus(required: requiredSampleTypes,
                                        granted: granted,
                                        denied: denied,
                                        notDetermined: pending,
                                        availability: .available)
        logHealthStatus(status, requestStatus: requestStatus, probeResults: probeResults)
        return status
    }

    private func shouldIgnoreBackgroundDeliveryError(_ error: Error) -> Bool {
        if let hkError = error as? HKError {
            // Explicitly ignore only the missing entitlement case; other HKError codes should surface.
            if hkError.errorCode == HKError.errorInvalidArgument.rawValue {
                return false
            }
        }
        let nsError = error as NSError
        if nsError.domain == HKError.errorDomain,
           nsError.code == HKError.errorInvalidArgument.rawValue {
            return false
        }
        // Fallback for older SDKs/localized messages; keep localization-safe by avoiding string equality.
        return nsError.localizedDescription.localizedCaseInsensitiveContains("background-delivery")
    }

    private func configureObservation(for status: HealthAccessStatus,
                                      resetRevokedAnchors: Bool) async throws {
        await DebugLogBuffer.shared.append("configureObservation availability=\(status.availability) granted=\(status.granted.map { $0.identifier })")
        guard case .available = status.availability else {
            stopAllObservers(resetAnchors: resetRevokedAnchors)
            return
        }

        try await enableBackgroundDelivery(for: status.granted)
        try await startObserversIfNeeded(for: status.granted)
        stopRevokedObservers(keeping: status.granted, resetAnchors: resetRevokedAnchors)
    }

    private func backfillHistoricalSamplesIfNeeded(for status: HealthAccessStatus) async {
        guard case .available = status.availability else {
            logDiagnostics(level: .info,
                           category: .backfill,
                           name: "data.backfill.phase.skip",
                           fields: [
                               "phase": .safeString(.stage("warmStart7d", allowed: ["warmStart7d", "full30d"])),
                               "reason": .safeString(.stage("health_unavailable", allowed: ["health_unavailable", "no_granted"]))
                           ])
            return
        }
        let grantedTypes = status.granted
        guard !grantedTypes.isEmpty else {
            logDiagnostics(level: .info,
                           category: .backfill,
                           name: "data.backfill.phase.skip",
                           fields: [
                               "phase": .safeString(.stage("warmStart7d", allowed: ["warmStart7d", "full30d"])),
                               "reason": .safeString(.stage("no_granted", allowed: ["health_unavailable", "no_granted"]))
                           ])
            return
        }

        let today = calendar.startOfDay(for: Date())
        let warmStartStart = calendar.date(byAdding: .day, value: -(warmStartWindowDays - 1), to: today) ?? today
        let fullWindowStart = calendar.date(byAdding: .day, value: -(fullAnalysisWindowDays - 1), to: today) ?? today

        let warmStartTypes = grantedTypes.filter { !backfillProgress.warmStartCompletedTypes.contains($0.identifier) }
        if warmStartTypes.isEmpty {
            logDiagnostics(level: .info,
                           category: .backfill,
                           name: "data.backfill.phase.skip",
                           fields: [
                               "phase": .safeString(.stage("warmStart7d", allowed: ["warmStart7d", "full30d"])),
                               "reason": .safeString(.stage("already_complete", allowed: ["health_unavailable", "no_granted", "already_complete"]))
                           ])
        } else {
            let phaseSpan = Diagnostics.span(category: .backfill,
                                             name: "data.backfill.phase",
                                             fields: [
                                                 "phase": .safeString(.stage("warmStart7d", allowed: ["warmStart7d", "full30d"])),
                                                 "start_day": .day(warmStartStart),
                                                 "end_day": .day(today),
                                                 "target_start_day": .day(fullWindowStart)
                                             ],
                                             traceId: diagnosticsTraceId,
                                             level: .info)
            let monitor = DiagnosticsStallMonitor(category: .backfill,
                                                  name: "data.backfill.warmStart",
                                                  traceId: diagnosticsTraceId,
                                                  thresholdSeconds: 25,
                                                  initialFields: [
                                                      "phase": .safeString(.stage("warmStart7d", allowed: ["warmStart7d", "full30d"])),
                                                      "type_count": .int(warmStartTypes.count)
                                                  ])
            await monitor.start()
            let result = await performBackfill(for: warmStartTypes.sorted { $0.identifier < $1.identifier },
                                               startDate: warmStartStart,
                                               endDate: today,
                                               phase: "warm-start",
                                               targetStartDate: fullWindowStart,
                                               markWarmStart: true,
                                               monitor: monitor)
            await monitor.stop(finalFields: [
                "touched_days": .int(result.days.count),
                "raw_sample_count": .int(result.totalSamples)
            ])
            phaseSpan.end(additionalFields: [
                "touched_days": .int(result.days.count),
                "raw_sample_count": .int(result.totalSamples)
            ], error: nil)
            notifySnapshotUpdate(for: today,
                                 reason: .stage("warm_backfill",
                                                allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]))
        }

        scheduleBackgroundFullBackfillIfNeeded(grantedTypes: grantedTypes, targetStartDate: fullWindowStart)
    }

    private func bootstrapFirstScore(for status: HealthAccessStatus) async {
        guard case .available = status.availability else { return }
        guard !status.granted.isEmpty else { return }
        let today = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -(bootstrapWindowDays - 1), to: today) else { return }
        let types = status.granted.sorted { $0.identifier < $1.identifier }
        let bootstrapSpan = Diagnostics.span(category: .dataAgent,
                                             name: "data.bootstrap",
                                             fields: [
                                                 "window_days": .int(bootstrapWindowDays),
                                                 "start_day": .day(start),
                                                 "end_day": .day(today)
                                             ],
                                             traceId: diagnosticsTraceId)
        var touchedDays = Set<Date>()
        var totalSamples = 0

        for type in types {
            let identifier = type.identifier
            let batchSpan = Diagnostics.span(category: .dataAgent,
                                             name: "data.bootstrap.batch",
                                             fields: [
                                                 "type": .safeString(.metadata(identifier)),
                                                 "batch_start_day": .day(start),
                                                 "batch_end_day": .day(today)
                                             ],
                                             traceId: diagnosticsTraceId,
                                             level: .info)
            do {
                switch identifier {
                case HKQuantityTypeIdentifier.stepCount.rawValue:
                    let totals = try await safeFetchDailyStepTotals(startDate: start,
                                                                    endDate: today,
                                                                    context: "Bootstrap \(identifier)")
                    let days = try await applyStepTotals(totals)
                    touchedDays.formUnion(days)
                    totalSamples += totals.count
                    batchSpan.end(additionalFields: [
                        "raw_sample_count": .int(totals.count),
                        "processed_days": .int(days.count)
                    ], error: nil)
                case HKQuantityTypeIdentifier.heartRate.rawValue:
                    let stats = try await safeFetchNocturnalHeartRateStats(startDate: start,
                                                                           endDate: today,
                                                                           context: "Bootstrap \(identifier)")
                    let days = try await applyNocturnalStats(stats)
                    touchedDays.formUnion(days)
                    totalSamples += stats.count
                    batchSpan.end(additionalFields: [
                        "raw_sample_count": .int(stats.count),
                        "processed_days": .int(days.count)
                    ], error: nil)
                default:
                    let samples = try await healthKit.fetchSamples(for: type, startDate: start, endDate: today)
                    let processed = try await processBackfillSamples(samples, type: type)
                    touchedDays.formUnion(processed.days)
                    totalSamples += processed.processedSamples
                    batchSpan.end(additionalFields: [
                        "raw_sample_count": .int(samples.count),
                        "processed_sample_count": .int(processed.processedSamples),
                        "processed_days": .int(processed.days.count)
                    ], error: nil)
                }
            } catch {
                if isProtectedHealthDataInaccessible(error) {
                    batchSpan.end(additionalFields: [
                        "skip_reason": .safeString(.stage("protected_data", allowed: ["protected_data", "fetch_failed"]))
                    ], error: nil)
                    continue
                }
                batchSpan.end(additionalFields: [
                    "skip_reason": .safeString(.stage("fetch_failed", allowed: ["protected_data", "fetch_failed"]))
                ], error: error)
            }
        }
        notifySnapshotUpdate(for: today,
                             reason: .stage("bootstrap",
                                            allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]))

        do {
            if let _ = try await latestFeatureVector() {
                bootstrapSpan.end(additionalFields: [
                    "touched_days": .int(touchedDays.count),
                    "raw_sample_count": .int(totalSamples),
                    "snapshot_day": .day(today)
                ], error: nil)
                return
            }
        } catch {
            bootstrapSpan.end(additionalFields: [
                "touched_days": .int(touchedDays.count),
                "raw_sample_count": .int(totalSamples),
                "snapshot_day": .day(today)
            ], error: error)
        }

        let fallbackEnd = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let fallbackStart = calendar.date(byAdding: .day, value: -(fullAnalysisWindowDays - 1), to: today) ?? today
        let fallbackSucceeded = await bootstrapFromFallbackWindow(status: status,
                                                                  fallbackStartDate: fallbackStart,
                                                                  fallbackEndDate: fallbackEnd)
        if !fallbackSucceeded {
            notifySnapshotUpdate(for: today,
                                 reason: .stage("bootstrap",
                                                allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]))
        }
        bootstrapSpan.end(additionalFields: [
            "touched_days": .int(touchedDays.count),
            "raw_sample_count": .int(totalSamples),
            "snapshot_day": .day(today)
        ], error: nil)
    }

    private func scheduleBackfill(for status: HealthAccessStatus) {
        guard case .available = status.availability else { return }
        backgroundBackfillTask?.cancel()
        backgroundBackfillTask = Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            await self.backfillHistoricalSamplesIfNeeded(for: status)
        }
    }

    private func bootstrapFromFallbackWindow(status: HealthAccessStatus,
                                             fallbackStartDate: Date,
                                             fallbackEndDate: Date) async -> Bool {
        guard case .available = status.availability else { return false }
        guard !status.granted.isEmpty else { return false }

        let span = Diagnostics.span(category: .dataAgent,
                                    name: "data.bootstrap.fallback",
                                    fields: [
                                        "start_day": .day(fallbackStartDate),
                                        "end_day": .day(fallbackEndDate)
                                    ],
                                    traceId: diagnosticsTraceId,
                                    level: .info)
        var touchedDays: Set<Date> = []
        var totalSamples = 0
        let types = status.granted.sorted { $0.identifier < $1.identifier }

        for type in types {
            let identifier = type.identifier
            let batchSpan = Diagnostics.span(category: .dataAgent,
                                             name: "data.bootstrap.fallback.batch",
                                             fields: [
                                                 "type": .safeString(.metadata(identifier)),
                                                 "batch_start_day": .day(fallbackStartDate),
                                                 "batch_end_day": .day(fallbackEndDate)
                                             ],
                                             traceId: diagnosticsTraceId,
                                             level: .info)
            do {
                switch identifier {
                case HKQuantityTypeIdentifier.stepCount.rawValue:
                    let totals = try await safeFetchDailyStepTotals(startDate: fallbackStartDate,
                                                                    endDate: fallbackEndDate,
                                                                    context: "Bootstrap fallback \(identifier)")
                    let days = try await applyStepTotals(totals)
                    touchedDays.formUnion(days)
                    totalSamples += totals.count
                    batchSpan.end(additionalFields: [
                        "raw_sample_count": .int(totals.count),
                        "processed_days": .int(days.count)
                    ], error: nil)
                case HKQuantityTypeIdentifier.heartRate.rawValue:
                    let stats = try await safeFetchNocturnalHeartRateStats(startDate: fallbackStartDate,
                                                                           endDate: fallbackEndDate,
                                                                           context: "Bootstrap fallback \(identifier)")
                    let days = try await applyNocturnalStats(stats)
                    touchedDays.formUnion(days)
                    totalSamples += stats.count
                    batchSpan.end(additionalFields: [
                        "raw_sample_count": .int(stats.count),
                        "processed_days": .int(days.count)
                    ], error: nil)
                default:
                    let samples = try await healthKit.fetchSamples(for: type, startDate: fallbackStartDate, endDate: fallbackEndDate)
                    let processed = try await processBackfillSamples(samples, type: type)
                    touchedDays.formUnion(processed.days)
                    totalSamples += processed.processedSamples
                    batchSpan.end(additionalFields: [
                        "raw_sample_count": .int(samples.count),
                        "processed_sample_count": .int(processed.processedSamples),
                        "processed_days": .int(processed.days.count)
                    ], error: nil)
                }
            } catch {
                if isProtectedHealthDataInaccessible(error) {
                    batchSpan.end(additionalFields: [
                        "skip_reason": .safeString(.stage("protected_data", allowed: ["protected_data", "fetch_failed"]))
                    ], error: nil)
                    continue
                }
                batchSpan.end(additionalFields: [
                    "skip_reason": .safeString(.stage("fetch_failed", allowed: ["protected_data", "fetch_failed"]))
                ], error: error)
                span.end(additionalFields: [
                    "touched_days": .int(touchedDays.count),
                    "raw_sample_count": .int(totalSamples)
                ], error: error)
                return false
            }
        }

        guard let latestDay = touchedDays.max() else {
            span.end(additionalFields: [
                "touched_days": .int(touchedDays.count),
                "raw_sample_count": .int(totalSamples)
            ], error: nil)
            return false
        }
        notifySnapshotUpdate(for: latestDay,
                             reason: .stage("bootstrap",
                                            allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]))
        span.end(additionalFields: [
            "touched_days": .int(touchedDays.count),
            "raw_sample_count": .int(totalSamples),
            "snapshot_day": .day(latestDay)
        ], error: nil)
        return true
    }

    private func processBackfillSamples(_ samples: [HKSample], type: HKSampleType) async throws -> (processedSamples: Int, days: Set<Date>) {
        switch type {
        case let quantityType as HKQuantityType:
            let quantitySamples = samples.compactMap { $0 as? HKQuantitySample }
            guard !quantitySamples.isEmpty else {
                logDiagnostics(level: .info,
                               category: .backfill,
                               name: "data.backfill.skip",
                               fields: [
                                   "type": .safeString(.metadata(quantityType.identifier)),
                                   "reason": .safeString(.stage("no_castable_samples", allowed: ["no_castable_samples"]))
                               ])
                return (0, [])
            }
            // Group by day to avoid huge single calls and to log progress.
            let grouped = Dictionary(grouping: quantitySamples) { calendar.startOfDay(for: $0.startDate) }
            var touched: Set<Date> = []
            var processedCount = 0
            for (_, daySamples) in grouped {
                let days = try await processQuantitySamples(daySamples, type: quantityType)
                touched.formUnion(days)
                processedCount += daySamples.count
            }
            return (processedCount, touched)

        case let categoryType as HKCategoryType:
            let categorySamples = samples.compactMap { $0 as? HKCategorySample }
            guard !categorySamples.isEmpty else {
                logDiagnostics(level: .info,
                               category: .backfill,
                               name: "data.backfill.skip",
                               fields: [
                                   "type": .safeString(.metadata(categoryType.identifier)),
                                   "reason": .safeString(.stage("no_castable_samples", allowed: ["no_castable_samples"]))
                               ])
                return (0, [])
            }
            let grouped = Dictionary(grouping: categorySamples) { calendar.startOfDay(for: $0.startDate) }
            var touched: Set<Date> = []
            var processedCount = 0
            for (_, daySamples) in grouped {
                let days = try await processCategorySamples(daySamples, type: categoryType)
                touched.formUnion(days)
                processedCount += daySamples.count
            }
            return (processedCount, touched)

        default:
            logDiagnostics(level: .info,
                           category: .backfill,
                           name: "data.backfill.skip",
                           fields: [
                               "type": .safeString(.metadata(type.identifier)),
                               "reason": .safeString(.stage("unsupported_type", allowed: ["unsupported_type"]))
                           ])
            return (0, [])
        }
    }

    private func performBackfill(for types: [HKSampleType],
                                 startDate: Date,
                                 endDate: Date,
                                 phase: String,
                                 targetStartDate: Date,
                                 markWarmStart: Bool,
                                 monitor: DiagnosticsStallMonitor? = nil) async -> (days: Set<Date>, totalSamples: Int) {
        guard !types.isEmpty else { return ([], 0) }
        let sorted = types.sorted { $0.identifier < $1.identifier }
        var touchedDays: Set<Date> = []
        var totalSamples = 0
        var processedTypeCount = 0
        for type in sorted {
            let identifier = type.identifier
            let batchSpan = Diagnostics.span(category: .backfill,
                                             name: "data.backfill.batch",
                                             fields: [
                                                 "phase": .safeString(.stage(phase, allowed: ["warm-start", "full"])),
                                                 "type": .safeString(.metadata(identifier)),
                                                 "batch_start_day": .day(startDate),
                                                 "batch_end_day": .day(endDate),
                                                 "target_start_day": .day(targetStartDate),
                                                 "mark_warm_start": .bool(markWarmStart)
                                             ],
                                             traceId: diagnosticsTraceId,
                                             level: .info)
            do {
                switch identifier {
                case HKQuantityTypeIdentifier.stepCount.rawValue:
                    let totals = try await safeFetchDailyStepTotals(startDate: startDate,
                                                                    endDate: endDate,
                                                                    context: "Backfill (\(phase)) \(identifier)")
                    let processedDays = try await applyStepTotals(totals)
                    touchedDays.formUnion(processedDays)
                    totalSamples += totals.count
                    batchSpan.end(additionalFields: [
                        "raw_sample_count": .int(totals.count),
                        "processed_days": .int(processedDays.count)
                    ], error: nil)
                case HKQuantityTypeIdentifier.heartRate.rawValue:
                    let stats = try await safeFetchNocturnalHeartRateStats(startDate: startDate,
                                                                           endDate: endDate,
                                                                           context: "Backfill (\(phase)) \(identifier)")
                    let processedDays = try await applyNocturnalStats(stats)
                    touchedDays.formUnion(processedDays)
                    totalSamples += stats.count
                    batchSpan.end(additionalFields: [
                        "raw_sample_count": .int(stats.count),
                        "processed_days": .int(processedDays.count)
                    ], error: nil)
                default:
                    let samples = try await healthKit.fetchSamples(for: type, startDate: startDate, endDate: endDate)
                    var processed: (processedSamples: Int, days: Set<Date>) = (0, [])
                    if !samples.isEmpty {
                        processed = try await processBackfillSamples(samples, type: type)
                        touchedDays.formUnion(processed.days)
                        totalSamples += processed.processedSamples
                        batchSpan.end(additionalFields: [
                            "raw_sample_count": .int(samples.count),
                            "processed_sample_count": .int(processed.processedSamples),
                            "processed_days": .int(processed.days.count)
                        ], error: nil)
                    } else {
                        batchSpan.end(additionalFields: [
                            "skip_reason": .safeString(.stage("zero_samples", allowed: ["zero_samples", "protected_data", "fetch_failed"]))
                        ], error: nil)
                    }
                }

                if markWarmStart {
                    backfillProgress.recordWarmStart(for: type.identifier, earliestDate: startDate, calendar: calendar)
                } else {
                    backfillProgress.recordProcessedRange(for: type.identifier,
                                                          startDate: startDate,
                                                          targetStartDate: targetStartDate,
                                                         calendar: calendar)
                }
                persistBackfillProgress()
            } catch {
                if isProtectedHealthDataInaccessible(error) {
                    batchSpan.end(additionalFields: [
                        "skip_reason": .safeString(.stage("protected_data", allowed: ["zero_samples", "protected_data", "fetch_failed"]))
                    ], error: nil)
                } else {
                    batchSpan.end(additionalFields: [
                        "skip_reason": .safeString(.stage("fetch_failed", allowed: ["zero_samples", "protected_data", "fetch_failed"]))
                    ], error: error)
                }
            }
            await monitor?.heartbeat(progressFields: [
                "phase": .safeString(.stage(phase, allowed: ["warm-start", "full"])),
                "processed_types": .int(processedTypeCount + 1)
            ])
            processedTypeCount += 1
        }
        return (touchedDays, totalSamples)
    }

    private func scheduleBackgroundFullBackfillIfNeeded(grantedTypes: Set<HKSampleType>, targetStartDate: Date) {
        guard needsFullBackfill(for: grantedTypes, targetStartDate: targetStartDate) else {
            Task { await DebugLogBuffer.shared.append("Background backfill skipped: full window already covered") }
            return
        }
        if let task = backgroundBackfillTask, !task.isCancelled {
            return
        }
        backgroundBackfillTask = Task { [weak self] in
            await self?.performBackgroundFullBackfill(grantedTypes: grantedTypes, targetStartDate: targetStartDate)
        }
    }

    private func needsFullBackfill(for grantedTypes: Set<HKSampleType>, targetStartDate: Date) -> Bool {
        for type in grantedTypes {
            let identifier = type.identifier
            if backfillProgress.fullBackfillCompletedTypes.contains(identifier) {
                continue
            }
            guard let earliest = backfillProgress.earliestProcessedDate(for: identifier, calendar: calendar) else {
                return true
            }
            if earliest > targetStartDate {
                return true
            }
        }
        return false
    }

    private func performBackgroundFullBackfill(grantedTypes: Set<HKSampleType>, targetStartDate: Date) async {
        let phaseSpan = Diagnostics.span(category: .backfill,
                                         name: "data.backfill.phase",
                                         fields: [
                                             "phase": .safeString(.stage("full30d", allowed: ["warmStart7d", "full30d"])),
                                             "target_start_day": .day(targetStartDate)
                                         ],
                                         traceId: diagnosticsTraceId,
                                         level: .info)
        let monitor = DiagnosticsStallMonitor(category: .backfill,
                                              name: "data.backfill.full",
                                              traceId: diagnosticsTraceId,
                                              thresholdSeconds: 90,
                                              initialFields: [
                                                  "phase": .safeString(.stage("full30d", allowed: ["warmStart7d", "full30d"])),
                                                  "granted_types": .int(grantedTypes.count)
                                              ])
        await monitor.start()
        defer { backgroundBackfillTask = nil }

        var iteration = 0
        var batchTouchedDays: Set<Date> = []
        var batchSampleCount = 0
        var batchTypes: [String] = []
        var totalTouchedDays: Set<Date> = []
        var totalSamples = 0
        let today = calendar.startOfDay(for: Date())

        while !Task.isCancelled {
            var madeProgress = false
            let sorted = grantedTypes.sorted { $0.identifier < $1.identifier }

            for type in sorted {
                let identifier = type.identifier
                if backfillProgress.fullBackfillCompletedTypes.contains(identifier) {
                    continue
                }

                let currentEarliest = backfillProgress.earliestProcessedDate(for: identifier, calendar: calendar) ?? calendar.startOfDay(for: Date())
                if currentEarliest <= targetStartDate {
                    backfillProgress.markFullBackfillComplete(for: identifier)
                    persistBackfillProgress()
                    continue
                }

                let batchEnd = calendar.date(byAdding: .day, value: -1, to: currentEarliest) ?? targetStartDate
                var batchStart = calendar.date(byAdding: .day, value: -(backgroundBackfillBatchDays - 1), to: batchEnd) ?? targetStartDate
                if batchStart < targetStartDate { batchStart = targetStartDate }

                let touched = await performBackfill(for: [type],
                                                    startDate: batchStart,
                                                    endDate: batchEnd,
                                                    phase: "full",
                                                    targetStartDate: targetStartDate,
                                                    markWarmStart: false,
                                                    monitor: monitor)
                batchTypes.append(identifier)
                batchSampleCount += touched.totalSamples
                totalSamples += touched.totalSamples
                batchTouchedDays.formUnion(touched.days)
                totalTouchedDays.formUnion(touched.days)
                madeProgress = true
            }

            if !needsFullBackfill(for: grantedTypes, targetStartDate: targetStartDate) {
                break
            }
            if !madeProgress {
                logDiagnostics(level: .warn,
                               category: .backfill,
                               name: "data.backfill.phase.pause",
                               fields: [
                                   "phase": .safeString(.stage("full30d", allowed: ["warmStart7d", "full30d"])),
                                   "reason": .safeString(.stage("no_progress", allowed: ["no_progress"]))
                               ])
                break
            }
            logDiagnostics(level: .info,
                           category: .backfill,
                           name: "data.backfill.phase.iteration",
                           fields: [
                               "phase": .safeString(.stage("full30d", allowed: ["warmStart7d", "full30d"])),
                               "iteration": .int(iteration),
                               "window_start_day": batchTouchedDays.min().map { .day($0) } ?? .day(today),
                               "window_end_day": batchTouchedDays.max().map { .day($0) } ?? .day(today),
                               "types_processed": .int(batchTypes.count),
                               "touched_days": .int(batchTouchedDays.count),
                               "raw_sample_count": .int(batchSampleCount)
                           ])
            if !batchTouchedDays.isEmpty {
                notifySnapshotUpdate(for: today,
                                     reason: .stage("full_backfill",
                                                    allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]))
            }
            batchTouchedDays.removeAll()
            batchSampleCount = 0
            batchTypes.removeAll()
            iteration += 1
            if iteration > 64 { break }
            try? await Task.sleep(nanoseconds: 150_000_000)
        }

        await monitor.stop(finalFields: [
            "touched_days": .int(totalTouchedDays.count),
            "raw_sample_count": .int(totalSamples),
            "iterations": .int(iteration)
        ])

        phaseSpan.end(additionalFields: [
            "phase": .safeString(.stage("full30d", allowed: ["warmStart7d", "full30d"])),
            "touched_days": .int(totalTouchedDays.count),
            "raw_sample_count": .int(totalSamples),
            "iterations": .int(iteration)
        ], error: nil)
    }


    private func enableBackgroundDelivery(for grantedTypes: Set<HKSampleType>) async throws {
        guard !grantedTypes.isEmpty else {
            await DebugLogBuffer.shared.append("enableBackgroundDelivery skipped: no granted types")
            return
        }
        do {
            try await healthKit.enableBackgroundDelivery(for: grantedTypes)
            await DebugLogBuffer.shared.append("enableBackgroundDelivery enabled for \(grantedTypes.map { $0.identifier })")
        } catch HealthKitServiceError.backgroundDeliveryFailed(let type, let underlying) {
            if shouldIgnoreBackgroundDeliveryError(underlying) {
                await DebugLogBuffer.shared.append("enableBackgroundDelivery ignored missing entitlement for \(type.identifier)")
                Diagnostics.log(level: .warn,
                                category: .healthkit,
                                name: "data.healthkit.backgroundDelivery.missingEntitlement",
                                fields: ["type": .safeString(.metadata(type.identifier))])
            } else {
                throw HealthKitServiceError.backgroundDeliveryFailed(type: type, underlying: underlying)
            }
        } catch {
            throw error
        }
    }

    private func startObserversIfNeeded(for types: Set<HKSampleType>) async throws {
        guard !types.isEmpty else {
            await DebugLogBuffer.shared.append("startObserversIfNeeded skipped: no granted types")
            return
        }
        for type in types {
            await DebugLogBuffer.shared.append("Starting observer for \(type.identifier)")
            try await observe(sampleType: type)
        }
    }

    private func stopRevokedObservers(keeping granted: Set<HKSampleType>, resetAnchors: Bool) {
        let grantedIdentifiers = Set(granted.map { $0.identifier })
        let identifiers = Array(observers.keys)
        var revoked: [String] = []
        for identifier in identifiers where !grantedIdentifiers.contains(identifier) {
            if let type = sampleTypesByIdentifier[identifier] {
                stopObservation(for: type, resetAnchor: resetAnchors)
                revoked.append(identifier)
            } else {
                observers.removeValue(forKey: identifier)
            }
        }
        if resetAnchors, !revoked.isEmpty {
            for identifier in revoked {
                backfillProgress.removeProgress(for: identifier)
            }
            persistBackfillProgress()
        }
    }

    private func readAuthorizationProbeResults(forceRefresh: Bool = false) async -> [String: ReadAuthorizationProbeResult] {
        if !forceRefresh,
           let cached = cachedReadAccess,
           Date().timeIntervalSince(cached.timestamp) < readProbeCacheTTL {
            return cached.results
        }

        let resultsByType = await healthKit.probeReadAuthorization(for: requiredSampleTypes)
        var mapped: [String: ReadAuthorizationProbeResult] = [:]
        for (type, result) in resultsByType {
            mapped[type.identifier] = result
        }
        cachedReadAccess = (timestamp: Date(), results: mapped)
        return mapped
    }

    private func invalidateReadAccessCache() {
        cachedReadAccess = nil
    }

    private func logHealthStatus(_ status: HealthAccessStatus,
                                 requestStatus: HKAuthorizationRequestStatus?,
                                 probeResults: [String: ReadAuthorizationProbeResult]) {
        var debugLines: [String] = []
        debugLines.append("Health access status → granted: \(status.granted.map(\.identifier)), denied: \(status.denied.map(\.identifier)), pending: \(status.notDetermined.map(\.identifier)), availability: \(status.availability)")
        if let requestStatus {
            debugLines.append("HealthKit requestStatusForAuthorization=\(requestStatus.rawValue)")
        }
        if !probeResults.isEmpty {
            debugLines.append(readProbeSummary(probeResults))
            let perType = probeResults
                .map { "\($0.key)=\(probeLabel(for: $0.value))" }
                .sorted()
                .joined(separator: ", ")
            debugLines.append("HealthKit read probe per-type: \(perType)")
        }
        for line in debugLines {
            Task { await DebugLogBuffer.shared.append(line) }
        }
        Diagnostics.log(level: .info,
                        category: .healthkit,
                        name: "data.healthkit.status",
                        fields: [
                            "granted": .int(status.granted.count),
                            "denied": .int(status.denied.count),
                            "pending": .int(status.notDetermined.count),
                            "availability": .safeString(DiagnosticsSafeString.stage(status.availability == .available ? "available" : "unavailable",
                                                                                    allowed: Set(["available", "unavailable"])))
                        ],
                        traceId: diagnosticsTraceId)
    }

    private func logDiagnostics(level: DiagnosticsLevel,
                                category: DiagnosticsCategory = .dataAgent,
                                name: String,
                                fields: [String: DiagnosticsValue] = [:],
                                error: Error? = nil) {
        Diagnostics.log(level: level,
                        category: category,
                        name: name,
                        fields: fields,
                        traceId: diagnosticsTraceId,
                        error: error)
    }

    private func statusSummary(_ status: HealthAccessStatus) -> String {
        let grantedIds = status.granted.map(\.identifier).sorted().joined(separator: ",")
        let deniedIds = status.denied.map(\.identifier).sorted().joined(separator: ",")
        let pendingIds = status.notDetermined.map(\.identifier).sorted().joined(separator: ",")
        return "granted=[\(grantedIds)] denied=[\(deniedIds)] pending=[\(pendingIds)] availability=\(status.availability)"
    }

    private func stopAllObservers(resetAnchors: Bool) {
        let identifiers = Array(observers.keys)
        for identifier in identifiers {
            if let type = sampleTypesByIdentifier[identifier] {
                stopObservation(for: type, resetAnchor: resetAnchors)
            }
        }
        observers.removeAll()
    }

    private func stopObservation(for type: HKSampleType, resetAnchor: Bool) {
        observers.removeValue(forKey: type.identifier)
        healthKit.stopObserving(sampleType: type, resetAnchor: resetAnchor)
    }

    private func readProbeSummary(_ results: [String: ReadAuthorizationProbeResult]) -> String {
        var authorized = 0
        var denied = 0
        var pending = 0
        var protected = 0
        var errors = 0

        for result in results.values {
            switch result {
            case .authorized:
                authorized += 1
            case .denied:
                denied += 1
            case .notDetermined:
                pending += 1
            case .protectedDataUnavailable, .healthDataUnavailable:
                protected += 1
            case .error:
                errors += 1
            }
        }

        return "HealthKit read probe summary: authorized=\(authorized) denied=\(denied) pending=\(pending) protected=\(protected) error=\(errors)"
    }

    private func probeLabel(for result: ReadAuthorizationProbeResult) -> String {
        switch result {
        case .authorized:
            return "authorized"
        case .denied:
            return "denied"
        case .notDetermined:
            return "notDetermined"
        case .protectedDataUnavailable:
            return "protectedDataUnavailable"
        case .healthDataUnavailable:
            return "healthDataUnavailable"
        case let .error(domain, code):
            return "error(\(domain):\(code))"
        }
    }

    func latestFeatureVector() async throws -> FeatureVectorSnapshot? {
        let context = self.context
        let result = try await context.perform { () throws -> FeatureComputation? in
            let request = FeatureVector.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: #keyPath(FeatureVector.date), ascending: false)]
            request.fetchLimit = 1
            guard let latest = try context.fetch(request).first else { return nil }
            let bundle = DataAgent.materializeFeatures(from: latest)
            return FeatureComputation(date: latest.date,
                                      featureValues: bundle.values,
                                      imputedFlags: bundle.imputed,
                                      featureVectorObjectID: latest.objectID)
        }

        guard let computation = result else {
            await DebugLogBuffer.shared.append("latestFeatureVector -> none found")
            return nil
        }
        let modelFeatures = WellbeingModeling.normalize(features: computation.featureValues,
                                                        imputedFlags: computation.imputedFlags)
        let snapshot = stateEstimator.currentSnapshot(features: modelFeatures)
        let dayString = DiagnosticsDayFormatter.dayString(from: computation.date)
        await DebugLogBuffer.shared.append("latestFeatureVector -> day=\(dayString) feature_count=\(computation.featureValues.count)")
        return FeatureVectorSnapshot(date: computation.date,
                                     wellbeingScore: snapshot.wellbeingScore,
                                     contributions: snapshot.contributions,
                                     imputedFlags: computation.imputedFlags,
                                     featureVectorObjectID: computation.featureVectorObjectID,
                                     features: computation.featureValues)
    }

    func scoreBreakdown() async throws -> ScoreBreakdown? {
        guard let snapshot = try await latestFeatureVector() else { return nil }

        let context = self.context
        let dayString = DiagnosticsDayFormatter.dayString(from: snapshot.date)
        await DebugLogBuffer.shared.append("Computing scoreBreakdown for day=\(dayString)")

        struct BaselinePayload: Sendable {
            let median: Double?
            let mad: Double?
            let ewma: Double?
            let updatedAt: Date?
        }

        let descriptors = Self.scoreMetricDescriptors
        let coverageByFeature = try await metricCoverage(for: snapshot, descriptors: descriptors)
        let rawAndBaselines = try await context.perform { () throws -> ([String: Double], [String: BaselinePayload]) in
            var rawValues: [String: Double] = [:]
            var baselines: [String: BaselinePayload] = [:]

            let metricsRequest = DailyMetrics.fetchRequest()
            metricsRequest.predicate = NSPredicate(format: "date == %@", snapshot.date as NSDate)
            metricsRequest.fetchLimit = 1
            if let metrics = try context.fetch(metricsRequest).first {
                rawValues["hrv"] = metrics.hrvMedian?.doubleValue
                rawValues["nocthr"] = metrics.nocturnalHRPercentile10?.doubleValue
                rawValues["resthr"] = metrics.restingHR?.doubleValue
                rawValues["sleepDebt"] = metrics.sleepDebt?.doubleValue
                rawValues["rr"] = metrics.respiratoryRate?.doubleValue
                rawValues["steps"] = metrics.steps?.doubleValue
            }

            let baselineKeys = Array(Set(descriptors.compactMap { $0.baselineKey }))
            if !baselineKeys.isEmpty {
                let baselineKeysPredicate = baselineKeys as NSArray
                let baselineRequest = Baseline.fetchRequest()
                baselineRequest.predicate = NSPredicate(format: "metric IN %@", baselineKeysPredicate)
                let baselineObjects = try context.fetch(baselineRequest)
                for baseline in baselineObjects {
                    let key = baseline.metric
                    guard !key.isEmpty else { continue }
                    baselines[key] = BaselinePayload(
                        median: baseline.median?.doubleValue,
                        mad: baseline.mad?.doubleValue,
                        ewma: baseline.ewma?.doubleValue,
                        updatedAt: baseline.updatedAt
                    )
                }
            }

            return (rawValues, baselines)
        }

        let rawValues = rawAndBaselines.0
        let baselineValues = rawAndBaselines.1

        var metrics: [ScoreBreakdown.MetricDetail] = []
        metrics.reserveCapacity(descriptors.count)

        for descriptor in descriptors.sorted(by: { $0.order < $1.order }) {
            let value: Double?
            if let rawKey = descriptor.rawValueKey {
                value = rawValues[rawKey]
            } else {
                value = snapshot.features[descriptor.featureKey]
            }

            let zScore: Double?
            if descriptor.usesZScore {
                zScore = snapshot.features[descriptor.featureKey]
            } else {
                zScore = nil
            }

            let baseline = descriptor.baselineKey.flatMap { baselineValues[$0] }
            let contribution = snapshot.contributions[descriptor.featureKey] ?? 0
            let notes = descriptor.flagMessages(for: snapshot.imputedFlags)

            let detail = ScoreBreakdown.MetricDetail(
                id: descriptor.featureKey,
                name: descriptor.displayName,
                kind: descriptor.kind,
                value: value,
                unit: descriptor.unit,
                zScore: zScore,
                contribution: contribution,
                baselineMedian: baseline?.median,
                baselineEwma: baseline?.ewma,
                baselineMad: baseline?.mad,
                rollingWindowDays: descriptor.rollingWindowDays,
                explanation: descriptor.explanation,
                notes: notes,
                coverage: coverageByFeature[descriptor.featureKey]
            )

            metrics.append(detail)
        }

        let generalNotes = Self.generalFlagMessages(for: snapshot.imputedFlags)

        return ScoreBreakdown(date: snapshot.date,
                              wellbeingScore: snapshot.wellbeingScore,
                              metrics: metrics,
                              generalNotes: generalNotes)
    }

    private func metricCoverage(for snapshot: FeatureVectorSnapshot,
                                descriptors: [ScoreMetricDescriptor]) async throws -> [String: ScoreBreakdown.MetricDetail.Coverage] {
        let calendar = self.calendar
        let context = self.context

        return try await context.perform {
            var coverage: [String: ScoreBreakdown.MetricDetail.Coverage] = [:]
            let endDate = calendar.startOfDay(for: snapshot.date)

            var windowStarts: [String: Date] = [:]
            for descriptor in descriptors {
                guard let window = descriptor.rollingWindowDays else { continue }
                let start = calendar.date(byAdding: .day, value: -(window - 1), to: endDate) ?? endDate
                windowStarts[descriptor.featureKey] = start
            }

            guard let earliest = windowStarts.values.min() else { return [:] }

            let request = DailyMetrics.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", earliest as NSDate, endDate as NSDate)
            let metrics = try context.fetch(request)

            var counts: [String: (days: Set<Date>, samples: Int)] = [:]

            for metric in metrics {
                let flags = DataAgent.decodeFlags(from: metric)
                let day = calendar.startOfDay(for: metric.date)

                let hrvCount = flags.hrvSamples.isEmpty ? (metric.hrvMedian != nil ? 1 : 0) : flags.hrvSamples.count
                let nocturnalAvailable = metric.nocturnalHRPercentile10 != nil || flags.aggregatedNocturnalAverage != nil || !flags.heartRateSamples.isEmpty
                let restingSamples = flags.heartRateSamples.filter { $0.context == .resting }.count
                let restingCount = restingSamples == 0 ? (metric.restingHR != nil ? 1 : 0) : restingSamples
                let sleepDebtCount = metric.sleepDebt != nil ? 1 : 0
                let rrCount = flags.respiratorySamples.isEmpty ? (metric.respiratoryRate != nil ? 1 : 0) : flags.respiratorySamples.count
                let stepsAvailable = metric.steps != nil || flags.aggregatedStepTotal != nil || !flags.stepBuckets.isEmpty

                let sampleCounts: [String: Int] = [
                    "z_hrv": hrvCount,
                    "z_nocthr": nocturnalAvailable ? 1 : 0,
                    "z_resthr": restingCount,
                    "z_sleepDebt": sleepDebtCount,
                    "z_rr": rrCount,
                    "z_steps": stepsAvailable ? 1 : 0
                ]

                for (featureKey, count) in sampleCounts {
                    guard let windowStart = windowStarts[featureKey] else { continue }
                    guard day >= windowStart else { continue }
                    guard count > 0 else { continue }

                    var entry = counts[featureKey] ?? (Set<Date>(), 0)
                    entry.days.insert(day)
                    entry.samples += count
                    counts[featureKey] = entry
                }
            }

            for (featureKey, _) in windowStarts {
                if let entry = counts[featureKey] {
                    coverage[featureKey] = ScoreBreakdown.MetricDetail.Coverage(daysWithSamples: entry.days.count,
                                                                                sampleCount: entry.samples)
                } else {
                    // Explicitly surface zero coverage when no samples are available
                    coverage[featureKey] = ScoreBreakdown.MetricDetail.Coverage(daysWithSamples: 0, sampleCount: 0)
                }
            }

            return coverage
        }
    }

    func reprocessDay(date: Date) async throws {
        let day = calendar.startOfDay(for: date)
        try await reprocessDayInternal(day)
        notifySnapshotUpdate(for: day,
                             reason: .stage("reprocess",
                                            allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]))
    }

    func recordSubjectiveInputs(date: Date, stress: Double, energy: Double, sleepQuality: Double) async throws {
        let targetDate = calendar.startOfDay(for: date)
        let context = self.context
        let dayString = DiagnosticsDayFormatter.dayString(from: targetDate)
        await DebugLogBuffer.shared.append("Recording subjective inputs for day=\(dayString)")
        try await context.perform {
            let request = FeatureVector.fetchRequest()
            request.predicate = NSPredicate(format: "date == %@", targetDate as NSDate)
            request.fetchLimit = 1
            let vector = try context.fetch(request).first ?? FeatureVector(context: context)
            vector.date = targetDate
            vector.subjectiveStress = NSNumber(value: stress)
            vector.subjectiveEnergy = NSNumber(value: energy)
            vector.subjectiveSleepQuality = NSNumber(value: sleepQuality)
            try context.save()
        }
        try await reprocessDayInternal(targetDate)
        notifySnapshotUpdate(for: targetDate,
                             reason: .stage("reprocess",
                                            allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]))
    }

    // MARK: - Observation

    private func observe(sampleType: HKSampleType) async throws {
        let identifier = sampleType.identifier
        guard observers[identifier] == nil else { return }
        let token = try healthKit.observeSampleType(sampleType, predicate: nil) { result in
            switch result {
            case let .success(update):
                Task { await self.handle(update: update, sampleType: sampleType) }
            case let .failure(error):
                let nsError = error as NSError
                Task { await DebugLogBuffer.shared.append("HealthKit observe error for \(sampleType.identifier): domain=\(nsError.domain) code=\(nsError.code)") }
                Diagnostics.log(level: .warn,
                                category: .healthkit,
                                name: "data.healthkit.observe.error",
                                fields: ["type": .safeString(.metadata(sampleType.identifier))],
                                error: error)
            }
        }
        observers[identifier] = token
    }

    private func handle(update: HealthKitService.AnchoredUpdate, sampleType: HKSampleType) async {
        do {
            var touchedDays: Set<Date> = []
            switch sampleType {
            case let quantityType as HKQuantityType:
                let days = try await processQuantitySamples(update.samples.compactMap { $0 as? HKQuantitySample },
                                                            type: quantityType)
                touchedDays.formUnion(days)
            case let categoryType as HKCategoryType:
                let days = try await processCategorySamples(update.samples.compactMap { $0 as? HKCategorySample },
                                                            type: categoryType)
                touchedDays.formUnion(days)
            default:
                break
            }
            let deletedDays = try await handleDeletedSamples(update.deletedSamples)
            touchedDays.formUnion(deletedDays)

            logDiagnostics(level: .info,
                           category: .healthkit,
                           name: "data.healthkit.update",
                           fields: [
                               "type": .safeString(.metadata(sampleType.identifier)),
                               "sample_count": .int(update.samples.count),
                               "deleted_count": .int(update.deletedSamples.count),
                               "touched_days": .int(touchedDays.count)
                           ])

            if touchedDays.isEmpty {
                notifySnapshotUpdate(for: calendar.startOfDay(for: Date()),
                                     reason: .stage("refresh",
                                                    allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]))
            } else {
                for day in touchedDays {
                    notifySnapshotUpdate(for: day,
                                         reason: .stage("refresh",
                                                        allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]))
                }
            }
        } catch {
            Diagnostics.log(level: .error,
                            category: .dataAgent,
                            name: "dataAgent.handleUpdate.error",
                            fields: ["type": .safeString(.metadata(sampleType.identifier))],
                            error: error)
        }
    }

    // MARK: - Sample Processing

    private func processQuantitySamples(_ samples: [HKQuantitySample],
                                        type: HKQuantityType) async throws -> Set<Date> {
        guard !samples.isEmpty else { return [] }

        let calendar = self.calendar
        let context = self.context
        let identifier = type.identifier

        if identifier == HKQuantityTypeIdentifier.stepCount.rawValue {
            guard let range = dayRange(for: samples) else { return [] }
            do {
                let totals = try await safeFetchDailyStepTotals(startDate: range.start,
                                                                endDate: range.end,
                                                                context: "Backfill \(identifier)")
                return try await applyStepTotals(totals)
            } catch {
                if isProtectedHealthDataInaccessible(error) {
                    await DebugLogBuffer.shared.append("Backfill skipped for \(identifier): protected data inaccessible (device likely locked).")
                    return []
                }
                throw error
            }
        } else if identifier == HKQuantityTypeIdentifier.heartRate.rawValue {
            guard let range = dayRange(for: samples) else { return [] }
            do {
                let stats = try await safeFetchNocturnalHeartRateStats(startDate: range.start,
                                                                       endDate: range.end,
                                                                       context: "Backfill \(identifier)")
                return try await applyNocturnalStats(stats)
            } catch {
                if isProtectedHealthDataInaccessible(error) {
                    await DebugLogBuffer.shared.append("Backfill skipped for \(identifier): protected data inaccessible (device likely locked).")
                    return []
                }
                throw error
            }
        }

        let dirtyDays = try await context.perform { () throws -> Set<Date> in
            var dirtyDays: Set<Date> = []
            for sample in samples {
                let day = calendar.startOfDay(for: sample.startDate)
                let metrics = DataAgent.fetchOrCreateDailyMetrics(in: context, date: day)
                DataAgent.mutateFlags(metrics) { flags in
                    flags.append(quantitySample: sample, type: type)
                }
                dirtyDays.insert(day)
            }

            if context.hasChanges {
                try context.save()
            }
            return dirtyDays
        }

        for day in dirtyDays {
            try await reprocessDayInternal(day)
        }

        return dirtyDays
    }

    private func processCategorySamples(_ samples: [HKCategorySample],
                                        type: HKCategoryType) async throws -> Set<Date> {
        guard type.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue else { return [] }
        guard !samples.isEmpty else { return [] }

        let calendar = self.calendar
        let context = self.context

        let dirtyDays = try await context.perform { () throws -> Set<Date> in
            var dirtyDays: Set<Date> = []
            for sample in samples {
                let day = calendar.startOfDay(for: sample.startDate)
                let metrics = DataAgent.fetchOrCreateDailyMetrics(in: context, date: day)
                DataAgent.mutateFlags(metrics) { flags in
                    let appended = flags.append(sleepSample: sample)
                    if appended {
                        dirtyDays.insert(day)
                    }
                }
            }
            if context.hasChanges {
                try context.save()
            }
            return dirtyDays
        }

        for day in dirtyDays {
            try await reprocessDayInternal(day)
        }

        return dirtyDays
    }

    private func handleDeletedSamples(_ deletedObjects: [HKDeletedObject]) async throws -> Set<Date> {
        guard !deletedObjects.isEmpty else { return [] }

        let identifiers = Set(deletedObjects.map { $0.uuid })
        let context = self.context
        let dirtyDays = try await context.perform { () throws -> Set<Date> in
            let request = DailyMetrics.fetchRequest()
            let metrics = try context.fetch(request)
            var dirty: Set<Date> = []
            for metric in metrics {
                var flags = DataAgent.decodeFlags(from: metric)
                if flags.pruneDeletedSamples(identifiers) {
                    metric.flags = DataAgent.encodeFlags(flags)
                    dirty.insert(metric.date)
                }
            }
            if context.hasChanges {
                try context.save()
            }
            return dirty
        }

        for day in dirtyDays {
            try await reprocessDayInternal(day)
        }

        return dirtyDays
    }

    private func dayRange(for samples: [HKSample]) -> (start: Date, end: Date)? {
        guard let earliest = samples.map(\.startDate).min(),
              let latest = samples.map(\.startDate).max() else { return nil }
        let startDay = calendar.startOfDay(for: earliest)
        let endExclusive = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: latest)) ?? calendar.startOfDay(for: latest)
        return (startDay, endExclusive)
    }

    private func applyStepTotals(_ totals: [Date: Int]) async throws -> Set<Date> {
        guard !totals.isEmpty else { return [] }
        let calendar = self.calendar
        let context = self.context

        let dirtyDays = try await context.perform { () throws -> Set<Date> in
            var dirty: Set<Date> = []
            for (rawDay, total) in totals {
                let day = calendar.startOfDay(for: rawDay)
                let metrics = DataAgent.fetchOrCreateDailyMetrics(in: context, date: day)
                DataAgent.mutateFlags(metrics) { flags in
                    flags.aggregatedStepTotal = Double(total)
                    flags.stepBuckets = []
                }
                dirty.insert(day)
            }
            if context.hasChanges {
                try context.save()
            }
            return dirty
        }

        for day in dirtyDays {
            try await reprocessDayInternal(day)
        }

        return dirtyDays
    }

    private func applyNocturnalStats(_ stats: [Date: (avgBPM: Double, minBPM: Double?)]) async throws -> Set<Date> {
        guard !stats.isEmpty else { return [] }
        let calendar = self.calendar
        let context = self.context

        let dirtyDays = try await context.perform { () throws -> Set<Date> in
            var dirty: Set<Date> = []
            for (rawDay, value) in stats {
                let day = calendar.startOfDay(for: rawDay)
                let metrics = DataAgent.fetchOrCreateDailyMetrics(in: context, date: day)
                DataAgent.mutateFlags(metrics) { flags in
                    flags.aggregatedNocturnalAverage = value.avgBPM
                    flags.aggregatedNocturnalMin = value.minBPM
                    flags.heartRateSamples.removeAll { $0.context == .normal }
                }
                dirty.insert(day)
            }
            if context.hasChanges {
                try context.save()
            }
            return dirty
        }

        for day in dirtyDays {
            try await reprocessDayInternal(day)
        }

        return dirtyDays
    }

    // MARK: - Daily Computation

    private func reprocessDayInternal(_ day: Date) async throws {
        let context = self.context
        let calendar = self.calendar
        let sedentaryThreshold = sedentaryThresholdStepsPerHour
        let sedentaryDuration = sedentaryMinimumDuration
        let sleepDebtWindowDays = self.sleepDebtWindowDays
        let analysisWindowDays = self.fullAnalysisWindowDays

        let computation = try await context.perform { () throws -> FeatureComputation in
            let metrics = try DataAgent.fetchDailyMetrics(in: context, date: day)
            var flags = DataAgent.decodeFlags(from: metrics)
            let summary = try DataAgent.computeSummary(for: metrics,
                                                       flags: flags,
                                                       context: context,
                                                       calendar: calendar,
                                                       sedentaryThreshold: sedentaryThreshold,
                                                       sedentaryMinimumDuration: sedentaryDuration,
                                                       sleepDebtWindowDays: sleepDebtWindowDays,
                                                       analysisWindowDays: analysisWindowDays)
            flags = summary.updatedFlags

            metrics.hrvMedian = summary.hrv.map(NSNumber.init(value:))
            metrics.nocturnalHRPercentile10 = summary.nocturnalHR.map(NSNumber.init(value:))
            metrics.restingHR = summary.restingHR.map(NSNumber.init(value:))
            metrics.totalSleepTime = summary.totalSleepSeconds.map(NSNumber.init(value:))
            metrics.sleepDebt = summary.sleepDebtHours.map(NSNumber.init(value:))
            metrics.respiratoryRate = summary.respiratoryRate.map(NSNumber.init(value:))
            metrics.steps = summary.stepCount.map(NSNumber.init(value:))
            metrics.flags = DataAgent.encodeFlags(flags)

            let baselines = try DataAgent.updateBaselines(in: context,
                                                          summary: summary,
                                                          referenceDate: day,
                                                          windowDays: analysisWindowDays)
            let bundle = try DataAgent.buildFeatureBundle(for: metrics,
                                                          summary: summary,
                                                          baselines: baselines,
                                                          context: context)
            let featureVector = try DataAgent.fetchOrCreateFeatureVector(in: context, date: day)
            DataAgent.apply(features: bundle.values, to: featureVector)

            if context.hasChanges {
                try context.save()
            }

            return FeatureComputation(date: day,
                                      featureValues: bundle.values,
                                      imputedFlags: bundle.imputed,
                                      featureVectorObjectID: featureVector.objectID)
        }

        let modelFeatures = WellbeingModeling.normalize(features: computation.featureValues,
                                                        imputedFlags: computation.imputedFlags)
        let target = WellbeingModeling.target(for: modelFeatures)
        let snapshot = stateEstimator.update(features: modelFeatures, target: target)
        let dayString = DiagnosticsDayFormatter.dayString(from: day)
        await DebugLogBuffer.shared.append("Reprocessed day \(dayString) -> feature_count=\(computation.featureValues.count)")
        persistEstimatorState(from: snapshot)

        try await context.perform {
            guard let vector = try? context.existingObject(with: computation.featureVectorObjectID) as? FeatureVector else { return }
            vector.imputedFlags = DataAgent.encodeFeatureMetadata(imputed: computation.imputedFlags,
                                                                  contributions: snapshot.contributions,
                                                                  wellbeing: snapshot.wellbeingScore)
            if context.hasChanges {
                try context.save()
            }
        }
    }

    private func persistEstimatorState(from snapshot: StateEstimatorSnapshot) {
        let state = StateEstimatorState(version: EstimatorStateStore.schemaVersion,
                                        weights: snapshot.weights,
                                        bias: snapshot.bias)
        estimatorStore.saveState(state)
    }

    private func safeFetchDailyStepTotals(startDate: Date, endDate: Date, context: String) async throws -> [Date: Int] {
        do {
            return try await healthKit.fetchDailyStepTotals(startDate: startDate, endDate: endDate)
        } catch {
            if isProtectedHealthDataInaccessible(error) {
                await DebugLogBuffer.shared.append("\(context): protected data inaccessible (device likely locked); returning empty step totals.")
                return [:]
            }
            throw error
        }
    }

    private func safeFetchNocturnalHeartRateStats(startDate: Date, endDate: Date, context: String) async throws -> [Date: (avgBPM: Double, minBPM: Double?)] {
        do {
            return try await healthKit.fetchNocturnalHeartRateStats(startDate: startDate, endDate: endDate)
        } catch {
            if isProtectedHealthDataInaccessible(error) {
                await DebugLogBuffer.shared.append("\(context): protected data inaccessible (device likely locked); returning empty nocturnal HR stats.")
                return [:]
            }
            throw error
        }
    }

    private func isProtectedHealthDataInaccessible(_ error: Error) -> Bool {
        if let hkError = error as? HKError {
            return hkError.code == .errorDatabaseInaccessible || hkError.code == .errorHealthDataUnavailable
        }
        let nsError = error as NSError
        if nsError.domain == HKError.errorDomain {
            return nsError.code == HKError.errorDatabaseInaccessible.rawValue
        }
        // Fallback for unexpected error domains where localizedDescription is the only indicator.
        return nsError.localizedDescription.localizedCaseInsensitiveContains("Protected health data is inaccessible")
    }

    private static func computeSummary(for metrics: DailyMetrics,
                                       flags: DailyFlags,
                                       context: NSManagedObjectContext,
                                       calendar: Calendar,
                                       sedentaryThreshold: Double,
                                       sedentaryMinimumDuration: TimeInterval,
                                       sleepDebtWindowDays: Int,
                                       analysisWindowDays: Int) throws -> DailySummary {
        var imputed: [String: Bool] = [:]

        let sleepIntervals = flags.sleepIntervals()
        let sedentaryIntervals = flags.sedentaryIntervals(thresholdStepsPerHour: sedentaryThreshold,
                                                          minimumDuration: sedentaryMinimumDuration,
                                                          excluding: sleepIntervals)
        if sedentaryIntervals.isEmpty && sleepIntervals.isEmpty {
            imputed["sedentary_missing"] = true
        }

        let previousHRV = try previousMetricValue(in: context,
                                                  keyPath: #keyPath(DailyMetrics.hrvMedian),
                                                  before: metrics.date)
        let hrvValue = flags.medianHRV(in: sleepIntervals,
                                       fallback: sedentaryIntervals,
                                       previous: previousHRV,
                                       imputed: &imputed)

        let previousNocturnal = try previousMetricValue(in: context,
                                                        keyPath: #keyPath(DailyMetrics.nocturnalHRPercentile10),
                                                        before: metrics.date)
        let nocturnalHR = flags.nocturnalHeartRate(in: sleepIntervals,
                                                   fallback: sedentaryIntervals,
                                                   previous: previousNocturnal,
                                                   imputed: &imputed)

        let previousResting = try previousMetricValue(in: context,
                                                      keyPath: #keyPath(DailyMetrics.restingHR),
                                                      before: metrics.date)
        let restingHR = flags.restingHeartRate(fallback: sedentaryIntervals,
                                               previous: previousResting,
                                               imputed: &imputed)

        let sleepSeconds = flags.sleepDurations()
        let sleepNeed = try personalizedSleepNeedHours(context: context,
                                                       referenceDate: metrics.date,
                                                       latestActualHours: (sleepSeconds ?? 0) / 3600,
                                                       windowDays: analysisWindowDays)
        var sleepDebt: Double?
        if let sleepSeconds {
            let actualSleepHours = sleepSeconds / 3600
            if sleepSeconds < 3 * 3600 {
                imputed["sleep_low_confidence"] = true
            }
            sleepDebt = try sleepDebtHours(context: context,
                                           personalNeed: sleepNeed,
                                           currentHours: actualSleepHours,
                                           referenceDate: metrics.date,
                                           windowDays: sleepDebtWindowDays,
                                           calendar: calendar)
        } else {
            imputed["sleepDebt_missing"] = true
        }

        let respiratoryRate = flags.averageRespiratoryRate(in: sleepIntervals)
        if respiratoryRate == nil {
            imputed["rr_missing"] = true
        }
        let stepCount = flags.totalSteps()
        if stepCount == nil {
            imputed["steps_missing"] = true
        } else if (stepCount ?? 0) < 500 {
            imputed["steps_low_confidence"] = true
        }

        return DailySummary(date: metrics.date,
                            hrv: hrvValue,
                            nocturnalHR: nocturnalHR,
                            restingHR: restingHR,
                            totalSleepSeconds: sleepSeconds,
                            sleepNeedHours: sleepNeed,
                            sleepDebtHours: sleepDebt,
                            respiratoryRate: respiratoryRate,
                            stepCount: stepCount,
                            updatedFlags: flags,
                            imputed: imputed)
    }

    private static func buildFeatureBundle(for metrics: DailyMetrics,
                                           summary: DailySummary,
                                           baselines: [String: BaselineMath.RobustStats],
                                           context: NSManagedObjectContext) throws -> FeatureBundle {
        var values: [String: Double] = [:]

        if let hrv = summary.hrv, let stats = baselines["hrv"] {
            values["z_hrv"] = BaselineMath.zScore(value: hrv, stats: stats)
        }
        if let nocturnal = summary.nocturnalHR, let stats = baselines["nocthr"] {
            values["z_nocthr"] = BaselineMath.zScore(value: nocturnal, stats: stats)
        }
        if let resting = summary.restingHR, let stats = baselines["resthr"] {
            values["z_resthr"] = BaselineMath.zScore(value: resting, stats: stats)
        }
        if let debt = summary.sleepDebtHours, let stats = baselines["sleepDebt"] {
            values["z_sleepDebt"] = BaselineMath.zScore(value: debt, stats: stats)
        }
        if let resp = summary.respiratoryRate, let stats = baselines["rr"] {
            values["z_rr"] = BaselineMath.zScore(value: resp, stats: stats)
        }
        if let steps = summary.stepCount, let stats = baselines["steps"] {
            values["z_steps"] = BaselineMath.zScore(value: steps, stats: stats)
        }

        let vector = try fetchOrCreateFeatureVector(in: context, date: summary.date)
        if let stress = vector.subjectiveStress?.doubleValue { values["subj_stress"] = stress }
        if let energy = vector.subjectiveEnergy?.doubleValue { values["subj_energy"] = energy }
        if let sleepQuality = vector.subjectiveSleepQuality?.doubleValue { values["subj_sleepQuality"] = sleepQuality }
        if let sentiment = vector.sentiment?.doubleValue { values["sentiment"] = sentiment }

        for key in FeatureBundle.requiredKeys where values[key] == nil {
            values[key] = 0
        }

        return FeatureBundle(values: values, imputed: summary.imputed)
    }

    private static func apply(features: [String: Double], to vector: FeatureVector) {
        vector.zHrv = NSNumber(value: features["z_hrv"] ?? 0)
        vector.zNocturnalHR = NSNumber(value: features["z_nocthr"] ?? 0)
        vector.zRestingHR = NSNumber(value: features["z_resthr"] ?? 0)
        vector.zSleepDebt = NSNumber(value: features["z_sleepDebt"] ?? 0)
        vector.zRespiratoryRate = NSNumber(value: features["z_rr"] ?? 0)
        vector.zSteps = NSNumber(value: features["z_steps"] ?? 0)
        vector.subjectiveStress = NSNumber(value: features["subj_stress"] ?? 0)
        vector.subjectiveEnergy = NSNumber(value: features["subj_energy"] ?? 0)
        vector.subjectiveSleepQuality = NSNumber(value: features["subj_sleepQuality"] ?? 0)
        vector.sentiment = NSNumber(value: features["sentiment"] ?? 0)
    }

    // MARK: - Persistence Helpers

    private static func fetchDailyMetrics(in context: NSManagedObjectContext, date: Date) throws -> DailyMetrics {
        let request = DailyMetrics.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", date as NSDate)
        request.fetchLimit = 1
        if let metrics = try context.fetch(request).first {
            return metrics
        }
        let metrics = DailyMetrics(context: context)
        metrics.date = date
        metrics.flags = Self.encodeFlags(DailyFlags())
        return metrics
    }

    private static func fetchOrCreateDailyMetrics(in context: NSManagedObjectContext, date: Date) -> DailyMetrics {
        let request = DailyMetrics.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", date as NSDate)
        request.fetchLimit = 1
        if let metrics = try? context.fetch(request).first {
            return metrics
        }
        let metrics = DailyMetrics(context: context)
        metrics.date = date
        metrics.flags = Self.encodeFlags(DailyFlags())
        return metrics
    }

    private static func fetchOrCreateFeatureVector(in context: NSManagedObjectContext, date: Date) throws -> FeatureVector {
        let request = FeatureVector.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", date as NSDate)
        request.fetchLimit = 1
        if let vector = try context.fetch(request).first {
            return vector
        }
        let vector = FeatureVector(context: context)
        vector.date = date
        return vector
    }

    private static func mutateFlags(_ metrics: DailyMetrics, mutate: (inout DailyFlags) -> Void) {
        var flags = Self.decodeFlags(from: metrics)
        mutate(&flags)
        metrics.flags = Self.encodeFlags(flags)
    }

    private static func decodeFlags(from metrics: DailyMetrics) -> DailyFlags {
        guard let payload = metrics.flags, let data = payload.data(using: .utf8) else { return DailyFlags() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(DailyFlags.self, from: data)) ?? DailyFlags()
    }

    private static func encodeFlags(_ flags: DailyFlags) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(flags) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private static func encodeFeatureMetadata(imputed: [String: Bool], contributions: [String: Double], wellbeing: Double) -> String? {
        let payload: [String: Any] = [
            "imputed": imputed,
            "contributions": contributions,
            "wellbeing": wellbeing
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func notifySnapshotUpdate(for date: Date,
                                      reason: DiagnosticsSafeString = .stage("unknown", allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"])) {
        pendingSnapshotUpdate?.cancel()
        let center = notificationCenter
        let today = calendar.startOfDay(for: Date())
        let trace = diagnosticsTraceId
        pendingSnapshotUpdate = Task { [weak self, center, trace, today, date, reason] in
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            center.post(name: .pulsumScoresUpdated,
                        object: nil,
                        userInfo: [AgentNotificationKeys.date: today])
            var fields: [String: DiagnosticsValue] = [
                "reason": .safeString(reason),
                "snapshot_day": .day(date)
            ]
            if let metadata = await self?.latestSnapshotMetadata() {
                if let day = metadata.dayString {
                    fields["latest_snapshot_day"] = .safeString(.metadata(day))
                }
                if let score = metadata.score {
                    fields["wellbeing_score"] = .double(score)
                }
            }
            Diagnostics.log(level: .info,
                            category: .dataAgent,
                            name: "data.snapshot.published",
                            fields: fields,
                            traceId: trace)
        }
    }

    private func persistBackfillProgress() {
        backfillStore.saveState(backfillProgress)
    }

    func diagnosticsBackfillCounts() async -> (warmCompleted: Int, fullCompleted: Int) {
        let warmCount = backfillProgress.warmStartCompletedTypes.count
        let fullCount = backfillProgress.fullBackfillCompletedTypes.count
        return (warmCount, fullCount)
    }

    func latestSnapshotMetadata() async -> (dayString: String?, score: Double?) {
        do {
            if let snapshot = try await latestFeatureVector() {
                let day = DiagnosticsDayFormatter.dayString(from: snapshot.date)
                return (day, snapshot.wellbeingScore)
            }
        } catch {
            return (nil, nil)
        }
        return (nil, nil)
    }

#if DEBUG
    func _testPublishSnapshotUpdate(for date: Date) {
        notifySnapshotUpdate(for: date)
    }
#endif

    private static func materializeFeatures(from vector: FeatureVector) -> FeatureBundle {
        var imputed: [String: Bool] = [:]
        if let payload = vector.imputedFlags,
           let data = payload.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let map = json["imputed"] as? [String: Bool] {
            imputed = map
        }

        let values: [String: Double] = [
            "z_hrv": vector.zHrv?.doubleValue ?? 0,
            "z_nocthr": vector.zNocturnalHR?.doubleValue ?? 0,
            "z_resthr": vector.zRestingHR?.doubleValue ?? 0,
            "z_sleepDebt": vector.zSleepDebt?.doubleValue ?? 0,
            "z_rr": vector.zRespiratoryRate?.doubleValue ?? 0,
            "z_steps": vector.zSteps?.doubleValue ?? 0,
            "subj_stress": vector.subjectiveStress?.doubleValue ?? 0,
            "subj_energy": vector.subjectiveEnergy?.doubleValue ?? 0,
            "subj_sleepQuality": vector.subjectiveSleepQuality?.doubleValue ?? 0,
            "sentiment": vector.sentiment?.doubleValue ?? 0
        ]
        return FeatureBundle(values: values, imputed: imputed)
    }

    private static func previousMetricValue(in context: NSManagedObjectContext,
                                            keyPath: String,
                                            before date: Date) throws -> Double? {
        let request = DailyMetrics.fetchRequest()
        request.predicate = NSPredicate(format: "date < %@", date as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(DailyMetrics.date), ascending: false)]
        request.fetchLimit = 1
        let metrics = try context.fetch(request)
        guard let number = (metrics.first?.value(forKey: keyPath) as? NSNumber) else { return nil }
        return number.doubleValue
    }

    private static func updateBaselines(in context: NSManagedObjectContext,
                                        summary: DailySummary,
                                        referenceDate: Date,
                                        windowDays: Int) throws -> [String: BaselineMath.RobustStats] {
        let stats = try computeBaselines(in: context, referenceDate: referenceDate, windowDays: windowDays)
        let latestValues: [String: Double?] = [
            "hrv": summary.hrv,
            "nocthr": summary.nocturnalHR,
            "resthr": summary.restingHR,
            "sleepDebt": summary.sleepDebtHours,
            "rr": summary.respiratoryRate,
            "steps": summary.stepCount
        ]

        for (metricKey, stat) in stats {
            let baseline = try fetchBaseline(in: context, metric: metricKey)
            baseline.metric = metricKey
            baseline.windowDays = Int16(windowDays)
            baseline.median = NSNumber(value: stat.median)
            baseline.mad = NSNumber(value: stat.mad)
            if let latest = latestValues[metricKey] ?? nil {
                let previous = baseline.ewma?.doubleValue
                let ewma = BaselineMath.ewma(previous: previous, newValue: latest)
                baseline.ewma = NSNumber(value: ewma)
            }
            baseline.updatedAt = referenceDate
        }

        return stats
    }

    private static func computeBaselines(in context: NSManagedObjectContext,
                                         referenceDate: Date,
                                         windowDays: Int) throws -> [String: BaselineMath.RobustStats] {
        let request = DailyMetrics.fetchRequest()
        request.predicate = NSPredicate(format: "date <= %@", referenceDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(DailyMetrics.date), ascending: false)]
        request.fetchLimit = windowDays
        let metrics = try context.fetch(request)

        func stats(_ keyPath: KeyPath<DailyMetrics, NSNumber?>) -> BaselineMath.RobustStats? {
            let values = metrics.compactMap { $0[keyPath: keyPath]?.doubleValue }
            return BaselineMath.robustStats(for: values)
        }

        var result: [String: BaselineMath.RobustStats] = [:]
        if let stats = stats(\DailyMetrics.hrvMedian) { result["hrv"] = stats }
        if let stats = stats(\DailyMetrics.nocturnalHRPercentile10) { result["nocthr"] = stats }
        if let stats = stats(\DailyMetrics.restingHR) { result["resthr"] = stats }
        if let stats = stats(\DailyMetrics.sleepDebt) { result["sleepDebt"] = stats }
        if let stats = stats(\DailyMetrics.respiratoryRate) { result["rr"] = stats }
        if let stats = stats(\DailyMetrics.steps) { result["steps"] = stats }
        return result
    }

    private static func fetchBaseline(in context: NSManagedObjectContext, metric: String) throws -> Baseline {
        let request = Baseline.fetchRequest()
        request.predicate = NSPredicate(format: "metric == %@", metric)
        request.fetchLimit = 1
        if let baseline = try context.fetch(request).first {
            return baseline
        }
        let baseline = Baseline(context: context)
        baseline.metric = metric
        baseline.windowDays = 0
        return baseline
    }

    private static func personalizedSleepNeedHours(context: NSManagedObjectContext,
                                                   referenceDate: Date,
                                                   latestActualHours: Double,
                                                   windowDays: Int) throws -> Double {
        let request = DailyMetrics.fetchRequest()
        request.predicate = NSPredicate(format: "date <= %@", referenceDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(DailyMetrics.date), ascending: false)]
        request.fetchLimit = windowDays
        let metrics = try context.fetch(request)
        let historical = metrics.compactMap { $0.totalSleepTime?.doubleValue }.map { $0 / 3600 }
        let defaultNeed = 7.5
        guard historical.count >= 7 else { return defaultNeed }
        let mean = historical.reduce(0, +) / Double(historical.count)
        return min(max(mean, defaultNeed - 0.75), defaultNeed + 0.75)
    }

    private static func sleepDebtHours(context: NSManagedObjectContext,
                                       personalNeed: Double,
                                       currentHours: Double?,
                                       referenceDate: Date,
                                       windowDays: Int,
                                       calendar: Calendar) throws -> Double? {
        guard let currentHours else { return nil }
        let start = calendar.date(byAdding: .day, value: -(windowDays - 1), to: referenceDate) ?? referenceDate
        let request = DailyMetrics.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", start as NSDate, referenceDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(DailyMetrics.date), ascending: true)]
        let metrics = try context.fetch(request)
        var window = metrics.map { ($0.totalSleepTime?.doubleValue ?? 0) / 3600 }
        if metrics.last?.date != referenceDate {
            window.append(currentHours)
        }
        return window.map { max(0, personalNeed - $0) }.reduce(0, +)
    }

    private struct ScoreMetricDescriptor {
        let featureKey: String
        let displayName: String
        let kind: ScoreBreakdown.MetricDetail.Kind
        let order: Int
        let unit: String?
        let usesZScore: Bool
        let rawValueKey: String?
        let baselineKey: String?
        let rollingWindowDays: Int?
        let explanation: String
        let flagKeys: [String]

        func flagMessages(for flags: [String: Bool]) -> [String] {
            flagKeys.compactMap { key in
                guard flags[key] == true else { return nil }
                return DataAgent.flagMessages[key]
            }
        }
    }

    private static let scoreMetricDescriptors: [ScoreMetricDescriptor] = [
        ScoreMetricDescriptor(
            featureKey: "z_hrv",
            displayName: "Heart Rate Variability",
            kind: .objective,
            order: 0,
            unit: "ms",
            usesZScore: true,
            rawValueKey: "hrv",
            baselineKey: "hrv",
            rollingWindowDays: 30,
            explanation: "Median overnight SDNN. Higher values mean the autonomic nervous system is more recovered.",
            flagKeys: ["hrv", "sedentary_missing"]
        ),
        ScoreMetricDescriptor(
            featureKey: "z_nocthr",
            displayName: "Nocturnal Heart Rate",
            kind: .objective,
            order: 1,
            unit: "bpm",
            usesZScore: true,
            rawValueKey: "nocthr",
            baselineKey: "nocthr",
            rollingWindowDays: 30,
            explanation: "10th percentile of heart rate while asleep. Lower values indicate better overnight recovery.",
            flagKeys: ["nocturnalHR", "sedentary_missing"]
        ),
        ScoreMetricDescriptor(
            featureKey: "z_resthr",
            displayName: "Resting Heart Rate",
            kind: .objective,
            order: 2,
            unit: "bpm",
            usesZScore: true,
            rawValueKey: "resthr",
            baselineKey: "resthr",
            rollingWindowDays: 30,
            explanation: "Latest resting heart rate sample. Lower relative to baseline typically reflects parasympathetic dominance.",
            flagKeys: ["restingHR", "sedentary_missing"]
        ),
        ScoreMetricDescriptor(
            featureKey: "z_sleepDebt",
            displayName: "Sleep Debt",
            kind: .objective,
            order: 3,
            unit: "h",
            usesZScore: true,
            rawValueKey: "sleepDebt",
            baselineKey: "sleepDebt",
            rollingWindowDays: 7,
            explanation: "Cumulative sleep debt over the past 7 days vs your personalized sleep need.",
            flagKeys: ["sleep_low_confidence", "sleepDebt_missing"]
        ),
        ScoreMetricDescriptor(
            featureKey: "z_rr",
            displayName: "Respiratory Rate",
            kind: .objective,
            order: 4,
            unit: "breaths/min",
            usesZScore: true,
            rawValueKey: "rr",
            baselineKey: "rr",
            rollingWindowDays: 30,
            explanation: "Average sleeping respiratory rate. Stable values indicate steady recovery.",
            flagKeys: ["rr_missing"]
        ),
        ScoreMetricDescriptor(
            featureKey: "z_steps",
            displayName: "Steps",
            kind: .objective,
            order: 5,
            unit: "steps",
            usesZScore: true,
            rawValueKey: "steps",
            baselineKey: "steps",
            rollingWindowDays: 30,
            explanation: "Total steps captured today relative to your rolling baseline.",
            flagKeys: ["steps_missing", "steps_low_confidence"]
        ),
        ScoreMetricDescriptor(
            featureKey: "subj_stress",
            displayName: "Stress",
            kind: .subjective,
            order: 6,
            unit: "(1-7)",
            usesZScore: false,
            rawValueKey: nil,
            baselineKey: nil,
            rollingWindowDays: nil,
            explanation: "Self-reported stress level captured in today's pulse check.",
            flagKeys: []
        ),
        ScoreMetricDescriptor(
            featureKey: "subj_energy",
            displayName: "Energy",
            kind: .subjective,
            order: 7,
            unit: "(1-7)",
            usesZScore: false,
            rawValueKey: nil,
            baselineKey: nil,
            rollingWindowDays: nil,
            explanation: "Self-reported energy level from today's pulse check.",
            flagKeys: []
        ),
        ScoreMetricDescriptor(
            featureKey: "subj_sleepQuality",
            displayName: "Sleep Quality",
            kind: .subjective,
            order: 8,
            unit: "(1-7)",
            usesZScore: false,
            rawValueKey: nil,
            baselineKey: nil,
            rollingWindowDays: nil,
            explanation: "Perceived sleep quality for the prior night.",
            flagKeys: []
        ),
        ScoreMetricDescriptor(
            featureKey: "sentiment",
            displayName: "Journal Sentiment",
            kind: .sentiment,
            order: 9,
            unit: nil,
            usesZScore: false,
            rawValueKey: nil,
            baselineKey: nil,
            rollingWindowDays: nil,
            explanation: "On-device sentiment score from your latest journal entry (negative to positive).",
            flagKeys: []
        )
    ]

    private static let flagMessages: [String: String] = [
        "hrv": "HRV carried forward from a previous day because no fresh overnight samples were available.",
        "sedentary_missing": "No restful sedentary window detected today; fallbacks were used for recovery metrics.",
        "nocturnalHR": "No nocturnal heart rate samples during sleep; carried forward the last reliable value.",
        "restingHR": "Resting heart rate sample missing; reused the most recent reliable value.",
        "rr_missing": "Sleeping respiratory rate missing, so this signal is omitted today.",
        "steps_missing": "Step data unavailable; activity impact excluded from today's score.",
        "steps_low_confidence": "Very low step count (<500) flagged as low confidence.",
        "sleep_low_confidence": "Less than 3 hours of sleep recorded; sleep-related calculations are low confidence.",
        "sleepDebt_missing": "No sleep data available; sleep debt is omitted from today's score."
    ]

    private static func generalFlagMessages(for flags: [String: Bool]) -> [String] {
        let handledKeys = Set(scoreMetricDescriptors.flatMap { $0.flagKeys })
        return flags.compactMap { key, value in
            guard value, !handledKeys.contains(key) else { return nil }
            return flagMessages[key]
        }
    }
#if DEBUG
    func _testProcessQuantitySamples(_ samples: [HKQuantitySample], type: HKQuantityType) async throws {
        _ = try await processQuantitySamples(samples, type: type)
    }

    func _testProcessCategorySamples(_ samples: [HKCategorySample], type: HKCategoryType) async throws {
        _ = try await processCategorySamples(samples, type: type)
    }

    func _testReprocess(day: Date) async throws {
        try await reprocessDayInternal(day)
    }

    @discardableResult
    func _testUpdateEstimator(features: [String: Double], imputed: [String: Bool] = [:]) -> StateEstimatorSnapshot {
        let normalized = WellbeingModeling.normalize(features: features, imputedFlags: imputed)
        let target = WellbeingModeling.target(for: normalized)
        let snapshot = stateEstimator.update(features: normalized, target: target)
        persistEstimatorState(from: snapshot)
        return snapshot
    }

    func _testEstimatorState() -> StateEstimatorState {
        stateEstimator.persistedState(version: EstimatorStateStore.schemaVersion)
    }

    func _testBackfillProgress() -> BackfillProgress {
        backfillProgress
    }

    func _testRunFullBackfillNow(targetStartDate: Date? = nil, grantedTypes: Set<HKSampleType>? = nil) async {
        let today = calendar.startOfDay(for: Date())
        let target = targetStartDate ?? calendar.date(byAdding: .day, value: -(fullAnalysisWindowDays - 1), to: today) ?? today
        let types = grantedTypes ?? Set(requiredSampleTypes)
        await performBackgroundFullBackfill(grantedTypes: types, targetStartDate: target)
    }
#endif
}

enum WellbeingModeling {
    static let targetWeights: [String: Double] = [
        "z_hrv": 0.55,
        "z_nocthr": -0.4,
        "z_resthr": -0.35,
        "z_sleepDebt": -0.65,
        "z_steps": 0.32,
        "z_rr": -0.1,
        "subj_stress": -0.4,
        "subj_energy": 0.45,
        "subj_sleepQuality": 0.3,
        "sentiment": 0.22
    ]

    static func normalize(features: [String: Double], imputedFlags: [String: Bool]) -> [String: Double] {
        var normalized: [String: Double] = [:]
        for key in FeatureBundle.requiredKeys {
            let raw = features[key] ?? 0
            normalized[key] = normalizedValue(for: key, value: raw, imputedFlags: imputedFlags)
        }
        return normalized
    }

    static func target(for normalizedFeatures: [String: Double]) -> Double {
        var target = 0.0
        for (feature, weight) in targetWeights {
            target += weight * (normalizedFeatures[feature] ?? 0)
        }
        return clamp(target, limit: 2.5)
    }

    private static func normalizedValue(for key: String, value: Double, imputedFlags: [String: Bool]) -> Double {
        let adjusted = adjustForImputation(key: key, value: value, imputedFlags: imputedFlags)
        switch key {
        case let feature where feature.hasPrefix("z_"):
            return clamp(adjusted, limit: 3)
        case "subj_stress", "subj_energy", "subj_sleepQuality":
            let centered = (adjusted - 4.0) / 3.0
            return clamp(centered, limit: 1)
        case "sentiment":
            return clamp(adjusted, limit: 1)
        default:
            return adjusted
        }
    }

    private static func adjustForImputation(key: String, value: Double, imputedFlags: [String: Bool]) -> Double {
        var adjusted = value

        switch key {
        case "z_hrv", "z_nocthr", "z_resthr":
            if imputedFlags["sedentary_missing"] == true {
                adjusted *= 0.5
            }
        case "z_sleepDebt":
            if imputedFlags["sleep_low_confidence"] == true {
                adjusted = 0
            }
        case "z_rr":
            if imputedFlags["rr_missing"] == true {
                adjusted = 0
            }
        case "z_steps":
            if imputedFlags["steps_missing"] == true {
                adjusted = 0
            } else if imputedFlags["steps_low_confidence"] == true {
                adjusted *= 0.5
            }
        default:
            break
        }

        let missingKey = key.replacingOccurrences(of: "z_", with: "") + "_missing"
        if imputedFlags[missingKey] == true {
            adjusted = 0
        }

        return adjusted
    }

    private static func clamp(_ value: Double, limit: Double) -> Double {
        min(max(value, -limit), limit)
    }
}

// MARK: - Supporting Types

private struct FeatureBundle {
    static let requiredKeys: Set<String> = [
        "z_hrv",
        "z_nocthr",
        "z_resthr",
        "z_sleepDebt",
        "z_rr",
        "z_steps",
        "subj_stress",
        "subj_energy",
        "subj_sleepQuality",
        "sentiment"
    ]

    var values: [String: Double]
    var imputed: [String: Bool]
}

private struct FeatureComputation: Sendable {
    let date: Date
    let featureValues: [String: Double]
    let imputedFlags: [String: Bool]
    let featureVectorObjectID: NSManagedObjectID
}

private struct DailySummary {
    let date: Date
    let hrv: Double?
    let nocturnalHR: Double?
    let restingHR: Double?
    let totalSleepSeconds: Double?
    let sleepNeedHours: Double
    let sleepDebtHours: Double?
    let respiratoryRate: Double?
    let stepCount: Double?
    let updatedFlags: DailyFlags
    let imputed: [String: Bool]
}

private struct DailyFlags: Codable {
    var aggregatedStepTotal: Double?
    var aggregatedNocturnalAverage: Double?
    var aggregatedNocturnalMin: Double?
    var aggregatedSleepDurationSeconds: Double?
    var hrvSamples: [HRVSample] = []
    var heartRateSamples: [HeartRateSample] = []
    var respiratorySamples: [RespiratorySample] = []
    var sleepSegments: [SleepSegment] = []
    var stepBuckets: [StepBucket] = []

    mutating func append(quantitySample sample: HKQuantitySample, type: HKQuantityType) {
        switch type.identifier {
        case HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue:
            hrvSamples.append(HRVSample(sample))
            hrvSamples.trim(to: 512)
        case HKQuantityTypeIdentifier.heartRate.rawValue:
            heartRateSamples.append(HeartRateSample(sample))
            heartRateSamples.trim(to: 4096)
        case HKQuantityTypeIdentifier.restingHeartRate.rawValue:
            heartRateSamples.append(HeartRateSample(sample, context: .resting))
            heartRateSamples.trim(to: 4096)
        case HKQuantityTypeIdentifier.respiratoryRate.rawValue:
            respiratorySamples.append(RespiratorySample(sample))
            respiratorySamples.trim(to: 512)
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            stepBuckets.append(StepBucket(sample))
            stepBuckets.trim(to: 4096)
        default:
            break
        }
    }

    mutating func append(sleepSample sample: HKCategorySample) -> Bool {
        let segment = SleepSegment(sample)
        guard !sleepSegments.contains(where: { $0.id == segment.id }) else { return false }
        sleepSegments.append(segment)
        sleepSegments.trim(to: 256)
        if segment.stage.isAsleep {
            aggregatedSleepDurationSeconds = (aggregatedSleepDurationSeconds ?? 0) + segment.duration
        }
        return true
    }

    mutating func removeSample(with uuid: UUID) {
        hrvSamples.removeAll { $0.id == uuid }
        heartRateSamples.removeAll { $0.id == uuid }
        respiratorySamples.removeAll { $0.id == uuid }
        sleepSegments.removeAll { $0.id == uuid }
        stepBuckets.removeAll { $0.id == uuid }
    }

    mutating func pruneDeletedSamples(_ identifiers: Set<UUID>) -> Bool {
        let originalCounts = (hrvSamples.count, heartRateSamples.count, respiratorySamples.count, sleepSegments.count, stepBuckets.count)
        hrvSamples.removeAll { identifiers.contains($0.id) }
        heartRateSamples.removeAll { identifiers.contains($0.id) }
        respiratorySamples.removeAll { identifiers.contains($0.id) }
        sleepSegments.removeAll { identifiers.contains($0.id) }
        stepBuckets.removeAll { identifiers.contains($0.id) }
        let updatedCounts = (hrvSamples.count, heartRateSamples.count, respiratorySamples.count, sleepSegments.count, stepBuckets.count)
        return originalCounts != updatedCounts
    }

    // Computations
    func sleepIntervals() -> [DateInterval] {
        sleepSegments
            .filter { $0.stage.isAsleep }
            .map { DateInterval(start: $0.start, end: $0.end) }
    }

    func sedentaryIntervals(thresholdStepsPerHour: Double,
                            minimumDuration: TimeInterval,
                            excluding sleep: [DateInterval]) -> [DateInterval] {
        guard !stepBuckets.isEmpty else { return [] }
        let sorted = stepBuckets.sorted { $0.start < $1.start }
        var intervals: [DateInterval] = []
        var currentStart: Date?
        var currentEnd: Date?
        var totalSteps: Double = 0

        func finalize() {
            guard let start = currentStart, let end = currentEnd else { return }
            let duration = end.timeIntervalSince(start)
            guard duration >= minimumDuration else { reset() ; return }
            let stepsPerHour = totalSteps / max(duration / 3600, 0.001)
            guard stepsPerHour <= thresholdStepsPerHour else { reset(); return }
            let candidate = DateInterval(start: start, end: end)
            if !candidate.intersectsAny(of: sleep) {
                intervals.append(candidate)
            }
            reset()
        }

        func reset() {
            currentStart = nil
            currentEnd = nil
            totalSteps = 0
        }

        var previousEnd: Date?
        for bucket in sorted {
            if currentStart == nil { currentStart = bucket.start }
            if let prev = previousEnd, bucket.start.timeIntervalSince(prev) > 300 {
                finalize()
                currentStart = bucket.start
            }
            previousEnd = bucket.end
            currentEnd = max(currentEnd ?? bucket.end, bucket.end)
            totalSteps += bucket.steps
        }
        finalize()
        return intervals
    }

    func sleepDurations() -> Double? {
        if let aggregatedSleepDurationSeconds {
            return aggregatedSleepDurationSeconds
        }
        let asleep = sleepSegments.filter { $0.stage.isAsleep }
        guard !asleep.isEmpty else { return nil }
        return asleep.reduce(0) { $0 + $1.duration }
    }

    func medianHRV(in intervals: [DateInterval],
                   fallback: [DateInterval],
                   previous: Double?,
                   imputed: inout [String: Bool]) -> Double? {
        if let median = median(samples: hrvSamples, within: intervals) {
            return median
        }
        if let median = median(samples: hrvSamples, within: fallback) {
            return median
        }
        if let previous { imputed["hrv"] = true; return previous }
        return nil
    }

    func nocturnalHeartRate(in intervals: [DateInterval],
                            fallback: [DateInterval],
                            previous: Double?,
                            imputed: inout [String: Bool]) -> Double? {
        if let aggregatedNocturnalAverage {
            return aggregatedNocturnalAverage
        }
        if let percentile = percentile(samples: heartRateSamples, within: intervals, percentile: 0.10) {
            return percentile
        }
        if let percentile = percentile(samples: heartRateSamples, within: fallback, percentile: 0.10) {
            return percentile
        }
        if let previous { imputed["nocturnalHR"] = true; return previous }
        return nil
    }

    func restingHeartRate(fallback: [DateInterval],
                          previous: Double?,
                          imputed: inout [String: Bool]) -> Double? {
        if let latest = heartRateSamples.last(where: { $0.context == .resting }) {
            return latest.value
        }
        if let average = average(samples: heartRateSamples, within: fallback) {
            return average
        }
        if let previous { imputed["restingHR"] = true; return previous }
        return nil
    }

    func averageRespiratoryRate(in intervals: [DateInterval]) -> Double? {
        guard !respiratorySamples.isEmpty else { return nil }
        if intervals.isEmpty { return respiratorySamples.map { $0.value }.mean }
        let filtered = respiratorySamples.filter { sample in intervals.contains { $0.contains(sample.time) } }
        guard !filtered.isEmpty else { return nil }
        return filtered.map { $0.value }.mean
    }

    func totalSteps() -> Double? {
        if let aggregatedStepTotal {
            return aggregatedStepTotal
        }
        guard !stepBuckets.isEmpty else { return nil }
        return stepBuckets.reduce(0) { $0 + $1.steps }
    }

    // MARK: - Statistics helpers

    private func median<T: TimedSample>(samples: [T], within intervals: [DateInterval]) -> Double? {
        guard !samples.isEmpty else { return nil }
        let filtered = samples.filter { sample in intervals.contains { $0.contains(sample.time) } }
        guard !filtered.isEmpty else { return nil }
        let values = filtered.map { $0.value }.sorted()
        let mid = values.count / 2
        if values.count % 2 == 0 { return (values[mid - 1] + values[mid]) / 2 }
        return values[mid]
    }

    private func percentile<T: TimedSample>(samples: [T], within intervals: [DateInterval], percentile: Double) -> Double? {
        guard !samples.isEmpty else { return nil }
        let filtered = samples.filter { sample in intervals.contains { $0.contains(sample.time) } }
        guard !filtered.isEmpty else { return nil }
        let sorted = filtered.map { $0.value }.sorted()
        let index = max(0, Int(Double(sorted.count - 1) * percentile))
        return sorted[index]
    }

    private func average<T: TimedSample>(samples: [T], within intervals: [DateInterval]) -> Double? {
        guard !samples.isEmpty else { return nil }
        let filtered = samples.filter { sample in intervals.contains { $0.contains(sample.time) } }
        guard !filtered.isEmpty else { return nil }
        return filtered.map { $0.value }.mean
    }
}

// MARK: - Sample Models

private protocol TimedSample {
    var id: UUID { get }
    var time: Date { get }
    var value: Double { get }
}

private struct HRVSample: Codable, TimedSample {
    let id: UUID
    let time: Date
    let value: Double

    init(_ sample: HKQuantitySample) {
        id = sample.uuid
        time = sample.startDate
        value = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
    }
}

private struct HeartRateSample: Codable, TimedSample {
    enum Context: String, Codable { case normal, resting }
    let id: UUID
    let time: Date
    let value: Double
    let context: Context

    init(_ sample: HKQuantitySample, context: Context = .normal) {
        id = sample.uuid
        time = sample.startDate
        value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
        self.context = context
    }
}

private struct RespiratorySample: Codable, TimedSample {
    let id: UUID
    let time: Date
    let value: Double

    init(_ sample: HKQuantitySample) {
        id = sample.uuid
        time = sample.startDate
        value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
    }
}

private struct SleepSegment: Codable {
    enum Stage: String, Codable {
        case inBed
        case asleepCore
        case asleepDeep
        case asleepREM
        case asleepUnspecified
        case awake

        var isAsleep: Bool {
            switch self {
            case .asleepCore, .asleepDeep, .asleepREM, .asleepUnspecified:
                return true
            default:
                return false
            }
        }
    }

    let id: UUID
    let start: Date
    let end: Date
    let stage: Stage

    var duration: TimeInterval { max(0, end.timeIntervalSince(start)) }

    init(_ sample: HKCategorySample) {
        id = sample.uuid
        start = sample.startDate
        end = sample.endDate
        let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) ?? .inBed
        switch value {
        case .inBed: stage = .inBed
        case .asleepUnspecified: stage = .asleepUnspecified
        case .awake: stage = .awake
        case .asleepCore: stage = .asleepCore
        case .asleepDeep: stage = .asleepDeep
        case .asleepREM: stage = .asleepREM
        @unknown default: stage = .asleepUnspecified
        }
    }
}

private struct StepBucket: Codable {
    let id: UUID
    let start: Date
    let end: Date
    let steps: Double

    init(_ sample: HKQuantitySample) {
        id = sample.uuid
        start = sample.startDate
        end = sample.endDate
        steps = sample.quantity.doubleValue(for: HKUnit.count())
    }
}

// MARK: - Utilities

private extension Array {
    mutating func trim(to limit: Int) {
        guard count > limit else { return }
        removeFirst(count - limit)
    }
}

private extension Array where Element == Double {
    var mean: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}

private extension Array where Element == DateInterval {
    func contains(where predicate: (DateInterval) -> Bool) -> Bool {
        for interval in self where predicate(interval) { return true }
        return false
    }

    func contains(_ date: Date) -> Bool {
        contains { $0.contains(date) }
    }

    func intersectsAny(of other: [DateInterval]) -> Bool {
        for interval in self {
            if other.contains(where: { $0.intersects(interval) }) { return true }
        }
        return false
    }
}

private extension DateInterval {
    func intersectsAny(of intervals: [DateInterval]) -> Bool {
        intervals.contains { $0.intersects(self) }
    }
}
