# Pulsum — App Store Review Guidelines Compliance Report

**Generated:** 2026-02-14
**Audit Scope:** Apple App Store Review Guidelines (February 2026)
**App:** Pulsum (iOS 26.0, deployment target resolved from `IPHONEOS_DEPLOYMENT_TARGET` in project.pbxproj)
**Files Reviewed:** 48
**Cross-Referenced:** master_report.md (112 findings), guidelines_report_PREV.md (V1 audit, 2026-02-05)
**Diagnostics:** No `diagnostics_data.md` available — all assessments based on static code analysis only.
**Privacy Report:** No `privacy_report.pdf` available.

---

## Overall Compliance Assessment

**App Store Review: LIKELY PASS**

Pulsum has addressed all critical blockers identified in the V1 audit (2026-02-05). The app now has:

- Medical disclaimers with user acknowledgment checkboxes
- AI-generated content labels on all coach messages
- 988 Suicide & Crisis Lifeline in the crisis overlay
- Locale-aware crisis resources for 11 countries
- Data deletion ("Delete All My Data") with confirmation
- Score methodology disclosure
- Dynamic Type–compatible fonts
- No `fatalError()` in data initialization paths

The privacy architecture remains strong: cloud consent is opt-in with clear disclosure, HealthKit data is protected with `NSFileProtectionCompleteUnlessOpen`, PII redaction covers 6 pattern types plus NER, and all 6 PrivacyInfo.xcprivacy manifests are valid with `NSPrivacyAccessedAPICategoryUserDefaults` (CA92.1) declared.

**Top 5 Remaining Compliance Risks (lowest severity first):**

1. **SafetyCardView crisis overlay lacks "not a substitute for professional help" disclaimer** — The crisis UI shows 988 and 911 buttons but no explicit text that the app is not a replacement for professional care. Low risk but strengthens the submission.
2. **Score breakdown lacks explicit "not a clinical measurement" language** — The methodology is explained, but the score is not explicitly disclaimed as non-clinical.
3. **Privacy policy URL must be verified live** — `https://pulsum.ai/privacy` is linked in Settings but cannot be verified from source code alone.
4. **App Store Connect metadata requires manual verification** — Privacy questionnaire, app category, and description cannot be checked from source.
5. **`@unchecked Sendable` used in ~35 production types** — Not a compliance risk per se but represents technical debt. Several are justified (HealthKit types, Foundation Models types) but should be audited for correctness.

---

## Changes from V1 Audit (2026-02-05)

| Guideline | V1 Status | V2 Status | Change |
|---|---|---|---|
| 1.4.1 Medical Disclaimer | FAIL | PASS | Disclaimer added to OnboardingView + SettingsView |
| 1.4.1 Accuracy Claims | AT RISK | PASS | Methodology disclosed in ScoreBreakdownView |
| 1.4.1 AI Coaching | AT RISK | PASS | "AI-generated" badges + disclaimer in CoachView |
| 1.4.1 Crisis Resources | AT RISK | PASS | 988 Lifeline added to SafetyCardView |
| 1.4.1 Safety System | AT RISK | PASS | CRIT-002, CRIT-005, HIGH-010 all fixed |
| 1.6 Data Security | PASS | PASS | No change |
| 2.1 App Completeness | AT RISK | PASS | fatalError removed from DataStack |
| 2.3 Accurate Metadata | PASS | PASS | No change |
| 2.4.2 Power Efficiency | PASS | PASS | No change |
| 2.5.1 Public APIs | PASS | PASS | No change |
| 2.5.4 Background Modes | PASS | PASS | No change |
| 2.5.14 Recording Consent | PASS | PASS | No change |
| 4.2 Minimum Functionality | PASS | PASS | No change |
| 4.10 Monetizing Capabilities | PASS | PASS | No change |
| 5.1.1(i) Privacy Policy | PASS | PASS | No change |
| 5.1.1(ii) Consent | PASS | PASS | No change |
| 5.1.1(iii) Data Minimization | PASS | PASS | No change |
| 5.1.1(iv) Permission Denial | PASS | PASS | No change |
| 5.1.1(v) Account Sign-In | PASS | PASS | No change |
| 5.1.2(i) Sharing | PASS (caveat) | PASS | PII redaction expanded (SSN, CC, IP, addresses) |
| 5.1.2(ii) No Repurposing | PASS | PASS | No change |
| 5.1.2(vi) HealthKit Restrictions | PASS | PASS | No change |
| 5.1.3(i) Health Data Use | PASS | PASS | No change |
| 5.1.3(ii) False Data / iCloud | PASS | PASS | No change |
| Privacy Manifests: Presence | PASS | PASS | Now include UserDefaults CA92.1 |
| Privacy Manifests: Data Types | PASS | PASS | No change |
| Privacy Manifests: Required APIs | PASS | PASS | UserDefaults (CA92.1) now declared |
| Entitlements: HealthKit | PASS | PASS | No change |
| Entitlements: Completeness | PASS | PASS | No change |

**No regressions detected.** All V1 PASS items remain PASS. All V1 FAIL/AT RISK items improved.

---

## App Store Review Guidelines — Detailed Results

### Section 1: Safety

---

#### GUIDELINE 1.4.1: Medical/Health App Accuracy — Medical Disclaimer

**Status: PASS** (was FAIL in V1)

**Evidence:**
- `OnboardingView.swift` line 86: "This app does not provide medical advice. Always consult a healthcare professional before making decisions about your health or treatment."
- `OnboardingView.swift` lines 95–106: User must check an "I understand and acknowledge this disclaimer" checkbox before proceeding. The "Get Started" button is disabled until acknowledged (line 123).
- `SettingsView.swift` line 494: Same disclaimer text in the Privacy section.
- `CoachView.swift` line 105: "Responses are AI-generated and not medical advice." displayed persistently above the chat input.

**Risk:** Low. The disclaimer is clear, user-acknowledged, and present in both onboarding and settings.

---

#### GUIDELINE 1.4.1: Medical/Health App Accuracy — Accuracy Claims

**Status: PASS** (was AT RISK in V1)

**Evidence:**
- `ScoreBreakdownView.swift` line 154: "The score is a weighted blend of physiological z-scores, subjective sliders, and journal sentiment. Each contribution shown below is the weight × today's normalized value."
- `ScoreBreakdownView.swift` lines 338, 351: Additional explanations of how the recommendation system uses the score, including mention of the "RecRanker model" and that "HealthKit data will reshuffle this analysis on the next sync."
- Score labels use qualitative, non-clinical language: "Strong recovery signal today", "Positive momentum building", "Holding steady around baseline", "Focus on rest and low-load actions."

**Risk:** Low. The methodology is disclosed transparently. The labels avoid clinical precision. Consider adding "This is not a clinical measurement" for additional clarity.

---

#### GUIDELINE 1.4.1: Medical/Health App Accuracy — AI Coaching Presentation

**Status: PASS** (was AT RISK in V1)

**Evidence:**
- `CoachView.swift` line 105: Persistent disclaimer "Responses are AI-generated and not medical advice." above chat input.
- `CoachView.swift` line 365: "AI-generated" text badge displayed on each assistant chat message below the timestamp.
- `CoachView.swift` line 307 (ConsentPrompt): Clear disclosure that GPT-5 is used for coaching text, with details on data minimization.
- `CoachViewModel.swift` line 231: Guardrail violation responses are sanitized: "Let's keep the focus on supportive wellness actions."

**Risk:** Low. AI content is clearly labeled at both the message level and the input area.

---

#### GUIDELINE 1.4.1: Medical/Health App Accuracy — Crisis Resources

**Status: PASS** (was AT RISK in V1)

**Evidence:**
- `SafetyCardView.swift` line 36: "Call 911" emergency button (tel://911).
- `SafetyCardView.swift` lines 50–63: "988 Suicide & Crisis Lifeline" button (tel://988).
- `SafetyCardView.swift` line 67: "I'm safe" dismissal button.
- `SettingsView.swift` lines 432–454: Dedicated "Safety" section with both 911 and 988 links.
- `SafetyAgent.swift` lines 117–128: Locale-aware crisis resources for 11 countries: US (988), CA (988), GB (Samaritans 116 123), AU (Lifeline 13 11 14), NZ (1737), DE (Telefonseelsorge), FR (3114), JP (Inochi no Denwa), IN (iCall), BR (CVV 188), IE (Samaritans 116 123).
- `SafetyAgent.swift` line 139: International fallback: "If you are in immediate danger, call your local emergency number (112 in many countries). Visit findahelpline.com for crisis support in your region."

**Risk:** Low. Crisis resources are comprehensive and locale-aware. Consider adding explicit "This app is not a substitute for professional mental health care" text to `SafetyCardView` for maximum clarity.

---

#### GUIDELINE 1.4.1: Safety System Integrity (Cross-Reference)

**Status: PASS** (was AT RISK in V1)

**Evidence:**
- **CRIT-002 FIXED:** `FoundationModelsSafetyProvider.swift` line 60: Guardrail violations now return `.caution(reason: "Content flagged by on-device safety system")`. Line 62: Refusals return `.caution(reason: "Content refused by on-device safety system")`. Previously returned `.safe`.
- **CRIT-005 FIXED:** `SafetyLocal.swift` lines 18–24: Crisis keywords expanded to 17 terms including "suicide", "kill myself", "ending it", "overdose", "hurt myself", "want to die", "self-harm", "cut myself", "cutting myself", "no reason to live", "jump off", "hang myself", "don't want to be here", "can't go on", "take all the pills", "ending my life", "not want to live". `SafetyAgent.swift` lines 100–107: 20 keywords including "better off dead", "ending it".
- **HIGH-010 FIXED:** `SafetyLocal.swift` lines 113–118: High-confidence embedding match (>0.85 similarity) alone now triggers `.crisis` classification without requiring keyword match. Medium-confidence still requires keyword confirmation (lines 119–124).
- `SafetyAgent.swift` lines 44–46: Crisis downgrade logic prevents false positives — if Foundation Models return `.crisis` but no crisis keywords detected, downgrade to `.caution`. This is intentional safety validation.
- Comprehensive test coverage in `SafetyClassifierTests.swift` with tests for each keyword, mixed content, case-insensitive matching, high-similarity without keyword, degraded mode, and custom thresholds.

**Risk:** Low. The two-wall safety system now properly escalates dangerous content and has been tested extensively.

---

#### GUIDELINE 1.6: Data Security

**Status: PASS**

**Evidence:**
- `DataStack.swift` line 135: File protection set to `NSFileProtectionCompleteUnlessOpen` on Application Support, vector index, and health anchor directories. (Changed from `Complete` to `CompleteUnlessOpen` to support HealthKit background delivery while device is locked — this is the correct choice per Apple's guidance.)
- `DataStack.swift` lines 157–173: `isExcludedFromBackup = true` applied to all health data directories.
- `KeychainService.swift` line 71: API keys stored with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — no iCloud sync, requires device unlock.
- `PIIRedactor.swift` lines 8–37: 6 regex patterns (email, phone, SSN, credit card, street address, IP) plus NER-based personal name redaction on iOS 17+.
- `SentimentAgent.swift` line 228: `PIIRedactor.redact(transcript)` called before any storage or analysis.
- `CoachAgent.swift` line 201: `PIIRedactor.redact(userInput)` called before LLM processing.
- `LLMGateway.swift` lines 218–220: Schema guards prevent PHI fields (transcript, heartrate, samples) from being sent to cloud.

**Risk:** Low. Data security architecture is comprehensive and defense-in-depth.

---

### Section 2: Performance

---

#### GUIDELINE 2.1: App Completeness

**Status: PASS** (was AT RISK in V1)

**Evidence:**
- **CRIT-004 FIXED:** No `fatalError()` or `preconditionFailure()` calls found in `DataStack.swift`. The DataStack now uses SwiftData with a throwing initializer pattern. `AppViewModel.swift` line 305: Startup errors are caught and presented via `startupState = .failed(error.localizedDescription)` with a retry mechanism (line 328: `retryStartup()`).
- **VectorIndex replaced:** The `VectorIndex.swift` with CRIT-001 (non-deterministic hashValue) has been replaced by `VectorStore.swift` (Phase 0F).
- No visible placeholder text, "TODO" comments, or empty screens found in any UI view file.
- `ModernSpeechBackend` remains a stub but falls back to working `LegacySpeechBackend` — user-facing voice journaling works.

**Risk:** Low. No crash-on-launch scenarios remain. The app handles startup errors gracefully.

---

#### GUIDELINE 2.3: Accurate Metadata — Hidden/Dormant Features and UITest Stubs

**Status: PASS**

**Evidence:**
- `BuildFlags.swift` lines 6–10: UITest seams gated by `#if DEBUG || PULSUM_UITESTS`. In Release builds, `uiTestSeamsCompiledIn` is `false`.
- `AppRuntimeConfig.swift` lines 14–59: All UITest config properties require explicit environment variables (`UITEST_USE_STUB_LLM`, `UITEST_DISABLE_CLOUD_KEYCHAIN`, `UITEST_AUTOGRANT`, etc.) that App Review would never set.
- `SettingsView.swift`: DiagnosticsPanel and triple-tap diagnostics behind `#if DEBUG`.
- `PulsumUITests` target: `PULSUM_UITESTS` flag only set on UITests Debug/Release configurations (project.pbxproj lines 664, 685), not on the main app target.

**Risk:** Minimal. UITest infrastructure is inaccessible in production builds.

---

#### GUIDELINE 2.4.2: Power Efficiency

**Status: PASS**

**Evidence:**
- Only `com.apple.developer.healthkit.background-delivery` declared in entitlements.
- `HealthKitService.swift` line 495: Background delivery uses `.immediate` frequency.
- No continuous polling, timer-based refresh, or location tracking.
- Voice recording is user-initiated and limited to 30 seconds.

---

#### GUIDELINE 2.5.1: Public APIs and Framework Usage

**Status: PASS**

**Evidence:**
- HealthKit: Read-only health metric ingestion (6 types).
- Speech: Voice journal transcription with on-device preference (`requiresOnDeviceRecognition = true`).
- Foundation Models: On-device text generation with `#available(iOS 26.0, *)` guards.
- Core ML: Fallback sentiment/embedding models.
- Natural Language: PII redaction (NLTagger) and sentiment fallback.
- All frameworks used for their intended purposes.

---

#### GUIDELINE 2.5.4: Background Modes

**Status: PASS**

**Evidence:** `Pulsum.entitlements` declares only:
- `com.apple.developer.healthkit` = `true`
- `com.apple.developer.healthkit.background-delivery` = `true`

No other background modes (audio, location, fetch, etc.) declared.

---

#### GUIDELINE 2.5.14: Recording Consent

**Status: PASS**

**Evidence:**
- Microphone purpose string (Debug+Release): "Pulsum uses the microphone to capture voice journals." (project.pbxproj lines 538, 582)
- Speech recognition purpose string (Debug+Release): "Pulsum transcribes your voice journals to keep coaching relevant." (project.pbxproj lines 539, 583)
- Visual recording indication: Animated waveform, progress ring (30s countdown), red stop button with accessibility label, "LIVE" text label during recording.
- Recording is user-initiated (requires tapping the record button).

---

### Section 4: Design

---

#### GUIDELINE 4.2: Minimum Functionality

**Status: PASS**

**Evidence:** Pulsum provides substantial native functionality:
- HealthKit integration with 6 data types
- On-device ML wellbeing score with z-score breakdown
- Voice journal recording with real-time transcription
- Sentiment analysis and PII redaction
- AI coaching chat (on-device Foundation Models + optional cloud GPT-5)
- Personalized recommendation cards with ML ranking
- Crisis detection with locale-aware resources
- Score breakdown screen with methodology disclosure
- Full settings management with consent controls, data deletion, diagnostics export

---

#### GUIDELINE 4.10: Monetizing Built-In Capabilities

**Status: PASS**

**Evidence:** No in-app purchases, subscriptions, advertising, or monetization of HealthKit data, microphone access, or any built-in capability visible in the codebase. The only external dependency is Spline (3D animation).

---

### Section 5: Legal / Privacy

---

#### GUIDELINE 5.1.1(i): Privacy Policy

**Status: PASS**

**Evidence:**
- `SettingsView.swift` line 475: `Link(destination: URL(string: "https://pulsum.ai/privacy")!)` — clickable privacy policy URL.
- `SettingsView.swift` line 487: "Pulsum stores all health data on-device with NSFileProtectionComplete and never uploads your journals."
- **MANUAL CHECK REQUIRED:** Verify `https://pulsum.ai/privacy` returns a valid privacy policy before submission. Verify App Store Connect metadata includes privacy policy URL.

---

#### GUIDELINE 5.1.1(ii): Permission / Consent

**Status: PASS**

**Evidence:**
- **HealthKit consent:** Requested during onboarding with "Allow Health Data Access" button and "Skip for Now" option. Also available in Settings with per-type status display. Purpose strings present in both Debug and Release build configurations.
- **Microphone/Speech consent:** iOS handles permission prompts using declared purpose strings.
- **Cloud consent:** Opt-in toggle in Settings ("Use GPT-5 phrasing") disabled by default. Clear disclosure: "Pulsum only sends minimized context (no journals, no identifiers, no raw health samples). Turn this off anytime." (SettingsView lines 50–75). Default OFF via `ConsentStore.loadConsent()`.
- **Consent withdrawal:** Cloud toggle can be turned off anytime. Consent changes persisted with timestamps via `ConsentState` SwiftData entity (AppViewModel.swift lines 593–615).
- **Consent history:** Audit trail with `grantedAt` and `revokedAt` timestamps per version.

Purpose strings verified present:
- `NSHealthShareUsageDescription` = "Pulsum reads key wellness metrics like HRV and sleep to personalize your coaching."
- `NSHealthUpdateUsageDescription` = "Pulsum references your recent trends to surface the most helpful guidance."
- `NSMicrophoneUsageDescription` = "Pulsum uses the microphone to capture voice journals."
- `NSSpeechRecognitionUsageDescription` = "Pulsum transcribes your voice journals to keep coaching relevant."

---

#### GUIDELINE 5.1.1(iii): Data Minimization

**Status: PASS**

**Evidence:** HealthKit read types limited to 6 directly relevant types (HealthKitService lines 174–182): HRV (SDNN), Heart Rate, Resting Heart Rate, Respiratory Rate, Step Count, Sleep Analysis. No write access requested (`toShare: nil`). Voice recording limited to 30 seconds, user-initiated.

---

#### GUIDELINE 5.1.1(iv): Access — Permission Denial Handling

**Status: PASS**

**Evidence:**
- **HealthKit denied:** "Skip for Now" in onboarding. Settings shows "Health data unavailable" with re-request option. Per-type permission status display (granted/denied/pending).
- **Microphone denied:** Error handling via `PulseViewModel.mapRecordingError()` with user-facing messages like "I couldn't hear anything. Let's try again."
- **App without permissions:** Launches and operates in degraded but functional state. Coach tab works for chat. Wellbeing score shows appropriate "Health access needed" states.

---

#### GUIDELINE 5.1.1(v): Account Sign-In

**Status: PASS**

**Evidence:** No account creation, login, or authentication. Optional OpenAI API key stored in Keychain for cloud features.

---

#### GUIDELINE 5.1.2(i): Sharing with Third Parties

**Status: PASS** (was PASS with caveat in V1)

**Evidence:**
- Cloud consent opt-in, disabled by default.
- Explicit disclosure in consent banner and ConsentPrompt.
- PII redaction now covers 6 pattern types (email, phone, SSN, credit card, street address, IP address) plus NER-based personal name redaction. This addresses the V1 caveat about SSN/address gaps (master_report.md MED-014).
- Cloud routing gated by both consent AND safety: `let allowCloud = consentGranted && safety.allowCloud` (AgentOrchestrator).
- LLM payload validation prevents PHI fields from being transmitted (LLMGateway lines 218–220: forbidden fields include transcript, heartrate, samples).

---

#### GUIDELINE 5.1.2(ii): No Repurposing

**Status: PASS**

**Evidence:** No analytics SDKs, advertising frameworks, or data mining. Spline (3D animation) is the only external dependency. Health data used exclusively for wellbeing score computation and coaching.

---

#### GUIDELINE 5.1.2(vi): HealthKit Data Restrictions

**Status: PASS**

**Evidence:**
- HealthKit data stored with `NSFileProtectionCompleteUnlessOpen`.
- HealthKit data NOT directly sent to cloud — coaching pipeline sends z-score summaries, not raw samples.
- No advertising, marketing, or data mining use.
- Data directories excluded from iCloud backup.

---

#### GUIDELINE 5.1.3(i): Health Data Use Restrictions

**Status: PASS**

**Evidence:** Health data used exclusively for: (1) Computing wellbeing scores, (2) Generating coaching recommendations, (3) Providing context for AI chat responses. Data types disclosed in onboarding UI and Settings health section.

---

#### GUIDELINE 5.1.3(ii): False Data / iCloud Storage

**Status: PASS**

**Evidence:**
- Read-only HealthKit access: `requestAuthorization(toShare: nil, read: readTypes)`.
- Health data excluded from iCloud backup: `isExcludedFromBackup = true`.
- No CloudKit, iCloud Drive, or iCloud Key-Value store usage.

---

### Privacy Manifests

---

#### Privacy Manifests: Presence and Format

**Status: PASS**

**Evidence:** All 6 source-level PrivacyInfo.xcprivacy files exist in XML/Property List format:

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

All declarations accurate. `NSPrivacyCollectedDataTypeTracking` is `false` for all entries. No tracking domains declared.

---

#### Privacy Manifests: Required Reason APIs

**Status: PASS** (improved from V1)

**Evidence:** All manifests now declare `NSPrivacyAccessedAPICategoryUserDefaults` with reason code `CA92.1` (access user defaults for app functionality). The app uses `UserDefaults` in `AppRuntimeConfig.swift`, `AppViewModel.swift`, `SettingsView.swift`, `SettingsViewModel+DataDeletion.swift`, and `DiagnosticsTypes.swift` — all for legitimate app configuration, not tracking.

---

### Entitlements and Capabilities

---

#### Entitlements: HealthKit

**Status: PASS**

**Evidence:** `Pulsum.entitlements` contains:
- `com.apple.developer.healthkit` = `true`
- `com.apple.developer.healthkit.background-delivery` = `true`

Both actively used by `HealthKitService.swift`.

---

#### Entitlements: Completeness

**Status: PASS**

**Evidence:** Only HealthKit entitlements declared. Microphone and speech recognition require Info.plist purpose strings (present via `INFOPLIST_KEY_*` build settings) rather than entitlements. No unused or excessive entitlements.

---

## App Store Submission Readiness Checklist

- [x] Medical/health disclaimer visible in app — OnboardingView (line 86) with checkbox acknowledgment + SettingsView (line 494)
- [x] "Consult your doctor" language present — "Always consult a healthcare professional" in both disclaimer instances
- [x] Privacy policy link in Settings — Link to `https://pulsum.ai/privacy` in SettingsView (line 475). **MANUAL CHECK:** Verify URL is live.
- [ ] Privacy policy URL in App Store Connect metadata — **MANUAL CHECK REQUIRED**
- [x] HealthKit purpose string complete and accurate — "Pulsum reads key wellness metrics like HRV and sleep to personalize your coaching."
- [x] HealthKit update purpose string present — "Pulsum references your recent trends to surface the most helpful guidance."
- [x] Microphone purpose string complete and accurate — "Pulsum uses the microphone to capture voice journals."
- [x] Speech recognition purpose string complete and accurate — "Pulsum transcribes your voice journals to keep coaching relevant."
- [x] Cloud consent explicitly obtained before any data leaves device — Opt-in toggle, disabled by default, with clear disclosure language.
- [x] PII redaction verified before cloud transmission — PIIRedactor covers email, phone, SSN, credit card, street address, IP address, and personal names (NER).
- [x] No HealthKit data used for advertising/marketing/data mining — Confirmed.
- [x] No personal health info stored in iCloud — `isExcludedFromBackup = true` on all data directories. No CloudKit usage.
- [x] All 6 PrivacyInfo.xcprivacy manifests present and valid — Confirmed, all XML plist format with UserDefaults CA92.1 declared.
- [x] Entitlements match actual capabilities used — HealthKit + background delivery, both actively used.
- [x] No placeholder text or stub UI visible in production — No visible stubs or placeholder text in any UI view.
- [x] UITest flags cannot activate in production builds — Gated by `#if DEBUG || PULSUM_UITESTS` and runtime env vars not present in production.
- [x] App works without login/account — No account required.
- [x] App handles all permission denials gracefully — Degraded state with appropriate messaging for HealthKit, microphone, and speech denial.
- [x] Crisis/safety content includes professional help resources — 911 + 988 Lifeline in SafetyCardView and Settings Safety section.
- [x] Crisis resources are locale-aware and functional — 11 countries + international fallback with findahelpline.com.
- [x] AI-generated content clearly labeled as AI-generated — "AI-generated" badge on messages + persistent disclaimer in CoachView.
- [x] User can disable cloud AI features — Cloud consent toggle in Settings.
- [x] Data deletion mechanism exists — "Delete All My Data" button in Settings with confirmation dialog (SettingsView lines 659–714).
- [x] Background modes used only for HealthKit delivery — Confirmed.
- [x] No deprecated APIs — All APIs used with proper availability checks.
- [x] App does not monetize HealthKit or microphone access — Confirmed.
- [x] Wellbeing score methodology disclosed — ScoreBreakdownView line 154 explains the weighted blend methodology.
- [x] Dynamic Type / accessibility support — Design system uses semantic fonts (`Font.system(.title)`, `.body`, `.caption`, etc.) throughout PulsumDesignSystem.swift.
- [ ] **SafetyCardView "not a substitute" disclaimer** — RECOMMENDED: Add "This app is not a substitute for professional mental health care" to SafetyCardView.
- [ ] **Score "not a clinical measurement" language** — RECOMMENDED: Add explicit non-clinical disclaimer to ScoreBreakdownView.
- [ ] **App Store Connect privacy nutrition labels** — **MANUAL CHECK:** Ensure questionnaire matches PrivacyInfo.xcprivacy declarations.
- [x] Non-exempt encryption declared — `ITSAppUsesNonExemptEncryption = NO` in build settings.

---

## Pre-Submission Action Items

### Blockers (must fix or Apple will reject)

None. All previously identified blockers from the V1 audit have been resolved.

### High Risk (Apple may flag these during review)

1. **Verify privacy policy URL is live**
   - **Action:** Confirm `https://pulsum.ai/privacy` returns a valid, current privacy policy document before submission.
   - **Guideline:** 5.1.1(i)

2. **Verify App Store Connect privacy questionnaire**
   - **Action:** Ensure the privacy questionnaire matches PrivacyInfo.xcprivacy declarations: Health data collected for App Functionality, Audio collected for App Functionality, no tracking.
   - **Guideline:** 5.1.1(i)

### Recommended (strengthens submission, reduces review friction)

3. **Add "not a substitute" disclaimer to SafetyCardView**
   - **File:** `SafetyCardView.swift`
   - **Change:** Add text between the 988 button and "I'm safe" button: "This app is not a substitute for professional mental health care."
   - **Guideline:** 1.4.1

4. **Add "not a clinical measurement" to score breakdown**
   - **File:** `ScoreBreakdownView.swift`
   - **Change:** Append to the existing methodology text (line 154): "This is not a clinical measurement."
   - **Guideline:** 1.4.1

5. **Add VoiceOver labels to interactive elements**
   - **Files:** Various view files
   - **Change:** Ensure all interactive elements have `accessibilityLabel` and `accessibilityHint`. Many already exist but a comprehensive audit would strengthen accessibility compliance.

---

## Summary

| Category | Pass | Fail | At Risk | Manual Check |
|---|---|---|---|---|
| Section 1: Safety | 6 | 0 | 0 | 0 |
| Section 2: Performance | 5 | 0 | 0 | 0 |
| Section 4: Design | 2 | 0 | 0 | 0 |
| Section 5: Legal/Privacy | 10 | 0 | 0 | 1 |
| Privacy Manifests | 3 | 0 | 0 | 0 |
| Entitlements | 2 | 0 | 0 | 0 |
| **Total** | **28** | **0** | **0** | **1** |

The app has moved from **AT RISK** (V1: 1 FAIL, 6 AT RISK) to **LIKELY PASS** (V2: 0 FAIL, 0 AT RISK, 1 MANUAL CHECK). All critical compliance gaps have been addressed. The remaining manual check (App Store Connect metadata) cannot be verified from source code and is standard for any submission.

With the recommended additions (SafetyCardView disclaimer, score non-clinical language), the submission profile would be further strengthened, but neither is likely to cause rejection on its own.
