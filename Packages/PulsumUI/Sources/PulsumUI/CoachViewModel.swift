import Foundation
import Observation
import os
import PulsumAgents
#if canImport(FoundationModels) && os(iOS)
import FoundationModels
#endif
import PulsumTypes

protocol CoachOrchestrating: AnyObject, Sendable {
    func wellbeingSnapshotState(consentGranted: Bool) async throws -> WellbeingSnapshotResponse
    func recommendations(consentGranted: Bool) async throws -> RecommendationResponse
    func logCompletion(momentId: String) async throws -> CheerEvent
    func chat(userInput: String, consentGranted: Bool) async throws -> String
}

extension AgentOrchestrator: CoachOrchestrating {}

@MainActor
@Observable
final class CoachViewModel {
    struct ChatMessage: Identifiable, Equatable {
        enum Role {
            case user
            case assistant
            case system
        }

        let id = UUID()
        let role: Role
        let text: String
        let timestamp: Date
    }

    enum WellbeingNoticeTone: Equatable {
        case neutral
        case warning
    }

    struct WellbeingNotice: Equatable {
        let icon: String
        let text: String
        let tone: WellbeingNoticeTone
    }

    @ObservationIgnored private var orchestrator: (any CoachOrchestrating)?
    @ObservationIgnored private var consentProvider: () -> Bool = { false }
    private let recommendationsDebounceNanoseconds: UInt64
    private let recommendationsSoftTimeoutSeconds: Double
    @ObservationIgnored private let softTimeoutSleep: @Sendable (UInt64) async throws -> Void

    var recommendations: [RecommendationCard] = []
    var wellbeingScore: Double?
    var contributions: [String: Double] = [:]
    var wellbeingState: WellbeingScoreState = .loading
    private var hasLoadedWellbeing = false
    var snapshotKind: WellbeingSnapshotKind = .none

    var isLoadingCards = false
    var cardErrorMessage: String?

    var messages: [ChatMessage] = []
    var chatInput: String = ""
    var isSendingChat = false
    var chatErrorMessage: String?

    var cheerEventMessage: String?
    var lastCheerDate: Date?

    private(set) var consentGranted: Bool = false
    var chatFocusToken = UUID()
    @ObservationIgnored private let logger = Logger(subsystem: "com.pulsum", category: "CoachViewModel")
    private var lastWellbeingState: WellbeingScoreState = .loading
    private var refreshSequence = 0
    @ObservationIgnored private var recommendationsTask: Task<Void, Never>?
    @ObservationIgnored private var recommendationsDebounceTask: Task<Void, Never>?
    private var recommendationsPending = false
    private var recommendationsCoalesced = false
    @ObservationIgnored private var recommendationsSoftTimeoutTask: Task<Void, Never>?
    private var recommendationsSoftTimedOut = false
    private var activeRecommendationsRefreshID: Int?
    @ObservationIgnored private var reloadTask: Task<Void, Never>?
    @ObservationIgnored private var cheerResetTask: Task<Void, Never>?

    var recommendationsSoftTimeoutMessage: String?

    var wellbeingNotice: WellbeingNotice? {
        switch wellbeingState {
        case let .noData(reason):
            if snapshotKind == .placeholder, reason == .insufficientSamples {
                return WellbeingNotice(icon: "clock",
                                       text: "Warming up... Health data may take a moment on first run.",
                                       tone: .neutral)
            }
            return WellbeingNotice(icon: "exclamationmark.triangle",
                                   text: noDataMessage(for: reason),
                                   tone: .warning)
        case .error:
            return WellbeingNotice(icon: "exclamationmark.triangle",
                                   text: "We couldn't compute your wellbeing score yet. Try again after enabling Health access or adding data.",
                                   tone: .warning)
        default:
            return nil
        }
    }

    init(recommendationsDebounceNanoseconds: UInt64 = 750_000_000,
         recommendationsSoftTimeoutSeconds: Double = 9,
         softTimeoutSleep: @escaping @Sendable (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) }) {
        self.recommendationsDebounceNanoseconds = recommendationsDebounceNanoseconds
        self.recommendationsSoftTimeoutSeconds = recommendationsSoftTimeoutSeconds
        self.softTimeoutSleep = softTimeoutSleep
    }

    func bind(orchestrator: any CoachOrchestrating, consentProvider: @escaping () -> Bool) {
        self.orchestrator = orchestrator
        self.consentProvider = consentProvider
        self.consentGranted = consentProvider()
    }

    func refreshRecommendations() async {
        guard let orchestrator else { return }
        consentGranted = consentProvider()
        let refreshID = nextRefreshID()
        if !hasLoadedWellbeing {
            let previous = wellbeingState
            wellbeingState = .loading
            snapshotKind = .none
            logWellbeingTransition(from: previous, to: wellbeingState, reason: "loading")
            cardErrorMessage = nil
        }
        do {
            let snapshot = try await orchestrator.wellbeingSnapshotState(consentGranted: consentProvider())
            guard refreshID == refreshSequence else { return }
            applyWellbeingState(snapshot.wellbeingState,
                                snapshotKind: snapshot.snapshotKind,
                                reason: "snapshot")
            logWellbeingSnapshotUpdate(snapshot, refreshID: refreshID)
        } catch is CancellationError {
            logger.debug("Wellbeing snapshot refresh cancelled.")
            return
        } catch {
            let previous = wellbeingState
            wellbeingState = .error(message: "Unable to compute wellbeing right now.")
            snapshotKind = .none
            logWellbeingTransition(from: previous, to: wellbeingState, reason: "error")
            wellbeingScore = nil
            contributions = [:]
            hasLoadedWellbeing = true
            lastWellbeingState = wellbeingState
        }
        if Task.isCancelled { return }
        scheduleRecommendationsRefresh()
        await Task.yield()
    }

    func updateConsent(_ granted: Bool) {
        consentGranted = granted
    }

    func requestChatFocus() {
        chatFocusToken = UUID()
    }

    func reloadIfNeeded() {
        reloadTask?.cancel()
        reloadTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshRecommendations()
        }
    }

    func complete(card: RecommendationCard, orchestrator: any CoachOrchestrating) async {
        do {
            let event = try await orchestrator.logCompletion(momentId: card.id)
            let message = "\(event.message)"
            cheerEventMessage = message
            lastCheerDate = Date()
            scheduleCheerReset()
            await refreshRecommendations()
        } catch {
            cheerEventMessage = "Couldn't log completion. Please try again later."
            scheduleCheerReset()
        }
    }

    func markCardComplete(_ card: RecommendationCard) async {
        guard let orchestrator else { return }
        await complete(card: card, orchestrator: orchestrator)
    }

    func sendChat() async {
        let trimmed = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        logger.debug("Sending chat message. Characters: \(trimmed.count, privacy: .public)")
        let userMessage = ChatMessage(role: .user, text: trimmed, timestamp: Date())
        messages.append(userMessage)
        chatInput = ""
        chatErrorMessage = nil
        isSendingChat = true
        defer { isSendingChat = false }
        guard let orchestrator else {
            if AppRuntimeConfig.useStubLLM {
                let assistant = ChatMessage(role: .assistant,
                                            text: "Stub response: Pulsum coach stub reply for UI testing.",
                                            timestamp: Date())
                messages.append(assistant)
            } else {
                chatErrorMessage = "Coach is unavailable right now."
            }
            return
        }
        do {
            let response = try await orchestrator.chat(userInput: trimmed, consentGranted: consentProvider())
            let assistant = ChatMessage(role: .assistant, text: response, timestamp: Date())
            messages.append(assistant)
            logger.debug("Chat response appended. Characters: \(response.count, privacy: .public)")
        } catch {
            chatErrorMessage = mapError(error)
            let nsError = error as NSError
            logger.error("Chat send failed. domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)")
        }
    }

    private func mapError(_ error: Error) -> String {
        #if canImport(FoundationModels) && os(iOS)
        if #available(iOS 26.0, *), let generationError = error as? LanguageModelSession.GenerationError {
            switch generationError {
            case .guardrailViolation:
                return "Let's keep the focus on supportive wellness actions"
            case .refusal:
                return "Unable to process that request. Try rephrasing."
            default:
                break
            }
        }
        #endif
        if (error as NSError).domain == NSURLErrorDomain {
            return "Network connection appears offline."
        }
        return error.localizedDescription
    }

    private func noDataMessage(for reason: WellbeingNoDataReason) -> String {
        switch reason {
        case .healthDataUnavailable:
            return "Health data isn't available on this device. Try on a device with Health access."
        case .permissionsDeniedOrPending:
            return "Health permissions are needed to personalize picks. Enable Health data in Settings."
        case .insufficientSamples:
            return "We're waiting for enough Health data to personalize your picks."
        }
    }

    private func scheduleCheerReset() {
        cheerResetTask?.cancel()
        cheerResetTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard let self else { return }
            cheerEventMessage = nil
        }
    }

    private func logWellbeingTransition(from: WellbeingScoreState, to: WellbeingScoreState, reason: String) {
        let allowedStates: Set<String> = ["loading", "ready", "no_data", "error"]
        let allowedReasons: Set<String> = ["refresh", "snapshot", "error", "loading", "unknown"]
        Diagnostics.log(level: .info,
                        category: .ui,
                        name: "ui.wellbeingState.transition",
                        fields: [
                            "from": .safeString(.stage(label(for: from), allowed: allowedStates)),
                            "to": .safeString(.stage(label(for: to), allowed: allowedStates)),
                            "reason": .safeString(.stage(reason, allowed: allowedReasons)),
                            "has_snapshot": .bool(snapshotKind == .real)
                        ])
    }

    private func label(for state: WellbeingScoreState) -> String {
        switch state {
        case .loading: return "loading"
        case .ready: return "ready"
        case .noData: return "no_data"
        case .error: return "error"
        }
    }

    private func nextRefreshID() -> Int {
        refreshSequence += 1
        return refreshSequence
    }

    private func applyWellbeingState(_ state: WellbeingScoreState,
                                     snapshotKind: WellbeingSnapshotKind,
                                     reason: String) {
        let previous = wellbeingState
        wellbeingState = state
        self.snapshotKind = snapshotKind
        logWellbeingTransition(from: previous, to: wellbeingState, reason: reason)
        switch state {
        case let .ready(score, contributions):
            wellbeingScore = score
            self.contributions = contributions
        default:
            wellbeingScore = nil
            contributions = [:]
        }
        hasLoadedWellbeing = true
        lastWellbeingState = wellbeingState
    }

    private func logWellbeingSnapshotUpdate(_ snapshot: WellbeingSnapshotResponse, refreshID: Int) {
        let allowedStates: Set<String> = ["loading", "ready", "no_data", "error"]
        let allowedSnapshotKinds: Set<String> = ["none", "placeholder", "real"]
        let hasRealSnapshot = snapshot.snapshotKind == .real
        var fields: [String: DiagnosticsValue] = [
            "refresh_id": .int(refreshID),
            "state": .safeString(.stage(label(for: snapshot.wellbeingState), allowed: allowedStates)),
            "snapshot_kind": .safeString(.stage(snapshot.snapshotKind.rawValue,
                                                allowed: allowedSnapshotKinds)),
            "has_snapshot": .bool(hasRealSnapshot),
            "score_present": .bool(hasRealSnapshot)
        ]
        if let dayString = snapshot.dayString {
            fields["day"] = .safeString(.metadata(dayString))
        }
        Diagnostics.log(level: .info,
                        category: .ui,
                        name: "ui.wellbeing.snapshot.update",
                        fields: fields)
    }

    private func scheduleRecommendationsRefresh() {
        if recommendationsTask != nil {
            recommendationsPending = true
            recommendationsCoalesced = true
            updateRecommendationsLoadingState()
            return
        }

        if recommendationsDebounceTask != nil {
            recommendationsCoalesced = true
        }

        if recommendationsDebounceNanoseconds == 0 {
            recommendationsDebounceTask?.cancel()
            recommendationsDebounceTask = nil
            startRecommendationsRefresh()
            updateRecommendationsLoadingState()
            return
        }

        recommendationsDebounceTask?.cancel()
        let debounceNanoseconds = recommendationsDebounceNanoseconds
        recommendationsDebounceTask = Task { [weak self] in
            guard let self else { return }
            defer {
                self.recommendationsDebounceTask = nil
                self.updateRecommendationsLoadingState()
            }
            if debounceNanoseconds > 0 {
                do {
                    try await Task.sleep(nanoseconds: debounceNanoseconds)
                } catch {
                    return
                }
            }
            self.startRecommendationsRefresh()
        }
        updateRecommendationsLoadingState()
    }

    private func startRecommendationsRefresh() {
        guard recommendationsTask == nil else { return }
        guard let orchestrator else {
            updateRecommendationsLoadingState()
            return
        }
        let refreshID = refreshSequence
        let coalesced = recommendationsCoalesced
        recommendationsCoalesced = false
        cardErrorMessage = nil
        resetRecommendationsSoftTimeout()
        activeRecommendationsRefreshID = refreshID

        let span = Diagnostics.span(category: .ui,
                                    name: "ui.recommendations.refresh",
                                    fields: [
                                        "refresh_id": .int(refreshID),
                                        "coalesced": .bool(coalesced)
                                    ],
                                    level: .info)

        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            defer {
                self.recommendationsTask = nil
                self.activeRecommendationsRefreshID = nil
                self.resetRecommendationsSoftTimeout()
                if self.recommendationsPending {
                    self.recommendationsPending = false
                    self.scheduleRecommendationsRefresh()
                } else {
                    self.updateRecommendationsLoadingState()
                }
            }
            let resultAllowlist: Set<String> = ["applied", "stale", "failed", "cancelled"]
            do {
                let response = try await orchestrator.recommendations(consentGranted: consentProvider())
                try Task.checkCancellation()
                let isStale = refreshID != self.refreshSequence
                let shouldApply = !isStale || self.recommendations.isEmpty
                if shouldApply {
                    self.recommendations = response.cards
                    self.cardErrorMessage = response.notice
                    self.resetRecommendationsSoftTimeout()
                }
                span.end(additionalFields: [
                    "result": .safeString(.stage(isStale ? "stale" : "applied", allowed: resultAllowlist)),
                    "cards_count": .int(response.cards.count)
                ], error: nil)
            } catch is CancellationError {
                span.end(additionalFields: [
                    "result": .safeString(.stage("cancelled", allowed: resultAllowlist))
                ], error: nil)
            } catch {
                if refreshID == self.refreshSequence {
                    self.cardErrorMessage = mapError(error)
                }
                span.end(additionalFields: [
                    "result": .safeString(.stage("failed", allowed: resultAllowlist))
                ], error: error)
            }
        }

        recommendationsTask = task
        beginRecommendationsSoftTimeout(for: refreshID)
        updateRecommendationsLoadingState()
    }

    private func updateRecommendationsLoadingState() {
        let isBusy = recommendationsTask != nil
            || recommendationsPending
            || recommendationsDebounceTask != nil
        isLoadingCards = isBusy && !recommendationsSoftTimedOut
    }

    private func beginRecommendationsSoftTimeout(for refreshID: Int) {
        recommendationsSoftTimeoutTask?.cancel()
        guard recommendationsSoftTimeoutSeconds > 0 else { return }
        let timeoutNanos = UInt64(max(0, recommendationsSoftTimeoutSeconds) * 1_000_000_000)
        recommendationsSoftTimeoutTask = Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            do {
                try await self.softTimeoutSleep(timeoutNanos)
            } catch {
                return
            }
            await MainActor.run {
                guard self.recommendationsTask != nil else { return }
                guard self.activeRecommendationsRefreshID == refreshID else { return }
                self.recommendationsSoftTimedOut = true
                self.recommendationsSoftTimeoutMessage = "Recommendations are taking longer than expected. We'll show them here as soon as they're ready."
                self.updateRecommendationsLoadingState()
            }
        }
    }

    private func resetRecommendationsSoftTimeout() {
        recommendationsSoftTimeoutTask?.cancel()
        recommendationsSoftTimeoutTask = nil
        recommendationsSoftTimedOut = false
        recommendationsSoftTimeoutMessage = nil
    }

    deinit {
        reloadTask?.cancel()
        cheerResetTask?.cancel()
        recommendationsTask?.cancel()
        recommendationsDebounceTask?.cancel()
        recommendationsSoftTimeoutTask?.cancel()
    }
}
