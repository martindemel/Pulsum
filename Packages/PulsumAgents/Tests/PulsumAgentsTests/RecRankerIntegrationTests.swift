import Testing
import Foundation
@testable import PulsumAgents
@testable import PulsumData
import PulsumML
import SwiftData

/// B6-13 | LOW-19: Integration tests exercising the full RecRanker pipeline
/// with a real VectorStore actor (not mocks).
@Suite("RecRanker Integration with VectorStore")
struct RecRankerIntegrationTests {
    /// Full pipeline: upsert vectors → VectorStore search → RecRanker ranking → feedback update.
    @Test("Full pipeline: recommend, rank, and update with feedback")
    func test_fullPipeline_recommendAndFeedback() async throws {
        // 1. Set up a real VectorStore with a temp file (dimension 4 for speed).
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RecRankerIntegration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let storeURL = tempDir.appendingPathComponent("vectors.bin")
        let vectorStore = VectorStore(fileURL: storeURL, dimension: 4)

        // 2. Upsert micro-moment embedding vectors.
        let moments: [(id: String, vector: [Float])] = [
            ("breathe", [0.9, 0.1, 0.2, 0.3]),
            ("stretch", [0.1, 0.9, 0.2, 0.1]),
            ("hydrate", [0.2, 0.3, 0.8, 0.1]),
            ("walk", [0.3, 0.2, 0.1, 0.9]),
            ("journal", [0.5, 0.5, 0.3, 0.2]),
        ]
        for moment in moments {
            try await vectorStore.upsert(id: moment.id, vector: moment.vector)
        }

        // 3. Search VectorStore for moments similar to a query.
        let queryVector: [Float] = [0.8, 0.2, 0.3, 0.2]
        let searchResults = try await vectorStore.search(query: queryVector, topK: 3)
        #expect(searchResults.count == 3, "Should return top 3 matches")
        #expect(searchResults[0].id == "breathe",
                "Closest match to breathing-like query should be 'breathe'")

        // 4. Build RecommendationFeatures from search results and rank with RecRanker.
        let ranker = RecRanker()
        let candidates = searchResults.map { match in
            RecommendationFeatures(
                id: match.id,
                wellbeingScore: Double(match.score) * 0.5,
                evidenceStrength: 0.7,
                novelty: match.id == "breathe" ? 0.3 : 0.8,
                cooldown: 0.0,
                acceptanceRate: 0.5,
                timeCostFit: 0.6,
                zScores: ["z_hrv": Double(match.score) * 0.2]
            )
        }
        let ranked = await ranker.rank(candidates)
        #expect(ranked.count == 3, "Ranked list should preserve all candidates")

        // 5. Record initial weights.
        let metricsBefore = await ranker.getPerformanceMetrics()

        // 6. Simulate user accepting the top recommendation (feedback update).
        //    ranked[0] and ranked[last] will differ on novelty (and possibly other features),
        //    so the pairwise gradient will produce non-zero weight updates.
        let preferred = ranked[0]
        let other = ranked[ranked.count - 1]
        await ranker.update(preferred: preferred, other: other)

        // 7. Verify weights changed after feedback.
        //    The update modifies weights for features that differ between preferred and other.
        let metricsAfter = await ranker.getPerformanceMetrics()
        #expect(metricsBefore.weights != metricsAfter.weights,
                "Weights should change after pairwise update feedback")

        // 8. Verify state can be persisted and restored.
        let state = await ranker.snapshotState()
        let restoredRanker = RecRanker(state: state)
        let restoredMetrics = await restoredRanker.getPerformanceMetrics()
        #expect(restoredMetrics.weights == metricsAfter.weights,
                "Restored ranker should have identical weights")
        #expect(restoredMetrics.learningRate == metricsAfter.learningRate,
                "Restored ranker should have identical learning rate")
    }

    /// Verify that VectorStore persistence round-trips correctly.
    @Test("VectorStore persist and reload preserves data")
    func test_vectorStore_persistAndReload() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("VectorStoreRoundTrip-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let storeURL = tempDir.appendingPathComponent("vectors.bin")

        // Write vectors to store and persist.
        let store1 = VectorStore(fileURL: storeURL, dimension: 4)
        try await store1.upsert(id: "alpha", vector: [1.0, 0.0, 0.0, 0.0])
        try await store1.upsert(id: "beta", vector: [0.0, 1.0, 0.0, 0.0])
        try await store1.persist()

        // Reload from disk in a new VectorStore instance.
        let store2 = VectorStore(fileURL: storeURL, dimension: 4)
        let stats = await store2.stats()
        #expect(stats.items == 2, "Reloaded store should have 2 items")

        let results = try await store2.search(query: [1.0, 0.0, 0.0, 0.0], topK: 1)
        #expect(results.first?.id == "alpha", "Should find 'alpha' as closest to [1,0,0,0]")
    }

    /// Verify RecRanker learning rate adapts over multiple feedback rounds.
    @Test("RecRanker adapts learning rate through acceptance history")
    func test_rankerLearningRateAdaptation() async throws {
        let ranker = RecRanker()

        // Low acceptance → higher exploration rate.
        await ranker.updateLearningRate(basedOn: AcceptanceHistory(
            rollingAcceptance: 0.2, sampleCount: 20
        ))
        let lowMetrics = await ranker.getPerformanceMetrics()
        #expect(abs(lowMetrics.learningRate - 0.07) < 0.001,
                "Low acceptance should set learning rate to 0.07")

        // High acceptance → lower, more conservative rate.
        await ranker.updateLearningRate(basedOn: AcceptanceHistory(
            rollingAcceptance: 0.9, sampleCount: 20
        ))
        let highMetrics = await ranker.getPerformanceMetrics()
        #expect(abs(highMetrics.learningRate - 0.03) < 0.001,
                "High acceptance should set learning rate to 0.03")
    }
}
