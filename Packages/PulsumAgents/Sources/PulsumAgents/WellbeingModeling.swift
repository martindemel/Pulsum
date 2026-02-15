import Foundation

enum WellbeingModeling {
    static let targetWeights: [String: Double] = [
        "z_hrv": 0.55,
        "z_nocthr": -0.4,
        "z_resthr": -0.35,
        "z_sleepDebt": -0.65,
        "z_steps": 0.32,
        "z_rr": -0.1,
        "subj_stress": -0.4,
        "subj_energy": 0.45,
        "subj_sleepQuality": 0.3,
        "sentiment": 0.22
    ]

    static func normalize(features: [String: Double], imputedFlags: [String: Bool]) -> [String: Double] {
        var normalized: [String: Double] = [:]
        for key in FeatureBundle.requiredKeys {
            let raw = features[key] ?? 0
            normalized[key] = normalizedValue(for: key, value: raw, imputedFlags: imputedFlags)
        }
        return normalized
    }

    static func target(for normalizedFeatures: [String: Double]) -> Double {
        var target = 0.0
        for (feature, weight) in targetWeights {
            target += weight * (normalizedFeatures[feature] ?? 0)
        }
        return clamp(target, limit: 2.5)
    }

    private static func normalizedValue(for key: String, value: Double, imputedFlags: [String: Bool]) -> Double {
        let adjusted = adjustForImputation(key: key, value: value, imputedFlags: imputedFlags)
        switch key {
        case let feature where feature.hasPrefix("z_"):
            return clamp(adjusted, limit: 3)
        case "subj_stress", "subj_energy", "subj_sleepQuality":
            let centered = (adjusted - 4.0) / 3.0
            return clamp(centered, limit: 1)
        case "sentiment":
            return clamp(adjusted, limit: 1)
        default:
            return adjusted
        }
    }

    private static func adjustForImputation(key: String, value: Double, imputedFlags: [String: Bool]) -> Double {
        var adjusted = value

        switch key {
        case "z_hrv", "z_nocthr", "z_resthr":
            if imputedFlags["sedentary_missing"] == true {
                adjusted *= 0.5
            }
        case "z_sleepDebt":
            if imputedFlags["sleep_low_confidence"] == true {
                adjusted = 0
            }
        case "z_rr":
            if imputedFlags["rr_missing"] == true {
                adjusted = 0
            }
        case "z_steps":
            if imputedFlags["steps_missing"] == true {
                adjusted = 0
            } else if imputedFlags["steps_low_confidence"] == true {
                adjusted *= 0.5
            }
        default:
            break
        }

        let missingKey = key.replacingOccurrences(of: "z_", with: "") + "_missing"
        if imputedFlags[missingKey] == true {
            adjusted = 0
        }

        return adjusted
    }

    private static func clamp(_ value: Double, limit: Double) -> Double {
        min(max(value, -limit), limit)
    }
}
