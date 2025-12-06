@testable import PulsumAgents
import XCTest

final class DebugLogBufferTests: XCTestCase {
    func testRingBufferEvictsOldEntries() async {
        let buffer = DebugLogBuffer.shared
        await buffer._testReset()

        for index in 0..<31_000 {
            await buffer.append("test-line-\(index)")
        }

        let snapshot = await buffer.snapshot()
        let lines = snapshot.split(separator: "\n")
        XCTAssertLessThanOrEqual(lines.count, 30_000)
        XCTAssertTrue(lines.first?.contains("test-line-1000") ?? false, "Oldest entries should be evicted beyond capacity.")
        XCTAssertTrue(lines.last?.contains("test-line-30999") ?? false)
    }
}
