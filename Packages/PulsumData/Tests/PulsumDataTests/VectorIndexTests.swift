import XCTest
@testable import PulsumData

final class VectorIndexTests: XCTestCase {
    func testUpsertAndSearch() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("VectorIndexTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let vectorIndex = VectorIndex(name: "test-index", directory: tempDir)
        let embedding = Array(repeating: Float(0.5), count: 384)
        try await vectorIndex.upsert(id: "test", vector: embedding)
        let results = try await vectorIndex.search(vector: embedding, topK: 1)
        XCTAssertEqual(results.first?.id, "test")
        XCTAssertEqual(results.first?.score, 0)
        try await vectorIndex.remove(id: "test")
    }
}
