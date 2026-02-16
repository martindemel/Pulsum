import Foundation
import SwiftData

@Model
public final class FeatureVector {
    #Index<FeatureVector>([\.date])

    /// Callers must normalize to midnight (start of day) before setting.
    @Attribute(.unique) public var date: Date
    public var zHrv: Double?
    public var zNocturnalHR: Double?
    public var zRestingHR: Double?
    public var zSleepDebt: Double?
    public var zRespiratoryRate: Double?
    public var zSteps: Double?
    public var subjectiveStress: Double?
    public var subjectiveEnergy: Double?
    public var subjectiveSleepQuality: Double?
    public var sentiment: Double?
    public var imputedFlags: String?

    public init(
        date: Date,
        zHrv: Double? = nil,
        zNocturnalHR: Double? = nil,
        zRestingHR: Double? = nil,
        zSleepDebt: Double? = nil,
        zRespiratoryRate: Double? = nil,
        zSteps: Double? = nil,
        subjectiveStress: Double? = nil,
        subjectiveEnergy: Double? = nil,
        subjectiveSleepQuality: Double? = nil,
        sentiment: Double? = nil,
        imputedFlags: String? = nil
    ) {
        self.date = date
        self.zHrv = zHrv
        self.zNocturnalHR = zNocturnalHR
        self.zRestingHR = zRestingHR
        self.zSleepDebt = zSleepDebt
        self.zRespiratoryRate = zRespiratoryRate
        self.zSteps = zSteps
        self.subjectiveStress = subjectiveStress
        self.subjectiveEnergy = subjectiveEnergy
        self.subjectiveSleepQuality = subjectiveSleepQuality
        self.sentiment = sentiment
        self.imputedFlags = imputedFlags
    }
}
