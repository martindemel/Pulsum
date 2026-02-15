import XCTest
@testable import PulsumData

final class Gate5_VectorIndexConcurrencyTests: XCTestCase {
    func testConcurrentOperationsRemainDeterministic() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gate5-vector-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let store = VectorStore(fileURL: tempDirectory.appendingPathComponent("concurrency.vecstore"))
        let identifiers = (0 ..< 64).map { "moment-\($0)" }
        let vectors = Dictionary(uniqueKeysWithValues: identifiers.enumerated().map { offset, id in
            (id, Self.makeVector(seed: offset))
        })

        try await withThrowingTaskGroup(of: Void.self) { group in
            for (offset, id) in identifiers.enumerated() {
                group.addTask { @Sendable () async throws -> Void in
                    guard let vector = vectors[id] else { return }
                    try await store.upsert(id: id, vector: vector)
                    if offset % 4 == 0 {
                        _ = try await store.search(query: vector, topK: 5)
                    }
                    if offset % 6 == 0 {
                        await store.remove(id: id)
                        try await store.upsert(id: id, vector: vector)
                    }
                }
            }

            for id in identifiers where ((Int(id.split(separator: "-").last ?? "0") ?? 0) % 5) == 0 {
                group.addTask { @Sendable () async throws -> Void in
                    guard let vector = vectors[id] else { return }
                    _ = try await store.search(query: vector, topK: 3)
                }
            }

            for try await _ in group {}
        }

        for id in identifiers {
            guard let vector = vectors[id] else {
                XCTFail("Missing vector for \(id)")
                continue
            }
            let matches = try await store.search(query: vector, topK: 1)
            XCTAssertEqual(matches.first?.id, id, "Expected deterministic match for \(id)")
        }
    }

    private static func makeVector(seed: Int) -> [Float] {
        let base = Float(seed) / 100.0
        return (0 ..< 384).map { Float($0) * 0.0001 + base }
    }
}
