import XCTest
@testable import PulsumUI

final class PulsumRootViewTests: XCTestCase {
    func testRootViewHealthCheckPrecondition() {
        XCTAssertNotNil(PulsumRootView().body)
    }
}
