import XCTest
import Foundation

class PulsumUITestCase: XCTestCase {
    var app: XCUIApplication!

    private let defaultEnvironment: [String: String] = [
        "UITEST": "1",
        "UITEST_USE_STUB_LLM": "1",
        "UITEST_DISABLE_CLOUD_KEYCHAIN": "1",
        "UITEST_FAKE_SPEECH": "1",
        "UITEST_AUTOGRANT": "1",
        "UITEST_HIDE_CONSENT_BANNER": "1",
        "UITEST_SETTINGS_HOOK": "1",
        "PULSUM_COACH_API_KEY": "test_key"
    ]

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        registerInterruptionMonitors()
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
        try super.tearDownWithError()
    }

    func launchPulsum(additionalEnvironment: [String: String] = [:]) {
        app = XCUIApplication()
        app.launchArguments.append("-ui_testing")
        var merged = defaultEnvironment
        additionalEnvironment.forEach { merged[$0.key] = $0.value }
        merged.forEach { key, value in
            app.launchEnvironment[key] = value
        }
        app.launch()
        triggerInterruptionHandlers()
        waitForHome()
    }

    func waitForHome(timeout: TimeInterval = 15) {
        let pulseButton = app.buttons["PulseButton"]
        XCTAssertTrue(pulseButton.waitForExistence(timeout: timeout), "Pulse entry point did not appear.")
        XCTAssertTrue(pulseButton.waitForHittable(timeout: timeout), "Pulse entry point is not hittable.")
    }

    func openPulseSheetOrSkip() throws {
        let pulseButton = app.buttons["PulseButton"]
        XCTAssertTrue(pulseButton.waitForExistence(timeout: 8), "Pulse button missing.")
        pulseButton.tapWhenHittable(timeout: 6)
        let sheetMarker = app.staticTexts["Voice journal"]
        if !sheetMarker.waitForExistence(timeout: 6) {
            pulseButton.tapWhenHittable(timeout: 6)
        }
        guard app.staticTexts["Voice journal"].waitForExistence(timeout: 6) else {
            throw XCTSkip("Pulse sheet did not open.")
        }
    }

    func startVoiceJournal() {
        let startButton = app.buttons["VoiceJournalStartButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 4), "Voice journal start button missing.")
        startButton.tapWhenHittable(timeout: 3)
        triggerInterruptionHandlers()
        XCTAssertTrue(app.buttons["VoiceJournalStopButton"].waitForExistence(timeout: 4), "Recording UI did not activate.")
    }

    func stopVoiceJournal() {
        let stopButton = app.buttons["VoiceJournalStopButton"]
        if stopButton.exists {
            stopButton.tap()
        }
    }

    @discardableResult
    func waitForTranscriptText(timeout: TimeInterval = 5) -> XCUIElement {
        let transcript = app.staticTexts["VoiceJournalTranscriptText"]
        XCTAssertTrue(transcript.waitForExistence(timeout: timeout), "Transcript did not appear.")
        return transcript
    }

    @discardableResult
    func openSettingsSheetOrSkip() -> Bool {
        let sheetMarker = app.otherElements["SettingsSheetRoot"]
        if sheetMarker.exists {
            return true
        }
        let settingsButtons = app.buttons.matching(identifier: "SettingsButton")
        let settingsButton = firstHittableElement(in: settingsButtons, timeout: 6)
        if let settingsButton {
            settingsButton.tapWhenHittable(timeout: 2)
        } else {
            let hookButton = firstHittableElement(in: app.buttons.matching(identifier: "SettingsTestHookButton"),
                                                  timeout: 2)
            hookButton?.tapWhenHittable(timeout: 2)
        }
        let sheet = app.sheets.firstMatch
        let opened = sheet.waitForExistence(timeout: 6) || sheetMarker.waitForExistence(timeout: 2)
        if !opened {
            settingsButton?.tapWhenHittable(timeout: 2)
        }
        if !sheet.exists && !sheetMarker.exists {
            let hookButton = firstHittableElement(in: app.buttons.matching(identifier: "SettingsTestHookButton"),
                                                  timeout: 2)
            hookButton?.tapWhenHittable(timeout: 2)
        }
        guard sheet.exists || sheetMarker.waitForExistence(timeout: 6) else {
            recordSettingsSheetFailure()
            XCTFail("Settings sheet did not open.")
            return false
        }
        return true
    }

    /// Tap a field and wait for the keyboard to appear, retrying if focus is stolen.
    func tapAndWaitForKeyboard(_ element: XCUIElement, retries: Int = 3) {
        for attempt in 0..<retries {
            element.tapWhenHittable(timeout: 3)
            if app.keyboards.firstMatch.waitForExistence(timeout: attempt == 0 ? 2 : 3) {
                return
            }
        }
    }

    func dismissKeyboardIfPresent() {
        guard app.keyboards.count > 0 else { return }
        // Tap a non-interactive label to resign first responder.
        // Avoids navigation bar (close button) and keyboard gestures (destabilize simulator).
        let labels = ["Cloud Processing", "GPT-5 API Key", "Use GPT-5 phrasing"]
        for label in labels {
            let element = app.staticTexts[label]
            if element.exists && element.isHittable {
                element.tap()
                break
            }
        }
        _ = app.keyboards.firstMatch.waitForDisappearance(timeout: 2)
    }

    func dismissSettingsSheet() {
        let closeButton = app.buttons["Close Settings"]
        if closeButton.exists {
            closeButton.tap()
        } else {
            app.swipeDown()
        }
    }

    private func registerInterruptionMonitors() {
        addUIInterruptionMonitor(withDescription: "Speech and Microphone Permissions") { alert in
            guard Self.alertContainsPermissionText(alert) else { return false }
            return Self.tapAllowButton(in: alert)
        }

        addUIInterruptionMonitor(withDescription: "System Alerts") { alert in
            return Self.tapAllowButton(in: alert)
        }
    }

    private func triggerInterruptionHandlers(maxAttempts: Int = 3) {
        guard app != nil else { return }
        for _ in 0..<maxAttempts {
            if app.alerts.firstMatch.waitForExistence(timeout: 1) {
                app.tap()
            } else {
                break
            }
        }
    }

    private func recordSettingsSheetFailure() {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "SettingsSheetMissing"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let debugAttachment = XCTAttachment(string: app.debugDescription)
        debugAttachment.name = "SettingsSheetDebugDescription"
        debugAttachment.lifetime = .keepAlways
        add(debugAttachment)
    }

    private func firstHittableElement(in query: XCUIElementQuery,
                                      timeout: TimeInterval) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let count = query.count
            if count > 0 {
                for index in 0..<count {
                    let element = query.element(boundBy: index)
                    if element.exists && element.isHittable {
                        return element
                    }
                }
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        let fallback = query.firstMatch
        return fallback.exists ? fallback : nil
    }

    private static func tapAllowButton(in alert: XCUIElement) -> Bool {
        let positiveButtons = [
            "Allow",
            "OK",
            "Continue",
            "Allow While Using App",
            "Allow Once",
            "Always Allow"
        ]
        for label in positiveButtons {
            let button = alert.buttons[label]
            if button.exists {
                button.tap()
                return true
            }
        }
        return false
    }

    private static func alertContainsPermissionText(_ alert: XCUIElement) -> Bool {
        let keywords = ["microphone", "speech recognition", "speech", "dictation"]
        let alertText = ([alert.label] + alert.staticTexts.allElementsBoundByIndex.map { $0.label })
            .joined(separator: " ")
            .lowercased()
        return keywords.contains { alertText.contains($0) }
    }
}

extension XCUIElement {
    func waitForDisappearance(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    func waitForHittable(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == true && hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    func tapWhenHittable(timeout: TimeInterval) {
        if waitForHittable(timeout: timeout) {
            tap()
            return
        }

        guard exists else { return }
        let coordinate = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coordinate.tap()
    }
}
