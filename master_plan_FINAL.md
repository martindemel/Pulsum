# Pulsum -- Master Remediation Plan (Post-Phase 0)

**Status:** Ready to execute | **Progress:** 6 / 74 items | **Est. effort:** 3-4 weeks
**Based on:** `master_report.md` (2026-02-14, 87 findings, health score 6.5/10)

---

## READ THIS FIRST

**Before starting any work, read this entire file.** Then read `master_report.md` for finding details.

### What's Already Done (Phase 0 -- Completed)

Phase 0 architecture remediation is complete on `refactor/phase0-architecture` branch:
- SwiftData migration (9 `@Model` classes, DTO snapshots, DataStack rewrite)
- VectorStore actor replaces sharded VectorIndex
- DataAgent decomposed into focused extensions
- SettingsViewModel split into 3 ViewModels
- FoundationModelsSafetyProvider returns `.caution` for guardrails
- SafetyAgent two-wall classification
- Crisis resources, medical disclaimers, AI content labeling
- GDPR data deletion, MetricKit crash diagnostics

### Critical Execution Warnings

**1. Batch ordering matters.** Batch 1 (safety-critical NaN fixes) must be first -- it prevents data corruption and safety bypasses. Batch 2 (concurrency) is the largest effort and enables Batch 3-6. Do not skip ahead.

**2. One item at a time.** Finish each item completely before moving to the next. Mark items done by changing `[ ]` to `[x]` and adding the date.

**3. Build-verify after every change.** Use the simulator build command after each modification:
```bash
xcodebuild -scheme Pulsum \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath /tmp/PulsumDerivedData \
  build
```

**4. Safe-point commits before each batch.** Commit current working state before starting a batch so changes can be reverted cleanly.

### Technical Guardrails

- **Prefer `actor` over `@unchecked Sendable` + locks.** If adding a lock forces `@unchecked Sendable`, convert to actor instead.
- **`@ModelActor` for SwiftData contexts.** Do not store `ModelContext` across `await` boundaries unless `@ModelActor`-owned.
- **`NSFileProtectionCompleteUnlessOpen`** (not Complete) -- HealthKit background delivery needs DB access while locked.
- **BYOK API key is accepted risk for v1.0.** Backend proxy in v1.1. See `master_plan_1_1_FUTURE.md`.
- **Use `Diagnostics.log()`** from PulsumTypes for all logging (not `print()`).
- **Use Swift Testing** for new tests, not XCTest.

| File | What It Contains | When to Read |
|---|---|---|
| `master_report.md` | 87 findings with full detail, evidence, suggested fixes | When implementing any item -- look up the finding ID |
| `guidelines_report.md` | App Store compliance checks | When implementing compliance work |
| `master_plan_1_1_FUTURE.md` | v1.1 roadmap (backend proxy, StoreKit, etc.) | After completing this plan |

---

## Project Context

| Property | Value |
|---|---|
| **Platform** | iOS 26+ only |
| **Language** | Swift 6.1 (`swift-tools-version: 6.1`) |
| **UI** | SwiftUI with `@Observable` (Observation framework) |
| **Concurrency** | Swift Concurrency (async/await, actors). `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (app target only) |
| **Persistence** | SwiftData (`@Model`, `FetchDescriptor`, `#Predicate`) |
| **Packages** | 6 SPM: PulsumTypes -> PulsumML + PulsumData -> PulsumServices -> PulsumAgents -> PulsumUI -> App |
| **External deps** | Spline (spline-ios v0.2.48) -- 3D animation only |
| **Backend** | OpenAI GPT-5 Responses API (consent-gated, BYOK API key) |
| **Frameworks** | HealthKit, Speech, Foundation Models, Core ML, Natural Language, Accelerate, MetricKit |
| **Users** | Zero. Fresh install every test. No data migration risk. |

---

## Rules for AI Agents

### DO

- **Read this entire file** at the start of every session.
- Work on **ONE item at a time**.
- **Mark items done** by changing `[ ]` to `[x]` and adding the date: `[x] *(2026-02-15)*`
- Look up the **finding ID** in `master_report.md` for full detail before implementing each item.
- Validate with build after each change.
- Run `swiftformat .` after each change.
- Use `#available(iOS 26.0, *)` guards for Foundation Models APIs.
- Use Swift Concurrency (`async`/`await`, `actor`) instead of Combine.
- Prefer `actor` for thread-safe mutable state over `@unchecked Sendable` + locks.
- Use `@ModelActor` for any actor that owns a SwiftData `ModelContext`.
- Reference the finding ID in commit messages (e.g., `fix: CRIT-01 -- NaN target guard in StateEstimator`).
- Use `String(localized:)` for all new user-facing strings.
- Use `Diagnostics.log()` from PulsumTypes for logging.
- Prefer Swift Testing framework for new unit tests.

### DO NOT

- Do NOT start Batch N+1 until Batch N is fully complete.
- Do NOT change multiple items in one commit.
- Do NOT refactor adjacent code "while you're in there."
- Do NOT add SPM dependencies without approval.
- Do NOT use `@unchecked Sendable` on new code.
- Do NOT use `fatalError()`, `preconditionFailure()`, or force unwraps (`!`).
- Do NOT use `print()` -- use `Diagnostics.log()`.
- Do NOT use Combine -- use async/await.
- Do NOT store `ModelContext` as a long-lived property -- use `@ModelActor`.

### Build & Verify

```bash
# Simulator build
xcodebuild -scheme Pulsum \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath /tmp/PulsumDerivedData \
  build

# Package tests
swift test --package-path Packages/PulsumML
swift test --package-path Packages/PulsumData
swift test --package-path Packages/PulsumServices
swift test --package-path Packages/PulsumAgents
swift test --package-path Packages/PulsumUI

# Format
swiftformat .

# Privacy manifests
scripts/ci/check-privacy-manifests.sh
```

---

## Architecture Decisions (Preserved from Phase 0)

| # | Decision | Choice | Reason |
|---|---|---|---|
| D1 | Persistence | **SwiftData** | Done. Zero users = zero migration risk. |
| D2 | Vector Index | **VectorStore actor** | Done. Single flat dict + Accelerate search. |
| D3 | Agents | **Keep 5, fix isolation** | Fix DI and threading, not structure. |
| D4 | Concurrency | **Actor isolation** | Mechanical change. Prevents ML inference contending with UI. |
| D5 | State observation | **@Observable + NotificationCenter** | Correct for cross-package events. |
| D6 | DataAgent | **Decomposed into extensions** | Done. Focused files under 1,500 lines each (except Backfill). |
| D7 | SettingsVM | **Split into 3 VMs** | Done. HealthSettingsVM, DiagnosticsVM, SettingsVM. |
| D8 | Monetization | **BYOK optional** | On-device is primary. Backend proxy in v1.1. |
| D9 | Packages | **Keep 6 as-is** | Correct dependency direction. |
| D10 | Localization | **String(localized:) for all UI strings** | Required for App Store. |

---

## Batch 1: Safety-Critical Fixes (5 items, ~1 day)

**Goal:** Fix NaN corruption paths and safety bypasses. These are data-destroying or safety-defeating bugs.

- [x] **B1-01** | CRIT-01: Add NaN guard on `target` in `StateEstimator.update()` *(2026-02-15)*

- [x] **B1-02** | CRIT-02: Add NaN guard in SafetyLocal cosine similarity + EmbeddingService NaN rejection *(2026-02-15)*

- [x] **B1-03** | CRIT-04: Clamp MAD in `RobustStats.init` *(2026-02-15)*

- [x] **B1-04** | CRIT-05: Fix PulsumServicesDependencyTests compilation *(2026-02-15 — stale test file deleted)*

- [x] **B1-05** | HIGH-05: Add dispatch queue to RecRankerStateStore *(2026-02-15)*

---

## Batch 2: Concurrency & Actor Isolation (8 items, ~3-4 days)

**Goal:** Fix `@MainActor` on orchestrator, reduce `@unchecked Sendable` surface, fix ModelContext isolation.

- [ ] **B2-01** | CRIT-03: Move AgentOrchestrator off `@MainActor`
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`
  **Change:** Remove `@MainActor` from `AgentOrchestrator`. Make it a plain class or actor. ViewModels call orchestrator methods via `await`. Agents that need `ModelContext` use `@ModelActor` or `@MainActor` independently.
  **Impact:** This is the largest single change -- requires updating all call sites in PulsumUI ViewModels.

- [ ] **B2-02** | HIGH-06: Fix LibraryImporter ModelContext across await
  **File:** `Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift`
  **Change:** Either convert to `@ModelActor` or restructure `ingestIfNeeded()` so that all `ModelContext` operations occur in a single non-async scope (collect async results first, then apply to context in one synchronous block).

- [ ] **B2-03** | HIGH-07: Add explicit actor isolation to SentimentAgent
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift`
  **Change:** Add `@MainActor` annotation to `SentimentAgent` class (matches `SentimentAgentProviding` protocol).

- [ ] **B2-04** | HIGH-13: Replace JournalSessionState @unchecked Sendable
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift`
  **Change:** Convert `JournalSessionState` to an `actor`. Replace `queue.async` fire-and-forget in `updateTranscript` with `await` call.

- [ ] **B2-05** | MED-10: Add Sendable to response types
  **Files:** `AgentOrchestrator.swift`, `CoachAgent.swift`, `SafetyAgent.swift`, `CheerAgent.swift`, `SentimentAgent.swift`
  **Change:** Add `: Sendable` to `RecommendationResponse`, `CheerEvent`, `JournalCaptureResponse`. *(SafetyDecision and JournalResult already done — 2026-02-15)*

- [ ] **B2-06** | MED-19: Add Sendable to provider protocols
  **Files:** `TextEmbeddingProviding.swift`, `SentimentProviding.swift`
  **Change:** Add `: Sendable` conformance.

- [ ] **B2-07** | MED-16: Add lock protection to ModernSpeechBackend override
  **File:** `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift`
  **Change:** Protect `nonisolated(unsafe) static var availabilityOverride` with a lock (matching `BuildFlags._modernSpeechOverride` pattern).

- [ ] **B2-08** | LOW-02: Add Sendable to DiagnosticsSpanToken
  **File:** `Packages/PulsumTypes/Sources/PulsumTypes/DiagnosticsSpanToken.swift`
  **Change:** Add `: Sendable` conformance.

---

## Batch 3: ML Correctness (5 items, ~2 days)

**Goal:** Fix embedding dimension issues, NaN propagation paths, and code duplication in ML layer.

- [ ] **B3-01** | HIGH-01: Fix embedding dimension inconsistency
  **File:** `Packages/PulsumML/Sources/PulsumML/Embedding/AFMTextEmbeddingProvider.swift`
  **Change:** Prefer sentence embedding consistently. When sentence embedding is unavailable, log a warning and use word embedding with a distinct flag so downstream code knows the source. Do not mix vectors from different embedding types in the same cosine similarity comparison.

- [ ] **B3-02** | HIGH-12: Add locale-aware embedding selection
  **File:** `Packages/PulsumML/Sources/PulsumML/Embedding/AFMTextEmbeddingProvider.swift`
  **Change:** Use `Locale.current.language.languageCode` to select embedding language. Fall back to `.english` when the user's language is not supported by NLEmbedding.

- [ ] **B3-03** | HIGH-17: Add logging to SentimentService fallback chain
  **File:** `Packages/PulsumML/Sources/PulsumML/SentimentService.swift`
  **Change:** Log provider errors via `Diagnostics.log()` before falling to the next provider. Log a summary when all providers fail.

- [ ] **B3-04** | MED-01: Extract shared cosine similarity utility
  **Files:** `SafetyLocal.swift`, `EmbeddingTopicGateProvider.swift`, `AFMSentimentProvider.swift`
  **Change:** Create `CosineSimilarity.swift` in PulsumML with a single `static func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float` and replace all 3 duplications.

- [ ] **B3-05** | MED-15: Cache PIIRedactor regex patterns
  **File:** `Packages/PulsumML/Sources/PulsumML/PIIRedactor.swift`
  **Change:** Move `NSRegularExpression` compilation to static `let` properties instead of compiling per `redact()` call.

---

## Batch 4: Safety & Privacy (6 items, ~2 days)

**Goal:** Fix safety gaps, prompt injection, privacy declarations, crisis resources.

- [ ] **B4-01** | HIGH-03: Pass locale-aware crisis resources to SafetyCardView
  **Files:** `SafetyCardView.swift`, `SafetyAgent.swift`, `AgentOrchestrator.swift`
  **Change:** `SafetyDecision` should include locale-aware crisis info from `SafetyAgent.crisisResources(for:)`. `SafetyCardView` renders the passed resources instead of hardcoded US numbers.

- [ ] **B4-02** | HIGH-10: Expand PIIRedactor patterns
  **File:** `Packages/PulsumML/Sources/PulsumML/PIIRedactor.swift`
  **Change:** Add patterns for: date of birth (`\b\d{1,2}/\d{1,2}/\d{2,4}\b`), parenthesized phone area codes (`\(\d{3}\)\s*\d{3}[-.]?\d{4}`), medical record numbers. Make street address regex configurable.

- [ ] **B4-03** | HIGH-11: Mitigate prompt injection in FM providers
  **Files:** `FoundationModelsSentimentProvider.swift`, `FoundationModelsSafetyProvider.swift`, `FoundationModelsTopicGateProvider.swift`
  **Change:** Wrap user text in a clearly delimited block: `"<user_input>\(text)</user_input>"` and instruct the system prompt to only process content within these tags. This is defense-in-depth, not a complete fix.

- [ ] **B4-04** | HIGH-09: Fix misleading privacy description in Settings
  **File:** `Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift`
  **Change:** Line 487: Update "NSFileProtectionComplete" to "NSFileProtectionCompleteUnlessOpen (required for background health data sync)".

- [ ] **B4-05** | MED-17: Add privacy declarations for Keychain and NWPathMonitor
  **File:** `Packages/PulsumServices/Sources/PulsumServices/PrivacyInfo.xcprivacy`
  **Change:** Add accessed API types for Keychain usage if required by Apple's evolving privacy manifest requirements.

- [ ] **B4-06** | LOW-12: Add explicit NSPrivacyTracking key to PulsumData manifest
  **File:** `Packages/PulsumData/Sources/PulsumData/PrivacyInfo.xcprivacy`
  **Change:** Add `<key>NSPrivacyTracking</key><false/>` explicitly.

---

## Batch 5: Security & LLM (4 items, ~1 day)

**Goal:** Fix certificate pinning documentation, force unwraps, LLM validation issues.

- [ ] **B5-01** | HIGH-08: Fix certificate pinning documentation
  **File:** `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift`
  **Change:** Update comments on lines 948-951 to accurately describe behavior as "standard TLS trust evaluation" rather than "SPKI pinning". If actual pinning is desired, implement with hardcoded key hashes.

- [ ] **B5-02** | HIGH-15: Eliminate force unwraps in production code
  **Files:** `VectorStore.swift`, `SafetyCardView.swift`, `SettingsView.swift`
  **Change:** Replace `baseAddress!` with `guard let baseAddress = buffer.baseAddress else { throw VectorStoreError.corruptFile }`. Replace URL force unwraps with `guard let url = URL(string: ...) else { return }`.

- [x] **B5-03** | HIGH-16: Fix potential unaligned memory access in VectorStore *(2026-02-15 — safe byte copy via unsafeUninitializedCapacity)*

- [ ] **B5-04** | MED-24: Remove redundant validation in LLMGateway
  **File:** `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift`
  **Change:** Remove the redundant double-check of `body["input"]` in `validateChatPayload` (lines 579-588).

---

## Batch 6: UI & Accessibility (7 items, ~2 days)

**Goal:** Begin localization infrastructure, fix UI issues, improve accessibility.

- [ ] **B6-01** | HIGH-02 (partial): Set up localization infrastructure
  **Files:** `Localizable.xcstrings`, all PulsumUI source files
  **Change:** Replace the highest-priority hardcoded strings with `String(localized:)`: medical disclaimer, consent banner, onboarding text, error messages, safety card text. Do NOT attempt to localize everything at once -- focus on user-safety-critical strings first.

- [ ] **B6-02** | MED-03: Replace Foundation Models status string comparison
  **File:** `Packages/PulsumUI/Sources/PulsumUI/CoachView.swift`
  **Change:** Replace `foundationStatus != "Apple Intelligence is ready."` with a typed enum or boolean flag from the ViewModel.

- [ ] **B6-03** | MED-08: Cancel all tasks in CoachViewModel deinit
  **File:** `Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift`
  **Change:** Add `recommendationsTask?.cancel()`, `recommendationsDebounceTask?.cancel()`, `recommendationsSoftTimeoutTask?.cancel()` in `deinit`.

- [ ] **B6-04** | MED-09: Replace hardcoded font sizes with Dynamic Type
  **Files:** `CoachView.swift`, `PulsumRootView.swift`
  **Change:** Replace `.font(.system(size: N))` with `.font(.headline)`, `.font(.subheadline)`, etc. for text elements. Decorative icon sizes can remain hardcoded.

- [ ] **B6-05** | MED-21: Extract shared wellbeing card component
  **Files:** `PulsumRootView.swift`, `SettingsView.swift`
  **Change:** Extract the duplicated wellbeing score card into a shared `WellbeingScoreCardView.swift` and use it in both locations.

- [ ] **B6-06** | MED-12: Fix silent test passes in UI tests
  **Files:** `Gate3_HealthAccessUITests.swift`, `SettingsAndCoachUITests.swift`
  **Change:** Replace `guard openSettingsSheetOrSkip() else { return }` with `try XCTSkipUnless(openSettingsSheetOrSkip())` to make failures visible.

- [ ] **B6-07** | MED-11: Add environment setup to PulsumUITestsLaunchTests
  **File:** `PulsumUITests/PulsumUITestsLaunchTests.swift`
  **Change:** Extend `PulsumUITestCase` instead of `XCTestCase` to inherit the stub environment, or add explicit environment variable setup.

---

## Batch 7: Test Coverage (12 items, ~3 days)

**Goal:** Fill critical and high-priority test coverage gaps.

- [ ] **B7-01** | TC-01: Add PIIRedactor tests
  **File:** Create `Packages/PulsumML/Tests/PulsumMLTests/PIIRedactorTests.swift`
  **Tests:** Email redaction, phone number redaction (with/without area code parens), SSN redaction, mixed PII, clean text preservation, empty input.

- [ ] **B7-02** | TC-02: Add SentimentService fallback chain tests
  **File:** Create `Packages/PulsumML/Tests/PulsumMLTests/SentimentServiceFallbackTests.swift`
  **Tests:** Primary succeeds (fallback not called), primary fails -> fallback used, all providers fail -> error thrown.

- [ ] **B7-03** | TC-03: Add NaN target test for StateEstimator
  **File:** `Packages/PulsumML/Tests/PulsumMLTests/WellbeingScorePipelineTests.swift`
  **Test:** `test_update_nanTarget_weightsUnchanged` -- verify weights remain unchanged after update with NaN target.

- [ ] **B7-04** | TC-16: Add NaN embedding test for SafetyLocal
  **File:** `Packages/PulsumML/Tests/PulsumMLTests/SafetyClassifierTests.swift`
  **Test:** `test_nanEmbedding_returnsCaution` -- inject embedding provider that returns NaN vectors, verify crisis text returns `.caution` not `.safe`.

- [ ] **B7-05** | TC-05: Add RecRanker adaptWeights/updateLearningRate tests
  **File:** `Packages/PulsumML/Tests/PulsumMLTests/PackageEmbedTests.swift`
  **Tests:** `test_adaptWeights_changesWeights`, `test_updateLearningRate_adjustsRate`.

- [ ] **B7-06** | TC-06: Add PulseViewModel tests
  **File:** Create `Packages/PulsumUI/Tests/PulsumUITests/PulseViewModelTests.swift`
  **Tests:** Voice journal start/stop lifecycle, audio level updates, recording state transitions.

- [ ] **B7-07** | TC-07: Add SettingsViewModel consent tests
  **File:** Create `Packages/PulsumUI/Tests/PulsumUITests/SettingsViewModelTests.swift`
  **Tests:** Toggle consent on/off, consent signal propagation, API key save/test.

- [ ] **B7-08** | TC-10: Add ConsentStore tests
  **File:** Create `Packages/PulsumUI/Tests/PulsumUITests/ConsentStoreTests.swift`
  **Tests:** Grant consent persistence, revoke consent persistence, consent history versioning.

- [ ] **B7-09** | TC-13: Add AppViewModel startup tests
  **File:** Create `Packages/PulsumUI/Tests/PulsumUITests/AppViewModelTests.swift`
  **Tests:** Startup state transitions (idle -> loading -> ready), failure state, UITest mode skips heavy work.

- [ ] **B7-10** | TC-17: Add HealthSettingsViewModel tests
  **File:** `Packages/PulsumUI/Tests/PulsumUITests/SettingsViewModelHealthAccessTests.swift`
  **Tests:** Partial health access display, full grant flow, unavailable banner, toast display.

- [ ] **B7-11** | TC-18: Add VectorStore unaligned access test
  **File:** `Packages/PulsumData/Tests/PulsumDataTests/VectorIndexTests.swift`
  **Test:** Upsert entries with odd-length IDs (1, 3, 5 bytes), persist, reload, verify all entries intact.

- [ ] **B7-12** | TC-20: Add SafetyCardView display test
  **File:** Create `Packages/PulsumUI/Tests/PulsumUITests/SafetyCardViewTests.swift`
  **Test:** Verify crisis card renders with correct phone numbers for current locale.

---

## Batch 8: Cleanup & Polish (11 items, ~1-2 days)

**Goal:** Fix remaining medium and low-priority issues. Code cleanup.

- [ ] **B8-01** | HIGH-14: Refactor DataAgent+Backfill.swift duplication
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent+Backfill.swift`
  **Change:** Extract shared `fetchSamplesForType(type:window:timeout:)` and `processBootstrapBatch(types:window:timeout:)` methods to eliminate the triplicated bootstrap/retry/fallback switch-case blocks.

- [ ] **B8-02** | MED-02: Add bulk persist to VectorIndexManager
  **File:** `Packages/PulsumData/Sources/PulsumData/VectorIndexManager.swift`
  **Change:** Add `bulkUpsertMicroMoments(_:)` that calls `store.bulkUpsert()` followed by a single `store.persist()`.

- [ ] **B8-03** | MED-04: Fix EvidenceScorer domain matching
  **File:** `Packages/PulsumData/Sources/PulsumData/EvidenceScorer.swift`
  **Change:** Remove dead `harvard.edu` from `mediumDomains`. Replace `.gov`/`.edu` with more specific domains if needed.

- [ ] **B8-04** | MED-05: Add date normalization guard
  **Files:** `DailyMetrics.swift`, `FeatureVector.swift`
  **Change:** Add a comment documenting the midnight-normalization requirement, or add a `willSet` that normalizes the date to start of day.

- [ ] **B8-05** | MED-13: Update CI simulator lists
  **Files:** `scripts/ci/build-release.sh`, `scripts/ci/test-harness.sh`
  **Change:** Update preferred simulator lists to include iPhone 17 Pro, iPhone 17 Pro Max, iPhone Air.

- [ ] **B8-06** | MED-14: Add privacy manifest content expectations
  **File:** `scripts/ci/check-privacy-manifests.sh`
  **Change:** Add expected API types (at minimum `CA92.1` for UserDefaults) to the `REQUIRED` dict validation.

- [ ] **B8-07** | MED-18: Add snapshot extensions for UserPrefs and ConsentState
  **File:** `Packages/PulsumData/Sources/PulsumData/Model/ModelSnapshots+Extensions.swift`
  **Change:** Add `UserPrefs.snapshot` and `ConsentState.snapshot` extensions with corresponding `Sendable` types in PulsumTypes.

- [ ] **B8-08** | LOW-01: Remove unused LiquidGlassTabBar
  **File:** `Packages/PulsumUI/Sources/PulsumUI/LiquidGlassComponents.swift`
  **Change:** Remove `LiquidGlassTabBar` struct if confirmed unused (verify with grep first).

- [ ] **B8-09** | LOW-06: Remove empty PulsumData.swift
  **File:** `Packages/PulsumData/Sources/PulsumData/PulsumData.swift`
  **Change:** Delete if the file contains only comments and no code.

- [ ] **B8-10** | LOW-07: Consolidate TestCoreDataStack
  **Change:** Consider creating a shared test support package or using a single `TestCoreDataStack.swift` via a test-only dependency, rather than duplicating across 3 test targets.

- [ ] **B8-11** | LOW-13: Remove dead code in AFMTextEmbeddingProvider
  **File:** `Packages/PulsumML/Sources/PulsumML/Embedding/AFMTextEmbeddingProvider.swift`
  **Change:** Remove the unused `availability` stored property.

---

## Batch 9: High-18 & Degraded Mode Safety (4 items, ~1 day)

**Goal:** Improve safety behavior in degraded/error states.

- [ ] **B9-01** | HIGH-18: Topic gate fail-closed in degraded mode
  **File:** `Packages/PulsumML/Sources/PulsumML/TopicGate/EmbeddingTopicGateProvider.swift`
  **Change:** In degraded mode, return `isOnTopic: false` (or `.unknown`) instead of `true`. The downstream code should handle unknown state by using the on-device fallback path rather than allowing arbitrary content.

- [ ] **B9-02** | MED-06: Improve sparse data coverage fallback
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent+Coverage.swift`
  **Change:** Instead of always returning `.soft` for sparse data, check if at least the topic matches a known wellbeing domain. Return `.fail` for clearly off-topic queries even with sparse data.

- [ ] **B9-03** | MED-07: Replace localizedDescription check in background delivery error
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent+Ingestion.swift`
  **Change:** Check for specific error code or domain instead of substring matching on `localizedDescription`.

- [ ] **B9-04** | MED-20: Fix ConsentStore revocation semantics
  **File:** `Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift`
  **Change:** In `persistConsentHistory`, only create a revocation record if `grantedAt` was non-nil.

---

## Batch 10: @unchecked Sendable Reduction (6 items, ~2-3 days)

**Goal:** Convert highest-risk `@unchecked Sendable` types to proper isolation.

**Note:** This is the most invasive batch. Each conversion should be verified with a full build + test run. Prioritize types that are most likely to have real concurrency issues.

- [ ] **B10-01** | Convert `EmbeddingService` to actor
  **File:** `Packages/PulsumML/Sources/PulsumML/Embedding/EmbeddingService.swift`
  **Change:** Convert from `final class @unchecked Sendable` with DispatchQueue to `actor`. This is the highest-traffic `@unchecked Sendable` type.

- [ ] **B10-02** | Convert `SafetyLocal` to actor
  **File:** `Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift`
  **Change:** Convert from `final class @unchecked Sendable` with `prototypeQueue` to `actor`.

- [ ] **B10-03** | Convert `EstimatorStateStore` to actor
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/EstimatorStateStore.swift`
  **Change:** Convert from `final class @unchecked Sendable` with `ioQueue` to `actor`.

- [ ] **B10-04** | Convert `RecRankerStateStore` to actor
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/RecRankerStateStore.swift`
  **Change:** After B1-05 adds the dispatch queue, convert to actor for consistency.

- [ ] **B10-05** | Convert `LLMGateway` in-memory key to actor-isolated state
  **File:** `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift`
  **Change:** Extract in-memory API key state into a small `APIKeyCache` actor, removing the `NSLock` from `LLMGateway`.

- [ ] **B10-06** | Audit remaining @unchecked Sendable types
  **All packages**
  **Change:** For each remaining `@unchecked Sendable` type, add a comment justifying why actor conversion is not feasible (e.g., NSObject subclass, Apple framework requirement). Types with DispatchQueue should be converted; types with immutable `let` properties should be properly `Sendable`.

---

## Remaining Items (6 items, ~1 day)

- [ ] **R-01** | MED-22: Replace Date() with ContinuousClock in RateLimiter
- [ ] **R-02** | MED-23: Make FoundationModelsCoachGenerator topic parsing more robust
- [ ] **R-03** | LOW-03: Rename `podcastrecommendations 2.json` to `podcastrecommendations.json`
- [ ] **R-04** | LOW-05: Remove duplicate DataStackSecurityTests
- [ ] **R-05** | LOW-08: Remove unused `coachAgent` parameter from `dominantTopic`
- [ ] **R-06** | LOW-15: Add meaningful app target tests in PulsumTests.swift

---

## Progress Summary

| Batch | Items | Effort | Status |
|---|---|---|---|
| Batch 1: Safety-Critical | 5 | ~1 day | 5/5 done |
| Batch 2: Concurrency | 8 | ~3-4 days | Not started |
| Batch 3: ML Correctness | 5 | ~2 days | Not started |
| Batch 4: Safety & Privacy | 6 | ~2 days | Not started |
| Batch 5: Security & LLM | 4 | ~1 day | 1/4 done |
| Batch 6: UI & Accessibility | 7 | ~2 days | Not started |
| Batch 7: Test Coverage | 12 | ~3 days | Not started |
| Batch 8: Cleanup & Polish | 11 | ~1-2 days | Not started |
| Batch 9: Degraded Mode Safety | 4 | ~1 day | Not started |
| Batch 10: @unchecked Sendable | 6 | ~2-3 days | Not started |
| Remaining | 6 | ~1 day | Not started |
| **Total** | **74** | **~3-4 weeks** | **6 / 74** |

---

*Plan generated 2026-02-14 based on full codebase analysis of 191 files.*
*Updated 2026-02-15: Batch 1 complete (B1-01 CRIT-01, B1-02 CRIT-02, B1-03 CRIT-04, B1-04 CRIT-05, B1-05 HIGH-05). B5-03 (HIGH-16) done. B2-05 partial (SafetyDecision/JournalResult).*
