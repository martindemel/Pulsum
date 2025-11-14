import SwiftUI

struct LiveWaveformLevels: RandomAccessCollection, MutableCollection, Sendable {
    typealias Index = Int
    private var storage: [CGFloat]
    private var writeIndex: Int = 0
    private var filledCount: Int = 0
    private(set) var samplesAppended: Int = 0

    init(capacity: Int) {
        precondition(capacity > 0, "capacity must be positive")
        storage = Array(repeating: 0, count: capacity)
    }

    var startIndex: Int { 0 }
    var endIndex: Int { filledCount }

    subscript(position: Int) -> CGFloat {
        get {
            precondition(position >= 0 && position < filledCount, "index out of range")
            let index = (writeIndex + storage.count - filledCount + position) % storage.count
            return storage[index]
        }
        set {
            precondition(position >= 0 && position < filledCount, "index out of range")
            let index = (writeIndex + storage.count - filledCount + position) % storage.count
            storage[index] = newValue
        }
    }

    var capacity: Int { storage.count }

    @inline(__always) private func clamp01(_ x: CGFloat) -> CGFloat {
        Swift.max(0, Swift.min(1, x))
    }

    mutating func append(_ value: CGFloat) {
        let clamped = clamp01(value)
        storage[writeIndex] = clamped
        writeIndex = (writeIndex + 1) % storage.count
        filledCount = Swift.min(filledCount + 1, storage.count)
        samplesAppended += 1
    }

    mutating func reset(with value: CGFloat = 0) {
        storage = Array(repeating: value, count: storage.count)
        writeIndex = 0
        filledCount = 0
        samplesAppended = 0
    }
}
