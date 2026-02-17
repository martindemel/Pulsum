# Pulsum — Master Remediation Plan (Post-V2 Remediation)

**Status:** Ready to execute | **Progress:** 0 / 42 items | **Est. effort:** 2-3 weeks
**Based on:** `master_report.md` (2026-02-15, 42 findings, health score 8.0/10)

---

## READ THIS FIRST

**Before starting any work, read this entire file.** Then read `master_report.md` for finding details.

### What's Already Done (V2 Remediation — Completed)

The V2 remediation (commit 99b8409) resolved all critical issues from the previous audit (6.5/10 → 8.0/10):
- **NaN corruption paths:** StateEstimator target guard, SafetyLocal cosine similarity NaN check, RobustStats MAD clamping
- **Safety bypasses:** NaN embeddings no longer bypass safety classification
- **Concurrency:** AgentOrchestrator no longer blocks main thread; RecRankerStateStore and JournalSessionState converted to actors; SentimentAgent has @MainActor annotation
- **Foundation Models:** All three ML providers (Safety, Sentiment, TopicGate) converted from string interpolation to `@Generable` structured types
- **Safety:** Locale-aware crisis resources for 12 regions; force unwraps eliminated in SafetyCardView and SettingsView
- **ML:** Embedding dimension handling fixed; locale-aware language selection; PIIRedactor expanded and cached
- **Privacy:** Settings text corrected to NSFileProtectionCompleteUnlessOpen
- **Tests:** PIIRedactor, SentimentService fallback, DataAgent backfill, CoachAgent ranking — all test gaps filled
- **Cleanup:** Non-compiling test deleted; various code cleanup

### What Remains (This Plan)

42 findings: 0 CRIT, 4 HIGH, 18 MED, 20 LOW — organized into 6 implementation batches.

### Critical Execution Warnings

**1. Batch ordering matters.** Batch 1 (localization) is the largest effort and addresses the primary App Store compliance gap. Batch 2 (security) and Batch 3 (data integrity) fix remaining high-priority issues. Batches 4-6 are independent and can be parallelized.

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
- **`NSFileProtectionCompleteUnlessOpen`** (not Complete) — HealthKit background delivery needs DB access while locked.
- **BYOK API key is accepted risk for v1.0.** Backend proxy in v1.1. See `master_plan_1_1_FUTURE.md`.
- **Use `Diagnostics.log()`** from PulsumTypes for all logging (not `print()`).
- **Use Swift Testing** for new tests, not XCTest.
- **Use `String(localized:)` for all new user-facing strings.**

| File | What It Contains | When to Read |
|---|---|---|
| `master_report.md` | 42 findings with full detail, evidence, suggested fixes | When implementing any item — look up the finding ID |
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
| **Packages** | 6 SPM: PulsumTypes → PulsumML + PulsumData → PulsumServices → PulsumAgents → PulsumUI → App |
| **External deps** | Spline (spline-ios v0.2.48) — 3D animation only |
| **Backend** | OpenAI GPT-5 Responses API (consent-gated, BYOK API key) |
| **Frameworks** | HealthKit, Speech, Foundation Models, Core ML, Natural Language, Accelerate, MetricKit |
| **Users** | Zero. Fresh install every test. No data migration risk. |

---

## Rules for AI Agents

### DO

- **Read this entire file** at the start of every session.
- Work on **ONE item at a time**.
- **Mark items done** by changing `[ ]` to `[x]` and adding the date: `[x] *(2026-02-16)*`
- Look up the **finding ID** in `master_report.md` for full detail before implementing each item.
- Validate with build after each change.
- Run `swiftformat .` after each change.
- Use `#available(iOS 26.0, *)` guards for Foundation Models APIs.
- Use Swift Concurrency (`async`/`await`, `actor`) instead of Combine.
- Prefer `actor` for thread-safe mutable state over `@unchecked Sendable` + locks.
- Use `@ModelActor` for any actor that owns a SwiftData `ModelContext`.
- Reference the finding ID in commit messages (e.g., `fix: HIGH-01 — complete localization for SettingsView`).
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
- Do NOT use `print()` — use `Diagnostics.log()`.
- Do NOT use Combine — use async/await.
- Do NOT store `ModelContext` as a long-lived property — use `@ModelActor`.

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

## Architecture Decisions (Preserved)

| # | Decision | Choice | Status |
|---|---|---|---|
| D1 | Persistence | **SwiftData** | Done — 9 @Model classes, DTO snapshots |
| D2 | Vector Index | **VectorStore actor** | Done — flat dict + Accelerate search |
| D3 | Agents | **Keep 5, fix isolation** | Done — proper actor/MainActor annotations |
| D4 | Concurrency | **Actor isolation** | Mostly done — 26 justified @unchecked Sendable remain |
| D5 | State observation | **@Observable + NotificationCenter** | Done |
| D6 | DataAgent | **Decomposed into extensions** | Done — Backfill still ~1,500 lines (MED-04) |
| D7 | SettingsVM | **Split into 3 VMs** | Done — HealthSettingsVM, DiagnosticsVM, SettingsVM |
| D8 | Monetization | **BYOK optional** | Done — backend proxy deferred to v1.1 |
| D9 | Packages | **Keep 6 as-is** | Done — strict DAG maintained |
| D10 | Localization | **String(localized:) for all UI strings** | Partial — 4/22 UI files done |
| D11 | Foundation Models | **@Generable structured types** | Done — Safety, Sentiment, TopicGate |
| D12 | Crisis resources | **Locale-aware (12 regions)** | Done — SafetyAgent → SafetyCardView |

---

## Batch 1: Localization & Compliance (8 items, ~4-5 days)

**Goal:** Complete localization across all user-facing UI, addressing the primary App Store compliance gap.

- [ ] **B1-01** | HIGH-01 (partial): Localize SettingsView
  **File:** `Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift`
  **Change:** Replace all hardcoded English strings with `String(localized:)`. Priority: medical disclaimer text, privacy policy descriptions, data handling explanations, health data descriptions. Use descriptive key names (e.g., `"settings.privacy.fileProtection"`, `"settings.medical.disclaimer"`).

- [ ] **B1-02** | HIGH-01 (partial): Localize PulseView
  **File:** `Packages/PulsumUI/Sources/PulsumUI/PulseView.swift`
  **Change:** Replace hardcoded English strings with `String(localized:)`. Includes: button labels, status messages, recording prompts.

- [ ] **B1-03** | HIGH-01 (partial): Localize ScoreBreakdownView
  **File:** `Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownView.swift`
  **Change:** Replace hardcoded metric descriptions, score interpretations, and section headers with `String(localized:)`.

- [ ] **B1-04** | HIGH-01 (partial): Localize WellbeingStateCardView
  **File:** `Packages/PulsumUI/Sources/PulsumUI/WellbeingStateCardView.swift`
  **Change:** Replace hardcoded wellbeing state labels and descriptions with `String(localized:)`.

- [ ] **B1-05** | HIGH-01 (partial): Localize PulsumRootView
  **File:** `Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift`
  **Change:** Replace hardcoded navigation titles, button labels, and any user-facing text with `String(localized:)`.

- [ ] **B1-06** | HIGH-01 (partial): Localize remaining UI files
  **Files:** Any remaining PulsumUI source files with hardcoded user-facing strings (DiagnosticsViewModel error messages, HealthSettingsViewModel status text, etc.)
  **Change:** Audit all remaining PulsumUI files and replace hardcoded user-facing strings with `String(localized:)`.

- [ ] **B1-07** | MED-06: Populate Localizable.xcstrings
  **File:** `Pulsum/Localizable.xcstrings`
  **Change:** Build the project and verify that all `String(localized:)` keys are auto-extracted into the string catalog. If not, manually add entries. Ensure the catalog is the single source of truth for all localized strings.

- [ ] **B1-08** | HIGH-01 (partial): Localize AgentOrchestrator user-facing messages
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`
  **Change:** Verify all `String(localized:)` calls at lines 695, 750 use proper keys. Check for any remaining hardcoded strings in user-facing error messages or fallback text.

---

## Batch 2: Security & Documentation (3 items, ~1 day)

**Goal:** Fix security documentation issues and defense-in-depth gaps.

- [ ] **B2-01** | HIGH-02: Fix certificate pinning documentation in LLMGateway
  **File:** `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift`
  **Change:** Update comments describing `OpenAICertificatePinningDelegate` to accurately state "standard TLS trust evaluation with system CA validation" instead of "SPKI pinning against Let's Encrypt and DigiCert root CAs". If actual pinning is desired, implement with hardcoded public key hashes.

- [ ] **B2-02** | MED-05: Add user input delimiters to FoundationModelsCoachGenerator
  **File:** `Packages/PulsumServices/Sources/PulsumServices/FoundationModelsCoachGenerator.swift`
  **Change:** Wrap user input in clear delimiters: `<user_message>\(userMessage)</user_message>` and instruct the system prompt to only process content within these tags. This is defense-in-depth for the one remaining provider using string interpolation.

- [ ] **B2-03** | MED-13: Align DiagnosticsLogger file protection
  **File:** `Packages/PulsumTypes/Sources/PulsumTypes/DiagnosticsLogger.swift`
  **Change:** Change `NSFileProtectionComplete` to `NSFileProtectionCompleteUnlessOpen` on log files, matching the project standard required for HealthKit background delivery.

---

## Batch 3: Data Integrity & Actor Conversion (3 items, ~2 days)

**Goal:** Fix data integrity issues and convert LibraryImporter to actor.

- [ ] **B3-01** | HIGH-03: Surface VectorStore corrupt file errors
  **File:** `Packages/PulsumData/Sources/PulsumData/VectorStore.swift`
  **Change:** In `loadFromDisk()`, log corruption via `Diagnostics.log(.error, ...)` when the binary file cannot be parsed. Throw a `VectorStoreError.corruptFile` that callers can handle. In LibraryImporter, catch the error and invalidate the import checksum to trigger re-import on next launch.

- [ ] **B3-02** | MED-02: Replace VectorStore force unwrap
  **File:** `Packages/PulsumData/Sources/PulsumData/VectorStore.swift:174`
  **Change:** Replace `raw.baseAddress!.advanced(by: cursor)` with `guard let base = raw.baseAddress else { throw VectorStoreError.corruptFile }; base.advanced(by: cursor)`.

- [ ] **B3-03** | MED-01: Convert LibraryImporter to actor
  **File:** `Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift`
  **Change:** Convert from `@unchecked Sendable` class with `NSLock` to `actor`. Remove the lock and `_lastImportHadDeferredEmbeddings` backing field — use an actor-isolated property instead. Update all call sites to `await` LibraryImporter methods.

---

## Batch 4: Accessibility (4 items, ~2 days)

**Goal:** Improve accessibility compliance across UI layer.

- [ ] **B4-01** | HIGH-04 (partial): Add accessibility labels to interactive elements
  **Files:** All PulsumUI view files
  **Change:** Audit all `Button`, `Toggle`, `TextField`, and interactive elements. Add `.accessibilityLabel()` to any element that doesn't have descriptive text visible to VoiceOver. Priority: SettingsView, PulseView, ScoreBreakdownView.

- [ ] **B4-02** | HIGH-04 (partial): Add VoiceOver descriptions to data visualizations
  **Files:** `ScoreBreakdownView.swift`, `WellbeingStateCardView.swift`
  **Change:** Add `.accessibilityElement(children: .combine)` with descriptive labels to score displays and metric cards. VoiceOver users should hear the numeric score and its interpretation.

- [ ] **B4-03** | LOW-01: Replace hardcoded font sizes with Dynamic Type
  **Files:** `CoachView.swift`, `PulsumRootView.swift`
  **Change:** Replace `.font(.system(size: N))` with semantic fonts (`.headline`, `.subheadline`, `.body`, `.caption`). Decorative/icon sizes can remain hardcoded.

- [ ] **B4-04** | LOW-11: Add accessibility identifiers for UI test coverage
  **File:** `Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift`
  **Change:** Add `.accessibilityIdentifier()` to any interactive elements that lack them, enabling comprehensive UI test coverage.

---

## Batch 5: Build & Configuration Cleanup (10 items, ~1 day)

**Goal:** Fix build configuration issues, clean up stale references.

- [ ] **B5-01** | MED-07: Remove stale workspace reference
  **File:** `Pulsum.xcodeproj/project.xcworkspace/contents.xcworkspacedata`
  **Change:** Remove the `datagentsummary.md` file reference.

- [ ] **B5-02** | MED-11: Add PulsumTypes to PulsumTests dependencies
  **File:** `Pulsum.xcodeproj/project.pbxproj`
  **Change:** Add PulsumTypes to PulsumTests target's `packageProductDependencies`.

- [ ] **B5-03** | MED-12: Add PulsumTypes to PulsumUITests dependencies
  **File:** `Pulsum.xcodeproj/project.pbxproj`
  **Change:** Add PulsumTypes to PulsumUITests target's `packageProductDependencies`.

- [ ] **B5-04** | MED-16: Clean up empty Config.xcconfig
  **File:** `Config.xcconfig`
  **Change:** Add a comment explaining the Keychain-based key management approach, or delete the file if it serves no purpose.

- [ ] **B5-05** | MED-17: Verify Swift version in pbxproj
  **File:** `Pulsum.xcodeproj/project.pbxproj`
  **Change:** Verify that `SWIFT_VERSION = 5.0` with `SWIFT_APPROACHABLE_CONCURRENCY = YES` is the correct Xcode 26 configuration for Swift 6.1 mode. If not, update to the correct value.

- [ ] **B5-06** | LOW-03: Fix build number script for shallow clones
  **File:** `Pulsum.xcodeproj/project.pbxproj` (build phase)
  **Change:** Add a fallback for shallow clones: `git rev-list HEAD --count 2>/dev/null || echo 0`.

- [ ] **B5-07** | LOW-05: Rename icon asset files
  **File:** `Assets.xcassets/AppIcon.appiconset/Contents.json`
  **Change:** Rename `iconnew 2.png` → `AppIcon-dark.png`, `iconnew 1.png` → `AppIcon-tinted.png`, `iconnew.png` → `AppIcon.png`. Update Contents.json references.

- [ ] **B5-08** | LOW-07: Verify code signing for CI/archive builds
  **File:** `Pulsum.xcodeproj/project.pbxproj`
  **Change:** Verify `CODE_SIGN_IDENTITY = "Apple Development"` works for archive builds. Add a note in CLAUDE.md if manual override is needed for App Store distribution.

- [ ] **B5-09** | LOW-08: Verify RELEASE_LOG_AUDIT flag usage
  **File:** `Pulsum.xcodeproj/project.pbxproj`
  **Change:** Grep for `RELEASE_LOG_AUDIT` usage in source code. Verify all conditional compilation blocks behind this flag are production-safe. Document the flag's purpose.

- [ ] **B5-10** | LOW-15: Verify background modes in generated Info.plist
  **File:** `Pulsum/Pulsum.entitlements`
  **Change:** Build the project and inspect the generated Info.plist for `UIBackgroundModes`. Verify HealthKit background delivery works without an explicit `UIBackgroundModes` entry (iOS 26 may handle this via the entitlement alone).

---

## Batch 6: Architecture, Code Quality & Testing (14 items, ~4-5 days)

**Goal:** Reduce technical debt, improve architecture, fill remaining test gaps.

### Architecture & Code Quality

- [ ] **B6-01** | MED-03: Simplify AgentOrchestrator isolation model
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`
  **Change:** Evaluate converting to `@MainActor final class` (removing `@unchecked Sendable`) since all methods are already `@MainActor`-annotated. If any methods need to run off main actor, split into a non-MainActor orchestration core + MainActor UI facade.

- [ ] **B6-02** | MED-04: Refactor DataAgent+Backfill.swift duplication
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent+Backfill.swift`
  **Change:** Extract shared `fetchSamplesForType(type:window:timeout:)` and `processBootstrapBatch(types:window:timeout:)` methods. Target: reduce file from ~1,500 lines to under 1,000 by eliminating triplicated switch-case blocks.

- [x] **B6-03** | MED-10 (partial): ~~Convert HealthKitService to actor~~ **NOT APPLICABLE**
  **File:** `Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift`
  **Decision:** The current `@unchecked Sendable` + `DispatchQueue` pattern is industry best practice for HealthKit's callback-based APIs. `HKHealthStore` is not Sendable, `observeSampleType` must return synchronously, and background delivery callbacks fire on arbitrary queues. Actor conversion would require `nonisolated(unsafe)`, break the synchronous API surface, and risk regressions with no user-visible benefit. Apple's own WWDC sample code uses this same pattern. **No change needed.**

- [ ] **B6-04** | MED-10 (partial): Convert SentimentService to actor
  **File:** `Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentService.swift`
  **Change:** Convert from `@unchecked Sendable` (all `let` properties) to actor or add proper `Sendable` conformance since all properties are immutable.

- [ ] **B6-05** | MED-14: Add deep linking foundation
  **Files:** `PulsumApp.swift`, `PulsumRootView.swift`
  **Change:** Register a URL scheme (`pulsum://`) and add basic `onOpenURL` handler in PulsumRootView. Support at minimum: `pulsum://journal` (open voice journal), `pulsum://coach` (open coach). This enables future integration with Health app and Shortcuts.

### Testing

- [ ] **B6-06** | MED-18: Expand app-level integration tests
  **File:** `PulsumTests/PulsumTests.swift`
  **Change:** Add tests for: app-level environment injection, `AppRuntimeConfig` flag behavior, animation disable logic. Target: at least 5 meaningful tests beyond the current 2.

- [ ] **B6-07** | LOW-02: Stabilize UI test infrastructure
  **Files:** `PulsumUITests/PulsumUITestCase.swift`
  **Change:** Document the multi-strategy settings sheet detection pattern. Add retry counts as configurable constants. Consider adding a `XCTContext.runActivity` wrapper for better test failure diagnostics.

- [ ] **B6-08** | LOW-09: Enforce integrity script tag check in CI
  **File:** `scripts/ci/integrity.sh`
  **Change:** Make the `gate0-done-2025-11-09` tag check enforced by default (not just informational). Add a `--lenient` flag for local development.

- [ ] **B6-09** | LOW-10: Decouple PulsumUI tests from app host
  **File:** `Pulsum.xcodeproj/xcshareddata/xcschemes/PulsumUI.xcscheme`
  **Change:** Evaluate running PulsumUI package tests via `swift test` instead of through the app host scheme. This would speed up test iteration.

- [ ] **B6-10** | LOW-12: Add explicit NSPrivacyTracking to package manifests
  **Files:** Package-level PrivacyInfo.xcprivacy files
  **Change:** Add `<key>NSPrivacyTracking</key><false/>` explicitly to all package privacy manifests.

- [ ] **B6-11** | LOW-13: Remove Python dependency from CI scripts
  **Files:** `scripts/ci/test-harness.sh`, `scripts/ci/build-release.sh`
  **Change:** Replace Python simulator auto-detection with a pure shell implementation using `xcrun simctl list devices -j` and `plutil` or `jq`.

- [ ] **B6-12** | LOW-14: Monitor Keychain/NWPathMonitor privacy requirements
  **File:** `Packages/PulsumServices/Sources/PulsumServices/PrivacyInfo.xcprivacy`
  **Change:** Add a comment noting that Keychain (Security/SecItem*) and NWPathMonitor (Network) are excluded from API declarations as of iOS 26. Add a TODO to check Apple's WWDC announcements for requirement changes.

- [ ] **B6-13** | LOW-19: Add RecRanker integration test with real VectorStore
  **File:** Create `Packages/PulsumAgents/Tests/PulsumAgentsTests/RecRankerIntegrationTests.swift`
  **Change:** Test the full pipeline: recommendation request → VectorStore search → RecRanker ranking → feedback update, using in-memory SwiftData containers and a real VectorStore actor.

- [ ] **B6-14** | LOW-20: Add performance regression tests
  **Files:** Create performance test files in relevant test targets
  **Change:** Add `measure {}` blocks for: recommendation generation, safety classification, voice journal save pipeline. Establish baselines to catch regressions.

---

## Progress Summary

| Batch | Items | Effort | Status |
|---|---|---|---|
| Batch 1: Localization & Compliance | 8 | ~4-5 days | Not started |
| Batch 2: Security & Documentation | 3 | ~1 day | Not started |
| Batch 3: Data Integrity & Actor Conversion | 3 | ~2 days | Not started |
| Batch 4: Accessibility | 4 | ~2 days | Not started |
| Batch 5: Build & Config Cleanup | 10 | ~1 day | Not started |
| Batch 6: Architecture, Quality & Testing | 14 (1 N/A) | ~4-5 days | Not started |
| **Total** | **42 (1 N/A = 41 actionable)** | **~2-3 weeks** | **0 / 41** |

---

## Items Not Carried Forward

The following items from the previous plan (`master_plan_FINAL_old.md`) are **resolved** and not included in this plan:

| Previous ID | Resolution |
|---|---|
| B1-01 (CRIT-01) | NaN target guard added to StateEstimator |
| B1-02 (CRIT-02) | NaN guard added to SafetyLocal cosine similarity |
| B1-03 (CRIT-04) | MAD clamped to 1e-6 in RobustStats init |
| B1-04 (CRIT-05) | Stale test file deleted |
| B1-05 (HIGH-05) | RecRankerStateStore converted to actor |
| B2-01 (CRIT-03) | AgentOrchestrator no longer blocks main thread |
| B2-03 (HIGH-07) | SentimentAgent has @MainActor annotation |
| B2-04 (HIGH-13) | JournalSessionState converted to actor |
| B3-01 (HIGH-01) | Embedding dimension handling fixed |
| B3-02 (HIGH-12) | Locale-aware embedding selection |
| B3-05 (MED-15) | PIIRedactor regex cached at module load |
| B4-01 (HIGH-03) | Locale-aware crisis resources passed to SafetyCardView |
| B4-02 (HIGH-10) | PIIRedactor expanded to 8 patterns |
| B4-03 (HIGH-11) | FM providers use @Generable (prompt injection mitigated) |
| B4-04 (HIGH-09) | Privacy description corrected |
| B5-02 (HIGH-15) | Force unwraps eliminated in SafetyCardView, SettingsView |
| B5-03 (HIGH-16) | VectorStore unaligned memory fixed |
| B7-01 (TC-01) | PIIRedactorTests.swift exists with comprehensive coverage |
| B7-02 (TC-02) | SentimentServiceFallbackTests.swift exists |
| B10-02 | SafetyLocal converted to actor |
| B10-04 | RecRankerStateStore converted to actor |

---

*Plan generated 2026-02-15 based on full codebase analysis of 206 files. Previous health score: 6.5/10 → Current: 8.0/10.*
