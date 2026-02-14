import Foundation
import SwiftData

@Model
public final class SDRecommendationEvent {
    #Index<SDRecommendationEvent>([\.momentId])

    public var momentId: String
    public var date: Date
    public var accepted: Bool = false
    public var completedAt: Date?

    public init(
        momentId: String,
        date: Date,
        accepted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.momentId = momentId
        self.date = date
        self.accepted = accepted
        self.completedAt = completedAt
    }
}
