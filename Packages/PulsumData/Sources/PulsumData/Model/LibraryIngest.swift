import Foundation
import SwiftData

@Model
public final class LibraryIngest {
    #Index<LibraryIngest>([\.source])

    public var id: UUID
    @Attribute(.unique) public var source: String
    public var checksum: String?
    public var ingestedAt: Date
    public var version: String?

    public init(
        id: UUID = UUID(),
        source: String,
        checksum: String? = nil,
        ingestedAt: Date = Date(),
        version: String? = nil
    ) {
        self.id = id
        self.source = source
        self.checksum = checksum
        self.ingestedAt = ingestedAt
        self.version = version
    }
}
