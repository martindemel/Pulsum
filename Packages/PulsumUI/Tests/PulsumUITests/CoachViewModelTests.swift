import XCTest
@testable import PulsumAgents
import PulsumTypes
@testable import PulsumUI

// Run with: xcodebuild test -scheme PulsumUI -destination 'platform=iOS Simulator,name=iPhone 15'

@MainActor
final class CoachViewModelTests: XCTestCase {
    func testSnapshotReadyBeforeRecommendationsComplete() async {
        let snapshot = WellbeingSnapshotResponse(
            wellbeingState: .ready(score: 0.72, contributions: ["z_hrv": 0.12]),
            snapshotKind: .real,
            dayString: "2025-10-23"
        )
        let response = RecommendationResponse(
            cards: [RecommendationCard(id: "r1", title: "Card A", body: "Body", caution: nil, sourceBadge: "Local")],
            wellbeingScore: 0,
            contributions: [:],
            wellbeingState: .noData(.insufficientSamples),
            notice: nil
        )
        let orchestrator = TestCoachOrchestrator(
            snapshotResponse: snapshot,
            recommendationsResponses: [response],
            recommendationsDelay: 200_000_000
        )
        let viewModel = CoachViewModel(recommendationsDebounceNanoseconds: 0)
        viewModel.bind(orchestrator: orchestrator, consentProvider: { true })

        await viewModel.refreshRecommendations()
        XCTAssertEqual(viewModel.wellbeingState, snapshot.wellbeingState)
        XCTAssertTrue(viewModel.isLoadingCards)
        XCTAssertTrue(viewModel.recommendations.isEmpty)

        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertTrue(viewModel.isLoadingCards)

        try? await Task.sleep(nanoseconds: 250_000_000)
        XCTAssertFalse(viewModel.isLoadingCards)
        XCTAssertEqual(viewModel.recommendations, response.cards)
    }

    func testRefreshStormCoalescesRecommendationsAndKeepsWellbeingReady() async {
        let snapshot = WellbeingSnapshotResponse(
            wellbeingState: .ready(score: 0.61, contributions: ["z_steps": -0.05]),
            snapshotKind: .real,
            dayString: "2025-10-23"
        )
        let first = RecommendationResponse(
            cards: [RecommendationCard(id: "r1", title: "Card A", body: "Body", caution: nil, sourceBadge: "Local")],
            wellbeingScore: 0,
            contributions: [:],
            wellbeingState: .noData(.insufficientSamples),
            notice: nil
        )
        let second = RecommendationResponse(
            cards: [RecommendationCard(id: "r2", title: "Card B", body: "Body", caution: nil, sourceBadge: "Local")],
            wellbeingScore: 0,
            contributions: [:],
            wellbeingState: .noData(.insufficientSamples),
            notice: nil
        )
        let orchestrator = TestCoachOrchestrator(
            snapshotResponse: snapshot,
            recommendationsResponses: [first, second],
            recommendationsDelay: 200_000_000
        )
        let viewModel = CoachViewModel(recommendationsDebounceNanoseconds: 0)
        viewModel.bind(orchestrator: orchestrator, consentProvider: { true })

        await viewModel.refreshRecommendations()
        try? await Task.sleep(nanoseconds: 20_000_000)

        let refreshTasks = (0..<5).map { _ in
            Task { await viewModel.refreshRecommendations() }
        }
        for task in refreshTasks {
            await task.value
        }

        if case .loading = viewModel.wellbeingState {
            XCTFail("Wellbeing state should not return to loading after initial load.")
        }

        try? await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertEqual(orchestrator.maxConcurrentRecommendations, 1)
        XCTAssertEqual(orchestrator.recommendationsCallCount, 2)
    }

    func testStaleRecommendationResultsApplyWhenEmpty() async {
        let snapshot = WellbeingSnapshotResponse(
            wellbeingState: .ready(score: 0.55, contributions: ["z_sleepDebt": -0.2]),
            snapshotKind: .real,
            dayString: "2025-10-23"
        )
        let stale = RecommendationResponse(
            cards: [RecommendationCard(id: "stale", title: "Old", body: "Body", caution: nil, sourceBadge: "Local")],
            wellbeingScore: 0,
            contributions: [:],
            wellbeingState: .noData(.insufficientSamples),
            notice: nil
        )
        let fresh = RecommendationResponse(
            cards: [RecommendationCard(id: "fresh", title: "New", body: "Body", caution: nil, sourceBadge: "Local")],
            wellbeingScore: 0,
            contributions: [:],
            wellbeingState: .noData(.insufficientSamples),
            notice: nil
        )
        let orchestrator = TestCoachOrchestrator(
            snapshotResponse: snapshot,
            recommendationsResponses: [stale, fresh],
            recommendationsDelay: 150_000_000
        )
        let viewModel = CoachViewModel(recommendationsDebounceNanoseconds: 0)
        viewModel.bind(orchestrator: orchestrator, consentProvider: { true })

        let firstCompleted = expectation(description: "first recommendations completed")
        let secondCompleted = expectation(description: "second recommendations completed")
        orchestrator.onRecommendationsComplete = { (callIndex: Int) in
            if callIndex == 1 {
                firstCompleted.fulfill()
            }
            if callIndex == 2 {
                secondCompleted.fulfill()
            }
        }

        Task { await viewModel.refreshRecommendations() }
        try? await Task.sleep(nanoseconds: 20_000_000)
        Task { await viewModel.refreshRecommendations() }

        await fulfillment(of: [firstCompleted], timeout: 1.0)
        XCTAssertEqual(viewModel.recommendations, stale.cards)

        await fulfillment(of: [secondCompleted], timeout: 1.0)
        XCTAssertEqual(viewModel.recommendations, fresh.cards)
    }

    func testStaleRecommendationResultsIgnoredWhenCardsExist() async {
        let snapshot = WellbeingSnapshotResponse(
            wellbeingState: .ready(score: 0.66, contributions: ["z_steps": 0.12]),
            snapshotKind: .real,
            dayString: "2025-10-23"
        )
        let initial = RecommendationResponse(
            cards: [RecommendationCard(id: "current", title: "Current", body: "Body", caution: nil, sourceBadge: "Local")],
            wellbeingScore: 0,
            contributions: [:],
            wellbeingState: .noData(.insufficientSamples),
            notice: nil
        )
        let stale = RecommendationResponse(
            cards: [RecommendationCard(id: "stale", title: "Old", body: "Body", caution: nil, sourceBadge: "Local")],
            wellbeingScore: 0,
            contributions: [:],
            wellbeingState: .noData(.insufficientSamples),
            notice: nil
        )
        let fresh = RecommendationResponse(
            cards: [RecommendationCard(id: "fresh", title: "New", body: "Body", caution: nil, sourceBadge: "Local")],
            wellbeingScore: 0,
            contributions: [:],
            wellbeingState: .noData(.insufficientSamples),
            notice: nil
        )
        let orchestrator = TestCoachOrchestrator(
            snapshotResponse: snapshot,
            recommendationsResponses: [initial, stale, fresh],
            recommendationsDelay: 150_000_000
        )
        let viewModel = CoachViewModel(recommendationsDebounceNanoseconds: 0)
        viewModel.bind(orchestrator: orchestrator, consentProvider: { true })

        await viewModel.refreshRecommendations()
        try? await Task.sleep(nanoseconds: 250_000_000)
        XCTAssertEqual(viewModel.recommendations, initial.cards)

        let staleCompleted = expectation(description: "stale recommendations completed")
        let freshCompleted = expectation(description: "fresh recommendations completed")
        orchestrator.onRecommendationsComplete = { (callIndex: Int) in
            if callIndex == 2 {
                staleCompleted.fulfill()
            }
            if callIndex == 3 {
                freshCompleted.fulfill()
            }
        }

        Task { await viewModel.refreshRecommendations() }
        try? await Task.sleep(nanoseconds: 20_000_000)
        Task { await viewModel.refreshRecommendations() }

        await fulfillment(of: [staleCompleted], timeout: 1.0)
        XCTAssertEqual(viewModel.recommendations, initial.cards)

        await fulfillment(of: [freshCompleted], timeout: 1.0)
        XCTAssertEqual(viewModel.recommendations, fresh.cards)
    }

    func testRecommendationsSoftTimeoutStopsSpinnerAndAppliesLaterWithoutManualRefresh() async {
        let snapshot = WellbeingSnapshotResponse(
            wellbeingState: .ready(score: 0.72, contributions: ["z_hrv": 0.12]),
            snapshotKind: .real,
            dayString: "2025-10-23"
        )
        let response = RecommendationResponse(
            cards: [RecommendationCard(id: "slow", title: "Slow", body: "Body", caution: nil, sourceBadge: "Local")],
            wellbeingScore: 0,
            contributions: [:],
            wellbeingState: .noData(.insufficientSamples),
            notice: nil
        )
        let softTimeoutSleeper = TestSleeper()
        let recommendationsSleeper = TestSleeper()
        let orchestrator = TestCoachOrchestrator(
            snapshotResponse: snapshot,
            recommendationsResponses: [response],
            recommendationsDelay: 1,
            recommendationsSleep: recommendationsSleeper.sleep
        )
        let viewModel = CoachViewModel(recommendationsDebounceNanoseconds: 0,
                                       recommendationsSoftTimeoutSeconds: 9,
                                       softTimeoutSleep: softTimeoutSleeper.sleep)
        viewModel.bind(orchestrator: orchestrator, consentProvider: { true })

        await viewModel.refreshRecommendations()
        XCTAssertTrue(viewModel.isLoadingCards)

        await softTimeoutSleeper.advanceAll()
        await Task.yield()
        XCTAssertFalse(viewModel.isLoadingCards)
        XCTAssertTrue(viewModel.recommendations.isEmpty)
        XCTAssertEqual(viewModel.recommendationsSoftTimeoutMessage,
                       "Recommendations are taking longer than expected. We'll show them here as soon as they're ready.")

        await recommendationsSleeper.advanceAll()
        await Task.yield()
        XCTAssertEqual(viewModel.recommendations, response.cards)
        XCTAssertNil(viewModel.recommendationsSoftTimeoutMessage)
    }

    func testPlaceholderSnapshotShowsWarmingUpNotice() async {
        let snapshot = WellbeingSnapshotResponse(
            wellbeingState: .noData(.insufficientSamples),
            snapshotKind: .placeholder,
            dayString: "2025-10-23"
        )
        let orchestrator = TestCoachOrchestrator(
            snapshotResponse: snapshot,
            recommendationsResponses: []
        )
        let viewModel = CoachViewModel(recommendationsDebounceNanoseconds: 0)
        viewModel.bind(orchestrator: orchestrator, consentProvider: { true })

        await viewModel.refreshRecommendations()

        XCTAssertEqual(viewModel.snapshotKind, .placeholder)
        XCTAssertEqual(viewModel.wellbeingState, .noData(.insufficientSamples))
        XCTAssertEqual(viewModel.wellbeingNotice?.text,
                       "Warming up... Health data may take a moment on first run.")
    }

    func testSnapshotKindSemantics() async throws {
        let noneSnapshot = WellbeingSnapshotResponse(
            wellbeingState: .noData(.insufficientSamples),
            snapshotKind: .none,
            dayString: nil
        )
        let realSnapshot = WellbeingSnapshotResponse(
            wellbeingState: .ready(score: 0.42, contributions: ["z_steps": 0.2]),
            snapshotKind: .real,
            dayString: "2025-10-23"
        )

        let noneOrchestrator = TestCoachOrchestrator(
            snapshotResponse: noneSnapshot,
            recommendationsResponses: []
        )
        let noneViewModel = CoachViewModel(recommendationsDebounceNanoseconds: 0)
        noneViewModel.bind(orchestrator: noneOrchestrator, consentProvider: { true })

        await noneViewModel.refreshRecommendations()
        XCTAssertEqual(noneViewModel.snapshotKind, .none)
        XCTAssertNil(noneViewModel.wellbeingScore)
        XCTAssertEqual(noneViewModel.wellbeingNotice?.text,
                       "We're waiting for enough Health data to personalize your picks.")

        let realOrchestrator = TestCoachOrchestrator(
            snapshotResponse: realSnapshot,
            recommendationsResponses: []
        )
        let realViewModel = CoachViewModel(recommendationsDebounceNanoseconds: 0)
        realViewModel.bind(orchestrator: realOrchestrator, consentProvider: { true })

        await realViewModel.refreshRecommendations()
        XCTAssertEqual(realViewModel.snapshotKind, .real)
        let score = try XCTUnwrap(realViewModel.wellbeingScore)
        XCTAssertEqual(score, 0.42, accuracy: 0.0001)
        XCTAssertNil(realViewModel.wellbeingNotice)
    }
}

@MainActor
private final class TestCoachOrchestrator: CoachOrchestrating {
    let snapshotResponse: WellbeingSnapshotResponse
    let recommendationsResponses: [RecommendationResponse]
    let snapshotDelay: UInt64
    let recommendationsDelay: UInt64
    let snapshotSleep: @Sendable (UInt64) async throws -> Void
    let recommendationsSleep: @Sendable (UInt64) async throws -> Void

    private(set) var recommendationsCallCount = 0
    private(set) var maxConcurrentRecommendations = 0
    private var activeRecommendations = 0

    var onRecommendationsComplete: ((Int) -> Void)?

    init(snapshotResponse: WellbeingSnapshotResponse,
         recommendationsResponses: [RecommendationResponse],
         snapshotDelay: UInt64 = 0,
         recommendationsDelay: UInt64 = 0,
         snapshotSleep: @escaping @Sendable (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) },
         recommendationsSleep: @escaping @Sendable (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) }) {
        self.snapshotResponse = snapshotResponse
        self.recommendationsResponses = recommendationsResponses
        self.snapshotDelay = snapshotDelay
        self.recommendationsDelay = recommendationsDelay
        self.snapshotSleep = snapshotSleep
        self.recommendationsSleep = recommendationsSleep
    }

    func wellbeingSnapshotState(consentGranted: Bool) async throws -> WellbeingSnapshotResponse {
        _ = consentGranted
        if snapshotDelay > 0 {
            try await snapshotSleep(snapshotDelay)
        }
        return snapshotResponse
    }

    func recommendations(consentGranted: Bool) async throws -> RecommendationResponse {
        _ = consentGranted
        recommendationsCallCount += 1
        activeRecommendations += 1
        maxConcurrentRecommendations = max(maxConcurrentRecommendations, activeRecommendations)
        let callIndex = recommendationsCallCount
        defer {
            activeRecommendations -= 1
            onRecommendationsComplete?(callIndex)
        }
        if recommendationsDelay > 0 {
            try await recommendationsSleep(recommendationsDelay)
        }
        if callIndex <= recommendationsResponses.count {
            return recommendationsResponses[callIndex - 1]
        }
        return recommendationsResponses.last ?? RecommendationResponse(cards: [],
                                                                      wellbeingScore: 0,
                                                                      contributions: [:],
                                                                      wellbeingState: .noData(.insufficientSamples),
                                                                      notice: nil)
    }

    func logCompletion(momentId: String) async throws -> CheerEvent {
        CheerEvent(message: "Nice work!", haptic: .success, timestamp: Date())
    }

    func chat(userInput: String, consentGranted: Bool) async throws -> String {
        _ = (userInput, consentGranted)
        return "OK"
    }
}

private actor TestSleeper {
    private var continuations: [UUID: CheckedContinuation<Void, Error>] = [:]

    func sleep(nanoseconds: UInt64) async throws {
        _ = nanoseconds
        let id = UUID()
        try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in
                continuations[id] = continuation
            }
        }, onCancel: {
            Task { await self.cancelSleep(id: id) }
        })
    }

    func advanceAll() {
        for (_, continuation) in continuations {
            continuation.resume()
        }
        continuations.removeAll()
    }

    private func cancelSleep(id: UUID) {
        if let continuation = continuations.removeValue(forKey: id) {
            continuation.resume(throwing: CancellationError())
        }
    }
}
