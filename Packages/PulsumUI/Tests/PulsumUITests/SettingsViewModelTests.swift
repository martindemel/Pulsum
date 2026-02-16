import Foundation
import Testing
@testable import PulsumUI

// MARK: - B7-07 | TC-07: SettingsViewModel consent tests

@MainActor
struct SettingsViewModelTests {
    @Test("toggleConsent(true) sets consentGranted to true")
    func test_toggleConsent_on() {
        let vm = SettingsViewModel(initialConsent: false)
        #expect(vm.consentGranted == false)

        vm.toggleConsent(true)

        #expect(vm.consentGranted == true)
        #expect(vm.lastConsentUpdated <= Date())
    }

    @Test("toggleConsent(false) sets consentGranted to false")
    func test_toggleConsent_off() {
        let vm = SettingsViewModel(initialConsent: true)
        #expect(vm.consentGranted == true)

        vm.toggleConsent(false)

        #expect(vm.consentGranted == false)
    }

    @Test("toggleConsent is a no-op when value is unchanged")
    func test_toggleConsent_noopWhenSame() {
        let vm = SettingsViewModel(initialConsent: true)
        let before = vm.consentDidChange

        vm.toggleConsent(true)

        #expect(vm.consentDidChange == before, "consentDidChange should not toggle for same value")
    }

    @Test("consentDidChange toggles after each consent change")
    func test_consentDidChange_signals() {
        let vm = SettingsViewModel(initialConsent: false)
        let initial = vm.consentDidChange

        vm.toggleConsent(true)
        #expect(vm.consentDidChange != initial, "consentDidChange should toggle after first change")

        let afterFirst = vm.consentDidChange
        vm.toggleConsent(false)
        #expect(vm.consentDidChange != afterFirst, "consentDidChange should toggle after second change")
    }
}
