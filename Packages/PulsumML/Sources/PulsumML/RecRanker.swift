import Foundation

public struct RecommendationFeatures {
    public let id: String
    public let wellbeingScore: Double
    public let evidenceStrength: Double
    public let novelty: Double
    public let cooldown: Double
    public let acceptanceRate: Double
    public let timeCostFit: Double
    public let zScores: [String: Double]

    public init(id: String,
                wellbeingScore: Double,
                evidenceStrength: Double,
                novelty: Double,
                cooldown: Double,
                acceptanceRate: Double,
                timeCostFit: Double,
                zScores: [String: Double] = [:]) {
        self.id = id
        self.wellbeingScore = wellbeingScore
        self.evidenceStrength = evidenceStrength
        self.novelty = novelty
        self.cooldown = cooldown
        self.acceptanceRate = acceptanceRate
        self.timeCostFit = timeCostFit
        self.zScores = zScores
    }

    public var vector: [String: Double] {
        var base: [String: Double] = [
            "bias": 1,
            "wellbeing": wellbeingScore,
            "evidence": evidenceStrength,
            "novelty": novelty,
            "cooldown": cooldown,
            "acceptance": acceptanceRate,
            "timeCostFit": timeCostFit
        ]
        for (key, value) in zScores {
            base[key] = value
        }
        return base
    }
}

public struct AcceptanceHistory {
    public let rollingAcceptance: Double
    public let sampleCount: Int

    public init(rollingAcceptance: Double, sampleCount: Int) {
        self.rollingAcceptance = rollingAcceptance
        self.sampleCount = sampleCount
    }
}

public struct UserFeedback {
    public let featureId: String
    public let delta: Double

    public init(featureId: String, delta: Double) {
        self.featureId = featureId
        self.delta = delta
    }
}

public struct RankerMetrics {
    public let weights: [String: Double]
    public let learningRate: Double

    public init(weights: [String: Double], learningRate: Double) {
        self.weights = weights
        self.learningRate = learningRate
    }
}

public struct RecRankerState: Codable, Equatable {
    public let version: Int
    public let weights: [String: Double]
    public let learningRate: Double

    public init(version: Int, weights: [String: Double], learningRate: Double) {
        self.version = version
        self.weights = weights
        self.learningRate = learningRate
    }
}

public final class RecRanker {
    private static let schemaVersion = 1
    private static let defaultWeights: [String: Double] = [
        "bias": 0.0,
        "wellbeing": -0.2,
        "evidence": 0.6,
        "novelty": 0.4,
        "cooldown": -0.5,
        "acceptance": 0.3,
        "timeCostFit": 0.2,
        "z_hrv": 0.25,
        "z_nocthr": -0.2,
        "z_resthr": -0.2,
        "z_sleepDebt": -0.25,
        "z_rr": -0.05,
        "z_steps": 0.18
    ]

    private var weights: [String: Double]
    private var learningRate: Double
    private let weightCap: ClosedRange<Double> = -3.0...3.0

    public init(state: RecRankerState? = nil) {
        self.weights = Self.defaultWeights
        self.learningRate = 0.05
        if let state {
            apply(state: state)
        }
    }

    public func score(features: RecommendationFeatures) -> Double {
        logistic(dot(weights: weights, features: features.vector))
    }

    public func rank(_ candidates: [RecommendationFeatures]) -> [RecommendationFeatures] {
        candidates.sorted { score(features: $0) > score(features: $1) }
    }

    public func update(preferred: RecommendationFeatures, other: RecommendationFeatures) {
        let preferredScore = score(features: preferred)
        let otherScore = score(features: other)
        let gradientPreferred = 1 - preferredScore
        let gradientOther = -otherScore

        applyGradient(features: preferred.vector, gradient: gradientPreferred)
        applyGradient(features: other.vector, gradient: gradientOther)
    }

    public func updateLearningRate(basedOn history: AcceptanceHistory) {
        let normalized = max(0, min(history.rollingAcceptance, 1))
        if history.sampleCount < 10 {
            learningRate = 0.08
        } else if normalized < 0.35 {
            learningRate = 0.07
        } else if normalized > 0.75 {
            learningRate = 0.03
        } else {
            learningRate = 0.05
        }
    }

    public func adaptWeights(from feedback: [UserFeedback]) {
        guard !feedback.isEmpty else { return }
        for entry in feedback {
            let updated = clampedWeight((weights[entry.featureId] ?? 0) + entry.delta)
            weights[entry.featureId] = updated
        }
    }

    public func getPerformanceMetrics() -> RankerMetrics {
        RankerMetrics(weights: weights, learningRate: learningRate)
    }

    public func snapshotState() -> RecRankerState {
        RecRankerState(version: Self.schemaVersion, weights: weights, learningRate: learningRate)
    }

    private func applyGradient(features: [String: Double], gradient: Double) {
        for (feature, value) in features {
            let updated = clampedWeight((weights[feature] ?? 0) + learningRate * gradient * value)
            weights[feature] = updated
        }
    }

    private func dot(weights: [String: Double], features: [String: Double]) -> Double {
        weights.reduce(into: 0.0) { result, element in
            result += element.value * (features[element.key] ?? 0)
        }
    }

    private func logistic(_ x: Double) -> Double {
        1 / (1 + exp(-x))
    }

    private func clampedWeight(_ value: Double) -> Double {
        min(max(value, weightCap.lowerBound), weightCap.upperBound)
    }

    private func apply(state: RecRankerState) {
        guard state.version == Self.schemaVersion else { return }
        for (key, value) in state.weights {
            weights[key] = clampedWeight(value)
        }
        learningRate = state.learningRate
    }
}
