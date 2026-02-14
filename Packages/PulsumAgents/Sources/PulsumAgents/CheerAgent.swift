import Foundation

@MainActor
public final class CheerAgent {
    private let calendar = Calendar(identifier: .gregorian)

    public init() {}

    public func celebrateCompletion(momentTitle: String) async -> CheerEvent {
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let timeQualifier: String
        switch hour {
        case 5 ..< 12: timeQualifier = "morning momentum"
        case 12 ..< 17: timeQualifier = "midday reset"
        case 17 ..< 22: timeQualifier = "evening follow-through"
        default: timeQualifier = "late-day commitment"
        }

        let affirmations = [
            "That move keeps your trend headed the right way.",
            "Nice follow-through—log how it felt while it's fresh.",
            "Your consistency is building a durable baseline.",
            "You're stacking evidence you can count on."
        ]
        let affirmation = affirmations.randomElement() ?? "Great job locking in the win."

        let message = "\(momentTitle) • \(timeQualifier). \(affirmation)"
        let haptic: CheerEvent.HapticStyle = affirmation.contains("consistency") ? .success : .light
        return CheerEvent(message: message, haptic: haptic, timestamp: now)
    }
}
