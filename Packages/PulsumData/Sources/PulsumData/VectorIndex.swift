import Foundation
import os.log

protocol VectorIndexFileHandle: AnyObject {
    func seekToEnd() throws -> UInt64
    func seek(toOffset offset: UInt64) throws
    func read(upToCount count: Int) throws -> Data?
    func write(_ data: Data)
    func synchronize() throws
    func close() throws
}

extension FileHandle: VectorIndexFileHandle {}

protocol VectorIndexFileHandleFactory {
    func updatingHandle(for url: URL) throws -> VectorIndexFileHandle
}

struct SystemVectorIndexFileHandleFactory: VectorIndexFileHandleFactory {
    func updatingHandle(for url: URL) throws -> VectorIndexFileHandle {
        try FileHandle(forUpdating: url)
    }
}

enum VectorIndexError: LocalizedError {
    case invalidDimension(expected: Int, actual: Int)
    case corruptShard(String)
    case ioFailure(String)

    var errorDescription: String? {
        switch self {
        case let .invalidDimension(expected, actual):
            return "Vector dimension mismatch. Expected \(expected), got \(actual)."
        case let .corruptShard(shard):
            return "Vector index shard \(shard) is corrupt."
        case let .ioFailure(message):
            return "Vector index I/O error: \(message)"
        }
    }
}

private struct VectorIndexHeader {
    static let magic: UInt32 = 0x50535649 // 'PSVI'
    static let version: UInt16 = 1
    let dimension: UInt16
    let recordCount: UInt64

    static let byteSize = MemoryLayout<UInt32>.size + MemoryLayout<UInt16>.size * 2 + MemoryLayout<UInt64>.size

    func data() -> Data {
        var data = Data()
        data.reserveCapacity(Self.byteSize)
        data.append(Self.magic.littleEndianData)
        data.append(Self.version.littleEndianData)
        data.append(dimension.littleEndianData)
        data.append(recordCount.littleEndianData)
        return data
    }
}

private struct VectorRecordHeader {
    let idLength: UInt16
    let flags: UInt16

    static let byteSize = MemoryLayout<UInt16>.size * 2

    func data() -> Data {
        var data = Data(capacity: Self.byteSize)
        data.append(idLength.littleEndianData)
        data.append(flags.littleEndianData)
        return data
    }
}

private final class VectorIndexShard {
    private(set) var metadata: [String: UInt64]
    private let shardURL: URL
    private let metadataURL: URL
    private let dimension: Int
    private let fileManager: FileManager
    private let fileHandleFactory: VectorIndexFileHandleFactory

    init(baseDirectory: URL,
         name: String,
         shardIdentifier: String,
         dimension: Int,
         fileManager: FileManager = .default,
         fileHandleFactory: VectorIndexFileHandleFactory = SystemVectorIndexFileHandleFactory()) throws {
        self.dimension = dimension
        self.fileManager = fileManager
        self.fileHandleFactory = fileHandleFactory
        let shardDirectory = baseDirectory.appendingPathComponent(name, isDirectory: true)
        if !fileManager.fileExists(atPath: shardDirectory.path) {
            #if os(iOS)
            try fileManager.createDirectory(at: shardDirectory, withIntermediateDirectories: true, attributes: [.protectionKey: FileProtectionType.completeUnlessOpen])
            #else
            try fileManager.createDirectory(at: shardDirectory, withIntermediateDirectories: true, attributes: nil)
            #endif
        }
        self.shardURL = shardDirectory.appendingPathComponent("\(shardIdentifier).shard")
        self.metadataURL = shardDirectory.appendingPathComponent("\(shardIdentifier).meta")
        if !fileManager.fileExists(atPath: shardURL.path) {
            let header = VectorIndexHeader(dimension: UInt16(dimension), recordCount: 0)
            try header.data().write(to: shardURL, options: .atomic)
            #if os(iOS)
            try fileManager.setAttributes([.protectionKey: FileProtectionType.completeUnlessOpen], ofItemAtPath: shardURL.path)
            #endif
        }
        if fileManager.fileExists(atPath: metadataURL.path) {
            let data = try Data(contentsOf: metadataURL)
            let decoded = try JSONDecoder().decode([String: UInt64].self, from: data)
            self.metadata = decoded
        } else {
            self.metadata = [:]
            try persistMetadata()
        }
        try validateHeader()
    }

    func upsert(id: String, vector: [Float]) throws {
        guard vector.count == dimension else {
            throw VectorIndexError.invalidDimension(expected: dimension, actual: vector.count)
        }

        try withHandle { handle in
            if let existingOffset = metadata[id] {
                try markRecordDeleted(at: existingOffset, handle: handle)
            }

            let offset = try appendRecord(id: id, vector: vector, handle: handle)
            metadata[id] = offset

            // Flush shard data to disk before updating metadata, so a crash
            // between these steps leaves metadata pointing at valid offsets.
            try handle.synchronize()
            try persistMetadata()
            try updateRecordCount(handle: handle)
        }
    }

    func remove(id: String) throws {
        guard let offset = metadata.removeValue(forKey: id) else { return }
        try withHandle { handle in
            try markRecordDeleted(at: offset, handle: handle)
            try handle.synchronize()
            try persistMetadata()
            try updateRecordCount(handle: handle)
        }
    }

    func search(query: [Float], topK: Int) throws -> [VectorMatch] {
        guard query.count == dimension else {
            throw VectorIndexError.invalidDimension(expected: dimension, actual: query.count)
        }

        let data = try Data(contentsOf: shardURL, options: .mappedIfSafe)
        _ = try currentHeader(from: data)
        var cursor = VectorIndexHeader.byteSize
        var matches: [VectorMatch] = []
        while cursor < data.count {
            guard let header = readRecordHeader(data: data, offset: cursor) else { break }
            cursor += VectorRecordHeader.byteSize
            guard cursor + Int(header.idLength) <= data.count else { break }
            let idData = data[cursor ..< (cursor + Int(header.idLength))]
            cursor += Int(header.idLength)
            let vectorByteCount = dimension * MemoryLayout<Float>.size
            guard cursor + vectorByteCount <= data.count else { break }
            if header.flags == 0 {
                let vectorData = data[cursor ..< (cursor + vectorByteCount)]
                let score = l2Distance(query: query, vectorData: vectorData)
                let identifier = String(decoding: idData, as: UTF8.self)
                if matches.count < topK {
                    matches.append(VectorMatch(id: identifier, score: score))
                    matches.sort { $0.score < $1.score }
                } else if let worst = matches.last, score < worst.score {
                    matches.removeLast()
                    matches.append(VectorMatch(id: identifier, score: score))
                    matches.sort { $0.score < $1.score }
                }
            }
            cursor += vectorByteCount
        }
        return matches
    }

    private func appendRecord(id: String, vector: [Float], handle: VectorIndexFileHandle) throws -> UInt64 {
        guard let idData = id.data(using: .utf8) else {
            throw VectorIndexError.ioFailure("Unable to encode identifier \(id)")
        }
        let offset = try handle.seekToEnd()
        let recordHeader = VectorRecordHeader(idLength: UInt16(idData.count), flags: 0)
        handle.write(recordHeader.data())
        handle.write(idData)
        for value in vector {
            handle.write(value.bitPattern.littleEndianData)
        }
        return offset
    }

    private func markRecordDeleted(at offset: UInt64, handle: VectorIndexFileHandle) throws {
        try handle.seek(toOffset: offset)
        guard let headerData = try handle.read(upToCount: VectorRecordHeader.byteSize), headerData.count == VectorRecordHeader.byteSize else {
            throw VectorIndexError.corruptShard(shardURL.lastPathComponent)
        }
        let idLength = headerData[0 ..< 2].toUInt16()
        let newFlags = UInt16(1)
        let updatedHeader = VectorRecordHeader(idLength: idLength, flags: newFlags)
        try handle.seek(toOffset: offset)
        handle.write(updatedHeader.data())
    }

    private func persistMetadata() throws {
        let data = try JSONEncoder().encode(metadata)
        try data.write(to: metadataURL, options: .atomic)
        #if os(iOS)
        try fileManager.setAttributes([.protectionKey: FileProtectionType.completeUnlessOpen], ofItemAtPath: metadataURL.path)
        #endif
    }

    private func updateRecordCount(handle: VectorIndexFileHandle) throws {
        let count = UInt64(metadata.count)
        let header = VectorIndexHeader(dimension: UInt16(dimension), recordCount: count)
        try handle.seek(toOffset: 0)
        handle.write(header.data())
    }

    private func withHandle<T>(_ work: (VectorIndexFileHandle) throws -> T) throws -> T {
        let handle = try fileHandleFactory.updatingHandle(for: shardURL)
        var operationResult: Result<T, Error> = .failure(VectorIndexError.ioFailure("Uninitialized handle state"))
        do {
            let value = try work(handle)
            operationResult = .success(value)
        } catch {
            operationResult = .failure(error)
        }

        var closeError: Error?
        do {
            try handle.close()
        } catch {
            closeError = error
            os_log("VectorIndex: close() failed for %@: %@", type: .error, shardURL.lastPathComponent, String(describing: error))
        }

        if let closeError {
            switch operationResult {
            case let .failure(opError):
                throw VectorIndexError.ioFailure("FileHandle.close() failed for \(shardURL.lastPathComponent) after operation error: \(opError.localizedDescription); close: \(closeError.localizedDescription)")
            case .success:
                throw VectorIndexError.ioFailure("FileHandle.close() failed for \(shardURL.lastPathComponent): \(closeError.localizedDescription)")
            }
        }

        return try operationResult.get()
    }

    private func validateHeader() throws {
        let data = try Data(contentsOf: shardURL)
        guard data.count >= VectorIndexHeader.byteSize else {
            throw VectorIndexError.corruptShard(shardURL.lastPathComponent)
        }
        let header = try currentHeader(from: data)
        guard header.dimension == UInt16(dimension) else {
            throw VectorIndexError.invalidDimension(expected: dimension, actual: Int(header.dimension))
        }
    }

    private func currentHeader(from data: Data? = nil) throws -> VectorIndexHeader {
        let blob = try data ?? Data(contentsOf: shardURL)
        guard blob.count >= VectorIndexHeader.byteSize else {
            throw VectorIndexError.corruptShard(shardURL.lastPathComponent)
        }
        let magic = blob[0 ..< 4].toUInt32()
        guard magic == VectorIndexHeader.magic else {
            throw VectorIndexError.corruptShard(shardURL.lastPathComponent)
        }
        let version = blob[4 ..< 6].toUInt16()
        guard version == VectorIndexHeader.version else {
            throw VectorIndexError.corruptShard(shardURL.lastPathComponent)
        }
        let dimension = blob[6 ..< 8].toUInt16()
        let recordCount = blob[8 ..< (8 + MemoryLayout<UInt64>.size)].toUInt64()
        return VectorIndexHeader(dimension: dimension, recordCount: recordCount)
    }

    private func readRecordHeader(data: Data, offset: Int) -> VectorRecordHeader? {
        guard offset + VectorRecordHeader.byteSize <= data.count else { return nil }
        let idLength = data[offset ..< (offset + 2)].toUInt16()
        let flags = data[(offset + 2) ..< (offset + 4)].toUInt16()
        return VectorRecordHeader(idLength: idLength, flags: flags)
    }

    private func l2Distance(query: [Float], vectorData: Data) -> Float {
        var sum: Float = 0
        var index = vectorData.startIndex
        for value in query {
            let end = index + MemoryLayout<Float>.size
            let slice = vectorData[index ..< end]
            let stored = Float(bitPattern: slice.toUInt32())
            let diff = value - stored
            sum += diff * diff
            index = end
        }
        return sqrt(max(sum, 0))
    }
}

actor VectorIndex {
    private let name: String
    private let dimension: Int
    private let shardCount: Int
    private let directory: URL
    private let fileHandleFactory: VectorIndexFileHandleFactory
    private var shards: [Int: VectorIndexShard] = [:]

    init(name: String,
         dimension: Int = 384,
         directory: URL,
         shardCount: Int = 16,
         fileHandleFactory: VectorIndexFileHandleFactory = SystemVectorIndexFileHandleFactory()) {
        self.name = name
        self.dimension = dimension
        self.directory = directory
        self.shardCount = shardCount
        self.fileHandleFactory = fileHandleFactory
    }

    func upsert(id: String, vector: [Float]) throws {
        let shard = try shard(for: id)
        try shard.upsert(id: id, vector: vector)
    }

    func remove(id: String) throws {
        let shard = try shard(for: id)
        try shard.remove(id: id)
    }

    func search(vector: [Float], topK: Int) throws -> [VectorMatch] {
        guard vector.count == dimension else {
            throw VectorIndexError.invalidDimension(expected: dimension, actual: vector.count)
        }

        var allMatches: [VectorMatch] = []
        for shardIndex in 0 ..< shardCount {
            let shard = try shard(forShardIndex: shardIndex)
            let matches = try shard.search(query: vector, topK: topK)
            allMatches.append(contentsOf: matches)
        }
        return Array(allMatches.sorted { $0.score < $1.score }.prefix(topK))
    }

    func stats() -> (shards: Int, items: Int) {
        var total = 0
        for index in 0 ..< shardCount {
            if let shard = try? shard(forShardIndex: index) {
                total += shard.metadata.count
            }
        }
        return (shardCount, total)
    }

    private func shard(for id: String) throws -> VectorIndexShard {
        let shardIndex = Int(Self.fnv1a(id) % UInt64(shardCount))
        return try shard(forShardIndex: shardIndex)
    }

    /// FNV-1a 64-bit hash — deterministic across process launches (unlike String.hashValue).
    private static func fnv1a(_ string: String) -> UInt64 {
        Data(string.utf8).withUnsafeBytes { ptr -> UInt64 in
            var h: UInt64 = 0xcbf29ce484222325
            for byte in ptr {
                h = (h ^ UInt64(byte)) &* 0x100000001b3
            }
            return h
        }
    }

    private func shard(forShardIndex index: Int) throws -> VectorIndexShard {
        if let existing = shards[index] {
            return existing
        }

        let shard = try VectorIndexShard(baseDirectory: directory,
                                         name: name,
                                         shardIdentifier: "shard_\(index)",
                                         dimension: dimension,
                                         fileHandleFactory: fileHandleFactory)
        shards[index] = shard
        return shard
    }
}

private extension FixedWidthInteger {
    var littleEndianData: Data {
        var value = self.littleEndian
        return Data(bytes: &value, count: MemoryLayout<Self>.size)
    }
}

private extension DataProtocol {
    func toUInt16() -> UInt16 {
        var value: UInt16 = 0
        withUnsafeMutableBytes(of: &value) { buffer in
            _ = Data(self).copyBytes(to: buffer)
        }
        return UInt16(littleEndian: value)
    }

    func toUInt32() -> UInt32 {
        var value: UInt32 = 0
        withUnsafeMutableBytes(of: &value) { buffer in
            _ = Data(self).copyBytes(to: buffer)
        }
        return UInt32(littleEndian: value)
    }

    func toUInt64() -> UInt64 {
        var value: UInt64 = 0
        withUnsafeMutableBytes(of: &value) { buffer in
            _ = Data(self).copyBytes(to: buffer)
        }
        return UInt64(littleEndian: value)
    }
}
