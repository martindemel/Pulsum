import XCTest
import SwiftData
@testable import PulsumAgents
@testable import PulsumData
@testable import PulsumServices
@testable import PulsumML
@preconcurrency import HealthKit

@MainActor
final class AgentSystemTests: XCTestCase {

    func testFoundationModelsAvailability() async throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("Foundation Models require iOS 26")
        }
        let status = FoundationModelsAvailability.checkAvailability()
        let message = FoundationModelsAvailability.availabilityMessage(for: status)
        XCTAssertFalse(message.isEmpty)
    }

    func testSafetyAgentFlagsCrisis() async throws {
#if !os(iOS)
        throw XCTSkip("Safety agent FM classification validated on iOS 26+ only")
#else
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("Safety agent FM classification validated on iOS 26+ only")
        }
        let safety = SafetyAgent()
        let decision = await safety.evaluate(text: "I might hurt myself tonight")
        switch decision.classification {
        case .crisis:
            XCTAssertFalse(decision.allowCloud)
        default:
            XCTFail("Expected crisis classification")
        }
#endif
    }

    func testAgentOrchestrationFlow() async throws {
#if !os(iOS)
        throw XCTSkip("HealthKit orchestration only available on iOS")
#else
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()
        let container = try TestCoreDataStack.makeContainer()
        let orchestrator = try AgentOrchestrator(container: container, storagePaths: storagePaths)
        try await orchestrator.start()

        // Test that orchestrator initializes without throwing
        XCTAssertNotNil(orchestrator)

        // Test Foundation Models status reporting
        let status = orchestrator.foundationModelsStatus
        XCTAssertFalse(status.isEmpty)
#endif
    }

    func testPIIRedactionInSentimentPipeline() async throws {
#if !os(iOS)
        throw XCTSkip("Sentiment journal pipeline only validated on iOS")
#else
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()
        let container = try TestCoreDataStack.makeContainer()
        let agent = SentimentAgent(container: container,
                                   vectorIndexDirectory: storagePaths.vectorIndexDirectory)
        let result = try await agent.importTranscript("Contact me at sample@example.com about the plan.")
        XCTAssertFalse(result.transcript.contains("example.com"))
        XCTAssertTrue(result.transcript.contains("[redacted]"))
#endif
    }
}
