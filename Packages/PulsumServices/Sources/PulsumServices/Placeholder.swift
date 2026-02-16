import Foundation
import PulsumML

public enum PulsumServices {
    public static var keychain: KeychainService { KeychainService.shared }

    public static func embeddingVersion() -> String {
        PulsumML.version
    }
}
