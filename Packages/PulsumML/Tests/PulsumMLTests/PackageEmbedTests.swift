import XCTest
@testable import PulsumML

final class PackageEmbedTests: XCTestCase {
    func testVersionStringIsPresent() {
        XCTAssertFalse(PulsumML.version.isEmpty)
    }

    func testEmbeddingDimensionIs384() {
        let vector = PulsumML.embedding(for: "Calm breathing exercise and gentle walk")
        XCTAssertEqual(vector.count, 384)
    }

    func testSegmentEmbeddingAveragesVectors() {
        let vector = PulsumML.embedding(forSegments: ["sleep hygiene", "low HRV"])
        XCTAssertEqual(vector.count, 384)
    }

    func testRobustStatsMedianAndZScore() {
        let values: [Double] = [50, 52, 49, 80, 51, 48, 47]
        guard let stats = BaselineMath.robustStats(for: values) else {
            XCTFail("Stats should not be nil")
            return
        }
        let z = BaselineMath.zScore(value: 80, stats: stats)
        XCTAssertGreaterThan(z, 2.0)
    }
    func testStateEstimatorUpdatesWeights() {
        let estimator = StateEstimator()
        let features = [
            "z_hrv": -1.0,
            "subj_stress": 2.0,
            "subj_energy": -1.0
        ]
        let snapshotBefore = estimator.currentSnapshot(features: features)
        let updated = estimator.update(features: features, target: 1.0)
        XCTAssertNotEqual(snapshotBefore.weights, updated.weights)
    }

    func testRecRankerPrefersHigherEvidence() {
        let ranker = RecRanker()
        let strong = RecommendationFeatures(id: "strong",
                                            wellbeingScore: -0.5,
                                            evidenceStrength: 1.0,
                                            novelty: 0.5,
                                            cooldown: 0.0,
                                            acceptanceRate: 0.5,
                                            timeCostFit: 0.8)
        let weak = RecommendationFeatures(id: "weak",
                                          wellbeingScore: -0.5,
                                          evidenceStrength: 0.2,
                                          novelty: 0.3,
                                          cooldown: 0.0,
                                          acceptanceRate: 0.5,
                                          timeCostFit: 0.8)
        let ranked = ranker.rank([weak, strong])
        XCTAssertEqual(ranked.first?.id, "strong")
    }

    func testSafetyLocalDetectsCrisisLanguage() {
        let safety = SafetyLocal()
        let classification = safety.classify(text: "I am thinking about suicide tonight")
        switch classification {
        case .crisis:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected crisis classification")
        }
    }
}
