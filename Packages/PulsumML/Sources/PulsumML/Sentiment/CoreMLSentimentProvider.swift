import Foundation
import NaturalLanguage
import CoreML

// SAFETY: NLModel is set once in init and never mutated — safe for concurrent reads.
final class CoreMLSentimentProvider: SentimentProviding, @unchecked Sendable {
    private let model: NLModel

    init?() {
        let bundle = Bundle.pulsumMLResources
        if let compiledURL = bundle.url(forResource: "PulsumSentimentCoreML", withExtension: "mlmodelc"),
           let nlModel = try? NLModel(contentsOf: compiledURL) {
            model = nlModel
        } else if let rawURL = bundle.url(forResource: "PulsumSentimentCoreML", withExtension: "mlmodel"),
                  let compiled = try? MLModel.compileModel(at: rawURL),
                  let nlModel = try? NLModel(contentsOf: compiled) {
            model = nlModel
        } else {
            return nil
        }
    }

    func sentimentScore(for text: String) async throws -> Double {
        guard let label = model.predictedLabel(for: text.lowercased()) else {
            throw SentimentProviderError.unavailable
        }
        let normalized = label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "positive":
            return 0.7
        case "negative":
            return -0.7
        case "neutral":
            return 0
        default:
            if let value = Double(normalized) {
                return max(min(value, 1), -1)
            }
            throw SentimentProviderError.unavailable
        }
    }
}
