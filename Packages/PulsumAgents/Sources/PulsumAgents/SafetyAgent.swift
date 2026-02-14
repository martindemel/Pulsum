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
                let result = try await provider.classify(text: text)
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
            crisisMessage = "If you're in the United States, call 911 right away."
        }
        return SafetyDecision(classification: classification, allowCloud: allowCloud, crisisMessage: crisisMessage)
    }
}
