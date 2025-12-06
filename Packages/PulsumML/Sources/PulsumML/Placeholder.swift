import Foundation

public enum PulsumML {
    public static let version = "0.1.0"

    public static func embedding(for text: String) throws -> [Float] {
        try EmbeddingService.shared.embedding(for: text)
    }

    public static func embedding(forSegments segments: [String]) throws -> [Float] {
        try EmbeddingService.shared.embedding(forSegments: segments)
    }
}
