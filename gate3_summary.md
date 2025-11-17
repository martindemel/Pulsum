# Gate 3 — HealthKit Ingestion & UI Freshness

## Problem (BUG‑0024 / 0037 / 0040 / 0043)
- HealthKit authorization logic was all-or-nothing, so denied/not-determined types still started observers and Settings couldn’t show partial status.
- Restarting ingestion after the user re-granted access duplicated observers and left revoked types running.
- `AgentOrchestrator.postScoresUpdated` was removed but nothing replaced it, so `.pulsumScoresUpdated` never fired after HealthKit ingest or manual recomputes.
- Settings/Onboarding always celebrated on first load if permissions were already granted, giving users a misleading “success” toast.

## Solution
- Introduced `HealthAccessStatus` + `HealthKitServicing` seams so `DataAgent` evaluates per-type status before building observers. New APIs (`startIngestionIfAuthorized`, `restartIngestionAfterPermissionsChange`, `currentHealthAccessStatus`) let `AgentOrchestrator` and Settings re-query idempotently.
- `DataAgent` is now the **single owner** of the freshness bus: every recompute (manual reprocess, sliders, HealthKit quantity/sleep/deletion) calls `notifySnapshotUpdate(for:)`, emitting `.pulsumScoresUpdated` with `AgentNotificationKeys.date`.
- Settings/Onboarding read `HealthAccessStatus` and render:
  - summary text (`x/6 granted`)
  - missing-type detail (names of denied/not-determined types)
  - per-type rows with icons + grant status
  - success toast only when the state transitions from “not fully granted” → “fully granted” or immediately after a user-initiated `requestHealthKitAuthorization`.
- Debug-only seams (`PULSUM_HEALTHKIT_STATUS_OVERRIDE`, `PULSUM_HEALTHKIT_REQUEST_BEHAVIOR`) keep UITests deterministic.

## Key Files & Anchors
- `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift` — reprocess + notification flow (`344‑510`), HealthKit observer handling (`386‑509`).
- `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift` — surfaces `currentHealthAccessStatus`, `requestHealthAccess`, `restartIngestionAfterPermissionsChange`.
- `Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift` — toast gating, request flow, per-type row construction (`36‑216`).
- `Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift` — override hooks and authorization helpers.
- `gates.md` (Gate 3 row) + `architecture.md` (HealthKit / freshness notes) for high-level context.

## Tests & Harness
- **Packages:** `Gate3_FreshnessBusTests`, `Gate3_HealthAccessStatusTests`, `Gate3_IngestionIdempotenceTests`.
- **UI:** `Gate3_HealthAccessUITests` (partial status + request flow + “no toast on initial fully granted”).
- Run `scripts/ci/test-harness.sh` to execute all Gate suites plus PulsumUITests on iOS 26 simulator.

## Simulating Scenarios
- `PULSUM_HEALTHKIT_STATUS_OVERRIDE="HKQuantityTypeIdentifierHeartRate=authorized,HKCategoryTypeIdentifierSleepAnalysis=denied"` — drive partial states.
- `PULSUM_HEALTHKIT_REQUEST_BEHAVIOR=grantAll` — force the in-app request button to grant all types (used by UITests/spot checks).
- Optional: set `UITEST_CAPTURE_TREE=1` to record hierarchy snapshots during UI runs.

## Follow-ups / Watch Items
- Monitor background-delivery reliability; `todolist.md` still calls out exploring BGTasks for HealthKit refresh (Gate 4 scope).
- Expand CI discovery if additional Gate 4 suites are added.
- Keep `bugs.md`, `gates.md`, `todolist.md`, and `architecture.md` aligned when future HealthKit or freshness changes ship.
