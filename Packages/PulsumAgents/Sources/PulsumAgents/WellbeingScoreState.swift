import Foundation

public enum WellbeingNoDataReason: Equatable, Sendable {
    case healthDataUnavailable
    case permissionsDeniedOrPending
    case insufficientSamples
}

public enum WellbeingScoreState: Equatable, Sendable {
    case loading
    case ready(score: Double, contributions: [String: Double])
    case noData(WellbeingNoDataReason)
    case error(message: String)
}
