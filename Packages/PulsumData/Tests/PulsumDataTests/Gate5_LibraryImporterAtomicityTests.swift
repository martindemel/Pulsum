import CryptoKit
import SwiftData
import XCTest
@testable import PulsumData
@testable import PulsumML

@MainActor
final class Gate5_LibraryImporterAtomicityTests: XCTestCase {
    private let testConfig = LibraryImporterConfiguration(bundle: .module,
                                                          subdirectory: "PulsumDataTests/Resources")
    private var container: ModelContainer!

    override func setUp() async throws {
        let schema = Schema(DataStack.modelTypes)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        resetStore()
    }

    override func tearDown() async throws {
        container = nil
    }

    func testChecksumNotSavedOnIndexFailure_andRetrySucceeds() async throws {
        let metadata = try sampleMetadata()
        let failingIndex = FlakyIndex(failCount: 3)
        let importerFail = LibraryImporter(configuration: testConfig,
                                           vectorIndex: failingIndex,
                                           modelContainer: container)

        do {
            try await importerFail.ingestIfNeeded()
            XCTFail("Expected indexing failure")
        } catch LibraryImporterError.indexingFailed {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertNil(fetchLibraryIngest(source: metadata.filename), "Checksum should not persist on indexing failure")

        let succeedingIndex = FlakyIndex(failCount: 0)
        let importerSuccess = LibraryImporter(configuration: testConfig,
                                              vectorIndex: succeedingIndex,
                                              modelContainer: container)
        try await importerSuccess.ingestIfNeeded()

        let ingest = fetchLibraryIngest(source: metadata.filename)
        XCTAssertEqual(ingest?.checksum, metadata.checksum)

        let failingCount = await failingIndex.callCount()
        let successCount = await succeedingIndex.callCount()
        let totalUpserts = failingCount + successCount
        XCTAssertGreaterThanOrEqual(totalUpserts, metadata.microMomentCount)
    }

    func testImporterIsIdempotent_NoDuplicateEpisodesAfterRetry() async throws {
        let metadata = try sampleMetadata()
        let failingIndex = FlakyIndex(failCount: 2)
        let importerFail = LibraryImporter(configuration: testConfig,
                                           vectorIndex: failingIndex,
                                           modelContainer: container)
        do {
            try await importerFail.ingestIfNeeded()
            XCTFail("Expected indexing failure")
        } catch LibraryImporterError.indexingFailed {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        let succeedingIndex = FlakyIndex(failCount: 0)
        let importerSuccess = LibraryImporter(configuration: testConfig,
                                              vectorIndex: succeedingIndex,
                                              modelContainer: container)
        try await importerSuccess.ingestIfNeeded()

        let (count, uniqueCount) = fetchMicroMomentCounts()
        XCTAssertEqual(count, metadata.microMomentCount)
        XCTAssertEqual(uniqueCount, metadata.microMomentCount)
    }

    func testSkipWhenChecksumMatches_DoesNotTouchIndex() async throws {
        try await LibraryImporter(configuration: testConfig,
                                  vectorIndex: SpyIndex(),
                                  modelContainer: container).ingestIfNeeded()

        let spy = SpyIndex(throwsOnUpsert: true)
        let importer = LibraryImporter(configuration: testConfig,
                                       vectorIndex: spy,
                                       modelContainer: container)
        try await importer.ingestIfNeeded()

        let calls = await spy.upsertCallCount()
        XCTAssertEqual(calls, 0, "Checksum short-circuit should avoid index usage")
    }

    func testEmbeddingsUnavailableDefersIndexingGracefully() async throws {
        let metadata = try sampleMetadata()
        let unavailableIndex = UnavailableEmbeddingIndex()
        let importer = LibraryImporter(configuration: testConfig,
                                       vectorIndex: unavailableIndex,
                                       modelContainer: container)

        try await importer.ingestIfNeeded()

        XCTAssertTrue(importer.lastImportHadDeferredEmbeddings)
        XCTAssertNil(fetchLibraryIngest(source: metadata.filename), "Checksum should not be saved when embeddings are unavailable")
        let (count, uniqueCount) = fetchMicroMomentCounts()
        XCTAssertGreaterThan(count, 0)
        XCTAssertEqual(count, uniqueCount)
    }

    // MARK: - Helpers

    private func resetStore() {
        let context = ModelContext(container)
        try? context.delete(model: MicroMoment.self)
        try? context.delete(model: LibraryIngest.self)
        try? context.save()
    }

    private func fetchLibraryIngest(source: String) -> LibraryIngest? {
        let context = ModelContext(container)
        let targetSource = source
        var descriptor = FetchDescriptor<LibraryIngest>(predicate: #Predicate { $0.source == targetSource })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func fetchMicroMomentCounts() -> (Int, Int) {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<MicroMoment>()
        guard let moments = try? context.fetch(descriptor) else { return (0, 0) }
        let ids = moments.map(\.id)
        return (ids.count, Set(ids).count)
    }

    private func sampleMetadata() throws -> (filename: String, checksum: String, microMomentCount: Int) {
        let url = try fixtureURL()
        let data = try Data(contentsOf: url)
        let checksum = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let episodes = try JSONDecoder().decode([SampleEpisode].self, from: data)
        let count = episodes.reduce(0) { $0 + $1.recommendations.count }
        return (url.lastPathComponent, checksum, count)
    }

    private func fixtureURL() throws -> URL {
        let bundle = Bundle.module
        if let url = bundle.url(forResource: "podcasts_sample",
                                withExtension: "json",
                                subdirectory: testConfig.subdirectory) {
            return url
        }
        if let url = bundle.url(forResource: "podcasts_sample",
                                withExtension: "json") {
            return url
        }
        throw XCTSkip("podcasts_sample.json fixture missing")
    }
}

// MARK: - Test Actors

private actor FlakyIndex: VectorIndexProviding {
    private var remainingFailures: Int
    private var calls = 0

    init(failCount: Int) {
        self.remainingFailures = failCount
    }

    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float] {
        calls += 1
        if remainingFailures > 0 {
            remainingFailures -= 1
            throw TestError.transient
        }
        return []
    }

    func bulkUpsertMicroMoments(_ items: [(id: String, title: String, detail: String?, tags: [String]?)]) async throws {
        for item in items {
            _ = try await upsertMicroMoment(id: item.id, title: item.title, detail: item.detail, tags: item.tags)
        }
    }

    func removeMicroMoment(id: String) async throws {}

    func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch] { [] }

    func callCount() -> Int { calls }
}

private actor SpyIndex: VectorIndexProviding {
    private var calls = 0
    private let throwsOnUpsert: Bool

    init(throwsOnUpsert: Bool = false) {
        self.throwsOnUpsert = throwsOnUpsert
    }

    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float] {
        calls += 1
        if throwsOnUpsert {
            throw TestError.transient
        }
        return []
    }

    func bulkUpsertMicroMoments(_ items: [(id: String, title: String, detail: String?, tags: [String]?)]) async throws {
        for item in items {
            _ = try await upsertMicroMoment(id: item.id, title: item.title, detail: item.detail, tags: item.tags)
        }
    }

    func removeMicroMoment(id: String) async throws {}

    func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch] { [] }

    func upsertCallCount() -> Int { calls }
}

private actor UnavailableEmbeddingIndex: VectorIndexProviding {
    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float] {
        throw EmbeddingError.generatorUnavailable
    }

    func bulkUpsertMicroMoments(_ items: [(id: String, title: String, detail: String?, tags: [String]?)]) async throws {
        for item in items {
            _ = try await upsertMicroMoment(id: item.id, title: item.title, detail: item.detail, tags: item.tags)
        }
    }

    func removeMicroMoment(id: String) async throws {}

    func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch] {
        throw EmbeddingError.generatorUnavailable
    }
}

private enum TestError: Error {
    case transient
}

private struct SampleEpisode: Decodable {
    let recommendations: [SampleRecommendation]
}

private struct SampleRecommendation: Decodable {
    let recommendation: String
}
