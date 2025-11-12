import XCTest
@testable import PulsumServices

final class Gate1_SpeechFakeBackendTests: XCTestCase {
    func testFakeBackendStreamsScriptedSegments_whenFlagOn() async throws {
        guard ProcessInfo.processInfo.environment["UITEST_FAKE_SPEECH"] == "1" else {
            throw XCTSkip("UITEST_FAKE_SPEECH not set")
        }

        let service = SpeechService()
        try await service.requestAuthorization()

        let session = try await service.startRecording(maxDuration: 1.5)
        var didEmit = false

        do {
            for try await segment in session.stream {
                XCTAssertFalse(segment.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                didEmit = true
                break
            }
        } catch {
            XCTFail("Fake backend should not throw: \(error)")
        }

        XCTAssertTrue(didEmit, "Fake backend should emit at least one segment")
        session.stop()
    }
}
