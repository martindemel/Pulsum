import Foundation
import HealthKit
import SwiftData
import PulsumData
import PulsumML
import PulsumServices
import PulsumTypes

// MARK: - Sample Processing & Daily Computation

extension DataAgent {
    func observe(sampleType: HKSampleType) async throws {
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

    func handle(update: HealthKitService.AnchoredUpdate, sampleType: HKSampleType) async {
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

    func processQuantitySamples(_ samples: [HKQuantitySample],
                                type: HKQuantityType) async throws -> Set<Date> {
        guard !samples.isEmpty else { return [] }

        let calendar = self.calendar
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

        var dirtyDays: Set<Date> = []
        for sample in samples {
            let day = calendar.startOfDay(for: sample.startDate)
            let metrics = self.fetchOrCreateDailyMetrics(date: day)
            Self.mutateFlags(metrics) { flags in
                flags.append(quantitySample: sample, type: type)
            }
            dirtyDays.insert(day)
        }
        try modelContext.save()

        for day in dirtyDays {
            try await reprocessDayInternal(day)
        }

        return dirtyDays
    }

    func processCategorySamples(_ samples: [HKCategorySample],
                                type: HKCategoryType) async throws -> Set<Date> {
        guard type.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue else { return [] }
        guard !samples.isEmpty else { return [] }

        let calendar = self.calendar

        var dirtyDays: Set<Date> = []
        for sample in samples {
            let day = calendar.startOfDay(for: sample.startDate)
            let metrics = self.fetchOrCreateDailyMetrics(date: day)
            Self.mutateFlags(metrics) { flags in
                let appended = flags.append(sleepSample: sample)
                if appended {
                    dirtyDays.insert(day)
                }
            }
        }
        try modelContext.save()

        for day in dirtyDays {
            try await reprocessDayInternal(day)
        }

        return dirtyDays
    }

    func handleDeletedSamples(_ deletedObjects: [HKDeletedObject]) async throws -> Set<Date> {
        guard !deletedObjects.isEmpty else { return [] }

        let identifiers = Set(deletedObjects.map { $0.uuid })
        let descriptor = FetchDescriptor<DailyMetrics>()
        let metrics = try modelContext.fetch(descriptor)
        var dirty: Set<Date> = []
        for metric in metrics {
            var flags = Self.decodeFlags(from: metric)
            let stepCount = flags.stepBuckets.count
            let sleepCount = flags.sleepSegments.count
            let heartRateCount = flags.heartRateSamples.count
            if flags.pruneDeletedSamples(identifiers) {
                if flags.stepBuckets.count < stepCount {
                    flags.aggregatedStepTotal = nil
                }
                if flags.sleepSegments.count < sleepCount {
                    flags.aggregatedSleepDurationSeconds = nil
                }
                if flags.heartRateSamples.count < heartRateCount {
                    flags.aggregatedNocturnalAverage = nil
                    flags.aggregatedNocturnalMin = nil
                }
                metric.flags = Self.encodeFlags(flags)
                dirty.insert(metric.date)
            }
        }
        try modelContext.save()
        let dirtyDays = dirty

        for day in dirtyDays {
            try await reprocessDayInternal(day)
        }

        return dirtyDays
    }

    func dayRange(for samples: [HKSample]) -> (start: Date, end: Date)? {
        guard let earliest = samples.map(\.startDate).min(),
              let latest = samples.map(\.startDate).max() else { return nil }
        let startDay = calendar.startOfDay(for: earliest)
        let endExclusive = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: latest)) ?? calendar.startOfDay(for: latest)
        return (startDay, endExclusive)
    }

    func applyStepTotals(_ totals: [Date: Int]) async throws -> Set<Date> {
        guard !totals.isEmpty else { return [] }
        let calendar = self.calendar

        var dirtyDays: Set<Date> = []
        for (rawDay, total) in totals {
            let day = calendar.startOfDay(for: rawDay)
            let metrics = self.fetchOrCreateDailyMetrics(date: day)
            Self.mutateFlags(metrics) { flags in
                flags.aggregatedStepTotal = Double(total)
                flags.stepBuckets = []
            }
            dirtyDays.insert(day)
        }
        try modelContext.save()

        for day in dirtyDays {
            try await reprocessDayInternal(day)
        }

        return dirtyDays
    }

    func applyNocturnalStats(_ stats: [Date: (avgBPM: Double, minBPM: Double?)]) async throws -> Set<Date> {
        guard !stats.isEmpty else { return [] }
        let calendar = self.calendar

        var dirtyDays: Set<Date> = []
        for (rawDay, value) in stats {
            let day = calendar.startOfDay(for: rawDay)
            let metrics = self.fetchOrCreateDailyMetrics(date: day)
            Self.mutateFlags(metrics) { flags in
                flags.aggregatedNocturnalAverage = value.avgBPM
                flags.aggregatedNocturnalMin = value.minBPM
                flags.heartRateSamples.removeAll { $0.context == .normal }
            }
            dirtyDays.insert(day)
        }
        try modelContext.save()

        for day in dirtyDays {
            try await reprocessDayInternal(day)
        }

        return dirtyDays
    }

    // MARK: - Daily Computation

    func reprocessDayInternal(_ day: Date) async throws {
        let calendar = self.calendar
        let sedentaryThreshold = sedentaryThresholdStepsPerHour
        let sedentaryDuration = sedentaryMinimumDuration
        let sleepDebtWindowDays = self.sleepDebtWindowDays
        let analysisWindowDays = self.fullAnalysisWindowDays

        let metrics = try self.fetchDailyMetrics(date: day)
        var flags = Self.decodeFlags(from: metrics)
        let summary = try self.computeSummary(for: metrics,
                                              flags: flags,
                                              calendar: calendar,
                                              sedentaryThreshold: sedentaryThreshold,
                                              sedentaryMinimumDuration: sedentaryDuration,
                                              sleepDebtWindowDays: sleepDebtWindowDays,
                                              analysisWindowDays: analysisWindowDays)
        flags = summary.updatedFlags

        metrics.hrvMedian = summary.hrv
        metrics.nocturnalHRPercentile10 = summary.nocturnalHR
        metrics.restingHR = summary.restingHR
        metrics.totalSleepTime = summary.totalSleepSeconds
        metrics.sleepDebt = summary.sleepDebtHours
        metrics.respiratoryRate = summary.respiratoryRate
        metrics.steps = summary.stepCount
        metrics.flags = Self.encodeFlags(flags)

        let baselines = try baselineCalc.updateBaselines(summary: summary,
                                                         referenceDate: day,
                                                         windowDays: analysisWindowDays)
        let bundle = try baselineCalc.buildFeatureBundle(for: summary,
                                                         baselines: baselines)
        let featureVector = try baselineCalc.fetchOrCreateFeatureVector(date: day)
        baselineCalc.apply(features: bundle.values, to: featureVector)

        try modelContext.save()

        let computation = FeatureComputation(date: day,
                                             featureValues: bundle.values,
                                             imputedFlags: bundle.imputed,
                                             featureVectorObjectID: featureVector.persistentModelID)

        let modelFeatures = WellbeingModeling.normalize(features: computation.featureValues,
                                                        imputedFlags: computation.imputedFlags)
        let target = WellbeingModeling.target(for: modelFeatures)
        let snapshot = await stateEstimator.update(features: modelFeatures, target: target)
        let dayString = DiagnosticsDayFormatter.dayString(from: day)
        await DebugLogBuffer.shared.append("Reprocessed day \(dayString) -> feature_count=\(computation.featureValues.count)")
        await persistEstimatorState(from: snapshot)

        guard let vector: FeatureVector = modelContext.registeredModel(for: computation.featureVectorObjectID) else { return }
        vector.imputedFlags = BaselineCalculator.encodeFeatureMetadata(imputed: computation.imputedFlags,
                                                                       contributions: snapshot.contributions,
                                                                       wellbeing: snapshot.wellbeingScore)
        try modelContext.save()
    }

    func persistEstimatorState(from snapshot: StateEstimatorSnapshot) async {
        let state = StateEstimatorState(version: EstimatorStateStore.schemaVersion,
                                        weights: snapshot.weights,
                                        bias: snapshot.bias)
        await estimatorStore.saveState(state)
    }

    func computeSummary(for metrics: DailyMetrics,
                        flags: DailyFlags,
                        calendar _: Calendar,
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

        let previousHRV = try baselineCalc.previousMetricValue(keyPath: \.hrvMedian,
                                                               date: metrics.date)
        let hrvValue = flags.medianHRV(in: sleepIntervals,
                                       fallback: sedentaryIntervals,
                                       previous: previousHRV,
                                       imputed: &imputed)

        let previousNocturnal = try baselineCalc.previousMetricValue(keyPath: \.nocturnalHRPercentile10,
                                                                     date: metrics.date)
        let nocturnalHR = flags.nocturnalHeartRate(in: sleepIntervals,
                                                   fallback: sedentaryIntervals,
                                                   previous: previousNocturnal,
                                                   imputed: &imputed)

        let previousResting = try baselineCalc.previousMetricValue(keyPath: \.restingHR,
                                                                   date: metrics.date)
        let restingHR = flags.restingHeartRate(fallback: sedentaryIntervals,
                                               previous: previousResting,
                                               imputed: &imputed)

        let sleepSeconds = flags.sleepDurations()
        let sleepNeed = try baselineCalc.personalizedSleepNeedHours(referenceDate: metrics.date,
                                                                    latestActualHours: (sleepSeconds ?? 0) / 3600,
                                                                    windowDays: analysisWindowDays)
        var sleepDebt: Double?
        if let sleepSeconds {
            let actualSleepHours = sleepSeconds / 3600
            if sleepSeconds < 3 * 3600 {
                imputed["sleep_low_confidence"] = true
            }
            sleepDebt = try baselineCalc.sleepDebtHours(personalNeed: sleepNeed,
                                                        currentHours: actualSleepHours,
                                                        referenceDate: metrics.date,
                                                        windowDays: sleepDebtWindowDays)
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

    // MARK: - Persistence Helpers
}
