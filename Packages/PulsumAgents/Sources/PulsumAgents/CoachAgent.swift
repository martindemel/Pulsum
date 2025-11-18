import Foundation
import CoreData
#if canImport(FoundationModels)
import FoundationModels
#endif
import os
import PulsumData
import PulsumML
import PulsumServices

@MainActor
public final class CoachAgent {
    private let context: NSManagedObjectContext
    private let vectorIndex: VectorIndexProviding
    private let ranker = RecRanker()
    private let libraryImporter: LibraryImporter
    private let llmGateway: LLMGateway
    private let shouldIngestLibrary: Bool
    private var hasPreparedLibrary = false
    private let logger = Logger(subsystem: "com.pulsum", category: "CoachAgent")

    public init(container: NSPersistentContainer = PulsumData.container,
                vectorIndex: VectorIndexProviding = VectorIndexManager.shared,
                libraryImporter: LibraryImporter = LibraryImporter(),
                llmGateway: LLMGateway = LLMGateway(),
                shouldIngestLibrary: Bool = true) throws {
        self.context = container.newBackgroundContext()
        self.context.name = "Pulsum.CoachAgent.FoundationModels"
        self.context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        self.vectorIndex = vectorIndex
        self.libraryImporter = libraryImporter
        self.llmGateway = llmGateway
        self.shouldIngestLibrary = shouldIngestLibrary
    }

    public func prepareLibraryIfNeeded() async throws {
        guard shouldIngestLibrary, !hasPreparedLibrary else { return }
        do {
            try await libraryImporter.ingestIfNeeded()
            hasPreparedLibrary = true
        } catch {
            hasPreparedLibrary = false
            throw error
        }
    }

    public func recommendationCards(for snapshot: FeatureVectorSnapshot,
                                    consentGranted: Bool) async throws -> [RecommendationCard] {
        let query = buildQuery(from: snapshot)
        let matches = try vectorIndex.searchMicroMoments(query: query, topK: 20)
        guard !matches.isEmpty else { return [] }

        let scoreLookup = Dictionary(uniqueKeysWithValues: matches.map { ($0.id, $0.score) })
        let moments = try await fetchMicroMoments(ids: Array(scoreLookup.keys))

        var candidates: [CardCandidate] = []
        for moment in moments {
            guard let distance = scoreLookup[moment.id] else { continue }
            if let candidate = await makeCandidate(moment: moment,
                                                   distance: distance,
                                                   snapshot: snapshot) {
                candidates.append(candidate)
            }
        }

        guard !candidates.isEmpty else { return [] }

        let rankedFeatures = ranker.rank(candidates.map { $0.features })
        var rankedCards: [RecommendationCard] = []
        for feature in rankedFeatures {
            guard let candidate = candidates.first(where: { $0.features.id == feature.id }) else { continue }
            rankedCards.append(candidate.card)
            if rankedCards.count == 3 { break }
        }
        return rankedCards
    }

    public func chatResponse(userInput: String,
                             snapshot: FeatureVectorSnapshot,
                             consentGranted: Bool,
                             intentTopic: String?,
                             topSignal: String,
                             groundingFloor: Double) async -> CoachReplyPayload {
        let sanitizedInput = PIIRedactor.redact(userInput)
        logger.debug("Preparing chat response. Consent: \(consentGranted, privacy: .public), input: \(String(sanitizedInput.prefix(160)), privacy: .public)")
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
        logger.debug("LLM context built. Top signal: \(context.topSignal, privacy: .public), intentTopic: \(intentTopic ?? "none", privacy: .public), rationale: \(context.rationale, privacy: .public), zScores: \(String(context.zScoreSummary.prefix(200)), privacy: .public)")
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
        try await context.perform { [context] in
            let event = RecommendationEvent(context: context)
            event.momentId = momentId
            event.date = Date()
            event.accepted = accepted
            event.completedAt = accepted ? Date() : nil
            try context.save()
        }
    }

    public func momentTitle(for id: String) async -> String? {
        await context.perform { [context] in
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
        guard let matches = try? vectorIndex.searchMicroMoments(query: query, topK: limit),
              !matches.isEmpty else {
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

    private func fetchMicroMoments(ids: [String]) async throws -> [MicroMoment] {
        try await context.perform { [context] in
            let request = MicroMoment.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", ids)
            return try context.fetch(request)
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
        var matches = try vectorIndex.searchMicroMoments(query: query, topK: 20)
        var decision = decideCoverage(CoverageInputs(l2Matches: matches,
                                                     canonicalTopic: canonicalTopic,
                                                     snapshot: snapshot))

        if case .fail = decision.kind, let topic = canonicalTopic {
            let backfill = try await keywordBackfillMoments(for: topic, limit: 8)
            for moment in backfill {
                let backfillMatches = try vectorIndex.searchMicroMoments(query: moment.title, topK: 1)
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
                                        limit: Int) async throws -> [MicroMoment] {
        try await context.perform { [context] in
            let request = NSFetchRequest<MicroMoment>(entityName: "MicroMoment")
            request.fetchLimit = limit
            request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "title CONTAINS[c] %@", topic),
                NSPredicate(format: "ANY tags CONTAINS[c] %@", topic)
            ])
            return try context.fetch(request)
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

    private func makeCandidate(moment: MicroMoment,
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

    private func buildBody(for moment: MicroMoment) -> String {
        var paragraphs: [String] = [moment.shortDescription]
        if let detail = moment.detail, !detail.isEmpty {
            paragraphs.append(detail)
        }
        if let activity = moment.cooldownSec?.intValue, activity > 0 {
            paragraphs.append("Cooldown: \(activity / 60) min between repeats")
        }
        return paragraphs.prefix(2).joined(separator: "\n\n")
    }

    private func cautionMessage(for moment: MicroMoment, snapshot: FeatureVectorSnapshot) async -> String? {
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
    private func generateFoundationModelsCaution(for moment: MicroMoment, snapshot: FeatureVectorSnapshot) async -> String? {
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

    private func cooldownScore(for moment: MicroMoment) async -> Double {
        guard let cooldown = moment.cooldownSec?.doubleValue, cooldown > 0 else { return 0 }
        let momentId = moment.id
        let elapsed: TimeInterval? = await context.perform { [context] in
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

    private func acceptanceRate(for momentId: String) async -> Double {
        await context.perform { [context] in
            let request = RecommendationEvent.fetchRequest()
            request.predicate = NSPredicate(format: "momentId == %@", momentId)
            guard let events = try? context.fetch(request), !events.isEmpty else { return 0.1 }
            let acceptances = events.filter { $0.accepted }.count
            return Double(acceptances) / Double(events.count)
        }
    }

    private func timeCostFit(for moment: MicroMoment) -> Double {
        guard let seconds = moment.estimatedTimeSec?.doubleValue else { return 0.5 }
        let normalized = max(0, min(1, 1 - (seconds / 1800)))
        return normalized
    }
}

private struct CardCandidate {
    let card: RecommendationCard
    let features: RecommendationFeatures
}
