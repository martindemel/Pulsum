import Foundation
import Observation
import PulsumAgents
import SwiftUI

@MainActor
@Observable
final class PulseViewModel {
    private enum RecordingError: LocalizedError {
        case streamUnavailable

        var errorDescription: String? {
            switch self {
            case .streamUnavailable:
                return "Unable to access the microphone stream."
            }
        }
    }
    @ObservationIgnored private var orchestrator: AgentOrchestrator?
    @ObservationIgnored private var countdownTask: Task<Void, Never>?
    @ObservationIgnored private var recordingTask: Task<Void, Never>?
    @ObservationIgnored private var audioLevelTask: Task<Void, Never>?
    @ObservationIgnored private var toastTask: Task<Void, Never>?

    var isRecording = false
    var recordingSecondsRemaining: Int = 30
    var waveformLevels = LiveWaveformLevels(capacity: 180)
    var transcript: String?
    var sentimentScore: Double?
    var analysisError: String?
    var lastCapturedAt: Date?

    var stressLevel: Double = 4
    var energyLevel: Double = 4
    var sleepQualityLevel: Double = 4

    var isSubmittingInputs = false
    var sliderSubmissionMessage: String?
    var sliderErrorMessage: String?

    var isAnalyzing = false
    var onSafetyDecision: ((SafetyDecision) -> Void)?
    var savedToastMessage: String?

    func bind(orchestrator: AgentOrchestrator) {
        self.orchestrator = orchestrator
    }

    func startRecording(maxDuration: TimeInterval = 30) {
        guard let orchestrator else { return }
        guard !isRecording && !isAnalyzing else { return }
        cancelCountdown()
        toastTask?.cancel()
        savedToastMessage = nil
        analysisError = nil
        transcript = nil
        sentimentScore = nil
        lastCapturedAt = nil
        waveformLevels.reset()
        recordingSecondsRemaining = Int(maxDuration.rounded(.up))
        isRecording = true
        isAnalyzing = true
        recordingTask?.cancel()
        recordingTask = nil
        audioLevelTask?.cancel()
        audioLevelTask = nil

        countdownTask = Task { [weak self] in
            guard let self else { return }
            var remaining = maxDuration
            while remaining > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                remaining -= 1
                if !Task.isCancelled {
                    self.recordingSecondsRemaining = max(Int(remaining.rounded(.up)), 0)
                }
            }
        }

        recordingTask = Task { [weak self] in
            guard let self else { return }
            var latestTranscript = ""
            do {
                try await orchestrator.beginVoiceJournalRecording(maxDuration: maxDuration)

                guard let speechStream = orchestrator.voiceJournalSpeechStream,
                      let levelStream = orchestrator.voiceJournalAudioLevels else {
                    throw RecordingError.streamUnavailable
                }

                audioLevelTask = Task.detached { [weak self] in
                    guard let self else { return }
                    for await level in levelStream {
                        guard !Task.isCancelled else { break }
                        await MainActor.run {
                            self.waveformLevels.append(CGFloat(level))
                        }
                    }
                }

                for try await segment in speechStream {
                    guard !Task.isCancelled else { break }
                    latestTranscript = segment.transcript
                    orchestrator.updateVoiceJournalTranscript(latestTranscript)
                    transcript = latestTranscript
                }

                isRecording = false
                let response = try await orchestrator.finishVoiceJournalRecording(transcript: latestTranscript)
                handleJournalResponse(response)
            } catch {
                await handleRecordingFailure(error,
                                             orchestrator: orchestrator,
                                             latestTranscript: latestTranscript)
            }

            isRecording = false
            isAnalyzing = false
            cancelCountdown()
            recordingTask = nil
            audioLevelTask?.cancel()
            audioLevelTask = nil
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        
        // Stop audio capture but keep processing state
        // The recording task will continue and save the transcript
        cancelCountdown()
        isRecording = false
        audioLevelTask?.cancel()
        audioLevelTask = nil
        
        // This signals the speech service to stop capturing audio
        // The transcript captured so far will be processed
        orchestrator?.stopVoiceJournalRecording()
        
        // isAnalyzing remains true - will be set to false when processing completes
        // recordingTask continues running to save the transcript
    }

    func submitInputs(for date: Date = Date()) {
        guard let orchestrator else { return }
        isSubmittingInputs = true
        sliderErrorMessage = nil
        sliderSubmissionMessage = nil
        Task { [weak self] in
            guard let self else { return }
            do {
                try await orchestrator.updateSubjectiveInputs(
                    date: date,
                    stress: stressLevel,
                    energy: energyLevel,
                    sleepQuality: sleepQualityLevel
                )
                self.sliderSubmissionMessage = "Thanks for checking in."
                self.scheduleSubmissionReset()
            } catch {
                self.sliderErrorMessage = error.localizedDescription
            }
            self.isSubmittingInputs = false
        }
    }

    func clearTranscript() {
        transcript = nil
        sentimentScore = nil
        analysisError = nil
        savedToastMessage = nil
        lastCapturedAt = nil
        toastTask?.cancel()
        toastTask = nil
    }

    private func scheduleSubmissionReset() {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard let self else { return }
            self.sliderSubmissionMessage = nil
        }
    }

    private func handleJournalResponse(_ response: JournalCaptureResponse) {
        transcript = response.result.transcript
        sentimentScore = response.result.sentimentScore
        lastCapturedAt = Date()
        onSafetyDecision?(response.safety)
        analysisError = nil
        if response.result.embeddingPending {
            savedToastMessage = "Saved. We'll analyze this entry when the on-device model is available."
        } else {
            savedToastMessage = "Saved to Journal"
        }
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                self?.savedToastMessage = nil
            }
        }
    }

    private func handleRecordingFailure(_ error: Error,
                                        orchestrator: AgentOrchestrator,
                                        latestTranscript: String) async {
        analysisError = mapRecordingError(error)
        let fallback = latestTranscript.isEmpty ? (transcript ?? "") : latestTranscript
        let trimmed = fallback.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            orchestrator.stopVoiceJournalRecording()
            return
        }
        if let response = try? await orchestrator.finishVoiceJournalRecording(transcript: trimmed) {
            handleJournalResponse(response)
        }
    }

    private func mapRecordingError(_ error: Error) -> String {
        if let sentimentError = error as? SentimentAgentError {
            switch sentimentError {
            case .noSpeechDetected:
                return "I couldn't hear anything. Let's try again."
            case .sessionAlreadyActive:
                return "Recording already in progress."
            case .noActiveRecording:
                return "No active recording to finish."
            }
        }
        // NOTE: keep UI layer decoupled from PulsumServices; lower layers surface user-facing copy via LocalizedError.
        return error.localizedDescription
    }

    private func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
    }

    deinit {
        countdownTask?.cancel()
        recordingTask?.cancel()
        audioLevelTask?.cancel()
        toastTask?.cancel()
    }
}
