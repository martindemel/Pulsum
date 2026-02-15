@testable import PulsumAgents
@testable import PulsumData
import PulsumML
import SwiftData
import XCTest

@MainActor
// swiftlint:disable:next type_name
final class Gate6_SentimentJournalingFallbackTests: XCTestCase {
    func testJournalPersistsWhenEmbeddingUnavailable() async throws {
        let container = try TestCoreDataStack.makeContainer()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()
        let embeddingService = EmbeddingService.debugInstance(primary: AlwaysFailEmbeddingProvider())
        let sentimentService = SentimentService(providers: [StubSentimentProvider(score: 0.35)])
        let agent = SentimentAgent(container: container,
                                   vectorIndexDirectory: storagePaths.vectorIndexDirectory,
                                   sentimentService: sentimentService,
                                   embeddingService: embeddingService)

        let result = try await agent.importTranscript("Testing journal text")

        XCTAssertTrue(result.embeddingPending)
        XCTAssertNil(result.vectorURL)

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<JournalEntry>()
        let entries = try context.fetch(descriptor)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.transcript, PIIRedactor.redact("Testing journal text"))
        XCTAssertNil(entries.first?.embeddedVectorURL)
    }

    func testPendingEmbeddingsReprocessedAfterRecovery() async throws {
        let container = try TestCoreDataStack.makeContainer()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()
        let provider = FailOnceEmbeddingProvider(vector: [Float](repeating: 0.25, count: 4))
        let embeddingService = EmbeddingService.debugInstance(primary: provider, fallback: nil, dimension: 4)
        let sentimentService = SentimentService(providers: [StubSentimentProvider(score: 0.1)])
        let agent = SentimentAgent(container: container,
                                   vectorIndexDirectory: storagePaths.vectorIndexDirectory,
                                   sentimentService: sentimentService,
                                   embeddingService: embeddingService)

        let result = try await agent.importTranscript("Pending embedding recovery test")
        XCTAssertTrue(result.embeddingPending)

        await agent.reprocessPendingJournals()

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<JournalEntry>()
        let entries = try context.fetch(descriptor)
        XCTAssertEqual(entries.count, 1)
        let entry = entries.first
        XCTAssertNotNil(entry?.embeddedVectorURL)
        let pendingCount = await agent.pendingEmbeddingCount()
        XCTAssertEqual(pendingCount, 0)
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

private final class FailOnceEmbeddingProvider: TextEmbeddingProviding {
    private let vector: [Float]
    private var didFail = false
    private let lock = NSLock()

    init(vector: [Float]) {
        self.vector = vector
    }

    func embedding(for text: String) throws -> [Float] {
        lock.lock()
        defer { lock.unlock() }
        if !didFail {
            didFail = true
            throw EmbeddingError.generatorUnavailable
        }
        return vector
    }
}
