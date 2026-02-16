import Testing
@testable import PulsumML

// MARK: - StateEstimator predict & update tests

struct StateEstimatorTests {
    @Test("Predict with full feature vector produces expected range")
    func predictWithFullFeatureVector() async {
        let estimator = StateEstimator()
        let features: [String: Double] = [
            "z_hrv": 1.0,
            "z_nocthr": -0.5,
            "z_resthr": -0.3,
            "z_sleepDebt": -0.2,
            "z_steps": 0.8,
            "z_rr": 0.0,
            "subj_stress": 3.0,
            "subj_energy": 6.0,
            "subj_sleepQuality": 5.0,
            "sentiment": 0.5,
        ]
        let score = await estimator.predict(features: features)
        // Score should be a finite number in a reasonable range
        #expect(score.isFinite)
        #expect(score > -10 && score < 10)
    }

    @Test("Predict with missing features uses zero imputation")
    func predictWithMissingFeatures() async {
        let estimator = StateEstimator()
        // Only provide a subset of features; missing keys get weight*0 = 0
        let features: [String: Double] = [
            "z_hrv": 1.5,
            "subj_energy": 5.0,
        ]
        let score = await estimator.predict(features: features)
        #expect(score.isFinite)

        // Score should equal: w_hrv * 1.5 + w_energy * 5.0 + bias
        let expected = 0.6 * 1.5 + 0.5 * 5.0 + 0
        #expect(abs(score - expected) < 0.001)
    }

    @Test("Predict with empty features returns bias")
    func predictWithEmptyFeaturesReturnsBias() async {
        let estimator = StateEstimator(bias: 0.42)
        let score = await estimator.predict(features: [:])
        #expect(abs(score - 0.42) < 0.001)
    }

    @Test("Update moves weights toward target")
    func updateMovesWeightsTowardTarget() async {
        let estimator = StateEstimator()
        let features: [String: Double] = [
            "z_hrv": 1.0,
            "z_steps": 0.5,
            "subj_energy": 6.0,
        ]

        let before = await estimator.predict(features: features)
        let target = before + 2.0 // target is above current prediction
        let snapshot = await estimator.update(features: features, target: target)

        // After one update step, the prediction should be closer to the target
        let after = snapshot.wellbeingScore
        #expect(abs(after - target) < abs(before - target),
                "Update should move prediction closer to target")
    }

    @Test("Update with NaN features does not modify weights")
    func updateWithNaNFeaturesDoesNotModifyWeights() async {
        let estimator = StateEstimator(
            initialWeights: ["z_hrv": 0.6, "subj_energy": 0.5],
            bias: 1.0
        )
        let features: [String: Double] = [
            "z_hrv": .nan,
            "subj_energy": 5.0,
        ]
        let stateBefore = await estimator.persistedState()
        _ = await estimator.update(features: features, target: 3.0)
        let stateAfter = await estimator.persistedState()

        // Weights should be unchanged since NaN was detected
        #expect(stateAfter.weights == stateBefore.weights)
        #expect(abs(stateAfter.bias - stateBefore.bias) < 0.001)
    }

    @Test("Update with NaN target does not modify weights")
    func updateWithNaNTargetDoesNotModifyWeights() async {
        let estimator = StateEstimator(
            initialWeights: ["z_hrv": 0.6, "subj_energy": 0.5],
            bias: 1.0
        )
        let features: [String: Double] = [
            "z_hrv": 1.0,
            "subj_energy": 5.0,
        ]
        let stateBefore = await estimator.persistedState()
        _ = await estimator.update(features: features, target: .nan)
        let stateAfter = await estimator.persistedState()

        // Weights and bias should be unchanged since NaN target was rejected
        #expect(stateAfter.weights == stateBefore.weights)
        #expect(abs(stateAfter.bias - stateBefore.bias) < 0.001)
    }

    @Test("Weights stay within cap after many updates")
    func weightsCappedAfterManyUpdates() async {
        let config = StateEstimatorConfig(learningRate: 0.5, regularization: 0, weightCap: -2.0 ... 2.0)
        let estimator = StateEstimator(config: config)
        let features: [String: Double] = ["z_hrv": 10.0]

        // Drive weights with extreme values repeatedly
        for _ in 0 ..< 100 {
            _ = await estimator.update(features: features, target: 1000)
        }
        let state = await estimator.persistedState()
        for (_, weight) in state.weights {
            #expect(weight >= -2.0 && weight <= 2.0, "Weight should be within cap")
        }
    }

    @Test("Snapshot includes correct contributions")
    func snapshotContributions() async {
        let weights: [String: Double] = ["z_hrv": 0.5, "z_steps": 0.3]
        let estimator = StateEstimator(initialWeights: weights, bias: 0.1)
        let features: [String: Double] = ["z_hrv": 2.0, "z_steps": 1.0]
        let snapshot = await estimator.currentSnapshot(features: features)

        #expect(abs((snapshot.contributions["z_hrv"] ?? 0) - 1.0) < 0.001)
        #expect(abs((snapshot.contributions["z_steps"] ?? 0) - 0.3) < 0.001)
        #expect(abs(snapshot.wellbeingScore - 1.4) < 0.001) // 1.0 + 0.3 + 0.1
    }

    @Test("PersistedState round-trips correctly")
    func persistedStateRoundTrips() async {
        let estimator = StateEstimator(
            initialWeights: ["z_hrv": 0.7, "sentiment": 0.3],
            bias: 0.15
        )
        let state = await estimator.persistedState()

        let restored = StateEstimator(state: state)
        let restoredState = await restored.persistedState()

        #expect(restoredState.weights == state.weights)
        #expect(abs(restoredState.bias - state.bias) < 0.001)
    }
}

// MARK: - BaselineMath tests

struct BaselineMathTests {
    @Test("Baseline with sufficient history computes robust stats")
    func baselineWithSufficientHistory() {
        let values = [50.0, 52.0, 48.0, 55.0, 47.0, 51.0, 49.0, 53.0, 50.0, 46.0,
                      54.0, 50.0, 48.0, 52.0, 51.0, 49.0, 53.0, 47.0, 55.0, 48.0,
                      50.0, 52.0, 49.0, 51.0, 48.0, 53.0, 50.0, 47.0, 54.0, 50.0]
        let stats = BaselineMath.robustStats(for: values)
        #expect(stats != nil)
        #expect(stats!.median > 45 && stats!.median < 55)
        #expect(stats!.mad > 0)
    }

    @Test("Baseline with insufficient history returns nil")
    func baselineWithNoHistory() {
        let stats = BaselineMath.robustStats(for: [])
        #expect(stats == nil)
    }

    @Test("Baseline with single value produces valid stats")
    func baselineWithSingleValue() {
        let stats = BaselineMath.robustStats(for: [42.0])
        #expect(stats != nil)
        #expect(abs(stats!.median - 42.0) < 0.001)
        // MAD of single value is 0, but clamped to epsilon
        #expect(stats!.mad >= 1e-6)
    }

    @Test("z-score computation with zero MAD uses epsilon guard")
    func zScoreWithZeroMAD() {
        // All identical values produce MAD = 0, but robustStats clamps to 1e-6
        let stats = BaselineMath.robustStats(for: [50.0, 50.0, 50.0, 50.0, 50.0])!
        #expect(stats.mad >= 1e-6, "MAD should be clamped to at least epsilon")

        let z = BaselineMath.zScore(value: 51.0, stats: stats)
        #expect(z.isFinite, "z-score should be finite even with near-zero MAD")
        #expect(z > 0, "Value above median should produce positive z-score")
    }

    @Test("RobustStats init with mad=0 clamps to epsilon")
    func robustStatsMadZeroClampedToEpsilon() {
        let stats = BaselineMath.RobustStats(median: 50.0, mad: 0)
        #expect(stats.mad >= 1e-6, "MAD should be clamped to at least 1e-6")

        let z = BaselineMath.zScore(value: 51.0, stats: stats)
        #expect(z.isFinite, "z-score should be finite even when init receives mad=0")
        #expect(z > 0, "Value above median should produce positive z-score")
    }

    @Test("RobustStats init with negative mad clamps to epsilon")
    func robustStatsNegativeMadClampedToEpsilon() {
        let stats = BaselineMath.RobustStats(median: 50.0, mad: -5.0)
        #expect(stats.mad >= 1e-6, "Negative MAD should be clamped to at least 1e-6")
    }

    @Test("z-score computation with normal MAD")
    func zScoreWithNormalMAD() {
        let stats = BaselineMath.RobustStats(median: 50.0, mad: 5.0)
        let z = BaselineMath.zScore(value: 55.0, stats: stats)
        #expect(abs(z - 1.0) < 0.001) // (55 - 50) / 5 = 1.0
    }

    @Test("EWMA with no previous value returns new value")
    func ewmaWithNoPrevious() {
        let result = BaselineMath.ewma(previous: nil, newValue: 42.0)
        #expect(abs(result - 42.0) < 0.001)
    }

    @Test("EWMA weights previous value appropriately")
    func ewmaWeightsPrevious() {
        let result = BaselineMath.ewma(previous: 50.0, newValue: 60.0, lambda: 0.2)
        // 0.2 * 60 + 0.8 * 50 = 12 + 40 = 52
        #expect(abs(result - 52.0) < 0.001)
    }
}

// MARK: - FeatureVectorSnapshot Sendable compile-time check

struct FeatureVectorSnapshotSendableTests {
    @Test("FeatureVectorSnapshot is Sendable")
    func featureVectorSnapshotIsSendable() async {
        // Compile-time check: if FeatureVectorSnapshot is not Sendable, this won't compile.
        let _: any Sendable = StateEstimatorSnapshot(
            weights: ["z_hrv": 0.5],
            bias: 0.0,
            wellbeingScore: 0.5,
            contributions: ["z_hrv": 0.25]
        )
        #expect(true, "StateEstimatorSnapshot conforms to Sendable")
    }
}
