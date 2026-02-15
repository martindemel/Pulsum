import SwiftData
import XCTest
@testable import PulsumData

final class Gate5_LibraryImporterPerfTests: XCTestCase {
    func testSwiftDataReadCompletesQuicklyDuringImport() async throws {
        let schema = Schema(DataStack.modelTypes)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        let cleanContext = ModelContext(container)
        try cleanContext.delete(model: LibraryIngest.self)
        try cleanContext.save()

        let importer = LibraryImporter(configuration: LibraryImporterConfiguration(bundle: .module,
                                                                                    subdirectory: "PulsumDataTests/Resources"),
                                       vectorIndex: StubVectorIndex(),
                                       modelContainer: container)

        async let ingestTask: Void = importer.ingestIfNeeded()
        let start = Date()
        let readContext = ModelContext(container)
        var descriptor = FetchDescriptor<MicroMoment>()
        descriptor.fetchLimit = 1
        _ = try? readContext.fetch(descriptor)
        let elapsed = Date().timeIntervalSince(start)
        try await ingestTask
        XCTAssertLessThan(elapsed, 1.0, "SwiftData read blocked for \(elapsed) seconds")
    }
}

private actor StubVectorIndex: VectorIndexProviding {
    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float] { [] }
    func removeMicroMoment(id: String) async throws {}
    func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch] { [] }
}
