import Foundation
import Observation
import os
import PulsumAgents
#if canImport(FoundationModels) && os(iOS)
import FoundationModels
#endif

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

    @ObservationIgnored fileprivate var orchestrator: AgentOrchestrator?
    @ObservationIgnored private var consentProvider: () -> Bool = { false }

    var recommendations: [RecommendationCard] = []
    var wellbeingScore: Double?
    var contributions: [String: Double] = [:]
    var wellbeingState: WellbeingScoreState = .loading
    private var hasLoadedWellbeing = false

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

    func bind(orchestrator: AgentOrchestrator, consentProvider: @escaping () -> Bool) {
        self.orchestrator = orchestrator
        self.consentProvider = consentProvider
        self.consentGranted = consentProvider()
    }

    func refreshRecommendations() async {
        guard let orchestrator else { return }
        if !hasLoadedWellbeing {
            wellbeingState = .loading
            cardErrorMessage = nil
        }
        isLoadingCards = true
        cardErrorMessage = nil
        defer { isLoadingCards = false }
        do {
            let response = try await orchestrator.recommendations(consentGranted: consentProvider())
            recommendations = response.cards
            wellbeingState = response.wellbeingState
            cardErrorMessage = response.notice

            switch response.wellbeingState {
            case let .ready(score, contributions):
                wellbeingScore = score
                self.contributions = contributions
            default:
                wellbeingScore = nil
                contributions = [:]
            }
            hasLoadedWellbeing = true
        } catch {
            cardErrorMessage = mapError(error)
            wellbeingState = .error(message: cardErrorMessage ?? "Unable to compute wellbeing right now.")
            wellbeingScore = nil
            contributions = [:]
            hasLoadedWellbeing = true
        }
    }

    func updateConsent(_ granted: Bool) {
        consentGranted = granted
    }

    func requestChatFocus() {
        chatFocusToken = UUID()
    }

    func reloadIfNeeded() {
        Task { [weak self] in
            guard let self else { return }
            await self.refreshRecommendations()
        }
    }

    func complete(card: RecommendationCard, orchestrator: AgentOrchestrator) async {
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
        guard let orchestrator else { return }
        let trimmed = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        logger.debug("Sending chat message. Characters: \(trimmed.count, privacy: .public)")
        let userMessage = ChatMessage(role: .user, text: trimmed, timestamp: Date())
        messages.append(userMessage)
        chatInput = ""
        isSendingChat = true
        chatErrorMessage = nil
        do {
            let response = try await orchestrator.chat(userInput: trimmed, consentGranted: consentProvider())
            let assistant = ChatMessage(role: .assistant, text: response, timestamp: Date())
            messages.append(assistant)
            logger.debug("Chat response appended. Characters: \(response.count, privacy: .public)")
        } catch {
            chatErrorMessage = mapError(error)
            logger.error("Chat send failed: \(error.localizedDescription, privacy: .public)")
        }
        isSendingChat = false
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

    private func scheduleCheerReset() {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard let self else { return }
            cheerEventMessage = nil
        }
    }
}
