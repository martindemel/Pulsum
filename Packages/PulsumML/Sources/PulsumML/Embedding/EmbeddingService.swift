import Foundation
import os

/// Central access point for on-device embeddings with AFM primary and hash fallback.
public final class EmbeddingService {
    public static let shared = EmbeddingService()

    public enum AvailabilityMode {
        case available
        case unavailable
    }

    private let primaryProvider: TextEmbeddingProviding?
    private let fallbackProvider: TextEmbeddingProviding?
    private let dimension: Int
    private let availabilityQueue = DispatchQueue(label: "ai.pulsum.embedding.availability", qos: .utility)
    private enum AvailabilityState {
        case unknown
        case available
        case unavailable(lastChecked: Date)
        case probing(previous: Bool?)
    }

    private var availabilityState: AvailabilityState = .unknown
    private let availabilityProbeText = "pulsum-availability-check"
    private let reprobeInterval: TimeInterval
    private let dateProvider: () -> Date
    private let logger = Logger(subsystem: "com.pulsum", category: "EmbeddingService")

    private init(primary: TextEmbeddingProviding? = nil,
                 fallback: TextEmbeddingProviding? = nil,
                 dimension: Int = 384,
                 reprobeInterval: TimeInterval = 3600,
                 dateProvider: @escaping () -> Date = Date.init) {
        self.dimension = dimension
        self.reprobeInterval = reprobeInterval
        self.dateProvider = dateProvider
        if let primary {
            self.primaryProvider = primary
        } else if #available(iOS 17.0, macOS 13.0, *) {
            self.primaryProvider = AFMTextEmbeddingProvider()
        } else {
            self.primaryProvider = nil
        }

        if let fallback {
            self.fallbackProvider = fallback
        } else if #available(iOS 17.0, macOS 13.0, *) {
            self.fallbackProvider = CoreMLEmbeddingFallbackProvider()
        } else {
            self.fallbackProvider = nil
        }
    }

    /// Availability probe with self-healing. Re-probes after a cooldown or once Apple Intelligence reports ready.
    public func isAvailable() -> Bool {
        let now = dateProvider()
        var shouldProbe = true
        var cachedResult: Bool?

        availabilityQueue.sync {
            switch availabilityState {
            case .available:
                shouldProbe = false
                cachedResult = true
            case .unavailable(let lastChecked):
                let fmReady = FoundationModelsAvailability.checkAvailability() == .ready
                if fmReady || now.timeIntervalSince(lastChecked) >= reprobeInterval {
                    availabilityState = .probing(previous: false)
                    shouldProbe = true
                    cachedResult = false
                } else {
                    shouldProbe = false
                    cachedResult = false
                }
            case .probing(let previous):
                shouldProbe = false
                cachedResult = previous
            case .unknown:
                availabilityState = .probing(previous: nil)
                shouldProbe = true
                cachedResult = nil
            }
        }

        if !shouldProbe {
            return cachedResult ?? false
        }

        let result = probeAvailability()

        availabilityQueue.sync {
            availabilityState = result ? .available : .unavailable(lastChecked: now)
        }
        return result
    }

    /// Lightweight availability probe without invoking caller text; callers can branch without throwing.
    public func availabilityMode() -> AvailabilityMode {
        isAvailable() ? .available : .unavailable
    }

    /// Generates an embedding for the supplied text, padding or truncating to 384 dimensions.
    public func embedding(for text: String) throws -> [Float] {
        var lastError: Error?

        if let primaryProvider {
            do {
                let vector = try primaryProvider.embedding(for: text)
                return try validated(vector)
            } catch {
                lastError = error
            }
        }

        if let fallbackProvider {
            do {
                let vector = try fallbackProvider.embedding(for: text)
                return try validated(vector)
            } catch {
                lastError = error
            }
        }

        throw lastError ?? EmbeddingError.generatorUnavailable
    }

    /// Generates a combined embedding for multiple text segments (averaged element-wise).
    public func embedding(forSegments segments: [String]) throws -> [Float] {
        guard !segments.isEmpty else { throw EmbeddingError.emptyResult }
        var accumulator = [Float](repeating: 0, count: dimension)
        var count: Float = 0
        for segment in segments where !segment.isEmpty {
            do {
                let vector = try embedding(for: segment)
                for index in 0..<dimension {
                    accumulator[index] += vector[index]
                }
                count += 1
            } catch {
                continue
            }
        }
        guard count > 0 else { throw EmbeddingError.generatorUnavailable }
        for index in 0..<dimension {
            accumulator[index] /= count
        }
        guard accumulator.contains(where: { $0 != 0 }) else {
            throw EmbeddingError.emptyResult
        }
        return accumulator
    }

    private func validated(_ vector: [Float]) throws -> [Float] {
        guard !vector.isEmpty else { throw EmbeddingError.emptyResult }
        if vector.count == dimension {
            guard vector.contains(where: { $0 != 0 }) else { throw EmbeddingError.emptyResult }
            return vector
        }
        let adjusted: [Float]
        if vector.count > dimension {
            adjusted = Array(vector.prefix(dimension))
        } else {
            var padded = vector
            padded.reserveCapacity(dimension)
            while padded.count < dimension {
                padded.append(0)
            }
            adjusted = padded
        }
        guard adjusted.contains(where: { $0 != 0 }) else { throw EmbeddingError.emptyResult }
        return adjusted
    }

    private func probeAvailability() -> Bool {
        if let vector = try? embedding(for: availabilityProbeText),
           vector.count == dimension,
           vector.contains(where: { $0 != 0 }) {
            return true
        }
        logger.error("Embedding availability probe failed; providers unavailable or returned zero-vector.")
        return false
    }
}

#if DEBUG
extension EmbeddingService {
    public static func debugInstance(primary: TextEmbeddingProviding? = nil,
                                     fallback: TextEmbeddingProviding? = nil,
                                     dimension: Int = 384,
                                     reprobeInterval: TimeInterval = 3600,
                                     dateProvider: @escaping () -> Date = Date.init) -> EmbeddingService {
        EmbeddingService(primary: primary,
                         fallback: fallback,
                         dimension: dimension,
                         reprobeInterval: reprobeInterval,
                         dateProvider: dateProvider)
    }
}
#endif

extension EmbeddingService: @unchecked Sendable {}
