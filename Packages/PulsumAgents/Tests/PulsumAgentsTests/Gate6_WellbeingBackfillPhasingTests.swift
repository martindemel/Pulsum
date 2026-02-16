@testable import PulsumAgents
@testable import PulsumData
@testable import PulsumServices
import SwiftData
import HealthKit
import XCTest

// swiftlint:disable:next type_name
final class Gate6_WellbeingBackfillPhasingTests: XCTestCase {
    private let timeZone = TimeZone(secondsFromGMT: 0)!
    private let referenceDate = Date()

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    func testWarmStartBackfillsFastWindowAndProducesSnapshot() async throws {
        let stub = HealthKitServiceStub()
        TestHealthKitSampleSeeder.authorizeAllTypes(stub)
        TestHealthKitSampleSeeder.populateSamples(stub,
                                                  days: 35,
                                                  referenceDate: referenceDate,
                                                  calendar: calendar,
                                                  timeZone: timeZone)
        let store = BackfillStateStoreSpy()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()
        let agent = DataAgent(modelContainer: try TestCoreDataStack.makeContainer(),
                              storagePaths: storagePaths,
                              healthKit: stub,
                              calendar: calendar,
                              estimatorStore: EstimatorStateStore(baseDirectory: storagePaths.applicationSupport),
                              backfillStore: store)

        try await agent.start()

        let today = calendar.startOfDay(for: referenceDate)
        let expectedBootstrapStart = calendar.date(byAdding: .day, value: -1, to: today)!
        var firstRequestByType: [String: (Date, Date)] = [:]
        for request in stub.fetchRequests where firstRequestByType[request.identifier] == nil {
            firstRequestByType[request.identifier] = (request.start, request.end)
        }
        if let steps = stub.dailyStepTotalsRequests.first {
            firstRequestByType[HKQuantityTypeIdentifier.stepCount.rawValue] = (steps.start, steps.end)
        }
        if let nocturnal = stub.nocturnalStatsRequests.first {
            firstRequestByType[HKQuantityTypeIdentifier.heartRate.rawValue] = (nocturnal.start, nocturnal.end)
        }
        XCTAssertEqual(firstRequestByType.count, HealthKitService.orderedReadSampleTypes.count, "Bootstrap should touch each granted type once.")
        for (_, window) in firstRequestByType {
            XCTAssertEqual(calendar.startOfDay(for: window.0), expectedBootstrapStart)
        }

        let snapshot = try await agent.latestFeatureVector()
        XCTAssertNotNil(snapshot, "Warm-start should materialize a feature vector when samples exist in-window.")

        // Allow background warm-start to finish and persist progress.
        let progress = await waitForWarmStart(store: store, agent: agent)
        XCTAssertEqual(progress.warmStartCompletedTypes.count, HealthKitService.orderedReadSampleTypes.count)
        XCTAssertTrue(progress.fullBackfillCompletedTypes.isEmpty, "Background backfill has not completed yet.")
    }

    func testAggregatedStepsAndNocturnalHRUseStatisticsQueries() async throws {
        let stub = HealthKitServiceStub()
        TestHealthKitSampleSeeder.authorizeAllTypes(stub)
        TestHealthKitSampleSeeder.populateSamples(stub,
                                                  days: 10,
                                                  referenceDate: referenceDate,
                                                  calendar: calendar,
                                                  timeZone: timeZone)
        let store = BackfillStateStoreSpy()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()

        let agent = DataAgent(modelContainer: try TestCoreDataStack.makeContainer(),
                              storagePaths: storagePaths,
                              healthKit: stub,
                              calendar: calendar,
                              estimatorStore: EstimatorStateStore(baseDirectory: storagePaths.applicationSupport),
                              backfillStore: store)

        try await agent.start()

        XCTAssertGreaterThan(stub.dailyStepTotalsRequests.count, 0, "Step totals should be fetched via HKStatisticsCollectionQuery.")
        XCTAssertGreaterThan(stub.nocturnalStatsRequests.count, 0, "Nocturnal HR should be fetched via HKStatisticsQuery.")
        XCTAssertEqual(stub.fetchRequests.filter { $0.identifier == HKQuantityTypeIdentifier.stepCount.rawValue }.count, 0, "Raw stepCount samples should not be fetched for backfill.")
        XCTAssertEqual(stub.fetchRequests.filter { $0.identifier == HKQuantityTypeIdentifier.heartRate.rawValue }.count, 0, "Raw heartRate samples should not be fetched for nocturnal HR backfill.")
    }

    func testRequestHealthAccessReturnsBeforeWarmStartCompletes() async throws {
        let stub = HealthKitServiceStub()
        stub.fetchDelayNanoseconds = 200_000_000
        TestHealthKitSampleSeeder.authorizeAllTypes(stub)
        TestHealthKitSampleSeeder.populateSamples(stub,
                                                  days: 35,
                                                  referenceDate: referenceDate,
                                                  calendar: calendar,
                                                  timeZone: timeZone)
        let store = BackfillStateStoreSpy()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()

        let agent = DataAgent(modelContainer: try TestCoreDataStack.makeContainer(),
                              storagePaths: storagePaths,
                              healthKit: stub,
                              calendar: calendar,
                              estimatorStore: EstimatorStateStore(baseDirectory: storagePaths.applicationSupport),
                              backfillStore: store)

        _ = try await agent.requestHealthAccess()

        let immediateProgress: BackfillProgress
        if let saved = store.loadState() {
            immediateProgress = saved
        } else {
            immediateProgress = await agent._testBackfillProgress()
        }
        XCTAssertLessThan(immediateProgress.warmStartCompletedTypes.count,
                          HealthKitService.orderedReadSampleTypes.count,
                          "Warm start should run in background after requestHealthAccess returns.")

        let snapshot = try await agent.latestFeatureVector()
        XCTAssertNotNil(snapshot, "Bootstrap should materialize a snapshot even while warm start continues.")

        let progress = await waitForWarmStart(store: store, agent: agent)
        XCTAssertEqual(progress.warmStartCompletedTypes.count, HealthKitService.orderedReadSampleTypes.count)
    }

    func testBackgroundBackfillExpandsCoverageAndPersistsAcrossSessions() async throws {
        let stub = HealthKitServiceStub()
        TestHealthKitSampleSeeder.authorizeAllTypes(stub)
        TestHealthKitSampleSeeder.populateSamples(stub,
                                                  days: 35,
                                                  referenceDate: referenceDate,
                                                  calendar: calendar,
                                                  timeZone: timeZone)
        let store = BackfillStateStoreSpy()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()

        let agent = DataAgent(modelContainer: try TestCoreDataStack.makeContainer(),
                              storagePaths: storagePaths,
                              healthKit: stub,
                              calendar: calendar,
                              estimatorStore: EstimatorStateStore(baseDirectory: storagePaths.applicationSupport),
                              backfillStore: store)
        try await agent.start()

        _ = await waitForWarmStart(store: store, agent: agent)
        await agent._testRunFullBackfillNow()

        let progress: BackfillProgress
        if let saved = store.loadState() {
            progress = saved
        } else {
            progress = await agent._testBackfillProgress()
        }
        let targetStart = calendar.date(byAdding: .day,
                                        value: -(30 - 1),
                                        to: calendar.startOfDay(for: referenceDate))!
        for identifier in HealthKitService.orderedReadSampleTypes.map(\.identifier) {
            XCTAssertTrue(progress.fullBackfillCompletedTypes.contains(identifier), "Full backfill should mark \(identifier) complete.")
            if let earliest = progress.earliestProcessedByType[identifier] {
                XCTAssertLessThanOrEqual(calendar.startOfDay(for: earliest), targetStart)
            }
        }

        let fetchesAfterFullBackfill = totalRequests(for: stub)

        // Simulate app restart; backfill progress should prevent re-running warm start.
        let restartedAgent = DataAgent(modelContainer: try TestCoreDataStack.makeContainer(),
                                       storagePaths: storagePaths,
                                       healthKit: stub,
                                       calendar: calendar,
                                       estimatorStore: EstimatorStateStore(baseDirectory: storagePaths.applicationSupport),
                                       backfillStore: store)
        try await restartedAgent.start()

        let bootstrapFetchAllowance = HealthKitService.orderedReadSampleTypes.count
        XCTAssertLessThanOrEqual(totalRequests(for: stub), fetchesAfterFullBackfill + bootstrapFetchAllowance, "Restart should only perform a bootstrap window fetch per type.")
    }

    func testBootstrapFallbackFindsOlderDataWhenRecentWindowIsEmpty() async throws {
        let stub = HealthKitServiceStub()
        TestHealthKitSampleSeeder.authorizeAllTypes(stub)
        TestHealthKitSampleSeeder.populateSamples(stub,
                                                  days: 5,
                                                  referenceDate: referenceDate,
                                                  calendar: calendar,
                                                  timeZone: timeZone)

        // Remove samples from the last two days so the 2-day bootstrap window is empty.
        let today = calendar.startOfDay(for: referenceDate)
        let cutoff = calendar.date(byAdding: .day, value: -2, to: today)!
        for (key, samples) in stub.fetchedSamples {
            let filtered = samples.filter { $0.startDate < cutoff }
            stub.fetchedSamples[key] = filtered
        }

        let store = BackfillStateStoreSpy()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()
        let agent = DataAgent(modelContainer: try TestCoreDataStack.makeContainer(),
                              storagePaths: storagePaths,
                              healthKit: stub,
                              calendar: calendar,
                              estimatorStore: EstimatorStateStore(baseDirectory: storagePaths.applicationSupport),
                              backfillStore: store)

        try await agent.start()

        let snapshot = try await agent.latestFeatureVector()
        XCTAssertNotNil(snapshot, "Fallback bootstrap should materialize a snapshot even when the 2-day window is empty.")
        if let snapshot {
            XCTAssertLessThan(snapshot.date, cutoff, "Snapshot should come from the most recent day with data before the bootstrap window.")
        }
    }

    func testSleepDebtMissingDataIsImputedButScoreStillComputes() async throws {
        let stub = HealthKitServiceStub()
        TestHealthKitSampleSeeder.authorizeAllTypes(stub)
        TestHealthKitSampleSeeder.populateSamples(stub,
                                                  days: 5,
                                                  referenceDate: referenceDate,
                                                  calendar: calendar,
                                                  timeZone: timeZone)
        stub.fetchedSamples[HKCategoryTypeIdentifier.sleepAnalysis.rawValue] = []
        let store = BackfillStateStoreSpy()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()

        let agent = DataAgent(modelContainer: try TestCoreDataStack.makeContainer(),
                              storagePaths: storagePaths,
                              healthKit: stub,
                              calendar: calendar,
                              estimatorStore: EstimatorStateStore(baseDirectory: storagePaths.applicationSupport),
                              backfillStore: store)
        try await agent.start()

        let snapshot = try await agent.latestFeatureVector()
        XCTAssertNotNil(snapshot)
        XCTAssertEqual(snapshot?.imputedFlags["sleepDebt_missing"], true)
    }

    @MainActor
    func testOverlappingBackfillDoesNotInflateSleepTotals() async throws {
        let stub = HealthKitServiceStub()
        TestHealthKitSampleSeeder.authorizeAllTypes(stub)
        let container = try TestCoreDataStack.makeContainer()
        let store = BackfillStateStoreSpy()
        let storagePaths = TestCoreDataStack.makeTestStoragePaths()
        let agent = DataAgent(modelContainer: container,
                              storagePaths: storagePaths,
                              healthKit: stub,
                              calendar: calendar,
                              estimatorStore: EstimatorStateStore(baseDirectory: storagePaths.applicationSupport),
                              backfillStore: store)

        let day = calendar.startOfDay(for: referenceDate)
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let sleepStart = calendar.date(byAdding: .hour, value: 22, to: day)!
        let sleepEnd = calendar.date(byAdding: .hour, value: 30, to: day)!
        let sample = HKCategorySample(type: sleepType,
                                      value: HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                                      start: sleepStart,
                                      end: sleepEnd)

        try await agent._testProcessCategorySamples([sample], type: sleepType)
        let firstSnapshotValue = try await agent.latestFeatureVector()
        let firstSnapshot = try XCTUnwrap(firstSnapshotValue)
        let firstMetricsValue = try fetchMetrics(for: day, container: container)
        let firstMetrics = try XCTUnwrap(firstMetricsValue)
        let firstFlags = try XCTUnwrap(decodeFlags(from: firstMetrics))

        try await agent._testProcessCategorySamples([sample], type: sleepType)
        let secondSnapshotValue = try await agent.latestFeatureVector()
        let secondSnapshot = try XCTUnwrap(secondSnapshotValue)
        let secondMetricsValue = try fetchMetrics(for: day, container: container)
        let secondMetrics = try XCTUnwrap(secondMetricsValue)
        let secondFlags = try XCTUnwrap(decodeFlags(from: secondMetrics))

        let expectedDuration = sleepEnd.timeIntervalSince(sleepStart)
        let firstAggregated = try XCTUnwrap(firstFlags.aggregatedSleepDurationSeconds)
        let secondAggregated = try XCTUnwrap(secondFlags.aggregatedSleepDurationSeconds)
        XCTAssertEqual(firstAggregated, expectedDuration, accuracy: 0.5)
        XCTAssertEqual(secondAggregated, expectedDuration, accuracy: 0.5)
        XCTAssertEqual(firstFlags.sleepSegments.count, 1)
        XCTAssertEqual(secondFlags.sleepSegments.count, 1)
        XCTAssertEqual(Set(firstFlags.sleepSegments.map(\.id)).count, 1)
        XCTAssertEqual(Set(secondFlags.sleepSegments.map(\.id)).count, 1)

        let firstTotal = try XCTUnwrap(firstMetrics.totalSleepTime)
        let secondTotal = try XCTUnwrap(secondMetrics.totalSleepTime)
        XCTAssertEqual(firstTotal, expectedDuration, accuracy: 0.5)
        XCTAssertEqual(secondTotal, expectedDuration, accuracy: 0.5)
        XCTAssertEqual(firstMetrics.sleepDebt, secondMetrics.sleepDebt)
        XCTAssertEqual(firstSnapshot.features, secondSnapshot.features)
        XCTAssertEqual(firstSnapshot.wellbeingScore, secondSnapshot.wellbeingScore, accuracy: 0.0001)
    }

    // MARK: - Helpers

    @MainActor
    private func fetchMetrics(for day: Date, container: ModelContainer) throws -> DailyMetrics? {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<DailyMetrics>(predicate: #Predicate { $0.date == day })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func decodeFlags(from metrics: DailyMetrics) -> TestDailyFlags? {
        guard let payload = metrics.flags?.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(TestDailyFlags.self, from: payload)
    }


    private func totalRequests(for stub: HealthKitServiceStub) -> Int {
        stub.fetchRequests.count + stub.dailyStepTotalsRequests.count + stub.nocturnalStatsRequests.count
    }

    private func waitForWarmStart(store: BackfillStateStoreSpy, agent: DataAgent) async -> BackfillProgress {
        let requiredCount = HealthKitService.orderedReadSampleTypes.count
        let clock = ContinuousClock()
        let deadline = clock.now + .seconds(5)
        while clock.now < deadline {
            if let saved = store.loadState(), saved.warmStartCompletedTypes.count == requiredCount {
                return saved
            }
            let progress = await agent._testBackfillProgress()
            if progress.warmStartCompletedTypes.count == requiredCount {
                return progress
            }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        if let saved = store.loadState() {
            return saved
        }
        return await agent._testBackfillProgress()
    }
}

// Test-only: mutable spy — lock-protected for safe concurrent access in tests.
final class BackfillStateStoreSpy: BackfillStateStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var _savedState: BackfillProgress?
    private var _loadStateReturn: BackfillProgress?

    var savedState: BackfillProgress? {
        lock.lock(); defer { lock.unlock() }
        return _savedState
    }

    var loadStateReturn: BackfillProgress? {
        get { lock.lock(); defer { lock.unlock() }; return _loadStateReturn }
        set { lock.lock(); defer { lock.unlock() }; _loadStateReturn = newValue }
    }

    func loadState() -> BackfillProgress? {
        lock.lock(); defer { lock.unlock() }
        return _loadStateReturn ?? _savedState
    }

    func saveState(_ state: BackfillProgress) {
        lock.lock(); defer { lock.unlock() }
        _savedState = state
    }
}

private struct TestDailyFlags: Codable {
    let aggregatedSleepDurationSeconds: Double?
    let sleepSegments: [TestSleepSegment]
}

private struct TestSleepSegment: Codable, Hashable {
    let id: UUID
    let start: Date
    let end: Date
    let stage: String
}
