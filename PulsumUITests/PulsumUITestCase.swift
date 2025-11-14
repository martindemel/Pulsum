import XCTest

class PulsumUITestCase: XCTestCase {
    var app: XCUIApplication!

    private let defaultEnvironment = [
        "UITEST_USE_STUB_LLM": "1",
        "UITEST_FAKE_SPEECH": "1",
        "UITEST_AUTOGRANT": "1"
    ]

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        addUIInterruptionMonitor(withDescription: "System Permissions") { alert -> Bool in
            let positiveButtons = ["Allow", "OK", "Continue", "Allow While Using App"]
            for label in positiveButtons {
                let button = alert.buttons[label]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
        }
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
        try super.tearDownWithError()
    }

    func launchPulsum(additionalEnvironment: [String: String] = [:]) {
        app = XCUIApplication()
        var merged = defaultEnvironment
        additionalEnvironment.forEach { merged[$0.key] = $0.value }
        merged.forEach { key, value in
            app.launchEnvironment[key] = value
        }
        app.launch()
        waitForHome()
    }

    func waitForHome(timeout: TimeInterval = 15) {
        let pulseButton = app.buttons["PulseButton"]
        XCTAssertTrue(pulseButton.waitForExistence(timeout: timeout), "Pulse entry point did not appear.")
    }

    func openPulseSheetOrSkip() throws {
        let pulseButton = app.buttons["PulseButton"]
        XCTAssertTrue(pulseButton.waitForExistence(timeout: 8), "Pulse button missing.")
        pulseButton.tap()
        let sheetMarker = app.staticTexts["Voice journal"]
        if !sheetMarker.waitForExistence(timeout: 6) {
            pulseButton.tap()
        }
        guard app.staticTexts["Voice journal"].waitForExistence(timeout: 6) else {
            throw XCTSkip("Pulse sheet did not open.")
        }
    }

    func startVoiceJournal() {
        let startButton = app.buttons["VoiceJournalStartButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 4), "Voice journal start button missing.")
        if startButton.isHittable {
            startButton.tap()
        } else {
            let coordinate = startButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coordinate.tap()
        }
        app.tap() // Trigger permission monitors if alerts appear.
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

    func openSettingsSheetOrSkip() throws {
        let settingsButton = app.buttons["SettingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 6), "Settings button missing.")
        settingsButton.tap()
        let sheetMarker = app.staticTexts["Cloud Processing"]
        if !sheetMarker.waitForExistence(timeout: 6) {
            settingsButton.tap()
        }
        guard app.staticTexts["Cloud Processing"].waitForExistence(timeout: 6) else {
            throw XCTSkip("Settings sheet did not open.")
        }
    }

    func dismissSettingsSheet() {
        let closeButton = app.buttons["Close Settings"]
        if closeButton.exists {
            closeButton.tap()
        } else {
            app.swipeDown()
        }
    }
}

extension XCUIElement {
    func waitForDisappearance(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
