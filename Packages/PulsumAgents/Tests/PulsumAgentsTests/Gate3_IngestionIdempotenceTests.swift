@testable import PulsumAgents
@testable import PulsumData
@testable import PulsumServices
import XCTest

final class Gate3_IngestionIdempotenceTests: XCTestCase {
    func testRestartDoesNotDuplicateObserversAndStopsRevokedTypes() async throws {
        let stub = HealthKitServiceStub()
        let identifiers = HealthKitService.orderedReadSampleTypes.map { $0.identifier }
        identifiers.forEach {
            stub.authorizationStatuses[$0] = .sharingAuthorized
            stub.readProbeResults[$0] = .authorized
        }
        let agent = DataAgent(modelContainer: try TestCoreDataStack.makeContainer(), storagePaths: TestCoreDataStack.makeTestStoragePaths(), healthKit: stub)

        try await agent.startIngestionIfAuthorized()

        var counts = Dictionary(grouping: stub.observedIdentifiers, by: { $0 }).mapValues(\.count)
        for identifier in identifiers {
            XCTAssertEqual(counts[identifier], 1, "Each type should be observed exactly once on start.")
        }

        try await agent.startIngestionIfAuthorized()

        counts = Dictionary(grouping: stub.observedIdentifiers, by: { $0 }).mapValues(\.count)
        for identifier in identifiers {
            XCTAssertEqual(counts[identifier], 1, "Repeated start should not duplicate observers.")
        }

        guard let firstIdentifier = identifiers.first else {
            XCTFail("Expected at least one HealthKit type.")
            return
        }

        stub.authorizationStatuses[firstIdentifier] = .sharingDenied
        stub.readProbeResults[firstIdentifier] = .denied

        try await agent.restartIngestionAfterPermissionsChange()

        XCTAssertTrue(stub.stoppedIdentifiers.contains(firstIdentifier), "Revoked type should be stopped.")

        stub.authorizationStatuses[firstIdentifier] = .sharingAuthorized
        stub.readProbeResults[firstIdentifier] = .authorized

        try await agent.restartIngestionAfterPermissionsChange()

        counts = Dictionary(grouping: stub.observedIdentifiers, by: { $0 }).mapValues(\.count)
        XCTAssertEqual(counts[firstIdentifier], 2, "Revoked then re-granted type should be re-observed once.")
    }
}
