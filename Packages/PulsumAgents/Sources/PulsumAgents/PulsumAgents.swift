import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif
import PulsumData
import PulsumServices
import PulsumML
import SwiftData

public enum PulsumAgents {
    @MainActor
    public static func makeOrchestrator(container: ModelContainer, storagePaths: StoragePaths) throws -> AgentOrchestrator {
        try AgentOrchestrator(container: container, storagePaths: storagePaths)
    }

    public static func healthCheck(storagePaths: StoragePaths) -> Bool {
        !storagePaths.sqliteStoreURL.path.isEmpty && !storagePaths.healthAnchorsDirectory.path.isEmpty
    }

    public static func foundationModelsStatus() -> String {
        if #available(iOS 26.0, *) {
            let status = FoundationModelsAvailability.checkAvailability()
            return FoundationModelsAvailability.availabilityMessage(for: status)
        } else {
            return "Foundation Models require iOS 26 or later."
        }
    }
}
