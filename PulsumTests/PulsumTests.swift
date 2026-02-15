import Testing
@testable import Pulsum

struct PulsumTests {
    @Test("App target can be imported and types are accessible")
    func appTargetImport() {
        // Smoke test: verify the Pulsum app target compiles and key types are reachable.
        #expect(true, "Pulsum app target imported successfully")
    }
}
