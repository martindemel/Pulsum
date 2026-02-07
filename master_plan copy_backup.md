# Pulsum — Master Remediation Plan

**Created:** 2026-02-05  
**Status:** DECISIONS RECOMMENDED — Review recommendations, confirm or override, then begin work  
**Overall Progress:** 0 / TBD items (finalized after decisions confirmed)  
**Source Reports:** `master_report.md` (112 findings), `guidelines_report.md` (29 checks)

---

## SECTION 0: Context

- **Zero App Store users.** No data migration risk. No backward compatibility required.
- **Fresh install every test cycle.** Persistence store is always empty at start.
- **iOS 26 only.** SwiftData, Foundation Models, and all modern APIs are available.
- **Pre-revenue.** No monetization exists. Business model undecided.
- **SwiftData is production-ready.** Confirmed stable since 2025, with iOS 26 adding schema migration, model inheritance, and #Index support.

---

## SECTION 1: Architecture Decisions

Each decision has a **recommended option** marked with `[x]` and reasoning. If you agree, leave as-is. If you disagree, change the `[x]` to a different option and note why. Once all 10 are confirmed, Section 3 execution phases become active.

---

### DECISION 1: Persistence Layer

**Current problems:** Core Data with 9 flat-table entities, zero relationships, zero fetch indexes, 19 `NSNumber?` type mismatches, 3 `fatalError()` in init, `performAndWait` blocking main thread, stale compiled .momd, no migration strategy. (CRIT-004, HIGH-007, MED-004, MED-005, MED-013, PROD-009)

- [x] **Option A: Migrate to SwiftData** | Effort: ~2 weeks | Eliminates 6 findings automatically  
- [ ] Option B: Keep Core Data, fix individually | Effort: ~1 week | Must fix all 6 one by one

**Recommendation: Option A (SwiftData)**

**Reasoning:** SwiftData is production-ready since 2025 and the recommended Apple persistence for new SwiftUI projects targeting iOS 17+. This app targets iOS 26 where SwiftData has mature schema migration (`VersionedSchema`), `#Index` for queries, and `@Query` for SwiftUI. The current Core Data usage doesn't leverage ANY of Core Data's strengths (no object graph, no relationships, no faulting, no undo) — it's flat tables with manual foreign keys. SwiftData eliminates:

1. `fatalError` crash paths (CRIT-004) — `ModelContainer` init is throwing, not fatal
2. `performAndWait` main-thread blocking (HIGH-007) — `ModelContext` is async-friendly
3. 19 `NSNumber?` mismatches (MED-004) — `@Model` uses native Swift types
4. Missing fetch indexes (MED-005) — SwiftData supports `#Index` macro
5. Stale .momd risk (MED-013) — SwiftData has no compiled model file
6. No migration strategy (PROD-009) — `VersionedSchema` + `SchemaMigrationPlan`

With zero users and fresh installs, there is literally no migration risk. Every week spent fixing Core Data bugs is work that becomes throwaway when you eventually migrate. Do it now while it's free.

---

### DECISION 2: Vector Index

**Current problems:** Custom binary format (437 lines), non-deterministic hash sharding, non-atomic writes, NSLock inside actor. Used for ~200-500 vectors of 384 dims. (CRIT-001, HIGH-009, MED-015)

- [x] **Option A: Replace with in-memory array + file serialization** | Effort: ~2 days | Eliminates 3 findings  
- [ ] Option B: Replace with SQLite/GRDB | Effort: ~4 days | Eliminates 3 findings  
- [ ] Option C: Fix bugs in current custom index | Effort: ~2 days | Must fix all 3

**Recommendation: Option A (in-memory)**

**Reasoning:** The math doesn't justify the current complexity. 500 vectors × 384 floats × 4 bytes = 770KB. That fits comfortably in memory on any iPhone. Brute-force L2 search over 500 vectors using Accelerate's `vDSP_distancesq` takes <1ms — faster than any disk-based solution. The implementation is ~60-80 lines replacing 437 lines of custom binary I/O that has already produced 2 critical bugs. Atomic file serialization via `Data.write(to:options:.atomic)` eliminates the crash-recovery problem. The 16-shard architecture is engineering for a scale (100K+ vectors) that this app will never reach.

If the app someday needs 10K+ vectors, you'd want a proper vector database anyway, not the current custom format. Build for what you have, not what you might hypothetically need.

---

### DECISION 3: Agent Pattern

**Current state:** 5 agents + orchestrator. SafetyAgent is 91 lines with no state. CheerAgent returns a random string. (ARCH-004)

- [ ] Option A: Simplify to 3 agents + 2 services | Effort: ~3 days  
- [x] **Option B: Keep 5 agents, fix their isolation and DI** | Effort: ~2 days  
- [ ] Option C: Keep exactly as-is | Effort: 0

**Recommendation: Option B (keep 5, fix isolation)**

**Reasoning:** The agent naming is cosmetic — what matters is isolation and injectability. Converting SafetyAgent from `@MainActor class` to a `Sendable` service and adding DI (injectable classifiers) gives the real benefits without restructuring the orchestrator's coordination logic. CheerAgent at ~60 lines isn't worth the refactoring effort to extract. The orchestrator already works and its call sites don't need to change. Spend the effort on decomposing DataAgent instead, where the ROI is 100x higher.

---

### DECISION 4: Concurrency Model

**Current state:** Orchestrator, CoachAgent, SafetyAgent all `@MainActor`. Only DataAgent is a proper actor. ML inference and Core Data queries serialize on the UI thread. (ARCH-005)

- [x] **Option A: Move computation agents to proper actor isolation** | Effort: ~2-3 days  
- [ ] Option B: Keep @MainActor everywhere | Effort: 0

**Recommendation: Option A (actor isolation)**

**Reasoning:** With SwiftData (Decision 1), the `performAndWait` blocking goes away. But SafetyAgent's ML inference (embedding computation + cosine similarity for crisis detection) takes 10-50ms on first call, and that's on the main thread. CoachAgent's vector search + ranking pipeline chains multiple awaits that each hop back to the main actor. Converting CoachAgent to `actor` and SafetyAgent to `Sendable` (or `nonisolated`) is a mechanical change — the callers already use `await`. This prevents a class of performance issues that are hard to debug (intermittent frame drops during coaching).

The change is: `@MainActor public final class CoachAgent` → `public actor CoachAgent`. The compiler will tell you every call site that needs adjustment.

---

### DECISION 5: Singleton Removal

**Current state:** 5 singletons creating hidden coupling: DataStack.shared, PulsumData.container, EmbeddingService.shared, VectorIndexManager.shared, KeychainService.shared. (ARCH-006)

- [ ] Option A: Remove all singletons, create composition root | Effort: ~1 week  
- [x] **Option B: Remove Core Data singletons only** | Effort: ~2-3 days (mostly absorbed by SwiftData migration)  
- [ ] Option C: Keep singletons, add protocol wrappers | Effort: ~1-2 days

**Recommendation: Option B (remove Core Data singletons)**

**Reasoning:** The SwiftData migration (Decision 1) naturally eliminates `DataStack.shared` and the `PulsumData` static facade because those are entirely Core Data constructs. The new `ModelContainer` will be created in the composition root (`AppViewModel`) and passed via init to agents. That's the biggest testability win.

The remaining singletons are appropriate:
- `EmbeddingService.shared` — genuinely a global resource (one ML model in memory). Making it non-singleton means passing it through 6+ init chains for zero benefit.
- `KeychainService.shared` — wraps the iOS Keychain, which is itself a system singleton. The `KeychainStoring` protocol already enables mocking.
- `VectorIndexManager.shared` — if we go in-memory (Decision 2), this becomes a simple actor that can be non-singleton and passed through CoachAgent's init. But it's also fine as a singleton.

Don't remove singletons dogmatically. Remove the ones that block testability (Core Data), keep the ones that represent genuinely shared resources.

---

### DECISION 6: State Observation

**Current state:** Three patterns: `@Observable`, `NotificationCenter` (score updates), closure callbacks (consent/safety routing). (ARCH-008)

- [ ] Option A: Consolidate everything to @Observable | Effort: ~3-4 days  
- [x] **Option B: Keep @Observable + NotificationCenter, remove closure callbacks** | Effort: ~1-2 days  
- [ ] Option C: Keep all three as-is | Effort: 0

**Recommendation: Option B (remove closures only)**

**Reasoning:** `NotificationCenter` for `.pulsumScoresUpdated` is the correct iOS pattern. DataAgent is an `actor` that fires score updates asynchronously. `NotificationCenter` decouples the producer (DataAgent in PulsumAgents) from the consumer (AppViewModel in PulsumUI) across package boundaries without introducing a dependency. Replacing it with direct property observation would require PulsumUI to observe DataAgent's properties directly, creating tighter coupling than the notification.

The closure callbacks (`onConsentChanged`, `onSafetyDecision` in AppViewModel) are the confusing part — they're set up as wiring between parent and child ViewModels, but the wiring happens in `start()`, not in init, and it's easy to miss. Converting these to observable properties on the orchestrator (e.g., `orchestrator.latestSafetyDecision` as an `@Observable` property) makes the data flow visible in the type system rather than hidden in closures.

---

### DECISION 7: DataAgent Decomposition

**Current state:** 3,706 lines, 10+ responsibilities in one actor. (ARCH-001)

- [x] **Option A: Decompose into 5-6 focused types** | Effort: ~1-2 weeks  
- [ ] Option B: Split into 2-3 large chunks | Effort: ~3-5 days

**Recommendation: Option A (5-6 types)**

**Reasoning:** This refactoring happens once. If you do Option B now (3 chunks of ~1,200 lines each), you'll want to split further later — refactoring the same code twice. With zero users and no production pressure, do it right once.

The natural decomposition is:
1. **DataAgent** (~400 lines) — thin coordinator, public API surface, notification posting
2. **HealthKitIngestionCoordinator** (~500 lines) — authorization, observers, sample delivery callbacks
3. **SampleProcessors** (~600 lines) — protocol + per-type implementations (HRV, HR, sleep, steps, respiratory)
4. **BaselineCalculator** (~400 lines) — robust statistics, z-scores, baseline persistence
5. **FeatureVectorBuilder** (~300 lines) — materialize feature vectors from daily metrics + baselines
6. **BackfillCoordinator** (~1,000 lines) — bootstrap lifecycle, warm/full backfill, retry, watchdog

Each type is under 1,000 lines, has a single clear responsibility, and can be independently unit-tested. The SampleProcessor protocol means adding a new HealthKit data type (e.g., blood oxygen) requires adding one new file, not modifying a 3,700-line actor.

---

### DECISION 8: SettingsViewModel Decomposition

**Current state:** 573 lines, 7 concerns: health status, API key management, consent, diagnostics config, diagnostics export, FM status, debug observers. (ARCH-007)

- [x] **Option A: Split into 3-4 focused ViewModels** | Effort: ~3-4 days  
- [ ] Option B: Keep as one, add protocol abstraction | Effort: ~1 day

**Recommendation: Option A (split)**

**Reasoning:** 573 lines with 7 concerns is textbook God Object. The decomposition is mechanical:
1. **SettingsViewModel** (~150 lines) — consent, app version, FM status (the things that are always visible)
2. **HealthSettingsViewModel** (~120 lines) — HealthKit access status, authorization, success toast
3. **APIKeySettingsViewModel** (~100 lines) — API key storage, testing, connection status
4. **DiagnosticsViewModel** (~200 lines) — config, log snapshot, export, clear

Each is independently testable. SettingsView composes them as `@State` properties. The split makes it obvious which ViewModel to look at when debugging a specific settings section.

---

### DECISION 9: Monetization Model

**Current state:** No StoreKit, no paywall. Cloud coaching requires BYOK OpenAI API key. On-device Foundation Models coaching works without API key. (PROD-001)

- [ ] Option A: Remove cloud coaching for v1.0 (on-device only)  
- [x] **Option B: Keep BYOK as optional power-user feature** | On-device is primary  
- [ ] Option C: Build StoreKit subscription for v1.0 | Effort: ~2-3 weeks

**Recommendation: Option B (BYOK optional)**

**Reasoning:** The app's core value proposition works entirely without cloud: HealthKit wellness score + voice journaling + on-device Foundation Models coaching + crisis detection. ALL of this runs locally on iOS 26 with Apple Intelligence. The cloud GPT-5 coaching is an enhancement, not a requirement.

For v1.0: ship with on-device as primary. The BYOK API key in Settings is fine for power users and developers. It doesn't violate App Store Guideline 3.1.1 because the cloud feature is optional — the app is fully functional without it. No need to build StoreKit subscription infrastructure when you don't yet know if users want cloud coaching at all.

For v1.1: based on user feedback, decide whether to add server-managed API keys behind a subscription. Building StoreKit now (2-3 weeks) before you know the business model is premature optimization.

---

### DECISION 10: Package Structure

**Current state:** 6 packages, acyclic graph. PulsumTypes is a kitchen sink. PulsumUI depends on PulsumData directly. (ARCH-009)

- [ ] Option A: Fix PulsumUI → PulsumData dependency  
- [ ] Option B: Split PulsumTypes into Types + Diagnostics  
- [x] **Option C: Keep 6 packages as-is** | Effort: 0

**Recommendation: Option C (keep as-is)**

**Reasoning:** With SwiftData (Decision 1), PulsumUI depending on PulsumData becomes correct by design. SwiftData encourages views to use `@Query` directly on model types, which means PulsumUI legitimately needs to import the data layer. The dependency that looked wrong under Core Data becomes right under SwiftData.

PulsumTypes being a "kitchen sink" for shared types, diagnostics, and utilities is fine — that's literally what a Types/Foundation package is for. It's 10 files, ~1,200 lines. Splitting it into two packages adds build complexity for negligible benefit. The 6-package structure is clean, the dependency graph is acyclic, and the boundaries are at the right seams. Don't over-engineer the package structure.

---

## SECTION 2: Decision Impact Summary

**Findings automatically eliminated by recommended choices:**

| Decision | Choice | Findings Eliminated |
|---|---|---|
| D1: SwiftData | Option A | CRIT-004, HIGH-007, MED-004, MED-005, MED-013, PROD-009 |
| D2: In-memory vectors | Option A | CRIT-001, HIGH-009, MED-015 |
| D4: Actor isolation | Option A | ARCH-005 |
| D5: Remove CD singletons | Option B | ARCH-006 (partially) |
| D7: DataAgent decomposition | Option A | ARCH-001 |
| D8: SettingsVM split | Option A | ARCH-007 (partially) |
| **Total** | | **9 findings eliminated automatically + 3 architecture issues resolved** |

**Findings that still need manual fixes (not eliminated by architecture choices):**

| Category | Findings | Items |
|---|---|---|
| Safety/Security Critical | CRIT-002, CRIT-003, CRIT-005 | FM guardrails, schema mismatch, crisis keywords |
| High-Priority Bugs | HIGH-001, HIGH-002, HIGH-003, HIGH-004, HIGH-005, HIGH-006, HIGH-008, HIGH-010 | RecRanker math, sentiment fallback, topic gate, speech thread safety, UI stuck state, accessibility, speech stub, crisis AND-gate |
| App Store Compliance | GL-1.4.1 (disclaimer, AI labels, crisis resources, methodology) | 4 distinct changes |
| Medium Bugs | MED-001, MED-002, MED-003, MED-007, MED-008, MED-009, MED-011, MED-012, MED-014, MED-016 | 10 items |
| Production Readiness | PROD-002, PROD-003, PROD-004, PROD-005, PROD-006, PROD-007, PROD-008, PROD-010, PROD-011 | Crash reporting, analytics, network, disclaimers, GDPR, onboarding, localization, SSL, rating |
| Low Priority | LOW-001 through LOW-015 | 15 items |

---

## SECTION 3: Execution Phases (Active after Section 1 confirmed)

Detailed phase items with checkboxes will be generated once you confirm the 10 decisions above. The phases will be:

**Phase 0: Architecture Foundation** (~2-3 weeks)
- SwiftData migration (if D1=A): Rewrite 9 entities as @Model, replace DataStack/PulsumData, update all agents and tests
- Vector index replacement (if D2=A): Build in-memory vector store, replace VectorIndex + VectorIndexManager
- DataAgent decomposition (D7): Extract 5-6 focused types
- SettingsViewModel split (D8): Extract 3-4 focused ViewModels
- Actor isolation changes (D4): Move CoachAgent/SafetyAgent off @MainActor

**Phase 1: Safety & Critical Bugs** (~2-3 days)
- CRIT-002: FM safety guardrail fix
- CRIT-003: Schema/prompt enum unification
- CRIT-005: Expand crisis keywords
- HIGH-005: Fix stuck isAnalyzing
- HIGH-010: Remove crisis keyword-AND-embedding requirement
- HIGH-002: Add NL sentiment fallback
- HIGH-003: Make topic gate permissive when degraded
- HIGH-001: Fix RecRanker Bradley-Terry gradient
- App Store compliance: Medical disclaimers, 988 Lifeline, AI labels

**Phase 2: Concurrency & Remaining Fixes** (~3-4 days)
- HIGH-004: Speech backend thread safety
- MED-001 through MED-016: All remaining medium-priority fixes
- Singleton cleanup (absorbed by SwiftData migration)
- State observation cleanup (D6: remove closure callbacks)

**Phase 3: Production Readiness** (~1-2 weeks)
- PROD-002: Crash reporting (MetricKit)
- PROD-003: Analytics framework structure
- PROD-004: Network reachability monitor
- PROD-005/006/007: Disclaimers, GDPR data deletion, onboarding persistence
- HIGH-006: Dynamic Type accessibility
- All LOW-priority items

---

## SECTION 4: Instructions for AI Agents

### DO

- Read this file at the start of every session to understand current progress.
- Verify Section 1 decisions are confirmed (all have exactly one `[x]`) before starting Phase 0.
- Work on ONE item at a time. Complete it fully before moving to the next.
- After completing an item, update its checkbox from `[ ]` to `[x]` and add the completion date.
- After each code change, run `swiftformat .` from the project root.
- Use `#available(iOS 26.0, *)` guards when using Foundation Models APIs.
- Use Swift Concurrency (async/await) instead of Combine.
- Prefer `actor` for thread-safe mutable state over `@unchecked Sendable` + manual locks.
- Keep changes minimal and surgical — one fix per item, no drive-by refactors.
- Validate changes with Xcode build (`BuildProject` via MCP if available, or `xcodebuild -scheme Pulsum -sdk iphoneos -derivedDataPath ./DerivedData`).
- Use `XcodeRefreshCodeIssuesInFile` for quick diagnostics on changed files.
- Reference the finding ID (e.g., CRIT-001) in commit messages.
- Use 4-space indentation. PascalCase for types, camelCase for vars/functions.

### DO NOT

- Do NOT start any phase work until Section 1 decisions are all confirmed.
- Do NOT change multiple items in a single commit — each item is an atomic unit.
- Do NOT refactor adjacent code "while you're in there" — create a separate item if needed.
- Do NOT add new SPM dependencies without explicit approval.
- Do NOT use `@unchecked Sendable` on new code — use `actor` or proper `Sendable` conformance.
- Do NOT use `fatalError()`, `preconditionFailure()`, or force unwraps (`!`) in new code.
- Do NOT use `print()` for logging — use `Diagnostics.log()` from PulsumTypes.
- Do NOT hardcode user-facing strings — use `String(localized:)` for all new strings.
- Do NOT commit secrets, API keys, or tokens.
- Do NOT modify the Core Data model — it will be replaced by SwiftData (if D1=A confirmed).

### Build & Verify Commands

```bash
# Build the main app
xcodebuild -scheme Pulsum -sdk iphoneos -derivedDataPath ./DerivedData

# Run package tests
swift test --package-path Packages/PulsumML
swift test --package-path Packages/PulsumData
swift test --package-path Packages/PulsumServices
swift test --package-path Packages/PulsumAgents
swift test --package-path Packages/PulsumUI

# Lint and format
swiftformat --lint .
swiftformat .

# Privacy manifests
scripts/ci/check-privacy-manifests.sh
```

### Project Context

- **Platform:** iOS 26+ (deployment target)
- **Language:** Swift 6.1 (swift-tools-version: 6.1)
- **UI Framework:** SwiftUI with @Observable (Observation framework)
- **Concurrency:** Swift Concurrency (async/await, actors). SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor.
- **Architecture:** 6 SPM packages in acyclic dependency graph
- **Packages:** PulsumTypes → PulsumML + PulsumData → PulsumServices → PulsumAgents → PulsumUI → App
- **External dependency:** Spline (spline-ios v0.2.48) — 3D animation only
- **Backend:** OpenAI GPT-5 Responses API (consent-gated, BYOK API key)
- **Key frameworks:** HealthKit, Speech, Foundation Models, SwiftData (after migration), Natural Language, Core ML

---

## SECTION 5: Progress Tracker

| Phase | Items | Completed | Status |
|---|---|---|---|
| Section 1: Decisions | 10 | 0 | **REVIEW RECOMMENDATIONS** |
| Phase 0: Architecture Foundation | TBD | 0 | Waiting on decisions |
| Phase 1: Safety & Critical Bugs | TBD | 0 | Waiting on decisions |
| Phase 2: Concurrency & Remaining | TBD | 0 | Waiting on decisions |
| Phase 3: Production Readiness | TBD | 0 | Waiting on decisions |

---

## SECTION 6: Reference Index

| Report | Location | What It Contains |
|---|---|---|
| `master_report.md` | Project root | 112 technical, architecture, and production findings |
| `guidelines_report.md` | Project root | 29 App Store Review Guidelines compliance checks |
| `scan_prompt.md` | Project root | Reusable audit prompt with 43+ analysis dimensions |

| Finding ID Pattern | Report | Section |
|---|---|---|
| CRIT-001 through CRIT-005 | master_report.md | Critical Issues |
| HIGH-001 through HIGH-010 | master_report.md | High-Priority Issues |
| MED-001 through MED-016 | master_report.md | Medium-Priority Issues |
| LOW-001 through LOW-015 | master_report.md | Low-Priority Issues |
| ARCH-001 through ARCH-009 | master_report.md | Architecture Design Review |
| PROD-001 through PROD-018 | master_report.md | Production-Readiness Findings |
| GL-1.4.1, GL-2.1, etc. | guidelines_report.md | App Store Guidelines Checks |
| STUB-001 through STUB-003 | master_report.md | Stubs and Incomplete Implementations |
| CALC-001 through CALC-012 | master_report.md | Calculation and Logic Audit |
| GAP-001 through GAP-007 | master_report.md | Test Coverage Gaps |
