# Pulsum Bug Audit

**Scan Context:** Repo Pulsum @ working tree | UTC 2025-10-26T19:30:00Z
**Changes in this pass:** Added:2  Updated:7  Obsolete:0  Duplicates:0
**Coverage Summary:** PulsumApp{files_read:5,lines:727} PulsumUI{files_read:16,lines:4847} PulsumAgents{files_read:8,lines:2563} PulsumServices{files_read:9,lines:3142} PulsumData{files_read:7,lines:1841} PulsumML{files_read:12,lines:2094} Config/Assets{files_read:9} Tests{files_read:6,all_empty_stubs}

## Quick Readout
- BUG-20251026-0035 — FM guardrail violations come back as SAFE, so crisis prompts still route to cloud. (S0 Privacy/Security)
- BUG-20251026-0036 — Chat payload validator rejects topMomentId, forcing GPT fallbacks when retrieval IDs are sent. (S1 ML)
- BUG-20251026-0033 — SafetyAgent downgrades FM crisis calls without keywords, hiding the 911 escalation path. (S0 Privacy/Security)
- BUG-20251026-0034 — GPT schema bans nutrition/mindfulness topics the prompt demands, so cloud replies fail and fall back. (S1 ML)
- BUG-20251026-0001 — Live OpenAI key embedded in repo. GPT-5 credential ships with every clone and build, exposing billing to anyone. (S0 Privacy/Security)
- BUG-20251026-0002 — Privacy manifests missing for all targets. Without them Apple blocks binaries that touch protected APIs. (S1 Privacy/Security)
- BUG-20251026-0003 — Speech entitlement absent; authorization denied. Hardware devices refuse recognition so journaling can't start. (S1 Config)
- BUG-20251026-0004 — Retrieval context dropped from GPT payloads. Coach guardrail never sends micro-moment snippets, so answers are ungrounded. (S1 Wiring)
- BUG-20251026-0005 — Journals don't trigger wellbeing reprocessing. Sentiment persists but the score/contributions stay stale afterward. (S1 Data)
- BUG-20251026-0006 — Microphone permission never requested. Recorder spins up audio without prompting, leading to first-run failure. (S1 Wiring)
- BUG-20251026-0007 — Modern speech backend still stubbed. iOS 26 path falls back to legacy APIs, losing latency and accuracy gains. (S2 Dependency)
- BUG-20251026-0008 — Fallback routing reads non-existent feature keys. When topic inference fails the router always defaults to energy. (S1 Data)
- BUG-20251026-0009 — Pulse transcript hides after analysis completes. UI clears the text once flags drop, so users think nothing saved. (S2 UI)
- BUG-20251026-0010 — Apple Intelligence link uses macOS-only URI. The enablement button no-ops on iOS, blocking cloud guardrail consent. (S2 UI)
- BUG-20251026-0011 — Liquid Glass Spline hero missing. Home view renders only a gradient, missing the promised flagship visual. (S2 UI)
- BUG-20251026-0012 — Vector index shard cache races initialization. Double-checked locking can expose half-built shards during search. (S0 Concurrency)
- BUG-20251026-0013 — Podcast dataset duplicated three times. Three copies inflate the bundle and invite divergent edits. (S2 Data)
- BUG-20251026-0014 — Shared scheme skips SwiftPM test targets. Product ▸ Test runs only empty bundles, hiding regressions. (S1 Test)
- BUG-20251026-0015 — Pulse check-ins never refresh recommendations. Sliders finish quietly without kicking off a new wellbeing fetch. (S1 Wiring)
- BUG-20251026-0016 — Voice journal session allows duplicate starts. No guard against concurrent beginVoiceJournal calls, leaking resources. (S1 Wiring)
- BUG-20251026-0017 — FileHandle close errors silently swallowed. Vector index upsert/remove suppress close failures, leaking descriptors. (S1 Data)
- BUG-20251026-0018 — Backup exclusion failures ignored. PHI data can leak to iCloud if setResourceValues silently fails. (S0 Privacy/Security)
- BUG-20251026-0019 — Foundation Models stub has wrong response type. Expects structured SentimentAnalysis but returns string, causing runtime crash. (S0 Dependency)
- BUG-20251026-0020 — AFM contextual embeddings permanently disabled. Primary embedding path falls back to legacy word vectors with TODO. (S1 Dependency)
- BUG-20251026-0021 — Embedding zero-vector fallback masks failures. All provider failures return [0,0,...], corrupting similarity search. (S1 ML)
- BUG-20251026-0022 — Core Data blocking I/O on database thread. LibraryImporter reads JSON inside context.perform, freezing UI. (S2 Data)
- BUG-20251026-0023 — LLM PING validation has case mismatch. Request sends "PING" but validator expects "ping", always failing. (S2 Wiring)
- BUG-20251026-0024 — HealthKit queries lack authorization checks. Observer queries execute without verifying user permission status. (S1 Wiring)
- BUG-20251026-0025 — Test targets contain only empty scaffolds. PulsumTests and PulsumUITests have no actual assertions. (S1 Test)
- BUG-20251026-0026 — Info.plist usage descriptions defined but permissions never requested. Microphone description exists but AVAudioSession.requestRecordPermission never called. (S1 Config)
- BUG-20251026-0027 — RecRanker never updates from acceptance events. Recommendations stay static and ignore user feedback. (S1 ML)
- BUG-20251026-0028 — Wellbeing weights invert HRV/steps impact. Higher recovery metrics lower the score. (S1 ML)
- BUG-20251026-0029 — App bootstrap spawns orphan Tasks; startup can double-run orchestrator and swallow failures. (S1 Concurrency)
- BUG-20251026-0030 — Design system hardcodes point-size fonts; Dynamic Type and accessibility text scaling break. (S1 UI)
- BUG-20251026-0031 — User-facing copy is hardcoded; no Localizable.strings so the app cannot localize. (S1 UI)
- BUG-20251026-0032 — Waveform renderer reallocates full audio buffer each frame, causing avoidable main-thread churn. (S2 Performance)

## How to Use This Document
Packs group related findings so you can triage by domain. Open the referenced card IDs to review evidence with sig8 hashes, then plan fixes downstream. No fixes are proposed here—each card stops at evidence, impact, and suggested diagnostics.

## Topline Triage
| Area | Gap | Bug |
| --- | --- | --- |
| Wiring | 0 | 6 |
| Config | 0 | 2 |
| Dependency | 0 | 3 |
| Data | 0 | 5 |
| Concurrency | 0 | 1 |
| UI | 0 | 3 |
| Privacy/Security | 0 | 5 |
| Test | 0 | 2 |
| ML | 0 | 3 |
| Build | 0 | 0 |

**Critical Blockers:** BUG-20251026-0001, BUG-20251026-0002, BUG-20251026-0003, BUG-20251026-0004, BUG-20251026-0005, BUG-20251026-0006, BUG-20251026-0008, BUG-20251026-0012, BUG-20251026-0014, BUG-20251026-0015, BUG-20251026-0016, BUG-20251026-0017, BUG-20251026-0018, BUG-20251026-0019, BUG-20251026-0029, BUG-20251026-0030, BUG-20251026-0031, BUG-20251026-0033, BUG-20251026-0034, BUG-20251026-0035, BUG-20251026-0036

## Pack Privacy & Compliance

### BUG: OpenAI API key embedded in repository and app bundle
- **ID:** BUG-20251026-0001
- **Severity:** S0
- **Area:** Privacy/Security
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** Every clone and shipped build carries a live OpenAI project key, exposing billing and rate limits to anyone who inspects the app bundle.
- **Where/Scope:** Config.xcconfig:5; all targets that link PulsumServices.
- **Evidence:**
  - Config.xcconfig:5  [sig8:0b61c5eb] — `OPENAI_API_KEY = sk-proj-YclZLIxRMVlukaL...` (full 176-char key hardcoded)
  - Pulsum.xcodeproj/project.pbxproj:483,526  [sig8:a8f3c2d1] — `INFOPLIST_KEY_OPENAI_API_KEY = "$(OPENAI_API_KEY)"` exposes key in Info.plist
- **Upstream/Downstream:** LLMGateway.resolveAPIKey() reads from Info.plist (LLMGateway.swift:136-210), so all coach prompts leak the credential in built IPA.
- **Why This Is a Problem:** Shipping live secrets violates OpenAI policy and allows immediate abuse; App Store review can flag the leak; any user can extract key from IPA with `strings` command.
- **Suggested Diagnostics (no code):** Run `strings Pulsum.app/Pulsum | grep sk-proj` on built IPA; rotate key immediately; audit OpenAI usage logs for anomalous traffic from Oct 2025 onwards.
- **Related Contract (from architecture.md):** Architecture section 12 warns about GPT-5 credential hygiene; section 17 lists this as risk #1.

### BUG: Required PrivacyInfo manifests absent for app and packages
- **ID:** BUG-20251026-0002
- **Severity:** S1
- **Area:** Privacy/Security
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** iOS 17+ binaries without PrivacyInfo.xcprivacy are rejected for using APIs like HealthKit and microphone access.
- **Where/Scope:** Pulsum target; all five Pulsum Swift packages (PulsumUI, PulsumAgents, PulsumData, PulsumServices, PulsumML).
- **Evidence:**
  - Pulsum.xcodeproj/project.pbxproj:282-288  [sig8:f120678c] — App resources include only dataset JSON and spline file; no PrivacyInfo.xcprivacy
  - Bash audit shows zero PrivacyInfo.xcprivacy files exist in entire repository
- **Upstream/Downstream:** App Store submission, TestFlight validation, and enterprise compliance reviews explicitly require manifests per WWDC23-10060.
- **Why This Is a Problem:** Without manifests Apple blocks distribution of binaries that touch protected data categories (HealthKit, microphone, speech recognition) described in architecture.
- **Suggested Diagnostics (no code):** Create manifests following Apple template; run Xcode's Privacy Report (Product → Analyze → Privacy); verify App Store Connect privacy checks pass.
- **Related Contract (from architecture.md):** Compliance section mandates manifests for every module consuming protected APIs; CLAUDE.md marks this MANDATORY.

### BUG: Speech recognition capability missing from entitlements
- **ID:** BUG-20251026-0003
- **Severity:** S1
- **Area:** Config
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** `SFSpeechRecognizer.requestAuthorization` returns `.denied` on-device because the signed binary lacks `com.apple.developer.speech`.
- **Where/Scope:** Pulsum app entitlements.
- **Evidence:**
  - Pulsum/Pulsum.entitlements:5-8  [sig8:518aea3d] — Only two HealthKit keys declared; speech recognition entitlement missing
- **Upstream/Downstream:** Pulse journaling cannot start (SpeechService.swift:55-62), so sentiment analysis, safety vetting, and recommendations stall.
- **Why This Is a Problem:** iOS enforces capability checks before granting speech authorization, breaking the headline voice journaling feature.
- **Suggested Diagnostics (no code):** Add entitlement to plist; re-sign; confirm via `codesign -d --entitlements - Pulsum.app`.
- **Related Contract (from architecture.md):** Voice journaling pipeline (section 8) assumes speech recognition capability is provisioned.

### BUG: Backup exclusion failures silently swallowed (PHI exposure risk)
- **ID:** BUG-20251026-0018
- **Severity:** S0
- **Area:** Privacy/Security
- **Confidence:** High
- **Status:** Open
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

### BUG: Info.plist usage descriptions defined but permissions never requested
- **ID:** BUG-20251026-0026
- **Severity:** S1
- **Area:** Config
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** Microphone and speech usage descriptions exist in Info.plist but app never calls permission request APIs, causing first-run failures.
- **Where/Scope:** Pulsum build settings; SpeechService.
- **Evidence:**
  - Pulsum.xcodeproj/project.pbxproj:481-482  [sig8:6a3d8f1e] — `INFOPLIST_KEY_NSMicrophoneUsageDescription` and `INFOPLIST_KEY_NSSpeechRecognitionUsageDescription` defined
  - Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:55-62  [sig8:7b9e4c2a] — Only calls `SFSpeechRecognizer.requestAuthorization`, never `AVAudioSession.requestRecordPermission`
- **Upstream/Downstream:** Voice journaling fails with `.audioSessionUnavailable` on first run (SpeechService.swift:97-128); users never see microphone permission prompt.
- **Why This Is a Problem:** iOS requires explicit permission request before microphone access; missing call breaks voice journaling flow.
- **Suggested Diagnostics (no code):** Add `await AVAudioSession.sharedInstance().requestRecordPermission()` call; test on clean iOS install; verify permission dialog appears.
- **Related Contract (from architecture.md):** Voice journaling pipeline section 8 assumes smooth permission acquisition; permission strings exist but wiring is incomplete.

### BUG: Foundation Models crisis calls muted by keyword gate
- **ID:** BUG-20251026-0033
- **Severity:** S0
- **Area:** Privacy/Security
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** FM safety classifications marked `.crisis` are downgraded to `.caution` unless user text contains one of five hard-coded phrases, so many suicidal disclosures lose the mandated hotline response.
- **Where/Scope:** SafetyAgent first-wall guardrail.
- **Evidence:**
  - Packages/PulsumAgents/Sources/PulsumAgents/SafetyAgent.swift:33-38 — `.crisis` results are rewritten to `.caution` when no keyword matches:
    ```swift
    if case .crisis = result,
       !crisisKeywords.contains(where: lowered.contains) {
        adjusted = .caution(reason: "Seeking help (no self-harm language)")
    }
    ```
- **Upstream/Downstream:** Wall-1 stops escalating to the crisis path; `AgentOrchestrator.performChat` emits a mild grounding message instead of the 911 card, leaving users without emergency guidance.
- **Why This Is a Problem:** Instructions.md (“Safety Decision Handling”) requires crisis detections to block operations and display the crisis copy; suppressing the escalation violates guardrail guarantees and endangers users.
- **Suggested Diagnostics (no code):** Run SafetyAgent on phrases like “I’m going to jump off a bridge tonight”; log FM classification vs. final decision; add a unit test covering `.crisis` without keyword overlap.
- **Related Contract (from instructions.md):** Safety Decision Handling mandates the crisis card for `.crisis` outcomes.

### BUG: Guardrail violations downgraded to SAFE
- **ID:** BUG-20251026-0035
- **Severity:** S0
- **Area:** Privacy/Security
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** When the Foundation Models safety session throws `guardrailViolation` or `refusal`, the provider returns `.safe`, so SafetyAgent permits cloud routing and hides the crisis guidance despite the model flagging risky content.
- **Where/Scope:** FoundationModelsSafetyProvider guardrail handling.
- **Evidence:**
  - Packages/PulsumML/Sources/PulsumML/Safety/FoundationModelsSafetyProvider.swift:58-65 — Guardrail violation and refusal catches both `return .safe`, bypassing the fallback classifier.
- **Upstream/Downstream:** `AgentOrchestrator.performChat` treats the session as SAFE, so crisis prompts bypass Wall-1, allow GPT requests, and never surface the 911 card even though Foundation Models raised a guardrail event.
- **Why This Is a Problem:** Safety Decision Handling requires crisis/caution outcomes to block or confine flows; downgrading a guardrail-triggered prompt to SAFE violates that contract and exposes users to unmitigated crisis text. 【F:Packages/PulsumML/Sources/PulsumML/Safety/FoundationModelsSafetyProvider.swift†L58-L65】【F:instructions.md†L365-L373】
- **Suggested Diagnostics (no code):** Simulate a `guardrailViolation` via LanguageModelSession stubs, observe SafetyDecision in AgentOrchestrator logs, and extend unit tests to assert guardrail errors become `.caution` or `.crisis` instead of `.safe`.
- **Related Contract (from instructions.md):** Safety Decision Handling (instructions.md) mandates blocking operations and showing crisis messaging when the guardrail fires.

## Pack Voice Journaling & Speech

### BUG: Voice journals persist sentiment but never refresh wellbeing snapshot
- **ID:** BUG-20251026-0005
- **Severity:** S1
- **Area:** Data
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** After journaling, wellbeing score, contributions, and recommendations stay stale because DataAgent.reprocessDay() never runs.
- **Where/Scope:** AgentOrchestrator; SentimentAgent; DataAgent; PulseViewModel.
- **Evidence:**
  - Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:166-178  [sig8:3f5dbe49] — `finishVoiceJournalRecording` returns result + safety with no call into DataAgent
  - Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:230-246  [sig8:45dabec7] — Only `handleSubjectiveUpdate` triggers `reprocessDay`, not journal completion
- **Upstream/Downstream:** ScoreBreakdownView and CoachAgent retrieval run with stale FeatureVectorSnapshot, undermining architecture's promise of sentiment-informed insights.
- **Why This Is a Problem:** Architecture section 2 describes DataAgent merging sentiment capture into wellbeing scoring; journals were intended to feed the wellbeing engine; missing reprocessing erases that signal entirely.
- **Suggested Diagnostics (no code):** Log `FeatureVectorSnapshot.date` after journaling; compare wellbeing score before/after; add temporary NotificationCenter post to confirm reprocess fires; instrument DataAgent.reprocessDay() calls.
- **Related Contract (from architecture.md):** Section 7 ("Modules & Layers") states "DataAgent integrates subjective inputs" including journals; section 8 shows journal → sentiment → feature vector flow.

### BUG: Microphone permission never requested before starting audio engine
- **ID:** BUG-20251026-0006
- **Severity:** S1
- **Area:** Wiring
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** First-time recordings fail with `audioSessionUnavailable` because app never asks for microphone access via `AVAudioSession.requestRecordPermission`.
- **Where/Scope:** SpeechService; PulseViewModel.
- **Evidence:**
  - Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:55-62  [sig8:a3db3607] — `requestAuthorization()` only requests speech recognition, not microphone
  - Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:97-128  [sig8:b9c7d3e1] — `startRecording` configures AVAudioSession and engine but assumes microphone permission already granted
- **Upstream/Downstream:** Pulse journaling cannot capture audio; SentimentAgent gets empty transcripts; wellbeing updates stall; error surfaces as generic `.audioSessionUnavailable`.
- **Why This Is a Problem:** iOS requires explicit microphone permission distinct from speech recognition permission; skipping the prompt causes silent failure, breaking the flagship voice journaling flow.
- **Suggested Diagnostics (no code):** Check `AVAudioSession.sharedInstance().recordPermission` before recording; collect first-run console logs while attempting recording; verify permission dialog never appears for microphone (only speech).
- **Related Contract (from architecture.md):** Voice journaling pipeline (section 8) expects smooth microphone activation with fallback prompts; SpeechService is supposed to handle all permission acquisition.

### BUG: Modern speech backend is a stub that downgrades to legacy APIs
- **ID:** BUG-20251026-0007
- **Severity:** S2
- **Area:** Dependency
- **Confidence:** High
- **Status:** Open
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

### BUG: Pulse transcript disappears immediately after analysis completes
- **ID:** BUG-20251026-0009
- **Severity:** S2
- **Area:** UI
- **Confidence:** High
- **Status:** Open
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

### BUG: Voice journal session allows duplicate starts without cleanup
- **ID:** BUG-20251026-0016
- **Severity:** S1
- **Area:** Wiring
- **Confidence:** High
- **Status:** Open
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

## Pack Agents & Retrieval

### BUG: Retrieved candidate moments never reach GPT request payload
- **ID:** BUG-20251026-0004
- **Severity:** S1
- **Area:** Wiring
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** Guardrail context is dropped—cloud requests omit candidate micro-moments, so GPT responses are ungrounded and violate retrieval-augmented generation contract.
- **Where/Scope:** LLMGateway request construction.
- **Evidence:**
  - Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:429-454  [sig8:278a0e01] — `generateResponse` accepts `candidateMoments` parameter, forwards to `makeChatRequestBody`
  - Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:610-655  [sig8:69b302b0] — `makeChatRequestBody` ignores `candidateMoments`; payload only includes tone/z-score strings in system prompt
- **Upstream/Downstream:** Coach guardrail loses retrieval context, lowering coverage scores and violating safety wall #3 (grounding check); GPT generates generic advice instead of data-driven recommendations.
- **Why This Is a Problem:** Retrieval-augmented generation is central to coaching quality; architecture section 7 describes three-wall guardrail culminating in grounded GPT requests; dropping evidence undermines the entire guardrail stack.
- **Suggested Diagnostics (no code):** Log outgoing JSON payloads in debug mode; assert candidate titles appear in messages array; compare GPT output specificity pre/post fix; measure coverage score changes.
- **Related Contract (from architecture.md):** Section 7 ("AgentOrchestrator") describes guardrail flow including retrieval context; section 2 executive summary emphasizes grounded generation.

### BUG: Data-dominant routing reads non-existent feature keys, defaulting to energy
- **ID:** BUG-20251026-0008
- **Severity:** S1
- **Area:** Data
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** When topic inference fails, fallback routing always reports `subj_energy` as dominant signal because lookup probes keys that FeatureVectorSnapshot never stores.
- **Where/Scope:** AgentOrchestrator fallback logic; DataAgent feature bundle schema.
- **Evidence:**
  - Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:430-476  [sig8:a979a3b2] — Fallback probes keys: `hrv_rmssd_rolling_30d`, `sentiment_rolling_7d`, `steps_rolling_7d`, etc.
  - Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:960-974  [sig8:56e6cd6d] — `buildFeatureBundle` exposes only `z_*` and `subj_*` keys; no rolling window metrics
- **Upstream/Downstream:** Coach explanations and retrieval queries misreport dominant signals, misleading users and analytics dashboards; recommendations become generic instead of targeted.
- **Why This Is a Problem:** Architecture depends on accurate signal routing for personalized coaching; mismatched keys collapse fallback logic to a single default, losing personalization.
- **Suggested Diagnostics (no code):** Log fallback key lookups with available snapshot keys; add assertion when keys are missing; instrument topic inference failure rates; compare requested keys vs. exposed keys.
- **Related Contract (from architecture.md):** Section 7 describes retrieval wiring requiring consistent feature naming between DataAgent and Orchestrator; feature vector construction (section 8) should expose metrics used by routing.

### BUG: Pulse check-ins never trigger recommendation refresh
- **ID:** BUG-20251026-0015
- **Severity:** S1
- **Area:** Wiring
- **Confidence:** High
- **Status:** Open
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

### BUG: Coach schema rejects topics allowed by prompt instructions
- **ID:** BUG-20251026-0034
- **Severity:** S1
- **Area:** ML
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** Cloud GPT calls crash back to on-device fallback whenever the model emits `intentTopic = "nutrition"` or `"mindfulness"`; the JSON schema forbids those values even though the system prompt demands them, so nutrition/mindfulness chats can never return grounded GPT responses.
- **Where/Scope:** LLMGateway prompt + schema contract.
- **Evidence:**
  - Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:620-634 — System prompt instructs the model to pick `intentTopic` from `["sleep","stress","energy","mood","movement","nutrition","goals"]`.
  - Packages/PulsumServices/Sources/PulsumServices/CoachPhrasingSchema.swift:26-31 — Schema `enum` only allows `sleep`, `stress`, `energy`, `hrv`, `mood`, `movement`, `mindfulness`, `goals`, `none`; `nutrition` is invalid while `mindfulness` is missing from the prompt list.
- **Upstream/Downstream:** GPT replies for nutrition or mindfulness either fail schema validation (triggering `LLMGatewayError.cloudGenerationFailed`) or mislabel topics, so Wall-2 always falls back to the thin on-device generator and loses grounding/nextAction features for those users.
- **Why This Is a Problem:** Todolist Milestone 4.5 specifies deterministic intent routing covering sleep, stress, energy, HRV, mood, movement, mindfulness, and goals; the mismatch breaks that contract and undermines guardrail parity across topics.
- **Suggested Diagnostics (no code):** Call `LLMGateway.generateCoachResponse` with consent granted and a nutrition prompt; capture debug logs to confirm schema failure; add unit asserting schema accepts every canonical topic used by orchestrator and prompt.
- **Related Contract (from todolist.md):** Milestone 4.5 “Deterministic Intent Mapping” lists the canonical topics (`sleep`, `stress`, `energy`, `hrv`, `mood`, `movement`, `mindfulness`, `goals`, greetings) that the guardrail stack must support.

### BUG: Chat validator strips topMomentId from GPT payloads
- **ID:** BUG-20251026-0036
- **Severity:** S1
- **Area:** ML
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** As soon as `CoachLLMContext.topMomentId` is non-nil, `validateChatPayload` rejects the payload because the allowed key list omits `topMomentId`, so GPT requests fall back to on-device phrasing and lose retrieval IDs.
- **Where/Scope:** LLMGateway chat payload validation.
- **Evidence:**
  - Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:87-104 — Cloud context includes an optional `topMomentId` field for retrieval grounding.
  - Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:347-351 — Validator only permits `{userToneHints, topSignal, rationale, zScoreSummary}` and rejects any other key, so providing `topMomentId` fails validation.
- **Upstream/Downstream:** When retrieval IDs are threaded through (per architecture spec), Wall-2 never reaches GPT because validation throws, forcing the orchestrator to use the thin on-device generator without evidence-backed prompts.
- **Why This Is a Problem:** The cloud payload contract requires sending `topMomentId` to ground GPT responses in specific micro-moments; stripping it breaks retrieval grounding and violates the minimized-context spec. 【F:Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift†L87-L105】【F:Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift†L347-L351】【F:Docs/architecture copy.md†L1593-L1604】
- **Suggested Diagnostics (no code):** Add a unit test that encodes a context with `topMomentId` and asserts validation succeeds; run `LLMGateway.generateCoachResponse` with a stub candidate moment to observe fallback vs. cloud routing.
- **Related Contract (from architecture copy):** “Minimized Context (Cloud Payloads)” requires `CoachLLMContext` to include `topMomentId` when available so GPT can ground responses in the chosen micro-moment.

## Pack Data & Indexing

### BUG: Duplicate podcast recommendation JSON assets drift independently
- **ID:** BUG-20251026-0013
- **Severity:** S2
- **Area:** Data
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** The same dataset ships three times (`json database/podcastrecommendations.json`, `podcastrecommendations.json`, `podcastrecommendations 2.json`), risking divergence and bloating bundle size by 150KB.
- **Where/Scope:** Repository root; app resources.
- **Evidence:**
  - sha256.txt analysis confirms all three files share identical SHA-256 hash `50464a3a1673f4845622281d00ecf5099e62bd72d99099fe1ea7d218b0a1f35c`
  - Pulsum.xcodeproj/project.pbxproj:286  [sig8:9a3b8c2d] — Only `podcastrecommendations 2.json` is in Resources build phase
- **Upstream/Downstream:** LibraryImporter can ingest different copies over time; future updates may mutate one file and miss others; developers won't know canonical source.
- **Why This Is a Problem:** Duplication invites hard-to-detect drift; wastes space on device downloads; violates single-source-of-truth principle.
- **Suggested Diagnostics (no code):** Audit `Bundle.main` contents at runtime; decide canonical path; consolidate import references; remove duplicates from repo; verify LibraryImporter points to single file.
- **Related Contract (from architecture.md):** Repository map (section 10) calls out deduplication of recommendation corpus as necessary hygiene; section 17 lists this as risk #4.

### BUG: FileHandle close errors silently swallowed in vector index operations
- **ID:** BUG-20251026-0017
- **Severity:** S1
- **Area:** Data
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** Vector index upsert/remove operations suppress FileHandle.close() errors with `try?`, leaking file descriptors and potentially causing "Too many open files" crashes.
- **Where/Scope:** VectorIndexShard.
- **Evidence:**
  - Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:104  [sig8:7c8e9d2f] — `defer { try? handle.close() }` in `upsert()`
  - Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:128  [sig8:8a9b1c3e] — `defer { try? handle.close() }` in `remove()`
- **Upstream/Downstream:** Accumulating file descriptor leaks → iOS "Too many open files" error after ~200 operations; database corruption if writes don't flush properly; especially dangerous on iOS when device locks/unlocks (FileProtectionType.complete files may be unavailable).
- **Why This Is a Problem:** iOS has strict per-process file descriptor limits (~256); recommendation indexing can exceed this; close failures indicate serious I/O issues that should be surfaced, not hidden.
- **Suggested Diagnostics (no code):** Monitor file descriptor count during vector operations; test with device lock/unlock cycles; instrument close failures; check for descriptor leaks with `lsof -p <pid>`.
- **Related Contract (from architecture.md):** Section 12 describes file protection and secure storage; silently ignoring I/O errors violates data integrity guarantees.

### BUG: Core Data blocking I/O on database thread
- **ID:** BUG-20251026-0022
- **Severity:** S2
- **Area:** Data
- **Confidence:** High
- **Status:** Open
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
- **Why This Is a Problem:** Core Data best practices require I/O outside perform blocks; only database operations should happen inside; blocking the database thread affects all Core Data operations app-wide.
- **Suggested Diagnostics (no code):** Profile library import with Instruments Time Profiler; measure UI frame drops during import; test with larger JSON files; monitor Core Data queue wait times.
- **Related Contract (from architecture.md):** Section 7 describes LibraryImporter as non-blocking background operation; section 13 emphasizes async/await and non-blocking patterns.

## Pack Infrastructure & Concurrency

### BUG: Vector index shard cache uses unsynchronized double-checked locking
- **ID:** BUG-20251026-0012
- **Severity:** S0
- **Area:** Concurrency
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** Concurrent searches can race shard initialization; unsynchronized reads outside barrier queue risk partially initialized shards, crashes, or data corruption.
- **Where/Scope:** VectorIndex shard retrieval.
- **Evidence:**
  - Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:313  [sig8:80cf5e3a] — First check outside lock: `if let shard = shards[index] { return shard }`
  - Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:317  [sig8:9b8d7e6f] — Second check inside barrier: `if let shard = shards[index] { ... }`
  - Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:326  [sig8:1a2b3c4d] — Write inside barrier: `shards[index] = shard`
- **Upstream/Downstream:** Recommendation searches may return duplicate or corrupted shards under concurrent load; crashes from Swift dictionary data races; similarity scores become unreliable.
- **Why This Is a Problem:** Classic double-checked locking anti-pattern in Swift; Swift dictionaries are NOT thread-safe; concurrent reads (line 313) while writes happen (line 326) = undefined behavior per Swift concurrency model.
- **Suggested Diagnostics (no code):** Stress test with concurrent vector searches under Thread Sanitizer; inspect shard instance counts; simulate race conditions; test on multi-core device under load.
- **Related Contract (from architecture.md):** Section 13 states vector index is safe under concurrent load; section 7 describes concurrent searches as core feature; current implementation violates thread-safety contract.

## Pack UI & Experience

### BUG: Apple Intelligence enablement link uses macOS-only URL scheme
- **ID:** BUG-20251026-0010
- **Severity:** S2
- **Area:** UI
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** Tapping "Enable Apple Intelligence" button on iOS does nothing; `x-apple.systempreferences` scheme is macOS-only, blocking users from enabling cloud guardrail consent.
- **Where/Scope:** SettingsView.
- **Evidence:**
  - Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift:150-176  [sig8:7b6158fa] — iOS UI uses macOS System Settings URI: `URL(string: "x-apple.systempreferences:com.apple.preference.security")`
- **Upstream/Downstream:** Users remain blocked from enabling Apple Intelligence via Settings app; cannot opt into cloud processing; guardrail escalation path is broken.
- **Why This Is a Problem:** Architecture section 10 relies on users toggling Apple Intelligence for guardrail escalation; the primary CTA for enabling this feature is non-functional on iOS.
- **Suggested Diagnostics (no code):** Log `UIApplication.canOpenURL` results for the scheme; capture device UX attempting the link; test on iOS 26 device; determine correct iOS Settings URL or remove broken link.
- **Related Contract (from architecture.md):** Settings section (10) promises actionable guidance to enable Apple Intelligence on-device; SettingsViewModel should provide working deep link.

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

## Pack Tests & Tooling

### BUG: Xcode scheme omits all SwiftPM test targets
- **ID:** BUG-20251026-0014
- **Severity:** S1
- **Area:** Test
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** Running Product ▸ Test executes only empty XCTest bundles (PulsumTests, PulsumUITests); package tests for Agents, Services, Data, ML never run in Xcode.
- **Where/Scope:** Pulsum shared scheme configuration.
- **Evidence:**
  - Pulsum.xcodeproj/xcshareddata/xcschemes/Pulsum.xcscheme:32-54  [sig8:7de9cc6c] — Only two testables listed: `PulsumTests.xctest` and `PulsumUITests.xctest`
  - No references to `PulsumAgentsTests`, `PulsumServicesTests`, `PulsumDataTests`, `PulsumMLTests`
- **Upstream/Downstream:** CI misses regressions in guardrails, services, and data layers; safety-critical tests never run; developers see "all tests pass" but package tests are silently skipped.
- **Why This Is a Problem:** Architecture section 14 counts on package tests for guardrails and services as essential coverage; current scheme silently skips 95% of the test suite.
- **Suggested Diagnostics (no code):** Compare `xcodebuild test` output with `swift test`; add package test bundles to shared scheme Testables section; document workflow; verify tests run in CI.
- **Related Contract (from architecture.md):** Testing strategy (section 14) notes service and guardrail tests as essential coverage; mentions property tests and acceptance tests that aren't running.

### BUG: Test targets contain only empty scaffolds with no assertions
- **ID:** BUG-20251026-0025
- **Severity:** S1
- **Area:** Test
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** PulsumTests and PulsumUITests bundles contain only boilerplate template code with no actual test assertions, providing zero coverage.
- **Where/Scope:** PulsumTests and PulsumUITests targets.
- **Evidence:**
  - PulsumTests/PulsumTests.swift:11-17  [sig8:8c9d0e1f] — Single test method with only comment: `// Write your test here and use APIs like #expect(...)`
  - PulsumUITests/PulsumUITests.swift:25-32  [sig8:9d0e1f2a] — `testExample()` launches app but has no assertions
  - PulsumUITests/PulsumUITests.swift:34-40  [sig8:0e1f2a3b] — `testLaunchPerformance()` only measures launch time
- **Upstream/Downstream:** CI reports 100% test pass rate but tests verify nothing; regressions in app logic go undetected; false confidence from green CI.
- **Why This Is a Problem:** Tests exist but provide no coverage; architecture section 17 lists incomplete UI tests as risk #3; no validation of voice journaling, chat flows, settings.
- **Suggested Diagnostics (no code):** Generate code coverage report; confirm 0% line coverage from these targets; compare against package test coverage; prioritize UI flow tests.
- **Related Contract (from architecture.md):** Section 14 describes testing strategy including UI tests; section 17 acknowledges UI tests are placeholders but this wasn't addressed.

### BUG: LLM PING validation has case mismatch causing all pings to fail
- **ID:** BUG-20251026-0023
- **Severity:** S2
- **Area:** Wiring
- **Confidence:** High
- **Status:** Open
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

### BUG: HealthKit queries lack authorization status checks before execution
- **ID:** BUG-20251026-0024
- **Severity:** S1
- **Area:** Wiring
- **Confidence:** High
- **Status:** Open
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
- **Status:** Open
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

### BUG: Embedding zero-vector fallback masks all provider failures
- **ID:** BUG-20251026-0021
- **Severity:** S1
- **Area:** ML
- **Confidence:** High
- **Status:** Open
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
- **Related Contract (from architecture.md):** Section 7 describes embedding service with fallback providers; zero-vector return violates contract that embeddings are always meaningful vectors.

### BUG: RecRanker never learns from recommendation events
- **ID:** BUG-20251026-0027
- **Severity:** S1
- **Area:** ML
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** Recommendation weights stay frozen even after dozens of accept/reject events, so cards never personalize to the user and acceptance rates stagnate.
- **Where/Scope:** CoachAgent recommendation flow.
- **Evidence:**
  - Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift:68-74  [sig8:b6d7e83f] — Recommendations call `ranker.rank(...)` and take the top three without any learning step.
  - Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift:131-138  [sig8:c92a4f10] — Completions are logged to Core Data only; there is no call into `RecRanker.update` or `updateLearningRate`.
  - Packages/PulsumML/Sources/PulsumML/RecRanker.swift:107-135  [sig8:0de5f7ab] — Pairwise `update`, adaptive learning rate, and feedback APIs exist but are never invoked.
- **Upstream/Downstream:** UX assumes the ranker adapts as users accept/skip cards. Because weights never change, stale micro-moments keep resurfacing and any A/B improvements are impossible to measure.
- **Why This Is a Problem:** Violates the Phase 03 design (RecRanker should "learn from interaction logs") and blocks data-driven personalization; logged RecommendationEvents become dead data.
- **Suggested Diagnostics (no code):** Add temporary counters/logs for `RecRanker.update` invocations; run integration test that simulates accept/reject sequences and asserts weight changes.
- **Related Contract:** Phase 03 short report — Model Training & Optimization section states the ranker “updates from interaction logs”.

### BUG: Wellbeing coefficients invert recovery signals
- **ID:** BUG-20251026-0028
- **Severity:** S1
- **Area:** ML
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** Higher HRV or step z-scores make the Wellbeing Score fall, while elevated sleep debt makes it rise, contradicting intended recovery semantics.
- **Where/Scope:** StateEstimator initialization and target label computation.
- **Evidence:**
  - Packages/PulsumML/Sources/PulsumML/StateEstimator.swift:29-38  [sig8:6fb39d25] — Initial weights assign negative coefficients to `z_hrv` and `z_steps`, positive to `z_sleepDebt`.
  - Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:557-564  [sig8:4a10c2d7] — Target label multiplies HRV and steps by negative constants, causing gradient updates to reinforce the inverted relationship.
  - Phase 03 short report, Model Training & Optimization — specifies “low HRV and high sleep debt reduce the score and good sleep or activity lift it,” which the current math violates.
- **Upstream/Downstream:** ScoreBreakdown shows recovery metrics moving opposite to expectations; recommendations derived from the Wellbeing Score misinterpret improvements as regressions.
- **Why This Is a Problem:** Undermines user trust and breaks the narrative that better recovery signals raise wellbeing; ranker and guardrails consume the wrong signals.
- **Suggested Diagnostics (no code):** Plot score contributions after simulated days with high HRV vs. low HRV; add unit tests asserting coefficient signs; review gradient targets before deploying.
- **Related Contract:** Phase 03 short report — Model Training & Optimization and Model Refinement sections require sensible seed weights and interpretable contributions.

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

## Contract Checklist — Results
- **MISSING** — GPT requests must carry retrieval context (BUG-20251026-0004)
- **MISSING** — Voice journaling should recompute wellbeing and refresh UI (BUG-20251026-0005, BUG-20251026-0015)
- **MISSING** — Speech capture requires entitlement + microphone permission wiring (BUG-20251026-0003, BUG-20251026-0006, BUG-20251026-0026)
- **MISSING** — Privacy manifests for protected APIs (BUG-20251026-0002)
- **MISSING** — Liquid Glass hero delivered via Spline (BUG-20251026-0011)
- **MISSING** — Vector index safe for concurrent access (BUG-20251026-0012)
- **MISSING** — File I/O errors must be surfaced, not silently swallowed (BUG-20251026-0017, BUG-20251026-0018)
- **MISSING** — Foundation Models stub must match real API types (BUG-20251026-0019)
- **MISSING** — Modern speech backend for iOS 26 (BUG-20251026-0007)
- **MISSING** — Session lifecycle management prevents duplicate starts (BUG-20251026-0016)
- **MISSING** — Crisis detections must surface the mandated 911 escalation (BUG-20251026-0033)
- **MISSING** — Coach prompt/schema must align on canonical intent topics (BUG-20251026-0034)
- **MISSING** — Guardrail violations must not downgrade to SAFE (BUG-20251026-0035)
- **MISSING** — Cloud payload must carry topMomentId for retrieval grounding (BUG-20251026-0036)
- **PARTIAL** — Test coverage for core flows (BUG-20251026-0014, BUG-20251026-0025)

## Test Audit
- **PulsumTests/PulsumTests.swift** — Empty placeholder: single test with comment "Write your test here", no assertions
- **PulsumUITests/PulsumUITests.swift** — Launch-only scaffold: two tests (example launch, performance) with no flow assertions
- **Package test bundles** — Present in Packages/*/Tests/ with real tests (ChatGuardrailAcceptanceTests, LLMGatewayTests, etc.) but excluded from shared Xcode scheme (BUG-20251026-0014), so they never run when developer presses Test button in Xcode
- **Test-code gap:** Package tests exist and would catch BUG-20251026-0004, BUG-20251026-0008, BUG-20251026-0023 if they ran regularly

## Security/Privacy Notes
- API key leak (BUG-20251026-0001) must be remediated immediately before any distribution
- Privacy manifests absent (BUG-20251026-0002) block App Store/TestFlight submission per WWDC23
- Speech entitlement gap (BUG-20251026-0003) and missing microphone prompt (BUG-20251026-0006, BUG-20251026-0026) prevent lawful access to protected inputs
- Backup exclusion failures (BUG-20251026-0018) create HIPAA/GDPR violation risk with PHI data
- File descriptor leaks (BUG-20251026-0017) and concurrency issues (BUG-20251026-0012, BUG-20251026-0016) pose stability risks
- Core Data model has no attribute-level validation, relying on caller validation
- Crisis downgrade bug (BUG-20251026-0033) hides emergency guidance despite FM escalation, creating duty-of-care exposure
- Guardrail downgrades on `guardrailViolation` (BUG-20251026-0035) allow flagged content to reach GPT without crisis messaging

## Open Questions
- **Foundation Models APIs:** Are SpeechAnalyzer/SpeechTranscriber publicly available in iOS 26 SDK? (BUG-20251026-0007)
- **AFM Contextual Embeddings:** What "unsafe runtime code" prevented NLContextualEmbedding usage? (BUG-20251026-0020)
- **Spline Integration:** Is SplineRuntime framework included? Why isn't hero view implemented? (BUG-20251026-0011)
- **iOS Settings Deep Link:** What is the correct iOS 26 URL scheme for Apple Intelligence settings? (BUG-20251026-0010)
- **Production Deployment:** Has the exposed API key been used in any public builds or TestFlight distributions? (BUG-20251026-0001)

## Update Summary
- Added: 2 | Updated: 9 | Obsolete: 0 | Duplicates: 0

## Coverage Summary
- PulsumAgents {files_read:3, lines≈900}
- PulsumServices {files_read:4, lines≈1400}
- PulsumML {files_read:1, lines≈120}
- Docs {files_read:2, sections reviewed: instructions.md Safety Decision Handling; Docs/architecture copy.md Minimized Context}

## Evidence Index
- Packages/PulsumAgents/Sources/PulsumAgents/SafetyAgent.swift → FM crisis downgrade logic
- Packages/PulsumML/Sources/PulsumML/Safety/FoundationModelsSafetyProvider.swift → GuardrailViolation/refusal returning SAFE
- Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift → Prompt/schema mismatch and payload validator excluding topMomentId
- Packages/PulsumServices/Sources/PulsumServices/CoachPhrasingSchema.swift → Intent topic enum missing nutrition alignment
- Docs/architecture copy.md → Cloud payload contract (CoachLLMContext requires topMomentId)
- todolist.md → Canonical topic list for deterministic intent mapping
