import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif
import PulsumML
import PulsumTypes

public protocol SafetyClassifying: Sendable {
    func classify(text: String) async -> SafetyClassification
}

public struct SafetyAgent: SafetyClassifying, Sendable {
    private let foundationModelsProvider: (any Sendable)?
    private let fallbackClassifier: SafetyLocal
    private let crisisKeywords: [String]

    public init() {
        self.fallbackClassifier = SafetyLocal()
        self.crisisKeywords = Self.defaultCrisisKeywords
        if #available(iOS 26.0, *) {
            self.foundationModelsProvider = FoundationModelsSafetyProvider()
        } else {
            self.foundationModelsProvider = nil
        }
    }

    init(fallbackClassifier: SafetyLocal = SafetyLocal(),
         foundationModelsProvider: (any Sendable)? = nil,
         crisisKeywords: [String] = SafetyAgent.defaultCrisisKeywords) {
        self.fallbackClassifier = fallbackClassifier
        self.foundationModelsProvider = foundationModelsProvider
        self.crisisKeywords = crisisKeywords
    }

    public func classify(text: String) async -> SafetyClassification {
        // Try Foundation Models classification first
        if #available(iOS 26.0, *),
           let provider = foundationModelsProvider as? FoundationModelsSafetyProvider {
            do {
                let result = try await withThrowingTimeout(seconds: 5) {
                    try await provider.classify(text: text)
                }
                let lowered = text.lowercased()
                if case .crisis = result,
                   !crisisKeywords.contains(where: lowered.contains) {
                    return .caution(reason: "Seeking help (no self-harm language)")
                }
                return result
            } catch {
                Diagnostics.log(level: .warn,
                                category: .safety,
                                name: "safety.fm.error",
                                fields: [:],
                                error: error)
            }
        }

        // Use existing SafetyLocal as fallback
        return fallbackClassifier.classify(text: text)
    }

    public func evaluate(text: String) async -> SafetyDecision {
        let classification = await classify(text: text)
        let decision = makeDecision(from: classification)
        let eventName: String
        if #available(iOS 26.0, *), foundationModelsProvider is FoundationModelsSafetyProvider {
            eventName = "safety.fm.classification"
        } else {
            eventName = "safety.local.classification"
        }
        Diagnostics.log(level: .info,
                        category: .safety,
                        name: eventName,
                        fields: [
                            "classification": .safeString(.metadata("\(classification)")),
                            "allow_cloud": .bool(decision.allowCloud)
                        ])
        return decision
    }

    private func makeDecision(from classification: SafetyClassification) -> SafetyDecision {
        let allowCloud: Bool
        let crisisMessage: String?
        let crisisResources: CrisisResourceInfo?
        switch classification {
        case .safe:
            allowCloud = true
            crisisMessage = nil
            crisisResources = nil
        case .caution:
            allowCloud = false
            crisisMessage = nil
            crisisResources = nil
        case .crisis:
            allowCloud = false
            let resources = Self.localizedCrisisResources()
            crisisResources = resources
            crisisMessage = Self.localizedCrisisMessage()
        }
        return SafetyDecision(classification: classification, allowCloud: allowCloud, crisisMessage: crisisMessage, crisisResources: crisisResources)
    }

    static func localizedCrisisResources() -> CrisisResourceInfo {
        let regionCode = Locale.current.region?.identifier ?? ""
        if let resource = crisisResourcesByRegion[regionCode] {
            return CrisisResourceInfo(
                emergencyNumber: resource.emergencyNumber,
                crisisLineName: resource.crisisLineName,
                crisisLineNumber: resource.crisisLine
            )
        }
        // Fallback for unsupported locales — 112 is the international emergency number
        return CrisisResourceInfo(
            emergencyNumber: "112",
            crisisLineName: nil,
            crisisLineNumber: nil
        )
    }

    // MARK: - Crisis Keywords

    private static let defaultCrisisKeywords: [String] = [
        "suicide", "kill myself", "end my life", "not worth living",
        "better off dead", "want to die", "self-harm", "cut myself",
        "cutting myself", "overdose", "no reason to live", "jump off",
        "hang myself", "hurt myself", "don't want to be here",
        "can't go on", "take all the pills", "ending my life",
        "not want to live", "ending it",
    ]

    // MARK: - Locale-Aware Crisis Resources

    private struct CrisisResource {
        let emergencyNumber: String
        let crisisLine: String?
        let crisisLineName: String?
    }

    private static let crisisResourcesByRegion: [String: CrisisResource] = [
        "US": CrisisResource(emergencyNumber: "911", crisisLine: "988", crisisLineName: "988 Suicide & Crisis Lifeline"),
        "CA": CrisisResource(emergencyNumber: "911", crisisLine: "988", crisisLineName: "988 Suicide Crisis Helpline"),
        "GB": CrisisResource(emergencyNumber: "999", crisisLine: "116 123", crisisLineName: "Samaritans"),
        "AU": CrisisResource(emergencyNumber: "000", crisisLine: "13 11 14", crisisLineName: "Lifeline"),
        "NZ": CrisisResource(emergencyNumber: "111", crisisLine: "1737", crisisLineName: "Need to Talk?"),
        "DE": CrisisResource(emergencyNumber: "112", crisisLine: "0800 111 0 111", crisisLineName: "Telefonseelsorge"),
        "FR": CrisisResource(emergencyNumber: "112", crisisLine: "3114", crisisLineName: "Num\u{00E9}ro National de Pr\u{00E9}vention du Suicide"),
        "JP": CrisisResource(emergencyNumber: "119", crisisLine: "0120-783-556", crisisLineName: "Inochi no Denwa"),
        "IN": CrisisResource(emergencyNumber: "112", crisisLine: "9820466726", crisisLineName: "iCall"),
        "BR": CrisisResource(emergencyNumber: "192", crisisLine: "188", crisisLineName: "CVV"),
        "IE": CrisisResource(emergencyNumber: "112", crisisLine: "116 123", crisisLineName: "Samaritans"),
    ]

    private static func localizedCrisisMessage() -> String {
        let regionCode = Locale.current.region?.identifier ?? ""
        if let resource = crisisResourcesByRegion[regionCode] {
            if let line = resource.crisisLine, let name = resource.crisisLineName {
                return "If you are in immediate danger, call \(resource.emergencyNumber). You can also reach \(name) at \(line)."
            }
            return "If you are in immediate danger, call \(resource.emergencyNumber)."
        }
        return "If you are in immediate danger, call your local emergency number (112 in many countries). Visit findahelpline.com for crisis support in your region."
    }
}

private func withThrowingTimeout<T: Sendable>(
    seconds: TimeInterval,
    operation: @Sendable @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw CancellationError()
        }
        guard let result = try await group.next() else {
            throw CancellationError()
        }
        group.cancelAll()
        return result
    }
}
