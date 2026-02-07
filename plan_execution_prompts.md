# Pulsum — Plan Execution Prompts

**Purpose:** Step-by-step prompts to execute `master_plan_FINAL.md` using Claude Code (Opus 4.6, thinking, 1M context).
**How to use:** Run one prompt at a time. Test between each. Commit after each succeeds. Start a new chat window for each prompt.

---

## Pre-Flight Setup (Do Once Before Starting)

### 1. Verify Claude Code Settings

In your Claude Code / Cursor AI setup, confirm:
- **Model:** Opus 4.6 (1M context)
- **Thinking:** Enabled (max)
- **Agent mode:** Yes (not plan mode)

### 2. Create the Branch

```bash
git checkout -b refactor/phase0-architecture
```

### 3. Verify Guardrail #8 (Default Actor Isolation)

Before any code changes, run this prompt in a quick Claude Code session:

```
Read every Package.swift file in the Packages/ directory. Check if any of them
have swiftSettings containing defaultIsolation(.mainActor). Report which packages
have it and which don't. Also check the app target's build settings in the
.pbxproj for SWIFT_DEFAULT_ACTOR_ISOLATION.

DO NOT modify any files. Just report findings.
```

**Expected result:** SPM packages should NOT have MainActor default isolation. Only the app target should. If any non-UI package has it, remove it before proceeding.

### 4. Git Discipline

**Before each prompt:** Verify clean git state (`git status` — no uncommitted changes).
**After each prompt succeeds:** Commit with the P-item IDs: `git commit -m "P0-01: Create @Model classes for all 9 entities"`
**If a prompt fails:** `git stash` or `git checkout .` to revert, then debug in a new chat window.
**Never amend previous commits** — always create new ones.

---

## Rules for Every Prompt

Every prompt below includes these instructions implicitly. You do NOT need to repeat them — they're here for your reference:

1. **Always start a NEW chat window** for each prompt (fresh context = no stale state)
2. **Always read `master_plan_FINAL.md`** at the start (the prompt tells the agent to do this)
3. **One item at a time** within each prompt — the agent should complete, verify, then move to the next
4. **Build after every change** — `xcodebuild -scheme Pulsum -sdk iphoneos -derivedDataPath ./DerivedData`
5. **Format after every change** — `swiftformat .`
6. **Search Apple docs** before using any SwiftData, Foundation Models, or Liquid Glass API
7. **Do NOT refactor adjacent code** — only touch what the item specifies
8. **Use `Diagnostics.log()` not `print()`**
9. **Use `String(localized:)` for new user-facing strings**
10. **Reference finding IDs in commits** — `fix: CRIT-002 — FM guardrail returns .caution`
11. **Update progress in `master_plan_FINAL.md`** — after EACH completed item, change `[ ]` to `[x]` and add the date: `[x] *(2026-02-XX)*`. Also update the Progress Tracker table (done count + percentage). This is how you track progress across chat windows.

---

## CRITICAL: Progress Tracking (applies to ALL prompts)

Every prompt below includes this instruction at the end:

> **After completing each P-item, update `master_plan_FINAL.md`:**
> 1. Change the item's `[ ]` to `[x] *(YYYY-MM-DD)*` (today's date)
> 2. Update the **Progress Tracker** table at the bottom (increment the "Done" column for the current phase)
> 3. Update the **Total** row percentage
>
> This is how progress persists across chat windows. The next agent session reads
> `master_plan_FINAL.md` and sees what's already done.

**When copy-pasting prompts, ALWAYS append this block at the very end:**

```
IMPORTANT — PROGRESS TRACKING (do this after EACH completed item):
1. Open master_plan_FINAL.md
2. Find the item you just completed (e.g., P0-01)
3. Change its [ ] to [x] *(YYYY-MM-DD)* with today's date
4. Update the Progress Tracker table at the bottom:
   - Increment the "Done" column for the current phase
   - Recalculate the Total row percentage
5. Save the file
This is mandatory — it's how progress persists across chat windows.
```

**Why this matters:** Each prompt runs in a fresh chat window. The agent has no memory of previous sessions. The only way it knows what's done is by reading `master_plan_FINAL.md` and seeing which items are `[x]`. If you skip this, the next session won't know where you left off.

---

## Phase 0: Architecture Foundation

### PROMPT 0-A: Create SwiftData Models + DTO Snapshots (P0-01 + P0-01b)

**New chat window.** Copy-paste this prompt:

```
Read master_plan_FINAL.md completely before doing anything.

You are implementing P0-01 and P0-01b from the Pulsum master remediation plan.

## P0-01: Create @Model classes for all 9 entities

Create new files in Packages/PulsumData/Sources/PulsumData/Model/ for each entity.
Read the existing ManagedObjects.swift and Pulsum.xcdatamodel/contents first to
understand the current Core Data schema — every attribute must be preserved.

Follow the entity table in master_plan_FINAL.md P0-01 exactly. Key requirements:
- Use native Swift types (NOT NSNumber)
- Add @Attribute(.unique) where specified (DailyMetrics.date, FeatureVector.date,
  LibraryIngest.source, UserPrefs.id, ConsentState.version)
- Add #Unique<Baseline>([\.metric, \.windowDays]) for compound uniqueness
- Add #Index macros as specified
- MicroMoment.tags is String? (JSON string), NOT [String]
- Search Apple docs for SwiftData @Model, #Index, #Unique, @Attribute(.unique)
  before writing any code

## P0-01b: Create Sendable DTO snapshot types

Create Packages/PulsumTypes/Sources/PulsumTypes/ModelSnapshots.swift with Sendable
snapshot structs: DailyMetricsSnapshot, WellbeingScoreSnapshot, JournalEntrySnapshot,
and any others needed by cross-actor APIs (check what DataAgent, CoachAgent,
SentimentAgent currently return to callers).

Also create snapshot mapping extensions in PulsumData (not PulsumTypes):
Packages/PulsumData/Sources/PulsumData/Model/ModelSnapshots+Mapping.swift

Each @Model class gets a `var snapshot: <SnapshotType>` computed property.

## Rules
- Do NOT delete or modify existing Core Data files yet
- Do NOT modify any agent files yet
- Build must succeed with BOTH old CD types AND new SwiftData models coexisting
- Run swiftformat . after all files are created
- After completing P0-01: open master_plan_FINAL.md, change P0-01's `[ ]` to
  `[x] *(today's date)*`. After completing P0-01b: same. Update the Progress
  Tracker table (Phase 0 done count).
- Verify: all 9 model files + snapshot file compile. Run swift test --package-path
  Packages/PulsumData and swift test --package-path Packages/PulsumTypes
```

**After this prompt:**
- Verify 9 new model files exist in `Packages/PulsumData/Sources/PulsumData/Model/`
- Verify `ModelSnapshots.swift` exists in PulsumTypes
- Verify build succeeds
- Verify `master_plan_FINAL.md` shows P0-01 and P0-01b as `[x]` with today's date
- Verify Progress Tracker shows Phase 0: 2 done
- `git add` the new files and commit: `git commit -m "P0-01 + P0-01b: Create SwiftData @Model classes and DTO snapshots"`

---

### PROMPT 0-B: Replace DataStack + Remove Static Facade (P0-02 + P0-03)

**New chat window.**

```
Read master_plan_FINAL.md completely before doing anything.

You are implementing P0-02 and P0-03 from the Pulsum master remediation plan.

## P0-02: Replace DataStack with SwiftData ModelContainer

File: Packages/PulsumData/Sources/PulsumData/DataStack.swift

Read the current file first. Then:
- Replace NSPersistentContainer with ModelContainer
- Make init() throws (NOT fatalError) — this fixes CRIT-004
- Apply NSFileProtectionCompleteUnlessOpen (NOT Complete — see plan for rationale)
- Keep StoragePaths struct
- Enable backup exclusion
- Search Apple docs for ModelContainer, ModelConfiguration before changing

## P0-03: Replace PulsumData static facade with injectable access

File: Packages/PulsumData/Sources/PulsumData/PulsumData.swift

- Remove ALL static accessors (PulsumData.container, .viewContext, etc.)
- The ModelContainer will be created in the App layer (P0-11) and injected
- For now, callers that used PulsumData.container will have compile errors —
  that's expected and will be fixed in P0-06 through P0-09

## Rules
- Do NOT delete ManagedObjects.swift or the xcdatamodeld yet
- Do NOT modify any agent files yet
- Build MAY have errors in PulsumAgents/PulsumUI packages — that's expected
  because agents still reference the old static facade. Only verify that
  PulsumData package itself compiles: swift test --package-path Packages/PulsumData
- Run swiftformat . after changes

IMPORTANT: After completing each item, update master_plan_FINAL.md:
- Change the item's [ ] to [x] *(today's date)*
- Update the Progress Tracker table (done count + total percentage)
```

**After this prompt:**
- Verify PulsumData package compiles
- Expect compile errors in downstream packages (agents still reference old facade) — that's OK
- Commit: `git commit -m "P0-02 + P0-03: Replace DataStack with ModelContainer, remove static facade"`

---

### PROMPT 0-C: Migrate DataAgent + Decompose (P0-06 + P0-18 through P0-22)

**New chat window. This is the largest single prompt — it combines the DataAgent SwiftData migration with its decomposition per Warning #2.**

```
Read master_plan_FINAL.md completely before doing anything. Pay special attention
to Warning #2 (combine P0-06 with P0-18-P0-22) and the SwiftData Concurrency Rules.

You are implementing P0-06, P0-18, P0-19, P0-20, P0-21, and P0-22 together.

## Context

DataAgent.swift is currently ~3,706 lines with 10+ responsibilities. The plan
says to migrate it to SwiftData AND decompose it in one combined effort so we
don't touch it twice.

## Step 1: Read everything first

Read these files completely before making ANY changes:
- Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift (all lines)
- The new @Model classes you created in P0-01
- The DTO snapshots from P0-01b
- master_plan_FINAL.md sections for P0-06, P0-18, P0-19, P0-20, P0-21, P0-22

## Step 2: Create the extracted types (P0-18 through P0-21)

Create these new files, already using SwiftData from the start:

1. HealthKitIngestionCoordinator.swift — HealthKit auth, observer queries,
   background delivery, sample callbacks. MUST call completionHandler on all paths.
2. SampleProcessing/ directory with protocol + 5 processor files (HRV, HeartRate,
   Sleep, Steps, RespiratoryRate)
3. BaselineCalculator.swift — Baseline CRUD, z-scores, feature vectors
4. BackfillCoordinator.swift — bootstrap lifecycle, retry, watchdog

Each extracted type that does persistence must either:
- Be a @ModelActor actor (if it owns a ModelContext), or
- Receive data as Sendable types and delegate persistence to the owning actor

## Step 3: Slim down DataAgent (P0-06 + P0-22)

Make DataAgent a @ModelActor actor. It should:
- Delegate to the 4 extracted types
- Keep only: public API surface, StateEstimator coordination, notification posting
- Return DTO snapshots (not @Model objects) from all public methods
- Target: < 500 lines

## Rules
- Use @ModelActor for DataAgent (see plan's code example)
- All public APIs return Sendable snapshots, not @Model objects
- Use FetchDescriptor + #Predicate, not NSFetchRequest
- Use modelContext.save(), not context.save()
- No performAndWait — @ModelActor context is actor-isolated
- Search Apple docs for @ModelActor, FetchDescriptor, #Predicate
- Build after creating each file: xcodebuild -scheme Pulsum -sdk iphoneos
  -derivedDataPath ./DerivedData
- Run swiftformat . after all changes
- Verify: wc -l on DataAgent.swift < 500 lines. Run package tests:
  swift test --package-path Packages/PulsumAgents

IMPORTANT — PROGRESS TRACKING: After completing ALL items in this batch,
open master_plan_FINAL.md and change [ ] to [x] *(today's date)* for:
P0-06, P0-18, P0-19, P0-20, P0-21, P0-22. Update Progress Tracker done count.
```

**After this prompt:**
- Verify DataAgent.swift < 500 lines
- Verify 4 new extracted files + 5 sample processor files exist
- Verify PulsumAgents package tests pass
- Commit: `git commit -m "P0-06 + P0-18-P0-22: Migrate DataAgent to SwiftData + decompose into focused types"`

---

### PROMPT 0-D: Migrate SentimentAgent (P0-07)

**New chat window.**

```
Read master_plan_FINAL.md P0-07 before doing anything.

You are implementing P0-07: Update SentimentAgent for SwiftData.

File: Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift

Read the file first. Then:
- Make it a @ModelActor actor (if it uses persistence) or accept ModelContainer
- Replace NSManagedObjectContext with ModelContext
- Replace NSFetchRequest with FetchDescriptor
- Public APIs must return Sendable types (snapshots), not @Model objects
- Search Apple docs for @ModelActor before changing

Verify: build succeeds, swiftformat clean, package tests pass.

IMPORTANT — PROGRESS TRACKING: After completing P0-07, open master_plan_FINAL.md,
change P0-07's [ ] to [x] *(today's date)*, update Progress Tracker done count.
```

**Commit:** `git commit -m "P0-07: Migrate SentimentAgent to SwiftData"`

---

### PROMPT 0-E: Migrate CoachAgent (P0-08)

**New chat window.**

```
Read master_plan_FINAL.md P0-08 before doing anything.

You are implementing P0-08: Update CoachAgent for SwiftData (eliminates HIGH-007).

Files:
- Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift
- Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent+Coverage.swift

Read both files first. Then:
- Delete contextPerformAndWait helper entirely
- Move persistence into @ModelActor-provided modelContext
- ModelContext is NOT Sendable — don't pass between actors
- Use PersistentIdentifier for cross-actor object references
- Public APIs must return Sendable snapshots
- Search Apple docs for @ModelActor

Verify: build succeeds, swiftformat clean, CoachAgent tests pass.

IMPORTANT — PROGRESS TRACKING: After completing P0-08, open master_plan_FINAL.md,
change P0-08's [ ] to [x] *(today's date)*, update Progress Tracker done count.
```

**Commit:** `git commit -m "P0-08: Migrate CoachAgent to SwiftData, eliminate HIGH-007"`

---

### PROMPT 0-F: Migrate LibraryImporter (P0-09)

**New chat window.**

```
Read master_plan_FINAL.md P0-09 before doing anything.

You are implementing P0-09: Update LibraryImporter for SwiftData using @ModelActor.

File: Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift

Read the file first. Then:
- Make it @ModelActor actor LibraryImporter
- The embedding TaskGroup produces [Float] vectors (Sendable) — that's fine
- Only the persistence step (insert/update MicroMoments) touches modelContext
- Replace NSFetchRequest with FetchDescriptor
- Do NOT manually create ModelContext(container) as a stored property
- Search Apple docs for @ModelActor

Verify: build succeeds, swiftformat clean, library import creates records.

IMPORTANT — PROGRESS TRACKING: After completing P0-09, open master_plan_FINAL.md,
change P0-09's [ ] to [x] *(today's date)*, update Progress Tracker done count.
```

**Commit:** `git commit -m "P0-09: Migrate LibraryImporter to @ModelActor"`

---

### PROMPT 0-G: Delete Core Data Artifacts (P0-04 + P0-05)

**New chat window. Only run this AFTER all agents are migrated (0-C through 0-F).**

```
Read master_plan_FINAL.md P0-04 and P0-05.

You are implementing P0-04 and P0-05: Delete Core Data artifacts.

IMPORTANT: This is Step C from Warning #1. All agents must already be migrated
to SwiftData before running this. If any agent still references Core Data types,
this will break the build.

## P0-04: Delete PulsumManagedObjectModel.swift
Delete: Packages/PulsumData/Sources/PulsumData/PulsumManagedObjectModel.swift

## P0-05: Remove Core Data artifacts
Delete:
- ManagedObjects.swift
- Pulsum.xcdatamodeld/ (entire directory)
- PulsumCompiled.momd/ (entire directory)
- Bundle+PulsumDataResources.swift (if only used for CD model loading)

Update Packages/PulsumData/Package.swift:
- Remove .process("PulsumData/Resources/Pulsum.xcdatamodeld")
- Remove .process("PulsumData/Resources/PulsumCompiled.momd")

Verify:
- Full build succeeds: xcodebuild -scheme Pulsum -sdk iphoneos -derivedDataPath ./DerivedData
- grep -r "NSManagedObjectContext\|NSPersistentContainer\|performAndWait" Packages/ returns zero
- grep -r "ManagedObjects\|xcdatamodel\|PulsumManagedObjectModel" Packages/ returns zero
- swiftformat . clean

IMPORTANT — PROGRESS TRACKING: After completing P0-04 and P0-05, open
master_plan_FINAL.md, change their [ ] to [x] *(today's date)*, update
Progress Tracker done count.
```

**Commit:** `git commit -m "P0-04 + P0-05: Remove all Core Data artifacts"`

---

### PROMPT 0-H: Orchestrator + AppViewModel + Test Helpers (P0-10 + P0-11 + P0-12)

**New chat window.**

```
Read master_plan_FINAL.md P0-10, P0-11, and P0-12 before doing anything.

You are implementing P0-10, P0-11, and P0-12.

## P0-10: Update AgentOrchestrator to receive container + move off @MainActor

File: Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift

- RECEIVE ModelContainer from App layer (don't create it here)
- Change from @MainActor to actor
- Pass container to DataAgent, SentimentAgent, CoachAgent, LibraryImporter inits
- Fix all call-site compiler errors (callers need await)

## P0-11: Update AppViewModel as ModelContainer composition root

File: Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift

- Create DataStack (ModelContainer) during startup
- Handle init failure with .blocked state
- Expose container property for SwiftUI .modelContainer() injection
- Pass container to AgentOrchestrator.init(container:)

## P0-12: Update test helpers for SwiftData

Files: PulsumAgentsTests/TestCoreDataStack.swift, PulsumUITests/TestCoreDataStack.swift

- Replace in-memory NSPersistentContainer with ModelContainer
- Use ModelConfiguration(isStoredInMemoryOnly: true)

Verify:
- Full build succeeds
- ALL package tests pass (swift test for each package)
- swiftformat . clean
```

**Commit:** `git commit -m "P0-10 + P0-11 + P0-12: Wire composition root, move orchestrator off MainActor, update test helpers"`

---

### PROMPT 0-I: Vector Index Replacement (P0-13 + P0-14 + P0-15)

**New chat window.**

```
Read master_plan_FINAL.md P0-13, P0-14, and P0-15 before doing anything.

You are implementing P0-13, P0-14, and P0-15: Replace the vector index.

## P0-13: Build VectorStore actor

Create: Packages/PulsumData/Sources/PulsumData/VectorStore.swift

Follow the plan's code template exactly. Key requirements:
- Actor (not class) — actor isolation replaces all locking
- Binary format (not JSON) — entry count + id-length + id + float data
- bulkUpsert for library import (single persist after all inserts)
- vDSP_distancesq from Accelerate for L2 distance
- NSFileProtectionCompleteUnlessOpen on the file
- Data.write(to:options:.atomic) for crash safety

## P0-14: Update VectorIndexManager to use VectorStore

File: Packages/PulsumData/Sources/PulsumData/VectorIndexManager.swift

- Replace internal VectorIndex with VectorStore
- Keep VectorIndexProviding protocol unchanged
- Remove sharding logic

## P0-15: Delete old VectorIndex.swift

Delete: Packages/PulsumData/Sources/PulsumData/VectorIndex.swift

Verify:
- Build succeeds
- grep -r "VectorIndexShard\|VectorRecordHeader\|VectorIndexHeader" Packages/ = zero
- VectorIndexManager tests pass
- swiftformat . clean
```

**Commit:** `git commit -m "P0-13 + P0-14 + P0-15: Replace vector index with in-memory VectorStore actor"`

---

### PROMPT 0-J: Actor Isolation (P0-16 + P0-17)

**New chat window.**

```
Read master_plan_FINAL.md P0-16 and P0-17 before doing anything.

## P0-16: Change CoachAgent from @MainActor class to actor

Files: CoachAgent.swift, CoachAgent+Coverage.swift
Fix call sites in AgentOrchestrator.swift.

## P0-17: Change SafetyAgent to protocol-backed struct

File: SafetyAgent.swift

- Define SafetyClassifying protocol
- Make SafetyAgent a struct conforming to SafetyClassifying + Sendable
- Inject classifiers via init
- It has no mutable state — struct is the correct type

Verify: build succeeds, all tests pass, swiftformat clean.
```

**Commit:** `git commit -m "P0-16 + P0-17: Actor isolation for CoachAgent and SafetyAgent"`

---

### PROMPT 0-K: SettingsViewModel Split + Observation Cleanup (P0-23 through P0-26)

**New chat window.**

```
Read master_plan_FINAL.md P0-23, P0-24, P0-25, and P0-26 before doing anything.

## P0-23: Extract HealthSettingsViewModel
Create: Packages/PulsumUI/Sources/PulsumUI/HealthSettingsViewModel.swift
Move: health access, authorization, toast logic from SettingsViewModel

## P0-24: Extract DiagnosticsViewModel
Create: Packages/PulsumUI/Sources/PulsumUI/DiagnosticsViewModel.swift
Move: config, logs, export, FM status from SettingsViewModel

## P0-25: Update SettingsView to compose the split ViewModels

## P0-26: Replace closure callbacks with observable properties
File: AppViewModel.swift (onConsentChanged, onSafetyDecision → observable props)

Verify: build succeeds, all tests pass, swiftformat clean.
```

**Commit:** `git commit -m "P0-23-P0-26: Split SettingsViewModel, cleanup observation pattern"`

---

### PROMPT 0-FINAL: Phase 0 Verification Gate

**New chat window. This is a verification-only prompt — no code changes.**

```
Read master_plan_FINAL.md "Phase 0 Done When" checklist.

Verify ALL of these gates. Report PASS or FAIL for each:

1. All 27 Phase 0 items implemented (check git log for commits)
2. Full build passes: xcodebuild -scheme Pulsum -sdk iphoneos -derivedDataPath ./DerivedData
3. All package tests pass (swift test for each of the 5 packages)
4. swiftformat . produces no changes
5. scripts/ci/check-privacy-manifests.sh passes
6. DataAgent.swift < 500 lines (run wc -l)
7. No NSManagedObjectContext, NSPersistentContainer, performAndWait in source
   (grep -r across Packages/)
8. No VectorIndexShard, VectorRecordHeader in source
9. All agent public APIs return Sendable types — grep for functions returning
   @Model types like [DailyMetrics], [JournalEntry], etc. across actor boundaries
10. SWIFT_DEFAULT_ACTOR_ISOLATION not set to MainActor in non-UI Package.swift files
11. Uniqueness: write a quick test — insert two DailyMetrics with same date,
    save, verify exactly 1 row (upsert behavior)
12. Report any remaining compiler warnings

DO NOT modify any files. Only verify and report.
```

**After verification passes:** Tag the commit: `git tag phase0-complete`

**Then: Manual smoke test (Warning #3)** — Run the app on device/simulator and verify:
- App launches without crash
- HealthKit data flows to wellbeing score
- Voice journal records and transcribes
- Coach chat responds (on-device)
- Settings save and persist
- Safety card appears for crisis content

---

## Phase 1: Safety & Critical Bugs

**Branch:** `git checkout -b fix/phase1-safety`

### PROMPT 1-A: Safety Fixes (P1-01 through P1-05)

**New chat window.**

```
Read master_plan_FINAL.md Phase 1, section 1.1 (Safety Fixes).

Implement P1-01 through P1-05, one at a time. For each item:
1. Read the finding ID in master_report.md for full context
2. Read the target file completely
3. Make the change
4. Build and verify
5. Run swiftformat .

Items:
- P1-01: CRIT-002 — FM guardrail violations return .caution not .safe
- P1-02: CRIT-003 — Unify intentTopic enum between CoachPhrasingSchema and LLMGateway
- P1-03: CRIT-005 — Expand crisis keywords in SafetyLocal.swift and SafetyAgent.swift
- P1-04: HIGH-010 — High-confidence crisis without keyword (embedding > 0.85 = crisis)
- P1-05: MED-014 — Expand PII redaction (SSN, credit card with Luhn, IP address)

After all 5: full build + all tests pass + swiftformat clean.

IMPORTANT — PROGRESS TRACKING: After each completed item, open master_plan_FINAL.md,
change its [ ] to [x] *(today's date)*, update Progress Tracker done count.
```

**Commit each separately or as one:** `git commit -m "P1-01 through P1-05: Safety fixes — FM guardrail, crisis keywords, PII redaction"`

---

### PROMPT 1-B: ML Pipeline Fixes (P1-06 through P1-09)

**New chat window.**

```
Read master_plan_FINAL.md Phase 1, section 1.2 (ML Pipeline Fixes).

Implement P1-06 through P1-09:
- P1-06: HIGH-001 — Fix RecRanker Bradley-Terry gradient (pairwise formula)
- P1-07: HIGH-002 + MED-003 — Add NL sentiment fallback provider
- P1-08: HIGH-003 — Topic gate permissive when degraded (return isOnTopic:true on failure)
- P1-09: MED-002 — Remove AFM gate on NLEmbedding

For each: read the file, read the finding in master_report.md, implement, build, test.

IMPORTANT — PROGRESS TRACKING: After each completed item, open master_plan_FINAL.md,
change its [ ] to [x] *(today's date)*, update Progress Tracker done count.
```

**Commit:** `git commit -m "P1-06 through P1-09: ML pipeline fixes — RecRanker, sentiment, topic gate, NLEmbedding"`

---

### PROMPT 1-C: App Store Compliance (P1-10 through P1-14)

**New chat window.**

```
Read master_plan_FINAL.md Phase 1, section 1.3 (App Store Compliance).
Also read guidelines_report.md for full compliance context.

Implement P1-10 through P1-14:
- P1-10: HIGH-005 — Fix stuck isAnalyzing in PulseViewModel
- P1-11: GL-1.4.1 FAIL — Add medical disclaimer to OnboardingView, SettingsView, CoachView
- P1-12: GL-1.4.1 AT RISK — Add 988 Lifeline to SafetyCardView + SafetyAgent
- P1-13: GL-1.4.1 AT RISK — Label AI-generated content in CoachView ChatBubble
- P1-14: GL-1.4.1 AT RISK — Score methodology disclosure in ScoreBreakdownView

Use String(localized:) for all new user-facing text.
After all 5: full build + all tests pass + swiftformat clean.

IMPORTANT — PROGRESS TRACKING: After each completed item, open master_plan_FINAL.md,
change its [ ] to [x] *(today's date)*, update Progress Tracker done count.
```

**Commit:** `git commit -m "P1-10 through P1-14: App Store compliance — disclaimers, 988, AI labels, methodology"`

---

## Phase 2: Concurrency & Cleanup

**Branch:** `git checkout -b fix/phase2-cleanup`

### PROMPT 2-A: Concurrency Fixes (P2-01 through P2-05)

**New chat window.**

```
Read master_plan_FINAL.md Phase 2 items P2-01 through P2-05.

Implement each one at a time:
- P2-01: HIGH-004 — Add serial DispatchQueue to LegacySpeechBackend
- P2-02: MED-001 — Confine RecRanker + StateEstimator inside owning actors (no locks)
- P2-03: MED-007 — Fix HealthKitAnchorStore read/write asymmetry (store → queue.sync)
- P2-04: MED-008 — Add reprocessDay to submitTranscript in AgentOrchestrator
- P2-05: MED-011 — Convert LLMGateway to actor (or isolate key storage)

For each: read the file + finding in master_report.md first. Build and test after each.
```

---

### PROMPT 2-B: Bug Fixes + Cleanup (P2-06 through P2-12)

**New chat window.**

```
Read master_plan_FINAL.md Phase 2 items P2-06 through P2-12.

Implement each one:
- P2-06: MED-012 — Document testAPIConnection consent
- P2-07: MED-016 — Verify day-boundary timezone handling
- P2-08: LOW-002 — Guard zScore against zero MAD
- P2-09: LOW-003 — NaN guard in StateEstimator
- P2-10: LOW-004 — Fix sanitize punctuation
- P2-11: LOW-005 — Remove duplicate #if DEBUG
- P2-12: LOW-006 — Fix speech timeout task leak

Build and test after each change.
```

---

### PROMPT 2-C: Remaining Cleanup (P2-13 through P2-19)

**New chat window.**

```
Read master_plan_FINAL.md Phase 2 items P2-13 through P2-19.

Implement each one:
- P2-13: LOW-007 — Log RecRanker state version mismatch
- P2-14: LOW-008 + LOW-009 — Fix ViewModel task leaks (deinit, stored tasks)
- P2-15: LOW-010 — Cache DateFormatters (static let)
- P2-16: LOW-001 — Clean up EvidenceScorer dead domains
- P2-17: MED-006 — Fix LibraryImporter non-atomic 3-phase commit
- P2-18: MED-010 — Fix OnboardingView bypassing orchestrator auth
- P2-19: STUB-003 — Fix FM TopicGate returning nil topic

Build and test after each change. Full build + all tests after last item.
```

---

## Phase 3: Production Readiness

**Branch:** `git checkout -b feat/phase3-production`

### PROMPT 3-A: Compliance + Observability (P3-01 through P3-04)

**New chat window.**

```
Read master_plan_FINAL.md Phase 3 items P3-01 through P3-04.

- P3-01: PROD-006 — Delete All Data (GDPR) — use SwiftData bulk delete pattern
  from the plan. Run inside a @ModelActor context.
- P3-02: PROD-007 — Persist onboarding completion with @AppStorage
- P3-03: PROD-002 — Add MetricKit crash diagnostics subscriber
- P3-04: PROD-003 — Add analytics event structure + NoOp provider
```

---

### PROMPT 3-B: Network + Accessibility (P3-05 through P3-08)

**New chat window.**

```
Read master_plan_FINAL.md Phase 3 items P3-05 through P3-08.

- P3-05: PROD-004 — Build NetworkMonitor (NWPathMonitor wrapper)
- P3-06: PROD-016 — Offline banner in CoachView
- P3-07: PROD-015 — Rate limiter for LLMGateway
- P3-08: HIGH-006 — Dynamic Type support (semantic fonts, search Apple docs first)
```

---

### PROMPT 3-C: Build & Ops (P3-09 through P3-16)

**New chat window.**

```
Read master_plan_FINAL.md Phase 3 items P3-09 through P3-16.

- P3-09: PROD-013 — Auto-increment build number
- P3-10: PROD-017 — Centralize UserDefaults keys in PulsumDefaults
- P3-11: LOW-012 + LOW-013 — Fix empty PulsumTests + enable in scheme
- P3-12: LOW-014 — Compile-gate KeychainService UITest fallback
- P3-13: PROD-011 — App rating prompt (ViewModel flag, View calls requestReview)
- P3-14: PROD-014 — Audit Release logging for PHI leaks
- P3-15: PROD-010 — SSL cert pinning (EVALUATE — likely defer to v1.1)
- P3-16: PROD-018 — Add units to health data display
```

---

### PROMPT 3-D: Test Coverage (P3-17 through P3-19)

**New chat window.**

```
Read master_plan_FINAL.md Phase 3 items P3-17 through P3-19.

- P3-17: GAP-002 — Write 20+ safety classifier tests
- P3-18: GAP-001 — Write voice journal streaming lifecycle tests
- P3-19: GAP-004 + GAP-005 — Write wellbeing score pipeline + LLM integration tests

Use Swift Testing framework for new tests.
After all tests written: full build + ALL tests pass + swiftformat clean.
```

---

### PROMPT 3-FINAL: Phase 3 Verification Gate

**New chat window.**

```
Read master_plan_FINAL.md "Phase 3 Done When" checklist.

Verify ALL gates:
1. All 19 Phase 3 items implemented
2. Full build passes
3. All tests pass
4. Dynamic Type works (check PulsumDesignSystem.swift uses semantic fonts)
5. Data deletion resets to onboarding (test the Delete All Data flow)
6. Offline indicator shows in CoachView when disconnected
7. swiftformat . + scripts/ci/check-privacy-manifests.sh clean

DO NOT modify files. Only verify and report.
```

---

## Troubleshooting

### If a prompt runs out of context window
1. Note which item it was working on
2. Start a new chat window
3. In the new prompt, say: "Continue implementing P0-XX from master_plan_FINAL.md.
   The previous items P0-01 through P0-[previous] are already done and committed.
   Read the current state of [file] and continue from where it needs to be."

### If the build breaks after a prompt
1. `git diff` to see what changed
2. Start a new chat window
3. Paste the compiler errors and say: "Fix these build errors that resulted from
   implementing P0-XX. Read the file and the error messages. The intended change
   is described in master_plan_FINAL.md item P0-XX."

### If tests fail after a prompt
1. Run the failing test in isolation to get the full error
2. Start a new chat window
3. Paste the test failure and say: "Fix this test failure after implementing P0-XX.
   Read both the test file and the implementation file."

### If you need to revert completely
```bash
git stash   # or git checkout .
git log --oneline -10   # find the last good commit
git reset --hard <commit-hash>
```

---

## Summary: Execution Order

| # | Prompt | Items | Est. Time | Checkpoint |
|---|---|---|---|---|
| 0-A | Models + DTOs | P0-01, P0-01b | 30-45 min | PulsumData compiles |
| 0-B | DataStack + Facade | P0-02, P0-03 | 15-20 min | PulsumData compiles |
| 0-C | DataAgent migrate+decompose | P0-06, P0-18-22 | 60-90 min | DataAgent < 500 lines |
| 0-D | SentimentAgent | P0-07 | 10-15 min | Build succeeds |
| 0-E | CoachAgent | P0-08 | 15-20 min | Build succeeds |
| 0-F | LibraryImporter | P0-09 | 15-20 min | Build succeeds |
| 0-G | Delete CD artifacts | P0-04, P0-05 | 10 min | No CD references |
| 0-H | Orchestrator+VM+Tests | P0-10-12 | 30-45 min | Full build + tests |
| 0-I | Vector index | P0-13-15 | 20-30 min | Build + tests |
| 0-J | Actor isolation | P0-16-17 | 15-20 min | Build + tests |
| 0-K | Settings+Observation | P0-23-26 | 20-30 min | Build + tests |
| 0-FINAL | Verification | — | 10 min | All gates pass |
| — | **Manual smoke test** | — | 15 min | App works on device |
| 1-A | Safety fixes | P1-01-05 | 20-30 min | Build + tests |
| 1-B | ML pipeline | P1-06-09 | 20-30 min | Build + tests |
| 1-C | Compliance | P1-10-14 | 20-30 min | Build + tests |
| 2-A | Concurrency | P2-01-05 | 20-30 min | Build + tests |
| 2-B | Bug fixes | P2-06-12 | 20-30 min | Build + tests |
| 2-C | Remaining cleanup | P2-13-19 | 20-30 min | Build + tests |
| 3-A | Compliance+Observability | P3-01-04 | 20-30 min | Build + tests |
| 3-B | Network+Accessibility | P3-05-08 | 20-30 min | Build + tests |
| 3-C | Build & Ops | P3-09-16 | 30-45 min | Build + tests |
| 3-D | Test coverage | P3-17-19 | 30-45 min | All tests pass |
| 3-FINAL | Verification | — | 10 min | All gates pass |
