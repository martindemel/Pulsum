import Foundation
import PulsumTypes

public actor RateLimiter {
    private let minimumInterval: TimeInterval
    private var lastRequestTime: Date = .distantPast

    public init(minimumInterval: TimeInterval = 3.0) {
        self.minimumInterval = minimumInterval
    }

    public func acquire() async throws {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastRequestTime)
        let delay = minimumInterval - elapsed
        if delay > 0 {
            Diagnostics.log(level: .debug,
                            category: .llm,
                            name: "rateLimiter.waiting",
                            fields: ["delay": .safeString(.metadata(String(format: "%.1fs", delay)))])
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        lastRequestTime = Date()
    }
}
