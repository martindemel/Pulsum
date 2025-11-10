import Foundation
import Speech
#if os(iOS)
import AVFoundation
#endif
import os.log

private let speechLogger = Logger(subsystem: "ai.pulsum", category: "SpeechService")

enum SpeechLoggingPolicy {
#if DEBUG
    static let transcriptLoggingEnabled = true
#else
    static let transcriptLoggingEnabled = false
#endif
}

public protocol SpeechAuthorizationProviding: Sendable {
    func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus
    func requestRecordPermission() async -> Bool
}

public struct SystemSpeechAuthorizationProvider: SpeechAuthorizationProviding {
    public init() {}

    public func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    public func requestRecordPermission() async -> Bool {
#if os(iOS)
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
#else
        return true
#endif
    }
}

public struct SpeechSegment: Sendable {
    public let transcript: String
    public let confidence: Float
}

public enum SpeechServiceError: LocalizedError {
    case speechPermissionDenied
    case speechPermissionRestricted
    case microphonePermissionDenied
    case recognitionUnavailable
    case engineError(String)
    case audioSessionUnavailable

    public var errorDescription: String? {
        switch self {
        case .speechPermissionDenied:
            return "Speech recognition permission denied."
        case .speechPermissionRestricted:
            return "Speech recognition is restricted on this device."
        case .microphonePermissionDenied:
            return "Microphone access is required to record journals."
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
        public let audioLevels: AsyncStream<Float>?
    }

    private enum Backend {
        case modern(ModernSpeechBackend)
        case legacy(LegacySpeechBackend)
    }

    private let backend: Backend

    public init(locale: Locale = Locale(identifier: "en_US"),
                authorizationProvider: SpeechAuthorizationProviding = SystemSpeechAuthorizationProvider()) {
        if #available(iOS 26.0, *), let modern = ModernSpeechBackend(locale: locale, authorizationProvider: authorizationProvider) {
            backend = .modern(modern)
        } else {
            backend = .legacy(LegacySpeechBackend(locale: locale, authorizationProvider: authorizationProvider))
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
    private var streamContinuation: AsyncThrowingStream<SpeechSegment, Error>.Continuation?
    private var levelContinuation: AsyncStream<Float>.Continuation?
    private let authorizationProvider: SpeechAuthorizationProviding

    init(locale: Locale, authorizationProvider: SpeechAuthorizationProviding) {
        let recognizer = SFSpeechRecognizer(locale: locale)
        recognizer?.supportsOnDeviceRecognition = true
        self.recognizer = recognizer
        self.authorizationProvider = authorizationProvider
    }

    func requestAuthorization() async throws {
        let status = await authorizationProvider.requestSpeechAuthorization()
        switch status {
        case .authorized:
            break
        case .denied:
            throw SpeechServiceError.speechPermissionDenied
        case .restricted:
            throw SpeechServiceError.speechPermissionRestricted
        default:
            throw SpeechServiceError.speechPermissionDenied
        }
#if os(iOS)
        let granted = await authorizationProvider.requestRecordPermission()
        guard granted else { throw SpeechServiceError.microphonePermissionDenied }
#endif
    }

    func startRecording(maxDuration: TimeInterval) async throws -> SpeechService.Session {
        guard let recognizer, recognizer.isAvailable else {
            speechLogger.error("Speech recognizer not available.")
            throw SpeechServiceError.recognitionUnavailable
        }
        speechLogger.info("Speech recognizer available (on-device: \(recognizer.supportsOnDeviceRecognition)).")

#if os(iOS)
        guard AVAudioSession.sharedInstance().recordPermission == .granted else {
            throw SpeechServiceError.microphonePermissionDenied
        }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            speechLogger.info("Audio session configured.")
        } catch {
#if targetEnvironment(simulator)
            // In simulator, audio session config may fail but recording still works
            speechLogger.debug("Audio session config failed in simulator (expected): \(error.localizedDescription, privacy: .public)")
#else
            speechLogger.error("Audio session configuration failed: \(error.localizedDescription, privacy: .public)")
            throw SpeechServiceError.audioSessionUnavailable
#endif
        }
#endif

        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        request.shouldReportPartialResults = true
        
        speechLogger.debug("Starting audio engine...")

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        speechLogger.debug("Audio format sampleRate=\(format.sampleRate, privacy: .public) channels=\(format.channelCount, privacy: .public)")
        inputNode.removeTap(onBus: 0)
        
        // Create audio level stream with stored continuation
        let audioLevelStream = AsyncStream<Float> { continuation in
            self.levelContinuation = continuation
            continuation.onTermination = { @Sendable _ in
                speechLogger.debug("Audio level stream terminated.")
            }
            
            // Install tap to capture audio and send to recognition
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                // Feed buffer to speech recognition
                request.append(buffer)
                
                // Calculate and yield RMS power level for waveform visualization
                let level = Self.calculateRMSLevel(from: buffer)
                continuation.yield(level)
            }
        }

        engine.prepare()
        do {
            try engine.start()
            speechLogger.info("Audio engine started.")
        } catch {
            speechLogger.error("Failed to start audio engine: \(error.localizedDescription, privacy: .public)")
            throw SpeechServiceError.engineError(error.localizedDescription)
        }

        audioEngine = engine
        recognitionRequest = request

        // Create speech segment stream with stored continuation
        let stream = AsyncThrowingStream<SpeechSegment, Error> { continuation in
            self.streamContinuation = continuation
            continuation.onTermination = { @Sendable _ in
                speechLogger.debug("Speech segment stream terminated.")
            }
        }
        
        // Start recognition task IMMEDIATELY (not deferred until stream consumption)
        speechLogger.debug("Starting recognition task.")
        self.recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            
            if let error {
                speechLogger.error("Recognition error: \(error.localizedDescription, privacy: .public)")
                self.streamContinuation?.finish(throwing: error)
                return
            }
            
            guard let result else { return }
            
            let confidence = result.transcriptions.first?.segments.averageConfidence ?? 0
            let transcript = result.bestTranscription.formattedString
            
            if !transcript.isEmpty {
#if DEBUG
                if SpeechLoggingPolicy.transcriptLoggingEnabled {
                    speechLogger
                        .debug("PULSUM_TRANSCRIPT_LOG_MARKER final=\(result.isFinal, privacy: .public) chars=\(transcript.count, privacy: .public) confidence=\(confidence, privacy: .public)")
                }
#endif
                self.streamContinuation?.yield(SpeechSegment(transcript: transcript, confidence: confidence))
            }
            
            if result.isFinal {
                speechLogger.info("Recognition completed with final transcript.")
                self.streamContinuation?.finish()
            }
        }
        
        speechLogger.info("Recognition task listening.")

        // Set up max duration timeout
        if maxDuration > 0 {
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(maxDuration * 1_000_000_000))
                speechLogger.info("Max recording duration reached; stopping.")
                self?.stopRecording()
            }
        }

        return SpeechService.Session(
            stream: stream,
            stop: { [weak self] in
                self?.stopRecording()
            },
            audioLevels: audioLevelStream
        )
    }
    
    private static func calculateRMSLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride)
            .map { channelDataValue[$0] }
        
        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        
        // Convert to dB and normalize to 0...1 range
        let decibels = 20 * log10(max(rms, 0.00001))
        let normalized = max(0, min(1, (decibels + 50) / 50)) // -50dB to 0dB mapped to 0...1
        
        return normalized
    }

    func stopRecording() {
        speechLogger.info("Stopping recording.")
        
        // Finish streams
        streamContinuation?.finish()
        streamContinuation = nil
        levelContinuation?.finish()
        levelContinuation = nil
        
        // Cancel recognition task (not cancel, just finish cleanly)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.finish()
        recognitionTask = nil
        
        // Stop audio engine
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        
#if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
#endif
        speechLogger.info("Recording stopped and cleaned up.")
    }
}

extension LegacySpeechBackend: @unchecked Sendable {}

@available(iOS 26.0, *)
private final class ModernSpeechBackend {
    private let locale: Locale
    private let fallback: LegacySpeechBackend

    init?(locale: Locale, authorizationProvider: SpeechAuthorizationProviding) {
        self.locale = locale
        self.fallback = LegacySpeechBackend(locale: locale, authorizationProvider: authorizationProvider)

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
