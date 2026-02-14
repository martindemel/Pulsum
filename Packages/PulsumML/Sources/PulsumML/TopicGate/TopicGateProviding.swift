import Foundation

/// Decision from the topic gate classifier
public struct GateDecision: Sendable {
    public let isOnTopic: Bool
    public let reason: String
    public let confidence: Double
    public let topic: String? // Canonical topics: "sleep", "stress", "energy", "hrv", "mood", "movement",
    // "mindfulness", "goals", or nil for greetings

    public init(isOnTopic: Bool, reason: String, confidence: Double, topic: String? = nil) {
        self.isOnTopic = isOnTopic
        self.reason = reason
        self.confidence = confidence
        self.topic = topic
    }
}

/// Protocol for on-device topic classification
/// Validates whether user input is relevant to wellbeing coaching before cloud calls
public protocol TopicGateProviding: Sendable {
    /// Classify text as on-topic (wellbeing-related) or off-topic
    /// - Parameter text: User input to classify
    /// - Returns: Gate decision with topic classification and confidence
    func classify(_ text: String) async throws -> GateDecision
}
