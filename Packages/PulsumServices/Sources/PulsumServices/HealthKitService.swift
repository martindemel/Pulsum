import Foundation
@preconcurrency import HealthKit

/// Errors thrown by `HealthKitService`.
public enum HealthKitServiceError: LocalizedError {
    case healthDataUnavailable
    case authorizationDenied
    case backgroundDeliveryFailed(type: HKObjectType, underlying: Error)
    case queryExecutionFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            return "Health data is not available on this device."
        case .authorizationDenied:
            return "Pulsum does not have permission to read the requested health data."
        case let .backgroundDeliveryFailed(type, underlying):
            return "Background delivery failed for \(type.identifier): \(underlying.localizedDescription)"
        case let .queryExecutionFailed(underlying):
            return "Failed to execute HealthKit query: \(underlying.localizedDescription)"
        }
    }
}

/// Encapsulates HealthKit anchored + observer queries for Pulsum ingestion.
public final class HealthKitService {
    public struct AnchoredUpdate {
        public let samples: [HKSample]
        public let deletedSamples: [HKDeletedObject]
        public let newAnchor: HKQueryAnchor
    }

    public typealias AnchoredUpdateHandler = @Sendable (Result<AnchoredUpdate, Error>) -> Void

private let healthStore: HKHealthStore
private let anchorStore: HealthKitAnchorStore
    private let processingQueue = DispatchQueue(label: "ai.pulsum.healthkit.service")

    private var activeObserverQueries: [HKSampleType: HKObserverQuery] = [:]
    private var activeAnchoredQueries: [HKSampleType: HKAnchoredObjectQuery] = [:]

    public init(healthStore: HKHealthStore = HKHealthStore(), anchorStore: HealthKitAnchorStore = HealthKitAnchorStore()) {
        self.healthStore = healthStore
        self.anchorStore = anchorStore
    }

    /// All HealthKit sample types Pulsum consumes.
    public static var readSampleTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = []
        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { types.insert(hrv) }
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) { types.insert(heartRate) }
        if let restingHR = HKObjectType.quantityType(forIdentifier: .restingHeartRate) { types.insert(restingHR) }
        if let respiratoryRate = HKObjectType.quantityType(forIdentifier: .respiratoryRate) { types.insert(respiratoryRate) }
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) { types.insert(steps) }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        return types
    }

    /// Requests read authorization for Pulsum health data requirements.
    public func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitServiceError.healthDataUnavailable
        }

        let readTypes = HealthKitService.readSampleTypes

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitServiceError.authorizationDenied)
                }
            }
        }
    }

    /// Configures background delivery for all supported data types.
    public func enableBackgroundDelivery() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for type in HealthKitService.readSampleTypes {
                group.addTask { [healthStore] in
                    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                        healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
                            if let error {
                                continuation.resume(throwing: HealthKitServiceError.backgroundDeliveryFailed(type: type, underlying: error))
                            } else if success {
                                continuation.resume()
                            } else {
                                continuation.resume(throwing: HealthKitServiceError.backgroundDeliveryFailed(type: type, underlying: HealthKitServiceError.authorizationDenied))
                            }
                        }
                    }
                }
            }

            try await group.waitForAll()
        }
    }

    /// Starts an observer + anchored query pair for the provided sample type.
    @discardableResult
    public func observeSampleType(_ sampleType: HKSampleType,
                                  predicate: NSPredicate? = nil,
                                  updateHandler: @escaping AnchoredUpdateHandler) throws -> HKObserverQuery {
        let predicateBox = PredicateBox(value: predicate)

        let observer = HKObserverQuery(sampleType: sampleType, predicate: predicateBox.value) { [weak self] _, completionHandler, error in
            guard let self else { completionHandler(); return }

            if let error {
                updateHandler(.failure(error))
                completionHandler()
                return
            }

            let completionBox = CompletionBox(handler: completionHandler)
            self.executeAnchoredQuery(for: sampleType, predicateBox: predicateBox, updateHandler: updateHandler) {
                completionBox.call()
            }
        }

        healthStore.execute(observer)
        processingQueue.async { [weak self] in
            self?.activeObserverQueries[sampleType] = observer
        }

        // Initial fetch
        executeAnchoredQuery(for: sampleType, predicateBox: predicateBox, updateHandler: updateHandler, completion: nil)

        return observer
    }

    /// Stops observation for a sample type and clears the persisted anchor.
    public func stopObserving(sampleType: HKSampleType, resetAnchor: Bool = false) {
        processingQueue.async { [weak self] in
            guard let self else { return }
            if let observer = self.activeObserverQueries.removeValue(forKey: sampleType) {
                self.healthStore.stop(observer)
            }
            if let anchored = self.activeAnchoredQueries.removeValue(forKey: sampleType) {
                self.healthStore.stop(anchored)
            }
            if resetAnchor {
                self.anchorStore.removeAnchor(for: sampleType.identifier)
            }
        }
    }

    private func executeAnchoredQuery(for sampleType: HKSampleType,
                                      predicateBox: PredicateBox,
                                      updateHandler: @escaping AnchoredUpdateHandler,
                                      completion: (@Sendable () -> Void)?) {
        processingQueue.async { [weak self] in
            guard let self else { completion?(); return }
            let predicate = predicateBox.value
            let currentAnchor = self.anchorStore.anchor(for: sampleType.identifier)
            let query = HKAnchoredObjectQuery(type: sampleType,
                                             predicate: predicate,
                                             anchor: currentAnchor,
                                             limit: HKObjectQueryNoLimit) { [weak self] _, samples, deletedObjects, newAnchor, error in
                defer { completion?() }

                guard let self else { return }

                if let error {
                    updateHandler(.failure(error))
                    return
                }

                guard let newAnchor else {
                    updateHandler(.failure(HealthKitServiceError.queryExecutionFailed(underlying: CocoaError(.coderValueNotFound))))
                    return
                }

                self.anchorStore.store(anchor: newAnchor, for: sampleType.identifier)
                let samples = samples ?? []
                let deleted = deletedObjects ?? []
                let result = AnchoredUpdate(samples: samples, deletedSamples: deleted, newAnchor: newAnchor)
                updateHandler(.success(result))
            }

            query.updateHandler = { [weak self] _, samples, deletedObjects, newAnchor, error in
                guard let self else { return }
                if let error {
                    updateHandler(.failure(error))
                    return
                }
                guard let newAnchor else { return }
                self.anchorStore.store(anchor: newAnchor, for: sampleType.identifier)
                let samples = samples ?? []
                let deleted = deletedObjects ?? []
                let result = AnchoredUpdate(samples: samples, deletedSamples: deleted, newAnchor: newAnchor)
                updateHandler(.success(result))
            }

            self.healthStore.execute(query)
            self.activeAnchoredQueries[sampleType] = query
        }
    }
}

extension HealthKitService: @unchecked Sendable {}

extension HealthKitService.AnchoredUpdate: @unchecked Sendable {}

private struct CompletionBox: @unchecked Sendable {
    let handler: HKObserverQueryCompletionHandler
    func call() { handler() }
}

private struct PredicateBox: @unchecked Sendable {
    let value: NSPredicate?
}
