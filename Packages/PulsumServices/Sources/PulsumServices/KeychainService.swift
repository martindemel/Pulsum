import Foundation
import Security
import PulsumTypes

public protocol APIKeyProviding: Sendable {
    func storeAPIKeyData(_ value: Data, identifier: String) throws
    func fetchAPIKeyData(for identifier: String) throws -> Data?
    func removeAPIKey(for identifier: String) throws
}

public protocol KeychainStoring: APIKeyProviding {
    func setSecret(_ value: Data, for key: String) throws
    func secret(for key: String) throws -> Data?
    func removeSecret(for key: String) throws
}

public extension KeychainStoring {
    func storeAPIKeyData(_ value: Data, identifier: String) throws {
        try setSecret(value, for: identifier)
    }

    func fetchAPIKeyData(for identifier: String) throws -> Data? {
        try secret(for: identifier)
    }

    func removeAPIKey(for identifier: String) throws {
        try removeSecret(for: identifier)
    }
}

public enum KeychainServiceError: LocalizedError {
    case unexpectedStatus(OSStatus)

    public var errorDescription: String? {
        switch self {
        case let .unexpectedStatus(status):
            if let message = SecCopyErrorMessageString(status, nil) as String? {
                return message
            }
            return "Unexpected keychain status: \(status)"
        }
    }
}

/// Minimal wrapper around iOS Keychain for Pulsum secrets.
public final class KeychainService: KeychainStoring {
    public static let shared = KeychainService()

    private let accessGroup: String?
    private let service = "ai.pulsum.app"

    private var useFallbackStore: Bool {
        #if DEBUG
        return AppRuntimeConfig.disableKeychain
        #else
        return false
        #endif
    }

    public init(accessGroup: String? = nil) {
        self.accessGroup = accessGroup
    }

    public func setSecret(_ value: Data, for key: String) throws {
        if useFallbackStore {
            Self.storeFallback(value, for: key)
            return
        }
        var query: [String: Any] = baseQuery(for: key)
        query[kSecValueData as String] = value
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            try updateSecret(value, for: key)
            return
        }
        guard status == errSecSuccess else { throw KeychainServiceError.unexpectedStatus(status) }
    }

    public func secret(for key: String) throws -> Data? {
        if useFallbackStore {
            return Self.fetchFallback(for: key)
        }
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainServiceError.unexpectedStatus(status) }
        return item as? Data
    }

    public func removeSecret(for key: String) throws {
        if useFallbackStore {
            Self.removeFallback(for: key)
            return
        }
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainServiceError.unexpectedStatus(status)
        }
    }

    private func updateSecret(_ value: Data, for key: String) throws {
        let status = SecItemUpdate(baseQuery(for: key) as CFDictionary,
                                   [kSecValueData as String: value] as CFDictionary)
        guard status == errSecSuccess else { throw KeychainServiceError.unexpectedStatus(status) }
    }

    private func baseQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }

    private static func storeFallback(_ value: Data, for key: String) {
        let defaults = AppRuntimeConfig.uiTestDefaults
        defaults.set(value, forKey: key)
        AppRuntimeConfig.synchronizeUITestDefaults()
    }

    private static func fetchFallback(for key: String) -> Data? {
        AppRuntimeConfig.uiTestDefaults.data(forKey: key)
    }

    private static func removeFallback(for key: String) {
        let defaults = AppRuntimeConfig.uiTestDefaults
        defaults.removeObject(forKey: key)
        AppRuntimeConfig.synchronizeUITestDefaults()
    }
}

// SAFETY: All stored properties are immutable (`let`) and Sendable (String, String?).
extension KeychainService: Sendable {}
