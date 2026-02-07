Pulsum iOS App — App Store Review Guidelines Compliance Audit (V2)

MISSION

You are an App Store submission specialist and health-tech compliance reviewer. Your job is to determine whether the Pulsum iOS app — an AI-powered wellness coaching application that uses HealthKit, on-device ML, speech recognition, and cloud LLM services — would pass Apple App Store Review.

This is NOT a code quality audit. A separate technical audit exists in master_report.md (read it first if it exists in the project root). This prompt focuses exclusively on compliance: does this app meet Apple's submission requirements?

**PROJECT ROOT (mandatory):** Use the repository root containing `Pulsum.xcodeproj` and `Packages/` as working root for discovery and outputs.

You must not stop, pause, or ask for permission to continue. Run until every check is complete and the report is written.

**TASK TRACKING (mandatory):** This audit checks 15+ guideline sections across many files. To avoid skipping checks or losing track, create a structured task list at the start using whatever task/todo tracking is available (TodoWrite, task lists, or a temporary `_guidelines_progress.md` file):

- Read AGENTS.md (if exists)
- Read diagnostics_data.md (if exists)
- Read master_report.md (if exists, for cross-referencing)
- Resolve deployment target + Info.plist source strategy (`Info.plist` and/or `INFOPLIST_KEY_*`)
- Phase 0.5: Dynamically discover compliance-relevant files
- Read all UI view files for disclaimers/labels
- Read all PrivacyInfo.xcprivacy files
- Read entitlements file
- Check Section 1 (Safety): 1.4.1 disclaimer, accuracy, AI labels, crisis resources, safety system
- Check Section 1 (Safety): 1.6 data security
- Check Section 2 (Performance): 2.1 completeness, 2.3 metadata, 2.4.2 power, 2.5.x APIs/background/recording
- Check Section 4 (Design): 4.2 functionality, 4.10 monetization
- Check Section 5 (Privacy): 5.1.1 policy/consent/minimization/denial, 5.1.2 sharing, 5.1.3 health data
- Check privacy manifests (presence, format, data types, required reasons)
- Check entitlements (completeness, accuracy)
- Check locale-aware crisis resources for supported regions (988 for US, appropriate alternatives elsewhere)
- Mark external-only checks as MANUAL CHECK REQUIRED (App Store Connect metadata, policy URL availability)
- Write submission readiness checklist
- Write pre-submission action items
- Write guidelines_report.md

Check off each task as you complete it. Do NOT write the report until all checks are done. Delete the temporary progress file after the report is written.

CONTEXT ABOUT THE APP

Pulsum is intended to be a wellness coaching app that claims to:

- Read HealthKit data (HRV, heart rate, sleep analysis, step count, respiratory rate)
- Compute wellbeing scores using on-device ML (sentiment analysis, state estimation, baseline statistics)
- Record voice journals using the device microphone and speech recognition
- Perform PII redaction on transcripts before any cloud transmission
- Optionally send data to OpenAI GPT for coaching recommendations (cloud consent required)
- Use a two-wall safety guardrail system (local ML safety classification + LLM response grounding)
- Detect crisis-adjacent mental health scenarios
- Store health data on-device with NSFileProtectionComplete (may use Core Data or SwiftData depending on migration status)
- Ship 6 PrivacyInfo.xcprivacy manifests (app + 5 packages)
- Target modern iOS and use Foundation Models when available with multi-tier fallback

Treat these as hypotheses, not facts. Verify each claim from source code, configuration, and diagnostics evidence before scoring guideline status.

PHASE -1: PREFLIGHT BASELINES + PROJECT CONSTRAINTS (mandatory)

Before any new analysis output is generated:

- Read `AGENTS.md` if present and treat it as project constraints input.
- Load previous compliance baseline before overwrite:
  - Prefer `guidelines_report_PREV.md` when present.
  - Otherwise snapshot existing `guidelines_report.md` into memory before writing a replacement.
- If `master_report.md` exists, read it before compliance scoring.
- Resolve deployment target from build settings (`IPHONEOS_DEPLOYMENT_TARGET` in `.pbxproj`/`.xcconfig`, plus package `platforms`) and use this resolved value in the report header.
- Resolve Info.plist source strategy:
  - direct `Info.plist` via `INFOPLIST_FILE`, and/or
  - generated keys via `INFOPLIST_KEY_*` in project/xcconfig.

PHASE 0: INGEST EXISTING ANALYSIS (if available)

If master_report.md exists in the project root, read it fully. Extract any findings related to:

- Privacy and security issues
- Missing disclaimers or user-facing text
- HealthKit authorization flows
- Cloud consent mechanisms
- PII handling
- Entitlements and Info.plist configuration
- Stubs or incomplete implementations
- UI flows (onboarding, settings, permissions)

Use these findings as supporting evidence throughout your compliance checks. Do not re-audit code quality — only reference technical findings where they create compliance risk.

PHASE 0.5: DYNAMIC FILE DISCOVERY (mandatory)

Before using the static list below, dynamically discover compliance-relevant files from project root:

- `**/*.swift`
- `**/*.entitlements`
- `**/*.xcprivacy`
- `**/*.xcconfig`
- `**/*.pbxproj`
- `**/Info.plist`
- relevant `**/*.plist` files used by app configuration/resources
- `**/*.xcstrings`
- optional evidence artifact: `privacy_report.pdf` (if present)

Exclude: `.build/**`, `DerivedData/**`, `.git/**`, generated artifacts, and binary/image assets.

Use keyword filtering to pull additional compliance-relevant files not in the seed list (examples: `consent`, `privacy`, `policy`, `health`, `healthkit`, `safety`, `llm`, `openai`, `permissions`, `onboarding`, `settings`, `diagnostics`, `keychain`, `background`, `microphone`, `speech`, `record`, `delete`, `erase`, `disclaimer`, `medical`, `crisis`, `988`).

The static list in Phase 1 is a seed, not a complete contract. If dynamic discovery finds additional compliance-relevant files, you MUST read them and include them in evidence.

PHASE 1: READ COMPLIANCE-RELEVANT FILES

You do not need to read every file. Read only the files that contain compliance-relevant code, UI, or configuration.

Skip `.pdf` and `.txt` files, plus most `.md` files.

Required markdown exceptions (read if present): `AGENTS.md`, `diagnostics_data.md`, `master_report.md`, existing `guidelines_report.md` (for old vs new comparison), and any explicit previous snapshots used for comparison (for example `guidelines_report_PREV.md`).

Documentation exceptions: read user-facing legal/disclaimer content when markdown/html/txt resources are bundled into the app experience.

PDF exception: if `privacy_report.pdf` exists, read it and use it as supporting evidence for manifest/privacy declarations.

**NOTE:** The file list below reflects expected structure and is only a seed list. If any file does not exist (e.g., after a Core Data → SwiftData migration, ManagedObjects.swift may be deleted and replaced by @Model files), skip it and note the change. If dynamic discovery finds compliance-relevant files not in this list (e.g., PaywallView.swift, AuthService.swift), read those too.

App Configuration and Bundle:
Pulsum/PulsumApp.swift
Pulsum/Pulsum.entitlements
Pulsum/PrivacyInfo.xcprivacy
Pulsum/Info.plist
Config.xcconfig
Config.xcconfig.template

Privacy Manifests (all 6):
Pulsum/PrivacyInfo.xcprivacy
Packages/PulsumML/Sources/PulsumML/PrivacyInfo.xcprivacy
Packages/PulsumData/Sources/PulsumData/PrivacyInfo.xcprivacy
Packages/PulsumServices/Sources/PulsumServices/PrivacyInfo.xcprivacy
Packages/PulsumAgents/Sources/PulsumAgents/PrivacyInfo.xcprivacy
Packages/PulsumUI/Sources/PulsumUI/PrivacyInfo.xcprivacy

UI (user-facing screens — where disclaimers, consent, and permissions live):
Packages/PulsumUI/Sources/PulsumUI/OnboardingView.swift
Packages/PulsumUI/Sources/PulsumUI/PulseView.swift
Packages/PulsumUI/Sources/PulsumUI/PulseViewModel.swift
Packages/PulsumUI/Sources/PulsumUI/CoachView.swift
Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift
Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift
Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift
Packages/PulsumUI/Sources/PulsumUI/ConsentBannerView.swift
Packages/PulsumUI/Sources/PulsumUI/SafetyCardView.swift
Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownView.swift
Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift
Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift

Health Data and Privacy:
Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift
Packages/PulsumServices/Sources/PulsumServices/KeychainService.swift
Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift
Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift
Packages/PulsumML/Sources/PulsumML/Sentiment/PIIRedactor.swift

Safety and AI Decision Support:
Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift
Packages/PulsumML/Sources/PulsumML/Safety/FoundationModelsSafetyProvider.swift
Packages/PulsumML/Sources/PulsumML/StateEstimator.swift
Packages/PulsumML/Sources/PulsumML/RecRanker.swift
Packages/PulsumAgents/Sources/PulsumAgents/SafetyAgent.swift
Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift
Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift
Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift
Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift

Data Persistence:
Packages/PulsumData/Sources/PulsumData/DataStack.swift
Packages/PulsumData/Sources/PulsumData/Model/ManagedObjects.swift

Runtime Configuration:
Packages/PulsumTypes/Sources/PulsumTypes/AppRuntimeConfig.swift
Packages/PulsumTypes/Sources/PulsumTypes/Notifications.swift
Packages/PulsumServices/Sources/PulsumServices/BuildFlags.swift

Xcode Project (for build settings, capabilities, deployment target):
Pulsum.xcodeproj/project.pbxproj

Build Settings (Info.plist source and usage descriptions):

- Resolve `INFOPLIST_FILE` from project settings
- Resolve `INFOPLIST_KEY_*` overrides in `.pbxproj`/`.xcconfig`

PHASE 1.5: RUNTIME DIAGNOSTICS (optional)

If `diagnostics_data.md` exists in the project root, read it now. This file contains exported runtime diagnostics from an actual device run. It provides evidence that static code analysis cannot:

- Did the app launch without crashing? (Guideline 2.1)
- Did HealthKit authorization flow complete? (Guideline 5.1.1)
- Did the safety classifier trigger correctly on test crisis content? (Guideline 1.4.1)
- Did the on-device Foundation Models coach generate a response? (Guideline 4.2 minimum functionality)
- Were there any runtime errors that would affect the reviewer experience?

Use diagnostics data as EVIDENCE in your PASS/FAIL assessments. For example: if the diagnostics show the app crashed during startup, that's direct evidence for a Guideline 2.1 FAIL.

If `diagnostics_data.md` does not exist, base all assessments on static code analysis only. Note: "No runtime diagnostics available — assessments based on code review only."

PHASE 1.6: OPTIONAL PRIVACY REPORT EVIDENCE

If `privacy_report.pdf` exists in project root, read it and use it as secondary evidence for:

- declared data collection categories,
- required-reason API declarations,
- manifest aggregation consistency.

If absent, continue with code/config evidence only.

PHASE 2: APP STORE REVIEW GUIDELINES COMPLIANCE CHECK

Check every guideline listed below. For each one, state: PASS, FAIL, AT RISK, MANUAL CHECK REQUIRED, or NOT APPLICABLE, with evidence from the code you read. Pulsum-irrelevant guidelines (gambling, VPN, kids category, Apple Music, etc.) are pre-excluded.

Section 1 — Safety

1.4.1 Medical/Health App Accuracy:
Apple states: "Medical apps that could provide inaccurate data or information, or that could be used for diagnosing or treating patients may be reviewed with greater scrutiny."
Apple requires: "Apps should remind users to check with a doctor in addition to using the app and before making medical decisions."
Apple requires: "Apps must clearly disclose data and methodology to support accuracy claims relating to health measurements."

CHECK: Does the app display a "consult your doctor" or equivalent medical disclaimer anywhere in the UI? Check OnboardingView.swift, PulseView.swift, CoachView.swift, SettingsView.swift, and SafetyCardView.swift.
CHECK: Does the app make any accuracy claims about health measurements (wellbeing score, sentiment, HRV analysis) that it cannot validate?
CHECK: Does the app present AI-generated coaching recommendations in a way that could be mistaken for medical advice?
CHECK: Is there a clear disclaimer that the app is for wellness/informational purposes and not medical diagnosis or treatment?
CHECK: When the safety system detects crisis content, does SafetyCardView present appropriate crisis resources and disclaim that the app is not a substitute for professional help?
CHECK: Are crisis resources locale-aware for supported regions? (988 for US users; correct alternatives elsewhere; no nonfunctional hotline links)

1.6 Data Security:
CHECK: Is user health data protected with appropriate security measures (NSFileProtectionComplete on Core Data store, Keychain for sensitive credentials)?
CHECK: Are there any vectors where health data could be accessed by unauthorized third parties?

Section 2 — Performance

2.1 App Completeness:
CHECK: Are there any placeholder text, empty screens, or stub implementations that would be visible to a reviewer? Check for TODO comments, placeholder strings, or stub UI in all view files.
CHECK: Does the app crash or exhibit obvious technical problems on first launch? (Reference master_report.md if available for crash-risk findings.)

2.3 Accurate Metadata:
CHECK: Are there any hidden, dormant, or undocumented features?
CHECK: Does the UITest stub system (UITEST_USE_STUB_LLM, UITEST_FAKE_SPEECH, UITEST_AUTOGRANT) have any risk of activating in a production build reviewed by Apple?

2.4.2 Power Efficiency:
CHECK: Does the app use background modes appropriately? Is HealthKit background delivery the only background activity?
CHECK: Are there any excessive write cycles, continuous polling, or battery-draining patterns?

2.5.1 Public APIs and Framework Usage:
CHECK: Is HealthKit used exclusively for health and fitness purposes?
CHECK: Are all frameworks used for their intended purposes?
CHECK: Are there any deprecated APIs or frameworks that could cause rejection?

2.5.4 Background Modes:
CHECK: Are background modes declared in the entitlements? If so, are they used only for their intended purposes (HealthKit background delivery)?

2.5.14 Recording Consent:
CHECK: When the microphone is used for voice journaling, does the app request explicit user consent?
CHECK: Is there a clear visual indication that recording is in progress?
CHECK: Is the purpose string for microphone access clear and complete?

Section 4 — Design

4.2 Minimum Functionality:
CHECK: Does the app provide sufficient functionality beyond a basic wrapper? Does it have enough native features to be considered "app-like"?

4.10 Monetizing Built-In Capabilities:
CHECK: Does the app monetize HealthKit data, the microphone, or any other built-in capability? (It should not.)

Section 5 — Legal / Privacy

5.1.1 Data Collection and Storage:

(i) Privacy Policy:
CHECK: Is there a privacy policy link accessible within the app (e.g., in SettingsView)?
CHECK: Does the privacy policy (or a link to one) exist in the app metadata?
NOTE: App Store metadata cannot be fully verified from local source code. If App Store Connect data is unavailable, mark that metadata sub-check as MANUAL CHECK REQUIRED and list the exact metadata fields to verify.

(ii) Permission / Consent:
CHECK: Does the app secure user consent before collecting health data?
CHECK: Does the app secure consent before collecting voice/speech data?
CHECK: Are purpose strings clear and complete for all protected resources (HealthKit, microphone, speech recognition)?
CHECK: Are purpose strings present via either `Info.plist` keys or `INFOPLIST_KEY_*` generated build settings?
CHECK: Verify these keys exist and are non-empty (direct plist and/or generated build keys):
- `NSHealthShareUsageDescription`
- `NSHealthUpdateUsageDescription`
- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`
CHECK: Can the user withdraw consent? Is there a mechanism to disable cloud processing, delete data, or revoke permissions?

(iii) Data Minimization:
CHECK: Does the app only request access to health data types it actually uses (HRV, heart rate, sleep, steps, respiratory rate)?
CHECK: Does it avoid collecting unnecessary data?

(iv) Access:
CHECK: Does the app respect user permission denials gracefully? What happens if HealthKit is denied? If microphone is denied?

(v) Account Sign-In:
CHECK: Does the app require account creation? If not, does it work without login? (It should work without login since it is on-device focused.)

5.1.2 Data Use and Sharing:

(i) Sharing with Third Parties:
CHECK: When cloud consent is enabled and data is sent to OpenAI, is the user explicitly informed that data will be shared with a third-party AI service?
CHECK: Is explicit permission obtained before any cloud data transmission?
CHECK: Is PII redaction applied before data leaves the device?

(ii) No Repurposing:
CHECK: Is health data used only for its stated purpose (wellness coaching)? Is there any analytics, advertising, or secondary use?

(vi) HealthKit Data Restrictions:
CRITICAL CHECK: Apple states: "Data gathered from HealthKit may not be used for marketing, advertising or use-based data mining, including by third parties."
CHECK: Is HealthKit data ever sent to the cloud? If so, is it only for the direct purpose of generating coaching recommendations (improving health management)?
CHECK: Is HealthKit data ever logged, cached, or stored outside the protected Core Data store in a way that could be accessed by third parties?

5.1.3 Health and Health Research:

(i) Health Data Use Restrictions:
CHECK: Is health data used only for improving health management or health research, and only with permission?
CHECK: Does the app disclose the specific health data types it collects from the device?

(ii) False Data:
CHECK: Does the app write any data to HealthKit? If so, is it accurate? (It likely only reads from HealthKit.)
CHECK: Is personal health information stored in iCloud? (It must not be.)

Privacy Manifests:
CHECK: Do all 6 PrivacyInfo.xcprivacy files exist and contain valid required-reason API declarations?
CHECK: Are the declared API usage reasons accurate for the APIs actually called?
CHECK: Are the manifests in XML/Property List format (required by Apple tooling)?

Entitlements:
CHECK: Does Pulsum.entitlements include the HealthKit entitlement?
CHECK: Are all declared entitlements actually used by the app?
CHECK: Are there any missing entitlements for capabilities the app uses?

PHASE 3: REPORT GENERATION

Write your findings to guidelines_report.md in the project root. Use this exact structure:

Pulsum — App Store Review Guidelines Compliance Report

Generated: [date]
Audit Scope: Apple App Store Review Guidelines (as accessed on [YYYY-MM-DD])
App: Pulsum (deployment target resolved from build settings: [value])
Files Reviewed: [count]

Overall Compliance Assessment

App Store Review: [LIKELY PASS | AT RISK | LIKELY REJECT] with rationale
Top 5 Compliance Risks (the items most likely to cause App Store rejection):

1. [description]
2. [description]
3. [description]
4. [description]
5. [description]

App Store Review Guidelines — Detailed Results

For each guideline checked, use this format:

GUIDELINE [number]: [title]
Status: [PASS | FAIL | AT RISK | MANUAL CHECK REQUIRED | NOT APPLICABLE]
Evidence: [what you found in the code/UI]
Risk: [what could happen if this is not addressed — rejection reason, user harm, legal exposure]
Remediation: [what specific changes are needed, referencing exact files]

Group results by section:

- Section 1: Safety
- Section 2: Performance
- Section 4: Design
- Section 5: Legal / Privacy
- Privacy Manifests
- Entitlements and Capabilities

App Store Submission Readiness Checklist

A final pass/fail checklist for the developer to review before submitting:

[ ] Medical/health disclaimer visible in app
[ ] "Consult your doctor" language present
[ ] Privacy policy link in Settings (code-verified) and App Store metadata (manual verification)
[ ] HealthKit purpose strings complete and accurate
[ ] Microphone purpose string complete and accurate
[ ] Speech recognition purpose string complete and accurate
[ ] Cloud consent explicitly obtained before any data leaves device
[ ] PII redaction verified before cloud transmission
[ ] No HealthKit data used for advertising/marketing/data mining
[ ] No personal health info stored in iCloud
[ ] All 6 PrivacyInfo.xcprivacy manifests present and valid
[ ] Entitlements match actual capabilities used
[ ] No placeholder text or stub UI visible in production
[ ] UITest flags cannot activate in production builds
[ ] App works without login/account
[ ] App handles all permission denials gracefully
[ ] Crisis/safety content includes professional help resources
[ ] Crisis resources are locale-aware and functional for supported regions (988 for US where applicable)
[ ] AI-generated content clearly labeled as AI-generated
[ ] User can disable cloud AI features
[ ] Data deletion mechanism exists
[ ] Background modes used only for HealthKit delivery
[ ] No deprecated APIs
[ ] App does not monetize HealthKit or microphone access
[Add any additional items discovered during review]

Pre-Submission Action Items

A prioritized list of things to fix before submitting to App Review:

Blockers (must fix or Apple will reject):

1. [item with file reference and specific change needed]
2. ...

High Risk (Apple may flag these during review):

1. [item with file reference]
2. ...

Recommended (strengthens submission, reduces review friction):

1. [item with file reference]
2. ...

EXECUTION RULES

1. **Use subagents to parallelize.** Read UI files, agent files, service files, and configuration files in parallel via subagents. The compliance audit touches files across all packages — parallel reads drastically reduce scan time. Use subagents for: reading all PrivacyInfo.xcprivacy files simultaneously, reading all UI views for disclaimer/label checks, reading all agent files for safety system checks.
2. Do not stop until done. Complete all checks and write the full report.
3. Do not ask for confirmation. Just keep going.
4. Be evidence-based. Every PASS/FAIL/AT RISK must cite specific code, file paths, diagnostics evidence, or user-facing UI text. If evidence is external-only (for example App Store Connect metadata), use MANUAL CHECK REQUIRED instead of guessing.
5. Think like an App Store reviewer. They will test: launch the app, try all features, check permissions flow, look for disclaimers, check privacy policy, test with permissions denied, look for hidden features. Anticipate what they will find.
6. Think like a health-tech regulator. They will ask: does this app make health claims it cannot support? Could AI recommendations cause harm? Is the user informed about AI limitations? Is health data protected? Treat "CONTEXT ABOUT THE APP" claims as unverified until proven.
7. Cross-reference with master_report.md. If the technical audit found issues that create compliance risk (e.g., a broken safety guardrail means guideline 1.4.1 is at risk), reference the specific finding ID.
8. **Use web search** to verify current Apple App Store Review Guidelines. Guidelines change — confirm clause numbers and requirements are current before citing them.
9. The report must be actionable. Each finding must tell the developer exactly what to change, in which file, before submitting to App Review.
10. Do not fabricate compliance issues. If the code meets a requirement, say PASS and move on. Do not invent problems.
11. If a previous `guidelines_report.md` exists, snapshot it before writing the new report (prefer `guidelines_report_PREV.md` when available), then compare old vs new status for each guideline. Note which checks changed from FAIL/AT RISK to PASS (improvements) and which changed from PASS to FAIL (regressions).
12. Determine deployment target from build settings, not prompt assumptions. Gate API/compliance comments against resolved deployment targets.
13. Parallel safety rule: if using subagents, subagents must not write shared files (`_guidelines_progress.md`) directly. They should write per-subagent outputs or return results to the primary agent, and the primary agent merges updates sequentially.
