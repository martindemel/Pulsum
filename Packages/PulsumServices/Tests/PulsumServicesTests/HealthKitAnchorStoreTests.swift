import XCTest
import HealthKit
@testable import PulsumServices

final class HealthKitAnchorStoreTests: XCTestCase {
    func testPersistAndLoadAnchor() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)

        let store = HealthKitAnchorStore(directory: tempURL)
        let anchor = HKQueryAnchor(fromValue: Int(Date().timeIntervalSince1970))
        let identifier = "com.apple.healthkit.heartRate"

        store.store(anchor: anchor, for: identifier)

        let expectation = XCTestExpectation(description: "Anchor persisted")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            let retrieved = store.anchor(for: identifier)
            XCTAssertNotNil(retrieved)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testRemoveAnchorDeletesFile() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)

        let store = HealthKitAnchorStore(directory: tempURL)
        let anchor = HKQueryAnchor(fromValue: 1)
        let identifier = "com.apple.healthkit.sleepAnalysis"
        store.store(anchor: anchor, for: identifier)

        let expectation = XCTestExpectation(description: "Anchor removed")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            store.removeAnchor(for: identifier)
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                let retrieved = store.anchor(for: identifier)
                XCTAssertNil(retrieved)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.5)
    }
}
