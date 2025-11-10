import XCTest
@testable import PulsumData

final class DataStackSecurityTests: XCTestCase {
    func testDebugApplyBackupExclusionMarksDirectories() throws {
        let temporaryRoot = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
        let directories = ["AppSupport", "VectorIndex", "Anchors"].map { temporaryRoot.appendingPathComponent($0, isDirectory: true) }
        for directory in directories {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        let issue = DataStack.debugApplyBackupExclusion(to: directories)
        XCTAssertNil(issue)

        for directory in directories {
            let values = try directory.resourceValues(forKeys: [.isExcludedFromBackupKey])
            XCTAssertEqual(values.isExcludedFromBackup, true, "Directory \(directory.path) should be excluded from backup")
        }

        try FileManager.default.removeItem(at: temporaryRoot)
    }
}
