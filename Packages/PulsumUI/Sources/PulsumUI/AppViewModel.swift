import Foundation
import CoreData
import Observation
import PulsumAgents
import PulsumData
import PulsumServices
#if canImport(HealthKit)
import HealthKit
#endif

@MainActor
@Observable
final class AppViewModel {
    enum StartupState: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
    }

    enum Tab: String, CaseIterable, Identifiable {
        case main
        case coach

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .main: return "Main"
            case .coach: return "Coach"
            }
        }

        var iconName: String {
            switch self {
            case .main: return "gauge.with.needle"
            case .coach: return "text.bubble"
            }
        }
    }

    private let consentStore = ConsentStore()
    @ObservationIgnored private(set) var orchestrator: AgentOrchestrator?

    var startupState: StartupState = .idle
    var selectedTab: Tab = .main
    var isPresentingPulse = false
    var isPresentingSettings = false
    var isShowingSafetyCard = false
    var safetyMessage: String?

    var consentGranted: Bool
    var shouldHideConsentBanner = false
    var showConsentBanner: Bool { !consentGranted && !shouldHideConsentBanner }

    let coachViewModel: CoachViewModel
    let pulseViewModel: PulseViewModel
    let settingsViewModel: SettingsViewModel

    init() {
        let consent = consentStore.loadConsent()
        self.consentGranted = consent

        let coachVM = CoachViewModel()
        let pulseVM = PulseViewModel()
        let settingsVM = SettingsViewModel(initialConsent: consent)

        self.coachViewModel = coachVM
        self.pulseViewModel = pulseVM
        self.settingsViewModel = settingsVM

        settingsVM.onConsentChanged = { [weak self] newValue in
            guard let self else { return }
            self.updateConsent(to: newValue)
        }

        pulseVM.onSafetyDecision = { [weak self] decision in
            guard let self else { return }
            if !decision.allowCloud, case .crisis = decision.classification {
                self.safetyMessage = decision.crisisMessage ?? "If in danger, call 911"
                self.isShowingSafetyCard = true
            }
        }
    }

    func start() {
        guard startupState == .idle else { return }
        startupState = .loading
        Task { [weak self] in
            guard let self else { return }
            do {
                print("[Pulsum] Attempting to make orchestrator")
                let orchestrator = try PulsumAgents.makeOrchestrator()
                print("[Pulsum] Orchestrator created")
                self.orchestrator = orchestrator
                self.coachViewModel.bind(orchestrator: orchestrator, consentProvider: { [weak self] in
                    self?.consentGranted ?? false
                })
                print("[Pulsum] CoachViewModel bound")
                self.pulseViewModel.bind(orchestrator: orchestrator)
                print("[Pulsum] PulseViewModel bound")
                self.settingsViewModel.bind(orchestrator: orchestrator)
                self.settingsViewModel.refreshFoundationStatus()
                print("[Pulsum] SettingsViewModel bound and foundation status refreshed")
                self.startupState = .ready
                print("[Pulsum] Startup state set to ready")

                Task { [weak self] in
                    guard let self else { return }
                    do {
                        print("[Pulsum] Starting orchestrator start()")
                        try await orchestrator.start()
                        print("[Pulsum] Orchestrator start() completed")
                        await self.coachViewModel.refreshRecommendations()
                        print("[Pulsum] Recommendations refreshed")
                    } catch {
                        print("[Pulsum] Orchestrator start failed: \(error)")
                        if let healthError = error as? HealthKitServiceError,
                           case .healthDataUnavailable = healthError {
                            // Expected on simulators or devices without HealthKit; continue without blocking UI.
                            return
                        }
                        if let healthError = error as? HealthKitServiceError,
                           case let .backgroundDeliveryFailed(_, underlying) = healthError,
                           shouldIgnoreBackgroundDeliveryError(underlying) {
                            return
                        }
                        self.startupState = .failed(error.localizedDescription)
                    }
                }
            } catch {
                print("[Pulsum] Failed to create orchestrator: \(error)")
                self.startupState = .failed(error.localizedDescription)
            }
        }
    }

    func retryStartup() {
        startupState = .idle
        start()
    }

    func updateConsent(to newValue: Bool) {
        consentGranted = newValue
        consentStore.saveConsent(newValue)
        coachViewModel.updateConsent(newValue)
        settingsViewModel.refreshConsent(newValue)
        Task { [weak self] in
            await self?.coachViewModel.refreshRecommendations()
        }
    }

    func triggerCoachFocus() {
        selectedTab = .coach
        coachViewModel.requestChatFocus()
    }

    func dismissConsentBanner() {
        shouldHideConsentBanner = true
    }

    func handleRecommendationCompletion(_ card: RecommendationCard) {
        Task { [weak self] in
            guard let self, let orchestrator else { return }
            await coachViewModel.complete(card: card, orchestrator: orchestrator)
        }
    }

    func dismissSafetyCard() {
        isShowingSafetyCard = false
        safetyMessage = nil
    }
}

private func shouldIgnoreBackgroundDeliveryError(_ error: Error) -> Bool {
    (error as NSError).localizedDescription.contains("Missing com.apple.developer.healthkit.background-delivery")
}

@MainActor
struct ConsentStore {
    private let context = PulsumData.viewContext
    private static let recordID = "default"

    func loadConsent() -> Bool {
        let request = UserPrefs.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", Self.recordID)
        if let existing = try? context.fetch(request).first {
            return existing.consentCloud
        }
        return false
    }

    func saveConsent(_ granted: Bool) {
        let request = UserPrefs.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", Self.recordID)
        let prefs: UserPrefs
        if let existing = try? context.fetch(request).first {
            prefs = existing
        } else {
            prefs = UserPrefs(context: context)
            prefs.id = Self.recordID
        }
        prefs.consentCloud = granted
        prefs.updatedAt = Date()
        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }
}
