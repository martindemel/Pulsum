import Foundation
import CoreML
import NaturalLanguage

/// Fallback embedding provider backed by a bundled Core ML word embedding model.
@available(iOS 17.0, macOS 13.0, *)
final class CoreMLEmbeddingFallbackProvider: TextEmbeddingProviding {
    private let embedding: NLEmbedding?
    private let targetDimension = 384

    init() {
        let bundle = Bundle.forPulsumML()

        if let compiledURL = bundle.url(forResource: "PulsumFallbackEmbedding", withExtension: "mlmodelc"),
           let loaded = try? NLEmbedding(contentsOf: compiledURL) {
            embedding = loaded
        } else if let modelURL = bundle.url(forResource: "PulsumFallbackEmbedding", withExtension: "mlmodel"),
                  let compiled = try? MLModel.compileModel(at: modelURL),
                  let loaded = try? NLEmbedding(contentsOf: compiled) {
            embedding = loaded
        } else {
            embedding = nil
        }
    }

    func embedding(for text: String) throws -> [Float] {
        guard let embedding,
              let vector = embedding.vector(for: text) else {
            throw EmbeddingError.generatorUnavailable
        }
        return adjustDimension(vector.map { Float($0) })
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

@available(iOS 17.0, macOS 13.0, *)
final class PulsumMLBundleLocator {}

@available(iOS 17.0, macOS 13.0, *)
extension Bundle {
    static func forPulsumML() -> Bundle {
#if SWIFT_PACKAGE
        return .module
#else
        let bundleName = "PulsumML_PulsumML"
        let candidates: [URL?] = [
            Bundle.main.resourceURL,
            Bundle.main.bundleURL,
            Bundle(for: PulsumMLBundleLocator.self).resourceURL,
            Bundle(for: PulsumMLBundleLocator.self).bundleURL
        ]

        for candidate in candidates {
            guard let candidate else { continue }
            let bundleURL = candidate.appendingPathComponent(bundleName + ".bundle")
            if let bundle = Bundle(url: bundleURL) {
                return bundle
            }
        }

        return Bundle(for: PulsumMLBundleLocator.self)
#endif
    }
}
