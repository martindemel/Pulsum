import Testing
import Foundation
@testable import PulsumML

private func makeTopicGateProvider() -> EmbeddingTopicGateProvider {
    let embeddingService = EmbeddingService.debugInstance(
        primary: KeywordEmbeddingProvider(dimension: 4),
        fallback: nil,
        dimension: 4
    )
    return EmbeddingTopicGateProvider(embeddingService: embeddingService)
}

/// Tests for TopicGate providers (on-device topical guardrail)
struct TopicGateTests {

    @Test("Embedding fallback classifies on-topic wellbeing queries")
    func embeddingFallbackOnTopic() async throws {
        let provider = makeTopicGateProvider()

        let onTopicQueries = [
            "I'm feeling stressed today, what should I do?",
            "My sleep has been poor lately",
            "I need help managing my energy levels",
            "How can I improve my HRV?",
            "My mood is low and I'm anxious"
        ]

        for query in onTopicQueries {
            let decision = try await provider.classify(query)
            #expect(decision.isOnTopic, "Expected '\(query)' to be classified as on-topic")
            #expect(decision.confidence > 0.5, "Expected confidence > 0.5 for on-topic query")
        }
    }

    @Test("Embedding fallback classifies off-topic queries")
    func embeddingFallbackOffTopic() async throws {
        let provider = makeTopicGateProvider()

        let offTopicQueries = [
            "Calculate the prime factors of 512",
            "Where to find the best pizza recipe",
            "Schedule for city subway trains",
            "Plan my taxes for 2025",
            "Explain quantum entanglement"
        ]

        for query in offTopicQueries {
            let decision = try await provider.classify(query)
            #expect(!decision.isOnTopic, "Expected off-topic for: \(query)")
        }
    }

    @Test("Greetings are treated generously")
    func greetingsOnTopic() async throws {
        let provider = makeTopicGateProvider()

        let greetings = [
            "hi",
            "hello",
            "hey there",
            "good morning",
            "how are you?"
        ]

        for greeting in greetings {
            let decision = try await provider.classify(greeting)
            // Greetings should have moderate similarity to wellbeing topics
            #expect(decision.confidence >= 0.3, "Expected greetings to have reasonable confidence")
        }
    }

    @Test("Empty input fails gracefully")
    func emptyInputHandling() async throws {
        let provider = makeTopicGateProvider()
        let decision = try await provider.classify("")

        // Empty input should fail-closed (off-topic)
        #expect(!decision.isOnTopic, "Expected empty input to be classified as off-topic")
    }

    @Test("Sleep coaching query maps to sleep topic")
    func sleepQueryMapsToSleepTopic() async throws {
        let provider = makeTopicGateProvider()
        let decision = try await provider.classify("How to improve sleep")
        #expect(decision.isOnTopic)
        #expect(decision.topic == "sleep")
        #expect(decision.confidence >= 0.59)
    }

    @Test("Motivation query maps to goals domain")
    func motivationQueryMapsToGoals() async throws {
        let provider = makeTopicGateProvider()
        let decision = try await provider.classify("How can I keep motivated lately")
        #expect(decision.isOnTopic)
        #expect(decision.topic == "goals" || decision.topic == "energy")
        #expect(decision.confidence >= 0.59)
    }

    @Test("Margin guard rejects near-threshold off-topic")
    func marginGuardRejectsOffTopic() async throws {
        let provider = makeTopicGateProvider()
        let scores = try await provider.debugScores(for: "Calculate the prime factors of 512")
        #expect(scores.margin < 0.12)
    }

#if canImport(FoundationModels) && os(iOS)
    @available(iOS 26.0, *)
    @Test("Foundation Models provider requires availability")
    func foundationModelsRequiresAvailability() async throws {
        let provider = FoundationModelsTopicGateProvider()

        // Test should gracefully handle unavailable models
        do {
            _ = try await provider.classify("test input")
            // If we reach here, model is available (test environment specific)
        } catch TopicGateError.modelUnavailable {
            // Expected in environments without Apple Intelligence
            #expect(true)
        } catch {
            throw error // Unexpected error
        }
    }
#endif
}

private struct ConstantEmbeddingProvider: TextEmbeddingProviding {
    let dimension: Int

    func embedding(for text: String) throws -> [Float] {
        var vector = [Float](repeating: 0, count: dimension)
        let lower = text.lowercased()
        if lower.contains("sleep") {
            vector[0] = 1
        } else if lower.contains("stress") || lower.contains("anxious") || lower.contains("anxiety") {
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

private typealias KeywordEmbeddingProvider = ConstantEmbeddingProvider
