import XCTest
@testable import PulsumUI

@MainActor
final class PulsumRootViewTests: XCTestCase {
    func testRootViewHealthCheckPrecondition() throws {
#if os(macOS)
        throw XCTSkip("PulsumRootView is iOS-only in this test configuration.")
#else
        // Ensure the root view can be constructed without crashing.
        _ = PulsumRootView()
#endif
    }
}
