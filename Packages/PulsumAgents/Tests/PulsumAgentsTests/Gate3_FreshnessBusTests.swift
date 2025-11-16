@testable import PulsumAgents
@testable import PulsumData
import PulsumTypes
import XCTest

final class Gate3_FreshnessBusTests: XCTestCase {
    func testSnapshotPublishPostsNotificationExactlyOnce() async {
        let stub = HealthKitServiceStub()
        let center = RecordingNotificationCenter()
        let agent = DataAgent(healthKit: stub,
                              container: TestCoreDataStack.makeContainer(),
                              notificationCenter: center)

        await agent._testPublishSnapshotUpdate(for: Date())

        XCTAssertEqual(center.postedNames.filter { $0 == .pulsumScoresUpdated }.count, 1)
    }
}

private final class RecordingNotificationCenter: NotificationCenter, @unchecked Sendable {
    private(set) var postedNames: [Notification.Name] = []

    override func post(name aName: Notification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable: Any]? = nil) {
        postedNames.append(aName)
        super.post(name: aName, object: anObject, userInfo: aUserInfo)
    }
}
