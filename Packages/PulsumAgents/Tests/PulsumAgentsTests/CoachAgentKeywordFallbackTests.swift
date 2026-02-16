@testable import PulsumAgents
@testable import PulsumData
@testable import PulsumML
import SwiftData
import XCTest

@MainActor
final class CoachAgentKeywordFallbackTests: XCTestCase {
    func testKeywordFallbackMatchesTitleAndTagsWhenEmbeddingsUnavailable() async throws {
        let container = try TestCoreDataStack.makeContainer()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()
        let context = ModelContext(container)

        let titleMatch = MicroMoment(id: "energy-walk",
                                     title: "Energy Reset Walk",
                                     shortDescription: "Take a short walk to restore energy.",
                                     detail: "A quick walk outside can raise energy without overexertion.")
        context.insert(titleMatch)

        let tagMatch = MicroMoment(id: "focus-routine",
                                   title: "Focus Routine",
                                   shortDescription: "Tighten focus with a brief cadence.",
                                   detail: "Alternate between short breathing drills and light movement.",
                                   tags: "[\"ENERGY boost\", \"focus\"]")
        context.insert(tagMatch)

        let nonMatch = MicroMoment(id: "calm-breath",
                                   title: "Calm Breathing",
                                   shortDescription: "Slow breathing to reduce stress.",
                                   detail: "A calming pattern for winding down.",
                                   tags: "[\"calm\"]")
        context.insert(nonMatch)

        try context.save()

        let coach = try CoachAgent(container: container,
                                   storagePaths: storagePaths,
                                   vectorIndex: UnavailableKeywordIndexStub(),
                                   shouldIngestLibrary: false)

        let moments = await coach.candidateMoments(for: "energy", limit: 3)
        let ids = moments.map { $0.id }

        XCTAssertEqual(ids, ["energy-walk", "focus-routine"])
        XCTAssertFalse(ids.contains("calm-breath"), "Non-matching moments should not be returned.")
    }
}

private actor UnavailableKeywordIndexStub: VectorIndexProviding {
    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float] {
        throw EmbeddingError.generatorUnavailable
    }

    func removeMicroMoment(id: String) async throws {}

    func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch] {
        throw EmbeddingError.generatorUnavailable
    }
}
