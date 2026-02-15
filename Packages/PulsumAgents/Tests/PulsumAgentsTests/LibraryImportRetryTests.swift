import SwiftData
import XCTest
import PulsumData
import PulsumML
@testable import PulsumAgents

@MainActor
final class LibraryImportRetryTests: XCTestCase {
    func testRetryDeferredLibraryImportSkipsWhenNotDeferred() async throws {
        let sourceName = "library_retry_test.json"
        try purgeLibraryIngestRecords(source: sourceName)

        let vectorIndex = CountingVectorIndex()
        let container = try TestCoreDataStack.makeContainer()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()
        let config = LibraryImporterConfiguration(bundle: Bundle.module,
                                                  subdirectory: nil,
                                                  fileExtension: "json")
        let importer = LibraryImporter(configuration: config,
                                       vectorIndex: vectorIndex,
                                       modelContainer: container)
        let coachAgent = try CoachAgent(container: container,
                                        storagePaths: storagePaths,
                                        vectorIndex: vectorIndex,
                                        libraryImporter: importer,
                                        shouldIngestLibrary: true)

        await coachAgent.retryDeferredLibraryImport()

        let count = await vectorIndex.upsertCount
        XCTAssertEqual(count, 0)
    }

    private func purgeLibraryIngestRecords(source: String) throws {
        let container = try TestCoreDataStack.makeContainer()
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<LibraryIngest>(predicate: #Predicate { $0.source == source })
        let results = try context.fetch(descriptor)
        for ingest in results {
            context.delete(ingest)
        }
        if context.hasChanges {
            try context.save()
        }
    }
}

private actor CountingVectorIndex: VectorIndexProviding {
    private(set) var upsertCount = 0

    @discardableResult
    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float] {
        upsertCount += 1
        return []
    }

    func removeMicroMoment(id: String) async throws {}

    func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch] {
        []
    }
}
