import Testing
@testable import PulsumML

struct RecRankerTests {
    @Test("adaptWeights changes weights in expected direction")
    func test_adaptWeights_changesWeights() async {
        let ranker = RecRanker()
        let metricsBefore = await ranker.getPerformanceMetrics()
        let originalEvidence = metricsBefore.weights["evidence"] ?? 0

        await ranker.adaptWeights(from: [
            UserFeedback(featureId: "evidence", delta: 0.2),
        ])

        let metricsAfter = await ranker.getPerformanceMetrics()
        let updatedEvidence = metricsAfter.weights["evidence"] ?? 0
        #expect(abs(updatedEvidence - (originalEvidence + 0.2)) < 0.001,
                "Weight should increase by the feedback delta")
    }

    @Test("adaptWeights with empty feedback is a no-op")
    func test_adaptWeights_emptyFeedback() async {
        let ranker = RecRanker()
        let metricsBefore = await ranker.getPerformanceMetrics()

        await ranker.adaptWeights(from: [])

        let metricsAfter = await ranker.getPerformanceMetrics()
        #expect(metricsBefore.weights == metricsAfter.weights)
    }

    @Test("adaptWeights clamps to weight cap")
    func test_adaptWeights_clampedToWeightCap() async {
        let ranker = RecRanker()

        // Push weight far beyond the 3.0 cap
        await ranker.adaptWeights(from: [
            UserFeedback(featureId: "evidence", delta: 100.0),
        ])

        let metrics = await ranker.getPerformanceMetrics()
        let evidence = metrics.weights["evidence"] ?? 0
        #expect(evidence <= 3.0, "Weight should be clamped at 3.0")
    }

    @Test("updateLearningRate adjusts rate for low acceptance")
    func test_updateLearningRate_lowAcceptance() async {
        let ranker = RecRanker()

        // Low acceptance with enough samples → higher learning rate (0.07)
        await ranker.updateLearningRate(basedOn: AcceptanceHistory(
            rollingAcceptance: 0.2, sampleCount: 20
        ))

        let metrics = await ranker.getPerformanceMetrics()
        #expect(abs(metrics.learningRate - 0.07) < 0.001)
    }

    @Test("updateLearningRate adjusts rate for high acceptance")
    func test_updateLearningRate_highAcceptance() async {
        let ranker = RecRanker()

        // High acceptance with enough samples → lower learning rate (0.03)
        await ranker.updateLearningRate(basedOn: AcceptanceHistory(
            rollingAcceptance: 0.9, sampleCount: 20
        ))

        let metrics = await ranker.getPerformanceMetrics()
        #expect(abs(metrics.learningRate - 0.03) < 0.001)
    }

    @Test("updateLearningRate with few samples uses exploration rate")
    func test_updateLearningRate_fewSamples() async {
        let ranker = RecRanker()

        // Fewer than 10 samples → exploration rate (0.08)
        await ranker.updateLearningRate(basedOn: AcceptanceHistory(
            rollingAcceptance: 0.5, sampleCount: 5
        ))

        let metrics = await ranker.getPerformanceMetrics()
        #expect(abs(metrics.learningRate - 0.08) < 0.001)
    }

    @Test("updateLearningRate with normal acceptance keeps default")
    func test_updateLearningRate_normalAcceptance() async {
        let ranker = RecRanker()

        // Normal range with enough samples → default rate (0.05)
        await ranker.updateLearningRate(basedOn: AcceptanceHistory(
            rollingAcceptance: 0.55, sampleCount: 20
        ))

        let metrics = await ranker.getPerformanceMetrics()
        #expect(abs(metrics.learningRate - 0.05) < 0.001)
    }
}
