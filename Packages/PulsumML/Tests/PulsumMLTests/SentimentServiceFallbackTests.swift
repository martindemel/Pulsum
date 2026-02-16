import Testing
@testable import PulsumML

// MARK: - Mock providers

private struct SucceedingProvider: SentimentProviding {
    let score: Double

    func sentimentScore(for _: String) async throws -> Double {
        score
    }
}

private struct FailingProvider: SentimentProviding {
    func sentimentScore(for _: String) async throws -> Double {
        throw SentimentProviderError.unavailable
    }
}

private struct InsufficientInputProvider: SentimentProviding {
    func sentimentScore(for _: String) async throws -> Double {
        throw SentimentProviderError.insufficientInput
    }
}

// MARK: - Tests

struct SentimentServiceFallbackTests {
    @Test("Primary succeeds, fallback is not called")
    func test_primarySucceeds_fallbackNotCalled() async {
        let service = SentimentService(providers: [
            SucceedingProvider(score: 0.75),
            SucceedingProvider(score: -0.5),
        ])
        let result = await service.sentiment(for: "I feel great today")
        #expect(result == 0.75)
    }

    @Test("Primary fails, fallback is used")
    func test_primaryFails_fallbackUsed() async {
        let service = SentimentService(providers: [
            FailingProvider(),
            SucceedingProvider(score: 0.42),
        ])
        let result = await service.sentiment(for: "I feel okay")
        #expect(result == 0.42)
    }

    @Test("All providers fail, returns nil")
    func test_allProvidersFail_returnsNil() async {
        let service = SentimentService(providers: [
            FailingProvider(),
            FailingProvider(),
        ])
        let result = await service.sentiment(for: "Some text")
        #expect(result == nil)
    }

    @Test("InsufficientInput skips to next provider")
    func test_insufficientInput_skipsToNext() async {
        let service = SentimentService(providers: [
            InsufficientInputProvider(),
            SucceedingProvider(score: -0.3),
        ])
        let result = await service.sentiment(for: "Hi")
        #expect(result == -0.3)
    }

    @Test("Score is clamped to [-1, 1]")
    func test_scoreClamped() async {
        let service = SentimentService(providers: [
            SucceedingProvider(score: 5.0),
        ])
        let result = await service.sentiment(for: "Extreme positivity")
        #expect(result == 1.0)
    }

    @Test("Empty input returns zero without calling providers")
    func test_emptyInput_returnsZero() async {
        let service = SentimentService(providers: [
            FailingProvider(),
        ])
        let result = await service.sentiment(for: "")
        #expect(result == 0)
    }
}
