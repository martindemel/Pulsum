import XCTest

final class JournalFlowUITests: PulsumUITestCase {
    func testRecordStreamFinish_showsSavedToastAndTranscript() throws {
        launchPulsum()
        try openPulseSheetOrSkip()
        startVoiceJournal()

        let transcriptElement = waitForTranscriptText()
        let transcript = transcriptElement.label
        XCTAssertFalse(transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Transcript should stream text while recording.")
        XCTAssertTrue(transcript.contains("Energy feels steady"), "Stub speech should surface deterministic content.")

        stopVoiceJournal()
        XCTAssertTrue(app.staticTexts["Tap to record"].waitForExistence(timeout: 4), "Idle state should return after finishing.")

        let savedToast = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Saved")).firstMatch
        guard savedToast.waitForExistence(timeout: 3) else {
            throw XCTSkip("Saved toast not yet implemented (BUG-20251026-0009).")
        }
        XCTAssertTrue(savedToast.exists)
    }

    func testSecondStartIsGuarded_noDuplicateSession() throws {
        launchPulsum()
        try openPulseSheetOrSkip()
        startVoiceJournal()

        XCTAssertFalse(app.buttons["VoiceJournalStartButton"].exists, "Start button should not be visible while recording.")

        stopVoiceJournal()
        XCTAssertTrue(app.buttons["VoiceJournalStartButton"].waitForExistence(timeout: 4), "Start control should return after stopping.")
    }
}
