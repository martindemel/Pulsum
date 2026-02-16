import XCTest
import SwiftData
@testable import PulsumData

final class PulsumDataBootstrapTests: XCTestCase {
    func testDataStackCreatesModelContainer() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema = Schema(DataStack.modelTypes)
        let container = try ModelContainer(for: schema, configurations: [config])
        XCTAssertNotNil(container)
    }

    func testStoragePathsContainExpectedSubdirectories() throws {
        let paths = try StoragePaths()
        XCTAssertTrue(paths.vectorIndexDirectory.path.contains("VectorIndex"))
        XCTAssertTrue(paths.healthAnchorsDirectory.path.contains("Anchors"))
    }
}
