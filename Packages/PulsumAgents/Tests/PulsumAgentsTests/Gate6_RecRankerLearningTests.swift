import XCTest
import SwiftData
@testable import PulsumAgents
@testable import PulsumData
@testable import PulsumML
@testable import PulsumServices

@MainActor
// swiftlint:disable:next type_name
final class Gate6_RecRankerLearningTests: XCTestCase {
    func testCoachAgentAppliesFeedbackToRanking() async throws {
        let container = try TestCoreDataStack.makeContainer()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()
        let vectorIndex = Gate6VectorIndexStub(matches: [
            VectorMatch(id: "A", score: 0.1),
            VectorMatch(id: "B", score: 2.0)
        ])

        let agent = try CoachAgent(container: container,
                                   storagePaths: storagePaths,
                                   vectorIndex: vectorIndex,
                                   shouldIngestLibrary: false)

        let context = ModelContext(container)
        let momentA = MicroMoment(id: "A",
                                  title: "Stretch and breathe",
                                  shortDescription: "Quick stretch with deep breathing.")
        context.insert(momentA)
        let momentB = MicroMoment(id: "B",
                                  title: "Take a brisk walk",
                                  shortDescription: "10-minute outdoor walk.")
        context.insert(momentB)
        try context.save()

        let featureVector = FeatureVector(date: Date())
        context.insert(featureVector)
        try context.save()

        let snapshot = FeatureVectorSnapshot(date: Date(),
                                             wellbeingScore: 0.1,
                                             contributions: ["z_hrv": 0.2, "z_sleepDebt": 0.1],
                                             imputedFlags: [:],
                                             featureVectorObjectID: featureVector.persistentModelID,
                                             features: ["z_hrv": 0.6, "z_sleepDebt": -0.4, "subj_energy": 6.0])

        _ = try await agent.recommendationCards(for: snapshot, consentGranted: false)

        try await agent.logEvent(momentId: "A", accepted: false)
        try await agent.logEvent(momentId: "B", accepted: true)
        try await agent.logEvent(momentId: "B", accepted: true)

        let reranked = try await agent.recommendationCards(for: snapshot, consentGranted: false)
        XCTAssertEqual(reranked.first?.id, "B")

        let metrics = await agent._testRankerMetrics()
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
