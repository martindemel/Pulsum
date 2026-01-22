# Post-IX Audit

## What changed / why it's safe
- No code changes made; this is a validation pass against the original production fix described in `DIAGNOSIS.md`.
- The library import coalescing, deferred retry gating, and recommendation timeout/refresh logic all remain consistent with the prior fix in `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift`, `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`, and `Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift`.
- The PulsumUI scheme stays shared and points at the PulsumTests bundle (which includes PulsumUI package tests via the project group wiring), so CI runs the intended tests without custom scripts.

## Checklist confirmation (production fix integrity)
- [x] Library prep coalescing is present: `prepareLibraryIfNeeded()` guards on `libraryPreparationTask` (in-flight task reuse) and `hasPreparedLibrary` so concurrent `ingestIfNeeded()` does not run (`Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift`).
- [x] Deferred retry is gated on `libraryEmbeddingsDeferred`: `retryDeferredLibraryImport` exits early unless deferred, and `prepareLibraryIfNeeded()` bails when embeddings are unavailable (`Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift`).
- [x] Hard timeout notice is truthful: `AgentOrchestrator.recommendations()` uses `withHardTimeout` and returns a timeout notice that does not claim background continuation (`Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`).
- [x] Soft timeout is real and non-canceling: `recommendationsSoftTimedOut` suppresses the spinner via `isLoadingCards`, the task continues, and timeout state is cleared in the task defer path and on success (`Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift`).
- [x] Stale results apply only when empty: `shouldApply = !isStale || recommendations.isEmpty` prevents "empty forever" while still ignoring stale results once cards exist (`Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift`).
- [x] Diagnostics semantics remain aligned (no overlapping `library.import.begin`): the in-flight guard prevents concurrent library imports and retry is only triggered after deferred embeddings become available (`Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift`, `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`, `Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift`).

## Checklist confirmation (test fixes)
- [x] `Gate7_FirstRunWatchdogTests` uses the centralized test seeder and authorizes all types (`Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate7_FirstRunWatchdogTests.swift`).
- [x] `TestHealthKitSampleSeeder` lives under a test-only target folder (`Packages/PulsumAgents/Tests/PulsumAgentsTests/TestHealthKitSampleSeeder.swift`).
- [x] Seeder covers all required HealthKit types by iterating `HealthKitService.orderedReadSampleTypes` and generating samples per type (`Packages/PulsumAgents/Tests/PulsumAgentsTests/TestHealthKitSampleSeeder.swift`, `Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift`).
- [x] Gate6 tests call only the new seeder once per test; no double-seeding via legacy helpers found (`Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate6_WellbeingBackfillPhasingTests.swift`).

## Checklist confirmation (PulsumUI scheme)
- [x] `PulsumUI.xcscheme` is shared under `Pulsum.xcodeproj/xcshareddata/xcschemes/`.
- [x] TestAction targets `PulsumTests.xctest`, which includes `Packages/PulsumUI/Tests/PulsumUITests` via the `PulsumTests` target group wiring (`Pulsum.xcodeproj/xcshareddata/xcschemes/PulsumUI.xcscheme`, `Pulsum.xcodeproj/project.pbxproj`).
- [x] TestAction and LaunchAction use default environments with no startup bypass flags; unit tests rely on DEBUG-only XCTest detection inside `AppViewModel.start()` (`Pulsum.xcodeproj/xcshareddata/xcschemes/PulsumUI.xcscheme`, `Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift`).

## Potential risks / mitigations
- HealthKit seeding uses `Date()` and the local calendar/timezone; DST or timezone differences could affect edge-case comparisons. Mitigation: allow `TestHealthKitSampleSeeder.populateSamples` to accept a fixed `Date` and `TimeZone` for deterministic CI.
- If non-test runs inject `XCTestConfigurationFilePath`/`XCTestBundlePath`, startup would short-circuit; keep those env vars confined to XCTest harnesses.
- The broader test suite is known to be outdated per `bugs.md`; these passing tests only validate the specific fixes above.

## Commands run + results
- `swift test --package-path Packages/PulsumAgents --filter Gate7_FirstRunWatchdogTests`
  - Result: PASS (2 tests)
  - Output highlights:
    - `Executed 2 tests, with 0 failures (0 unexpected) in 1.061 seconds`
- `xcodebuild test -scheme PulsumUI -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'`
  - Result: PASS (PulsumTests)
  - Output highlights:
    - `Test Suite 'PulsumTests.xctest' passed ... Executed 12 tests, with 0 failures`
    - `** TEST SUCCEEDED **`
  - Notes: Xcode emitted two DVTDeviceOperation warnings about an empty build number, but tests completed successfully.

## Still pending manual verification steps
- Run the app and confirm diagnostics show only one `library.import.begin` per startup (no overlap with `library.import.retry.begin`) in fresh `PulsumDiagnostics` logs.
- Decide whether to rename the scheme or adjust LaunchAction env vars to avoid skipping startup during dev runs.
- If CI instability appears, consider hard-coding a fixed date/timezone for HealthKit seeding tests.
