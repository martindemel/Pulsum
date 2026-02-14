import XCTest
@testable import PulsumData

final class Gate5_VectorIndexFileHandleTests: XCTestCase {
    func testCloseFailureIsSurfacedToCaller() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gate5-close-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let warmIndex = VectorIndex(name: "gate5-close",
                                    directory: directory,
                                    fileHandleFactory: TestHandleFactory(shouldFailClose: false))
        let vector = Array(repeating: Float(0.1), count: 384)

        try await warmIndex.upsert(id: "seed", vector: vector)

        let failingIndex = VectorIndex(name: "gate5-close",
                                       directory: directory,
                                       fileHandleFactory: TestHandleFactory(shouldFailClose: true))

        do {
            try await failingIndex.upsert(id: "seed", vector: vector)
            XCTFail("Expected close failure to surface")
        } catch VectorIndexError.ioFailure(let message) {
            XCTAssertTrue(message.contains("close"), "Unexpected message: \(message)")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private struct TestHandleFactory: VectorIndexFileHandleFactory, Sendable {
    let shouldFailClose: Bool

    func updatingHandle(for url: URL) throws -> VectorIndexFileHandle {
        try TestVectorHandle(url: url, shouldFailClose: shouldFailClose)
    }
}

private final class TestVectorHandle: VectorIndexFileHandle {
    enum CloseError: Error {
        case simulated
    }

    private let handle: FileHandle
    private let shouldFailClose: Bool

    init(url: URL, shouldFailClose: Bool) throws {
        self.handle = try FileHandle(forUpdating: url)
        self.shouldFailClose = shouldFailClose
    }

    func seekToEnd() throws -> UInt64 {
        try handle.seekToEnd()
    }

    func seek(toOffset offset: UInt64) throws {
        try handle.seek(toOffset: offset)
    }

    func read(upToCount count: Int) throws -> Data? {
        try handle.read(upToCount: count)
    }

    func write(_ data: Data) {
        handle.write(data)
    }

    func synchronize() throws {
        try handle.synchronize()
    }

    func close() throws {
        try handle.close()
        if shouldFailClose {
            throw CloseError.simulated
        }
    }
}
