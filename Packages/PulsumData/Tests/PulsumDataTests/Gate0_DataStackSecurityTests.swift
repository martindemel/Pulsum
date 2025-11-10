import XCTest
@testable import PulsumData

final class Gate0_DataStackSecurityTests: XCTestCase {
    func testPHIDirectoriesAreExcludedFromBackup() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let directories = ["AppSupport", "VectorIndex", "Anchors"].map { root.appendingPathComponent($0, isDirectory: true) }
        for directory in directories {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        let issue = DataStack.debugApplyBackupExclusion(to: directories)
        XCTAssertNil(issue)

        for directory in directories {
            let values = try directory.resourceValues(forKeys: [.isExcludedFromBackupKey])
            XCTAssertEqual(values.isExcludedFromBackup, true, "Directory \(directory.path) should be excluded from backup")
        }
    }
}
