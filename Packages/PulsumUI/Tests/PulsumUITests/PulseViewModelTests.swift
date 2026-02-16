import Foundation
import Testing
@testable import PulsumAgents
import PulsumTypes
@testable import PulsumUI

// MARK: - Mock orchestrator

@MainActor
private final class StubPulseOrchestrator: PulseOrchestrating {
    var updateSubjectiveInputsCalled = false
    var updateSubjectiveInputsError: (any Error)?
    var lastStress: Double?
    var lastEnergy: Double?
    var lastSleepQuality: Double?

    func beginVoiceJournalRecording(maxDuration _: TimeInterval) async throws {}

    func finishVoiceJournalRecording(transcript _: String?) async throws -> JournalCaptureResponse {
        JournalCaptureResponse(
            result: JournalResult(
                entryID: UUID(),
                date: Date(),
                transcript: "",
                sentimentScore: 0,
                vectorURL: nil,
                embeddingPending: false
            ),
            safety: SafetyDecision(
                classification: .safe,
                allowCloud: true,
                crisisMessage: nil,
                crisisResources: nil
            )
        )
    }

    var voiceJournalSpeechStream: AsyncThrowingStream<SpeechSegment, Error>? { nil }
    var voiceJournalAudioLevels: AsyncStream<Float>? { nil }
    func updateVoiceJournalTranscript(_: String) {}
    func stopVoiceJournalRecording() {}

    nonisolated func updateSubjectiveInputs(date _: Date,
                                            stress: Double,
                                            energy: Double,
                                            sleepQuality: Double) async throws {
        await MainActor.run {
            self.updateSubjectiveInputsCalled = true
            self.lastStress = stress
            self.lastEnergy = energy
            self.lastSleepQuality = sleepQuality
        }
        if let error = await MainActor.run(body: { self.updateSubjectiveInputsError }) {
            throw error
        }
    }
}

// MARK: - Tests

@MainActor
struct PulseViewModelTests {
    @Test("Initial state has recording off and transcript nil")
    func test_initialState() {
        let vm = PulseViewModel()
        #expect(vm.isRecording == false)
        #expect(vm.transcript == nil)
        #expect(vm.sentimentScore == nil)
        #expect(vm.isSubmittingInputs == false)
        #expect(vm.sliderSubmissionMessage == nil)
        #expect(vm.sliderErrorMessage == nil)
        #expect(vm.isAnalyzing == false)
        #expect(vm.stressLevel == 4)
        #expect(vm.energyLevel == 4)
        #expect(vm.sleepQualityLevel == 4)
    }

    @Test("submitInputs updates state through success flow")
    func test_submitInputs_updatesState() async throws {
        let orchestrator = StubPulseOrchestrator()
        let vm = PulseViewModel()
        vm.bind(orchestrator: orchestrator)

        vm.stressLevel = 7
        vm.energyLevel = 3
        vm.sleepQualityLevel = 8
        vm.submitInputs()

        // isSubmittingInputs should be true immediately
        #expect(vm.isSubmittingInputs == true)

        // Wait for the background task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(orchestrator.updateSubjectiveInputsCalled == true)
        #expect(orchestrator.lastStress == 7)
        #expect(orchestrator.lastEnergy == 3)
        #expect(orchestrator.lastSleepQuality == 8)
        #expect(vm.isSubmittingInputs == false)
        #expect(vm.sliderSubmissionMessage == "Thanks for checking in.")
        #expect(vm.sliderErrorMessage == nil)
    }

    @Test("submitInputs without orchestrator is a no-op")
    func test_submitInputs_noOrchestrator() {
        let vm = PulseViewModel()
        vm.submitInputs()
        #expect(vm.isSubmittingInputs == false)
    }

    @Test("submitInputs surfaces error message on failure")
    func test_submitInputs_error() async throws {
        let orchestrator = StubPulseOrchestrator()
        orchestrator.updateSubjectiveInputsError = NSError(
            domain: "test", code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Test failure"]
        )
        let vm = PulseViewModel()
        vm.bind(orchestrator: orchestrator)

        vm.submitInputs()
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(vm.isSubmittingInputs == false)
        #expect(vm.sliderErrorMessage == "Test failure")
        #expect(vm.sliderSubmissionMessage == nil)
    }
}
