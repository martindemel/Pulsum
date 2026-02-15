import PulsumAgents
import Testing
@testable import PulsumUI

// MARK: - B7-12 | TC-20: SafetyCardView display tests

@MainActor
struct SafetyCardViewTests {
    @Test("SafetyCardView can be initialized without crash")
    func test_crisisCardRenders() {
        let view = SafetyCardView(
            message: "If you are in danger, please call emergency services.",
            crisisResources: nil,
            dismiss: {}
        )
        #expect(view.message == "If you are in danger, please call emergency services.")
        #expect(view.crisisResources == nil)
    }

    @Test("SafetyCardView with crisis resources contains expected data")
    func test_crisisResourcesShown() {
        let resources = CrisisResourceInfo(
            emergencyNumber: "911",
            crisisLineName: "988 Suicide & Crisis Lifeline",
            crisisLineNumber: "988"
        )
        let view = SafetyCardView(
            message: "We noticed something important.",
            crisisResources: resources,
            dismiss: {}
        )
        #expect(view.message == "We noticed something important.")
        #expect(view.crisisResources?.emergencyNumber == "911")
        #expect(view.crisisResources?.crisisLineName == "988 Suicide & Crisis Lifeline")
        #expect(view.crisisResources?.crisisLineNumber == "988")
    }

    @Test("SafetyCardView dismiss closure is stored correctly")
    func test_dismissClosure() {
        var dismissed = false
        let view = SafetyCardView(
            message: "Test",
            crisisResources: nil,
            dismiss: { dismissed = true }
        )
        view.dismiss()
        #expect(dismissed == true)
    }
}
