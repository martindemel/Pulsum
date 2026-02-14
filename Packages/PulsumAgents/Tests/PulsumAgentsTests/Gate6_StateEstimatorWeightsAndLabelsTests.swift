import XCTest
@testable import PulsumAgents
@testable import PulsumML

// swiftlint:disable:next type_name
final class Gate6_StateEstimatorWeightsAndLabelsTests: XCTestCase {
    func testRecoverySignalsLiftScore() async {
        let goodRaw: [String: Double] = [
            "z_hrv": 1.5,
            "z_sleepDebt": -1.0,
            "z_steps": 1.1,
            "z_nocthr": -0.8,
            "z_resthr": -0.6,
            "subj_stress": 2.0,
            "subj_energy": 6.5,
            "subj_sleepQuality": 6.0,
            "sentiment": 0.7
        ]
        let badRaw: [String: Double] = [
            "z_hrv": -1.4,
            "z_sleepDebt": 1.2,
            "z_steps": -0.8,
            "z_nocthr": 0.9,
            "z_resthr": 0.7,
            "subj_stress": 6.5,
            "subj_energy": 2.0,
            "subj_sleepQuality": 2.5,
            "sentiment": -0.6
        ]

        let goodFeatures = WellbeingModeling.normalize(features: goodRaw, imputedFlags: [:])
        let badFeatures = WellbeingModeling.normalize(features: badRaw, imputedFlags: [:])

        let estimator = StateEstimator()
        let goodTarget = WellbeingModeling.target(for: goodFeatures)
        let badTarget = WellbeingModeling.target(for: badFeatures)

        let goodSnapshot = await estimator.update(features: goodFeatures, target: goodTarget)
        let badSnapshot = await estimator.update(features: badFeatures, target: badTarget)

        XCTAssertGreaterThan(goodSnapshot.wellbeingScore, badSnapshot.wellbeingScore)
        XCTAssertGreaterThan(goodSnapshot.contributions["z_hrv"] ?? 0, 0)
        XCTAssertLessThan(badSnapshot.contributions["z_hrv"] ?? 0, 0)
        XCTAssertGreaterThan(goodSnapshot.contributions["z_steps"] ?? 0, badSnapshot.contributions["z_steps"] ?? 0)
        XCTAssertGreaterThan(goodSnapshot.contributions["z_sleepDebt"] ?? 0, 0)
        XCTAssertLessThan(badSnapshot.contributions["z_sleepDebt"] ?? 0, 0)
        XCTAssertGreaterThan(goodSnapshot.contributions["sentiment"] ?? 0, badSnapshot.contributions["sentiment"] ?? 0)
    }

    func testImputedSignalsClampToNeutralContribution() async {
        let raw: [String: Double] = [
            "z_hrv": 1.2,
            "z_steps": 1.5,
            "subj_energy": 6.0
        ]
        let imputed = [
            "steps_missing": true,
            "sedentary_missing": true
        ]
        let normalized = WellbeingModeling.normalize(features: raw, imputedFlags: imputed)

        XCTAssertEqual(normalized["z_steps"], 0)
        XCTAssertLessThan(normalized["z_hrv"] ?? 0, 1.2)

        let estimator = StateEstimator()
        let target = WellbeingModeling.target(for: normalized)
        let snapshot = await estimator.update(features: normalized, target: target)

        XCTAssertEqual(snapshot.contributions["z_steps"] ?? -1, 0)
    }
}
