import XCTest
@testable import PulsumML

final class Gate6_EmbeddingProviderContextualTests: XCTestCase {
    func testEmbeddingServiceRejectsZeroVector() {
        let service = EmbeddingService.debugInstance(
            primary: ZeroEmbeddingProvider(),
            fallback: ThrowingEmbeddingProvider(),
            dimension: 4
        )

        XCTAssertThrowsError(try service.embedding(for: "fail")) { error in
            XCTAssertTrue(error is EmbeddingError)
        }
    }

    func testEmbeddingServiceThrowsWhenAllProvidersFail() {
        let service = EmbeddingService.debugInstance(
            primary: ThrowingEmbeddingProvider(),
            fallback: ThrowingEmbeddingProvider(),
            dimension: 3
        )
        XCTAssertThrowsError(try service.embedding(for: "unavailable"))
    }

    func testEmbeddingServiceAveragesSegments() throws {
        let provider = ConstantEmbeddingProvider(vector: [1, 1, 1, 1])
        let service = EmbeddingService.debugInstance(primary: provider, fallback: nil, dimension: 4)
        let vector = try service.embedding(forSegments: ["a", "b"])
        XCTAssertEqual(vector.count, 4)
        XCTAssertTrue(vector.allSatisfy { $0 == 1 })
    }

    func testContextualProviderProducesNonZeroVectorIfAvailable() throws {
#if canImport(FoundationModels)
        if #available(iOS 17.0, macOS 14.0, *) {
            let provider = AFMTextEmbeddingProvider()
            guard let vector = try? provider.embedding(for: "contextual embedding check") else {
                throw XCTSkip("Contextual embeddings unavailable in this environment")
            }
            XCTAssertEqual(vector.count, 384)
            XCTAssertFalse(vector.allSatisfy { $0 == 0 })
        } else {
            throw XCTSkip("Contextual embeddings unavailable on this platform")
        }
#else
        throw XCTSkip("FoundationModels not available on this platform")
#endif
    }
}

private struct ZeroEmbeddingProvider: TextEmbeddingProviding {
    func embedding(for text: String) throws -> [Float] {
        Array(repeating: 0, count: 4)
    }
}

private struct ThrowingEmbeddingProvider: TextEmbeddingProviding {
    func embedding(for text: String) throws -> [Float] {
        throw EmbeddingError.generatorUnavailable
    }
}

private struct ConstantEmbeddingProvider: TextEmbeddingProviding {
    let vector: [Float]

    func embedding(for text: String) throws -> [Float] {
        vector
    }
}
