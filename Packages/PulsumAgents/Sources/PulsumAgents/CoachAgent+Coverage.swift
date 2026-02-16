import Foundation
import PulsumData
import PulsumTypes

public enum CoveragePassKind: Sendable {
    case strong
    case soft
    case fail
}

public struct CoverageDecision: Sendable {
    public let kind: CoveragePassKind
    public let reason: String
    public let count: Int
    public let top: Double
    public let median: Double
    public let thresholdUsed: Double
}

@inline(__always)
private func simFromL2(_ d: Double) -> Double {
    let clamped = min(max(d, 0.0), 4.0)
    return 1.0 / (1.0 + clamped)
}

@inline(__always)
private func median(_ xs: [Double]) -> Double {
    guard !xs.isEmpty else { return 0 }
    let sorted = xs.sorted()
    let mid = sorted.count / 2
    if sorted.count % 2 == 0 {
        return (sorted[mid - 1] + sorted[mid]) / 2.0
    } else {
        return sorted[mid]
    }
}

public struct CoverageInputs {
    public let l2Matches: [VectorMatch]
    public let canonicalTopic: String?
    public let snapshot: FeatureVectorSnapshot?

    public init(l2Matches: [VectorMatch], canonicalTopic: String?, snapshot: FeatureVectorSnapshot?) {
        self.l2Matches = l2Matches
        self.canonicalTopic = canonicalTopic
        self.snapshot = snapshot
    }
}

public func decideCoverage(_ input: CoverageInputs) -> CoverageDecision {
    let sims = input.l2Matches.prefix(10).map { simFromL2(Double($0.score)) }
    let count = sims.count
    let top = sims.max() ?? 0.0
    let med = median(sims)
    let onTopic = (input.canonicalTopic != nil)

    let sparse: Bool = {
        guard let snapshot = input.snapshot else { return true }
        let flags = snapshot.imputedFlags
        let imputedHRV = flags["hrv"] == true
        let imputedResting = flags["restingHR"] == true
        let missingSteps = flags["steps_missing"] == true
        return imputedHRV || imputedResting || missingSteps
    }()

    // Strong pass: ≥3 matches with median similarity ≥0.42 and best match ≥0.58.
    // These thresholds were tuned on the Huberman library (~200 moments): 0.42 median
    // filters out random noise while 0.58 top ensures at least one highly relevant result.
    if count >= 3 && med >= 0.42 && top >= 0.58 {
        return CoverageDecision(kind: .strong,
                                reason: "strong-pass",
                                count: count,
                                top: top,
                                median: med,
                                thresholdUsed: 0.42)
    }

    // Soft pass (on-topic): when topic gate confirms relevance, accept lower median (0.35)
    // because the topic signal compensates for weaker embedding coverage.
    if onTopic && med >= 0.35 {
        return CoverageDecision(kind: .soft,
                                reason: "on-topic-median",
                                count: count,
                                top: top,
                                median: med,
                                thresholdUsed: 0.35)
    }

    // Cohesive soft pass: top match is decent (≥0.50) and the median/top ratio ≥0.70
    // indicates tightly clustered results rather than one lucky outlier.
    if onTopic && top >= 0.50 && med > 0 && (med / max(top, 1e-6)) >= 0.70 {
        return CoverageDecision(kind: .soft,
                                reason: "cohesive-soft",
                                count: count,
                                top: top,
                                median: med,
                                thresholdUsed: 0.35)
    }

    // Sparse data fallback: when health metrics are imputed or missing, relax thresholds
    // to avoid blocking coaching entirely during the user's first days of data collection.
    // Still reject clearly off-topic queries (top similarity < 0.30).
    if sparse {
        if top < 0.30 {
            return CoverageDecision(kind: .fail,
                                    reason: "data-sparse-off-topic",
                                    count: count,
                                    top: top,
                                    median: med,
                                    thresholdUsed: 0.30)
        }
        return CoverageDecision(kind: .soft,
                                reason: "data-sparse-soft",
                                count: count,
                                top: top,
                                median: med,
                                thresholdUsed: 0.30)
    }

    // Fail: none of the above gates passed. The 0.40 threshold is recorded for diagnostics.
    return CoverageDecision(kind: .fail,
                            reason: "low-coverage",
                            count: count,
                            top: top,
                            median: med,
                            thresholdUsed: 0.40)
}

public func logCoverage(_ decision: CoverageDecision) {
    Diagnostics.log(level: .debug,
                    category: .coach,
                    name: "coach.coverage.decision",
                    fields: [
                        "kind": .safeString(.stage("\(decision.kind)", allowed: ["strong", "soft", "fail"])),
                        "reason": .safeString(.metadata(decision.reason)),
                        "match_count": .int(decision.count),
                        "top": .double(decision.top),
                        "median": .double(decision.median),
                        "threshold": .double(decision.thresholdUsed)
                    ])
}
