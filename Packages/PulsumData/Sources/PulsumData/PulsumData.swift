import Foundation
import CoreData

/// Facade exposing Pulsum's persistent data infrastructure.
public enum PulsumData {
    /// Shared Core Data stack configured for on-device only storage.
    public static var dataStack: DataStack { DataStack.shared }

    /// Primary persistent container. Use for dependency injection when needed.
    public static var container: NSPersistentContainer { dataStack.container }

    /// Main-thread view context sourced from the container.
    public static var viewContext: NSManagedObjectContext { dataStack.container.viewContext }

    /// Creates a background context with merge policies configured for Pulsum writes.
    @discardableResult
    public static func newBackgroundContext(name: String = "Pulsum.Background") -> NSManagedObjectContext {
        dataStack.newBackgroundContext(name: name)
    }

    /// Performs an asynchronous background task, delegating to the underlying container helper.
    public static func performBackgroundTask(_ block: @Sendable @escaping (NSManagedObjectContext) -> Void) {
        dataStack.performBackgroundTask(block)
    }

    /// Location of the Application Support directory used for Pulsum persistence.
    public static var applicationSupportDirectory: URL { dataStack.storagePaths.applicationSupport }

    /// Location of the SQLite store backing Core Data.
    public static var sqliteStoreURL: URL { dataStack.storagePaths.sqliteStoreURL }

    /// Directory where vector index shards are stored (file protected, excluded from backup).
    public static var vectorIndexDirectory: URL { dataStack.storagePaths.vectorIndexDirectory }

    /// Directory storing persisted HealthKit query anchors.
    public static var healthAnchorsDirectory: URL { dataStack.storagePaths.healthAnchorsDirectory }
}
