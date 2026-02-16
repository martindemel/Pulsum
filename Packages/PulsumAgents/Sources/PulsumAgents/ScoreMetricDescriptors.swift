import Foundation

struct ScoreMetricDescriptor {
    let featureKey: String
    let displayName: String
    let kind: ScoreBreakdown.MetricDetail.Kind
    let order: Int
    let unit: String?
    let usesZScore: Bool
    let rawValueKey: String?
    let baselineKey: String?
    let rollingWindowDays: Int?
    let explanation: String
    let flagKeys: [String]

    func flagMessages(for flags: [String: Bool]) -> [String] {
        flagKeys.compactMap { key in
            guard flags[key] == true else { return nil }
            return scoreMetricFlagMessages[key]
        }
    }
}

let scoreMetricDescriptors: [ScoreMetricDescriptor] = [
    ScoreMetricDescriptor(
        featureKey: "z_hrv",
        displayName: "Heart Rate Variability",
        kind: .objective,
        order: 0,
        unit: "ms",
        usesZScore: true,
        rawValueKey: "hrv",
        baselineKey: "hrv",
        rollingWindowDays: 30,
        explanation: "Median overnight SDNN. Higher values mean the autonomic nervous system is more recovered.",
        flagKeys: ["hrv", "sedentary_missing"]
    ),
    ScoreMetricDescriptor(
        featureKey: "z_nocthr",
        displayName: "Nocturnal Heart Rate",
        kind: .objective,
        order: 1,
        unit: "bpm",
        usesZScore: true,
        rawValueKey: "nocthr",
        baselineKey: "nocthr",
        rollingWindowDays: 30,
        explanation: "10th percentile of heart rate while asleep. Lower values indicate better overnight recovery.",
        flagKeys: ["nocturnalHR", "sedentary_missing"]
    ),
    ScoreMetricDescriptor(
        featureKey: "z_resthr",
        displayName: "Resting Heart Rate",
        kind: .objective,
        order: 2,
        unit: "bpm",
        usesZScore: true,
        rawValueKey: "resthr",
        baselineKey: "resthr",
        rollingWindowDays: 30,
        explanation: "Latest resting heart rate sample. Lower relative to baseline typically reflects parasympathetic dominance.",
        flagKeys: ["restingHR", "sedentary_missing"]
    ),
    ScoreMetricDescriptor(
        featureKey: "z_sleepDebt",
        displayName: "Sleep Debt",
        kind: .objective,
        order: 3,
        unit: "h",
        usesZScore: true,
        rawValueKey: "sleepDebt",
        baselineKey: "sleepDebt",
        rollingWindowDays: 7,
        explanation: "Cumulative sleep debt over the past 7 days vs your personalized sleep need.",
        flagKeys: ["sleep_low_confidence", "sleepDebt_missing"]
    ),
    ScoreMetricDescriptor(
        featureKey: "z_rr",
        displayName: "Respiratory Rate",
        kind: .objective,
        order: 4,
        unit: "breaths/min",
        usesZScore: true,
        rawValueKey: "rr",
        baselineKey: "rr",
        rollingWindowDays: 30,
        explanation: "Average sleeping respiratory rate. Stable values indicate steady recovery.",
        flagKeys: ["rr_missing"]
    ),
    ScoreMetricDescriptor(
        featureKey: "z_steps",
        displayName: "Steps",
        kind: .objective,
        order: 5,
        unit: "steps",
        usesZScore: true,
        rawValueKey: "steps",
        baselineKey: "steps",
        rollingWindowDays: 30,
        explanation: "Total steps captured today relative to your rolling baseline.",
        flagKeys: ["steps_missing", "steps_low_confidence"]
    ),
    ScoreMetricDescriptor(
        featureKey: "subj_stress",
        displayName: "Stress",
        kind: .subjective,
        order: 6,
        unit: "(1-7)",
        usesZScore: false,
        rawValueKey: nil,
        baselineKey: nil,
        rollingWindowDays: nil,
        explanation: "Self-reported stress level captured in today's pulse check.",
        flagKeys: []
    ),
    ScoreMetricDescriptor(
        featureKey: "subj_energy",
        displayName: "Energy",
        kind: .subjective,
        order: 7,
        unit: "(1-7)",
        usesZScore: false,
        rawValueKey: nil,
        baselineKey: nil,
        rollingWindowDays: nil,
        explanation: "Self-reported energy level from today's pulse check.",
        flagKeys: []
    ),
    ScoreMetricDescriptor(
        featureKey: "subj_sleepQuality",
        displayName: "Sleep Quality",
        kind: .subjective,
        order: 8,
        unit: "(1-7)",
        usesZScore: false,
        rawValueKey: nil,
        baselineKey: nil,
        rollingWindowDays: nil,
        explanation: "Perceived sleep quality for the prior night.",
        flagKeys: []
    ),
    ScoreMetricDescriptor(
        featureKey: "sentiment",
        displayName: "Journal Sentiment",
        kind: .sentiment,
        order: 9,
        unit: nil,
        usesZScore: false,
        rawValueKey: nil,
        baselineKey: nil,
        rollingWindowDays: nil,
        explanation: "On-device sentiment score from your latest journal entry (negative to positive).",
        flagKeys: []
    )
]

let scoreMetricFlagMessages: [String: String] = [
    "hrv": "HRV carried forward from a previous day because no fresh overnight samples were available.",
    "sedentary_missing": "No restful sedentary window detected today; fallbacks were used for recovery metrics.",
    "nocturnalHR": "No nocturnal heart rate samples during sleep; carried forward the last reliable value.",
    "restingHR": "Resting heart rate sample missing; reused the most recent reliable value.",
    "rr_missing": "Sleeping respiratory rate missing, so this signal is omitted today.",
    "steps_missing": "Step data unavailable; activity impact excluded from today's score.",
    "steps_low_confidence": "Very low step count (<500) flagged as low confidence.",
    "sleep_low_confidence": "Less than 3 hours of sleep recorded; sleep-related calculations are low confidence.",
    "sleepDebt_missing": "No sleep data available; sleep debt is omitted from today's score."
]

func generalFlagMessages(for flags: [String: Bool]) -> [String] {
    let handledKeys = Set(scoreMetricDescriptors.flatMap { $0.flagKeys })
    return flags.compactMap { key, value in
        guard value, !handledKeys.contains(key) else { return nil }
        return scoreMetricFlagMessages[key]
    }
}
