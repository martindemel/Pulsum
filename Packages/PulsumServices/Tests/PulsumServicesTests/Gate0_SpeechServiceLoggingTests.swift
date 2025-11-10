import XCTest
@testable import PulsumServices

final class Gate0_SpeechServiceLoggingTests: XCTestCase {
    func testReleaseBuildDisablesTranscriptLogging() throws {
#if RELEASE_LOG_AUDIT
        XCTAssertFalse(SpeechLoggingPolicy.transcriptLoggingEnabled, "Release builds must never log transcripts.")
#else
        throw XCTSkip("Release-only assertion. Build with -DRELEASE_LOG_AUDIT to run.")
#endif
    }

    func testReleaseBinaryOmitsTranscriptAuditMarker() throws {
#if RELEASE_LOG_AUDIT
        let marker = ["PULSUM", "TRANSCRIPT", "LOG", "MARKER"].joined(separator: "_")
        guard let executableURL = Bundle(for: Self.self).executableURL else {
            return XCTFail("Unable to resolve test bundle executable URL.")
        }
        let data = try Data(contentsOf: executableURL)
        let haystack = String(decoding: data, as: UTF8.self)
        XCTAssertFalse(haystack.contains(marker), "Release binary should not contain transcript audit marker")
#else
        throw XCTSkip("Release-only binary audit. Build with -DRELEASE_LOG_AUDIT to run.")
#endif
    }
}
