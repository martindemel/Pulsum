import Foundation
import PulsumML

public protocol VectorIndexProviding: AnyObject, Sendable {
    @discardableResult
    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float]
    func removeMicroMoment(id: String) async throws
    func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch]
    func stats() async -> (shards: Int, items: Int)
}

public extension VectorIndexProviding {
    func stats() async -> (shards: Int, items: Int) { (0, 0) }
}

public actor VectorIndexManager: VectorIndexProviding {
    private let microMomentsIndex: VectorIndex
    private let embeddingService: EmbeddingService

    public init(directory: URL, embeddingService: EmbeddingService = .shared) {
        self.embeddingService = embeddingService
        self.microMomentsIndex = VectorIndex(name: "micro_moments", directory: directory)
    }

    init(embeddingService: EmbeddingService = .shared, microMomentsIndex: VectorIndex) {
        self.embeddingService = embeddingService
        self.microMomentsIndex = microMomentsIndex
    }

    @discardableResult
    public func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float] {
        let segments = [title, detail ?? "", tags?.joined(separator: " ") ?? ""].filter { !$0.isEmpty }
        let embedding = try embeddingService.embedding(forSegments: segments)
        try await microMomentsIndex.upsert(id: id, vector: embedding)
        return embedding
    }

    public func removeMicroMoment(id: String) async throws {
        try await microMomentsIndex.remove(id: id)
    }

    public func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch] {
        let embedding = try embeddingService.embedding(for: query)
        return try await microMomentsIndex.search(vector: embedding, topK: topK)
    }

    public func stats() async -> (shards: Int, items: Int) {
        await microMomentsIndex.stats()
    }
}
