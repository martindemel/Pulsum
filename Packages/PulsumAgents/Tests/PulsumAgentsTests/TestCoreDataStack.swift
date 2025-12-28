import Foundation
import CoreData
@testable import PulsumData

public final class TestCoreDataStack {
    public static func makeContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "Pulsum", managedObjectModel: PulsumManagedObjectModel.shared)
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Test Core Data store error: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return container
    }
}








