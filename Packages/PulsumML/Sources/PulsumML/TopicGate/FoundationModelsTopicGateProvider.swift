import Foundation

#if canImport(FoundationModels) && os(iOS)
import FoundationModels

@available(iOS 26.0, *)
@Generable
public struct OnTopic: Codable, Sendable {
    public let isOnTopic: Bool
    public let confidence: Double // 0...1
    public let reason: String

    public init(isOnTopic: Bool, confidence: Double, reason: String) {
        self.isOnTopic = isOnTopic
        self.confidence = confidence
        self.reason = reason
    }
}

@available(iOS 26.0, *)
public final class FoundationModelsTopicGateProvider: TopicGateProviding {
    private let session: LanguageModelSession

    public init() {
        self.session = LanguageModelSession(
            instructions: Instructions("""
            You are a topic classifier for a wellbeing coaching app.
            Classify whether user input is on-topic (relevant to health, wellness, stress, sleep, energy, mood, movement, or personal wellbeing).
            Off-topic examples: general knowledge questions, weather, news, entertainment, unrelated chitchat.
            On-topic examples: questions about stress management, sleep advice, energy levels, health metrics, emotional support.
            Return your classification with confidence (0.0 to 1.0) and a brief reason.
            Be generous with greetings—"hi", "hello", "how are you" should be considered on-topic with moderate confidence (0.7).
            """)
        )
    }

    public func classify(_ text: String) async throws -> GateDecision {
        guard SystemLanguageModel.default.isAvailable else {
            throw TopicGateError.modelUnavailable
        }

        let result = try await session.respond(
            to: Prompt("Classify: '\(text)'"),
            generating: OnTopic.self,
            options: GenerationOptions(temperature: 0.1)
        )

        return GateDecision(
            isOnTopic: result.content.isOnTopic,
            reason: result.content.reason,
            confidence: result.content.confidence
        )
    }
}

@available(iOS 26.0, *)
extension FoundationModelsTopicGateProvider: @unchecked Sendable {}
#else
public final class FoundationModelsTopicGateProvider: TopicGateProviding {
    private let local = EmbeddingTopicGateProvider()

    public init() {}

    public func classify(_ text: String) async throws -> GateDecision {
        try await local.classify(text)
    }
}

extension FoundationModelsTopicGateProvider: @unchecked Sendable {}
#endif

public enum TopicGateError: LocalizedError {
    case modelUnavailable

    public var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "Foundation Models is not available for topic classification."
        }
    }
}
