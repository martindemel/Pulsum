import Foundation

public extension Notification.Name {
    static let pulsumScoresUpdated = Notification.Name("pulsumScoresUpdated")
    static let pulsumChatRouteDiagnostics = Notification.Name("com.pulsum.chatRouteDiagnostics")
    static let pulsumChatCloudError = Notification.Name("com.pulsum.chatCloudError")
}

public enum AgentNotificationKeys {
    public static let date = "date"
}
