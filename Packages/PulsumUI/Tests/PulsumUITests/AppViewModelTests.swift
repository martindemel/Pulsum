import Testing
@testable import PulsumUI

// MARK: - B7-09 | TC-13: AppViewModel startup tests

@MainActor
struct AppViewModelTests {
    @Test("Initial startupState is idle after init")
    func test_initialState_isIdle() {
        let vm = AppViewModel(sessionInfo: ("test", "0"))
        #expect(vm.startupState == .idle)
    }

    @Test("start() transitions state away from idle")
    func test_start_transitionsFromIdle() {
        let vm = AppViewModel(sessionInfo: ("test", "0"))
        #expect(vm.startupState == .idle)

        vm.start()

        // start() should move state away from idle. Under test conditions:
        // - If XCTest env detected: .ready (fast path)
        // - If DataStack available: .loading (then async -> .ready)
        // - If DataStack fails: .failed(...)
        #expect(vm.startupState != .idle,
                "start() must transition state away from .idle")
    }

    @Test("start() is a no-op when not in idle state")
    func test_start_guardsOnIdle() {
        let vm = AppViewModel(sessionInfo: ("test", "0"))
        vm.start()

        let stateAfterFirstStart = vm.startupState
        vm.start() // second call should be no-op (guard on .idle)

        #expect(vm.startupState == stateAfterFirstStart,
                "Second start() must not change state")
    }
}
