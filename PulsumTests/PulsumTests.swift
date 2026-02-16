import Testing
@testable import Pulsum
import PulsumData
import PulsumTypes

struct PulsumTests {
    @Test("AppRuntimeConfig defaults are sensible in test environment")
    func runtimeConfigDefaults() {
        // These env-gated flags should all be false in the unit test runner
        #expect(!AppRuntimeConfig.skipHeavyStartupWork)
        #expect(!AppRuntimeConfig.hideConsentBanner)
        #expect(!AppRuntimeConfig.settingsHookEnabled)
        #expect(!AppRuntimeConfig.forceSettingsFallback)
        #expect(!AppRuntimeConfig.captureSettingsURLs)
    }

    @Test("DataStack registers all 9 model types")
    func dataStackModelTypes() {
        #expect(DataStack.modelTypes.count == 9)
    }
}
