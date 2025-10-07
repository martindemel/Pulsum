import Foundation
import PulsumML

public protocol VectorIndexProviding: AnyObject {
    @discardableResult
    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) throws -> [Float]
    func removeMicroMoment(id: String) throws
    func searchMicroMoments(query: String, topK: Int) throws -> [VectorMatch]
}

public final class VectorIndexManager: VectorIndexProviding {
    public static let shared = VectorIndexManager()

    private let microMomentsIndex: VectorIndex
    private let embeddingService = EmbeddingService.shared

    public init() {
        self.microMomentsIndex = VectorIndex(name: "micro_moments")
    }

    @discardableResult
    public func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) throws -> [Float] {
        let segments = [title, detail ?? "", tags?.joined(separator: " ") ?? ""].filter { !$0.isEmpty }
        let embedding = embeddingService.embedding(forSegments: segments)
        try microMomentsIndex.upsert(id: id, vector: embedding)
        return embedding
    }

    public func removeMicroMoment(id: String) throws {
        try microMomentsIndex.remove(id: id)
    }

    public func searchMicroMoments(query: String, topK: Int) throws -> [VectorMatch] {
        let embedding = embeddingService.embedding(for: query)
        return try microMomentsIndex.search(vector: embedding, topK: topK)
    }
}

extension VectorIndexManager: @unchecked Sendable {}
