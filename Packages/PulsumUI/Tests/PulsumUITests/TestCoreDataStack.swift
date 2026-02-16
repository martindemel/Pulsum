import Foundation
import SwiftData
import PulsumData

final class TestCoreDataStack {
    static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema = Schema(DataStack.modelTypes)
        return try ModelContainer(
            for: schema,
            configurations: [config]
        )
    }

    static func makeTestStoragePaths() -> StoragePaths {
        let tempBase = FileManager.default.temporaryDirectory
            .appendingPathComponent("PulsumTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempBase, withIntermediateDirectories: true)
        return StoragePaths(
            applicationSupport: tempBase,
            sqliteStoreURL: tempBase.appendingPathComponent("test.sqlite"),
            vectorIndexDirectory: tempBase.appendingPathComponent("VectorIndex", isDirectory: true),
            healthAnchorsDirectory: tempBase.appendingPathComponent("Anchors", isDirectory: true)
        )
    }
}
