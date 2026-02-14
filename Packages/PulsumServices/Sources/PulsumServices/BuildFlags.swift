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
    private static let overrideLock = NSLock()
    private nonisolated(unsafe) static var _modernSpeechOverride: Bool?

    static func overrideModernSpeechBackend(_ value: Bool?) {
        overrideLock.withLock { _modernSpeechOverride = value }
    }

    static var useModernSpeechBackend: Bool {
        if let override = overrideLock.withLock({ _modernSpeechOverride }) { return override }
        return ProcessInfo.processInfo.environment["PULSUM_USE_MODERN_SPEECH"] == "1"
    }
    #else
    static let useModernSpeechBackend = false
    #endif
}
