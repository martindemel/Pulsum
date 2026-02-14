import Foundation
import SwiftData

@Model
public final class SDDailyMetrics {
    #Index<SDDailyMetrics>([\.date])

    @Attribute(.unique) public var date: Date
    public var hrvMedian: Double?
    public var nocturnalHRPercentile10: Double?
    public var restingHR: Double?
    public var totalSleepTime: Double?
    public var sleepDebt: Double?
    public var respiratoryRate: Double?
    public var steps: Double?
    public var flags: String?

    public init(
        date: Date,
        hrvMedian: Double? = nil,
        nocturnalHRPercentile10: Double? = nil,
        restingHR: Double? = nil,
        totalSleepTime: Double? = nil,
        sleepDebt: Double? = nil,
        respiratoryRate: Double? = nil,
        steps: Double? = nil,
        flags: String? = nil
    ) {
        self.date = date
        self.hrvMedian = hrvMedian
        self.nocturnalHRPercentile10 = nocturnalHRPercentile10
        self.restingHR = restingHR
        self.totalSleepTime = totalSleepTime
        self.sleepDebt = sleepDebt
        self.respiratoryRate = respiratoryRate
        self.steps = steps
        self.flags = flags
    }
}
