import Foundation
import Testing
import SwiftData
@testable import PulsumAgents
@testable import PulsumServices
@testable import PulsumData
@testable import PulsumML

#if DEBUG
@MainActor
struct ChatGuardrailAcceptanceTests {

    @Test("Greeting routes on-device when consent is OFF")
    func greetingRoutesOnDevice() async throws {
        let harness = try await ChatHarness()
        harness.reset()
        let reply = await harness.chat("Hello", consentGranted: false)
        #expect(!reply.isEmpty)
        #expect(harness.cloudClient.callCount == 0)
        #expect(harness.localGenerator.callCount == 1)
    }

    @Test("Sleep question with consent ON goes to cloud")
    func sleepQuestionRoutesToCloud() async throws {
        let harness = try await ChatHarness()
        harness.reset()
        let reply = await harness.chat("How is my sleep?", consentGranted: true)
        #expect(reply.contains("Cloud response"))
        #expect(harness.cloudClient.callCount == 1)
        #expect(harness.localGenerator.callCount == 0)
    }

    @Test("Sleep question with consent OFF uses on-device AFM")
    func sleepQuestionRoutesOnDeviceWhenConsentOff() async throws {
        let harness = try await ChatHarness()
        harness.reset()
        let reply = await harness.chat("How to improve sleep", consentGranted: false)
        #expect(reply.contains("Local response"))
        #expect(harness.cloudClient.callCount == 0)
        #expect(harness.localGenerator.callCount == 1)
    }

    @Test("Motivation prompt remains on-topic")
    func motivationPromptOnTopic() async throws {
        let harness = try await ChatHarness()
        harness.reset()
        let reply = await harness.chat("How to keep motivated", consentGranted: true)
        #expect(!reply.isEmpty)
        #expect(harness.cloudClient.callCount == 1)
    }

    @Test("Out-of-domain prompt redirects safely")
    func primeFactorsRedirects() async throws {
        let harness = try await ChatHarness()
        harness.reset()
        let reply = await harness.chat("Calculate the prime factors of 512", consentGranted: true)
        #expect(reply == "Let's keep Pulsum focused on your wellbeing data. Ask me about stress, sleep, energy, or today's recommendations.")
        #expect(harness.cloudClient.callCount == 0)
        #expect(harness.localGenerator.callCount == 0)
    }
}

// MARK: - Harness

@MainActor
final class ChatHarness {
    let orchestrator: AgentOrchestrator
    let snapshot: FeatureVectorSnapshot
    let cloudClient: AcceptanceCloudClient
    let localGenerator: AcceptanceLocalGenerator
    let embeddingService: EmbeddingService
    private let dataAgent: StubDataAgent

    init() async throws {
        let container = try TestCoreDataStack.makeContainer()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()
        snapshot = ChatHarness.makeSnapshot(container: container)
        dataAgent = StubDataAgent(snapshot: snapshot)
        embeddingService = EmbeddingService.debugInstance(primary: DeterministicEmbeddingProvider(),
                                                          fallback: nil,
                                                          dimension: 16,
                                                          reprobeInterval: 0,
                                                          dateProvider: Date.init)

        cloudClient = AcceptanceCloudClient()
        localGenerator = AcceptanceLocalGenerator()
        let gateway = LLMGateway(cloudClient: cloudClient,
                                 localGenerator: localGenerator)
        try? gateway.setAPIKey("stub-acceptance-key")
        let coachAgent: CoachAgent = try CoachAgent(
            container: container,
            storagePaths: storagePaths,
            vectorIndex: StubVectorIndex(),
            libraryImporter: LibraryImporter(vectorIndex: VectorIndexManager(directory: storagePaths.vectorIndexDirectory),
                                             modelContainer: container),
            llmGateway: gateway,
            shouldIngestLibrary: false)

        let sentimentAgent = SentimentAgent(container: container,
                                            vectorIndexDirectory: storagePaths.vectorIndexDirectory)
        let safetyAgent = SafetyAgent()
        let cheerAgent = CheerAgent()
        let topicGate = AcceptanceTopicGate()

        self.orchestrator = AgentOrchestrator(dataAgent: dataAgent,
                                              sentimentAgent: sentimentAgent,
                                              coachAgent: coachAgent,
                                              safetyAgent: safetyAgent,
                                              cheerAgent: cheerAgent,
                                              topicGate: topicGate,
                                              embeddingService: embeddingService,
                                              afmAvailable: false)
    }

    func reset() {
        cloudClient.reset()
        localGenerator.reset()
    }

    func chat(_ text: String, consentGranted: Bool) async -> String {
        await orchestrator.chat(userInput: text, consentGranted: consentGranted, snapshotOverride: snapshot)
    }

    nonisolated private static func makeSnapshot(container: ModelContainer) -> FeatureVectorSnapshot {
        let context = ModelContext(container)
        let feature = FeatureVector(date: Date())
        context.insert(feature)
        try? context.save()
        return FeatureVectorSnapshot(date: Date(),
                                                   wellbeingScore: 0.6,
                                                   contributions: ["z_sleepDebt": -0.4, "z_hrv": 0.3, "subj_energy": 0.2],
                                                   imputedFlags: ["hrv": false, "restingHR": false, "steps_missing": false],
                                                   featureVectorObjectID: feature.persistentModelID,
                                                   features: ["z_sleepDebt": -0.4, "z_hrv": 0.3, "subj_energy": 0.2])
    }
}

private actor StubDataAgent: DataAgentProviding {
    private let snapshot: FeatureVectorSnapshot?

    init(snapshot: FeatureVectorSnapshot) {
        self.snapshot = snapshot
    }

    func setDiagnosticsTraceId(_ traceId: UUID?) async {}

    func start() async throws {}

    func latestFeatureVector() async throws -> FeatureVectorSnapshot? {
        snapshot
    }

    func recordSubjectiveInputs(date: Date, stress: Double, energy: Double, sleepQuality: Double) async throws {}

    func scoreBreakdown() async throws -> ScoreBreakdown? { nil }

    func reprocessDay(date: Date) async throws {}

    func currentHealthAccessStatus() async -> HealthAccessStatus {
        HealthAccessStatus(required: [],
                           granted: [],
                           denied: [],
                           notDetermined: [],
                           availability: .available)
    }

    func requestHealthAccess() async throws -> HealthAccessStatus {
        await currentHealthAccessStatus()
    }

    func restartIngestionAfterPermissionsChange() async throws -> HealthAccessStatus {
        await currentHealthAccessStatus()
    }

    func diagnosticsBackfillCounts() async -> (warmCompleted: Int, fullCompleted: Int) {
        (warmCompleted: 0, fullCompleted: 0)
    }

    func latestSnapshotMetadata() async -> (dayString: String?, score: Double?) {
        (dayString: nil, score: snapshot?.wellbeingScore)
    }

    func reset() {}
}

actor StubVectorIndex: VectorIndexProviding {
    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float] { [] }
    func removeMicroMoment(id: String) async throws {}

    func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch] {
        switch query.lowercased() {
        case let text where text.contains("sleep"):
            return Self.matches(similarities: [0.75, 0.68, 0.61])
        case let text where text.contains("motivated"):
            return Self.matches(similarities: [0.74, 0.66, 0.60])
        case let text where text.contains("stress"):
            return Self.matches(similarities: [0.72, 0.65, 0.58])
        default:
            return []
        }
    }

    private static func matches(similarities: [Double]) -> [VectorMatch] {
        similarities.enumerated().map { index, similarity in
            let distance = max((1.0 / similarity) - 1.0, 0.0)
            return VectorMatch(id: "stub-\(index)", score: Float(distance))
        }
    }
}

final class AcceptanceCloudClient: CloudLLMClient {
    private(set) var callCount = 0
    var cannedReply: String = "Cloud response"

    func generateResponse(context: CoachLLMContext,
                          intentTopic: String?,
                          candidateMoments: [CandidateMoment],
                          apiKey: String,
                          keySource: String) async throws -> CoachPhrasing {
        callCount += 1
        return CoachPhrasing(coachReply: cannedReply,
                             isOnTopic: true,
                             groundingScore: 0.78,
                             intentTopic: intentTopic ?? "none",
                             nextAction: "3-minute box breathing")
    }

    func reset() {
        callCount = 0
    }
}

final class AcceptanceLocalGenerator: OnDeviceCoachGenerator {
    private(set) var callCount = 0

    func generate(context: CoachLLMContext) async -> CoachReplyPayload {
        callCount += 1
        return CoachReplyPayload(coachReply: "Local response for \(context.topSignal)")
    }

    func reset() {
        callCount = 0
    }
}
#endif
final class AcceptanceTopicGate: TopicGateProviding {
    func classify(_ text: String) async throws -> GateDecision {
        let lower = text.lowercased()
        let topic: String?
        if lower.contains("sleep") {
            topic = "sleep"
        } else if lower.contains("stress") {
            topic = "stress"
        } else if lower.contains("energy") || lower.contains("motivation") || lower.contains("motivat") {
            topic = "energy"
        } else if lower.contains("walk") || lower.contains("steps") {
            topic = "movement"
        } else if lower.contains("hrv") {
            topic = "hrv"
        } else {
            topic = nil
        }
        return GateDecision(isOnTopic: topic != nil,
                            reason: "stub",
                            confidence: 0.95,
                            topic: topic)
    }
}

private struct DeterministicEmbeddingProvider: TextEmbeddingProviding {
    func embedding(for text: String) throws -> [Float] {
        // Small deterministic vector with non-zero values to satisfy availability checks.
        Array(repeating: Float((text.count % 5) + 1) * 0.01, count: 16)
    }
}
