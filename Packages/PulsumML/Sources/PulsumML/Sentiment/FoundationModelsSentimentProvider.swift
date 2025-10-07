import Foundation
#if canImport(FoundationModels) && os(iOS)
import FoundationModels

@available(iOS 26.0, *)
@Generable enum SentimentLabel: String, CaseIterable {
    case positive, neutral, negative
}

@available(iOS 26.0, *)
@Generable struct SentimentAnalysis {
    @Guide(description: "Sentiment classification: positive, neutral, or negative")
    let label: SentimentLabel
    @Guide(description: "Confidence score between -1.0 (very negative) and 1.0 (very positive)")
    let score: Double
}

@available(iOS 26.0, *)
final class FoundationModelsSentimentProvider: SentimentProviding {
    private let model = SystemLanguageModel.default
    
    func sentimentScore(for text: String) async throws -> Double {
        guard model.isAvailable else {
            throw SentimentProviderError.unavailable
        }
        
        let session = LanguageModelSession(
            instructions: Instructions("""
            Analyze the sentiment of user text with high precision.
            Return a score between -1.0 (very negative) and 1.0 (very positive).
            Consider emotional tone, stress indicators, and overall mood.
            Be calibrated: 0.0 is truly neutral, ±0.3 is mild, ±0.7 is strong, ±1.0 is extreme.
            """)
        )
        
        do {
            let result = try await session.respond(
                to: Prompt("Analyze sentiment of this text: \(text)"),
                generating: SentimentAnalysis.self,
                options: GenerationOptions(temperature: 0.1)
            )
            return max(min(result.content.score, 1.0), -1.0)
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            // If guardrails triggered, text might be too sensitive - return neutral
            return 0.0
        } catch LanguageModelSession.GenerationError.refusal {
            // Model refused to analyze - return neutral
            return 0.0
        } catch {
            throw SentimentProviderError.unavailable
        }
    }
}
#else
final class FoundationModelsSentimentProvider: SentimentProviding {
    func sentimentScore(for text: String) async throws -> Double {
        throw SentimentProviderError.unavailable
    }
}
#endif
