import Foundation
import Speech
#if os(iOS)
import AVFoundation
#endif
import os.log
import PulsumTypes

private let speechLogger = Logger(subsystem: "ai.pulsum", category: "SpeechService")

enum SpeechLoggingPolicy {
    #if DEBUG
    static let transcriptLoggingEnabled = true
    #else
    static let transcriptLoggingEnabled = false
    #endif
}

private struct SpeechAuthorizationState {
    let speechStatus: SFSpeechRecognizerAuthorizationStatus
    let microphoneGranted: Bool
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

    private let backend: any SpeechBackending
    private let authorizationProvider: SpeechAuthorizationProviding
    private let overrides: SpeechUITestOverrides
    private let backendName: String
    private var cachedAuthorization: SpeechAuthorizationState?

    public init(
        locale: Locale = Locale(identifier: "en_US"),
        authorizationProvider: SpeechAuthorizationProviding = SystemSpeechAuthorizationProvider()
    ) {
        self.authorizationProvider = authorizationProvider
        self.overrides = SpeechUITestOverrides()
        #if DEBUG
        if BuildFlags.uiTestSeamsCompiledIn && overrides.useFakeBackend {
            backend = FakeSpeechBackend(
                authorizationProvider: authorizationProvider,
                autoGrantPermissions: overrides.autoGrantPermissions
            )
            backendName = backend.backendName
            return
        }
        #endif

        if #available(iOS 26.0, *),
           BuildFlags.useModernSpeechBackend,
           let modern = ModernSpeechBackend(locale: locale, authorizationProvider: authorizationProvider) {
            backend = modern
        } else {
            backend = LegacySpeechBackend(locale: locale, authorizationProvider: authorizationProvider)
        }
        backendName = backend.backendName
    }

    public func requestAuthorization() async throws {
        try await preflightPermissions()
        try await backend.requestAuthorization()
    }

    public func startRecording(maxDuration: TimeInterval = 30) async throws -> Session {
        #if DEBUG
        let clock = ContinuousClock()
        let start = clock.now
        let session = try await backend.startRecording(maxDuration: maxDuration)
        let elapsed = start.duration(to: clock.now)
        speechLogger.debug("Speech backend \(self.backendName, privacy: .public) start latency \(elapsed.components.seconds, privacy: .public)s")
        return session
        #else
        return try await backend.startRecording(maxDuration: maxDuration)
        #endif
    }

    public func stopRecording() {
        backend.stopRecording()
    }

    public nonisolated var selectedBackendIdentifier: String { backendName }

    private func preflightPermissions() async throws {
        #if DEBUG
        if overrides.autoGrantPermissions {
            cachedAuthorization = SpeechAuthorizationState(speechStatus: .authorized, microphoneGranted: true)
            return
        }
        #endif
        if let cached = cachedAuthorization,
           cached.speechStatus == .authorized,
           cached.microphoneGranted {
            return
        }

        let speechStatus = await authorizationProvider.requestSpeechAuthorization()
        switch speechStatus {
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
        let microphoneGranted = await authorizationProvider.requestRecordPermission()
        guard microphoneGranted else { throw SpeechServiceError.microphonePermissionDenied }
        #else
        let microphoneGranted = true
        #endif
        cachedAuthorization = SpeechAuthorizationState(speechStatus: speechStatus, microphoneGranted: microphoneGranted)
    }
}

private protocol SpeechBackending: Sendable {
    var backendName: String { get }
    func requestAuthorization() async throws
    func startRecording(maxDuration: TimeInterval) async throws -> SpeechService.Session
    func stopRecording()
}

// Gate-1b: UITest seams are compiled out of Release builds.
// Gate-1b: UITest seams are compiled out of Release builds.
private struct SpeechUITestOverrides {
    let useFakeBackend: Bool
    let autoGrantPermissions: Bool

    init() {
        #if DEBUG
        useFakeBackend = AppRuntimeConfig.useFakeSpeechBackend
        autoGrantPermissions = AppRuntimeConfig.autoGrantSpeechPermissions
        #else
        useFakeBackend = false
        autoGrantPermissions = false
        #endif
    }
}

private final class LegacySpeechBackend: SpeechBackending {
    private let recognizer: SFSpeechRecognizer?
    private let stateQueue = DispatchQueue(label: "ai.pulsum.speech.legacy.state")
    private var audioEngine: AVAudioEngine?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var streamContinuation: AsyncThrowingStream<SpeechSegment, Error>.Continuation?
    private var levelContinuation: AsyncStream<Float>.Continuation?
    private var timeoutTask: Task<Void, Never>?
    let backendName = "legacy"

    init(locale: Locale, authorizationProvider _: SpeechAuthorizationProviding) {
        let recognizer = SFSpeechRecognizer(locale: locale)
        self.recognizer = recognizer
    }

    func requestAuthorization() async throws {
        guard let recognizer else {
            throw SpeechServiceError.recognitionUnavailable
        }
        guard recognizer.isAvailable else {
            throw SpeechServiceError.recognitionUnavailable
        }
    }

    func startRecording(maxDuration: TimeInterval) async throws -> SpeechService.Session {
        guard let recognizer, recognizer.isAvailable else {
            speechLogger.error("Speech recognizer not available.")
            throw SpeechServiceError.recognitionUnavailable
        }
        speechLogger.info("Speech recognizer available (on-device: \(recognizer.supportsOnDeviceRecognition)).")

        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        if session.recordPermission == .undetermined {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                session.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
        guard session.recordPermission == .granted else {
            throw SpeechServiceError.microphonePermissionDenied
        }
        do {
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            speechLogger.info("Audio session configured.")
        } catch {
            #if targetEnvironment(simulator)
            // In simulator, audio session config may fail but recording still works
            let info = Self.safeErrorInfo(error)
            speechLogger.debug("Audio session config failed in simulator (expected). domain=\(info.domain, privacy: .public) code=\(info.code, privacy: .public)")
            #else
            let info = Self.safeErrorInfo(error)
            speechLogger.error("Audio session configuration failed. domain=\(info.domain, privacy: .public) code=\(info.code, privacy: .public)")
            throw SpeechServiceError.audioSessionUnavailable
            #endif
        }
        #endif

        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        request.shouldReportPartialResults = true

        speechLogger.debug("Starting audio engine...")

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        speechLogger.debug("Audio format sampleRate=\(format.sampleRate, privacy: .public) channels=\(format.channelCount, privacy: .public)")
        inputNode.removeTap(onBus: 0)

        // Create audio level stream with stored continuation
        let audioLevelStream = AsyncStream<Float> { continuation in
            self.stateQueue.sync { self.levelContinuation = continuation }
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
            let info = Self.safeErrorInfo(error)
            speechLogger.error("Failed to start audio engine. domain=\(info.domain, privacy: .public) code=\(info.code, privacy: .public)")
            throw SpeechServiceError.engineError(error.localizedDescription)
        }

        stateQueue.sync {
            audioEngine = engine
            recognitionRequest = request
        }

        // Create speech segment stream with stored continuation
        let stream = AsyncThrowingStream<SpeechSegment, Error> { continuation in
            self.stateQueue.sync { self.streamContinuation = continuation }
            continuation.onTermination = { @Sendable _ in
                speechLogger.debug("Speech segment stream terminated.")
            }
        }

        // Start recognition task IMMEDIATELY (not deferred until stream consumption)
        speechLogger.debug("Starting recognition task.")
        let task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let error {
                let info = Self.safeErrorInfo(error)
                speechLogger.error("Recognition error. domain=\(info.domain, privacy: .public) code=\(info.code, privacy: .public)")
                self.stateQueue.sync { self.streamContinuation }?.finish(throwing: error)
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
                self.stateQueue.sync { self.streamContinuation }?.yield(
                    SpeechSegment(transcript: transcript, isFinal: result.isFinal, confidence: confidence)
                )
            }

            if result.isFinal {
                speechLogger.info("Recognition completed with final transcript.")
                self.stateQueue.sync { self.streamContinuation }?.finish()
            }
        }
        stateQueue.sync { self.recognitionTask = task }

        speechLogger.info("Recognition task listening.")

        // Set up max duration timeout (stored for cancellation in stopRecording)
        if maxDuration > 0 {
            let task = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(maxDuration * 1_000_000_000))
                guard !Task.isCancelled else { return }
                speechLogger.info("Max recording duration reached; stopping.")
                self?.stopRecording()
            }
            stateQueue.sync { self.timeoutTask = task }
        }

        return SpeechService.Session(
            stream: stream,
            stop: { [weak self] in
                self?.stopRecording()
            },
            audioLevels: audioLevelStream
        )
    }

    private static func safeErrorInfo(_ error: Error) -> (domain: String, code: Int) {
        let nsError = error as NSError
        return (nsError.domain, nsError.code)
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

        // Take all mutable state under lock, then perform cleanup outside to avoid deadlock
        // (recognitionTask?.finish() could synchronously fire recognition callback)
        let (stream, level, request, task, engine, timeout) = stateQueue.sync {
            let snapshot = (streamContinuation, levelContinuation, recognitionRequest, recognitionTask, audioEngine, timeoutTask)
            streamContinuation = nil
            levelContinuation = nil
            recognitionRequest = nil
            recognitionTask = nil
            audioEngine = nil
            timeoutTask = nil
            return snapshot
        }

        // Cancel timeout task to prevent re-entrant stop
        timeout?.cancel()

        // Finish streams
        stream?.finish()
        level?.finish()

        // Cancel recognition task (not cancel, just finish cleanly)
        request?.endAudio()
        task?.finish()

        // Stop audio engine
        engine?.stop()
        engine?.inputNode.removeTap(onBus: 0)

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
        speechLogger.info("Recording stopped and cleaned up.")
    }
}

// SAFETY: Mutable state (`audioEngine`, `recognitionTask`, `recognitionRequest`,
// `streamContinuation`, `levelContinuation`) is exclusively accessed under `stateQueue`.
extension LegacySpeechBackend: @unchecked Sendable {}

#if DEBUG
#if DEBUG
private final class FakeSpeechBackend: SpeechBackending {
    private let authorizationProvider: SpeechAuthorizationProviding
    private let autoGrantPermissions: Bool
    private let stateQueue = DispatchQueue(label: "ai.pulsum.speech.fake.state")
    private var streamTask: Task<Void, Never>?
    private var levelTask: Task<Void, Never>?
    private var streamContinuation: AsyncThrowingStream<SpeechSegment, Error>.Continuation?
    private var levelContinuation: AsyncStream<Float>.Continuation?
    private var stopHandler: (@Sendable () -> Void)?
    let backendName = "fake"

    init(authorizationProvider: SpeechAuthorizationProviding, autoGrantPermissions: Bool) {
        self.authorizationProvider = authorizationProvider
        self.autoGrantPermissions = autoGrantPermissions
    }

    func requestAuthorization() async throws {
        guard !autoGrantPermissions else { return }
        _ = await authorizationProvider.requestSpeechAuthorization()
        #if os(iOS)
        _ = await authorizationProvider.requestRecordPermission()
        #endif
    }

    func startRecording(maxDuration: TimeInterval) async throws -> SpeechService.Session {
        let stream = AsyncThrowingStream<SpeechSegment, Error> { continuation in
            self.stateQueue.sync {
                self.streamContinuation = continuation
                self.streamTask = Task {
                    for segment in Self.scriptedSegments {
                        if Task.isCancelled { break }
                        try? await Task.sleep(nanoseconds: 350_000_000)
                        continuation.yield(segment)
                    }
                    let deadline = Date().addingTimeInterval(maxDuration)
                    while !Task.isCancelled && Date() < deadline {
                        try? await Task.sleep(nanoseconds: 200_000_000)
                    }
                    continuation.finish()
                }
            }
        }

        let levelStream = AsyncStream<Float> { continuation in
            self.stateQueue.sync {
                self.levelContinuation = continuation
                self.levelTask = Task {
                    var cursor: Float = 0.15
                    while !Task.isCancelled {
                        cursor = cursor >= 0.9 ? 0.2 : cursor + 0.15
                        continuation.yield(cursor)
                        try? await Task.sleep(nanoseconds: 120_000_000)
                    }
                }
            }
        }

        let stop: @Sendable () -> Void = { [weak self] in
            guard let self else { return }
            let (sTask, lTask, sCont, lCont) = self.stateQueue.sync {
                let snapshot = (self.streamTask, self.levelTask, self.streamContinuation, self.levelContinuation)
                self.streamTask = nil
                self.levelTask = nil
                self.streamContinuation = nil
                self.levelContinuation = nil
                return snapshot
            }
            sTask?.cancel()
            lTask?.cancel()
            sCont?.finish()
            lCont?.finish()
        }
        stateQueue.sync { stopHandler = stop }

        return SpeechService.Session(
            stream: stream,
            stop: stop,
            audioLevels: levelStream
        )
    }

    func stopRecording() {
        let handler = stateQueue.sync { () -> (@Sendable () -> Void)? in
            let h = stopHandler
            stopHandler = nil
            return h
        }
        handler?()
    }

    private static let scriptedSegments: [SpeechSegment] = [
        SpeechSegment(transcript: "Energy feels steady and focus is clear.", isFinal: false, confidence: 0.95),
        SpeechSegment(transcript: "Energy feels steady and focus is clear. Quick calm check-in for Pulsum.", isFinal: false, confidence: 0.94),
        SpeechSegment(transcript: "Energy feels steady and focus is clear. Plan is to stretch after meetings.", isFinal: true, confidence: 0.97)
    ]
}

// SAFETY: Mutable state is exclusively accessed under `stateQueue`.
extension FakeSpeechBackend: @unchecked Sendable {}
#endif
#endif

@available(iOS 26.0, *)
private final class ModernSpeechBackend: SpeechBackending {
    private let fallback: LegacySpeechBackend
    let backendName = "modern"
    #if DEBUG
    nonisolated(unsafe) static var availabilityOverride: Bool?
    #endif

    init?(locale: Locale, authorizationProvider: SpeechAuthorizationProviding) {
        self.fallback = LegacySpeechBackend(locale: locale, authorizationProvider: authorizationProvider)

        guard ModernSpeechBackend.isSystemAnalyzerAvailable else {
            return nil
        }
    }

    func requestAuthorization() async throws {
        try await fallback.requestAuthorization()
    }

    func startRecording(maxDuration: TimeInterval) async throws -> SpeechService.Session {
        // NOTE: When Apple ships public SpeechAnalyzer/SpeechTranscriber APIs, integrate them here.
        // For now we reuse the legacy backend under a feature flag (Gate-2 hook) to preserve functionality.
        return try await fallback.startRecording(maxDuration: maxDuration)
    }

    func stopRecording() {
        fallback.stopRecording()
    }

    private static var isSystemAnalyzerAvailable: Bool {
        #if DEBUG
        if let override = availabilityOverride { return override }
        #endif
        return NSClassFromString("SpeechTranscriber") != nil || NSClassFromString("SpeechAnalyzer") != nil
    }
}

// SAFETY: Only immutable `let` properties plus `nonisolated(unsafe)` debug-only static.
@available(iOS 26.0, *)
extension ModernSpeechBackend: @unchecked Sendable {}

#if os(iOS)
private extension [SFTranscriptionSegment] {
    var averageConfidence: Float {
        guard !isEmpty else { return 0 }
        let total = reduce(Float(0)) { $0 + $1.confidence }
        return total / Float(count)
    }
}
#else
private extension [SFTranscriptionSegment] {
    var averageConfidence: Float { 0 }
}
#endif

#if DEBUG
enum SpeechServiceDebug {
    static func overrideModernBackendAvailability(_ value: Bool?) {
        if #available(iOS 26.0, *) {
            ModernSpeechBackend.availabilityOverride = value
        }
    }
}
#endif
