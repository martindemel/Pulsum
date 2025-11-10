import Foundation

/// Central access point for on-device embeddings with AFM primary and hash fallback.
public final class EmbeddingService {
    public static let shared = EmbeddingService()

    private let primaryProvider: TextEmbeddingProviding?
    private let fallbackProvider: TextEmbeddingProviding?
    private let dimension: Int

    private init(primary: TextEmbeddingProviding? = nil,
                 fallback: TextEmbeddingProviding? = nil,
                 dimension: Int = 384) {
        self.dimension = dimension
        if let primary {
            self.primaryProvider = primary
        } else if #available(iOS 17.0, macOS 13.0, *) {
            self.primaryProvider = AFMTextEmbeddingProvider()
        } else {
            self.primaryProvider = nil
        }

        if let fallback {
            self.fallbackProvider = fallback
        } else if #available(iOS 17.0, macOS 13.0, *) {
            self.fallbackProvider = CoreMLEmbeddingFallbackProvider()
        } else {
            self.fallbackProvider = nil
        }
    }

    /// Generates an embedding for the supplied text, padding or truncating to 384 dimensions.
    public func embedding(for text: String) -> [Float] {
        if let primaryProvider,
           let primary = try? primaryProvider.embedding(for: text) {
            return ensureDimension(primary)
        }

        if let fallbackProvider,
           let fallback = try? fallbackProvider.embedding(for: text) {
            return ensureDimension(fallback)
        }

        return Array(repeating: 0, count: dimension)
    }

    /// Generates a combined embedding for multiple text segments (averaged element-wise).
    public func embedding(forSegments segments: [String]) -> [Float] {
        guard !segments.isEmpty else { return Array(repeating: 0, count: dimension) }
        var accumulator = [Float](repeating: 0, count: dimension)
        var count: Float = 0
        for segment in segments where !segment.isEmpty {
            let vector = embedding(for: segment)
            for index in 0..<dimension {
                accumulator[index] += vector[index]
            }
            count += 1
        }
        guard count > 0 else { return accumulator }
        for index in 0..<dimension {
            accumulator[index] /= count
        }
        return accumulator
    }

    private func ensureDimension(_ vector: [Float]) -> [Float] {
        if vector.count == dimension { return vector }
        if vector.count > dimension { return Array(vector.prefix(dimension)) }
        var padded = vector
        padded.reserveCapacity(dimension)
        while padded.count < dimension {
            padded.append(0)
        }
        return padded
    }
}

#if DEBUG
extension EmbeddingService {
    static func debugInstance(primary: TextEmbeddingProviding? = nil,
                              fallback: TextEmbeddingProviding? = nil,
                              dimension: Int = 384) -> EmbeddingService {
        EmbeddingService(primary: primary, fallback: fallback, dimension: dimension)
    }
}
#endif

extension EmbeddingService: @unchecked Sendable {}
