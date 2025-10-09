import XCTest
import CoreData
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
    
    func testSafetyAgentFlagsCrisis() async {
        let safety = SafetyAgent()
        let decision = await safety.evaluate(text: "I might hurt myself tonight")
        switch decision.classification {
        case .crisis:
            XCTAssertFalse(decision.allowCloud)
        default:
            XCTFail("Expected crisis classification")
        }
    }

    func testAgentOrchestrationFlow() async throws {
#if !os(iOS)
        throw XCTSkip("HealthKit orchestration only available on iOS")
#else
        let orchestrator = try AgentOrchestrator()
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
        let container = makeInMemoryContainer()
        let agent = SentimentAgent(container: container)
        let result = try await agent.importTranscript("Contact me at sample@example.com about the plan.")
        XCTAssertFalse(result.transcript.contains("example.com"))
        XCTAssertTrue(result.transcript.contains("[redacted]"))
#endif
    }

    private func makeInMemoryContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "Pulsum")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error { fatalError("In-memory store error: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }
}








