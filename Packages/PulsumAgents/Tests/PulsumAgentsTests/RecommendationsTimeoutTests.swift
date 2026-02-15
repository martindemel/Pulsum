import SwiftData
import XCTest
import HealthKit
import PulsumData
import PulsumML
import PulsumTypes
@testable import PulsumAgents

@MainActor
final class RecommendationsTimeoutTests: XCTestCase {
    func testRecommendationsTimeoutReturnsFallback() async throws {
        let container = try TestCoreDataStack.makeContainer()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()
        let snapshot = try makeSnapshot(container: container)
        let dataAgent = DataAgentStub(snapshot: snapshot)
        let slowIndex = SlowVectorIndex(delayNanoseconds: 200_000_000)
        let coachAgent = try CoachAgent(container: container,
                                        storagePaths: storagePaths,
                                        vectorIndex: slowIndex,
                                        shouldIngestLibrary: false)
        let orchestrator = AgentOrchestrator(dataAgent: dataAgent,
                                             sentimentAgent: SentimentAgentStub(),
                                             coachAgent: coachAgent,
                                             safetyAgent: SafetyAgent(),
                                             cheerAgent: CheerAgent(),
                                             topicGate: TopicGateStub(),
                                             afmAvailable: false,
                                             recommendationsTimeoutSeconds: 0.05)

        let response = try await orchestrator.recommendations(consentGranted: false)

        XCTAssertTrue(response.cards.isEmpty)
        XCTAssertEqual(response.notice,
                       "Recommendations are taking longer than expected. Try refreshing again soon.")
        XCTAssertEqual(response.wellbeingScore, snapshot.wellbeingScore, accuracy: 0.0001)
        if case .ready = response.wellbeingState {
        } else {
            XCTFail("Expected wellbeing state to remain ready on timeout.")
        }
    }

    private func makeSnapshot(container: ModelContainer) throws -> AgentSnapshot {
        let context = ModelContext(container)
        let feature = FeatureVector(date: Date(), zSteps: 0.1)
        context.insert(feature)
        try context.save()

        return AgentSnapshot(date: feature.date,
                                                   wellbeingScore: 0.55,
                                                   contributions: ["z_steps": 0.1],
                                                   imputedFlags: [:],
                                                   featureVectorObjectID: feature.persistentModelID,
                                                   features: ["z_steps": 0.1])
    }
}

// MARK: - Test doubles

private actor DataAgentStub: DataAgentProviding {
    private let snapshot: AgentSnapshot?
    private let healthStatus: HealthAccessStatus

    init(snapshot: AgentSnapshot?) {
        self.snapshot = snapshot
        self.healthStatus = HealthAccessStatus(required: [] as [HKSampleType],
                                               granted: [],
                                               denied: [],
                                               notDetermined: [],
                                               availability: .available)
    }

    func start() async throws {}
    func setDiagnosticsTraceId(_ traceId: UUID?) async {}
    func latestFeatureVector() async throws -> AgentSnapshot? { snapshot }
    func recordSubjectiveInputs(date: Date, stress: Double, energy: Double, sleepQuality: Double) async throws {}
    func scoreBreakdown() async throws -> ScoreBreakdown? { nil }
    func reprocessDay(date: Date) async throws {}
    func currentHealthAccessStatus() async -> HealthAccessStatus { healthStatus }
    func requestHealthAccess() async throws -> HealthAccessStatus { healthStatus }
    func restartIngestionAfterPermissionsChange() async throws -> HealthAccessStatus { healthStatus }
    func diagnosticsBackfillCounts() async -> (warmCompleted: Int, fullCompleted: Int) {
        (warmCompleted: 0, fullCompleted: 0)
    }
    func latestSnapshotMetadata() async -> (dayString: String?, score: Double?) {
        (dayString: nil, score: snapshot?.wellbeingScore)
    }
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
    func reprocessPendingJournals(traceId: UUID?) async {}
    func pendingEmbeddingCount() async -> Int { 0 }
}

private struct TopicGateStub: TopicGateProviding {
    func classify(_ text: String) async throws -> GateDecision {
        GateDecision(isOnTopic: true, reason: "stub", confidence: 0.99, topic: nil)
    }
}

private actor SlowVectorIndex: VectorIndexProviding {
    private let delayNanoseconds: UInt64

    init(delayNanoseconds: UInt64) {
        self.delayNanoseconds = delayNanoseconds
    }

    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float] {
        []
    }

    func removeMicroMoment(id: String) async throws {}

    func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch] {
        try await Task.sleep(nanoseconds: delayNanoseconds)
        return []
    }
}
