import XCTest
@testable import PulsumAgents
@testable import PulsumServices
import PulsumTypes

final class Gate2_JournalSessionTests: XCTestCase {
    func testBeginRejectsDuplicateSessions() async throws {
        let state = JournalSessionState()
        try await state.begin(with: makeSession())
        do {
            try await state.begin(with: makeSession())
            XCTFail("Expected SentimentAgentError.sessionAlreadyActive")
        } catch let error as SentimentAgentError {
            XCTAssertEqual(error, .sessionAlreadyActive)
        }
    }

    func testTakeSessionClearsState() async throws {
        let state = JournalSessionState()
        try await state.begin(with: makeSession())
        await state.updateTranscript("hello world")

        let result = await state.takeSession()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.1, "hello world")

        let nextResult = await state.takeSession()
        XCTAssertNil(nextResult)
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
