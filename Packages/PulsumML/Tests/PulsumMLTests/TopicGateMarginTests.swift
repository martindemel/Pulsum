import Testing
@testable import PulsumML

struct TopicGateMarginTests {

    @Test("Topic gate margin telemetry")
    func topicGateMarginTelemetry() async throws {
        let provider = EmbeddingTopicGateProvider()
        let onTopic = [
            "How to improve sleep",
            "Ideas to manage stress better",
            "Ways to keep my energy steady"
        ]
        let offTopic = [
            "Calculate the prime factors of 512",
            "Where to find the best pizza recipe",
            "Plan my taxes for 2025"
        ]

        for text in onTopic {
            let scores = try await provider.debugScores(for: text)
#if DEBUG
            print("[TopicGate margin] on-topic \(text) → domain=\(String(format: "%.3f", scores.domain)) ood=\(String(format: "%.3f", scores.ood)) margin=\(String(format: "%.3f", scores.margin))")
#endif
            #expect(scores.margin >= 0.12)
        }

        for text in offTopic {
            let scores = try await provider.debugScores(for: text)
#if DEBUG
            print("[TopicGate margin] off-topic \(text) → domain=\(String(format: "%.3f", scores.domain)) ood=\(String(format: "%.3f", scores.ood)) margin=\(String(format: "%.3f", scores.margin))")
#endif
            #expect(scores.margin < 0.12)
        }
    }
}
