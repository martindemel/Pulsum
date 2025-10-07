import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif
import PulsumML

@MainActor
public final class SafetyAgent {
    private let foundationModelsProvider: FoundationModelsSafetyProvider?
    private let fallbackClassifier = SafetyLocal()
    private let crisisKeywords: [String] = [
        "suicide",
        "kill myself",
        "end my life",
        "not worth living",
        "better off dead"
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
        if let provider = foundationModelsProvider {
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
#if DEBUG
                print("[PulsumSafety] FM classification: \(adjusted) -> allowCloud=\(decision.allowCloud)")
#endif
                return decision
            } catch {
                #if DEBUG
                print("Foundation Models safety classification failed: \(error)")
                #endif
                // Fall back to existing classifier
            }
        }

        // Use existing SafetyLocal as fallback
        let result = fallbackClassifier.classify(text: text)
        let decision = makeDecision(from: result)
#if DEBUG
        print("[PulsumSafety] Local classification: \(result) -> allowCloud=\(decision.allowCloud)")
#endif
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
