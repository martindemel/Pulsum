import Foundation
import Observation
import PulsumAgents
import PulsumServices
import PulsumTypes

/// View model for HealthKit authorization & status display in Settings.
///
/// Extracted from SettingsViewModel (Phase 0G, P0-23).
@MainActor
@Observable
final class HealthSettingsViewModel {
    // MARK: - HealthKit State

    struct HealthAccessRow: Identifiable, Equatable {
        let id: String
        let title: String
        let detail: String
        let iconName: String
        let status: HealthAccessGrantState
    }

    @ObservationIgnored var orchestrator: AgentOrchestrator?

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

    var debugLogSnapshot: String = ""

    // MARK: - Orchestrator Binding

    func bind(orchestrator: AgentOrchestrator) {
        self.orchestrator = orchestrator
        refreshHealthAccessStatus()
    }

    // MARK: - HealthKit Authorization & Status

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

    func debugHealthStatusSnapshot() -> String {
        healthKitDebugSummary
    }

    func applyHealthStatus(_ status: HealthAccessStatus) {
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
        case let .unavailable(reason):
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

    func rowStatus(for identifier: String, status: HealthAccessStatus) -> HealthAccessGrantState {
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

    func emitHealthKitSuccessToast() {
        healthKitSuccessMessage = "Health data connected"
        healthKitSuccessTask?.cancel()
        healthKitSuccessTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                self?.healthKitSuccessMessage = nil
            }
        }
    }

    func cancelHealthKitSuccessToast() {
        healthKitSuccessTask?.cancel()
        healthKitSuccessTask = nil
        healthKitSuccessMessage = nil
    }

    static func debugSummary(from status: HealthAccessStatus) -> String {
        let granted = status.granted.map(\.identifier).sorted().joined(separator: ", ")
        let denied = status.denied.map(\.identifier).sorted().joined(separator: ", ")
        let pending = status.notDetermined.map(\.identifier).sorted().joined(separator: ", ")
        return "Granted: [\(granted)] | Denied: [\(denied)] | Pending: [\(pending)] | Availability: \(status.availability)"
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
}
