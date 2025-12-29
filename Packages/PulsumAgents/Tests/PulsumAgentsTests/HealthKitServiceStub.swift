import Foundation
import HealthKit
@testable import PulsumServices

final class HealthKitServiceStub: HealthKitServicing, @unchecked Sendable {
    var isHealthDataAvailable: Bool = true
    private(set) var observedIdentifiers: [String] = []
    private(set) var stoppedIdentifiers: [String] = []
    private(set) var backgroundRequests: [Set<String>] = []
    var authorizationStatuses: [String: HKAuthorizationStatus] = [:]
    var requestAuthorizationStatus: HKAuthorizationRequestStatus? = .unnecessary
    var availabilityReason: String = "Unavailable"
    var fetchedSamples: [String: [HKSample]] = [:]
    private(set) var fetchRequests: [(identifier: String, start: Date, end: Date)] = []
    private(set) var dailyStepTotalsRequests: [(start: Date, end: Date)] = []
    private(set) var nocturnalStatsRequests: [(start: Date, end: Date)] = []
    var fetchDelayNanoseconds: UInt64 = 0
    var readProbeResults: [String: ReadAuthorizationProbeResult] = [:]

    func requestAuthorization() async throws {}

    func requestStatusForAuthorization(readTypes: Set<HKSampleType>) async -> HKAuthorizationRequestStatus? {
        requestAuthorizationStatus
    }

    func probeReadAuthorization(for type: HKSampleType) async -> ReadAuthorizationProbeResult {
        readProbeResults[type.identifier] ?? .authorized
    }

    func probeReadAuthorization(for types: [HKSampleType]) async -> [HKSampleType: ReadAuthorizationProbeResult] {
        var results: [HKSampleType: ReadAuthorizationProbeResult] = [:]
        for type in types {
            results[type] = await probeReadAuthorization(for: type)
        }
        return results
    }

    func fetchDailyStepTotals(startDate: Date, endDate: Date) async throws -> [Date: Int] {
        dailyStepTotalsRequests.append((startDate, endDate))
        if fetchDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: fetchDelayNanoseconds)
        }

        let calendar = Calendar(identifier: .gregorian)
        let samples = fetchedSamples[HKQuantityTypeIdentifier.stepCount.rawValue] ?? []
        let quantitySamples = samples.compactMap { $0 as? HKQuantitySample }
        var totals: [Date: Int] = [:]
        for sample in quantitySamples where sample.startDate >= startDate && sample.startDate < endDate {
            let day = calendar.startOfDay(for: sample.startDate)
            let value = sample.quantity.doubleValue(for: HKUnit.count())
            totals[day, default: 0] += Int(value)
        }
        return totals
    }

    func fetchNocturnalHeartRateStats(startDate: Date, endDate: Date) async throws -> [Date: (avgBPM: Double, minBPM: Double?)] {
        nocturnalStatsRequests.append((startDate, endDate))
        if fetchDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: fetchDelayNanoseconds)
        }

        let calendar = Calendar(identifier: .gregorian)
        let samples = fetchedSamples[HKQuantityTypeIdentifier.heartRate.rawValue] ?? []
        let quantitySamples = samples
            .compactMap { $0 as? HKQuantitySample }
            .filter { $0.startDate >= startDate && $0.startDate < endDate }
        var result: [Date: (avgBPM: Double, minBPM: Double?)] = [:]

        var day = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)
        while day < endDay {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            let nightStart = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: day) ?? day
            let nightEnd = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: nextDay) ?? nextDay
            let values = quantitySamples.compactMap { sample -> Double? in
                guard sample.startDate >= nightStart && sample.startDate < nightEnd else { return nil }
                return sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            }
            if !values.isEmpty {
                let avg = values.reduce(0, +) / Double(values.count)
                result[day] = (avgBPM: avg, minBPM: values.min())
            }
            day = nextDay
        }

        return result
    }

    func fetchSamples(for sampleType: HKSampleType, startDate: Date, endDate: Date) async throws -> [HKSample] {
        fetchRequests.append((sampleType.identifier, startDate, endDate))
        if fetchDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: fetchDelayNanoseconds)
        }
        let samples = fetchedSamples[sampleType.identifier] ?? []
        return samples.filter { $0.startDate >= startDate && $0.startDate < endDate }
    }

    func enableBackgroundDelivery(for types: Set<HKSampleType>) async throws {
        backgroundRequests.append(Set(types.map(\.identifier)))
    }

    func enableBackgroundDelivery() async throws {
        try await enableBackgroundDelivery(for: HealthKitService.readSampleTypes)
    }

    @discardableResult
    func observeSampleType(_ sampleType: HKSampleType,
                           predicate: NSPredicate? = nil,
                           updateHandler: @escaping HealthKitService.AnchoredUpdateHandler) throws -> HealthKitObservationToken {
        observedIdentifiers.append(sampleType.identifier)
        return StubObservationToken()
    }

    func stopObserving(sampleType: HKSampleType, resetAnchor: Bool) {
        stoppedIdentifiers.append(sampleType.identifier)
    }

    func authorizationStatus(for sampleType: HKSampleType) -> HKAuthorizationStatus {
        authorizationStatuses[sampleType.identifier] ?? .notDetermined
    }

    final class StubObservationToken: HealthKitObservationToken {}
}
