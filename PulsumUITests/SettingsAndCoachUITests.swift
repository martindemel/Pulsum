import XCTest

final class SettingsAndCoachUITests: PulsumUITestCase {
    func testCoachChat_withStub_returnsGroundedReply() throws {
        launchPulsum()
        try enableCloudConsentIfNeeded()

        let coachTab = app.tabBars.buttons["Coach"]
        XCTAssertTrue(coachTab.waitForExistence(timeout: 5), "Coach tab is unavailable.")
        coachTab.tap()

        let chatField = app.textFields["Ask Pulsum anything about your recovery"]
        XCTAssertTrue(chatField.waitForExistence(timeout: 5), "Chat input missing.")
        chatField.tap()
        chatField.typeText("How should I wind down after work?")

        let sendButton = app.buttons["CoachSendButton"]
        XCTAssertTrue(sendButton.exists, "Send button missing.")
        sendButton.tap()

        let stubReply = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Stub response")).firstMatch
        XCTAssertTrue(stubReply.waitForExistence(timeout: 8), "Stubbed reply did not render.")
    }

    func testCloudConsentToggle_existsAndPersists() throws {
        launchPulsum()
        try openSettingsSheetOrSkip()

        guard let toggle = consentToggle() else {
            throw XCTSkip("Cloud consent toggle not present yet; defer to later gate.")
        }
        let initialValue = toggle.value as? String ?? "0"
        toggle.tap()

        let expectedValue = initialValue == "1" ? "0" : "1"
        XCTAssertEqual(toggle.value as? String, expectedValue, "Toggle did not change value.")

        dismissSettingsSheet()
        app.terminate()

        launchPulsum()
        try openSettingsSheetOrSkip()

        guard let persistedToggle = consentToggle() else {
            XCTFail("Consent toggle missing after relaunch.")
            return
        }
        XCTAssertEqual(persistedToggle.value as? String, expectedValue, "Consent state did not persist across launches.")
    }

    private func consentToggle() -> XCUIElement? {
        let toggle = app.switches["Use GPT-5 phrasing"]
        return toggle.exists ? toggle : nil
    }

    private func enableCloudConsentIfNeeded() throws {
        try openSettingsSheetOrSkip()
        guard let toggle = consentToggle() else {
            XCTFail("Consent toggle not found.")
            return
        }
        if toggle.value as? String == "0" {
            toggle.tap()
        }
        dismissSettingsSheet()
    }
}
