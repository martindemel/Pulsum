@testable import PulsumAgents
@testable import PulsumData
@testable import PulsumServices
import HealthKit
import XCTest

final class Gate3_HealthAccessStatusTests: XCTestCase {
    func testDeniedTypesAreExcludedFromObservation() async throws {
        let stub = HealthKitServiceStub()
        let sleepIdentifier = HKCategoryTypeIdentifier.sleepAnalysis.rawValue
        for type in HealthKitService.orderedReadSampleTypes {
            if type.identifier == sleepIdentifier {
                stub.authorizationStatuses[type.identifier] = .sharingDenied
            } else {
                stub.authorizationStatuses[type.identifier] = .sharingAuthorized
            }
        }
        let agent = DataAgent(healthKit: stub, container: TestCoreDataStack.makeContainer())

        let status = await agent.currentHealthAccessStatus()

        XCTAssertTrue(status.denied.contains { $0.identifier == sleepIdentifier })
        XCTAssertFalse(status.granted.contains { $0.identifier == sleepIdentifier })

        try await agent.startIngestionIfAuthorized()

        XCTAssertFalse(stub.observedIdentifiers.contains(sleepIdentifier), "Denied type should not start observation.")

        let grantedIdentifiers = Set(stub.observedIdentifiers)
        XCTAssertEqual(grantedIdentifiers.count, HealthKitService.orderedReadSampleTypes.count - 1)

        stub.authorizationStatuses[sleepIdentifier] = .sharingAuthorized

        try await agent.restartIngestionAfterPermissionsChange()

        let counts = Dictionary(grouping: stub.observedIdentifiers, by: { $0 }).mapValues(\.count)
        XCTAssertEqual(counts[sleepIdentifier], 1, "Sleep type should be observed exactly once after grant.")
        for type in HealthKitService.orderedReadSampleTypes where type.identifier != sleepIdentifier {
            XCTAssertEqual(counts[type.identifier], 1, "Already granted types should not duplicate observers.")
        }
    }

    func testRequestStatusDoesNotOverrideDeniedAuthorization() async throws {
        let stub = HealthKitServiceStub()
        stub.requestAuthorizationStatus = .unnecessary
        for type in HealthKitService.orderedReadSampleTypes {
            stub.authorizationStatuses[type.identifier] = .sharingDenied
        }
        let agent = DataAgent(healthKit: stub, container: TestCoreDataStack.makeContainer())

        let status = await agent.currentHealthAccessStatus()
        XCTAssertTrue(status.granted.isEmpty)
        XCTAssertEqual(status.denied.count, HealthKitService.orderedReadSampleTypes.count)
        XCTAssertTrue(status.notDetermined.isEmpty)

        try await agent.startIngestionIfAuthorized()
        XCTAssertTrue(stub.observedIdentifiers.isEmpty, "Denied types should not start observation even when request status is unnecessary.")
    }
}
