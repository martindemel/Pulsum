import XCTest
@testable import PulsumData

final class LibraryImporterTests: XCTestCase {
    func testIngestCreatesMicroMomentsAndVectorIndex() async throws {
        let config = LibraryImporterConfiguration(bundle: .module,
                                                  subdirectory: "PulsumDataTests/Resources")
        let importer = LibraryImporter(configuration: config)
        try await importer.ingestIfNeeded()

        let viewContext = PulsumData.viewContext
        var fetchedMoments: [MicroMoment] = []
        viewContext.performAndWait {
            do {
                let request = MicroMoment.fetchRequest()
                request.fetchLimit = 5
                fetchedMoments = try viewContext.fetch(request)
            } catch {
                XCTFail("Fetch failed: \(error)")
            }
        }

        guard let moment = fetchedMoments.first else {
            XCTFail("MicroMoment not ingested")
            return
        }

        XCTAssertEqual(moment.title, "Practice diaphragmatic breathing")
        XCTAssertEqual(moment.evidenceBadge, EvidenceBadge.strong.rawValue)

        let matches = try VectorIndexManager.shared.searchMicroMoments(query: "diaphragmatic breathing", topK: 1)
        XCTAssertEqual(matches.first?.id, moment.id)
    }
}
