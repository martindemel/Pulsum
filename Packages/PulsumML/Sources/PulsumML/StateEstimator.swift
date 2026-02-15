import Foundation
import PulsumTypes

public struct StateEstimatorConfig {
    public let learningRate: Double
    public let regularization: Double
    public let weightCap: ClosedRange<Double>

    public init(learningRate: Double = 0.05,
                regularization: Double = 1e-3,
                weightCap: ClosedRange<Double> = -2.0 ... 2.0) {
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

public struct StateEstimatorState: Codable, Sendable {
    public let version: Int
    public let weights: [String: Double]
    public let bias: Double

    public init(version: Int = 1, weights: [String: Double], bias: Double) {
        self.version = version
        self.weights = weights
        self.bias = bias
    }
}

public actor StateEstimator {
    public static let defaultWeights: [String: Double] = [
        "z_hrv": 0.6,
        "z_nocthr": -0.45,
        "z_resthr": -0.35,
        "z_sleepDebt": -0.55,
        "z_steps": 0.3,
        "z_rr": -0.1,
        "subj_stress": -0.5,
        "subj_energy": 0.5,
        "subj_sleepQuality": 0.35,
        "sentiment": 0.25
    ]

    private let config: StateEstimatorConfig
    private var weights: [String: Double]
    private var bias: Double

    public init(initialWeights: [String: Double] = StateEstimator.defaultWeights,
                bias: Double = 0,
                config: StateEstimatorConfig = StateEstimatorConfig()) {
        self.weights = initialWeights
        self.config = config
        self.bias = bias
    }

    public init(state: StateEstimatorState, config: StateEstimatorConfig = StateEstimatorConfig()) {
        self.weights = state.weights
        self.bias = state.bias
        self.config = config
    }

    public func predict(features: [String: Double]) -> Double {
        guard features.allSatisfy({ !$0.value.isNaN }) else {
            Diagnostics.log(level: .warn, category: .dataAgent, name: "nan.features", fields: [:])
            return bias
        }
        let contributions = contributionVector(features: features)
        return contributions.values.reduce(bias, +)
    }

    public func update(features: [String: Double], target: Double) -> StateEstimatorSnapshot {
        guard features.allSatisfy({ !$0.value.isNaN }) else {
            Diagnostics.log(level: .warn, category: .dataAgent, name: "nan.features.update", fields: [:])
            return currentSnapshot(features: features)
        }
        guard !target.isNaN else {
            Diagnostics.log(level: .warn, category: .dataAgent, name: "nan.target.update", fields: [:])
            return currentSnapshot(features: features)
        }
        let prediction = predict(features: features)
        let error = target - prediction

        for (feature, value) in features {
            let gradient = -error * value + config.regularization * (weights[feature] ?? 0)
            var updated = (weights[feature] ?? 0) - config.learningRate * gradient
            updated = min(max(updated, config.weightCap.lowerBound), config.weightCap.upperBound)
            weights[feature] = updated
        }

        bias -= config.learningRate * -error

        let contributions = contributionVector(features: features)
        let wellbeing = contributions.values.reduce(bias, +)
        return StateEstimatorSnapshot(weights: weights, bias: bias, wellbeingScore: wellbeing, contributions: contributions)
    }

    public func currentSnapshot(features: [String: Double]) -> StateEstimatorSnapshot {
        let contributions = contributionVector(features: features)
        let wellbeing = contributions.values.reduce(bias, +)
        return StateEstimatorSnapshot(weights: weights, bias: bias, wellbeingScore: wellbeing, contributions: contributions)
    }

    public func persistedState(version: Int = 1) -> StateEstimatorState {
        StateEstimatorState(version: version, weights: weights, bias: bias)
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
