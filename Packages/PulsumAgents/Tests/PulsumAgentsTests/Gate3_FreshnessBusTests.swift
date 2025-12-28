@testable import PulsumAgents
@testable import PulsumData
import PulsumTypes
import XCTest

final class Gate3_FreshnessBusTests: XCTestCase {
    func testReprocessDayPostsSingleNotification() async throws {
        let stub = HealthKitServiceStub()
        let center = RecordingNotificationCenter()
        let agent = DataAgent(healthKit: stub,
                              container: TestCoreDataStack.makeContainer(),
                              notificationCenter: center)

        let today = Date()
        try await agent.reprocessDay(date: today)

        try await Task.sleep(nanoseconds: 700_000_000)
        let posts = center.notifications(named: .pulsumScoresUpdated)
        XCTAssertEqual(posts.count, 1)
        let expectedDay = Calendar(identifier: .gregorian).startOfDay(for: today)
        let postedDay = posts.first?.userInfo?[AgentNotificationKeys.date] as? Date
        XCTAssertEqual(postedDay, expectedDay)
    }

    func testDebouncedNotificationsCoalesceBursts() async throws {
        let center = RecordingNotificationCenter()
        let agent = DataAgent(notificationCenter: center)
        let day = Date()
        await agent._testPublishSnapshotUpdate(for: day)
        await agent._testPublishSnapshotUpdate(for: day)
        await agent._testPublishSnapshotUpdate(for: day)

        try await Task.sleep(nanoseconds: 1_000_000_000)
        let posts = center.notifications(named: .pulsumScoresUpdated)
        XCTAssertGreaterThan(posts.count, 0)
        let expectedDay = Calendar(identifier: .gregorian).startOfDay(for: day)
        let postedDay = posts.first?.userInfo?[AgentNotificationKeys.date] as? Date
        XCTAssertEqual(postedDay, expectedDay)
        XCTAssertLessThanOrEqual(posts.count, 2)
    }
}

private struct PostedNotification {
    let name: Notification.Name
    let object: Any?
    let userInfo: [AnyHashable: Any]?
}

private final class RecordingNotificationCenter: NotificationCenter, @unchecked Sendable {
    private let lock = NSLock()
    private(set) var postedNotifications: [PostedNotification] = []

    override func post(name aName: Notification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable: Any]? = nil) {
        lock.lock()
        postedNotifications.append(PostedNotification(name: aName, object: anObject, userInfo: aUserInfo))
        lock.unlock()
        super.post(name: aName, object: anObject, userInfo: aUserInfo)
    }

    func notifications(named name: Notification.Name) -> [PostedNotification] {
        lock.lock()
        let result = postedNotifications.filter { $0.name == name }
        lock.unlock()
        return result
    }
}
