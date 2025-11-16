import Foundation
import Observation
import PulsumAgents
import HealthKit
import PulsumTypes

@MainActor
@Observable
final class SettingsViewModel {
    @ObservationIgnored private var orchestrator: AgentOrchestrator?
    private(set) var foundationModelsStatus: String = ""
    var consentGranted: Bool
    var lastConsentUpdated: Date = Date()

    struct HealthAccessRow: Identifiable, Equatable {
        let id: String
        let title: String
        let detail: String
        let iconName: String
        let status: HealthAccessGrantState
    }

    // HealthKit State
    private(set) var healthKitSummary: String = "Checking..."
    private(set) var missingHealthKitDetail: String?
    private(set) var healthAccessRows: [HealthAccessRow] = HealthAccessRequirement.ordered.map {
        HealthAccessRow(id: $0.id,
                        title: $0.title,
                        detail: $0.detail,
                        iconName: $0.iconName,
                        status: .pending)
    }
    private(set) var showHealthKitUnavailableBanner: Bool = false
    private(set) var isRequestingHealthKitAuthorization: Bool = false
    private(set) var healthKitError: String?
    private(set) var healthKitSuccessMessage: String?
    @ObservationIgnored private var healthKitSuccessTask: Task<Void, Never>?
    private var lastHealthAccessStatus: HealthAccessStatus?

    // GPT-5 API Status
    private(set) var gptAPIStatus: String = "Missing API key"
    private(set) var isGPTAPIWorking: Bool = false
    var gptAPIKeyDraft: String = ""

    var onConsentChanged: ((Bool) -> Void)?

#if DEBUG
    var diagnosticsVisible: Bool = false
    var routeHistory: [String] = []
    var lastCoverageSummary: String = "—"
    var lastCloudError: String = "None"
    @ObservationIgnored private var routeTask: Task<Void, Never>?
    @ObservationIgnored private var errorTask: Task<Void, Never>?
    private let diagnosticsHistoryLimit = 5
#endif

    init(initialConsent: Bool) {
        self.consentGranted = initialConsent
#if DEBUG
        setupDiagnosticsObservers()
#endif
    }

    func bind(orchestrator: AgentOrchestrator) {
        self.orchestrator = orchestrator
        foundationModelsStatus = orchestrator.foundationModelsStatus
        if let stored = orchestrator.currentLLMAPIKey() {
            gptAPIKeyDraft = stored
            if !stored.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Task { await checkGPTAPIKey() }
            } else {
                gptAPIStatus = "Missing API key"
                isGPTAPIWorking = false
            }
        } else {
            gptAPIStatus = "Missing API key"
            isGPTAPIWorking = false
        }
        refreshHealthAccessStatus()
    }

    func refreshFoundationStatus() {
        guard let orchestrator else { return }
        foundationModelsStatus = orchestrator.foundationModelsStatus
    }

    func refreshHealthAccessStatus() {
        guard let orchestrator else {
            healthKitSummary = "Agent unavailable"
            return
        }
        Task { [weak self] in
            guard let self else { return }
            let status = await orchestrator.currentHealthAccessStatus()
            await MainActor.run {
                self.applyHealthStatus(status)
            }
        }
    }

    func requestHealthKitAuthorization() async {
        guard let orchestrator else {
            healthKitError = "Agent unavailable"
            return
        }
        isRequestingHealthKitAuthorization = true
        healthKitError = nil

        do {
            let status = try await orchestrator.requestHealthAccess()
            applyHealthStatus(status)
        } catch {
            healthKitError = error.localizedDescription
        }

        isRequestingHealthKitAuthorization = false
    }

    func toggleConsent(_ newValue: Bool) {
        guard consentGranted != newValue else { return }
        consentGranted = newValue
        lastConsentUpdated = Date()
        onConsentChanged?(newValue)
    }

    func refreshConsent(_ value: Bool) {
        consentGranted = value
        lastConsentUpdated = Date()
    }

    @MainActor
    func saveAPIKeyAndTest(_ key: String) async {
        guard let orchestrator else {
            gptAPIStatus = "Agent unavailable"
            isGPTAPIWorking = false
            return
        }
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            gptAPIStatus = "Missing API key"
            isGPTAPIWorking = false
            return
        }
        gptAPIStatus = "Saving..."
        isGPTAPIWorking = false
        do {
            try orchestrator.setLLMAPIKey(trimmedKey)
            gptAPIStatus = "Testing..."
            let ok = try await orchestrator.testLLMAPIConnection()
            isGPTAPIWorking = ok
            gptAPIStatus = ok ? "OpenAI reachable" : "OpenAI ping failed"
        } catch {
            isGPTAPIWorking = false
            gptAPIStatus = "Missing or invalid API key"
        }
    }

    @MainActor
    func checkGPTAPIKey() async {
        guard let orchestrator else {
            gptAPIStatus = "Agent unavailable"
            isGPTAPIWorking = false
            return
        }
        gptAPIStatus = "Testing..."
        isGPTAPIWorking = false
        do {
            let ok = try await orchestrator.testLLMAPIConnection()
            isGPTAPIWorking = ok
            gptAPIStatus = ok ? "OpenAI reachable" : "OpenAI ping failed"
        } catch {
            isGPTAPIWorking = false
            gptAPIStatus = "Missing or invalid API key"
        }
    }

    func makeScoreBreakdownViewModel() -> ScoreBreakdownViewModel? {
        guard let orchestrator else { return nil }
        return ScoreBreakdownViewModel(orchestrator: orchestrator)
    }

    private func applyHealthStatus(_ status: HealthAccessStatus) {
        let previouslyGranted = lastHealthAccessStatus?.isFullyGranted ?? false
        lastHealthAccessStatus = status

        switch status.availability {
        case .available:
            if status.totalRequired > 0 {
                healthKitSummary = "\(status.grantedCount)/\(status.totalRequired) granted"
            } else {
                healthKitSummary = "Ready"
            }
            showHealthKitUnavailableBanner = false
            let missingTitles = status.missingTypes.compactMap { HealthAccessRequirement.descriptor(for: $0)?.title }
            if missingTitles.isEmpty {
                missingHealthKitDetail = nil
            } else {
                missingHealthKitDetail = "Missing: \(missingTitles.joined(separator: ", "))"
            }
        case .unavailable(let reason):
            healthKitSummary = "Health data unavailable"
            showHealthKitUnavailableBanner = true
            missingHealthKitDetail = reason
        }

        healthAccessRows = HealthAccessRequirement.ordered.map { descriptor in
            HealthAccessRow(id: descriptor.id,
                            title: descriptor.title,
                            detail: descriptor.detail,
                            iconName: descriptor.iconName,
                            status: rowStatus(for: descriptor.id, status: status))
        }

        if status.isFullyGranted && !previouslyGranted {
            emitHealthKitSuccessToast()
        } else if !status.isFullyGranted {
            cancelHealthKitSuccessToast()
        }
    }

    private func rowStatus(for identifier: String, status: HealthAccessStatus) -> HealthAccessGrantState {
        if status.granted.contains(where: { $0.identifier == identifier }) {
            return .granted
        }
        if status.denied.contains(where: { $0.identifier == identifier }) {
            return .denied
        }
        if status.notDetermined.contains(where: { $0.identifier == identifier }) {
            return .pending
        }
        return .pending
    }

    private func emitHealthKitSuccessToast() {
        healthKitSuccessMessage = "Health data connected"
        healthKitSuccessTask?.cancel()
        healthKitSuccessTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                self?.healthKitSuccessMessage = nil
            }
        }
    }

    private func cancelHealthKitSuccessToast() {
        healthKitSuccessTask?.cancel()
        healthKitSuccessTask = nil
        healthKitSuccessMessage = nil
    }

#if DEBUG
    func toggleDiagnosticsVisibility() {
        diagnosticsVisible.toggle()
    }

    private func setupDiagnosticsObservers() {
        let center = NotificationCenter.default

        routeTask = Task { [weak self] in
            for await note in center.notifications(named: .pulsumChatRouteDiagnostics) {
                guard let self else { continue }
                await MainActor.run {
                    if let route = note.userInfo?["route"] as? String {
                        routeHistory.insert(route, at: 0)
                        if routeHistory.count > diagnosticsHistoryLimit {
                            routeHistory.removeLast(routeHistory.count - diagnosticsHistoryLimit)
                        }
                    }

                    if let top = note.userInfo?["top"] as? Double,
                       let median = note.userInfo?["median"] as? Double,
                       let count = note.userInfo?["count"] as? Int {
                        lastCoverageSummary = "matches=\(count) top=\(String(format: "%.2f", top)) median=\(String(format: "%.2f", median))"
                    } else {
                        lastCoverageSummary = "–"
                    }
                }
            }
        }

        errorTask = Task { [weak self] in
            for await note in center.notifications(named: .pulsumChatCloudError) {
                guard let self else { continue }
                await MainActor.run {
                    if let message = note.userInfo?["message"] as? String {
                        lastCloudError = message
                    }
                }
            }
        }
    }

    deinit {
        routeTask?.cancel()
        errorTask?.cancel()
    }
#endif
}
