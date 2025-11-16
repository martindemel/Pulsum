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
    }

    public let date: Date
    public let wellbeingScore: Double
    public let metrics: [MetricDetail]
    public let generalNotes: [String]
}

actor DataAgent {
    private let healthKit: any HealthKitServicing
    private let calendar = Calendar(identifier: .gregorian)
    private var stateEstimator = StateEstimator()
    private let context: NSManagedObjectContext
    private var observers: [String: HealthKitObservationToken] = [:]
    private let requiredSampleTypes: [HKSampleType]
    private let sampleTypesByIdentifier: [String: HKSampleType]
    private var cachedHealthAccessStatus: HealthAccessStatus?
    private let notificationCenter: NotificationCenter

    private let analysisWindowDays = 30
    private let sleepDebtWindowDays = 7
    private let sedentaryThresholdStepsPerHour: Double = 30
    private let sedentaryMinimumDuration: TimeInterval = 30 * 60

    init(healthKit: any HealthKitServicing = PulsumServices.healthKit,
         container: NSPersistentContainer = PulsumData.container,
         notificationCenter: NotificationCenter = .default) {
        self.healthKit = healthKit
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
        self.cachedHealthAccessStatus = nil
    }

    // MARK: - Lifecycle

    func start() async throws {
        let initialStatus = await currentHealthAccessStatus()
        try await configureObservation(for: initialStatus, resetRevokedAnchors: false)

        guard !initialStatus.notDetermined.isEmpty else { return }

        try await healthKit.requestAuthorization()
        _ = try await startIngestionIfAuthorized()
    }

    @discardableResult
    func startIngestionIfAuthorized() async throws -> HealthAccessStatus {
        let status = await currentHealthAccessStatus()
        try await configureObservation(for: status, resetRevokedAnchors: false)
        return status
    }

    @discardableResult
    func restartIngestionAfterPermissionsChange() async throws -> HealthAccessStatus {
        let status = await currentHealthAccessStatus()
        try await configureObservation(for: status, resetRevokedAnchors: true)
        return status
    }

    @discardableResult
    func requestHealthAccess() async throws -> HealthAccessStatus {
        try await healthKit.requestAuthorization()
        return try await restartIngestionAfterPermissionsChange()
    }

    func currentHealthAccessStatus() async -> HealthAccessStatus {
        if !healthKit.isHealthDataAvailable {
            let unavailable = HealthAccessStatus(required: requiredSampleTypes,
                                                 granted: [],
                                                 denied: [],
                                                 notDetermined: [],
                                                 availability: .unavailable(reason: "Health data is not available on this device."))
            cachedHealthAccessStatus = unavailable
            return unavailable
        }

        var granted: Set<HKSampleType> = []
        var denied: Set<HKSampleType> = []
        var pending: Set<HKSampleType> = []

        for type in requiredSampleTypes {
            switch healthKit.authorizationStatus(for: type) {
            case .sharingAuthorized:
                granted.insert(type)
            case .sharingDenied:
                denied.insert(type)
            case .notDetermined:
                pending.insert(type)
            @unknown default:
                pending.insert(type)
            }
        }

        let status = HealthAccessStatus(required: requiredSampleTypes,
                                        granted: granted,
                                        denied: denied,
                                        notDetermined: pending,
                                        availability: .available)
        cachedHealthAccessStatus = status
        return status
    }

    private func shouldIgnoreBackgroundDeliveryError(_ error: Error) -> Bool {
        let message = (error as NSError).localizedDescription
        return message.contains("Missing com.apple.developer.healthkit.background-delivery")
    }

    private func configureObservation(for status: HealthAccessStatus,
                                      resetRevokedAnchors: Bool) async throws {
        cachedHealthAccessStatus = status
        guard case .available = status.availability else {
            stopAllObservers(resetAnchors: resetRevokedAnchors)
            return
        }

        try await enableBackgroundDelivery(for: status.granted)
        try await startObserversIfNeeded(for: status.granted)
        stopRevokedObservers(keeping: status.granted, resetAnchors: resetRevokedAnchors)
    }

    private func enableBackgroundDelivery(for grantedTypes: Set<HKSampleType>) async throws {
        guard !grantedTypes.isEmpty else { return }
        do {
            try await healthKit.enableBackgroundDelivery(for: grantedTypes)
        } catch HealthKitServiceError.backgroundDeliveryFailed(let type, let underlying) {
            if shouldIgnoreBackgroundDeliveryError(underlying) {
#if DEBUG
                print("[PulsumData] Background delivery disabled (missing entitlement) for \(type.identifier).")
#endif
            } else {
                throw HealthKitServiceError.backgroundDeliveryFailed(type: type, underlying: underlying)
            }
        } catch {
            throw error
        }
    }

    private func startObserversIfNeeded(for types: Set<HKSampleType>) async throws {
        guard !types.isEmpty else { return }
        for type in types {
            try await observe(sampleType: type)
        }
    }

    private func stopRevokedObservers(keeping granted: Set<HKSampleType>, resetAnchors: Bool) {
        let grantedIdentifiers = Set(granted.map { $0.identifier })
        let identifiers = Array(observers.keys)
        for identifier in identifiers where !grantedIdentifiers.contains(identifier) {
            if let type = sampleTypesByIdentifier[identifier] {
                stopObservation(for: type, resetAnchor: resetAnchors)
            } else {
                observers.removeValue(forKey: identifier)
            }
        }
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

        guard let computation = result else { return nil }
        let snapshot = stateEstimator.currentSnapshot(features: computation.featureValues)
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

        struct BaselinePayload: Sendable {
            let median: Double?
            let mad: Double?
            let ewma: Double?
            let updatedAt: Date?
        }

        let descriptors = Self.scoreMetricDescriptors
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
                notes: notes
            )

            metrics.append(detail)
        }

        let generalNotes = Self.generalFlagMessages(for: snapshot.imputedFlags)

        return ScoreBreakdown(date: snapshot.date,
                              wellbeingScore: snapshot.wellbeingScore,
                              metrics: metrics,
                              generalNotes: generalNotes)
    }

    func reprocessDay(date: Date) async throws {
        let day = calendar.startOfDay(for: date)
        try await reprocessDayInternal(day)
    }

    func recordSubjectiveInputs(date: Date, stress: Double, energy: Double, sleepQuality: Double) async throws {
        let targetDate = calendar.startOfDay(for: date)
        let context = self.context
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
                #if DEBUG
                print("HealthKit observe error: \(error)")
                #endif
            }
        }
        observers[identifier] = token
    }

    private func handle(update: HealthKitService.AnchoredUpdate, sampleType: HKSampleType) async {
        do {
            switch sampleType {
            case let quantityType as HKQuantityType:
                try await processQuantitySamples(update.samples.compactMap { $0 as? HKQuantitySample },
                                                 type: quantityType)
            case let categoryType as HKCategoryType:
                try await processCategorySamples(update.samples.compactMap { $0 as? HKCategorySample },
                                                 type: categoryType)
            default:
                break
            }
            try await handleDeletedSamples(update.deletedSamples)
        } catch {
#if DEBUG
            print("DataAgent processing error: \(error)")
#endif
        }
    }

    // MARK: - Sample Processing

    private func processQuantitySamples(_ samples: [HKQuantitySample],
                                        type: HKQuantityType) async throws {
        guard !samples.isEmpty else { return }

        let calendar = self.calendar
        let context = self.context

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
    }

    private func processCategorySamples(_ samples: [HKCategorySample],
                                        type: HKCategoryType) async throws {
        guard type.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue else { return }
        guard !samples.isEmpty else { return }

        let calendar = self.calendar
        let context = self.context

        let dirtyDays = try await context.perform { () throws -> Set<Date> in
            var dirtyDays: Set<Date> = []
            for sample in samples {
                let day = calendar.startOfDay(for: sample.startDate)
                let metrics = DataAgent.fetchOrCreateDailyMetrics(in: context, date: day)
                DataAgent.mutateFlags(metrics) { flags in
                    flags.append(sleepSample: sample)
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
    }

    private func handleDeletedSamples(_ deletedObjects: [HKDeletedObject]) async throws {
        guard !deletedObjects.isEmpty else { return }

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
    }

    // MARK: - Daily Computation

    private func reprocessDayInternal(_ day: Date) async throws {
        let context = self.context
        let calendar = self.calendar
        let sedentaryThreshold = sedentaryThresholdStepsPerHour
        let sedentaryDuration = sedentaryMinimumDuration
        let sleepDebtWindowDays = self.sleepDebtWindowDays
        let analysisWindowDays = self.analysisWindowDays

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

        let target = computeTarget(using: computation.featureValues)
        let snapshot = stateEstimator.update(features: computation.featureValues, target: target)

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
        if sedentaryIntervals.isEmpty {
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
        let actualSleepHours = sleepSeconds / 3600
        if sleepSeconds < 3 * 3600 {
            imputed["sleep_low_confidence"] = true
        }
        let sleepNeed = try personalizedSleepNeedHours(context: context,
                                                       referenceDate: metrics.date,
                                                       latestActualHours: actualSleepHours,
                                                       windowDays: analysisWindowDays)
        let sleepDebt = try sleepDebtHours(context: context,
                                           personalNeed: sleepNeed,
                                           currentHours: actualSleepHours,
                                           referenceDate: metrics.date,
                                           windowDays: sleepDebtWindowDays,
                                           calendar: calendar)

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
    }

    private func computeTarget(using features: [String: Double]) -> Double {
        let stress = features["subj_stress"] ?? 0
        let energy = features["subj_energy"] ?? 0
        let sleepQuality = features["subj_sleepQuality"] ?? 0
        let sleepDebt = features["z_sleepDebt"] ?? 0
        let hrv = features["z_hrv"] ?? 0
        let steps = features["z_steps"] ?? 0
        return (-0.35 * hrv) + (-0.25 * steps) + (-0.4 * sleepDebt) + (0.45 * stress) + (-0.4 * energy) + (0.3 * sleepQuality)
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

    private func notifySnapshotUpdate(for date: Date) {
        notificationCenter.post(name: .pulsumScoresUpdated,
                                object: nil,
                                userInfo: [AgentNotificationKeys.date: date])
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
                                       currentHours: Double,
                                       referenceDate: Date,
                                       windowDays: Int,
                                       calendar: Calendar) throws -> Double {
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
            flagKeys: ["sleep_low_confidence"]
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
        "sleep_low_confidence": "Less than 3 hours of sleep recorded; sleep-related calculations are low confidence."
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
        try await processQuantitySamples(samples, type: type)
    }

    func _testProcessCategorySamples(_ samples: [HKCategorySample], type: HKCategoryType) async throws {
        try await processCategorySamples(samples, type: type)
    }

    func _testReprocess(day: Date) async throws {
        try await reprocessDayInternal(day)
    }
#endif
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

    mutating func append(sleepSample sample: HKCategorySample) {
        sleepSegments.append(SleepSegment(sample))
        sleepSegments.trim(to: 256)
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

    func sleepDurations() -> Double {
        let asleep = sleepSegments.filter { $0.stage.isAsleep }
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
