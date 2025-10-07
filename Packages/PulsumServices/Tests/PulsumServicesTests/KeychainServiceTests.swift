import XCTest
@testable import PulsumServices

final class KeychainServiceTests: XCTestCase {
    func testRoundTripSecret() throws {
        let service = KeychainService()
        let key = "test.api.key"
        let value = Data("secret".utf8)
        try service.setSecret(value, for: key)
        let retrieved = try service.secret(for: key)
        XCTAssertEqual(retrieved, value)
        try service.removeSecret(for: key)
        XCTAssertNil(try service.secret(for: key))
    }
}
