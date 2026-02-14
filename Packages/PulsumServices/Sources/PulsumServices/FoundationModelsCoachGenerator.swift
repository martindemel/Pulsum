import Foundation
#if canImport(FoundationModels) && os(iOS)
import FoundationModels
#endif
import PulsumML

public final class FoundationModelsCoachGenerator: OnDeviceCoachGenerator {
    public init() {}

    public func generate(context: CoachLLMContext) async -> CoachReplyPayload {
        #if canImport(FoundationModels) && os(iOS)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard model.isAvailable else {
                return fallbackResponse(for: context.topSignal)
            }

            var instructionText = """
            You are Pulsum's wellness coach. Guidelines:
            - Keep responses under 80 words and maximum 2 sentences
            - Ground suggestions in provided wellbeing signals and scores
            - Be supportive, calm, and actionable - NEVER diagnostic
            - Focus on immediate, doable actions
            - Use language like "may help", "consider", or "notice"; never "should", "must", or medical claims
            - NEVER diagnose, prescribe, or claim to treat conditions
            - Relate suggestions to current wellbeing context (sleep, energy, stress, mood, movement)
            """

            if let topic = topicFromSignal(context.topSignal) {
                switch topic {
                case "sleep":
                    instructionText += "\nWhen topic is sleep and data is sparse, favor wind-down routines, light exposure timing, and mindful caffeine timing; avoid medical claims."
                case "stress":
                    instructionText += "\nWhen topic is stress, encourage brief breathing exercises, gentle walks, or grounded check-ins; avoid therapeutic claims."
                case "energy":
                    instructionText += "\nWhen topic is energy or motivation, suggest pacing, hydration, or light movement to build steady momentum without promising outcomes."
                default:
                    break
                }
            }

            let session = LanguageModelSession(
                instructions: Instructions(instructionText)
            )

            let prompt = """
            User context: \(context.userToneHints)
            Current health signal: \(context.topSignal)
            Health metrics: \(context.zScoreSummary)
            Analysis: \(context.rationale)

            Provide a brief, supportive coaching response that addresses their current state.
            """

            do {
                let response = try await session.respond(
                    to: Prompt(prompt),
                    options: GenerationOptions(temperature: 0.6)
                )
                return CoachReplyPayload(
                    coachReply: sanitizeResponse(response.content),
                    nextAction: nil // Foundation Models doesn't generate nextAction
                )
            } catch LanguageModelSession.GenerationError.guardrailViolation {
                return CoachReplyPayload(
                    coachReply: "Take a moment to focus on what feels supportive right now.",
                    nextAction: nil
                )
            } catch LanguageModelSession.GenerationError.refusal {
                return CoachReplyPayload(
                    coachReply: "Let's keep the focus on gentle, grounding actions.",
                    nextAction: nil
                )
            } catch {
                return fallbackResponse(for: context.topSignal)
            }
        }
        #endif
        return fallbackResponse(for: context.topSignal)
    }

    private func topicFromSignal(_ signal: String) -> String? {
        guard let range = signal.range(of: "topic=") else { return nil }
        let suffix = signal[range.upperBound...]
        let components = suffix.split(separator: " ", maxSplits: 1)
        return components.first.map { String($0) }
    }

    private func sanitizeResponse(_ response: String) -> String {
        // Split on sentence boundaries while preserving the terminating punctuation.
        let pattern = #"[^.!?]*[.!?]"#
        let matches = (try? NSRegularExpression(pattern: pattern))
            .map { regex in
                regex.matches(in: response, range: NSRange(response.startIndex..., in: response))
                    .compactMap { Range($0.range, in: response).map { String(response[$0]) } }
            } ?? []
        let sentences = matches.isEmpty ? [response] : matches
        let trimmed = sentences.prefix(2).map { sentence -> String in
            String(sentence.trimmingCharacters(in: .whitespacesAndNewlines).prefix(280))
        }
        return trimmed.joined(separator: " ")
    }

    private func fallbackResponse(for signal: String) -> CoachReplyPayload {
        let topic = topicFromSignal(signal) ?? "today"
        let hint = topic == "today" ? "" : " A tiny action for \(topic) may help.".trimmingCharacters(in: .whitespaces)
        let message = "Take a slow breath and notice one thing that feels steady right now." + (hint.isEmpty ? "" : " \(hint)")
        return CoachReplyPayload(
            coachReply: sanitizeResponse(message),
            nextAction: nil
        )
    }
}
