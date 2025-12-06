import CoreData
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
        let config = LibraryImporterConfiguration(bundle: .module,
                                                  subdirectory: "PulsumDataTests/Resources")
        let indexStub = HappyPathIndexStub()
        let importer = LibraryImporter(configuration: config, vectorIndex: indexStub)
        try await importer.ingestIfNeeded()

        let viewContext = PulsumData.viewContext
        let snapshot = await viewContext.perform { () -> (id: String, title: String, badge: String?)? in
            do {
                let request = MicroMoment.fetchRequest()
                request.fetchLimit = 1
                if let moment = try viewContext.fetch(request).first {
                    return (moment.id, moment.title, moment.evidenceBadge)
                }
            } catch {
                XCTFail("Fetch failed: \(error)")
            }
            return nil
        }

        guard let momentSnapshot = snapshot else {
            XCTFail("MicroMoment not ingested")
            return
        }

        let counts = await viewContext.perform { () -> (count: Int, unique: Int) in
            let request: NSFetchRequest<MicroMoment> = MicroMoment.fetchRequest()
            let moments = (try? viewContext.fetch(request)) ?? []
            let unique = Set(moments.map(\.id)).count
            return (moments.count, unique)
        }

        XCTAssertEqual(momentSnapshot.title, "Practice diaphragmatic breathing")
        XCTAssertEqual(momentSnapshot.badge, EvidenceBadge.strong.rawValue)
        XCTAssertGreaterThan(counts.count, 0)
        XCTAssertEqual(counts.count, counts.unique)

        let upserts = await indexStub.upsertedIds.count
        XCTAssertGreaterThan(upserts, 0, "Happy-path importer should upsert at least one micro-moment into the index.")
    }
}
