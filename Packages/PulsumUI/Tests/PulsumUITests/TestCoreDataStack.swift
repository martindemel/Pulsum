import CoreData
import PulsumData

final class TestCoreDataStack {
    static func makeContainer() -> NSPersistentContainer {
        guard let model = PulsumManagedObjectModel.shared else {
            fatalError("Test setup: PulsumManagedObjectModel not found")
        }
        let container = NSPersistentContainer(name: "Pulsum", managedObjectModel: model)
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
