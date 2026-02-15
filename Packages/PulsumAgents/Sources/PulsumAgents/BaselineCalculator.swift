import Foundation
import SwiftData
import PulsumData
import PulsumML

/// Runs within DataAgent's actor isolation -- not a standalone actor.
/// Owns baseline computation, sleep need/debt, and feature bundle construction.
struct BaselineCalculator {
    let modelContext: ModelContext
    let calendar: Calendar

    // MARK: - Baselines

    func updateBaselines(summary: DailySummary,
                         referenceDate: Date,
                         windowDays: Int) throws -> [String: BaselineMath.RobustStats] {
        let stats = try computeBaselines(referenceDate: referenceDate, windowDays: windowDays)
        let latestValues: [String: Double?] = [
            "hrv": summary.hrv,
            "nocthr": summary.nocturnalHR,
            "resthr": summary.restingHR,
            "sleepDebt": summary.sleepDebtHours,
            "rr": summary.respiratoryRate,
            "steps": summary.stepCount
        ]

        for (metricKey, stat) in stats {
            let baseline = try fetchBaseline(metric: metricKey)
            baseline.metric = metricKey
            baseline.windowDays = Int16(windowDays)
            baseline.median = stat.median
            baseline.mad = stat.mad
            if let latest = latestValues[metricKey] ?? nil {
                let previous = baseline.ewma
                let ewma = BaselineMath.ewma(previous: previous, newValue: latest)
                baseline.ewma = ewma
            }
            baseline.updatedAt = referenceDate
        }

        return stats
    }

    func computeBaselines(referenceDate: Date,
                          windowDays: Int) throws -> [String: BaselineMath.RobustStats] {
        let refDate = referenceDate
        var descriptor = FetchDescriptor<DailyMetrics>(predicate: #Predicate { $0.date <= refDate })
        descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        descriptor.fetchLimit = windowDays
        let metrics = try modelContext.fetch(descriptor)

        func stats(_ keyPath: KeyPath<DailyMetrics, Double?>) -> BaselineMath.RobustStats? {
            let values = metrics.compactMap { $0[keyPath: keyPath] }
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

    func fetchBaseline(metric: String) throws -> Baseline {
        let metricKey = metric
        var descriptor = FetchDescriptor<Baseline>(predicate: #Predicate { $0.metric == metricKey })
        descriptor.fetchLimit = 1
        if let baseline = try modelContext.fetch(descriptor).first {
            return baseline
        }
        let baseline = Baseline(metric: metric, windowDays: 0)
        modelContext.insert(baseline)
        return baseline
    }

    func previousMetricValue(keyPath: KeyPath<DailyMetrics, Double?>, date: Date) throws -> Double? {
        let targetDate = date
        var descriptor = FetchDescriptor<DailyMetrics>(predicate: #Predicate { $0.date < targetDate })
        descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?[keyPath: keyPath]
    }

    // MARK: - Sleep

    func personalizedSleepNeedHours(referenceDate: Date,
                                    latestActualHours _: Double,
                                    windowDays: Int) throws -> Double {
        let refDate = referenceDate
        var descriptor = FetchDescriptor<DailyMetrics>(predicate: #Predicate { $0.date <= refDate })
        descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        descriptor.fetchLimit = windowDays
        let metrics = try modelContext.fetch(descriptor)
        let historical = metrics.compactMap { $0.totalSleepTime }.map { $0 / 3600 }
        let defaultNeed = 7.5
        guard historical.count >= 7 else { return defaultNeed }
        let mean = historical.reduce(0, +) / Double(historical.count)
        return min(max(mean, defaultNeed - 0.75), defaultNeed + 0.75)
    }

    func sleepDebtHours(personalNeed: Double,
                        currentHours: Double?,
                        referenceDate: Date,
                        windowDays: Int) throws -> Double? {
        guard let currentHours else { return nil }
        let start = calendar.date(byAdding: .day, value: -(windowDays - 1), to: referenceDate) ?? referenceDate
        let startDate = start
        let refDate = referenceDate
        var descriptor = FetchDescriptor<DailyMetrics>(predicate: #Predicate { $0.date >= startDate && $0.date <= refDate })
        descriptor.sortBy = [SortDescriptor(\.date)]
        let metrics = try modelContext.fetch(descriptor)
        var window = metrics.map { ($0.totalSleepTime ?? 0) / 3600 }
        if metrics.last?.date != referenceDate {
            window.append(currentHours)
        }
        return window.map { max(0, personalNeed - $0) }.reduce(0, +)
    }

    // MARK: - Feature Bundle

    func buildFeatureBundle(for summary: DailySummary,
                            baselines: [String: BaselineMath.RobustStats]) throws -> FeatureBundle {
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

        let vector = try fetchOrCreateFeatureVector(date: summary.date)
        if let stress = vector.subjectiveStress { values["subj_stress"] = stress }
        if let energy = vector.subjectiveEnergy { values["subj_energy"] = energy }
        if let sleepQuality = vector.subjectiveSleepQuality { values["subj_sleepQuality"] = sleepQuality }
        if let sentiment = vector.sentiment { values["sentiment"] = sentiment }

        for key in FeatureBundle.requiredKeys where values[key] == nil {
            values[key] = 0
        }

        return FeatureBundle(values: values, imputed: summary.imputed)
    }

    func apply(features: [String: Double], to vector: FeatureVector) {
        vector.zHrv = features["z_hrv"] ?? 0
        vector.zNocturnalHR = features["z_nocthr"] ?? 0
        vector.zRestingHR = features["z_resthr"] ?? 0
        vector.zSleepDebt = features["z_sleepDebt"] ?? 0
        vector.zRespiratoryRate = features["z_rr"] ?? 0
        vector.zSteps = features["z_steps"] ?? 0
        vector.subjectiveStress = features["subj_stress"] ?? 0
        vector.subjectiveEnergy = features["subj_energy"] ?? 0
        vector.subjectiveSleepQuality = features["subj_sleepQuality"] ?? 0
        vector.sentiment = features["sentiment"] ?? 0
    }

    // MARK: - Materialization

    static func materializeFeatures(from vector: FeatureVector) -> FeatureBundle {
        var imputed: [String: Bool] = [:]
        if let payload = vector.imputedFlags,
           let data = payload.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let map = json["imputed"] as? [String: Bool] {
            imputed = map
        }

        let values: [String: Double] = [
            "z_hrv": vector.zHrv ?? 0,
            "z_nocthr": vector.zNocturnalHR ?? 0,
            "z_resthr": vector.zRestingHR ?? 0,
            "z_sleepDebt": vector.zSleepDebt ?? 0,
            "z_rr": vector.zRespiratoryRate ?? 0,
            "z_steps": vector.zSteps ?? 0,
            "subj_stress": vector.subjectiveStress ?? 0,
            "subj_energy": vector.subjectiveEnergy ?? 0,
            "subj_sleepQuality": vector.subjectiveSleepQuality ?? 0,
            "sentiment": vector.sentiment ?? 0
        ]
        return FeatureBundle(values: values, imputed: imputed)
    }

    static func encodeFeatureMetadata(imputed: [String: Bool], contributions: [String: Double], wellbeing: Double) -> String? {
        let payload: [String: Any] = [
            "imputed": imputed,
            "contributions": contributions,
            "wellbeing": wellbeing
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Persistence helpers

    func fetchOrCreateFeatureVector(date: Date) throws -> FeatureVector {
        let targetDate = date
        var descriptor = FetchDescriptor<FeatureVector>(predicate: #Predicate { $0.date == targetDate })
        descriptor.fetchLimit = 1
        if let vector = try modelContext.fetch(descriptor).first {
            return vector
        }
        let vector = FeatureVector(date: date)
        modelContext.insert(vector)
        return vector
    }
}
