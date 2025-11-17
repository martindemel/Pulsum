#if DEBUG
import Foundation
import XCTest
@testable import PulsumAgents
@testable import PulsumServices

final class Gate4_LLMKeyTests: XCTestCase {
    func testSetAndGetKeyRoundtripUsesKeychainStub() throws {
        let keychain = EphemeralKeychain()
        let gateway = LLMGateway(keychain: keychain)

        XCTAssertNil(gateway.currentAPIKey())
        try gateway.setAPIKey("  demo-key  ")
        XCTAssertEqual(gateway.currentAPIKey(), "demo-key")
        XCTAssertEqual(String(data: keychain.storage["openai.api.key"] ?? Data(), encoding: .utf8), "demo-key")
    }

    func testPingAcceptsExpectedVariants() {
        var body = LLMGateway.makePingRequestBody()
        if var input = body["input"] as? [[String: Any]] {
            input[0]["content"] = "PING"
            body["input"] = input
        }

        XCTAssertTrue(LLMGateway.validatePingPayload(body))
    }
}

private final class EphemeralKeychain: KeychainStoring, @unchecked Sendable {
    fileprivate var storage: [String: Data] = [:]
    private let lock = NSLock()

    func setSecret(_ value: Data, for key: String) throws {
        lock.lock()
        storage[key] = value
        lock.unlock()
    }

    func secret(for key: String) throws -> Data? {
        lock.lock()
        let value = storage[key]
        lock.unlock()
        return value
    }

    func removeSecret(for key: String) throws {
        lock.lock()
        storage.removeValue(forKey: key)
        lock.unlock()
    }
}
#endif
