import Foundation
import CoreData
import PulsumData
import PulsumServices
import PulsumTypes

// MARK: - Data Deletion (GDPR/CCPA)

extension SettingsViewModel {
    func deleteAllData() async {
        guard !isDeletingAllData else { return }
        isDeletingAllData = true
        deleteAllDataMessage = nil
        defer { isDeletingAllData = false }

        do {
            // 1. Delete all Core Data entities
            let context = PulsumData.newBackgroundContext(name: "Pulsum.DeleteAll")
            let entityNames = [
                "JournalEntry", "DailyMetrics", "Baseline", "FeatureVector",
                "MicroMoment", "RecommendationEvent", "LibraryIngest",
                "UserPrefs", "ConsentState"
            ]
            try await context.perform {
                for entityName in entityNames {
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    deleteRequest.resultType = .resultTypeObjectIDs
                    let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                    if let objectIDs = result?.result as? [NSManagedObjectID] {
                        let changes = [NSDeletedObjectsKey: objectIDs]
                        NSManagedObjectContext.mergeChanges(
                            fromRemoteContextSave: changes,
                            into: [PulsumData.viewContext]
                        )
                    }
                }
            }

            // 2. Clear vector index directory
            let vectorDir = PulsumData.vectorIndexDirectory
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: vectorDir.path) {
                let contents = try fileManager.contentsOfDirectory(at: vectorDir, includingPropertiesForKeys: nil)
                for file in contents {
                    try fileManager.removeItem(at: file)
                }
            }

            // 3. Remove Keychain entries (API key)
            try KeychainService.shared.removeSecret(for: "openai.api.key")

            // 4. Clear UserDefaults
            let defaults = UserDefaults.standard
            if let bundleId = Bundle.main.bundleIdentifier {
                defaults.removePersistentDomain(forName: bundleId)
            }
            defaults.removeObject(forKey: "ai.pulsum.hasLaunched")
            defaults.removeObject(forKey: "ai.pulsum.cloudConsent")
            defaults.removeObject(forKey: "ai.pulsum.hasCompletedOnboarding")

            // 5. Clear diagnostics
            await Diagnostics.clearDiagnostics()

            // Reset local state
            gptAPIKeyDraft = ""
            gptAPIStatus = "Missing API key"
            isGPTAPIWorking = false
            consentGranted = false
            debugLogSnapshot = ""
            diagnosticsExportURL = nil

            deleteAllDataMessage = "All data has been deleted."

            Diagnostics.log(level: .info,
                            category: .app,
                            name: "app.data.deleteAll.success")

            // Notify parent to reset to onboarding
            onDataDeleted?()
        } catch {
            deleteAllDataMessage = "Failed to delete data: \(error.localizedDescription)"
            Diagnostics.log(level: .error,
                            category: .app,
                            name: "app.data.deleteAll.failed",
                            error: error)
        }
    }
}
