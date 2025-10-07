import Foundation
import Speech
#if os(iOS)
import AVFoundation
#endif

public struct SpeechSegment: Sendable {
    public let transcript: String
    public let confidence: Float
}

public enum SpeechServiceError: LocalizedError {
    case permissionDenied
    case recognitionUnavailable
    case engineError(String)
    case audioSessionUnavailable

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Speech recognition permission denied."
        case .recognitionUnavailable:
            return "On-device speech recognition is not available."
        case let .engineError(message):
            return message
        case .audioSessionUnavailable:
            return "Unable to configure audio session."
        }
    }
}

/// Handles on-device speech recognition with a managed lifecycle.
public actor SpeechService {
    public struct Session: Sendable {
        public let stream: AsyncThrowingStream<SpeechSegment, Error>
        public let stop: @Sendable () -> Void
    }

    private enum Backend {
        case modern(ModernSpeechBackend)
        case legacy(LegacySpeechBackend)
    }

    private let backend: Backend

    public init(locale: Locale = Locale(identifier: "en_US")) {
        if #available(iOS 26.0, *), let modern = ModernSpeechBackend(locale: locale) {
            backend = .modern(modern)
        } else {
            backend = .legacy(LegacySpeechBackend(locale: locale))
        }
    }

    public func requestAuthorization() async throws {
        switch backend {
        case .modern(let backend):
            try await backend.requestAuthorization()
        case .legacy(let backend):
            try await backend.requestAuthorization()
        }
    }

    public func startRecording(maxDuration: TimeInterval = 30) async throws -> Session {
        switch backend {
        case .modern(let backend):
            return try await backend.startRecording(maxDuration: maxDuration)
        case .legacy(let backend):
            return try await backend.startRecording(maxDuration: maxDuration)
        }
    }

    public func stopRecording() {
        switch backend {
        case .modern(let backend):
            backend.stopRecording()
        case .legacy(let backend):
            backend.stopRecording()
        }
    }
}

private final class LegacySpeechBackend {
    private let recognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    init(locale: Locale) {
        let recognizer = SFSpeechRecognizer(locale: locale)
        recognizer?.supportsOnDeviceRecognition = true
        self.recognizer = recognizer
    }

    func requestAuthorization() async throws {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard status == .authorized else { throw SpeechServiceError.permissionDenied }
    }

    func startRecording(maxDuration: TimeInterval) async throws -> SpeechService.Session {
        guard let recognizer, recognizer.isAvailable else {
            throw SpeechServiceError.recognitionUnavailable
        }

#if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            #if targetEnvironment(simulator)
            // In simulator, audio session config may fail but recording still works
            print("[SpeechService] Audio session config failed in simulator (expected): \(error)")
            #else
            throw SpeechServiceError.audioSessionUnavailable
            #endif
        }
#endif

        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        request.shouldReportPartialResults = true

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            throw SpeechServiceError.engineError(error.localizedDescription)
        }

        audioEngine = engine
        recognitionRequest = request

        let stream = AsyncThrowingStream<SpeechSegment, Error> { continuation in
            self.recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    continuation.finish(throwing: error)
                    return
                }
                guard let result else { return }
                let confidence = result.transcriptions.first?.segments.averageConfidence ?? 0
                continuation.yield(SpeechSegment(transcript: result.bestTranscription.formattedString,
                                                  confidence: confidence))
                if result.isFinal {
                    continuation.finish()
                }
            }

            if maxDuration > 0 {
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(maxDuration * 1_000_000_000))
                    self.stopRecording()
                    continuation.finish()
                }
            }
        }

        return SpeechService.Session(stream: stream, stop: { [weak self] in
            self?.stopRecording()
        })
    }

    func stopRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
#if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
#endif
    }
}

extension LegacySpeechBackend: @unchecked Sendable {}

@available(iOS 26.0, *)
private final class ModernSpeechBackend {
    private let locale: Locale
    private let fallback: LegacySpeechBackend

    init?(locale: Locale) {
        self.locale = locale
        self.fallback = LegacySpeechBackend(locale: locale)

        guard ModernSpeechBackend.isSystemAnalyzerAvailable else {
            return nil
        }
    }

    func requestAuthorization() async throws {
        try await fallback.requestAuthorization()
    }

    func startRecording(maxDuration: TimeInterval) async throws -> SpeechService.Session {
        // Placeholder: integrate SpeechAnalyzer/SpeechTranscriber APIs when publicly available.
        // For now we reuse the legacy backend to ensure functionality while maintaining the interface.
        return try await fallback.startRecording(maxDuration: maxDuration)
    }

    func stopRecording() {
        fallback.stopRecording()
    }

    private static var isSystemAnalyzerAvailable: Bool {
        NSClassFromString("SpeechTranscriber") != nil || NSClassFromString("SpeechAnalyzer") != nil
    }
}

@available(iOS 26.0, *)
extension ModernSpeechBackend: @unchecked Sendable {}

#if os(iOS)
private extension Array where Element == SFTranscriptionSegment {
    var averageConfidence: Float {
        guard !isEmpty else { return 0 }
        let total = reduce(Float(0)) { $0 + $1.confidence }
        return total / Float(count)
    }
}
#else
private extension Array where Element == SFTranscriptionSegment {
    var averageConfidence: Float { 0 }
}
#endif
