import Foundation
import Observation
import SwiftData
import PulsumAgents
import PulsumData
import PulsumTypes
import PulsumServices

/// Settings view model — coordinates consent, API key, and data deletion.
///
/// HealthKit state is now in `HealthSettingsViewModel`.
/// Diagnostics state is now in `DiagnosticsViewModel`.
///
/// Method implementations are split across focused extensions:
/// - `SettingsViewModel+APIKey.swift` — GPT API key management
/// - `SettingsViewModel+DataDeletion.swift` — GDPR/CCPA data deletion
@MainActor
@Observable
final class SettingsViewModel {
    // MARK: - Core

    @ObservationIgnored var orchestrator: AgentOrchestrator?
    @ObservationIgnored var modelContainer: ModelContainer?
    @ObservationIgnored var vectorIndexDirectory: URL?
    var consentGranted: Bool
    var lastConsentUpdated: Date = Date()

    /// Fires when consent changes. Observed by AppViewModel (P0-26).
    var consentDidChange: Bool = false

    /// Fires when data deletion completes. Observed by AppViewModel (P0-26).
    var dataDidDelete: Bool = false

    // MARK: - GPT API State

    var gptAPIStatus: String = "Missing API key"
    var isGPTAPIWorking: Bool = false
    var gptAPIKeyDraft: String = ""
    var isTestingAPIKey: Bool = false

    // MARK: - Data Deletion State

    var showDeleteAllConfirmation = false
    var isDeletingAllData = false
    var deleteAllDataMessage: String?

    // MARK: - Init

    init(initialConsent: Bool) {
        self.consentGranted = initialConsent
    }

    // MARK: - Orchestrator Binding

    func bind(orchestrator: AgentOrchestrator) {
        self.orchestrator = orchestrator
        if let stored = orchestrator.currentLLMAPIKey() {
            gptAPIKeyDraft = stored
            if !stored.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Task { await testCurrentAPIKey() }
            } else {
                gptAPIStatus = "Missing API key"
                isGPTAPIWorking = false
            }
        } else {
            gptAPIStatus = "Missing API key"
            isGPTAPIWorking = false
        }
    }

    func toggleConsent(_ newValue: Bool) {
        guard consentGranted != newValue else { return }
        consentGranted = newValue
        lastConsentUpdated = Date()
        consentDidChange.toggle()
        AppRuntimeConfig.synchronizeUITestDefaults()
    }

    func refreshConsent(_ value: Bool) {
        consentGranted = value
        lastConsentUpdated = Date()
    }

    func makeScoreBreakdownViewModel() -> ScoreBreakdownViewModel? {
        guard let orchestrator else { return nil }
        return ScoreBreakdownViewModel(orchestrator: orchestrator)
    }
}
