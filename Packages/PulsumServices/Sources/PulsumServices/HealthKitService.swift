import Foundation
@preconcurrency import HealthKit
import PulsumTypes

public protocol HealthKitObservationToken: AnyObject {}
#if canImport(HealthKit)
extension HKObserverQuery: HealthKitObservationToken {}
#endif

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

public enum ReadAuthorizationProbeResult: Equatable, Sendable {
    case authorized
    case denied
    case notDetermined
    case protectedDataUnavailable
    case healthDataUnavailable
    case error(domain: String, code: Int)
}

#if DEBUG
private enum HealthKitStatusOverrideBehavior: String {
    case none
    case grantAll
}

private final class HealthKitAuthorizationOverrides: @unchecked Sendable {
    static let shared = HealthKitAuthorizationOverrides()

    private let queue = DispatchQueue(label: "ai.pulsum.healthkit.override", qos: .utility)
    private var overrides: [String: HKAuthorizationStatus]
    private let requestBehavior: HealthKitStatusOverrideBehavior
    private let debugLoggingEnabled: Bool

    private init() {
        self.overrides = Self.parseOverrides(ProcessInfo.processInfo.environment["PULSUM_HEALTHKIT_STATUS_OVERRIDE"])
        if let rawBehavior = ProcessInfo.processInfo.environment["PULSUM_HEALTHKIT_REQUEST_BEHAVIOR"],
           let behavior = HealthKitStatusOverrideBehavior(rawValue: rawBehavior) {
            self.requestBehavior = behavior
        } else {
            self.requestBehavior = .none
        }
        self.debugLoggingEnabled = ProcessInfo.processInfo.environment["PULSUM_HEALTHKIT_DEBUG"] == "1"
    }

    func status(for identifier: String) -> HKAuthorizationStatus? {
        queue.sync { overrides[identifier] }
    }

    func handleRequest(availableTypes: Set<HKSampleType>) -> Bool {
        switch requestBehavior {
        case .grantAll:
            queue.sync {
                for type in availableTypes {
                    overrides[type.identifier] = .sharingAuthorized
                }
                if debugLoggingEnabled {
                    let identifiers = availableTypes.map(\.identifier).sorted()
                    Diagnostics.log(level: .debug,
                                    category: .healthkit,
                                    name: "healthkit.override.grantAll",
                                    fields: [
                                        "type_count": .int(identifiers.count)
                                    ])
                }
            }
            return true
        case .none:
            if debugLoggingEnabled {
                Diagnostics.log(level: .debug,
                                category: .healthkit,
                                name: "healthkit.override.none")
            }
            return false
        }
    }

    private static func parseOverrides(_ raw: String?) -> [String: HKAuthorizationStatus] {
        guard let raw, !raw.isEmpty else { return [:] }
        var result: [String: HKAuthorizationStatus] = [:]
        for entry in raw.split(separator: ",") {
            let pair = entry.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard pair.count == 2,
                  let status = status(from: pair[1]) else { continue }
            let identifier = identifier(from: pair[0])
            guard !identifier.isEmpty else { continue }
            result[identifier] = status
        }
        return result
    }

    private static func status(from value: String) -> HKAuthorizationStatus? {
        switch value.lowercased() {
        case "authorized", "sharingauthorized", "granted", "allow":
            return .sharingAuthorized
        case "denied", "sharingdenied":
            return .sharingDenied
        case "undetermined", "notdetermined", "pending":
            return .notDetermined
        default:
            return nil
        }
    }

    private static func identifier(from raw: String) -> String {
        let lower = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch lower {
        case "hrv", "heartratevariability", "heartratevariabilitysdnn":
            return HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue
        case "heartrate", "hr":
            return HKQuantityTypeIdentifier.heartRate.rawValue
        case "restingheartrate", "restinghr":
            return HKQuantityTypeIdentifier.restingHeartRate.rawValue
        case "respiratoryrate", "rr":
            return HKQuantityTypeIdentifier.respiratoryRate.rawValue
        case "steps", "stepcount":
            return HKQuantityTypeIdentifier.stepCount.rawValue
        case "sleep", "sleepanalysis":
            return HKCategoryTypeIdentifier.sleepAnalysis.rawValue
        default:
            return raw
        }
    }
}
#endif

/// Encapsulates HealthKit anchored + observer queries for Pulsum ingestion.
public final class HealthKitService: @unchecked Sendable {
    public struct AnchoredUpdate {
        public let samples: [HKSample]
        public let deletedSamples: [HKDeletedObject]
        public let newAnchor: HKQueryAnchor
    }

    public typealias AnchoredUpdateHandler = @Sendable (Result<AnchoredUpdate, Error>) -> Void

    private let healthStore: HKHealthStore
    private let anchorStore: HealthKitAnchorStore
    private let calendar = Calendar(identifier: .gregorian)
    private let processingQueue = DispatchQueue(label: "ai.pulsum.healthkit.service")
    private let initialAnchorWindowDays = 2

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

    /// Sorted array of required sample types for deterministic UI display.
    public static var orderedReadSampleTypes: [HKSampleType] {
        readSampleTypes.sorted { $0.identifier < $1.identifier }
    }

    public var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Requests read authorization for Pulsum health data requirements.
    public func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitServiceError.healthDataUnavailable
        }

        #if DEBUG
        if BuildFlags.uiTestSeamsCompiledIn,
           HealthKitAuthorizationOverrides.shared.handleRequest(availableTypes: HealthKitService.readSampleTypes) {
            return
        }
        #endif

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

    public func requestStatusForAuthorization(readTypes: Set<HKSampleType>) async -> HKAuthorizationRequestStatus? {
        #if DEBUG
        if BuildFlags.uiTestSeamsCompiledIn {
            let hasOverride = readTypes.contains { type in
                HealthKitAuthorizationOverrides.shared.status(for: type.identifier) != nil
            }
            if hasOverride {
                return .unnecessary
            }
        }
        #endif
        guard #available(iOS 14.0, *) else { return nil }
        let objectTypes = Set(readTypes.map { $0 as HKObjectType })
        return try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKAuthorizationRequestStatus, Error>) in
            healthStore.getRequestStatusForAuthorization(toShare: [], read: objectTypes) { status, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: status)
                }
            }
        }
    }

    public func probeReadAuthorization(for type: HKSampleType) async -> ReadAuthorizationProbeResult {
        #if DEBUG
        if BuildFlags.uiTestSeamsCompiledIn,
           let override = HealthKitAuthorizationOverrides.shared.status(for: type.identifier) {
            switch override {
            case .sharingAuthorized:
                return .authorized
            case .sharingDenied:
                return .denied
            case .notDetermined:
                return .notDetermined
            @unknown default:
                return .notDetermined
            }
        }
        #endif
        guard HKHealthStore.isHealthDataAvailable() else {
            return .healthDataUnavailable
        }

        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -1, to: endDate) ?? endDate.addingTimeInterval(-86_400)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictStartDate])

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type,
                                      predicate: predicate,
                                      limit: 1,
                                      sortDescriptors: nil) { _, samples, error in
                if let error {
                    continuation.resume(returning: self.readProbeResult(for: error))
                } else if let samples, !samples.isEmpty {
                    continuation.resume(returning: .authorized)
                } else {
                    // A successful query doesn't confirm read authorization; it may just return no data.
                    continuation.resume(returning: .notDetermined)
                }
            }

            self.healthStore.execute(query)
        }
    }

    public func probeReadAuthorization(for types: [HKSampleType]) async -> [HKSampleType: ReadAuthorizationProbeResult] {
        guard !types.isEmpty else { return [:] }
        let maxConcurrent = 3
        return await withTaskGroup(of: (HKSampleType, ReadAuthorizationProbeResult).self) { group in
            var iterator = types.makeIterator()
            for _ in 0 ..< maxConcurrent {
                guard let next = iterator.next() else { break }
                group.addTask { [self] in
                    let result = await self.probeReadAuthorization(for: next)
                    return (next, result)
                }
            }

            var results: [HKSampleType: ReadAuthorizationProbeResult] = [:]
            for await (type, result) in group {
                results[type] = result
                if let next = iterator.next() {
                    group.addTask { [self] in
                        let result = await self.probeReadAuthorization(for: next)
                        return (next, result)
                    }
                }
            }
            return results
        }
    }

    public func fetchDailyStepTotals(startDate: Date, endDate: Date) async throws -> [Date: Int] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitServiceError.healthDataUnavailable
        }

        let quantityType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        var interval = DateComponents()
        interval.day = 1
        let anchorDate = calendar.startOfDay(for: startDate)
        let healthStore = self.healthStore
        let handle = HealthKitQueryHandle<[Date: Int]>()

        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Date: Int], Error>) in
                let coordinator = HealthKitQueryCoordinator<[Date: Int]>(continuation: continuation)
                handle.set(coordinator)

                let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                                        quantitySamplePredicate: predicate,
                                                        options: .cumulativeSum,
                                                        anchorDate: anchorDate,
                                                        intervalComponents: interval)

                coordinator.setQuery(query)

                query.initialResultsHandler = { [calendar] _, collection, error in
                    if let error {
                        coordinator.resumeFailure(error)
                        return
                    }

                    guard let collection else {
                        coordinator.resumeSuccess([:])
                        return
                    }

                    var results: [Date: Int] = [:]
                    collection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                        guard let sum = statistics.sumQuantity() else { return }
                        let day = calendar.startOfDay(for: statistics.startDate)
                        results[day] = Int(sum.doubleValue(for: HKUnit.count()))
                    }

                    coordinator.resumeSuccess(results)
                }

                healthStore.execute(query)
            }
        }, onCancel: {
            handle.cancel(healthStore: healthStore)
        })
    }

    public func fetchNocturnalHeartRateStats(startDate: Date, endDate: Date) async throws -> [Date: (avgBPM: Double, minBPM: Double?)] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitServiceError.healthDataUnavailable
        }

        let quantityType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        var results: [Date: (avgBPM: Double, minBPM: Double?)] = [:]

        var day = calendar.startOfDay(for: startDate)
        let endBoundary = calendar.startOfDay(for: endDate)
        let healthStore = self.healthStore

        while day < endBoundary {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            let nightStart = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: day) ?? day
            let nightEnd = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: nextDay) ?? nextDay

            let windowStart = max(nightStart, startDate)
            let windowEnd = min(nightEnd, endDate)
            if windowStart < windowEnd {
                let predicate = HKQuery.predicateForSamples(withStart: windowStart, end: windowEnd, options: .strictStartDate)
                let handle = HealthKitQueryHandle<(Double, Double?)?>()

                let stats = try await withTaskCancellationHandler(operation: {
                    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Double, Double?)?, Error>) in
                        let coordinator = HealthKitQueryCoordinator<(Double, Double?)?>(continuation: continuation)
                        handle.set(coordinator)

                        let query = HKStatisticsQuery(quantityType: quantityType,
                                                      quantitySamplePredicate: predicate,
                                                      options: [.discreteAverage, .discreteMin]) { _, statistics, error in
                            if let error {
                                if let hkError = error as? HKError, hkError.code == .errorNoData {
                                    coordinator.resumeSuccess(nil)
                                    return
                                }
                                let nsError = error as NSError
                                if nsError.domain == HKError.errorDomain,
                                   nsError.code == HKError.Code.errorNoData.rawValue {
                                    coordinator.resumeSuccess(nil)
                                    return
                                }
                                coordinator.resumeFailure(error)
                                return
                            }
                            guard let statistics, let average = statistics.averageQuantity() else {
                                coordinator.resumeSuccess(nil)
                                return
                            }
                            let unit = HKUnit.count().unitDivided(by: .minute())
                            let avg = average.doubleValue(for: unit)
                            let min = statistics.minimumQuantity()?.doubleValue(for: unit)
                            coordinator.resumeSuccess((avg, min))
                        }
                        coordinator.setQuery(query)
                        healthStore.execute(query)
                    }
                }, onCancel: {
                    handle.cancel(healthStore: healthStore)
                })

                if let stats {
                    results[day] = (avgBPM: stats.0, minBPM: stats.1)
                }
            }

            if day == endBoundary { break }
            guard let advance = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = advance
        }

        return results
    }

    public func fetchSamples(for sampleType: HKSampleType, startDate: Date, endDate: Date) async throws -> [HKSample] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitServiceError.healthDataUnavailable
        }

        let healthStore = self.healthStore
        let handle = HealthKitQueryHandle<[HKSample]>()

        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let coordinator = HealthKitQueryCoordinator<[HKSample]>(continuation: continuation)
                handle.set(coordinator)

                let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictStartDate])
                let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
                let query = HKSampleQuery(sampleType: sampleType,
                                          predicate: predicate,
                                          limit: HKObjectQueryNoLimit,
                                          sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error {
                        coordinator.resumeFailure(error)
                    } else {
                        coordinator.resumeSuccess(samples ?? [])
                    }
                }

                coordinator.setQuery(query)
                healthStore.execute(query)
            }
        }, onCancel: {
            handle.cancel(healthStore: healthStore)
        })
    }

    /// Configures background delivery for all supported data types.
    public func enableBackgroundDelivery() async throws {
        try await enableBackgroundDelivery(for: HealthKitService.readSampleTypes)
    }

    /// Configures background delivery for a subset of data types.
    public func enableBackgroundDelivery(for types: Set<HKSampleType>) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            guard !types.isEmpty else { return }
            for type in types {
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
                                  updateHandler: @escaping AnchoredUpdateHandler) throws -> HealthKitObservationToken {
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

        let hasAnchor = anchorStore.anchor(for: sampleType.identifier) != nil
        if predicateBox.value != nil || hasAnchor {
            executeAnchoredQuery(for: sampleType, predicateBox: predicateBox, updateHandler: updateHandler, completion: nil)
        } else {
            Diagnostics.log(level: .info,
                            category: .healthkit,
                            name: "healthkit.observe.initialFetch.skipped",
                            fields: [
                                "type": .safeString(.metadata(sampleType.identifier)),
                                "reason": .safeString(.stage("no_anchor", allowed: ["no_anchor"]))
                            ])
        }

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

    /// Returns the current authorization status for a specific sample type.
    public func authorizationStatus(for sampleType: HKSampleType) -> HKAuthorizationStatus {
        #if DEBUG
        if BuildFlags.uiTestSeamsCompiledIn,
           let override = HealthKitAuthorizationOverrides.shared.status(for: sampleType.identifier) {
            return override
        }
        #endif
        return healthStore.authorizationStatus(for: sampleType)
    }

    private func executeAnchoredQuery(for sampleType: HKSampleType,
                                      predicateBox: PredicateBox,
                                      updateHandler: @escaping AnchoredUpdateHandler,
                                      completion: (@Sendable () -> Void)?) {
        processingQueue.async { [weak self] in
            guard let self else { completion?(); return }
            let currentAnchor = self.anchorStore.anchor(for: sampleType.identifier)
            var predicate = predicateBox.value
            if predicate == nil, currentAnchor == nil {
                let endDate = Date()
                let windowDays = self.initialAnchorWindowDays
                let startDate = self.calendar.date(byAdding: .day, value: -windowDays, to: endDate)
                    ?? endDate.addingTimeInterval(-Double(windowDays) * 86_400)
                predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictStartDate])
                Diagnostics.log(level: .info,
                                category: .healthkit,
                                name: "healthkit.anchored.initialBounded",
                                fields: [
                                    "type": .safeString(.metadata(sampleType.identifier)),
                                    "window_days": .int(windowDays)
                                ])
            }
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

public protocol HealthKitServicing: AnyObject, Sendable {
    var isHealthDataAvailable: Bool { get }
    func requestAuthorization() async throws
    func requestStatusForAuthorization(readTypes: Set<HKSampleType>) async -> HKAuthorizationRequestStatus?
    func probeReadAuthorization(for type: HKSampleType) async -> ReadAuthorizationProbeResult
    func probeReadAuthorization(for types: [HKSampleType]) async -> [HKSampleType: ReadAuthorizationProbeResult]
    func fetchDailyStepTotals(startDate: Date, endDate: Date) async throws -> [Date: Int]
    func fetchNocturnalHeartRateStats(startDate: Date, endDate: Date) async throws -> [Date: (avgBPM: Double, minBPM: Double?)]
    func fetchSamples(for sampleType: HKSampleType, startDate: Date, endDate: Date) async throws -> [HKSample]
    func enableBackgroundDelivery(for types: Set<HKSampleType>) async throws
    func enableBackgroundDelivery() async throws
    @discardableResult
    func observeSampleType(_ sampleType: HKSampleType,
                           predicate: NSPredicate?,
                           updateHandler: @escaping HealthKitService.AnchoredUpdateHandler) throws -> HealthKitObservationToken
    func stopObserving(sampleType: HKSampleType, resetAnchor: Bool)
    func authorizationStatus(for sampleType: HKSampleType) -> HKAuthorizationStatus
}

extension HealthKitService: HealthKitServicing {}

extension HealthKitService.AnchoredUpdate: @unchecked Sendable {}

private final class HealthKitQueryHandle<Result: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var coordinator: HealthKitQueryCoordinator<Result>?

    func set(_ coordinator: HealthKitQueryCoordinator<Result>) {
        lock.lock()
        self.coordinator = coordinator
        lock.unlock()
    }

    func cancel(healthStore: HKHealthStore) {
        lock.lock()
        let coordinator = coordinator
        lock.unlock()
        coordinator?.cancel(healthStore: healthStore)
    }
}

private final class HealthKitQueryCoordinator<Result: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var resumed = false
    private var query: HKQuery?
    private let continuation: CheckedContinuation<Result, Error>

    init(continuation: CheckedContinuation<Result, Error>) {
        self.continuation = continuation
    }

    func setQuery(_ query: HKQuery) {
        lock.lock()
        self.query = query
        lock.unlock()
    }

    func resumeSuccess(_ result: Result) {
        lock.lock()
        guard !resumed else { lock.unlock(); return }
        resumed = true
        lock.unlock()
        continuation.resume(returning: result)
    }

    func resumeFailure(_ error: Error) {
        lock.lock()
        guard !resumed else { lock.unlock(); return }
        resumed = true
        lock.unlock()
        continuation.resume(throwing: error)
    }

    func cancel(healthStore: HKHealthStore) {
        let query: HKQuery?
        lock.lock()
        query = self.query
        let shouldResume = !resumed
        if !resumed {
            resumed = true
        }
        lock.unlock()

        if let query {
            healthStore.stop(query)
        }
        if shouldResume {
            continuation.resume(throwing: CancellationError())
        }
    }
}

private struct CompletionBox: @unchecked Sendable {
    let handler: HKObserverQueryCompletionHandler
    func call() { handler() }
}

private struct PredicateBox: @unchecked Sendable {
    let value: NSPredicate?
}

private extension HealthKitService {
    func readProbeResult(for error: Error) -> ReadAuthorizationProbeResult {
        if let hkError = error as? HKError {
            return readProbeResult(for: hkError)
        }

        let nsError = error as NSError
        if nsError.domain == HKError.errorDomain,
           let code = HKError.Code(rawValue: nsError.code) {
            return readProbeResult(forHKCode: code)
        }

        return .error(domain: (error as NSError).domain, code: (error as NSError).code)
    }

    func readProbeResult(for hkError: HKError) -> ReadAuthorizationProbeResult {
        return readProbeResult(forHKCode: hkError.code)
    }

    func readProbeResult(forHKCode code: HKError.Code) -> ReadAuthorizationProbeResult {
        switch code {
        case .errorAuthorizationDenied, .errorRequiredAuthorizationDenied:
            return .denied
        case .errorAuthorizationNotDetermined:
            return .notDetermined
        case .errorDatabaseInaccessible:
            return .protectedDataUnavailable
        case .errorHealthDataUnavailable, .errorHealthDataRestricted:
            return .healthDataUnavailable
        case .errorNoData:
            return .notDetermined
        #if compiler(>=6.0)
        case .errorNotPermissibleForGuestUserMode:
            return .healthDataUnavailable
        #endif
        default:
            return .error(domain: HKError.errorDomain, code: code.rawValue)
        }
    }
}
