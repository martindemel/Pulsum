import SwiftData
import PulsumData

final class TestCoreDataStack {
    static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: DataStack.modelTypes,
            configurations: [config]
        )
    }
}
