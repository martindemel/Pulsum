import XCTest
@testable import PulsumData

/// B6-14 | LOW-20: Performance regression tests for VectorStore operations.
///
/// Establishes baselines for search latency to catch regressions.
final class VectorStorePerformanceTests: XCTestCase {

    private var tempDir: URL!
    private var storeURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("VectorStorePerf-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        storeURL = tempDir.appendingPathComponent("vectors.bin")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
        try super.tearDownWithError()
    }

    /// Measure search latency with ~200 vectors at dimension 384 (realistic workload).
    func testSearchLatency_200Vectors() async throws {
        let dimension = 384
        let store = VectorStore(fileURL: storeURL, dimension: dimension)

        // Populate with 200 random vectors.
        for i in 0 ..< 200 {
            let vector = (0 ..< dimension).map { _ in Float.random(in: -1.0 ... 1.0) }
            try await store.upsert(id: "item-\(i)", vector: vector)
        }

        let query = (0 ..< dimension).map { _ in Float.random(in: -1.0 ... 1.0) }

        measure {
            let exp = expectation(description: "search")
            Task {
                _ = try await store.search(query: query, topK: 5)
                exp.fulfill()
            }
            wait(for: [exp], timeout: 5.0)
        }
    }

    /// Measure bulk upsert latency for 100 vectors.
    func testBulkUpsertLatency() async throws {
        let dimension = 384
        let store = VectorStore(fileURL: storeURL, dimension: dimension)

        let items = (0 ..< 100).map { i in
            (id: "bulk-\(i)", vector: (0 ..< dimension).map { _ in Float.random(in: -1.0 ... 1.0) })
        }

        measure {
            let exp = expectation(description: "bulkUpsert")
            Task {
                try await store.bulkUpsert(items)
                exp.fulfill()
            }
            wait(for: [exp], timeout: 5.0)
        }
    }

    /// Measure persist-to-disk latency with 200 vectors.
    func testPersistLatency_200Vectors() async throws {
        let dimension = 384
        let store = VectorStore(fileURL: storeURL, dimension: dimension)

        for i in 0 ..< 200 {
            let vector = (0 ..< dimension).map { _ in Float.random(in: -1.0 ... 1.0) }
            try await store.upsert(id: "persist-\(i)", vector: vector)
        }

        measure {
            let exp = expectation(description: "persist")
            Task {
                try await store.persist()
                exp.fulfill()
            }
            wait(for: [exp], timeout: 10.0)
        }
    }
}
