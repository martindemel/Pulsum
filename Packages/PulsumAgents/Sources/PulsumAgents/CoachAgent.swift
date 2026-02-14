import Foundation
import CoreData
#if canImport(FoundationModels)
import FoundationModels
#endif
import os
import PulsumData
import PulsumML
import PulsumServices
import PulsumTypes

@MainActor
public final class CoachAgent {
    private let context: NSManagedObjectContext
    private let vectorIndex: VectorIndexProviding
    private let ranker: RecRanker
    private let rankerStore: RecRankerStateStoring
    private var lastRankedFeatures: [RecommendationFeatures] = []
    private let libraryImporter: LibraryImporter
    private let llmGateway: LLMGateway
    private let shouldIngestLibrary: Bool
    private var hasPreparedLibrary = false
    private var libraryEmbeddingsDeferred = false
    private var lastRecommendationNotice: String?
    private var libraryPreparationTask: Task<Void, Error>?
    private let logger = Logger(subsystem: "com.pulsum", category: "CoachAgent")

    public init(container: NSPersistentContainer = PulsumData.container,
                vectorIndex: VectorIndexProviding = VectorIndexManager.shared,
                libraryImporter: LibraryImporter = LibraryImporter(),
                llmGateway: LLMGateway = LLMGateway(),
                shouldIngestLibrary: Bool = true,
                rankerStore: RecRankerStateStoring = RecRankerStateStore()) throws {
        self.context = container.newBackgroundContext()
        self.context.name = "Pulsum.CoachAgent.FoundationModels"
        self.context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        self.vectorIndex = vectorIndex
        self.libraryImporter = libraryImporter
        self.llmGateway = llmGateway
        self.shouldIngestLibrary = shouldIngestLibrary
        self.rankerStore = rankerStore
        self.ranker = RecRanker(state: rankerStore.loadState())
    }

    public var libraryImportDeferred: Bool {
        libraryEmbeddingsDeferred
    }

    public func prepareLibraryIfNeeded() async throws {
        guard shouldIngestLibrary else { return }
        if let inFlight = libraryPreparationTask {
            try await inFlight.value
            return
        }
        if hasPreparedLibrary && !libraryEmbeddingsDeferred { return }
        if libraryEmbeddingsDeferred && EmbeddingService.shared.availabilityMode() == .unavailable {
            return
        }
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            try await self.performLibraryPreparation()
        }
        libraryPreparationTask = task
        defer { libraryPreparationTask = nil }
        try await task.value
    }

    public func retryDeferredLibraryImport(traceId: UUID? = nil) async {
        guard shouldIngestLibrary else { return }
        guard libraryEmbeddingsDeferred else { return }
        let span = Diagnostics.span(category: .library,
                                    name: "library.import.retry",
                                    fields: ["deferred": .bool(libraryEmbeddingsDeferred)],
                                    traceId: traceId)
        do {
            try await prepareLibraryIfNeeded()
            Diagnostics.log(level: .info,
                            category: .library,
                            name: "library.import.retry.end",
                            fields: ["deferred": .bool(libraryEmbeddingsDeferred)],
                            traceId: traceId)
            span.end(error: nil)
        } catch {
            let nsError = error as NSError
            logger.error("Deferred library import retry failed. domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)")
            Diagnostics.log(level: .warn,
                            category: .library,
                            name: "library.import.retry.failed",
                            fields: ["deferred": .bool(true)],
                            traceId: traceId,
                            error: error)
            span.end(error: error)
        }
    }

    public func recommendationCards(for snapshot: FeatureVectorSnapshot,
                                    consentGranted: Bool) async throws -> [RecommendationCard] {
        let span = Diagnostics.span(category: .coach,
                                    name: "coach.recommendations",
                                    fields: ["consent": .bool(consentGranted)],
                                    level: .info)
        var route = "library"
        var candidateCount = 0
        do {
            try Task.checkCancellation()
            try await prepareLibraryIfNeeded()
            lastRecommendationNotice = nil

            let query = buildQuery(from: snapshot)
            let matches: [VectorMatch]
            do {
                try Task.checkCancellation()
                matches = try await vectorIndex.searchMicroMoments(query: query, topK: 20)
            } catch let embeddingError as EmbeddingError where embeddingError == .generatorUnavailable {
                libraryEmbeddingsDeferred = true
                lastRecommendationNotice = "Personalized recommendations are limited on this device right now. We'll enable smarter suggestions when on-device embeddings are available."
                route = "fallback_embeddings_unavailable"
                try Task.checkCancellation()
                let cards = await fallbackRecommendations(snapshot: snapshot, topic: nil)
                candidateCount = cards.count
                span.end(additionalFields: [
                    "route": .safeString(.stage(route, allowed: ["library", "fallback_embeddings_unavailable", "fallback_no_matches"])),
                    "candidate_count": .int(candidateCount)
                ], error: nil)
                return cards
            }
            guard !matches.isEmpty else {
                if libraryEmbeddingsDeferred {
                    lastRecommendationNotice = "Personalized recommendations are limited on this device right now. We'll enable smarter suggestions when on-device embeddings are available."
                }
                route = "fallback_no_matches"
                try Task.checkCancellation()
                let cards = await fallbackRecommendations(snapshot: snapshot, topic: nil)
                candidateCount = cards.count
                span.end(additionalFields: [
                    "route": .safeString(.stage(route, allowed: ["library", "fallback_embeddings_unavailable", "fallback_no_matches"])),
                    "candidate_count": .int(candidateCount)
                ], error: nil)
                return cards
            }

            let scoreLookup = Dictionary(uniqueKeysWithValues: matches.map { ($0.id, $0.score) })
            try Task.checkCancellation()
            let moments = try await fetchMicroMoments(ids: Array(scoreLookup.keys))

            var candidates: [CardCandidate] = []
            for moment in moments {
                try Task.checkCancellation()
                guard let distance = scoreLookup[moment.id] else { continue }
                if let candidate = await makeCandidate(moment: moment,
                                                       distance: distance,
                                                       snapshot: snapshot) {
                    candidates.append(candidate)
                }
            }

            guard !candidates.isEmpty else {
                candidateCount = 0
                span.end(additionalFields: [
                    "route": .safeString(.stage(route, allowed: ["library", "fallback_embeddings_unavailable", "fallback_no_matches"])),
                    "candidate_count": .int(candidateCount),
                    "matches_considered": .int(matches.count)
                ], error: nil)
                return []
            }

            try Task.checkCancellation()
            let rankedFeatures = ranker.rank(candidates.map { $0.features })
            lastRankedFeatures = rankedFeatures
            var rankedCards: [RecommendationCard] = []
            for feature in rankedFeatures {
                try Task.checkCancellation()
                guard let candidate = candidates.first(where: { $0.features.id == feature.id }) else { continue }
                rankedCards.append(candidate.card)
                if rankedCards.count == 3 { break }
            }
            candidateCount = rankedCards.count
            span.end(additionalFields: [
                "route": .safeString(.stage(route, allowed: ["library", "fallback_embeddings_unavailable", "fallback_no_matches"])),
                "candidate_count": .int(candidateCount),
                "matches_considered": .int(matches.count)
            ], error: nil)
            return rankedCards
        } catch {
            span.end(additionalFields: [
                "route": .safeString(.stage(route, allowed: ["library", "fallback_embeddings_unavailable", "fallback_no_matches"])),
                "candidate_count": .int(candidateCount)
            ], error: error)
            throw error
        }
    }

    public func chatResponse(userInput: String,
                             snapshot: FeatureVectorSnapshot,
                             consentGranted: Bool,
                             intentTopic: String?,
                             topSignal: String,
                             groundingFloor: Double) async -> CoachReplyPayload {
        let sanitizedInput = PIIRedactor.redact(userInput)
        Diagnostics.log(level: .info,
                        category: .coach,
                        name: "coach.chat.prepare",
                        fields: [
                            "consent": .bool(consentGranted),
                            "input_chars": .int(userInput.count)
                        ])
        let rationale = snapshot.contributions.sorted { abs($0.value) > abs($1.value) }
            .prefix(3)
            .map { "\($0.key): \(String(format: "%.2f", $0.value))" }
            .joined(separator: ", ")
        let summary = snapshot.contributions.map { "\($0.key)=\(String(format: "%.2f", $0.value))" }
            .joined(separator: ", ")

        let candidateMoments: [CandidateMoment]
        if let topic = intentTopic {
            candidateMoments = await self.candidateMoments(for: topic, limit: 3)
        } else {
            candidateMoments = []
        }

        let context = CoachLLMContext(userToneHints: String(sanitizedInput.prefix(180)),
                                      topSignal: topSignal,
                                      topMomentId: candidateMoments.first?.id,
                                      rationale: rationale,
                                      zScoreSummary: summary,
                                      candidateMoments: candidateMoments)
        return await llmGateway.generateCoachResponse(context: context,
                                                      intentTopic: intentTopic,
                                                      candidateMoments: candidateMoments,
                                                      consentGranted: consentGranted,
                                                      groundingFloor: groundingFloor)
    }

    private func mapIntentToSignal(intentTopic: String?, snapshot: FeatureVectorSnapshot) -> String {
        guard let topic = intentTopic else {
            return snapshot.contributions.max(by: { abs($0.value) < abs($1.value) })?.key ?? "wellbeing"
        }

        // Map canonical topics to signal keys
        switch topic {
        case "sleep": return "subj_sleepQuality"
        case "stress": return "subj_stress"
        case "energy": return "subj_energy"
        case "hrv": return "z_hrv"
        case "mood": return "sentiment"
        case "movement": return "z_steps"
        case "mindfulness": return "z_rr"
        default: return "subj_energy"
        }
    }

    public func logEvent(momentId: String, accepted: Bool) async throws {
        try contextPerformAndWait { context in
            let event = RecommendationEvent(context: context)
            event.momentId = momentId
            event.date = Date()
            event.accepted = accepted
            event.completedAt = accepted ? Date() : nil
            try context.save()
        }
        let feedback = await applyFeedback(for: momentId, accepted: accepted)
        Diagnostics.log(level: .info,
                        category: .coach,
                        name: accepted ? "coach.feedback.accept" : "coach.feedback.dismiss",
                        fields: [
                            "moment_id": .safeString(.metadata(momentId)),
                            "weights_changed": .int(feedback?.changedCount ?? 0),
                            "learning_rate_bucket": .safeString(.stage(feedback?.learningRateBucket ?? "unknown",
                                                                       allowed: ["coldstart", "learning", "stable", "unknown"]))
                        ])
    }

    public func momentTitle(for id: String) async -> String? {
        contextPerformAndWait { context in
            let request = MicroMoment.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1
            return try? context.fetch(request).first?.title
        }
    }

    /// Fetch candidate micro-moments for intent-aware coaching
    /// Returns privacy-safe title and oneLiner (no PHI)
    public func candidateMoments(for intentTopic: String, limit: Int = 2) async -> [CandidateMoment] {
        let query = "wellbeing \(intentTopic)"
        let matches: [VectorMatch]
        do {
            matches = try await vectorIndex.searchMicroMoments(query: query, topK: limit)
        } catch let embeddingError as EmbeddingError where embeddingError == .generatorUnavailable {
            let keyword = try? await keywordBackfillMoments(for: intentTopic, limit: limit)
            guard let keyword, !keyword.isEmpty else { return [] }
            return keyword.compactMap { moment in
                let title = moment.title.trimmingCharacters(in: .whitespacesAndNewlines)
                let short = moment.shortDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !title.isEmpty, !short.isEmpty else { return nil }
                let detail = normalizeOptionalText(moment.detail, limit: 240)
                return CandidateMoment(id: moment.id,
                                       title: title,
                                       shortDescription: String(short.prefix(200)),
                                       detail: detail,
                                       evidenceBadge: moment.evidenceBadge)
            }
        } catch {
            return []
        }
        guard !matches.isEmpty else {
            return []
        }

        let ids = matches.map { $0.id }
        guard let moments = try? await fetchMicroMoments(ids: ids) else {
            return []
        }

        let lookup = Dictionary(uniqueKeysWithValues: moments.map { ($0.id, $0) })

        return ids.compactMap { id in
            guard let moment = lookup[id] else { return nil }
            let title = moment.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let short = moment.shortDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !id.isEmpty, !title.isEmpty, !short.isEmpty else { return nil }
            let detail = normalizeOptionalText(moment.detail, limit: 240)
            return CandidateMoment(id: id,
                                   title: title,
                                   shortDescription: String(short.prefix(200)),
                                   detail: detail,
                                   evidenceBadge: moment.evidenceBadge)
        }
    }

    private func normalizeOptionalText(_ text: String?, limit: Int) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return String(trimmed.prefix(limit))
    }

    private func buildQuery(from snapshot: FeatureVectorSnapshot) -> String {
        let leadingSignals = snapshot.contributions.sorted { abs($0.value) > abs($1.value) }
            .prefix(4)
            .map { "\($0.key)=\(String(format: "%.2f", $0.value))" }
            .joined(separator: " ")
        return "wellbeing=\(String(format: "%.2f", snapshot.wellbeingScore)) \(leadingSignals)"
    }

    private func fetchMicroMoments(ids: [String]) async throws -> [MicroMomentSnapshot] {
        try contextPerformAndWait { context in
            let request = MicroMoment.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", ids)
            let moments = try context.fetch(request)
            return moments.map(MicroMomentSnapshot.init)
        }
    }

    func generateResponse(context: CoachLLMContext,
                          intentTopic: String?,
                          consentGranted: Bool,
                          groundingFloor: Double) async -> CoachReplyPayload {
        await llmGateway.generateCoachResponse(context: context,
                                               intentTopic: intentTopic,
                                               candidateMoments: context.candidateMoments,
                                               consentGranted: consentGranted,
                                               groundingFloor: groundingFloor)
    }

    func coverageDecision(for query: String,
                          canonicalTopic: String?,
                          snapshot: FeatureVectorSnapshot?) async throws -> (matches: [VectorMatch], decision: CoverageDecision) {
        var matches = try await vectorIndex.searchMicroMoments(query: query, topK: 20)
        var decision = decideCoverage(CoverageInputs(l2Matches: matches,
                                                     canonicalTopic: canonicalTopic,
                                                     snapshot: snapshot))

        if case .fail = decision.kind, let topic = canonicalTopic {
            let backfill = try await keywordBackfillMoments(for: topic, limit: 8)
            for moment in backfill {
                let backfillMatches = try await vectorIndex.searchMicroMoments(query: moment.title, topK: 1)
                for match in backfillMatches where !matches.contains(where: { $0.id == match.id }) {
                    matches.append(match)
                }
            }
            decision = decideCoverage(CoverageInputs(l2Matches: matches,
                                                     canonicalTopic: canonicalTopic,
                                                     snapshot: snapshot))
        }

        logCoverage(decision)
        return (matches, decision)
    }

    private func keywordBackfillMoments(for topic: String,
                                        limit: Int) async throws -> [MicroMomentSnapshot] {
        try contextPerformAndWait { context in
            let request = NSFetchRequest<MicroMoment>(entityName: "MicroMoment")
            let candidateLimit = max(limit * 20, 200)
            request.fetchLimit = candidateLimit
            request.fetchBatchSize = candidateLimit
            request.sortDescriptors = [
                NSSortDescriptor(key: "title",
                                 ascending: true,
                                 selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))),
                NSSortDescriptor(key: "id", ascending: true)
            ]

            // tags is Transformable; filter matches in-memory to avoid SQL string predicates
            let candidates = try context.fetch(request)
            let filtered = candidates.filter { moment in
                if moment.title.range(of: topic, options: .caseInsensitive) != nil {
                    return true
                }
                guard let tags = moment.tags else { return false }
                return tags.contains { tag in
                    tag.range(of: topic, options: .caseInsensitive) != nil
                }
            }

            let sorted = filtered.sorted {
                let comparison = $0.title.localizedCaseInsensitiveCompare($1.title)
                if comparison == .orderedSame {
                    return $0.id < $1.id
                }
                return comparison == .orderedAscending
            }

            return Array(sorted.prefix(limit)).map(MicroMomentSnapshot.init)
        }
    }

    func minimalCoachContext(from snapshot: FeatureVectorSnapshot?, topic: String) -> CoachLLMContext {
        let summary: String
        if let features = snapshot?.features, !features.isEmpty {
            summary = features
                .sorted(by: { abs($0.value) > abs($1.value) })
                .prefix(5)
                .map { "\($0.key)=\(String(format: "%.2f", $0.value))" }
                .joined(separator: ", ")
        } else {
            summary = "insufficient recent data"
        }

        return CoachLLMContext(
            userToneHints: "supportive, concise",
            topSignal: "topic=\(topic)",
            topMomentId: nil,
            rationale: "User asked about \(topic)",
            zScoreSummary: summary
        )
    }

    private func makeCandidate(moment: MicroMomentSnapshot,
                               distance: Float,
                               snapshot: FeatureVectorSnapshot) async -> CardCandidate? {
        let evidenceStrength = badgeScore(moment.evidenceBadge)
        let acceptance = await acceptanceRate(for: moment.id)
        let cooldown = await cooldownScore(for: moment)
        let novelty = max(0, 1 - acceptance)
        let similarityScore = max(0, 1 - min(Double(distance) / 5, 1))
        let blendedNovelty = min(1, (novelty * 0.7) + (similarityScore * 0.3))
        let timeFit = timeCostFit(for: moment)
        let zScores = snapshot.features.reduce(into: [String: Double]()) { result, element in
            if element.key.hasPrefix("z_") {
                result[element.key] = element.value
            }
        }

        let features = RecommendationFeatures(id: moment.id,
                                              wellbeingScore: snapshot.wellbeingScore,
                                              evidenceStrength: evidenceStrength,
                                              novelty: blendedNovelty,
                                              cooldown: cooldown,
                                              acceptanceRate: acceptance,
                                              timeCostFit: timeFit,
                                              zScores: zScores)

        let card = RecommendationCard(id: moment.id,
                                      title: moment.title,
                                      body: buildBody(for: moment),
                                      caution: await cautionMessage(for: moment, snapshot: snapshot),
                                      sourceBadge: moment.evidenceBadge ?? "Weak")
        return CardCandidate(card: card, features: features)
    }

    public func currentLLMAPIKey() -> String? {
        llmGateway.currentAPIKey()
    }

    public func setLLMAPIKey(_ key: String) throws {
        try llmGateway.setAPIKey(key)
    }

    public func testLLMAPIConnection() async throws -> Bool {
        try await llmGateway.testAPIConnection()
    }

    private func buildBody(for moment: MicroMomentSnapshot) -> String {
        var paragraphs: [String] = [moment.shortDescription]
        if let detail = moment.detail, !detail.isEmpty {
            let filteredDetail = detail
                .split(separator: "\n")
                .filter { line in
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    return !trimmed.hasPrefix("Episode #")
                }
                .joined(separator: "\n")
            if !filteredDetail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                paragraphs.append(filteredDetail)
            }
        }
        if let cooldownSec = moment.cooldownSec, cooldownSec > 0 {
            let minutes = Int(cooldownSec) / 60
            paragraphs.append("Cooldown: \(minutes) min between repeats")
        }
        return paragraphs.prefix(2).joined(separator: "\n\n")
    }

    private func cautionMessage(for moment: MicroMomentSnapshot, snapshot: FeatureVectorSnapshot) async -> String? {
        #if canImport(FoundationModels) && os(iOS)
        // Use Foundation Models for intelligent caution assessment instead of simple rules
        if #available(iOS 26.0, *), SystemLanguageModel.default.isAvailable {
            return await generateFoundationModelsCaution(for: moment, snapshot: snapshot)
        }
        #endif
        // Fallback to basic heuristics only when Foundation Models unavailable
        guard let difficulty = moment.difficulty?.lowercased() else { return nil }
        if difficulty.contains("hard") {
            return "Check in with your energy before tackling this higher-effort option."
        }
        if moment.category?.lowercased().contains("injury") == true {
            return "Adjust intensity if your body signals any discomfort."
        }
        return nil
    }

    #if canImport(FoundationModels) && os(iOS)
    @available(iOS 26.0, *)
    private func generateFoundationModelsCaution(for moment: MicroMomentSnapshot, snapshot: FeatureVectorSnapshot) async -> String? {
        let session = LanguageModelSession(
            instructions: Instructions("""
            You are assessing whether a wellness activity needs a caution message.
            Generate a brief caution ONLY if the activity could be risky given the person's current state.
            Consider their energy levels, stress, and physical readiness.
            Keep cautions under 20 words and supportive in tone.
            Return empty string if no caution needed.
            """)
        )

        let contextInfo = """
        Activity: \(moment.title)
        Difficulty: \(moment.difficulty ?? "Unknown")
        Category: \(moment.category ?? "General")
        Current wellbeing score: \(snapshot.wellbeingScore)
        Energy level: \(snapshot.features["subj_energy"] ?? 0)
        Stress level: \(snapshot.features["subj_stress"] ?? 0)
        """

        do {
            let response = try await session.respond(
                to: Prompt("Should this activity have a caution message? \(contextInfo)"),
                options: GenerationOptions(temperature: 0.3)
            )
            let caution = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return caution.isEmpty ? nil : caution
        } catch {
            return nil // No caution on error
        }
    }
    #endif

    private func badgeScore(_ badge: String?) -> Double {
        switch badge {
        case EvidenceBadge.strong.rawValue:
            return 1.0
        case EvidenceBadge.medium.rawValue:
            return 0.7
        default:
            return 0.3
        }
    }

    private func cooldownScore(for moment: MicroMomentSnapshot) async -> Double {
        guard let cooldown = moment.cooldownSec, cooldown > 0 else { return 0 }
        let momentId = moment.id
        let elapsed: TimeInterval? = contextPerformAndWait { context in
            let request = RecommendationEvent.fetchRequest()
            request.predicate = NSPredicate(format: "momentId == %@ AND accepted == YES", momentId)
            request.sortDescriptors = [NSSortDescriptor(key: #keyPath(RecommendationEvent.completedAt), ascending: false)]
            request.fetchLimit = 1
            guard let last = try? context.fetch(request).first, let completed = last.completedAt else { return nil }
            return Date().timeIntervalSince(completed)
        }
        guard let elapsed else { return 0 }
        if elapsed >= cooldown { return 0 }
        return 1 - (elapsed / cooldown)
    }

    private func applyFeedback(for momentId: String, accepted: Bool) async -> (changedCount: Int, learningRateBucket: String)? {
        guard let target = lastRankedFeatures.first(where: { $0.id == momentId }) else { return nil }
        let comparators = lastRankedFeatures.filter { $0.id != momentId }
        guard !comparators.isEmpty else { return nil }

        for candidate in comparators {
            if accepted {
                ranker.update(preferred: target, other: candidate)
            } else {
                ranker.update(preferred: candidate, other: target)
            }
        }

        let history = await acceptanceHistory(for: momentId)
        ranker.updateLearningRate(basedOn: history)
        persistRankerState()
        return (changedCount: comparators.count, learningRateBucket: learningRateBucket(for: history.sampleCount))
    }

    private func learningRateBucket(for sampleCount: Int) -> String {
        switch sampleCount {
        case ..<3:
            return "coldstart"
        case 3 ..< 10:
            return "learning"
        default:
            return "stable"
        }
    }

    private func acceptanceHistory(for momentId: String) async -> AcceptanceHistory {
        contextPerformAndWait { context in
            let request = RecommendationEvent.fetchRequest()
            request.predicate = NSPredicate(format: "momentId == %@", momentId)
            guard let events = try? context.fetch(request), !events.isEmpty else {
                return AcceptanceHistory(rollingAcceptance: 0.5, sampleCount: 0)
            }
            let acceptances = events.filter { $0.accepted }.count
            let rate = Double(acceptances) / Double(events.count)
            return AcceptanceHistory(rollingAcceptance: rate, sampleCount: events.count)
        }
    }

    private func acceptanceRate(for momentId: String) async -> Double {
        contextPerformAndWait { context in
            let request = RecommendationEvent.fetchRequest()
            request.predicate = NSPredicate(format: "momentId == %@", momentId)
            guard let events = try? context.fetch(request), !events.isEmpty else { return 0.1 }
            let acceptances = events.filter { $0.accepted }.count
            return Double(acceptances) / Double(events.count)
        }
    }

    private func timeCostFit(for moment: MicroMomentSnapshot) -> Double {
        guard let seconds = moment.estimatedTimeSec else { return 0.5 }
        let normalized = max(0, min(1, 1 - (seconds / 1800)))
        return normalized
    }

    #if DEBUG
    func _testRankerMetrics() -> RankerMetrics {
        ranker.getPerformanceMetrics()
    }

    func _injectRankedFeaturesForTesting(_ features: [RecommendationFeatures]) {
        lastRankedFeatures = features
    }
    #endif
}

private struct CardCandidate {
    let card: RecommendationCard
    let features: RecommendationFeatures
}

private struct MicroMomentSnapshot: Sendable {
    let id: String
    let title: String
    let shortDescription: String
    let detail: String?
    let tags: [String]?
    let estimatedTimeSec: Double?
    let difficulty: String?
    let category: String?
    let evidenceBadge: String?
    let cooldownSec: Double?

    init(moment: MicroMoment) {
        id = moment.id
        title = moment.title
        shortDescription = moment.shortDescription
        detail = moment.detail
        tags = moment.tags
        estimatedTimeSec = moment.estimatedTimeSec?.doubleValue
        difficulty = moment.difficulty
        category = moment.category
        evidenceBadge = moment.evidenceBadge
        cooldownSec = moment.cooldownSec?.doubleValue
    }
}

private extension CoachAgent {
    func contextPerformAndWait<T>(_ work: (NSManagedObjectContext) -> T) -> T {
        let context = self.context
        return context.performAndWait {
            work(context)
        }
    }

    func contextPerformAndWait<T>(_ work: (NSManagedObjectContext) throws -> T) throws -> T {
        let context = self.context
        return try context.performAndWait {
            try work(context)
        }
    }

    func persistRankerState() {
        let state = ranker.snapshotState()
        rankerStore.saveState(state)
    }

    func fallbackRecommendations(snapshot: FeatureVectorSnapshot, topic: String?) async -> [RecommendationCard] {
        let topic = topic ?? "wellbeing"
        let moments = (try? await keywordBackfillMoments(for: topic, limit: 6)) ?? []
        guard !moments.isEmpty else { return [] }

        var candidates: [CardCandidate] = []
        for moment in moments {
            if let candidate = await makeCandidate(moment: moment, distance: 1.0, snapshot: snapshot) {
                candidates.append(candidate)
            }
        }
        guard !candidates.isEmpty else { return [] }

        let rankedFeatures = ranker.rank(candidates.map { $0.features })
        lastRankedFeatures = rankedFeatures
        var rankedCards: [RecommendationCard] = []
        for feature in rankedFeatures {
            guard let candidate = candidates.first(where: { $0.features.id == feature.id }) else { continue }
            rankedCards.append(candidate.card)
            if rankedCards.count == 3 { break }
        }
        return rankedCards
    }
}

public extension CoachAgent {
    var recommendationNotice: String? { lastRecommendationNotice }
}

private extension CoachAgent {
    func performLibraryPreparation() async throws {
        do {
            try await libraryImporter.ingestIfNeeded()
            libraryEmbeddingsDeferred = libraryImporter.lastImportHadDeferredEmbeddings
            hasPreparedLibrary = !libraryEmbeddingsDeferred
        } catch {
            hasPreparedLibrary = false
            libraryEmbeddingsDeferred = false
            throw error
        }
    }
}
