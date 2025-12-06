import XCTest
@testable import PulsumML

private struct MockEmbeddingProvider: TextEmbeddingProviding {
    enum Mode {
        case succeeds([Float])
        case fails(Error)
    }

    let mode: Mode

    func embedding(for text: String) throws -> [Float] {
        switch mode {
        case let .succeeds(vector):
            return vector
        case let .fails(error):
            throw error
        }
    }
}

private struct MockError: Error {}

final class Gate0_EmbeddingServiceFallbackTests: XCTestCase {
    func testFallsBackWhenPrimaryUnavailable() throws {
        let fallbackVector: [Float] = [1, 2, 3, 4]
        let service = EmbeddingService.debugInstance(
            primary: MockEmbeddingProvider(mode: .fails(MockError())),
            fallback: MockEmbeddingProvider(mode: .succeeds(fallbackVector)),
            dimension: 4
        )

        let result = try service.embedding(for: "test")
        XCTAssertEqual(result, fallbackVector)
    }

    func testAvailabilityProbeUsesFallback() throws {
        let fallbackVector: [Float] = [0.1, 0.2, 0.3, 0.4]
        let service = EmbeddingService.debugInstance(
            primary: MockEmbeddingProvider(mode: .fails(MockError())),
            fallback: MockEmbeddingProvider(mode: .succeeds(fallbackVector)),
            dimension: 4
        )

        XCTAssertTrue(service.isAvailable())
    }
}
