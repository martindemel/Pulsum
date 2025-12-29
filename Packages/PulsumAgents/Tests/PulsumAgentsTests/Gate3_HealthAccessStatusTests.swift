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
            stub.readProbeResults[type.identifier] = type.identifier == sleepIdentifier ? .denied : .authorized
        }
        let agent = DataAgent(healthKit: stub, container: TestCoreDataStack.makeContainer())

        let status = await agent.currentHealthAccessStatus()

        XCTAssertTrue(status.denied.contains { $0.identifier == sleepIdentifier })
        XCTAssertFalse(status.granted.contains { $0.identifier == sleepIdentifier })

        try await agent.startIngestionIfAuthorized()

        XCTAssertFalse(stub.observedIdentifiers.contains(sleepIdentifier), "Denied type should not start observation.")

        let grantedIdentifiers = Set(stub.observedIdentifiers)
        XCTAssertEqual(grantedIdentifiers.count, HealthKitService.orderedReadSampleTypes.count - 1)

        stub.readProbeResults[sleepIdentifier] = .authorized

        try await agent.restartIngestionAfterPermissionsChange()

        let counts = Dictionary(grouping: stub.observedIdentifiers, by: { $0 }).mapValues(\.count)
        XCTAssertEqual(counts[sleepIdentifier], 1, "Sleep type should be observed exactly once after grant.")
        for type in HealthKitService.orderedReadSampleTypes where type.identifier != sleepIdentifier {
            XCTAssertEqual(counts[type.identifier], 1, "Already granted types should not duplicate observers.")
        }
    }

    func testReadOnlyAuthorizationDoesNotMarkGrantedAsDenied() async throws {
        let stub = HealthKitServiceStub()
        stub.requestAuthorizationStatus = .unnecessary
        for type in HealthKitService.orderedReadSampleTypes {
            stub.authorizationStatuses[type.identifier] = .sharingDenied
            stub.readProbeResults[type.identifier] = .authorized
        }
        let agent = DataAgent(healthKit: stub, container: TestCoreDataStack.makeContainer())

        let status = await agent.currentHealthAccessStatus()
        XCTAssertEqual(status.granted.count, HealthKitService.orderedReadSampleTypes.count)
        XCTAssertTrue(status.denied.isEmpty)
        XCTAssertTrue(status.notDetermined.isEmpty)

        try await agent.startIngestionIfAuthorized()
        let observed = Set(stub.observedIdentifiers)
        XCTAssertEqual(observed.count, HealthKitService.orderedReadSampleTypes.count, "All granted types should start observation even when sharing is denied.")
    }

    func testMixedProbeResultsClassifyPerType() async throws {
        let stub = HealthKitServiceStub()
        stub.requestAuthorizationStatus = .unnecessary
        let types = HealthKitService.orderedReadSampleTypes
        guard let deniedType = types.first, let pendingType = types.last, deniedType.identifier != pendingType.identifier else {
            XCTFail("Expected at least two HealthKit types for classification test.")
            return
        }

        for type in types {
            if type.identifier == deniedType.identifier {
                stub.readProbeResults[type.identifier] = .denied
            } else if type.identifier == pendingType.identifier {
                stub.readProbeResults[type.identifier] = .notDetermined
            } else {
                stub.readProbeResults[type.identifier] = .authorized
            }
        }

        let agent = DataAgent(healthKit: stub, container: TestCoreDataStack.makeContainer())

        let status = await agent.currentHealthAccessStatus()
        XCTAssertTrue(status.denied.contains { $0.identifier == deniedType.identifier })
        XCTAssertTrue(status.notDetermined.contains { $0.identifier == pendingType.identifier })
        XCTAssertFalse(status.granted.contains { $0.identifier == deniedType.identifier })
        XCTAssertFalse(status.granted.contains { $0.identifier == pendingType.identifier })
        XCTAssertEqual(status.granted.count, HealthKitService.orderedReadSampleTypes.count - 2)

        try await agent.startIngestionIfAuthorized()

        let observed = Set(stub.observedIdentifiers)
        XCTAssertFalse(observed.contains(deniedType.identifier))
        XCTAssertFalse(observed.contains(pendingType.identifier))
        XCTAssertEqual(observed.count, HealthKitService.orderedReadSampleTypes.count - 2)
    }
}
