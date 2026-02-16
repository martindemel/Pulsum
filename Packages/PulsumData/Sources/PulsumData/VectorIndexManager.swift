import Foundation
import PulsumML

public protocol VectorIndexProviding: AnyObject, Sendable {
    @discardableResult
    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float]
    func bulkUpsertMicroMoments(_ items: [(id: String, title: String, detail: String?, tags: [String]?)]) async throws
    func removeMicroMoment(id: String) async throws
    func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch]
    func stats() async -> (shards: Int, items: Int)
}

public extension VectorIndexProviding {
    func bulkUpsertMicroMoments(_: [(id: String, title: String, detail: String?, tags: [String]?)]) async throws {}
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

    public func bulkUpsertMicroMoments(_ items: [(id: String, title: String, detail: String?, tags: [String]?)]) async throws {
        guard !items.isEmpty else { return }
        var vectors: [(id: String, vector: [Float])] = []
        vectors.reserveCapacity(items.count)
        for item in items {
            let segments = [item.title, item.detail ?? "", item.tags?.joined(separator: " ") ?? ""].filter { !$0.isEmpty }
            let embedding = try embeddingService.embedding(forSegments: segments)
            vectors.append((id: item.id, vector: embedding))
        }
        try await store.bulkUpsert(vectors)
        try await store.persist()
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
