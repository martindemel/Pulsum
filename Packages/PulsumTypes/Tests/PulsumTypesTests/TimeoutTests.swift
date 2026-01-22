import XCTest
@testable import PulsumTypes

final class TimeoutTests: XCTestCase {
    func testHardTimeoutReturnsTimedOutWithinBudget() async throws {
        let start = Date()
        let result = try await withHardTimeout(seconds: 0.2) {
            try await Task.sleep(nanoseconds: 2_000_000_000) // deliberately longer than timeout
            return "done"
        }
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 1.0, "Timeout should return promptly")
        switch result {
        case .timedOut:
            break
        case .value:
            XCTFail("Expected timeout, got value")
        }
    }

    func testHardTimeoutPropagatesValueWhenWithinBudget() async throws {
        let result = try await withHardTimeout(seconds: 1.0) {
            try await Task.sleep(nanoseconds: 50_000_000)
            return 42
        }
        switch result {
        case .value(let value):
            XCTAssertEqual(value, 42)
        case .timedOut:
            XCTFail("Expected value, got timeout")
        }
    }
}
