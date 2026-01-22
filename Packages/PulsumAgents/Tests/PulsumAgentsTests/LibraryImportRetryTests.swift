import CoreData
import XCTest
import PulsumData
import PulsumML
@testable import PulsumAgents

@MainActor
final class LibraryImportRetryTests: XCTestCase {
    func testRetryDeferredLibraryImportSkipsWhenNotDeferred() async throws {
        let sourceName = "library_retry_test.json"
        try await purgeLibraryIngestRecords(source: sourceName)

        let vectorIndex = CountingVectorIndex()
        let config = LibraryImporterConfiguration(bundle: Bundle.module,
                                                  subdirectory: nil,
                                                  fileExtension: "json")
        let importer = LibraryImporter(configuration: config,
                                       vectorIndex: vectorIndex)
        let container = TestCoreDataStack.makeContainer()
        let coachAgent = try CoachAgent(container: container,
                                        vectorIndex: vectorIndex,
                                        libraryImporter: importer,
                                        shouldIngestLibrary: true)

        await coachAgent.retryDeferredLibraryImport()

        let count = await vectorIndex.upsertCount
        XCTAssertEqual(count, 0)
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

private func purgeLibraryIngestRecords(source: String) async throws {
    let context = PulsumData.newBackgroundContext(name: "Pulsum.Tests.LibraryImportRetry")
    try await context.perform {
        let request: NSFetchRequest<LibraryIngest> = LibraryIngest.fetchRequest()
        request.predicate = NSPredicate(format: "source == %@", source)
        let results = try context.fetch(request)
        for ingest in results {
            context.delete(ingest)
        }
        if context.hasChanges {
            try context.save()
        }
    }
}
