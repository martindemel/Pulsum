import Foundation
import HealthKit

struct DailyFlags: Codable {
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

    // MARK: - Computations

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
            guard duration >= minimumDuration else { reset(); return }
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

    private func median(samples: [some TimedSample], within intervals: [DateInterval]) -> Double? {
        guard !samples.isEmpty else { return nil }
        let filtered = samples.filter { sample in intervals.contains { $0.contains(sample.time) } }
        guard !filtered.isEmpty else { return nil }
        let values = filtered.map { $0.value }.sorted()
        let mid = values.count / 2
        if values.count % 2 == 0 { return (values[mid - 1] + values[mid]) / 2 }
        return values[mid]
    }

    private func percentile(samples: [some TimedSample], within intervals: [DateInterval], percentile: Double) -> Double? {
        guard !samples.isEmpty else { return nil }
        let filtered = samples.filter { sample in intervals.contains { $0.contains(sample.time) } }
        guard !filtered.isEmpty else { return nil }
        let sorted = filtered.map { $0.value }.sorted()
        let index = max(0, Int(Double(sorted.count - 1) * percentile))
        return sorted[index]
    }

    private func average(samples: [some TimedSample], within intervals: [DateInterval]) -> Double? {
        guard !samples.isEmpty else { return nil }
        let filtered = samples.filter { sample in intervals.contains { $0.contains(sample.time) } }
        guard !filtered.isEmpty else { return nil }
        return filtered.map { $0.value }.mean
    }
}
