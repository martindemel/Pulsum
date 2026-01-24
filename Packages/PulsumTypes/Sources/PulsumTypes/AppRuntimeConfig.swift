import Foundation

public enum AppRuntimeConfig {
    public static let uiTestDefaultsSuite = "pulsum.uitest"

    private static var environment: [String: String] {
        ProcessInfo.processInfo.environment
    }

    private static var arguments: [String] {
        ProcessInfo.processInfo.arguments
    }

    public static var isUITesting: Bool {
        if arguments.contains("-ui_testing") {
            return true
        }
        return environment["UITEST"] == "1"
    }

    public static var disableAnimations: Bool {
        isUITesting || environment["UITEST_DISABLE_ANIMATIONS"] == "1"
    }

    public static var skipHeavyStartupWork: Bool {
        isUITesting || environment["UITEST_SKIP_STARTUP"] == "1"
    }

    public static var useStubLLM: Bool {
        isUITesting || environment["UITEST_USE_STUB_LLM"] == "1"
    }

    public static var disableKeychain: Bool {
        isUITesting || environment["UITEST_DISABLE_CLOUD_KEYCHAIN"] == "1"
    }

    public static var hideConsentBanner: Bool {
        environment["UITEST_HIDE_CONSENT_BANNER"] == "1"
    }

    public static var settingsHookEnabled: Bool {
        environment["UITEST_SETTINGS_HOOK"] == "1"
    }

    public static var forceSettingsFallback: Bool {
        environment["UITEST_FORCE_SETTINGS_FALLBACK"] == "1"
    }

    public static var captureSettingsURLs: Bool {
        environment["UITEST_CAPTURE_URLS"] == "1"
    }

    public static var useFakeSpeechBackend: Bool {
        environment["UITEST_FAKE_SPEECH"] == "1"
    }

    public static var autoGrantSpeechPermissions: Bool {
        environment["UITEST_AUTOGRANT"] == "1"
    }

    public static var uiTestDefaults: UserDefaults {
        UserDefaults(suiteName: uiTestDefaultsSuite) ?? .standard
    }

    public static var runtimeDefaults: UserDefaults {
        isUITesting ? uiTestDefaults : .standard
    }

    public static func synchronizeUITestDefaults() {
        guard isUITesting || disableKeychain else { return }
        CFPreferencesAppSynchronize(uiTestDefaultsSuite as CFString)
    }
}
