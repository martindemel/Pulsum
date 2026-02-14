import Foundation
import SwiftData

@Model
public final class SDBaseline {
    #Unique<SDBaseline>([\.metric, \.windowDays])

    public var metric: String
    public var windowDays: Int16 = 21
    public var median: Double?
    public var mad: Double?
    public var ewma: Double?
    public var updatedAt: Date?

    public init(
        metric: String,
        windowDays: Int16 = 21,
        median: Double? = nil,
        mad: Double? = nil,
        ewma: Double? = nil,
        updatedAt: Date? = nil
    ) {
        self.metric = metric
        self.windowDays = windowDays
        self.median = median
        self.mad = mad
        self.ewma = ewma
        self.updatedAt = updatedAt
    }
}
