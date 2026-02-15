import Accelerate
import Foundation
import os.log

/// In-memory vector store with file-backed binary persistence.
///
/// Binary format:
///   entry-count (UInt32)
///   per entry: id-length (UInt16) + id (UTF-8 bytes) + vector (dimension × Float raw bytes)
///
/// Designed for ~500 micro-moment embeddings at dimension 384 (~770KB on disk).
public actor VectorStore {
    private let fileURL: URL
    private let dimension: Int
    private var entries: [String: [Float]] = [:]
    private var isDirty = false
    private let logger = Logger(subsystem: "ai.pulsum", category: "VectorStore")

    public init(fileURL: URL, dimension: Int = 384) {
        self.fileURL = fileURL
        self.dimension = dimension
        self.entries = Self.loadFromDisk(fileURL: fileURL, dimension: dimension)
    }

    // MARK: - Mutations

    public func upsert(id: String, vector: [Float]) throws {
        guard vector.count == dimension else {
            throw VectorStoreError.dimensionMismatch(expected: dimension, actual: vector.count)
        }
        entries[id] = vector
        isDirty = true
    }

    public func bulkUpsert(_ items: [(id: String, vector: [Float])]) throws {
        for item in items {
            guard item.vector.count == dimension else {
                throw VectorStoreError.dimensionMismatch(expected: dimension, actual: item.vector.count)
            }
            entries[item.id] = item.vector
        }
        if !items.isEmpty {
            isDirty = true
        }
    }

    public func remove(id: String) {
        if entries.removeValue(forKey: id) != nil {
            isDirty = true
        }
    }

    // MARK: - Search

    public func search(query: [Float], topK: Int) throws -> [VectorMatch] {
        guard query.count == dimension else {
            throw VectorStoreError.dimensionMismatch(expected: dimension, actual: query.count)
        }
        guard !entries.isEmpty else { return [] }

        var results: [(id: String, distSq: Float)] = []
        results.reserveCapacity(min(entries.count, topK + 1))

        for (id, vector) in entries {
            let distSq = vDSPDistanceSquared(query, vector)
            if results.count < topK {
                results.append((id, distSq))
                if results.count == topK {
                    results.sort { $0.distSq < $1.distSq }
                }
            } else if let worst = results.last, distSq < worst.distSq {
                results[results.count - 1] = (id, distSq)
                results.sort { $0.distSq < $1.distSq }
            }
        }

        if results.count < topK {
            results.sort { $0.distSq < $1.distSq }
        }

        return results.map { VectorMatch(id: $0.id, score: sqrt(max($0.distSq, 0))) }
    }

    // MARK: - Persistence

    public func persist() throws {
        guard isDirty else { return }
        let data = serialize()
        let directory = fileURL.deletingLastPathComponent()
        let fm = FileManager.default
        if !fm.fileExists(atPath: directory.path) {
            #if os(iOS)
            try fm.createDirectory(at: directory, withIntermediateDirectories: true,
                                   attributes: [.protectionKey: FileProtectionType.completeUnlessOpen])
            #else
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
            #endif
        }
        try data.write(to: fileURL, options: .atomic)
        #if os(iOS)
        try? fm.setAttributes([.protectionKey: FileProtectionType.completeUnlessOpen],
                              ofItemAtPath: fileURL.path)
        #endif
        isDirty = false
    }

    public func stats() -> (shards: Int, items: Int) {
        (1, entries.count)
    }

    // MARK: - Binary Serialization

    private func serialize() -> Data {
        let entryCount = UInt32(entries.count)
        let vectorByteSize = dimension * MemoryLayout<Float>.size
        // Estimate: 4 (count) + entries × (2 + ~30 id bytes + vectorByteSize)
        var data = Data(capacity: 4 + entries.count * (2 + 40 + vectorByteSize))

        var count = entryCount.littleEndian
        data.append(Data(bytes: &count, count: MemoryLayout<UInt32>.size))

        for (id, vector) in entries {
            let idData = Data(id.utf8)
            var idLen = UInt16(idData.count).littleEndian
            data.append(Data(bytes: &idLen, count: MemoryLayout<UInt16>.size))
            data.append(idData)
            vector.withUnsafeBufferPointer { buffer in
                guard let baseAddress = buffer.baseAddress else { return }
                data.append(UnsafeBufferPointer(start: UnsafeRawPointer(baseAddress)
                        .assumingMemoryBound(to: UInt8.self), count: vectorByteSize))
            }
        }
        return data
    }

    private nonisolated static func loadFromDisk(fileURL: URL, dimension: Int) -> [String: [Float]] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [:] }
        do {
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            return try deserializeStatic(data, dimension: dimension)
        } catch {
            return [:]
        }
    }

    private nonisolated static func deserializeStatic(_ data: Data, dimension: Int) throws -> [String: [Float]] {
        guard data.count >= MemoryLayout<UInt32>.size else {
            throw VectorStoreError.corruptFile("File too small")
        }

        var cursor = 0
        let entryCount = data.withUnsafeBytes { $0.load(fromByteOffset: cursor, as: UInt32.self) }.littleEndian
        cursor += MemoryLayout<UInt32>.size

        let vectorByteSize = dimension * MemoryLayout<Float>.size
        var result: [String: [Float]] = [:]
        result.reserveCapacity(Int(entryCount))

        for _ in 0 ..< entryCount {
            guard cursor + MemoryLayout<UInt16>.size <= data.count else {
                throw VectorStoreError.corruptFile("Unexpected end of file reading id length")
            }
            let idLen = Int(data.withUnsafeBytes { $0.load(fromByteOffset: cursor, as: UInt16.self) }.littleEndian)
            cursor += MemoryLayout<UInt16>.size

            guard cursor + idLen + vectorByteSize <= data.count else {
                throw VectorStoreError.corruptFile("Unexpected end of file reading entry")
            }
            let id = String(decoding: data[cursor ..< cursor + idLen], as: UTF8.self)
            cursor += idLen

            let vector: [Float] = [Float](unsafeUninitializedCapacity: dimension) { buffer, count in
                data.withUnsafeBytes { raw in
                    let src = UnsafeRawBufferPointer(start: raw.baseAddress!.advanced(by: cursor), count: vectorByteSize)
                    buffer.withMemoryRebound(to: UInt8.self) { dest in
                        _ = src.copyBytes(to: dest)
                    }
                }
                count = dimension
            }
            cursor += vectorByteSize
            result[id] = vector
        }

        return result
    }

    // MARK: - vDSP Accelerated Distance

    private func vDSPDistanceSquared(_ a: [Float], _ b: [Float]) -> Float {
        vDSP.distanceSquared(a, b)
    }
}

// MARK: - Error

public enum VectorStoreError: LocalizedError {
    case dimensionMismatch(expected: Int, actual: Int)
    case corruptFile(String)

    public var errorDescription: String? {
        switch self {
        case let .dimensionMismatch(expected, actual):
            return "Vector dimension mismatch. Expected \(expected), got \(actual)."
        case let .corruptFile(reason):
            return "VectorStore file corrupt: \(reason)"
        }
    }
}
