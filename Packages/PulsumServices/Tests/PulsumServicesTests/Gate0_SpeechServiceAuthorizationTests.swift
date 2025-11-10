#if os(iOS)
import Speech
import XCTest
@testable import PulsumServices

private struct MockSpeechAuthorizationProvider: SpeechAuthorizationProviding {
    let speechStatus: SFSpeechRecognizerAuthorizationStatus
    let microphoneGranted: Bool

    func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        speechStatus
    }

    func requestRecordPermission() async -> Bool {
        microphoneGranted
    }
}

final class Gate0_SpeechServiceAuthorizationTests: XCTestCase {
    func testSpeechPermissionDenied() async {
        let provider = MockSpeechAuthorizationProvider(speechStatus: .denied, microphoneGranted: true)
        let service = SpeechService(authorizationProvider: provider)

        await expect(service: service, toThrow: .speechPermissionDenied)
    }

    func testSpeechPermissionRestricted() async {
        let provider = MockSpeechAuthorizationProvider(speechStatus: .restricted, microphoneGranted: true)
        let service = SpeechService(authorizationProvider: provider)

        await expect(service: service, toThrow: .speechPermissionRestricted)
    }

    func testMicrophonePermissionDenied() async {
        let provider = MockSpeechAuthorizationProvider(speechStatus: .authorized, microphoneGranted: false)
        let service = SpeechService(authorizationProvider: provider)

        await expect(service: service, toThrow: .microphonePermissionDenied)
    }

    func testPermissionsGranted() async throws {
        let provider = MockSpeechAuthorizationProvider(speechStatus: .authorized, microphoneGranted: true)
        let service = SpeechService(authorizationProvider: provider)

        XCTAssertNoThrow(try await service.requestAuthorization())
    }
}

private extension Gate0_SpeechServiceAuthorizationTests {
    func expect(service: SpeechService,
                toThrow expected: SpeechServiceError,
                file: StaticString = #filePath,
                line: UInt = #line) async {
        do {
            try await service.requestAuthorization()
            XCTFail("Expected error \(expected) but call succeeded", file: file, line: line)
        } catch let error as SpeechServiceError {
            switch (error, expected) {
            case (.speechPermissionDenied, .speechPermissionDenied),
                 (.speechPermissionRestricted, .speechPermissionRestricted),
                 (.microphonePermissionDenied, .microphonePermissionDenied):
                break
            default:
                XCTFail("Unexpected SpeechServiceError: \(error)", file: file, line: line)
            }
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }
}
#else
import XCTest

final class Gate0_SpeechServiceAuthorizationTests: XCTestCase {
    func testSpeechAuthorizationSkippedOnNonIOS() throws {
        throw XCTSkip("Speech authorization matrix is only available on iOS.")
    }
}
#endif
