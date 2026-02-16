import Foundation
import SwiftData

@Model
public final class ConsentState {
    public var id: UUID
    @Attribute(.unique) public var version: String
    public var grantedAt: Date?
    public var revokedAt: Date?

    public init(
        id: UUID = UUID(),
        version: String,
        grantedAt: Date? = nil,
        revokedAt: Date? = nil
    ) {
        self.id = id
        self.version = version
        self.grantedAt = grantedAt
        self.revokedAt = revokedAt
    }
}
