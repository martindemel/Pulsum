import XCTest
@testable import PulsumAgents
@testable import PulsumML

// swiftlint:disable:next type_name
final class Gate6_StateEstimatorPersistenceTests: XCTestCase {
    func testEstimatorStatePersistsAcrossInstances() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gate6-estimator-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let estimatorStore = EstimatorStateStore(baseDirectory: tempDirectory)
        let container = TestCoreDataStack.makeContainer()
        let agent = DataAgent(healthKit: HealthKitServiceStub(),
                              container: container,
                              estimatorStore: estimatorStore)

        let featureInput: [String: Double] = [
            "z_hrv": 1.0,
            "z_sleepDebt": -0.8,
            "z_steps": 0.9,
            "subj_energy": 6.0,
            "subj_stress": 2.5,
            "sentiment": 0.4
        ]

        let snapshot = await agent._testUpdateEstimator(features: featureInput)

        guard let persisted = estimatorStore.loadState() else {
            XCTFail("Expected persisted estimator state")
            return
        }

        XCTAssertNotEqual(persisted.weights, StateEstimator.defaultWeights)
        XCTAssertEqual(persisted.bias, snapshot.bias)

        let restarted = DataAgent(healthKit: HealthKitServiceStub(),
                                  container: container,
                                  estimatorStore: estimatorStore)
        let restartedState = await restarted._testEstimatorState()
        XCTAssertEqual(restartedState.weights, persisted.weights)
        XCTAssertEqual(restartedState.bias, persisted.bias)
    }
}
