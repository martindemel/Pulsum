import Foundation
import Observation
import PulsumAgents
import PulsumServices
import HealthKit

@MainActor
@Observable
final class SettingsViewModel {
    @ObservationIgnored private var orchestrator: AgentOrchestrator?
    private(set) var foundationModelsStatus: String = ""
    var consentGranted: Bool
    var lastConsentUpdated: Date = Date()

    // HealthKit State
    private(set) var healthKitAuthorizationStatus: String = "Unknown"
    private(set) var isRequestingHealthKitAuthorization: Bool = false
    private(set) var healthKitError: String?

    // GPT-5 API Status
    private(set) var gptAPIStatus: String = "Checking..."
    private(set) var isGPTAPIWorking: Bool = false
    var gptAPIKeyDraft: String = ""

    var onConsentChanged: ((Bool) -> Void)?
    private let llmGateway = LLMGateway()

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
        if let stored = llmGateway.currentAPIKey() {
            gptAPIKeyDraft = stored
        }
        // Auto-test on load if we have any seed
        if !gptAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Task { await checkGPTAPIKey() }
        }
#if DEBUG
        setupDiagnosticsObservers()
#endif
    }

    func bind(orchestrator: AgentOrchestrator) {
        self.orchestrator = orchestrator
        foundationModelsStatus = orchestrator.foundationModelsStatus
    }

    func refreshFoundationStatus() {
        guard let orchestrator else { return }
        foundationModelsStatus = orchestrator.foundationModelsStatus
    }

    func refreshHealthKitStatus() {
        if !HKHealthStore.isHealthDataAvailable() {
            healthKitAuthorizationStatus = "Not available on this device"
            return
        }

        // Check authorization status for HRV (representative type)
        let healthStore = HKHealthStore()
        if let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            let status = healthStore.authorizationStatus(for: hrvType)
            switch status {
            case .notDetermined:
                healthKitAuthorizationStatus = "Not requested"
            case .sharingDenied:
                healthKitAuthorizationStatus = "Denied - Please enable in Settings"
            case .sharingAuthorized:
                healthKitAuthorizationStatus = "Authorized"
            @unknown default:
                healthKitAuthorizationStatus = "Unknown"
            }
        }
    }

    func requestHealthKitAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthKitError = "Health data is not available on this device"
            return
        }

        isRequestingHealthKitAuthorization = true
        healthKitError = nil

        do {
            let healthStore = HKHealthStore()
            let readTypes: Set<HKSampleType> = {
                var types: Set<HKSampleType> = []
                if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { types.insert(hrv) }
                if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) { types.insert(heartRate) }
                if let restingHR = HKObjectType.quantityType(forIdentifier: .restingHeartRate) { types.insert(restingHR) }
                if let respiratoryRate = HKObjectType.quantityType(forIdentifier: .respiratoryRate) { types.insert(respiratoryRate) }
                if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) { types.insert(steps) }
                if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
                return types
            }()

            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            refreshHealthKitStatus()
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
        gptAPIStatus = "Saving..."
        isGPTAPIWorking = false
        do {
            try llmGateway.setAPIKey(key)
            gptAPIStatus = "Testing..."
            let ok = try await llmGateway.testAPIConnection()
            isGPTAPIWorking = ok
            gptAPIStatus = ok ? "OpenAI reachable" : "OpenAI ping failed"
        } catch {
            isGPTAPIWorking = false
            gptAPIStatus = "Missing or invalid API key"
        }
    }

    @MainActor
    func checkGPTAPIKey() async {
        // Route through the same unified path
        await saveAPIKeyAndTest(gptAPIKeyDraft)
    }

    func makeScoreBreakdownViewModel() -> ScoreBreakdownViewModel? {
        guard let orchestrator else { return nil }
        return ScoreBreakdownViewModel(orchestrator: orchestrator)
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
