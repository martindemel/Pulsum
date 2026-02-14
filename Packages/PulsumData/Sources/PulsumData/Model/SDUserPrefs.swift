import Foundation
import SwiftData

@Model
public final class SDUserPrefs {
    @Attribute(.unique) public var id: String
    public var consentCloud: Bool = false
    public var updatedAt: Date

    public init(
        id: String = "default",
        consentCloud: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.consentCloud = consentCloud
        self.updatedAt = updatedAt
    }
}
