import Foundation

final class AFMSentimentProvider: SentimentProviding {
    private let embeddingService: EmbeddingService
    private let positiveAnchors: [[Float]]
    private let negativeAnchors: [[Float]]

    init(embeddingService: EmbeddingService = .shared) {
        self.embeddingService = embeddingService
        let positives = [
            "I feel grounded and steady today.",
            "There's momentum building and I can sense the progress.",
            "I'm proud of the effort I put in.",
            "My energy feels balanced and supportive.",
            "I can see the habits working for me."
        ]
        let negatives = [
            "I'm overwhelmed and can't slow my thoughts.",
            "Everything feels heavy and unmanageable.",
            "I'm exhausted and running on fumes.",
            "It feels like I'm slipping backwards.",
            "I'm tense and can't shake the stress."
        ]
        positiveAnchors = positives.compactMap { try? embeddingService.embedding(for: $0) }
        negativeAnchors = negatives.compactMap { try? embeddingService.embedding(for: $0) }
    }

    func sentimentScore(for text: String) async throws -> Double {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.count > 2 else { throw SentimentProviderError.insufficientInput }
        guard !positiveAnchors.isEmpty, !negativeAnchors.isEmpty else {
            throw SentimentProviderError.unavailable
        }
        let embedding = try embeddingService.embedding(for: cleaned.lowercased())
        guard embedding.contains(where: { $0 != 0 }) else {
            throw SentimentProviderError.unavailable
        }

        let positive = averageSimilarity(for: embedding, anchors: positiveAnchors)
        let negative = averageSimilarity(for: embedding, anchors: negativeAnchors)
        let score = positive - negative
        return max(min(score, 1), -1)
    }

    private func averageSimilarity(for vector: [Float], anchors: [[Float]]) -> Double {
        guard !anchors.isEmpty else { return 0 }
        var total: Double = 0
        for anchor in anchors {
            total += Double(cosineSimilarity(vector, anchor))
        }
        return total / Double(anchors.count)
    }

    private func cosineSimilarity(_ lhs: [Float], _ rhs: [Float]) -> Float {
        guard lhs.count == rhs.count else { return 0 }
        var dot: Float = 0
        var lhsNorm: Float = 0
        var rhsNorm: Float = 0
        for idx in 0..<lhs.count {
            dot += lhs[idx] * rhs[idx]
            lhsNorm += lhs[idx] * lhs[idx]
            rhsNorm += rhs[idx] * rhs[idx]
        }
        let denominator = sqrt(lhsNorm) * sqrt(rhsNorm)
        guard denominator > 0 else { return 0 }
        return dot / denominator
    }
}
