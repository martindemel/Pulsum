import XCTest
@testable import PulsumML

final class EmbeddingServiceFallbackTests: XCTestCase {
    func testFallsBackWhenPrimaryUnavailable() {
        let fallback = MockEmbeddingProvider(vector: Array(repeating: Float(0.25), count: 4))
        let service = EmbeddingService.debugInstance(primary: FailingEmbeddingProvider(),
                                                     fallback: fallback,
                                                     dimension: 4)
        let vector = service.embedding(for: "pulsum")
        XCTAssertEqual(vector, fallback.vector)
    }
}

private struct FailingEmbeddingProvider: TextEmbeddingProviding {
    func embedding(for text: String) throws -> [Float] {
        throw EmbeddingError.generatorUnavailable
    }
}

private struct MockEmbeddingProvider: TextEmbeddingProviding {
    let vector: [Float]

    func embedding(for text: String) throws -> [Float] {
        vector
    }
}
