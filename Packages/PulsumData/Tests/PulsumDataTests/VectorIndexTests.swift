import Testing
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

// MARK: - B7-11 | TC-18: VectorStore unaligned access test

struct VectorStoreUnalignedTests {
    @Test("Odd-length IDs persist and reload correctly (unaligned float offsets)")
    func test_oddLengthIds_persistAndReload() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("VectorStoreUnaligned-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileURL = tempDir.appendingPathComponent("unaligned.vecstore")
        // IDs of lengths 1, 3, 5, 7, 11 bytes — odd lengths cause float data
        // to start at non-4-byte-aligned offsets in the binary format.
        let oddIds = ["a", "abc", "abcde", "abcdefg", "abcdefghijk"]
        let dimension = 384

        let store1 = VectorStore(fileURL: fileURL)
        for (i, id) in oddIds.enumerated() {
            let vector = (0 ..< dimension).map { Float($0) * 0.001 + Float(i) * 0.1 }
            try await store1.upsert(id: id, vector: vector)
        }
        try await store1.persist()

        // Reload from same file
        let store2 = VectorStore(fileURL: fileURL)
        let stats = await store2.stats()
        #expect(stats.items == oddIds.count)

        // Verify all entries survive round-trip with correct vectors
        for (i, id) in oddIds.enumerated() {
            let expectedVector = (0 ..< dimension).map { Float($0) * 0.001 + Float(i) * 0.1 }
            let results = try await store2.search(query: expectedVector, topK: 1)
            #expect(results.first?.id == id, "Expected \(id) to be nearest neighbor for its own vector")
            #expect(results.first?.score == 0, "Expected exact match (distance 0) for \(id)")
        }
    }
}
