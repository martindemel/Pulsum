import XCTest
@testable import PulsumData

final class VectorIndexTests: XCTestCase {
    func testUpsertAndSearch() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("VectorStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = VectorStore(fileURL: tempDir.appendingPathComponent("test.vecstore"))
        let embedding = Array(repeating: Float(0.5), count: 384)
        try await store.upsert(id: "test", vector: embedding)
        let results = try await store.search(query: embedding, topK: 1)
        XCTAssertEqual(results.first?.id, "test")
        XCTAssertEqual(results.first?.score, 0)
        await store.remove(id: "test")
        let empty = try await store.search(query: embedding, topK: 1)
        XCTAssertTrue(empty.isEmpty)
    }

    func testPersistAndReload() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("VectorStorePersist-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileURL = tempDir.appendingPathComponent("persist.vecstore")
        let embedding = Array(repeating: Float(0.3), count: 384)

        let store1 = VectorStore(fileURL: fileURL)
        try await store1.upsert(id: "persist-test", vector: embedding)
        try await store1.persist()

        let store2 = VectorStore(fileURL: fileURL)
        let results = try await store2.search(query: embedding, topK: 1)
        XCTAssertEqual(results.first?.id, "persist-test")
    }

    func testBulkUpsert() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("VectorStoreBulk-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = VectorStore(fileURL: tempDir.appendingPathComponent("bulk.vecstore"))
        let items = (0 ..< 50).map { i in
            (id: "item-\(i)", vector: (0 ..< 384).map { Float($0) * 0.001 + Float(i) * 0.01 })
        }
        try await store.bulkUpsert(items)
        let stats = await store.stats()
        XCTAssertEqual(stats.items, 50)
    }
}
