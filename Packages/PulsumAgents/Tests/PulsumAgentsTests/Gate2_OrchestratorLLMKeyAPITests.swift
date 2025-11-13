#if DEBUG
import Foundation
import XCTest
@testable import PulsumAgents
@testable import PulsumServices
import PulsumML
import PulsumTypes

@MainActor
final class Gate2_OrchestratorLLMKeyAPITests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        StubURLProtocol.handler = nil
    }

    func testLLMKeyRoundTripAndConnectivity() async throws {
        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: ["Content-Type": "application/json"])!
            let payload = #"{"id":"stub","object":"response","output":[]}"#.data(using: .utf8)!
            return (response, payload)
        }

        let orchestrator = try makeOrchestrator()

        XCTAssertNil(orchestrator.currentLLMAPIKey())

        try orchestrator.setLLMAPIKey("ci-test-valid")
        XCTAssertEqual(orchestrator.currentLLMAPIKey(), "ci-test-valid")

        let ping = try await orchestrator.testLLMAPIConnection()
        XCTAssertTrue(ping)
    }

    private func makeOrchestrator() throws -> AgentOrchestrator {
        let coachAgent = try makeCoachAgent()
        return AgentOrchestrator(
            dataAgent: DataAgentStub(),
            sentimentAgent: SentimentAgentStub(),
            coachAgent: coachAgent,
            safetyAgent: SafetyAgent(),
            cheerAgent: CheerAgent(),
            topicGate: TopicGateStub(),
            afmAvailable: false
        )
    }

    private func makeCoachAgent() throws -> CoachAgent {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let gateway = LLMGateway(keychain: InMemoryKeychain(), session: session)
        return try CoachAgent(llmGateway: gateway, shouldIngestLibrary: false)
    }
}

// MARK: - Test doubles

private actor DataAgentStub: DataAgentProviding {
    func start() async throws {}
    func latestFeatureVector() async throws -> FeatureVectorSnapshot? { nil }
    func recordSubjectiveInputs(date: Date,
                                stress: Double,
                                energy: Double,
                                sleepQuality: Double) async throws {}
    func scoreBreakdown() async throws -> ScoreBreakdown? { nil }
    func reprocessDay(date: Date) async throws {}
}

@MainActor
private final class SentimentAgentStub: SentimentAgentProviding {
    var audioLevels: AsyncStream<Float>? { nil }
    var speechStream: AsyncThrowingStream<SpeechSegment, Error>? { nil }

    func beginVoiceJournal(maxDuration: TimeInterval) async throws {}
    func finishVoiceJournal(transcript: String?) async throws -> JournalResult {
        throw SentimentAgentError.noActiveRecording
    }

    func recordVoiceJournal(maxDuration: TimeInterval) async throws -> JournalResult {
        throw SentimentAgentError.noActiveRecording
    }

    func importTranscript(_ transcript: String) async throws -> JournalResult {
        throw SentimentAgentError.noActiveRecording
    }

    func requestAuthorization() async throws {}
    func stopRecording() {}
    func updateTranscript(_ transcript: String) {}
    func latestTranscriptSnapshot() -> String { "" }
}

private struct TopicGateStub: TopicGateProviding {
    func classify(_ text: String) async throws -> GateDecision {
        GateDecision(isOnTopic: true, reason: "stub", confidence: 0.99, topic: nil)
    }
}

private final class InMemoryKeychain: KeychainStoring, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    private let lock = NSLock()

    func setSecret(_ value: Data, for key: String) throws {
        lock.lock()
        storage[key] = value
        lock.unlock()
    }

    func secret(for key: String) throws -> Data? {
        lock.lock()
        let value = storage[key]
        lock.unlock()
        return value
    }

    func removeSecret(for key: String) throws {
        lock.lock()
        storage.removeValue(forKey: key)
        lock.unlock()
    }
}

private final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
#endif
