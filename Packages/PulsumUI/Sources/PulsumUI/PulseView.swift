import SwiftUI
import Observation
private enum PulseHapticStyle { case medium, heavy }

#if canImport(UIKit)
private func performPulseHaptic(_ style: PulseHapticStyle) {
    let mapped: UIImpactFeedbackGenerator.FeedbackStyle = {
        switch style {
        case .medium: return .medium
        case .heavy: return .heavy
        }
    }()
    let generator = UIImpactFeedbackGenerator(style: mapped)
    generator.impactOccurred()
}
#else
private func performPulseHaptic(_ style: PulseHapticStyle) {}
#endif
