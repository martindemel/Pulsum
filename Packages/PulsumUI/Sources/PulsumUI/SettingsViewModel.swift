import Foundation
import Observation
import PulsumAgents
import HealthKit
import PulsumTypes
import PulsumServices
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
final class SettingsViewModel {
    @ObservationIgnored private var orchestrator: AgentOrchestrator?
    private(set) var foundationModelsStatus: String = ""
    var consentGranted: Bool
    var lastConsentUpdated: Date = Date()
    var healthKitDebugSummary: String = ""

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
    private(set) var canRequestHealthKitAccess: Bool = true
    private(set) var healthKitError: String?
    private(set) var healthKitSuccessMessage: String?
    @ObservationIgnored private var healthKitSuccessTask: Task<Void, Never>?
    private var lastHealthAccessStatus: HealthAccessStatus?
    private var awaitingToastAfterRequest: Bool = false
    private var didApplyInitialStatus: Bool = false
    var debugLogSnapshot: String = ""
    var diagnosticsConfig: DiagnosticsConfig = Diagnostics.currentConfig()
    var diagnosticsSessionId: UUID = Diagnostics.sessionId
    var diagnosticsExportURL: URL?
    var isExportingDiagnostics = false

    // GPT-5 API Status
    private(set) var gptAPIStatus: String = "Missing API key"
    private(set) var isGPTAPIWorking: Bool = false
    var gptAPIKeyDraft: String = ""
    private(set) var isTestingAPIKey: Bool = false

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
        refreshDiagnosticsConfig()
    }

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

    func refreshHealthAccessStatus() {
        guard let orchestrator else {
            healthKitSummary = "Agent unavailable"
            canRequestHealthKitAccess = false
            return
        }
        Task { [weak self] in
            guard let self else { return }
            let status = await orchestrator.currentHealthAccessStatus()
            await MainActor.run {
                self.applyHealthStatus(status)
                self.healthKitDebugSummary = Self.debugSummary(from: status)
                self.debugLogSnapshot = ""
            }
        }
    }

    func requestHealthKitAuthorization() async {
        guard let orchestrator else {
            healthKitError = "Agent unavailable"
            return
        }
        isRequestingHealthKitAuthorization = true
        awaitingToastAfterRequest = true
        healthKitError = nil
        defer { isRequestingHealthKitAuthorization = false }

        do {
            let status = try await orchestrator.requestHealthAccess()
            applyHealthStatus(status)
            healthKitDebugSummary = Self.debugSummary(from: status)
        } catch let serviceError as HealthKitServiceError {
            healthKitError = serviceError.localizedDescription
            let status = await orchestrator.currentHealthAccessStatus()
            applyHealthStatus(status)
            healthKitDebugSummary = Self.debugSummary(from: status)
        } catch {
            healthKitError = error.localizedDescription
            let status = await orchestrator.currentHealthAccessStatus()
            applyHealthStatus(status)
            healthKitDebugSummary = Self.debugSummary(from: status)
        }
    }

    func refreshDebugLog() async {
        guard let orchestrator else {
            debugLogSnapshot = "Debug log unavailable (orchestrator not ready)"
            return
        }
        let snapshot = await orchestrator.debugLogSnapshot()
        await MainActor.run {
            debugLogSnapshot = snapshot.isEmpty ? "No events captured yet." : snapshot
        }
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

    func refreshDiagnosticsConfig() {
        diagnosticsConfig = Diagnostics.currentConfig()
        diagnosticsSessionId = Diagnostics.sessionId
    }

    func updateDiagnosticsEnabled(_ enabled: Bool) {
        diagnosticsConfig.enabled = enabled
        Diagnostics.updateConfig(diagnosticsConfig)
    }

    func updateDiagnosticsPersistence(_ persist: Bool) {
        diagnosticsConfig.persistToDisk = persist
        Diagnostics.updateConfig(diagnosticsConfig)
    }

    func updateDiagnosticsOSLog(_ mirror: Bool) {
        diagnosticsConfig.mirrorToOSLog = mirror
        Diagnostics.updateConfig(diagnosticsConfig)
    }

    func updateDiagnosticsSignposts(_ enable: Bool) {
        diagnosticsConfig.enableSignposts = enable
        Diagnostics.updateConfig(diagnosticsConfig)
    }

    func exportDiagnosticsReport() async {
        isExportingDiagnostics = true
        defer { isExportingDiagnostics = false }
        let config = diagnosticsConfig
        let debugTail = await DebugLogBuffer.shared.snapshot()
            .split(separator: "\n")
            .map(String.init)
        let debugTailLines = Array(debugTail.suffix(config.logTailLinesForExport))
        let persisted = await Diagnostics.persistedLogTail(maxLines: config.logTailLinesForExport)
        let combined = Array((debugTailLines + persisted).suffix(config.logTailLinesForExport))
        let snapshot = await orchestrator?.diagnosticsSnapshot() ?? DiagnosticsSnapshot()
        let context = DiagnosticsReportContext(appVersion: Self.appVersion(),
                                               buildNumber: Self.buildNumber(),
                                               deviceModel: Self.deviceModel(),
                                               osVersion: Self.osVersion(),
                                               locale: Locale.current.identifier,
                                               sessionId: diagnosticsSessionId,
                                               diagnosticsEnabled: config.enabled,
                                               persistenceEnabled: config.persistToDisk)
        diagnosticsExportURL = try? DiagnosticsReportBuilder.buildReport(context: context,
                                                                         snapshot: snapshot,
                                                                         logTail: combined)
    }

    func clearDiagnostics() async {
        await Diagnostics.clearDiagnostics()
        debugLogSnapshot = ""
        diagnosticsExportURL = nil
    }

    @MainActor
    func saveAPIKey(_ key: String) async {
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
        do {
            try orchestrator.setLLMAPIKey(trimmedKey)
            gptAPIKeyDraft = trimmedKey
            isGPTAPIWorking = false
            gptAPIStatus = "API key saved"
        } catch {
            isGPTAPIWorking = false
            gptAPIStatus = "Missing or invalid API key"
        }
    }

    @MainActor
    func testCurrentAPIKey() async {
        guard let orchestrator else {
            gptAPIStatus = "Agent unavailable"
            isGPTAPIWorking = false
            return
        }
        isTestingAPIKey = true
        defer { isTestingAPIKey = false }
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
        let wasFullyGrantedOptional = lastHealthAccessStatus?.isFullyGranted
        lastHealthAccessStatus = status

        switch status.availability {
        case .available:
            if status.totalRequired > 0 {
                healthKitSummary = "\(status.grantedCount)/\(status.totalRequired) granted"
            } else {
                healthKitSummary = "Ready"
            }
            showHealthKitUnavailableBanner = false
            canRequestHealthKitAccess = true
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
            canRequestHealthKitAccess = false
        }

        healthAccessRows = HealthAccessRequirement.ordered.map { descriptor in
            HealthAccessRow(id: descriptor.id,
                            title: descriptor.title,
                            detail: descriptor.detail,
                            iconName: descriptor.iconName,
                            status: rowStatus(for: descriptor.id, status: status))
        }

        let transitionedToFull = (wasFullyGrantedOptional == false) && status.isFullyGranted
        if status.isFullyGranted && (transitionedToFull || awaitingToastAfterRequest) && didApplyInitialStatus {
            awaitingToastAfterRequest = false
            emitHealthKitSuccessToast()
        } else if !status.isFullyGranted {
            cancelHealthKitSuccessToast()
        }

        if !didApplyInitialStatus {
            didApplyInitialStatus = true
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

    func debugHealthStatusSnapshot() -> String {
        healthKitDebugSummary
    }

    private static func debugSummary(from status: HealthAccessStatus) -> String {
        let granted = status.granted.map(\.identifier).sorted().joined(separator: ", ")
        let denied = status.denied.map(\.identifier).sorted().joined(separator: ", ")
        let pending = status.notDetermined.map(\.identifier).sorted().joined(separator: ", ")
        return "Granted: [\(granted)] | Denied: [\(denied)] | Pending: [\(pending)] | Availability: \(status.availability)"
    }

    private static func appVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }

    private static func buildNumber() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
    }

    private static func deviceModel() -> String {
        #if canImport(UIKit)
        return UIDevice.current.model
        #else
        return "mac"
        #endif
    }

    private static func osVersion() -> String {
        #if canImport(UIKit)
        return UIDevice.current.systemVersion
        #else
        return ProcessInfo.processInfo.operatingSystemVersionString
        #endif
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
