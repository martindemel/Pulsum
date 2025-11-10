import XCTest
import Speech
@testable import PulsumServices

final class SpeechServiceAuthorizationTests: XCTestCase {
    func testRequestAuthorizationSucceedsWhenPermissionsGranted() async throws {
        let provider = StubSpeechAuthorizationProvider(speechStatus: .authorized, recordPermission: true)
        let service = SpeechService(authorizationProvider: provider)
        try await service.requestAuthorization()
    }

    func testRequestAuthorizationFailsWhenSpeechDenied() async {
        let provider = StubSpeechAuthorizationProvider(speechStatus: .denied, recordPermission: true)
        let service = SpeechService(authorizationProvider: provider)
        await XCTAssertThrowsErrorAsync(try await service.requestAuthorization()) { error in
            guard case SpeechServiceError.speechPermissionDenied = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testRequestAuthorizationFailsWhenSpeechRestricted() async {
        let provider = StubSpeechAuthorizationProvider(speechStatus: .restricted, recordPermission: true)
        let service = SpeechService(authorizationProvider: provider)
        await XCTAssertThrowsErrorAsync(try await service.requestAuthorization()) { error in
            guard case SpeechServiceError.speechPermissionRestricted = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

#if os(iOS)
    func testRequestAuthorizationFailsWhenMicDenied() async {
        let provider = StubSpeechAuthorizationProvider(speechStatus: .authorized, recordPermission: false)
        let service = SpeechService(authorizationProvider: provider)
        await XCTAssertThrowsErrorAsync(try await service.requestAuthorization()) { error in
            guard case SpeechServiceError.microphonePermissionDenied = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }
#endif
}

private struct StubSpeechAuthorizationProvider: SpeechAuthorizationProviding {
    let speechStatus: SFSpeechRecognizerAuthorizationStatus
    let recordPermission: Bool

    func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        speechStatus
    }

    func requestRecordPermission() async -> Bool {
        recordPermission
    }
}

private extension XCTestCase {
    func XCTAssertThrowsErrorAsync<T>(
        _ expression: @autoclosure () async throws -> T,
        _ handler: (Error) -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error", file: file, line: line)
        } catch {
            handler(error)
        }
    }
}
