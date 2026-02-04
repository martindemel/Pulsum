import XCTest
@testable import PulsumUI

@MainActor
final class PulsumRootViewTests: XCTestCase {
    func testRootViewHealthCheckPrecondition() {
        // Ensure the root view can be constructed without crashing.
        _ = PulsumRootView()
    }
}
