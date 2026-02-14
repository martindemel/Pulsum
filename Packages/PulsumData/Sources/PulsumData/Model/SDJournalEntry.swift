import Foundation
import SwiftData

@Model
public final class SDJournalEntry {
    #Index<SDJournalEntry>([\.date])

    public var id: UUID
    public var date: Date
    public var transcript: String
    public var sentiment: Double = 0
    public var embeddedVectorURL: String?
    public var sensitiveFlags: String?

    public init(
        id: UUID = UUID(),
        date: Date,
        transcript: String,
        sentiment: Double = 0,
        embeddedVectorURL: String? = nil,
        sensitiveFlags: String? = nil
    ) {
        self.id = id
        self.date = date
        self.transcript = transcript
        self.sentiment = sentiment
        self.embeddedVectorURL = embeddedVectorURL
        self.sensitiveFlags = sensitiveFlags
    }
}
