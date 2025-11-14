import XCTest
@testable import PulsumServices

final class Gate2_ModernSpeechBackendTests: XCTestCase {
    func testModernBackendRespectsFeatureFlag() async throws {
#if os(iOS)
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("Modern backend only available on iOS 26+")
        }
        BuildFlags.overrideModernSpeechBackend(true)
        SpeechServiceDebug.overrideModernBackendAvailability(true)
        defer {
            BuildFlags.overrideModernSpeechBackend(nil)
            SpeechServiceDebug.overrideModernBackendAvailability(nil)
        }

        let service = SpeechService()
        XCTAssertEqual(service.selectedBackendIdentifier, "modern")
#else
        throw XCTSkip("Speech backend selection only available on iOS")
#endif
    }

    func testLegacyBackendDefault() async throws {
#if os(iOS)
        BuildFlags.overrideModernSpeechBackend(false)
        SpeechServiceDebug.overrideModernBackendAvailability(true)
        defer {
            BuildFlags.overrideModernSpeechBackend(nil)
            SpeechServiceDebug.overrideModernBackendAvailability(nil)
        }

        let service = SpeechService()
        XCTAssertEqual(service.selectedBackendIdentifier, "legacy")
#else
        throw XCTSkip("Speech backend selection only available on iOS")
#endif
    }
}
