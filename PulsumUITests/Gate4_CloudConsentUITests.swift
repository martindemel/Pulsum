import XCTest

final class Gate4_CloudConsentUITests: PulsumUITestCase {
    func test_enter_key_and_test_connection_shows_ok_status() {
        launchPulsum(additionalEnvironment: ["PULSUM_COACH_API_KEY": "sk-test-ui-123"])
        guard openSettingsSheetOrSkip() else { return }

        let secureKeyField = app.secureTextFields["CloudAPIKeyField"]
        let textKeyField = app.textFields["CloudAPIKeyField"]
        let keyField = secureKeyField.waitForExistence(timeout: 2) ? secureKeyField : textKeyField
        XCTAssertTrue(keyField.waitForExistence(timeout: 5), "Cloud API key field missing.")
        ensureElementIsVisibleInSettingsIfNeeded(keyField)
        // Prefer a seeded key for simulator stability; only drive keyboard input when needed.
        if !containsNonPlaceholderValue(keyField) {
            XCTAssertTrue(tapAndWaitForKeyboard(keyField, retries: 7),
                          "Cloud API key field did not gain keyboard focus.")
            keyField.typeText("sk-test-ui-123")
        }

        // Dismiss keyboard so buttons below are hittable on small screens (iPhone SE)
        dismissKeyboardIfPresent()

        let saveButton = app.buttons["Save Key"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Save Key button missing.")
        saveButton.tapWhenHittable(timeout: 3)

        // Wait for the save Task to complete on MainActor before tapping Test Connection.
        // The status changes to "API key saved" or "Agent unavailable" on completion.
        let saved = app.staticTexts["API key saved"]
        _ = saved.waitForExistence(timeout: 3)

        let testButton = app.buttons["CloudTestConnectionButton"]
        XCTAssertTrue(testButton.waitForExistence(timeout: 5), "Test Connection button missing.")
        testButton.tapWhenHittable(timeout: 5)

        let statusElement = app.staticTexts["GPTAPIStatusText"]
        XCTAssertTrue(statusElement.waitForExistence(timeout: 8), "GPT API status text element missing.")
        let actualStatus = statusElement.label
        XCTAssertEqual(actualStatus, "OpenAI reachable", "Expected 'OpenAI reachable' but got '\(actualStatus)'")

        dismissSettingsSheet()
    }

    func test_open_ai_enablement_link_falls_back_to_support_url() {
        launchPulsum(additionalEnvironment: [
            "UITEST_CAPTURE_URLS": "1",
            "UITEST_FORCE_SETTINGS_FALLBACK": "1"
        ])
        guard openSettingsSheetOrSkip() else { return }

        let linkButton = app.buttons["AppleIntelligenceLinkButton"]
        XCTAssertTrue(linkButton.waitForExistence(timeout: 4))
        ensureElementIsVisibleInSettingsIfNeeded(linkButton)
        linkButton.tapWhenHittable(timeout: 4)

        let urlLabel = app.staticTexts["LastOpenedURL"]
        XCTAssertTrue(urlLabel.waitForExistence(timeout: 4), "Support URL was not captured.")
        XCTAssertEqual(urlLabel.label, "https://support.apple.com/en-us/HT213969")

        dismissSettingsSheet()
    }

    func test_escape_key_dismisses_settings_if_supported() {
        launchPulsum()
        guard openSettingsSheetOrSkip() else { return }

        let closeButton = app.buttons["Close Settings"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 3))

        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])

        if !closeButton.waitForDisappearance(timeout: 3) {
            closeButton.tap()
        }
        XCTAssertTrue(closeButton.waitForDisappearance(timeout: 3), "Settings sheet did not dismiss after Escape key.")
    }

    private func ensureElementIsVisibleInSettingsIfNeeded(_ element: XCUIElement, maxSwipes: Int = 4) {
        guard !element.isHittable else { return }

        for _ in 0..<maxSwipes {
            app.swipeUp()
            if element.isHittable { return }
        }

        for _ in 0..<maxSwipes {
            app.swipeDown()
            if element.isHittable { return }
        }
    }

    private func containsNonPlaceholderValue(_ element: XCUIElement) -> Bool {
        guard let rawValue = element.value as? String else { return false }
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return false }
        if value == "sk-..." { return false }
        if value.lowercased() == "secure text field" { return false }
        return true
    }
}
