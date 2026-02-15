import Foundation
import SwiftData
import HealthKit
import PulsumData
import PulsumML
import PulsumServices
import PulsumTypes

actor DataAgent: ModelActor {
    nonisolated let modelExecutor: any ModelExecutor
    nonisolated let modelContainer: ModelContainer

    let healthKit: any HealthKitServicing
    let calendar: Calendar
    let estimatorStore: EstimatorStateStoring
    var stateEstimator: StateEstimator
    var observers: [String: HealthKitObservationToken] = [:]
    let requiredSampleTypes: [HKSampleType]
    let sampleTypesByIdentifier: [String: HKSampleType]
    let notificationCenter: NotificationCenter
    let backfillStore: BackfillStateStoring
    var backfillProgress: BackfillProgress
    var pendingSnapshotUpdate: Task<Void, Never>?
    var warmStartBackfillTask: Task<Void, Never>?
    var fullBackfillTask: Task<Void, Never>?
    let bootstrapPolicy: DataAgentBootstrapPolicy
    var bootstrapWatchdogTask: Task<Void, Never>?
    var bootstrapRetryTask: Task<Void, Never>?
    var bootstrapRetryAttempt = 0
    var bootstrapRetryStart: Date?
    var pendingBootstrapRetryIdentifiers: Set<String> = []
    var cachedReadAccess: (timestamp: Date, results: [String: ReadAuthorizationProbeResult])?
    let readProbeCacheTTL: TimeInterval = 30
    var diagnosticsTraceId: UUID?
    var lastAuthorizationRequestStatus: HKAuthorizationRequestStatus?
    lazy var baselineCalc: BaselineCalculator = BaselineCalculator(modelContext: modelContext, calendar: calendar)

    // Phase 1: small foreground window for fast first score; Phase 2: full context restored in background.
    let warmStartWindowDays = 7
    let fullAnalysisWindowDays = 30
    let bootstrapWindowDays = 2
    let sleepDebtWindowDays = 7
    let backgroundBackfillBatchDays = 5
    let sedentaryThresholdStepsPerHour: Double = 30
    let sedentaryMinimumDuration: TimeInterval = 30 * 60

    init(modelContainer: ModelContainer,
         storagePaths: StoragePaths,
         healthKit: (any HealthKitServicing)? = nil,
         notificationCenter: NotificationCenter = .default,
         calendar: Calendar = Calendar(identifier: .gregorian),
         estimatorStore: EstimatorStateStoring? = nil,
         backfillStore: BackfillStateStoring? = nil,
         bootstrapPolicy: DataAgentBootstrapPolicy = .default) {
        let modelContext = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
        self.modelContainer = modelContainer
        self.healthKit = healthKit ?? HealthKitService(
            anchorStore: HealthKitAnchorStore(directory: storagePaths.healthAnchorsDirectory)
        )
        self.calendar = calendar
        self.estimatorStore = estimatorStore ?? EstimatorStateStore(baseDirectory: storagePaths.applicationSupport)
        self.backfillStore = backfillStore ?? BackfillStateStore(baseDirectory: storagePaths.applicationSupport)
        self.bootstrapPolicy = bootstrapPolicy
        self.stateEstimator = StateEstimator()
        self.notificationCenter = notificationCenter
        self.requiredSampleTypes = HealthKitService.orderedReadSampleTypes
        var dictionary: [String: HKSampleType] = [:]
        for type in requiredSampleTypes {
            dictionary[type.identifier] = type
        }
        self.sampleTypesByIdentifier = dictionary

        if let persistedBackfill = self.backfillStore.loadState() {
            self.backfillProgress = persistedBackfill
        } else {
            self.backfillProgress = BackfillProgress()
        }

        if let persisted = self.estimatorStore.loadState() {
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
        // Avoid prompting at startup; defer requests to explicit user actions.
        invalidateReadAccessCache()
        let refreshedStatus = await currentHealthAccessStatus()
        scheduleBootstrapWatchdog(for: refreshedStatus)
        await bootstrapFirstScore(for: refreshedStatus)
        try await configureObservation(for: refreshedStatus, resetRevokedAnchors: true)
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
        scheduleBootstrapWatchdog(for: status)
        await bootstrapFirstScore(for: status)
        try await configureObservation(for: status, resetRevokedAnchors: true)
        scheduleBackfill(for: status)
        return status
    }

    @discardableResult
    func requestHealthAccess() async throws -> HealthAccessStatus {
        try await healthKit.requestAuthorization()
        invalidateReadAccessCache()
        let status = await currentHealthAccessStatus()
        await DebugLogBuffer.shared.append("requestHealthAccess refreshed status: \(statusSummary(status))")
        scheduleBootstrapWatchdog(for: status)
        await bootstrapFirstScore(for: status)
        try await configureObservation(for: status, resetRevokedAnchors: true)
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
        lastAuthorizationRequestStatus = requestStatus

        if requestStatus == .shouldRequest || requestStatus == nil {
            pending = Set(requiredSampleTypes)
        } else {
            probeResults = await readAuthorizationProbeResults()
            for type in requiredSampleTypes {
                // `authorizationStatus(for:)` reflects sharing (write) permission, not read access.
                // For read-only authorization, rely on the probe result.
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

    func logDiagnostics(level: DiagnosticsLevel,
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

    func reprocessDay(date: Date) async throws {
        let day = calendar.startOfDay(for: date)
        try await reprocessDayInternal(day)
        notifySnapshotUpdate(for: day,
                             reason: .stage("reprocess",
                                            allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]))
    }

    func recordSubjectiveInputs(date: Date, stress: Double, energy: Double, sleepQuality: Double) async throws {
        let targetDate = calendar.startOfDay(for: date)
        let dayString = DiagnosticsDayFormatter.dayString(from: targetDate)
        await DebugLogBuffer.shared.append("Recording subjective inputs for day=\(dayString)")
        let fetchDate = targetDate
        var descriptor = FetchDescriptor<FeatureVector>(predicate: #Predicate { $0.date == fetchDate })
        descriptor.fetchLimit = 1
        let vector: FeatureVector
        if let existing = try modelContext.fetch(descriptor).first {
            vector = existing
        } else {
            vector = FeatureVector(date: targetDate)
            modelContext.insert(vector)
        }
        vector.date = targetDate
        vector.subjectiveStress = stress
        vector.subjectiveEnergy = energy
        vector.subjectiveSleepQuality = sleepQuality
        try modelContext.save()
        try await reprocessDayInternal(targetDate)
        notifySnapshotUpdate(for: targetDate,
                             reason: .stage("reprocess",
                                            allowed: ["bootstrap", "warm_backfill", "full_backfill", "journal", "reprocess", "refresh", "unknown"]))
    }

    // MARK: - Observation

    func fetchDailyMetrics(date: Date) throws -> DailyMetrics {
        let targetDate = date
        var descriptor = FetchDescriptor<DailyMetrics>(predicate: #Predicate { $0.date == targetDate })
        descriptor.fetchLimit = 1
        if let metrics = try modelContext.fetch(descriptor).first {
            return metrics
        }
        let metrics = DailyMetrics(date: date, flags: Self.encodeFlags(DailyFlags()))
        modelContext.insert(metrics)
        return metrics
    }

    func fetchOrCreateDailyMetrics(date: Date) -> DailyMetrics {
        let targetDate = date
        var descriptor = FetchDescriptor<DailyMetrics>(predicate: #Predicate { $0.date == targetDate })
        descriptor.fetchLimit = 1
        if let metrics = try? modelContext.fetch(descriptor).first {
            return metrics
        }
        let metrics = DailyMetrics(date: date, flags: Self.encodeFlags(DailyFlags()))
        modelContext.insert(metrics)
        return metrics
    }

    static func mutateFlags(_ metrics: DailyMetrics, mutate: (inout DailyFlags) -> Void) {
        var flags = Self.decodeFlags(from: metrics)
        mutate(&flags)
        metrics.flags = Self.encodeFlags(flags)
    }

    static func decodeFlags(from metrics: DailyMetrics) -> DailyFlags {
        guard let payload = metrics.flags, let data = payload.data(using: .utf8) else { return DailyFlags() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(DailyFlags.self, from: data)) ?? DailyFlags()
    }

    static func encodeFlags(_ flags: DailyFlags) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(flags) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    func notifySnapshotUpdate(for date: Date,
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
            if let details = await self?.latestSnapshotDiagnostics() {
                if let day = details.dayString {
                    fields["latest_snapshot_day"] = .safeString(.metadata(day))
                }
                if let score = details.score {
                    fields["wellbeing_score"] = .double(score)
                }
                fields["placeholder"] = .bool(details.placeholder)
            }
            Diagnostics.log(level: .info,
                            category: .dataAgent,
                            name: "data.snapshot.published",
                            fields: fields,
                            traceId: trace)
        }
    }

    func persistBackfillProgress() {
        backfillStore.saveState(backfillProgress)
    }

    func diagnosticsBackfillCounts() async -> (warmCompleted: Int, fullCompleted: Int) {
        let warmCount = backfillProgress.warmStartCompletedTypes.count
        let fullCount = backfillProgress.fullBackfillCompletedTypes.count
        return (warmCount, fullCount)
    }

    func latestSnapshotMetadata() async -> (dayString: String?, score: Double?) {
        let details = await latestSnapshotDiagnostics()
        return (details.dayString, details.score)
    }

    private func latestSnapshotDiagnostics() async -> (dayString: String?, score: Double?, placeholder: Bool) {
        do {
            if let snapshot = try await latestFeatureVector() {
                let day = DiagnosticsDayFormatter.dayString(from: snapshot.date)
                return (day, snapshot.wellbeingScore, SnapshotPlaceholder.isPlaceholder(snapshot))
            }
        } catch {
            return (nil, nil, false)
        }
        return (nil, nil, false)
    }

    #if DEBUG
    func _testPublishSnapshotUpdate(for date: Date) {
        notifySnapshotUpdate(for: date)
    }
    #endif

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
    func _testUpdateEstimator(features: [String: Double], imputed: [String: Bool] = [:]) async -> StateEstimatorSnapshot {
        let normalized = WellbeingModeling.normalize(features: features, imputedFlags: imputed)
        let target = WellbeingModeling.target(for: normalized)
        let snapshot = await stateEstimator.update(features: normalized, target: target)
        persistEstimatorState(from: snapshot)
        return snapshot
    }

    func _testEstimatorState() async -> StateEstimatorState {
        await stateEstimator.persistedState(version: EstimatorStateStore.schemaVersion)
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
