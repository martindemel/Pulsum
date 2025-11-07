# CodeRabbit Validation Report

**Scan Context:** Manual review of Pulsum working tree @ 2025-10-26.  
**Docs Covered:** `architecture.md`, `todolist.md`, `bugs.md`, `agents.md`, `instructions.md`.  
**Swift Coverage:** Key modules in `PulsumAgents`, `PulsumServices`, `PulsumUI`, and Xcode project settings inspected to validate review feedback.

## Quick Readout
- BUG-CR-0001 — OpenAI API key is baked into `Info.plist`, exposing production credentials. (S0 Privacy/Security)
- BUG-CR-0002 — Ping payload validator assumes lowercase `ping` while the request builder emits uppercase `PING`, so any validation pass will always fail. (S2 Wiring)
- BUG-CR-0003 — SpeechService prints live transcript text in release builds, leaking PHI into device logs. (S1 Privacy/Security)
- BUG-CR-0004 — AgentOrchestrator’s legacy `recordVoiceJournal` never tears down the recording session when streaming throws, leaving the mic hot and skipping safety review. (S1 Wiring)
- BUG-CR-0005 — PulseView uses `UIImpactFeedbackGenerator` without importing UIKit, breaking the UI build. (S1 Build/UI)
- BUG-CR-0006 — `Pulsum.xcodeproj/project.pbxproj.backup` resurrects SplineRuntime wiring and deleted scripts; keeping it tracked invites accidental regressions. (S3 Project Hygiene)

---

## Pack Privacy & Secrets

### BUG: OpenAI API key baked into Info.plist
- **ID:** BUG-CR-0001
- **Severity:** S0
- **Area:** Privacy/Security
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** The main app target writes `OPENAI_API_KEY` into `Info.plist` via build settings, and `LLMGateway` loads it directly. Any IPA now contains the production key in plaintext, violating the requirement to keep secrets in the Keychain only.
- **Where/Scope:** `Pulsum.xcodeproj` build configurations; `LLMGateway`.
- **Evidence:**
  - `Pulsum.xcodeproj/project.pbxproj:470-538` — Both Debug and Release set `INFOPLIST_KEY_OPENAI_API_KEY = "$(OPENAI_API_KEY)"`, forcing the key into the bundle.
  - `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:142-168` — `bundledAPIKey` first looks up the Info entry and only later checks the environment or keychain.
- **Why This Is a Problem:** Instructions mandate secrets remain on-device (Keychain) and never ship in distributable artifacts (`instructions.md:10-18`). Shipping the key lets anyone extract it from the bundle and bill against the team’s OpenAI account.
- **Suggested Diagnostics (no code):** Build the app and run `strings Pulsum.app/Info.plist | rg OPENAI`; the key is visible. Remove the Info entry, inject short-lived tokens at runtime, and keep `LLMGateway` limited to keychain/environment sources.
- **Related Contract:** Privacy/secret-handling constraints in `instructions.md:10-18`; `bugs.md` existing S0 privacy issues call out the same risk.

### BUG: Speech transcripts logged in release builds
- **ID:** BUG-CR-0003
- **Severity:** S1
- **Area:** Privacy/Security
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** Each partial transcription is emitted through `print` with the user’s spoken text, so PHI lands in syslog and crash logs even in production builds.
- **Where/Scope:** `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift`.
- **Evidence:**
  - `SpeechService.swift:194-205` — Logs `"Transcript update..."` and `"Recognition completed"` unguarded before yielding to the stream.
- **Why This Is a Problem:** Voice journals are explicitly PHI and must stay on-device (`instructions.md:10-18`, `architecture.md:90-118`). Logs are readable via Console, diagnostics uploads, or shared crash reports, leaking sensitive content outside the secure store.
- **Suggested Diagnostics (no code):** Capture a release build on-device, start journaling, and observe the Console stream; transcripts appear verbatim. Wrap the logs in `#if DEBUG` or remove them entirely before shipping.
- **Related Contract:** Privacy guarantees in `architecture.md` (PII redaction & file protection) and `bugs.md` Pack Voice Journaling sections.

---

## Pack Cloud Diagnostics

### BUG: Ping validator rejects its own payload
- **ID:** BUG-CR-0002
- **Severity:** S2
- **Area:** Wiring
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** `validatePingPayload` requires the request body to contain `"content": "ping"` (lowercase) but `makePingRequestBody` emits `"PING"` (uppercase). Once validation is turned on (either locally or by the CodeRabbit reviewer’s suggested tests), the check fails 100% of the time, flagging healthy pings as malformed.
- **Where/Scope:** `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift`.
- **Evidence:**
  - `LLMGateway.swift:367-405` — Guard compares `content == "ping"`.
  - `LLMGateway.swift:655-666` — Builder hardcodes uppercase `"PING"`.
- **Why This Is a Problem:** The Settings screen relies on `LLMGateway.testAPIConnection()` to verify the API key. A failing validation aborts the flow even though the network call succeeded, leaving the user unable to confirm their key.
- **Suggested Diagnostics (no code):** Instrument `validatePingPayload` in the ping path (or add a temporary unit test) and observe that `.lowercased()` normalization fixes the false negatives.
- **Related Contract:** Cloud consent + diagnostics requirements outlined in `architecture.md:600-640`.

---

## Pack Voice Journaling & Speech

### BUG: Legacy voice journaling leaves mic active on errors
- **ID:** BUG-CR-0004
- **Severity:** S1
- **Area:** Wiring
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** If the speech stream throws (network hiccup, permission revocation), `AgentOrchestrator.recordVoiceJournal` exits before calling `finishVoiceJournalRecording`. The SpeechService session keeps listening, the mic indicator stays on, and safety evaluation never runs.
- **Where/Scope:** `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`.
- **Evidence:**
  - `AgentOrchestrator.swift:172-185` — Iterates the stream without `do/catch`, so any thrown error aborts before teardown.
  - `SentimentAgent.swift:100-118` — Shows the expected pattern (`do/catch`, `stop()` in the error path) that the orchestrator fails to mirror.
- **Why This Is a Problem:** Architecture requirements expect a begin → consume → finish sequence with guaranteed cleanup (`CLAUDE.md Voice Journal API notes). Skipping `finish` means the journal is never persisted and the safety guardrails never activate, leaving the system in an inconsistent state.
- **Suggested Diagnostics (no code):** Simulate a speech error (disable speech recognition mid-stream) while calling the legacy API; observe via debugger that `SentimentAgent.activeSession` never resets and `finishVoiceJournalRecording` is never invoked. Add `do/catch` with a `defer` to stop the session before rethrowing.
- **Related Contract:** Voice journal API migration guidance in `CLAUDE.md` and `bugs.md` Pack Voice Journaling warnings.

---

## Pack UI & Build Stability

### BUG: Missing UIKit import for haptic feedback
- **ID:** BUG-CR-0005
- **Severity:** S1
- **Area:** Build/UI
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** `PulseView` references `UIImpactFeedbackGenerator` twice (record/stop buttons) but the file only imports SwiftUI/Observation. The Swift build fails with “Cannot find 'UIImpactFeedbackGenerator' in scope” whenever the file is compiled.
- **Where/Scope:** `Packages/PulsumUI/Sources/PulsumUI/PulseView.swift`.
- **Evidence:**
  - `PulseView.swift:1-4` — Missing `import UIKit` or conditional wrapper.
  - `PulseView.swift:239-290` — `UIImpactFeedbackGenerator` used for start/stop haptics.
- **Why This Is a Problem:** The Pulse screen cannot compile, blocking the entire iOS target. The iOS 26 requirement includes tactile feedback, but it must be gated with `#if canImport(UIKit)` to build cleanly.
- **Suggested Diagnostics (no code):** Run `swift build`; compiler errors cite the missing type. Add `#if canImport(UIKit) import UIKit #endif` at the top or guard the haptic code.
- **Related Contract:** `instructions.md:46-73` earmarks PulseView as a core feature that must be buildable in production.

---

## Pack Project Hygiene

### BUG: Stale project backup keeps deleted Spline wiring alive
- **ID:** BUG-CR-0006
- **Severity:** S3
- **Area:** Project Config
- **Confidence:** High
- **Status:** Open
- **Symptom/Impact:** `Pulsum.xcodeproj/project.pbxproj.backup` is checked in with old SplineRuntime links and a removed shell script. Xcode can open the backup accidentally, reintroducing dependencies the main project intentionally deleted, causing linker failures or rogue build phases.
- **Where/Scope:** `Pulsum.xcodeproj/project.pbxproj.backup`.
- **Evidence:**
  - `project.pbxproj.backup:10-52` — Adds `SplineRuntime` to the frameworks list even though the live project no longer references it.
  - `project.pbxproj.backup:300-330` — Contains the removed Spline dSYM shell script that would run again if the backup is used.
- **Why This Is a Problem:** The instructions explicitly warn against stale scaffolding, and the reviewer removed SplineRuntime elsewhere. Keeping a second project file around makes it easy for teammates to edit the wrong file and unknowingly resurrect the dependency.
- **Suggested Diagnostics (no code):** Attempt to open the backup in Xcode; note the extra dependency + script. Delete the backup or move it outside the repo to keep a single source of truth.
- **Related Contract:** Repository hygiene expectations in `todolist.md` (Milestone 0/1 cleanup) and `bugs.md` documentation debt section.

