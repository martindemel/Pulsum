import XCTest
@testable import PulsumData

final class VectorIndexTests: XCTestCase {
    func testUpsertAndSearch() throws {
        let vectorIndex = VectorIndex(name: "test-index", directory: PulsumData.vectorIndexDirectory)
        defer { try? vectorIndex.remove(id: "test") }
        let embedding = Array(repeating: Float(0.5), count: 384)
        try vectorIndex.upsert(id: "test", vector: embedding)
        let results = try vectorIndex.search(vector: embedding, topK: 1)
        XCTAssertEqual(results.first?.id, "test")
        XCTAssertEqual(results.first?.score, 0)
    }
}
