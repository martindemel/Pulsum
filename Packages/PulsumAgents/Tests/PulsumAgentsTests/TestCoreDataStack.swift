import Foundation
import SwiftData
@testable import PulsumAgents
@testable import PulsumData

/// Typealias to disambiguate from PulsumTypes.FeatureVectorSnapshot.
/// The module-qualified `PulsumAgents.FeatureVectorSnapshot` is shadowed by the `PulsumAgents` enum
/// within the PulsumAgents module, so this typealias provides unambiguous access.
typealias AgentSnapshot = FeatureVectorSnapshot

public final class TestCoreDataStack {
    public static func makeContainer() throws -> ModelContainer {
        let schema = Schema(DataStack.modelTypes)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: schema,
            configurations: [config]
        )
    }

    public static func makeTestStoragePaths() -> StoragePaths {
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
