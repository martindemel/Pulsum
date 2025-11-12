import XCTest

final class FirstRunPermissionsUITests: PulsumUITestCase {
    func testFirstRun_authorizeSpeechAndMic() throws {
        launchPulsum()
        try openPulseSheetOrSkip()
        startVoiceJournal()

        XCTAssertTrue(app.buttons["VoiceJournalStopButton"].exists, "Stop control should be visible once recording begins.")

        stopVoiceJournal()
    }
}
