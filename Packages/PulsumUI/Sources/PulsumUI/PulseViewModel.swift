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

    var isRecording = false
    var recordingSecondsRemaining: Int = 30
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
        recordingSecondsRemaining = Int(maxDuration.rounded(.up))
        isRecording = true
        isAnalyzing = true
        recordingTask?.cancel()
        recordingTask = nil
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
                let response = try await orchestrator.recordVoiceJournal(maxDuration: maxDuration)
                self.transcript = response.result.transcript
                self.sentimentScore = response.result.sentimentScore
                self.onSafetyDecision?(response.safety)
                self.lastCapturedAt = Date()
            } catch {
                self.analysisError = error.localizedDescription
            }
            self.isRecording = false
            self.isAnalyzing = false
            self.cancelCountdown()
            self.recordingTask = nil
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        cancelCountdown()
        isRecording = false
        orchestrator?.stopVoiceJournalRecording()
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
    }
}
