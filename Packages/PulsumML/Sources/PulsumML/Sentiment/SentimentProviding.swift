import Foundation

public protocol SentimentProviding: Sendable {
    /// Produces a sentiment score in the range [-1, 1].
    func sentimentScore(for text: String) async throws -> Double
}

public enum SentimentProviderError: LocalizedError {
    case unavailable
    case insufficientInput

    public var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Sentiment provider is unavailable on this device."
        case .insufficientInput:
            return "Not enough text to analyze sentiment."
        }
    }
}
