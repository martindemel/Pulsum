import Foundation
import os
import PulsumTypes

/// Central access point for on-device embeddings with AFM primary and hash fallback.
/// Actor isolation protects mutable availability state; embedding methods are nonisolated
/// since they only access immutable (Sendable) provider references.
public actor EmbeddingService {
    public static let shared = EmbeddingService()

    public enum AvailabilityMode: Sendable {
        case available
        case unavailable
    }

    private let primaryProvider: (any TextEmbeddingProviding)?
    private let fallbackProvider: (any TextEmbeddingProviding)?
    private let dimension: Int
    private enum AvailabilityState {
        case unknown
        case available
        case unavailable(lastChecked: Date)
        case probing(previous: Bool?)
    }

    private var availabilityState: AvailabilityState = .unknown
    private var lastReportedAvailability: AvailabilityMode?
    private let availabilityProbeText = "pulsum-availability-check"
    private let reprobeInterval: TimeInterval
    private let dateProvider: @Sendable () -> Date
    private let logger = Logger(subsystem: "com.pulsum", category: "EmbeddingService")
    #if DEBUG
    private let debugAvailabilityOverride: Bool?
    #endif

    private init(primary: (any TextEmbeddingProviding)? = nil,
                 fallback: (any TextEmbeddingProviding)? = nil,
                 dimension: Int = 384,
                 reprobeInterval: TimeInterval = 3600,
                 dateProvider: @Sendable @escaping () -> Date = { Date() }) {
        self.dimension = dimension
        self.reprobeInterval = reprobeInterval
        self.dateProvider = dateProvider
        #if DEBUG
        self.debugAvailabilityOverride = Self.parseDebugAvailabilityOverride()
        #endif
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

    // MARK: - Availability (actor-isolated — accesses mutable state)

    /// Availability probe with self-healing. Re-probes after a cooldown or once Apple Intelligence reports ready.
    public func isAvailable(trigger: String = "cache_check") -> Bool {
        let now = dateProvider()

        #if DEBUG
        if let override = debugAvailabilityOverride {
            availabilityState = override ? .available : .unavailable(lastChecked: now)
            return override
        }
        #endif

        switch availabilityState {
        case .available:
            return true
        case .unavailable(let lastChecked):
            let fmReady = FoundationModelsAvailability.checkAvailability() == .ready
            if fmReady || now.timeIntervalSince(lastChecked) >= reprobeInterval {
                availabilityState = .probing(previous: false)
            } else {
                return false
            }
        case .probing(let previous):
            return previous ?? false
        case .unknown:
            availabilityState = .probing(previous: nil)
        }

        let result = probeAvailability(trigger: trigger)
        let completion = dateProvider()
        availabilityState = result ? .available : .unavailable(lastChecked: completion)
        logAvailabilityChangeIfNeeded(newMode: result ? .available : .unavailable, trigger: trigger)
        return result
    }

    /// Clears any cached availability decision so a subsequent probe re-evaluates providers.
    public func invalidateAvailabilityCache() {
        availabilityState = .unknown
    }

    /// Refreshes availability, optionally forcing a probe even if cached unavailable.
    @discardableResult
    public func refreshAvailability(force: Bool = false, trigger: String = "manual") async -> AvailabilityMode {
        let now = dateProvider()

        #if DEBUG
        if let override = debugAvailabilityOverride {
            availabilityState = override ? .available : .unavailable(lastChecked: now)
            return override ? .available : .unavailable
        }
        #endif

        var shouldProbe = force
        var cached: AvailabilityMode = .unavailable

        switch availabilityState {
        case .available:
            cached = .available
        case .unavailable(let lastChecked):
            cached = .unavailable
            let fmReady = FoundationModelsAvailability.checkAvailability() == .ready
            if fmReady || now.timeIntervalSince(lastChecked) >= reprobeInterval {
                shouldProbe = true
            }
        case .probing(let previous):
            cached = (previous ?? false) ? .available : .unavailable
        case .unknown:
            shouldProbe = true
        }

        guard shouldProbe else { return cached }

        availabilityState = .probing(previous: cached == .available)
        let result = probeAvailability(trigger: trigger)
        let mode: AvailabilityMode = result ? .available : .unavailable
        let completionDate = dateProvider()
        availabilityState = mode == .available ? .available : .unavailable(lastChecked: completionDate)
        logAvailabilityChangeIfNeeded(newMode: mode, trigger: trigger)
        return mode
    }

    /// Lightweight availability probe without invoking caller text; callers can branch without throwing.
    public func availabilityMode(trigger: String = "cache_check") -> AvailabilityMode {
        isAvailable(trigger: trigger) ? .available : .unavailable
    }

    // MARK: - Embedding (nonisolated — only accesses immutable Sendable properties)

    /// Generates an embedding for the supplied text, padding or truncating to 384 dimensions.
    public nonisolated func embedding(for text: String) throws -> [Float] {
        var lastError: Error?
        var lastProvider: DiagnosticsSafeString?

        if let primaryProvider {
            do {
                let vector = try primaryProvider.embedding(for: text)
                return try validated(vector)
            } catch {
                lastError = error
                lastProvider = DiagnosticsSafeString.stage("primary", allowed: Set(["primary", "fallback"]))
            }
        }

        if let fallbackProvider {
            do {
                let vector = try fallbackProvider.embedding(for: text)
                return try validated(vector)
            } catch {
                lastError = error
                lastProvider = DiagnosticsSafeString.stage("fallback", allowed: Set(["primary", "fallback"]))
            }
        }

        let terminalError = lastError ?? EmbeddingError.generatorUnavailable
        Diagnostics.log(level: .error,
                        category: .embeddings,
                        name: "embeddings.embedding.failed",
                        fields: [
                            "provider": .safeString(lastProvider ?? DiagnosticsSafeString.stage("none", allowed: Set(["none", "primary", "fallback"]))),
                            "dimension": .int(dimension)
                        ],
                        error: terminalError)
        throw terminalError
    }

    /// Generates a combined embedding for multiple text segments (averaged element-wise).
    public nonisolated func embedding(forSegments segments: [String]) throws -> [Float] {
        guard !segments.isEmpty else { throw EmbeddingError.emptyResult }
        var accumulator = [Float](repeating: 0, count: dimension)
        var count: Float = 0
        for (index, segment) in segments.enumerated() where !segment.isEmpty {
            do {
                let vector = try embedding(for: segment)
                for i in 0 ..< dimension {
                    accumulator[i] += vector[i]
                }
                count += 1
            } catch {
                #if DEBUG
                logger.debug("Segment embedding failed at index \(index, privacy: .public); continuing without it. Error: \(error.localizedDescription, privacy: .public)")
                #endif
                continue
            }
        }
        guard count > 0 else { throw EmbeddingError.generatorUnavailable }
        for index in 0 ..< dimension {
            accumulator[index] /= count
        }
        guard accumulator.contains(where: { $0 != 0 }) else {
            throw EmbeddingError.emptyResult
        }
        return accumulator
    }

    // MARK: - Private Helpers

    private nonisolated func validated(_ vector: [Float]) throws -> [Float] {
        guard !vector.isEmpty else { throw EmbeddingError.emptyResult }
        guard !vector.contains(where: { $0.isNaN }) else { throw EmbeddingError.emptyResult }
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

    private nonisolated func probeAvailability(trigger: String) -> Bool {
        let triggerSafe = DiagnosticsSafeString.stage(trigger, allowed: Set(["cache_check", "manual", "startup", "foreground", "retry_deferred"]))
        let span = Diagnostics.span(category: .embeddings,
                                    name: "embeddings.availability.probe",
                                    fields: [
                                        "trigger": .safeString(triggerSafe),
                                        "dimension": .int(dimension)
                                    ],
                                    level: .info)
        let start = ContinuousClock().now
        var providerUsed = DiagnosticsSafeString.stage("unknown", allowed: Set(["primary", "fallback", "unknown"]))
        var success = false

        if let primaryProvider {
            if let vector = try? primaryProvider.embedding(for: availabilityProbeText),
               let validatedVec = try? validated(vector),
               validatedVec.count == dimension,
               validatedVec.contains(where: { $0 != 0 }) {
                success = true
                providerUsed = DiagnosticsSafeString.stage("primary", allowed: Set(["primary", "fallback", "unknown"]))
            }
        }

        if !success, let fallbackProvider {
            if let vector = try? fallbackProvider.embedding(for: availabilityProbeText),
               let validatedVec = try? validated(vector),
               validatedVec.count == dimension,
               validatedVec.contains(where: { $0 != 0 }) {
                success = true
                providerUsed = DiagnosticsSafeString.stage("fallback", allowed: Set(["primary", "fallback", "unknown"]))
            }
        }

        if !success {
            logger.error("Embedding availability probe failed; providers unavailable or returned zero-vector.")
        }

        let elapsed = ContinuousClock().now - start
        let durationMs = Double(elapsed.components.seconds) * 1_000 + Double(elapsed.components.attoseconds) / 1_000_000_000_000_000.0
        span.end(additionalFields: [
            "trigger": .safeString(triggerSafe),
            "provider": .safeString(providerUsed),
            "result": .safeString(DiagnosticsSafeString.stage(success ? "available" : "unavailable",
                                                              allowed: Set(["available", "unavailable"]))),
            "dimension": .int(dimension)
        ], error: success ? nil : EmbeddingError.generatorUnavailable)
        Diagnostics.log(level: success ? .info : .warn,
                        category: .embeddings,
                        name: "embeddings.availability.probe.end",
                        fields: [
                            "trigger": .safeString(triggerSafe),
                            "provider": .safeString(providerUsed),
                            "result": .safeString(DiagnosticsSafeString.stage(success ? "available" : "unavailable",
                                                                              allowed: Set(["available", "unavailable"]))),
                            "dimension": .int(dimension),
                            "duration_ms": .double(durationMs)
                        ])
        return success
    }

    #if DEBUG
    private static func parseDebugAvailabilityOverride() -> Bool? {
        guard let value = ProcessInfo.processInfo.environment["PULSUM_EMBEDDINGS_AVAILABLE"]?.lowercased() else {
            return nil
        }
        if ["1", "true", "yes", "available"].contains(value) {
            return true
        }
        if ["0", "false", "no", "unavailable"].contains(value) {
            return false
        }
        return nil
    }
    #endif

    private func logAvailabilityChangeIfNeeded(newMode: AvailabilityMode, trigger: String) {
        guard lastReportedAvailability != newMode else { return }
        lastReportedAvailability = newMode
        Diagnostics.log(level: .info,
                        category: .embeddings,
                        name: "embeddings.availability.changed",
                        fields: [
                            "state": .safeString(DiagnosticsSafeString.stage(newMode == .available ? "available" : "unavailable",
                                                                             allowed: Set(["available", "unavailable"]))),
                            "trigger": .safeString(DiagnosticsSafeString.stage(trigger,
                                                                               allowed: Set(["cache_check", "manual", "startup", "foreground", "retry_deferred"])))
                        ])
    }
}

#if DEBUG
public extension EmbeddingService {
    static func debugInstance(primary: (any TextEmbeddingProviding)? = nil,
                              fallback: (any TextEmbeddingProviding)? = nil,
                              dimension: Int = 384,
                              reprobeInterval: TimeInterval = 3600,
                              dateProvider: @Sendable @escaping () -> Date = { Date() }) -> EmbeddingService {
        EmbeddingService(primary: primary,
                         fallback: fallback,
                         dimension: dimension,
                         reprobeInterval: reprobeInterval,
                         dateProvider: dateProvider)
    }
}
#endif
