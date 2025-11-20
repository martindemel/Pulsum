import CoreData
import XCTest
@testable import PulsumData

final class Gate5_LibraryImporterPerfTests: XCTestCase {
    func testCoreDataReadCompletesQuicklyDuringImport() async throws {
        let viewContext = PulsumData.viewContext
        viewContext.performAndWait {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LibraryIngest")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            _ = try? viewContext.execute(deleteRequest)
            try? viewContext.save()
        }

        let config = LibraryImporterConfiguration(bundle: .module,
                                                  subdirectory: "PulsumDataTests/Resources")
        let importer = LibraryImporter(configuration: config)

        async let ingestTask: Void = importer.ingestIfNeeded()
        let start = Date()
        viewContext.performAndWait {
            let request = MicroMoment.fetchRequest()
            request.fetchLimit = 1
            _ = try? viewContext.fetch(request)
        }
        let elapsed = Date().timeIntervalSince(start)
        try await ingestTask
        XCTAssertLessThan(elapsed, 0.5, "Core Data read blocked for \(elapsed) seconds")
    }
}
