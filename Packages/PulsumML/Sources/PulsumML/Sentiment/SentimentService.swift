import Foundation

public final class SentimentService {
    private let providers: [SentimentProviding]

    public init(providers: [SentimentProviding]? = nil) {
        if let providers, !providers.isEmpty {
            self.providers = providers
        } else {
            var stack: [SentimentProviding] = []
            // Prefer Foundation Models when available
            if #available(iOS 26.0, *) {
                stack.append(FoundationModelsSentimentProvider())
            }
            stack.append(AFMSentimentProvider())
            if let coreML = CoreMLSentimentProvider() {
                stack.append(coreML)
            }
            stack.append(NaturalLanguageSentimentProvider())
            self.providers = stack
        }
    }

    public func sentiment(for text: String) async -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }

        for provider in providers {
            do {
                let score = try await provider.sentimentScore(for: trimmed)
                return max(min(score, 1), -1)
            } catch SentimentProviderError.insufficientInput {
                continue
            } catch {
                continue
            }
        }
        return nil
    }
}

// SAFETY: All stored properties are immutable (`let`). `providers` is set once in init
// and never mutated. SentimentProviding implementors are stateless or internally synchronized.
extension SentimentService: @unchecked Sendable {}
