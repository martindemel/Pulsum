# Pulsum — App Store Review Guidelines Compliance Report

**Generated:** 2026-02-05  
**Audit Scope:** Apple App Store Review Guidelines (November 2025)  
**App:** Pulsum (iOS 26+ wellness coaching)  
**Files Reviewed:** 42  
**Cross-Referenced:** master_report.md (78 findings, 142 files analyzed)

---

## Overall Compliance Assessment

**App Store Review: AT RISK**

Pulsum is well-engineered for privacy and consent, but has two categories of issues that create real rejection risk:

1. **Missing medical/health disclaimers** — Apple explicitly requires health apps to remind users to consult a doctor. Pulsum has zero such language anywhere in its UI. This is the single most likely cause of rejection.

2. **Safety system defects that create compliance exposure** — The crisis detection system has known false-negative paths (CRIT-002, CRIT-005 from master_report.md) and the SafetyCardView crisis UI lacks the 988 Suicide & Crisis Lifeline and a disclaimer that the app is not a substitute for professional help.

The app does many things right: cloud consent is opt-in with clear language, HealthKit data is properly protected, privacy manifests are complete, PII redaction is applied before cloud transmission, and all 6 PrivacyInfo.xcprivacy manifests are valid. These are not trivial — many health apps fail on exactly these points.

**Top 5 Compliance Risks (most likely to cause rejection):**

1. **No medical disclaimer anywhere in the app** — Apple guideline 1.4.1 explicitly requires "consult your doctor" language for health apps. Not present in any view.
2. **No "for informational/wellness purposes only" disclaimer** — The wellbeing score, sentiment analysis, and AI coaching could be mistaken for medical advice without a clear disclaimer.
3. **SafetyCardView crisis UI missing 988 Lifeline and professional-help disclaimer** — The crisis overlay only shows "Call 911" and an "I'm safe" button, with no mention of the 988 Suicide & Crisis Lifeline or that the app is not a substitute for professional help.
4. **AI-generated coaching responses not labeled as AI-generated** — Chat messages from GPT-5 or Foundation Models appear in the same format as any text, with no indication they are AI-generated.
5. **DataStack fatalError can cause unrecoverable crash loops** — If the Core Data store becomes corrupted, the app crashes on launch with no recovery path. Apple reviewers encountering this would reject for guideline 2.1.

---

## App Store Review Guidelines — Detailed Results

### Section 1: Safety

---

#### GUIDELINE 1.4.1: Medical/Health App Accuracy — Medical Disclaimer

**Status: FAIL**

**Evidence:** Searched all user-facing views: `OnboardingView.swift`, `PulseView.swift`, `CoachView.swift`, `SettingsView.swift`, `SafetyCardView.swift`, `ScoreBreakdownView.swift`, and `PulsumRootView.swift`. Grep for "medical", "disclaimer", "informational", "consult", "doctor", "professional", "not.*substitute" across all `.swift` files returned zero matches in UI-facing text. The only related hits are in `FoundationModelsCoachGenerator.swift` system prompt instructions telling the LLM to "avoid medical claims" — but this is backend instruction, not user-facing disclosure.

**Risk:** Apple explicitly states: "Apps should remind users to check with a doctor in addition to using the app and before making medical decisions." A health app that computes wellbeing scores from HRV, heart rate, and sleep data — and provides AI-generated coaching recommendations — without any medical disclaimer is a textbook 1.4.1 rejection.

**Remediation:**
- Add a persistent medical disclaimer to `OnboardingView.swift` welcome page (e.g., "Pulsum is for informational wellness purposes only. It is not a medical device and does not provide medical advice. Always consult your doctor before making health decisions.")
- Add a brief disclaimer footer to `CoachView.swift` chat area (e.g., "AI-generated wellness suggestions. Not medical advice.")
- Add a disclaimer section to `SettingsView.swift` Privacy section (e.g., "Pulsum is designed for general wellness and informational purposes. It is not intended to diagnose, treat, cure, or prevent any disease.")

---

#### GUIDELINE 1.4.1: Medical/Health App Accuracy — Accuracy Claims

**Status: AT RISK**

**Evidence:** The wellbeing score in `WellbeingScoreCard` (SettingsView.swift lines 1258-1320) displays a numeric score with interpretive labels: "Strong recovery" (≥1.5), "Positive momentum" (0.5–1.5), "Maintaining base" (-1–0.5), "Let's go gentle today" (<-1). The score computation methodology (StateEstimator linear regression on z-scored HealthKit features) is not disclosed to the user. The `ScoreBreakdownView` shows contributing factors but does not explain the mathematical basis.

The LLM system prompt (FoundationModelsCoachGenerator.swift line 24) instructs: "Use language like 'may help', 'consider', or 'notice'; never 'should', 'must', or medical claims." This is good backend practice but is not visible to the user.

**Risk:** Apple requires apps to "clearly disclose data and methodology to support accuracy claims relating to health measurements." The wellbeing score presents as a quantitative health measurement without methodology disclosure. While the labels are qualitative ("Positive momentum"), the numeric score could imply clinical precision.

**Remediation:**
- Add a brief methodology disclosure to `ScoreBreakdownView.swift` (e.g., "This score is a statistical estimate based on recent HealthKit data trends. It is not a clinical measurement.")
- Consider adding "Estimated" or "Trend" prefix to the score display label.

---

#### GUIDELINE 1.4.1: Medical/Health App Accuracy — AI Coaching Presentation

**Status: AT RISK**

**Evidence:** Chat messages from the AI coach (GPT-5 or Foundation Models) appear in `ChatBubble` (CoachView.swift lines 319-356) with a mint green background for assistant messages but no "AI-generated" label or indicator. The `ConsentPrompt` (CoachView.swift line 287) mentions GPT-5, but only when consent is not yet granted. Once enabled, there is no persistent indicator that responses are AI-generated.

Recommendation cards in `RecommendationCardView` (CoachView.swift lines 358-418) show a `sourceBadge` but this appears to be topic-based, not an AI disclosure.

**Risk:** Apple may flag AI-generated health recommendations that are not clearly identified as AI-generated, especially in a health context where users might interpret suggestions as professional advice.

**Remediation:**
- Add a small "AI" badge or "Powered by AI" indicator to assistant chat messages in `ChatBubble`.
- Add a persistent one-line disclaimer above the chat input area (e.g., "Responses are AI-generated and not medical advice").

---

#### GUIDELINE 1.4.1: Medical/Health App Accuracy — Crisis Resources

**Status: AT RISK**

**Evidence:** `SafetyCardView.swift` presents crisis content with a "Call 911" button and an "I'm safe" dismiss button. It does NOT:
- Mention the 988 Suicide & Crisis Lifeline
- State that the app is not a substitute for professional help
- Provide any alternative resources beyond 911

However, `SettingsView.swift` (lines 422-463) contains a dedicated "Safety" section with both a "dial 911" link and a "988 Suicide & Crisis Lifeline" link. This is good but the safety card overlay — which is the primary crisis intervention UI — is missing these resources.

The crisis message from `SafetyAgent.swift` (line 86) is: "If you're in the United States, call 911 right away." — which is US-centric (master_report.md MED-009).

**Risk:** A reviewer testing crisis scenarios would see the SafetyCardView without 988 resources. Apple could flag this as inadequate crisis resources for a mental health–adjacent app.

**Remediation:**
- Add 988 Suicide & Crisis Lifeline link to `SafetyCardView.swift` alongside the 911 button.
- Add text: "This app is not a substitute for professional mental health support."
- Update `SafetyAgent.swift` crisis message to include 988 and locale-aware guidance.

---

#### GUIDELINE 1.4.1: Safety System Integrity (Cross-Reference)

**Status: AT RISK**

**Evidence:** master_report.md documents two critical safety system defects:

- **CRIT-002:** `FoundationModelsSafetyProvider.swift` (lines 59-63) returns `.safe` when Apple's Foundation Models trigger guardrail violations or refusals. Content that Apple's own AI considers dangerous is classified as safe by Pulsum's Wall 1.
- **CRIT-005:** Crisis keyword lists in `SafetyLocal.swift` (5 keywords) and `SafetyAgent.swift` (5 keywords) are incomplete. Common crisis phrases like "want to die", "self-harm", "cutting myself" are not covered.
- **HIGH-010:** `SafetyLocal.swift` requires both embedding similarity AND keyword match for crisis classification, missing paraphrased crisis language.

**Risk:** These are not directly visible to a reviewer, but if a reviewer tests crisis scenarios with unlisted phrases, the app may respond with coaching instead of crisis resources. This is a safety liability that could trigger rejection and legal exposure.

**Remediation:**
- Fix CRIT-002: Return `.caution` or `.crisis` for guardrail violations in `FoundationModelsSafetyProvider.swift`.
- Fix CRIT-005: Expand keyword lists per CDC/SAMHSA crisis language patterns.
- Fix HIGH-010: Remove keyword requirement for high-confidence embedding matches.

---

#### GUIDELINE 1.6: Data Security

**Status: PASS**

**Evidence:**
- Core Data store uses `NSFileProtectionComplete` (`DataStack.swift` line 84): `description.setOption(FileProtectionType.complete as NSObject, forKey: NSPersistentStoreFileProtectionKey)`
- Directory-level file protection applied (`DataStack.swift` lines 122-143): `.protectionKey: FileProtectionType.complete`
- Backup exclusion applied to all health data directories (`DataStack.swift` lines 91-95): `resourceValues.isExcludedFromBackup = true`
- API keys stored in Keychain (via `KeychainService`)
- PII redaction applied before cloud transmission (`PIIRedactor.swift`)

**Risk:** Low. Data security implementation is solid. The `fatalError` in `DataStack.init` (CRIT-004) is a reliability risk, not a security risk per se, but could cause data loss if users delete the app to recover from crash loops.

---

### Section 2: Performance

---

#### GUIDELINE 2.1: App Completeness

**Status: AT RISK**

**Evidence:**
- `ModernSpeechBackend` is a stub (master_report.md HIGH-008/STUB-001) but falls back to a working `LegacySpeechBackend`, so the user-visible voice journaling feature works.
- No visible placeholder text, "TODO" comments, or empty screens found in any UI view files.
- `DataStack.init` has 3 `fatalError()` calls (master_report.md CRIT-004) at lines 70, 76, 101 that cause unrecoverable crashes on recoverable filesystem errors (disk full, corrupted store, missing directories).

**Risk:** If a reviewer's simulator has storage issues or the Core Data store is corrupted during testing, the app will crash on launch with no recovery path. While unlikely during review, this is a crash-on-launch scenario that would cause immediate rejection.

**Remediation:**
- Replace `fatalError()` calls in `DataStack.swift` with throwing initializer or graceful error recovery per CRIT-004 recommendation.

---

#### GUIDELINE 2.3: Accurate Metadata — Hidden/Dormant Features and UITest Stubs

**Status: PASS**

**Evidence:**
- UITest stub activation requires either `-ui_testing` launch argument or `UITEST=1` environment variable (via `AppRuntimeConfig.swift`).
- `BuildFlags.swift` uses compile-time gating: `#if DEBUG || PULSUM_UITESTS` for UITest seams. In Release builds, `uiTestSeamsCompiledIn` is `false`.
- `AppRuntimeConfig.useStubLLM` is `isUITesting || environment["UITEST_USE_STUB_LLM"] == "1"` — runtime check, but requires explicit env var that reviewers would not set.
- The `#if DEBUG` DiagnosticsPanel in `SettingsView.swift` (lines 1015-1079) is only compiled in Debug builds.
- Triple-tap to reveal diagnostics (`SettingsView.swift` line 538) is also behind `#if DEBUG`.

**Risk:** Minimal. UITest stubs are inaccessible in production builds. The `AppRuntimeConfig` runtime checks look at environment variables that App Review would never set.

**Note:** `KeychainService` UITest fallback (master_report.md LOW-014) is runtime-gated only (not `#if DEBUG`), but requires `AppRuntimeConfig.disableKeychain` which checks `isUITesting`. This is a defense-in-depth concern, not a compliance risk.

---

#### GUIDELINE 2.4.2: Power Efficiency

**Status: PASS**

**Evidence:**
- Background modes: Only `com.apple.developer.healthkit.background-delivery` declared in `Pulsum.entitlements`.
- HealthKit background delivery uses `.immediate` frequency (`HealthKitService.swift` line 489) which is Apple's recommended approach.
- No continuous polling, timer-based refresh, or location tracking.
- Voice recording is user-initiated and time-limited (30 seconds max).

---

#### GUIDELINE 2.5.1: Public APIs and Framework Usage

**Status: PASS**

**Evidence:**
- HealthKit used exclusively for health metric ingestion (HRV, heart rate, sleep, steps, respiratory rate).
- Speech framework used for voice journal transcription.
- Foundation Models used for on-device text generation with proper `#available(iOS 26.0, *)` guards.
- Core ML used for fallback sentiment/embedding models.
- Natural Language framework used for PII redaction and sentiment fallback.
- All frameworks used for their intended purposes.

---

#### GUIDELINE 2.5.4: Background Modes

**Status: PASS**

**Evidence:** Entitlements file (`Pulsum.entitlements`) declares only:
- `com.apple.developer.healthkit` — HealthKit access
- `com.apple.developer.healthkit.background-delivery` — HealthKit background delivery

No other background modes (audio, location, fetch, etc.) declared. Background delivery is used solely for HealthKit sample updates per `HealthKitService.enableBackgroundDelivery()`.

---

#### GUIDELINE 2.5.14: Recording Consent

**Status: PASS**

**Evidence:**
- Microphone purpose string: "Pulsum uses the microphone to capture voice journals." (project.pbxproj, both Debug and Release configurations)
- Speech recognition purpose string: "Pulsum transcribes your voice journals to keep coaching relevant." (project.pbxproj)
- Visual recording indication: `VoiceJournalButton` (PulseView.swift lines 231-360) shows:
  - Animated waveform visualization during recording
  - Progress ring counting down from 30 seconds
  - Red stop button with "Stop recording" accessibility label
  - "LIVE" text label during active recording
  - "Analyzing..." state with spinner after recording stops
- Recording is user-initiated (requires tapping the record button)

---

### Section 4: Design

---

#### GUIDELINE 4.2: Minimum Functionality

**Status: PASS**

**Evidence:** Pulsum provides substantial native functionality:
- HealthKit data integration with 6 data types
- On-device ML wellbeing score computation
- Voice journal recording with real-time transcription
- Sentiment analysis and PII redaction
- AI coaching chat (on-device Foundation Models + optional cloud GPT-5)
- Personalized recommendation cards with ML ranking
- Crisis detection and safety resources
- Full settings management with consent controls

This far exceeds a "wrapper" app.

---

#### GUIDELINE 4.10: Monetizing Built-In Capabilities

**Status: PASS**

**Evidence:** No monetization of HealthKit data, microphone access, or any other built-in capability. No in-app purchases, subscriptions, or advertising visible in the codebase. The app does not charge for access to health data or speech features.

---

### Section 5: Legal / Privacy

---

#### GUIDELINE 5.1.1(i): Privacy Policy

**Status: PASS**

**Evidence:** Privacy policy link present in `SettingsView.swift` (lines 473-483):
```swift
Link(destination: URL(string: "https://pulsum.ai/privacy")!) {
    HStack {
        Text("Privacy policy")
            .font(.pulsumBody)
            .foregroundStyle(Color.pulsumBlueSoft)
        // ...
    }
}
```

Additionally, the Privacy section includes the statement: "Pulsum stores all health data on-device with NSFileProtectionComplete and never uploads your journals." (line 485)

**Note:** Ensure `https://pulsum.ai/privacy` returns a valid, current privacy policy before submission. App Store Connect also requires a privacy policy URL in app metadata.

---

#### GUIDELINE 5.1.1(ii): Permission / Consent

**Status: PASS**

**Evidence:**
- **HealthKit consent:** Requested during onboarding (`OnboardingView.swift` lines 169-206) with "Allow Health Data Access" button and "Skip for Now" option. Also available in Settings (`SettingsView.swift` lines 267-292). Purpose string: "Pulsum reads key wellness metrics like HRV and sleep to personalize your coaching."
- **Microphone/Speech consent:** iOS handles permission prompts automatically using the declared purpose strings.
- **Cloud consent:** Opt-in toggle in Settings ("Use GPT-5 phrasing") with clear disclosure: "Pulsum only sends minimized context (no journals, no identifiers, no raw health samples). Turn this off anytime." (`SettingsView.swift` lines 48-73). Default is OFF (`ConsentStore.loadConsent()` returns `false` by default).
- **Consent withdrawal:** Cloud toggle can be turned off anytime. ConsentBannerView clearly states "You can turn this off anytime in Settings > Cloud Processing." Consent changes are persisted with timestamps via `ConsentState` Core Data entity.

---

#### GUIDELINE 5.1.1(iii): Data Minimization

**Status: PASS**

**Evidence:** HealthKit read types are limited to 6 directly relevant data types (`HealthKitService.swift` lines 171-179):
- Heart Rate Variability (SDNN)
- Heart Rate
- Resting Heart Rate
- Respiratory Rate
- Step Count
- Sleep Analysis

No write access requested (`requestAuthorization(toShare: nil, read: readTypes)`). No unnecessary data types. Voice recording is limited to 30 seconds and is user-initiated.

---

#### GUIDELINE 5.1.1(iv): Access — Permission Denial Handling

**Status: PASS**

**Evidence:**
- **HealthKit denied:** `OnboardingView.swift` allows "Skip for Now" (line 199). `SettingsView.swift` shows "Health data unavailable" banner and "Health access needed" card with re-request option. `WellbeingNoDataCard` shows appropriate messaging for each denial scenario.
- **Microphone denied:** `PulseViewModel.swift` `mapRecordingError()` (lines 229-241) handles errors including `noSpeechDetected` and `sessionAlreadyActive`. Error messages are displayed via `analysisError` property.
- **App functionality without permissions:** The app launches and operates in a degraded but functional state. The Coach tab works for on-device chat even without HealthKit. The wellbeing score shows "Health access needed" states.

---

#### GUIDELINE 5.1.1(v): Account Sign-In

**Status: PASS**

**Evidence:** No account creation, login, or authentication required anywhere in the app. `AppViewModel.swift` initializes directly to the main UI. The only credential is an optional OpenAI API key for cloud features, which is user-provided and stored in Keychain.

---

#### GUIDELINE 5.1.2(i): Sharing with Third Parties

**Status: PASS (with caveat)**

**Evidence:**
- Cloud consent is opt-in and disabled by default.
- Consent banner explicitly discloses: "Pulsum can optionally use GPT-5 to phrase brief coaching text. If you allow cloud processing, Pulsum sends only minimized context (no journals, no raw health data, no identifiers). PII is redacted." (`ConsentBannerView.swift` line 7, `CoachView.swift` line 287)
- PII redaction applied via `PIIRedactor.swift` before cloud transmission (emails and phone numbers via regex, personal names via NLTagger on iOS 17+).
- Cloud routing gated by both consent AND safety: `let allowCloud = consentGranted && safety.allowCloud` (`AgentOrchestrator.swift`)

**Caveat:** PII redaction has known gaps (master_report.md MED-014): SSN, street addresses, credit card numbers, IP addresses, and URLs with user identifiers are not redacted. While unlikely to appear in a voice journal, this is a defense-in-depth gap.

**Remediation:** Expand `PIIRedactor.swift` regex patterns to cover SSN, credit card, and other common PII formats per MED-014.

---

#### GUIDELINE 5.1.2(ii): No Repurposing

**Status: PASS**

**Evidence:** No analytics SDKs, advertising frameworks, or data mining visible in the codebase. The `Spline` package (3D animation) is the only external dependency. Health data is used exclusively for wellbeing score computation and coaching recommendation generation. No data export to third parties beyond the consent-gated OpenAI API for coaching phrasing.

---

#### GUIDELINE 5.1.2(vi): HealthKit Data Restrictions

**Status: PASS**

**Evidence:**
- HealthKit data is stored in Core Data with `NSFileProtectionComplete`.
- HealthKit data is NOT directly sent to the cloud. The LLM context is "minimized" — the coaching pipeline sends z-score summaries and topic context, not raw HealthKit samples.
- The consent banner explicitly states: "no raw health data" is sent.
- No advertising, marketing, or data mining use of HealthKit data.
- Data directories excluded from iCloud backup (`DataStack.swift` lines 91-95).

---

#### GUIDELINE 5.1.3(i): Health Data Use Restrictions

**Status: PASS**

**Evidence:** Health data is used exclusively for:
1. Computing wellbeing scores (via `StateEstimator` linear regression)
2. Generating personalized coaching recommendations (via `CoachAgent`)
3. Providing context for AI chat responses

Health data types are disclosed in the onboarding UI (`OnboardingView.swift` lines 132-147) and Settings health section (`SettingsView.swift` lines 227-246).

---

#### GUIDELINE 5.1.3(ii): False Data / iCloud Storage

**Status: PASS**

**Evidence:**
- App requests read-only HealthKit access: `requestAuthorization(toShare: nil, read: readTypes)` (`HealthKitService.swift` line 207). No data is written to HealthKit.
- Health data is excluded from iCloud backup: `isExcludedFromBackup = true` applied to all data directories (`DataStack.swift` lines 145-161).
- No CloudKit, iCloud Drive, or iCloud Key-Value store usage detected.

---

### Privacy Manifests

---

#### Privacy Manifests: Presence and Format

**Status: PASS**

**Evidence:** All 6 PrivacyInfo.xcprivacy files exist and are in XML/Property List format:

| Package | Location | Format | Valid |
|---|---|---|---|
| App Target | `Pulsum/PrivacyInfo.xcprivacy` | XML plist | Yes |
| PulsumML | `Packages/PulsumML/.../PrivacyInfo.xcprivacy` | XML plist | Yes |
| PulsumData | `Packages/PulsumData/.../PrivacyInfo.xcprivacy` | XML plist | Yes |
| PulsumServices | `Packages/PulsumServices/.../PrivacyInfo.xcprivacy` | XML plist | Yes |
| PulsumAgents | `Packages/PulsumAgents/.../PrivacyInfo.xcprivacy` | XML plist | Yes |
| PulsumUI | `Packages/PulsumUI/.../PrivacyInfo.xcprivacy` | XML plist | Yes |

---

#### Privacy Manifests: Collected Data Types

**Status: PASS**

**Evidence:**

| Manifest | Collected Types | Tracking | Purposes |
|---|---|---|---|
| App | Health, Audio, Text | No | App Functionality |
| PulsumData | Health, Text | No | App Functionality |
| PulsumServices | Health, Audio, Text | No | App Functionality |
| PulsumML | (none) | No | — |
| PulsumAgents | (none) | No | — |
| PulsumUI | (none) | No | — |

All declarations are accurate: the app collects health data (HealthKit), audio (microphone for voice journals), and text (journal transcripts). No tracking domains declared. `NSPrivacyCollectedDataTypeTracking` is `false` for all entries.

---

#### Privacy Manifests: Required Reason APIs

**Status: PASS**

**Evidence:** All manifests declare `NSPrivacyAccessedAPITypes` as an empty array. The app does not appear to use any APIs that require declared reasons (e.g., `UserDefaults`, file timestamp, disk space, or system boot time APIs are not used in ways requiring reasons). The standard `UserDefaults` usage is through `AppRuntimeConfig.runtimeDefaults` which uses standard suite names.

---

### Entitlements and Capabilities

---

#### Entitlements: HealthKit

**Status: PASS**

**Evidence:** `Pulsum.entitlements` contains:
- `com.apple.developer.healthkit` = `true`
- `com.apple.developer.healthkit.background-delivery` = `true`

Both are actively used by `HealthKitService.swift` (authorization requests and background delivery setup).

---

#### Entitlements: Completeness

**Status: PASS**

**Evidence:** Only HealthKit entitlements are declared. The app uses microphone and speech recognition, but these require Info.plist purpose strings (present) rather than entitlements. No unused or excessive entitlements.

---

## App Store Submission Readiness Checklist

- [ ] **Medical/health disclaimer visible in app** — NOT PRESENT. Must add to OnboardingView, CoachView, and SettingsView.
- [ ] **"Consult your doctor" language present** — NOT PRESENT. Must add before submission.
- [x] Privacy policy link in Settings and App Store metadata — Link to `https://pulsum.ai/privacy` in SettingsView. Verify URL is live before submission.
- [x] HealthKit purpose string complete and accurate — "Pulsum reads key wellness metrics like HRV and sleep to personalize your coaching."
- [x] Microphone purpose string complete and accurate — "Pulsum uses the microphone to capture voice journals."
- [x] Speech recognition purpose string complete and accurate — "Pulsum transcribes your voice journals to keep coaching relevant."
- [x] Cloud consent explicitly obtained before any data leaves device — Opt-in toggle, disabled by default, with clear disclosure language.
- [x] PII redaction verified before cloud transmission — PIIRedactor covers emails, phone numbers, personal names. Gaps exist for SSN/addresses (MED-014).
- [x] No HealthKit data used for advertising/marketing/data mining — Confirmed.
- [x] No personal health info stored in iCloud — `isExcludedFromBackup = true` on all data directories. No CloudKit usage.
- [x] All 6 PrivacyInfo.xcprivacy manifests present and valid — Confirmed, all XML plist format.
- [x] Entitlements match actual capabilities used — HealthKit + background delivery, both actively used.
- [x] No placeholder text or stub UI visible in production — ModernSpeechBackend stub is backend-only, not visible to users.
- [x] UITest flags cannot activate in production builds — Gated by `#if DEBUG` and runtime env vars not present in production.
- [x] App works without login/account — No account required.
- [x] App handles all permission denials gracefully — Degraded state with appropriate messaging for HealthKit, microphone, and speech denial.
- [ ] **Crisis/safety content includes professional help resources** — SafetyCardView missing 988 Lifeline and "not a substitute" disclaimer.
- [ ] **AI-generated content clearly labeled as AI-generated** — No AI labels on chat messages.
- [x] User can disable cloud AI features — Cloud consent toggle in Settings.
- [ ] **Data deletion mechanism exists** — No explicit "delete my data" option in Settings. Consider adding for GDPR and App Store compliance.
- [x] Background modes used only for HealthKit delivery — Confirmed.
- [x] No deprecated APIs — All APIs used with proper availability checks.
- [x] App does not monetize HealthKit or microphone access — Confirmed.
- [ ] **Wellbeing score methodology disclosed** — No disclosure of how the score is computed.
- [ ] **SafetyAgent crisis message internationalized** — Currently US-only ("call 911").
- [ ] **Dynamic Type / accessibility support** — All fonts use hardcoded sizes (master_report.md HIGH-006).

---

## Pre-Submission Action Items

### Blockers (must fix or Apple will reject)

1. **Add medical/health disclaimer to the app UI**
   - **Files:** `OnboardingView.swift`, `SettingsView.swift`
   - **Change:** Add a visible disclaimer: "Pulsum is for general wellness and informational purposes only. It does not provide medical advice, diagnosis, or treatment. Always consult your healthcare provider before making health decisions."
   - **Where:** OnboardingView welcome page (before "Get Started"), SettingsView Privacy section (below privacy policy link).
   - **Guideline:** 1.4.1

2. **Add "consult your doctor" language**
   - **Files:** `CoachView.swift` (near chat input), `ScoreBreakdownView.swift`
   - **Change:** Add text: "Always check with your doctor before making changes to your health routine."
   - **Guideline:** 1.4.1

3. **Add 988 Suicide & Crisis Lifeline to SafetyCardView**
   - **File:** `SafetyCardView.swift`
   - **Change:** Add a "988 Suicide & Crisis Lifeline" link button below the 911 button. Add text: "This app is not a substitute for professional mental health care."
   - **Guideline:** 1.4.1

4. **Fix DataStack fatalError crash paths**
   - **File:** `DataStack.swift` lines 70, 76, 101
   - **Change:** Replace `fatalError()` with throwing initializer or graceful error handling. Add recovery UI in `PulsumRootView.swift` (the `blocked` state already exists and can be extended).
   - **Guideline:** 2.1
   - **Cross-ref:** master_report.md CRIT-004

### High Risk (Apple may flag these during review)

5. **Label AI-generated content**
   - **File:** `CoachView.swift` (`ChatBubble` struct)
   - **Change:** Add a small "AI" indicator or footer text to assistant messages. Add a persistent disclaimer near the chat input: "Responses are AI-generated wellness suggestions, not medical advice."
   - **Guideline:** 1.4.1

6. **Fix Foundation Models safety provider false negatives**
   - **File:** `FoundationModelsSafetyProvider.swift` lines 59-63
   - **Change:** Return `.caution(reason: "Content flagged by on-device safety system")` instead of `.safe` for guardrail violations and refusals.
   - **Guideline:** 1.4.1
   - **Cross-ref:** master_report.md CRIT-002

7. **Expand crisis keyword lists**
   - **Files:** `SafetyLocal.swift` (config default), `SafetyAgent.swift` lines 12-18
   - **Change:** Add "want to die", "self-harm", "cutting myself", "overdose", "no reason to live", "don't want to be here", "hurt myself", "ending my life" per CDC/SAMHSA patterns.
   - **Guideline:** 1.4.1
   - **Cross-ref:** master_report.md CRIT-005

8. **Add wellbeing score methodology disclosure**
   - **File:** `ScoreBreakdownView.swift` or `SettingsView.swift`
   - **Change:** Add a brief explanation: "Your wellbeing score is an estimated trend indicator based on statistical patterns in your recent health data. It is not a clinical measurement."
   - **Guideline:** 1.4.1

9. **Expand PII redaction coverage**
   - **File:** `PIIRedactor.swift`
   - **Change:** Add regex patterns for SSN (`\d{3}-\d{2}-\d{4}`), credit card numbers, and URLs with user identifiers.
   - **Guideline:** 5.1.2(i)
   - **Cross-ref:** master_report.md MED-014

### Recommended (strengthens submission, reduces review friction)

10. **Add data deletion option to Settings**
    - **File:** `SettingsView.swift`
    - **Change:** Add a "Delete All My Data" button that clears Core Data store, vector index, and Keychain entries. Important for GDPR and demonstrates respect for user data.
    - **Guideline:** 5.1.1(ii)

11. **Internationalize crisis resources**
    - **Files:** `SafetyAgent.swift` line 86, `SafetyCardView.swift`
    - **Change:** Use locale-aware crisis resource information. Add "Contact your local emergency services" for non-US users. Consider Crisis Text Line (text HOME to 741741) as an additional resource.
    - **Cross-ref:** master_report.md MED-009

12. **Support Dynamic Type**
    - **File:** `PulsumDesignSystem.swift` lines 63-83
    - **Change:** Replace `Font.system(size:)` with semantic font styles or `@ScaledMetric` wrappers.
    - **Cross-ref:** master_report.md HIGH-006

13. **Add VoiceOver labels to key interactive elements**
    - **Files:** Various view files
    - **Change:** Audit and add `accessibilityLabel` and `accessibilityHint` to all interactive elements. Many already exist (VoiceJournalStartButton, CoachSendButton, etc.) but a comprehensive audit would strengthen the submission.

14. **Verify privacy policy URL is live**
    - **Action:** Confirm `https://pulsum.ai/privacy` returns a valid, current privacy policy document before submission.

15. **Add App Store Connect privacy nutrition labels**
    - **Action:** When submitting, ensure the App Store Connect privacy questionnaire matches the PrivacyInfo.xcprivacy declarations (Health data collected for App Functionality, Audio collected for App Functionality, no tracking).

---

## Summary

| Category | Pass | Fail | At Risk | N/A |
|---|---|---|---|---|
| Section 1: Safety | 1 | 1 | 4 | 0 |
| Section 2: Performance | 4 | 0 | 1 | 0 |
| Section 4: Design | 2 | 0 | 0 | 0 |
| Section 5: Legal/Privacy | 10 | 0 | 1 | 0 |
| Privacy Manifests | 3 | 0 | 0 | 0 |
| Entitlements | 2 | 0 | 0 | 0 |
| **Total** | **22** | **1** | **6** | **0** |

The single FAIL (missing medical disclaimer) is the highest-priority item. It is also the easiest to fix — adding a few lines of text to 2-3 view files. The AT RISK items require more substantial but still manageable changes. With the blockers addressed, this app has a strong submission profile: excellent privacy architecture, proper consent flows, clean entitlements, and valid privacy manifests.
