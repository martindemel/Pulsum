import SwiftData
import XCTest
@testable import PulsumData

final actor HappyPathIndexStub: VectorIndexProviding {
    private(set) var upsertedIds: [String] = []

    @discardableResult
    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float] {
        upsertedIds.append(id)
        return Array(repeating: 0.1, count: 384)
    }

    func removeMicroMoment(id: String) async throws {
        // no-op
    }

    func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch] {
        []
    }
}

final class LibraryImporterTests: XCTestCase {
    func testIngestCreatesMicroMomentsAndVectorIndex() async throws {
        let schema = Schema(DataStack.modelTypes)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        let testConfig = LibraryImporterConfiguration(bundle: .module,
                                                       subdirectory: "PulsumDataTests/Resources")
        let indexStub = HappyPathIndexStub()
        let importer = LibraryImporter(configuration: testConfig,
                                       vectorIndex: indexStub,
                                       modelContainer: container)
        try await importer.ingestIfNeeded()

        let context = ModelContext(container)
        var descriptor = FetchDescriptor<MicroMoment>()
        descriptor.fetchLimit = 1
        let first = try context.fetch(descriptor).first

        guard let moment = first else {
            XCTFail("MicroMoment not ingested")
            return
        }

        XCTAssertEqual(moment.title, "Practice diaphragmatic breathing")
        XCTAssertEqual(moment.evidenceBadge, EvidenceBadge.strong.rawValue)

        let allDescriptor = FetchDescriptor<MicroMoment>()
        let all = try context.fetch(allDescriptor)
        let uniqueIds = Set(all.map(\.id))
        XCTAssertGreaterThan(all.count, 0)
        XCTAssertEqual(all.count, uniqueIds.count)

        let upserts = await indexStub.upsertedIds.count
        XCTAssertGreaterThan(upserts, 0, "Happy-path importer should upsert at least one micro-moment into the index.")
    }
}
