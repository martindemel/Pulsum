import Foundation
import PulsumTypes

public actor RateLimiter {
    private let minimumInterval: Duration
    private let clock = ContinuousClock()
    private var lastRequestTime: ContinuousClock.Instant?

    public init(minimumInterval: TimeInterval = 3.0) {
        self.minimumInterval = .seconds(minimumInterval)
    }

    public func acquire() async throws {
        let now = clock.now
        if let lastRequestTime {
            let elapsed = lastRequestTime.duration(to: now)
            let delay = minimumInterval - elapsed
            if delay > .zero {
                let delaySeconds = Double(delay.components.seconds) + Double(delay.components.attoseconds) / 1e18
                Diagnostics.log(level: .debug,
                                category: .llm,
                                name: "rateLimiter.waiting",
                                fields: ["delay": .safeString(.metadata(String(format: "%.1fs", delaySeconds)))])
                try await clock.sleep(for: delay)
            }
        }
        lastRequestTime = clock.now
    }
}
