# Gate 4 — RAG / LLM Wiring & Consent UX

## Problem (BUG‑0004 / 0008 / 0010 / 0023 / 0041)
- Guardrail payloads sent to GPT‑5 omitted micro‑moment context, violating the minimized‑context contract and letting cloud replies drift off-topic.
- Fallback routing probed feature keys that don’t exist in `FeatureVectorSnapshot`, so “data-dominant” decisions always defaulted to `subj_energy`.
- Settings had no working Apple Intelligence CTA, no runtime GPT key storage, and no deterministic Save/Test UX; ESC key dismissal crashed because `.onKeyPress` closures returned `Void`.
- `LLMGateway` PING validation rejected every payload due to case-sensitive mismatch, so “Test Connection” always failed.
- CI harnesses didn’t guarantee the Pulsum app target built before Gate suites and didn’t single out the Gate 4 UI acceptance flows.

## Solution
- Added `MinimizedCloudRequest` and candidate moment schema guards inside `LLMGateway` so outbound payloads now include `{userToneHints, topSignal, topMomentId, rationale, zScoreSummary, candidateMoments[]}` and reject PHI or unexpected keys before hitting `/v1/responses`. (`Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:1-220,836-878`)
- Introduced `TopicSignalResolver` and updated `CoachAgent.chatResponse` so topics map to the actual `z_*`/`subj_*`/`sentiment` keys, data-dominant fallback selects max |z|, and candidateMoments + `topMomentId` are forwarded through to the gateway. (`Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:19-72`; `CoachAgent.swift:78-205`)
- Rebuilt the Settings “Cloud Processing” card with a secure API-key field, Save/Test buttons, deterministic status pill, escape helper returning `KeyPress.Result`, and an Apple Intelligence CTA that opens `UIApplication.openSettingsURLString` with logging + fallback to Apple’s support URL. (`Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift:60-320,536-600`; `SettingsViewModel.swift:135-179`)
- Fixed `LLMGateway.validatePingPayload` to accept case-insensitive “ping”, exposed a deterministic `makePingRequestBody`, and wired Settings’ “Test Connection” button to use it so users can verify keys on-device. (`Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:879-912`)
- Hardened `scripts/ci/test-harness.sh` to build the Pulsum app for iPhone 16 Pro (iOS 26) before running Gate suites, auto-discover Gate4_* tests in SPM packages, and execute Gate 4 UITests on a 26.0 simulator. (`scripts/ci/test-harness.sh:14-198`)

## Key Files & Anchors
- `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift` — MinimizedCloudRequest, schema guard, ping validator, chat payload builder.
- `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift` — TopicSignalResolver and routing diagnostics.
- `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift` — Candidate moment retrieval + context wiring.
- `Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift` & `SettingsViewModel.swift` — Consent toggle, key management, Apple Intelligence CTA, ESC helper.
- `scripts/ci/test-harness.sh` — Build-first flow plus Gate4 package + UI test execution.
- Documentation updates in `architecture.md` (Section 2) and `bugs.md` record the Gate 4 fixes/status.

## Tests & Harness
- **Agents:** `Gate4_RoutingTests` verify TopicSignalResolver and data-dominant fallback; `Gate4_LLMKeyTests` exercise Keychain round-trip + ping guard. (`Packages/PulsumAgents/Tests/PulsumAgentsTests`)
- **Services:** `Gate4_LLMGatewayPingSeams` ensures UITest stubs short-circuit, while `LLMGatewaySchemaTests` assert minimized payload structure and PHI guards. (`Packages/PulsumServices/Tests/PulsumServicesTests`)
- **Consent Routing:** `Gate4_ConsentRoutingTests` confirms cloud vs on-device routing obeys consent toggles.
- **UI:** `Gate4_CloudConsentUITests` cover Save/Test API key UX, Apple Intelligence fallback link, and Escape key dismissal. (`PulsumUITests/Gate4_CloudConsentUITests.swift`)
- Run `scripts/ci/test-harness.sh` to build the app, execute all Gate suites (including the new Gate4_* groups), and launch the UI suite on the preferred iOS 26 simulator.

## Simulating Scenarios
- `UITEST_FORCE_SETTINGS_FALLBACK=1` + `UITEST_CAPTURE_URLS=1` — forces Apple Intelligence CTA to log and open the support article path; UITest asserts the recorded URL.
- `UITEST_USE_STUB_LLM=1` — short-circuits GPT ping/coach requests so Gate suites can run without a live key while still validating schema construction.
- Modify `PULSUM_COACH_API_KEY` (env) to emulate env/keychain precedence during local smoke tests.

## Follow-ups / Watch Items
- Monitor Gate4 coverage in CI: if additional consent/routing regressions appear, extend `Gate4_ConsentRoutingTests` to include topic-specific candidate payload assertions.
- Observe production telemetry for Settings CTA success to confirm Apple Intelligence enablement guidance is clear; update copy if Apple publishes an iOS-specific deep link.
- As future gates add new schema fields, update `MinimizedCloudRequest.allowed*Keys` and schema tests so guardrails stay strict.
