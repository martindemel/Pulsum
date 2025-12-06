import XCTest
@testable import PulsumAgents
@testable import PulsumData
@testable import PulsumML
@testable import PulsumServices

@MainActor
final class Gate6_RecRankerLearningTests: XCTestCase {
    func testCoachAgentAppliesFeedbackToRanking() async throws {
        let container = TestCoreDataStack.makeContainer()
        let vectorIndex = Gate6VectorIndexStub(matches: [
            VectorMatch(id: "A", score: 0.1),
            VectorMatch(id: "B", score: 2.0)
        ])

        let agent = try CoachAgent(container: container,
                                   vectorIndex: vectorIndex,
                                   libraryImporter: LibraryImporter(),
                                   llmGateway: LLMGateway(),
                                   shouldIngestLibrary: false)

        let context = container.viewContext
        let momentA = MicroMoment(context: context)
        momentA.id = "A"
        momentA.title = "Stretch and breathe"
        momentA.shortDescription = "Quick stretch with deep breathing."
        let momentB = MicroMoment(context: context)
        momentB.id = "B"
        momentB.title = "Take a brisk walk"
        momentB.shortDescription = "10-minute outdoor walk."
        try context.save()

        let featureVector = FeatureVector(context: context)
        featureVector.date = Date()
        try context.save()

        let snapshot = FeatureVectorSnapshot(date: Date(),
                                             wellbeingScore: 0.1,
                                             contributions: ["z_hrv": 0.2, "z_sleepDebt": 0.1],
                                             imputedFlags: [:],
                                             featureVectorObjectID: featureVector.objectID,
                                             features: ["z_hrv": 0.6, "z_sleepDebt": -0.4, "subj_energy": 6.0])

        _ = try await agent.recommendationCards(for: snapshot, consentGranted: false)

        try await agent.logEvent(momentId: "A", accepted: false)
        try await agent.logEvent(momentId: "B", accepted: true)
        try await agent.logEvent(momentId: "B", accepted: true)

        let reranked = try await agent.recommendationCards(for: snapshot, consentGranted: false)
        XCTAssertEqual(reranked.first?.id, "B")

        let metrics = agent._testRankerMetrics()
        XCTAssertNotEqual(metrics.weights["bias"], 0)
    }
}

private final class Gate6VectorIndexStub: VectorIndexProviding, @unchecked Sendable {
    var matches: [VectorMatch]

    init(matches: [VectorMatch]) {
        self.matches = matches
    }

    @discardableResult
    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float] {
        []
    }

    func removeMicroMoment(id: String) async throws {}

    func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch] {
        matches
    }
}
