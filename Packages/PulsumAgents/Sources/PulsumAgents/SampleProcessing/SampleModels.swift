import Foundation
import HealthKit

// MARK: - TimedSample Protocol

protocol TimedSample {
    var id: UUID { get }
    var time: Date { get }
    var value: Double { get }
}

// MARK: - Sample Types

struct HRVSample: Codable, TimedSample {
    let id: UUID
    let time: Date
    let value: Double

    init(_ sample: HKQuantitySample) {
        id = sample.uuid
        time = sample.startDate
        value = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
    }
}

struct HeartRateSample: Codable, TimedSample {
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

struct RespiratorySample: Codable, TimedSample {
    let id: UUID
    let time: Date
    let value: Double

    init(_ sample: HKQuantitySample) {
        id = sample.uuid
        time = sample.startDate
        value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
    }
}

struct SleepSegment: Codable {
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

struct StepBucket: Codable {
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

// MARK: - Collection Utilities

extension Array {
    mutating func trim(to limit: Int) {
        guard count > limit else { return }
        removeFirst(count - limit)
    }
}

extension [Double] {
    var mean: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}

extension [DateInterval] {
    func contains(where predicate: (DateInterval) -> Bool) -> Bool {
        for interval in self where predicate(interval) {
            return true
        }
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

extension DateInterval {
    func intersectsAny(of intervals: [DateInterval]) -> Bool {
        intervals.contains { $0.intersects(self) }
    }
}
