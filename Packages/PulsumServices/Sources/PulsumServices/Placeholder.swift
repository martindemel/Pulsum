import Foundation
import PulsumData
import PulsumML

public enum PulsumServices {
    private static let healthKitInstance = HealthKitService()

    public static var healthKit: HealthKitService { healthKitInstance }
    public static var keychain: KeychainService { KeychainService.shared }

    public static func storageMetadata() -> (storeURL: URL, anchorsDirectory: URL) {
        (PulsumData.sqliteStoreURL, PulsumData.healthAnchorsDirectory)
    }

    public static func embeddingVersion() -> String {
        PulsumML.version
    }
}
