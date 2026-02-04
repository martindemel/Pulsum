@testable import PulsumAgents
@testable import PulsumData
import PulsumTypes
import XCTest

final class Gate7_FirstRunWatchdogTests: XCTestCase {
    private let timeZone = TimeZone(secondsFromGMT: 0)!
    private let referenceDate = Date()
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
    func testWatchdogPublishesPlaceholderWhenBootstrapTimesOut() async throws {
        let stub = HealthKitServiceStub()
        TestHealthKitSampleSeeder.authorizeAllTypes(stub)
        stub.fetchDelayNanoseconds = 300_000_000

        let policy = DataAgentBootstrapPolicy(bootstrapTimeoutSeconds: 0.05,
                                              heartRateTimeoutSeconds: 0.05,
                                              backfillTimeoutSeconds: 0.05,
                                              placeholderDeadlineSeconds: 0.2,
                                              retryDelaySeconds: 0.1,
                                              retryTimeoutSeconds: 0.3,
                                              retryMaxAttempts: 1,
                                              retryMaxElapsedSeconds: 1)
        let agent = DataAgent(healthKit: stub,
                              container: TestCoreDataStack.makeContainer(),
                              calendar: calendar,
                              estimatorStore: EstimatorStateStore(),
                              backfillStore: BackfillStateStore(),
                              bootstrapPolicy: policy)

        let startTask = Task { try await agent.start() }

        let placeholderSnapshot = await waitForSnapshot(agent: agent,
                                                        timeout: 0.6,
                                                        predicate: { SnapshotPlaceholder.isPlaceholder($0) })
        XCTAssertNotNil(placeholderSnapshot, "Placeholder snapshot should be created within the watchdog deadline.")

        let startResult = try await withHardTimeout(seconds: 1.0) {
            try await startTask.value
            return true
        }
        switch startResult {
        case .timedOut:
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
        stub.fetchDelayNanoseconds = 50_000_000

        let policy = DataAgentBootstrapPolicy(bootstrapTimeoutSeconds: 0.03,
                                              heartRateTimeoutSeconds: 0.03,
                                              backfillTimeoutSeconds: 0.03,
                                              placeholderDeadlineSeconds: 0.05,
                                              retryDelaySeconds: 0.1,
                                              retryTimeoutSeconds: 0.3,
                                              retryMaxAttempts: 1,
                                              retryMaxElapsedSeconds: 1)
        let agent = DataAgent(healthKit: stub,
                              container: TestCoreDataStack.makeContainer(),
                              calendar: calendar,
                              estimatorStore: EstimatorStateStore(),
                              backfillStore: BackfillStateStore(),
                              bootstrapPolicy: policy)

        let startTask = Task { try await agent.start() }

        let placeholderSnapshot = await waitForSnapshot(agent: agent,
                                                        timeout: 0.4,
                                                        predicate: { SnapshotPlaceholder.isPlaceholder($0) })
        XCTAssertNotNil(placeholderSnapshot, "Placeholder should publish after the initial timeout.")

        let realSnapshot = await waitForSnapshot(agent: agent,
                                                 timeout: 1.2,
                                                 predicate: { !SnapshotPlaceholder.isPlaceholder($0) })
        XCTAssertNotNil(realSnapshot, "Retry should materialize a real snapshot.")

        _ = try await startTask.value
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
