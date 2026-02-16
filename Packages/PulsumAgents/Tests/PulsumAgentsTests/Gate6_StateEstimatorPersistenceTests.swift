import XCTest
@testable import PulsumAgents
@testable import PulsumData
@testable import PulsumML

// swiftlint:disable:next type_name
final class Gate6_StateEstimatorPersistenceTests: XCTestCase {
    func testEstimatorStatePersistsAcrossInstances() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gate6-estimator-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let estimatorStore = EstimatorStateStore(baseDirectory: tempDirectory)
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()
        let container = try TestCoreDataStack.makeContainer()
        let agent = DataAgent(modelContainer: container,
                              storagePaths: storagePaths,
                              healthKit: HealthKitServiceStub(),
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

        guard let persisted = await estimatorStore.loadState() else {
            XCTFail("Expected persisted estimator state")
            return
        }

        XCTAssertNotEqual(persisted.weights, StateEstimator.defaultWeights)
        XCTAssertEqual(persisted.bias, snapshot.bias)

        let restarted = DataAgent(modelContainer: container,
                                  storagePaths: storagePaths,
                                  healthKit: HealthKitServiceStub(),
                                  estimatorStore: estimatorStore)
        await restarted.restoreEstimatorState()
        let restartedState = await restarted._testEstimatorState()
        XCTAssertEqual(restartedState.weights, persisted.weights)
        XCTAssertEqual(restartedState.bias, persisted.bias)
    }
}
