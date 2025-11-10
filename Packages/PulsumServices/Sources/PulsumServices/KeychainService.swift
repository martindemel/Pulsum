import Foundation
import Security

public protocol KeychainStoring: Sendable {
    func setSecret(_ value: Data, for key: String) throws
    func secret(for key: String) throws -> Data?
    func removeSecret(for key: String) throws
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

    public init(accessGroup: String? = nil) {
        self.accessGroup = accessGroup
    }

    public func setSecret(_ value: Data, for key: String) throws {
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
}

extension KeychainService: @unchecked Sendable {}
