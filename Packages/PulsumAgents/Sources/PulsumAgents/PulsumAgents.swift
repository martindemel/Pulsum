import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif
import PulsumData
import PulsumServices
import PulsumML

public enum PulsumAgents {
    @MainActor
    public static func makeOrchestrator() throws -> AgentOrchestrator {
        try AgentOrchestrator()
    }

    public static func healthCheck() -> Bool {
        let metadata = PulsumServices.storageMetadata()
        return !metadata.storeURL.path.isEmpty && !metadata.anchorsDirectory.path.isEmpty
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








