import Foundation
import HealthKit
@testable import PulsumServices

final class HealthKitServiceStub: HealthKitServicing, @unchecked Sendable {
    var isHealthDataAvailable: Bool = true
    private(set) var observedIdentifiers: [String] = []
    private(set) var stoppedIdentifiers: [String] = []
    private(set) var backgroundRequests: [Set<String>] = []
    var authorizationStatuses: [String: HKAuthorizationStatus] = [:]

    func requestAuthorization() async throws {}

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
