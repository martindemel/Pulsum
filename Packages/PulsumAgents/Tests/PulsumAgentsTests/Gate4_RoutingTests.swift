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
}

private func makeSnapshot(features: [String: Double]) throws -> FeatureVectorSnapshot {
    let container = TestCoreDataStack.makeContainer()
    let context = container.newBackgroundContext()

    var snapshot: FeatureVectorSnapshot?
    var capturedError: Error?

    context.performAndWait {
        do {
            let vector = FeatureVector(context: context)
            try context.obtainPermanentIDs(for: [vector])
            snapshot = FeatureVectorSnapshot(date: Date(),
                                             wellbeingScore: 0,
                                             contributions: [:],
                                             imputedFlags: [:],
                                             featureVectorObjectID: vector.objectID,
                                             features: features)
        } catch {
            capturedError = error
        }
    }

    if let capturedError {
        throw capturedError
    }
    guard let snapshot else {
        throw NSError(domain: "Gate4RoutingTests", code: 0)
    }
    return snapshot
}
