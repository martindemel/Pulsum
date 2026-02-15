import Foundation
import SwiftData
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
            // 1. Delete all SwiftData entities
            guard let container = modelContainer else {
                deleteAllDataMessage = "Data store not available."
                return
            }
            let context = ModelContext(container)
            try context.delete(model: JournalEntry.self)
            try context.delete(model: DailyMetrics.self)
            try context.delete(model: Baseline.self)
            try context.delete(model: FeatureVector.self)
            try context.delete(model: MicroMoment.self)
            try context.delete(model: RecommendationEvent.self)
            try context.delete(model: LibraryIngest.self)
            try context.delete(model: UserPrefs.self)
            try context.delete(model: ConsentState.self)
            try context.save()

            // 2. Clear vector index directory
            if let vectorDir = vectorIndexDirectory {
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: vectorDir.path) {
                    let contents = try fileManager.contentsOfDirectory(at: vectorDir, includingPropertiesForKeys: nil)
                    for file in contents {
                        try fileManager.removeItem(at: file)
                    }
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
