# Pulsum Master Technical Analysis Report

**Generated:** 2026-02-15 (Full re-audit, post-V2 remediation)
**Files Analyzed:** 206 (114 source + 85 test/UI test + 7 CI scripts + build configs)
**Total Findings:** 42 (0 CRIT + 4 HIGH + 18 MED + 20 LOW)
**Overall Health Score:** 8.0 / 10

**Rationale:** The score reflects substantial improvement since the previous audit (6.5/10, 87 findings). **Technically** (8.5/10): All five previous CRIT issues are resolved — NaN corruption paths in StateEstimator and SafetyLocal are guarded, RobustStats MAD is clamped, AgentOrchestrator is no longer blocking the main thread for ML operations, and the non-compiling test was removed. Foundation Models providers now use `@Generable` types instead of string interpolation, eliminating the prompt injection vector. Zero `fatalError`, zero `print()`, zero Combine usage. **Architecturally** (8.5/10): Clean 6-package DAG with strict dependency direction. Proper `@ModelActor` / actor patterns for data and ML layers. All 26 `@unchecked Sendable` annotations in production code are individually justified with safety comments (immutable `let` properties, lock-protected state, or NSObject compatibility). **Operationally** (7/10): Medical disclaimer in 3+ locations, AI-generated content labels, GDPR data deletion, locale-aware crisis resources for 12 regions, comprehensive CI pipeline (integrity, secrets, privacy manifests, gate tests). Remaining gaps: incomplete localization (4/22 UI files), BYOK API key security (accepted risk for v1.0), some views without accessibility labels, and VectorStore silent empty-result on corrupt file.

---

## Executive Summary

Pulsum is an iOS 26+ wellness coaching app with a clean 6-package modular design (PulsumTypes → PulsumML + PulsumData → PulsumServices → PulsumAgents → PulsumUI → App). The V2 remediation (commit 99b8409) has resolved all critical issues from the previous audit: NaN corruption paths are guarded, safety classification bypasses are closed, the orchestrator no longer blocks the main thread, Foundation Models providers use structured `@Generable` types, and concurrency safety has been materially improved with actor conversions (StateEstimator, SafetyLocal, RecRankerStateStore, JournalSessionState, VectorStore).

**What works well:**
- SwiftData integration with `@Model` classes, `#Predicate` queries, and Sendable DTO snapshots
- VectorStore actor with Accelerate-backed search and atomic file persistence
- Two-wall safety system (SafetyLocal keywords/embeddings + Foundation Models classification) with NaN guards
- HealthKit integration with anchored queries, background delivery, and retry logic
- LLM Gateway with PII redaction, MinimizedCloudRequest sanitization, rate limiting, and grounding floor
- Foundation Models providers using `@Generable` structured types (SafetyAssessment, SentimentAnalysis, OnTopic)
- Structured diagnostics logging with PII protection via DiagnosticsSafeString
- Locale-aware crisis resources for 12 regions (US, UK, CA, AU, DE, FR, JP, IN, NZ, IE, ZA, BR)
- Comprehensive CI scripts (integrity, secrets scan, privacy manifests, gate tests, release build)
- PIIRedactor with 8 patterns + NER names, regex compiled once at module load
- Comprehensive test coverage: 130+ ML tests, agent pipeline tests, ViewModel tests, UI tests

**What needs attention:**
- **Localization:** Only 4/22 PulsumUI source files use `String(localized:)` — SettingsView, PulseView, ScoreBreakdownView, WellbeingStateCardView remain hardcoded English
- **@unchecked Sendable:** 26 justified instances in production — architecturally correct but not converged to actors
- **VectorStore:** Silent empty-result fallback on corrupt persistence file (no error surfaced to user)
- **Certificate pinning:** Comments describe "SPKI pinning" but implementation performs standard TLS trust evaluation
- **Accessibility:** Some UI views lack accessibility labels and Dynamic Type support
- **DataAgent+Backfill.swift:** Still ~1,500 lines with repeated switch-case blocks

---

## Delta from Previous Audit (2026-02-14, 6.5/10 → 8.0/10)

### Fixed Since Previous Audit

| Previous ID | Severity | Description | Resolution |
|---|---|---|---|
| CRIT-01 | Critical | NaN target in StateEstimator.update() corrupts weights | Guard added: `guard !target.isNaN` |
| CRIT-02 | Critical | NaN embeddings bypass SafetyLocal → `.safe` | NaN check in cosine similarity comparison |
| CRIT-03 | Critical | AgentOrchestrator @MainActor blocks UI thread | Converted to `@unchecked Sendable` class with all `let` properties; `@MainActor` only on init and UI-facing methods |
| CRIT-04 | Critical | RobustStats `mad=0` → division by zero | `mad = max(mad, 1e-6)` in init |
| CRIT-05 | Critical | PulsumServicesDependencyTests won't compile | Stale test file deleted |
| HIGH-01 | High | Embedding dimension inconsistency (512 vs 300 → 384) | Proper truncation/padding with capacity reserve |
| HIGH-03 | High | US-only crisis resources hardcoded | SafetyCardView accepts locale-aware CrisisResourceInfo from SafetyAgent |
| HIGH-05 | High | RecRankerStateStore lacks thread safety | Converted to `public actor` |
| HIGH-07 | High | SentimentAgent no explicit actor isolation | Added `@MainActor` annotation |
| HIGH-09 | High | Misleading privacy description (Complete vs CompleteUnlessOpen) | Settings text corrected |
| HIGH-10 | High | PIIRedactor coverage gaps | Expanded to 8 patterns + parenthesized phone; regex cached at load |
| HIGH-11 | High | Prompt injection in FM providers (string interpolation) | All three providers converted to `@Generable` structured types |
| HIGH-12 | High | English-only embeddings | Locale-aware language selection with English fallback |
| HIGH-13 | High | JournalSessionState @unchecked Sendable | Converted to proper `actor` |
| HIGH-15 | High | Force unwraps in SafetyCardView, SettingsView | Replaced with optional binding; SafetyCardView fully locale-aware |
| HIGH-16 | High | VectorStore unaligned memory access | Safe byte copy via unsafeUninitializedCapacity |

### New Findings

16 findings were not present in the previous audit (MED-01 through MED-07, LOW-01 through LOW-09 below) — most are refinements uncovered by deeper analysis rather than regressions.

### Unchanged / Partially Addressed

| Previous ID | Current ID | Status | Notes |
|---|---|---|---|
| HIGH-02 | HIGH-01 | Partial | Localization improved (4 files) but still incomplete |
| HIGH-04 | MED-10 | Reduced | 26 justified @unchecked Sendable remain; all documented |
| HIGH-06 | MED-08 | Reduced | LibraryImporter still @unchecked Sendable with NSLock (justified) |
| HIGH-08 | HIGH-02 | Open | Certificate pinning comments still mislabeled |
| HIGH-14 | MED-09 | Open | DataAgent+Backfill.swift still ~1,500 lines |

---

## If You Only Fix 5 Things, Fix These

1. **HIGH-01** — Complete localization: 18/22 PulsumUI source files still use hardcoded English strings
2. **HIGH-02** — Fix certificate pinning comments or implement actual SPKI pinning in LLMGateway
3. **HIGH-03** — VectorStore: surface error on corrupt persistence file instead of silent empty result
4. **HIGH-04** — Add accessibility labels and Dynamic Type to remaining UI views
5. **MED-01** — Convert LibraryImporter from @unchecked Sendable + NSLock to actor pattern

---

## App Understanding

Pulsum is an iOS 26+ wellness coaching application combining on-device ML, HealthKit integration, voice journaling, and optional cloud-powered AI coaching. Users can: (1) view a computed wellbeing score derived from HealthKit metrics (HRV, heart rate, sleep, steps, respiratory rate) and subjective inputs (stress, energy, sleep quality), (2) record voice journals that are transcribed, sentiment-analyzed, and PII-redacted, (3) receive personalized micro-moment recommendations ranked by a Bradley-Terry learning algorithm, (4) chat with an AI coach that routes between on-device Foundation Models and cloud GPT-5 based on consent and safety classification.

**Architecture:** 6 Swift packages in acyclic dependency order:
- `PulsumTypes` (16 files, 1,778 lines) — shared types, diagnostics, PII redaction, DTO snapshots, timeout coordination
- `PulsumML` (38 files) — embeddings, sentiment (4-provider fallback), safety (two-wall), state estimation, topic gate, RecRanker
- `PulsumData` (25 files) — 9 SwiftData `@Model` classes, VectorStore actor, LibraryImporter, DataStack
- `PulsumServices` (27 files) — HealthKit (anchored queries, background delivery), Speech (3 backends), LLM Gateway (GPT-5), Keychain, NetworkMonitor
- `PulsumAgents` (54 files, ~6,022 lines) — orchestrator, DataAgent + backfill, SentimentAgent, CoachAgent, SafetyAgent, CheerAgent
- `PulsumUI` (33 files) — SwiftUI views, view models (all `@MainActor` + `@Observable`), Liquid Glass design, onboarding

**Key Dependencies:** HealthKit, Speech, Foundation Models (iOS 26), SwiftData, Natural Language, Core ML, Accelerate, MetricKit, spline-ios v0.2.48. **Backend:** OpenAI GPT-5 via Responses API (consent-gated, BYOK).

---

## High-Priority Issues

### HIGH-01: Incomplete Localization (18/22 UI Files Hardcoded)

**Severity:** High
**Category:** App Store Compliance
**Files:** PulseView.swift, SettingsView.swift, ScoreBreakdownView.swift, WellbeingStateCardView.swift, PulsumRootView.swift, and 13 other PulsumUI source files
**Effort:** L

**Description:** Only 4 of 22 PulsumUI source files use `String(localized:)`: OnboardingView (14+ keys), CoachView, SafetyCardView, and ConsentBannerView. The remaining files — including SettingsView (extensive user-facing text about privacy, data handling, and health data), PulseView, ScoreBreakdownView, and WellbeingStateCardView — contain hardcoded English strings. The `Localizable.xcstrings` catalog in the app target is empty.

**Impact:** Apple requires localization support for App Store submission. User-safety-critical text (medical disclaimers in Settings, score interpretations, health data descriptions) is not localizable.

**Fix:** Prioritize localizing user-safety-critical strings first (medical disclaimers, privacy descriptions, health data explanations), then remaining UI text. Populate `Localizable.xcstrings` with the localized keys.

---

### HIGH-02: Certificate Pinning Comments Mislabel Standard TLS Evaluation

**Severity:** High
**Category:** Security / Documentation
**File:** `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift`
**Effort:** S

**Description:** Comments describe "SPKI pinning against Let's Encrypt and DigiCert root CAs" but the `OpenAICertificatePinningDelegate` implementation performs standard `SecTrustEvaluateWithError` trust evaluation with no hardcoded public key hashes. This provides no additional security beyond the system trust store.

**Impact:** Misleading documentation could give false security assurance during review. If actual pinning is desired for the OpenAI API connection, it is not implemented.

**Fix:** Either implement actual SPKI pinning with hardcoded key hashes, or update comments to accurately describe behavior as "standard TLS trust evaluation with system CA validation."

---

### HIGH-03: VectorStore Returns Empty Results on Corrupt Persistence File

**Severity:** High
**Category:** Data Integrity
**File:** `Packages/PulsumData/Sources/PulsumData/VectorStore.swift`
**Effort:** S

**Description:** When the binary persistence file is corrupt or truncated, `loadFromDisk()` fails silently and the VectorStore returns empty search results. The user experiences recommendations and topic matching degradation with no diagnostic feedback.

**Impact:** After a crash or disk issue corrupts the vector file, the recommendation system silently degrades. The LibraryImporter's checksum-based idempotency means the library won't be re-imported because the checksum still matches, leaving the VectorStore permanently empty until the app is reinstalled.

**Fix:** Log corruption via `Diagnostics.log()` and trigger a re-import by invalidating the checksum. Surface a user-visible indicator that recommendations may be limited.

---

### HIGH-04: Accessibility Gaps in UI Layer

**Severity:** High
**Category:** Accessibility / App Store Compliance
**Files:** Multiple PulsumUI views
**Effort:** M

**Description:** Several UI views lack accessibility labels on interactive elements. Some views use hardcoded `.font(.system(size: N))` instead of Dynamic Type-compatible semantic fonts (`.headline`, `.subheadline`). The score breakdown and wellbeing card views do not provide VoiceOver descriptions for their data visualizations.

**Impact:** Users with accessibility needs cannot fully interact with the app. Dynamic Type users see fixed-size text that doesn't respect their system preferences.

**Fix:** Add `.accessibilityLabel()` to all interactive elements. Replace hardcoded font sizes with semantic Dynamic Type fonts. Add `.accessibilityElement(children: .combine)` with descriptive labels to data visualization containers.

---

## Medium-Priority Issues

### MED-01: LibraryImporter Uses @unchecked Sendable + NSLock Instead of Actor

**File:** `Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift`
**Category:** Concurrency | **Effort:** M

LibraryImporter is `@unchecked Sendable` with an `NSLock` protecting mutable state (`_lastImportHadDeferredEmbeddings`). While functionally correct and documented with a safety comment, this violates the project preference for actors over locks. The `ingestIfNeeded()` method performs async operations that would benefit from actor isolation.

---

### MED-02: VectorStore Force Unwrap on baseAddress

**File:** `Packages/PulsumData/Sources/PulsumData/VectorStore.swift:174`
**Category:** Safety | **Effort:** S

One force unwrap remains: `raw.baseAddress!.advanced(by: cursor)` in binary deserialization. While `baseAddress` is guaranteed non-null for non-empty `Data` buffers, this violates the project's zero-force-unwrap policy.

**Fix:** Replace with `guard let base = raw.baseAddress else { throw VectorStoreError.corruptFile }`.

---

### MED-03: AgentOrchestrator @unchecked Sendable with @MainActor Methods

**File:** `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:179`
**Category:** Concurrency | **Effort:** L

AgentOrchestrator is `@unchecked Sendable` with all `let` properties and `@MainActor`-annotated methods. While functionally correct (documented with safety comment), the mixed isolation model (class-level @unchecked Sendable + method-level @MainActor) is unusual and may confuse future contributors. Consider converting to a `@MainActor final class` (for UI-bound methods) or splitting into a non-MainActor orchestration core + MainActor UI facade.

---

### MED-04: DataAgent+Backfill.swift Is ~1,500 Lines with Duplicated Logic

**File:** `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent+Backfill.swift`
**Category:** Maintainability | **Effort:** L

The file contains near-identical switch-case blocks repeated ~3 times (~600 lines of duplication) for bootstrap/retry/fallback sample processing logic. Changes to sample processing must be applied in multiple places.

**Fix:** Extract a shared `fetchSamplesForType(type:window:timeout:)` method and a shared `processBootstrapBatch(types:window:timeout:)` to eliminate triplicated logic.

---

### MED-05: Foundation Models Coach Generator Uses String Interpolation for Prompts

**File:** `Packages/PulsumServices/Sources/PulsumServices/FoundationModelsCoachGenerator.swift:46-53`
**Category:** Security | **Effort:** S

Unlike the three ML providers (Safety, Sentiment, TopicGate) which use `@Generable` structured types, the coach generator constructs prompts via string interpolation. The coach response is intentionally unstructured text, so `@Generable` may not apply, but the user-provided message is interpolated directly into the prompt without delimiters.

**Fix:** Wrap user input in clear delimiters: `<user_message>\(userMessage)</user_message>` and instruct the system prompt to only respond to content within these tags. This is defense-in-depth.

---

### MED-06: Empty Localizable.xcstrings in App Target

**File:** `Pulsum/Localizable.xcstrings`
**Category:** Build / Localization | **Effort:** S

The app target's string catalog is empty (`"strings": {}`), despite `LOCALIZATION_PREFERS_STRING_CATALOGS = YES` in the build settings. The localized keys used by PulsumUI views (OnboardingView, CoachView, SafetyCardView, ConsentBannerView) are defined in package-level code but never exported to the app-level catalog.

**Fix:** Either populate the catalog with all localized keys, or ensure the SwiftUI automatic string extraction picks up package-level `String(localized:)` calls during build.

---

### MED-07: Workspace References Missing File (datagentsummary.md)

**File:** `Pulsum.xcodeproj/project.xcworkspace/contents.xcworkspacedata`
**Category:** Build | **Effort:** S

The Xcode workspace references `datagentsummary.md` which does not exist in the repository. This causes a warning in Xcode's file navigator.

**Fix:** Remove the stale reference from the workspace data file.

---

### MED-08: SettingsView Contains Extensive Unlocalized User-Facing Text

**File:** `Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift`
**Category:** Localization | **Effort:** M

SettingsView contains extensive user-facing text about privacy policies, data handling, health data descriptions, and medical disclaimers — all hardcoded in English. This is particularly important because the privacy and safety text in Settings is user-safety-critical.

---

### MED-09: ScoreBreakdownView and WellbeingStateCardView Lack Localization

**Files:** `ScoreBreakdownView.swift`, `WellbeingStateCardView.swift`
**Category:** Localization | **Effort:** M

Health score interpretations, metric descriptions, and wellbeing state labels are hardcoded English. These views display health-related information that should be localized for non-English users.

---

### MED-10: 26 @unchecked Sendable Annotations in Production Code

**Files:** Multiple across all packages
**Category:** Concurrency / Technical Debt | **Effort:** L

All 26 instances are individually justified with safety comments explaining immutable `let` properties, lock-protected mutable state, or NSObject compatibility requirements. The justifications are technically sound, but the volume of `@unchecked Sendable` represents architectural debt that could be reduced by converting more types to actors.

**Key candidates for actor conversion:** LibraryImporter (MED-01), HealthKitService, LLMGateway, SentimentService.

---

### MED-11: PulsumTests Target Missing PulsumTypes Dependency in pbxproj

**File:** `Pulsum.xcodeproj/project.pbxproj`
**Category:** Build | **Effort:** S

The PulsumTests target's `packageProductDependencies` section does not include PulsumTypes. If tests import PulsumTypes symbols directly, this could cause link failures.

---

### MED-12: PulsumUITests Target Missing PulsumTypes Dependency in pbxproj

**File:** `Pulsum.xcodeproj/project.pbxproj`
**Category:** Build | **Effort:** S

Same as MED-11 but for the PulsumUITests target.

---

### MED-13: DiagnosticsLogger File Protection Inconsistency

**File:** `Packages/PulsumTypes/Sources/PulsumTypes/DiagnosticsLogger.swift`
**Category:** Security | **Effort:** S

DiagnosticsLogger sets `NSFileProtectionComplete` on log files, while the project standard is `NSFileProtectionCompleteUnlessOpen` (required for HealthKit background delivery). If diagnostics logging occurs during background HealthKit delivery, log writes could fail.

**Fix:** Align to `NSFileProtectionCompleteUnlessOpen`.

---

### MED-14: No Deep Linking Support

**Files:** PulsumApp.swift, PulsumUI views
**Category:** Feature Completeness | **Effort:** M

The app has no URL scheme registration or universal link handling. This prevents integration with Health app, Shortcuts, or notification-based navigation.

---

### MED-15: PulseView and PulsumRootView Lack Localization

**Files:** `PulseView.swift`, `PulsumRootView.swift`
**Category:** Localization | **Effort:** M

The main app views (pulse recording interface and root navigation) contain hardcoded English strings for button labels, status messages, and navigation titles.

---

### MED-16: Config.xcconfig Is Empty

**File:** `Config.xcconfig`
**Category:** Build | **Effort:** S

The xcconfig file is empty (comments only). The documented API key injection mechanism (launchctl setenv or committed .xcconfig) has no actual configuration. This is intentional (secrets via Keychain) but the file's existence without content may confuse contributors.

**Fix:** Either remove the file or add a comment explaining the Keychain-based key management approach.

---

### MED-17: Swift Version in pbxproj Shows 5.0

**File:** `Pulsum.xcodeproj/project.pbxproj`
**Category:** Build | **Effort:** S

`SWIFT_VERSION = 5.0` in the project settings. While SPM packages correctly use `swift-tools-version: 6.1`, the Xcode project target shows 5.0. In Xcode 26, `SWIFT_VERSION = 5.0` with `SWIFT_APPROACHABLE_CONCURRENCY = YES` effectively enables Swift 6 mode, but the version number is misleading.

---

### MED-18: Minimal Unit Tests in App Target

**File:** `PulsumTests/PulsumTests.swift`
**Category:** Testing | **Effort:** M

Only 2 tests in the main app target (runtime config defaults + data stack model types). While comprehensive testing exists at the package level, the app-level integration surface (PulsumApp init, environment injection, animation config) is minimally tested.

---

## Low-Priority Issues

### LOW-01: Hardcoded Font Sizes in CoachView and PulsumRootView

**Files:** `CoachView.swift`, `PulsumRootView.swift`
**Category:** Accessibility | **Effort:** S

`.font(.system(size: N))` used for some text elements instead of Dynamic Type-compatible semantic fonts.

---

### LOW-02: UI Test Infrastructure Has Multiple Fallback Strategies

**File:** `PulsumUITests/PulsumUITestCase.swift`
**Category:** Test Stability | **Effort:** M

Settings sheet detection uses 3 fallback strategies (SettingsButton → SettingsTestHookButton → sheet detection). Keyboard handling uses KVC-based focus check with retries. These suggest UI test fragility.

---

### LOW-03: Build Number Script Requires Git History

**File:** `Pulsum.xcodeproj/project.pbxproj` (build phase)
**Category:** Build | **Effort:** S

The "Set Build Number" build phase uses `git rev-list HEAD --count`. This fails in shallow clones (CI environments) and produces incorrect numbers after history rewrites.

---

### LOW-04: spline-ios Dependency Pinned to Specific Version

**File:** `Package.resolved`
**Category:** Dependencies | **Effort:** S

spline-ios v0.2.48 is the only external dependency. It's pinned to a specific revision, which is good for reproducibility but requires manual updates.

---

### LOW-05: AppIcon Assets Use Non-Descriptive Filenames

**File:** `Assets.xcassets/AppIcon.appiconset/Contents.json`
**Category:** Asset Management | **Effort:** S

Icon files named `iconnew 2.png`, `iconnew 1.png`, `iconnew.png` — non-descriptive names with spaces.

---

### LOW-06: Workspace References Are Self-Referential Plus Stale File

**File:** `project.xcworkspace/contents.xcworkspacedata`
**Category:** Build | **Effort:** S

Contains standard self-reference plus stale `datagentsummary.md` reference (see MED-07).

---

### LOW-07: Code Signing Identity Hardcoded to "Apple Development"

**File:** `Pulsum.xcodeproj/project.pbxproj`
**Category:** Build | **Effort:** S

`CODE_SIGN_IDENTITY = "Apple Development"` in project settings. Standard for development but may need adjustment for CI/archive builds.

---

### LOW-08: RELEASE_LOG_AUDIT Custom Swift Flag

**File:** `Pulsum.xcodeproj/project.pbxproj`
**Category:** Build | **Effort:** S

Release configuration has `OTHER_SWIFT_FLAGS = "$(inherited) -DRELEASE_LOG_AUDIT"`. Ensure this flag's usage is intentional and all code paths behind it are production-safe.

---

### LOW-09: Integrity Script Tag Check Is Informational Only

**File:** `scripts/ci/integrity.sh`
**Category:** CI | **Effort:** S

The `gate0-done-2025-11-09` tag check is informational (not enforced unless --strict). Consider enforcing in CI.

---

### LOW-10: PulsumUI Package Tests Run Under PulsumUI.xcscheme with App as Test Host

**File:** `Pulsum.xcodeproj/xcshareddata/xcschemes/PulsumUI.xcscheme`
**Category:** Testing | **Effort:** S

PulsumUI scheme runs PulsumTests (app-level) non-parallel, using the app as test host. This couples package-level testing to the app target.

---

### LOW-11: SettingsView Has No Accessibility Identifiers for All Interactive Elements

**File:** `Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift`
**Category:** Accessibility / Testing | **Effort:** S

While key buttons have accessibility identifiers (for UI tests), some interactive elements in Settings may lack identifiers needed for comprehensive UI test coverage.

---

### LOW-12: No Explicit NSPrivacyTracking Key in Some Package Manifests

**Files:** Package-level PrivacyInfo.xcprivacy files
**Category:** Compliance | **Effort:** S

While `NSPrivacyTracking` defaults to `false` when omitted, Apple's evolving requirements may eventually require explicit declaration. Adding it proactively ensures forward compatibility.

---

### LOW-13: test-harness.sh and build-release.sh Depend on Python 3

**Files:** `scripts/ci/test-harness.sh`, `scripts/ci/build-release.sh`
**Category:** CI | **Effort:** S

Simulator auto-detection uses a Python 3 script. CI runners without Python 3 will fail.

---

### LOW-14: PulsumServices PrivacyInfo Comment Notes Keychain/NWPathMonitor Exclusion

**File:** `Packages/PulsumServices/Sources/PulsumServices/PrivacyInfo.xcprivacy`
**Category:** Compliance | **Effort:** S

Comment notes that Keychain (Security/SecItem*) and NWPathMonitor (Network) don't require API category declarations as of iOS 26. Monitor Apple's privacy manifest requirements for changes.

---

### LOW-15: HealthKit Background Modes Entitlement Relies on Info.plist Generation

**File:** `Pulsum/Pulsum.entitlements`
**Category:** Build | **Effort:** S

The entitlements file declares `com.apple.developer.healthkit.background-delivery` but the `UIBackgroundModes` array (if needed) is set via `GENERATE_INFOPLIST_FILE`. Verify the generated Info.plist includes `processing` or `fetch` background modes if required.

---

### LOW-16: PulsumRootView Contains Score Display Logic

**File:** `Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift`
**Category:** Architecture | **Effort:** M

PulsumRootView contains score display and wellbeing card rendering alongside navigation logic. Consider extracting score-related views into dedicated components for better separation of concerns.

---

### LOW-17: Onboarding View Has 14+ Localized Keys — Other Views Should Match

**File:** `Packages/PulsumUI/Sources/PulsumUI/OnboardingView.swift`
**Category:** Localization | **Effort:** S

OnboardingView sets a good example with 14+ `String(localized:)` keys. This pattern should be replicated across all user-facing views.

---

### LOW-18: DiagnosticsStallMonitor and DiagnosticsSpanToken Are Separate Files

**Files:** `PulsumTypes/DiagnosticsStallMonitor.swift`, `PulsumTypes/DiagnosticsLogger.swift`
**Category:** Code Organization | **Effort:** S

DiagnosticsSpanToken is defined inside DiagnosticsLogger.swift. Consider extracting to its own file for consistency with the separate DiagnosticsStallMonitor file.

---

### LOW-19: RecRanker Has No Integration Test with Real VectorStore

**Files:** `Packages/PulsumAgents/Tests/PulsumAgentsTests/`
**Category:** Testing | **Effort:** M

RecRanker learning tests use a VectorIndexStub. No test exercises the full pipeline from recommendation request → VectorStore search → RecRanker ranking → feedback update with real actors.

---

### LOW-20: No Automated Performance Regression Testing

**Files:** Test suites
**Category:** Testing | **Effort:** M

While Gate5_LibraryImporterPerfTests exists for import performance, there are no performance tests for critical user-facing paths: recommendation generation latency, safety classification time, voice journal save time.

---

## Test Coverage Summary

| Package | Test Files | Key Coverage |
|---|---|---|
| PulsumML | 13 test files | SafetyLocal, RecRanker, StateEstimator, Embedding fallback, PIIRedactor, Sentiment fallback, WellbeingScore pipeline |
| PulsumData | 9 test files | DataStack security, LibraryImporter atomicity/perf, VectorIndex concurrency |
| PulsumServices | 13 test files + 1 support | LLMGateway (schema, keys, UI seams), SpeechService (3 backends), HealthKitAnchorStore, Keychain |
| PulsumAgents | 29 test files | Orchestrator (LLM key, consent routing), RecRanker (learning, persistence), Sentiment (journaling fallback), Backfill (phasing), Chat guardrails, Gate 2-7 suites |
| PulsumUI | 11 test files | PulseViewModel, AppViewModel, CoachViewModel, SettingsViewModel, SafetyCardView, ConsentStore |
| App (PulsumTests) | 1 test file | Runtime config defaults, DataStack model types (2 tests) |
| UI Tests | 7 test files | First run permissions, health access (Gate 3), cloud consent (Gate 4), journal flow, settings/coach, launch |

**Overall:** 83 test files with 130+ individual test cases. Coverage is comprehensive for critical paths (safety, ML correctness, concurrency, data integrity). Gaps exist for: full pipeline integration tests, performance regression tests, and app-level integration beyond runtime config.

---

## Compliance Summary

Based on `guidelines_report.md` (V3, 2026-02-15): **LIKELY PASS** (28 PASS, 0 FAIL, 0 AT RISK, 1 MANUAL CHECK).

Key compliance strengths: medical disclaimer in 3+ locations, AI-generated content labeling, GDPR data deletion, crisis resources, safety classification, privacy manifests (all 6 targets), HealthKit usage descriptions, encryption declaration (ITSAppUsesNonExemptEncryption = NO).

Remaining compliance items: localization completeness (see HIGH-01), privacy policy URL verification (manual), App Store Connect metadata (manual).

---

## Architecture Decision Record

| # | Decision | Choice | Status |
|---|---|---|---|
| D1 | Persistence | SwiftData | Done — 9 @Model classes, DTO snapshots |
| D2 | Vector Index | VectorStore actor | Done — flat dict + Accelerate search |
| D3 | Agents | Keep 5, fix isolation | Done — proper actor/MainActor annotations |
| D4 | Concurrency | Actor isolation | Mostly done — 26 justified @unchecked Sendable remain |
| D5 | State observation | @Observable + NotificationCenter | Done |
| D6 | DataAgent | Decomposed into extensions | Done — except Backfill still ~1,500 lines |
| D7 | SettingsVM | Split into 3 VMs | Done — HealthSettingsVM, DiagnosticsVM, SettingsVM |
| D8 | Monetization | BYOK optional | Done — backend proxy deferred to v1.1 |
| D9 | Packages | Keep 6 as-is | Done — strict DAG maintained |
| D10 | Localization | String(localized:) | Partial — 4/22 UI files done |
| D11 | Foundation Models | @Generable structured types | Done — Safety, Sentiment, TopicGate |
| D12 | Crisis resources | Locale-aware (12 regions) | Done — SafetyAgent → SafetyCardView |
