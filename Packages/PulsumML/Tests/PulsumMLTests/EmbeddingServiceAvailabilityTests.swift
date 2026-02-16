import XCTest
@testable import PulsumML

final class EmbeddingServiceAvailabilityTests: XCTestCase {
    func testReprobesAfterCooldown() async {
        let provider = MutableEmbeddingProvider(response: .failure(EmbeddingError.generatorUnavailable))
        let clock = StubClock()
        let service = EmbeddingService.debugInstance(primary: provider,
                                                     fallback: nil,
                                                     dimension: 4,
                                                     reprobeInterval: 10,
                                                     dateProvider: { clock.now })

        let first = await service.isAvailable()
        XCTAssertFalse(first)
        XCTAssertEqual(provider.callCount, 1)

        provider.response = .success([Float](repeating: 0.5, count: 4))

        // Within cooldown, should not probe again even though provider is now healthy.
        let second = await service.isAvailable()
        XCTAssertFalse(second)
        XCTAssertEqual(provider.callCount, 1)

        clock.advance(by: 11)
        let third = await service.isAvailable()
        XCTAssertTrue(third)
        XCTAssertEqual(provider.callCount, 2)
    }

    func testAvailabilityStaysTrueAfterSuccess() async {
        let provider = MutableEmbeddingProvider(response: .success([Float](repeating: 0.3, count: 4)))
        let clock = StubClock()
        let service = EmbeddingService.debugInstance(primary: provider,
                                                     fallback: nil,
                                                     dimension: 4,
                                                     reprobeInterval: 10,
                                                     dateProvider: { clock.now })

        let first = await service.isAvailable()
        XCTAssertTrue(first)

        provider.response = .failure(EmbeddingError.generatorUnavailable)

        // No reprobe needed while cached as available.
        let second = await service.isAvailable()
        XCTAssertTrue(second)
        XCTAssertEqual(provider.callCount, 1)
    }
}

// Test-only: mutable stub — serial test execution, no concurrent access.
private final class MutableEmbeddingProvider: TextEmbeddingProviding, @unchecked Sendable {
    var response: Result<[Float], Error>
    private(set) var callCount = 0

    init(response: Result<[Float], Error>) {
        self.response = response
    }

    func embedding(for text: String) throws -> [Float] {
        callCount += 1
        return try response.get()
    }
}

// Test-only: mutable stub — serial test execution, no concurrent access.
private final class StubClock: @unchecked Sendable {
    private var current: Date

    init(now: Date = Date()) {
        self.current = now
    }

    var now: Date { current }

    func advance(by seconds: TimeInterval) {
        current = current.addingTimeInterval(seconds)
    }
}
