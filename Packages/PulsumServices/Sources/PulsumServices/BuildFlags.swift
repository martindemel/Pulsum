import Foundation

// Gate-1b: UITest seam hardening
// Shared entry point so all services know if UITest seams are compiled in.
enum BuildFlags {
#if DEBUG || PULSUM_UITESTS
    static let uiTestSeamsCompiledIn = true
#else
    static let uiTestSeamsCompiledIn = false
#endif

#if DEBUG
    nonisolated(unsafe) private static var modernSpeechOverride: Bool?

    static func overrideModernSpeechBackend(_ value: Bool?) {
        modernSpeechOverride = value
    }

    static var useModernSpeechBackend: Bool {
        if let override = modernSpeechOverride { return override }
        return ProcessInfo.processInfo.environment["PULSUM_USE_MODERN_SPEECH"] == "1"
    }
#else
    static let useModernSpeechBackend = false
#endif
}
