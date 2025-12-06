@testable import PulsumAgents
@testable import PulsumServices
import HealthKit
import XCTest

final class Gate6_WellbeingStateMappingTests: XCTestCase {
    func testComputeWellbeingStateMatchesHealthAccess() {
        let required = HealthKitService.orderedReadSampleTypes
        let unavailable = HealthAccessStatus(required: required,
                                             granted: [],
                                             denied: [],
                                             notDetermined: [],
                                             availability: .unavailable(reason: "simulator"))
        XCTAssertEqual(AgentOrchestrator.computeWellbeingState(for: unavailable),
                       .noData(.healthDataUnavailable))

        let pending = HealthAccessStatus(required: required,
                                         granted: [],
                                         denied: [],
                                         notDetermined: Set(required),
                                         availability: .available)
        XCTAssertEqual(AgentOrchestrator.computeWellbeingState(for: pending),
                       .noData(.permissionsDeniedOrPending))

        let denied = HealthAccessStatus(required: required,
                                        granted: [],
                                        denied: Set(required),
                                        notDetermined: [],
                                        availability: .available)
        XCTAssertEqual(AgentOrchestrator.computeWellbeingState(for: denied),
                       .noData(.permissionsDeniedOrPending))

        let granted = HealthAccessStatus(required: required,
                                         granted: Set(required),
                                         denied: [],
                                         notDetermined: [],
                                         availability: .available)
        XCTAssertEqual(AgentOrchestrator.computeWellbeingState(for: granted),
                       .noData(.insufficientSamples))
    }
}
