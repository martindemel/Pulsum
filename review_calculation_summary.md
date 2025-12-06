### Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift
```swift
import Foundation
@preconcurrency import HealthKit

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
                    print("[PulsumHealthKitOverride] Granting all overrides for: \(identifiers.joined(separator: ", "))")
                }
            }
            return true
        case .none:
            if debugLoggingEnabled {
                print("[PulsumHealthKitOverride] No override behavior configured.")
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

    public func fetchSamples(for sampleType: HKSampleType, startDate: Date, endDate: Date) async throws -> [HKSample] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitServiceError.healthDataUnavailable
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictStartDate])
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: sampleType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples ?? [])
                }
            }
            self.healthStore.execute(query)
        }
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

public protocol HealthKitServicing: AnyObject, Sendable {
    var isHealthDataAvailable: Bool { get }
    func requestAuthorization() async throws
    func requestStatusForAuthorization(readTypes: Set<HKSampleType>) async -> HKAuthorizationRequestStatus?
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

private struct CompletionBox: @unchecked Sendable {
    let handler: HKObserverQueryCompletionHandler
    func call() { handler() }
}

private struct PredicateBox: @unchecked Sendable {
    let value: NSPredicate?
}
```

### Packages/PulsumServices/Sources/PulsumServices/HealthKitAnchorStore.swift
```swift
import Foundation
import HealthKit
import PulsumData

/// Persists HealthKit query anchors on-device with complete file protection.
public final class HealthKitAnchorStore {
    private let directory: URL
    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "ai.pulsum.healthkit.anchorstore")

    public init(directory: URL = PulsumData.healthAnchorsDirectory, fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
    }

    public func anchor(for sampleTypeIdentifier: String) -> HKQueryAnchor? {
        queue.sync {
            let fileURL = url(for: sampleTypeIdentifier)
            guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
            guard let data = try? Data(contentsOf: fileURL) else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
        }
    }

    public func store(anchor: HKQueryAnchor, for sampleTypeIdentifier: String) {
        queue.async {
            let fileURL = self.url(for: sampleTypeIdentifier)
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
                try data.write(to: fileURL, options: .atomic)
                try self.applyFileProtection(to: fileURL)
            } catch {
                assertionFailure("Failed to persist HKQueryAnchor for \(sampleTypeIdentifier): \(error)")
            }
        }
    }

    public func removeAnchor(for sampleTypeIdentifier: String) {
        queue.async {
            let fileURL = self.url(for: sampleTypeIdentifier)
            guard self.fileManager.fileExists(atPath: fileURL.path) else { return }
            do {
                try self.fileManager.removeItem(at: fileURL)
            } catch {
                assertionFailure("Failed to remove HKQueryAnchor for \(sampleTypeIdentifier): \(error)")
            }
        }
    }

    private func url(for identifier: String) -> URL {
        directory.appendingPathComponent(identifier.safeFilenameComponent).appendingPathExtension("anchor")
    }

    private func applyFileProtection(to url: URL) throws {
        try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
    }
}

private extension String {
    /// Sanitizes the identifier for safe filesystem usage.
    var safeFilenameComponent: String {
        let invalidCharacters = CharacterSet(charactersIn: ":/")
        return components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}

extension HealthKitAnchorStore: @unchecked Sendable {}
```

### Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift
```swift
import Foundation
@preconcurrency import CoreData
import HealthKit
@preconcurrency import PulsumData
import PulsumML
import PulsumServices
import PulsumTypes

public struct FeatureVectorSnapshot: Sendable {
    public let date: Date
    public let wellbeingScore: Double
    public let contributions: [String: Double]
    public let imputedFlags: [String: Bool]
    public let featureVectorObjectID: NSManagedObjectID
    public let features: [String: Double]
}

public struct ScoreBreakdown: Sendable {
    public struct MetricDetail: Identifiable, Sendable {
        public enum Kind: String, Sendable {
            case objective
            case subjective
            case sentiment
        }

        public struct Coverage: Sendable {
            public let daysWithSamples: Int
            public let sampleCount: Int
        }

        public let id: String
        public let name: String
        public let kind: Kind
        public let value: Double?
        public let unit: String?
        public let zScore: Double?
        public let contribution: Double
        public let baselineMedian: Double?
        public let baselineEwma: Double?
        public let baselineMad: Double?
        public let rollingWindowDays: Int?
        public let explanation: String
        public let notes: [String]
        public let coverage: Coverage?
    }

    public let date: Date
    public let wellbeingScore: Double
    public let metrics: [MetricDetail]
    public let generalNotes: [String]
}

actor DataAgent {
    private let healthKit: any HealthKitServicing
    private let calendar = Calendar(identifier: .gregorian)
    private let estimatorStore: EstimatorStateStoring
    private var stateEstimator: StateEstimator
    private let context: NSManagedObjectContext
    private var observers: [String: HealthKitObservationToken] = [:]
    private let requiredSampleTypes: [HKSampleType]
    private let sampleTypesByIdentifier: [String: HKSampleType]
    private let notificationCenter: NotificationCenter

    // TEMP: narrowed to 7 days to avoid long-running backfills on large datasets; see docs for follow-up plan.
    private let analysisWindowDays = 7
    private let sleepDebtWindowDays = 7
    private let sedentaryThresholdStepsPerHour: Double = 30
    private let sedentaryMinimumDuration: TimeInterval = 30 * 60
    private var hasPerformedInitialBackfill = false

    init(healthKit: any HealthKitServicing = PulsumServices.healthKit,
         container: NSPersistentContainer = PulsumData.container,
         notificationCenter: NotificationCenter = .default,
         estimatorStore: EstimatorStateStoring = EstimatorStateStore()) {
        self.healthKit = healthKit
        self.estimatorStore = estimatorStore
        self.stateEstimator = StateEstimator()
        self.context = container.newBackgroundContext()
        self.context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        self.context.name = "Pulsum.DataAgent"
        self.notificationCenter = notificationCenter
        self.requiredSampleTypes = HealthKitService.orderedReadSampleTypes
        var dictionary: [String: HKSampleType] = [:]
        for type in requiredSampleTypes {
            dictionary[type.identifier] = type
        }
        self.sampleTypesByIdentifier = dictionary

        if let persisted = estimatorStore.loadState() {
            self.stateEstimator = StateEstimator(state: persisted)
        }
    }

    // MARK: - Lifecycle

    func start() async throws {
        await DebugLogBuffer.shared.append("DataAgent.start invoked")
        let initialStatus = await currentHealthAccessStatus()
        await DebugLogBuffer.shared.append("Initial HealthKit status: \(statusSummary(initialStatus))")
        try await configureObservation(for: initialStatus, resetRevokedAnchors: false)

        // Always re-request to refresh HealthKit's internal state; authorized paths return immediately.
        do {
            try await healthKit.requestAuthorization()
            await DebugLogBuffer.shared.append("HealthKit requestAuthorization succeeded")
        } catch {
            await DebugLogBuffer.shared.append("HealthKit requestAuthorization failed: \(error.localizedDescription)")
            throw error
        }

        let refreshedStatus = await currentHealthAccessStatus()
        await DebugLogBuffer.shared.append("Refreshed HealthKit status: \(statusSummary(refreshedStatus))")
        try await configureObservation(for: refreshedStatus, resetRevokedAnchors: true)
        await backfillHistoricalSamplesIfNeeded(for: refreshedStatus)
    }

    @discardableResult
    func startIngestionIfAuthorized() async throws -> HealthAccessStatus {
        let status = await currentHealthAccessStatus()
        await DebugLogBuffer.shared.append("startIngestionIfAuthorized status: \(statusSummary(status))")
        try await configureObservation(for: status, resetRevokedAnchors: false)
        return status
    }

    @discardableResult
    func restartIngestionAfterPermissionsChange() async throws -> HealthAccessStatus {
        let status = await currentHealthAccessStatus()
        await DebugLogBuffer.shared.append("restartIngestionAfterPermissionsChange status: \(statusSummary(status))")
        try await configureObservation(for: status, resetRevokedAnchors: true)
        return status
    }

    @discardableResult
    func requestHealthAccess() async throws -> HealthAccessStatus {
        try await healthKit.requestAuthorization()
        let status = await currentHealthAccessStatus()
        await DebugLogBuffer.shared.append("requestHealthAccess refreshed status: \(statusSummary(status))")
        try await configureObservation(for: status, resetRevokedAnchors: true)
        await backfillHistoricalSamplesIfNeeded(for: status)
        return status
    }

    func currentHealthAccessStatus() async -> HealthAccessStatus {
        if !healthKit.isHealthDataAvailable {
            let unavailable = HealthAccessStatus(required: requiredSampleTypes,
                                                 granted: [],
                                                 denied: [],
                                                 notDetermined: [],
                                                 availability: .unavailable(reason: "Health data is not available on this device."))
            return unavailable
        }

        var granted: Set<HKSampleType> = []
        var denied: Set<HKSampleType> = []
        var pending: Set<HKSampleType> = []

        let requestStatus = await healthKit.requestStatusForAuthorization(readTypes: Set(requiredSampleTypes))

        for type in requiredSampleTypes {
            switch healthKit.authorizationStatus(for: type) {
            case .sharingAuthorized:
                granted.insert(type)
            case .sharingDenied:
                if let requestStatus, requestStatus == .unnecessary {
                    granted.insert(type)
                } else {
                    denied.insert(type)
                }
            case .notDetermined:
                pending.insert(type)
            @unknown default:
                pending.insert(type)
            }
        }

        let status = HealthAccessStatus(required: requiredSampleTypes,
                                        granted: granted,
                                        denied: denied,
                                        notDetermined: pending,
                                        availability: .available)
        logHealthStatus(status)
        return status
    }

    private func shouldIgnoreBackgroundDeliveryError(_ error: Error) -> Bool {
        let message = (error as NSError).localizedDescription
        return message.contains("Missing com.apple.developer.healthkit.background-delivery")
    }

    private func configureObservation(for status: HealthAccessStatus,
                                      resetRevokedAnchors: Bool) async throws {
        await DebugLogBuffer.shared.append("configureObservation availability=\(status.availability) granted=\(status.granted.map { $0.identifier })")
        guard case .available = status.availability else {
            stopAllObservers(resetAnchors: resetRevokedAnchors)
            return
        }

        try await enableBackgroundDelivery(for: status.granted)
        try await startObserversIfNeeded(for: status.granted)
        stopRevokedObservers(keeping: status.granted, resetAnchors: resetRevokedAnchors)
    }

    private func backfillHistoricalSamplesIfNeeded(for status: HealthAccessStatus) async {
        guard case .available = status.availability else {
            await DebugLogBuffer.shared.append("Backfill skipped: health unavailable")
            return
        }
        guard !status.granted.isEmpty else {
            await DebugLogBuffer.shared.append("Backfill skipped: no granted types")
            return
        }

        if hasPerformedInitialBackfill {
            await DebugLogBuffer.shared.append("Backfill skipped: already performed this session")
            return
        }
        hasPerformedInitialBackfill = true

        let endDate = Date()
        let window = analysisWindowDays - 1
        let startDay = calendar.startOfDay(for: endDate)
        guard let startDate = calendar.date(byAdding: .day, value: -window, to: startDay) else {
            await DebugLogBuffer.shared.append("Backfill skipped: could not compute start date")
            return
        }

        let sortedTypes = status.granted.sorted { $0.identifier < $1.identifier }
        for type in sortedTypes {
            await DebugLogBuffer.shared.append("Backfill starting for \(type.identifier)")
            do {
                let samples = try await healthKit.fetchSamples(for: type, startDate: startDate, endDate: endDate)
                let earliest = samples.compactMap(\.startDate).min()
                let latest = samples.compactMap(\.startDate).max()
                await DebugLogBuffer.shared.append("Backfill fetched \(samples.count) samples for \(type.identifier) between \(startDate) and \(endDate); earliest=\(String(describing: earliest)); latest=\(String(describing: latest))")
                guard !samples.isEmpty else {
                    await DebugLogBuffer.shared.append("Backfill skipping \(type.identifier): zero samples fetched")
                    continue
                }
                let touched = try await processBackfillSamples(samples, type: type)
                await DebugLogBuffer.shared.append("Backfill processed \(touched.processedSamples) samples for \(type.identifier) touchedDays=\(touched.days.count)")
            } catch {
                await DebugLogBuffer.shared.append("Backfill failed for \(type.identifier): \(error.localizedDescription)")
            }
        }
    }

    private func processBackfillSamples(_ samples: [HKSample], type: HKSampleType) async throws -> (processedSamples: Int, days: Set<Date>) {
        switch type {
        case let quantityType as HKQuantityType:
            let quantitySamples = samples.compactMap { $0 as? HKQuantitySample }
            await DebugLogBuffer.shared.append("Backfill casting summary for \(quantityType.identifier): quantitySamples=\(quantitySamples.count) raw=\(samples.count)")
            guard !quantitySamples.isEmpty else {
                await DebugLogBuffer.shared.append("Backfill skipped \(quantityType.identifier): no castable HKQuantitySample instances")
                return (0, [])
            }
            // Group by day to avoid huge single calls and to log progress.
            let grouped = Dictionary(grouping: quantitySamples) { calendar.startOfDay(for: $0.startDate) }
            var touched: Set<Date> = []
            var processedCount = 0
            for (day, daySamples) in grouped {
                let days = try await processQuantitySamples(daySamples, type: quantityType)
                touched.formUnion(days)
                processedCount += daySamples.count
                await DebugLogBuffer.shared.append("Backfill day batch \(day) for \(quantityType.identifier): processed=\(daySamples.count) daysTouched=\(days.count)")
            }
            return (processedCount, touched)

        case let categoryType as HKCategoryType:
            let categorySamples = samples.compactMap { $0 as? HKCategorySample }
            await DebugLogBuffer.shared.append("Backfill casting summary for \(categoryType.identifier): categorySamples=\(categorySamples.count) raw=\(samples.count)")
            guard !categorySamples.isEmpty else {
                await DebugLogBuffer.shared.append("Backfill skipped \(categoryType.identifier): no castable HKCategorySample instances")
                return (0, [])
            }
            let grouped = Dictionary(grouping: categorySamples) { calendar.startOfDay(for: $0.startDate) }
            var touched: Set<Date> = []
            var processedCount = 0
            for (day, daySamples) in grouped {
                let days = try await processCategorySamples(daySamples, type: categoryType)
                touched.formUnion(days)
                processedCount += daySamples.count
                await DebugLogBuffer.shared.append("Backfill day batch \(day) for \(categoryType.identifier): processed=\(daySamples.count) daysTouched=\(days.count)")
            }
            return (processedCount, touched)

        default:
            await DebugLogBuffer.shared.append("Backfill skipped unsupported type \(type.identifier)")
            return (0, [])
        }
    }


    private func enableBackgroundDelivery(for grantedTypes: Set<HKSampleType>) async throws {
        guard !grantedTypes.isEmpty else {
            await DebugLogBuffer.shared.append("enableBackgroundDelivery skipped: no granted types")
            return
        }
        do {
            try await healthKit.enableBackgroundDelivery(for: grantedTypes)
            await DebugLogBuffer.shared.append("enableBackgroundDelivery enabled for \(grantedTypes.map { $0.identifier })")
        } catch HealthKitServiceError.backgroundDeliveryFailed(let type, let underlying) {
            if shouldIgnoreBackgroundDeliveryError(underlying) {
#if DEBUG
                print("[PulsumData] Background delivery disabled (missing entitlement) for \(type.identifier).")
#endif
                await DebugLogBuffer.shared.append("enableBackgroundDelivery ignored missing entitlement for \(type.identifier)")
            } else {
                throw HealthKitServiceError.backgroundDeliveryFailed(type: type, underlying: underlying)
            }
        } catch {
            throw error
        }
    }

    private func startObserversIfNeeded(for types: Set<HKSampleType>) async throws {
        guard !types.isEmpty else {
            await DebugLogBuffer.shared.append("startObserversIfNeeded skipped: no granted types")
            return
        }
        for type in types {
            await DebugLogBuffer.shared.append("Starting observer for \(type.identifier)")
            try await observe(sampleType: type)
        }
    }

    private func stopRevokedObservers(keeping granted: Set<HKSampleType>, resetAnchors: Bool) {
        let grantedIdentifiers = Set(granted.map { $0.identifier })
        let identifiers = Array(observers.keys)
        for identifier in identifiers where !grantedIdentifiers.contains(identifier) {
            if let type = sampleTypesByIdentifier[identifier] {
                stopObservation(for: type, resetAnchor: resetAnchors)
            } else {
                observers.removeValue(forKey: identifier)
            }
        }
    }

    private func logHealthStatus(_ status: HealthAccessStatus) {
#if DEBUG
        let grantedIds = status.granted.map(\.identifier).sorted()
        let deniedIds = status.denied.map(\.identifier).sorted()
        let pendingIds = status.notDetermined.map(\.identifier).sorted()
        print("[PulsumDataAgent] Health access status → granted: \(grantedIds), denied: \(deniedIds), pending: \(pendingIds), availability: \(status.availability)")
#endif
        Task { await DebugLogBuffer.shared.append("Health access status → granted: \(status.granted.map(\.identifier)), denied: \(status.denied.map(\.identifier)), pending: \(status.notDetermined.map(\.identifier)), availability: \(status.availability)") }
    }

    private func statusSummary(_ status: HealthAccessStatus) -> String {
        let grantedIds = status.granted.map(\.identifier).sorted().joined(separator: ",")
        let deniedIds = status.denied.map(\.identifier).sorted().joined(separator: ",")
        let pendingIds = status.notDetermined.map(\.identifier).sorted().joined(separator: ",")
        return "granted=[\(grantedIds)] denied=[\(deniedIds)] pending=[\(pendingIds)] availability=\(status.availability)"
    }

    private func stopAllObservers(resetAnchors: Bool) {
        let identifiers = Array(observers.keys)
        for identifier in identifiers {
            if let type = sampleTypesByIdentifier[identifier] {
                stopObservation(for: type, resetAnchor: resetAnchors)
            }
        }
        observers.removeAll()
    }

    private func stopObservation(for type: HKSampleType, resetAnchor: Bool) {
        observers.removeValue(forKey: type.identifier)
        healthKit.stopObserving(sampleType: type, resetAnchor: resetAnchor)
    }

    func latestFeatureVector() async throws -> FeatureVectorSnapshot? {
        let context = self.context
        let result = try await context.perform { () throws -> FeatureComputation? in
            let request = FeatureVector.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: #keyPath(FeatureVector.date), ascending: false)]
            request.fetchLimit = 1
            guard let latest = try context.fetch(request).first else { return nil }
            let bundle = DataAgent.materializeFeatures(from: latest)
            return FeatureComputation(date: latest.date,
                                      featureValues: bundle.values,
                                      imputedFlags: bundle.imputed,
                                      featureVectorObjectID: latest.objectID)
        }

        guard let computation = result else {
            await DebugLogBuffer.shared.append("latestFeatureVector -> none found")
            return nil
        }
        let modelFeatures = WellbeingModeling.normalize(features: computation.featureValues,
                                                        imputedFlags: computation.imputedFlags)
        let snapshot = stateEstimator.currentSnapshot(features: modelFeatures)
        await DebugLogBuffer.shared.append("latestFeatureVector -> date=\(computation.date) wellbeing=\(snapshot.wellbeingScore) features=\(computation.featureValues)")
        return FeatureVectorSnapshot(date: computation.date,
                                     wellbeingScore: snapshot.wellbeingScore,
                                     contributions: snapshot.contributions,
                                     imputedFlags: computation.imputedFlags,
                                     featureVectorObjectID: computation.featureVectorObjectID,
                                     features: computation.featureValues)
    }

    func scoreBreakdown() async throws -> ScoreBreakdown? {
        guard let snapshot = try await latestFeatureVector() else { return nil }

        let context = self.context
        await DebugLogBuffer.shared.append("Computing scoreBreakdown for \(snapshot.date)")

        struct BaselinePayload: Sendable {
            let median: Double?
            let mad: Double?
            let ewma: Double?
            let updatedAt: Date?
        }

        let descriptors = Self.scoreMetricDescriptors
        let coverageByFeature = try await metricCoverage(for: snapshot, descriptors: descriptors)
        let rawAndBaselines = try await context.perform { () throws -> ([String: Double], [String: BaselinePayload]) in
            var rawValues: [String: Double] = [:]
            var baselines: [String: BaselinePayload] = [:]

            let metricsRequest = DailyMetrics.fetchRequest()
            metricsRequest.predicate = NSPredicate(format: "date == %@", snapshot.date as NSDate)
            metricsRequest.fetchLimit = 1
            if let metrics = try context.fetch(metricsRequest).first {
                rawValues["hrv"] = metrics.hrvMedian?.doubleValue
                rawValues["nocthr"] = metrics.nocturnalHRPercentile10?.doubleValue
                rawValues["resthr"] = metrics.restingHR?.doubleValue
                rawValues["sleepDebt"] = metrics.sleepDebt?.doubleValue
                rawValues["rr"] = metrics.respiratoryRate?.doubleValue
                rawValues["steps"] = metrics.steps?.doubleValue
            }

            let baselineKeys = Array(Set(descriptors.compactMap { $0.baselineKey }))
            if !baselineKeys.isEmpty {
                let baselineKeysPredicate = baselineKeys as NSArray
                let baselineRequest = Baseline.fetchRequest()
                baselineRequest.predicate = NSPredicate(format: "metric IN %@", baselineKeysPredicate)
                let baselineObjects = try context.fetch(baselineRequest)
                for baseline in baselineObjects {
                    let key = baseline.metric
                    guard !key.isEmpty else { continue }
                    baselines[key] = BaselinePayload(
                        median: baseline.median?.doubleValue,
                        mad: baseline.mad?.doubleValue,
                        ewma: baseline.ewma?.doubleValue,
                        updatedAt: baseline.updatedAt
                    )
                }
            }

            return (rawValues, baselines)
        }

        let rawValues = rawAndBaselines.0
        let baselineValues = rawAndBaselines.1

        var metrics: [ScoreBreakdown.MetricDetail] = []
        metrics.reserveCapacity(descriptors.count)

        for descriptor in descriptors.sorted(by: { $0.order < $1.order }) {
            let value: Double?
            if let rawKey = descriptor.rawValueKey {
                value = rawValues[rawKey]
            } else {
                value = snapshot.features[descriptor.featureKey]
            }

            let zScore: Double?
            if descriptor.usesZScore {
                zScore = snapshot.features[descriptor.featureKey]
            } else {
                zScore = nil
            }

            let baseline = descriptor.baselineKey.flatMap { baselineValues[$0] }
            let contribution = snapshot.contributions[descriptor.featureKey] ?? 0
            let notes = descriptor.flagMessages(for: snapshot.imputedFlags)

            let detail = ScoreBreakdown.MetricDetail(
                id: descriptor.featureKey,
                name: descriptor.displayName,
                kind: descriptor.kind,
                value: value,
                unit: descriptor.unit,
                zScore: zScore,
                contribution: contribution,
                baselineMedian: baseline?.median,
                baselineEwma: baseline?.ewma,
                baselineMad: baseline?.mad,
                rollingWindowDays: descriptor.rollingWindowDays,
                explanation: descriptor.explanation,
                notes: notes,
                coverage: coverageByFeature[descriptor.featureKey]
            )

            metrics.append(detail)
        }

        let generalNotes = Self.generalFlagMessages(for: snapshot.imputedFlags)

        return ScoreBreakdown(date: snapshot.date,
                              wellbeingScore: snapshot.wellbeingScore,
                              metrics: metrics,
                              generalNotes: generalNotes)
    }

    private func metricCoverage(for snapshot: FeatureVectorSnapshot,
                                descriptors: [ScoreMetricDescriptor]) async throws -> [String: ScoreBreakdown.MetricDetail.Coverage] {
        let calendar = self.calendar
        let context = self.context

        return try await context.perform {
            var coverage: [String: ScoreBreakdown.MetricDetail.Coverage] = [:]
            let endDate = calendar.startOfDay(for: snapshot.date)

            var windowStarts: [String: Date] = [:]
            for descriptor in descriptors {
                guard let window = descriptor.rollingWindowDays else { continue }
                let start = calendar.date(byAdding: .day, value: -(window - 1), to: endDate) ?? endDate
                windowStarts[descriptor.featureKey] = start
            }

            guard let earliest = windowStarts.values.min() else { return [:] }

            let request = DailyMetrics.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", earliest as NSDate, endDate as NSDate)
            let metrics = try context.fetch(request)

            var counts: [String: (days: Set<Date>, samples: Int)] = [:]

            for metric in metrics {
                let flags = DataAgent.decodeFlags(from: metric)
                let day = calendar.startOfDay(for: metric.date)

                let sampleCounts: [String: Int] = [
                    "z_hrv": flags.hrvSamples.count,
                    "z_nocthr": flags.heartRateSamples.count,
                    "z_resthr": flags.heartRateSamples.filter { $0.context == .resting }.count,
                    "z_sleepDebt": flags.sleepSegments.count,
                    "z_rr": flags.respiratorySamples.count,
                    "z_steps": flags.stepBuckets.count
                ]

                for (featureKey, count) in sampleCounts {
                    guard let windowStart = windowStarts[featureKey] else { continue }
                    guard day >= windowStart else { continue }
                    guard count > 0 else { continue }

                    var entry = counts[featureKey] ?? (Set<Date>(), 0)
                    entry.days.insert(day)
                    entry.samples += count
                    counts[featureKey] = entry
                }
            }

            for (featureKey, _) in windowStarts {
                if let entry = counts[featureKey] {
                    coverage[featureKey] = ScoreBreakdown.MetricDetail.Coverage(daysWithSamples: entry.days.count,
                                                                                sampleCount: entry.samples)
                } else {
                    // Explicitly surface zero coverage when no samples are available
                    coverage[featureKey] = ScoreBreakdown.MetricDetail.Coverage(daysWithSamples: 0, sampleCount: 0)
                }
            }

            return coverage
        }
    }

    func reprocessDay(date: Date) async throws {
        let day = calendar.startOfDay(for: date)
        try await reprocessDayInternal(day)
        notifySnapshotUpdate(for: day)
    }

    func recordSubjectiveInputs(date: Date, stress: Double, energy: Double, sleepQuality: Double) async throws {
        let targetDate = calendar.startOfDay(for: date)
        let context = self.context
        await DebugLogBuffer.shared.append("Recording subjective inputs for \(targetDate)")
        try await context.perform {
            let request = FeatureVector.fetchRequest()
            request.predicate = NSPredicate(format: "date == %@", targetDate as NSDate)
            request.fetchLimit = 1
            let vector = try context.fetch(request).first ?? FeatureVector(context: context)
            vector.date = targetDate
            vector.subjectiveStress = NSNumber(value: stress)
            vector.subjectiveEnergy = NSNumber(value: energy)
            vector.subjectiveSleepQuality = NSNumber(value: sleepQuality)
            try context.save()
        }
        try await reprocessDayInternal(targetDate)
        notifySnapshotUpdate(for: targetDate)
    }

    // MARK: - Observation

    private func observe(sampleType: HKSampleType) async throws {
        let identifier = sampleType.identifier
        guard observers[identifier] == nil else { return }
        let token = try healthKit.observeSampleType(sampleType, predicate: nil) { result in
            switch result {
            case let .success(update):
                Task { await self.handle(update: update, sampleType: sampleType) }
            case let .failure(error):
#if DEBUG
                print("HealthKit observe error: \(error)")
#endif
                Task { await DebugLogBuffer.shared.append("HealthKit observe error for \(sampleType.identifier): \(error.localizedDescription)") }
            }
        }
        observers[identifier] = token
    }

    private func handle(update: HealthKitService.AnchoredUpdate, sampleType: HKSampleType) async {
        do {
            var touchedDays: Set<Date> = []
            switch sampleType {
            case let quantityType as HKQuantityType:
                let days = try await processQuantitySamples(update.samples.compactMap { $0 as? HKQuantitySample },
                                                            type: quantityType)
                await DebugLogBuffer.shared.append("Processed quantity samples for \(quantityType.identifier) count=\(update.samples.count) touchedDays=\(days.count)")
                touchedDays.formUnion(days)
            case let categoryType as HKCategoryType:
                let days = try await processCategorySamples(update.samples.compactMap { $0 as? HKCategorySample },
                                                            type: categoryType)
                await DebugLogBuffer.shared.append("Processed category samples for \(categoryType.identifier) count=\(update.samples.count) touchedDays=\(days.count)")
                touchedDays.formUnion(days)
            default:
                break
            }
            let deletedDays = try await handleDeletedSamples(update.deletedSamples)
            touchedDays.formUnion(deletedDays)

            if touchedDays.isEmpty {
                let today = calendar.startOfDay(for: Date())
                notifySnapshotUpdate(for: today)
            } else {
                for day in touchedDays {
                    notifySnapshotUpdate(for: day)
                }
            }
        } catch {
#if DEBUG
            print("DataAgent processing error: \(error)")
#endif
        }
    }

    // MARK: - Sample Processing

    private func processQuantitySamples(_ samples: [HKQuantitySample],
                                        type: HKQuantityType) async throws -> Set<Date> {
        guard !samples.isEmpty else { return [] }

        let calendar = self.calendar
        let context = self.context

        let dirtyDays = try await context.perform { () throws -> Set<Date> in
            var dirtyDays: Set<Date> = []
            for sample in samples {
                let day = calendar.startOfDay(for: sample.startDate)
                let metrics = DataAgent.fetchOrCreateDailyMetrics(in: context, date: day)
                DataAgent.mutateFlags(metrics) { flags in
                    flags.append(quantitySample: sample, type: type)
                }
                dirtyDays.insert(day)
            }

            if context.hasChanges {
                try context.save()
            }
            return dirtyDays
        }

        for day in dirtyDays {
            try await reprocessDayInternal(day)
        }

        return dirtyDays
    }

    private func processCategorySamples(_ samples: [HKCategorySample],
                                        type: HKCategoryType) async throws -> Set<Date> {
        guard type.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue else { return [] }
        guard !samples.isEmpty else { return [] }

        let calendar = self.calendar
        let context = self.context

        let dirtyDays = try await context.perform { () throws -> Set<Date> in
            var dirtyDays: Set<Date> = []
            for sample in samples {
                let day = calendar.startOfDay(for: sample.startDate)
                let metrics = DataAgent.fetchOrCreateDailyMetrics(in: context, date: day)
                DataAgent.mutateFlags(metrics) { flags in
                    flags.append(sleepSample: sample)
                }
                dirtyDays.insert(day)
            }
            if context.hasChanges {
                try context.save()
            }
            return dirtyDays
        }

        for day in dirtyDays {
            try await reprocessDayInternal(day)
        }

        return dirtyDays
    }

    private func handleDeletedSamples(_ deletedObjects: [HKDeletedObject]) async throws -> Set<Date> {
        guard !deletedObjects.isEmpty else { return [] }

        let identifiers = Set(deletedObjects.map { $0.uuid })
        let context = self.context
        let dirtyDays = try await context.perform { () throws -> Set<Date> in
            let request = DailyMetrics.fetchRequest()
            let metrics = try context.fetch(request)
            var dirty: Set<Date> = []
            for metric in metrics {
                var flags = DataAgent.decodeFlags(from: metric)
                if flags.pruneDeletedSamples(identifiers) {
                    metric.flags = DataAgent.encodeFlags(flags)
                    dirty.insert(metric.date)
                }
            }
            if context.hasChanges {
                try context.save()
            }
            return dirty
        }

        for day in dirtyDays {
            try await reprocessDayInternal(day)
        }

        return dirtyDays
    }

    // MARK: - Daily Computation

    private func reprocessDayInternal(_ day: Date) async throws {
        let context = self.context
        let calendar = self.calendar
        let sedentaryThreshold = sedentaryThresholdStepsPerHour
        let sedentaryDuration = sedentaryMinimumDuration
        let sleepDebtWindowDays = self.sleepDebtWindowDays
        let analysisWindowDays = self.analysisWindowDays

        let computation = try await context.perform { () throws -> FeatureComputation in
            let metrics = try DataAgent.fetchDailyMetrics(in: context, date: day)
            var flags = DataAgent.decodeFlags(from: metrics)
            let summary = try DataAgent.computeSummary(for: metrics,
                                                       flags: flags,
                                                       context: context,
                                                       calendar: calendar,
                                                       sedentaryThreshold: sedentaryThreshold,
                                                       sedentaryMinimumDuration: sedentaryDuration,
                                                       sleepDebtWindowDays: sleepDebtWindowDays,
                                                       analysisWindowDays: analysisWindowDays)
            flags = summary.updatedFlags

            metrics.hrvMedian = summary.hrv.map(NSNumber.init(value:))
            metrics.nocturnalHRPercentile10 = summary.nocturnalHR.map(NSNumber.init(value:))
            metrics.restingHR = summary.restingHR.map(NSNumber.init(value:))
            metrics.totalSleepTime = summary.totalSleepSeconds.map(NSNumber.init(value:))
            metrics.sleepDebt = summary.sleepDebtHours.map(NSNumber.init(value:))
            metrics.respiratoryRate = summary.respiratoryRate.map(NSNumber.init(value:))
            metrics.steps = summary.stepCount.map(NSNumber.init(value:))
            metrics.flags = DataAgent.encodeFlags(flags)

            let baselines = try DataAgent.updateBaselines(in: context,
                                                          summary: summary,
                                                          referenceDate: day,
                                                          windowDays: analysisWindowDays)
            let bundle = try DataAgent.buildFeatureBundle(for: metrics,
                                                          summary: summary,
                                                          baselines: baselines,
                                                          context: context)
            let featureVector = try DataAgent.fetchOrCreateFeatureVector(in: context, date: day)
            DataAgent.apply(features: bundle.values, to: featureVector)

            if context.hasChanges {
                try context.save()
            }

            return FeatureComputation(date: day,
                                      featureValues: bundle.values,
                                      imputedFlags: bundle.imputed,
                                      featureVectorObjectID: featureVector.objectID)
        }

        let modelFeatures = WellbeingModeling.normalize(features: computation.featureValues,
                                                        imputedFlags: computation.imputedFlags)
        let target = WellbeingModeling.target(for: modelFeatures)
        let snapshot = stateEstimator.update(features: modelFeatures, target: target)
        await DebugLogBuffer.shared.append("Reprocessed day \(day) → wellbeing=\(snapshot.wellbeingScore) features=\(computation.featureValues)")
        persistEstimatorState(from: snapshot)

        try await context.perform {
            guard let vector = try? context.existingObject(with: computation.featureVectorObjectID) as? FeatureVector else { return }
            vector.imputedFlags = DataAgent.encodeFeatureMetadata(imputed: computation.imputedFlags,
                                                                  contributions: snapshot.contributions,
                                                                  wellbeing: snapshot.wellbeingScore)
            if context.hasChanges {
                try context.save()
            }
        }
    }

    private func persistEstimatorState(from snapshot: StateEstimatorSnapshot) {
        let state = StateEstimatorState(version: EstimatorStateStore.schemaVersion,
                                        weights: snapshot.weights,
                                        bias: snapshot.bias)
        estimatorStore.saveState(state)
    }

    private static func computeSummary(for metrics: DailyMetrics,
                                       flags: DailyFlags,
                                       context: NSManagedObjectContext,
                                       calendar: Calendar,
                                       sedentaryThreshold: Double,
                                       sedentaryMinimumDuration: TimeInterval,
                                       sleepDebtWindowDays: Int,
                                       analysisWindowDays: Int) throws -> DailySummary {
        var imputed: [String: Bool] = [:]

        let sleepIntervals = flags.sleepIntervals()
        let sedentaryIntervals = flags.sedentaryIntervals(thresholdStepsPerHour: sedentaryThreshold,
                                                          minimumDuration: sedentaryMinimumDuration,
                                                          excluding: sleepIntervals)
        if sedentaryIntervals.isEmpty {
            imputed["sedentary_missing"] = true
        }

        let previousHRV = try previousMetricValue(in: context,
                                                  keyPath: #keyPath(DailyMetrics.hrvMedian),
                                                  before: metrics.date)
        let hrvValue = flags.medianHRV(in: sleepIntervals,
                                       fallback: sedentaryIntervals,
                                       previous: previousHRV,
                                       imputed: &imputed)

        let previousNocturnal = try previousMetricValue(in: context,
                                                        keyPath: #keyPath(DailyMetrics.nocturnalHRPercentile10),
                                                        before: metrics.date)
        let nocturnalHR = flags.nocturnalHeartRate(in: sleepIntervals,
                                                   fallback: sedentaryIntervals,
                                                   previous: previousNocturnal,
                                                   imputed: &imputed)

        let previousResting = try previousMetricValue(in: context,
                                                      keyPath: #keyPath(DailyMetrics.restingHR),
                                                      before: metrics.date)
        let restingHR = flags.restingHeartRate(fallback: sedentaryIntervals,
                                               previous: previousResting,
                                               imputed: &imputed)

        let sleepSeconds = flags.sleepDurations()
        let actualSleepHours = sleepSeconds / 3600
        if sleepSeconds < 3 * 3600 {
            imputed["sleep_low_confidence"] = true
        }
        let sleepNeed = try personalizedSleepNeedHours(context: context,
                                                       referenceDate: metrics.date,
                                                       latestActualHours: actualSleepHours,
                                                       windowDays: analysisWindowDays)
        let sleepDebt = try sleepDebtHours(context: context,
                                           personalNeed: sleepNeed,
                                           currentHours: actualSleepHours,
                                           referenceDate: metrics.date,
                                           windowDays: sleepDebtWindowDays,
                                           calendar: calendar)

        let respiratoryRate = flags.averageRespiratoryRate(in: sleepIntervals)
        if respiratoryRate == nil {
            imputed["rr_missing"] = true
        }
        let stepCount = flags.totalSteps()
        if stepCount == nil {
            imputed["steps_missing"] = true
        } else if (stepCount ?? 0) < 500 {
            imputed["steps_low_confidence"] = true
        }

        return DailySummary(date: metrics.date,
                            hrv: hrvValue,
                            nocturnalHR: nocturnalHR,
                            restingHR: restingHR,
                            totalSleepSeconds: sleepSeconds,
                            sleepNeedHours: sleepNeed,
                            sleepDebtHours: sleepDebt,
                            respiratoryRate: respiratoryRate,
                            stepCount: stepCount,
                            updatedFlags: flags,
                            imputed: imputed)
    }

    private static func buildFeatureBundle(for metrics: DailyMetrics,
                                           summary: DailySummary,
                                           baselines: [String: BaselineMath.RobustStats],
                                           context: NSManagedObjectContext) throws -> FeatureBundle {
        var values: [String: Double] = [:]

        if let hrv = summary.hrv, let stats = baselines["hrv"] {
            values["z_hrv"] = BaselineMath.zScore(value: hrv, stats: stats)
        }
        if let nocturnal = summary.nocturnalHR, let stats = baselines["nocthr"] {
            values["z_nocthr"] = BaselineMath.zScore(value: nocturnal, stats: stats)
        }
        if let resting = summary.restingHR, let stats = baselines["resthr"] {
            values["z_resthr"] = BaselineMath.zScore(value: resting, stats: stats)
        }
        if let debt = summary.sleepDebtHours, let stats = baselines["sleepDebt"] {
            values["z_sleepDebt"] = BaselineMath.zScore(value: debt, stats: stats)
        }
        if let resp = summary.respiratoryRate, let stats = baselines["rr"] {
            values["z_rr"] = BaselineMath.zScore(value: resp, stats: stats)
        }
        if let steps = summary.stepCount, let stats = baselines["steps"] {
            values["z_steps"] = BaselineMath.zScore(value: steps, stats: stats)
        }

        let vector = try fetchOrCreateFeatureVector(in: context, date: summary.date)
        if let stress = vector.subjectiveStress?.doubleValue { values["subj_stress"] = stress }
        if let energy = vector.subjectiveEnergy?.doubleValue { values["subj_energy"] = energy }
        if let sleepQuality = vector.subjectiveSleepQuality?.doubleValue { values["subj_sleepQuality"] = sleepQuality }
        if let sentiment = vector.sentiment?.doubleValue { values["sentiment"] = sentiment }

        for key in FeatureBundle.requiredKeys where values[key] == nil {
            values[key] = 0
        }

        return FeatureBundle(values: values, imputed: summary.imputed)
    }

    private static func apply(features: [String: Double], to vector: FeatureVector) {
        vector.zHrv = NSNumber(value: features["z_hrv"] ?? 0)
        vector.zNocturnalHR = NSNumber(value: features["z_nocthr"] ?? 0)
        vector.zRestingHR = NSNumber(value: features["z_resthr"] ?? 0)
        vector.zSleepDebt = NSNumber(value: features["z_sleepDebt"] ?? 0)
        vector.zRespiratoryRate = NSNumber(value: features["z_rr"] ?? 0)
        vector.zSteps = NSNumber(value: features["z_steps"] ?? 0)
        vector.subjectiveStress = NSNumber(value: features["subj_stress"] ?? 0)
        vector.subjectiveEnergy = NSNumber(value: features["subj_energy"] ?? 0)
        vector.subjectiveSleepQuality = NSNumber(value: features["subj_sleepQuality"] ?? 0)
        vector.sentiment = NSNumber(value: features["sentiment"] ?? 0)
    }

    // MARK: - Persistence Helpers

    private static func fetchDailyMetrics(in context: NSManagedObjectContext, date: Date) throws -> DailyMetrics {
        let request = DailyMetrics.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", date as NSDate)
        request.fetchLimit = 1
        if let metrics = try context.fetch(request).first {
            return metrics
        }
        let metrics = DailyMetrics(context: context)
        metrics.date = date
        metrics.flags = Self.encodeFlags(DailyFlags())
        return metrics
    }

    private static func fetchOrCreateDailyMetrics(in context: NSManagedObjectContext, date: Date) -> DailyMetrics {
        let request = DailyMetrics.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", date as NSDate)
        request.fetchLimit = 1
        if let metrics = try? context.fetch(request).first {
            return metrics
        }
        let metrics = DailyMetrics(context: context)
        metrics.date = date
        metrics.flags = Self.encodeFlags(DailyFlags())
        return metrics
    }

    private static func fetchOrCreateFeatureVector(in context: NSManagedObjectContext, date: Date) throws -> FeatureVector {
        let request = FeatureVector.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", date as NSDate)
        request.fetchLimit = 1
        if let vector = try context.fetch(request).first {
            return vector
        }
        let vector = FeatureVector(context: context)
        vector.date = date
        return vector
    }

    private static func mutateFlags(_ metrics: DailyMetrics, mutate: (inout DailyFlags) -> Void) {
        var flags = Self.decodeFlags(from: metrics)
        mutate(&flags)
        metrics.flags = Self.encodeFlags(flags)
    }

    private static func decodeFlags(from metrics: DailyMetrics) -> DailyFlags {
        guard let payload = metrics.flags, let data = payload.data(using: .utf8) else { return DailyFlags() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(DailyFlags.self, from: data)) ?? DailyFlags()
    }

    private static func encodeFlags(_ flags: DailyFlags) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(flags) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private static func encodeFeatureMetadata(imputed: [String: Bool], contributions: [String: Double], wellbeing: Double) -> String? {
        let payload: [String: Any] = [
            "imputed": imputed,
            "contributions": contributions,
            "wellbeing": wellbeing
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func notifySnapshotUpdate(for date: Date) {
        notificationCenter.post(name: .pulsumScoresUpdated,
                                object: nil,
                                userInfo: [AgentNotificationKeys.date: date])
    }

#if DEBUG
    func _testPublishSnapshotUpdate(for date: Date) {
        notifySnapshotUpdate(for: date)
    }
#endif

    private static func materializeFeatures(from vector: FeatureVector) -> FeatureBundle {
        var imputed: [String: Bool] = [:]
        if let payload = vector.imputedFlags,
           let data = payload.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let map = json["imputed"] as? [String: Bool] {
            imputed = map
        }

        let values: [String: Double] = [
            "z_hrv": vector.zHrv?.doubleValue ?? 0,
            "z_nocthr": vector.zNocturnalHR?.doubleValue ?? 0,
            "z_resthr": vector.zRestingHR?.doubleValue ?? 0,
            "z_sleepDebt": vector.zSleepDebt?.doubleValue ?? 0,
            "z_rr": vector.zRespiratoryRate?.doubleValue ?? 0,
            "z_steps": vector.zSteps?.doubleValue ?? 0,
            "subj_stress": vector.subjectiveStress?.doubleValue ?? 0,
            "subj_energy": vector.subjectiveEnergy?.doubleValue ?? 0,
            "subj_sleepQuality": vector.subjectiveSleepQuality?.doubleValue ?? 0,
            "sentiment": vector.sentiment?.doubleValue ?? 0
        ]
        return FeatureBundle(values: values, imputed: imputed)
    }

    private static func previousMetricValue(in context: NSManagedObjectContext,
                                            keyPath: String,
                                            before date: Date) throws -> Double? {
        let request = DailyMetrics.fetchRequest()
        request.predicate = NSPredicate(format: "date < %@", date as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(DailyMetrics.date), ascending: false)]
        request.fetchLimit = 1
        let metrics = try context.fetch(request)
        guard let number = (metrics.first?.value(forKey: keyPath) as? NSNumber) else { return nil }
        return number.doubleValue
    }

    private static func updateBaselines(in context: NSManagedObjectContext,
                                        summary: DailySummary,
                                        referenceDate: Date,
                                        windowDays: Int) throws -> [String: BaselineMath.RobustStats] {
        let stats = try computeBaselines(in: context, referenceDate: referenceDate, windowDays: windowDays)
        let latestValues: [String: Double?] = [
            "hrv": summary.hrv,
            "nocthr": summary.nocturnalHR,
            "resthr": summary.restingHR,
            "sleepDebt": summary.sleepDebtHours,
            "rr": summary.respiratoryRate,
            "steps": summary.stepCount
        ]

        for (metricKey, stat) in stats {
            let baseline = try fetchBaseline(in: context, metric: metricKey)
            baseline.metric = metricKey
            baseline.windowDays = Int16(windowDays)
            baseline.median = NSNumber(value: stat.median)
            baseline.mad = NSNumber(value: stat.mad)
            if let latest = latestValues[metricKey] ?? nil {
                let previous = baseline.ewma?.doubleValue
                let ewma = BaselineMath.ewma(previous: previous, newValue: latest)
                baseline.ewma = NSNumber(value: ewma)
            }
            baseline.updatedAt = referenceDate
        }

        return stats
    }

    private static func computeBaselines(in context: NSManagedObjectContext,
                                         referenceDate: Date,
                                         windowDays: Int) throws -> [String: BaselineMath.RobustStats] {
        let request = DailyMetrics.fetchRequest()
        request.predicate = NSPredicate(format: "date <= %@", referenceDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(DailyMetrics.date), ascending: false)]
        request.fetchLimit = windowDays
        let metrics = try context.fetch(request)

        func stats(_ keyPath: KeyPath<DailyMetrics, NSNumber?>) -> BaselineMath.RobustStats? {
            let values = metrics.compactMap { $0[keyPath: keyPath]?.doubleValue }
            return BaselineMath.robustStats(for: values)
        }

        var result: [String: BaselineMath.RobustStats] = [:]
        if let stats = stats(\DailyMetrics.hrvMedian) { result["hrv"] = stats }
        if let stats = stats(\DailyMetrics.nocturnalHRPercentile10) { result["nocthr"] = stats }
        if let stats = stats(\DailyMetrics.restingHR) { result["resthr"] = stats }
        if let stats = stats(\DailyMetrics.sleepDebt) { result["sleepDebt"] = stats }
        if let stats = stats(\DailyMetrics.respiratoryRate) { result["rr"] = stats }
        if let stats = stats(\DailyMetrics.steps) { result["steps"] = stats }
        return result
    }

    private static func fetchBaseline(in context: NSManagedObjectContext, metric: String) throws -> Baseline {
        let request = Baseline.fetchRequest()
        request.predicate = NSPredicate(format: "metric == %@", metric)
        request.fetchLimit = 1
        if let baseline = try context.fetch(request).first {
            return baseline
        }
        let baseline = Baseline(context: context)
        baseline.metric = metric
        baseline.windowDays = 0
        return baseline
    }

    private static func personalizedSleepNeedHours(context: NSManagedObjectContext,
                                                   referenceDate: Date,
                                                   latestActualHours: Double,
                                                   windowDays: Int) throws -> Double {
        let request = DailyMetrics.fetchRequest()
        request.predicate = NSPredicate(format: "date <= %@", referenceDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(DailyMetrics.date), ascending: false)]
        request.fetchLimit = windowDays
        let metrics = try context.fetch(request)
        let historical = metrics.compactMap { $0.totalSleepTime?.doubleValue }.map { $0 / 3600 }
        let defaultNeed = 7.5
        guard historical.count >= 7 else { return defaultNeed }
        let mean = historical.reduce(0, +) / Double(historical.count)
        return min(max(mean, defaultNeed - 0.75), defaultNeed + 0.75)
    }

    private static func sleepDebtHours(context: NSManagedObjectContext,
                                       personalNeed: Double,
                                       currentHours: Double,
                                       referenceDate: Date,
                                       windowDays: Int,
                                       calendar: Calendar) throws -> Double {
        let start = calendar.date(byAdding: .day, value: -(windowDays - 1), to: referenceDate) ?? referenceDate
        let request = DailyMetrics.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", start as NSDate, referenceDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(DailyMetrics.date), ascending: true)]
        let metrics = try context.fetch(request)
        var window = metrics.map { ($0.totalSleepTime?.doubleValue ?? 0) / 3600 }
        if metrics.last?.date != referenceDate {
            window.append(currentHours)
        }
        return window.map { max(0, personalNeed - $0) }.reduce(0, +)
    }

    private struct ScoreMetricDescriptor {
        let featureKey: String
        let displayName: String
        let kind: ScoreBreakdown.MetricDetail.Kind
        let order: Int
        let unit: String?
        let usesZScore: Bool
        let rawValueKey: String?
        let baselineKey: String?
        let rollingWindowDays: Int?
        let explanation: String
        let flagKeys: [String]

        func flagMessages(for flags: [String: Bool]) -> [String] {
            flagKeys.compactMap { key in
                guard flags[key] == true else { return nil }
                return DataAgent.flagMessages[key]
            }
        }
    }

    private static let scoreMetricDescriptors: [ScoreMetricDescriptor] = [
        ScoreMetricDescriptor(
            featureKey: "z_hrv",
            displayName: "Heart Rate Variability",
            kind: .objective,
            order: 0,
            unit: "ms",
            usesZScore: true,
            rawValueKey: "hrv",
            baselineKey: "hrv",
            rollingWindowDays: 30,
            explanation: "Median overnight SDNN. Higher values mean the autonomic nervous system is more recovered.",
            flagKeys: ["hrv", "sedentary_missing"]
        ),
        ScoreMetricDescriptor(
            featureKey: "z_nocthr",
            displayName: "Nocturnal Heart Rate",
            kind: .objective,
            order: 1,
            unit: "bpm",
            usesZScore: true,
            rawValueKey: "nocthr",
            baselineKey: "nocthr",
            rollingWindowDays: 30,
            explanation: "10th percentile of heart rate while asleep. Lower values indicate better overnight recovery.",
            flagKeys: ["nocturnalHR", "sedentary_missing"]
        ),
        ScoreMetricDescriptor(
            featureKey: "z_resthr",
            displayName: "Resting Heart Rate",
            kind: .objective,
            order: 2,
            unit: "bpm",
            usesZScore: true,
            rawValueKey: "resthr",
            baselineKey: "resthr",
            rollingWindowDays: 30,
            explanation: "Latest resting heart rate sample. Lower relative to baseline typically reflects parasympathetic dominance.",
            flagKeys: ["restingHR", "sedentary_missing"]
        ),
        ScoreMetricDescriptor(
            featureKey: "z_sleepDebt",
            displayName: "Sleep Debt",
            kind: .objective,
            order: 3,
            unit: "h",
            usesZScore: true,
            rawValueKey: "sleepDebt",
            baselineKey: "sleepDebt",
            rollingWindowDays: 7,
            explanation: "Cumulative sleep debt over the past 7 days vs your personalized sleep need.",
            flagKeys: ["sleep_low_confidence"]
        ),
        ScoreMetricDescriptor(
            featureKey: "z_rr",
            displayName: "Respiratory Rate",
            kind: .objective,
            order: 4,
            unit: "breaths/min",
            usesZScore: true,
            rawValueKey: "rr",
            baselineKey: "rr",
            rollingWindowDays: 30,
            explanation: "Average sleeping respiratory rate. Stable values indicate steady recovery.",
            flagKeys: ["rr_missing"]
        ),
        ScoreMetricDescriptor(
            featureKey: "z_steps",
            displayName: "Steps",
            kind: .objective,
            order: 5,
            unit: "steps",
            usesZScore: true,
            rawValueKey: "steps",
            baselineKey: "steps",
            rollingWindowDays: 30,
            explanation: "Total steps captured today relative to your rolling baseline.",
            flagKeys: ["steps_missing", "steps_low_confidence"]
        ),
        ScoreMetricDescriptor(
            featureKey: "subj_stress",
            displayName: "Stress",
            kind: .subjective,
            order: 6,
            unit: "(1-7)",
            usesZScore: false,
            rawValueKey: nil,
            baselineKey: nil,
            rollingWindowDays: nil,
            explanation: "Self-reported stress level captured in today's pulse check.",
            flagKeys: []
        ),
        ScoreMetricDescriptor(
            featureKey: "subj_energy",
            displayName: "Energy",
            kind: .subjective,
            order: 7,
            unit: "(1-7)",
            usesZScore: false,
            rawValueKey: nil,
            baselineKey: nil,
            rollingWindowDays: nil,
            explanation: "Self-reported energy level from today's pulse check.",
            flagKeys: []
        ),
        ScoreMetricDescriptor(
            featureKey: "subj_sleepQuality",
            displayName: "Sleep Quality",
            kind: .subjective,
            order: 8,
            unit: "(1-7)",
            usesZScore: false,
            rawValueKey: nil,
            baselineKey: nil,
            rollingWindowDays: nil,
            explanation: "Perceived sleep quality for the prior night.",
            flagKeys: []
        ),
        ScoreMetricDescriptor(
            featureKey: "sentiment",
            displayName: "Journal Sentiment",
            kind: .sentiment,
            order: 9,
            unit: nil,
            usesZScore: false,
            rawValueKey: nil,
            baselineKey: nil,
            rollingWindowDays: nil,
            explanation: "On-device sentiment score from your latest journal entry (negative to positive).",
            flagKeys: []
        )
    ]

    private static let flagMessages: [String: String] = [
        "hrv": "HRV carried forward from a previous day because no fresh overnight samples were available.",
        "sedentary_missing": "No restful sedentary window detected today; fallbacks were used for recovery metrics.",
        "nocturnalHR": "No nocturnal heart rate samples during sleep; carried forward the last reliable value.",
        "restingHR": "Resting heart rate sample missing; reused the most recent reliable value.",
        "rr_missing": "Sleeping respiratory rate missing, so this signal is omitted today.",
        "steps_missing": "Step data unavailable; activity impact excluded from today's score.",
        "steps_low_confidence": "Very low step count (<500) flagged as low confidence.",
        "sleep_low_confidence": "Less than 3 hours of sleep recorded; sleep-related calculations are low confidence."
    ]

    private static func generalFlagMessages(for flags: [String: Bool]) -> [String] {
        let handledKeys = Set(scoreMetricDescriptors.flatMap { $0.flagKeys })
        return flags.compactMap { key, value in
            guard value, !handledKeys.contains(key) else { return nil }
            return flagMessages[key]
        }
    }
#if DEBUG
    func _testProcessQuantitySamples(_ samples: [HKQuantitySample], type: HKQuantityType) async throws {
        try await processQuantitySamples(samples, type: type)
    }

    func _testProcessCategorySamples(_ samples: [HKCategorySample], type: HKCategoryType) async throws {
        try await processCategorySamples(samples, type: type)
    }

    func _testReprocess(day: Date) async throws {
        try await reprocessDayInternal(day)
    }

    @discardableResult
    func _testUpdateEstimator(features: [String: Double], imputed: [String: Bool] = [:]) -> StateEstimatorSnapshot {
        let normalized = WellbeingModeling.normalize(features: features, imputedFlags: imputed)
        let target = WellbeingModeling.target(for: normalized)
        let snapshot = stateEstimator.update(features: normalized, target: target)
        persistEstimatorState(from: snapshot)
        return snapshot
    }

    func _testEstimatorState() -> StateEstimatorState {
        stateEstimator.persistedState(version: EstimatorStateStore.schemaVersion)
    }
#endif
}

enum WellbeingModeling {
    static let targetWeights: [String: Double] = [
        "z_hrv": 0.55,
        "z_nocthr": -0.4,
        "z_resthr": -0.35,
        "z_sleepDebt": -0.65,
        "z_steps": 0.32,
        "z_rr": -0.1,
        "subj_stress": -0.4,
        "subj_energy": 0.45,
        "subj_sleepQuality": 0.3,
        "sentiment": 0.22
    ]

    static func normalize(features: [String: Double], imputedFlags: [String: Bool]) -> [String: Double] {
        var normalized: [String: Double] = [:]
        for key in FeatureBundle.requiredKeys {
            let raw = features[key] ?? 0
            normalized[key] = normalizedValue(for: key, value: raw, imputedFlags: imputedFlags)
        }
        return normalized
    }

    static func target(for normalizedFeatures: [String: Double]) -> Double {
        var target = 0.0
        for (feature, weight) in targetWeights {
            target += weight * (normalizedFeatures[feature] ?? 0)
        }
        return clamp(target, limit: 2.5)
    }

    private static func normalizedValue(for key: String, value: Double, imputedFlags: [String: Bool]) -> Double {
        let adjusted = adjustForImputation(key: key, value: value, imputedFlags: imputedFlags)
        switch key {
        case let feature where feature.hasPrefix("z_"):
            return clamp(adjusted, limit: 3)
        case "subj_stress", "subj_energy", "subj_sleepQuality":
            let centered = (adjusted - 4.0) / 3.0
            return clamp(centered, limit: 1)
        case "sentiment":
            return clamp(adjusted, limit: 1)
        default:
            return adjusted
        }
    }

    private static func adjustForImputation(key: String, value: Double, imputedFlags: [String: Bool]) -> Double {
        var adjusted = value

        switch key {
        case "z_hrv", "z_nocthr", "z_resthr":
            if imputedFlags["sedentary_missing"] == true {
                adjusted *= 0.5
            }
        case "z_sleepDebt":
            if imputedFlags["sleep_low_confidence"] == true {
                adjusted = 0
            }
        case "z_rr":
            if imputedFlags["rr_missing"] == true {
                adjusted = 0
            }
        case "z_steps":
            if imputedFlags["steps_missing"] == true {
                adjusted = 0
            } else if imputedFlags["steps_low_confidence"] == true {
                adjusted *= 0.5
            }
        default:
            break
        }

        let missingKey = key.replacingOccurrences(of: "z_", with: "") + "_missing"
        if imputedFlags[missingKey] == true {
            adjusted = 0
        }

        return adjusted
    }

    private static func clamp(_ value: Double, limit: Double) -> Double {
        min(max(value, -limit), limit)
    }
}

// MARK: - Supporting Types

private struct FeatureBundle {
    static let requiredKeys: Set<String> = [
        "z_hrv",
        "z_nocthr",
        "z_resthr",
        "z_sleepDebt",
        "z_rr",
        "z_steps",
        "subj_stress",
        "subj_energy",
        "subj_sleepQuality",
        "sentiment"
    ]

    var values: [String: Double]
    var imputed: [String: Bool]
}

private struct FeatureComputation: Sendable {
    let date: Date
    let featureValues: [String: Double]
    let imputedFlags: [String: Bool]
    let featureVectorObjectID: NSManagedObjectID
}

private struct DailySummary {
    let date: Date
    let hrv: Double?
    let nocturnalHR: Double?
    let restingHR: Double?
    let totalSleepSeconds: Double?
    let sleepNeedHours: Double
    let sleepDebtHours: Double?
    let respiratoryRate: Double?
    let stepCount: Double?
    let updatedFlags: DailyFlags
    let imputed: [String: Bool]
}

private struct DailyFlags: Codable {
    var hrvSamples: [HRVSample] = []
    var heartRateSamples: [HeartRateSample] = []
    var respiratorySamples: [RespiratorySample] = []
    var sleepSegments: [SleepSegment] = []
    var stepBuckets: [StepBucket] = []

    mutating func append(quantitySample sample: HKQuantitySample, type: HKQuantityType) {
        switch type.identifier {
        case HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue:
            hrvSamples.append(HRVSample(sample))
            hrvSamples.trim(to: 512)
        case HKQuantityTypeIdentifier.heartRate.rawValue:
            heartRateSamples.append(HeartRateSample(sample))
            heartRateSamples.trim(to: 4096)
        case HKQuantityTypeIdentifier.restingHeartRate.rawValue:
            heartRateSamples.append(HeartRateSample(sample, context: .resting))
            heartRateSamples.trim(to: 4096)
        case HKQuantityTypeIdentifier.respiratoryRate.rawValue:
            respiratorySamples.append(RespiratorySample(sample))
            respiratorySamples.trim(to: 512)
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            stepBuckets.append(StepBucket(sample))
            stepBuckets.trim(to: 4096)
        default:
            break
        }
    }

    mutating func append(sleepSample sample: HKCategorySample) {
        sleepSegments.append(SleepSegment(sample))
        sleepSegments.trim(to: 256)
    }

    mutating func removeSample(with uuid: UUID) {
        hrvSamples.removeAll { $0.id == uuid }
        heartRateSamples.removeAll { $0.id == uuid }
        respiratorySamples.removeAll { $0.id == uuid }
        sleepSegments.removeAll { $0.id == uuid }
        stepBuckets.removeAll { $0.id == uuid }
    }

    mutating func pruneDeletedSamples(_ identifiers: Set<UUID>) -> Bool {
        let originalCounts = (hrvSamples.count, heartRateSamples.count, respiratorySamples.count, sleepSegments.count, stepBuckets.count)
        hrvSamples.removeAll { identifiers.contains($0.id) }
        heartRateSamples.removeAll { identifiers.contains($0.id) }
        respiratorySamples.removeAll { identifiers.contains($0.id) }
        sleepSegments.removeAll { identifiers.contains($0.id) }
        stepBuckets.removeAll { identifiers.contains($0.id) }
        let updatedCounts = (hrvSamples.count, heartRateSamples.count, respiratorySamples.count, sleepSegments.count, stepBuckets.count)
        return originalCounts != updatedCounts
    }

    // Computations
    func sleepIntervals() -> [DateInterval] {
        sleepSegments
            .filter { $0.stage.isAsleep }
            .map { DateInterval(start: $0.start, end: $0.end) }
    }

    func sedentaryIntervals(thresholdStepsPerHour: Double,
                            minimumDuration: TimeInterval,
                            excluding sleep: [DateInterval]) -> [DateInterval] {
        guard !stepBuckets.isEmpty else { return [] }
        let sorted = stepBuckets.sorted { $0.start < $1.start }
        var intervals: [DateInterval] = []
        var currentStart: Date?
        var currentEnd: Date?
        var totalSteps: Double = 0

        func finalize() {
            guard let start = currentStart, let end = currentEnd else { return }
            let duration = end.timeIntervalSince(start)
            guard duration >= minimumDuration else { reset() ; return }
            let stepsPerHour = totalSteps / max(duration / 3600, 0.001)
            guard stepsPerHour <= thresholdStepsPerHour else { reset(); return }
            let candidate = DateInterval(start: start, end: end)
            if !candidate.intersectsAny(of: sleep) {
                intervals.append(candidate)
            }
            reset()
        }

        func reset() {
            currentStart = nil
            currentEnd = nil
            totalSteps = 0
        }

        var previousEnd: Date?
        for bucket in sorted {
            if currentStart == nil { currentStart = bucket.start }
            if let prev = previousEnd, bucket.start.timeIntervalSince(prev) > 300 {
                finalize()
                currentStart = bucket.start
            }
            previousEnd = bucket.end
            currentEnd = max(currentEnd ?? bucket.end, bucket.end)
            totalSteps += bucket.steps
        }
        finalize()
        return intervals
    }

    func sleepDurations() -> Double {
        let asleep = sleepSegments.filter { $0.stage.isAsleep }
        return asleep.reduce(0) { $0 + $1.duration }
    }

    func medianHRV(in intervals: [DateInterval],
                   fallback: [DateInterval],
                   previous: Double?,
                   imputed: inout [String: Bool]) -> Double? {
        if let median = median(samples: hrvSamples, within: intervals) {
            return median
        }
        if let median = median(samples: hrvSamples, within: fallback) {
            return median
        }
        if let previous { imputed["hrv"] = true; return previous }
        return nil
    }

    func nocturnalHeartRate(in intervals: [DateInterval],
                            fallback: [DateInterval],
                            previous: Double?,
                            imputed: inout [String: Bool]) -> Double? {
        if let percentile = percentile(samples: heartRateSamples, within: intervals, percentile: 0.10) {
            return percentile
        }
        if let percentile = percentile(samples: heartRateSamples, within: fallback, percentile: 0.10) {
            return percentile
        }
        if let previous { imputed["nocturnalHR"] = true; return previous }
        return nil
    }

    func restingHeartRate(fallback: [DateInterval],
                          previous: Double?,
                          imputed: inout [String: Bool]) -> Double? {
        if let latest = heartRateSamples.last(where: { $0.context == .resting }) {
            return latest.value
        }
        if let average = average(samples: heartRateSamples, within: fallback) {
            return average
        }
        if let previous { imputed["restingHR"] = true; return previous }
        return nil
    }

    func averageRespiratoryRate(in intervals: [DateInterval]) -> Double? {
        guard !respiratorySamples.isEmpty else { return nil }
        if intervals.isEmpty { return respiratorySamples.map { $0.value }.mean }
        let filtered = respiratorySamples.filter { sample in intervals.contains { $0.contains(sample.time) } }
        guard !filtered.isEmpty else { return nil }
        return filtered.map { $0.value }.mean
    }

    func totalSteps() -> Double? {
        guard !stepBuckets.isEmpty else { return nil }
        return stepBuckets.reduce(0) { $0 + $1.steps }
    }

    // MARK: - Statistics helpers

    private func median<T: TimedSample>(samples: [T], within intervals: [DateInterval]) -> Double? {
        guard !samples.isEmpty else { return nil }
        let filtered = samples.filter { sample in intervals.contains { $0.contains(sample.time) } }
        guard !filtered.isEmpty else { return nil }
        let values = filtered.map { $0.value }.sorted()
        let mid = values.count / 2
        if values.count % 2 == 0 { return (values[mid - 1] + values[mid]) / 2 }
        return values[mid]
    }

    private func percentile<T: TimedSample>(samples: [T], within intervals: [DateInterval], percentile: Double) -> Double? {
        guard !samples.isEmpty else { return nil }
        let filtered = samples.filter { sample in intervals.contains { $0.contains(sample.time) } }
        guard !filtered.isEmpty else { return nil }
        let sorted = filtered.map { $0.value }.sorted()
        let index = max(0, Int(Double(sorted.count - 1) * percentile))
        return sorted[index]
    }

    private func average<T: TimedSample>(samples: [T], within intervals: [DateInterval]) -> Double? {
        guard !samples.isEmpty else { return nil }
        let filtered = samples.filter { sample in intervals.contains { $0.contains(sample.time) } }
        guard !filtered.isEmpty else { return nil }
        return filtered.map { $0.value }.mean
    }
}

// MARK: - Sample Models

private protocol TimedSample {
    var id: UUID { get }
    var time: Date { get }
    var value: Double { get }
}

private struct HRVSample: Codable, TimedSample {
    let id: UUID
    let time: Date
    let value: Double

    init(_ sample: HKQuantitySample) {
        id = sample.uuid
        time = sample.startDate
        value = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
    }
}

private struct HeartRateSample: Codable, TimedSample {
    enum Context: String, Codable { case normal, resting }
    let id: UUID
    let time: Date
    let value: Double
    let context: Context

    init(_ sample: HKQuantitySample, context: Context = .normal) {
        id = sample.uuid
        time = sample.startDate
        value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
        self.context = context
    }
}

private struct RespiratorySample: Codable, TimedSample {
    let id: UUID
    let time: Date
    let value: Double

    init(_ sample: HKQuantitySample) {
        id = sample.uuid
        time = sample.startDate
        value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
    }
}

private struct SleepSegment: Codable {
    enum Stage: String, Codable {
        case inBed
        case asleepCore
        case asleepDeep
        case asleepREM
        case asleepUnspecified
        case awake

        var isAsleep: Bool {
            switch self {
            case .asleepCore, .asleepDeep, .asleepREM, .asleepUnspecified:
                return true
            default:
                return false
            }
        }
    }

    let id: UUID
    let start: Date
    let end: Date
    let stage: Stage

    var duration: TimeInterval { max(0, end.timeIntervalSince(start)) }

    init(_ sample: HKCategorySample) {
        id = sample.uuid
        start = sample.startDate
        end = sample.endDate
        let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) ?? .inBed
        switch value {
        case .inBed: stage = .inBed
        case .asleepUnspecified: stage = .asleepUnspecified
        case .awake: stage = .awake
        case .asleepCore: stage = .asleepCore
        case .asleepDeep: stage = .asleepDeep
        case .asleepREM: stage = .asleepREM
        @unknown default: stage = .asleepUnspecified
        }
    }
}

private struct StepBucket: Codable {
    let id: UUID
    let start: Date
    let end: Date
    let steps: Double

    init(_ sample: HKQuantitySample) {
        id = sample.uuid
        start = sample.startDate
        end = sample.endDate
        steps = sample.quantity.doubleValue(for: HKUnit.count())
    }
}

// MARK: - Utilities

private extension Array {
    mutating func trim(to limit: Int) {
        guard count > limit else { return }
        removeFirst(count - limit)
    }
}

private extension Array where Element == Double {
    var mean: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}

private extension Array where Element == DateInterval {
    func contains(where predicate: (DateInterval) -> Bool) -> Bool {
        for interval in self where predicate(interval) { return true }
        return false
    }

    func contains(_ date: Date) -> Bool {
        contains { $0.contains(date) }
    }

    func intersectsAny(of other: [DateInterval]) -> Bool {
        for interval in self {
            if other.contains(where: { $0.intersects(interval) }) { return true }
        }
        return false
    }
}

private extension DateInterval {
    func intersectsAny(of intervals: [DateInterval]) -> Bool {
        intervals.contains { $0.intersects(self) }
    }
}
```

### Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift
```swift
import Foundation
import CoreData
#if canImport(FoundationModels)
import FoundationModels
#endif
import os
import PulsumData
import PulsumServices
import PulsumML
import PulsumTypes

public enum OrchestratorStartupError: Error {
    case healthDataUnavailable
    case healthBackgroundDeliveryMissing(underlying: Error)
}

// MARK: - Topic routing helpers

struct TopicSignalResolver {
    static func mapTopicToSignalOrDataDominant(topic: String?,
                                               snapshot: FeatureVectorSnapshot) -> String {
        if let topic,
           let focus = TopicFocus(rawValue: topic) {
            return focus.signalKey
        }
        return dataDominantSignal(from: snapshot)
    }

    static func dataDominantSignal(from snapshot: FeatureVectorSnapshot) -> String {
        let prioritizedKeys = snapshot.features.keys
            .filter { $0.hasPrefix("z_") || $0.hasPrefix("subj_") || $0 == "sentiment" }
            .sorted()

        var dominantSignal = "subj_energy"
        var maxAbsZ = 0.0

        for key in prioritizedKeys {
            guard let value = snapshot.features[key] else { continue }
            let magnitude = abs(value)
            if magnitude > maxAbsZ {
                maxAbsZ = magnitude
                dominantSignal = key
            }
        }

        return dominantSignal
    }

    private enum TopicFocus: String {
        case sleep
        case stress
        case energy
        case hrv
        case mood
        case movement
        case mindfulness
        case goals

        var signalKey: String {
            switch self {
            case .sleep: return "subj_sleepQuality"
            case .stress: return "subj_stress"
            case .energy: return "subj_energy"
            case .hrv: return "z_hrv"
            case .mood: return "sentiment"
            case .movement: return "z_steps"
            case .mindfulness: return "z_rr"
            case .goals: return "subj_energy"
            }
        }
    }
}

protocol DataAgentProviding: AnyObject, Sendable {
    func start() async throws
    func latestFeatureVector() async throws -> FeatureVectorSnapshot?
    func recordSubjectiveInputs(date: Date, stress: Double, energy: Double, sleepQuality: Double) async throws
    func scoreBreakdown() async throws -> ScoreBreakdown?
    func reprocessDay(date: Date) async throws
    func currentHealthAccessStatus() async -> HealthAccessStatus
    func requestHealthAccess() async throws -> HealthAccessStatus
    func restartIngestionAfterPermissionsChange() async throws -> HealthAccessStatus
}

extension DataAgent: DataAgentProviding {}

@MainActor
protocol SentimentAgentProviding: AnyObject {
    func beginVoiceJournal(maxDuration: TimeInterval) async throws
    func finishVoiceJournal(transcript: String?) async throws -> JournalResult
    func recordVoiceJournal(maxDuration: TimeInterval) async throws -> JournalResult
    func importTranscript(_ transcript: String) async throws -> JournalResult
    func requestAuthorization() async throws
    func stopRecording()
    var audioLevels: AsyncStream<Float>? { get }
    var speechStream: AsyncThrowingStream<SpeechSegment, Error>? { get }
    func updateTranscript(_ transcript: String)
    func latestTranscriptSnapshot() -> String
}

extension SentimentAgent: SentimentAgentProviding {}

public struct RecommendationResponse {
    public let cards: [RecommendationCard]
    public let wellbeingScore: Double
    public let contributions: [String: Double]
    public let wellbeingState: WellbeingScoreState
}

public struct JournalCaptureResponse {
    public let result: JournalResult
    public let safety: SafetyDecision
}

public struct RecommendationCard: Equatable {
    public let id: String
    public let title: String
    public let body: String
    public let caution: String?
    public let sourceBadge: String
}

public struct SafetyDecision {
    public let classification: SafetyClassification
    public let allowCloud: Bool
    public let crisisMessage: String?
}

public struct JournalResult: @unchecked Sendable {
    public let entryID: NSManagedObjectID
    public let date: Date
    public let transcript: String
    public let sentimentScore: Double
    public let vectorURL: URL?
    public let embeddingPending: Bool
}

public struct CheerEvent {
    public enum HapticStyle {
        case success
        case light
        case heavy
    }

    public let message: String
    public let haptic: HapticStyle
    public let timestamp: Date
}

@MainActor
public final class AgentOrchestrator {
    private let dataAgent: any DataAgentProviding
    private let sentimentAgent: any SentimentAgentProviding
    private let coachAgent: CoachAgent
    private let safetyAgent: SafetyAgent
    private let cheerAgent: CheerAgent

    private let afmAvailable: Bool
    private let topicGate: TopicGateProviding
    private let logger = Logger(subsystem: "com.pulsum", category: "AgentOrchestrator")
    private var isVoiceJournalActive = false
    
    public init() throws {
        // Check Foundation Models availability
#if canImport(FoundationModels) && os(iOS)
        if #available(iOS 26.0, *) {
            self.afmAvailable = SystemLanguageModel.default.isAvailable
        } else {
            self.afmAvailable = false
        }
#else
        self.afmAvailable = false
#endif

        // Initialize TopicGate with cascade: AFM → embedding fallback
#if canImport(FoundationModels) && os(iOS)
        if #available(iOS 26.0, *), SystemLanguageModel.default.isAvailable {
            self.topicGate = FoundationModelsTopicGateProvider()
        } else {
            self.topicGate = EmbeddingTopicGateProvider()
        }
#else
        self.topicGate = EmbeddingTopicGateProvider()
#endif

        self.dataAgent = DataAgent()
        self.sentimentAgent = SentimentAgent()
        self.coachAgent = try CoachAgent()
        self.safetyAgent = SafetyAgent()
        self.cheerAgent = CheerAgent()
    }
#if DEBUG
    init(dataAgent: any DataAgentProviding,
                sentimentAgent: any SentimentAgentProviding,
                coachAgent: CoachAgent,
                safetyAgent: SafetyAgent,
                cheerAgent: CheerAgent,
                topicGate: TopicGateProviding,
                afmAvailable: Bool = false) {
        self.dataAgent = dataAgent
        self.sentimentAgent = sentimentAgent
        self.coachAgent = coachAgent
        self.safetyAgent = safetyAgent
        self.cheerAgent = cheerAgent
        self.topicGate = topicGate
        self.afmAvailable = afmAvailable
    }
#endif

#if DEBUG
    init(testDataAgent: DataAgent,
         testSentimentAgent: any SentimentAgentProviding,
         testCoachAgent: CoachAgent,
         testSafetyAgent: SafetyAgent,
         testCheerAgent: CheerAgent,
         testTopicGate: TopicGateProviding,
         afmAvailable: Bool = false) {
        self.dataAgent = testDataAgent
        self.sentimentAgent = testSentimentAgent
        self.coachAgent = testCoachAgent
        self.safetyAgent = testSafetyAgent
        self.cheerAgent = testCheerAgent
        self.afmAvailable = afmAvailable
        self.topicGate = testTopicGate
    }
#endif
    
    public var foundationModelsStatus: String {
        if #available(iOS 26.0, *) {
            let status = FoundationModelsAvailability.checkAvailability()
            return FoundationModelsAvailability.availabilityMessage(for: status)
        } else {
            return "Foundation Models require iOS 26 or later."
        }
    }

    public func debugLogSnapshot() async -> String {
        await DebugLogBuffer.shared.snapshot()
    }

    public func start() async throws {
        do {
            try await coachAgent.prepareLibraryIfNeeded()
            try await dataAgent.start()
        } catch let healthError as HealthKitServiceError {
            switch healthError {
            case .healthDataUnavailable:
                throw OrchestratorStartupError.healthDataUnavailable
            case let .backgroundDeliveryFailed(_, underlying):
                throw OrchestratorStartupError.healthBackgroundDeliveryMissing(underlying: underlying)
            default:
                throw healthError
            }
        }
    }

    public func currentHealthAccessStatus() async -> HealthAccessStatus {
        await dataAgent.currentHealthAccessStatus()
    }

    public func requestHealthAccess() async throws -> HealthAccessStatus {
        try await dataAgent.requestHealthAccess()
    }

    public func restartHealthDataIngestion() async throws -> HealthAccessStatus {
        try await dataAgent.restartIngestionAfterPermissionsChange()
    }

    /// Begins voice journal recording and returns immediately after starting audio capture.
    /// Audio levels and speech stream become available synchronously via properties.
    /// The caller should consume `voiceJournalSpeechStream` for real-time transcription.
    /// Call `finishVoiceJournalRecording(transcript:)` to complete recording and get the result.
    public func beginVoiceJournalRecording(maxDuration: TimeInterval = 30) async throws {
        guard !isVoiceJournalActive else {
            throw SentimentAgentError.sessionAlreadyActive
        }
        isVoiceJournalActive = true
        do {
            try await sentimentAgent.beginVoiceJournal(maxDuration: maxDuration)
        } catch {
            isVoiceJournalActive = false
            throw error
        }
    }
    
    /// Completes the voice journal recording that was started with `beginVoiceJournalRecording()`.
    /// Uses the provided transcript (from consuming the speech stream) to persist the journal.
    /// Returns the journal result with safety evaluation.
    public func finishVoiceJournalRecording(transcript: String? = nil) async throws -> JournalCaptureResponse {
        defer { isVoiceJournalActive = false }
        let result = try await sentimentAgent.finishVoiceJournal(transcript: transcript)
        let safety = await safetyAgent.evaluate(text: result.transcript)
        try await dataAgent.reprocessDay(date: result.date)
        return JournalCaptureResponse(result: result, safety: safety)
    }

    /// Legacy method that combines begin + finish for backward compatibility
    public func recordVoiceJournal(maxDuration: TimeInterval = 30) async throws -> JournalCaptureResponse {
        try await beginVoiceJournalRecording(maxDuration: maxDuration)
        var transcript = ""
        do {
            if let stream = voiceJournalSpeechStream {
                for try await segment in stream {
                    transcript = segment.transcript
                    sentimentAgent.updateTranscript(transcript)
                }
            }
            return try await finishVoiceJournalRecording(transcript: transcript)
        } catch {
            let fallbackTranscript = transcript.isEmpty ? sentimentAgent.latestTranscriptSnapshot() : transcript
            if !fallbackTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                _ = try? await finishVoiceJournalRecording(transcript: fallbackTranscript)
            } else {
                stopVoiceJournalRecording()
            }
            throw error
        }
    }

    public func submitTranscript(_ text: String) async throws -> JournalCaptureResponse {
        let result = try await sentimentAgent.importTranscript(text)
        let safety = await safetyAgent.evaluate(text: result.transcript)
        return JournalCaptureResponse(result: result, safety: safety)
    }

    public func currentLLMAPIKey() -> String? {
        coachAgent.currentLLMAPIKey()
    }

    public func setLLMAPIKey(_ key: String) throws {
        try coachAgent.setLLMAPIKey(key)
    }

    public func testLLMAPIConnection() async throws -> Bool {
        try await coachAgent.testLLMAPIConnection()
    }

    public func stopVoiceJournalRecording() {
        isVoiceJournalActive = false
        sentimentAgent.stopRecording()
    }
    
    public var voiceJournalAudioLevels: AsyncStream<Float>? {
        sentimentAgent.audioLevels
    }
    
    public var voiceJournalSpeechStream: AsyncThrowingStream<SpeechSegment, Error>? {
        sentimentAgent.speechStream
    }

    public func updateVoiceJournalTranscript(_ transcript: String) {
        sentimentAgent.updateTranscript(transcript)
    }

    public func updateSubjectiveInputs(date: Date, stress: Double, energy: Double, sleepQuality: Double) async throws {
        try await dataAgent.recordSubjectiveInputs(date: date, stress: stress, energy: energy, sleepQuality: sleepQuality)
    }

    public func recommendations(consentGranted: Bool) async throws -> RecommendationResponse {
        let healthStatus = await dataAgent.currentHealthAccessStatus()
        do {
            if let snapshot = try await dataAgent.latestFeatureVector() {
                let cards = try await coachAgent.recommendationCards(for: snapshot, consentGranted: consentGranted)
                return RecommendationResponse(cards: cards,
                                              wellbeingScore: snapshot.wellbeingScore,
                                              contributions: snapshot.contributions,
                                              wellbeingState: .ready(score: snapshot.wellbeingScore,
                                                                      contributions: snapshot.contributions))
            }

            let state = Self.computeWellbeingState(for: healthStatus)
            return RecommendationResponse(cards: [],
                                          wellbeingScore: 0,
                                          contributions: [:],
                                          wellbeingState: state)
        } catch {
            let sanitized = "Unable to compute wellbeing right now."
            return RecommendationResponse(cards: [],
                                          wellbeingScore: 0,
                                          contributions: [:],
                                          wellbeingState: .error(message: sanitized))
        }
    }

    nonisolated static func computeWellbeingState(for healthStatus: HealthAccessStatus) -> WellbeingScoreState {
        switch healthStatus.availability {
        case .unavailable:
            return .noData(.healthDataUnavailable)
        case .available:
            if !healthStatus.denied.isEmpty || !healthStatus.notDetermined.isEmpty {
                return .noData(.permissionsDeniedOrPending)
            }
            return .noData(.insufficientSamples)
        }
    }

    public func scoreBreakdown() async throws -> ScoreBreakdown? {
        try await dataAgent.scoreBreakdown()
    }

    public func chat(userInput: String, consentGranted: Bool) async throws -> String {
        let sanitizedInput = PIIRedactor.redact(userInput)
        logger.debug("Chat request received. Consent: \(consentGranted, privacy: .public), input: \(sanitizedInput.prefix(160), privacy: .public)")

        guard let snapshot = try await dataAgent.latestFeatureVector() else {
            logger.info("No feature vector snapshot available; returning warmup prompt.")
            return "Let's take a moment to capture your pulse first."
        }

        return await performChat(userInput: userInput,
                                 sanitizedInput: sanitizedInput,
                                 snapshot: snapshot,
                                 consentGranted: consentGranted,
                                 diagnosticsContext: "live")
    }

#if DEBUG
    public func chat(userInput: String,
                     consentGranted: Bool,
                     snapshotOverride: FeatureVectorSnapshot) async -> String {
        let sanitizedInput = PIIRedactor.redact(userInput)
        logger.debug("Chat request (override). Consent: \(consentGranted, privacy: .public), input: \(sanitizedInput.prefix(160), privacy: .public)")
        return await performChat(userInput: userInput,
                                 sanitizedInput: sanitizedInput,
                                 snapshot: snapshotOverride,
                                 consentGranted: consentGranted,
                                 diagnosticsContext: "override")
    }
#endif

    private func performChat(userInput: String,
                             sanitizedInput: String,
                             snapshot: FeatureVectorSnapshot,
                             consentGranted: Bool,
                             diagnosticsContext: String) async -> String {
        // WALL 1: Safety + On-Topic Guardrail (on-device)
        let safety = await safetyAgent.evaluate(text: userInput)
        let classification: String
        switch safety.classification {
        case .safe:
            classification = "safe"
        case .caution(let reason):
            classification = "caution: \(String(PIIRedactor.redact(reason).prefix(120)))"
        case .crisis(let reason):
            classification = "crisis: \(String(PIIRedactor.redact(reason).prefix(120)))"
        }
        logger.debug("Safety decision → allowCloud: \(safety.allowCloud, privacy: .public), classification: \(classification, privacy: .public)")

        let allowCloud = consentGranted && safety.allowCloud

        if !safety.allowCloud {
            logger.notice("Safety gate blocked cloud usage. Returning guardrail message.")
            switch safety.classification {
            case .crisis:
                emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=nil coverage=fail → safety", decision: nil, top: nil, median: nil, count: nil, context: diagnosticsContext)
                return safety.crisisMessage ?? "If you're in immediate danger, please contact 911."
            case .caution:
                emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=nil coverage=fail → safety", decision: nil, top: nil, median: nil, count: nil, context: diagnosticsContext)
                return "Let's stay with grounding actions for a moment."
            case .safe:
                break
            }
        }

        // Step 2: Topic gate (on-device ML classification)
        let intentTopic: String?
        var topSignal: String
        do {
            let gateDecision = try await topicGate.classify(sanitizedInput)
            logger.debug("Topic gate → isOnTopic: \(gateDecision.isOnTopic, privacy: .public), confidence: \(String(format: "%.2f", gateDecision.confidence), privacy: .public), topic: \(gateDecision.topic ?? "none", privacy: .public), reason: \(String(gateDecision.reason.prefix(100)), privacy: .public)")

            if !gateDecision.isOnTopic {
                logger.notice("Topic gate blocked off-topic request. Returning redirect message.")
                emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=nil coverage=fail → redirect", decision: nil, top: nil, median: nil, count: nil, context: diagnosticsContext)
                return "Let's keep Pulsum focused on your wellbeing data. Ask me about stress, sleep, energy, or today's recommendations."
            }

            // Step 2b: Deterministic intent → topSignal mapping (4-step override)
            var topic = gateDecision.topic
            let lower = sanitizedInput.lowercased()
            let phraseToTopic: [(substr: String, topic: String)] = [
                ("sleep", "sleep"), ("insomnia", "sleep"), ("rest", "sleep"), ("tired", "sleep"),
                ("stress", "stress"), ("anxiety", "stress"), ("overwhelm", "stress"), ("worry", "stress"),
                ("energy", "energy"), ("fatigue", "energy"), ("motivation", "energy"),
                ("hrv", "hrv"), ("heart rate variability", "hrv"), ("recovery", "hrv"), ("rmssd", "hrv"),
                ("mood", "mood"), ("feeling", "mood"), ("emotion", "mood"),
                ("movement", "movement"), ("steps", "movement"), ("walk", "movement"), ("exercise", "movement"),
                ("mindfulness", "mindfulness"), ("meditation", "mindfulness"), ("breathe", "mindfulness"), ("calm", "mindfulness"),
                ("goal", "goals"), ("habit", "goals"), ("micro", "goals"), ("activity", "goals")
            ]
            if let hit = phraseToTopic.first(where: { lower.contains($0.substr) }) {
                topic = hit.topic
            }

            let candidateMoments = await coachAgent.candidateMoments(for: topic ?? "goals", limit: 2)
            if let dominantFromCandidates = dominantTopic(from: candidateMoments, coachAgent: coachAgent) {
                topic = dominantFromCandidates
            }

            topSignal = TopicSignalResolver.mapTopicToSignalOrDataDominant(topic: topic, snapshot: snapshot)
            if let topic {
                topSignal += " topic=\(topic)"
            }
            intentTopic = topic

            logger.debug("Intent mapping → topic: \(topic ?? "none", privacy: .public), topSignal: \(topSignal, privacy: .public)")
        } catch {
            logger.error("Topic gate failed: \(error.localizedDescription, privacy: .public). Failing closed.")
            emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=nil coverage=fail → redirect", decision: nil, top: nil, median: nil, count: nil, context: diagnosticsContext)
            return "Let's keep Pulsum focused on your wellbeing data. Ask me about stress, sleep, energy, or today's recommendations."
        }

        // Embedding availability gate: if no on-device embeddings are available, fail closed and respond on-device.
        if !EmbeddingService.shared.isAvailable() {
            logger.error("Embeddings unavailable; skipping coverage and routing to on-device response.")
            emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=\(intentTopic ?? "nil") coverage=unavailable → on-device",
                                decision: nil,
                                top: nil,
                                median: nil,
                                count: nil,
                                context: diagnosticsContext)
            let topic = intentTopic ?? "wellbeing"
            let context = coachAgent.minimalCoachContext(from: snapshot, topic: topic)
            let payload = await coachAgent.generateResponse(context: context,
                                                            intentTopic: intentTopic ?? topic,
                                                            consentGranted: false,
                                                            groundingFloor: 0.40)
            return payload.coachReply
        }

        // Step 3: Retrieval coverage with hybrid backfill
        let coverageResult: (matches: [VectorMatch], decision: CoverageDecision)
        do {
            coverageResult = try await coachAgent.coverageDecision(for: sanitizedInput,
                                                                   canonicalTopic: intentTopic,
                                                                   snapshot: snapshot)
        } catch {
            if let embeddingError = error as? EmbeddingError, case .generatorUnavailable = embeddingError {
                logger.error("Coverage evaluation skipped: embeddings unavailable. Routing to on-device response.")
                emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=\(intentTopic ?? "nil") coverage=unavailable → on-device", decision: nil, top: nil, median: nil, count: nil, context: diagnosticsContext)
                let topic = intentTopic ?? "wellbeing"
                let context = coachAgent.minimalCoachContext(from: snapshot, topic: topic)
                let payload = await coachAgent.generateResponse(context: context,
                                                                intentTopic: intentTopic ?? topic,
                                                                consentGranted: false,
                                                                groundingFloor: 0.40)
                return payload.coachReply
            }
            logger.error("Coverage evaluation failed: \(error.localizedDescription, privacy: .public). Falling back to redirect.")
            emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=\(intentTopic ?? "nil") coverage=unknown → redirect", decision: nil, top: nil, median: nil, count: nil, context: diagnosticsContext)
            return "Let's keep Pulsum focused on your wellbeing data. Ask me about stress, sleep, energy, or today's recommendations."
        }

        let decision = coverageResult.decision
        let routeDestination = allowCloud ? "cloud" : "on-device"
        let groundingFloor: Double

        switch decision.kind {
        case .strong:
            groundingFloor = 0.50
            emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=\(intentTopic ?? "nil") coverage=strong → \(routeDestination)",
                                decision: decision,
                                top: decision.top,
                                median: decision.median,
                                count: decision.count,
                                context: diagnosticsContext)
        case .soft:
            groundingFloor = 0.40
            emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=\(intentTopic ?? "nil") coverage=soft → \(routeDestination)",
                                decision: decision,
                                top: decision.top,
                                median: decision.median,
                                count: decision.count,
                                context: diagnosticsContext)
        case .fail:
            if intentTopic == nil {
                emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=nil coverage=fail → on-device",
                                    decision: decision,
                                    top: decision.top,
                                    median: decision.median,
                                    count: decision.count,
                                    context: diagnosticsContext)
                let context = coachAgent.minimalCoachContext(from: snapshot, topic: "greeting")
                let payload = await coachAgent.generateResponse(context: context,
                                                                intentTopic: "greeting",
                                                                consentGranted: false,
                                                                groundingFloor: 0.40)
                return payload.coachReply
            }
            emitRouteDiagnostics(line: "ChatRoute consent=\(consentGranted) topic=\(intentTopic ?? "nil") coverage=fail → on-device",
                                decision: decision,
                                top: decision.top,
                                median: decision.median,
                                count: decision.count,
                                context: diagnosticsContext)
            let context = coachAgent.minimalCoachContext(from: snapshot, topic: intentTopic!)
            let payload = await coachAgent.generateResponse(context: context,
                                                            intentTopic: intentTopic,
                                                            consentGranted: false,
                                                            groundingFloor: 0.40)
            return payload.coachReply
        }

        let payload = await coachAgent.chatResponse(userInput: userInput,
                                                    snapshot: snapshot,
                                                    consentGranted: allowCloud,
                                                    intentTopic: intentTopic,
                                                    topSignal: topSignal,
                                                    groundingFloor: groundingFloor)
        logger.debug("Chat response delivered. Length: \(payload.coachReply.count, privacy: .public), hasNextAction: \(payload.nextAction != nil, privacy: .public)")

        return payload.coachReply
    }

    private func emitRouteDiagnostics(line: String,
                                      decision: CoverageDecision?,
                                      top: Double?,
                                      median: Double?,
                                      count: Int?,
                                      context: String) {
        print(line)
#if DEBUG
        var info: [String: Any] = [
            "route": line,
            "context": context
        ]
        if let decision {
            info["reason"] = decision.reason
        }
        if let top { info["top"] = top }
        if let median { info["median"] = median }
        if let count { info["count"] = count }
        NotificationCenter.default.post(name: .pulsumChatRouteDiagnostics,
                                        object: nil,
                                        userInfo: info)
#endif
    }

    public func logCompletion(momentId: String) async throws -> CheerEvent {
        try await coachAgent.logEvent(momentId: momentId, accepted: true)
        let title = await coachAgent.momentTitle(for: momentId) ?? momentId
        return await cheerAgent.celebrateCompletion(momentTitle: title)
    }

    // MARK: - Intent Mapping Helpers

    /// Extract dominant topic from candidate moments (Step 3 of intent mapping)
    private func dominantTopic(from candidates: [CandidateMoment], coachAgent: CoachAgent) -> String? {
        // Use embedding similarity to infer dominant topic from candidate titles
        let topicKeywords: [String: [String]] = [
            "sleep": ["sleep", "rest", "recovery", "insomnia", "tired"],
            "stress": ["stress", "anxiety", "overwhelm", "worry", "tension"],
            "energy": ["energy", "fatigue", "motivation", "vitality"],
            "hrv": ["hrv", "heart rate", "variability", "recovery", "vagal"],
            "mood": ["mood", "feeling", "emotion", "mental"],
            "movement": ["movement", "steps", "walk", "exercise", "activity"],
            "mindfulness": ["mindfulness", "meditation", "breathe", "calm", "grounding"],
            "goals": ["goal", "habit", "micro", "moment", "action"]
        ]

        var topicScores: [String: Int] = [:]
        for candidate in candidates {
            let detail = candidate.detail ?? ""
            let text = (candidate.title + " " + candidate.shortDescription + " " + detail).lowercased()
            for (topic, keywords) in topicKeywords {
                let matches = keywords.filter { text.contains($0) }.count
                topicScores[topic, default: 0] += matches
            }
        }

        return topicScores.max(by: { $0.value < $1.value })?.key
    }

}
```

### Packages/PulsumAgents/Sources/PulsumAgents/WellbeingScoreState.swift
```swift
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
```

### Packages/PulsumAgents/Sources/PulsumAgents/EstimatorStateStore.swift
```swift
import Foundation
import os.log
import PulsumData
import PulsumML

protocol EstimatorStateStoring: Sendable {
    func loadState() -> StateEstimatorState?
    func saveState(_ state: StateEstimatorState)
}

final class EstimatorStateStore: EstimatorStateStoring, @unchecked Sendable {
    static let schemaVersion = 1

    private let fileURL: URL
    private let fileManager: FileManager
    private let logger = Logger(subsystem: "ai.pulsum", category: "EstimatorStateStore")

    init(baseDirectory: URL = PulsumData.applicationSupportDirectory,
         fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let directory = baseDirectory.appendingPathComponent("EstimatorState", isDirectory: true)
        self.fileURL = directory.appendingPathComponent("state_v\(Self.schemaVersion).json")
        prepareDirectory(at: directory)
    }

    func loadState() -> StateEstimatorState? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            let state = try JSONDecoder().decode(StateEstimatorState.self, from: data)
            guard state.version == Self.schemaVersion else {
                logger.warning("Estimator state version mismatch. Expected \(Self.schemaVersion), found \(state.version). Ignoring persisted state.")
                return nil
            }
            return state
        } catch {
            logger.error("Failed to load estimator state: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func saveState(_ state: StateEstimatorState) {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: fileURL, options: .atomic)
            applyFileProtection()
            excludeFromBackup()
        } catch {
            logger.error("Failed to persist estimator state: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func prepareDirectory(at url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            do {
                #if os(iOS)
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: [.protectionKey: FileProtectionType.complete])
                #else
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                #endif
            } catch {
                logger.error("Failed to prepare estimator state directory: \(error.localizedDescription, privacy: .public)")
            }
        } else {
            #if os(iOS)
            do {
                try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
            } catch {
                logger.error("Failed to update estimator state directory protection: \(error.localizedDescription, privacy: .public)")
            }
            #endif
        }
    }

    private func applyFileProtection() {
        #if os(iOS)
        do {
            try fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: fileURL.path)
        } catch {
            logger.error("Failed to set file protection on estimator state: \(error.localizedDescription, privacy: .public)")
        }
        #endif
    }

    private func excludeFromBackup() {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableURL = fileURL
        do {
            try mutableURL.setResourceValues(values)
        } catch {
            logger.error("Failed to mark estimator state as backup-excluded: \(error.localizedDescription, privacy: .public)")
        }
    }
}
```

### Packages/PulsumML/Sources/PulsumML/StateEstimator.swift
```swift
import Foundation

public struct StateEstimatorConfig {
    public let learningRate: Double
    public let regularization: Double
    public let weightCap: ClosedRange<Double>

    public init(learningRate: Double = 0.05,
                regularization: Double = 1e-3,
                weightCap: ClosedRange<Double> = -2.0...2.0) {
        self.learningRate = learningRate
        self.regularization = regularization
        self.weightCap = weightCap
    }
}

public struct StateEstimatorSnapshot: Sendable {
    public let weights: [String: Double]
    public let bias: Double
    public let wellbeingScore: Double
    public let contributions: [String: Double]
}

public struct StateEstimatorState: Codable, Sendable {
    public let version: Int
    public let weights: [String: Double]
    public let bias: Double

    public init(version: Int = 1, weights: [String: Double], bias: Double) {
        self.version = version
        self.weights = weights
        self.bias = bias
    }
}

public final class StateEstimator {
    public static let defaultWeights: [String: Double] = [
        "z_hrv": 0.6,
        "z_nocthr": -0.45,
        "z_resthr": -0.35,
        "z_sleepDebt": -0.55,
        "z_steps": 0.3,
        "z_rr": -0.1,
        "subj_stress": -0.5,
        "subj_energy": 0.5,
        "subj_sleepQuality": 0.35,
        "sentiment": 0.25
    ]

    private let config: StateEstimatorConfig
    private var weights: [String: Double]
    private var bias: Double

    public init(initialWeights: [String: Double] = StateEstimator.defaultWeights,
                bias: Double = 0,
                config: StateEstimatorConfig = StateEstimatorConfig()) {
        self.weights = initialWeights
        self.config = config
        self.bias = bias
    }

    public init(state: StateEstimatorState, config: StateEstimatorConfig = StateEstimatorConfig()) {
        self.weights = state.weights
        self.bias = state.bias
        self.config = config
    }

    public func predict(features: [String: Double]) -> Double {
        let contributions = contributionVector(features: features)
        return contributions.values.reduce(bias, +)
    }

    public func update(features: [String: Double], target: Double) -> StateEstimatorSnapshot {
        let prediction = predict(features: features)
        let error = target - prediction

        for (feature, value) in features {
            let gradient = -error * value + config.regularization * (weights[feature] ?? 0)
            var updated = (weights[feature] ?? 0) - config.learningRate * gradient
            updated = min(max(updated, config.weightCap.lowerBound), config.weightCap.upperBound)
            weights[feature] = updated
        }

        bias -= config.learningRate * (-error)

        let contributions = contributionVector(features: features)
        let wellbeing = contributions.values.reduce(bias, +)
        return StateEstimatorSnapshot(weights: weights, bias: bias, wellbeingScore: wellbeing, contributions: contributions)
    }

    public func currentSnapshot(features: [String: Double]) -> StateEstimatorSnapshot {
        let contributions = contributionVector(features: features)
        let wellbeing = contributions.values.reduce(bias, +)
        return StateEstimatorSnapshot(weights: weights, bias: bias, wellbeingScore: wellbeing, contributions: contributions)
    }

    public func persistedState(version: Int = 1) -> StateEstimatorState {
        StateEstimatorState(version: version, weights: weights, bias: bias)
    }

    private func contributionVector(features: [String: Double]) -> [String: Double] {
        var result: [String: Double] = [:]
        result.reserveCapacity(features.count)
        for (feature, value) in features {
            let weight = weights[feature] ?? 0
            result[feature] = weight * value
        }
        return result
    }
}
```

### Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift
```swift
import Foundation
import CoreData
import Observation
import PulsumAgents
import PulsumData
#if canImport(HealthKit)
import HealthKit
#endif

@MainActor
@Observable
final class AppViewModel {
    enum StartupState: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
        case blocked(String)
    }

    enum Tab: String, CaseIterable, Identifiable, Hashable {
        case main
        case insights
        case coach

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .main: return "Main"
            case .insights: return "Insights"
            case .coach: return "Coach"
            }
        }

        var iconName: String {
            switch self {
            case .main: return "gauge.with.needle"
            case .insights: return "lightbulb"
            case .coach: return "text.bubble"
            }
        }
    }

    private let consentStore = ConsentStore()
    @ObservationIgnored private(set) var orchestrator: AgentOrchestrator?
    @ObservationIgnored private var scoreRefreshObserver: NSObjectProtocol?

    var startupState: StartupState = .idle
    var selectedTab: Tab = .main
    var isPresentingPulse = false
    var isPresentingSettings = false
    var isShowingSafetyCard = false
    var safetyMessage: String?

    var consentGranted: Bool
    var shouldHideConsentBanner = false
    var showConsentBanner: Bool { !consentGranted && !shouldHideConsentBanner }

    let coachViewModel: CoachViewModel
    let pulseViewModel: PulseViewModel
    let settingsViewModel: SettingsViewModel

    init() {
        Task { await DebugLogBuffer.shared.append("AppViewModel.init invoked") }
        let consent = consentStore.loadConsent()
        self.consentGranted = consent

        let coachVM = CoachViewModel()
        let pulseVM = PulseViewModel()
        let settingsVM = SettingsViewModel(initialConsent: consent)

        self.coachViewModel = coachVM
        self.pulseViewModel = pulseVM
        self.settingsViewModel = settingsVM

        settingsVM.onConsentChanged = { [weak self] newValue in
            guard let self else { return }
            self.updateConsent(to: newValue)
        }

        pulseVM.onSafetyDecision = { [weak self] decision in
            guard let self else { return }
            if !decision.allowCloud, case .crisis = decision.classification {
                self.safetyMessage = decision.crisisMessage ?? "If in danger, call 911"
                self.isShowingSafetyCard = true
            }
        }

        scoreRefreshObserver = NotificationCenter.default.addObserver(forName: .pulsumScoresUpdated,
                                                                      object: nil,
                                                                      queue: .main) { [weak self] _ in
            guard let self else { return }
            Task { [weak self] in
                await self?.coachViewModel.refreshRecommendations()
            }
        }
    }

    func start() {
        guard startupState == .idle else { return }
        if let issue = PulsumData.backupSecurityIssue {
            let location = issue.url.lastPathComponent
            startupState = .blocked("Storage is not secured for backup (directory: \(location)). \(issue.reason)")
            Task { await DebugLogBuffer.shared.append("Startup blocked: \(issue.reason)") }
            return
        }
        startupState = .loading
        Task { [weak self] in
            guard let self else { return }
            do {
                print("[Pulsum] Attempting to make orchestrator")
                await DebugLogBuffer.shared.append("Creating orchestrator")
                let orchestrator = try PulsumAgents.makeOrchestrator()
                print("[Pulsum] Orchestrator created")
                await DebugLogBuffer.shared.append("Orchestrator created")
                self.orchestrator = orchestrator
                self.coachViewModel.bind(orchestrator: orchestrator, consentProvider: { [weak self] in
                    self?.consentGranted ?? false
                })
                print("[Pulsum] CoachViewModel bound")
                self.pulseViewModel.bind(orchestrator: orchestrator)
                print("[Pulsum] PulseViewModel bound")
                self.settingsViewModel.bind(orchestrator: orchestrator)
                self.settingsViewModel.refreshFoundationStatus()
                Task { await DebugLogBuffer.shared.append("Orchestrator bound to UI view models") }
                print("[Pulsum] SettingsViewModel bound and foundation status refreshed")
                self.startupState = .ready
                print("[Pulsum] Startup state set to ready")

                Task { [weak self] in
                    guard let self else { return }
                    do {
                        print("[Pulsum] Starting orchestrator start()")
                        await DebugLogBuffer.shared.append("Starting orchestrator.start()")
                        try await orchestrator.start()
                        print("[Pulsum] Orchestrator start() completed")
                        self.settingsViewModel.refreshHealthAccessStatus()
                        await self.coachViewModel.refreshRecommendations()
                        print("[Pulsum] Recommendations refreshed")
                        await DebugLogBuffer.shared.append("Orchestrator start complete; recommendations refreshed")
                    } catch {
                        print("[Pulsum] Orchestrator start failed: \(error)")
                        await DebugLogBuffer.shared.append("Orchestrator start failed: \(error.localizedDescription)")
                        if let startupError = error as? OrchestratorStartupError {
                            switch startupError {
                            case .healthDataUnavailable:
                                await DebugLogBuffer.shared.append("HealthDataUnavailable during start")
                                return
                            case let .healthBackgroundDeliveryMissing(underlying):
                                if shouldIgnoreBackgroundDeliveryError(underlying) {
                                    await DebugLogBuffer.shared.append("Background delivery missing but ignored: \(underlying.localizedDescription)")
                                    return
                                }
                            }
                        }
                        self.startupState = .failed(error.localizedDescription)
                    }
                }
            } catch {
                print("[Pulsum] Failed to create orchestrator: \(error)")
                await DebugLogBuffer.shared.append("Failed to create orchestrator: \(error.localizedDescription)")
                self.startupState = .failed(error.localizedDescription)
            }
        }
    }

    func retryStartup() {
        startupState = .idle
        start()
    }

    func updateConsent(to newValue: Bool) {
        consentGranted = newValue
        consentStore.saveConsent(newValue)
        coachViewModel.updateConsent(newValue)
        settingsViewModel.refreshConsent(newValue)
        Task { [weak self] in
            await self?.coachViewModel.refreshRecommendations()
        }
    }

    func triggerCoachFocus() {
        selectedTab = .coach
        coachViewModel.requestChatFocus()
    }

    func dismissConsentBanner() {
        shouldHideConsentBanner = true
    }

    func handleRecommendationCompletion(_ card: RecommendationCard) {
        Task { [weak self] in
            guard let self, let orchestrator else { return }
            await coachViewModel.complete(card: card, orchestrator: orchestrator)
        }
    }

    func dismissSafetyCard() {
        isShowingSafetyCard = false
        safetyMessage = nil
    }
}

private func shouldIgnoreBackgroundDeliveryError(_ error: Error) -> Bool {
    (error as NSError).localizedDescription.contains("Missing com.apple.developer.healthkit.background-delivery")
}

@MainActor
struct ConsentStore {
    private let context = PulsumData.viewContext
    private static let recordID = "default"
    private let consentVersion: String = {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }()

    func loadConsent() -> Bool {
        let request = UserPrefs.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", Self.recordID)
        if let existing = try? context.fetch(request).first {
            return existing.consentCloud
        }
        return false
    }

    func saveConsent(_ granted: Bool) {
        let request = UserPrefs.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", Self.recordID)
        let prefs: UserPrefs
        if let existing = try? context.fetch(request).first {
            prefs = existing
        } else {
            prefs = UserPrefs(context: context)
            prefs.id = Self.recordID
        }
        prefs.consentCloud = granted
        prefs.updatedAt = Date()
        do {
            persistConsentHistory(granted: granted)
            try context.save()
        } catch {
            context.rollback()
        }
    }

    private func persistConsentHistory(granted: Bool) {
        let request = ConsentState.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "version == %@", consentVersion)

        let record: ConsentState
        if let existing = try? context.fetch(request).first {
            record = existing
        } else {
            record = ConsentState(context: context)
            record.id = UUID()
            record.version = consentVersion
        }

        let timestamp = Date()
        if granted {
            record.grantedAt = timestamp
            record.revokedAt = nil
        } else {
            if record.grantedAt == nil {
                record.grantedAt = timestamp
            }
            record.revokedAt = timestamp
        }
    }
}
```

### Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift
```swift
import Foundation
import Observation
import PulsumAgents
import HealthKit
import PulsumTypes
import PulsumServices

@MainActor
@Observable
final class SettingsViewModel {
    @ObservationIgnored private var orchestrator: AgentOrchestrator?
    private(set) var foundationModelsStatus: String = ""
    var consentGranted: Bool
    var lastConsentUpdated: Date = Date()
    var healthKitDebugSummary: String = ""

    struct HealthAccessRow: Identifiable, Equatable {
        let id: String
        let title: String
        let detail: String
        let iconName: String
        let status: HealthAccessGrantState
    }

    // HealthKit State
    private(set) var healthKitSummary: String = "Checking..."
    private(set) var missingHealthKitDetail: String?
    private(set) var healthAccessRows: [HealthAccessRow] = HealthAccessRequirement.ordered.map {
        HealthAccessRow(id: $0.id,
                        title: $0.title,
                        detail: $0.detail,
                        iconName: $0.iconName,
                        status: .pending)
    }
    private(set) var showHealthKitUnavailableBanner: Bool = false
    private(set) var isRequestingHealthKitAuthorization: Bool = false
    private(set) var canRequestHealthKitAccess: Bool = true
    private(set) var healthKitError: String?
    private(set) var healthKitSuccessMessage: String?
    @ObservationIgnored private var healthKitSuccessTask: Task<Void, Never>?
    private var lastHealthAccessStatus: HealthAccessStatus?
    private var awaitingToastAfterRequest: Bool = false
    private var didApplyInitialStatus: Bool = false
    var debugLogSnapshot: String = ""

    // GPT-5 API Status
    private(set) var gptAPIStatus: String = "Missing API key"
    private(set) var isGPTAPIWorking: Bool = false
    var gptAPIKeyDraft: String = ""
    private(set) var isTestingAPIKey: Bool = false

    var onConsentChanged: ((Bool) -> Void)?

#if DEBUG
    var diagnosticsVisible: Bool = false
    var routeHistory: [String] = []
    var lastCoverageSummary: String = "—"
    var lastCloudError: String = "None"
    @ObservationIgnored private var routeTask: Task<Void, Never>?
    @ObservationIgnored private var errorTask: Task<Void, Never>?
    private let diagnosticsHistoryLimit = 5
#endif

    init(initialConsent: Bool) {
        self.consentGranted = initialConsent
#if DEBUG
        setupDiagnosticsObservers()
#endif
    }

    func bind(orchestrator: AgentOrchestrator) {
        self.orchestrator = orchestrator
        foundationModelsStatus = orchestrator.foundationModelsStatus
        if let stored = orchestrator.currentLLMAPIKey() {
            gptAPIKeyDraft = stored
            if !stored.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Task { await testCurrentAPIKey() }
            } else {
                gptAPIStatus = "Missing API key"
                isGPTAPIWorking = false
            }
        } else {
            gptAPIStatus = "Missing API key"
            isGPTAPIWorking = false
        }
        refreshHealthAccessStatus()
    }

    func refreshFoundationStatus() {
        guard let orchestrator else { return }
        foundationModelsStatus = orchestrator.foundationModelsStatus
    }

    func refreshHealthAccessStatus() {
        guard let orchestrator else {
            healthKitSummary = "Agent unavailable"
            canRequestHealthKitAccess = false
            return
        }
        Task { [weak self] in
            guard let self else { return }
            let status = await orchestrator.currentHealthAccessStatus()
            await MainActor.run {
                self.applyHealthStatus(status)
                self.healthKitDebugSummary = Self.debugSummary(from: status)
                self.debugLogSnapshot = ""
            }
        }
    }

    func requestHealthKitAuthorization() async {
        guard let orchestrator else {
            healthKitError = "Agent unavailable"
            return
        }
        isRequestingHealthKitAuthorization = true
        awaitingToastAfterRequest = true
        healthKitError = nil
        defer { isRequestingHealthKitAuthorization = false }

        do {
            let status = try await orchestrator.requestHealthAccess()
            applyHealthStatus(status)
            healthKitDebugSummary = Self.debugSummary(from: status)
        } catch let serviceError as HealthKitServiceError {
            healthKitError = serviceError.localizedDescription
            let status = await orchestrator.currentHealthAccessStatus()
            applyHealthStatus(status)
            healthKitDebugSummary = Self.debugSummary(from: status)
        } catch {
            healthKitError = error.localizedDescription
            let status = await orchestrator.currentHealthAccessStatus()
            applyHealthStatus(status)
            healthKitDebugSummary = Self.debugSummary(from: status)
        }
    }

    func refreshDebugLog() async {
        guard let orchestrator else {
            debugLogSnapshot = "Debug log unavailable (orchestrator not ready)"
            return
        }
        let snapshot = await orchestrator.debugLogSnapshot()
        await MainActor.run {
            debugLogSnapshot = snapshot.isEmpty ? "No events captured yet." : snapshot
        }
    }

    func toggleConsent(_ newValue: Bool) {
        guard consentGranted != newValue else { return }
        consentGranted = newValue
        lastConsentUpdated = Date()
        onConsentChanged?(newValue)
    }

    func refreshConsent(_ value: Bool) {
        consentGranted = value
        lastConsentUpdated = Date()
    }

    @MainActor
    func saveAPIKey(_ key: String) async {
        guard let orchestrator else {
            gptAPIStatus = "Agent unavailable"
            isGPTAPIWorking = false
            return
        }
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            gptAPIStatus = "Missing API key"
            isGPTAPIWorking = false
            return
        }
        gptAPIStatus = "Saving..."
        do {
            try orchestrator.setLLMAPIKey(trimmedKey)
            gptAPIKeyDraft = trimmedKey
            isGPTAPIWorking = false
            gptAPIStatus = "API key saved"
        } catch {
            isGPTAPIWorking = false
            gptAPIStatus = "Missing or invalid API key"
        }
    }

    @MainActor
    func testCurrentAPIKey() async {
        guard let orchestrator else {
            gptAPIStatus = "Agent unavailable"
            isGPTAPIWorking = false
            return
        }
        isTestingAPIKey = true
        defer { isTestingAPIKey = false }
        gptAPIStatus = "Testing..."
        isGPTAPIWorking = false
        do {
            let ok = try await orchestrator.testLLMAPIConnection()
            isGPTAPIWorking = ok
            gptAPIStatus = ok ? "OpenAI reachable" : "OpenAI ping failed"
        } catch {
            isGPTAPIWorking = false
            gptAPIStatus = "Missing or invalid API key"
        }
    }

    func makeScoreBreakdownViewModel() -> ScoreBreakdownViewModel? {
        guard let orchestrator else { return nil }
        return ScoreBreakdownViewModel(orchestrator: orchestrator)
    }

    private func applyHealthStatus(_ status: HealthAccessStatus) {
        let wasFullyGrantedOptional = lastHealthAccessStatus?.isFullyGranted
        lastHealthAccessStatus = status

        switch status.availability {
        case .available:
            if status.totalRequired > 0 {
                healthKitSummary = "\(status.grantedCount)/\(status.totalRequired) granted"
            } else {
                healthKitSummary = "Ready"
            }
            showHealthKitUnavailableBanner = false
            canRequestHealthKitAccess = true
            let missingTitles = status.missingTypes.compactMap { HealthAccessRequirement.descriptor(for: $0)?.title }
            if missingTitles.isEmpty {
                missingHealthKitDetail = nil
            } else {
                missingHealthKitDetail = "Missing: \(missingTitles.joined(separator: ", "))"
            }
        case .unavailable(let reason):
            healthKitSummary = "Health data unavailable"
            showHealthKitUnavailableBanner = true
            missingHealthKitDetail = reason
            canRequestHealthKitAccess = false
        }

        healthAccessRows = HealthAccessRequirement.ordered.map { descriptor in
            HealthAccessRow(id: descriptor.id,
                            title: descriptor.title,
                            detail: descriptor.detail,
                            iconName: descriptor.iconName,
                            status: rowStatus(for: descriptor.id, status: status))
        }

        let transitionedToFull = (wasFullyGrantedOptional == false) && status.isFullyGranted
        if status.isFullyGranted && (transitionedToFull || awaitingToastAfterRequest) && didApplyInitialStatus {
            awaitingToastAfterRequest = false
            emitHealthKitSuccessToast()
        } else if !status.isFullyGranted {
            cancelHealthKitSuccessToast()
        }

        if !didApplyInitialStatus {
            didApplyInitialStatus = true
        }
    }

    private func rowStatus(for identifier: String, status: HealthAccessStatus) -> HealthAccessGrantState {
        if status.granted.contains(where: { $0.identifier == identifier }) {
            return .granted
        }
        if status.denied.contains(where: { $0.identifier == identifier }) {
            return .denied
        }
        if status.notDetermined.contains(where: { $0.identifier == identifier }) {
            return .pending
        }
        return .pending
    }

    private func emitHealthKitSuccessToast() {
        healthKitSuccessMessage = "Health data connected"
        healthKitSuccessTask?.cancel()
        healthKitSuccessTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                self?.healthKitSuccessMessage = nil
            }
        }
    }

    private func cancelHealthKitSuccessToast() {
        healthKitSuccessTask?.cancel()
        healthKitSuccessTask = nil
        healthKitSuccessMessage = nil
    }

    func debugHealthStatusSnapshot() -> String {
        healthKitDebugSummary
    }

    private static func debugSummary(from status: HealthAccessStatus) -> String {
        let granted = status.granted.map(\.identifier).sorted().joined(separator: ", ")
        let denied = status.denied.map(\.identifier).sorted().joined(separator: ", ")
        let pending = status.notDetermined.map(\.identifier).sorted().joined(separator: ", ")
        return "Granted: [\(granted)] | Denied: [\(denied)] | Pending: [\(pending)] | Availability: \(status.availability)"
    }

#if DEBUG
    func toggleDiagnosticsVisibility() {
        diagnosticsVisible.toggle()
    }

    private func setupDiagnosticsObservers() {
        let center = NotificationCenter.default

        routeTask = Task { [weak self] in
            for await note in center.notifications(named: .pulsumChatRouteDiagnostics) {
                guard let self else { continue }
                await MainActor.run {
                    if let route = note.userInfo?["route"] as? String {
                        routeHistory.insert(route, at: 0)
                        if routeHistory.count > diagnosticsHistoryLimit {
                            routeHistory.removeLast(routeHistory.count - diagnosticsHistoryLimit)
                        }
                    }

                    if let top = note.userInfo?["top"] as? Double,
                       let median = note.userInfo?["median"] as? Double,
                       let count = note.userInfo?["count"] as? Int {
                        lastCoverageSummary = "matches=\(count) top=\(String(format: "%.2f", top)) median=\(String(format: "%.2f", median))"
                    } else {
                        lastCoverageSummary = "–"
                    }
                }
            }
        }

        errorTask = Task { [weak self] in
            for await note in center.notifications(named: .pulsumChatCloudError) {
                guard let self else { continue }
                await MainActor.run {
                    if let message = note.userInfo?["message"] as? String {
                        lastCloudError = message
                    }
                }
            }
        }
    }

    deinit {
        routeTask?.cancel()
        errorTask?.cancel()
    }
#endif
}
```

### Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift
```swift
import SwiftUI
import Observation
import PulsumAgents
#if canImport(UIKit)
import UIKit
#endif

struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Bindable var viewModel: SettingsViewModel
    let wellbeingState: WellbeingScoreState

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: PulsumSpacing.lg) {
                    // Wellbeing Score Display (moved from MainView)
                    wellbeingScoreSection

                    // Cloud Processing Section
                    VStack(alignment: .leading, spacing: PulsumSpacing.md) {
                        Text("Cloud Processing")
                            .font(.pulsumHeadline)
                            .foregroundStyle(Color.pulsumTextPrimary)
                            .padding(.horizontal, PulsumSpacing.lg)

                        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
                            Toggle(isOn: Binding(
                                get: { viewModel.consentGranted },
                                set: { viewModel.toggleConsent($0) }
                            )) {
                                VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                                    Text("Use GPT-5 phrasing")
                                        .font(.pulsumBody)
                                        .foregroundStyle(Color.pulsumTextPrimary)
                                    Text("Pulsum only sends minimized context (no journals, no identifiers, no raw health samples). Turn this off anytime.")
                                        .font(.pulsumCaption)
                                        .foregroundStyle(Color.pulsumTextSecondary)
                                        .lineSpacing(2)
                                }
                            }
                            .tint(Color.pulsumGreenSoft)

                            if let updated = relativeDate(for: viewModel.lastConsentUpdated) {
                                Text("Updated \(updated)")
                                    .font(.pulsumFootnote)
                                    .foregroundStyle(Color.pulsumTextTertiary)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: PulsumSpacing.sm) {
                                VStack(alignment: .leading, spacing: PulsumSpacing.xs) {
                                    Text("GPT-5 API Key")
                                        .font(.pulsumCallout.weight(.semibold))
                                        .foregroundStyle(Color.pulsumTextPrimary)
                                    SecureField("sk-...", text: $viewModel.gptAPIKeyDraft)
                                        .textFieldStyle(.roundedBorder)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .font(.pulsumBody)
                                        .foregroundStyle(Color.pulsumTextPrimary)
                                        .accessibilityIdentifier("CloudAPIKeyField")
                                }

                                HStack(spacing: PulsumSpacing.sm) {
                                    Button {
                                        Task { await viewModel.saveAPIKey(viewModel.gptAPIKeyDraft) }
                                    } label: {
                                        Text("Save Key")
                                            .font(.pulsumCallout.weight(.semibold))
                                            .foregroundStyle(Color.pulsumTextPrimary)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .glassEffect(.regular.tint(Color.pulsumGreenSoft.opacity(0.6)).interactive())
                                    .accessibilityIdentifier("CloudAPISaveButton")
                                    .disabled(viewModel.gptAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isTestingAPIKey)

                                    Button {
                                        Task { await viewModel.testCurrentAPIKey() }
                                    } label: {
                                        if viewModel.isTestingAPIKey {
                                            ProgressView()
                                                .progressViewStyle(.circular)
                                                .tint(Color.pulsumTextPrimary)
                                                .frame(maxWidth: .infinity)
                                        } else {
                                            Text("Test Connection")
                                                .font(.pulsumCallout.weight(.semibold))
                                                .foregroundStyle(Color.pulsumTextPrimary)
                                                .frame(maxWidth: .infinity)
                                        }
                                    }
                                    .glassEffect(.regular.tint(Color.pulsumBlueSoft.opacity(0.5)).interactive())
                                    .disabled(viewModel.isTestingAPIKey)
                                    .accessibilityIdentifier("CloudAPITestButton")
                                }

                                HStack(spacing: PulsumSpacing.sm) {
                                    gptStatusBadge(isWorking: viewModel.isGPTAPIWorking,
                                                   status: viewModel.gptAPIStatus)
                                    Text(viewModel.gptAPIStatus)
                                        .font(.pulsumFootnote)
                                        .foregroundStyle(Color.pulsumTextSecondary)
                                        .lineSpacing(2)
                                        .accessibilityIdentifier("CloudAPIStatusText")
                                }
                            }
                        }
                        .padding(PulsumSpacing.lg)
                        .background(Color.pulsumCardWhite)
                        .cornerRadius(PulsumRadius.xl)
                        .shadow(
                            color: PulsumShadow.small.color,
                            radius: PulsumShadow.small.radius,
                            x: PulsumShadow.small.x,
                            y: PulsumShadow.small.y
                        )
                    }

                    // HealthKit Section
                    VStack(alignment: .leading, spacing: PulsumSpacing.md) {
                        Text("Apple HealthKit")
                            .font(.pulsumHeadline)
                            .foregroundStyle(Color.pulsumTextPrimary)
                            .padding(.horizontal, PulsumSpacing.lg)

                        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
                            HStack(alignment: .top, spacing: PulsumSpacing.sm) {
                                Image(systemName: "heart.text.square.fill")
                                    .font(.pulsumTitle3)
                                    .foregroundStyle(Color.pulsumPinkSoft)
                                    .symbolRenderingMode(.hierarchical)
                                VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                                    Text("Health Data Access")
                                        .font(.pulsumHeadline)
                                        .foregroundStyle(Color.pulsumTextPrimary)
                                    Text(viewModel.healthKitSummary)
                                        .font(.pulsumCallout)
                                        .foregroundStyle(Color.pulsumTextSecondary)
                                        .lineSpacing(2)
                                        .accessibilityIdentifier("HealthAccessSummaryLabel")
                                }
                            }

                            if let detail = viewModel.missingHealthKitDetail {
                                Text(detail)
                                    .font(.pulsumCaption)
                                    .foregroundStyle(Color.pulsumTextSecondary)
                                    .padding(.horizontal, PulsumSpacing.xs)
                                    .padding(.vertical, PulsumSpacing.xxs)
                                    .background(Color.pulsumBackgroundCream.opacity(0.6))
                                    .cornerRadius(PulsumRadius.sm)
                                    .accessibilityIdentifier("HealthAccessMissingLabel")
                            }

                            if viewModel.showHealthKitUnavailableBanner {
                                HStack(spacing: PulsumSpacing.xs) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.pulsumCaption)
                                        .foregroundStyle(Color.pulsumWarning)
                                    Text("Health data is unavailable on this device.")
                                        .font(.pulsumCaption)
                                        .foregroundStyle(Color.pulsumWarning)
                                }
                                .padding(.horizontal, PulsumSpacing.sm)
                                .padding(.vertical, PulsumSpacing.xs)
                                .background(Color.pulsumWarning.opacity(0.1))
                                .cornerRadius(PulsumRadius.sm)
                            }

                            if let success = viewModel.healthKitSuccessMessage {
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(Color.pulsumGreenSoft)
                                    Text(success)
                                        .font(.pulsumCaption)
                                        .foregroundStyle(Color.pulsumGreenSoft)
                                    Spacer()
                                }
                                .padding(.horizontal, PulsumSpacing.sm)
                                .padding(.vertical, PulsumSpacing.xs)
                                .background(Color.pulsumGreenSoft.opacity(0.12))
                                .cornerRadius(PulsumRadius.sm)
                            }

                            Divider()
                                .padding(.vertical, PulsumSpacing.xs)

                            VStack(spacing: PulsumSpacing.sm) {
                                ForEach(viewModel.healthAccessRows) { row in
                                    HStack(spacing: PulsumSpacing.sm) {
                                        Image(systemName: row.iconName)
                                            .font(.pulsumTitle3)
                                            .foregroundStyle(Color.pulsumTextPrimary.opacity(0.7))
                                        VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                                            Text(row.title)
                                                .font(.pulsumCallout.weight(.semibold))
                                                .foregroundStyle(Color.pulsumTextPrimary)
                                            Text(row.detail)
                                                .font(.pulsumFootnote)
                                                .foregroundStyle(Color.pulsumTextSecondary)
                                        }
                                        Spacer()
                                        statusBadge(for: row.status)
                                    }
                                    .padding(.vertical, PulsumSpacing.xs)
                                    .accessibilityIdentifier("HealthAccessRow-\(row.id)")
                                }
                            }

                            if let error = viewModel.healthKitError {
                                HStack(spacing: PulsumSpacing.xs) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.pulsumCaption)
                                        .foregroundStyle(Color.pulsumWarning)
                                    Text(error)
                                        .font(.pulsumCaption)
                                        .foregroundStyle(Color.pulsumWarning)
                                }
                                .padding(.horizontal, PulsumSpacing.sm)
                                .padding(.vertical, PulsumSpacing.xs)
                                .background(Color.pulsumWarning.opacity(0.1))
                                .cornerRadius(PulsumRadius.sm)
                            }

                            Divider()
                                .padding(.vertical, PulsumSpacing.xs)

                            Button {
                                Task {
                                    await viewModel.requestHealthKitAuthorization()
                                }
                            } label: {
                                HStack {
                                    if viewModel.isRequestingHealthKitAuthorization {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .tint(Color.pulsumTextPrimary)
                                        Text("Requesting...")
                                            .font(.pulsumCallout.weight(.semibold))
                                            .foregroundStyle(Color.pulsumTextPrimary)
                                    } else {
                                        Text("Request Health Data Access")
                                            .font(.pulsumCallout.weight(.semibold))
                                            .foregroundStyle(Color.pulsumTextPrimary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, PulsumSpacing.sm)
                            }
                                    .glassEffect(.regular.tint(Color.pulsumPinkSoft.opacity(0.6)).interactive())
                                    .disabled(viewModel.isRequestingHealthKitAuthorization || !viewModel.canRequestHealthKitAccess)
                                    .accessibilityIdentifier("HealthAccessRequestButton")

                                Text("Pulsum needs access to Heart Rate Variability, Heart Rate, Resting Heart Rate, Respiratory Rate, Steps, and Sleep data to provide personalized recovery recommendations.")
                                    .font(.pulsumFootnote)
                                    .foregroundStyle(Color.pulsumTextSecondary)
                                    .lineSpacing(3)

                                Divider()
                                    .padding(.vertical, PulsumSpacing.xs)

                            VStack(alignment: .leading, spacing: PulsumSpacing.xs) {
                                Text("Health access status")
                                    .font(.pulsumFootnote.weight(.semibold))
                                    .foregroundStyle(Color.pulsumTextSecondary)
                                Text(viewModel.healthKitDebugSummary.isEmpty ? "Tap Refresh to fetch status" : viewModel.healthKitDebugSummary)
                                    .font(.system(.footnote, design: .monospaced))
                                    .foregroundStyle(Color.pulsumTextPrimary)
                                    .textSelection(.enabled)
                                    .accessibilityIdentifier("HealthAccessDebugSummaryLabel")
                                HStack(spacing: PulsumSpacing.sm) {
                                    Button("Refresh Status") {
                                        viewModel.refreshHealthAccessStatus()
                                    }
                                    .font(.pulsumFootnote.weight(.semibold))
                                    .foregroundStyle(Color.pulsumTextPrimary)
                                    .glassEffect(.regular.tint(Color.pulsumBlueSoft.opacity(0.5)).interactive())
                                    Button("Copy") {
                                        copyToClipboard(viewModel.healthKitDebugSummary)
                                    }
                                    .font(.pulsumFootnote.weight(.semibold))
                                    .foregroundStyle(Color.pulsumTextPrimary)
                                    .glassEffect(.regular.tint(Color.pulsumTextSecondary.opacity(0.3)).interactive())
                                    .accessibilityIdentifier("HealthAccessCopyButton")
                                }
                            }

                            Divider()
                                .padding(.vertical, PulsumSpacing.xs)

                            VStack(alignment: .leading, spacing: PulsumSpacing.xs) {
                                Text("App debug log")
                                    .font(.pulsumFootnote.weight(.semibold))
                                    .foregroundStyle(Color.pulsumTextSecondary)
                                Text(viewModel.debugLogSnapshot.isEmpty ? "Tap Refresh Log to capture recent events" : viewModel.debugLogSnapshot)
                                    .font(.system(.footnote, design: .monospaced))
                                    .foregroundStyle(Color.pulsumTextPrimary)
                                    .textSelection(.enabled)
                                    .accessibilityIdentifier("DebugLogSnapshotLabel")
                                    .frame(maxHeight: 160, alignment: .topLeading)
                                    .lineLimit(nil)
                                HStack(spacing: PulsumSpacing.sm) {
                                    Button("Refresh Log") {
                                        Task { await viewModel.refreshDebugLog() }
                                    }
                                    .font(.pulsumFootnote.weight(.semibold))
                                    .foregroundStyle(Color.pulsumTextPrimary)
                                    .glassEffect(.regular.tint(Color.pulsumBlueSoft.opacity(0.5)).interactive())
                                    Button("Copy Log") {
                                        copyToClipboard(viewModel.debugLogSnapshot)
                                    }
                                    .font(.pulsumFootnote.weight(.semibold))
                                    .foregroundStyle(Color.pulsumTextPrimary)
                                    .glassEffect(.regular.tint(Color.pulsumTextSecondary.opacity(0.3)).interactive())
                                    .accessibilityIdentifier("DebugLogCopyButton")
                                }
                            }
                        }
                        .padding(PulsumSpacing.lg)
                        .background(Color.pulsumCardWhite)
                        .cornerRadius(PulsumRadius.xl)
                        .shadow(
                            color: PulsumShadow.small.color,
                            radius: PulsumShadow.small.radius,
                            x: PulsumShadow.small.x,
                            y: PulsumShadow.small.y
                        )
                    }

                    // AI Models Section
                    VStack(alignment: .leading, spacing: PulsumSpacing.md) {
                        Text("AI Models")
                            .font(.pulsumHeadline)
                            .foregroundStyle(Color.pulsumTextPrimary)
                            .padding(.horizontal, PulsumSpacing.lg)

                        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
                            // Apple Intelligence
                            HStack(alignment: .top, spacing: PulsumSpacing.sm) {
                                Image(systemName: "sparkles")
                                    .font(.pulsumTitle3)
                                    .foregroundStyle(Color.pulsumBlueSoft)
                                VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                                    Text("Apple Intelligence")
                                        .font(.pulsumHeadline)
                                        .foregroundStyle(Color.pulsumTextPrimary)
                                    Text(viewModel.foundationModelsStatus)
                                        .font(.pulsumCallout)
                                        .foregroundStyle(Color.pulsumTextSecondary)
                                        .lineSpacing(2)
                                }
                            }

                            if needsEnableLink(status: viewModel.foundationModelsStatus) {
#if os(macOS)
                                Link(destination: URL(string: "x-apple.systempreferences:com.apple.AppleIntelligence-Settings")!) {
                                    appleIntelligenceLinkContent()
                                }
#else
                                Button {
                                    openAppleIntelligenceSettings()
                                } label: {
                                    appleIntelligenceLinkContent()
                                }
                                .accessibilityIdentifier("AppleIntelligenceLinkButton")
#endif
                            }

                        }
                        .padding(PulsumSpacing.lg)
                        .background(Color.pulsumCardWhite)
                        .cornerRadius(PulsumRadius.xl)
                        .shadow(
                            color: PulsumShadow.small.color,
                            radius: PulsumShadow.small.radius,
                            x: PulsumShadow.small.x,
                            y: PulsumShadow.small.y
                        )
                    }

                    // Safety Section
                    VStack(alignment: .leading, spacing: PulsumSpacing.md) {
                        Text("Safety")
                            .font(.pulsumHeadline)
                            .foregroundStyle(Color.pulsumTextPrimary)
                            .padding(.horizontal, PulsumSpacing.lg)

                        VStack(spacing: PulsumSpacing.sm) {
                            Link(destination: URL(string: "tel://911")!) {
                                HStack {
                                    Text("If you're in crisis, dial 911")
                                        .font(.pulsumBody)
                                        .foregroundStyle(Color.pulsumError)
                                    Spacer()
                                    Image(systemName: "phone.fill")
                                        .foregroundStyle(Color.pulsumError)
                                }
                            }

                            Divider()

                            Link(destination: URL(string: "tel://988")!) {
                                HStack {
                                    Text("988 Suicide & Crisis Lifeline")
                                        .font(.pulsumBody)
                                        .foregroundStyle(Color.pulsumTextPrimary)
                                    Spacer()
                                    Image(systemName: "phone.fill")
                                        .foregroundStyle(Color.pulsumTextSecondary)
                                }
                            }
                        }
                        .padding(PulsumSpacing.lg)
                        .background(Color.pulsumCardWhite)
                        .cornerRadius(PulsumRadius.xl)
                        .shadow(
                            color: PulsumShadow.small.color,
                            radius: PulsumShadow.small.radius,
                            x: PulsumShadow.small.x,
                            y: PulsumShadow.small.y
                        )
                    }

                    // Privacy Section
                    VStack(alignment: .leading, spacing: PulsumSpacing.md) {
                        Text("Privacy")
                            .font(.pulsumHeadline)
                            .foregroundStyle(Color.pulsumTextPrimary)
                            .padding(.horizontal, PulsumSpacing.lg)

                        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
                            Link(destination: URL(string: "https://pulsum.ai/privacy")!) {
                                HStack {
                                    Text("Privacy policy")
                                        .font(.pulsumBody)
                                        .foregroundStyle(Color.pulsumBlueSoft)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.pulsumCaption)
                                        .foregroundStyle(Color.pulsumTextSecondary)
                                }
                            }

                            Text("Pulsum stores all health data on-device with NSFileProtectionComplete and never uploads your journals.")
                                .font(.pulsumFootnote)
                                .foregroundStyle(Color.pulsumTextSecondary)
                                .lineSpacing(3)
                        }
                        .padding(PulsumSpacing.lg)
                        .background(Color.pulsumCardWhite)
                        .cornerRadius(PulsumRadius.xl)
                        .shadow(
                            color: PulsumShadow.small.color,
                            radius: PulsumShadow.small.radius,
                            x: PulsumShadow.small.x,
                            y: PulsumShadow.small.y
                        )
                    }

#if DEBUG
                    if viewModel.diagnosticsVisible {
                        DiagnosticsPanel(routeHistory: viewModel.routeHistory,
                                         coverageSummary: viewModel.lastCoverageSummary,
                                         cloudError: viewModel.lastCloudError,
                                         healthStatusSummary: viewModel.healthKitDebugSummary)
                            .transition(.opacity)
                    }
#endif
                }
                .padding(PulsumSpacing.lg)
                .padding(.bottom, PulsumSpacing.xxl)
            }
            .background(Color.pulsumBackgroundBeige.ignoresSafeArea())
#if DEBUG
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.pulsumHeadline)
                        .foregroundStyle(Color.pulsumTextPrimary)
                        .onTapGesture(count: 3) {
                            viewModel.toggleDiagnosticsVisibility()
                        }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.pulsumTextSecondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .accessibilityLabel("Close Settings")
                }
            }
            .toolbarBackground(.automatic, for: .navigationBar)
#else
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.pulsumTextSecondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .accessibilityLabel("Close Settings")
                }
            }
            .toolbarBackground(.automatic, for: .navigationBar)
#endif
            .task {
                viewModel.refreshFoundationStatus()
                viewModel.refreshHealthAccessStatus()
                await viewModel.testCurrentAPIKey()
            }
            .onEscapeDismiss {
                dismiss()
            }
        }
    }

    private func needsEnableLink(status: String) -> Bool {
        status.localizedCaseInsensitiveContains("enable") || status.localizedCaseInsensitiveContains("require")
    }

    private func copyToClipboard(_ text: String) {
#if canImport(UIKit)
        UIPasteboard.general.string = text
#endif
    }

    @ViewBuilder
    private var wellbeingScoreSection: some View {
        switch wellbeingState {
        case let .ready(score, _):
            if let detailViewModel = viewModel.makeScoreBreakdownViewModel() {
                NavigationLink {
                    ScoreBreakdownScreen(viewModel: detailViewModel)
                } label: {
                    WellbeingScoreCard(score: score)
                }
                .buttonStyle(.plain)
            } else {
                WellbeingScoreCard(score: score)
            }
        case .loading:
            WellbeingScoreLoadingCard()
        case let .noData(reason):
            WellbeingNoDataCard(reason: reason) {
                Task { await viewModel.requestHealthKitAuthorization() }
            }
        case let .error(message):
            WellbeingErrorCard(message: message)
        }
    }

    private func relativeDate(for date: Date) -> String? {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    @ViewBuilder
    private func appleIntelligenceLinkContent() -> some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
            HStack(spacing: PulsumSpacing.xs) {
                Text("Enable Apple Intelligence in Settings")
                    .font(.pulsumCallout)
                    .foregroundStyle(Color.pulsumBlueSoft)
                Image(systemName: "arrow.up.right")
                    .font(.pulsumCaption)
                    .foregroundStyle(Color.pulsumBlueSoft)
            }
            Text("Opens system Settings so you can turn on Apple Intelligence for GPT-5 routing.")
                .font(.pulsumFootnote)
                .foregroundStyle(Color.pulsumTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func statusBadge(for status: HealthAccessGrantState) -> some View {
        let (icon, color, label): (String, Color, String) = {
            switch status {
            case .granted:
                return ("checkmark.circle.fill", Color.pulsumGreenSoft, "Granted")
            case .denied:
                return ("xmark.circle.fill", Color.pulsumWarning, "Denied")
            case .pending:
                return ("questionmark.circle", Color.pulsumTextSecondary, "Pending")
            }
        }()

        HStack(spacing: PulsumSpacing.xxs) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)
            Text(label)
                .font(.pulsumCaption.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, PulsumSpacing.xs)
        .padding(.vertical, PulsumSpacing.xxs)
        .background(color.opacity(0.12))
        .cornerRadius(PulsumRadius.sm)
        .accessibilityIdentifier("CloudAPIStatusBadge")
    }

    private func gptStatusBadge(isWorking: Bool, status: String) -> some View {
        let (label, color): (String, Color) = {
            if isWorking {
                return ("OK", Color.pulsumGreenSoft)
            }
            if status.localizedCaseInsensitiveContains("missing") {
                return ("Missing", Color.pulsumTextSecondary)
            }
            return ("Check", Color.pulsumWarning)
        }()
        return HStack(spacing: PulsumSpacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.pulsumCaption.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, PulsumSpacing.xs)
        .padding(.vertical, PulsumSpacing.xxs)
        .background(color.opacity(0.12))
        .cornerRadius(PulsumRadius.sm)
    }

    private func openAppleIntelligenceSettings() {
        let forceFallback = ProcessInfo.processInfo.environment["UITEST_FORCE_SETTINGS_FALLBACK"] == "1"
#if canImport(UIKit)
        if !forceFallback,
           let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL, options: [:]) { success in
                if success {
                    logOpenedURL(settingsURL)
                } else {
                    openSupportArticle()
                }
            }
            return
        }
#endif
        openSupportArticle()
    }

    private func logOpenedURL(_ url: URL) {
        guard ProcessInfo.processInfo.environment["UITEST_CAPTURE_URLS"] == "1" else { return }
        let defaults = UserDefaults(suiteName: "ai.pulsum.uiautomation")
        defaults?.set(url.absoluteString, forKey: "LastOpenedURL")
    }

    private func openSupportArticle() {
        guard let supportURL = URL(string: "https://support.apple.com/en-us/HT213969") else { return }
        logOpenedURL(supportURL)
        _ = openURL(supportURL)
    }
}

private extension View {
    func onEscapeDismiss(_ action: @escaping () -> Void) -> some View {
        Group {
            if #available(iOS 17.0, macOS 14.0, *) {
                self.onKeyPress(.escape) {
                    action()
                    return .handled
                }
            } else {
                self
            }
        }
    }
}

#if DEBUG
private struct DiagnosticsPanel: View {
    let routeHistory: [String]
    let coverageSummary: String
    let cloudError: String
    let healthStatusSummary: String

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            Text("Diagnostics")
                .font(.pulsumHeadline)
                .foregroundStyle(Color.pulsumTextPrimary)

            VStack(alignment: .leading, spacing: PulsumSpacing.sm) {
                Text("Last routes")
                    .font(.pulsumCallout.weight(.semibold))
                    .foregroundStyle(Color.pulsumTextSecondary)

                if routeHistory.isEmpty {
                    Text("No recent routing data")
                        .font(.pulsumCaption)
                        .foregroundStyle(Color.pulsumTextTertiary)
                } else {
                    ForEach(routeHistory, id: \.self) { line in
                        Text(line)
                            .font(.pulsumCaption)
                            .foregroundStyle(Color.pulsumTextSecondary)
                    }
                }

                Text("Coverage: \(coverageSummary)")
                    .font(.pulsumCaption)
                    .foregroundStyle(Color.pulsumTextSecondary)

                Text("Health access: \(healthStatusSummary)")
                    .font(.pulsumCaption)
                    .foregroundStyle(Color.pulsumTextSecondary)
                    .textSelection(.enabled)

                Text("Last cloud error: \(cloudError)")
                    .font(.pulsumCaption)
                    .foregroundStyle(Color.pulsumWarning)
                    .lineLimit(3)
            }
        }
        .padding(PulsumSpacing.lg)
        .background(Color.pulsumCardWhite)
        .cornerRadius(PulsumRadius.xl)
        .shadow(
            color: PulsumShadow.small.color,
            radius: PulsumShadow.small.radius,
            x: PulsumShadow.small.x,
            y: PulsumShadow.small.y
        )
        .overlay(alignment: .topLeading) {
            Text("DEBUG")
                .font(.pulsumCaption2.weight(.bold))
                .foregroundStyle(Color.pulsumBlueSoft)
                .padding(.horizontal, PulsumSpacing.xs)
                .padding(.vertical, PulsumSpacing.xxs)
        }
        .accessibilityIdentifier("DiagnosticsPanel")
    }
}
#endif

// MARK: - Wellbeing Score Loading Card
struct WellbeingScoreLoadingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                Text("Wellbeing score")
                    .font(.pulsumHeadline)
                    .foregroundStyle(Color.pulsumTextPrimary)
                Text("Calculated nightly from your data")
                    .font(.pulsumCaption)
                    .foregroundStyle(Color.pulsumTextSecondary)
            }

            HStack(alignment: .center, spacing: PulsumSpacing.lg) {
                VStack(alignment: .leading, spacing: PulsumSpacing.xs) {
                    HStack(spacing: PulsumSpacing.sm) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.pulsumGreenSoft)
                        Text("Calculating...")
                            .font(.pulsumTitle)
                            .foregroundStyle(Color.pulsumTextSecondary)
                    }
                    Text("Complete your first Pulse check-in")
                        .font(.pulsumCallout)
                        .foregroundStyle(Color.pulsumTextSecondary)
                }
                Spacer()
            }

            Text("Your score will appear here after your first nightly sync. Record a Pulse check-in to begin tracking your wellbeing.")
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumTextSecondary)
                .lineSpacing(2)
        }
        .padding(PulsumSpacing.lg)
        .background(Color.pulsumCardWhite)
        .cornerRadius(PulsumRadius.xl)
        .shadow(
            color: PulsumShadow.medium.color,
            radius: PulsumShadow.medium.radius,
            x: PulsumShadow.medium.x,
            y: PulsumShadow.medium.y
        )
    }
}

struct WellbeingNoDataCard: View {
    let reason: WellbeingNoDataReason
    var requestAccess: (() -> Void)?

    private var copy: (title: String, detail: String) {
        switch reason {
        case .healthDataUnavailable:
            return ("Health data unavailable",
                    "Health data is not available on this device. Try again on a device with Health access.")
        case .permissionsDeniedOrPending:
            return ("Health access needed",
                    "Pulsum needs permission to read Heart Rate Variability, Heart Rate, Resting Heart Rate, Respiratory Rate, Steps, and Sleep to compute your score.")
        case .insufficientSamples:
            return ("Waiting for data",
                    "We don't have enough recent Health data yet. Record a Pulse check-in or allow some time for HealthKit to sync.")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                Text("Wellbeing score")
                    .font(.pulsumHeadline)
                Text(copy.title)
                    .font(.pulsumTitle3)
                    .foregroundStyle(Color.pulsumTextPrimary)
                Text(copy.detail)
                    .font(.pulsumCallout)
                    .foregroundStyle(Color.pulsumTextSecondary)
                    .lineSpacing(2)
            }

            if let requestAccess, reason == .permissionsDeniedOrPending {
                Button {
                    requestAccess()
                } label: {
                    Text("Request Health Data Access")
                        .font(.pulsumCallout.weight(.semibold))
                        .foregroundStyle(Color.pulsumTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PulsumSpacing.sm)
                }
                .glassEffect(.regular.tint(Color.pulsumPinkSoft.opacity(0.6)).interactive())
            }
        }
        .padding(PulsumSpacing.lg)
        .background(Color.pulsumCardWhite)
        .cornerRadius(PulsumRadius.xl)
        .shadow(
            color: PulsumShadow.medium.color,
            radius: PulsumShadow.medium.radius,
            x: PulsumShadow.medium.x,
            y: PulsumShadow.medium.y
        )
    }
}

struct WellbeingErrorCard: View {
    let message: String
    var retry: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                Text("Wellbeing score")
                    .font(.pulsumHeadline)
                Text("Something went wrong")
                    .font(.pulsumTitle3)
                    .foregroundStyle(Color.pulsumWarning)
                Text(message)
                    .font(.pulsumCallout)
                    .foregroundStyle(Color.pulsumTextSecondary)
                    .lineSpacing(2)
            }

            if let retry {
                Button {
                    retry()
                } label: {
                    Text("Try again")
                        .font(.pulsumCallout.weight(.semibold))
                        .foregroundStyle(Color.pulsumTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PulsumSpacing.sm)
                }
                .glassEffect(.regular.tint(Color.pulsumBlueSoft.opacity(0.6)).interactive())
            }
        }
        .padding(PulsumSpacing.lg)
        .background(Color.pulsumCardWhite)
        .cornerRadius(PulsumRadius.xl)
        .shadow(
            color: PulsumShadow.medium.color,
            radius: PulsumShadow.medium.radius,
            x: PulsumShadow.medium.x,
            y: PulsumShadow.medium.y
        )
    }
}

// MARK: - Wellbeing Score Card
struct WellbeingScoreCard: View {
    let score: Double

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                Text("Wellbeing score")
                    .font(.pulsumHeadline)
                    .foregroundStyle(Color.pulsumTextPrimary)
                Text("Calculated nightly from your data")
                    .font(.pulsumCaption)
                    .foregroundStyle(Color.pulsumTextSecondary)
            }

            HStack(alignment: .center, spacing: PulsumSpacing.lg) {
                VStack(alignment: .leading, spacing: PulsumSpacing.xs) {
                    Text(score.formatted(.number.precision(.fractionLength(2))))
                        .font(.pulsumDataLarge)
                        .foregroundStyle(scoreColor)
                    Text(interpretedScore)
                        .font(.pulsumCallout)
                        .foregroundStyle(Color.pulsumTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.pulsumTitle3)
                    .foregroundStyle(Color.pulsumTextTertiary)
            }

            Text("Tap for the full breakdown, including objective recovery signals and your subjective check-in inputs.")
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumTextSecondary)
                .lineSpacing(2)
        }
        .padding(PulsumSpacing.lg)
        .background(Color.pulsumCardWhite)
        .cornerRadius(PulsumRadius.xl)
        .shadow(
            color: PulsumShadow.medium.color,
            radius: PulsumShadow.medium.radius,
            x: PulsumShadow.medium.x,
            y: PulsumShadow.medium.y
        )
    }

    private var scoreColor: Color {
        switch score {
        case ..<(-1): return Color.pulsumWarning
        case -1..<0.5: return Color.pulsumTextSecondary
        case 0.5..<1.5: return Color.pulsumGreenSoft
        default: return Color.pulsumSuccess
        }
    }

    private var interpretedScore: String {
        switch score {
        case ..<(-1): return "Let's go gentle today"
        case -1..<0.5: return "Maintaining base"
        case 0.5..<1.5: return "Positive momentum"
        default: return "Strong recovery"
        }
    }
}
```

### Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownView.swift
```swift
import SwiftUI
import PulsumAgents

struct ScoreBreakdownScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ScoreBreakdownViewModel

    init(viewModel: ScoreBreakdownViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulsumBackgroundBeige.ignoresSafeArea()

                if viewModel.isLoading && viewModel.breakdown == nil {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: PulsumSpacing.lg) {
                            if let breakdown = viewModel.breakdown {
                                SummaryCard(breakdown: breakdown)

                                if let highlights = viewModel.recommendationHighlights {
                                    RecommendationLogicCard(highlights: highlights)
                                }

                                if !viewModel.objectiveMetrics.isEmpty {
                                    MetricSection(title: "Objective signals",
                                                  caption: "Physiological measures compared against your rolling baseline.",
                                                  metrics: viewModel.objectiveMetrics)
                                }

                                if !viewModel.subjectiveMetrics.isEmpty {
                                    MetricSection(title: "Subjective check-in",
                                                  caption: "Sliders you provided during today's pulse.",
                                                  metrics: viewModel.subjectiveMetrics)
                                }

                                if !viewModel.sentimentMetrics.isEmpty {
                                    MetricSection(title: "Journal + sentiment",
                                                  caption: "On-device analysis of your latest journal entry.",
                                                  metrics: viewModel.sentimentMetrics)
                                }

                                if !breakdown.generalNotes.isEmpty {
                                    NotesCard(notes: breakdown.generalNotes)
                                }
                            } else if let message = viewModel.errorMessage {
                                ErrorStateView(message: message)
                            } else {
                                EmptyStateView()
                            }
                        }
                        .padding(.horizontal, PulsumSpacing.lg)
                        .padding(.bottom, PulsumSpacing.xxl)
                    }
                }
            }
            .navigationTitle("Score details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.pulsumTextSecondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .toolbarBackground(.automatic, for: .navigationBar)
            .task {
                await viewModel.refresh()
            }
        }
    }
}

private struct SummaryCard: View {
    let breakdown: ScoreBreakdown

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: breakdown.date)
    }

    private var topPositiveDriver: ScoreBreakdown.MetricDetail? {
        breakdown.metrics.max(by: { $0.contribution < $1.contribution })
    }

    private var topNegativeDriver: ScoreBreakdown.MetricDetail? {
        breakdown.metrics.min(by: { $0.contribution < $1.contribution })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.lg) {
            VStack(alignment: .leading, spacing: PulsumSpacing.xs) {
                Text("Today's wellbeing score")
                    .font(.pulsumHeadline)
                    .foregroundStyle(Color.pulsumTextPrimary)
                Text(dateString)
                    .font(.pulsumCaption)
                    .foregroundStyle(Color.pulsumTextSecondary)
            }

            VStack(spacing: PulsumSpacing.xs) {
                Text(breakdown.wellbeingScore.formatted(.number.precision(.fractionLength(2))))
                    .font(.pulsumDataXLarge)
                    .foregroundStyle(scoreColor(breakdown.wellbeingScore))
                Text(summaryCopy(for: breakdown.wellbeingScore))
                    .font(.pulsumCallout)
                    .foregroundStyle(Color.pulsumTextSecondary)
            }

            VStack(alignment: .leading, spacing: PulsumSpacing.xs) {
                Text("Top drivers")
                    .font(.pulsumSubheadline)
                    .foregroundStyle(Color.pulsumTextSecondary)
                VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                    if let positive = topPositiveDriver, positive.contribution > 0 {
                        DriverRow(prefix: "Lift", metric: positive, color: Color.pulsumGreenSoft)
                    }
                    if let negative = topNegativeDriver, negative.contribution < 0 {
                        DriverRow(prefix: "Drag", metric: negative, color: Color.pulsumWarning)
                    }
                }
            }

            Text("The score is a weighted blend of physiological z-scores, subjective sliders, and journal sentiment. Each contribution shown below is the weight × today's normalized value.")
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumTextSecondary)
                .lineSpacing(2)
        }
        .pulsumCardStyle()
    }

    private func scoreColor(_ value: Double) -> Color {
        switch value {
        case ..<(-1): return Color.pulsumWarning
        case -1..<0.5: return Color.pulsumTextSecondary
        case 0.5..<1.5: return Color.pulsumGreenSoft
        default: return Color.pulsumSuccess
        }
    }

    private func summaryCopy(for value: Double) -> String {
        switch value {
        case ..<(-1): return "Focus on rest and low-load actions."
        case -1..<0.5: return "Holding steady around baseline."
        case 0.5..<1.5: return "Positive momentum building."
        default: return "Strong recovery signal today."
        }
    }
}

private struct DriverRow: View {
    let prefix: String
    let metric: ScoreBreakdown.MetricDetail
    let color: Color

    var body: some View {
        HStack(spacing: PulsumSpacing.xs) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 8, height: 8)
            Text("\(prefix): \(metric.name) \(formatContribution(metric.contribution))")
                .font(.pulsumCaption)
                .foregroundStyle(color)
        }
    }
}

private struct MetricSection: View {
    let title: String
    let caption: String
    let metrics: [ScoreBreakdown.MetricDetail]

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                Text(title)
                    .font(.pulsumHeadline)
                    .foregroundStyle(Color.pulsumTextPrimary)
                Text(caption)
                    .font(.pulsumCaption)
                    .foregroundStyle(Color.pulsumTextSecondary)
            }

            LazyVStack(spacing: PulsumSpacing.md) {
                ForEach(metrics) { metric in
                    MetricCard(detail: metric)
                }
            }
        }
    }
}

private struct MetricCard: View {
    let detail: ScoreBreakdown.MetricDetail

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                    Text(detail.name)
                        .font(.pulsumHeadline)
                        .foregroundStyle(Color.pulsumTextPrimary)
                    if let valueLine = valueLine {
                        Text(valueLine)
                            .font(.pulsumCallout)
                            .foregroundStyle(Color.pulsumTextSecondary)
                    } else {
                        Text("No data today")
                            .font(.pulsumCallout)
                            .foregroundStyle(Color.pulsumTextTertiary)
                    }
                }
                Spacer()
                ContributionBadge(contribution: detail.contribution)
            }

            VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                if let zScoreLine = zScoreLine {
                    InfoRow(systemName: "chart.line.uptrend.xyaxis", text: zScoreLine)
                }
                if let coverageLine = coverageLine {
                    InfoRow(systemName: "stethoscope", text: coverageLine)
                }
                if let baselineLine = baselineLine {
                    InfoRow(systemName: "calendar", text: baselineLine)
                }
                if let ewmaLine = ewmaLine {
                    InfoRow(systemName: "waveform.path.ecg", text: ewmaLine)
                }
            }

            if !detail.notes.isEmpty {
                ForEach(detail.notes, id: \.self) { note in
                    NoteRow(text: note)
                }
            }

            Text(detail.explanation)
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumTextSecondary)
                .lineSpacing(2)
        }
        .pulsumCardStyle(padding: PulsumSpacing.lg)
    }

    private var valueLine: String? {
        guard let value = detail.value else { return nil }
        return formatValue(value, unit: detail.unit)
    }

    private var zScoreLine: String? {
        guard let zScore = detail.zScore else { return nil }
        let formatted = formatSigned(value: zScore, decimals: 2)
        return "Z-score vs baseline: \(formatted)"
    }

    private var coverageLine: String? {
        guard let coverage = detail.coverage else { return nil }
        let daysLabel = coverage.daysWithSamples == 1 ? "day" : "days"
        let sampleLabel = coverage.sampleCount == 1 ? "data point" : "data points"
        return "Health data: \(coverage.daysWithSamples) \(daysLabel), \(coverage.sampleCount) \(sampleLabel)"
    }

    private var baselineLine: String? {
        guard let median = detail.baselineMedian else { return nil }
        let prefix: String
        if let days = detail.rollingWindowDays {
            prefix = "Rolling baseline (\(days)d median):"
        } else {
            prefix = "Rolling baseline median:"
        }
        let value = formatValue(median, unit: detail.unit) ?? String(format: "%.2f", median)
        return "\(prefix) \(value)"
    }

    private var ewmaLine: String? {
        guard let ewma = detail.baselineEwma else { return nil }
        let value = formatValue(ewma, unit: detail.unit) ?? String(format: "%.2f", ewma)
        return "EWMA trend (λ=0.2): \(value)"
    }
}

private struct NotesCard: View {
    let notes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.sm) {
            Text("Data notes")
                .font(.pulsumHeadline)
                .foregroundStyle(Color.pulsumTextPrimary)
            ForEach(notes, id: \.self) { note in
                NoteRow(text: note)
            }
        }
        .pulsumCardStyle()
    }
}

private struct RecommendationLogicCard: View {
    let highlights: RecommendationHighlights

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            Text("How recommendations use this")
                .font(.pulsumHeadline)
                .foregroundStyle(Color.pulsumTextPrimary)

            Text("The Coach agent builds a retrieval query from the wellbeing score plus the strongest signals below, then ranks activities with the RecRanker model.")
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumTextSecondary)
                .lineSpacing(2)

            if !highlights.lifts.isEmpty {
                BulletList(title: "Signals lifting you", details: highlights.lifts, color: Color.pulsumGreenSoft)
            }

            if !highlights.drags.isEmpty {
                BulletList(title: "Signals needing support", details: highlights.drags, color: Color.pulsumWarning)
            }

            Text("Cards are prioritized when they address the most urgent drags while reinforcing the current lifts. Updating your pulse inputs or new HealthKit data will reshuffle this analysis on the next sync.")
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumTextSecondary)
                .lineSpacing(2)
        }
        .pulsumCardStyle()
    }
}

private struct BulletList: View {
    let title: String
    let details: [ScoreBreakdown.MetricDetail]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.xs) {
            Text(title)
                .font(.pulsumSubheadline)
                .foregroundStyle(color)
            ForEach(details) { detail in
                HStack(alignment: .top, spacing: PulsumSpacing.xs) {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                        Text(detail.name)
                            .font(.pulsumCallout)
                            .foregroundStyle(Color.pulsumTextPrimary)
                        Text(contributionLine(for: detail))
                            .font(.pulsumCaption)
                            .foregroundStyle(Color.pulsumTextSecondary)
                    }
                }
            }
        }
    }

    private func contributionLine(for detail: ScoreBreakdown.MetricDetail) -> String {
        let contribution = formatContribution(detail.contribution)
        if let explanation = detail.explanation.split(separator: "\n").first {
            return "\(contribution) – \(explanation)"
        }
        return contribution
    }
}

private struct ContributionBadge: View {
    let contribution: Double

    var body: some View {
        Text(formatContribution(contribution))
            .font(.pulsumCaption)
            .fontWeight(.semibold)
            .padding(.vertical, PulsumSpacing.xxs)
            .padding(.horizontal, PulsumSpacing.sm)
            .background(badgeBackground)
            .foregroundStyle(badgeForeground)
            .clipShape(Capsule())
    }

    private var badgeBackground: Color {
        if contribution > 0.05 {
            return Color.pulsumGreenSoft.opacity(0.15)
        } else if contribution < -0.05 {
            return Color.pulsumWarning.opacity(0.15)
        } else {
            return Color.pulsumBlueSoft.opacity(0.1)
        }
    }

    private var badgeForeground: Color {
        if contribution > 0.05 {
            return Color.pulsumGreenSoft
        } else if contribution < -0.05 {
            return Color.pulsumWarning
        } else {
            return Color.pulsumTextSecondary
        }
    }
}

private struct InfoRow: View {
    let systemName: String
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: PulsumSpacing.xs) {
            Image(systemName: systemName)
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumBlueSoft)
            Text(text)
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumTextSecondary)
        }
    }
}

private struct NoteRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: PulsumSpacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumWarning)
            Text(text)
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumWarning)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ErrorStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: PulsumSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.pulsumTitle2)
                .foregroundStyle(Color.pulsumWarning)
            Text("Unable to load score details")
                .font(.pulsumHeadline)
                .foregroundStyle(Color.pulsumTextPrimary)
            Text(message)
                .font(.pulsumCallout)
                .foregroundStyle(Color.pulsumTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, PulsumSpacing.lg)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, PulsumSpacing.xl)
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: PulsumSpacing.md) {
            Image(systemName: "waveform.path.ecg")
                .font(.pulsumTitle2)
                .foregroundStyle(Color.pulsumBlueSoft)
            Text("No metrics yet")
                .font(.pulsumHeadline)
                .foregroundStyle(Color.pulsumTextPrimary)
            Text("We will show a full breakdown after Pulsum completes the first nightly sync.")
                .font(.pulsumCallout)
                .foregroundStyle(Color.pulsumTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, PulsumSpacing.lg)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, PulsumSpacing.xl)
    }
}

// MARK: - Formatting Helpers

private func formatValue(_ value: Double, unit: String?) -> String? {
    guard let unit else { return formatSigned(value: value, decimals: 2) }
    switch unit {
    case "ms":
        return String(format: "%.0f ms", value)
    case "bpm":
        return String(format: "%.1f bpm", value)
    case "breaths/min":
        return String(format: "%.1f breaths/min", value)
    case "steps":
        return "\(Int(round(value))) steps"
    case "h":
        return String(format: "%.1f h", value)
    case "(1-7)":
        return String(format: "%.1f / 7", value)
    default:
        return formatSigned(value: value, decimals: 2)
    }
}

private func formatSigned(value: Double, decimals: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = decimals
    formatter.minimumFractionDigits = decimals
    let formatted = formatter.string(from: NSNumber(value: abs(value))) ?? String(format: "%.*f", decimals, abs(value))
    return value >= 0 ? "+\(formatted)" : "-\(formatted)"
}

private func formatContribution(_ contribution: Double) -> String {
    formatSigned(value: contribution, decimals: 2)
}
```

### Packages/PulsumData/Sources/PulsumData/Resources/Pulsum.xcdatamodeld/Pulsum.xcdatamodel/contents
```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<model type="com.apple.IDECoreDataModeler.DataModel" documentVersion="1.0" lastSavedToolsVersion="1" systemVersion="11A491" minimumToolsVersion="Automatic" sourceLanguage="Swift" usedWithCloudKit="false" userDefinedModelVersionIdentifier="">
    <entity name="JournalEntry" representedClassName="JournalEntry" syncable="YES">
        <attribute name="id" optional="NO" attributeType="UUID" usesScalarValueType="NO"/>
        <attribute name="date" optional="NO" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="transcript" optional="NO" attributeType="String"/>
        <attribute name="sentiment" optional="YES" attributeType="Double" defaultValueString="0" usesScalarValueType="YES"/>
        <attribute name="embeddedVectorURL" optional="YES" attributeType="String"/>
        <attribute name="sensitiveFlags" optional="YES" attributeType="String"/>
    </entity>
    <entity name="DailyMetrics" representedClassName="DailyMetrics" syncable="YES">
        <attribute name="date" optional="NO" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="hrvMedian" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="nocturnalHRPercentile10" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="restingHR" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="totalSleepTime" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="sleepDebt" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="respiratoryRate" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="steps" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="flags" optional="YES" attributeType="String"/>
    </entity>
    <entity name="Baseline" representedClassName="Baseline" syncable="YES">
        <attribute name="metric" optional="NO" attributeType="String"/>
        <attribute name="windowDays" optional="NO" attributeType="Integer 16" defaultValueString="21" usesScalarValueType="YES"/>
        <attribute name="median" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="mad" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="ewma" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="updatedAt" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
    </entity>
    <entity name="FeatureVector" representedClassName="FeatureVector" syncable="YES">
        <attribute name="date" optional="NO" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="zHrv" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="zNocturnalHR" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="zRestingHR" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="zSleepDebt" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="zRespiratoryRate" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="zSteps" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="subjectiveStress" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="subjectiveEnergy" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="subjectiveSleepQuality" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="sentiment" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="imputedFlags" optional="YES" attributeType="String"/>
    </entity>
    <entity name="MicroMoment" representedClassName="MicroMoment" syncable="YES">
        <attribute name="id" optional="NO" attributeType="String"/>
        <attribute name="title" optional="NO" attributeType="String"/>
        <attribute name="shortDescription" optional="NO" attributeType="String"/>
        <attribute name="detail" optional="YES" attributeType="String"/>
        <attribute name="tags" optional="YES" attributeType="Transformable" valueTransformerName="NSSecureUnarchiveFromData"/>
        <attribute name="estimatedTimeSec" optional="YES" attributeType="Integer 32" usesScalarValueType="YES"/>
        <attribute name="difficulty" optional="YES" attributeType="String"/>
        <attribute name="category" optional="YES" attributeType="String"/>
        <attribute name="sourceURL" optional="YES" attributeType="String"/>
        <attribute name="evidenceBadge" optional="YES" attributeType="String"/>
        <attribute name="cooldownSec" optional="YES" attributeType="Integer 32" usesScalarValueType="YES"/>
    </entity>
    <entity name="RecommendationEvent" representedClassName="RecommendationEvent" syncable="YES">
        <attribute name="momentId" optional="NO" attributeType="String"/>
        <attribute name="date" optional="NO" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="accepted" optional="NO" attributeType="Boolean" usesScalarValueType="YES"/>
        <attribute name="completedAt" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
    </entity>
    <entity name="LibraryIngest" representedClassName="LibraryIngest" syncable="YES">
        <attribute name="id" optional="NO" attributeType="UUID" usesScalarValueType="NO"/>
        <attribute name="source" optional="NO" attributeType="String"/>
        <attribute name="checksum" optional="YES" attributeType="String"/>
        <attribute name="ingestedAt" optional="NO" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="version" optional="YES" attributeType="String"/>
    </entity>
    <entity name="UserPrefs" representedClassName="UserPrefs" syncable="YES">
        <attribute name="id" optional="NO" attributeType="String"/>
        <attribute name="consentCloud" optional="NO" attributeType="Boolean" defaultValueString="0" usesScalarValueType="YES"/>
        <attribute name="updatedAt" optional="NO" attributeType="Date" usesScalarValueType="NO"/>
    </entity>
    <entity name="ConsentState" representedClassName="ConsentState" syncable="YES">
        <attribute name="id" optional="NO" attributeType="UUID" usesScalarValueType="NO"/>
        <attribute name="version" optional="NO" attributeType="String"/>
        <attribute name="grantedAt" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="revokedAt" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
    </entity>
    <elements>
        <element name="JournalEntry" positionX="-63" positionY="-18" width="128" height="150"/>
        <element name="DailyMetrics" positionX="111" positionY="-18" width="128" height="150"/>
        <element name="Baseline" positionX="285" positionY="-18" width="128" height="150"/>
        <element name="FeatureVector" positionX="459" positionY="-18" width="128" height="178"/>
        <element name="MicroMoment" positionX="633" positionY="-18" width="128" height="206"/>
        <element name="RecommendationEvent" positionX="807" positionY="-18" width="128" height="122"/>
        <element name="LibraryIngest" positionX="981" positionY="-18" width="128" height="150"/>
        <element name="UserPrefs" positionX="1155" positionY="-18" width="128" height="122"/>
        <element name="ConsentState" positionX="1329" positionY="-18" width="128" height="122"/>
    </elements>
</model>
```

### Packages/PulsumML/Sources/PulsumML/WellbeingModeling.swift
```swift
```

### Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownViewModel.swift
```swift
import Foundation
import Observation
import PulsumAgents

@MainActor
@Observable
final class ScoreBreakdownViewModel {
    @ObservationIgnored private let orchestrator: AgentOrchestrator

    var breakdown: ScoreBreakdown?
    var isLoading = false
    var errorMessage: String?

    init(orchestrator: AgentOrchestrator) {
        self.orchestrator = orchestrator
    }

    var recommendationHighlights: RecommendationHighlights? {
        guard let details = breakdown?.metrics else { return nil }
        let lifts = details
            .filter { $0.contribution > 0 }
            .sorted(by: { $0.contribution > $1.contribution })
            .prefix(3)
        let drags = details
            .filter { $0.contribution < 0 }
            .sorted(by: { abs($0.contribution) > abs($1.contribution) })
            .prefix(3)
        guard !lifts.isEmpty || !drags.isEmpty else { return nil }
        return RecommendationHighlights(lifts: Array(lifts), drags: Array(drags))
    }

    var objectiveMetrics: [ScoreBreakdown.MetricDetail] {
        breakdown?.metrics.filter { $0.kind == .objective } ?? []
    }

    var subjectiveMetrics: [ScoreBreakdown.MetricDetail] {
        breakdown?.metrics.filter { $0.kind == .subjective } ?? []
    }

    var sentimentMetrics: [ScoreBreakdown.MetricDetail] {
        breakdown?.metrics.filter { $0.kind == .sentiment } ?? []
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            breakdown = try await orchestrator.scoreBreakdown()
            errorMessage = nil
        } catch {
            breakdown = nil
            errorMessage = mapError(error)
        }
    }

    private func mapError(_ error: Error) -> String {
        if (error as NSError).domain == NSURLErrorDomain {
            return "Network connection appears offline."
        }
        return error.localizedDescription
    }
}

struct RecommendationHighlights {
    let lifts: [ScoreBreakdown.MetricDetail]
    let drags: [ScoreBreakdown.MetricDetail]
}
```

### Pulsum/Pulsum.entitlements
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.healthkit</key>
	<true/>
	<key>com.apple.developer.healthkit.background-delivery</key>
	<true/>
</dict>
</plist>
```

### Packages/PulsumData/Sources/PulsumData/Resources/Pulsum.xcdatamodeld/Pulsum.xcdatamodel/contents
```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<model type="com.apple.IDECoreDataModeler.DataModel" documentVersion="1.0" lastSavedToolsVersion="1" systemVersion="11A491" minimumToolsVersion="Automatic" sourceLanguage="Swift" usedWithCloudKit="false" userDefinedModelVersionIdentifier="">
    <entity name="JournalEntry" representedClassName="JournalEntry" syncable="YES">
        <attribute name="id" optional="NO" attributeType="UUID" usesScalarValueType="NO"/>
        <attribute name="date" optional="NO" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="transcript" optional="NO" attributeType="String"/>
        <attribute name="sentiment" optional="YES" attributeType="Double" defaultValueString="0" usesScalarValueType="YES"/>
        <attribute name="embeddedVectorURL" optional="YES" attributeType="String"/>
        <attribute name="sensitiveFlags" optional="YES" attributeType="String"/>
    </entity>
    <entity name="DailyMetrics" representedClassName="DailyMetrics" syncable="YES">
        <attribute name="date" optional="NO" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="hrvMedian" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="nocturnalHRPercentile10" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="restingHR" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="totalSleepTime" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="sleepDebt" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="respiratoryRate" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="steps" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="flags" optional="YES" attributeType="String"/>
    </entity>
    <entity name="Baseline" representedClassName="Baseline" syncable="YES">
        <attribute name="metric" optional="NO" attributeType="String"/>
        <attribute name="windowDays" optional="NO" attributeType="Integer 16" defaultValueString="21" usesScalarValueType="YES"/>
        <attribute name="median" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="mad" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="ewma" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="updatedAt" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
    </entity>
    <entity name="FeatureVector" representedClassName="FeatureVector" syncable="YES">
        <attribute name="date" optional="NO" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="zHrv" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="zNocturnalHR" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="zRestingHR" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="zSleepDebt" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="zRespiratoryRate" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="zSteps" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="subjectiveStress" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="subjectiveEnergy" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="subjectiveSleepQuality" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="sentiment" optional="YES" attributeType="Double" usesScalarValueType="YES"/>
        <attribute name="imputedFlags" optional="YES" attributeType="String"/>
    </entity>
    <entity name="MicroMoment" representedClassName="MicroMoment" syncable="YES">
        <attribute name="id" optional="NO" attributeType="String"/>
        <attribute name="title" optional="NO" attributeType="String"/>
        <attribute name="shortDescription" optional="NO" attributeType="String"/>
        <attribute name="detail" optional="YES" attributeType="String"/>
        <attribute name="tags" optional="YES" attributeType="Transformable" valueTransformerName="NSSecureUnarchiveFromData"/>
        <attribute name="estimatedTimeSec" optional="YES" attributeType="Integer 32" usesScalarValueType="YES"/>
        <attribute name="difficulty" optional="YES" attributeType="String"/>
        <attribute name="category" optional="YES" attributeType="String"/>
        <attribute name="sourceURL" optional="YES" attributeType="String"/>
        <attribute name="evidenceBadge" optional="YES" attributeType="String"/>
        <attribute name="cooldownSec" optional="YES" attributeType="Integer 32" usesScalarValueType="YES"/>
    </entity>
    <entity name="RecommendationEvent" representedClassName="RecommendationEvent" syncable="YES">
        <attribute name="momentId" optional="NO" attributeType="String"/>
        <attribute name="date" optional="NO" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="accepted" optional="NO" attributeType="Boolean" usesScalarValueType="YES"/>
        <attribute name="completedAt" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
    </entity>
    <entity name="LibraryIngest" representedClassName="LibraryIngest" syncable="YES">
        <attribute name="id" optional="NO" attributeType="UUID" usesScalarValueType="NO"/>
        <attribute name="source" optional="NO" attributeType="String"/>
        <attribute name="checksum" optional="YES" attributeType="String"/>
        <attribute name="ingestedAt" optional="NO" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="version" optional="YES" attributeType="String"/>
    </entity>
    <entity name="UserPrefs" representedClassName="UserPrefs" syncable="YES">
        <attribute name="id" optional="NO" attributeType="String"/>
        <attribute name="consentCloud" optional="NO" attributeType="Boolean" defaultValueString="0" usesScalarValueType="YES"/>
        <attribute name="updatedAt" optional="NO" attributeType="Date" usesScalarValueType="NO"/>
    </entity>
    <entity name="ConsentState" representedClassName="ConsentState" syncable="YES">
        <attribute name="id" optional="NO" attributeType="UUID" usesScalarValueType="NO"/>
        <attribute name="version" optional="NO" attributeType="String"/>
        <attribute name="grantedAt" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="revokedAt" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
    </entity>
    <elements>
        <element name="JournalEntry" positionX="-63" positionY="-18" width="128" height="150"/>
        <element name="DailyMetrics" positionX="111" positionY="-18" width="128" height="150"/>
        <element name="Baseline" positionX="285" positionY="-18" width="128" height="150"/>
        <element name="FeatureVector" positionX="459" positionY="-18" width="128" height="178"/>
        <element name="MicroMoment" positionX="633" positionY="-18" width="128" height="206"/>
        <element name="RecommendationEvent" positionX="807" positionY="-18" width="128" height="122"/>
        <element name="LibraryIngest" positionX="981" positionY="-18" width="128" height="150"/>
        <element name="UserPrefs" positionX="1155" positionY="-18" width="128" height="122"/>
        <element name="ConsentState" positionX="1329" positionY="-18" width="128" height="122"/>
    </elements>
</model>
```

### Packages/PulsumML/Sources/PulsumML/StateEstimator.swift
```swift
import Foundation

public struct StateEstimatorConfig {
    public let learningRate: Double
    public let regularization: Double
    public let weightCap: ClosedRange<Double>

    public init(learningRate: Double = 0.05,
                regularization: Double = 1e-3,
                weightCap: ClosedRange<Double> = -2.0...2.0) {
        self.learningRate = learningRate
        self.regularization = regularization
        self.weightCap = weightCap
    }
}

public struct StateEstimatorSnapshot: Sendable {
    public let weights: [String: Double]
    public let bias: Double
    public let wellbeingScore: Double
    public let contributions: [String: Double]
}

public struct StateEstimatorState: Codable, Sendable {
    public let version: Int
    public let weights: [String: Double]
    public let bias: Double

    public init(version: Int = 1, weights: [String: Double], bias: Double) {
        self.version = version
        self.weights = weights
        self.bias = bias
    }
}

public final class StateEstimator {
    public static let defaultWeights: [String: Double] = [
        "z_hrv": 0.6,
        "z_nocthr": -0.45,
        "z_resthr": -0.35,
        "z_sleepDebt": -0.55,
        "z_steps": 0.3,
        "z_rr": -0.1,
        "subj_stress": -0.5,
        "subj_energy": 0.5,
        "subj_sleepQuality": 0.35,
        "sentiment": 0.25
    ]

    private let config: StateEstimatorConfig
    private var weights: [String: Double]
    private var bias: Double

    public init(initialWeights: [String: Double] = StateEstimator.defaultWeights,
                bias: Double = 0,
                config: StateEstimatorConfig = StateEstimatorConfig()) {
        self.weights = initialWeights
        self.config = config
        self.bias = bias
    }

    public init(state: StateEstimatorState, config: StateEstimatorConfig = StateEstimatorConfig()) {
        self.weights = state.weights
        self.bias = state.bias
        self.config = config
    }

    public func predict(features: [String: Double]) -> Double {
        let contributions = contributionVector(features: features)
        return contributions.values.reduce(bias, +)
    }

    public func update(features: [String: Double], target: Double) -> StateEstimatorSnapshot {
        let prediction = predict(features: features)
        let error = target - prediction

        for (feature, value) in features {
            let gradient = -error * value + config.regularization * (weights[feature] ?? 0)
            var updated = (weights[feature] ?? 0) - config.learningRate * gradient
            updated = min(max(updated, config.weightCap.lowerBound), config.weightCap.upperBound)
            weights[feature] = updated
        }

        bias -= config.learningRate * (-error)

        let contributions = contributionVector(features: features)
        let wellbeing = contributions.values.reduce(bias, +)
        return StateEstimatorSnapshot(weights: weights, bias: bias, wellbeingScore: wellbeing, contributions: contributions)
    }

    public func currentSnapshot(features: [String: Double]) -> StateEstimatorSnapshot {
        let contributions = contributionVector(features: features)
        let wellbeing = contributions.values.reduce(bias, +)
        return StateEstimatorSnapshot(weights: weights, bias: bias, wellbeingScore: wellbeing, contributions: contributions)
    }

    public func persistedState(version: Int = 1) -> StateEstimatorState {
        StateEstimatorState(version: version, weights: weights, bias: bias)
    }

    private func contributionVector(features: [String: Double]) -> [String: Double] {
        var result: [String: Double] = [:]
        result.reserveCapacity(features.count)
        for (feature, value) in features {
            let weight = weights[feature] ?? 0
            result[feature] = weight * value
        }
        return result
    }
}
```

### Packages/PulsumML/Sources/PulsumML/BaselineMath.swift
```swift
import Foundation

public enum BaselineMath {
    public struct RobustStats {
        public let median: Double
        public let mad: Double

        public init(median: Double, mad: Double) {
            self.median = median
            self.mad = mad
        }
    }

    public static func robustStats(for values: [Double]) -> RobustStats? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let median = percentile(sorted, percentile: 0.5)
        let deviations = sorted.map { abs($0 - median) }
        let mad = percentile(deviations.sorted(), percentile: 0.5) * 1.4826
        return RobustStats(median: median, mad: max(mad, 1e-6))
    }

    public static func zScore(value: Double, stats: RobustStats) -> Double {
        (value - stats.median) / stats.mad
    }

    public static func ewma(previous: Double?, newValue: Double, lambda: Double = 0.2) -> Double {
        guard let previous else { return newValue }
        return lambda * newValue + (1 - lambda) * previous
    }

    private static func percentile(_ values: [Double], percentile: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        let index = Double(values.count - 1) * percentile
        let lower = Int(floor(index))
        let upper = Int(ceil(index))
        if lower == upper { return values[lower] }
        let weight = index - Double(lower)
        return values[lower] * (1 - weight) + values[upper] * weight
    }
}
```

### Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownViewModel.swift
```swift
import Foundation
import Observation
import PulsumAgents

@MainActor
@Observable
final class ScoreBreakdownViewModel {
    @ObservationIgnored private let orchestrator: AgentOrchestrator

    var breakdown: ScoreBreakdown?
    var isLoading = false
    var errorMessage: String?

    init(orchestrator: AgentOrchestrator) {
        self.orchestrator = orchestrator
    }

    var recommendationHighlights: RecommendationHighlights? {
        guard let details = breakdown?.metrics else { return nil }
        let lifts = details
            .filter { $0.contribution > 0 }
            .sorted(by: { $0.contribution > $1.contribution })
            .prefix(3)
        let drags = details
            .filter { $0.contribution < 0 }
            .sorted(by: { abs($0.contribution) > abs($1.contribution) })
            .prefix(3)
        guard !lifts.isEmpty || !drags.isEmpty else { return nil }
        return RecommendationHighlights(lifts: Array(lifts), drags: Array(drags))
    }

    var objectiveMetrics: [ScoreBreakdown.MetricDetail] {
        breakdown?.metrics.filter { $0.kind == .objective } ?? []
    }

    var subjectiveMetrics: [ScoreBreakdown.MetricDetail] {
        breakdown?.metrics.filter { $0.kind == .subjective } ?? []
    }

    var sentimentMetrics: [ScoreBreakdown.MetricDetail] {
        breakdown?.metrics.filter { $0.kind == .sentiment } ?? []
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            breakdown = try await orchestrator.scoreBreakdown()
            errorMessage = nil
        } catch {
            breakdown = nil
            errorMessage = mapError(error)
        }
    }

    private func mapError(_ error: Error) -> String {
        if (error as NSError).domain == NSURLErrorDomain {
            return "Network connection appears offline."
        }
        return error.localizedDescription
    }
}

struct RecommendationHighlights {
    let lifts: [ScoreBreakdown.MetricDetail]
    let drags: [ScoreBreakdown.MetricDetail]
}
```

### Pulsum/Pulsum.entitlements
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.healthkit</key>
	<true/>
	<key>com.apple.developer.healthkit.background-delivery</key>
	<true/>
</dict>
</plist>
```

