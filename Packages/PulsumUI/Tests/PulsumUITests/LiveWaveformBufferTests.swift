import XCTest
@testable import PulsumUI

final class LiveWaveformBufferTests: XCTestCase {
    func testRingBufferMaintainsLatestSamples() {
        var buffer = LiveWaveformLevels(capacity: 8)
        (0..<20).forEach { buffer.append(CGFloat($0)) }

        XCTAssertEqual(buffer.count, 8)
        XCTAssertEqual(buffer.samplesAppended, 20)
        XCTAssertEqual(Array(buffer), Array(repeating: 1, count: 8).map { CGFloat($0) })
    }

    func testWaveformPerfFeed30Seconds() {
        var buffer = LiveWaveformLevels(capacity: 180)
        let sampleCount = 1800
        let samples = (0..<sampleCount).map { _ in CGFloat.random(in: 0...1) }

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            buffer.reset()
            for sample in samples {
                buffer.append(sample)
            }
        }

        XCTAssertEqual(buffer.samplesAppended, sampleCount)
        XCTAssertEqual(buffer.count, buffer.capacity)
    }

    func testClampBehavior() {
        var buffer = LiveWaveformLevels(capacity: 4)
        buffer.append(-3)
        buffer.append(2)
        XCTAssertEqual(Array(buffer), [CGFloat(0), CGFloat(1)])
    }
}
