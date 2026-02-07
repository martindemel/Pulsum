# Pulsum — Master Remediation Plan

**Created:** 2026-02-05  
**Status:** DECISIONS RECOMMENDED — Review and confirm, then begin Phase 0  
**Overall Progress:** 0 / 70 items  
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

## SECTION 3: Execution Phases

---

### Phase 0: Architecture Foundation

**Goal:** Restructure persistence, vector index, agents, and ViewModels. After this phase the architecture is clean.  
**Estimated effort:** 2-3 weeks  
**Branch name:** `refactor/phase0-architecture`

#### 0.1 — SwiftData Migration (D1=A) — Eliminates CRIT-004, HIGH-007, MED-004, MED-005, MED-013, PROD-009

- [ ] **P0-01** | Create SwiftData model types to replace Core Data entities  
  **Create:** `Packages/PulsumData/Sources/PulsumData/Model/` — new `@Model` classes for all 9 entities (JournalEntry, DailyMetrics, Baseline, FeatureVector, MicroMoment, RecommendationEvent, LibraryIngest, UserPrefs, ConsentState). Use native Swift types (Double, Int16, Bool — not NSNumber?). Add `#Index` macros for date and ID fields. Add `@Attribute(.unique)` where applicable (MicroMoment.id, LibraryIngest.id).  
  **Reference:** `master_report.md` MED-004 (type mismatches), MED-005 (missing indexes)  
  **Verify:** Models compile. Compare every attribute with the old `ManagedObjects.swift` and `Pulsum.xcdatamodel/contents` XML to ensure nothing is missed.  

- [ ] **P0-02** | Replace DataStack with SwiftData ModelContainer setup  
  **Replace:** `Packages/PulsumData/Sources/PulsumData/DataStack.swift`  
  **What to change:** Replace `NSPersistentContainer` with `ModelContainer`. Use `ModelConfiguration` with `.isStoredInMemoryOnly = false` and appropriate file protection. The init must be `throws` (not `fatalError`). Apply `NSFileProtectionComplete` via the store URL's file attributes. Create container in `AppViewModel` as composition root and pass to agents via init.  
  **Reference:** `master_report.md` CRIT-004, ARCH-006  
  **Verify:** App launches. Container creates SQLite file. File protection is applied.  

- [ ] **P0-03** | Replace PulsumData static facade with injectable container  
  **Replace:** `Packages/PulsumData/Sources/PulsumData/PulsumData.swift`  
  **What to change:** Remove all static accessors (`PulsumData.container`, `.viewContext`, etc.). Consumers receive `ModelContainer` via their init. If a convenience accessor is still needed, make it instance-based, not static singleton.  
  **Reference:** `master_report.md` ARCH-006  
  **Verify:** Build succeeds. No more `PulsumData.container` references in source (grep to confirm).  

- [ ] **P0-04** | Update PulsumManagedObjectModel.swift for SwiftData  
  **File:** `Packages/PulsumData/Sources/PulsumData/PulsumManagedObjectModel.swift`  
  **What to change:** This file loads the Core Data model from bundle. With SwiftData, the model is defined in code via `@Model`. Either delete this file or repurpose it as a Schema definition file containing `VersionedSchema` for future migrations.  
  **Verify:** Build succeeds.  

- [ ] **P0-05** | Remove old Core Data artifacts  
  **Delete:** `Packages/PulsumData/Sources/PulsumData/Model/ManagedObjects.swift` (replaced by @Model classes), `Packages/PulsumData/Sources/PulsumData/Resources/Pulsum.xcdatamodeld/` (entire directory), `Packages/PulsumData/Sources/PulsumData/Resources/PulsumCompiled.momd/` (entire directory), `Packages/PulsumData/Sources/PulsumData/Bundle+PulsumDataResources.swift` (if no longer needed).  
  **Update:** `Packages/PulsumData/Package.swift` — remove `.process("PulsumData/Resources/Pulsum.xcdatamodeld")` and `.process("PulsumData/Resources/PulsumCompiled.momd")` from resources.  
  **Verify:** Build succeeds. No references to removed files.  

- [ ] **P0-06** | Update DataAgent for SwiftData  
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`  
  **What to change:** Replace all `NSManagedObjectContext` usage with `ModelContext`. Replace `context.performAndWait {}` with async `ModelContext` operations. Replace `NSFetchRequest` with SwiftData `#Predicate` and `FetchDescriptor`. Replace `context.save()` with `modelContext.save()`. Accept `ModelContainer` in init instead of `NSPersistentContainer`.  
  **Verify:** Build succeeds. DataAgent tests pass (after updating test helpers).  

- [ ] **P0-07** | Update SentimentAgent for SwiftData  
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift`  
  **What to change:** Same pattern as P0-06. Replace Core Data context usage with `ModelContext`. Accept `ModelContainer` in init.  
  **Verify:** Build succeeds.  

- [ ] **P0-08** | Update CoachAgent for SwiftData  
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift`  
  **What to change:** Same pattern. Remove `contextPerformAndWait` helper entirely (HIGH-007 eliminated). Replace with async `ModelContext` operations. Accept `ModelContainer` in init.  
  **Verify:** Build succeeds.  

- [ ] **P0-09** | Update LibraryImporter for SwiftData  
  **File:** `Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift`  
  **What to change:** Replace `NSManagedObjectContext` background context with `ModelContext`. Replace fetch requests with `FetchDescriptor`. Accept `ModelContainer` in init instead of defaulting to `PulsumData.container`.  
  **Verify:** Build succeeds. Library import creates MicroMoment records.  

- [ ] **P0-10** | Update AgentOrchestrator for SwiftData  
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`  
  **What to change:** Create `ModelContainer` in orchestrator init (composition root). Pass it to DataAgent, SentimentAgent, CoachAgent, and LibraryImporter. Update all `#if DEBUG` test inits.  
  **Verify:** Build succeeds. Orchestrator creates and starts successfully.  

- [ ] **P0-11** | Update AppViewModel for SwiftData  
  **File:** `Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift`  
  **What to change:** If `ModelContainer` is created in `AgentOrchestrator`, AppViewModel just creates the orchestrator as before. If container is created in AppViewModel, pass it to orchestrator init. Handle `ModelContainer` init failure gracefully (the `blocked` startup state).  
  **Verify:** App launches end-to-end. Onboarding works. HealthKit data flows to score display.  

- [ ] **P0-12** | Update all test helpers for SwiftData  
  **Files:** `PulsumAgentsTests/TestCoreDataStack.swift`, `PulsumUITests/TestCoreDataStack.swift`  
  **What to change:** Replace in-memory `NSPersistentContainer` with in-memory `ModelContainer` (`ModelConfiguration(isStoredInMemoryOnly: true)`). Update all tests that create Core Data stacks.  
  **Verify:** All package tests pass.  

#### 0.2 — Vector Index Replacement (D2=A) — Eliminates CRIT-001, HIGH-009, MED-015

- [ ] **P0-13** | Create in-memory VectorStore to replace VectorIndex  
  **Create:** `Packages/PulsumData/Sources/PulsumData/VectorStore.swift`  
  **What to build:** A simple `actor VectorStore` that holds a `[String: [Float]]` dictionary in memory. Methods: `upsert(id:vector:)`, `remove(id:)`, `search(query:topK:) -> [VectorMatch]`, `save()`, `load()`. Persistence via `Codable` struct serialized to a single JSON file using `Data.write(to:options:.atomic)`. L2 distance via Accelerate `vDSP_distancesq` for hardware acceleration. Apply `NSFileProtectionComplete` to the file.  
  **Verify:** Upsert, search, remove all work. File persists across actor restarts.  

- [ ] **P0-14** | Update VectorIndexManager to use VectorStore  
  **File:** `Packages/PulsumData/Sources/PulsumData/VectorIndexManager.swift`  
  **What to change:** Replace internal `VectorIndex` with `VectorStore`. The `VectorIndexProviding` protocol stays the same — only the implementation changes. Simplify the manager since sharding is gone.  
  **Verify:** Build succeeds. VectorIndexManager tests pass.  

- [ ] **P0-15** | Remove old VectorIndex  
  **Delete:** `Packages/PulsumData/Sources/PulsumData/VectorIndex.swift` (437 lines of custom binary I/O)  
  **Verify:** Build succeeds. No references to old VectorIndex types. Grep for `VectorIndexShard`, `VectorIndexHeader`, `VectorRecordHeader` returns zero results.  

#### 0.3 — Actor Isolation (D4=A) — Eliminates ARCH-005

- [ ] **P0-16** | Move CoachAgent off @MainActor  
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift`, `CoachAgent+Coverage.swift`  
  **What to change:** Change `@MainActor public final class CoachAgent` to `public actor CoachAgent`. Remove any `@MainActor` annotations on methods. The compiler will flag every call site that needs `await` — fix those in `AgentOrchestrator.swift`.  
  **Verify:** Build succeeds. ChatGuardrailTests, CoachAgentKeywordFallbackTests pass.  

- [ ] **P0-17** | Fix SafetyAgent isolation (D3=B)  
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/SafetyAgent.swift`  
  **What to change:** Change `@MainActor public final class SafetyAgent` to `public final class SafetyAgent: Sendable`. It has no mutable state after init — all properties are `let`. Add init parameter for `SafetyClassifying` protocol (injectable classifier). Add default init that creates `FoundationModelsSafetyProvider` + `SafetyLocal` for production.  
  **Reference:** `master_report.md` ARCH-004, ARCH-005  
  **Verify:** Build succeeds. AgentSystemTests pass.  

#### 0.4 — DataAgent Decomposition (D7=A) — Eliminates ARCH-001

- [ ] **P0-18** | Extract HealthKitIngestionCoordinator from DataAgent  
  **From:** `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`  
  **Create:** `Packages/PulsumAgents/Sources/PulsumAgents/HealthKitIngestionCoordinator.swift`  
  **What to move:** HealthKit authorization management, observer query setup/teardown, background delivery registration, sample delivery callbacks. DataAgent keeps a reference and delegates.  
  **Verify:** Build succeeds. Gate3_HealthAccessStatusTests, Gate3_IngestionIdempotenceTests pass.  

- [ ] **P0-19** | Extract SampleProcessors from DataAgent  
  **From:** `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`  
  **Create:** `Packages/PulsumAgents/Sources/PulsumAgents/SampleProcessing/` directory. Create `SampleProcessor` protocol + `HRVProcessor`, `HeartRateProcessor` (including nocturnal HR), `SleepProcessor` (including sleep debt), `StepProcessor`, `RespiratoryRateProcessor`.  
  **Verify:** Build succeeds. Gate6_WellbeingBackfillPhasingTests pass.  

- [ ] **P0-20** | Extract BaselineCalculator from DataAgent  
  **From:** `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`  
  **Create:** `Packages/PulsumAgents/Sources/PulsumAgents/BaselineCalculator.swift`  
  **What to move:** Z-score normalization, baseline computation, baseline persistence. Uses `BaselineMath` from PulsumML.  
  **Verify:** Build succeeds. Gate6_StateEstimatorWeightsAndLabelsTests pass.  

- [ ] **P0-21** | Extract BackfillCoordinator from DataAgent  
  **From:** `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`  
  **Create:** `Packages/PulsumAgents/Sources/PulsumAgents/BackfillCoordinator.swift`  
  **What to move:** Two-phase bootstrap (warm start + full backfill), retry/timeout/watchdog patterns, BackfillProgress tracking.  
  **Verify:** Build succeeds. Gate6_WellbeingBackfillPhasingTests, Gate7_FirstRunWatchdogTests pass.  

- [ ] **P0-22** | Verify DataAgent is now a thin coordinator  
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`  
  **Target:** DataAgent should be under 500 lines. Its public API stays unchanged. It delegates to the extracted types.  
  **Verify:** `wc -l DataAgent.swift` < 500. ALL agent tests pass. Full build succeeds.  

#### 0.5 — SettingsViewModel Decomposition (D8=A) — Addresses ARCH-007

- [ ] **P0-23** | Extract HealthSettingsViewModel  
  **From:** `Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift`  
  **Create:** `Packages/PulsumUI/Sources/PulsumUI/HealthSettingsViewModel.swift`  
  **What to move:** HealthKit access status, authorization state, re-request, success toast, `healthKitSuccessTask`.  
  **Verify:** Build succeeds. SettingsViewModelHealthAccessTests pass.  

- [ ] **P0-24** | Extract DiagnosticsViewModel  
  **From:** `Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift`  
  **Create:** `Packages/PulsumUI/Sources/PulsumUI/DiagnosticsViewModel.swift`  
  **What to move:** Diagnostics config, log snapshot, export URL, clear, persisted tail, report generation, FM status.  
  **Verify:** Build succeeds.  

- [ ] **P0-25** | Update SettingsView to use decomposed ViewModels  
  **File:** `Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift`  
  **What to change:** SettingsView uses slimmed `SettingsViewModel` + `HealthSettingsViewModel` + `DiagnosticsViewModel` as `@State` properties. Each settings section binds to the appropriate VM.  
  **Verify:** Build succeeds. Settings screen works in all sections.  

#### 0.6 — State Observation Cleanup (D6=B)

- [ ] **P0-26** | Replace closure callbacks with observable properties  
  **File:** `Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift`  
  **What to change:** Remove `onConsentChanged` and `onSafetyDecision` closure callbacks. Instead, expose relevant state as `@Observable` properties on the orchestrator or on the ViewModels themselves. Child VMs observe directly rather than receiving callbacks.  
  **Verify:** Build succeeds. Consent changes propagate to coach. Safety decisions show safety card.  

#### Phase 0 Completion Checklist

- [ ] All 26 items above completed
- [ ] Full project builds: `xcodebuild -scheme Pulsum -sdk iphoneos -derivedDataPath ./DerivedData`
- [ ] All package tests pass
- [ ] `swiftformat .` produces no changes
- [ ] `scripts/ci/check-privacy-manifests.sh` passes
- [ ] DataAgent.swift < 500 lines
- [ ] SettingsViewModel.swift < 200 lines
- [ ] No references to `NSManagedObjectContext`, `NSPersistentContainer`, `performAndWait` in source
- [ ] No references to `VectorIndexShard`, `VectorRecordHeader` in source
- [ ] Commit and PR: `refactor: Phase 0 — Architecture Foundation`

---

### Phase 1: Safety & Critical Bugs

**Goal:** Fix all safety issues, critical bugs, and App Store compliance blockers. After this phase the app is safe and submittable.  
**Estimated effort:** 2-3 days  
**Branch name:** `fix/phase1-safety-critical`  
**Prerequisite:** Phase 0 complete

#### 1.1 — Safety & Security Fixes

- [ ] **P1-01** | CRIT-002 | Fix FM safety provider guardrail violations returning `.safe`  
  **File:** `Packages/PulsumML/Sources/PulsumML/Safety/FoundationModelsSafetyProvider.swift`  
  **What to change:** In the `catch` block for `GenerationError` (~lines 59-64), change `.guardrailViolation` and `.refusal` from `return .safe` to `return .caution(reason: "Content flagged by on-device safety system")`.  
  **Reference:** `master_report.md` CRIT-002  
  **Verify:** Build succeeds. Existing SafetyLocalTests pass.  

- [ ] **P1-02** | CRIT-003 | Unify intentTopic enum between schema and system prompt  
  **Files:** `Packages/PulsumServices/Sources/PulsumServices/CoachPhrasingSchema.swift`, `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift`  
  **What to change:** Unify both lists to: `["sleep","stress","energy","hrv","mood","movement","mindfulness","nutrition","goals","none"]`. Update schema enum (~line 30) and system prompt instruction (~line 862).  
  **Reference:** `master_report.md` CRIT-003  
  **Verify:** Build succeeds. LLMGatewaySchemaTests pass.  

- [ ] **P1-03** | CRIT-005 | Expand crisis keyword lists  
  **Files:** `Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift`, `Packages/PulsumAgents/Sources/PulsumAgents/SafetyAgent.swift`  
  **What to change:** Add to BOTH keyword lists: "want to die", "self-harm", "cut myself", "cutting myself", "overdose", "no reason to live", "jump off", "hang myself", "hurt myself", "don't want to be here", "can't go on", "take all the pills", "ending my life", "not worth living", "better off dead", "wish I were dead", "no way out".  
  **Reference:** `master_report.md` CRIT-005, `guidelines_report.md` Section 1.4.1  
  **Verify:** Build succeeds. Write test: `testExpandedCrisisKeywordsCoverage`.  

- [ ] **P1-04** | HIGH-010 | Remove keyword requirement for high-confidence crisis embeddings  
  **File:** `Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift`  
  **What to change:** When embedding similarity to a crisis prototype exceeds 0.85, return `.crisis` regardless of keyword presence. Only require keyword-AND-embedding for similarity 0.65–0.85.  
  **Reference:** `master_report.md` HIGH-010  
  **Verify:** Build succeeds. Test paraphrased crisis text without keywords → `.crisis`.  

- [ ] **P1-05** | MED-014 | Expand PII redaction patterns  
  **File:** `Packages/PulsumML/Sources/PulsumML/Sentiment/PIIRedactor.swift`  
  **What to change:** Add regex for SSN (`\d{3}-\d{2}-\d{4}`), credit card (16-digit sequences with separators), IP addresses (`\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}`).  
  **Reference:** `master_report.md` MED-014, `guidelines_report.md` Section 5.1.2(i)  
  **Verify:** Build succeeds. Write tests per pattern type.  

#### 1.2 — ML Pipeline Fixes

- [ ] **P1-06** | HIGH-001 | Fix RecRanker Bradley-Terry pairwise gradient  
  **File:** `Packages/PulsumML/Sources/PulsumML/RecRanker.swift`  
  **What to change:** Replace independent gradient with correct Bradley-Terry: `let gradient = logistic(dotOther - dotPreferred)`, update weights: `w_k += lr * gradient * (x_preferred_k - x_other_k)`.  
  **Reference:** `master_report.md` HIGH-001, CALC-008  
  **Verify:** Build succeeds. Write test: `testPairwiseLearningConverges`.  

- [ ] **P1-07** | HIGH-002 | Add NaturalLanguageSentimentProvider to fallback chain  
  **File:** `Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentService.swift`  
  **What to change:** Add `NaturalLanguageSentimentProvider()` as final provider in array. Add `Diagnostics.log(level: .warn, ...)` before the `return 0.0` fallback.  
  **Reference:** `master_report.md` HIGH-002, MED-003  
  **Verify:** Build succeeds.  

- [ ] **P1-08** | HIGH-003 | Make topic gate permissive when embeddings unavailable  
  **File:** `Packages/PulsumML/Sources/PulsumML/TopicGate/EmbeddingTopicGateProvider.swift`  
  **What to change:** On embedding failure, return `GateDecision(isOnTopic: true, reason: "Embedding unavailable — defaulting to permissive", confidence: 0.0, topic: nil)`.  
  **Reference:** `master_report.md` HIGH-003  
  **Verify:** Build succeeds.  

- [ ] **P1-09** | MED-002 | Remove unnecessary AFM availability gate on NLEmbedding  
  **File:** `Packages/PulsumML/Sources/PulsumML/Embedding/AFMTextEmbeddingProvider.swift`  
  **What to change:** Remove `availability() == .ready` check (~line 20). NLEmbedding works without Foundation Models availability.  
  **Reference:** `master_report.md` MED-002  
  **Verify:** Build succeeds. Embedding tests pass.  

#### 1.3 — UI & App Store Compliance

- [ ] **P1-10** | HIGH-005 | Fix stuck `isAnalyzing` in PulseViewModel  
  **File:** `Packages/PulsumUI/Sources/PulsumUI/PulseViewModel.swift`  
  **What to change:** Add `isAnalyzing = false` to `stopRecording()`. Add `defer { isAnalyzing = false }` in the recording task.  
  **Reference:** `master_report.md` HIGH-005  
  **Verify:** Build succeeds. Start/stop recording — spinner always disappears.  

- [ ] **P1-11** | PROD-005 / GL-1.4.1 | Add medical disclaimer  
  **Files:** `OnboardingView.swift`, `SettingsView.swift`, `CoachView.swift`  
  **What to change:** Add disclaimer text: "Pulsum is for general wellness and informational purposes only. It does not provide medical advice. Always consult your healthcare provider before making health decisions." Add to onboarding welcome, settings privacy section, and near coach chat input.  
  **Reference:** `guidelines_report.md` Blocker #1, #2  
  **Verify:** Build succeeds. Disclaimer visible in all three locations.  

- [ ] **P1-12** | GL-1.4.1 | Add 988 Lifeline and professional-help disclaimer to SafetyCardView  
  **Files:** `SafetyCardView.swift`, `SafetyAgent.swift`  
  **What to change:** Add "988 Suicide & Crisis Lifeline" button (tel:988). Add "This app is not a substitute for professional mental health care." Update SafetyAgent crisis message to include 988 and locale-aware language.  
  **Reference:** `guidelines_report.md` Blocker #3, `master_report.md` MED-009  
  **Verify:** Build succeeds. SafetyCardView shows 911 + 988 + disclaimer.  

- [ ] **P1-13** | GL-1.4.1 | Label AI-generated content  
  **File:** `CoachView.swift`  
  **What to change:** Add "AI" badge to assistant chat messages in `ChatBubble`. Add persistent disclaimer near chat input: "Responses are AI-generated and not medical advice."  
  **Reference:** `guidelines_report.md` High Risk #5  
  **Verify:** Build succeeds. AI label visible on assistant messages.  

- [ ] **P1-14** | GL-1.4.1 | Add wellbeing score methodology disclosure  
  **File:** `ScoreBreakdownView.swift`  
  **What to change:** Add footer: "Your wellbeing score is an estimated trend indicator based on statistical patterns in your recent health data. It is not a clinical measurement."  
  **Reference:** `guidelines_report.md` High Risk #8  
  **Verify:** Build succeeds.  

#### Phase 1 Completion Checklist

- [ ] All 14 items completed
- [ ] Full build succeeds
- [ ] All tests pass
- [ ] `swiftformat .` clean
- [ ] Commit and PR: `fix: Phase 1 — Safety & Critical Bugs`

---

### Phase 2: Concurrency & Remaining Fixes

**Goal:** Fix thread safety, remaining medium-priority bugs, and cleanup. After this phase the codebase is solid.  
**Estimated effort:** 3-5 days  
**Branch name:** `fix/phase2-concurrency-cleanup`  
**Prerequisite:** Phase 1 complete

- [ ] **P2-01** | HIGH-004 | Add synchronization to LegacySpeechBackend  
  **File:** `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift`  
  **What to change:** Add private serial `DispatchQueue`. Wrap all mutations to audio engine, recognition task/request, and stream continuations in `queue.sync {}`.  
  **Reference:** `master_report.md` HIGH-004  

- [ ] **P2-02** | MED-001 | Add synchronization to RecRanker and StateEstimator  
  **Files:** `RecRanker.swift`, `StateEstimator.swift`  
  **What to change:** Add `NSLock` protecting mutable state, or convert to actors.  
  **Reference:** `master_report.md` MED-001  

- [ ] **P2-03** | MED-007 | Fix HealthKitAnchorStore read/write queue asymmetry  
  **File:** `HealthKitAnchorStore.swift`  
  **What to change:** Change `store(anchor:for:)` from `queue.async` to `queue.sync`.  
  **Reference:** `master_report.md` MED-007  

- [ ] **P2-04** | MED-008 | Add reprocessDay to submitTranscript  
  **File:** `AgentOrchestrator.swift`  
  **What to change:** Add `try await dataAgent.reprocessDay(date: result.date)` in `submitTranscript()`.  
  **Reference:** `master_report.md` MED-008  

- [ ] **P2-05** | MED-011 | Synchronize LLMGateway.inMemoryAPIKey  
  **File:** `LLMGateway.swift`  
  **What to change:** Add `NSLock` protecting `inMemoryAPIKey` reads and writes.  
  **Reference:** `master_report.md` MED-011  

- [ ] **P2-06** | MED-012 | Document testAPIConnection consent policy  
  **File:** `LLMGateway.swift`  
  **What to change:** Add comment and/or parameter documenting that `testAPIConnection()` contacts OpenAI without consent check (it's a connectivity test, not a data transmission).  
  **Reference:** `master_report.md` MED-012  

- [ ] **P2-07** | MED-016 | Document DiagnosticsDayFormatter UTC usage  
  **File:** `DiagnosticsTypes.swift`  
  **What to change:** Add documentation comment that `DiagnosticsDayFormatter` uses UTC intentionally for diagnostics/logging, NOT for health metric day-boundary aggregation. If DataAgent uses it for metric aggregation, switch to `TimeZone.current` there.  
  **Reference:** `master_report.md` MED-016  

- [ ] **P2-08** | LOW-002 | Guard BaselineMath.zScore against zero MAD  
  **File:** `BaselineMath.swift`  
  **What to change:** In `RobustStats.init`, clamp `mad` to `max(mad, 1e-6)`.  
  **Reference:** `master_report.md` LOW-002  

- [ ] **P2-09** | LOW-003 | Add NaN guard to StateEstimator  
  **File:** `StateEstimator.swift`  
  **What to change:** Filter NaN values from features at top of `predict()` and `update()`.  
  **Reference:** `master_report.md` LOW-003  

- [ ] **P2-10** | LOW-004 | Fix sanitize response punctuation  
  **Files:** `LLMGateway.swift`, `FoundationModelsCoachGenerator.swift`  
  **What to change:** Preserve `!` and `?` delimiters in `sanitizeResponse`.  
  **Reference:** `master_report.md` LOW-004  

- [ ] **P2-11** | LOW-005 | Remove duplicate `#if DEBUG`  
  **File:** `SpeechService.swift`  
  **What to change:** Remove nested duplicate at lines ~419-420.  

- [ ] **P2-12** | LOW-006 | Fix timeout task leak in speech  
  **File:** `SpeechService.swift`  
  **What to change:** Store max-duration timeout task. Cancel it in `stopRecording()`.  

- [ ] **P2-13** | LOW-007 | Log RecRanker state version mismatch  
  **File:** `RecRanker.swift`  
  **What to change:** Add `Diagnostics.log(level: .warn, ...)` when state version doesn't match.  

- [ ] **P2-14** | LOW-008 + LOW-009 | Fix task leaks in ViewModels  
  **Files:** `CoachViewModel.swift`, `PulseViewModel.swift`  
  **What to change:** Add `deinit` to CoachViewModel cancelling all tasks. Store and cancel previous tasks in `scheduleCheerReset`/`scheduleSubmissionReset`.  

- [ ] **P2-15** | LOW-010 | Cache DateFormatters  
  **Files:** `ScoreBreakdownView.swift`, `SettingsView.swift`  
  **What to change:** Replace per-render `DateFormatter()` with static cached formatters.  

- [ ] **P2-16** | LOW-001 | Clean up EvidenceScorer dead domains  
  **File:** `EvidenceScorer.swift`  
  **What to change:** Fix "pubmed", remove redundant "nih.gov", fix "harvard.edu" shadowing.  

#### Phase 2 Completion Checklist

- [ ] All 16 items completed
- [ ] Full build succeeds
- [ ] All tests pass
- [ ] `swiftformat .` clean
- [ ] Commit and PR: `fix: Phase 2 — Concurrency & Cleanup`

---

### Phase 3: Production Readiness

**Goal:** Add production infrastructure. After this phase the app is ready for App Store submission.  
**Estimated effort:** 1-2 weeks  
**Branch name:** `feat/phase3-production`  
**Prerequisite:** Phase 2 complete

#### 3.1 — Compliance & Data Management

- [ ] **P3-01** | PROD-006 | Add "Delete All Data" to Settings  
  **Files:** `SettingsView.swift`, `SettingsViewModel.swift`, `AgentOrchestrator.swift`  
  **What to change:** Add `deleteAllData()` to orchestrator (clears SwiftData store, vector store, Keychain, UserDefaults). Add button in Settings with confirmation dialog.  
  **Reference:** `master_report.md` PROD-006, `guidelines_report.md` Recommended #10  

- [ ] **P3-02** | PROD-007 | Persist onboarding completion  
  **File:** `AppViewModel.swift`  
  **What to change:** Add `@AppStorage("ai.pulsum.hasCompletedOnboarding")`. Set `true` after full onboarding. Drive onboarding visibility from this flag.  
  **Reference:** `master_report.md` PROD-007  

- [ ] **P3-03** | GL-1.4.1 | Add wellbeing score methodology disclosure  
  **File:** `ScoreBreakdownView.swift`  
  **What to change:** (If not done in P1-14 already.) Brief methodology footer.  

#### 3.2 — Observability

- [ ] **P3-04** | PROD-002 | Integrate MetricKit for crash diagnostics  
  **Create:** `Packages/PulsumServices/Sources/PulsumServices/CrashDiagnosticsSubscriber.swift`  
  **What to build:** `MXMetricManagerSubscriber` that logs crash diagnostics. Register in AppViewModel.  
  **Reference:** `master_report.md` PROD-002  

- [ ] **P3-05** | PROD-003 | Add analytics event tracking structure  
  **Create:** `Packages/PulsumTypes/Sources/PulsumTypes/AnalyticsEvent.swift`  
  **What to build:** `AnalyticsEvent` enum, `AnalyticsProvider` protocol, `NoOpAnalyticsProvider` default. Instrument key actions throughout the app. Real SDK can be plugged in later.  
  **Reference:** `master_report.md` PROD-003  

#### 3.3 — Network Resilience

- [ ] **P3-06** | PROD-004 | Add network reachability monitor  
  **Create:** `Packages/PulsumServices/Sources/PulsumServices/NetworkMonitor.swift`  
  **What to build:** `actor NetworkMonitor` using `NWPathMonitor`. Check before cloud requests. Skip cloud and use on-device when offline.  
  **Reference:** `master_report.md` PROD-004  

- [ ] **P3-07** | PROD-016 | Add offline mode indicator to CoachView  
  **File:** `CoachView.swift`  
  **What to change:** Show banner "You're offline — using on-device coaching" when not connected.  
  **Reference:** `master_report.md` PROD-016  

- [ ] **P3-08** | PROD-015 | Add client-side rate limiting to LLMGateway  
  **File:** `LLMGateway.swift`  
  **What to change:** Max 1 cloud request per 3 seconds, max 20 per hour. Return on-device response if rate limited.  
  **Reference:** `master_report.md` PROD-015  

#### 3.4 — Accessibility

- [ ] **P3-09** | HIGH-006 | Replace hardcoded fonts with Dynamic Type  
  **File:** `PulsumDesignSystem.swift`  
  **What to change:** Replace all `Font.system(size:)` with semantic styles (`.largeTitle`, `.title`, `.body`, etc.).  
  **Reference:** `master_report.md` HIGH-006  

#### 3.5 — Build & Operations

- [ ] **P3-10** | PROD-013 | Set up build number from git  
  **What to change:** Add Run Script phase: `CURRENT_PROJECT_VERSION` from `git rev-list --count HEAD`.  
  **Reference:** `master_report.md` PROD-013  

- [ ] **P3-11** | PROD-017 | Centralize UserDefaults keys  
  **Create:** `Packages/PulsumTypes/Sources/PulsumTypes/PulsumDefaults.swift`  
  **What to build:** Enum with all UserDefaults key constants.  

- [ ] **P3-12** | LOW-012 + LOW-013 | Fix empty PulsumTests and enable in scheme  
  **Files:** `PulsumTests/PulsumTests.swift`, `Pulsum.xcscheme`  
  **What to change:** Remove empty test. Set `skipped = "NO"`.  

- [ ] **P3-13** | LOW-014 | Compile-gate KeychainService UITest fallback  
  **File:** `KeychainService.swift`  
  **What to change:** Wrap UserDefaults fallback in `#if DEBUG`.  

- [ ] **P3-14** | PROD-011 | Add app rating prompt  
  **File:** `AppViewModel.swift`  
  **What to change:** After 5th score view, call `requestReview()`. Once per version.  

#### Phase 3 Completion Checklist

- [ ] All 14 items completed
- [ ] Full build succeeds
- [ ] All tests pass
- [ ] Dynamic Type works across all screens
- [ ] Data deletion works and resets to onboarding
- [ ] Offline mode shows indicator
- [ ] `swiftformat .` clean
- [ ] `scripts/ci/check-privacy-manifests.sh` passes
- [ ] Commit and PR: `feat: Phase 3 — Production Readiness`

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
| Section 1: Decisions | 10 | 10 | **RECOMMENDED — confirm or override** |
| Phase 0: Architecture Foundation | 26 | 0 | Not Started |
| Phase 1: Safety & Critical Bugs | 14 | 0 | Not Started |
| Phase 2: Concurrency & Cleanup | 16 | 0 | Not Started |
| Phase 3: Production Readiness | 14 | 0 | Not Started |
| **Total** | **70** | **0** | **0%** |

**Estimated total effort:** 5-7 weeks  
**Findings resolved:** 9 automatically (architecture) + ~55 manually = ~64 of 112 total  
**Remaining after all phases:** ~48 findings (mostly LOW-priority, test gaps, and stubs)

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
