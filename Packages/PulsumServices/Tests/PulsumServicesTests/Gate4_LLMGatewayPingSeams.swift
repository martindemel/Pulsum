import XCTest
@testable import PulsumServices

final class Gate4_LLMGatewayPingSeams: XCTestCase {
    func testStubPingShortCircuitsWhenFlagEnabled() async throws {
        let previous = getenv("UITEST_USE_STUB_LLM").flatMap { String(cString: $0) }
        setenv("UITEST_USE_STUB_LLM", "1", 1)
        defer {
            if let previous {
                setenv("UITEST_USE_STUB_LLM", previous, 1)
            } else {
                unsetenv("UITEST_USE_STUB_LLM")
            }
        }

        let gateway = LLMGateway()
        let result = try await gateway.testAPIConnection()
        XCTAssertTrue(result)
    }
}
