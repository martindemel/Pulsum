import Foundation
import SwiftData
@testable import PulsumData

public final class TestCoreDataStack {
    public static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: DataStack.modelTypes,
            configurations: [config]
        )
    }
}
