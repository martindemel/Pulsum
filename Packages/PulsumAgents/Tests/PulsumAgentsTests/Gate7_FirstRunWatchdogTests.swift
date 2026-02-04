@testable import PulsumAgents
@testable import PulsumData
import PulsumTypes
import XCTest

final class Gate7_FirstRunWatchdogTests: XCTestCase {
    private let timeZone = TimeZone(secondsFromGMT: 0)!
    private let referenceDate: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: 2026, month: 1, day: 15)) ?? Date()
    }()
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
    func testWatchdogPublishesPlaceholderWhenBootstrapTimesOut() async throws {
        let stub = HealthKitServiceStub()
        TestHealthKitSampleSeeder.authorizeAllTypes(stub)
        stub.fetchDelayNanoseconds = 400_000_000

        let policy = DataAgentBootstrapPolicy(bootstrapTimeoutSeconds: 0.25,
                                              heartRateTimeoutSeconds: 0.25,
                                              backfillTimeoutSeconds: 0.25,
                                              placeholderDeadlineSeconds: 0.8,
                                              retryDelaySeconds: 0.2,
                                              retryTimeoutSeconds: 0.6,
                                              retryMaxAttempts: 1,
                                              retryMaxElapsedSeconds: 2)
        let agent = DataAgent(healthKit: stub,
                              container: TestCoreDataStack.makeContainer(),
                              calendar: calendar,
                              estimatorStore: EstimatorStateStore(),
                              backfillStore: BackfillStateStore(),
                              bootstrapPolicy: policy)

        let startTask = Task { try await agent.start() }

        let placeholderSnapshot = await waitForSnapshot(agent: agent,
                                                        timeout: 1.5,
                                                        predicate: { SnapshotPlaceholder.isPlaceholder($0) })
        XCTAssertNotNil(placeholderSnapshot, "Placeholder snapshot should be created within the watchdog deadline.")

        let startResult = try await withHardTimeout(seconds: 4.0) {
            try await startTask.value
            return true
        }
        switch startResult {
        case .timedOut:
            startTask.cancel()
            XCTFail("DataAgent.start should return without hanging.")
        case .value:
            break
        }
    }

    func testRetryPublishesRealSnapshotAfterTimeout() async throws {
        let stub = HealthKitServiceStub()
        TestHealthKitSampleSeeder.authorizeAllTypes(stub)
        TestHealthKitSampleSeeder.populateSamples(stub,
                                                  days: 2,
                                                  referenceDate: referenceDate,
                                                  calendar: calendar,
                                                  timeZone: timeZone)
        stub.fetchDelayNanoseconds = 300_000_000

        let policy = DataAgentBootstrapPolicy(bootstrapTimeoutSeconds: 0.2,
                                              heartRateTimeoutSeconds: 0.2,
                                              backfillTimeoutSeconds: 0.2,
                                              placeholderDeadlineSeconds: 0.4,
                                              retryDelaySeconds: 0.2,
                                              retryTimeoutSeconds: 1.2,
                                              retryMaxAttempts: 1,
                                              retryMaxElapsedSeconds: 5)
        let agent = DataAgent(healthKit: stub,
                              container: TestCoreDataStack.makeContainer(),
                              calendar: calendar,
                              estimatorStore: EstimatorStateStore(),
                              backfillStore: BackfillStateStore(),
                              bootstrapPolicy: policy)

        let startTask = Task { try await agent.start() }

        let placeholderSnapshot = await waitForSnapshot(agent: agent,
                                                        timeout: 1.0,
                                                        predicate: { SnapshotPlaceholder.isPlaceholder($0) })
        XCTAssertNotNil(placeholderSnapshot, "Placeholder should publish after the initial timeout.")
        stub.fetchDelayNanoseconds = 50_000_000

        let realSnapshot = await waitForSnapshot(agent: agent,
                                                 timeout: 6.0,
                                                 predicate: { !SnapshotPlaceholder.isPlaceholder($0) })
        XCTAssertNotNil(realSnapshot, "Retry should materialize a real snapshot.")

        let startResult = try await withHardTimeout(seconds: 6.0) {
            try await startTask.value
            return true
        }
        switch startResult {
        case .timedOut:
            startTask.cancel()
            XCTFail("DataAgent.start should return without hanging.")
        case .value:
            break
        }
    }

    private func waitForSnapshot(agent: DataAgent,
                                 timeout: TimeInterval,
                                 predicate: @escaping (FeatureVectorSnapshot) -> Bool) async -> FeatureVectorSnapshot? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let snapshot = try? await agent.latestFeatureVector(), predicate(snapshot) {
                return snapshot
            }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        return nil
    }

}
