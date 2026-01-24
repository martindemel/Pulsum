import XCTest
import Foundation

final class SettingsAndCoachUITests: PulsumUITestCase {
    func testCoachChat_withStub_returnsGroundedReply() {
        launchPulsum()
        guard enableCloudConsentIfNeeded() else { return }

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

        let stubReply = app.staticTexts["CoachAssistantMessage"]
        XCTAssertTrue(stubReply.waitForExistence(timeout: 8), "Stubbed reply did not render.")
        XCTAssertTrue(stubReply.label.contains("Stub response"), "Stubbed reply text missing.")
    }

    func testCloudConsentToggle_existsAndPersists() {
        launchPulsum()
        guard openSettingsSheetOrSkip() else { return }

        guard let toggle = findConsentToggle() else {
            XCTFail("Cloud consent toggle not present yet.")
            return
        }
        guard let initialValue = toggleValue(toggle) else {
            XCTFail("Consent toggle value unreadable.")
            return
        }
        tapConsentToggle(toggle)

        let expectedValue = !initialValue
        assertConsentValue(expectedValue, message: "Toggle did not change value.")

        dismissSettingsSheet()
        app.terminate()

        launchPulsum()
        guard openSettingsSheetOrSkip() else { return }

        guard findConsentToggle() != nil else {
            XCTFail("Consent toggle missing after relaunch.")
            return
        }
        assertConsentValue(expectedValue, message: "Consent state did not persist across launches.")
    }

    private func findConsentToggle(timeout: TimeInterval = 5) -> XCUIElement? {
        let toggle = app.switches["CloudConsentToggle"]
        if toggle.waitForExistence(timeout: timeout) {
            return toggle
        }
        let fallback = app.otherElements["CloudConsentToggle"]
        if fallback.waitForExistence(timeout: timeout) {
            return fallback
        }
        return nil
    }

    @discardableResult
    private func enableCloudConsentIfNeeded() -> Bool {
        guard openSettingsSheetOrSkip() else { return false }
        guard let toggle = findConsentToggle() else {
            XCTFail("Consent toggle not found.")
            return false
        }
        if toggleValue(toggle) == false {
            tapConsentToggle(toggle)
        }
        dismissSettingsSheet()
        return true
    }

    private func toggleValue(_ toggle: XCUIElement) -> Bool? {
        if let raw = toggle.value as? String {
            switch raw.lowercased() {
            case "1", "on", "true":
                return true
            case "0", "off", "false":
                return false
            default:
                return nil
            }
        }
        if let number = toggle.value as? NSNumber {
            return number.boolValue
        }
        if let value = toggle.value as? Bool {
            return value
        }
        return nil
    }

    private func waitForConsentValue(_ expectedValue: Bool, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let toggle = findConsentToggle(timeout: 0.2),
               let value = toggleValue(toggle),
               value == expectedValue {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return false
    }

    private func tapConsentToggle(_ toggle: XCUIElement? = nil) {
        if let toggle = toggle ?? findConsentToggle(timeout: 2) {
            toggle.tapWhenHittable(timeout: 3)
            return
        }
        let label = app.staticTexts["Use GPT-5 phrasing"]
        if label.exists {
            label.tapWhenHittable(timeout: 3)
        }
    }

    private func assertConsentValue(_ expectedValue: Bool, message: String) {
        guard waitForConsentValue(expectedValue, timeout: 3) else {
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "ConsentToggleFailure"
            screenshot.lifetime = .keepAlways
            add(screenshot)

            let debugAttachment = XCTAttachment(string: app.debugDescription)
            debugAttachment.name = "ConsentToggleDebugDescription"
            debugAttachment.lifetime = .keepAlways
            add(debugAttachment)

            XCTFail(message)
            return
        }
    }
}
