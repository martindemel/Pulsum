import Foundation

public struct StateEstimatorConfig {
    public let learningRate: Double
    public let regularization: Double
    public let weightCap: ClosedRange<Double>

    public init(learningRate: Double = 0.05,
                regularization: Double = 1e-3,
                weightCap: ClosedRange<Double> = -2.0...2.0) {
        self.learningRate = learningRate
        self.regularization = regularization
        self.weightCap = weightCap
    }
}

public struct StateEstimatorSnapshot: Sendable {
    public let weights: [String: Double]
    public let bias: Double
    public let wellbeingScore: Double
    public let contributions: [String: Double]
}

public final class StateEstimator {
    private let config: StateEstimatorConfig
    private var weights: [String: Double]
    private var bias: Double

    public init(initialWeights: [String: Double] = [
        "z_hrv": -0.6,
        "z_nocthr": 0.5,
        "z_resthr": 0.4,
        "z_sleepDebt": 0.5,
        "z_steps": -0.2,
        "z_rr": 0.1,
        "subj_stress": 0.6,
        "subj_energy": -0.6,
        "subj_sleepQuality": 0.4
    ], config: StateEstimatorConfig = StateEstimatorConfig()) {
        self.weights = initialWeights
        self.config = config
        self.bias = 0
    }

    public func predict(features: [String: Double]) -> Double {
        let contributions = contributionVector(features: features)
        return contributions.values.reduce(bias, +)
    }

    public func update(features: [String: Double], target: Double) -> StateEstimatorSnapshot {
        let prediction = predict(features: features)
        let error = target - prediction

        for (feature, value) in features {
            let gradient = -error * value + config.regularization * (weights[feature] ?? 0)
            var updated = (weights[feature] ?? 0) - config.learningRate * gradient
            updated = min(max(updated, config.weightCap.lowerBound), config.weightCap.upperBound)
            weights[feature] = updated
        }

        bias -= config.learningRate * (-error)

        let contributions = contributionVector(features: features)
        let wellbeing = contributions.values.reduce(bias, +)
        return StateEstimatorSnapshot(weights: weights, bias: bias, wellbeingScore: wellbeing, contributions: contributions)
    }

    public func currentSnapshot(features: [String: Double]) -> StateEstimatorSnapshot {
        let contributions = contributionVector(features: features)
        let wellbeing = contributions.values.reduce(bias, +)
        return StateEstimatorSnapshot(weights: weights, bias: bias, wellbeingScore: wellbeing, contributions: contributions)
    }

    private func contributionVector(features: [String: Double]) -> [String: Double] {
        var result: [String: Double] = [:]
        result.reserveCapacity(features.count)
        for (feature, value) in features {
            let weight = weights[feature] ?? 0
            result[feature] = weight * value
        }
        return result
    }
}
