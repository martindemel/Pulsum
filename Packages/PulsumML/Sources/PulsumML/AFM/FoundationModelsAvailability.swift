import Foundation
#if canImport(FoundationModels) && os(iOS)
import FoundationModels
#endif

public enum AFMStatus {
    case ready
    case needsAppleIntelligence
    case downloading
    case unsupportedDevice
    case unknown
}

public final class FoundationModelsAvailability {
#if canImport(FoundationModels) && os(iOS)
    public static func checkAvailability() -> AFMStatus {
        guard #available(iOS 26.0, *) else { return .needsAppleIntelligence }
        switch SystemLanguageModel.default.availability {
        case .available:
            return .ready
        case .unavailable(.appleIntelligenceNotEnabled):
            return .needsAppleIntelligence
        case .unavailable(.modelNotReady):
            return .downloading
        default:
            return .unknown
        }
    }
#else
    public static func checkAvailability() -> AFMStatus { .unsupportedDevice }
#endif
    
    public static func availabilityMessage(for status: AFMStatus) -> String {
        switch status {
        case .ready:
            return "Apple Intelligence is ready."
        case .needsAppleIntelligence:
            return "Please enable Apple Intelligence in Settings to use AI features."
        case .downloading:
            return "Preparing AI model... This may take a few minutes."
        case .unsupportedDevice:
            return "This device doesn't support Apple Intelligence."
        case .unknown:
            return "AI features are temporarily unavailable."
        }
    }
}
