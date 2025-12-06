import Foundation

public enum WellbeingNoDataReason: Equatable {
    case healthDataUnavailable
    case permissionsDeniedOrPending
    case insufficientSamples
}

public enum WellbeingScoreState: Equatable {
    case loading
    case ready(score: Double, contributions: [String: Double])
    case noData(WellbeingNoDataReason)
    case error(message: String)
}
