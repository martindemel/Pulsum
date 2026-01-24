import CoreData
import CryptoKit
import XCTest
@testable import PulsumData
@testable import PulsumML

@MainActor
final class Gate5_LibraryImporterAtomicityTests: XCTestCase {
    private let testConfig = LibraryImporterConfiguration(bundle: .module,
                                                          subdirectory: "PulsumDataTests/Resources")
    private var container: NSPersistentContainer!
    private var storeDirectoryURL: URL?
    private var storeURL: URL?

    override func setUp() async throws {
        try await super.setUp()
        try setUpStore()
        resetStore()
    }

    override func tearDown() async throws {
        try tearDownStore()
        try await super.tearDown()
    }

    func testChecksumNotSavedOnIndexFailure_andRetrySucceeds() async throws {
        let metadata = try sampleMetadata()
        let failingIndex = FlakyIndex(failCount: 3)
        let importerFail = LibraryImporter(configuration: testConfig,
                                           vectorIndex: failingIndex,
                                           persistentContainer: container)

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
                                              persistentContainer: container)
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
                                           persistentContainer: container)
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
                                              persistentContainer: container)
        try await importerSuccess.ingestIfNeeded()

        let (count, uniqueCount) = fetchMicroMomentCounts()
        XCTAssertEqual(count, metadata.microMomentCount)
        XCTAssertEqual(uniqueCount, metadata.microMomentCount)
    }

    func testSkipWhenChecksumMatches_DoesNotTouchIndex() async throws {
        try await LibraryImporter(configuration: testConfig,
                                  vectorIndex: SpyIndex(),
                                  persistentContainer: container).ingestIfNeeded()

        let spy = SpyIndex(throwsOnUpsert: true)
        let importer = LibraryImporter(configuration: testConfig,
                                       vectorIndex: spy,
                                       persistentContainer: container)
        try await importer.ingestIfNeeded()

        let calls = await spy.upsertCallCount()
        XCTAssertEqual(calls, 0, "Checksum short-circuit should avoid index usage")
    }

    func testEmbeddingsUnavailableDefersIndexingGracefully() async throws {
        let metadata = try sampleMetadata()
        let unavailableIndex = UnavailableEmbeddingIndex()
        let importer = LibraryImporter(configuration: testConfig,
                                       vectorIndex: unavailableIndex,
                                       persistentContainer: container)

        try await importer.ingestIfNeeded()

        XCTAssertTrue(importer.lastImportHadDeferredEmbeddings)
        XCTAssertNil(fetchLibraryIngest(source: metadata.filename), "Checksum should not be saved when embeddings are unavailable")
        let (count, uniqueCount) = fetchMicroMomentCounts()
        XCTAssertGreaterThan(count, 0)
        XCTAssertEqual(count, uniqueCount)
    }

    // MARK: - Helpers

    private func setUpStore() throws {
        let fileManager = FileManager.default
        let directoryURL = fileManager.temporaryDirectory
            .appendingPathComponent("PulsumDataTests-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let storeURL = directoryURL.appendingPathComponent("Pulsum.sqlite")
        container = Self.makePersistentContainer(storeURL: storeURL)
        storeDirectoryURL = directoryURL
        self.storeURL = storeURL
    }

    private func tearDownStore() throws {
        guard let container else { return }
        let coordinator = container.persistentStoreCoordinator
        if let storeURL, let store = coordinator.persistentStore(for: storeURL) {
            try coordinator.remove(store)
        }
        if let storeDirectoryURL {
            try FileManager.default.removeItem(at: storeDirectoryURL)
        }
        self.storeURL = nil
        self.storeDirectoryURL = nil
        self.container = nil
    }

    private static func makePersistentContainer(storeURL: URL) -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "Pulsum",
                                              managedObjectModel: PulsumManagedObjectModel.shared)
        let description = NSPersistentStoreDescription(url: storeURL)
        description.type = NSSQLiteStoreType
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Test Core Data store error: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        container.viewContext.transactionAuthor = "Pulsum.Tests"
        return container
    }

    private func resetStore() {
        guard let container else {
            XCTFail("Test store not initialized")
            return
        }
        let viewContext = container.viewContext
        viewContext.performAndWait {
            ["MicroMoment", "LibraryIngest"].forEach { entity in
                let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
                let delete = NSBatchDeleteRequest(fetchRequest: fetch)
                _ = try? viewContext.execute(delete)
            }
            try? viewContext.save()
        }
    }

    private func fetchLibraryIngest(source: String) -> LibraryIngest? {
        guard let container else {
            XCTFail("Test store not initialized")
            return nil
        }
        let viewContext = container.viewContext
        return viewContext.performAndWait {
            let request: NSFetchRequest<LibraryIngest> = LibraryIngest.fetchRequest()
            request.predicate = NSPredicate(format: "source == %@", source)
            request.fetchLimit = 1
            let results = try? viewContext.fetch(request)
            return results?.first
        }
    }

    private func fetchMicroMomentCounts() -> (Int, Int) {
        guard let container else {
            XCTFail("Test store not initialized")
            return (0, 0)
        }
        let viewContext = container.viewContext
        return viewContext.performAndWait {
            let request: NSFetchRequest<MicroMoment> = MicroMoment.fetchRequest()
            guard let moments = try? viewContext.fetch(request) else { return (0, 0) }
            let ids = moments.compactMap { $0.id }
            return (ids.count, Set(ids).count)
        }
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

    func removeMicroMoment(id: String) async throws {}

    func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch] { [] }

    func upsertCallCount() -> Int { calls }
}

private actor UnavailableEmbeddingIndex: VectorIndexProviding {
    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float] {
        throw EmbeddingError.generatorUnavailable
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
