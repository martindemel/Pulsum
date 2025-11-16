# Gate 2 Summary — Voice Journaling End-to-End

This document freezes the state of Gate 2 (Voice Journaling) as of 2025‑11‑12. It records the architectural changes, test coverage, and CI wiring required to keep the gate green in the future.

---

## 1. Shared Types & Notifications

**Package:** `Packages/PulsumTypes`

- `SpeechSegment` moved to `PulsumTypes/Sources/PulsumTypes/SpeechTypes.swift` so Services, Agents, and UI share the same transcript struct (`transcript`, `isFinal`, `confidence`).
- Notification names (`.pulsumScoresUpdated`, `.pulsumChatRouteDiagnostics`, `.pulsumChatCloudError`) and `AgentNotificationKeys.date` now live in `PulsumTypes/Sources/PulsumTypes/Notifications.swift`.
- Duplicate definitions in Services/Agents were removed; all layers import `PulsumTypes` instead.

## 2. Speech Service (Mic Preflight & Modern Backend Hook)

**File:** `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift`

- `preflightPermissions()` chains `SFSpeechRecognizer.requestAuthorization` and `AVAudioSession.requestRecordPermission`, caches the state, and throws typed `SpeechServiceError` values (BUG‑0006).
- Speech logging is DEBUG‑gated (`SpeechLoggingPolicy.transcriptLoggingEnabled`).
- Feature flag `BuildFlags.useModernSpeechBackend` selects the modern backend when available; otherwise falls back to `LegacySpeechBackend`.
- `SpeechService.Session` streams `PulsumTypes.SpeechSegment` with `isFinal` and optional confidence values.
- UITest overrides (`UITEST_FAKE_SPEECH` / `UITEST_AUTOGRANT`) remain DEBUG-only so Release builds have no seams.
- Tests: `Gate0_SpeechServiceAuthorizationTests` (permission matrix) and `Gate2_ModernSpeechBackendTests` (flag/availability coverage).

## 3. SentimentAgent & JournalSessionState (Duplicate Guard / Teardown)

**Files:** `Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift`, `JournalSessionState` (same file)

- Rebuilt `JournalSessionState` as a serial-queue-protected struct that:
  - Throws `SentimentAgentError.sessionAlreadyActive` when begin is called twice.
  - Tracks transcript snapshots and audio levels.
  - Provides `takeSession()` to guarantee a single exit path.
- `SentimentAgent.finishVoiceJournal` calls `sessionState.takeSession()` and enforces non-empty transcripts, throwing `.noSpeechDetected` otherwise.
- On legacy streaming, any error triggers `sessionState.stopActiveSession()` so audio engines stop cleanly (BUG‑0034).

## 4. AgentOrchestrator (Reprocess + Notification + Safety)

**File:** `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`

- `finishVoiceJournalRecording` awaits sentiment + safety evaluation, then calls `DataAgent.reprocessDay(date:)` and posts `.pulsumScoresUpdated` with `AgentNotificationKeys.date` (BUG‑0005).
- `recordVoiceJournal` guards `isVoiceJournalActive`, consumes the streaming transcript, and on failure:
  - Finishes with the cached transcript if non-empty.
  - Otherwise stops the session explicitly.
- Public accessors `voiceJournalSpeechStream`, `voiceJournalAudioLevels`, and `updateVoiceJournalTranscript` allow the UI to stay in sync.
- Tests: `Gate2_JournalSessionTests` catches duplicate begin/teardown behavior; `Gate2_OrchestratorLLMKeyAPITests` verifies LLM key APIs and connectivity.

## 5. DataAgent (Reprocess Wellbeing)

**File:** `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`

- Added `reprocessDay(date:)` entry point that recomputes feature vectors / ScoreBreakdown for the target date. This is idempotent and reuses the existing Core Data pipeline.
- Internal helper `reprocessDayInternal` handles out-of-range dates by aligning to midnight before re-running metrics.

## 6. UI Layer (Transcript Persistence, Toasts, Waveform)

**Files:** `Packages/PulsumUI/Sources/PulsumUI/PulseViewModel.swift`, `PulseView.swift`, `LiveWaveformLevels.swift`

- `PulseViewModel.handleJournalResponse` stores transcript, sentiment, and `savedToastMessage` (“Saved to Journal”), dismissing the toast after 3 s via a Task.
- `PulseView` shows the toast with `VoiceJournalSavedToast` accessibility identifier and keeps the transcript visible until the user taps “Clear”.
- `LiveWaveformLevels` implements a fixed-size ring buffer with `Swift.max/Swift.min` clamping (`clamp01`) and tracks `samplesAppended` for perf tests (BUG‑0032).
- UITests (`PulsumUITests/JournalFlowUITests.swift`) verify transcript persistence, toast behavior, and duplicate-session guard.

## 7. Settings ViewModel (Notifications & Diagnostics)

**File:** `Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift`

- Observes `.pulsumScoresUpdated` and route/diagnostic notifications via `NotificationCenter` using the shared PulsumTypes constants.
- LLM key management now calls the orchestrator methods and surfaces statuses via `gptAPIStatus`.

## 8. CI Gate Harness

**Files:** `scripts/ci/test-harness.sh`, `scripts/ci/integrity.sh`, `.github/workflows/test-harness.yml`

- `test-harness.sh`:
  - Runs `swift test --list-tests` per package, extracts all `Gate[0-9]_` prefixes, builds a regex, then runs the matching suites in parallel.
  - Adds `SKIP_UI_GATES=1` escape hatch. When not set, resolves an available iOS simulator (prefers iPhone 16 Pro on iOS 26.x) and runs `xcodebuild … -only-testing:PulsumUITests` with `UITEST_FAKE_SPEECH=1` and `UITEST_AUTOGRANT=1`.
  - Logs to `/tmp/pulsum_*_gate.log` for later inspection.
- `integrity.sh` now calls the harness after the placeholder/secret/privacy scans so the Gate suites run before the Release build.
- GitHub Actions workflow (`.github/workflows/test-harness.yml`) simply runs the same script on macOS runners.

## 9. Documentation & Tracking

- `architecture.md` now lists `PulsumTypes` in the Repository Map/Modules section and documents the journaling → reprocess → notify flow.
- `gates.md` status updated to note shared types + harness coverage (Gate 2 is marked ✅ with references to the relevant tests).
- `instructions.md` gained a “CI Gate Harness” section explaining how to run the script locally and what it covers.
- `todolist.md` logs “Wire Gate suites into CI” as complete and reminds us that future Gate3/4 suites are auto-discovered.

## 10. Open Items / Tips

- **Simulator availability:** The harness expects an iOS 26.x simulator. If a host lacks one, set `SKIP_UI_GATES=1` temporarily and install the runtime via Xcode ▸ Settings ▸ Platforms.
- **Transcript logging:** Keep `SpeechLoggingPolicy` DEBUG-only to meet privacy rules; do not add Release logging of transcripts, safety classifications, or HealthKit data.
- **Naming future tests:** Prefix new critical-path suites with `GateN_` for automatic discovery and add descriptive UITest names (e.g., `JournalFlowUITests.test...`) for clarity.

By preserving this summary, future debugging of Gate 2 regressions can start with the listed files, tests, and CI hooks rather than re-deriving the entire scope.
