import Foundation
import SwiftData

@Model
public final class MicroMoment {
    #Index<MicroMoment>([\.id])

    @Attribute(.unique) public var id: String
    public var title: String
    public var shortDescription: String
    public var detail: String?
    /// JSON-encoded string array (e.g. `["sleep","stress"]`).
    /// SwiftData cannot query inside `[String]`, so tags are stored as a JSON string.
    public var tags: String?
    public var estimatedTimeSec: Int32?
    public var difficulty: String?
    public var category: String?
    public var sourceURL: String?
    public var evidenceBadge: String?
    public var cooldownSec: Int32?

    public init(
        id: String,
        title: String,
        shortDescription: String,
        detail: String? = nil,
        tags: String? = nil,
        estimatedTimeSec: Int32? = nil,
        difficulty: String? = nil,
        category: String? = nil,
        sourceURL: String? = nil,
        evidenceBadge: String? = nil,
        cooldownSec: Int32? = nil
    ) {
        self.id = id
        self.title = title
        self.shortDescription = shortDescription
        self.detail = detail
        self.tags = tags
        self.estimatedTimeSec = estimatedTimeSec
        self.difficulty = difficulty
        self.category = category
        self.sourceURL = sourceURL
        self.evidenceBadge = evidenceBadge
        self.cooldownSec = cooldownSec
    }
}
