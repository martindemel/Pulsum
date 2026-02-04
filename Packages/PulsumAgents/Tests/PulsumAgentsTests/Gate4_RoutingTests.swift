import Testing
import CoreData
@testable import PulsumAgents
@testable import PulsumData

struct Gate4_RoutingTests {

    @Test("Fallback picks the max absolute z-score")
    func fallbackUsesMaximumMagnitude() throws {
        let snapshot = try makeSnapshot(features: [
            "z_hrv": -0.4,
            "subj_stress": 0.25,
            "z_sleepDebt": 1.3,
            "subj_energy": 0.1
        ])
        let signal = TopicSignalResolver.dataDominantSignal(from: snapshot)
        #expect(signal == "z_sleepDebt")
    }

    @Test("Fallback ignores unknown feature keys")
    func fallbackIgnoresUnknownKeys() throws {
        let snapshot = try makeSnapshot(features: [
            "custom_window": 9.9,
            "subj_energy": 0.2,
            "z_rr": 0.3
        ])
        let signal = TopicSignalResolver.dataDominantSignal(from: snapshot)
        #expect(signal == "z_rr")
    }

    @Test("Topic override pipeline remains deterministic")
    func topicOverrideDeterministic() throws {
        let snapshot = try makeSnapshot(features: [
            "z_hrv": 0.6,
            "z_rr": 0.6,
            "subj_sleepQuality": -0.1
        ])
        let mapped = TopicSignalResolver.mapTopicToSignalOrDataDominant(topic: "sleep", snapshot: snapshot)
        #expect(mapped == "subj_sleepQuality")

        let fallback = TopicSignalResolver.mapTopicToSignalOrDataDominant(topic: nil, snapshot: snapshot)
        #expect(fallback == "z_hrv")
    }

    @Test("candidateMoments omit detail when source is nil")
    func candidateMomentsHandleNilDetail() async throws {
        let container = TestCoreDataStack.makeContainer()
        let context = container.newBackgroundContext()
        try context.performAndWait {
            let moment = MicroMoment(context: context)
            moment.id = "moment-1"
            moment.title = "Breathing reset"
            moment.shortDescription = "Take three calm breaths."
            moment.detail = nil
            moment.evidenceBadge = "Strong"
            try context.save()
        }

        let stubIndex = RoutingVectorIndexStub(matches: [VectorMatch(id: "moment-1", score: 0.1)])
        let agent = try await MainActor.run {
            try CoachAgent(container: container,
                           vectorIndex: stubIndex,
                           libraryImporter: LibraryImporter(),
                           shouldIngestLibrary: false)
        }
        let candidates = await agent.candidateMoments(for: "stress", limit: 1)
        #expect(candidates.count == 1)
        #expect(candidates.first?.detail == nil)
    }
}

private func makeSnapshot(features: [String: Double]) throws -> FeatureVectorSnapshot {
    let container = TestCoreDataStack.makeContainer()
    let context = container.newBackgroundContext()

    return try context.performAndWaitThrowing {
        let vector = FeatureVector(context: context)
        try context.obtainPermanentIDs(for: [vector])
        return FeatureVectorSnapshot(date: Date(),
                                     wellbeingScore: 0,
                                     contributions: [:],
                                     imputedFlags: [:],
                                     featureVectorObjectID: vector.objectID,
                                     features: features)
    }
}

private extension NSManagedObjectContext {
    func performAndWaitThrowing<T>(_ block: () throws -> T) throws -> T {
        var result: Result<T, Error>!
        performAndWait {
            result = Result { try block() }
        }
        return try result.get()
    }
}

private actor RoutingVectorIndexStub: VectorIndexProviding {
    private let storedMatches: [VectorMatch]

    init(matches: [VectorMatch]) {
        self.storedMatches = matches
    }

    @discardableResult
    func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) async throws -> [Float] {
        []
    }

    func removeMicroMoment(id: String) async throws {}

    func searchMicroMoments(query: String, topK: Int) async throws -> [VectorMatch] {
        storedMatches
    }
}
