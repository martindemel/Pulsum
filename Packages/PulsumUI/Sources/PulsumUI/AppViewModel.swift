import Foundation
import CoreData
import Observation
import PulsumAgents
import PulsumData
import PulsumTypes
#if canImport(HealthKit)
import HealthKit
#endif
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
final class AppViewModel {
    enum StartupState: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
        case blocked(String)
    }

    enum Tab: String, CaseIterable, Identifiable, Hashable {
        case main
        case insights
        case coach

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .main: return "Main"
            case .insights: return "Insights"
            case .coach: return "Coach"
            }
        }

        var iconName: String {
            switch self {
            case .main: return "gauge.with.needle"
            case .insights: return "lightbulb"
            case .coach: return "text.bubble"
            }
        }
    }

    private let consentStore: ConsentStore
    @ObservationIgnored private(set) var orchestrator: AgentOrchestrator?
    @ObservationIgnored private let observerBag = NotificationObserverBag()

    var startupState: StartupState = .idle
    var selectedTab: Tab = .main
    var isPresentingPulse = false
    var isPresentingSettings = false
    var isShowingSafetyCard = false
    var safetyMessage: String?
    var showOnboarding = false

    var consentGranted: Bool
    var shouldHideConsentBanner = false
    var showConsentBanner: Bool { !consentGranted && !shouldHideConsentBanner }

    let coachViewModel: CoachViewModel
    let pulseViewModel: PulseViewModel
    let settingsViewModel: SettingsViewModel
    private let startupTraceId = UUID()
    private var didEmitFirstRunStart = false
    private var didEmitFirstRunEnd = false
    private let firstLaunch: Bool
    private let sessionInfo: (version: String, build: String)
    private let firstRunReasonAllowlist: Set<String> = [
        "blocked",
        "ready",
        "failed",
        "health_unavailable",
        "background_delivery_ignored",
        "embeddings_pending",
        "health_backfill_running",
        "library_index_deferred",
        "journal_embeddings_pending",
        "unknown"
    ]
    #if DEBUG
    private var isRunningUnderXCTest: Bool {
        let env = ProcessInfo.processInfo.environment
        return env.keys.contains("XCTestConfigurationFilePath") || env.keys.contains("XCTestBundlePath")
    }
    #endif

    init(consentStore: ConsentStore = ConsentStore(),
         userDefaults: UserDefaults = AppRuntimeConfig.runtimeDefaults,
         sessionInfo: (version: String, build: String) = AppViewModel.makeVersionInfo()) {
        let consent = consentStore.loadConsent()
        let launchKey = "ai.pulsum.hasLaunched"
        let hasLaunched = userDefaults.bool(forKey: launchKey)
        let coachVM = CoachViewModel()
        let pulseVM = PulseViewModel()
        let settingsVM = SettingsViewModel(initialConsent: consent)

        self.consentStore = consentStore
        self.consentGranted = consent
        self.sessionInfo = sessionInfo
        self.firstLaunch = !hasLaunched
        userDefaults.set(true, forKey: launchKey)
        self.coachViewModel = coachVM
        self.pulseViewModel = pulseVM
        self.settingsViewModel = settingsVM
        if AppRuntimeConfig.hideConsentBanner {
            self.shouldHideConsentBanner = true
        }
        #if canImport(UIKit)
        if AppRuntimeConfig.disableAnimations {
            UIView.setAnimationsEnabled(false)
        }
        #endif

        settingsVM.onConsentChanged = { [weak self] newValue in
            guard let self else { return }
            self.updateConsent(to: newValue)
        }

        settingsVM.onDataDeleted = { [weak self] in
            guard let self else { return }
            self.showOnboarding = true
            self.isPresentingSettings = false
        }

        pulseVM.onSafetyDecision = { [weak self] decision in
            guard let self else { return }
            if !decision.allowCloud, case .crisis = decision.classification {
                self.safetyMessage = decision.crisisMessage ?? "If in danger, call 911"
                self.isShowingSafetyCard = true
            }
        }

        let scoreRefreshObserver = NotificationCenter.default.addObserver(forName: .pulsumScoresUpdated,
                                                                          object: nil,
                                                                          queue: .main) { [weak self] _ in
            guard let self else { return }
            Task { [weak self] in
                await self?.coachViewModel.refreshRecommendations()
            }
        }
        observerBag.add(scoreRefreshObserver)

        #if canImport(UIKit)
        let appActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                                                       object: nil,
                                                                       queue: .main) { [weak self] _ in
            Diagnostics.log(level: .info,
                            category: .app,
                            name: "app.lifecycle.didBecomeActive",
                            traceId: self?.startupTraceId)
            Task { @MainActor [weak self] in
                self?.refreshOnForeground()
            }
        }
        observerBag.add(appActiveObserver)
        let appBackgroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                                                           object: nil,
                                                                           queue: .main) { [weak self] _ in
            Diagnostics.log(level: .info,
                            category: .app,
                            name: "app.lifecycle.didEnterBackground",
                            traceId: self?.startupTraceId)
        }
        observerBag.add(appBackgroundObserver)
        #endif

        logSessionStart()
        Task { await DebugLogBuffer.shared.append("AppViewModel.init invoked") }
    }

    func start() {
        guard startupState == .idle else { return }
        #if DEBUG
        if isRunningUnderXCTest && !AppRuntimeConfig.isUITesting {
            startupState = .ready
            return
        }
        #endif
        emitFirstRunStartIfNeeded()
        if AppRuntimeConfig.skipHeavyStartupWork {
            startupState = .ready
            Task { await DebugLogBuffer.shared.append("Startup: UITest mode, skipping orchestrator bootstrap") }
            emitFirstRunEnd(fields: [
                "reason": .safeString(.stage("ready",
                                             allowed: firstRunReasonAllowlist))
            ])
            return
        }
        if let error = PulsumData.initializationError {
            startupState = .failed(error.localizedDescription)
            Task { await DebugLogBuffer.shared.append("Startup failed: DataStack initialization error: \(error.localizedDescription)") }
            emitFirstRunEnd(fields: [
                "reason": .safeString(.stage("failed",
                                             allowed: firstRunReasonAllowlist))
            ], error: error)
            return
        }
        if let issue = PulsumData.backupSecurityIssue {
            let location = issue.url.lastPathComponent
            startupState = .blocked("Storage is not secured for backup (directory: \(location)). \(issue.reason)")
            Task { await DebugLogBuffer.shared.append("Startup blocked: \(issue.reason)") }
            emitFirstRunEnd(fields: [
                "reason": .safeString(.stage("blocked",
                                             allowed: firstRunReasonAllowlist)),
                "directory": .safeString(.metadata(location))
            ])
            return
        }
        startupState = .loading
        Task { [weak self] in
            guard let self else { return }
            do {
                Diagnostics.log(level: .info,
                                category: .app,
                                name: "app.orchestrator.create.begin",
                                traceId: startupTraceId)
                let orchestrator = try PulsumAgents.makeOrchestrator()
                Diagnostics.log(level: .info,
                                category: .app,
                                name: "app.orchestrator.create.end",
                                traceId: startupTraceId)
                self.orchestrator = orchestrator
                self.coachViewModel.bind(orchestrator: orchestrator, consentProvider: { [weak self] in
                    self?.consentGranted ?? false
                })
                self.pulseViewModel.bind(orchestrator: orchestrator)
                self.settingsViewModel.bind(orchestrator: orchestrator)
                self.settingsViewModel.refreshFoundationStatus()
                Diagnostics.log(level: .info,
                                category: .ui,
                                name: "timeline.firstRun.checkpoint",
                                fields: [
                                    "stage": .safeString(.stage("orchestrator_bound", allowed: ["orchestrator_bound"]))
                                ],
                                traceId: startupTraceId)
                self.startupState = .ready

                Task { [weak self] in
                    guard let self else { return }
                    let startSpan = Diagnostics.span(category: .orchestrator,
                                                     name: "orchestrator.start.call",
                                                     traceId: startupTraceId)
                    do {
                        try await orchestrator.start(traceId: startupTraceId)
                        startSpan.end(error: nil)
                        self.settingsViewModel.refreshHealthAccessStatus()
                        await self.coachViewModel.refreshRecommendations()
                        if let deferred = analysisDeferredFields(from: await orchestrator.diagnosticsSnapshot()) {
                            var fields = deferred.fields
                            fields["reason"] = .safeString(deferred.reason)
                            Diagnostics.log(level: .info,
                                            category: .ui,
                                            name: "ui.analysis.deferred",
                                            fields: fields,
                                            traceId: startupTraceId)
                            emitFirstRunEnd(fields: fields)
                        } else {
                            emitFirstRunEnd(fields: [
                                "reason": .safeString(.stage("ready",
                                                             allowed: firstRunReasonAllowlist))
                            ])
                        }
                        await DebugLogBuffer.shared.append("Orchestrator start complete; recommendations refreshed")
                    } catch {
                        Diagnostics.log(level: .error,
                                        category: .app,
                                        name: "orchestrator.start.failed",
                                        traceId: startupTraceId,
                                        error: error)
                        startSpan.end(error: error)
                        await DebugLogBuffer.shared.append("Orchestrator start failed")
                        if let startupError = error as? OrchestratorStartupError {
                            switch startupError {
                            case .healthDataUnavailable:
                                await DebugLogBuffer.shared.append("HealthDataUnavailable during start")
                                emitFirstRunEnd(fields: [
                                    "reason": .safeString(.stage("health_unavailable",
                                                                 allowed: firstRunReasonAllowlist))
                                ])
                                return
                            case let .healthBackgroundDeliveryMissing(underlying):
                                if shouldIgnoreBackgroundDeliveryError(underlying) {
                                    await DebugLogBuffer.shared.append("Background delivery missing but ignored")
                                    emitFirstRunEnd(fields: [
                                        "reason": .safeString(.stage("background_delivery_ignored",
                                                                     allowed: firstRunReasonAllowlist)),
                                        "background_delivery_missing": .bool(true)
                                    ])
                                    return
                                }
                            }
                        }
                        self.startupState = .failed(error.localizedDescription)
                        emitFirstRunEnd(fields: [
                            "reason": .safeString(.stage("failed",
                                                         allowed: firstRunReasonAllowlist))
                        ], error: error)
                    }
                }
            } catch {
                Diagnostics.log(level: .error,
                                category: .app,
                                name: "app.orchestrator.create.failed",
                                traceId: startupTraceId,
                                error: error)
                await DebugLogBuffer.shared.append("Failed to create orchestrator")
                self.startupState = .failed(error.localizedDescription)
                emitFirstRunEnd(fields: [
                    "reason": .safeString(.stage("failed",
                                                 allowed: firstRunReasonAllowlist))
                ], error: error)
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

    func completeOnboarding() {
        showOnboarding = false
    }

    func dismissSafetyCard() {
        isShowingSafetyCard = false
        safetyMessage = nil
    }

    private func refreshOnForeground() {
        guard startupState == .ready, let orchestrator else { return }
        Task {
            await orchestrator.refreshOnDeviceModelAvailabilityAndRetryDeferredWork(traceId: startupTraceId)
        }
    }
}

private final class NotificationObserverBag {
    private var tokens: [NSObjectProtocol] = []

    func add(_ token: NSObjectProtocol) {
        tokens.append(token)
    }

    deinit {
        for token in tokens {
            NotificationCenter.default.removeObserver(token)
        }
    }
}

private func shouldIgnoreBackgroundDeliveryError(_ error: Error) -> Bool {
    (error as NSError).localizedDescription.contains("Missing com.apple.developer.healthkit.background-delivery")
}

private extension AppViewModel {
    func logSessionStart() {
        let locale = Locale.current.identifier
        #if canImport(UIKit)
        let deviceModel = UIDevice.current.model
        let osVersion = UIDevice.current.systemVersion
        let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        #else
        let deviceModel = "mac"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let lowPower = false
        #endif
        Diagnostics.log(level: .info,
                        category: .app,
                        name: "app.session.start",
                        fields: [
                            "app_version": .safeString(.metadata(sessionInfo.version)),
                            "build_number": .safeString(.metadata(sessionInfo.build)),
                            "device_model": .safeString(.metadata(deviceModel)),
                            "os_version": .safeString(.metadata(osVersion)),
                            "locale": .safeString(.metadata(locale)),
                            "low_power_mode": .bool(lowPower),
                            "first_launch": .bool(firstLaunch)
                        ],
                        traceId: startupTraceId)
    }

    static func makeVersionInfo() -> (String, String) {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        return (version, build)
    }

    func analysisDeferredFields(from snapshot: DiagnosticsSnapshot) -> (reason: DiagnosticsSafeString, fields: [String: DiagnosticsValue])? {
        let reasonAllowlist: Set<String> = ["embeddings_pending", "health_backfill_running", "library_index_deferred", "journal_embeddings_pending", "unknown"]
        let embeddingsAvailable = snapshot.embeddingsAvailable ?? false
        let pendingJournals = snapshot.pendingJournalsCount ?? 0
        let warmCompleted = snapshot.backfillWarmCompleted ?? 0
        let fullCompleted = snapshot.backfillFullCompleted ?? 0
        let deferredLibraryImport = snapshot.deferredLibraryImport ?? false
        let expectedTypes = snapshot.healthGrantedCount ?? 0
        let baseFields: [String: DiagnosticsValue] = [
            "pending_journals": .int(pendingJournals),
            "backfill_warm_completed": .int(warmCompleted),
            "backfill_full_completed": .int(fullCompleted),
            "embeddings_available": .bool(embeddingsAvailable),
            "deferred_library_import": .bool(deferredLibraryImport)
        ]
        if !embeddingsAvailable {
            return (.stage("embeddings_pending", allowed: reasonAllowlist), baseFields)
        }
        if pendingJournals > 0 {
            return (.stage("journal_embeddings_pending", allowed: reasonAllowlist), baseFields)
        }
        if deferredLibraryImport {
            return (.stage("library_index_deferred", allowed: reasonAllowlist), baseFields)
        }
        if warmCompleted < expectedTypes || fullCompleted < expectedTypes {
            return (.stage("health_backfill_running", allowed: reasonAllowlist), baseFields)
        }
        return nil
    }

    func emitFirstRunStartIfNeeded() {
        guard !didEmitFirstRunStart else { return }
        Diagnostics.log(level: .info,
                        category: .app,
                        name: "timeline.firstRun.start",
                        traceId: startupTraceId)
        didEmitFirstRunStart = true
    }

    func emitFirstRunEnd(fields: [String: DiagnosticsValue], error: Error? = nil) {
        guard !didEmitFirstRunEnd else { return }
        let level: DiagnosticsLevel = error == nil ? .info : .error
        Diagnostics.log(level: level,
                        category: .app,
                        name: "timeline.firstRun.end",
                        fields: fields,
                        traceId: startupTraceId,
                        error: error)
        didEmitFirstRunEnd = true
    }
}

@MainActor
struct ConsentStore {
    private let contextProvider: () -> NSManagedObjectContext
    private static let recordID = "default"
    private static let consentDefaultsKey = "ai.pulsum.cloudConsent"
    private let consentVersion: String

    init(contextProvider: @escaping () -> NSManagedObjectContext = { PulsumData.viewContext },
         consentVersion: String = ConsentStore.defaultConsentVersion()) {
        self.contextProvider = contextProvider
        self.consentVersion = consentVersion
    }

    private var context: NSManagedObjectContext { contextProvider() }

    private var defaults: UserDefaults {
        AppRuntimeConfig.runtimeDefaults
    }

    func loadConsent() -> Bool {
        let defaults = defaults
        if defaults.object(forKey: Self.consentDefaultsKey) != nil {
            return defaults.bool(forKey: Self.consentDefaultsKey)
        }
        if AppRuntimeConfig.isUITesting {
            return false
        }
        let request = UserPrefs.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", Self.recordID)
        if let existing = try? context.fetch(request).first {
            defaults.set(existing.consentCloud, forKey: Self.consentDefaultsKey)
            return existing.consentCloud
        }
        return false
    }

    func saveConsent(_ granted: Bool) {
        let defaults = defaults
        defaults.set(granted, forKey: Self.consentDefaultsKey)
        AppRuntimeConfig.synchronizeUITestDefaults()
        if AppRuntimeConfig.isUITesting {
            return
        }
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
            persistConsentHistory(granted: granted)
            try context.save()
        } catch {
            context.rollback()
        }
    }

    private func persistConsentHistory(granted: Bool) {
        let request = ConsentState.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "version == %@", consentVersion)

        let record: ConsentState
        if let existing = try? context.fetch(request).first {
            record = existing
        } else {
            record = ConsentState(context: context)
            record.id = UUID()
            record.version = consentVersion
        }

        let timestamp = Date()
        if granted {
            record.grantedAt = timestamp
            record.revokedAt = nil
        } else {
            if record.grantedAt == nil {
                record.grantedAt = timestamp
            }
            record.revokedAt = timestamp
        }
    }

    private static func defaultConsentVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }
}
