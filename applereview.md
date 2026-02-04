# Pulsum Apple Documentation Review

Date: 2026-02-03
Scope: repo-wide compliance checks against Apple Developer Documentation for Privacy Manifests, HealthKit, Speech, AVAudioSession, and Foundation Models.

## Apple Documentation Consulted (high-level)

- Privacy manifest files (create/add/describe data use; required reasons API) — Bundle Resources docs.
- Speech framework authorization and live recognition (SFSpeechRecognizer, SFSpeechRecognitionRequest).
- HealthKit authorization, availability, and long‑running queries (HKHealthStore, HKObserverQuery, HKAnchoredObjectQuery).
- File protection and iCloud backup exclusion (URLResourceValues.isExcludedFromBackup, URLFileProtection.complete).
- Foundation Models availability (SystemLanguageModel.availability; availability states and UI fallbacks).

## Findings (mismatches or risky gaps vs Apple docs)

### 1) Privacy manifests declare no collected data types

- **What Apple docs say:** Privacy manifest files must describe the data your app collects and the required‑reason APIs it uses. Data collection is recorded in `NSPrivacyCollectedDataTypes`. Apps and SDKs should report collected data categories. 
- **What I found (original):** All privacy manifests are present but `NSPrivacyCollectedDataTypes` is empty in:
  - `Pulsum/PrivacyInfo.xcprivacy`
  - `Packages/PulsumUI/Sources/PulsumUI/PrivacyInfo.xcprivacy`
  - `Packages/PulsumServices/Sources/PulsumServices/PrivacyInfo.xcprivacy`
  - `Packages/PulsumData/Sources/PulsumData/PrivacyInfo.xcprivacy`
  - `Packages/PulsumAgents/Sources/PulsumAgents/PrivacyInfo.xcprivacy`
  - `Packages/PulsumML/Sources/PulsumML/PrivacyInfo.xcprivacy`
- **Why this conflicts:** The app collects HealthKit data, microphone audio (transient), speech transcripts, and derived health metrics, which are data categories that should be declared. The current manifests don’t reflect that collection.
- **Impact:** App Store review or privacy report generation can be inconsistent with actual data use. It also risks mismatch with App Store privacy labels.
- **Action:** Populate `NSPrivacyCollectedDataTypes` for the relevant targets with Health, Audio/Voice, and other applicable categories (including derived analytics if stored). Verify each package manifest only declares what that module actually collects.
- **Status:** **Partially completed.** Updated collected data types in:
  - `Pulsum/PrivacyInfo.xcprivacy`
  - `Packages/PulsumServices/Sources/PulsumServices/PrivacyInfo.xcprivacy`
  - `Packages/PulsumData/Sources/PulsumData/PrivacyInfo.xcprivacy`
  - **Outstanding:** `Packages/PulsumUI/Sources/PulsumUI/PrivacyInfo.xcprivacy`, `Packages/PulsumAgents/Sources/PulsumAgents/PrivacyInfo.xcprivacy`, `Packages/PulsumML/Sources/PulsumML/PrivacyInfo.xcprivacy`

### 2) Privacy manifest declares required‑reason API usage without evidence

- **What Apple docs say:** Only list `NSPrivacyAccessedAPITypes` entries for required‑reason APIs your app actually uses.
- **What I found:** Manifests declare `NSPrivacyAccessedAPICategoryFileTimestamp` with reason `C617.1`, but I didn’t find usage of file timestamp APIs in the code paths reviewed (no `fileCreationDate`, `fileModificationDate`, or similar resource keys).
- **Why this conflicts:** Over‑declaring required‑reason APIs can be inaccurate and can trigger App Store review questions. 
- **Action:** Audit the codebase for file timestamp access. If not used, remove this entry; if used, document the specific API calls and keep the reason aligned.
- **Status:** **Outstanding.** No changes applied yet.

### 3) Speech API misuse: setting a read‑only property

- **What Apple docs say:** `SFSpeechRecognizer.supportsOnDeviceRecognition` is a read‑only property used to check availability. On‑device enforcement is done via `SFSpeechRecognitionRequest.requiresOnDeviceRecognition`.
- **What I found:** `LegacySpeechBackend` assigns `recognizer?.supportsOnDeviceRecognition = true`.
  - File: `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift` (LegacySpeechBackend init)
- **Why this conflicts:** This is not a settable property in Apple’s API. If this compiles via extensions or conditional builds, it risks diverging from the standard API or failing on SDK updates.
- **Action:** Remove the assignment and rely on `recognitionRequest.requiresOnDeviceRecognition` to enforce on‑device recognition. Keep `supportsOnDeviceRecognition` as a read‑only check.

### 4) “On‑device” promise vs actual speech recognition behavior

- **What Apple docs say:** Speech recognition may use Apple servers unless you explicitly require on‑device recognition and the device supports it. You should avoid misleading copy about where processing happens.
- **What I found:** `SpeechService` sets `request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition`. If the device does not support on‑device recognition, it allows server‑side recognition. However, Info.plist strings state transcription is “on‑device.”
  - File: `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift` (requiresOnDeviceRecognition assignment)
  - File: `Pulsum.xcodeproj/project.pbxproj` (usage descriptions)
- **Why this conflicts:** The app copy promises on‑device processing, but the runtime path can fall back to server‑based recognition.
- **Action:** Either (a) enforce `requiresOnDeviceRecognition = true` and fail gracefully when unsupported, or (b) adjust usage descriptions to avoid “on‑device” guarantees and add user messaging/consent for server processing.

### 5) HealthKit authorization requested automatically at startup

- **What Apple docs say:** Request access to protected resources at the time the user needs the feature; avoid prompting at launch without context.
- **What I found:** `DataAgent.start()` always calls `healthKit.requestAuthorization()` and is invoked during app startup.
  - File: `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`
  - File: `Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift` (startup triggers orchestrator start)
- **Why this conflicts:** This can prompt users before they actively attempt to use Health features, which is discouraged by Apple’s privacy guidance.
- **Action:** Defer HealthKit authorization until a user explicitly enters a feature that needs it (or use `HealthKitUI`’s `healthDataAccessRequest` modifier in a user‑initiated flow).
- **Status:** **Completed.** `DataAgent.start()` no longer requests authorization at startup; authorization is deferred to explicit user actions.

### 6) HealthKit read authorization inference is not reliable

- **What Apple docs say:** HealthKit doesn’t tell you whether read permission was denied; absent data can appear as “no data” instead of “denied.”
- **What I found:** `probeReadAuthorization` runs a sample query and returns `.authorized` if there’s no error. This can misreport read access.
  - File: `Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift`
- **Why this conflicts:** This approach treats “no error” as authorization, but HealthKit’s privacy model intentionally obscures read denial. 
- **Action:** Treat read access as “unknown” unless the user explicitly granted it via a confirmed authorization path; rely on `getRequestStatusForAuthorization` for whether a prompt is needed, and handle “no data” as a normal case.
- **Status:** **Completed.** The probe now returns `.authorized` only when actual samples are present; `.errorNoData` and empty results map to `.notDetermined`.

### 7) Foundation Models availability handling is incomplete

- **What Apple docs say:** Use `SystemLanguageModel.availability` and handle all unavailability cases explicitly, including `.deviceNotEligible`, `.appleIntelligenceNotEnabled`, and `.modelNotReady`.
- **What I found:** `FoundationModelsAvailability.checkAvailability()` handles `.appleIntelligenceNotEnabled` and `.modelNotReady`, but does not map `.deviceNotEligible` to the `unsupportedDevice` state and falls back to `.unknown`.
  - File: `Packages/PulsumML/Sources/PulsumML/AFM/FoundationModelsAvailability.swift`
- **Why this conflicts:** The UI may misrepresent unsupported devices as “unknown” instead of telling users their device is ineligible.
- **Action:** Explicitly map `.unavailable(.deviceNotEligible)` to `unsupportedDevice` and expand unknown handling. Consider showing the recommended “model not ready” state while downloading.

### 8) Foundation Models safety feedback path appears missing

- **What Apple docs say:** For generative AI features, provide a way for users to report potentially harmful output (Foundation Models safety guidance).
- **What I found:** I didn’t find a user‑visible “report content” or safety feedback entry in Settings or Coach UI; only diagnostics export exists.
  - Files: `Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift` (diagnostics export only)
- **Why this conflicts:** Apple’s guidance expects a feedback pathway for safety issues when using generative models.
- **Action:** Add a lightweight “Report a concern” action (e.g., mail or feedback form) and log minimal, privacy‑safe context.

## Notes (aligned with Apple docs)

- HealthKit availability checks are present (`HKHealthStore.isHealthDataAvailable()`).
- Usage description strings for HealthKit, Microphone, and Speech recognition exist in build settings.
- File protection uses `FileProtectionType.complete` for Application Support directories.
- Backup exclusion uses `URLResourceValues.isExcludedFromBackup`, consistent with iCloud backup guidance.

## Suggested Next Steps

1. Finish privacy manifest updates for UI/Agents/ML and confirm required‑reason API entries are accurate.
2. Fix Speech API property usage and align on‑device promises with runtime behavior.
3. Make Foundation Models availability messaging exhaustive.
4. Add a user‑visible safety feedback action for AI output.
