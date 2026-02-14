import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif
import PulsumML
import PulsumTypes

@MainActor
public final class SafetyAgent {
    private let foundationModelsProvider: Any?
    private let fallbackClassifier = SafetyLocal()
    private let crisisKeywords: [String] = [
        "suicide",
        "kill myself",
        "end my life",
        "not worth living",
        "better off dead",
        "want to die",
        "self-harm",
        "cut myself",
        "cutting myself",
        "overdose",
        "no reason to live",
        "jump off",
        "hang myself",
        "hurt myself",
        "don't want to be here",
        "can't go on",
        "take all the pills",
        "ending my life",
        "not want to live",
        "ending it"
    ]

    public init() {
        if #available(iOS 26.0, *) {
            self.foundationModelsProvider = FoundationModelsSafetyProvider()
        } else {
            self.foundationModelsProvider = nil
        }
    }

    public func evaluate(text: String) async -> SafetyDecision {
        // Try Foundation Models classification first
        if #available(iOS 26.0, *),
           let provider = foundationModelsProvider as? FoundationModelsSafetyProvider {
            do {
                let result = try await withThrowingTimeout(seconds: 5) {
                    try await provider.classify(text: text)
                }
                let lowered = text.lowercased()
                let adjusted: SafetyClassification
                if case .crisis = result,
                   !crisisKeywords.contains(where: lowered.contains) {
                    adjusted = .caution(reason: "Seeking help (no self-harm language)")
                } else {
                    adjusted = result
                }
                let decision = makeDecision(from: adjusted)
                Diagnostics.log(level: .info,
                                category: .safety,
                                name: "safety.fm.classification",
                                fields: [
                                    "classification": .safeString(.metadata("\(adjusted)")),
                                    "allow_cloud": .bool(decision.allowCloud)
                                ])
                return decision
            } catch {
                Diagnostics.log(level: .warn,
                                category: .safety,
                                name: "safety.fm.error",
                                fields: [:],
                                error: error)
                // Fall back to existing classifier
            }
        }

        // Use existing SafetyLocal as fallback
        let result = fallbackClassifier.classify(text: text)
        let decision = makeDecision(from: result)
        Diagnostics.log(level: .info,
                        category: .safety,
                        name: "safety.local.classification",
                        fields: [
                            "classification": .safeString(.metadata("\(result)")),
                            "allow_cloud": .bool(decision.allowCloud)
                        ])
        return decision
    }

    private func makeDecision(from classification: SafetyClassification) -> SafetyDecision {
        let allowCloud: Bool
        let crisisMessage: String?
        switch classification {
        case .safe:
            allowCloud = true
            crisisMessage = nil
        case .caution:
            allowCloud = false
            crisisMessage = nil
        case .crisis:
            allowCloud = false
            crisisMessage = Self.localizedCrisisMessage()
        }
        return SafetyDecision(classification: classification, allowCloud: allowCloud, crisisMessage: crisisMessage)
    }

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
        // Fallback: recommend 112 (international emergency) and a web resource
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
