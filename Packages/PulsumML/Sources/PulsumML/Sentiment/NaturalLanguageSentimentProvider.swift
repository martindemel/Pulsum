import Foundation
import NaturalLanguage

final class NaturalLanguageSentimentProvider: SentimentProviding {
    func sentimentScore(for text: String) async throws -> Double {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SentimentProviderError.insufficientInput }
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = trimmed
        let (tag, _) = tagger.tag(at: trimmed.startIndex, unit: .paragraph, scheme: .sentimentScore)
        guard let rawValue = tag?.rawValue, let score = Double(rawValue) else {
            throw SentimentProviderError.unavailable
        }
        return max(min(score, 1), -1)
    }
}
