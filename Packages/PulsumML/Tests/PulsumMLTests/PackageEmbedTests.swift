import XCTest
@testable import PulsumML

final class PackageEmbedTests: XCTestCase {
    func testVersionStringIsPresent() {
        XCTAssertFalse(PulsumML.version.isEmpty)
    }

    func testEmbeddingDimensionIs384() throws {
        let provider = ConstantEmbeddingProvider(vector: Array(repeating: Float(0.5), count: 384))
        let service = EmbeddingService.debugInstance(primary: provider, fallback: nil, dimension: 384)
        let vector = try service.embedding(for: "Calm breathing exercise and gentle walk")
        XCTAssertEqual(vector.count, 384)
    }

    func testSegmentEmbeddingAveragesVectors() throws {
        let vectors: [String: [Float]] = [
            "sleep hygiene": Array(repeating: Float(1), count: 384),
            "low HRV": Array(repeating: Float(3), count: 384)
        ]
        let provider = MappingEmbeddingProvider(map: vectors)
        let service = EmbeddingService.debugInstance(primary: provider, fallback: nil, dimension: 384)
        let vector = try service.embedding(forSegments: ["sleep hygiene", "low HRV"])
        XCTAssertEqual(vector.count, 384)
        XCTAssertEqual(vector.first, 2)
    }

    func testCoreMLFallbackModelIsBundled() throws {
        // Ensures the packaged Core ML embedding exists and yields a non-zero vector.
        if #available(iOS 17.0, macOS 13.0, *) {
            do {
                let provider = CoreMLEmbeddingFallbackProvider()
                let vector = try provider.embedding(for: "pulsum bundle availability")
                XCTAssertEqual(vector.count, 384)
                XCTAssertFalse(vector.allSatisfy { $0 == 0 })
            } catch EmbeddingError.generatorUnavailable {
                throw XCTSkip("Core ML fallback embedding unavailable in this environment.")
            }
        } else {
            throw XCTSkip("Core ML fallback requires at least iOS 17 / macOS 13.")
        }
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
    func testStateEstimatorUpdatesWeights() async {
        let estimator = StateEstimator()
        let features = [
            "z_hrv": -1.0,
            "subj_stress": 2.0,
            "subj_energy": -1.0
        ]
        let snapshotBefore = await estimator.currentSnapshot(features: features)
        let updated = await estimator.update(features: features, target: 1.0)
        XCTAssertNotEqual(snapshotBefore.weights, updated.weights)
    }

    func testRecRankerPrefersHigherEvidence() async {
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
        let ranked = await ranker.rank([weak, strong])
        XCTAssertEqual(ranked.first?.id, "strong")
    }

    func testSafetyLocalDetectsCrisisLanguage() async {
        let safety = SafetyLocal()
        let classification = await safety.classify(text: "I am thinking about suicide tonight")
        switch classification {
        case .crisis:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected crisis classification")
        }
    }

    func testAvailabilityModeReportsUnavailableWhenProvidersFail() async {
        let provider = FailingEmbeddingProvider()
        let service = EmbeddingService.debugInstance(primary: provider,
                                                     fallback: nil,
                                                     dimension: 384,
                                                     reprobeInterval: 0,
                                                     dateProvider: { Date() })
        let mode = await service.availabilityMode()
        XCTAssertEqual(mode, .unavailable)
    }
}

private struct ConstantEmbeddingProvider: TextEmbeddingProviding {
    let vector: [Float]

    func embedding(for text: String) throws -> [Float] {
        vector
    }
}

private struct FailingEmbeddingProvider: TextEmbeddingProviding {
    func embedding(for text: String) throws -> [Float] {
        throw EmbeddingError.generatorUnavailable
    }
}

private struct MappingEmbeddingProvider: TextEmbeddingProviding {
    let map: [String: [Float]]

    func embedding(for text: String) throws -> [Float] {
        guard let vector = map[text] else {
            throw EmbeddingError.generatorUnavailable
        }
        return vector
    }
}
