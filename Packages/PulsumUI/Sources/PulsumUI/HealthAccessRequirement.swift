import Foundation
import HealthKit

enum HealthAccessGrantState {
    case granted
    case denied
    case pending
}

struct HealthAccessRequirement: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let iconName: String

    static let ordered: [HealthAccessRequirement] = [
        HealthAccessRequirement(id: HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue,
                                title: "Heart Rate Variability",
                                detail: "Captures nervous system recovery.",
                                iconName: "waveform.path.ecg"),
        HealthAccessRequirement(id: HKQuantityTypeIdentifier.heartRate.rawValue,
                                title: "Heart Rate",
                                detail: "Measures training load and exertion.",
                                iconName: "heart.fill"),
        HealthAccessRequirement(id: HKQuantityTypeIdentifier.restingHeartRate.rawValue,
                                title: "Resting Heart Rate",
                                detail: "Highlights baseline strain changes.",
                                iconName: "heart.text.square"),
        HealthAccessRequirement(id: HKCategoryTypeIdentifier.sleepAnalysis.rawValue,
                                title: "Sleep Analysis",
                                detail: "Understands time asleep and quality.",
                                iconName: "bed.double.fill"),
        HealthAccessRequirement(id: HKQuantityTypeIdentifier.respiratoryRate.rawValue,
                                title: "Respiratory Rate",
                                detail: "Tracks breathing patterns overnight.",
                                iconName: "lungs.fill"),
        HealthAccessRequirement(id: HKQuantityTypeIdentifier.stepCount.rawValue,
                                title: "Steps",
                                detail: "Counts movement and activity volume.",
                                iconName: "figure.walk")
    ]

    private static let lookup: [String: HealthAccessRequirement] = {
        var dictionary: [String: HealthAccessRequirement] = [:]
        for requirement in ordered {
            dictionary[requirement.id] = requirement
        }
        return dictionary
    }()

    static func descriptor(for sampleType: HKSampleType) -> HealthAccessRequirement? {
        lookup[sampleType.identifier]
    }

    static func descriptor(forIdentifier identifier: String) -> HealthAccessRequirement? {
        lookup[identifier]
    }
}
