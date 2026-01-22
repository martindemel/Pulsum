import XCTest
@testable import PulsumUI

@MainActor
final class PulsumRootViewTests: XCTestCase {
    func testRootViewHealthCheckPrecondition() {
        XCTAssertNotNil(PulsumRootView.self)
    }
}
