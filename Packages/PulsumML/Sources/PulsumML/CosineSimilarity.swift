import Foundation

/// Shared cosine similarity utility for embedding comparisons.
public enum CosineSimilarity {
    /// Computes cosine similarity between two float vectors.
    ///
    /// Returns 0 when vectors have different lengths, when either vector is zero-magnitude,
    /// or when the result is NaN (degenerate input guard).
    public static func compute(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        var dot: Float = 0
        var aNorm: Float = 0
        var bNorm: Float = 0
        for index in 0 ..< a.count {
            dot += a[index] * b[index]
            aNorm += a[index] * a[index]
            bNorm += b[index] * b[index]
        }
        let denominator = sqrt(aNorm) * sqrt(bNorm)
        guard denominator > 0 else { return 0 }
        let result = dot / denominator
        // NaN guard (Batch 1 safety invariant)
        guard !result.isNaN else { return 0 }
        return result
    }
}
