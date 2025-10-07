import XCTest
import CoreData
@testable import PulsumData

final class PulsumDataBootstrapTests: XCTestCase {
    func testPersistentContainerLoadsPulsumModel() {
        let container = PulsumData.container
        XCTAssertEqual(container.name, "Pulsum")
        XCTAssertNotNil(container.managedObjectModel.entitiesByName["JournalEntry"])
    }

    func testBackgroundContextCreation() {
        let context = PulsumData.newBackgroundContext(name: "Pulsum.Test")
        XCTAssertEqual(context.name, "Pulsum.Test")
        XCTAssertEqual(context.persistentStoreCoordinator, PulsumData.container.persistentStoreCoordinator)
    }

    func testVectorIndexDirectoryIsInsideApplicationSupport() {
        let vectorDirectory = PulsumData.vectorIndexDirectory
        XCTAssertTrue(vectorDirectory.path.contains("Pulsum"))
        XCTAssertTrue(vectorDirectory.path.contains("VectorIndex"))
    }

    func testHealthAnchorsDirectoryIsInsideApplicationSupport() {
        let anchorsDirectory = PulsumData.healthAnchorsDirectory
        XCTAssertTrue(anchorsDirectory.path.contains("Pulsum"))
        XCTAssertTrue(anchorsDirectory.path.contains("Anchors"))
    }
}
