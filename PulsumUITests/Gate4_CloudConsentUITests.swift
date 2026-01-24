import XCTest

final class Gate4_CloudConsentUITests: PulsumUITestCase {
    func test_enter_key_and_test_connection_shows_ok_status() {
        launchPulsum()
        guard openSettingsSheetOrSkip() else { return }

        let secureKeyField = app.secureTextFields["CloudAPIKeyField"]
        let textKeyField = app.textFields["CloudAPIKeyField"]
        let keyField = secureKeyField.waitForExistence(timeout: 2) ? secureKeyField : textKeyField
        XCTAssertTrue(keyField.waitForExistence(timeout: 5), "Cloud API key field missing.")
        keyField.tapWhenHittable(timeout: 3)
        keyField.typeText("sk-test-ui-123")

        let saveButton = app.buttons["Save Key"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Save Key button missing.")
        saveButton.tapWhenHittable(timeout: 3)

        let testButton = app.buttons["CloudTestConnectionButton"]
        XCTAssertTrue(testButton.waitForExistence(timeout: 3), "Test Connection button missing.")
        testButton.tapWhenHittable(timeout: 3)

        let statusText = app.staticTexts["OpenAI reachable"]
        XCTAssertTrue(statusText.waitForExistence(timeout: 5), "API status did not report OpenAI reachable.")

        dismissSettingsSheet()
    }

    func test_open_ai_enablement_link_falls_back_to_support_url() {
        let defaults = UserDefaults(suiteName: "ai.pulsum.uiautomation")
        defaults?.removeObject(forKey: "LastOpenedURL")

        launchPulsum(additionalEnvironment: [
            "UITEST_CAPTURE_URLS": "1",
            "UITEST_FORCE_SETTINGS_FALLBACK": "1"
        ])
        guard openSettingsSheetOrSkip() else { return }

        let linkButton = app.buttons["AppleIntelligenceLinkButton"]
        XCTAssertTrue(linkButton.waitForExistence(timeout: 3))
        linkButton.tap()

        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let value = defaults?.string(forKey: "LastOpenedURL")
            return value == "https://support.apple.com/en-us/HT213969"
        }, object: nil)
        let result = XCTWaiter().wait(for: [expectation], timeout: 4)
        XCTAssertEqual(result, .completed, "Support URL was not opened.")

        dismissSettingsSheet()
    }

    func test_escape_key_dismisses_settings_if_supported() {
        launchPulsum()
        guard openSettingsSheetOrSkip() else { return }

        let closeButton = app.buttons["Close Settings"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 3))

        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])

        XCTAssertTrue(closeButton.waitForDisappearance(timeout: 3), "Settings sheet did not dismiss after Escape key.")
    }
}
