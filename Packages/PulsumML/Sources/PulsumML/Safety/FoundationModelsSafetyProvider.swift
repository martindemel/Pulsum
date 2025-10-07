import Foundation
#if canImport(FoundationModels) && os(iOS)
import FoundationModels

@available(iOS 26.0, *)
@Generable enum SafetyRating: String, CaseIterable {
    case safe, caution, crisis
}

@available(iOS 26.0, *)
@Generable struct SafetyAssessment {
    @Guide(description: "Safety classification: safe (normal discussion), caution (concerning but not dangerous), or crisis (immediate danger/self-harm)")
    let rating: SafetyRating
    @Guide(description: "Brief explanation of why this classification was chosen")
    let reason: String
}

@available(iOS 26.0, *)
public final class FoundationModelsSafetyProvider {
    private let model = SystemLanguageModel.default
    
    public init() {}
    
    public func classify(text: String) async throws -> SafetyClassification {
        guard model.isAvailable else {
            throw SafetyError.modelUnavailable
        }
        
        let session = LanguageModelSession(
            instructions: Instructions("""
            Assess the safety level of user text in a mental health context.
            
            Classifications:
            - SAFE: Normal wellness discussion, general questions, routine check-ins, casual conversation
            - CAUTION: Expressions of stress, anxiety, sadness, or emotional distress that are concerning but not indicating immediate danger
            - CRISIS: ONLY explicit indication of self-harm, suicide ideation, violence, or immediate danger to self or others
            
            Use SAFE for general questions, casual conversation, or anything that doesn't clearly indicate distress.
            CRISIS should ONLY be used when there is explicit mention of harming self or others.
            """)
        )
        
        do {
            let result = try await session.respond(
                to: Prompt("Assess safety of this text: \(text)"),
                generating: SafetyAssessment.self,
                options: GenerationOptions(temperature: 0.0)
            )
            
            switch result.content.rating {
            case .safe:
                return .safe
            case .caution:
                return .caution(reason: result.content.reason)
            case .crisis:
                return .crisis(reason: result.content.reason)
            }
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            // Guardrails triggered - treat as safe to avoid false positives
            // If truly dangerous, keyword-based fallback will catch it
            return .safe
        } catch LanguageModelSession.GenerationError.refusal {
            // Model refused to analyze - treat as safe and let fallback handle it
            return .safe
        } catch {
            throw SafetyError.classificationFailed
        }
    }
}
#else
public final class FoundationModelsSafetyProvider {
    public init() {}
    public func classify(text: String) async throws -> SafetyClassification {
        throw SafetyError.modelUnavailable
    }
}
#endif

public enum SafetyError: LocalizedError {
    case modelUnavailable
    case classificationFailed
    
    public var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "Safety classification model is not available"
        case .classificationFailed:
            return "Failed to classify content safety"
        }
    }
}

extension FoundationModelsSafetyProvider: @unchecked Sendable {}
