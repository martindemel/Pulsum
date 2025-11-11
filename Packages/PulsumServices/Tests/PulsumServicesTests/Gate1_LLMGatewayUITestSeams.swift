import XCTest
@testable import PulsumServices

final class Gate1_LLMGatewayUITestSeams: XCTestCase {
    func testStubPingShortCircuits_whenFlagOn() async throws {
        guard ProcessInfo.processInfo.environment["UITEST_USE_STUB_LLM"] == "1" else {
            throw XCTSkip("UITEST_USE_STUB_LLM not set")
        }

        let gateway = LLMGateway(keychain: InMemoryKeychainStore())
        let ok = try await gateway.testAPIConnection()

        XCTAssertTrue(ok)
        XCTAssertEqual(gateway.currentAPIKey(), "UITEST_STUB_KEY")
    }
}

private final class InMemoryKeychainStore: KeychainStoring, @unchecked Sendable {
    private var storage: [String: Data] = [:]

    func setSecret(_ value: Data, for key: String) throws {
        storage[key] = value
    }

    func secret(for key: String) throws -> Data? {
        storage[key]
    }

    func removeSecret(for key: String) throws {
        storage.removeValue(forKey: key)
    }
}
