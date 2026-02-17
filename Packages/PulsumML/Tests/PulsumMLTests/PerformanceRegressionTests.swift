import XCTest
@testable import PulsumML

/// B6-14 | LOW-20: Performance regression tests for ML operations.
///
/// These tests establish performance baselines to catch regressions in
/// latency-critical paths. Use `measure {}` to record timings automatically.
final class PerformanceRegressionTests: XCTestCase {

    // MARK: - Safety Classification Performance

    func testSafetyClassificationLatency() async throws {
        let classifier = SafetyLocal()

        let sampleTexts = [
            "I had a great day today and went for a walk in the park",
            "I'm feeling really stressed about work deadlines",
            "The weather was beautiful and I enjoyed my morning coffee",
            "I've been sleeping poorly and feeling exhausted lately",
            "My meditation practice has been helping me stay centered",
        ]

        measure {
            let exp = expectation(description: "classify")
            Task {
                for text in sampleTexts {
                    _ = await classifier.classify(text: text)
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: 10.0)
        }
    }

    // MARK: - RecRanker Performance

    func testRecRankerRankingLatency() async throws {
        let ranker = RecRanker()

        // Create a realistic set of candidates (20 micro-moments).
        let candidates = (0 ..< 20).map { i in
            RecommendationFeatures(
                id: "moment-\(i)",
                wellbeingScore: Double(i) * 0.05 - 0.5,
                evidenceStrength: Double.random(in: 0.2 ... 0.9),
                novelty: Double.random(in: 0.1 ... 1.0),
                cooldown: Double.random(in: 0.0 ... 0.5),
                acceptanceRate: Double.random(in: 0.1 ... 0.9),
                timeCostFit: Double.random(in: 0.2 ... 0.8),
                zScores: [
                    "z_hrv": Double.random(in: -2.0 ... 2.0),
                    "z_nocthr": Double.random(in: -1.0 ... 1.0),
                    "z_resthr": Double.random(in: -1.0 ... 1.0),
                ]
            )
        }

        measure {
            let exp = expectation(description: "rank")
            Task {
                _ = await ranker.rank(candidates)
                exp.fulfill()
            }
            wait(for: [exp], timeout: 5.0)
        }
    }

    func testRecRankerUpdateLatency() async throws {
        let ranker = RecRanker()

        let preferred = RecommendationFeatures(
            id: "pref",
            wellbeingScore: 0.3,
            evidenceStrength: 0.8,
            novelty: 0.6,
            cooldown: 0.0,
            acceptanceRate: 0.7,
            timeCostFit: 0.5,
            zScores: ["z_hrv": 0.5, "z_nocthr": -0.2]
        )
        let other = RecommendationFeatures(
            id: "other",
            wellbeingScore: -0.2,
            evidenceStrength: 0.3,
            novelty: 0.2,
            cooldown: 0.4,
            acceptanceRate: 0.2,
            timeCostFit: 0.3,
            zScores: ["z_hrv": -0.3, "z_nocthr": 0.1]
        )

        measure {
            let exp = expectation(description: "update")
            Task {
                // Simulate 10 feedback rounds.
                for _ in 0 ..< 10 {
                    await ranker.update(preferred: preferred, other: other)
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: 5.0)
        }
    }
}
