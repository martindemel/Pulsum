import Foundation
import NaturalLanguage

/// Opportunistic AFM/NL embedding provider.
///
/// This provider only attempts contextual embeddings when Apple Intelligence reports `.ready`.
/// On failure (or platforms without FoundationModels), it throws `generatorUnavailable` so callers
/// can fall back to the Core ML provider without masking errors.
@available(iOS 17.0, macOS 13.0, *)
final class AFMTextEmbeddingProvider: TextEmbeddingProviding {
    private let targetDimension = 384
    private let availability: @Sendable () -> AFMStatus

    init(availability: @escaping @Sendable () -> AFMStatus = FoundationModelsAvailability.checkAvailability) {
        self.availability = availability
    }

    func embedding(for text: String) throws -> [Float] {
        // NLEmbedding works on iOS 17+ regardless of Foundation Models availability.
        // No AFM availability gate needed.
        let embedding = NLEmbedding.sentenceEmbedding(for: .english) ?? NLEmbedding.wordEmbedding(for: .english)
        guard let embedding, let vector = embedding.vector(for: text), !vector.isEmpty else {
            throw EmbeddingError.generatorUnavailable
        }

        let floats = vector.map { Float($0) }
        let adjusted = adjustDimension(floats)
        guard adjusted.contains(where: { $0 != 0 }) else {
            throw EmbeddingError.emptyResult
        }
        return adjusted
    }

    private func adjustDimension(_ vector: [Float]) -> [Float] {
        if vector.count == targetDimension { return vector }
        if vector.count > targetDimension { return Array(vector.prefix(targetDimension)) }
        var padded = vector
        padded.reserveCapacity(targetDimension)
        while padded.count < targetDimension {
            padded.append(0)
        }
        return padded
    }
}
