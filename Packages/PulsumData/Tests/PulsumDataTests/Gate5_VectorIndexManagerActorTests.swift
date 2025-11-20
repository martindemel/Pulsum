import XCTest
@testable import PulsumData
@testable import PulsumML

final class Gate5_VectorIndexManagerActorTests: XCTestCase {
    func testManagerAllowsConcurrentAccessFromBackgroundTasks() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gate5-manager-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let vectorIndex = VectorIndex(name: "gate5-manager", directory: directory, shardCount: 4)
        let provider = MockEmbeddingProvider()
        let embeddingService = EmbeddingService.debugInstance(primary: provider, fallback: provider)
        let manager = VectorIndexManager(embeddingService: embeddingService, microMomentsIndex: vectorIndex)

        let identifiers = (0..<12).map { "moment-\($0)" }
        try await withThrowingTaskGroup(of: Void.self) { group in
            for id in identifiers {
                group.addTask {
                    _ = try await manager.upsertMicroMoment(id: id,
                                                            title: id,
                                                            detail: nil as String?,
                                                            tags: nil as [String]?)
                }
            }
            try await group.waitForAll()
        }

        let sampleID = identifiers.first ?? "moment-0"
        let matches = try await manager.searchMicroMoments(query: sampleID, topK: 2)
        XCTAssertTrue(matches.contains(where: { $0.id == sampleID }))
    }
}

private struct MockEmbeddingProvider: TextEmbeddingProviding {
    func embedding(for text: String) throws -> [Float] {
        let seed = abs(text.hashValue % 1000)
        let value = Float(seed) / 1000.0
        return Array(repeating: value, count: 384)
    }
}
