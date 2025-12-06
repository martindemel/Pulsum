@testable import PulsumAgents
@testable import PulsumData
import PulsumML
import XCTest

@MainActor
final class Gate6_SentimentJournalingFallbackTests: XCTestCase {
    func testJournalPersistsWhenEmbeddingUnavailable() async throws {
        let container = TestCoreDataStack.makeContainer()
        let embeddingService = EmbeddingService.debugInstance(primary: AlwaysFailEmbeddingProvider())
        let sentimentService = SentimentService(providers: [StubSentimentProvider(score: 0.35)])
        let agent = SentimentAgent(container: container,
                                   sentimentService: sentimentService,
                                   embeddingService: embeddingService)

        let result = try await agent.importTranscript("Testing journal text")

        XCTAssertTrue(result.embeddingPending)
        XCTAssertNil(result.vectorURL)

        let entries = try container.viewContext.fetch(JournalEntry.fetchRequest())
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.transcript, PIIRedactor.redact("Testing journal text"))
        XCTAssertNil(entries.first?.embeddedVectorURL)
    }
}

private struct AlwaysFailEmbeddingProvider: TextEmbeddingProviding {
    func embedding(for text: String) throws -> [Float] {
        throw EmbeddingError.generatorUnavailable
    }
}

private struct StubSentimentProvider: SentimentProviding {
    let score: Double

    func sentimentScore(for text: String) async throws -> Double {
        score
    }
}
