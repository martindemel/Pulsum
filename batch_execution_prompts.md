# Batch Execution Prompts

Open a **fresh Claude Code window** for each batch. Copy-paste the prompt below.
Each prompt is self-contained — no dependency on prior sessions. CLAUDE.md auto-loads.

After each batch completes, verify the commit landed on `main` before starting the next.

---

# COMPLETED — Remediation Batches 1-7

Batches 1-7 from `master_fix_plan.md` are complete. See git log for commits:
- `b4f4b15` Batch 1: Quick safety wins
- `e6208ac` Batch 2: Core data layer fixes
- `5bde773` Batch 3: ML correctness
- `378bf77` Batch 4: Concurrency safety
- `3f4f386` Batch 5: UI & accessibility
- `be20eeb` Batch 6: App Store compliance
- `9fd19dd` Batch 7: Medium priority fixes

---

## Batch 8 — Low Priority (optional, can run before or after Phase 0)

```
Read `master_fix_plan.md` section 5 "Low Priority Fixes" for the full list.

BEFORE making any changes: create a safe-point commit with message "Safe point: before Batch 8 — low priority fixes".

Implement all LOW items (LOW-01 through LOW-20) in order. For each:
- Read the target file first
- Apply the fix described in the plan
- Build-verify periodically (every 5-6 fixes)

After ALL fixes: run swiftformat, build for simulator, run SPM tests for all 5 packages. Fix any build errors.

Then commit with message "Batch 8: Low priority fixes — cleanup, guards, dead code removal" and push to main.
```

---

# PHASE 0 — Architecture Foundation (SwiftData Migration)

**Source of truth:** `master_plan_FINAL.md` Phase 0 (27 items: P0-01 through P0-26).
**Branch:** Create `refactor/phase0-architecture` from `main` before starting.
**Estimated effort:** ~3 weeks total.

### Critical ordering rules:
1. **Step A** (0A + 0B): Create models + DTOs, replace DataStack, remove facade — FIRST
2. **Step A2 + B first** (0C): DataAgent migration + composition root + decomposition — TOGETHER
3. **Step B continued** (0D): Migrate remaining agents one at a time
4. **Step C** (0E): Delete Core Data artifacts ONLY after all agents migrated
5. **Vector + cleanup** (0F, 0G): Independent, can follow Step C

---

## Phase 0A — SwiftData Models + DTO Snapshots

```
Read `master_plan_FINAL.md` items P0-01 and P0-01b in full detail. Also read the "SwiftData Concurrency Rules" section at the top of the file.

IMPORTANT: Search Apple docs for SwiftData `@Model`, `@Attribute(.unique)`, `#Unique`, `#Index`, `Schema` before starting. These APIs may differ from your training data.

Create branch: git checkout -b refactor/phase0-architecture

BEFORE making any changes: create a safe-point commit with message "Safe point: before Phase 0A — SwiftData models".

Implement these 2 items:

1. P0-01: Create @Model classes for all 9 entities
   - Create directory: Packages/PulsumData/Sources/PulsumData/Model/
   - Create 9 files: JournalEntry.swift, DailyMetrics.swift, Baseline.swift, FeatureVector.swift, MicroMoment.swift, RecommendationEvent.swift, LibraryIngest.swift, UserPrefs.swift, ConsentState.swift
   - Use native Swift types (Double, not NSNumber). See the entity table in master_plan_FINAL.md for exact attributes.
   - Add @Attribute(.unique) on: DailyMetrics.date, FeatureVector.date, MicroMoment.id, LibraryIngest.source, UserPrefs.id, ConsentState.version
   - Add #Unique<Baseline>([\.metric, \.windowDays]) for compound uniqueness
   - Add #Index macros for date-indexed entities
   - MicroMoment.tags is String? (JSON string, NOT [String] — SwiftData can't query inside arrays)
   - Each model needs a proper init with defaults

2. P0-01b: Create Sendable DTO snapshot types
   - Create: Packages/PulsumTypes/Sources/PulsumTypes/ModelSnapshots.swift
   - Create snapshot structs: DailyMetricsSnapshot, WellbeingScoreSnapshot, JournalEntrySnapshot, BaselineSnapshot, FeatureVectorSnapshot, MicroMomentSnapshot, RecommendationEventSnapshot
   - All must be: public struct ... : Sendable, Codable
   - These live in PulsumTypes (no SwiftData import) so both agents and ViewModels can use them
   - Also create .snapshot computed property extensions on each @Model class in PulsumData (separate file: Packages/PulsumData/Sources/PulsumData/Model/ModelSnapshots+Extensions.swift)

VERIFY after implementation:
- PulsumData package compiles: swift build --package-path Packages/PulsumData
- PulsumTypes package compiles: swift build --package-path Packages/PulsumTypes
- All 9 model files use native Swift types, no NSNumber
- Uniqueness attributes are on the right fields
- Snapshot structs match model properties needed by callers

Run swiftformat, then commit with message "Phase 0A: Create SwiftData @Model classes and DTO snapshots (P0-01, P0-01b)" and push.
```

---

## Phase 0B — DataStack + Static Facade Removal

```
Read `master_plan_FINAL.md` items P0-02 and P0-03 in full detail.

IMPORTANT: Search Apple docs for SwiftData `ModelContainer`, `ModelConfiguration`, `Schema` before starting.

BEFORE making any changes: create a safe-point commit with message "Safe point: before Phase 0B — DataStack replacement".

Implement these 2 items:

1. P0-02: Replace DataStack with SwiftData ModelContainer
   - File: Packages/PulsumData/Sources/PulsumData/DataStack.swift
   - Replace NSPersistentContainer with ModelContainer
   - Init MUST be throwing (not fatalError) — define DataStackError enum
   - Schema includes all 9 @Model types from Phase 0A
   - Apply NSFileProtectionCompleteUnlessOpen to store directory (NOT .complete — HealthKit background delivery needs DB access while locked)
   - Keep StoragePaths struct for directory management

2. P0-03: Remove PulsumData static facade
   - File: Packages/PulsumData/Sources/PulsumData/PulsumData.swift
   - Remove ALL static accessors (PulsumData.container, .viewContext, etc.)
   - ModelContainer will be created at App layer and injected (done in Phase 0C)

NOTE: After this batch, downstream packages will have compile errors — that's expected. The build won't fully pass until Phase 0C wires the composition root.

Run swiftformat. Verify PulsumData package compiles in isolation: swift build --package-path Packages/PulsumData

Commit with message "Phase 0B: Replace DataStack with SwiftData ModelContainer, remove static facade (P0-02, P0-03)" and push.
```

---

## Phase 0C-1 — Composition Root + DataAgent @ModelActor Conversion

```
Read `master_plan_FINAL.md` items P0-06, P0-10, P0-11, P0-12 in full detail. Also re-read "Critical Execution Warnings" #1 and #2.

IMPORTANT: Search Apple docs for `@ModelActor`, `ModelActor` protocol, `FetchDescriptor`, `#Predicate` before starting.

BEFORE making any changes: create a safe-point commit with message "Safe point: before Phase 0C-1 — composition root + DataAgent conversion".

These items MUST be done together (per plan Warning #1 and #2). Order within this batch:

STEP 1 — Composition root (P0-11, P0-10, P0-12):
1a. P0-11: Update AppViewModel as ModelContainer composition root
    - File: Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift
    - Create DataStack during startup (it now throws — handle failure with .blocked state)
    - Expose ModelContainer property for SwiftUI (.modelContainer injection)
    - Pass same container to AgentOrchestrator

1b. P0-10: Update AgentOrchestrator to receive container + move off @MainActor
    - File: Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift
    - Change from @MainActor to actor
    - Accept ModelContainer in init, store it, pass to agents as they're migrated
    - Wire DataAgent first (this batch), remaining agents in Phase 0D

1c. P0-12: Update test helpers for SwiftData
    - Files: PulsumAgentsTests/TestCoreDataStack.swift, PulsumUITests/TestCoreDataStack.swift
    - Replace NSPersistentContainer with ModelContainer(isStoredInMemoryOnly: true)

STEP 2 — DataAgent @ModelActor conversion (P0-06):
2a. P0-06: Convert DataAgent to @ModelActor
    - File: Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift
    - Change to: @ModelActor actor DataAgent
    - @ModelActor provides modelContainer and modelContext automatically
    - Replace NSFetchRequest → FetchDescriptor + #Predicate
    - Replace context.save() → try modelContext.save()
    - Remove performAndWait entirely — @ModelActor context is actor-isolated
    - Public APIs MUST return Sendable snapshots (from P0-01b), NOT @Model objects
    - Do NOT decompose DataAgent yet — that happens in Phase 0C-2

VERIFY after implementation:
- Full build passes: xcodebuild -scheme Pulsum -sdk iphonesimulator -derivedDataPath /tmp/PulsumDerivedData
- All package tests pass
- No @Model objects cross actor boundaries (grep for "-> [DailyMetrics]" etc. in public APIs)

Run swiftformat, then commit with message "Phase 0C-1: Composition root + DataAgent @ModelActor conversion (P0-06, P0-10-P0-12)" and push.
```

---

## Phase 0C-2 — DataAgent Decomposition

```
Read `master_plan_FINAL.md` items P0-18, P0-19, P0-20, P0-21, P0-22 in full detail.

IMPORTANT: Read DataAgent.swift first to understand what was converted in Phase 0C-1. The file should already be a @ModelActor actor using SwiftData. This step extracts 5 focused types out of it.

BEFORE making any changes: create a safe-point commit with message "Safe point: before Phase 0C-2 — DataAgent decomposition".

Extract these 5 types from DataAgent.swift:

1. P0-18: Extract HealthKitIngestionCoordinator
   - Create: Packages/PulsumAgents/Sources/PulsumAgents/HealthKitIngestionCoordinator.swift
   - Move: HealthKit authorization, observer queries, background delivery, anchored queries
   - CRITICAL: Always call observer query completionHandler in ALL code paths

2. P0-19: Extract SampleProcessors
   - Create: Packages/PulsumAgents/Sources/PulsumAgents/SampleProcessing/ directory
   - Create protocol SampleProcessor + 5 processors: HRV, HeartRate, Sleep, Step, RespiratoryRate

3. P0-20: Extract BaselineCalculator
   - Create: Packages/PulsumAgents/Sources/PulsumAgents/BaselineCalculator.swift
   - Move: Baseline CRUD, z-score computation, feature vector materialization

4. P0-21: Extract BackfillCoordinator
   - Create: Packages/PulsumAgents/Sources/PulsumAgents/BackfillCoordinator.swift
   - Move: Two-phase bootstrap, retry/timeout/watchdog, BackfillProgress

5. P0-22: Verify DataAgent is thin coordinator
   - Target: DataAgent.swift < 500 lines
   - Should only contain: public API surface, delegation to extracted types, StateEstimator coordination

VERIFY after implementation:
- Full build passes: xcodebuild -scheme Pulsum -sdk iphonesimulator -derivedDataPath /tmp/PulsumDerivedData
- All package tests pass
- DataAgent.swift < 500 lines (check with: wc -l Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift)
- No @Model objects cross actor boundaries
- App launches end-to-end (if possible to verify)

Run swiftformat, then commit with message "Phase 0C-2: DataAgent decomposition into 5 extracted types (P0-18-P0-22)" and push.
```

---

## Phase 0D — Remaining Agent Migrations

```
Read `master_plan_FINAL.md` items P0-07, P0-08, P0-09, P0-16 in full detail.

IMPORTANT: Search Apple docs for `@ModelActor` and `FetchDescriptor` before starting.

BEFORE making any changes: create a safe-point commit with message "Safe point: before Phase 0D — remaining agent migrations".

Migrate each agent one at a time. Build-verify after EACH agent migration.

1. P0-07: Update SentimentAgent for SwiftData
   - File: Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift
   - Convert to @ModelActor actor
   - Replace NSManagedObjectContext → modelContext (provided by @ModelActor)
   - Replace NSFetchRequest → FetchDescriptor + #Predicate
   - Accept ModelContainer in init
   - Update AgentOrchestrator to pass container to SentimentAgent
   - BUILD AND TEST after this step

2. P0-08 + P0-16: Update CoachAgent for SwiftData (also completes actor isolation)
   - File: Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift + CoachAgent+Coverage.swift
   - Convert to @ModelActor actor (this inherently removes @MainActor — P0-16 is done)
   - Delete contextPerformAndWait helper entirely
   - Move persistence into @ModelActor-provided modelContext
   - Use PersistentIdentifier for cross-actor object references (ModelContext is NOT Sendable)
   - Accept ModelContainer in init
   - Update AgentOrchestrator to pass container to CoachAgent
   - BUILD AND TEST after this step

3. P0-09: Update LibraryImporter for SwiftData
   - File: Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift
   - Convert to @ModelActor actor
   - Embedding TaskGroup produces [Float] vectors (Sendable) — only final persist touches modelContext
   - Replace NSFetchRequest → FetchDescriptor + #Predicate
   - Single modelContext.save() at end (atomic commit)
   - Accept ModelContainer in init
   - Update AgentOrchestrator to pass container to LibraryImporter
   - BUILD AND TEST after this step

VERIFY after all 3 migrations:
- Full build passes
- All package tests pass
- No NSManagedObjectContext or NSFetchRequest in migrated files
- No performAndWait in any agent
- All agent public APIs return Sendable types

Run swiftformat, then commit with message "Phase 0D: Migrate SentimentAgent, CoachAgent, LibraryImporter to SwiftData (P0-07, P0-08, P0-09, P0-16)" and push.
```

---

## Phase 0E — Core Data Artifact Cleanup

```
Read `master_plan_FINAL.md` items P0-04 and P0-05.

IMPORTANT: Only proceed if ALL agents (DataAgent, SentimentAgent, CoachAgent, LibraryImporter) have been migrated to SwiftData in Phases 0C and 0D. If any agent still references Core Data types, DO NOT delete yet.

BEFORE making any changes: create a safe-point commit with message "Safe point: before Phase 0E — Core Data cleanup".

1. P0-04: Delete PulsumManagedObjectModel.swift
   - File: Packages/PulsumData/Sources/PulsumData/PulsumManagedObjectModel.swift
   - SwiftData uses code-based models — no bundle model loading needed

2. P0-05: Remove all remaining Core Data artifacts
   - Delete: ManagedObjects.swift
   - Delete: Pulsum.xcdatamodeld/ (entire directory)
   - Delete: PulsumCompiled.momd/ (entire directory)
   - Delete: Bundle+PulsumDataResources.swift (if only used for CD model loading)
   - Update: Packages/PulsumData/Package.swift — remove .process resources for xcdatamodeld and momd

VERIFY:
- Full build passes
- grep -r "NSManagedObjectContext\|NSPersistentContainer\|NSFetchRequest\|performAndWait" Packages/ — returns ZERO results
- grep -r "xcdatamodeld\|momd\|ManagedObjects" Packages/ — returns ZERO results
- All package tests pass

Run swiftformat, then commit with message "Phase 0E: Delete Core Data artifacts (P0-04, P0-05)" and push.
```

---

## Phase 0F — VectorStore Replacement

```
Read `master_plan_FINAL.md` items P0-13, P0-14, P0-15 in full detail.

IMPORTANT: Search Apple docs for Accelerate framework `vDSP_distancesq` before starting.

BEFORE making any changes: create a safe-point commit with message "Safe point: before Phase 0F — VectorStore replacement".

1. P0-13: Build in-memory VectorStore actor
   - Create: Packages/PulsumData/Sources/PulsumData/VectorStore.swift
   - Actor holding vectors in memory with file-backed persistence
   - Binary format (NOT JSON) — 500 x 384 floats = ~770KB binary vs ~3MB JSON
   - Format: entry count (UInt32), then per entry: id-length (UInt16) + id (UTF-8) + vector (384 x Float raw bytes)
   - bulkUpsert() for library import (single file write, not 500 individual writes)
   - persist() is explicit with isDirty flag
   - Search uses vDSP_distancesq from Accelerate (hardware-accelerated, <1ms for 500 vectors)
   - Data.write(to:options:.atomic) for crash safety
   - NSFileProtectionCompleteUnlessOpen on the file
   - Actor isolation replaces all manual locking

2. P0-14: Update VectorIndexManager to use VectorStore
   - File: Packages/PulsumData/Sources/PulsumData/VectorIndexManager.swift
   - Replace internal VectorIndex with VectorStore
   - VectorIndexProviding protocol stays same — consumers don't change
   - Remove all sharding logic

3. P0-15: Delete old VectorIndex.swift
   - Delete: Packages/PulsumData/Sources/PulsumData/VectorIndex.swift (437 lines)

VERIFY:
- Full build passes
- swift test --package-path Packages/PulsumData
- grep -r "VectorIndexShard\|VectorRecordHeader\|VectorIndexHeader" Packages/ — returns ZERO
- bulkUpsert 500 vectors results in single file write
- Search returns correct top-K results

Run swiftformat, then commit with message "Phase 0F: Replace VectorIndex with VectorStore actor (P0-13, P0-14, P0-15)" and push.
```

---

## Phase 0G — SafetyAgent + SettingsViewModel Split + Observation Cleanup

```
Read `master_plan_FINAL.md` items P0-17, P0-23, P0-24, P0-25, P0-26.

BEFORE making any changes: create a safe-point commit with message "Safe point: before Phase 0G — actor isolation + VM split + observation".

1. P0-17: Change SafetyAgent to protocol-backed struct
   - File: Packages/PulsumAgents/Sources/PulsumAgents/SafetyAgent.swift
   - SafetyAgent is stateless after init (91 lines, no mutable state)
   - Define: protocol SafetyClassifying { func classify(text:) async -> SafetyClassification }
   - Make SafetyAgent a struct conforming to SafetyClassifying + Sendable
   - Inject classifiers (FoundationModelsSafetyProvider, SafetyLocal) via init with defaults
   - Structs are automatically Sendable if all stored properties are Sendable

2. P0-23: Extract HealthSettingsViewModel
   - Create: Packages/PulsumUI/Sources/PulsumUI/HealthSettingsViewModel.swift
   - Move: health access state, authorization requests, toast handling from SettingsViewModel

3. P0-24: Extract DiagnosticsViewModel
   - Create: Packages/PulsumUI/Sources/PulsumUI/DiagnosticsViewModel.swift
   - Move: diagnostics config, logs, export, FM status from SettingsViewModel

4. P0-25: Update SettingsView to compose split ViewModels
   - SettingsView now uses HealthSettingsViewModel + DiagnosticsViewModel + slimmed SettingsViewModel

5. P0-26: Replace closure callbacks with observable properties
   - File: Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift
   - Replace onConsentChanged, onSafetyDecision closures with @Observable properties

VERIFY:
- Full build passes
- All package tests pass
- SafetyAgent is a struct (not class/actor)
- SettingsViewModel is significantly smaller
- No closure callbacks in AppViewModel for consent/safety

Run swiftformat, then commit with message "Phase 0G: SafetyAgent struct, SettingsVM split, observation cleanup (P0-17, P0-23-P0-26)" and push.
```

---

## Phase 0 — Final Verification

```
Read `master_plan_FINAL.md` section "Phase 0 Done When" checklist.

This is a verification-only step. Do NOT make code changes unless a check fails.

Run these checks and report results:

1. Full build: xcodebuild -scheme Pulsum -sdk iphonesimulator -derivedDataPath /tmp/PulsumDerivedData
2. All package tests:
   swift test --package-path Packages/PulsumML
   swift test --package-path Packages/PulsumData
   swift test --package-path Packages/PulsumServices
   swift test --package-path Packages/PulsumAgents
   swift test --package-path Packages/PulsumUI
3. swiftformat . (should be clean)
4. scripts/ci/check-privacy-manifests.sh

5. Verify removals:
   grep -r "NSManagedObjectContext\|NSPersistentContainer\|performAndWait" Packages/
   grep -r "VectorIndexShard\|VectorRecordHeader\|VectorIndexHeader" Packages/
   — Both should return ZERO results

6. Verify DataAgent size: wc -l Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift
   — Must be < 500 lines

7. Verify all agent public APIs return Sendable types:
   grep -rn "-> \[DailyMetrics\]\|-> \[JournalEntry\]\|-> \[Baseline\]\|-> \[FeatureVector\]" Packages/PulsumAgents/
   — Should return ZERO (only snapshot arrays cross actor boundaries)

8. Verify SWIFT_DEFAULT_ACTOR_ISOLATION is NOT set in non-UI package targets

9. Verify uniqueness: Check that DailyMetrics.date, FeatureVector.date, LibraryIngest.source, UserPrefs.id, ConsentState.version have @Attribute(.unique), and Baseline has #Unique

If all checks pass, report "Phase 0 Complete" with a summary. If any fail, fix them and commit.

After all checks pass, merge to main:
git checkout main && git merge refactor/phase0-architecture && git push
```

---

# AFTER PHASE 0 — Phases 1-3

Phases 1-3 from `master_plan_FINAL.md` come next. **Many items from Phases 1-3 were already completed in Batches 1-7** (safety fixes, ML corrections, concurrency, compliance). Before starting each phase, cross-reference the batch commit history to skip already-done items.

Key items remaining that were NOT covered by Batches 1-7:
- P1-05: Expand PII redaction (SSN, credit card, IP patterns)
- P1-11: Medical disclaimer in CoachView footer
- P1-12: 988 Lifeline in SafetyCardView
- P1-13: AI-generated content label in CoachView
- P1-14: Score methodology disclosure
- P3-01: Delete All Data (needs SwiftData bulk delete — depends on Phase 0)
- P3-03: MetricKit crash diagnostics
- P3-04: Analytics event structure
- P3-05: NetworkMonitor
- P3-06: Offline banner
- P3-07: Rate limiter
- P3-09: Auto-increment build number
- P3-10: Centralize UserDefaults keys
- P3-13: App rating prompt
- P3-17-P3-19: Test coverage expansion

Prompts for these phases will be added after Phase 0 is verified complete.
