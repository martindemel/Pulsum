# Pulsum Master Technical Analysis Report

**Generated:** 2026-02-14 (Full re-audit, post-Phase 0 architecture remediation)
**Files Analyzed:** 191 (113 source + 78 test/UI test + CI scripts + build configs)
**Total Findings:** 87 (5 CRIT + 18 HIGH + 24 MED + 20 LOW + 20 test coverage gaps)
**Overall Health Score:** 6.5 / 10

**Rationale:** The score reflects significant improvement since the pre-Phase 0 audit (3.5/10). **Technically** (7/10): SwiftData migration eliminated Core Data fatalError crashes, VectorStore actor replaced the sharded index, agent decomposition improved maintainability, PII redaction and safety systems are functional. Remaining critical issues: NaN corruption paths in StateEstimator/SafetyLocal, `@MainActor` on AgentOrchestrator, one non-compiling test. **Architecturally** (7.5/10): Clean 6-package dependency graph, proper DTO snapshot pattern for `@Model` objects, VectorStore as an actor is correct. 15+ `@unchecked Sendable` annotations remain as the primary architectural debt. **Operationally** (5/10): Medical disclaimer present (3 locations), crash diagnostics via MetricKit, GDPR data deletion implemented, AI-generated content labeling. Zero localization, US-only crisis resources, BYOK security risk, and several test coverage gaps prevent production readiness.

---

## Executive Summary

Pulsum is an iOS 26+ wellness coaching app with a clean 6-package modular design (PulsumTypes -> PulsumML + PulsumData -> PulsumServices -> PulsumAgents -> PulsumUI -> App). The Phase 0 architecture remediation has been executed: SwiftData replaces Core Data with proper `@Model` classes and DTO snapshots, a VectorStore actor replaces the buggy sharded VectorIndex, DataAgent has been decomposed into focused extensions, SettingsViewModel has been split into HealthSettingsViewModel and DiagnosticsViewModel, and safety improvements (FoundationModelsSafetyProvider returns `.caution` for guardrails, SafetyAgent implements two-wall classification, crisis resources added) are in place.

**What works well:**
- SwiftData integration with `@Model` classes, `#Predicate` queries, and Sendable DTO snapshots
- VectorStore actor with Accelerate-backed search and atomic file persistence
- Two-wall safety system (SafetyLocal keywords + Foundation Models classification)
- HealthKit integration with anchored queries, background delivery, and retry logic
- LLM Gateway with PII redaction, MinimizedCloudRequest sanitization, and grounding floor
- Structured diagnostics logging with PII protection via DiagnosticsSafeString
- Comprehensive CI scripts (integrity, secrets, privacy manifests, gate tests)

**What needs attention:**
- **Safety:** NaN values in embeddings silently bypass SafetyLocal (crisis text classified as `.safe`)
- **Concurrency:** AgentOrchestrator is `@MainActor`, serializing all orchestration on UI thread; 15+ `@unchecked Sendable` types violate project rules
- **Localization:** Zero `String(localized:)` usage across entire UI layer
- **ML correctness:** NaN target in StateEstimator corrupts weights; embedding dimension inconsistency mixes truncated 512-dim and padded 300-dim vectors
- **Testing:** Multiple test coverage gaps including PIIRedactor, SentimentService fallback, and most ViewModels

---

## If You Only Fix 5 Things, Fix These

1. **CRIT-01** -- NaN target in `StateEstimator.update()` corrupts all model weights permanently
2. **CRIT-02** -- NaN embeddings cause SafetyLocal to classify crisis text as `.safe`
3. **CRIT-03** -- `AgentOrchestrator` is `@MainActor`, blocking the main thread during ML/data operations
4. **HIGH-01** -- Embedding dimension inconsistency: sentence (512->384 truncated) vs word (300->384 padded) vectors are geometrically incompatible
5. **HIGH-02** -- Zero localization across all user-facing strings (App Store requirement)

---

## App Understanding

Pulsum is an iOS 26+ wellness coaching application combining on-device ML, HealthKit integration, voice journaling, and optional cloud-powered AI coaching. Users can: (1) view a computed wellbeing score derived from HealthKit metrics (HRV, heart rate, sleep, steps, respiratory rate) and subjective inputs (stress, energy, sleep quality), (2) record voice journals that are transcribed, sentiment-analyzed, and PII-redacted, (3) receive personalized micro-moment recommendations ranked by a Bradley-Terry learning algorithm, (4) chat with an AI coach that routes between on-device Foundation Models and cloud GPT-5 based on consent and safety classification.

**Architecture:** 6 Swift packages in acyclic dependency order:
- `PulsumTypes` (13 files) -- shared types, diagnostics, PII redaction, snapshots
- `PulsumML` (24 files) -- embeddings, sentiment, safety, state estimation, topic gate, RecRanker
- `PulsumData` (16 files) -- SwiftData models, VectorStore, LibraryImporter, DataStack
- `PulsumServices` (13 files) -- HealthKit, Speech, LLM Gateway, Keychain, NetworkMonitor
- `PulsumAgents` (24 files) -- orchestrator, Data/Sentiment/Coach/Safety/Cheer agents
- `PulsumUI` (22 files) -- SwiftUI views, view models, Liquid Glass design, onboarding

**Key Dependencies:** HealthKit, Speech, Foundation Models (iOS 26), SwiftData, Natural Language, Core ML, Accelerate, MetricKit, spline-ios v0.2.48. **Backend:** OpenAI GPT-5 via Responses API (consent-gated, BYOK).

---

## Critical Issues (Immediate Action Required)

### CRIT-01: NaN Target in StateEstimator.update() Corrupts All Weights

**Severity:** Critical
**Category:** ML Correctness
**File:** `Packages/PulsumML/Sources/PulsumML/StateEstimator.swift:78`
**Effort:** S

**Description:** The `update(features:target:)` method guards against NaN in `features` (line 79) but NOT in `target`. If `target` is NaN: `error = NaN - prediction = NaN`, then `weights[k] += learningRate * NaN = NaN` for every weight. All subsequent predictions return NaN. The model is permanently corrupted until the state file is deleted or reinitialized.

**Impact:** A single NaN target value (which can originate from WellbeingModeling.computeTarget when baselines are missing) permanently destroys the wellbeing score model. The user sees NaN/undefined scores until app data is deleted.

**Evidence:**
```swift
// Line 78-88:
func update(features: [String: Double], target: Double) {
    guard !features.values.contains(where: \.isNaN) else { return } // guards features...
    // BUT: no guard on `target`
    let prediction = predict(features: features)
    let error = target - prediction  // if target is NaN, error is NaN
    for (key, value) in features {
        weights[key, default: 0] += learningRate * error * value // NaN propagates
    }
}
```

**Fix:** Add `guard !target.isNaN else { return }` after the features guard.

**Verification:** Test: call `update(features: ["x": 1.0], target: .nan)`, verify weights unchanged.

---

### CRIT-02: NaN Embeddings Cause SafetyLocal to Classify Crisis Text as .safe

**Severity:** Critical
**Category:** Safety
**File:** `Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift:69-143`
**Effort:** S

**Description:** If the embedding service returns vectors containing NaN values, cosine similarity computations produce NaN. All threshold comparisons (`score >= 0.65`, etc.) evaluate to `false` for NaN, causing the classifier to fall through all branches and return `.safe` as the default. Crisis-level text could bypass safety classification entirely.

**Impact:** A malfunctioning embedding provider that returns NaN values would cause all safety classifications to return `.safe`, including genuine crisis content like "I want to kill myself". This defeats the entire two-wall safety system.

**Fix:** Add NaN check before cosine similarity comparison: `guard !score.isNaN else { return .caution(reason: "Safety classification unavailable") }`. Also validate embedding vectors in `EmbeddingService.validated()` to reject vectors containing NaN.

---

### CRIT-03: AgentOrchestrator is @MainActor -- Blocks UI Thread

**Severity:** Critical
**Category:** Concurrency
**File:** `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:162`
**Effort:** L

**Description:** `AgentOrchestrator` is marked `@MainActor` (line 162), meaning ALL orchestration work runs on the main thread: safety classification, topic gating, embedding computation, LLM inference, recommendation ranking, and HealthKit data processing. The orchestrator coordinates 5 agents and calls into PulsumML for safety/topic/sentiment analysis.

**Impact:** UI freezes during: (1) chat message processing (safety + topic gate + LLM call), (2) recommendation refresh (data fetch + ranking + coverage), (3) voice journal save (sentiment + embedding + SwiftData). Any operation that takes >16ms blocks frame rendering.

**Fix:** Move orchestrator off `@MainActor`. Use `@ModelActor` for SwiftData-dependent operations, or convert to a plain actor. ViewModels (which ARE `@MainActor`) should `await` orchestrator methods across actor boundaries.

---

### CRIT-04: RobustStats Public Init Allows mad=0 -- Division by Zero

**Severity:** Critical
**Category:** ML Correctness
**File:** `Packages/PulsumML/Sources/PulsumML/BaselineMath.swift:8`
**Effort:** S

**Description:** `RobustStats` has a public `init(median:mad:)` with no validation. While the factory method `robustStats(for:)` clamps MAD to `max(mad, 1e-6)`, the public init allows `mad: 0`. The `zScore(_:)` method computes `(value - median) / mad`, causing division by zero.

**Impact:** Any code path that constructs `RobustStats` directly with `mad: 0` (e.g., single data point, or manual construction in tests) causes a floating-point infinity that propagates through z-score normalization, corrupting feature vectors and wellbeing scores.

**Fix:** Add `precondition(mad > 0)` in `init`, or clamp: `self.mad = max(mad, 1e-6)`.

---

### CRIT-05: PulsumServicesDependencyTests Calls Nonexistent Method -- Won't Compile

**Severity:** Critical
**Category:** Build
**File:** `Packages/PulsumServices/Tests/PulsumServicesTests/PulsumServicesDependencyTests.swift:6`
**Effort:** S

**Description:** The test calls `PulsumServices.storageMetadata()` which does not exist in the current `Placeholder.swift` source file. This test target will fail to compile.

**Fix:** Either add the `storageMetadata()` method to `PulsumServices` enum, or update the test to call an existing API.

---

## High-Priority Issues

### HIGH-01: Embedding Dimension Inconsistency

**File:** `Packages/PulsumML/Sources/PulsumML/Embedding/AFMTextEmbeddingProvider.swift:11`
**Category:** ML Correctness | **Effort:** M

`NLEmbedding.sentenceEmbedding` returns 512-dim vectors; `NLEmbedding.wordEmbedding` returns 300-dim. Both are adjusted to 384 via truncation (discards last 128 dims) or padding (adds 84 zeros). Vectors from different sources occupy different subspaces -- cosine similarity between truncated sentence vectors and padded word vectors is geometrically meaningless. The `targetDimension = 384` is arbitrary and matches neither native format.

**Fix:** Use a single embedding source consistently. If sentence embedding is available, always use it. If not, use word embedding exclusively -- never mix. Consider keeping the native dimension instead of forcing 384.

---

### HIGH-02: Zero Localization Across Entire UI Layer

**Files:** All 22 PulsumUI source files
**Category:** App Store Compliance | **Effort:** L

No `String(localized:)` usage found anywhere in the codebase. All user-facing strings are hardcoded English: onboarding text, medical disclaimers, consent banners, error messages, button labels, health descriptions, safety messages, score interpretations. The `Localizable.xcstrings` catalog is empty. Apple requires localization support for App Store submission.

---

### HIGH-03: US-Only Crisis Resources

**Files:** `Packages/PulsumUI/Sources/PulsumUI/SafetyCardView.swift`, `Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift`
**Category:** Safety | **Effort:** M

SafetyCardView hardcodes US crisis numbers (911, 988) with force unwraps: `URL(string: "tel://911")!`. While `SafetyAgent.swift` (line 117) has locale-aware crisis resources for 11 countries, the UI layer only displays US numbers. Non-US users seeing a crisis card get irrelevant emergency numbers.

**Fix:** Pass locale-aware crisis info from SafetyAgent through to SafetyCardView. Use `Locale.current.region` to select appropriate numbers.

---

### HIGH-04: 15+ @unchecked Sendable Annotations

**Files:** Multiple across all packages
**Category:** Concurrency | **Effort:** L

The codebase has `@unchecked Sendable` on: `EmbeddingService`, `SafetyLocal`, `EmbeddingTopicGateProvider`, `FoundationModelsTopicGateProvider`, `FoundationModelsSafetyProvider`, `FoundationModelsSentimentProvider`, `SentimentService`, `LibraryImporter`, `HealthKitService`, `HealthKitAnchorStore`, `LLMGateway`, `NetworkMonitor`, `LegacySpeechBackend`, `EstimatorStateStore`, `RecRankerStateStore`, `CrashDiagnosticsSubscriber`, `JournalSessionState`, `HealthAccessStatus`. Most use DispatchQueue serialization, which is functionally correct but violates the project rule "Do NOT use `@unchecked Sendable` on new code". Each should be evaluated for conversion to `actor` or proper `Sendable` conformance.

---

### HIGH-05: RecRankerStateStore Lacks Thread Safety

**File:** `Packages/PulsumAgents/Sources/PulsumAgents/RecRankerStateStore.swift`
**Category:** Concurrency | **Effort:** S

Unlike `EstimatorStateStore` and `BackfillStateStore` (which use dispatch queues), `RecRankerStateStore` performs file I/O without any serialization. Concurrent `saveState`/`loadState` calls could corrupt the persisted ranker weights.

**Fix:** Add `ioQueue: DispatchQueue` (matching `EstimatorStateStore` pattern), or convert to actor.

---

### HIGH-06: ModelContext Held Across Await in LibraryImporter

**File:** `Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift:101-174`
**Category:** Concurrency | **Effort:** M

`ModelContext` is created on line 101, used across multiple `await` points (lines 118, 133), and saved on line 174. SwiftData contexts have thread affinity -- if the continuation resumes on a different thread, context operations may be unsafe.

**Fix:** Use `@ModelActor` pattern, or scope context operations to non-async blocks using `context.performAndWait` equivalent.

---

### HIGH-07: SentimentAgent Has No Explicit Actor Isolation

**File:** `Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift:29`
**Category:** Concurrency | **Effort:** M

`SentimentAgent` is a `final class` (not an actor) but uses `ModelContext` directly (line 56). It relies on the `SentimentAgentProviding` protocol being `@MainActor` for call-site isolation, but there's no compile-time guarantee. Direct construction and use from a background context would be unsafe.

**Fix:** Add explicit `@MainActor` annotation or convert to `@ModelActor`.

---

### HIGH-08: Certificate "Pinning" is Mislabeled

**File:** `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:948-984`
**Category:** Security | **Effort:** M

Comments claim "SPKI pinning against Let's Encrypt and DigiCert root CAs" but the implementation performs standard `SecTrustEvaluateWithError` trust evaluation with no hardcoded public key hashes. This provides no additional security beyond the system trust store.

**Fix:** Either implement actual SPKI pinning with hardcoded key hashes, or update the comments to accurately describe the behavior as "standard TLS trust evaluation."

---

### HIGH-09: Misleading Privacy Description in Settings

**File:** `Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift:487`
**Category:** Compliance | **Effort:** S

Settings says "NSFileProtectionComplete" but the project uses `NSFileProtectionCompleteUnlessOpen` (required for HealthKit background delivery while device is locked). This is misleading user-facing text about data security.

**Fix:** Update to "NSFileProtectionCompleteUnlessOpen" with a brief explanation of why.

---

### HIGH-10: PIIRedactor Coverage Gaps

**File:** `Packages/PulsumML/Sources/PulsumML/PIIRedactor.swift`
**Category:** Privacy | **Effort:** M

Missing PII patterns: date of birth, passport numbers, medical record numbers, bank account numbers. Phone regex doesn't handle parenthesized area codes `(555)`. Street address regex is US-only. Regex is compiled fresh on every `redact()` call instead of being cached statically.

---

### HIGH-11: Prompt Injection in Foundation Models Providers

**Files:** `FoundationModelsSentimentProvider.swift`, `FoundationModelsSafetyProvider.swift`, `FoundationModelsTopicGateProvider.swift`
**Category:** Security | **Effort:** M

All three providers directly interpolate user text into prompts: `"Classify: '\(text)'"`, `"Assess safety of this text: \(text)"`. Adversarial input can manipulate the model's behavior by injecting instructions.

**Fix:** Use structured input/output via `@Generable` types instead of string interpolation. If string prompts are required, sanitize and escape user input.

---

### HIGH-12: English-Only Embeddings

**File:** `Packages/PulsumML/Sources/PulsumML/Embedding/AFMTextEmbeddingProvider.swift:21`
**Category:** ML Correctness | **Effort:** M

`NLEmbedding` is hardcoded to `.english`. Non-English input produces low-quality or zero-vector embeddings, causing safety classification, topic gating, and recommendation matching to fail silently for non-English users.

---

### HIGH-13: JournalSessionState Uses @unchecked Sendable

**File:** `Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift:359`
**Category:** Concurrency | **Effort:** S

`JournalSessionState` uses a `DispatchQueue` for thread safety (correct functionally) but violates the project's `@unchecked Sendable` prohibition. The `updateTranscript` method uses `queue.async` (fire-and-forget) creating a potential race with `takeSession()`.

---

### HIGH-14: Massive Code Duplication in DataAgent+Backfill.swift

**File:** `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent+Backfill.swift`
**Category:** Maintainability | **Effort:** L

1502 lines -- the largest file in the codebase. Bootstrap/retry/fallback logic contains near-identical switch-case blocks repeated ~3 times (~600 lines of duplication). Changes to sample processing must be applied in multiple places.

**Fix:** Extract a shared `fetchSamplesForType(type:window:timeout:)` method and a shared `processBootstrapBatch(types:window:timeout:)` to eliminate the triplicated logic.

---

### HIGH-15: Force Unwraps in Production Code

**Files:** `VectorStore.swift:133,177`, `SafetyCardView.swift:36,51`, `SettingsView.swift:399,432,445,475`
**Category:** Code Quality | **Effort:** S

8 force unwraps in production code. VectorStore's `baseAddress!` is safe but fragile. SafetyCardView/SettingsView URL constructions from string constants are safe but violate project rules.

---

### HIGH-16: Potential Unaligned Memory Access in VectorStore

**File:** `Packages/PulsumData/Sources/PulsumData/VectorStore.swift:177`
**Category:** Correctness | **Effort:** S

`assumingMemoryBound(to: Float.self)` at byte offset `cursor` which may not be 4-byte aligned after reading variable-length UTF-8 string IDs. While ARM64/x86-64 handle unaligned reads, this is technically undefined behavior in Swift.

**Fix:** Copy bytes to a properly aligned buffer before interpreting as Float, or use `withUnsafeBytes` with manual byte reading.

---

### HIGH-17: Silent Error Swallowing in SentimentService

**File:** `Packages/PulsumML/Sources/PulsumML/SentimentService.swift`
**Category:** Observability | **Effort:** S

All provider errors in the fallback chain are caught and discarded with no logging. When all providers fail, the error is swallowed silently, making sentiment failure diagnosis impossible in production.

---

### HIGH-18: Topic Gate Fail-Open in Degraded Mode

**File:** `Packages/PulsumML/Sources/PulsumML/TopicGate/EmbeddingTopicGateProvider.swift:100-166`
**Category:** Safety | **Effort:** M

When embeddings are unavailable or prototypes are empty, the topic gate returns `isOnTopic: true` with confidence 0.1. This allows ALL input through, including off-topic queries. In degraded mode, the entire topic filtering layer is disabled.

---

## Medium-Priority Issues

| ID | File(s) | Description | Effort |
|---|---|---|---|
| MED-01 | `SafetyLocal.swift`, `EmbeddingTopicGateProvider.swift`, `AFMSentimentProvider.swift` | Cosine similarity duplicated 3 times -- extract to shared utility | S |
| MED-02 | `VectorIndexManager.swift:36` | Persist-per-upsert: each `upsertMicroMoment` triggers file write; inefficient during bulk import | S |
| MED-03 | `CoachView.swift:248` | Foundation Models status checked via string comparison (`"Apple Intelligence is ready."`) -- fragile | S |
| MED-04 | `EvidenceScorer.swift:18,25` | `harvard.edu` in `mediumDomains` unreachable (`.edu` in `strongDomains` matches first); `.gov`/`.edu` TLDs overly broad | S |
| MED-05 | `DailyMetrics.swift`, `FeatureVector.swift` | `@Attribute(.unique) date` requires callers to normalize dates to midnight -- no guard in model | S |
| MED-06 | `CoachAgent+Coverage.swift:102` | Sparse data fallback always returns `.soft` regardless of query relevance -- poor UX during onboarding | M |
| MED-07 | `DataAgent+Ingestion.swift:179-190` | `shouldIgnoreBackgroundDeliveryError` checks `localizedDescription` for substring -- fragile across OS versions | S |
| MED-08 | `CoachViewModel.swift:476-479` | `deinit` doesn't cancel `recommendationsTask`, `recommendationsDebounceTask`, `recommendationsSoftTimeoutTask` | S |
| MED-09 | Multiple UI files | Hardcoded font sizes: `CoachView.swift:37,62`, `OnboardingView.swift:66`, `PulsumRootView.swift:116,136` | S |
| MED-10 | `AgentOrchestrator.swift`, `CoachAgent.swift` | Several response types (`RecommendationResponse`, `CheerEvent`, `SafetyDecision`, `JournalResult`) not marked `Sendable` | M |
| MED-11 | `PulsumUITestsLaunchTests.swift` | Launch test lacks environment setup -- launches without stubs, may cause flaky CI | S |
| MED-12 | `Gate3_HealthAccessUITests.swift`, `SettingsAndCoachUITests.swift` | Silent test passes: `openSettingsSheetOrSkip()` returns `Bool` (not throws), tests pass silently on failure | S |
| MED-13 | `build-release.sh`, `test-harness.sh` | Outdated simulator lists reference iPhone 16/15 series; CLAUDE.md says iPhone 17 series | S |
| MED-14 | `check-privacy-manifests.sh:33-39` | Privacy manifest validation has empty expectations `{}` -- only checks file existence, not content | S |
| MED-15 | `PIIRedactor.swift` | `NSRegularExpression` compiled fresh on every `redact()` call -- should be cached statically | S |
| MED-16 | `ModernSpeechBackend` line 545 | `nonisolated(unsafe) static var availabilityOverride` not lock-protected (unlike `BuildFlags._modernSpeechOverride`) | S |
| MED-17 | `PrivacyInfo.xcprivacy` (PulsumServices) | No privacy declaration for Keychain API or NWPathMonitor usage | S |
| MED-18 | `ModelSnapshots+Extensions.swift` | No snapshot extensions for `UserPrefs` and `ConsentState` models | S |
| MED-19 | `TextEmbeddingProviding`, `SentimentProviding` | Protocols lack `Sendable` conformance despite being used in `Sendable`-required contexts | S |
| MED-20 | `ConsentStore` (AppViewModel.swift:593) | When revoking consent that was never granted, creates a grant+revoke record simultaneously | S |
| MED-21 | `MainContainerView`, `SettingsScreen` | Wellbeing score card view duplicated between two files | S |
| MED-22 | `RateLimiter.swift:14` | Uses `Date()` (wall-clock) for timing instead of `ContinuousClock` -- NTP drift risk | S |
| MED-23 | `FoundationModelsCoachGenerator.swift:82-86` | Topic parsing assumes `"topic="` prefix format -- silent failure if format changes | S |
| MED-24 | `LLMGateway.swift:545,579-588` | `validateChatPayload` contains redundant double-check of `body["input"]` | S |

---

## Low-Priority Issues

| ID | File(s) | Description | Effort |
|---|---|---|---|
| LOW-01 | `LiquidGlassComponents.swift` | `LiquidGlassTabBar` defined but never used in any view -- dead code | S |
| LOW-02 | `DiagnosticsSpanToken` (PulsumTypes) | Not marked `Sendable` -- cannot be safely passed across actors | S |
| LOW-03 | `podcastrecommendations 2.json` | Filename contains space -- macOS duplicate naming convention | S |
| LOW-04 | `PulsumUITestCase.swift:249` | Uses KVC `value(forKey: "hasKeyboardFocus")` -- private API, may break across Xcode versions | S |
| LOW-05 | `DataStackSecurityTests.swift` / `Gate0_DataStackSecurityTests.swift` | Near-identical duplicate tests | S |
| LOW-06 | `PulsumData.swift` | Empty file -- only comments, no code | S |
| LOW-07 | `TestCoreDataStack.swift` | Duplicated identically in PulsumAgents, PulsumUI, and PulsumData test targets | S |
| LOW-08 | `AgentOrchestrator.swift` | `dominantTopic` function has unused `coachAgent` parameter (underscore) | S |
| LOW-09 | `DataAgent.swift` | `healthCheck` only validates non-empty paths, not file existence | S |
| LOW-10 | `DataAgent+SampleProcessing.swift:15` | Fire-and-forget `Task { await self.handle(...) }` in HK observer callback | S |
| LOW-11 | `SafetyAgent.swift:44-46` | Crisis keyword downgrade could miss novel crisis expressions not in keyword list | S |
| LOW-12 | `PrivacyInfo.xcprivacy` (PulsumData) | Missing explicit `NSPrivacyTracking` key (defaults to false but should be explicit) | S |
| LOW-13 | `AFMTextEmbeddingProvider.swift:19-20` | Dead code: `availability` property stored but never read | S |
| LOW-14 | `PulsumML/Package.swift` | Accelerate framework linked but not directly used in any ML source file (used in PulsumData VectorStore) | S |
| LOW-15 | `PulsumTests.swift` | Near-zero coverage: single `#expect(true)` assertion | S |
| LOW-16 | `Localizable.xcstrings` | Empty string catalog -- no localized strings defined | S |
| LOW-17 | `AppViewModel.swift:564` | `ConsentStore.saveConsent` creates new `ModelContext` on every call | S |
| LOW-18 | `LLMGateway.swift:658` | `GPT5Client.endpoint` falls back to `URL(fileURLWithPath: "/invalid")` -- dead code path | S |
| LOW-19 | `NotificationNames.swift` (PulsumTypes) | Notification name inconsistency between declaration and usage | S |
| LOW-20 | `PulsumUITestCase.swift:145` | Hard-coded UI strings in `dismissKeyboardIfPresent()` -- fragile | S |

---

## Test Coverage Gaps

| ID | Area | Missing Coverage | Priority |
|---|---|---|---|
| TC-01 | `PIIRedactor` | Zero test coverage for PII redaction logic | HIGH |
| TC-02 | `SentimentService` | No tests for provider fallback chain | HIGH |
| TC-03 | `StateEstimator` | No test for NaN target parameter (only NaN features tested) | CRIT |
| TC-04 | `FoundationModelsAvailability` | Status mapping logic untested | MED |
| TC-05 | `RecRanker` | No tests for `adaptWeights` or `updateLearningRate` | MED |
| TC-06 | `PulseViewModel` | Zero test coverage | MED |
| TC-07 | `SettingsViewModel` | No tests for consent toggle, data deletion | MED |
| TC-08 | `DiagnosticsViewModel` | Zero test coverage | LOW |
| TC-09 | `ScoreBreakdownViewModel` | Zero test coverage | LOW |
| TC-10 | `ConsentStore` | No tests for consent persistence, history tracking | MED |
| TC-11 | `NaturalLanguageSentimentProvider` | No isolated tests (only integration) | LOW |
| TC-12 | `CoreMLSentimentProvider` | No isolated tests (only integration) | LOW |
| TC-13 | `AppViewModel` | No tests for startup flow, consent observation, data deletion | MED |
| TC-14 | Test framework | All PulsumUI tests use XCTest; project prefers Swift Testing for new tests | LOW |
| TC-15 | Mock providers | Duplicate mock providers across test files (`ConstantEmbeddingProvider`, `FailingEmbeddingProvider`, etc.) | LOW |
| TC-16 | SafetyLocal | No tests for NaN embedding edge case | CRIT |
| TC-17 | `HealthSettingsViewModel` | Only 1 test covering authorization flow | MED |
| TC-18 | `VectorStore` | No test for unaligned memory access edge case | MED |
| TC-19 | `OnboardingView` | Zero test coverage for onboarding flow | LOW |
| TC-20 | `SafetyCardView` | No test for crisis card display | MED |

---

## Cross-Cutting Analysis

### 1. Architecture & Dependency Graph

The 6-package dependency graph is acyclic and correctly enforced via SPM:
```
PulsumTypes (leaf)
  -> PulsumML (+ Accelerate)
  -> PulsumData (SwiftData models, VectorStore)
       -> PulsumServices (HealthKit, Speech, LLM, Keychain)
            -> PulsumAgents (orchestration, agents)
                 -> PulsumUI (SwiftUI, ViewModels)
                      -> App (PulsumApp.swift)
```

All packages target iOS 26.0 / macOS v15 with swift-tools-version 6.1. Single external dependency: spline-ios v0.2.48 (3D animation).

**Finding:** `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` is correctly set only on the app target and NOT on SPM packages (verified in project.pbxproj).

### 2. SwiftData Integration

Migration from Core Data is complete. 9 `@Model` classes exist with proper indexes and unique constraints. The DTO snapshot pattern (`ModelSnapshots+Extensions.swift`) correctly creates `Sendable` snapshots from non-Sendable `@Model` objects. `DataStack` exposes `modelTypes` for container creation and `storagePaths` for file management.

**Remaining issues:** `LibraryImporter` holds `ModelContext` across `await` boundaries (HIGH-06). `SentimentAgent` uses `ModelContext` without explicit actor isolation (HIGH-07). `UserPrefs` and `ConsentState` lack snapshot extensions (MED-18).

### 3. Concurrency Model

The codebase uses Swift Concurrency throughout with no Combine. Key isolation patterns:
- `VectorStore`: actor (correct)
- `RecRanker`, `StateEstimator`: actors (correct)
- `DataAgent`: uses `ModelContext` with extensions (not `@ModelActor`)
- `CoachAgent`: `@MainActor` (correct for SwiftData via main context)
- `AgentOrchestrator`: `@MainActor` (incorrect -- CRIT-03)
- `EmbeddingService`: `@unchecked Sendable` with DispatchQueue
- `SpeechService`: actor (correct)
- `RateLimiter`: actor (correct)

**Primary concern:** 15+ `@unchecked Sendable` types (HIGH-04). Most use DispatchQueue serialization which is functionally correct but creates maintenance risk and violates project coding standards.

### 4. Safety System

Two-wall safety implementation:
- **Wall 1 (SafetyLocal):** Keyword matching + embedding similarity. Crisis keywords trigger immediate `.crisis`. Embedding similarity above 0.85 also triggers `.crisis` without keyword requirement. Between 0.65-0.85, downgrades to `.caution` unless keyword present.
- **Wall 2 (FoundationModelsSafetyProvider):** Structured LLM output with `.safe/.caution/.crisis` enum. Guardrail violations correctly return `.caution` (fixed from original `.safe`).
- **SafetyAgent orchestration:** Runs Wall 1 and Wall 2 with 5s timeout. If FM says `.crisis` but no crisis keywords found, downgrades to `.caution` (conservative).

**Gaps:** NaN embeddings bypass Wall 1 (CRIT-02). English-only embeddings (HIGH-12). Crisis keyword downgrade could miss novel expressions (LOW-11). Topic gate fail-open in degraded mode (HIGH-18).

### 5. HealthKit Integration

Comprehensive implementation in `HealthKitService.swift` (actor) with:
- 6 read types: HRV, heart rate, resting heart rate, respiratory rate, sleep analysis, step count
- Anchored queries with persistent anchor store (`HealthKitAnchorStore`)
- Background delivery with `enableBackgroundDeliveryForAllTypes()`
- Authorization probing with 30-second cache TTL
- Bootstrap strategy: 2-day -> fallback 30-day -> placeholder -> retry with exponential backoff
- Warm-start 7-day backfill, then full 30-day backfill in background

**File protection:** `NSFileProtectionCompleteUnlessOpen` correctly applied to anchor store directories and files (required for background delivery while device locked).

### 6. LLM Integration

`LLMGateway` handles cloud (GPT-5) and on-device (Foundation Models) routing:
- **Cloud:** OpenAI Responses API with structured JSON schema (`strict: true`), PII redaction via `PIIRedactor`, payload sanitization via `MinimizedCloudRequest` (field truncation + forbidden field guard), rate limiting (3s minimum interval), grounding floor validation (score >= 0.5)
- **On-device:** `FoundationModelsCoachGenerator` with temperature 0.6, guardrail/refusal handling, sanitized output (2 sentences, 280 chars each)
- **BYOK:** API key stored in Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`), 3-tier resolution (memory -> keychain -> env var)

**Certificate pinning mislabeled** (HIGH-08). **FoundationModelsCoachGenerator doesn't generate `nextAction`** -- on-device responses lack micro-action suggestions.

### 7. Voice Journal & Speech

`SpeechService` (actor) with:
- `LegacySpeechBackend`: SFSpeechRecognizer + AVAudioEngine, 30s max duration timeout
- `FakeSpeechBackend`: Scripted segments for UI tests
- `ModernSpeechBackend`: iOS 26+ placeholder (delegates to legacy)
- Audio levels: RMS power calculation with dB-to-linear normalization
- `SentimentAgent` manages session lifecycle, PII redaction, embedding persistence

### 8. ML Pipeline

- **Embeddings:** NLEmbedding (sentence/word) with CoreML fallback, dimension normalization to 384
- **Sentiment:** 3-provider fallback: Foundation Models -> CoreML -> NaturalLanguage
- **State estimation:** Online linear model with gradient descent, L2 regularization, NaN feature guards
- **Recommendation ranking:** Bradley-Terry pairwise logistic loss, adaptive learning rate, weight capping [-3, 3]
- **Wellbeing scoring:** 10-feature weighted sum (HRV +0.55, sleep debt -0.65, energy +0.45, etc.) with imputation adjustments

### 9. Privacy & Compliance

- **PII redaction:** Email, phone, SSN patterns. Gaps: DOB, passport, medical records (HIGH-10)
- **File protection:** `NSFileProtectionCompleteUnlessOpen` on all data directories
- **Backup exclusion:** Applied to PHI-containing directories
- **Privacy manifests:** 6 manifests across packages, all declare UserDefaults CA92.1
- **Medical disclaimer:** Present in onboarding (with checkbox), settings, and coach view
- **AI-generated content labeling:** "AI-generated" badge on assistant chat messages
- **Data deletion:** GDPR-compliant: SwiftData entities + vector index + keychain + UserDefaults + diagnostics
- **Consent gating:** Cloud API calls require explicit consent, persisted in SwiftData + UserDefaults

### 10. Build & CI

- **Build:** `xcodebuild` with DerivedData at `/tmp/PulsumDerivedData` (not iCloud)
- **Formatting:** swiftformat 0.59.1 with conservative config
- **CI scripts:** integrity.sh (comprehensive), scan-secrets.sh, scan-placeholders.sh, check-privacy-manifests.sh, build-release.sh, test-harness.sh, ui-tests.sh
- **Gate tests:** Discoverable via `Gate[0-9]+_` naming convention
- **UI tests:** 7 test files with stub environment (UITEST_USE_STUB_LLM, UITEST_FAKE_SPEECH, UITEST_AUTOGRANT)

**Issues:** Outdated simulator lists in build-release.sh/test-harness.sh (MED-13). Empty privacy manifest expectations (MED-14).

---

## Findings Summary Table

| Severity | Count | Status |
|---|---|---|
| Critical | 5 | All require immediate attention |
| High | 18 | Fix before App Store submission |
| Medium | 24 | Fix for production quality |
| Low | 20 | Fix when convenient |
| Test Gaps | 20 | Prioritize CRIT and HIGH-marked gaps |
| **Total** | **87** | |

---

## Comparison with Previous Audit

The original audit (2026-02-05) found 112 findings with a 3.5/10 health score. Key changes since Phase 0 remediation:

| Area | Before | After | Change |
|---|---|---|---|
| Health Score | 3.5/10 | 6.5/10 | +3.0 |
| Persistence | Core Data with fatalError crashes | SwiftData with graceful error handling | Fixed |
| Vector Index | Sharded with non-deterministic hash | VectorStore actor with Accelerate | Fixed |
| DataAgent | 3,706-line God Object | Decomposed into focused extensions | Fixed |
| SettingsVM | 573-line God Object | Split into 3 ViewModels | Fixed |
| Safety Provider | Guardrail violations returned .safe | Returns .caution | Fixed |
| Medical Disclaimer | None | Present in 3 locations | Fixed |
| GDPR Deletion | None | Complete data deletion implemented | Fixed |
| Crash Reporting | None | MetricKit CrashDiagnosticsSubscriber | Fixed |
| AI Content Label | None | "AI-generated" badge on chat messages | Fixed |
| Localization | None | Still none | Unchanged |
| @unchecked Sendable | Multiple | Still 15+ | Partially addressed |
| NaN handling | Not identified | New findings (CRIT-01, CRIT-02) | New |
| Test coverage | ~15% | Improved but gaps remain | Improved |

---

*End of report. Generated by automated analysis of all 191 files in the Pulsum codebase.*
