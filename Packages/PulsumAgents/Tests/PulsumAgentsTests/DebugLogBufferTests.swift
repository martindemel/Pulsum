@testable import PulsumAgents
import PulsumTypes
import XCTest

final class DebugLogBufferTests: XCTestCase {
    func testRingBufferEvictsOldEntries() async {
        let buffer = DebugLogBuffer.shared
        await buffer._testReset()

        for index in 0..<100 {
            await buffer.append("seed-line-\(index)")
        }
        let initialFirst = await buffer.snapshot().split(separator: "\n").first

        for index in 0..<35_000 {
            await buffer.append("test-line-\(index)")
        }

        let snapshot = await buffer.snapshot()
        let lines = snapshot.split(separator: "\n")
        XCTAssertLessThan(lines.count, 35_100)
        XCTAssertTrue(lines.last?.contains("test-line-34999") ?? false)
        if let initialFirst {
            XCTAssertFalse(lines.contains(initialFirst), "Old seed entries should be evicted when capacity is exceeded.")
        }
    }
}
