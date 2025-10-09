import Foundation

// TEMPORARY: Foundation Models stubs for current Xcode compatibility
// Remove when iOS 26 SDK becomes available

#if !canImport(FoundationModels)

// Stub Foundation Models types for compilation compatibility
public struct SystemLanguageModel {
    public static let `default` = SystemLanguageModel()
    
    public var isAvailable: Bool { false }
    
    public enum Availability {
        case available
        case unavailable(Reason)
        
        public enum Reason {
            case appleIntelligenceNotEnabled
            case modelNotReady
            case deviceNotSupported
        }
    }
    
    public var availability: Availability {
        .unavailable(.deviceNotSupported)
    }
}

public struct LanguageModelSession {
    public init(instructions: Instructions? = nil) {}
    
    public func respond(to prompt: Prompt, generating type: Any.Type, options: GenerationOptions) async throws -> Any {
        throw FoundationModelsStubError.unavailable
    }
    
    public func respond(to prompt: Prompt, options: GenerationOptions) async throws -> ResponseStub {
        throw FoundationModelsStubError.unavailable
    }
    
    public enum GenerationError: Error {
        case guardrailViolation(String)
        case refusal(String, String)
    }
}

public struct Instructions {
    public init(_ text: String) {}
}

public struct Prompt {
    public init(_ text: String) {}
}

public struct GenerationOptions {
    public init(temperature: Double) {}
}

public struct ResponseStub {
    public let content: String = ""
}

@propertyWrapper
public struct Generable<T> {
    public var wrappedValue: T
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}

@propertyWrapper 
public struct Guide<T> {
    public var wrappedValue: T
    public init(wrappedValue: T, description: String) {
        self.wrappedValue = wrappedValue
    }
}

enum FoundationModelsStubError: Error {
    case unavailable
}

#endif








