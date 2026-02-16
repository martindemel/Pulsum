import Foundation
import XCTest
@testable import PulsumServices

// Test-only: mutable stub — serial test execution, no concurrent access.
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

final class Gate0_LLMGatewayTests: XCTestCase {
    private let envVarName = "PULSUM_COACH_API_KEY"

    override func tearDown() {
        unsetenv(envVarName)
        super.tearDown()
    }

    func test_keyResolution_failsWithoutSources() throws {
        unsetenv(envVarName)
        let gateway = LLMGateway(keychain: InMemoryKeychainStore())
        gateway.debugOverrideInMemoryKey(nil)
        try gateway.debugClearPersistedAPIKey()

        XCTAssertThrowsError(try gateway.debugResolveAPIKey()) { error in
            XCTAssertEqual(error as? LLMGatewayError, .apiKeyMissing)
        }
    }

    func test_keyResolution_precedence_memory_then_keychain_then_env() throws {
        let keychain = InMemoryKeychainStore()
        let gateway = LLMGateway(keychain: keychain)
        try gateway.debugClearPersistedAPIKey()

        gateway.debugOverrideInMemoryKey("memory-key")
        XCTAssertEqual(try gateway.debugResolveAPIKey(), "memory-key")

        gateway.debugOverrideInMemoryKey(nil)
        try keychain.setSecret(Data("keychain-key".utf8), for: "openai.api.key")
        XCTAssertEqual(try gateway.debugResolveAPIKey(), "keychain-key")

        try keychain.removeSecret(for: "openai.api.key")
        setenv(envVarName, "env-key", 1)
        XCTAssertEqual(try gateway.debugResolveAPIKey(), "env-key")
    }
}
