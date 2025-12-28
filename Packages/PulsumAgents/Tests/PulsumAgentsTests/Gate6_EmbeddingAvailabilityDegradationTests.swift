// swiftlint:disable type_name
@testable import PulsumAgents
@testable import PulsumData
@testable import PulsumML
import XCTest

@MainActor
final class Gate6_EmbeddingAvailabilityDegradationTests: XCTestCase {
    func testRecommendationsFallbackWhenEmbeddingsUnavailable() async throws {
        let container = TestCoreDataStack.makeContainer()

        // Seed one MicroMoment so keyword fallback has content.
        let viewContext = container.viewContext
        viewContext.performAndWait {
            let moment = MicroMoment(context: viewContext)
            moment.id = "fallback-1"
            moment.title = "Wellbeing reset walk"
            moment.shortDescription = "Take a gentle 10-minute walk to reset."
            moment.detail = "A simple outdoor walk to refresh energy."
            moment.tags = ["wellbeing", "movement"]
            moment.evidenceBadge = "Medium"
            try? viewContext.save()
        }

        let vector = FeatureVector(context: viewContext)
        vector.date = Date()
        try viewContext.save()

        let snapshot = FeatureVectorSnapshot(date: Date(),
                                             wellbeingScore: 0.2,
                                             contributions: ["z_hrv": 0.5],
                                             imputedFlags: [:],
                                             featureVectorObjectID: vector.objectID,
                                             features: ["z_hrv": 0.5])

        let index = UnavailableIndexStub()
        let importer = LibraryImporter(configuration: LibraryImporterConfiguration(bundle: Bundle.pulsumDataResources,
                                                                                  subdirectory: "PulsumDataTests/Resources"),
                                       vectorIndex: index)
        let coach = try CoachAgent(container: container,
                                   vectorIndex: index,
                                   libraryImporter: importer,
                                   shouldIngestLibrary: false)

        let cards = try await coach.recommendationCards(for: snapshot, consentGranted: false)
        XCTAssertFalse(cards.isEmpty, "Fallback recommendations should be returned when embeddings are unavailable.")
        XCTAssertNotNil(coach.recommendationNotice, "A notice should be surfaced when embeddings are unavailable.")
    }
}

private actor UnavailableIndexStub: VectorIndexProviding {
    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float] {
        throw EmbeddingError.generatorUnavailable
    }

    func removeMicroMoment(id: String) async throws {}

    func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch] {
        throw EmbeddingError.generatorUnavailable
    }
}
