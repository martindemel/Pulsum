import Foundation

public protocol TextEmbeddingProviding: Sendable {
    /// Returns a 384-dimensional embedding for the supplied text.
    func embedding(for text: String) throws -> [Float]
}
