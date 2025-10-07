import XCTest
@testable import PulsumServices

final class PulsumServicesDependencyTests: XCTestCase {
    func testStorageMetadataAndEmbeddingVersion() {
        let metadata = PulsumServices.storageMetadata()
        XCTAssertTrue(metadata.storeURL.lastPathComponent.contains("Pulsum.sqlite"))
        XCTAssertTrue(metadata.anchorsDirectory.lastPathComponent.contains("Anchors"))

        let embeddingVersion = PulsumServices.embeddingVersion()
        XCTAssertFalse(embeddingVersion.isEmpty)
    }
}
