import XCTest
@testable import PulsumAgents
@testable import PulsumServices
import PulsumTypes

final class Gate2_JournalSessionTests: XCTestCase {
    func testBeginRejectsDuplicateSessions() throws {
        let state = JournalSessionState()
        try state.begin(with: makeSession())
        XCTAssertThrowsError(try state.begin(with: makeSession())) { error in
            guard let sentimentError = error as? SentimentAgentError else {
                return XCTFail("Expected SentimentAgentError, got \(error)")
            }
            XCTAssertEqual(sentimentError, .sessionAlreadyActive)
        }
    }

    func testTakeSessionClearsState() throws {
        let state = JournalSessionState()
        try state.begin(with: makeSession())
        state.updateTranscript("hello world")

        let result = state.takeSession()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.1, "hello world")

        XCTAssertNil(state.takeSession())
    }

    private func makeSession() -> SpeechService.Session {
        let stream = AsyncThrowingStream<SpeechSegment, Error> { continuation in
            continuation.finish()
        }
        let levels = AsyncStream<Float> { continuation in
            continuation.finish()
        }
        return SpeechService.Session(stream: stream, stop: {}, audioLevels: levels)
    }
}
