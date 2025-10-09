import Foundation
import CoreData
@testable import PulsumData

public final class TestCoreDataStack {
    public static func makeContainer() -> NSPersistentContainer {
        let model = makeModel()
        let container = NSPersistentContainer(name: "TestPulsum", managedObjectModel: model)
        
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
        return container
    }
    
    private static func attribute(name: String, 
                                  type: NSAttributeType, 
                                  isOptional: Bool = false,
                                  defaultValue: Any? = nil) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = isOptional
        attribute.defaultValue = defaultValue
        return attribute
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Create all Core Data entities for testing
        let journalEntry = NSEntityDescription()
        journalEntry.name = "JournalEntry"
        journalEntry.managedObjectClassName = NSStringFromClass(JournalEntry.self)
        journalEntry.properties = [
            attribute(name: "id", type: .UUIDAttributeType),
            attribute(name: "date", type: .dateAttributeType),
            attribute(name: "transcript", type: .stringAttributeType),
            attribute(name: "sentiment", type: .doubleAttributeType, isOptional: true),
            attribute(name: "embeddedVectorURL", type: .stringAttributeType, isOptional: true),
            attribute(name: "sensitiveFlags", type: .stringAttributeType, isOptional: true)
        ]

        let dailyMetrics = NSEntityDescription()
        dailyMetrics.name = "DailyMetrics"
        dailyMetrics.managedObjectClassName = NSStringFromClass(DailyMetrics.self)
        dailyMetrics.properties = [
            attribute(name: "date", type: .dateAttributeType),
            attribute(name: "hrvMedian", type: .doubleAttributeType, isOptional: true),
            attribute(name: "nocturnalHRPercentile10", type: .doubleAttributeType, isOptional: true),
            attribute(name: "restingHR", type: .doubleAttributeType, isOptional: true),
            attribute(name: "totalSleepTime", type: .doubleAttributeType, isOptional: true),
            attribute(name: "sleepDebt", type: .doubleAttributeType, isOptional: true),
            attribute(name: "respiratoryRate", type: .doubleAttributeType, isOptional: true),
            attribute(name: "steps", type: .doubleAttributeType, isOptional: true),
            attribute(name: "flags", type: .stringAttributeType, isOptional: true)
        ]

        let featureVector = NSEntityDescription()
        featureVector.name = "FeatureVector"
        featureVector.managedObjectClassName = NSStringFromClass(FeatureVector.self)
        featureVector.properties = [
            attribute(name: "date", type: .dateAttributeType),
            attribute(name: "zHrv", type: .doubleAttributeType, isOptional: true),
            attribute(name: "zNocturnalHR", type: .doubleAttributeType, isOptional: true),
            attribute(name: "zRestingHR", type: .doubleAttributeType, isOptional: true),
            attribute(name: "zSleepDebt", type: .doubleAttributeType, isOptional: true),
            attribute(name: "zRespiratoryRate", type: .doubleAttributeType, isOptional: true),
            attribute(name: "zSteps", type: .doubleAttributeType, isOptional: true),
            attribute(name: "subjectiveStress", type: .doubleAttributeType, isOptional: true),
            attribute(name: "subjectiveEnergy", type: .doubleAttributeType, isOptional: true),
            attribute(name: "subjectiveSleepQuality", type: .doubleAttributeType, isOptional: true),
            attribute(name: "sentiment", type: .doubleAttributeType, isOptional: true),
            attribute(name: "imputedFlags", type: .stringAttributeType, isOptional: true)
        ]

        let microMoment = NSEntityDescription()
        microMoment.name = "MicroMoment"
        microMoment.managedObjectClassName = NSStringFromClass(MicroMoment.self)
        microMoment.properties = [
            attribute(name: "id", type: .stringAttributeType),
            attribute(name: "title", type: .stringAttributeType),
            attribute(name: "shortDescription", type: .stringAttributeType),
            attribute(name: "detail", type: .stringAttributeType, isOptional: true),
            attribute(name: "tags", type: .transformableAttributeType, isOptional: true),
            attribute(name: "estimatedTimeSec", type: .integer32AttributeType, isOptional: true),
            attribute(name: "difficulty", type: .stringAttributeType, isOptional: true),
            attribute(name: "category", type: .stringAttributeType, isOptional: true),
            attribute(name: "sourceURL", type: .stringAttributeType, isOptional: true),
            attribute(name: "evidenceBadge", type: .stringAttributeType, isOptional: true),
            attribute(name: "cooldownSec", type: .integer32AttributeType, isOptional: true)
        ]

        let recommendationEvent = NSEntityDescription()
        recommendationEvent.name = "RecommendationEvent"
        recommendationEvent.managedObjectClassName = NSStringFromClass(RecommendationEvent.self)
        recommendationEvent.properties = [
            attribute(name: "momentId", type: .stringAttributeType),
            attribute(name: "date", type: .dateAttributeType),
            attribute(name: "accepted", type: .booleanAttributeType),
            attribute(name: "completedAt", type: .dateAttributeType, isOptional: true)
        ]

        let baseline = NSEntityDescription()
        baseline.name = "Baseline"
        baseline.managedObjectClassName = NSStringFromClass(Baseline.self)
        baseline.properties = [
            attribute(name: "metric", type: .stringAttributeType),
            attribute(name: "windowDays", type: .integer16AttributeType, defaultValue: 21),
            attribute(name: "median", type: .doubleAttributeType, isOptional: true),
            attribute(name: "mad", type: .doubleAttributeType, isOptional: true),
            attribute(name: "ewma", type: .doubleAttributeType, isOptional: true),
            attribute(name: "updatedAt", type: .dateAttributeType, isOptional: true)
        ]

        let userPrefs = NSEntityDescription()
        userPrefs.name = "UserPrefs"
        userPrefs.managedObjectClassName = NSStringFromClass(UserPrefs.self)
        userPrefs.properties = [
            attribute(name: "id", type: .stringAttributeType),
            attribute(name: "consentCloud", type: .booleanAttributeType, defaultValue: false),
            attribute(name: "updatedAt", type: .dateAttributeType)
        ]

        let consentState = NSEntityDescription()
        consentState.name = "ConsentState"
        consentState.managedObjectClassName = NSStringFromClass(ConsentState.self)
        consentState.properties = [
            attribute(name: "id", type: .UUIDAttributeType),
            attribute(name: "version", type: .stringAttributeType),
            attribute(name: "grantedAt", type: .dateAttributeType, isOptional: true),
            attribute(name: "revokedAt", type: .dateAttributeType, isOptional: true)
        ]

        let libraryIngest = NSEntityDescription()
        libraryIngest.name = "LibraryIngest"
        libraryIngest.managedObjectClassName = NSStringFromClass(LibraryIngest.self)
        libraryIngest.properties = [
            attribute(name: "id", type: .UUIDAttributeType),
            attribute(name: "source", type: .stringAttributeType),
            attribute(name: "checksum", type: .stringAttributeType, isOptional: true),
            attribute(name: "ingestedAt", type: .dateAttributeType),
            attribute(name: "version", type: .stringAttributeType, isOptional: true)
        ]

        model.entities = [journalEntry, dailyMetrics, featureVector, microMoment, recommendationEvent, baseline, userPrefs, consentState, libraryIngest]
        return model
    }
}








