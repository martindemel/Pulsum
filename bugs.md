# Pulsum Bug Audit

**Scan Context:** Repo Pulsum @ working tree | UTC 2025-10-26T19:30:00Z
**Changes in this pass:** Added:11  Updated:15  Obsolete:0  Duplicates:0
**Coverage Summary:** PulsumApp{files_read:5,lines:727} PulsumUI{files_read:16,lines:4847} PulsumAgents{files_read:8,lines:2563} PulsumServices{files_read:9,lines:3142} PulsumData{files_read:7,lines:1841} PulsumML{files_read:12,lines:2094} Config/Assets{files_read:9} Tests{files_read:6,all_empty_stubs}

## Quick Readout
- BUG-20251026-0001 — Live OpenAI key embedded in repo. GPT-5 credential ships with every clone and build, exposing billing to anyone. (S0 Privacy/Security) **[Fixed Gate 0]**
- BUG-20251026-0002 — Privacy manifests missing for all targets. Without them Apple blocks binaries that touch protected APIs. (S1 Privacy/Security) **[Fixed Gate 0]**
- BUG-20251026-0003 — Speech entitlement absent; authorization denied. Hardware devices refuse recognition so journaling can't start. (S1 Config) **[Gate 0 logic/tests fixed; signing follow-up pending]**
- BUG-20251026-0004 — Retrieval context dropped from GPT payloads. Coach guardrail never sends micro-moment snippets, so answers are ungrounded. (S1 Wiring)
- BUG-20251026-0005 — Journals don't trigger wellbeing reprocessing. Sentiment persists but the score/contributions stay stale afterward. (S1 Data)
- BUG-20251026-0006 — Microphone permission never requested. Recorder spins up audio without prompting, leading to first-run failure. (S1 Wiring) **[Fixed Gate 0]**
- BUG-20251026-0007 — Modern speech backend still stubbed. iOS 26 path falls back to legacy APIs, losing latency and accuracy gains. (S2 Dependency)
- BUG-20251026-0008 — Fallback routing reads non-existent feature keys. When topic inference fails the router always defaults to energy. (S1 Data)
- BUG-20251026-0009 — Pulse transcript hides after analysis completes. UI clears the text once flags drop, so users think nothing saved. (S2 UI)
- BUG-20251026-0010 — Apple Intelligence link uses macOS-only URI. The enablement button no-ops on iOS, blocking cloud guardrail consent. (S2 UI)
- BUG-20251026-0011 — Liquid Glass Spline hero missing. Home view renders only a gradient, missing the promised flagship visual. (S2 UI)
- BUG-20251026-0012 — Vector index shard cache races initialization. Double-checked locking can expose half-built shards during search. (S0 Concurrency) **[Fixed Gate 5]**
- BUG-20251026-0013 — Podcast dataset duplicated three times. Three copies inflate the bundle and invite divergent edits. (S2 Data) **[Fixed Gate 5]**
- BUG-20251026-0014 — Shared scheme skips SwiftPM test targets. Product ▸ Test runs only empty bundles, hiding regressions. (S1 Test) **[Fixed Gate 1]**
- BUG-20251026-0015 — Pulse check-ins never refresh recommendations. Sliders finish quietly without kicking off a new wellbeing fetch. (S1 Wiring)
- BUG-20251026-0016 — Voice journal session allows duplicate starts. No guard against concurrent beginVoiceJournal calls, leaking resources. (S1 Wiring)
- BUG-20251026-0017 — FileHandle close errors silently swallowed. Vector index upsert/remove suppress close failures, leaking descriptors. (S1 Data) **[Fixed Gate 5]**
- BUG-20251026-0018 — Backup exclusion failures ignored. PHI data can leak to iCloud if setResourceValues silently fails. (S0 Privacy/Security) **[Fixed Gate 0]**
- BUG-20251026-0019 — Foundation Models stub has wrong response type. Expects structured SentimentAnalysis but returns string, causing runtime crash. (S0 Dependency) **[Fixed Gate 0]**
- BUG-20251026-0020 — AFM contextual embeddings permanently disabled. Primary embedding path falls back to legacy word vectors with TODO. (S1 Dependency) **[Fixed Gate 6 – opportunistic AFM + CoreML fallback]**
- BUG-20251026-0021 — Embedding zero-vector fallback masks failures. All provider failures return [0,0,...], corrupting similarity search. (S1 ML) **[Fixed Gate 6 – zero-vector ban + availability probe + self-healing recheck]**
- BUG-20251026-0022 — Core Data blocking I/O on database thread. LibraryImporter reads JSON inside context.perform, freezing UI. (S2 Data) **[Fixed Gate 5]**
- BUG-20251026-0023 — LLM PING validation has case mismatch. Request sends "PING" but validator expects "ping", always failing. (S2 Wiring)
- BUG-20251026-0024 — HealthKit queries lack authorization checks. Observer queries execute without verifying user permission status. (S1 Wiring)
- BUG-20251026-0025 — Test targets contain only empty scaffolds. PulsumTests and PulsumUITests have no actual assertions. (S1 Test) **[Fixed Gate 1]**
- BUG-20251026-0026 — Info.plist usage descriptions defined but permissions never requested. Microphone description exists but AVAudioSession.requestRecordPermission never called. (S1 Config) **[Fixed Gate 0]**
- BUG-20251026-0027 — RecRanker never updates from acceptance events. Recommendations stay static and ignore user feedback. (S1 ML)
- BUG-20251026-0028 — Wellbeing weights invert HRV/steps impact. Higher recovery metrics lower the score. (S1 ML)
- BUG-20251026-0029 — App bootstrap spawns orphan Tasks; startup can double-run orchestrator and swallow failures. (S1 Concurrency)
- BUG-20251026-0030 — Design system hardcodes point-size fonts; Dynamic Type and accessibility text scaling break. (S1 UI)
- BUG-20251026-0031 — User-facing copy is hardcoded; no Localizable.strings so the app cannot localize. (S1 UI)
- BUG-20251026-0032 — Waveform renderer reallocates full audio buffer each frame, causing avoidable main-thread churn. (S2 Performance)
- BUG-20251026-0033 — SpeechService logs live transcripts verbatim, leaking PHI into release logs. (S1 Privacy/Security) **[Fixed Gate 0]**
- BUG-20251026-0034 — Legacy recordVoiceJournal path never tears down sessions on errors, leaving the mic hot and skipping safety review. (S1 Wiring)
- BUG-20251026-0035 — PulseView references UIKit haptics without importing UIKit, so the app fails to compile. (S1 UI) **[Fixed Gate 0]**
- BUG-20251026-0036 — Checked-in Pulsum.xcodeproj.backup still wires SplineRuntime and old build scripts, inviting regressions. (S3 Build)
- BUG-20251026-0037 — Wellbeing card never refreshes after HealthKit sync; score stays stale until user revisits Insights. (S1 UI) **[Fixed Gate 6 – explicit no-data/permission states]**
- BUG-20251026-0038 — StateEstimator weights are never persisted, so wellbeing personalization resets every launch. (S1 ML)
- BUG-20251026-0039 — Journal sentiment feature is absent from the wellbeing target, leaving that metric permanently zero. (S1 ML)
- BUG-20251026-0040 — HealthKit request buttons never restart DataAgent, so new permissions do nothing until relaunch. (S1 Wiring) **[Fixed Gate 6 follow-up – shared service + Settings/request refresh]**
- BUG-20251026-0041 — ChatGPT-5 API settings show only a status light; there’s no input or save action so users can’t supply their own key. (S1 UI)
- BUG-20251026-0042 — Chat keyboard stays visible on other tabs; focus never resigns when leaving the Coach screen. (S2 UI)
- BUG-20251026-0043 — HealthKit status indicator looks only at HRV authorization, so it reports “Authorized” even when other required types are denied. (S2 UI)
- BUG-20251026-0045 — HealthKit backfill over 30 days stalls on large datasets (heart rate/steps/respiratory), leaving coverage at 0/0. (S1 Data) **[Fixed Gate 6 – phased 7d warm-start + persisted background batches to 30d]**

## How to Use This Document
Packs group related findings so you can triage by domain. Open the referenced card IDs to review evidence with sig8 hashes, then plan fixes downstream. No fixes are proposed here—each card stops at evidence, impact, and suggested diagnostics.

## Topline Triage
| Area | Gap | Bug |
| --- | --- | --- |
| Wiring | 0 | 8 |
| Config | 0 | 2 |
| Dependency | 0 | 3 |
| Data | 0 | 5 |
| Concurrency | 0 | 1 |
| UI | 0 | 8 |
| Privacy/Security | 0 | 4 |
| Test | 0 | 2 |
| ML | 0 | 3 |
| Build | 0 | 1 |

**Critical Blockers:** BUG-20251026-0004, BUG-20251026-0005, BUG-20251026-0008, BUG-20251026-0015, BUG-20251026-0016, BUG-20251026-0029, BUG-20251026-0030, BUG-20251026-0031, BUG-20251026-0034, BUG-20251026-0040, BUG-20251026-0041

## Pack Privacy & Compliance

### BUG: OpenAI API key embedded in repository and app bundle
- **ID:** BUG-20251026-0001
- **Severity:** S0
- **Area:** Privacy/Security
- **Confidence:** High
- **Status:** Mitigated (Gate 2 — feature flag + availability hook)
- **Symptom/Impact:** Every clone and shipped build carries a live OpenAI project key, exposing billing and rate limits to anyone who inspects the app bundle.
- **Where/Scope:** Config.xcconfig:5; all targets that link PulsumServices.
- **Evidence:**
  - Config.xcconfig:5  [sig8:0b61c5eb] — `OPENAI_API_KEY = <redacted>...` (full 176-char key hardcoded)
  - Pulsum.xcodeproj/project.pbxproj:483,526  [sig8:a8f3c2d1] — `INFOPLIST_KEY_OPENAI_API_KEY = "$(OPENAI_API_KEY)"` exposes key in Info.plist
- **Upstream/Downstream:** LLMGateway.resolveAPIKey() reads from Info.plist (LLMGateway.swift:136-210), so all coach prompts leak the credential in built IPA.
- **Why This Is a Problem:** Shipping live secrets violates OpenAI policy and allows immediate abuse; App Store review can flag the leak; any user can extract key from IPA with `strings` command.
- **Suggested Diagnostics (no code):** Run `strings Pulsum.app/Pulsum | grep sk-proj` on built IPA; rotate key immediately; audit OpenAI usage logs for anomalous traffic from Oct 2025 onwards.
- **Related Contract (from architecture.md):** Architecture section 12 warns about GPT-5 credential hygiene; section 17 lists this as risk #1.
- **Fix (2025-10-23):** Config.xcconfig no longer contains keys, project build settings stop copying secrets into Info.plist, `LLMGateway` now resolves keys only from in-memory injection, Keychain, or the `PULSUM_COACH_API_KEY` environment variable, and `scripts/ci/scan-secrets.sh` plus new unit tests enforce the policy across repo/build artifacts. Gate‑0 regression coverage now lives in `Gate0_LLMGatewayTests` (missing key + precedence) and the hardened secret scanner inspects both the repo and built `.app` bundles for `sk-...`, `OPENAI_API_KEY =`, and `INFOPLIST_KEY_OPENAI_API_KEY`.

### BUG: Required PrivacyInfo manifests absent for app and packages
- **ID:** BUG-20251026-0002
- **Severity:** S1
- **Area:** Privacy/Security
- **Confidence:** High
- **Status:** Fixed (Gate 0 — Security & Build Blockers; logic + tests)
- **Follow-up:** Pending (provisioning alignment for `com.apple.developer.speech`)
- **Symptom/Impact:** iOS 17+ binaries without PrivacyInfo.xcprivacy are rejected for using APIs like HealthKit and microphone access.
- **Where/Scope:** Pulsum target; all five Pulsum Swift packages (PulsumUI, PulsumAgents, PulsumData, PulsumServices, PulsumML).
- **Evidence:**
  - Pulsum.xcodeproj/project.pbxproj:282-288  [sig8:f120678c] — App resources include only dataset JSON and spline file; no PrivacyInfo.xcprivacy
  - Bash audit shows zero PrivacyInfo.xcprivacy files exist in entire repository
- **Upstream/Downstream:** App Store submission, TestFlight validation, and enterprise compliance reviews explicitly require manifests per WWDC23-10060.
- **Why This Is a Problem:** Without manifests Apple blocks distribution of binaries that touch protected data categories (HealthKit, microphone, speech recognition) described in architecture.
- **Suggested Diagnostics (no code):** Create manifests following Apple template; run Xcode's Privacy Report (Product → Analyze → Privacy); verify App Store Connect privacy checks pass.
- **Related Contract (from architecture.md):** Compliance section mandates manifests for every module consuming protected APIs; CLAUDE.md marks this MANDATORY.
- **Fix (2025-10-23):** Added `PrivacyInfo.xcprivacy` files for the app plus PulsumUI/Agents/Data/Services/ML packages declaring the file-metadata reason, and introduced `scripts/ci/check-privacy-manifests.sh` (with optional `RUN_PRIVACY_REPORT=1`) to verify manifests exist and Xcode’s Privacy Report is runnable in CI. The script now uses `plistlib` for validation, verifies the app target has exactly one “PrivacyInfo.xcprivacy in Resources” entry, and fails if `project.pbxproj` ever tries to copy more than one manifest, preventing the “Multiple commands produce … PrivacyInfo.xcprivacy” warning.

### BUG: Speech recognition capability missing from entitlements
- **ID:** BUG-20251026-0003
- **Severity:** S1
- **Area:** Config
- **Confidence:** High
- **Status:** Fixed (Gate 0 — Security & Build Blockers)
- **Symptom/Impact:** `SFSpeechRecognizer.requestAuthorization` returns `.denied` on-device because the signed binary lacks `com.apple.developer.speech`.
- **Where/Scope:** Pulsum app entitlements.
- **Evidence:**
  - Pulsum/Pulsum.entitlements:5-8  [sig8:518aea3d] — Only two HealthKit keys declared; speech recognition entitlement missing
- **Upstream/Downstream:** Pulse journaling cannot start (SpeechService.swift:55-62), so sentiment analysis, safety vetting, and recommendations stall.
- **Why This Is a Problem:** iOS enforces capability checks before granting speech authorization, breaking the headline voice journaling feature.
- **Suggested Diagnostics (no code):** Add entitlement to plist; re-sign; confirm via `codesign -d --entitlements - Pulsum.app`.
- **Related Contract (from architecture.md):** Voice journaling pipeline (section 8) assumes speech recognition capability is provisioned.
- **Fix (2025-10-23):** Added `com.apple.developer.speech` to `Pulsum.entitlements`, hardened `SpeechService` to preflight both speech and microphone permissions, and covered the matrix with new `Gate0_SpeechServiceAuthorizationTests`.
- **Signing note (2025-11-12):** Apple’s Developer portal still lacks a Speech capability toggle for App ID `ai.pulsum.Pulsum`, so the entitlement was temporarily removed from `Pulsum.entitlements` to unblock automatic signing. Runtime behavior (usage strings plus `SFSpeechRecognizer` + microphone preflight) remains intact. Once Apple exposes the Speech capability for this identifier, re-enable `com.apple.developer.speech` and regenerate provisioning profiles.

### BUG: Backup exclusion failures silently swallowed (PHI exposure risk)
- **ID:** BUG-20251026-0018
- **Severity:** S0
- **Area:** Privacy/Security
- **Confidence:** High
- **Status:** Fixed (Gate 0 — Security & Build Blockers)
- **Symptom/Impact:** PHI data (journals, health metrics, vector embeddings) could be backed up to iCloud if `setResourceValues` fails silently, violating HIPAA/GDPR.
- **Where/Scope:** DataStack initialization.
- **Evidence:**
  - Packages/PulsumData/Sources/PulsumData/DataStack.swift:85-89  [sig8:3a8f1b2c] — Three `try?` statements swallow all backup exclusion errors:
    ```swift
    try? supportURL.setResourceValues(resourceValues)
    try? vectorURL.setResourceValues(resourceValues)
    try? anchorURL.setResourceValues(resourceValues)
    ```
- **Upstream/Downstream:** All Core Data stores, vector index files, and HealthKit anchors could sync to iCloud; compliance violation; App Store rejection risk.
- **Why This Is a Problem:** Architecture section 12 requires file protection and backup exclusion for PHI; silent failures violate this contract; user data exposed in cloud backups.
- **Suggested Diagnostics (no code):** Log failures or throw; verify backup status with `xattr -l <path> | grep com.apple.metadata:com_apple_backup_excludeItem`; test on iOS with iCloud enabled.
- **Related Contract (from architecture.md):** Section 12 mandates backup exclusion for all PHI storage; DataStack.swift:71-89 intends to implement this but errors are suppressed.
- **Fix (2025-10-23):** `DataStack` now enforces `.isExcludedFromBackup` with structured logging and exposes `BackupSecurityIssue`, AppViewModel blocks startup with a persistent panel until storage is secured, and the new `Gate0_DataStackSecurityTests` verifies temporary directories get the required xattrs.

### BUG: Info.plist usage descriptions defined but permissions never requested
- **ID:** BUG-20251026-0026
- **Severity:** S1
- **Area:** Config
- **Confidence:** High
- **Status:** Fixed (Gate 0 — Security & Build Blockers)
- **Symptom/Impact:** Microphone and speech usage descriptions exist in Info.plist but app never calls permission request APIs, causing first-run failures.
- **Where/Scope:** Pulsum build settings; SpeechService.
- **Evidence:**
  - Pulsum.xcodeproj/project.pbxproj:481-482  [sig8:6a3d8f1e] — `INFOPLIST_KEY_NSMicrophoneUsageDescription` and `INFOPLIST_KEY_NSSpeechRecognitionUsageDescription` defined
  - Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:55-62  [sig8:7b9e4c2a] — Only calls `SFSpeechRecognizer.requestAuthorization`, never `AVAudioSession.requestRecordPermission`
- **Upstream/Downstream:** Voice journaling fails with `.audioSessionUnavailable` on first run (SpeechService.swift:97-128); users never see microphone permission prompt.
- **Why This Is a Problem:** iOS requires explicit permission request before microphone access; missing call breaks voice journaling flow.
- **Suggested Diagnostics (no code):** Add `await AVAudioSession.sharedInstance().requestRecordPermission()` call; test on clean iOS install; verify permission dialog appears.
- **Related Contract (from architecture.md):** Voice journaling pipeline section 8 assumes smooth permission acquisition; permission strings exist but wiring is incomplete.
- **Fix (2025-10-23):** `SpeechService` now requests microphone permission alongside speech authorization, surfaces actionable errors, and is covered by `Gate0_SpeechServiceAuthorizationTests` that exercise authorized/denied/restricted cases.
- **Signing note (2025-11-12):** Speech and microphone prompts remain in place even though `Pulsum.entitlements` no longer declares `com.apple.developer.speech`; restore the entitlement once Apple allows the capability on this App ID.

### BUG: Speech transcripts logged to device console leak PHI
- **ID:** BUG-20251026-0033
- **Severity:** S1
- **Area:** Privacy/Security
- **Confidence:** High
- **Status:** Fixed (Gate 0 — Security & Build Blockers)
- **Symptom/Impact:** Every interim and final transcription is printed via `print` even in release builds, so sensitive journal text lands in device logs, diagnostics uploads, and crash reports.
- **Where/Scope:** SpeechService recognition callback.
- **Evidence:**
  - Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:194-205 — Recognition handler prints `"[SpeechService] 🎤 Transcript update..."` plus the transcript and confidence before yielding to the stream.
  - Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:202-205 — Completion handler prints `"Recognition completed with final transcript"` without any `#if DEBUG` guard.
- **Upstream/Downstream:** Logs are accessible via Console, sysdiagnose, and crash logs, exporting PHI beyond the secure on-device store and violating the privacy contract outlined in the architecture.
- **Why This Is a Problem:** Voice journals are treated as PHI—logging them contradicts instructions.md (privacy constraint #1) and risks HIPAA/GDPR exposure whenever logs are shared for support.
- **Suggested Diagnostics (no code):** Build an Ad Hoc or Release configuration, record a journal, and inspect device Console; transcripts appear verbatim. Remove the logs or wrap them in `#if DEBUG`.
- **Related Contract (from architecture.md):** Privacy & Safety section mandates that journal text never leaves protected storage; CLAUDE.md reiterates “PII redaction and no PHI in logs.”
- **Fix (2025-10-23):** Replaced all transcript `print` statements with structured `Logger` calls guarded by `SpeechLoggingPolicy`, ensured release builds disable transcript logging entirely, and added a release-only regression test in `Gate0_SpeechServiceLoggingTests`.

## Pack Voice Journaling & Speech

### BUG: Voice journals persist sentiment but never refresh wellbeing snapshot
- **ID:** BUG-20251026-0005
- **Severity:** S1
- **Area:** Data
- **Confidence:** High
- **Status:** Fixed (Gate 2 — Voice journaling E2E)
- **Symptom/Impact:** After journaling, wellbeing score, contributions, and recommendations stay stale because DataAgent.reprocessDay() never runs.
- **Where/Scope:** AgentOrchestrator; SentimentAgent; DataAgent; PulseViewModel.
- **Evidence:**
  - Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:166-178  [sig8:3f5dbe49] — `finishVoiceJournalRecording` returns result + safety with no call into DataAgent
  - Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:230-246  [sig8:45dabec7] — Only `handleSubjectiveUpdate` triggers `reprocessDay`, not journal completion
- **Upstream/Downstream:** ScoreBreakdownView and CoachAgent retrieval run with stale FeatureVectorSnapshot, undermining architecture's promise of sentiment-informed insights.
- **Why This Is a Problem:** Architecture section 2 describes DataAgent merging sentiment capture into wellbeing scoring; journals were intended to feed the wellbeing engine; missing reprocessing erases that signal entirely.
- **Suggested Diagnostics (no code):** Log `FeatureVectorSnapshot.date` after journaling; compare wellbeing score before/after; add temporary NotificationCenter post to confirm reprocess fires; instrument DataAgent.reprocessDay() calls.
- **Related Contract (from architecture.md):** Section 7 ("Modules & Layers") states "DataAgent integrates subjective inputs" including journals; section 8 shows journal → sentiment → feature vector flow.
- **Fix (2025-11-11):** `AgentOrchestrator.finishVoiceJournalRecording` now awaits `DataAgent.reprocessDay(date:)` and emits `.pulsumScoresUpdated` so UI refreshes immediately (see Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:165-191). `AppViewModel` observes that notification and triggers `CoachViewModel.refreshRecommendations()`, while `PulseViewModel` displays the saved transcript until a user clears it. Coverage: `Gate2_JournalSessionTests` plus the updated `JournalFlowUITests.testRecordStreamFinish_showsSavedToastAndTranscript`.

### BUG: Microphone permission never requested before starting audio engine
- **ID:** BUG-20251026-0006
- **Severity:** S1
- **Area:** Wiring
- **Confidence:** High
- **Status:** Fixed (Gate 0 — Security & Build Blockers)
- **Symptom/Impact:** First-time recordings fail with `audioSessionUnavailable` because app never asks for microphone access via `AVAudioSession.requestRecordPermission`.
- **Where/Scope:** SpeechService; PulseViewModel.
- **Evidence:**
  - Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:55-62  [sig8:a3db3607] — `requestAuthorization()` only requests speech recognition, not microphone
  - Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:97-128  [sig8:b9c7d3e1] — `startRecording` configures AVAudioSession and engine but assumes microphone permission already granted
- **Upstream/Downstream:** Pulse journaling cannot capture audio; SentimentAgent gets empty transcripts; wellbeing updates stall; error surfaces as generic `.audioSessionUnavailable`.
- **Why This Is a Problem:** iOS requires explicit microphone permission distinct from speech recognition permission; skipping the prompt causes silent failure, breaking the flagship voice journaling flow.
- **Suggested Diagnostics (no code):** Check `AVAudioSession.sharedInstance().recordPermission` before recording; collect first-run console logs while attempting recording; verify permission dialog never appears for microphone (only speech).
- **Related Contract (from architecture.md):** Voice journaling pipeline (section 8) expects smooth microphone activation with fallback prompts; SpeechService is supposed to handle all permission acquisition.
- **Fix (2025-11-09):** `SpeechService` now chains `SFSpeechRecognizer.requestAuthorization` with `AVAudioSession.requestRecordPermission`, surfaces precise `SpeechServiceError` cases, and the new `Gate0_SpeechServiceAuthorizationTests` cover authorized, denied, and restricted flows.
- **Signing note (2025-11-12):** Permission prompts stay enforced even though the Speech entitlement is temporarily removed to align with today’s provisioning profile; no Gate 0 regression is expected.

### BUG: Modern speech backend is a stub that downgrades to legacy APIs
- **ID:** BUG-20251026-0007
- **Severity:** S2
- **Area:** Dependency
- **Confidence:** High
- **Status:** Fixed (Gate 0 — Security & Build Blockers)
- **Symptom/Impact:** iOS 26 devices never exercise the SpeechAnalyzer/SpeechTranscriber path; all transcription falls back to older SFSpeechRecognizer with reduced accuracy.
- **Where/Scope:** SpeechService ModernSpeechBackend.
- **Evidence:**
  - Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:296-303  [sig8:30e8e734] — `ModernSpeechBackend.startRecording` implementation:
    ```swift
    // Placeholder: integrate SpeechAnalyzer/SpeechTranscriber APIs when publicly available.
    // For now we reuse the legacy backend to ensure functionality.
    return try await fallback.startRecording(maxDuration: maxDuration)
    ```
  - Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:300-302  [sig8:4b8e9a2c] — Backend selection checks for iOS 26 APIs but always uses legacy fallback
- **Upstream/Downstream:** Modern latency/quality improvements promised in architecture do not materialize; marketing claims about Apple Intelligence speech features are unfulfilled.
- **Why This Is a Problem:** Milestone 4 required Apple Intelligence speech features; code never integrates them; iOS 26 requirement provides no speech benefit over iOS 17.
- **Suggested Diagnostics (no code):** Instrument availability checks for `SpeechAnalyzer`/`SpeechTranscriber`; profile transcription quality on iOS 26 hardware; compare timings versus legacy path; confirm APIs are actually public.
- **Related Contract (from architecture.md):** Section 7 ("Services layer") specifies modern backend powered by Apple Intelligence APIs; CLAUDE.md documents this as known stub.
- **Fix (2025-11-11):** Added `BuildFlags.useModernSpeechBackend` plus `SpeechServiceDebug.overrideModernBackendAvailability` so DEBUG builds can toggle the modern path once Apple’s APIs ship. Selection now logs backend latency per start (Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:89-145), and `Gate2_ModernSpeechBackendTests` verifies the flag/availability override wiring. The runtime still falls back to the legacy backend until Apple exposes `SpeechAnalyzer`, but the Gate-2 requirement (hook + DEBUG-only latency probe) is satisfied and documented in `bugs.md` as a remaining dependency on Apple APIs.

### BUG: Pulse transcript disappears immediately after analysis completes
- **ID:** BUG-20251026-0009
- **Severity:** S2
- **Area:** UI
- **Confidence:** High
- **Status:** Fixed (Gate 2 — Voice journaling E2E)
- **Symptom/Impact:** Users cannot review what was just captured—transcript view hides as soon as recording and analysis flags drop to false, causing confusion.
- **Where/Scope:** PulseView SwiftUI.
- **Evidence:**
  - Packages/PulsumUI/Sources/PulsumUI/PulseView.swift:78  [sig8:bca9b0d3] — Transcript render condition:
    ```swift
    if let transcript = viewModel.transcript, !transcript.isEmpty,
       (viewModel.isRecording || viewModel.isAnalyzing) {
    ```
    View vanishes once `isRecording` and `isAnalyzing` are both false.
- **Upstream/Downstream:** Users assume journaling failed and may retry unnecessarily, reducing trust; no visual confirmation that transcript was saved.
- **Why This Is a Problem:** Architecture section 3 promises transcript playback UX; current implementation violates that contract by hiding transcript immediately.
- **Suggested Diagnostics (no code):** Capture screen recording of flow; instrument state flag transitions; confirm transcript visibility post-analysis; check ViewModel state management.
- **Related Contract (from architecture.md):** Section 10 ("UI Composition & Navigation") highlights PulseView transcript playback; section 8 describes sentiment capture preserving transcript for user review.
- **Fix (2025-11-11):** `PulseViewModel` now keeps the transcript and sentiment score until the user taps Clear, raises a “Saved to Journal” toast, and routes partial-error completions through the SafetyAgent. `PulseView` renders the transcript outside the recording/analyzing condition and exposes a deterministic toast (`VoiceJournalSavedToast`) asserted by `JournalFlowUITests.testRecordStreamFinish_showsSavedToastAndTranscript`. The new waveform buffer ensures transcript + waveform remain visible without stutter.

### BUG: Voice journal session allows duplicate starts without cleanup
- **ID:** BUG-20251026-0016
- **Severity:** S1
- **Area:** Wiring
- **Confidence:** High
- **Status:** Fixed (Gate 2 — Voice journaling lifecycle)
- **Symptom/Impact:** Calling `beginVoiceJournal` twice concurrently overwrites `activeSession` without stopping the previous one, leaking audio resources and SpeechService sessions.
- **Where/Scope:** SentimentAgent; AgentOrchestrator.
- **Evidence:**
  - Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift:60-65  [sig8:8d9a2f1b] — No guard against duplicate calls:
    ```swift
    public func beginVoiceJournal(maxDuration: TimeInterval = 30) async throws {
        try await speechService.requestAuthorization()
        let session = try await speechService.startRecording(maxDuration: min(maxDuration, 30))
        activeSession = session  // ⚠️ Overwrites without cleanup
        latestTranscript = ""
    }
    ```
  - Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:159-161  [sig8:6c8b3d4e] — Orchestrator has no duplicate-call protection
- **Upstream/Downstream:** Previous recording session leaks; audio engine remains active; user hears multiple recordings; system resources consumed.
- **Why This Is a Problem:** Resource leak vulnerability; audio system can become unstable with multiple active sessions; user confusion from overlapping recordings.
- **Suggested Diagnostics (no code):** Instrument `activeSession` lifecycle; test concurrent `beginVoiceJournal` calls; check iOS audio session state; monitor file descriptor count during repeated starts.
- **Related Contract (from architecture.md):** SentimentAgent (section 7) should manage recording lifecycle properly; agent pattern assumes single active operation per instance.
- **Fix (2025-11-11):** `JournalSessionState` serializes access to `SpeechService.Session`, `AgentOrchestrator` tracks `isVoiceJournalActive`, and `PulseViewModel` calls the new `updateVoiceJournalTranscript(_:)` hook. Concurrent begins now throw `SentimentAgentError.sessionAlreadyActive` (see Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift:56-125), and `Gate2_JournalSessionTests` assert duplicate protection.

### BUG: Legacy recordVoiceJournal path never tears down sessions on errors
- **ID:** BUG-20251026-0034
- **Severity:** S1
- **Area:** Wiring
- **Confidence:** High
- **Status:** Fixed (Gate 2 — Guaranteed teardown)
- **Symptom/Impact:** If speech streaming throws (network drop, revoked permission), `AgentOrchestrator.recordVoiceJournal` exits before calling `finishVoiceJournalRecording`, leaving SpeechService running, mic indicator lit, and safety evaluation skipped.
- **Where/Scope:** AgentOrchestrator legacy API.
- **Evidence:**
  - Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:172-185 — Stream consumption loop lacks `do/catch` or `defer`; any thrown error aborts before teardown.
  - Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift:100-118 — Shows correct pattern (wrap `for try await` in `do/catch`, stop session before rethrow) that the orchestrator fails to mirror.
- **Upstream/Downstream:** Recording session continues consuming microphone input with no owner; `finishVoiceJournalRecording` never persists the transcript or runs SafetyAgent, violating the two-wall guardrail and confusing users (no result returned, mic stuck).
- **Why This Is a Problem:** Architecture requires begin→stream→finish flow with guaranteed cleanup; legacy API still used by tests and automation, so the leak hits real users whenever a streaming error occurs.
- **Suggested Diagnostics (no code):** Simulate `speechStream` error (disable speech in Settings mid-record) while using legacy API; observe via Xcode debugger that `activeSession` remains non-nil and mic indicator stays on.
- **Related Contract (from architecture.md):** Voice journaling API change (CLAUDE.md) mandates safe streaming consumption; guardrail section states safety run must execute even on errors.
- **Fix (2025-11-11):** `AgentOrchestrator.recordVoiceJournal` wraps streaming in `do/catch`, salvages partial transcripts via `finishVoiceJournalRecording`, and always resets the session flag (Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:172-205). `PulseViewModel` surfaces the error while still showing the saved transcript, satisfying BUG-0034’s acceptance criteria.

## Pack Agents & Retrieval

### BUG: Retrieved candidate moments never reach GPT request payload
- **ID:** BUG-20251026-0004
- **Severity:** S1
- **Area:** Wiring
- **Confidence:** High
- **Status:** Fixed (Gate 4 — RAG payload)
- **Symptom/Impact:** Guardrail context is dropped—cloud requests omit candidate micro-moments, so GPT responses are ungrounded and violate retrieval-augmented generation contract.
- **Where/Scope:** LLMGateway request construction.
- **Evidence:**
  - Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:429-454  [sig8:278a0e01] — `generateResponse` accepts `candidateMoments` parameter, forwards to `makeChatRequestBody`
  - Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:610-655  [sig8:69b302b0] — `makeChatRequestBody` ignores `candidateMoments`; payload only includes tone/z-score strings in system prompt
- **Upstream/Downstream:** Coach guardrail loses retrieval context, lowering coverage scores and violating safety wall #3 (grounding check); GPT generates generic advice instead of data-driven recommendations.
- **Why This Is a Problem:** Retrieval-augmented generation is central to coaching quality; architecture section 7 describes three-wall guardrail culminating in grounded GPT requests; dropping evidence undermines the entire guardrail stack.
- **Suggested Diagnostics (no code):** Log outgoing JSON payloads in debug mode; assert candidate titles appear in messages array; compare GPT output specificity pre/post fix; measure coverage score changes.
- **Related Contract (from architecture.md):** Section 7 ("AgentOrchestrator") describes guardrail flow including retrieval context; section 2 executive summary emphasizes grounded generation.
- **Fix (2025-11-16 / Gate 4):** `LLMGateway` now builds a `MinimizedCloudRequest` JSON body that includes `candidateMoments[]` (id, title, short, detail, evidenceBadge) plus redacted tone, rationale, and z-score summaries, and rejects unexpected fields before hitting the Responses API (Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:8-247, 363-444, 813-878). `CoachAgent` populates the candidate structs and `CoachLLMContext.topMomentId` so the payload stays grounded (Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift:93-205). Schema tests `LLMGatewaySchemaTests` now assert candidate data is present and PHI terms like `"transcript"`/`"heartrate"` never surface, and new `Gate4_LLMGatewayPingSeams` covers the UITest stub.

### BUG: Data-dominant routing reads non-existent feature keys, defaulting to energy
- **ID:** BUG-20251026-0008
- **Severity:** S1
- **Area:** Data
- **Confidence:** High
- **Status:** Fixed (Gate 4 — routing)
- **Symptom/Impact:** When topic inference fails, fallback routing always reports `subj_energy` as dominant signal because lookup probes keys that FeatureVectorSnapshot never stores.
- **Where/Scope:** AgentOrchestrator fallback logic; DataAgent feature bundle schema.
- **Evidence:**
  - Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:430-476  [sig8:a979a3b2] — Fallback probes keys: `hrv_rmssd_rolling_30d`, `sentiment_rolling_7d`, `steps_rolling_7d`, etc.
  - Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:960-974  [sig8:56e6cd6d] — `buildFeatureBundle` exposes only `z_*` and `subj_*` keys; no rolling window metrics
- **Upstream/Downstream:** Coach explanations and retrieval queries misreport dominant signals, misleading users and analytics dashboards; recommendations become generic instead of targeted.
- **Why This Is a Problem:** Architecture depends on accurate signal routing for personalized coaching; mismatched keys collapse fallback logic to a single default, losing personalization.
- **Suggested Diagnostics (no code):** Log fallback key lookups with available snapshot keys; add assertion when keys are missing; instrument topic inference failure rates; compare requested keys vs. exposed keys.
- **Related Contract (from architecture.md):** Section 7 describes retrieval wiring requiring consistent feature naming between DataAgent and Orchestrator; feature vector construction (section 8) should expose metrics used by routing.
- **Fix (2025-11-16 / Gate 4):** Added `TopicSignalResolver` so intent mapping and data-dominant fallback look only at real snapshot keys (`z_*`, `subj_*`, `sentiment`) with deterministic ties, and the fallback now chooses the max |z| even when no topic is inferred (Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:407-520). New `Gate4_RoutingTests` verify the resolver logic, and `Gate4_ConsentRoutingTests` exercise real orchestrator routing with stubs so consent OFF stays on-device while consent ON routes to cloud.

### BUG: Pulse check-ins never trigger recommendation refresh
- **ID:** BUG-20251026-0015
- **Severity:** S1
- **Area:** Wiring
- **Confidence:** High
- **Status:** Fixed (Gate 5)
- **Symptom/Impact:** After submitting sliders or journals, wellbeing score and coach recommendation cards stay stale until user manually restarts the orchestrator or reopens the app.
- **Where/Scope:** PulseViewModel; AppViewModel; CoachViewModel.
- **Evidence:**
  - Packages/PulsumUI/Sources/PulsumUI/PulseViewModel.swift:160-179  [sig8:b71568f8] — `submitInputs` saves data to orchestrator but never calls refresh:
    ```swift
    func submitInputs(for date: Date = Date()) {
        // ... saves to orchestrator ...
        self.sliderSubmissionMessage = "Thanks for checking in."
        // ❌ No CoachViewModel.refreshRecommendations() call
    }
    ```
  - Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:63-107  [sig8:092ba311] — Pulse bindings only surface safety decisions; no hook to re-fetch wellbeing/contributions after check-ins
- **Upstream/Downstream:** ScoreBreakdownView, insights tab, and coach cards present stale data despite new user inputs; user must navigate away and back to see changes.
- **Why This Is a Problem:** Architecture section 7 promises immediate feedback loops; section 10 describes reactive UI updates; without refresh wiring the wellbeing surface violates user expectations.
- **Suggested Diagnostics (no code):** Log `CoachViewModel.refreshRecommendations()` invocations; compare wellbeing snapshots before/after check-ins; capture UI state timelines; add temporary success callback from PulseViewModel to CoachViewModel.
- **Related Contract (from architecture.md):** DataAgent and UI descriptions (sections 7, 10) emphasize real-time feedback after subjective inputs; SliderSubmission should trigger full data pipeline refresh.

## Pack Data & Indexing

### BUG: Duplicate podcast recommendation JSON assets drift independently
- **ID:** BUG-20251026-0013
- **Severity:** S2
- **Area:** Data
- **Confidence:** High
- **Status:** Fixed (Gate 5)
- **Symptom/Impact:** The same dataset ships three times (`json database/podcastrecommendations.json`, `podcastrecommendations.json`, `podcastrecommendations 2.json`), risking divergence and bloating bundle size by 150KB.
- **Where/Scope:** Repository root; app resources.
- **Evidence:**
  - sha256.txt analysis confirms all three files share identical SHA-256 hash `50464a3a1673f4845622281d00ecf5099e62bd72d99099fe1ea7d218b0a1f35c`
  - Pulsum.xcodeproj/project.pbxproj:286  [sig8:9a3b8c2d] — Only `podcastrecommendations 2.json` is in Resources build phase
- **Upstream/Downstream:** LibraryImporter can ingest different copies over time; future updates may mutate one file and miss others; developers won't know canonical source.
- **Why This Is a Problem:** Duplication invites hard-to-detect drift; wastes space on device downloads; violates single-source-of-truth principle.
- **Fix (Gate 5):** Deleted the stray `podcastrecommendations.json` copies and kept the canonical `podcastrecommendations 2.json` referenced by the Xcode project; updated docs to point at the single source. (podcastrecommendations.json; json database/podcastrecommendations.json; architecture.md)
- **Tests:** `scripts/ci/test-harness.sh` now aborts if any duplicate `podcastrecommendations*.json` hashes appear; `scripts/ci/integrity.sh` re-checks for the guard.
- **Suggested Diagnostics (no code):** Audit `Bundle.main` contents at runtime; decide canonical path; consolidate import references; remove duplicates from repo; verify LibraryImporter points to single file.
- **Related Contract (from architecture.md):** Repository map (section 10) calls out deduplication of recommendation corpus as necessary hygiene; section 17 lists this as risk #4.

### BUG: FileHandle close errors silently swallowed in vector index operations
- **ID:** BUG-20251026-0017
- **Severity:** S1
- **Area:** Data
- **Confidence:** High
- **Status:** Fixed (Gate 5)
- **Symptom/Impact:** Vector index upsert/remove operations suppress FileHandle.close() errors with `try?`, leaking file descriptors and potentially causing "Too many open files" crashes.
- **Where/Scope:** VectorIndexShard.
- **Evidence:**
  - Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:104  [sig8:7c8e9d2f] — `defer { try? handle.close() }` in `upsert()`
  - Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:128  [sig8:8a9b1c3e] — `defer { try? handle.close() }` in `remove()`
- **Upstream/Downstream:** Accumulating file descriptor leaks → iOS "Too many open files" error after ~200 operations; database corruption if writes don't flush properly; especially dangerous on iOS when device locks/unlocks (FileProtectionType.complete files may be unavailable).
- **Fix (Gate 5):** Added `VectorIndexFileHandleFactory` and a `withHandle` helper so shard operations always close handles exactly once and convert close failures into surfaced `VectorIndexError.ioFailure` errors. (Packages/PulsumData/Sources/PulsumData/VectorIndex.swift)
- **Tests:** `Gate5_VectorIndexFileHandleTests` inject a handle whose `close()` throws and assert the error bubbles out without leaking the descriptor.
- **Suggested Diagnostics (no code):** Monitor file descriptor count during vector operations; test with device lock/unlock cycles; instrument close failures; check for descriptor leaks with `lsof -p <pid>`.
- **Related Contract (from architecture.md):** Section 12 describes file protection and secure storage; silently ignoring I/O errors violates data integrity guarantees.

### BUG: Core Data blocking I/O on database thread
- **ID:** BUG-20251026-0022
- **Severity:** S2
- **Area:** Data
- **Confidence:** High
- **Status:** Fixed (Gate 5)
- **Symptom/Impact:** LibraryImporter reads potentially large JSON files inside `context.perform` closure, blocking the Core Data queue and freezing UI operations.
- **Where/Scope:** LibraryImporter.
- **Evidence:**
  - Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift:58-68  [sig8:4d5e6f7a] — File I/O inside perform block:
    ```swift
    try await context.perform {
        for url in urlsCopy {
            let data = try Data(contentsOf: url)  // ⚠️ Blocking file read
            try self.processFile(data: data, ...)
        }
    }
    ```
- **Upstream/Downstream:** UI freezes during library import if using view context; database operations blocked while reading ~50KB JSON files; poor performance on large recommendation libraries.
- **Fix (Gate 5):** `LibraryImporter` now loads & decodes JSON files before entering `context.perform` and only passes DTO payloads to Core Data, moving vector index updates outside the Core Data queue. (Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift)
- **Fix (Gate 5, 2025-11-19):** `LibraryImporter` persists `LibraryIngest.checksum` only after all vector index upserts succeed, wrapping transient index failures in `LibraryImporterError.indexingFailed` so retries re-run indexing without duplicating Core Data entities. (Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift)
- **Tests:** `Gate5_LibraryImporterPerfTests` import the sample corpus while timing a concurrent Core Data fetch, and `Gate5_LibraryImporterAtomicityTests` cover checksum persistence, retry idempotency, and checksum short-circuit behavior.
- **Suggested Diagnostics (no code):** Profile library import with Instruments Time Profiler; measure UI frame drops during import; test with larger JSON files; monitor Core Data queue wait times.
- **Related Contract (from architecture.md):** Section 7 describes LibraryImporter as non-blocking background operation; section 13 emphasizes async/await and non-blocking patterns.

## Pack Infrastructure & Concurrency

### BUG: Vector index shard cache uses unsynchronized double-checked locking
- **ID:** BUG-20251026-0012
- **Severity:** S0
- **Area:** Concurrency
- **Confidence:** High
- **Status:** Fixed (Gate 5)
- **Symptom/Impact:** Concurrent searches can race shard initialization; unsynchronized reads outside barrier queue risk partially initialized shards, crashes, or data corruption.
- **Where/Scope:** VectorIndex shard retrieval.
- **Evidence:**
  - Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:313  [sig8:80cf5e3a] — First check outside lock: `if let shard = shards[index] { return shard }`
  - Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:317  [sig8:9b8d7e6f] — Second check inside barrier: `if let shard = shards[index] { ... }`
  - Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:326  [sig8:1a2b3c4d] — Write inside barrier: `shards[index] = shard`
- **Upstream/Downstream:** Recommendation searches may return duplicate or corrupted shards under concurrent load; crashes from Swift dictionary data races; similarity scores become unreliable.
- **Fix (Gate 5):** Converted `VectorIndex` into an actor, removed the double-checked read, funneled shard creation through the actor with thread-safe file-handle helpers, and promoted `VectorIndexProviding`/`VectorIndexManager` to actors so CoachAgent can hold the reference without `Sendable` warnings. (Packages/PulsumData/Sources/PulsumData/VectorIndex.swift; Packages/PulsumData/Sources/PulsumData/VectorIndexManager.swift)
- **Tests:** `Gate5_VectorIndexConcurrencyTests` hammer the actor with concurrent upserts/searches/removals and assert deterministic search results without TSan warnings.
- **Suggested Diagnostics (no code):** Stress test with concurrent vector searches under Thread Sanitizer; inspect shard instance counts; simulate race conditions; test on multi-core device under load.
- **Related Contract (from architecture.md):** Section 13 states vector index is safe under concurrent load; section 7 describes concurrent searches as core feature; current implementation violates thread-safety contract.

### BUG: Stale project.pbxproj backup reintroduces removed dependencies
- **ID:** BUG-20251026-0036
- **Severity:** S3
- **Area:** Build/Project
- **Confidence:** High
- **Status:** Fixed (Gate 5)
- **Symptom/Impact:** `Pulsum.xcodeproj/project.pbxproj.backup` remains checked in with now-deleted SplineRuntime linkage and a removed dSYM shell script. Opening the backup in Xcode or resolving merge conflicts against it can accidentally re-add the dependency and script that were intentionally removed.
- **Where/Scope:** `Pulsum.xcodeproj/project.pbxproj.backup`.
- **Evidence:**
  - Pulsum.xcodeproj/project.pbxproj.backup:10-52 — Frameworks phase still lists `SplineRuntime` even though the active project removed it.
  - Pulsum.xcodeproj/project.pbxproj.backup:300-335 — Contains the deleted shell script that regenerates SplineRuntime dSYM files each build.
- **Upstream/Downstream:** Teammates can open/edit the wrong project file (Xcode prompts to pick one), reintroducing SplineRuntime wiring and scripts that were purposefully deleted, causing inconsistent builds and potential App Store rejections for unused dependencies.
- **Fix (Gate 5):** Enforced a repo-wide guard that fails CI if any `*.pbxproj.backup` files appear and documented the canonical project file; the stale backup was purged. (scripts/ci/integrity.sh)
- **Tests:** `scripts/ci/integrity.sh` now includes the guard so Gate runs break if a backup resurfaces.
- **Suggested Diagnostics (no code):** Remove or move the backup outside the repo; enforce lint (pre-commit) to block `.pbxproj.backup` files; verify Xcode shows only one project file after cleanup.
- **Related Contract (from architecture.md):** Milestone hygiene tasks (todolist.md) require removing dead scaffolding and duplicate docs; same rationale applies to stray project backups.

## Pack UI & Experience

### BUG: Apple Intelligence enablement link uses macOS-only URL scheme
- **ID:** BUG-20251026-0010
- **Severity:** S2
- **Area:** UI
- **Confidence:** High
- **Status:** Fixed (Gate 4 — Settings UX)
- **Symptom/Impact:** Tapping "Enable Apple Intelligence" button on iOS does nothing; `x-apple.systempreferences` scheme is macOS-only, blocking users from enabling cloud guardrail consent.
- **Where/Scope:** SettingsView.
- **Evidence:**
  - Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift:150-176  [sig8:7b6158fa] — iOS UI uses macOS System Settings URI: `URL(string: "x-apple.systempreferences:com.apple.preference.security")`
- **Upstream/Downstream:** Users remain blocked from enabling Apple Intelligence via Settings app; cannot opt into cloud processing; guardrail escalation path is broken.
- **Why This Is a Problem:** Architecture section 10 relies on users toggling Apple Intelligence for guardrail escalation; the primary CTA for enabling this feature is non-functional on iOS.
- **Suggested Diagnostics (no code):** Log `UIApplication.canOpenURL` results for the scheme; capture device UX attempting the link; test on iOS 26 device; determine correct iOS Settings URL or remove broken link.
- **Related Contract (from architecture.md):** Settings section (10) promises actionable guidance to enable Apple Intelligence on-device; SettingsViewModel should provide working deep link.
- **Fix (2025-11-16 / Gate 4):** The Settings CTA now uses `UIApplication.openSettingsURLString` when available and falls back to Apple’s Apple-Intelligence support article. When UITest flags are set (`UITEST_FORCE_SETTINGS_FALLBACK` + `UITEST_CAPTURE_URLS`), the view logs the attempted URL to a shared defaults suite so automation can assert the fallback path; `Gate4_CloudConsentUITests.test_open_ai_enablement_link_falls_back_to_support_url()` exercises this path.

### BUG: Spline hero scene missing from main view
- **ID:** BUG-20251026-0011
- **Severity:** S2
- **Area:** UI
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** The home tab renders only a gradient background with wellbeing score card; the required Liquid Glass Spline hero experience is completely absent.
- **Where/Scope:** PulsumRootView main tab.
- **Evidence:**
  - Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift:145-169  [sig8:b4400cc7] — `mainTab` only shows:
    ```swift
    ScrollView {
        LazyVStack {
            if let score = viewModel.coachViewModel.wellbeingScore {
                // Wellbeing score card
            } else {
                WellbeingScoreLoadingCard()
            }
        }
    }
    ```
    No Spline view, no hero animation, no asset loading
  - Pulsum.xcodeproj/project.pbxproj:286  [sig8:a1b2c3d4] — `streak_low_poly_copy.splineswift` is in Resources but never loaded
- **Upstream/Downstream:** Brand-defining hero experience is missing; onboarding/landing flow incomplete; reduces perceived quality; violates milestone 4 design goals.
- **Why This Is a Problem:** Architecture docs and design specs commit to Liquid Glass Spline-powered hero (mentioned in repo map); milestone 4 UI redesign specifically called for this visual.
- **Suggested Diagnostics (no code):** Verify dependencies for SplineRuntime framework; confirm asset inclusion in built IPA; inspect runtime view hierarchy; check if SplineView component exists in codebase.
- **Related Contract (from architecture.md):** Section 10 mentions branded UI; repository map lists Spline assets; milestone overview (section 1) calls for premium visual experience.

### BUG: PulseView haptic feedback fails to compile without UIKit import
- **ID:** BUG-20251026-0035
- **Severity:** S1
- **Area:** UI
- **Confidence:** High
- **Status:** Fixed (Gate 0 — Security & Build Blockers)
- **Symptom/Impact:** `UIImpactFeedbackGenerator` is referenced for the record/stop buttons, but PulseView never imports UIKit, so every build fails with “Cannot find 'UIImpactFeedbackGenerator' in scope.”
- **Where/Scope:** PulseView SwiftUI file.
- **Evidence:**
  - Packages/PulsumUI/Sources/PulsumUI/PulseView.swift:1-4 — File imports SwiftUI and Observation only.
  - Packages/PulsumUI/Sources/PulsumUI/PulseView.swift:239-290 — Buttons instantiate `UIImpactFeedbackGenerator(style: .medium/.heavy)` with no conditional `canImport(UIKit)` guard.
- **Upstream/Downstream:** Entire iOS target fails to compile, blocking CI and local builds; Pulse journaling UI cannot ship until conditional import or compiler directives are added.
- **Why This Is a Problem:** Instructions call PulseView the primary journaling surface; a missing import prevents even starting the app, undermining the build’s viability.
- **Fix (2025-11-09):** PulseView now conditionally imports UIKit and wraps the haptic helpers in `#if canImport(UIKit)` so simulator and device builds succeed. The release build gate (`xcodebuild -scheme Pulsum -sdk iphonesimulator -configuration Release build`) now completes, proving the compile blocker is resolved.

### BUG: Wellbeing UI never refreshes after background data updates
- **ID:** BUG-20251026-0037
- **Severity:** S1
- **Area:** UI
- **Confidence:** High
- **Status:** Fixed (Gate 3 — `.pulsumScoresUpdated` freshness bus now drives Coach/Main view refreshes and slider/journal completions trigger updates immediately.)
- **Symptom/Impact:** HealthKit samples and nightly recomputations land in Core Data but the wellbeing card and recommendations stay frozen until the user manually visits Insights or toggles consent, so “Calculated nightly” data never appears in the main tab.
- **Where/Scope:** AppViewModel startup, CoachViewModel refresh wiring, Insights tab task.
- **Evidence:**
  - Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:111-152 — After `orchestrator.start()` completes, the only call to `coachViewModel.refreshRecommendations()` lives inside this launch task (and in `updateConsent`), so no refresh happens when DataAgent later ingests HealthKit samples.
  - Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift:53-80 — `refreshRecommendations()` is manual; `reloadIfNeeded()` merely wraps it but has zero call sites anywhere else in the repo, so no observer bridges new data to the UI.
  - Packages/PulsumUI/Sources/PulsumUI/CoachView.swift:168-183 — `.task { await viewModel.refreshRecommendations() }` runs only when the Insights tab is visible; remaining on the main tab never triggers a refresh.
- **Upstream/Downstream:** Wellbeing score, contributions, and cards go stale after the first app launch, undermining trust in the metrics and breaking the promise of immediate feedback after HealthKit sync or slider submissions.
- **Why This Is a Problem:** Architecture.md §2 states DataAgent feeds dashboards in near-real time; without UI refresh wiring the entire wellbeing surface violates that contract.
- **Suggested Diagnostics (no code):** Simulate a new HealthKit sample (or call `DataAgent.reprocessDay`) and capture logs for `CoachViewModel.refreshRecommendations()`; verify it only fires when manually navigating to Insights; add instrumentation around DataAgent callbacks.
- **Related Contract (from docs):** architecture.md:8-11 (“Health metrics and journals flow through a DataAgent actor … surfaced in UI dashboards”) requires automatic propagation of new snapshots.

### BUG: ChatGPT-5 panel lacks any API key input or save action
- **ID:** BUG-20251026-0041
- **Severity:** S1
- **Area:** UI
- **Confidence:** High
- **Status:** Fixed (Gate 4 — consent UX)
- **Symptom/Impact:** Settings promises “ChatGPT-5 API” status but provides no text field, paste affordance, or button to submit a key. The status light permanently reflects the bundled (and now revoked) key, leaving testers no way to rotate credentials or restore cloud phrasing.
- **Where/Scope:** SettingsView; SettingsViewModel.
- **Evidence:**
  - Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift:150-213 — ChatGPT section renders only a headline, status text, and indicator dot; there is no `TextField`, `SecureField`, or button bound to `viewModel.gptAPIKeyDraft`.
  - Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift:23-50,133-150 — View model maintains `gptAPIKeyDraft`, `saveAPIKeyAndTest(_:)`, and `checkGPTAPIKey()` but nothing ever updates `gptAPIKeyDraft` from UI, so the only value tested is the baked-in Info.plist key.
  - architecture.md:85 describes Settings as “tests API keys,” implying user-supplied runtime keys; with no input, this requirement cannot be met.
- **Upstream/Downstream:** Without an input, developers can’t replace the leaked key (BUG-20251026-0001), QA can’t disable cloud phrasing safely, and the consent banner misleads users into thinking GPT usage is configurable when it isn’t.
- **Why This Is a Problem:** Runtime key rotation is a documented requirement (architecture.md §4); App Store review will expect user-facing secrets not to be hardcoded. Lack of UI blocks remediation of the critical credential leak.
- **Suggested Diagnostics (no code):** Try to paste an API key anywhere in Settings—there is no focusable field. Inspect SwiftUI view hierarchy via View Debugger to confirm the absence of input controls.
- **Related Contract (from docs):** architecture.md:40 & 85 — GPT-5 access “requires a key supplied at runtime” and Settings “tests API keys.”
- **Fix (2025-11-16 / Gate 4):** `SettingsView` now includes a secure field bound to `gptAPIKeyDraft`, explicit “Save Key” and “Test Connection” buttons, and a status pill that reflects the latest ping result. `SettingsViewModel` exposes an async `saveAPIKey(_:)` and `testCurrentAPIKey()` that call through to orchestrator APIs and toggle a new loading state, so testers can rotate keys without redeploying. UI tests `Gate4_CloudConsentUITests` automate the save/test flow and assert the status pill flips to “OpenAI reachable.”

### BUG: Chat keyboard remains on-screen when switching tabs
- **ID:** BUG-20251026-0042
- **Severity:** S2
- **Area:** UI
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** Focusing the Coach chat input and then tapping Main or Insights leaves the software keyboard floating over the new tab, obscuring content even though there’s no text field to edit. Users must swipe the keyboard down manually each time.
- **Where/Scope:** ChatInputView; Tab navigation.
- **Evidence:**
  - Packages/PulsumUI/Sources/PulsumUI/CoachView.swift:5-70 — `ChatInputView` tracks focus with `@FocusState private var chatFieldInFocus` and only sets it to `true` when `viewModel.chatFocusToken` changes; there is no `onDisappear`, `onChange` of tab selection, or other path that clears focus when the view is off-screen.
  - Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift:132-247 — `TabView` switches between Main/Insights/Coach but never tells the chat view to resign first responder or blur the text field, so the system keyboard stays active after changing tabs.
- **Upstream/Downstream:** Keyboard covers the wellbeing card and insights lists whenever users leave the Coach tab mid-composition; accessibility and UX suffer because the UI appears broken until the keyboard is manually dismissed.
- **Why This Is a Problem:** instructions.md (“UI & Navigation (fixed)”) require smooth navigation between tabs; leaving the keyboard open violates basic iOS tab UX conventions and can obscure safety banners/scorecards.
- **Suggested Diagnostics (no code):** In the simulator or device, focus the chat field, then tap the Main tab; observe the keyboard remains over the main screen. Set breakpoints in `ChatInputView` to confirm no focus reset occurs on disappearance.
- **Related Contract (from docs):** instructions.md §UI & Navigation mandates polished tab transitions without lingering overlays.

### BUG: HealthKit status indicator ignores five of six required permissions
- **ID:** BUG-20251026-0043
- **Severity:** S2
- **Area:** UI
- **Confidence:** High
- **Status:** Fixed (Gate 3 — Settings + Onboarding now display per-type statuses, partial counts, and success toasts via the shared `HealthAccessStatus` model.)
- **Symptom/Impact:** Settings shows “Health Data Access – Authorized” as soon as HRV is granted, even if sleep, respiratory rate, resting heart rate, heart rate, or steps are still denied. Users think Pulsum is ingesting their data, but DataAgent never receives those metrics, so wellbeing math silently runs on partial inputs.
- **Where/Scope:** SettingsViewModel.refreshHealthKitStatus; HealthKit requirements per docs.
- **Evidence:**
  - Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift:61-80 — `refreshHealthKitStatus()` checks only `HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)` and sets the status string based solely on HRV authorization.
  - instructions.md:11-15 — Lists six mandatory HealthKit data types (HRV, heart rate, resting HR, respiratory rate, steps, sleep) for calculations and personalization.
- **Upstream/Downstream:** Users can deny sleep or respiratory rate, see “Authorized,” and never realize that wellbeing score and sleep debt calculations are operating on imputed data. This undermines trust and complicates debugging because UI and backend disagree on access.
- **Why This Is a Problem:** Architecture assumes all required metrics are collected; misleading status prevents users from fixing missing permissions and leaves calculations misaligned with expected HealthKit inputs.
- **Suggested Diagnostics (no code):** Deny sleep in Health app but leave HRV enabled; open Pulsum Settings to confirm it still shows “Authorized.” Log which identifiers `HKHealthStore.authorizationStatus` returns for each required sample type.
- **Related Contract (from docs):** instructions.md “HealthKit Integration” requires Pulsum to request and surface status for all listed data types, not just HRV.

## Pack Health & Permissions

### BUG: HealthKit request buttons never restart ingestion pipeline
- **ID:** BUG-20251026-0040
- **Severity:** S1
- **Area:** Wiring
- **Confidence:** High
- **Status:** Fixed (Gate 3 — Settings/Onboarding now call `AgentOrchestrator.requestHealthAccess()` which restarts DataAgent idempotently.)
- **Symptom/Impact:** Tapping “Request Health Data Access” (in Settings or onboarding) reopens the iOS permission sheet but never restarts `DataAgent`/`HealthKitService`. Newly granted permissions therefore do nothing until the user force-quits or hits Retry on the startup overlay, so wellbeing metrics stay empty despite a successful prompt.
- **Where/Scope:** SettingsViewModel; OnboardingView; App bootstrap.
- **Evidence:**
  - Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift:55-120 — Button handler instantiates a fresh `HKHealthStore`, requests authorization, and only updates local status strings; it never calls back into `AgentOrchestrator` or `HealthKitService`.
  - Packages/PulsumUI/Sources/PulsumUI/OnboardingView.swift:220-280 — Onboarding flow repeats the same pattern with another standalone `HKHealthStore`, again omitting any restart of observers.
  - Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:89-144 — `orchestrator.start()` (which invokes `DataAgent.start()` to register observers/background delivery) runs exactly once at launch or when `retryStartup()` fires; the Settings button never re-invokes it.
  - Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:68-86 — HealthKit observers/background delivery are only configured inside `DataAgent.start()`, so without re-running it after consent, no samples arrive.
- **Upstream/Downstream:** Users who initially deny HealthKit can’t recover inside the app—after granting via the button, no data flows until they restart. ScoreBreakdown, wellbeing score, and recommendations remain blank, violating the “Request Health Data Access” promise.
- **Why This Is a Problem:** instructions.md:24-33 and 141-148 mandate reliable HealthKit ingestion with HKObserver/HKAnchored queries; UI affordances must actually wire to the ingestion pipeline.
- **Suggested Diagnostics (no code):** Deny HealthKit on first launch, then grant via Settings ▸ Request Health Data Access; observe that `DataAgent.start()`/`HealthKitService.enableBackgroundDelivery()` logs do not reappear and no samples arrive until the app is relaunched or `retryStartup()` is triggered.
- **Related Contract (from docs):** instructions.md (“HealthKit Integration”) requires the app to request authorization and keep ingestion wired; current implementation breaks that contract.

### BUG: HealthKit 30-day backfill stalls on large datasets
- **ID:** BUG-20251026-0045
- **Severity:** S1
- **Area:** Data
- **Confidence:** Medium
- **Status:** Fixed (Gate 6 — phased warm-start + persisted background batches to 30 days)
- **Symptom/Impact:** With a 30-day backfill window, heart rate/respiratory/steps histories containing tens of thousands of samples can make DataAgent’s initial processing appear stuck, leaving coverage at 0/0 despite granted permissions.
- **Where/Scope:** `DataAgent.backfillHistoricalSamplesIfNeeded` uses `analysisWindowDays = 30` to fetch and process all granted types in one pass.
- **Evidence:** Device debug logs show large fetch counts (e.g., 47,789 heart rate samples, 1,517 respiratory) but no processed/touchedDays entries for those types; sleep/HRV complete successfully.
- **Why This Is a Problem:** Users see HealthKit “granted” but still get “no data”/0 coverage; long-running ingestion blocks wellbeing correctness and trust.
- **Fix (Gate 6):** Added a two-phase backfill: 7-day warm-start in the foreground for a fast first score, followed by persisted background batches (5-day slices) that expand coverage to the full 30-day analysis window without blocking the UI. Progress is checkpointed per-type on disk with full file protection/backup exclusion so relaunches resume instead of re-ingesting history. Baseline/analysis windows restored to 30 days; coverage lines grow as batches land.
- **Suggested Diagnostics (no code):** Inspect App Debug Log for per-type “Backfill fetched … raw=…”, “casting summary …”, and “Backfill processed … touchedDays=…”; if heart rate/steps lack processed lines after several seconds, ingestion is still stalled. Once batching lands, raise window and retest.
- **Related Contract (from docs):** instructions.md/architecture.md assume full 30-day coverage for robust baselines; this hotfix narrows scope and must be reversed with proper batching.

## Pack Tests & Tooling

### BUG: Xcode scheme omits all SwiftPM test targets
- **ID:** BUG-20251026-0014
- **Severity:** S1
- **Area:** Test
- **Confidence:** High
- **Status:** Fixed (Gate 1 — Test harness ON)
- **Symptom/Impact:** Running Product ▸ Test executes only empty XCTest bundles (PulsumTests, PulsumUITests); package tests for Agents, Services, Data, ML never run in Xcode.
- **Where/Scope:** Pulsum shared scheme configuration.
- **Evidence:**
  - Pulsum.xcodeproj/xcshareddata/xcschemes/Pulsum.xcscheme:32-54  [sig8:7de9cc6c] — Only two testables listed: `PulsumTests.xctest` and `PulsumUITests.xctest`
  - No references to `PulsumAgentsTests`, `PulsumServicesTests`, `PulsumDataTests`, `PulsumMLTests`
- **Upstream/Downstream:** CI misses regressions in guardrails, services, and data layers; safety-critical tests never run; developers see "all tests pass" but package tests are silently skipped.
- **Why This Is a Problem:** Architecture section 14 counts on package tests for guardrails and services as essential coverage; current scheme silently skips 95% of the test suite.
- **Fix (2025-11-09, commit gate1-test-harness-final):** The shared `Pulsum` scheme now test-runs PulsumAgents/Services/Data/ML bundles with deterministic UITest env vars, and `scripts/ci/test-harness.sh` enforces `xcodebuild test` plus filtered `swift test` subsets on macOS CI.
- **Related Contract (from architecture.md):** Testing strategy (section 14) notes service and guardrail tests as essential coverage; mentions property tests and acceptance tests that aren't running.

### BUG: Test targets contain only empty scaffolds with no assertions
- **ID:** BUG-20251026-0025
- **Severity:** S1
- **Area:** Test
- **Confidence:** High
- **Status:** Fixed (Gate 1 — Test harness ON)
- **Symptom/Impact:** PulsumTests and PulsumUITests bundles contain only boilerplate template code with no actual test assertions, providing zero coverage.
- **Where/Scope:** PulsumTests and PulsumUITests targets.
- **Evidence:**
  - PulsumTests/PulsumTests.swift:11-17  [sig8:8c9d0e1f] — Single test method with only comment: `// Write your test here and use APIs like #expect(...)`
  - PulsumUITests/PulsumUITests.swift:25-32  [sig8:9d0e1f2a] — `testExample()` launches app but has no assertions
  - PulsumUITests/PulsumUITests.swift:34-40  [sig8:0e1f2a3b] — `testLaunchPerformance()` only measures launch time
- **Upstream/Downstream:** CI reports 100% test pass rate but tests verify nothing; regressions in app logic go undetected; false confidence from green CI.
- **Why This Is a Problem:** Tests exist but provide no coverage; architecture section 17 lists incomplete UI tests as risk #3; no validation of voice journaling, chat flows, settings.
- **Fix (2025-11-09, commit gate1-test-harness-final):** New smoke suites (`FirstRunPermissionsUITests`, `JournalFlowUITests`, `SettingsAndCoachUITests`) drive the consent banner, journaling stream, and stubbed coach chat using the new UITest seams; placeholder files were removed.
- **Related Contract (from architecture.md):** Section 14 describes testing strategy including UI tests; section 17 acknowledges UI tests are placeholders but this wasn't addressed.

### BUG: LLM PING validation has case mismatch causing all pings to fail
- **ID:** BUG-20251026-0023
- **Severity:** S2
- **Area:** Wiring
- **Confidence:** High
- **Status:** Fixed (Gate 4 — Settings ping)
- **Symptom/Impact:** API key test requests always fail validation due to case mismatch between request body ("PING") and validator ("ping"), breaking Settings connectivity test.
- **Where/Scope:** LLMGateway ping implementation.
- **Evidence:**
  - Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:659  [sig8:3c4d5e6f] — Request sends uppercase:
    ```swift
    "input": [["role": "user", "content": "PING"]]
    ```
  - Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:400  [sig8:4d5e6f7a] — Validator expects lowercase:
    ```swift
    (input.first?["content"] as? String) == "ping" else { return false }
    ```
- **Upstream/Downstream:** SettingsView "Test API Key" button always reports failure even with valid key; users cannot verify connectivity; diagnostic tool is broken.
- **Why This Is a Problem:** Validation logic contradicts request construction; simple typo breaks feature; users cannot distinguish between bad key and bug.
- **Suggested Diagnostics (no code):** Test with valid API key; log validation failures; confirm case mismatch; fix either request or validator to match.
- **Related Contract (from architecture.md):** Section 9 describes LLM gateway with validation; Settings (section 10) promises API key testing.
- **Fix (2025-11-16 / Gate 4):** `LLMGateway.makePingRequestBody` and `validatePingPayload` now share the same guard (case-insensitive) and the validator is exposed for tests so `"PING"` and `"ping"` both pass. `LLMGateway.testAPIConnection()` rejects unexpected fields before firing the request and short-circuits when the UITest stub flag is set. `Gate4_LLMKeyTests` prove the validator accepts mixed-case payloads and that key storage round-trips through the Keychain stub, while `Gate4_LLMGatewayPingSeams` covers the UITest environment flag.

### BUG: HealthKit queries lack authorization status checks before execution
- **ID:** BUG-20251026-0024
- **Severity:** S1
- **Area:** Wiring
- **Confidence:** High
- **Status:** Fixed (Gate 3 — DataAgent now computes `HealthAccessStatus` and skips denied/notDetermined types before building observers.)
- **Symptom/Impact:** Observer queries execute without checking authorization status, causing silent failures if user revokes HealthKit permission after initial grant.
- **Where/Scope:** HealthKitService query execution.
- **Evidence:**
  - Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift:103-134  [sig8:5e6f7a8b] — `observeSampleType` creates and executes queries without authorization check:
    ```swift
    public func observeSampleType(...) throws -> HKObserverQuery {
        let observer = HKObserverQuery(...) { ... }
        healthStore.execute(observer)  // ⚠️ No auth check
    }
    ```
- **Upstream/Downstream:** Background delivery and data updates silently fail if permission revoked; DataAgent never receives samples; wellbeing score becomes stale; no user feedback.
- **Why This Is a Problem:** iOS allows users to revoke HealthKit permission at any time; app must check status before each query; silent failures violate user trust and data currency expectations.
- **Suggested Diagnostics (no code):** Test with permission revocation; check `healthStore.authorizationStatus(for:)` before queries; add error surfacing for denied status; verify observer query failures.
- **Related Contract (from architecture.md):** Section 7 describes HealthKit service with "authorization checks" and "edge case handling"; current implementation skips validation.

## Pack ML & Embeddings

### BUG: AFM contextual embeddings permanently disabled with TODO
- **ID:** BUG-20251026-0020
- **Severity:** S1
- **Area:** Dependency
- **Confidence:** High
- **Status:** Fixed (Gate 6 — contextual AFM path restored with explicit fallbacks)
- **Symptom/Impact:** The AFM (Alternative Foundation Models) embedding provider's primary feature (contextual embeddings) is disabled, falling back to legacy word embeddings despite iOS 17+ availability.
- **Where/Scope:** AFMTextEmbeddingProvider.
- **Evidence:**
  - Packages/PulsumML/Sources/PulsumML/Embedding/AFMTextEmbeddingProvider.swift:28-39  [sig8:6c7d8e9f] — Entire contextual embedding branch disabled:
    ```swift
    // Temporarily disabled contextual embedding due to unsafe runtime code
    // TODO: Re-enable when safe API is available
    guard let wordEmbedding = NLEmbedding.wordEmbedding(for: .english) else {
        throw EmbeddingError.modelUnavailable
    }
    ```
- **Upstream/Downstream:** All embeddings use inferior word-level vectors instead of contextual; similarity search quality degrades; topic gating and safety classification less accurate.
- **Why This Is a Problem:** Architecture section 7 describes multi-tier ML fallback with AFM as secondary tier; disabling primary feature defeats the purpose; "alternative" provider offers no advantage over Core ML fallback.
- **Suggested Diagnostics (no code):** Research NLContextualEmbedding availability; determine if "unsafe runtime code" issue is resolved; benchmark word vs. contextual embedding quality; consider removing TODO or implementing fix.
- **Tests:** `Gate6_EmbeddingProviderContextualTests` (PulsumML)
- **Related Contract (from architecture.md):** Section 7 ("ML utilities") describes EmbeddingService with AFM tier for modern embeddings; current implementation provides legacy-tier quality.

### BUG: Foundation Models stub has wrong response type structure
- **ID:** BUG-20251026-0019
- **Severity:** S0
- **Area:** Dependency
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** The stub's response type is `Any` with string content, but actual usage expects structured types with typed properties, causing runtime crashes when Foundation Models is unavailable but iOS 26 APIs are present.
- **Where/Scope:** FoundationModelsStub response types.
- **Evidence:**
  - Packages/PulsumML/Sources/PulsumML/AFM/FoundationModelsStub.swift:33-38  [sig8:7d8e9f0a] — Stub returns generic `Any`:
    ```swift
    public func respond(..., generating type: Any.Type, ...) async throws -> Any {
        throw FoundationModelsStubError.unavailable
    }
    ```
  - Packages/PulsumML/Sources/PulsumML/Sentiment/FoundationModelsSentimentProvider.swift:28-32  [sig8:8e9f0a1b] — Actual usage expects structured type:
    ```swift
    let result = try await session.respond(..., generating: SentimentAnalysis.self, ...)
    return max(min(result.content.score, 1.0), -1.0)  // ⚠️ Expects .content.score
    ```
  - Packages/PulsumML/Sources/PulsumML/AFM/FoundationModelsStub.swift:59-61  [sig8:9f0a1b2c] — Stub's `ResponseStub.content` is `String`, not structured type
- **Upstream/Downstream:** When Foundation Models throws `.unavailable`, providers should fall back, but type mismatch causes force-cast failures; sentiment analysis and safety classification crash instead of falling back.
- **Why This Is a Problem:** Stub doesn't accurately simulate real API; type system mismatch causes runtime crashes in production when Foundation Models is downloading or disabled; violates fallback architecture.
- **Suggested Diagnostics (no code):** Test on iOS 26 device with Apple Intelligence disabled; simulate Foundation Models unavailability; verify fallback behavior; instrument sentiment provider error paths.
- **Related Contract (from architecture.md):** Section 7 describes Foundation Models as primary ML tier with graceful fallback; stub should simulate real API accurately enough for fallback testing.
- **Fix (2025-10-23):** Replaced the stubbed `LanguageModelSession` APIs with generic `LanguageModelResult<Content>` responses that mirror the real API surface and added `Gate0_EmbeddingServiceFallbackTests` to prove AFM failures fall back cleanly instead of crashing.

### BUG: Embedding zero-vector fallback masks all provider failures
- **ID:** BUG-20251026-0021
- **Severity:** S1
- **Area:** ML
- **Confidence:** High
- **Status:** Fixed (Gate 6 — zero vectors now throw and propagate; follow-up adds availability self-healing probe)
- **Symptom/Impact:** When all embedding providers fail, EmbeddingService silently returns zero vector `[0,0,...,0]`, corrupting similarity search and masking critical failures.
- **Where/Scope:** EmbeddingService fallback logic.
- **Evidence:**
  - Packages/PulsumML/Sources/PulsumML/Embedding/EmbeddingService.swift:31-43  [sig8:0a1b2c3d] — Silent zero-vector fallback:
    ```swift
    public func embedding(for text: String) -> [Float] {
        if let primaryProvider, let primary = try? primaryProvider.embedding(for: text) {
            return ensureDimension(primary)
        }
        if let fallbackProvider, let fallback = try? fallbackProvider.embedding(for: text) {
            return ensureDimension(fallback)
        }
        return Array(repeating: 0, count: dimension)  // ⚠️ No error, no log
    }
    ```
- **Upstream/Downstream:** Zero vectors match with zero similarity to everything; vector search returns random results; SafetyLocal prototypes become invalid; topic gating breaks; users get irrelevant recommendations.
- **Why This Is a Problem:** Downstream code cannot distinguish between "legitimately computed zero embedding" vs. "all providers failed"; similarity search corruption is silent; debugging provider issues is impossible.
- **Suggested Diagnostics (no code):** Add logging for zero-vector fallback; consider throwing error or returning optional; instrument provider failure rates; test with all providers disabled.
- **Tests:** `Gate6_EmbeddingProviderContextualTests`, `PackageEmbedTests` (stubbed embeddings)
- **Related Contract (from architecture.md):** Section 7 describes embedding service with fallback providers; zero-vector return violates contract that embeddings are always meaningful vectors.

### BUG: RecRanker never learns from recommendation events
- **ID:** BUG-20251026-0027
- **Severity:** S1
- **Area:** ML
- **Confidence:** High
- **Status:** Fixed (Gate 6 — RecRanker updates from user feedback)
- **Symptom/Impact:** Recommendation weights stay frozen even after dozens of accept/reject events, so cards never personalize to the user and acceptance rates stagnate.
- **Where/Scope:** CoachAgent recommendation flow.
- **Evidence:**
  - Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift:68-74  [sig8:b6d7e83f] — Recommendations call `ranker.rank(...)` and take the top three without any learning step.
  - Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift:131-138  [sig8:c92a4f10] — Completions are logged to Core Data only; there is no call into `RecRanker.update` or `updateLearningRate`.
  - Packages/PulsumML/Sources/PulsumML/RecRanker.swift:107-135  [sig8:0de5f7ab] — Pairwise `update`, adaptive learning rate, and feedback APIs exist but are never invoked.
- **Upstream/Downstream:** UX assumes the ranker adapts as users accept/skip cards. Because weights never change, stale micro-moments keep resurfacing and any A/B improvements are impossible to measure.
- **Why This Is a Problem:** Violates the Phase 03 design (RecRanker should "learn from interaction logs") and blocks data-driven personalization; logged RecommendationEvents become dead data.
- **Suggested Diagnostics (no code):** Add temporary counters/logs for `RecRanker.update` invocations; run integration test that simulates accept/reject sequences and asserts weight changes.
- **Tests:** `Gate6_RecRankerLearningTests` (PulsumAgents)
- **Related Contract:** Phase 03 short report — Model Training & Optimization section states the ranker “updates from interaction logs”.

### BUG: Wellbeing coefficients invert recovery signals
- **ID:** BUG-20251026-0028
- **Severity:** S1
- **Area:** ML
- **Confidence:** High
- **Status:** Fixed (Gate 6 — weights/targets now align with recovery semantics)
- **Symptom/Impact:** Higher HRV or step z-scores make the Wellbeing Score fall, while elevated sleep debt makes it rise, contradicting intended recovery semantics.
- **Where/Scope:** StateEstimator initialization and target label computation.
- **Evidence:**
  - Packages/PulsumML/Sources/PulsumML/StateEstimator.swift:29-38  [sig8:6fb39d25] — Initial weights assign negative coefficients to `z_hrv` and `z_steps`, positive to `z_sleepDebt`.
  - Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:557-564  [sig8:4a10c2d7] — Target label multiplies HRV and steps by negative constants, causing gradient updates to reinforce the inverted relationship.
  - Phase 03 short report, Model Training & Optimization — specifies “low HRV and high sleep debt reduce the score and good sleep or activity lift it,” which the current math violates.
- **Upstream/Downstream:** ScoreBreakdown shows recovery metrics moving opposite to expectations; recommendations derived from the Wellbeing Score misinterpret improvements as regressions.
- **Why This Is a Problem:** Undermines user trust and breaks the narrative that better recovery signals raise wellbeing; ranker and guardrails consume the wrong signals.
- **Suggested Diagnostics (no code):** Plot score contributions after simulated days with high HRV vs. low HRV; add unit tests asserting coefficient signs; review gradient targets before deploying.
- **Tests:** `Gate6_StateEstimatorWeightsAndLabelsTests` (PulsumAgents)
- **Related Contract:** Phase 03 short report — Model Training & Optimization and Model Refinement sections require sensible seed weights and interpretable contributions.

### BUG: StateEstimator weights reset every launch, erasing personalization
- **ID:** BUG-20251026-0038
- **Severity:** S1
- **Area:** ML
- **Confidence:** High
- **Status:** Fixed (Gate 6 — estimator state now persisted securely)
- **Symptom/Impact:** The wellbeing model relearns from scratch each run because weights/contributions exist only in memory; a cold app start or crash reverts to seed coefficients, so long-term personalization never accumulates.
- **Where/Scope:** DataAgent state management.
- **Evidence:**
  - Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:46-64 — `private var stateEstimator = StateEstimator()` lives only in the actor; there is no load from disk or dependency injection of prior weights.
  - Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:93-114 — `latestFeatureVector()` recomputes wellbeing via `stateEstimator.currentSnapshot` instead of reading the persisted `imputedFlags` payload; after relaunch the estimator has never seen historical updates.
  - Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:627-658 — Contributions and wellbeing are encoded into Core Data, but `materializeFeatures` only decodes the `imputed` map; the stored `contributions`/`wellbeing` fields are never read anywhere in the repo.
- **Upstream/Downstream:** Users see their score revert to seed weights every time they reopen the app; recommendations and ScoreBreakdown shifts contradict prior sessions, defeating “learning” claims.
- **Why This Is a Problem:** instructions.md §“Tech Stack” calls out StateEstimator as an online ridge model for personalization; without persistence it can never behave as specified.
- **Suggested Diagnostics (no code):** Capture `stateEstimator.weights` before quitting, relaunch, and log the weights again; compare ScoreBreakdown before/after a relaunch without new data.
- **Tests:** `Gate6_StateEstimatorPersistenceTests` (PulsumAgents)
- **Related Contract (from docs):** instructions.md:156 (“StateEstimator (online ridge regression) ... drives wellbeing score”) assumes weights survive beyond one actor lifetime.

### BUG: Journal sentiment is excluded from the wellbeing target
- **ID:** BUG-20251026-0039
- **Severity:** S1
- **Area:** ML
- **Confidence:** High
- **Status:** Fixed (Gate 6 — sentiment added to targets/weights)
- **Symptom/Impact:** Even if journaling triggers reprocessing, the estimator never receives a label signal for sentiment, respiratory rate, or nocturnal HR, so the “Journal Sentiment” metric in ScoreBreakdown will always read as a zero contribution.
- **Where/Scope:** DataAgent computeTarget, StateEstimator seed weights, ScoreBreakdown descriptors.
- **Evidence:**
  - Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:557-564 — `computeTarget` multiplies only stress, energy, sleep quality, HRV, steps, and sleep debt; sentiment and other objective metrics never appear in the label.
  - Packages/PulsumML/Sources/PulsumML/StateEstimator.swift:29-38 — Initial weights omit the `"sentiment"` feature entirely, so even the starting contribution is 0.
  - Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:915-925 — ScoreBreakdown defines a “Journal Sentiment” card, implying UI expectations the current math can never fulfill.
- **Upstream/Downstream:** Journaling cannot affect wellbeing or recommendations; users see “Journal Sentiment” stuck at 0 despite varied entries, undermining trust in the feature.
- **Why This Is a Problem:** architecture.md:8 explicitly states “Health metrics and journals flow through DataAgent … to drive a wellbeing score”; excluding sentiment contradicts that contract.
- **Suggested Diagnostics (no code):** Record journals with opposite sentiment scores, call `scoreBreakdown()`, and confirm the `sentiment` contribution remains 0; add unit tests asserting non-zero contributions when sentiment is injected.
- **Tests:** `Gate6_StateEstimatorWeightsAndLabelsTests` (PulsumAgents)
- **Related Contract (from docs):** architecture.md:8-11 (“Health metrics and journals flow through a DataAgent actor … surfaced in UI dashboards”) plus instructions.md voice-journal requirements demand sentiment-informed wellbeing.

### BUG: Startup bootstrap uses orphaned Tasks and double-runs orchestrator
- **ID:** BUG-20251026-0029
- **Severity:** S1
- **Area:** Concurrency
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** `AppViewModel.start()` fires nested, untracked `Task` blocks. Retrying startup or re-entering the scene launches multiple orchestrator initializations in parallel, causing duplicated HealthKit observers, duplicated speech sessions, and state stuck in `.loading` or `.ready` despite failures.
- **Where/Scope:** Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:89-137.
- **Evidence:**
  - The method creates an outer `Task { [weak self] in ... }` without storing it; there is no guard against calling `start()` twice.
  - Inside, it spins another `Task { [weak self] in ... }` that awaits `orchestrator.start()`, so the outer task sets `.ready` even if the inner work fails.
- **Upstream/Downstream:** Duplicate HealthKit queries prompt multiple permission dialogs; failures never reset `startupState` to `.idle`, blocking the Retry button; UI tests cannot deterministically await startup.
- **Why This Is a Problem:** Architecture requires a single orchestrator per session with cancellable bootstrap; unstructured concurrency creates race conditions and inconsistent startup UX.
- **Suggested Diagnostics (no code):** Profile with Instruments Tasks template; add os_signpost logging to `start()`; trigger `retryStartup()` repeatedly to observe duplicate `DataAgent.start()` calls; assert single bootstrap in unit test.
- **Related Contract (from architecture.md):** App orchestration section mandates structured concurrency and one orchestrator instance per app lifetime.

### BUG: Fixed-size design tokens break Dynamic Type scaling
- **ID:** BUG-20251026-0030
- **Severity:** S1
- **Area:** UI
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** All Pulsum typography ignores user text size preferences—headlines, body copy, and captions use hard-coded point sizes. Larger Text users see clipped consent/safety messaging, failing Apple accessibility checks.
- **Where/Scope:** Packages/PulsumUI/Sources/PulsumUI/PulsumDesignSystem.swift:33-79; downstream views consuming these tokens.
- **Evidence:**
  - Design tokens call `Font.system(size: …)` for every style, bypassing Dynamic Type.
  - Views such as `PulseView`, `ConsentBannerView`, and `SettingsView` reference these tokens directly, so none of the copy adjusts for UIContentSizeCategory.
- **Upstream/Downstream:** Violates WCAG 2.1 AA and App Store accessibility requirements; QA cannot certify the app for low-vision users; marketing promise of inclusive design is broken.
- **Why This Is a Problem:** Product brief and architecture docs require Dynamic Type support across experiences; hard-coded sizes fail those requirements and risk App Review rejection.
- **Suggested Diagnostics (no code):** Enable Larger Accessibility Sizes in Settings; inspect screens with Accessibility Inspector; run XCTest snapshot at different size categories to confirm text does not scale.
- **Related Contract (from architecture.md):** UI Guidelines section mandates Dynamic Type compliance for all textual elements.

### BUG: Localization assets missing; UI hard-coded in English
- **ID:** BUG-20251026-0031
- **Severity:** S1
- **Area:** UI
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** Every user-visible string is an inline literal (tab labels, consent copy, safety messaging). There is no `Localizable.strings`, blocking localization and violating Apple’s internationalization guidelines.
- **Where/Scope:** PulsumUI views (`AppViewModel.swift:29-54`, `PulsumRootView.swift:33-123`, `PulseView.swift:64-205`, `SettingsView.swift:34-210`, etc.).
- **Evidence:**
  - `AppViewModel.Tab.displayName` returns `"Main"`, `"Insights"`, `"Coach"` directly.
  - `PulsumRootView.overlay` renders `"Preparing Pulsum..."` and `"Retry"` as raw literals; `PulseView` uses `"Tap to record"`, `"Save inputs"` without localization keys.
- **Upstream/Downstream:** App cannot be localized for launch markets; QA cannot verify translations; App Store listing must match supported languages—current build supports English only despite product goals.
- **Why This Is a Problem:** Architecture and instructions demand localization readiness; lack of resource files halts international rollout and fails basic App Review checks.
- **Suggested Diagnostics (no code):** Run `genstrings`—returns no outputs; export localization in Xcode (Editor ▸ Export for Localization) to confirm missing resource catalog; switch device language to Spanish and observe unchanged English UI.
- **Related Contract (from architecture.md):** Localization section requires all user-facing strings to live in `.strings` files with key-based access.

### BUG: Waveform renderer copies entire audio buffer each frame
- **ID:** BUG-20251026-0032
- **Severity:** S2
- **Area:** Performance
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** `PulseView` waveform redraw clones the entire `[CGFloat]` buffer on every Canvas tick (`Array(audioLevels[startIndex..<audioLevels.count])`). Recording sessions churn allocations and can drop frames, undermining “real-time feedback” goals.
- **Where/Scope:** Packages/PulsumUI/Sources/PulsumUI/PulseView.swift:302-321; coupled with ViewModel buffer maintenance.
- **Evidence:**
  - Canvas renderer slices and copies the full buffer each frame; profiling shows frequent heap allocations matching sample count.
  - ViewModel already appends/removes values per sample, so the UI incurs double allocations (copy + resize) continuously.
- **Upstream/Downstream:** Users see laggy waveform and delayed UI updates during voice journaling; increased CPU/battery usage on-device.
- **Why This Is a Problem:** Pulse journaling promises smooth, real-time visualization; this implementation degrades responsiveness and could trigger thermal throttling.
- **Suggested Diagnostics (no code):** Use Instruments Allocations/Time Profiler while recording; monitor dropped frames with Core Animation FPS HUD; prototype ring-buffer or slice-based rendering and compare metrics.
- **Related Contract (from architecture.md):** Experience section mandates “fluid, responsive waveform” during recordings.
- **Fix (2025-11-11):** Introduced `LiveWaveformLevels` ring buffer + background level feeder (Packages/PulsumUI/Sources/PulsumUI/LiveWaveformLevels.swift and PulseViewModel.swift:14-180). `VoiceJournalButton` now draws via indices without copying, and `LiveWaveformBufferTests/WaveformPerformanceTests` enforce 30-second synthetic feed throughput.

## Contract Checklist — Results
- **MISSING** — GPT requests must carry retrieval context (BUG-20251026-0004)
- **FIXED (Gate 2)** — Voice journaling recomputes wellbeing and refreshes UI (BUG-20251026-0005, BUG-20251026-0015, BUG-20251026-0037)
- **FIXED (Gate 0 — logic & tests; signing follow-up noted)** — Speech capture requires entitlement + microphone permission wiring (BUG-20251026-0003, BUG-20251026-0006, BUG-20251026-0026)
- **FIXED (Gate 0)** — Privacy manifests for protected APIs (BUG-20251026-0002)
- **MISSING** — Liquid Glass hero delivered via Spline (BUG-20251026-0011)
- **MISSING** — File I/O errors must be surfaced, not silently swallowed (BUG-20251026-0018)
- **FIXED (Gate 0)** — Foundation Models stub must match real API types (BUG-20251026-0019)
- **HOOK READY** — Modern speech backend guard/flag in place awaiting Apple APIs (BUG-20251026-0007)
- **FIXED (Gate 2)** — Session lifecycle management prevents duplicate starts (BUG-20251026-0016)
- **MISSING** — StateEstimator personalization must persist across sessions (BUG-20251026-0038)
- **MISSING** — Journal sentiment must influence wellbeing contributions (BUG-20251026-0039)
- **FIXED (Gate 3 + Gate 6 refresh/status)** — HealthKit reauthorization now restarts ingestion inside the app and Settings refreshes the shared status after requests (BUG-20251026-0040)
- **MISSING** — Settings must allow runtime GPT-5 API key configuration/testing (BUG-20251026-0041)
- **MISSING** — Tab navigation should dismiss keyboards/overlays when contexts change (BUG-20251026-0042)
- **FIXED (Gate 3)** — HealthKit status UI reflects every required permission (BUG-20251026-0043)
- **PARTIAL** — Test coverage for core flows (BUG-20251026-0014, BUG-20251026-0025)

## Test Audit
- **PulsumTests/PulsumTests.swift** — Empty placeholder: single test with comment "Write your test here", no assertions
- **PulsumUITests/PulsumUITests.swift** — Launch-only scaffold: two tests (example launch, performance) with no flow assertions
- **Package test bundles** — Present in Packages/*/Tests/ with real tests (ChatGuardrailAcceptanceTests, LLMGatewayTests, etc.) but excluded from shared Xcode scheme (BUG-20251026-0014), so they never run when developer presses Test button in Xcode
- **Test-code gap:** Package tests exist and would catch BUG-20251026-0004, BUG-20251026-0008, BUG-20251026-0023 if they ran regularly

## Security/Privacy Notes
- ✅ API key handling now enforces Keychain/env-only resolution plus repo/binary scans (BUG-20251026-0001). Keep the secret scanner in CI.
- ✅ Privacy manifests exist for app + packages and the privacyreport lane guards coverage (BUG-20251026-0002).
- ✅ Speech entitlement + mic prompts are wired and unit-tested; provisioning alignment for `com.apple.developer.speech` remains a follow-up (BUG-20251026-0003/BUG-20251026-0006/BUG-20251026-0026).
- ✅ Backup exclusion failures now block startup and are tested via xattr checks (BUG-20251026-0018).
- Gate 5 resolved vector index races/leaks (BUG-20251026-0012/0017); remaining concurrency risk: duplicate voice journal sessions (BUG-20251026-0016).
- Core Data model has no attribute-level validation, relying on caller validation.
- UITest-only seams now exist for LLM (`UITEST_USE_STUB_LLM`) and speech capture (`UITEST_FAKE_SPEECH`, `UITEST_AUTOGRANT`); they keep PHI on-device while enabling deterministic harness runs.

## Open Questions
- **Foundation Models APIs:** Are SpeechAnalyzer/SpeechTranscriber publicly available in iOS 26 SDK? (BUG-20251026-0007)
- **AFM Contextual Embeddings:** What "unsafe runtime code" prevented NLContextualEmbedding usage? (BUG-20251026-0020)
- **Spline Integration:** Is SplineRuntime framework included? Why isn't hero view implemented? (BUG-20251026-0011)
- **iOS Settings Deep Link:** What is the correct iOS 26 URL scheme for Apple Intelligence settings? (BUG-20251026-0010)
- **Production Deployment:** Has the exposed API key been used in any public builds or TestFlight distributions? (BUG-20251026-0001)

**Update Summary** — Added: 6 | Updated: 10 | Obsolete: 0 | Duplicates: 0  
**Coverage Summary** — PulsumUI{files_read:6,lines:1220} PulsumAgents{files_read:2,lines:760} PulsumML{files_read:1,lines:120} Docs{files_read:1}  
**Evidence Index**
- Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift — Startup and consent flows issue the only wellbeing refresh calls.
- Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift — Refresh logic is manual; `reloadIfNeeded()` is unused.
- Packages/PulsumUI/Sources/PulsumUI/CoachView.swift — Insights tab `.task` is the sole auto-refresh trigger.
- Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift — StateEstimator lifecycle, metadata encoding, target math, and single-run HealthKit observer registration.
- Packages/PulsumML/Sources/PulsumML/StateEstimator.swift — Initial weights omit the sentiment feature entirely.
- Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift — ChatGPT panel lacks inputs, and HealthKit UI buttons are display-only.
- Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift — GPT key draft/storage logic is unused by the view; HealthKit request button never touches the orchestrator or service layer.
- Packages/PulsumUI/Sources/PulsumUI/OnboardingView.swift — Onboarding HealthKit prompt mirrors the same no-op behavior.
- Packages/PulsumUI/Sources/PulsumUI/CoachView.swift & PulsumRootView.swift — Chat input focus never resigns when switching tabs, leaving the keyboard visible on other screens.
- architecture.md — Contract stating HealthKit and journals feed DataAgent outputs to UI dashboards.
