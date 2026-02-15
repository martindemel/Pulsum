import Foundation
import SwiftData

public struct FeatureVectorSnapshot: Sendable {
    public let date: Date
    public let wellbeingScore: Double
    public let contributions: [String: Double]
    public let imputedFlags: [String: Bool]
    public let featureVectorObjectID: PersistentIdentifier
    public let features: [String: Double]
}

public struct ScoreBreakdown: Sendable {
    public struct MetricDetail: Identifiable, Sendable {
        public enum Kind: String, Sendable {
            case objective
            case subjective
            case sentiment
        }

        public struct Coverage: Sendable {
            public let daysWithSamples: Int
            public let sampleCount: Int
        }

        public let id: String
        public let name: String
        public let kind: Kind
        public let value: Double?
        public let unit: String?
        public let zScore: Double?
        public let contribution: Double
        public let baselineMedian: Double?
        public let baselineEwma: Double?
        public let baselineMad: Double?
        public let rollingWindowDays: Int?
        public let explanation: String
        public let notes: [String]
        public let coverage: Coverage?
    }

    public let date: Date
    public let wellbeingScore: Double
    public let metrics: [MetricDetail]
    public let generalNotes: [String]
}

enum SnapshotPlaceholder {
    static let imputedFlagKey = "snapshot_placeholder"

    static func isPlaceholder(_ flags: [String: Bool]) -> Bool {
        flags[imputedFlagKey] == true
    }

    static func isPlaceholder(_ snapshot: FeatureVectorSnapshot) -> Bool {
        isPlaceholder(snapshot.imputedFlags)
    }
}

struct DataAgentBootstrapPolicy: Sendable {
    let bootstrapTimeoutSeconds: Double
    let heartRateTimeoutSeconds: Double
    let backfillTimeoutSeconds: Double
    let placeholderDeadlineSeconds: Double
    let retryDelaySeconds: Double
    let retryTimeoutSeconds: Double
    let retryMaxAttempts: Int
    let retryMaxElapsedSeconds: Double

    static let `default` = DataAgentBootstrapPolicy(
        bootstrapTimeoutSeconds: 3,
        heartRateTimeoutSeconds: 3,
        backfillTimeoutSeconds: 5,
        placeholderDeadlineSeconds: 5,
        retryDelaySeconds: 4,
        retryTimeoutSeconds: 10,
        retryMaxAttempts: 2,
        retryMaxElapsedSeconds: 60
    )
}

enum BootstrapBatchResult: String {
    case success
    case empty
    case timeout
    case error
    case cancelled
}

// MARK: - Supporting Types

struct FeatureBundle {
    static let requiredKeys: Set<String> = [
        "z_hrv",
        "z_nocthr",
        "z_resthr",
        "z_sleepDebt",
        "z_rr",
        "z_steps",
        "subj_stress",
        "subj_energy",
        "subj_sleepQuality",
        "sentiment"
    ]

    var values: [String: Double]
    var imputed: [String: Bool]
}

struct FeatureComputation: Sendable {
    let date: Date
    let featureValues: [String: Double]
    let imputedFlags: [String: Bool]
    let featureVectorObjectID: PersistentIdentifier
}
