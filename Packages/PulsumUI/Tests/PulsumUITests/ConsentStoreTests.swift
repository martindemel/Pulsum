import Foundation
import PulsumData
import PulsumTypes
import SwiftData
import Testing
@testable import PulsumUI

// MARK: - B7-08 | TC-10: ConsentStore tests

@MainActor
struct ConsentStoreTests {
    private static let consentKey = PulsumDefaultsKey.cloudConsent

    @Test("grantConsent persists to UserDefaults and SwiftData")
    func test_grantConsent_persists() throws {
        let container = try TestCoreDataStack.makeContainer()
        var store = ConsentStore(consentVersion: "test-1.0")
        store.setModelContainer(container)

        let defaults = AppRuntimeConfig.runtimeDefaults
        defaults.removeObject(forKey: Self.consentKey)
        defer { defaults.removeObject(forKey: Self.consentKey) }

        store.saveConsent(true)

        // Verify UserDefaults
        #expect(defaults.bool(forKey: Self.consentKey) == true)

        // Verify SwiftData round-trip via a fresh context
        let context = ModelContext(container)
        let allPrefs = try context.fetch(FetchDescriptor<UserPrefs>())
        let defaultPrefs = allPrefs.first(where: { $0.id == "default" })
        #expect(defaultPrefs?.consentCloud == true)

        // Verify loadConsent returns true
        #expect(store.loadConsent() == true)
    }

    @Test("revokeConsent persists to UserDefaults and SwiftData")
    func test_revokeConsent_persists() throws {
        let container = try TestCoreDataStack.makeContainer()
        var store = ConsentStore(consentVersion: "test-1.0")
        store.setModelContainer(container)

        let defaults = AppRuntimeConfig.runtimeDefaults
        defaults.removeObject(forKey: Self.consentKey)
        defer { defaults.removeObject(forKey: Self.consentKey) }

        // Grant then revoke
        store.saveConsent(true)
        store.saveConsent(false)

        // Verify UserDefaults
        #expect(defaults.bool(forKey: Self.consentKey) == false)

        // Verify SwiftData round-trip via a fresh context
        let context = ModelContext(container)
        let allPrefs = try context.fetch(FetchDescriptor<UserPrefs>())
        let defaultPrefs = allPrefs.first(where: { $0.id == "default" })
        #expect(defaultPrefs?.consentCloud == false)

        // Verify loadConsent returns false
        #expect(store.loadConsent() == false)
    }
}
