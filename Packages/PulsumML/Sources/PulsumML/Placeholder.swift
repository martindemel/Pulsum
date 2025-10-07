import Foundation

public enum PulsumML {
    public static let version = "0.1.0"

    public static func embedding(for text: String) -> [Float] {
        EmbeddingService.shared.embedding(for: text)
    }

    public static func embedding(forSegments segments: [String]) -> [Float] {
        EmbeddingService.shared.embedding(forSegments: segments)
    }
}
