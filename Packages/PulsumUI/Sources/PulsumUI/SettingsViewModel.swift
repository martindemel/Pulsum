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
            healthKitDebugSummary = ""
            debugLogSnapshot = ""
            return
        }
        Task { [weak self] in
            guard let self else { return }
            let status = await orchestrator.currentHealthAccessStatus()
            await MainActor.run {
                if AppRuntimeConfig.isUITesting,
                   let last = self.lastHealthAccessStatus,
                   last.isFullyGranted,
                   !status.isFullyGranted {
                    return
                }
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

        let requestOverride = ProcessInfo.processInfo.environment["PULSUM_HEALTHKIT_REQUEST_BEHAVIOR"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let overrideIsGrantAll = requestOverride == "grantall" || requestOverride == "grant_all"
        let shouldForceGrant = AppRuntimeConfig.isUITesting || overrideIsGrantAll

        if shouldForceGrant {
            let status = await orchestrator.currentHealthAccessStatus()
            let patched = HealthAccessStatus(required: status.required,
                                             granted: Set(status.required),
                                             denied: [],
                                             notDetermined: [],
                                             availability: .available)
            applyHealthStatus(patched)
            healthKitDebugSummary = Self.debugSummary(from: patched)
            if overrideIsGrantAll {
                Task { [weak self] in
                    guard let self, let orchestrator = self.orchestrator else { return }
                    _ = try? await orchestrator.requestHealthAccess()
                }
            }
            return
        }

        do {
            let status = try await orchestrator.requestHealthAccess()
            if AppRuntimeConfig.isUITesting, !status.isFullyGranted {
                let patched = HealthAccessStatus(required: status.required,
                                                 granted: Set(status.required),
                                                 denied: [],
                                                 notDetermined: [],
                                                 availability: .available)
                applyHealthStatus(patched)
                healthKitDebugSummary = Self.debugSummary(from: patched)
                return
            }
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

    func forceGrantHealthAccessForUITest() {
        awaitingToastAfterRequest = true
        let required = lastHealthAccessStatus?.required ?? HealthKitService.orderedReadSampleTypes
        let patched = HealthAccessStatus(required: required,
                                         granted: Set(required),
                                         denied: [],
                                         notDetermined: [],
                                         availability: .available)
        applyHealthStatus(patched)
        healthKitDebugSummary = Self.debugSummary(from: patched)
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
        AppRuntimeConfig.synchronizeUITestDefaults()
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
        guard !isExportingDiagnostics else { return }
        isExportingDiagnostics = true
        diagnosticsExportURL = nil
        defer { isExportingDiagnostics = false }

        let config = diagnosticsConfig
        let sessionId = diagnosticsSessionId
        let locale = Locale.current.identifier
        let appVersion = Self.appVersion()
        let buildNumber = Self.buildNumber()
        let deviceModel = Self.deviceModel()
        let osVersion = Self.osVersion()
        let snapshot: DiagnosticsSnapshot
        if let orchestrator {
            do {
                let snapshotResult = try await withHardTimeout(seconds: 2) {
                    await orchestrator.diagnosticsSnapshot()
                }
                switch snapshotResult {
                case .value(let value):
                    snapshot = value
                case .timedOut:
                    snapshot = DiagnosticsSnapshot()
                    debugLogSnapshot = "Diagnostics snapshot timed out; exporting partial report."
                }
            } catch {
                snapshot = DiagnosticsSnapshot()
                debugLogSnapshot = "Diagnostics snapshot failed: \(error.localizedDescription)"
            }
        } else {
            snapshot = DiagnosticsSnapshot()
        }

        let exportTask = Task.detached(priority: .utility) { () async -> URL? in
            if config.persistToDisk {
                await Diagnostics.flushPersistence()
            }
            let logTail: [String]
            if config.persistToDisk {
                logTail = await Diagnostics.persistedLogTail(maxLines: config.logTailLinesForExport)
            } else {
                logTail = await DebugLogBuffer.shared.tail(maxLines: config.logTailLinesForExport)
            }

            let sessionsIncluded = Self.extractSessionIds(from: logTail)

            let context = DiagnosticsReportContext(appVersion: appVersion,
                                                   buildNumber: buildNumber,
                                                   deviceModel: deviceModel,
                                                   osVersion: osVersion,
                                                   locale: locale,
                                                   sessionId: sessionId,
                                                   diagnosticsEnabled: config.enabled,
                                                   persistenceEnabled: config.persistToDisk,
                                                   sessionsIncluded: sessionsIncluded.isEmpty ? nil : sessionsIncluded)

            do {
                return try DiagnosticsReportBuilder.buildReport(context: context,
                                                                snapshot: snapshot,
                                                                logTail: logTail)
            } catch {
                Diagnostics.log(level: .error,
                                category: .ui,
                                name: "ui.diagnostics.report.build.failed",
                                fields: [
                                    "session_id": .uuid(sessionId),
                                    "persist_enabled": .bool(config.persistToDisk)
                                ],
                                error: error)
                return nil
            }
        }

        diagnosticsExportURL = await exportTask.value
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
        if AppRuntimeConfig.isUITesting {
            let trimmed = gptAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            isTestingAPIKey = false
            if trimmed.isEmpty {
                isGPTAPIWorking = false
                gptAPIStatus = "Missing API key"
            } else {
                let ok = AppRuntimeConfig.useStubLLM
                isGPTAPIWorking = ok
                gptAPIStatus = ok ? "OpenAI reachable" : "OpenAI ping failed"
            }
            return
        }
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
        let shouldToast = status.isFullyGranted && (transitionedToFull || awaitingToastAfterRequest)
        if shouldToast && (didApplyInitialStatus || awaitingToastAfterRequest) {
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

    private nonisolated static func extractSessionIds(from logTail: [String]) -> [String] {
        var sessions: [String] = []
        for line in logTail {
            guard let range = line.range(of: "app.session.start session=") else { continue }
            let after = line[range.upperBound...]
            if let id = after.split(separator: " ").first {
                let value = String(id)
                if !sessions.contains(value) {
                    sessions.append(value)
                }
            }
        }
        return sessions
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
