import Foundation

public enum SafetyClassification: Equatable {
    case safe
    case caution(reason: String)
    case crisis(reason: String)
}

public struct SafetyLocalConfig {
    public let crisisKeywords: [String]
    public let cautionKeywords: [String]
    public let crisisSimilarityThreshold: Float
    public let cautionSimilarityThreshold: Float
    public let resolutionMargin: Float

    public init(
        crisisKeywords: [String] = ["suicide", "kill myself", "ending it", "overdose", "hurt myself"],
        cautionKeywords: [String] = ["depressed", "hopeless", "panic", "anxious", "self-harm"],
        crisisSimilarityThreshold: Float = 0.65,  // Raised from 0.48 - less aggressive for bench testing
        cautionSimilarityThreshold: Float = 0.35, // Raised from 0.22 - less aggressive for bench testing
        resolutionMargin: Float = 0.10            // Raised from 0.05 - require clearer signal
    ) {
        self.crisisKeywords = crisisKeywords
        self.cautionKeywords = cautionKeywords
        self.crisisSimilarityThreshold = crisisSimilarityThreshold
        self.cautionSimilarityThreshold = cautionSimilarityThreshold
        self.resolutionMargin = resolutionMargin
    }
}

public final class SafetyLocal {
    private enum Label: String { case safe, caution, crisis }

    private struct Prototype {
        let label: Label
        let text: String
        let embedding: [Float]
    }

    private let config: SafetyLocalConfig
    private let embeddingService = EmbeddingService.shared
    private let prototypes: [Prototype]

    public init(config: SafetyLocalConfig = SafetyLocalConfig()) {
        self.config = config
        self.prototypes = SafetyLocal.makePrototypes(using: embeddingService)
    }

    public func classify(text: String) -> SafetyClassification {
        let normalized = text.lowercased()
        
        #if DEBUG
        print("[SafetyLocal] Classifying: '\(text)'")
        #endif
        
        if containsKeyword(from: config.crisisKeywords, in: normalized) {
            #if DEBUG
            print("[SafetyLocal] Crisis keyword detected")
            #endif
            return .crisis(reason: "High-risk language detected")
        }

        guard
            let embedding = try? embeddingService.embedding(for: normalized),
            embedding.contains(where: { $0 != 0 }),
            !prototypes.isEmpty
        else {
            #if DEBUG
            print("[SafetyLocal] Embedding unavailable or prototypes missing, using fallback")
            #endif
            return fallbackClassification(for: normalized)
        }
        
        #if DEBUG
        let hasNonZero = embedding.contains(where: { $0 != 0 })
        print("[SafetyLocal] Embedding has non-zero values: \(hasNonZero)")
        #endif
        
        var scores: [Label: (similarity: Float, prototype: Prototype)] = [:]
        for prototype in prototypes {
            let similarity = cosineSimilarity(embedding, prototype.embedding)
            if let current = scores[prototype.label], current.similarity >= similarity { continue }
            scores[prototype.label] = (similarity, prototype)
        }

        let safeSimilarity = scores[.safe]?.similarity ?? 0
        
        #if DEBUG
        print("[SafetyLocal] Similarities - safe: \(safeSimilarity), crisis: \(scores[.crisis]?.similarity ?? 0), caution: \(scores[.caution]?.similarity ?? 0)")
        #endif

        if let crisis = scores[.crisis],
           crisis.similarity >= config.crisisSimilarityThreshold,
           crisis.similarity - safeSimilarity >= config.resolutionMargin {
            if containsKeyword(from: config.crisisKeywords, in: normalized) {
                #if DEBUG
                print("[SafetyLocal] → CRISIS (keyword + similarity)")
                #endif
                return .crisis(reason: crisis.prototype.text)
            }
            #if DEBUG
            print("[SafetyLocal] → CAUTION (similarity only, no keyword)")
            #endif
            return .caution(reason: crisis.prototype.text)
        }
        if let caution = scores[.caution],
           caution.similarity >= config.cautionSimilarityThreshold,
           caution.similarity - safeSimilarity >= config.resolutionMargin / 2 {
            #if DEBUG
            print("[SafetyLocal] → CAUTION")
            #endif
            return .caution(reason: caution.prototype.text)
        }
        
        #if DEBUG
        print("[SafetyLocal] → SAFE")
        #endif
        return .safe
    }

    // MARK: - Prototype Setup

    private static func makePrototypes(using service: EmbeddingService) -> [Prototype] {
        let dataset: [(Label, String)] = [
            (.crisis, "I want to hurt myself"),
            (.crisis, "Thinking about ending my life"),
            (.crisis, "I can't stay safe tonight"),
            (.crisis, "I overdosed and don't want to wake up"),
            (.caution, "Feeling really hopeless today"),
            (.caution, "My anxiety is spiking"),
            (.caution, "I'm panicking and can't calm down"),
            (.caution, "Everything feels overwhelming"),
            (.safe, "I could use a gentle nudge"),
            (.safe, "Looking for a quick habit to stay on track"),
            (.safe, "Just want a supportive reminder"),
            (.safe, "I finished a light workout and feel grounded")
        ]

        return dataset.compactMap { label, text in
            guard let embedding = try? service.embedding(for: text) else { return nil }
            return Prototype(label: label, text: text, embedding: embedding)
        }
    }

    // MARK: - Helpers

    private func containsKeyword(from keywords: [String], in text: String) -> Bool {
        for keyword in keywords where !keyword.isEmpty {
            if text.contains(keyword) { return true }
        }
        return false
    }

    private func fallbackClassification(for text: String) -> SafetyClassification {
        if containsKeyword(from: config.cautionKeywords, in: text) {
            return .caution(reason: "Sensitive language detected")
        }
        return .safe
    }

    private func cosineSimilarity(_ lhs: [Float], _ rhs: [Float]) -> Float {
        guard lhs.count == rhs.count else { return 0 }
        var dot: Float = 0
        var lhsNorm: Float = 0
        var rhsNorm: Float = 0
        for index in 0..<lhs.count {
            dot += lhs[index] * rhs[index]
            lhsNorm += lhs[index] * lhs[index]
            rhsNorm += rhs[index] * rhs[index]
        }
        let denominator = sqrt(lhsNorm) * sqrt(rhsNorm)
        guard denominator > 0 else { return 0 }
        return dot / denominator
    }
}
