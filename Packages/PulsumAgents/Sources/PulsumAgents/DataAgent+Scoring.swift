import Foundation
import SwiftData
import PulsumData
import PulsumML
import PulsumTypes

// MARK: - Scoring & Feature Vector Retrieval

extension DataAgent {
    func latestFeatureVector() async throws -> FeatureVectorSnapshot? {
        try await latestFeatureVector(includePlaceholder: true)
    }

    func latestRealFeatureVector() async throws -> FeatureVectorSnapshot? {
        try await latestFeatureVector(includePlaceholder: false)
    }

    func latestFeatureVector(includePlaceholder: Bool) async throws -> FeatureVectorSnapshot? {
        var descriptor = FetchDescriptor<FeatureVector>()
        descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        descriptor.fetchLimit = 5
        let vectors = try modelContext.fetch(descriptor)
        guard !vectors.isEmpty else {
            await DebugLogBuffer.shared.append("latestFeatureVector -> none found")
            return nil
        }

        var placeholderCandidate: FeatureComputation?
        var result: FeatureComputation?
        for vector in vectors {
            let bundle = BaselineCalculator.materializeFeatures(from: vector)
            let computation = FeatureComputation(date: vector.date,
                                                 featureValues: bundle.values,
                                                 imputedFlags: bundle.imputed,
                                                 featureVectorObjectID: vector.persistentModelID)
            if SnapshotPlaceholder.isPlaceholder(bundle.imputed) {
                if includePlaceholder, placeholderCandidate == nil {
                    placeholderCandidate = computation
                }
                continue
            }
            result = computation
            break
        }
        if result == nil {
            result = includePlaceholder ? placeholderCandidate : nil
        }

        guard let computation = result else {
            await DebugLogBuffer.shared.append("latestFeatureVector -> none found")
            return nil
        }
        let modelFeatures = WellbeingModeling.normalize(features: computation.featureValues,
                                                        imputedFlags: computation.imputedFlags)
        let snapshot = await stateEstimator.currentSnapshot(features: modelFeatures)
        let dayString = DiagnosticsDayFormatter.dayString(from: computation.date)
        let placeholder = SnapshotPlaceholder.isPlaceholder(computation.imputedFlags)
        await DebugLogBuffer.shared.append("latestFeatureVector -> day=\(dayString) feature_count=\(computation.featureValues.count) placeholder=\(placeholder)")
        return FeatureVectorSnapshot(date: computation.date,
                                     wellbeingScore: snapshot.wellbeingScore,
                                     contributions: snapshot.contributions,
                                     imputedFlags: computation.imputedFlags,
                                     featureVectorObjectID: computation.featureVectorObjectID,
                                     features: computation.featureValues)
    }

    func scoreBreakdown() async throws -> ScoreBreakdown? {
        guard let snapshot = try await latestRealFeatureVector() else { return nil }

        let dayString = DiagnosticsDayFormatter.dayString(from: snapshot.date)
        await DebugLogBuffer.shared.append("Computing scoreBreakdown for day=\(dayString)")

        struct BaselinePayload: Sendable {
            let median: Double?
            let mad: Double?
            let ewma: Double?
            let updatedAt: Date?
        }

        let descriptors = scoreMetricDescriptors
        let coverageByFeature = try metricCoverage(for: snapshot, descriptors: descriptors)

        var rawValues: [String: Double] = [:]
        var baselineValues: [String: BaselinePayload] = [:]

        let snapshotDate = snapshot.date
        var metricsDescriptor = FetchDescriptor<DailyMetrics>(predicate: #Predicate { $0.date == snapshotDate })
        metricsDescriptor.fetchLimit = 1
        if let metrics = try modelContext.fetch(metricsDescriptor).first {
            rawValues["hrv"] = metrics.hrvMedian
            rawValues["nocthr"] = metrics.nocturnalHRPercentile10
            rawValues["resthr"] = metrics.restingHR
            rawValues["sleepDebt"] = metrics.sleepDebt
            rawValues["rr"] = metrics.respiratoryRate
            rawValues["steps"] = metrics.steps
        }

        let baselineKeys = Array(Set(descriptors.compactMap { $0.baselineKey }))
        if !baselineKeys.isEmpty {
            var baselineDescriptor = FetchDescriptor<Baseline>(predicate: #Predicate { baselineKeys.contains($0.metric) })
            let baselineObjects = try modelContext.fetch(baselineDescriptor)
            for baseline in baselineObjects {
                let key = baseline.metric
                guard !key.isEmpty else { continue }
                baselineValues[key] = BaselinePayload(
                    median: baseline.median,
                    mad: baseline.mad,
                    ewma: baseline.ewma,
                    updatedAt: baseline.updatedAt
                )
            }
        }

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

        let generalNotes = generalFlagMessages(for: snapshot.imputedFlags)

        return ScoreBreakdown(date: snapshot.date,
                              wellbeingScore: snapshot.wellbeingScore,
                              metrics: metrics,
                              generalNotes: generalNotes)
    }

    func metricCoverage(for snapshot: FeatureVectorSnapshot,
                        descriptors: [ScoreMetricDescriptor]) throws -> [String: ScoreBreakdown.MetricDetail.Coverage] {
        let calendar = self.calendar

        var coverage: [String: ScoreBreakdown.MetricDetail.Coverage] = [:]
        let endDate = calendar.startOfDay(for: snapshot.date)

        var windowStarts: [String: Date] = [:]
        for descriptor in descriptors {
            guard let window = descriptor.rollingWindowDays else { continue }
            let start = calendar.date(byAdding: .day, value: -(window - 1), to: endDate) ?? endDate
            windowStarts[descriptor.featureKey] = start
        }

        guard let earliest = windowStarts.values.min() else { return [:] }

        let earliestDate = earliest
        let endDateForPredicate = endDate
        var metricsDescriptor = FetchDescriptor<DailyMetrics>(predicate: #Predicate { $0.date >= earliestDate && $0.date <= endDateForPredicate })
        let metrics = try modelContext.fetch(metricsDescriptor)

        var counts: [String: (days: Set<Date>, samples: Int)] = [:]

        for metric in metrics {
            let flags = Self.decodeFlags(from: metric)
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
