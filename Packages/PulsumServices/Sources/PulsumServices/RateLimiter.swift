import Foundation
import os

public actor RateLimiter {
    private let minimumInterval: TimeInterval
    private var lastRequestTime: Date = .distantPast
    private let logger = Logger(subsystem: "ai.pulsum", category: "RateLimiter")

    public init(minimumInterval: TimeInterval = 3.0) {
        self.minimumInterval = minimumInterval
    }

    public func acquire() async throws {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastRequestTime)
        let delay = minimumInterval - elapsed
        if delay > 0 {
            logger.debug("Rate limiting: waiting \(String(format: "%.1f", delay), privacy: .public)s before next API call.")
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        lastRequestTime = Date()
    }
}
