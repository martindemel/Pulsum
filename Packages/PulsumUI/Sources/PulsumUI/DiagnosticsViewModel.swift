import Foundation
import Observation
import PulsumAgents
import PulsumTypes
#if canImport(UIKit)
import UIKit
#endif

/// View model for diagnostics configuration, export, and debug panels in Settings.
///
/// Extracted from SettingsViewModel (Phase 0G, P0-24).
@MainActor
@Observable
final class DiagnosticsViewModel {
    // MARK: - Diagnostics State

    @ObservationIgnored var orchestrator: AgentOrchestrator?

    var diagnosticsConfig: DiagnosticsConfig = Diagnostics.currentConfig()
    var diagnosticsSessionId: UUID = Diagnostics.sessionId
    var diagnosticsExportURL: URL?
    var isExportingDiagnostics = false
    var foundationModelsStatus: String = ""

    // MARK: - Debug (DEBUG only)

    #if DEBUG
    var diagnosticsVisible: Bool = false
    var routeHistory: [String] = []
    var lastCoverageSummary: String = "---"
    var lastCloudError: String = "None"
    @ObservationIgnored var routeTask: Task<Void, Never>?
    @ObservationIgnored var errorTask: Task<Void, Never>?
    let diagnosticsHistoryLimit = 5
    #endif

    // MARK: - Init

    init() {
        #if DEBUG
        setupDiagnosticsObservers()
        #endif
        refreshDiagnosticsConfig()
    }

    // MARK: - Orchestrator Binding

    func bind(orchestrator: AgentOrchestrator) {
        self.orchestrator = orchestrator
        foundationModelsStatus = orchestrator.foundationModelsStatus
        refreshDiagnosticsConfig()
    }

    func refreshFoundationStatus() {
        guard let orchestrator else { return }
        foundationModelsStatus = orchestrator.foundationModelsStatus
    }

    // MARK: - Diagnostics & Logging

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
                case let .value(value):
                    snapshot = value
                case .timedOut:
                    snapshot = DiagnosticsSnapshot()
                }
            } catch {
                snapshot = DiagnosticsSnapshot()
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
                                    "persist_enabled": .bool(config.persistToDisk),
                                ],
                                error: error)
                return nil
            }
        }

        diagnosticsExportURL = await exportTask.value
    }

    func clearDiagnostics() async {
        await Diagnostics.clearDiagnostics()
        diagnosticsExportURL = nil
    }

    static func appVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }

    static func buildNumber() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
    }

    static func deviceModel() -> String {
        #if canImport(UIKit)
        return UIDevice.current.model
        #else
        return "mac"
        #endif
    }

    static func osVersion() -> String {
        #if canImport(UIKit)
        return UIDevice.current.systemVersion
        #else
        return ProcessInfo.processInfo.operatingSystemVersionString
        #endif
    }

    nonisolated static func extractSessionIds(from logTail: [String]) -> [String] {
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

    func setupDiagnosticsObservers() {
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
                        lastCoverageSummary = "---"
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
