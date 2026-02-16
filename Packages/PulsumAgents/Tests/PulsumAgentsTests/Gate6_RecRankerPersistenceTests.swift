@testable import PulsumAgents
@testable import PulsumData
import PulsumML
import PulsumServices
import SwiftData
import XCTest

@MainActor
// swiftlint:disable:next type_name
final class Gate6_RecRankerPersistenceTests: XCTestCase {
    func testRankerStatePersistsAcrossAgentRestarts() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let rankerStore = RecRankerStateStore(baseDirectory: tempDirectory)
        let container = try TestCoreDataStack.makeContainer()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()

        let agent = try makeCoachAgent(container: container, storagePaths: storagePaths, rankerStore: rankerStore)

        let initialMetrics = await agent._testRankerMetrics()

        let features = [
            RecommendationFeatures(id: "a",
                                   wellbeingScore: 0.2,
                                   evidenceStrength: 0.8,
                                   novelty: 0.5,
                                   cooldown: 0.1,
                                   acceptanceRate: 0.9,
                                   timeCostFit: 0.4,
                                   zScores: ["z_hrv": 0.3]),
            RecommendationFeatures(id: "b",
                                   wellbeingScore: -0.1,
                                   evidenceStrength: 0.4,
                                   novelty: 0.2,
                                   cooldown: 0.2,
                                   acceptanceRate: 0.1,
                                   timeCostFit: 0.6,
                                   zScores: ["z_hrv": -0.4])
        ]

        agent._injectRankedFeaturesForTesting(features)
        try await agent.logEvent(momentId: "a", accepted: true)

        let updatedMetrics = await agent._testRankerMetrics()
        XCTAssertNotEqual(updatedMetrics.weights, initialMetrics.weights, "Weights should update after feedback.")

        let restarted = try makeCoachAgent(container: container, storagePaths: storagePaths, rankerStore: rankerStore)
        await restarted.restoreRankerState()
        let restoredMetrics = await restarted._testRankerMetrics()

        XCTAssertEqual(restoredMetrics.weights, updatedMetrics.weights)
        XCTAssertEqual(restoredMetrics.learningRate, updatedMetrics.learningRate)
    }

    @MainActor
    private func makeCoachAgent(container: ModelContainer,
                                storagePaths: StoragePaths,
                                rankerStore: RecRankerStateStoring) throws -> CoachAgent {
        let vectorIndex = VectorIndexStub()
        return try CoachAgent(container: container,
                              storagePaths: storagePaths,
                              vectorIndex: vectorIndex,
                              shouldIngestLibrary: false,
                              rankerStore: rankerStore)
    }
}

// Test-only: stateless stub — no mutable state, safe for concurrent use.
private final class VectorIndexStub: VectorIndexProviding, @unchecked Sendable {
    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float] {
        []
    }

    func removeMicroMoment(id: String) async throws {}

    func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch] {
        []
    }
}
