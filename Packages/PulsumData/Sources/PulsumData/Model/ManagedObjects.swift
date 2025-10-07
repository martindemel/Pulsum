import CoreData

@objc(JournalEntry)
public final class JournalEntry: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var transcript: String
    @NSManaged public var sentiment: NSNumber?
    @NSManaged public var embeddedVectorURL: String?
    @NSManaged public var sensitiveFlags: String?
}

@objc(DailyMetrics)
public final class DailyMetrics: NSManagedObject {
    @NSManaged public var date: Date
    @NSManaged public var hrvMedian: NSNumber?
    @NSManaged public var nocturnalHRPercentile10: NSNumber?
    @NSManaged public var restingHR: NSNumber?
    @NSManaged public var totalSleepTime: NSNumber?
    @NSManaged public var sleepDebt: NSNumber?
    @NSManaged public var respiratoryRate: NSNumber?
    @NSManaged public var steps: NSNumber?
    @NSManaged public var flags: String?
}

@objc(Baseline)
public final class Baseline: NSManagedObject {
    @NSManaged public var metric: String
    @NSManaged public var windowDays: Int16
    @NSManaged public var median: NSNumber?
    @NSManaged public var mad: NSNumber?
    @NSManaged public var ewma: NSNumber?
    @NSManaged public var updatedAt: Date?
}

@objc(FeatureVector)
public final class FeatureVector: NSManagedObject {
    @NSManaged public var date: Date
    @NSManaged public var zHrv: NSNumber?
    @NSManaged public var zNocturnalHR: NSNumber?
    @NSManaged public var zRestingHR: NSNumber?
    @NSManaged public var zSleepDebt: NSNumber?
    @NSManaged public var zRespiratoryRate: NSNumber?
    @NSManaged public var zSteps: NSNumber?
    @NSManaged public var subjectiveStress: NSNumber?
    @NSManaged public var subjectiveEnergy: NSNumber?
    @NSManaged public var subjectiveSleepQuality: NSNumber?
    @NSManaged public var sentiment: NSNumber?
    @NSManaged public var imputedFlags: String?
}

@objc(MicroMoment)
public final class MicroMoment: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var title: String
    @NSManaged public var shortDescription: String
    @NSManaged public var detail: String?
    @NSManaged public var tags: [String]?
    @NSManaged public var estimatedTimeSec: NSNumber?
    @NSManaged public var difficulty: String?
    @NSManaged public var category: String?
    @NSManaged public var sourceURL: String?
    @NSManaged public var evidenceBadge: String?
    @NSManaged public var cooldownSec: NSNumber?
}

// MARK: - Fetch Request Helpers

public extension JournalEntry {
    @nonobjc class func fetchRequest() -> NSFetchRequest<JournalEntry> {
        NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
    }
}

public extension DailyMetrics {
    @nonobjc class func fetchRequest() -> NSFetchRequest<DailyMetrics> {
        NSFetchRequest<DailyMetrics>(entityName: "DailyMetrics")
    }
}

public extension Baseline {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Baseline> {
        NSFetchRequest<Baseline>(entityName: "Baseline")
    }
}

public extension FeatureVector {
    @nonobjc class func fetchRequest() -> NSFetchRequest<FeatureVector> {
        NSFetchRequest<FeatureVector>(entityName: "FeatureVector")
    }
}

public extension MicroMoment {
    @nonobjc class func fetchRequest() -> NSFetchRequest<MicroMoment> {
        NSFetchRequest<MicroMoment>(entityName: "MicroMoment")
    }
}

public extension RecommendationEvent {
    @nonobjc class func fetchRequest() -> NSFetchRequest<RecommendationEvent> {
        NSFetchRequest<RecommendationEvent>(entityName: "RecommendationEvent")
    }
}

public extension LibraryIngest {
    @nonobjc class func fetchRequest() -> NSFetchRequest<LibraryIngest> {
        NSFetchRequest<LibraryIngest>(entityName: "LibraryIngest")
    }
}

public extension UserPrefs {
    @nonobjc class func fetchRequest() -> NSFetchRequest<UserPrefs> {
        NSFetchRequest<UserPrefs>(entityName: "UserPrefs")
    }
}

public extension ConsentState {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ConsentState> {
        NSFetchRequest<ConsentState>(entityName: "ConsentState")
    }
}

@objc(RecommendationEvent)
public final class RecommendationEvent: NSManagedObject {
    @NSManaged public var momentId: String
    @NSManaged public var date: Date
    @NSManaged public var accepted: Bool
    @NSManaged public var completedAt: Date?
}

@objc(LibraryIngest)
public final class LibraryIngest: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var source: String
    @NSManaged public var checksum: String?
    @NSManaged public var ingestedAt: Date
    @NSManaged public var version: String?
}

@objc(UserPrefs)
public final class UserPrefs: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var consentCloud: Bool
    @NSManaged public var updatedAt: Date
}

@objc(ConsentState)
public final class ConsentState: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var version: String
    @NSManaged public var grantedAt: Date?
    @NSManaged public var revokedAt: Date?
}
