import Testing
import CoreData
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
private final class ChatHarness {
    let orchestrator: AgentOrchestrator
    let snapshot: FeatureVectorSnapshot
    let cloudClient: AcceptanceCloudClient
    let localGenerator: AcceptanceLocalGenerator
    private let dataAgent: StubDataAgent

    init() async throws {
        let container = TestCoreDataStack.makeContainer()
        snapshot = try await ChatHarness.makeSnapshot(in: container)
        dataAgent = StubDataAgent(snapshot: snapshot)

        cloudClient = AcceptanceCloudClient()
        localGenerator = AcceptanceLocalGenerator()
        let gateway = LLMGateway(cloudClient: cloudClient,
                                 localGenerator: localGenerator)
        let coachAgent: CoachAgent = try CoachAgent(container: container,
                                                    vectorIndex: StubVectorIndex(),
                                                    libraryImporter: LibraryImporter(configuration: LibraryImporterConfiguration(),
                                                                                    vectorIndexManager: VectorIndexManager.shared),
                                                    llmGateway: gateway,
                                                    shouldIngestLibrary: false)

        let sentimentAgent = SentimentAgent()
        let safetyAgent = SafetyAgent()
        let cheerAgent = CheerAgent()
        let topicGate = EmbeddingTopicGateProvider()

        self.orchestrator = AgentOrchestrator(dataAgent: dataAgent,
                                              sentimentAgent: sentimentAgent,
                                              coachAgent: coachAgent,
                                              safetyAgent: safetyAgent,
                                              cheerAgent: cheerAgent,
                                              topicGate: topicGate,
                                              afmAvailable: false)
    }

    func reset() {
        cloudClient.reset()
        localGenerator.reset()
    }

    func chat(_ text: String, consentGranted: Bool) async -> String {
        await orchestrator.chat(userInput: text, consentGranted: consentGranted, snapshotOverride: snapshot)
    }

    private static func makeSnapshot(in container: NSPersistentContainer) async throws -> FeatureVectorSnapshot {
        let context = container.newBackgroundContext()
        return try await context.perform { () throws -> FeatureVectorSnapshot in
            let feature = FeatureVector(context: context)
            try context.obtainPermanentIDs(for: [feature])
            return FeatureVectorSnapshot(date: Date(),
                                         wellbeingScore: 0.6,
                                         contributions: ["z_sleepDebt": -0.4, "z_hrv": 0.3, "subj_energy": 0.2],
                                         imputedFlags: ["hrv": false, "restingHR": false, "steps_missing": false],
                                         featureVectorObjectID: feature.objectID,
                                         features: ["z_sleepDebt": -0.4, "z_hrv": 0.3, "subj_energy": 0.2])
        }
    }
}

private actor StubDataAgent: DataAgentProviding {
    private let snapshot: FeatureVectorSnapshot?

    init(snapshot: FeatureVectorSnapshot) {
        self.snapshot = snapshot
    }

    func start() async throws {}

    func latestFeatureVector() async throws -> FeatureVectorSnapshot? {
        snapshot
    }

    func recordSubjectiveInputs(date: Date, stress: Double, energy: Double, sleepQuality: Double) async throws {}

    func scoreBreakdown() async throws -> ScoreBreakdown? { nil }

    func reset() {}
}

private final class StubVectorIndex: VectorIndexProviding {
    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) throws -> [Float] { [] }
    func removeMicroMoment(id: String) throws {}

    func searchMicroMoments(query: String, topK: Int) throws -> [VectorMatch] {
        switch query.lowercased() {
        case let text where text.contains("sleep"):
            return Self.matches(similarities: [0.75, 0.68, 0.61])
        case let text where text.contains("motivated"):
            return Self.matches(similarities: [0.74, 0.66, 0.60])
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

private final class AcceptanceCloudClient: CloudLLMClient {
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

private final class AcceptanceLocalGenerator: OnDeviceCoachGenerator {
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
