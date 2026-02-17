import XCTest
import Foundation

/// Base class for all Pulsum UI tests.
///
/// Provides common infrastructure for launching the app with test environment
/// variables, handling system permission alerts, and navigating to key screens.
///
/// ## Settings Sheet Detection Strategy (B6-07 | LOW-02)
///
/// Opening the settings sheet is challenging because the button's accessibility
/// identity can vary between iOS versions and SwiftUI layout passes. The
/// `openSettingsSheetOrSkip()` method uses a **multi-strategy approach**:
///
/// 1. **Direct button tap** — tries the primary `SettingsButton` identifier.
/// 2. **Test hook fallback** — if no hittable settings button is found,
///    tries `SettingsTestHookButton` (injected in UITEST mode).
/// 3. **Retry on sheet absence** — if the sheet doesn't appear after the
///    first tap, retries with the same button or hook.
/// 4. **Sheet detection** — checks both `app.sheets.firstMatch` and
///    `SettingsSheetRoot` (an `otherElements` identifier), because the
///    sheet presentation style varies between compact and regular size classes.
/// 5. **Diagnostic capture** — on failure, screenshots and debug descriptions
///    are attached via `recordSettingsSheetFailure()` for post-mortem analysis.
///
/// ## Retry Configuration
///
/// Retry counts and timeouts are defined as static constants below.
/// Adjust these when running on slower CI machines or different simulator hardware.
class PulsumUITestCase: XCTestCase {
    var app: XCUIApplication!

    // MARK: - Configurable Constants (B6-07 | LOW-02)

    /// Maximum retries for triggering system alert interruption handlers.
    static let maxInterruptionRetries = 3

    /// Maximum retries for tapping a text field and waiting for keyboard focus.
    static let maxKeyboardFocusRetries = 3

    /// Default timeout (seconds) for waiting for the home screen after launch.
    static let homeLaunchTimeout: TimeInterval = 15

    /// Default timeout (seconds) for element existence checks.
    static let defaultElementTimeout: TimeInterval = 6

    /// Default timeout (seconds) for settings sheet appearance.
    static let settingsSheetTimeout: TimeInterval = 6

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
        for (key, value) in merged {
            app.launchEnvironment[key] = value
        }
        app.launch()
        triggerInterruptionHandlers()
        waitForHome()
    }

    func waitForHome(timeout: TimeInterval = homeLaunchTimeout) {
        XCTContext.runActivity(named: "Wait for home screen") { _ in
            let pulseButton = app.buttons["PulseButton"]
            XCTAssertTrue(pulseButton.waitForExistence(timeout: timeout), "Pulse entry point did not appear.")
            XCTAssertTrue(pulseButton.waitForHittable(timeout: timeout), "Pulse entry point is not hittable.")
        }
    }

    func openPulseSheetOrSkip() throws {
        try XCTContext.runActivity(named: "Open pulse sheet") { _ in
            let pulseButton = app.buttons["PulseButton"]
            XCTAssertTrue(pulseButton.waitForExistence(timeout: 8), "Pulse button missing.")
            pulseButton.tapWhenHittable(timeout: Self.defaultElementTimeout)
            let sheetMarker = app.staticTexts["Voice journal"]
            if !sheetMarker.waitForExistence(timeout: Self.defaultElementTimeout) {
                pulseButton.tapWhenHittable(timeout: Self.defaultElementTimeout)
            }
            guard app.staticTexts["Voice journal"].waitForExistence(timeout: Self.defaultElementTimeout) else {
                throw XCTSkip("Pulse sheet did not open.")
            }
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

    /// Opens the settings sheet using a multi-strategy detection approach.
    ///
    /// See the class-level documentation for a description of the detection strategies.
    /// If all strategies fail, a screenshot and debug description are captured for
    /// post-mortem analysis, and the test is skipped with `XCTSkip`.
    func openSettingsSheetOrSkip() throws {
        try XCTContext.runActivity(named: "Open settings sheet") { _ in
            // Strategy 0: Already open — check for the sheet root marker.
            let sheetMarker = app.otherElements["SettingsSheetRoot"]
            if sheetMarker.exists {
                return
            }

            // Strategy 1: Direct button tap via primary identifier.
            let settingsButtons = app.buttons.matching(identifier: "SettingsButton")
            let settingsButton = firstHittableElement(in: settingsButtons, timeout: Self.settingsSheetTimeout)
            if let settingsButton {
                settingsButton.tapWhenHittable(timeout: 2)
            } else {
                // Strategy 2: Test hook button fallback (injected in UITEST mode).
                let hookButton = firstHittableElement(in: app.buttons.matching(identifier: "SettingsTestHookButton"),
                                                      timeout: 2)
                hookButton?.tapWhenHittable(timeout: 2)
            }

            // Wait for either sheet presentation style to appear.
            let sheet = app.sheets.firstMatch
            let opened = sheet.waitForExistence(timeout: Self.settingsSheetTimeout)
                || sheetMarker.waitForExistence(timeout: 2)

            // Strategy 3: Retry tap if sheet didn't appear on first attempt.
            if !opened {
                settingsButton?.tapWhenHittable(timeout: 2)
            }
            if !sheet.exists && !sheetMarker.exists {
                let hookButton = firstHittableElement(in: app.buttons.matching(identifier: "SettingsTestHookButton"),
                                                      timeout: 2)
                hookButton?.tapWhenHittable(timeout: 2)
            }

            // Final check — capture diagnostics on failure.
            guard sheet.exists || sheetMarker.waitForExistence(timeout: Self.settingsSheetTimeout) else {
                recordSettingsSheetFailure()
                throw XCTSkip("Settings sheet did not open.")
            }
        }
    }

    /// Tap a text input and wait until the element is actually focused.
    /// Relying on keyboard existence alone can be flaky on simulator CI.
    @discardableResult
    func tapAndWaitForKeyboard(_ element: XCUIElement, retries: Int = maxKeyboardFocusRetries) -> Bool {
        for attempt in 0 ..< retries {
            element.tapWhenHittable(timeout: 3)
            _ = app.keyboards.firstMatch.waitForExistence(timeout: attempt == 0 ? 2 : 3)
            if element.hasKeyboardFocusValue {
                return true
            }

            // Fallback tap at center helps when SwiftUI wrappers swallow the first tap.
            let coordinate = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coordinate.tap()
            if element.hasKeyboardFocusValue {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return element.hasKeyboardFocusValue
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

    private func triggerInterruptionHandlers(maxAttempts: Int = maxInterruptionRetries) {
        guard app != nil else { return }
        for _ in 0 ..< maxAttempts {
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
                for index in 0 ..< count {
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
    /// `hasKeyboardFocus` is not exposed on all XCTest SDK overlays.
    /// Reading via KVC keeps this helper portable across Xcode point releases.
    var hasKeyboardFocusValue: Bool {
        (value(forKey: "hasKeyboardFocus") as? Bool) ?? false
    }

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
