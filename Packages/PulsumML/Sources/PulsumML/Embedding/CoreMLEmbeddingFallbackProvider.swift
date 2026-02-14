import Foundation
import CoreML
import NaturalLanguage
import os.log

/// Reliable on-device fallback embedding provider backed by the bundled Core ML model.
@available(iOS 17.0, macOS 13.0, *)
final class CoreMLEmbeddingFallbackProvider: TextEmbeddingProviding {
    private let embedding: NLEmbedding?
    private let targetDimension = 384
    private let logger = Logger(subsystem: "com.pulsum", category: "EmbeddingService")

    init() {
        let bundle = Bundle.pulsumMLResources

        if let compiledURL = bundle.url(forResource: "PulsumFallbackEmbedding", withExtension: "mlmodelc"),
           let loaded = try? NLEmbedding(contentsOf: compiledURL) {
            embedding = loaded
        } else if let modelURL = bundle.url(forResource: "PulsumFallbackEmbedding", withExtension: "mlmodel"),
                  let compiled = try? MLModel.compileModel(at: modelURL),
                  let loaded = try? NLEmbedding(contentsOf: compiled) {
            embedding = loaded
        } else {
            embedding = nil
            #if DEBUG
            assertionFailure("PulsumFallbackEmbedding.{mlmodel|mlmodelc} is missing from the PulsumML bundle.")
            logger.error("Failed to locate PulsumFallbackEmbedding in bundle \(bundle.bundleURL, privacy: .public)")
            #endif
        }
    }

    func embedding(for text: String) throws -> [Float] {
        guard let embedding,
              let vector = embedding.vector(for: text) else {
            #if DEBUG
            logger.error("PulsumFallbackEmbedding failed to load; throwing generatorUnavailable.")
            #endif
            throw EmbeddingError.generatorUnavailable
        }
        let adjusted = adjustDimension(vector.map { Float($0) })
        guard adjusted.contains(where: { $0 != 0 }) else {
            throw EmbeddingError.emptyResult
        }
        return adjusted
    }

    private func adjustDimension(_ vector: [Float]) -> [Float] {
        if vector.count == targetDimension { return vector }
        if vector.count > targetDimension { return Array(vector.prefix(targetDimension)) }
        var padded = vector
        padded.reserveCapacity(targetDimension)
        while padded.count < targetDimension {
            padded.append(0)
        }
        return padded
    }
}
