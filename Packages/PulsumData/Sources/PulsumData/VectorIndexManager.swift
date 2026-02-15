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
    private let store: VectorStore
    private let embeddingService: EmbeddingService

    public init(directory: URL, embeddingService: EmbeddingService = .shared) {
        let fileURL = directory.appendingPathComponent("micro_moments.vecstore")
        self.embeddingService = embeddingService
        self.store = VectorStore(fileURL: fileURL)
    }

    init(embeddingService: EmbeddingService = .shared, store: VectorStore) {
        self.embeddingService = embeddingService
        self.store = store
    }

    @discardableResult
    public func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float] {
        let segments = [title, detail ?? "", tags?.joined(separator: " ") ?? ""].filter { !$0.isEmpty }
        let embedding = try embeddingService.embedding(forSegments: segments)
        try await store.upsert(id: id, vector: embedding)
        try await store.persist()
        return embedding
    }

    public func removeMicroMoment(id: String) async throws {
        await store.remove(id: id)
        try await store.persist()
    }

    public func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch] {
        let embedding = try embeddingService.embedding(for: query)
        return try await store.search(query: embedding, topK: topK)
    }

    public func stats() async -> (shards: Int, items: Int) {
        await store.stats()
    }
}
