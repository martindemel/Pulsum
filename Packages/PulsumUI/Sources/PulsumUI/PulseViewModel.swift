import Foundation
import Observation
import PulsumAgents

@MainActor
@Observable
final class PulseViewModel {
    private enum RecorderState {
        case idle
        case recording
        case processing
    }

    @ObservationIgnored private var orchestrator: AgentOrchestrator?
    @ObservationIgnored private var countdownTask: Task<Void, Never>?
    @ObservationIgnored private var recordingTask: Task<Void, Never>?
    @ObservationIgnored private var audioLevelTask: Task<Void, Never>?

    var isRecording = false
    var recordingSecondsRemaining: Int = 30
    var audioLevels: [CGFloat] = Array(repeating: 0, count: 120)
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

    func bind(orchestrator: AgentOrchestrator) {
        self.orchestrator = orchestrator
    }

    func startRecording(maxDuration: TimeInterval = 30) {
        guard let orchestrator else { return }
        guard !isRecording && !isAnalyzing else { return }
        cancelCountdown()
        analysisError = nil
        transcript = nil
        sentimentScore = nil
        lastCapturedAt = nil
        audioLevels = Array(repeating: 0, count: 120)
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
            do {
                // Begin recording - this returns immediately after starting audio capture
                try await orchestrator.beginVoiceJournalRecording(maxDuration: maxDuration)
                
                // Get the speech stream for real-time transcription
                guard let speechStream = orchestrator.voiceJournalSpeechStream else {
                    self.analysisError = "Unable to access speech stream"
                    self.isRecording = false
                    self.isAnalyzing = false
                    self.cancelCountdown()
                    return
                }
                
                // Audio levels are now available synchronously
                guard let levelStream = orchestrator.voiceJournalAudioLevels else {
                    self.analysisError = "Unable to access audio stream"
                    self.isRecording = false
                    self.isAnalyzing = false
                    self.cancelCountdown()
                    return
                }
                
                // Start consuming audio levels in parallel
                self.audioLevelTask = Task { [weak self] in
                    guard let self else { return }
                    for await level in levelStream {
                        guard !Task.isCancelled else { break }
                        var levels = self.audioLevels
                        levels.append(CGFloat(level))
                        levels.removeFirst()
                        self.audioLevels = levels
                    }
                }
                
                // Consume speech stream for REAL-TIME transcription display
                var latestTranscript = ""
                for try await segment in speechStream {
                    guard !Task.isCancelled else { break }
                    latestTranscript = segment.transcript
                    // Update UI with real-time transcript
                    self.transcript = latestTranscript
                }
                
                // Recording complete, now processing sentiment
                self.isRecording = false
                // Keep isAnalyzing = true during sentiment processing
                
                // Process the final transcript (passing it to avoid re-processing)
                let response = try await orchestrator.finishVoiceJournalRecording(transcript: latestTranscript)
                
                self.transcript = response.result.transcript
                self.sentimentScore = response.result.sentimentScore
                self.onSafetyDecision?(response.safety)
                self.lastCapturedAt = Date()
                
            } catch {
                self.analysisError = error.localizedDescription
            }
            
            // All processing complete
            self.isRecording = false
            self.isAnalyzing = false
            self.cancelCountdown()
            self.recordingTask = nil
            self.audioLevelTask?.cancel()
            self.audioLevelTask = nil
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

    private func scheduleSubmissionReset() {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard let self else { return }
            self.sliderSubmissionMessage = nil
        }
    }

    private func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
    }

    deinit {
        countdownTask?.cancel()
        recordingTask?.cancel()
        audioLevelTask?.cancel()
    }
}
