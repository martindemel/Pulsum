import XCTest

final class Gate4_CloudConsentUITests: PulsumUITestCase {
    func test_enter_key_and_test_connection_shows_ok_pill() throws {
        launchPulsum()
        try openSettingsSheetOrSkip()

        let keyField = app.secureTextFields["CloudAPIKeyField"]
        XCTAssertTrue(keyField.waitForExistence(timeout: 5), "Cloud API key field missing.")
        keyField.tap()
        keyField.typeText("sk-test-ui-123")

        let saveButton = app.buttons["CloudAPISaveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        saveButton.tap()

        let testButton = app.buttons["CloudAPITestButton"]
        XCTAssertTrue(testButton.waitForExistence(timeout: 3))
        testButton.tap()

        let statusText = app.staticTexts["CloudAPIStatusText"]
        XCTAssertTrue(statusText.waitForExistence(timeout: 5))
        XCTAssertEqual(statusText.label, "OpenAI reachable")

        let badge = app.otherElements["CloudAPIStatusBadge"]
        XCTAssertTrue(badge.waitForExistence(timeout: 2))

        dismissSettingsSheet()
    }

    func test_open_ai_enablement_link_falls_back_to_support_url() throws {
        let defaults = UserDefaults(suiteName: "ai.pulsum.uiautomation")
        defaults?.removeObject(forKey: "LastOpenedURL")

        launchPulsum(additionalEnvironment: [
            "UITEST_CAPTURE_URLS": "1",
            "UITEST_FORCE_SETTINGS_FALLBACK": "1"
        ])
        try openSettingsSheetOrSkip()

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

    func test_escape_key_dismisses_settings_if_supported() throws {
        launchPulsum()
        try openSettingsSheetOrSkip()

        let closeButton = app.buttons["Close Settings"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 3))

        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])

        XCTAssertTrue(closeButton.waitForDisappearance(timeout: 3), "Settings sheet did not dismiss after Escape key.")
    }
}
