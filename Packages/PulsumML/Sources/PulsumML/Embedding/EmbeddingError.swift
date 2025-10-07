import Foundation

public enum EmbeddingError: LocalizedError {
    case generatorUnavailable
    case emptyResult

    public var errorDescription: String? {
        switch self {
        case .generatorUnavailable:
            return "On-device embedding generator is unavailable."
        case .emptyResult:
            return "Failed to compute embedding for the provided text."
        }
    }
}
