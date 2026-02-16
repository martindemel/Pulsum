@testable import PulsumAgents
@testable import PulsumData
@testable import PulsumML
import SwiftData
import XCTest

@MainActor
// swiftlint:disable:next type_name
final class Gate6_EmbeddingAvailabilityDegradationTests: XCTestCase {
    func testRecommendationsFallbackWhenEmbeddingsUnavailable() async throws {
        let container = try TestCoreDataStack.makeContainer()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()

        // Seed one MicroMoment so keyword fallback has content.
        let context = ModelContext(container)

        let moment = MicroMoment(id: "fallback-1",
                                 title: "Wellbeing reset walk",
                                 shortDescription: "Take a gentle 10-minute walk to reset.",
                                 detail: "A simple outdoor walk to refresh energy.",
                                 tags: "[\"wellbeing\", \"movement\"]",
                                 evidenceBadge: "Medium")
        context.insert(moment)

        let vector = FeatureVector(date: Date())
        context.insert(vector)
        try context.save()

        let snapshot = FeatureVectorSnapshot(date: Date(),
                                             wellbeingScore: 0.2,
                                             contributions: ["z_hrv": 0.5],
                                             imputedFlags: [:],
                                             featureVectorObjectID: vector.persistentModelID,
                                             features: ["z_hrv": 0.5])

        let index = UnavailableIndexStub()
        let importer = LibraryImporter(configuration: LibraryImporterConfiguration(bundle: .module,
                                                                                  subdirectory: "PulsumDataTests/Resources"),
                                       vectorIndex: index,
                                       modelContainer: container)
        let coach = try CoachAgent(container: container,
                                   storagePaths: storagePaths,
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
