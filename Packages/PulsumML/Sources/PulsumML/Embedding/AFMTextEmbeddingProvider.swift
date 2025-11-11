import Foundation
import NaturalLanguage
#if canImport(ObjectiveC)
import ObjectiveC.runtime
#endif
#if canImport(FoundationModels) && os(iOS)
import FoundationModels
#endif

#if canImport(FoundationModels) && os(iOS)
/// Uses Apple contextual embeddings with mean pooling, falling back to legacy word embeddings.
@available(iOS 17.0, macOS 13.0, *)
final class AFMTextEmbeddingProvider: TextEmbeddingProviding {
    private let contextualEmbedding: NLContextualEmbedding?
    private let wordEmbedding: NLEmbedding?
    private let targetDimension = 384

    init() {
        if AFMTextEmbeddingProvider.shouldUseContextualEmbedding,
           #available(iOS 17.0, macOS 14.0, *) {
            self.contextualEmbedding = NLContextualEmbedding(language: .english)
        } else {
            self.contextualEmbedding = nil
        }
        self.wordEmbedding = NLEmbedding.wordEmbedding(for: .english)
    }

    func embedding(for text: String) throws -> [Float] {
        // Temporarily disabled contextual embedding due to unsafe runtime code
        // TODO: Re-enable when safe API is available
        // if let contextualEmbedding,
        //    #available(iOS 17.0, macOS 14.0, *) {
        //     if let vector = Self.sentenceEmbeddingVector(embedding: contextualEmbedding, text: text) {
        //         let floats = vector.map { Float(truncating: $0) }
        //         guard floats.contains(where: { $0 != 0 }) else {
        //             throw EmbeddingError.emptyResult
        //         }
        //         return adjustDimension(floats)
        //     }
        // }

        guard let wordEmbedding else {
            throw EmbeddingError.generatorUnavailable
        }

        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text.lowercased()
        var totals = [Double](repeating: 0, count: wordEmbedding.dimension)
        var tokenCount = 0

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let token = String(text[range]).trimmingCharacters(in: .punctuationCharacters)
            guard let vector = wordEmbedding.vector(for: token) else { return true }
            for index in 0..<vector.count {
                totals[index] += vector[index]
            }
            tokenCount += 1
            return true
        }

        guard tokenCount > 0 else {
            throw EmbeddingError.emptyResult
        }

        let averaged = totals.map { Float($0 / Double(tokenCount)) }
        return adjustDimension(averaged)
    }

    private static var shouldUseContextualEmbedding: Bool {
        #if canImport(FoundationModels) && os(iOS)
        if #available(iOS 26.0, *) {
            return FoundationModelsAvailability.checkAvailability() == .ready
        }
        return false
        #else
        return false
        #endif
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

    @available(iOS 17.0, macOS 14.0, *)
    private static func sentenceEmbeddingVector(embedding: NLContextualEmbedding, text: String) -> [NSNumber]? {
        let selector = NSSelectorFromString("sentenceEmbeddingVectorForString:language:error:")
        guard embedding.responds(to: selector) else { return nil }
        typealias Function = @convention(c) (AnyObject, Selector, NSString, NSString, UnsafeMutablePointer<NSError?>?) -> Unmanaged<NSArray>?
        #if canImport(ObjectiveC)
        let methodIMP = embedding.method(for: selector)
        let function = unsafeBitCast(methodIMP, to: Function.self)
        var error: NSError?
        let languageIdentifier = embedding.languages.first?.rawValue ?? "en"
        
        // Use Unmanaged to properly handle memory management
        guard let unmanagedResult = function(embedding, selector, text as NSString, languageIdentifier as NSString, &error) else {
            return nil
        }
        
        // Take unretained value (method doesn't transfer ownership)
        let array = unmanagedResult.takeUnretainedValue()
        return array as? [NSNumber]
        #else
        return nil
        #endif
    }
}
#else
@available(iOS 17.0, macOS 13.0, *)
final class AFMTextEmbeddingProvider: TextEmbeddingProviding {
    private let fallback = CoreMLEmbeddingFallbackProvider()

    init() {}

    func embedding(for text: String) throws -> [Float] {
        try fallback.embedding(for: text)
    }
}
#endif
