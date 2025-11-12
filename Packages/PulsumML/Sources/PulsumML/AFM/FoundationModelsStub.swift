import Foundation

// TEMPORARY: Foundation Models stubs for current Xcode compatibility
// Remove when iOS 26 SDK becomes available

#if !canImport(FoundationModels)

// Stub Foundation Models types for compilation compatibility
public struct SystemLanguageModel: Sendable {
    @MainActor public static let `default` = SystemLanguageModel()
    public var isAvailable: Bool { false }
}

public struct LanguageModelSession: Sendable {
    public init(instructions: Instructions? = nil) {}
    public init(temperature: Double) {}

    public func respond<T: Decodable & Sendable>(
        to prompt: Prompt,
        generating type: T.Type,
        options: GenerationOptions
    ) async throws -> LanguageModelResult<T> {
        throw FoundationModelsStubError.unavailable
    }

    public func respond(
        to prompt: Prompt,
        options: GenerationOptions
    ) async throws -> LanguageModelResult<String> {
        throw FoundationModelsStubError.unavailable
    }

    public enum GenerationError: Error, Sendable {
        case guardrailViolation(String)
        case refusal(String, String)
    }
}

public struct Instructions: Sendable {
    public init(_ text: String) {}
}

public struct Prompt: Sendable {
    public init(_ text: String) {}
}

public struct GenerationOptions: Sendable {
    public init(temperature: Double) {}
}

public struct LanguageModelResult<Content: Sendable>: Sendable {
    public let content: Content

    public init(content: Content) {
        self.content = content
    }
}

@propertyWrapper
public struct Generable<T: Sendable>: Sendable {
    public var wrappedValue: T
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}

@propertyWrapper
public struct Guide<T: Sendable>: Sendable {
    public var wrappedValue: T
    public init(wrappedValue: T, description: String) {
        self.wrappedValue = wrappedValue
    }
}

public enum FoundationModelsStubError: Error, Sendable {
    case unavailable
}

#endif


