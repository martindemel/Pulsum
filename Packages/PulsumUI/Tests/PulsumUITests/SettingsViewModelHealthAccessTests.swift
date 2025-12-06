@testable import PulsumAgents
@testable import PulsumServices
@testable import PulsumUI
import PulsumData
import PulsumML
import PulsumTypes
import XCTest

@MainActor
final class SettingsViewModelHealthAccessTests: XCTestCase {
    func testRequestHealthKitAuthorizationRefreshesStatus() async throws {
        let requiredTypes = HealthKitService.orderedReadSampleTypes
        if requiredTypes.isEmpty {
            throw XCTSkip("HealthKit sample types unavailable on this platform")
        }
        let pending = HealthAccessStatus(required: requiredTypes,
                                         granted: [],
                                         denied: [],
                                         notDetermined: Set(requiredTypes),
                                         availability: .available)
        let granted = HealthAccessStatus(required: requiredTypes,
                                         granted: Set(requiredTypes),
                                         denied: [],
                                         notDetermined: [],
                                         availability: .available)

        let dataAgent = HealthStatusDataAgentStub(statuses: [pending, granted])
        let orchestrator = try makeOrchestrator(dataAgent: dataAgent)
        let viewModel = SettingsViewModel(initialConsent: false)

        viewModel.bind(orchestrator: orchestrator)
        viewModel.refreshHealthAccessStatus()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.healthKitSummary, "0/\(requiredTypes.count) granted")

        await viewModel.requestHealthKitAuthorization()

        XCTAssertEqual(viewModel.healthKitSummary, "\(requiredTypes.count)/\(requiredTypes.count) granted")
        XCTAssertFalse(viewModel.showHealthKitUnavailableBanner)
    }

    private func makeOrchestrator(dataAgent: any DataAgentProviding) throws -> AgentOrchestrator {
        let coachAgent = try CoachAgent(container: TestCoreDataStack.makeContainer(),
                                        vectorIndex: VectorIndexStub(),
                                        libraryImporter: LibraryImporter(),
                                        llmGateway: LLMGateway(),
                                        shouldIngestLibrary: false)
        return AgentOrchestrator(
            dataAgent: dataAgent,
            sentimentAgent: SentimentAgentStub(),
            coachAgent: coachAgent,
            safetyAgent: SafetyAgent(),
            cheerAgent: CheerAgent(),
            topicGate: TopicGateStub(),
            afmAvailable: false
        )
    }
}

private actor HealthStatusDataAgentStub: DataAgentProviding {
    private var statuses: [HealthAccessStatus]

    init(statuses: [HealthAccessStatus]) {
        self.statuses = statuses
    }

    func start() async throws {}
    func latestFeatureVector() async throws -> FeatureVectorSnapshot? { nil }
    func recordSubjectiveInputs(date: Date, stress: Double, energy: Double, sleepQuality: Double) async throws {}
    func scoreBreakdown() async throws -> ScoreBreakdown? { nil }
    func reprocessDay(date: Date) async throws {}

    func currentHealthAccessStatus() async -> HealthAccessStatus {
        statuses.first ?? HealthAccessStatus(required: [],
                                             granted: [],
                                             denied: [],
                                             notDetermined: [],
                                             availability: .available)
    }

    func requestHealthAccess() async throws -> HealthAccessStatus {
        if statuses.count > 1 {
            statuses = Array(statuses.dropFirst())
        }
        return await currentHealthAccessStatus()
    }

    func restartIngestionAfterPermissionsChange() async throws -> HealthAccessStatus {
        return await currentHealthAccessStatus()
    }
}

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

private final class VectorIndexStub: VectorIndexProviding, @unchecked Sendable {
    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float] { [] }
    func removeMicroMoment(id: String) async throws {}
    func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch] { [] }
}
