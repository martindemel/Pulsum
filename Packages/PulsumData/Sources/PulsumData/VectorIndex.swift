import Foundation

public struct VectorMatch: Equatable {
    public let id: String
    public let score: Float
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
    private let queue = DispatchQueue(label: "ai.pulsum.vectorindex.shard", attributes: .concurrent)

    init(baseDirectory: URL, name: String, shardIdentifier: String, dimension: Int, fileManager: FileManager = .default) throws {
        self.dimension = dimension
        self.fileManager = fileManager
        let shardDirectory = baseDirectory.appendingPathComponent(name, isDirectory: true)
        if !fileManager.fileExists(atPath: shardDirectory.path) {
            #if os(iOS)
            try fileManager.createDirectory(at: shardDirectory, withIntermediateDirectories: true, attributes: [.protectionKey: FileProtectionType.complete])
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
            try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: shardURL.path)
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

        try queue.sync(flags: .barrier) {
            let handle = try FileHandle(forUpdating: shardURL)
            defer { try? handle.close() }

            var metadataChanged = false

            if let existingOffset = metadata[id] {
                try markRecordDeleted(at: existingOffset, handle: handle)
                metadataChanged = true
            }

            let offset = try appendRecord(id: id, vector: vector, handle: handle)
            metadata[id] = offset
            metadataChanged = true

            if metadataChanged {
                try persistMetadata()
                try updateRecordCount(handle: handle)
            }
        }
    }

    func remove(id: String) throws {
        try queue.sync(flags: .barrier) {
            guard let offset = metadata.removeValue(forKey: id) else { return }
            let handle = try FileHandle(forUpdating: shardURL)
            defer { try? handle.close() }
            try markRecordDeleted(at: offset, handle: handle)
            try persistMetadata()
            try updateRecordCount(handle: handle)
        }
    }

    func search(query: [Float], topK: Int) throws -> [VectorMatch] {
        guard query.count == dimension else {
            throw VectorIndexError.invalidDimension(expected: dimension, actual: query.count)
        }

        var result: Result<[VectorMatch], Error> = .success([])
        queue.sync {
            do {
                let data = try Data(contentsOf: shardURL, options: .mappedIfSafe)
                _ = try currentHeader(from: data)
                var cursor = VectorIndexHeader.byteSize
                var matches: [VectorMatch] = []
                while cursor < data.count {
                    guard let header = readRecordHeader(data: data, offset: cursor) else { break }
                    cursor += VectorRecordHeader.byteSize
                    guard cursor + Int(header.idLength) <= data.count else { break }
                    let idData = data[cursor..<(cursor + Int(header.idLength))]
                    cursor += Int(header.idLength)
                    let vectorByteCount = dimension * MemoryLayout<Float>.size
                    guard cursor + vectorByteCount <= data.count else { break }
                    if header.flags == 0 {
                        let vectorData = data[cursor..<(cursor + vectorByteCount)]
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
                result = .success(matches)
            } catch {
                result = .failure(error)
            }
        }
        return try result.get()
    }

    private func appendRecord(id: String, vector: [Float], handle: FileHandle) throws -> UInt64 {
        guard let idData = id.data(using: .utf8) else {
            throw VectorIndexError.ioFailure("Unable to encode identifier \(id)")
        }
        let offset = try handle.seekToEnd()
        let recordHeader = VectorRecordHeader(idLength: UInt16(idData.count), flags: 0)
        handle.write(recordHeader.data())
        handle.write(idData)
        vector.forEach { value in
            handle.write(value.bitPattern.littleEndianData)
        }
        return offset
    }

    private func markRecordDeleted(at offset: UInt64, handle: FileHandle) throws {
        try handle.seek(toOffset: offset)
        guard let headerData = try handle.read(upToCount: VectorRecordHeader.byteSize), headerData.count == VectorRecordHeader.byteSize else {
            throw VectorIndexError.corruptShard(shardURL.lastPathComponent)
        }
        let idLength = headerData[0..<2].toUInt16()
        let newFlags = UInt16(1)
        let updatedHeader = VectorRecordHeader(idLength: idLength, flags: newFlags)
        try handle.seek(toOffset: offset)
        handle.write(updatedHeader.data())
    }

    private func persistMetadata() throws {
        let data = try JSONEncoder().encode(metadata)
        try data.write(to: metadataURL, options: .atomic)
        try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: metadataURL.path)
    }

    private func updateRecordCount(handle: FileHandle) throws {
        let count = UInt64(metadata.count)
        let header = VectorIndexHeader(dimension: UInt16(dimension), recordCount: count)
        try handle.seek(toOffset: 0)
        handle.write(header.data())
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
        let magic = blob[0..<4].toUInt32()
        guard magic == VectorIndexHeader.magic else {
            throw VectorIndexError.corruptShard(shardURL.lastPathComponent)
        }
        let version = blob[4..<6].toUInt16()
        guard version == VectorIndexHeader.version else {
            throw VectorIndexError.corruptShard(shardURL.lastPathComponent)
        }
        let dimension = blob[6..<8].toUInt16()
        let recordCount = blob[8..<(8 + MemoryLayout<UInt64>.size)].toUInt64()
        return VectorIndexHeader(dimension: dimension, recordCount: recordCount)
    }

    private func readRecordHeader(data: Data, offset: Int) -> VectorRecordHeader? {
        guard offset + VectorRecordHeader.byteSize <= data.count else { return nil }
        let idLength = data[offset..<(offset + 2)].toUInt16()
        let flags = data[(offset + 2)..<(offset + 4)].toUInt16()
        return VectorRecordHeader(idLength: idLength, flags: flags)
    }

    private func l2Distance(query: [Float], vectorData: Data) -> Float {
        var sum: Float = 0
        var index = vectorData.startIndex
        for value in query {
            let end = index + MemoryLayout<Float>.size
            let slice = vectorData[index..<end]
            let stored = Float(bitPattern: slice.toUInt32())
            let diff = value - stored
            sum += diff * diff
            index = end
        }
        return sqrt(sum)
    }
}

final class VectorIndex {
    private let name: String
    private let dimension: Int
    private let shardCount: Int
    private let directory: URL
    private let queue = DispatchQueue(label: "ai.pulsum.vectorindex", attributes: .concurrent)
    private var shards: [Int: VectorIndexShard] = [:]

    init(name: String, dimension: Int = 384, directory: URL = PulsumData.vectorIndexDirectory, shardCount: Int = 16) {
        self.name = name
        self.dimension = dimension
        self.directory = directory
        self.shardCount = shardCount
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
        for shardIndex in 0..<shardCount {
            let shard = try shard(forShardIndex: shardIndex)
            let matches = try shard.search(query: vector, topK: topK)
            allMatches.append(contentsOf: matches)
        }
        return Array(allMatches.sorted { $0.score < $1.score }.prefix(topK))
    }

    private func shard(for id: String) throws -> VectorIndexShard {
        let shardIndex = abs(id.hashValue) % shardCount
        return try shard(forShardIndex: shardIndex)
    }

    private func shard(forShardIndex index: Int) throws -> VectorIndexShard {
        if let shard = shards[index] { return shard }
        var creationError: Error?
        var createdShard: VectorIndexShard?
        queue.sync(flags: .barrier) {
            if let shard = shards[index] {
                createdShard = shard
                return
            }
            do {
                let shard = try VectorIndexShard(baseDirectory: directory,
                                                 name: name,
                                                 shardIdentifier: "shard_\(index)",
                                                 dimension: dimension)
                shards[index] = shard
                createdShard = shard
            } catch {
                creationError = error
            }
        }
        if let creationError { throw creationError }
        guard let shard = createdShard else {
            throw VectorIndexError.ioFailure("Unable to initialize shard \(index)")
        }
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
