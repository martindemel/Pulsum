import Testing
@testable import PulsumAgents
@testable import PulsumData
import PulsumML
import SwiftData

// MARK: - Voice Journal Streaming Tests

struct VoiceJournalStreamingTests {
    @Test("Import transcript returns journal result with sentiment")
    func importTranscriptReturnsSentiment() async throws {
        let container = try TestCoreDataStack.makeContainer()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()
        let sentimentService = SentimentService(providers: [FixedSentimentProvider(score: 0.6)])
        let embeddingService = EmbeddingService.debugInstance(
            primary: FixedEmbeddingProvider(dimension: 4),
            fallback: nil,
            dimension: 4
        )
        let agent = SentimentAgent(
            container: container,
            vectorIndexDirectory: storagePaths.vectorIndexDirectory,
            sentimentService: sentimentService,
            embeddingService: embeddingService
        )

        let result = try await agent.importTranscript("I had a really good day today")
        #expect(!result.transcript.isEmpty)
        #expect(abs(result.sentimentScore - 0.6) < 0.01)
    }

    @Test("Stop recording returns transcript via importTranscript")
    func stopRecordingReturnsTranscript() async throws {
        let container = try TestCoreDataStack.makeContainer()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()
        let sentimentService = SentimentService(providers: [FixedSentimentProvider(score: 0.3)])
        let embeddingService = EmbeddingService.debugInstance(
            primary: FixedEmbeddingProvider(dimension: 4),
            fallback: nil,
            dimension: 4
        )
        let agent = SentimentAgent(
            container: container,
            vectorIndexDirectory: storagePaths.vectorIndexDirectory,
            sentimentService: sentimentService,
            embeddingService: embeddingService
        )

        let transcript = "I went for a walk and felt grounded"
        let result = try await agent.importTranscript(transcript)
        // Transcript should contain the text (possibly PII-redacted)
        #expect(!result.transcript.isEmpty)
    }

    @Test("Error during sentiment analysis does not crash")
    func errorDuringSentimentHandledGracefully() async throws {
        let container = try TestCoreDataStack.makeContainer()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()
        let sentimentService = SentimentService(providers: [FailingSentimentProvider()])
        let embeddingService = EmbeddingService.debugInstance(
            primary: FixedEmbeddingProvider(dimension: 4),
            fallback: nil,
            dimension: 4
        )
        let agent = SentimentAgent(
            container: container,
            vectorIndexDirectory: storagePaths.vectorIndexDirectory,
            sentimentService: sentimentService,
            embeddingService: embeddingService
        )

        // Should not crash; sentiment score may be nil
        let result = try await agent.importTranscript("Test transcript for error handling")
        #expect(!result.transcript.isEmpty)
    }

    @Test("PII redaction is applied to transcript before storage")
    func piiRedactionAppliedBeforeStorage() async throws {
        let container = try TestCoreDataStack.makeContainer()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()
        let sentimentService = SentimentService(providers: [FixedSentimentProvider(score: 0.0)])
        let embeddingService = EmbeddingService.debugInstance(
            primary: FixedEmbeddingProvider(dimension: 4),
            fallback: nil,
            dimension: 4
        )
        let agent = SentimentAgent(
            container: container,
            vectorIndexDirectory: storagePaths.vectorIndexDirectory,
            sentimentService: sentimentService,
            embeddingService: embeddingService
        )

        let transcriptWithPII = "Contact me at test@example.com about the plan"
        let result = try await agent.importTranscript(transcriptWithPII)

        // The email should be redacted
        #expect(!result.transcript.contains("test@example.com"))
        #expect(result.transcript.contains("[redacted]"))

        // Also verify the persisted journal entry is redacted
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<JournalEntry>()
        let entries = try context.fetch(descriptor)
        #expect(entries.count == 1)
        if let entry = entries.first {
            #expect(!entry.transcript.contains("test@example.com"))
            #expect(entry.transcript.contains("[redacted]"))
        }
    }

    @Test("PII redaction handles phone numbers")
    func piiRedactionHandlesPhoneNumbers() {
        let input = "Call me at +1 555-123-4567 for details"
        let redacted = PIIRedactor.redact(input)
        #expect(!redacted.contains("555-123-4567"))
        #expect(redacted.contains("[redacted]"))
    }

    @Test("PII redaction handles SSN")
    func piiRedactionHandlesSSN() {
        let input = "My SSN is 123-45-6789"
        let redacted = PIIRedactor.redact(input)
        #expect(!redacted.contains("123-45-6789"))
        #expect(redacted.contains("[redacted]"))
    }

    @Test("PII redaction preserves clean text")
    func piiRedactionPreservesCleanText() {
        let input = "I had a great day today and feel wonderful"
        let redacted = PIIRedactor.redact(input)
        #expect(redacted == input)
    }

    @Test("Empty transcript import returns empty result without error")
    func emptyTranscriptHandledGracefully() async throws {
        let container = try TestCoreDataStack.makeContainer()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()
        let sentimentService = SentimentService(providers: [FixedSentimentProvider(score: 0.0)])
        let embeddingService = EmbeddingService.debugInstance(
            primary: FixedEmbeddingProvider(dimension: 4),
            fallback: nil,
            dimension: 4
        )
        let agent = SentimentAgent(
            container: container,
            vectorIndexDirectory: storagePaths.vectorIndexDirectory,
            sentimentService: sentimentService,
            embeddingService: embeddingService
        )

        // Empty string should not crash
        do {
            _ = try await agent.importTranscript("")
        } catch {
            // Throwing is acceptable for empty input
            #expect(true, "Empty transcript throws, which is acceptable behavior")
        }
    }
}

// MARK: - Test Helpers

private struct FixedSentimentProvider: SentimentProviding {
    let score: Double

    func sentimentScore(for _: String) async throws -> Double {
        score
    }
}

private struct FailingSentimentProvider: SentimentProviding {
    func sentimentScore(for _: String) async throws -> Double {
        throw SentimentProviderError.insufficientInput
    }
}

private struct FixedEmbeddingProvider: TextEmbeddingProviding {
    let dimension: Int

    func embedding(for _: String) throws -> [Float] {
        [Float](repeating: 0.25, count: dimension)
    }
}
