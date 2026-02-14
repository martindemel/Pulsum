import Foundation
import Observation
import CoreData
import PulsumAgents
import PulsumData
import HealthKit
import PulsumTypes
import PulsumServices
#if canImport(UIKit)
import UIKit
#endif

/// Settings view model — coordinates HealthKit, API key, diagnostics, and data deletion.
///
/// Method implementations are split across focused extensions:
/// - `SettingsViewModel+HealthKit.swift` — HealthKit authorization & status
/// - `SettingsViewModel+APIKey.swift` — GPT API key management
/// - `SettingsViewModel+Diagnostics.swift` — Diagnostics config/export
/// - `SettingsViewModel+DataDeletion.swift` — GDPR/CCPA data deletion
@MainActor
@Observable
final class SettingsViewModel {
    // MARK: - Core

    @ObservationIgnored var orchestrator: AgentOrchestrator?
    var foundationModelsStatus: String = ""
    var consentGranted: Bool
    var lastConsentUpdated: Date = Date()
    var onConsentChanged: ((Bool) -> Void)?

    // MARK: - HealthKit State

    struct HealthAccessRow: Identifiable, Equatable {
        let id: String
        let title: String
        let detail: String
        let iconName: String
        let status: HealthAccessGrantState
    }

    var healthKitDebugSummary: String = ""
    var healthKitSummary: String = "Checking..."
    var missingHealthKitDetail: String?
    var healthAccessRows: [HealthAccessRow] = HealthAccessRequirement.ordered.map {
        HealthAccessRow(id: $0.id,
                        title: $0.title,
                        detail: $0.detail,
                        iconName: $0.iconName,
                        status: .pending)
    }

    var showHealthKitUnavailableBanner: Bool = false
    var isRequestingHealthKitAuthorization: Bool = false
    var canRequestHealthKitAccess: Bool = true
    var healthKitError: String?
    var healthKitSuccessMessage: String?
    @ObservationIgnored var healthKitSuccessTask: Task<Void, Never>?
    var lastHealthAccessStatus: HealthAccessStatus?
    var awaitingToastAfterRequest: Bool = false
    var didApplyInitialStatus: Bool = false

    // MARK: - Diagnostics State

    var debugLogSnapshot: String = ""
    var diagnosticsConfig: DiagnosticsConfig = Diagnostics.currentConfig()
    var diagnosticsSessionId: UUID = Diagnostics.sessionId
    var diagnosticsExportURL: URL?
    var isExportingDiagnostics = false

    // MARK: - GPT API State

    var gptAPIStatus: String = "Missing API key"
    var isGPTAPIWorking: Bool = false
    var gptAPIKeyDraft: String = ""
    var isTestingAPIKey: Bool = false

    // MARK: - Data Deletion State

    var showDeleteAllConfirmation = false
    var isDeletingAllData = false
    var deleteAllDataMessage: String?
    var onDataDeleted: (() -> Void)?

    // MARK: - Debug (DEBUG only)

    #if DEBUG
    var diagnosticsVisible: Bool = false
    var routeHistory: [String] = []
    var lastCoverageSummary: String = "—"
    var lastCloudError: String = "None"
    @ObservationIgnored var routeTask: Task<Void, Never>?
    @ObservationIgnored var errorTask: Task<Void, Never>?
    let diagnosticsHistoryLimit = 5
    #endif

    // MARK: - Init

    init(initialConsent: Bool) {
        self.consentGranted = initialConsent
        #if DEBUG
        setupDiagnosticsObservers()
        #endif
        refreshDiagnosticsConfig()
    }

    // MARK: - Orchestrator Binding

    func bind(orchestrator: AgentOrchestrator) {
        self.orchestrator = orchestrator
        foundationModelsStatus = orchestrator.foundationModelsStatus
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
        refreshHealthAccessStatus()
        refreshDiagnosticsConfig()
    }

    func refreshFoundationStatus() {
        guard let orchestrator else { return }
        foundationModelsStatus = orchestrator.foundationModelsStatus
    }

    func toggleConsent(_ newValue: Bool) {
        guard consentGranted != newValue else { return }
        consentGranted = newValue
        lastConsentUpdated = Date()
        onConsentChanged?(newValue)
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

    #if DEBUG
    deinit {
        routeTask?.cancel()
        errorTask?.cancel()
    }
    #endif
}
