import Foundation

public enum AnalyticsEvent: String, Sendable {
    case journalSubmitted
    case coachMessageSent
    case scoreViewed
    case settingsOpened
    case onboardingCompleted
    case pulseCompleted
    case recommendationCompleted
    case safetyCardShown
}

public protocol AnalyticsProvider: Sendable {
    func track(_ event: AnalyticsEvent)
}

public struct NoOpAnalyticsProvider: AnalyticsProvider {
    public init() {}

    public func track(_: AnalyticsEvent) {
        // No-op: analytics backend not configured
    }
}
