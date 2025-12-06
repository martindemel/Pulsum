import Foundation
import CoreData
#if canImport(FoundationModels)
import FoundationModels
#endif
import os
import PulsumData
import PulsumServices
import PulsumML
import PulsumTypes

public enum OrchestratorStartupError: Error {
    case healthDataUnavailable
    case healthBackgroundDeliveryMissing(underlying: Error)
}

// MARK: - Topic routing helpers

struct TopicSignalResolver {
    static func mapTopicToSignalOrDataDominant(topic: String?,
                                               snapshot: FeatureVectorSnapshot) -> String {
        if let topic,
           let focus = TopicFocus(rawValue: topic) {
            return focus.signalKey
        }
        return dataDominantSignal(from: snapshot)
    }

    static func dataDominantSignal(from snapshot: FeatureVectorSnapshot) -> String {
        let prioritizedKeys = snapshot.features.keys
            .filter { $0.hasPrefix("z_") || $0.hasPrefix("subj_") || $0 == "sentiment" }
            .sorted()

        var dominantSignal = "subj_energy"
        var maxAbsZ = 0.0

        for key in prioritizedKeys {
            guard let value = snapshot.features[key] else { continue }
            let magnitude = abs(value)
            if magnitude > maxAbsZ {
                maxAbsZ = magnitude
                dominantSignal = key
            }
        }

        return dominantSignal
    }

    private enum TopicFocus: String {
        case sleep
        case stress
        case energy
        case hrv
        case mood
        case movement
        case mindfulness
        case goals

        var signalKey: String {
            switch self {
            case .sleep: return "subj_sleepQuality"
            case .stress: return "subj_stress"
            case .energy: return "subj_energy"
            case .hrv: return "z_hrv"
            case .mood: return "sentiment"
            case .movement: return "z_steps"
            case .mindfulness: return "z_rr"
            case .goals: return "subj_energy"
            }
        }
    }
}

protocol DataAgentProviding: AnyObject, Sendable {
    func start() async throws
    func latestFeatureVector() async throws -> FeatureVectorSnapshot?
    func recordSubjectiveInputs(date: Date, stress: Double, energy: Double, sleepQuality: Double) async throws
    func scoreBreakdown() async throws -> ScoreBreakdown?
    func reprocessDay(date: Date) async throws
    func currentHealthAccessStatus() async -> HealthAccessStatus
    func requestHealthAccess() async throws -> HealthAccessStatus
    func restartIngestionAfterPermissionsChange() async throws -> HealthAccessStatus
}

extension DataAgent: DataAgentProviding {}

@MainActor
protocol SentimentAgentProviding: AnyObject {
    func beginVoiceJournal(maxDuration: TimeInterval) async throws
    func finishVoiceJournal(transcript: String?) async throws -> JournalResult
    func recordVoiceJournal(maxDuration: TimeInterval) async throws -> JournalResult
    func importTranscript(_ transcript: String) async throws -> JournalResult
    func requestAuthorization() async throws
    func stopRecording()
    var audioLevels: AsyncStream<Float>? { get }
    var speechStream: AsyncThrowingStream<SpeechSegment, Error>? { get }
    func updateTranscript(_ transcript: String)
    func latestTranscriptSnapshot() -> String
}

extension SentimentAgent: SentimentAgentProviding {}

public struct RecommendationResponse {
    public let cards: [RecommendationCard]
    public let wellbeingScore: Double
    public let contributions: [String: Double]
    public let wellbeingState: WellbeingScoreState
    public let notice: String?
}

public struct JournalCaptureResponse {
    public let result: JournalResult
    public let safety: SafetyDecision
}

public struct RecommendationCard: Equatable {
    public let id: String
    public let title: String
    public let body: String
    public let caution: String?
    public let sourceBadge: String
}

public struct SafetyDecision {
    public let classification: SafetyClassification
    public let allowCloud: Bool
    public let crisisMessage: String?
}

public struct JournalResult: @unchecked Sendable {
    public let entryID: NSManagedObjectID
    public let date: Date
    public let transcript: String
    public let sentimentScore: Double
    public let vectorURL: URL?
    public let embeddingPending: Bool
}

public struct CheerEvent {
    public enum HapticStyle {
        case success
        case light
        case heavy
    }

    public let message: String
    public let haptic: HapticStyle
    public let timestamp: Date
}

@MainActor
public final class AgentOrchestrator {
    private let dataAgent: any DataAgentProviding
    private let sentimentAgent: any SentimentAgentProviding
    private let coachAgent: CoachAgent
    private let safetyAgent: SafetyAgent
    private let cheerAgent: CheerAgent

    private let afmAvailable: Bool
    private let topicGate: TopicGateProviding
    private let logger = Logger(subsystem: "com.pulsum", category: "AgentOrchestrator")
    private var isVoiceJournalActive = false
    
    public init() throws {
        // Check Foundation Models availability
#if canImport(FoundationModels) && os(iOS)
        if #available(iOS 26.0, *) {
            self.afmAvailable = SystemLanguageModel.default.isAvailable
        } else {
            self.afmAvailable = false
        }
#else
        self.afmAvailable = false
#endif

        // Initialize TopicGate with cascade: AFM → embedding fallback
#if canImport(FoundationModels) && os(iOS)
        if #available(iOS 26.0, *), SystemLanguageModel.default.isAvailable {
            self.topicGate = FoundationModelsTopicGateProvider()
        } else {
            self.topicGate = EmbeddingTopicGateProvider()
        }
#else
        self.topicGate = EmbeddingTopicGateProvider()
#endif

        self.dataAgent = DataAgent()
        self.sentimentAgent = SentimentAgent()
        self.coachAgent = try CoachAgent()
        self.safetyAgent = SafetyAgent()
        self.cheerAgent = CheerAgent()
    }
#if DEBUG
    init(dataAgent: any DataAgentProviding,
                sentimentAgent: any SentimentAgentProviding,
                coachAgent: CoachAgent,
                safetyAgent: SafetyAgent,
                cheerAgent: CheerAgent,
                topicGate: TopicGateProviding,
                afmAvailable: Bool = false) {
        self.dataAgent = dataAgent
        self.sentimentAgent = sentimentAgent
        self.coachAgent = coachAgent
        self.safetyAgent = safetyAgent
        self.cheerAgent = cheerAgent
        self.topicGate = topicGate
        self.afmAvailable = afmAvailable
    }
#endif

#if DEBUG
    init(testDataAgent: DataAgent,
         testSentimentAgent: any SentimentAgentProviding,
         testCoachAgent: CoachAgent,
         testSafetyAgent: SafetyAgent,
         testCheerAgent: CheerAgent,
         testTopicGate: TopicGateProviding,
         afmAvailable: Bool = false) {
        self.dataAgent = testDataAgent
        self.sentimentAgent = testSentimentAgent
        self.coachAgent = testCoachAgent
        self.safetyAgent = testSafetyAgent
        self.cheerAgent = testCheerAgent
        self.afmAvailable = afmAvailable
        self.topicGate = testTopicGate
    }
#endif
    
    public var foundationModelsStatus: String {
        if #available(iOS 26.0, *) {
            let status = FoundationModelsAvailability.checkAvailability()
            return FoundationModelsAvailability.availabilityMessage(for: status)
        } else {
            return "Foundation Models require iOS 26 or later."
        }
    }

    public func debugLogSnapshot() async -> String {
        await DebugLogBuffer.shared.snapshot()
    }

    public func start() async throws {
        do {
            try await coachAgent.prepareLibraryIfNeeded()
            try await dataAgent.start()
        } catch let healthError as HealthKitServiceError {
            switch healthError {
            case .healthDataUnavailable:
                throw OrchestratorStartupError.healthDataUnavailable
            case let .backgroundDeliveryFailed(_, underlying):
                throw OrchestratorStartupError.healthBackgroundDeliveryMissing(underlying: underlying)
            default:
                throw healthError
            }
        }
    }

    public func currentHealthAccessStatus() async -> HealthAccessStatus {
        await dataAgent.currentHealthAccessStatus()
    }

    public func requestHealthAccess() async throws -> HealthAccessStatus {
        try await dataAgent.requestHealthAccess()
    }

    public func restartHealthDataIngestion() async throws -> HealthAccessStatus {
        try await dataAgent.restartIngestionAfterPermissionsChange()
    }

    /// Begins voice journal recording and returns immediately after starting audio capture.
    /// Audio levels and speech stream become available synchronously via properties.
    /// The caller should consume `voiceJournalSpeechStream` for real-time transcription.
    /// Call `finishVoiceJournalRecording(transcript:)` to complete recording and get the result.
    public func beginVoiceJournalRecording(maxDuration: TimeInterval = 30) async throws {
        guard !isVoiceJournalActive else {
            throw SentimentAgentError.sessionAlreadyActive
        }
        isVoiceJournalActive = true
        do {
            try await sentimentAgent.beginVoiceJournal(maxDuration: maxDuration)
        } catch {
            isVoiceJournalActive = false
            throw error
        }
    }
    
    /// Completes the voice journal recording that was started with `beginVoiceJournalRecording()`.
    /// Uses the provided transcript (from consuming the speech stream) to persist the journal.
    /// Returns the journal result with safety evaluation.
    public func finishVoiceJournalRecording(transcript: String? = nil) async throws -> JournalCaptureResponse {
        defer { isVoiceJournalActive = false }
        let result = try await sentimentAgent.finishVoiceJournal(transcript: transcript)
        let safety = await safetyAgent.evaluate(text: result.transcript)
        try await dataAgent.reprocessDay(date: result.date)
        return JournalCaptureResponse(result: result, safety: safety)
    }

    /// Legacy method that combines begin + finish for backward compatibility
    public func recordVoiceJournal(maxDuration: TimeInterval = 30) async throws -> JournalCaptureResponse {
        try await beginVoiceJournalRecording(maxDuration: maxDuration)
        var transcript = ""
        do {
            if let stream = voiceJournalSpeechStream {
                for try await segment in stream {
                    transcript = segment.transcript
                    sentimentAgent.updateTranscript(transcript)
                }
            }
            return try await finishVoiceJournalRecording(transcript: transcript)
        } catch {
            let fallbackTranscript = transcript.isEmpty ? sentimentAgent.latestTranscriptSnapshot() : transcript
            if !fallbackTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                _ = try? await finishVoiceJournalRecording(transcript: fallbackTranscript)
            } else {
                stopVoiceJournalRecording()
            }
            throw error
        }
    }

    public func submitTranscript(_ text: String) async throws -> JournalCaptureResponse {
        let result = try await sentimentAgent.importTranscript(text)
        let safety = await safetyAgent.evaluate(text: result.transcript)
        return JournalCaptureResponse(result: result, safety: safety)
    }

    public func currentLLMAPIKey() -> String? {
        coachAgent.currentLLMAPIKey()
    }

    public func setLLMAPIKey(_ key: String) throws {
        try coachAgent.setLLMAPIKey(key)
    }

    public func testLLMAPIConnection() async throws -> Bool {
        try await coachAgent.testLLMAPIConnection()
    }

    public func stopVoiceJournalRecording() {
        isVoiceJournalActive = false
        sentimentAgent.stopRecording()
    }
    
    public var voiceJournalAudioLevels: AsyncStream<Float>? {
        sentimentAgent.audioLevels
    }
    
    public var voiceJournalSpeechStream: AsyncThrowingStream<SpeechSegment, Error>? {
        sentimentAgent.speechStream
    }

    public func updateVoiceJournalTranscript(_ transcript: String) {
        sentimentAgent.updateTranscript(transcript)
    }

    public func updateSubjectiveInputs(date: Date, stress: Double, energy: Double, sleepQuality: Double) async throws {
        try await dataAgent.recordSubjectiveInputs(date: date, stress: stress, energy: energy, sleepQuality: sleepQuality)
    }

    public func recommendations(consentGranted: Bool) async throws -> RecommendationResponse {
        let healthStatus = await dataAgent.currentHealthAccessStatus()

        let snapshot: FeatureVectorSnapshot?
        do {
            snapshot = try await dataAgent.latestFeatureVector()
        } catch {
            return Self.makeNoDataRecommendationResponse(for: healthStatus)
        }

        guard let snapshot else {
            return Self.makeNoDataRecommendationResponse(for: healthStatus)
        }

        do {
            let cards = try await coachAgent.recommendationCards(for: snapshot, consentGranted: consentGranted)
            let notice = coachAgent.recommendationNotice
            return RecommendationResponse(cards: cards,
                                          wellbeingScore: snapshot.wellbeingScore,
                                          contributions: snapshot.contributions,
                                          wellbeingState: .ready(score: snapshot.wellbeingScore,
                                                                  contributions: snapshot.contributions),
                                          notice: notice)
        } catch {
            let sanitized = "Unable to compute wellbeing right now."
            return RecommendationResponse(cards: [],
                                          wellbeingScore: 0,
                                          contributions: [:],
                                          wellbeingState: .error(message: sanitized),
                                          notice: "Personalized recommendations are limited on this device right now.")
        }
    }

    nonisolated static func computeWellbeingState(for healthStatus: HealthAccessStatus) -> WellbeingScoreState {
        switch healthStatus.availability {
        case .unavailable:
            return .noData(.healthDataUnavailable)
        case .available:
            if !healthStatus.denied.isEmpty || !healthStatus.notDetermined.isEmpty {
                return .noData(.permissionsDeniedOrPending)
            }
            return .noData(.insufficientSamples)
        }
    }

    private static func makeNoDataRecommendationResponse(for healthStatus: HealthAccessStatus) -> RecommendationResponse {
        let state = computeWellbeingState(for: healthStatus)
        return RecommendationResponse(cards: [],
                                      wellbeingScore: 0,
                                      contributions: [:],
                                      wellbeingState: state,
                                      notice: nil)
    }

    public func scoreBreakdown() async throws -> ScoreBreakdown? {
        try await dataAgent.scoreBreakdown()
    }

    public func chat(userInput: String, consentGranted: Bool) async throws -> String {
        let sanitizedInput = PIIRedactor.redact(userInput)
        logger.debug("Chat request received. Consent: \(consentGranted, privacy: .public), input: \(sanitizedInput.prefix(160), privacy: .public)")

        guard let snapshot = try await dataAgent.latestFeatureVector() else {
            logger.info("No feature vector snapshot available; returning warmup prompt.")
            return "Let's take a moment to capture your pulse first."
        }

        return await performChat(userInput: userInput,
                                 sanitizedInput: sanitizedInput,
                                 snapshot: snapshot,
                                 consentGranted: consentGranted,
                                 diagnosticsContext: "live")
    }

#if DEBUG
    public func chat(userInput: String,
                     consentGranted: Bool,
                     snapshotOverride: FeatureVectorSnapshot) async -> String {
        let sanitizedInput = PIIRedactor.redact(userInput)
        logger.debug("Chat request (override). Consent: \(consentGranted, privacy: .public), input: \(sanitizedInput.prefix(160), privacy: .public)")
        return await performChat(userInput: userInput,
                                 sanitizedInput: sanitizedInput,
                                 snapshot: snapshotOverride,
                                 consentGranted: consentGranted,
                                 diagnosticsContext: "override")
    }
#endif

    private func performChat(userInput: String,
                             sanitizedInput: String,
                             snapshot: FeatureVectorSnapshot,
                             consentGranted: Bool,
                             diagnosticsContext: String) async -> String {
        // WALL 1: Safety + On-Topic Guardrail (on-device)
        let safety = await safetyAgent.evaluate(text: userInput)
        let classification: String
        switch safety.classification {
        case .safe:
            classification = "safe"
        case .caution(let reason):
            classification = "caution: \(String(PIIRedactor.redact(reason).prefix(120)))"
        case .crisis(let reason):
            classification = "crisis: \(String(PIIRedactor.redact(reason).prefix(120)))"
        }
        logger.debug("Safety decision → allowCloud: \(safety.allowCloud, privacy: .public), classification: \(classification, privacy: .public)")

        let allowCloud = consentGranted && safety.allowCloud

        if !safety.allowCloud {
            logger.notice("Safety gate blocked cloud usage. Returning guardrail message.")
            switch safety.classification {
            case .crisis:
                emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=nil coverage=fail → safety", decision: nil, top: nil, median: nil, count: nil, context: diagnosticsContext)
                return safety.crisisMessage ?? "If you're in immediate danger, please contact 911."
            case .caution:
                emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=nil coverage=fail → safety", decision: nil, top: nil, median: nil, count: nil, context: diagnosticsContext)
                return "Let's stay with grounding actions for a moment."
            case .safe:
                break
            }
        }

        // Step 2: Topic gate (on-device ML classification)
        let intentTopic: String?
        var topSignal: String
        do {
            let gateDecision = try await topicGate.classify(sanitizedInput)
            logger.debug("Topic gate → isOnTopic: \(gateDecision.isOnTopic, privacy: .public), confidence: \(String(format: "%.2f", gateDecision.confidence), privacy: .public), topic: \(gateDecision.topic ?? "none", privacy: .public), reason: \(String(gateDecision.reason.prefix(100)), privacy: .public)")

            if !gateDecision.isOnTopic {
                logger.notice("Topic gate blocked off-topic request. Returning redirect message.")
                emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=nil coverage=fail → redirect", decision: nil, top: nil, median: nil, count: nil, context: diagnosticsContext)
                return "Let's keep Pulsum focused on your wellbeing data. Ask me about stress, sleep, energy, or today's recommendations."
            }

            // Step 2b: Deterministic intent → topSignal mapping (4-step override)
            var topic = gateDecision.topic
            let lower = sanitizedInput.lowercased()
            let phraseToTopic: [(substr: String, topic: String)] = [
                ("sleep", "sleep"), ("insomnia", "sleep"), ("rest", "sleep"), ("tired", "sleep"),
                ("stress", "stress"), ("anxiety", "stress"), ("overwhelm", "stress"), ("worry", "stress"),
                ("energy", "energy"), ("fatigue", "energy"), ("motivation", "energy"),
                ("hrv", "hrv"), ("heart rate variability", "hrv"), ("recovery", "hrv"), ("rmssd", "hrv"),
                ("mood", "mood"), ("feeling", "mood"), ("emotion", "mood"),
                ("movement", "movement"), ("steps", "movement"), ("walk", "movement"), ("exercise", "movement"),
                ("mindfulness", "mindfulness"), ("meditation", "mindfulness"), ("breathe", "mindfulness"), ("calm", "mindfulness"),
                ("goal", "goals"), ("habit", "goals"), ("micro", "goals"), ("activity", "goals")
            ]
            if let hit = phraseToTopic.first(where: { lower.contains($0.substr) }) {
                topic = hit.topic
            }

            let candidateMoments = await coachAgent.candidateMoments(for: topic ?? "goals", limit: 2)
            if let dominantFromCandidates = dominantTopic(from: candidateMoments, coachAgent: coachAgent) {
                topic = dominantFromCandidates
            }

            topSignal = TopicSignalResolver.mapTopicToSignalOrDataDominant(topic: topic, snapshot: snapshot)
            if let topic {
                topSignal += " topic=\(topic)"
            }
            intentTopic = topic

            logger.debug("Intent mapping → topic: \(topic ?? "none", privacy: .public), topSignal: \(topSignal, privacy: .public)")
        } catch {
            logger.error("Topic gate failed: \(error.localizedDescription, privacy: .public). Failing closed.")
            emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=nil coverage=fail → redirect", decision: nil, top: nil, median: nil, count: nil, context: diagnosticsContext)
            return "Let's keep Pulsum focused on your wellbeing data. Ask me about stress, sleep, energy, or today's recommendations."
        }

        // Embedding availability gate: if no on-device embeddings are available, fail closed and respond on-device.
        if !EmbeddingService.shared.isAvailable() {
            logger.error("Embeddings unavailable; skipping coverage and routing to on-device response.")
            emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=\(intentTopic ?? "nil") coverage=unavailable → on-device",
                                decision: nil,
                                top: nil,
                                median: nil,
                                count: nil,
                                context: diagnosticsContext)
            let topic = intentTopic ?? "wellbeing"
            let context = coachAgent.minimalCoachContext(from: snapshot, topic: topic)
            let payload = await coachAgent.generateResponse(context: context,
                                                            intentTopic: intentTopic ?? topic,
                                                            consentGranted: false,
                                                            groundingFloor: 0.40)
            return payload.coachReply
        }

        // Step 3: Retrieval coverage with hybrid backfill
        let coverageResult: (matches: [VectorMatch], decision: CoverageDecision)
        do {
            coverageResult = try await coachAgent.coverageDecision(for: sanitizedInput,
                                                                   canonicalTopic: intentTopic,
                                                                   snapshot: snapshot)
        } catch {
            if let embeddingError = error as? EmbeddingError, case .generatorUnavailable = embeddingError {
                logger.error("Coverage evaluation skipped: embeddings unavailable. Routing to on-device response.")
                emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=\(intentTopic ?? "nil") coverage=unavailable → on-device", decision: nil, top: nil, median: nil, count: nil, context: diagnosticsContext)
                let topic = intentTopic ?? "wellbeing"
                let context = coachAgent.minimalCoachContext(from: snapshot, topic: topic)
                let payload = await coachAgent.generateResponse(context: context,
                                                                intentTopic: intentTopic ?? topic,
                                                                consentGranted: false,
                                                                groundingFloor: 0.40)
                return payload.coachReply
            }
            logger.error("Coverage evaluation failed: \(error.localizedDescription, privacy: .public). Falling back to redirect.")
            emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=\(intentTopic ?? "nil") coverage=unknown → redirect", decision: nil, top: nil, median: nil, count: nil, context: diagnosticsContext)
            return "Let's keep Pulsum focused on your wellbeing data. Ask me about stress, sleep, energy, or today's recommendations."
        }

        let decision = coverageResult.decision
        let routeDestination = allowCloud ? "cloud" : "on-device"
        let groundingFloor: Double

        switch decision.kind {
        case .strong:
            groundingFloor = 0.50
            emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=\(intentTopic ?? "nil") coverage=strong → \(routeDestination)",
                                decision: decision,
                                top: decision.top,
                                median: decision.median,
                                count: decision.count,
                                context: diagnosticsContext)
        case .soft:
            groundingFloor = 0.40
            emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=\(intentTopic ?? "nil") coverage=soft → \(routeDestination)",
                                decision: decision,
                                top: decision.top,
                                median: decision.median,
                                count: decision.count,
                                context: diagnosticsContext)
        case .fail:
            if intentTopic == nil {
                emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=nil coverage=fail → on-device",
                                    decision: decision,
                                    top: decision.top,
                                    median: decision.median,
                                    count: decision.count,
                                    context: diagnosticsContext)
                let context = coachAgent.minimalCoachContext(from: snapshot, topic: "greeting")
                let payload = await coachAgent.generateResponse(context: context,
                                                                intentTopic: "greeting",
                                                                consentGranted: false,
                                                                groundingFloor: 0.40)
                return payload.coachReply
            }
            emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=\(intentTopic ?? "nil") coverage=fail → on-device",
                                decision: decision,
                                top: decision.top,
                                median: decision.median,
                                count: decision.count,
                                context: diagnosticsContext)
            let context = coachAgent.minimalCoachContext(from: snapshot, topic: intentTopic!)
            let payload = await coachAgent.generateResponse(context: context,
                                                            intentTopic: intentTopic,
                                                            consentGranted: false,
                                                            groundingFloor: 0.40)
            return payload.coachReply
        }

        let payload = await coachAgent.chatResponse(userInput: userInput,
                                                    snapshot: snapshot,
                                                    consentGranted: allowCloud,
                                                    intentTopic: intentTopic,
                                                    topSignal: topSignal,
                                                    groundingFloor: groundingFloor)
        logger.debug("Chat response delivered. Length: \(payload.coachReply.count, privacy: .public), hasNextAction: \(payload.nextAction != nil, privacy: .public)")

        return payload.coachReply
    }

    private func emitRouteDiagnostics(line: String,
                                      decision: CoverageDecision?,
                                      top: Double?,
                                      median: Double?,
                                      count: Int?,
                                      context: String) {
        print(line)
#if DEBUG
        var info: [String: Any] = [
            "route": line,
            "context": context
        ]
        if let decision {
            info["reason"] = decision.reason
        }
        if let top { info["top"] = top }
        if let median { info["median"] = median }
        if let count { info["count"] = count }
        NotificationCenter.default.post(name: .pulsumChatRouteDiagnostics,
                                        object: nil,
                                        userInfo: info)
#endif
    }

    public func logCompletion(momentId: String) async throws -> CheerEvent {
        try await coachAgent.logEvent(momentId: momentId, accepted: true)
        let title = await coachAgent.momentTitle(for: momentId) ?? momentId
        return await cheerAgent.celebrateCompletion(momentTitle: title)
    }

    // MARK: - Intent Mapping Helpers

    /// Extract dominant topic from candidate moments (Step 3 of intent mapping)
    private func dominantTopic(from candidates: [CandidateMoment], coachAgent: CoachAgent) -> String? {
        // Use embedding similarity to infer dominant topic from candidate titles
        let topicKeywords: [String: [String]] = [
            "sleep": ["sleep", "rest", "recovery", "insomnia", "tired"],
            "stress": ["stress", "anxiety", "overwhelm", "worry", "tension"],
            "energy": ["energy", "fatigue", "motivation", "vitality"],
            "hrv": ["hrv", "heart rate", "variability", "recovery", "vagal"],
            "mood": ["mood", "feeling", "emotion", "mental"],
            "movement": ["movement", "steps", "walk", "exercise", "activity"],
            "mindfulness": ["mindfulness", "meditation", "breathe", "calm", "grounding"],
            "goals": ["goal", "habit", "micro", "moment", "action"]
        ]

        var topicScores: [String: Int] = [:]
        for candidate in candidates {
            let detail = candidate.detail ?? ""
            let text = (candidate.title + " " + candidate.shortDescription + " " + detail).lowercased()
            for (topic, keywords) in topicKeywords {
                let matches = keywords.filter { text.contains($0) }.count
                topicScores[topic, default: 0] += matches
            }
        }

        return topicScores.max(by: { $0.value < $1.value })?.key
    }

}
