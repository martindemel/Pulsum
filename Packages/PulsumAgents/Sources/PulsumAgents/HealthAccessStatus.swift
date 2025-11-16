import Foundation
@preconcurrency import HealthKit

/// Consolidated authorization surface for Pulsum's HealthKit ingestion.
/// `HKSampleType` is not marked `Sendable`, so the struct uses `@unchecked Sendable`.
public struct HealthAccessStatus: @unchecked Sendable {
    public enum Availability: Equatable, Sendable {
        case available
        case unavailable(reason: String)
    }

    public let required: [HKSampleType]
    public let granted: Set<HKSampleType>
    public let denied: Set<HKSampleType>
    public let notDetermined: Set<HKSampleType>
    public let availability: Availability
    public let timestamp: Date

    public init(required: [HKSampleType],
                granted: Set<HKSampleType>,
                denied: Set<HKSampleType>,
                notDetermined: Set<HKSampleType>,
                availability: Availability,
                timestamp: Date = Date()) {
        self.required = required
        self.granted = granted
        self.denied = denied
        self.notDetermined = notDetermined
        self.availability = availability
        self.timestamp = timestamp
    }

    public var grantedCount: Int { granted.count }
    public var totalRequired: Int { required.count }

    public var missingTypes: [HKSampleType] {
        Array(denied) + Array(notDetermined)
    }

    public var isFullyGranted: Bool {
        availability == .available && missingTypes.isEmpty && !required.isEmpty
    }
}
