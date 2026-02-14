import Foundation
import PulsumML

public enum PulsumServices {
    private static let healthKitInstance = HealthKitService()

    public static var healthKit: HealthKitService { healthKitInstance }
    public static var keychain: KeychainService { KeychainService.shared }

    public static func embeddingVersion() -> String {
        PulsumML.version
    }
}
