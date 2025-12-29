import Testing
@testable import PulsumML

private func makeMarginTopicGateProvider() -> EmbeddingTopicGateProvider {
    let embeddingService = EmbeddingService.debugInstance(
        primary: KeywordEmbeddingProvider(dimension: 4),
        fallback: nil,
        dimension: 4
    )
    return EmbeddingTopicGateProvider(embeddingService: embeddingService)
}

struct TopicGateMarginTests {

    @Test("Topic gate margin telemetry")
    func topicGateMarginTelemetry() async throws {
        let provider = makeMarginTopicGateProvider()
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
            #expect(scores.margin >= 0.12)
        }

        for text in offTopic {
            let scores = try await provider.debugScores(for: text)
            #expect(scores.margin < 0.12)
        }
    }
}

private struct KeywordEmbeddingProvider: TextEmbeddingProviding {
    let dimension: Int

    func embedding(for text: String) throws -> [Float] {
        var vector = [Float](repeating: 0, count: dimension)
        let lower = text.lowercased()
        if lower.contains("sleep") {
            vector[0] = 1
        } else if lower.contains("stress") || lower.contains("anxious") {
            vector[1] = 1
        } else if lower.contains("energy") || lower.contains("motiv") {
            vector[2] = 1
        } else if lower.contains("hrv") {
            vector[3] = 1
        }
        if vector.allSatisfy({ $0 == 0 }) {
            vector = Array(repeating: 0.1, count: dimension)
        }
        return vector
    }
}
