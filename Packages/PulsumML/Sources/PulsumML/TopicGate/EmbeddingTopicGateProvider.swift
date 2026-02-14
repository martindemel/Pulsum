import Foundation
import os

/// Fallback topic gate using embedding similarity against wellbeing knowledge base
public final class EmbeddingTopicGateProvider: TopicGateProviding, @unchecked Sendable {
    private let embeddingService: EmbeddingService
    private let wellbeingPrototypes: [WellbeingPrototype]
    private let oodPrototypes: [[Float]]
    private let logger = Logger(subsystem: "com.pulsum", category: "EmbeddingTopicGateProvider")

    private let OOD_MARGIN: Float = 0.12
    private let ON_TOPIC_THRESHOLD: Float = 0.59

    private struct WellbeingPrototype {
        let text: String
        let embedding: [Float]
        let topic: String? // Canonical topic or nil for greetings
    }

    private static let OOD_PROTOTYPES: [String] = [
        "prime factors",
        "matrix multiplication",
        "calculus",
        "pizza recipe",
        "restaurant menu",
        "cooking recipe",
        "subway schedule",
        "train timetable",
        "crypto price",
        "tax filing",
        "budget planning",
        "python code",
        "swift algorithm",
        "weather forecast",
        "stock ticker"
    ]

    public init(embeddingService: EmbeddingService = .shared) {
        self.embeddingService = embeddingService

        // Wellbeing knowledge base prototypes with canonical topics
        let prototypeData: [(text: String, topic: String?)] = [
            ("stress management breathing relaxation anxiety", "stress"),
            ("sleep quality rest recovery insomnia fatigue fall asleep can't sleep sleep better sleep hygiene", "sleep"),
            ("energy vitality mood motivation movement exercise motivation motivated momentum keep going stick with consistency", "energy"),
            ("heart rate variability HRV health metrics rmssd vagal tone parasympathetic recovery", "hrv"),
            ("mental health wellbeing self-care support", "mood"),
            ("physical activity steps walking fitness", "movement"),
            ("meditation mindfulness grounding calm", "mindfulness"),
            ("journal feelings emotions reflection", "mood"),
            ("health goals wellness habits routine motivation motivated momentum keep going stick with consistency", "goals"),
            ("micro-moment micromoment micro activity quick action nudge habit tiny step", "goals"),
            ("hi coach hello coach hey pulsum good morning coach", nil) // Greetings have no topic
        ]

        self.wellbeingPrototypes = prototypeData.compactMap { text, topic in
            guard let embedding = try? embeddingService.embedding(for: text) else { return nil }
            return WellbeingPrototype(
                text: text,
                embedding: embedding,
                topic: topic
            )
        }

        self.oodPrototypes = Self.OOD_PROTOTYPES.compactMap { try? embeddingService.embedding(for: $0) }
    }

    public func classify(_ text: String) async throws -> GateDecision {
        let decision = computeDecision(for: text.lowercased())
        return decision.decision
    }

    #if DEBUG
    func debugScores(for text: String) async throws -> (domain: Double, ood: Double, margin: Double, topic: String?) {
        let decision = computeDecision(for: text.lowercased())
        return (
            domain: Double(decision.domainScore),
            ood: Double(decision.oodScore),
            margin: Double(decision.domainScore - decision.oodScore),
            topic: decision.topic
        )
    }
    #endif

    private func cosineSimilarity(_ lhs: [Float], _ rhs: [Float]) -> Float {
        guard lhs.count == rhs.count else { return 0 }
        var dot: Float = 0
        var lhsNorm: Float = 0
        var rhsNorm: Float = 0
        for index in 0 ..< lhs.count {
            dot += lhs[index] * rhs[index]
            lhsNorm += lhs[index] * lhs[index]
            rhsNorm += rhs[index] * rhs[index]
        }
        let denominator = sqrt(lhsNorm) * sqrt(rhsNorm)
        guard denominator > 0 else { return 0 }
        return dot / denominator
    }

    private func computeDecision(for text: String) -> (decision: GateDecision, domainScore: Float, oodScore: Float, topic: String?) {
        guard
            let inputEmbedding = try? embeddingService.embedding(for: text),
            inputEmbedding.contains(where: { $0 != 0 }),
            !wellbeingPrototypes.isEmpty,
            !oodPrototypes.isEmpty
        else {
            #if DEBUG
            logger.debug("Topic gate degraded: embedding unavailable or prototypes empty (wellbeing=\(self.wellbeingPrototypes.count, privacy: .public), ood=\(self.oodPrototypes.count, privacy: .public)).")
            #endif
            let decision = GateDecision(
                isOnTopic: false,
                reason: "Unable to embed input text",
                confidence: 0.5,
                topic: nil
            )
            return (decision, 0, 0, nil)
        }

        let similaritiesWithPrototypes = wellbeingPrototypes.map { prototype in
            (similarity: cosineSimilarity(inputEmbedding, prototype.embedding), prototype: prototype)
        }

        guard let bestMatch = similaritiesWithPrototypes.max(by: { $0.similarity < $1.similarity }) else {
            let decision = GateDecision(
                isOnTopic: false,
                reason: "No prototype matches found",
                confidence: 0.0,
                topic: nil
            )
            return (decision, 0, 0, nil)
        }

        let domainScore = bestMatch.similarity
        let matchedTopic = bestMatch.prototype.topic
        let oodScore = computeOODScore(for: inputEmbedding)
        let marginOK = (domainScore - oodScore) >= OOD_MARGIN

        let isGreeting = (matchedTopic == nil)
        let isOnTopic: Bool

        if isGreeting {
            isOnTopic = domainScore >= 0.3 // greetings stay permissive as before
        } else {
            isOnTopic = domainScore >= ON_TOPIC_THRESHOLD && marginOK
        }

        let reason: String
        if isOnTopic {
            if isGreeting {
                reason = "Greeting detected (similarity: \(String(format: "%.2f", domainScore)))"
            } else {
                reason = "Input matches wellbeing topics (sim: \(String(format: "%.2f", domainScore))) with margin \(String(format: "%.2f", domainScore - oodScore))"
            }
        } else {
            reason = "Input outside wellbeing margin (domain: \(String(format: "%.2f", domainScore)), ood: \(String(format: "%.2f", oodScore)))"
        }

        let gateDecision = GateDecision(
            isOnTopic: isOnTopic,
            reason: reason,
            confidence: Double(domainScore),
            topic: isOnTopic ? matchedTopic : nil
        )

        return (gateDecision, domainScore, oodScore, matchedTopic)
    }

    private func computeOODScore(for embedding: [Float]) -> Float {
        var maxSimilarity: Float = 0
        for prototype in oodPrototypes {
            let similarity = cosineSimilarity(embedding, prototype)
            if similarity > maxSimilarity {
                maxSimilarity = similarity
            }
        }
        return maxSimilarity
    }
}
