@testable import PulsumAgents
@testable import PulsumData
@testable import PulsumML
import XCTest

@MainActor
final class CoachAgentKeywordFallbackTests: XCTestCase {
    func testKeywordFallbackMatchesTitleAndTagsWhenEmbeddingsUnavailable() async throws {
        let container = TestCoreDataStack.makeContainer()
        let viewContext = container.viewContext

        viewContext.performAndWait {
            let titleMatch = MicroMoment(context: viewContext)
            titleMatch.id = "energy-walk"
            titleMatch.title = "Energy Reset Walk"
            titleMatch.shortDescription = "Take a short walk to restore energy."
            titleMatch.detail = "A quick walk outside can raise energy without overexertion."

            let tagMatch = MicroMoment(context: viewContext)
            tagMatch.id = "focus-routine"
            tagMatch.title = "Focus Routine"
            tagMatch.shortDescription = "Tighten focus with a brief cadence."
            tagMatch.detail = "Alternate between short breathing drills and light movement."
            tagMatch.tags = ["ENERGY boost", "focus"]

            let nonMatch = MicroMoment(context: viewContext)
            nonMatch.id = "calm-breath"
            nonMatch.title = "Calm Breathing"
            nonMatch.shortDescription = "Slow breathing to reduce stress."
            nonMatch.detail = "A calming pattern for winding down."
            nonMatch.tags = ["calm"]

            try? viewContext.save()
        }

        let coach = try CoachAgent(container: container,
                                   vectorIndex: UnavailableKeywordIndexStub(),
                                   shouldIngestLibrary: false)

        let moments = await coach.candidateMoments(for: "energy", limit: 3)
        let ids = moments.map(\.id)

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
