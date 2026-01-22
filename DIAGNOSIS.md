# Pulsum Diagnosis — Recommendations Stall + Startup Duplication

## Inputs Reviewed
- `_project_focus_files.txt`
- `PulsumDiagnostics-Latest.txt`
- `Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift`
- `Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift`
- `Packages/PulsumUI/Sources/PulsumUI/CoachView.swift`
- `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`
- `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift`
- `Packages/PulsumTypes/Sources/PulsumTypes/Timeout.swift`

## First-Run Execution Timeline (Observed + Code)
1) App boot kicks off startup.
   - `PulsumRootView` launches `.task { viewModel.start() }` in `Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift`.
   - Log: `app.session.start` → `timeline.firstRun.start` → `ui.startupState.changed state=loading` in `PulsumDiagnostics-Latest.txt`.

2) Orchestrator is created and bound to view models.
   - `AppViewModel.start()` creates the orchestrator, binds `CoachViewModel`/`PulseViewModel`/`SettingsViewModel`, and sets `startupState = .ready` before starting orchestration in `Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift`.
   - Log: `app.orchestrator.create.begin/end`, `timeline.firstRun.checkpoint stage=orchestrator_bound`, `ui.startupState.changed state=ready` in `PulsumDiagnostics-Latest.txt`.

3) Orchestrator startup begins, including library import.
   - `AgentOrchestrator.start()` calls `coachAgent.prepareLibraryIfNeeded()` first in `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`.
   - Log: `orchestrator.start.begin`, `orchestrator.start.prepareLibrary.begin`, `library.import.begin` in `PulsumDiagnostics-Latest.txt`.

4) Health authorization + bootstrap start.
   - `DataAgent.start()` calls `healthKit.requestAuthorization()` and bootstraps the first score in `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`.
   - Log: `data.healthkit.authorization`, `data.bootstrap.begin`, and multiple `data.bootstrap.batch.*` entries in `PulsumDiagnostics-Latest.txt`.

5) Snapshot publish notifications fan out to UI.
   - `DataAgent.notifySnapshotUpdate()` posts `.pulsumScoresUpdated` and emits `data.snapshot.published` in `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`.
   - `AppViewModel` listens and triggers `CoachViewModel.refreshRecommendations()` in `Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift`.
   - Log: `data.snapshot.published` interleaved with `coach.recommendations.begin` in `PulsumDiagnostics-Latest.txt`.

6) Recommendations pipeline executes.
   - `CoachViewModel.refreshRecommendations()` gets a snapshot and schedules recommendations in `Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift`.
   - The Insights view also triggers `refreshRecommendations()` on `.task` in `Packages/PulsumUI/Sources/PulsumUI/CoachView.swift`.

## Log Pattern Explanations
### 1) Overlapping `library.import.begin` + `library.import.retry.begin`
- Observed: `library.import.begin` at 03:05:43.908Z followed by `library.import.retry.begin` + a second `library.import.begin` at 03:05:43.966Z in `PulsumDiagnostics-Latest.txt`.
- Root cause:
  - `AppViewModel.start()` sets `.ready` before `orchestrator.start()` finishes, so `app.lifecycle.didBecomeActive` immediately triggers `refreshOnForeground()` in `Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift`.
  - `refreshOnForeground()` calls `AgentOrchestrator.refreshOnDeviceModelAvailabilityAndRetryDeferredWork()` which invokes `CoachAgent.retryDeferredLibraryImport()` in `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`.
  - Prior to the fix, `retryDeferredLibraryImport()` ran even when the library was not deferred and `prepareLibraryIfNeeded()` lacked an in-flight guard, so two `ingestIfNeeded()` calls started concurrently in `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift`.
- Symptom: duplicate startup work (two simultaneous library ingests) and overlapping library logs.

### 2) `ui.recommendations.refresh.end result=stale` while `coach.recommendations.end` succeeds
- Root cause:
  - `CoachViewModel.refreshRecommendations()` increments `refreshSequence` each call; when recommendations return, the result is dropped if `refreshID != refreshSequence` in `Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift`.
  - Multiple triggers fire in quick succession: `AppViewModel` calls `refreshRecommendations()` after `orchestrator.start`, Insights view calls it on `.task`, and each `data.snapshot.published` posts `.pulsumScoresUpdated` which triggers another refresh.
- Evidence:
  - The diagnostics show several `coach.recommendations.begin` entries clustered around `data.snapshot.published` events in `PulsumDiagnostics-Latest.txt`.
- Symptom: UI can remain empty even though `coach.recommendations.end` succeeds, because the response is marked stale and ignored.

### 3) Timeout messaging claims background work continues
- Root cause:
  - `AgentOrchestrator.recommendations()` uses `withHardTimeout` in `Packages/PulsumTypes/Sources/PulsumTypes/Timeout.swift`, which cancels the underlying task on timeout.
  - The previous notice string in `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift` said “we’ll keep trying in the background,” but there is no retry and the canceled task’s result is discarded.
- Symptom: user-facing messaging implies continued progress even when the work is canceled.

## Root Causes → Symptoms → Fixes (Safe/Minimal)
1) **Unstructured startup concurrency + retry path always firing**
   - Symptom: duplicated library imports and overlapping `library.import.*` logs on startup.
   - Fix: `CoachAgent.retryDeferredLibraryImport()` now runs only when `libraryEmbeddingsDeferred` is true, and `prepareLibraryIfNeeded()` coalesces concurrent calls with an in-flight task guard in `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift`.
   - Safety: only reduces redundant work; no change to data model or ingest semantics.

2) **Refresh storm + stale suppression + no soft UI timeout**
   - Symptom: recommendations appear stuck (spinner forever) or never appear because stale results are discarded while the list is empty.
   - Fix: `CoachViewModel` now applies stale results when the UI is empty, schedules follow-up refreshes as before, and adds a true soft timeout that stops the spinner while the task continues, in `Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift`.
   - Safety: UI-only behavior; recommendations task is not canceled; results still apply when they eventually arrive.

3) **Hard timeout message not truthful**
   - Symptom: notice promises background progress when the task is canceled.
   - Fix: updated notice string and increased hard timeout (to a safety-cap value) in `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`.
   - Safety: clearer messaging; no change to recommendation selection logic.

## Residual Risk / Notes
- `AppViewModel.start()` still marks `.ready` before `orchestrator.start()` completes in `Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift`, so foreground refresh probes can still overlap startup. The library import is now guarded, but other startup probes may still overlap.
