import Foundation
import NaturalLanguage
import PulsumTypes

/// Opportunistic AFM/NL embedding provider.
///
/// This provider only attempts contextual embeddings when Apple Intelligence reports `.ready`.
/// On failure (or platforms without FoundationModels), it throws `generatorUnavailable` so callers
/// can fall back to the Core ML provider without masking errors.
///
/// **Dimension handling:** NLEmbedding.sentenceEmbedding produces 512-dim vectors;
/// wordEmbedding produces 300-dim vectors. When the native dimension differs from
/// `targetDimension` (384), the vector is truncated (if larger) or zero-padded (if smaller).
/// Truncation discards trailing dimensions which are typically lower-variance in NL embeddings.
/// Zero-padding preserves the original signal and adds inert dimensions.
/// Vectors from different sources (sentence vs word) are NOT mixed in the same space.
@available(iOS 17.0, macOS 13.0, *)
final class AFMTextEmbeddingProvider: TextEmbeddingProviding {
    private let targetDimension = 384
    private let availability: @Sendable () -> AFMStatus

    init(availability: @escaping @Sendable () -> AFMStatus = FoundationModelsAvailability.checkAvailability) {
        self.availability = availability
    }

    func embedding(for text: String) throws -> [Float] {
        let language = resolveLanguage()

        // Prefer sentence embedding (512-dim). Fall back to word embedding (300-dim) only
        // when sentence embedding is unavailable for the resolved language.
        let embedding: NLEmbedding
        if let sentence = NLEmbedding.sentenceEmbedding(for: language) {
            embedding = sentence
        } else if let sentenceEnglish = NLEmbedding.sentenceEmbedding(for: .english), language != .english {
            Diagnostics.log(
                level: .warn,
                category: .embeddings,
                name: "SentenceEmbeddingLanguageFallback",
                fields: ["requestedLanguage": .safeString(.metadata(language.rawValue))]
            )
            embedding = sentenceEnglish
        } else if let word = NLEmbedding.wordEmbedding(for: language) {
            Diagnostics.log(
                level: .warn,
                category: .embeddings,
                name: "WordEmbeddingFallback",
                fields: [
                    "reason": .safeString(.literal("Sentence embedding unavailable")),
                    "language": .safeString(.metadata(language.rawValue)),
                    "nativeDimension": .int(300),
                    "targetDimension": .int(targetDimension),
                ]
            )
            embedding = word
        } else if let wordEnglish = NLEmbedding.wordEmbedding(for: .english), language != .english {
            Diagnostics.log(
                level: .warn,
                category: .embeddings,
                name: "WordEmbeddingLanguageFallback",
                fields: ["requestedLanguage": .safeString(.metadata(language.rawValue))]
            )
            embedding = wordEnglish
        } else {
            throw EmbeddingError.generatorUnavailable
        }

        guard let vector = embedding.vector(for: text), !vector.isEmpty else {
            throw EmbeddingError.generatorUnavailable
        }

        let floats = vector.map { Float($0) }
        let adjusted = adjustDimension(floats)
        guard adjusted.contains(where: { $0 != 0 }) else {
            throw EmbeddingError.emptyResult
        }
        return adjusted
    }

    /// Resolves the NLLanguage to use based on the user's current locale.
    /// Falls back to English if the locale language code cannot be mapped.
    private func resolveLanguage() -> NLLanguage {
        guard let languageCode = Locale.current.language.languageCode else {
            return .english
        }
        let nlLanguage = NLLanguage(languageCode.identifier)
        return nlLanguage
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
