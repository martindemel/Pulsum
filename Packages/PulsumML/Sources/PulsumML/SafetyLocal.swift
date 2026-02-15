import Foundation
import os

public enum SafetyClassification: Equatable, Sendable {
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
        crisisKeywords: [String] = [
            "suicide", "kill myself", "ending it", "overdose", "hurt myself",
            "want to die", "self-harm", "cut myself", "cutting myself",
            "no reason to live", "jump off", "hang myself",
            "don't want to be here", "can't go on", "take all the pills",
            "ending my life", "not want to live"
        ],
        cautionKeywords: [String] = ["depressed", "hopeless", "panic", "anxious", "self-harm"],
        crisisSimilarityThreshold: Float = 0.65, // Raised from 0.48 - less aggressive for bench testing
        cautionSimilarityThreshold: Float = 0.35, // Raised from 0.22 - less aggressive for bench testing
        resolutionMargin: Float = 0.10 // Raised from 0.05 - require clearer signal
    ) {
        self.crisisKeywords = crisisKeywords
        self.cautionKeywords = cautionKeywords
        self.crisisSimilarityThreshold = crisisSimilarityThreshold
        self.cautionSimilarityThreshold = cautionSimilarityThreshold
        self.resolutionMargin = resolutionMargin
    }
}

// SAFETY: All mutable state is protected by `prototypeQueue` (serialized DispatchQueue).
// Immutable properties (`config`, `embeddingService`) are set once in init.
public final class SafetyLocal: @unchecked Sendable {
    private enum Label: String { case safe, caution, crisis }

    private struct Prototype {
        let label: Label
        let text: String
        let embedding: [Float]
    }

    private let config: SafetyLocalConfig
    private let embeddingService: EmbeddingService
    private let prototypeQueue = DispatchQueue(label: "ai.pulsum.safetyLocal.prototypes", qos: .userInitiated)
    private var prototypes: [Prototype]
    private var degraded: Bool
    private let logger = Logger(subsystem: "com.pulsum", category: "SafetyLocal")

    public init(config: SafetyLocalConfig = SafetyLocalConfig(),
                embeddingService: EmbeddingService = .shared) {
        self.config = config
        self.embeddingService = embeddingService
        let build = SafetyLocal.makePrototypes(using: embeddingService, logger: logger)
        self.prototypes = build.prototypes
        self.degraded = build.degraded
    }

    public var isDegraded: Bool {
        prototypeQueue.sync { degraded || prototypes.isEmpty }
    }

    public func classify(text: String) -> SafetyClassification {
        refreshPrototypesIfNeeded()
        let (localPrototypes, _) = prototypeQueue.sync { (prototypes, degraded) }
        let normalized = text.lowercased()
        #if DEBUG
        logger.debug("SafetyLocal classify lengthBucket=\(self.lengthBucket(for: normalized), privacy: .public)")
        #endif

        if containsKeyword(from: config.crisisKeywords, in: normalized) {
            #if DEBUG
            logger.debug("SafetyLocal keyword-based crisis trigger")
            #endif
            return .crisis(reason: "High-risk language detected")
        }

        guard !localPrototypes.isEmpty else {
            prototypeQueue.sync { degraded = true }
            logger.warning("SafetyLocal degraded: prototypes missing; using keyword-only fallback classification.")
            return fallbackClassification(for: normalized)
        }

        guard
            let embedding = try? embeddingService.embedding(for: normalized),
            embedding.contains(where: { $0 != 0 })
        else {
            #if DEBUG
            logger.debug("SafetyLocal embedding unavailable; using keyword-only fallback classification.")
            #endif
            return fallbackClassification(for: normalized)
        }

        var scores: [Label: (similarity: Float, prototype: Prototype)] = [:]
        for prototype in localPrototypes {
            let similarity = CosineSimilarity.compute(embedding, prototype.embedding)
            if similarity.isNaN {
                return .caution(reason: "Classification unavailable — embedding error")
            }
            if let current = scores[prototype.label], current.similarity >= similarity { continue }
            scores[prototype.label] = (similarity, prototype)
        }

        let safeSimilarity = scores[.safe]?.similarity ?? 0

        if let crisis = scores[.crisis],
           crisis.similarity >= config.crisisSimilarityThreshold,
           crisis.similarity - safeSimilarity >= config.resolutionMargin {
            // High-confidence embedding match alone is sufficient for crisis classification
            if crisis.similarity > 0.85 {
                #if DEBUG
                logger.debug("SafetyLocal → crisis (high-confidence embedding)")
                #endif
                return .crisis(reason: "High-confidence crisis embedding match")
            }
            if containsKeyword(from: config.crisisKeywords, in: normalized) {
                #if DEBUG
                logger.debug("SafetyLocal → crisis (keyword + embedding)")
                #endif
                return .crisis(reason: crisis.prototype.text)
            }
            #if DEBUG
            logger.debug("SafetyLocal → caution (embedding similarity only)")
            #endif
            return .caution(reason: crisis.prototype.text)
        }
        if let caution = scores[.caution],
           caution.similarity >= config.cautionSimilarityThreshold,
           caution.similarity - safeSimilarity >= config.resolutionMargin / 2 {
            #if DEBUG
            logger.debug("SafetyLocal → caution (similarity threshold)")
            #endif
            return .caution(reason: caution.prototype.text)
        }

        #if DEBUG
        logger.debug("SafetyLocal → safe")
        #endif
        return .safe
    }

    // MARK: - Prototype Setup

    private static func makePrototypes(using service: EmbeddingService, logger: Logger) -> (prototypes: [Prototype], degraded: Bool) {
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

        var built: [Prototype] = []
        var failures = 0

        for (index, item) in dataset.enumerated() {
            do {
                let embedding = try service.embedding(for: item.1)
                built.append(Prototype(label: item.0, text: item.1, embedding: embedding))
            } catch {
                failures += 1
                #if DEBUG
                logger.debug("Failed to embed safety prototype \(index, privacy: .public) label=\(item.0.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)")
                #endif
            }
        }

        let degraded = built.isEmpty

        if built.isEmpty {
            logger.warning("SafetyLocal prototypes empty; classifier will operate in degraded keyword-only mode.")
        } else if failures > 0 {
            #if DEBUG
            logger.debug("SafetyLocal built \(built.count, privacy: .public) prototypes with \(failures, privacy: .public) failures. Degraded=\(degraded, privacy: .public)")
            #endif
        }

        return (built, degraded)
    }

    // MARK: - Helpers

    private func refreshPrototypesIfNeeded() {
        let needsRefresh = prototypeQueue.sync { degraded || prototypes.isEmpty }
        guard needsRefresh else { return }
        let build = SafetyLocal.makePrototypes(using: embeddingService, logger: logger)
        prototypeQueue.sync {
            prototypes = build.prototypes
            degraded = build.degraded
        }
    }

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

    private func lengthBucket(for text: String) -> String {
        switch text.count {
        case 0 ... 20: return "0-20"
        case 21 ... 80: return "21-80"
        default: return "81+"
        }
    }
}
