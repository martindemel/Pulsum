import XCTest
@testable import PulsumData

final class LibraryImporterTests: XCTestCase {
    func testIngestCreatesMicroMomentsAndVectorIndex() async throws {
        let config = LibraryImporterConfiguration(bundle: .module,
                                                  subdirectory: "PulsumDataTests/Resources")
        let importer = LibraryImporter(configuration: config)
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

        XCTAssertEqual(momentSnapshot.title, "Practice diaphragmatic breathing")
        XCTAssertEqual(momentSnapshot.badge, EvidenceBadge.strong.rawValue)

        let matches = try await VectorIndexManager.shared.searchMicroMoments(query: "diaphragmatic breathing", topK: 1)
        XCTAssertEqual(matches.first?.id, momentSnapshot.id)
    }
}
