# Pulsum — Master Remediation Plan

**Status:** Ready to execute | **Progress:** 0 / 79 items | **Est. effort:** 5-7 weeks

---

## READ THIS FIRST

**Before starting any work, read this entire file.** Then read these reference files as needed.

### Critical Execution Warnings

**1. Phase 0 is make-or-break — and the ordering matters.** The SwiftData migration (P0-01 through P0-12) touches every package. If one entity conversion is wrong, it causes cascading build failures across 4 packages. **Critical sequencing:**
  - **Step A:** Do **P0-01 → P0-03** first (create SwiftData `@Model` classes + DTO snapshots, replace DataStack container, remove static facade). Verify build — the old CD types still exist so agents still compile against them.
  - **Step B:** Migrate agents **one at a time**: P0-06 (DataAgent), P0-07 (SentimentAgent), P0-08 (CoachAgent), P0-09 (LibraryImporter). Verify build after each.
  - **Step C:** Only **after all agents are migrated** and no longer reference Core Data types, do **P0-04 → P0-05** (delete CD artifacts). If you delete `ManagedObjects.swift` and `Pulsum.xcdatamodeld` before agents are migrated, the build will break immediately.
  - Do not try to update DataAgent, SentimentAgent, CoachAgent, and LibraryImporter all at once.
  *(Updated from feedback review: original ordering said "P0-01 through P0-05 first" but P0-05 deletes CD artifacts that agents still reference.)*

**2. Combine P0-06 with P0-18 through P0-22.** The plan lists DataAgent SwiftData update (P0-06) and DataAgent decomposition (P0-18–P0-22) as separate items, but in practice you'll be changing DataAgent twice — first migrating to SwiftData, then immediately tearing it apart. To avoid double-work, do them together: migrate DataAgent to SwiftData AND decompose it into the 5-6 focused types in one combined effort. The decomposed files should use SwiftData from the start, not Core Data.

**3. Manual smoke test between Phase 0 and Phase 1.** After completing Phase 0 and before starting Phase 1, manually run the app on a device or simulator and verify ALL of these work: app launches without crash, HealthKit data flows to the wellbeing score, voice journal records and transcribes, coach chat responds (on-device), settings save and persist, safety card appears for crisis content. A broken architecture migration that passes unit tests but fails in the real app would waste all subsequent phases.

### SwiftData Concurrency Rules (Applies to ALL Phase 0 items)

**Use `@ModelActor` for any actor that owns a `ModelContext`.** Apple's intended pattern for SwiftData + Swift Concurrency is the `@ModelActor` macro, NOT manually creating `ModelContext(container)` inside regular actors. `@ModelActor` gives you a properly isolated `ModelContext` that is safe across suspension points.

```swift
// CORRECT — use this pattern for DataAgent, CoachAgent, SentimentAgent:
@ModelActor
actor DataAgent {
    // The @ModelActor macro automatically provides:
    // - modelContainer: ModelContainer
    // - modelContext: ModelContext (isolated to this actor)

    // PUBLIC: returns Sendable snapshots (safe to cross actor boundaries)
    func fetchMetrics(for date: Date) throws -> [DailyMetricsSnapshot] {
        let descriptor = FetchDescriptor<DailyMetrics>(predicate: #Predicate { $0.date >= date })
        return try modelContext.fetch(descriptor).map { $0.snapshot }
    }
}

// WRONG — do NOT store ModelContext across awaits in a regular actor:
actor BadAgent {
    let context: ModelContext // ← dangerous if used across suspension points
}
```

**Search Apple docs for `@ModelActor` and `ModelActor` protocol before starting Phase 0.** This is a newer API that may differ from training data.

**Do NOT store a `ModelContext` as a long-lived property across `await` boundaries** unless it's owned by a `@ModelActor`. Create contexts for the scope you need, or use the `@ModelActor`-provided one.

### Additional Technical Guardrails

**4. NSLock conflicts with the "no @unchecked Sendable" rule.** Phase 2 proposes NSLock for some types. If adding a lock forces you to add `@unchecked Sendable`, prefer instead: (a) keep the type non-Sendable and confined inside its owning actor (no sharing = no locks needed), or (b) convert the type itself to an `actor`. Locks are a last resort.

**5. AgentOrchestrator must move off @MainActor for non-UI work.** The plan moves CoachAgent and SafetyAgent off @MainActor (P0-16, P0-17) but the orchestrator itself is still `@MainActor`. Its agent coordination, safety evaluation, and chat pipeline should NOT run on the main thread. Address this in P0-10.

**6. `@Environment(\.requestReview)` only works inside a SwiftUI View.** The app rating item (P3-13) cannot call `requestReview()` from AppViewModel. The ViewModel must expose a flag (`shouldRequestReview = true`), and a View must observe it and call `requestReview()`.

**7. BYOK API key is a known security risk — accepted for v1.0, fix in v1.1.** OpenAI's API key safety guidance explicitly states: "Never deploy your key in client-side environments like browsers or mobile apps." The current BYOK approach (user pastes their own key, stored in Keychain) is acceptable for testing and power users but is NOT suitable for broad distribution. The proper fix is a backend proxy (see `master_plan_1_1_FUTURE.md` Phase 4.5). For v1.0: (a) P3-07 rate limiting is critical to limit cost exposure from leaked keys, (b) add clear UX copy in Settings warning users about key security and cost responsibility, (c) do NOT ship to App Store with BYOK as the primary cloud path — either implement the backend first or launch with on-device-only coaching as the default experience. *(Added from feedback review: explicit risk callout per OpenAI API key safety best practices.)*

**8. Verify `SWIFT_DEFAULT_ACTOR_ISOLATION` does NOT apply to non-UI packages.** The project uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` on the app target. This is fine for the main app and PulsumUI (ViewModels and Views). But if this setting leaks into PulsumML, PulsumData, PulsumServices, PulsumAgents, or PulsumTypes, it pushes ML inference, data processing, and agent work onto the main thread — defeating the entire actor isolation strategy. **Before starting Phase 0:** verify that SPM packages do NOT have `defaultIsolation(.mainActor)` in their `Package.swift` `swiftSettings`. If they do, remove it from non-UI packages. Only PulsumUI (and the app target) should default to MainActor. *(Added from feedback review: default MainActor on non-UI packages silently pushes heavy work to the main thread.)*

| File | What It Contains | When to Read |
|---|---|---|
| `master_report.md` | 112 findings with full detail, evidence, suggested fixes | When implementing any P-item — look up the finding ID |
| `guidelines_report.md` | App Store compliance checks, submission checklist | When implementing GL-items or compliance work |
| `scan_prompt.md` | Reusable audit prompt (43 dimensions) | When re-auditing after changes |

---

## Project Context

| Property | Value |
|---|---|
| **Platform** | iOS 26+ only |
| **Language** | Swift 6.1 (`swift-tools-version: 6.1`) |
| **UI** | SwiftUI with `@Observable` (Observation framework) |
| **Concurrency** | Swift Concurrency (async/await, actors). `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` |
| **Persistence** | Core Data → **migrating to SwiftData** in Phase 0 |
| **Packages** | 6 SPM: PulsumTypes → PulsumML + PulsumData → PulsumServices → PulsumAgents → PulsumUI → App |
| **External deps** | Spline (spline-ios v0.2.48) — 3D animation only |
| **Backend** | OpenAI GPT-5 Responses API (consent-gated, BYOK API key) |
| **Frameworks** | HealthKit, Speech, Foundation Models, Core ML, Natural Language, Accelerate |
| **Users** | Zero. Fresh install every test. No data migration risk. |

---

## Rules for AI Agents

### DO

- **Read this entire file** at the start of every session to know current progress.
- Work on **ONE item at a time**. Finish it completely, then move to the next.
- **Mark items done** by changing `[ ]` to `[x]` and adding the date: `[x] *(2026-02-10)*`
- Look up the **finding ID** in `master_report.md` for full detail before implementing each item.
- **Use web search** when you need current Apple API details, especially for:
  - **SwiftData** — evolving rapidly; confirm `@Model`, `ModelContainer`, `#Index`, `VersionedSchema` APIs
  - **Foundation Models** — new framework; search Apple docs for `LanguageModelSession`, `@Generable`, `GenerationOptions`
  - **Liquid Glass** — new iOS 26 design system; search before assuming glass effect APIs
  - **SwiftUI** — always evolving; don't assume patterns from older versions
- Use **Xcode MCP tools** when available:
  - `BuildProject` — full Xcode build to verify compilation
  - `XcodeRefreshCodeIssuesInFile` — fast per-file diagnostics (types, imports, API misuse)
  - `DocumentationSearch` — search latest Apple developer docs locally
  - `ExecuteSnippet` — quick code experiments in project context
- Validate with build after each change: `xcodebuild -scheme Pulsum -sdk iphoneos -derivedDataPath ./DerivedData`
- Run `swiftformat .` after each change.
- Use `#available(iOS 26.0, *)` guards for Foundation Models APIs.
- Use Swift Concurrency (`async`/`await`, `actor`) instead of Combine.
- Prefer `actor` for thread-safe mutable state over `@unchecked Sendable` + locks.
- Use `@ModelActor` for any actor that owns a SwiftData `ModelContext`. Do NOT store `ModelContext` across `await` boundaries unless `@ModelActor`-owned.
- Reference the finding ID in commit messages (e.g., `fix: CRIT-002 — FM guardrail returns .caution`).
- Use 4-space indentation. PascalCase for types, camelCase for properties/methods.
- Use `String(localized:)` for all new user-facing strings.
- Use `Diagnostics.log()` from PulsumTypes for logging.
- Prefer Swift Testing framework for new unit tests, XCUIAutomation for UI tests.

### DO NOT

- Do NOT start Phase N+1 until Phase N is fully complete.
- Do NOT change multiple items in one commit — each item is atomic.
- Do NOT refactor adjacent code "while you're in there."
- Do NOT add SPM dependencies without approval.
- Do NOT use `@unchecked Sendable` on new code.
- Do NOT use `fatalError()`, `preconditionFailure()`, or force unwraps (`!`).
- Do NOT use `print()` — use `Diagnostics.log()`.
- Do NOT use Combine — use async/await.
- Do NOT commit secrets, API keys, or tokens.
- Do NOT assume you know SwiftData/FoundationModels/Liquid Glass APIs — search docs first.
- Do NOT modify the `.xcdatamodeld` — it will be replaced by SwiftData in Phase 0.
- Do NOT store `ModelContext` as a long-lived property in a regular actor — use `@ModelActor` instead.
- Do NOT add `NSLock` if it forces `@unchecked Sendable` — prefer actor confinement or convert to actor.

### Build & Verify

```bash
# Full build
xcodebuild -scheme Pulsum -sdk iphoneos -derivedDataPath ./DerivedData

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

## Architecture Decisions (Confirmed)

These decisions shape what each phase does. They eliminate 9 findings automatically.

| # | Decision | Choice | Eliminates | Reason (one line) |
|---|---|---|---|---|
| D1 | Persistence | **SwiftData** | CRIT-004, HIGH-007, MED-004, MED-005, MED-013, PROD-009 | Zero users = zero migration risk. CD unused strengths. SwiftData is production-ready iOS 26. |
| D2 | Vector Index | **In-memory + file** | CRIT-001, HIGH-009, MED-015 | 500 vectors = 770KB. Brute-force + Accelerate < 1ms. Replaces 437 lines of buggy binary I/O. |
| D3 | Agents | **Keep 5, fix isolation** | — | Agent naming is cosmetic. Fix DI and threading, not structure. |
| D4 | Concurrency | **Actor isolation** | ARCH-005 | Mechanical change. Prevents ML inference contending with UI. |
| D5 | Singletons | **Remove CD singletons only** | ARCH-006 partial | SwiftData migration naturally removes DataStack.shared + PulsumData facade. |
| D6 | State observation | **Keep @Observable + NotificationCenter, drop closures** | — | NotificationCenter is correct for cross-package events. Closures are the confusing part. |
| D7 | DataAgent | **Decompose into 5-6 types** | ARCH-001 | Do it right once. 3,706 lines → 6 files under 1,000 each. |
| D8 | SettingsVM | **Split into 3-4 VMs** | ARCH-007 partial | 573 lines, 7 concerns = God Object. Mechanical split. |
| D9 | Monetization | **BYOK optional** | — | On-device is primary. BYOK for testing/power users. **Security risk:** OpenAI policy says "never deploy keys in client-side apps." Move to backend proxy in v1.1 (Phase 4.5 in `master_plan_1_1_FUTURE.md`). StoreKit in v1.1. |
| D10 | Packages | **Keep 6 as-is** | — | With SwiftData, PulsumUI→PulsumData is correct (@Query). |

---

## Phase 0: Architecture Foundation

**Goal:** Restructure persistence, vector index, agents, ViewModels.  
**Effort:** ~2-3 weeks | **Branch:** `refactor/phase0-architecture`

### 0.1 — SwiftData Migration (eliminates 6 findings)

**Before starting: search Apple docs for `SwiftData`, `@Model`, `ModelContainer`, `ModelContext`, `#Index`, `@Attribute`, `VersionedSchema`, `FetchDescriptor`, `#Predicate`.**

- [ ] **P0-01** | Create `@Model` classes for all 9 entities  
  **Create:** New files in `Packages/PulsumData/Sources/PulsumData/Model/`  
  **Entities to convert** (source: `Pulsum.xcdatamodel/contents` XML and `ManagedObjects.swift`):

  | Entity | Key Attributes (use native Swift types, NOT NSNumber) | Indexes Needed |
  |---|---|---|
  | `JournalEntry` | `id: UUID`, `date: Date`, `transcript: String`, `sentiment: Double = 0`, `embeddedVectorURL: String?`, `sensitiveFlags: String?` | `#Index<JournalEntry>([\.date])` |
  | `DailyMetrics` | `date: Date` **(`@Attribute(.unique)`)**, `hrvMedian: Double?`, `nocturnalHRPercentile10: Double?`, `restingHR: Double?`, `totalSleepTime: Double?`, `sleepDebt: Double?`, `respiratoryRate: Double?`, `steps: Double?`, `flags: String?` | `#Index<DailyMetrics>([\.date])` |
  | `Baseline` | `metric: String`, `windowDays: Int16 = 21`, `median: Double?`, `mad: Double?`, `ewma: Double?`, `updatedAt: Date?` | `#Unique<Baseline>([\.metric, \.windowDays])` |
  | `FeatureVector` | `date: Date` **(`@Attribute(.unique)`)**, `zHrv: Double?`, `zNocturnalHR: Double?`, `zRestingHR: Double?`, `zSleepDebt: Double?`, `zRespiratoryRate: Double?`, `zSteps: Double?`, `subjectiveStress: Double?`, `subjectiveEnergy: Double?`, `subjectiveSleepQuality: Double?`, `sentiment: Double?`, `imputedFlags: String?` | `#Index<FeatureVector>([\.date])` |
  | `MicroMoment` | `id: String` (`@Attribute(.unique)`), `title: String`, `shortDescription: String`, `detail: String?`, `tags: String?` **(JSON string — see tags decision below)**, `estimatedTimeSec: Int32?`, `difficulty: String?`, `category: String?`, `sourceURL: String?`, `evidenceBadge: String?`, `cooldownSec: Int32?` | `#Index<MicroMoment>([\.id])` |
  | `RecommendationEvent` | `momentId: String`, `date: Date`, `accepted: Bool`, `completedAt: Date?` | `#Index<RecommendationEvent>([\.momentId])` |
  | `LibraryIngest` | `id: UUID`, `source: String` **(`@Attribute(.unique)`)**, `checksum: String?`, `ingestedAt: Date`, `version: String?` | `#Index<LibraryIngest>([\.source])` |
  | `UserPrefs` | `id: String` **(`@Attribute(.unique)`)**, `consentCloud: Bool = false`, `updatedAt: Date` | None |
  | `ConsentState` | `id: UUID`, `version: String` **(`@Attribute(.unique)`)**, `grantedAt: Date?`, `revokedAt: Date?` | None |

  **Pattern for each model:**
  ```swift
  import SwiftData
  
  @Model
  final class JournalEntry {
      var id: UUID
      var date: Date
      var transcript: String
      var sentiment: Double = 0
      var embeddedVectorURL: String?
      var sensitiveFlags: String?
      
      init(id: UUID = UUID(), date: Date, transcript: String, sentiment: Double = 0) {
          self.id = id
          self.date = date
          self.transcript = transcript
          self.sentiment = sentiment
      }
  }
  ```
  **SwiftData-specific notes:**
  - **Uniqueness constraints are critical for idempotent ingestion.** Without them, HealthKit backfill retries and library reimports will create duplicate rows. `DailyMetrics.date`, `FeatureVector.date`, `LibraryIngest.source`, `UserPrefs.id`, and `ConsentState.version` must be unique. `Baseline` needs compound uniqueness on `(metric, windowDays)` — use `#Unique<Baseline>([\.metric, \.windowDays])`. **Search Apple docs for SwiftData `#Unique` macro (introduced WWDC24) before implementing.** *(Added from feedback review: uniqueness prevents data corruption under retries/crashes.)*
  - **Tags decision (DECIDED: JSON string).** `MicroMoment.tags` is stored as `String?` containing a JSON array (e.g., `"[\"sleep\",\"stress\"]"`). SwiftData stores `[String]` as an encoded blob that cannot be queried with `#Predicate`. Since tags are display-only in v1.0 (no tag-based filtering), JSON string is simpler and predictable. If tag filtering is needed in v1.1, model a proper `Tag` entity with a relationship. *(Updated from feedback review: explicit decision required — can't query inside [String] arrays in SwiftData.)*
  - `#Index` can only be used once per model class — list all indexed key paths in a single macro invocation.
  **Verify:** All 9 model files compile. **Uniqueness verified by upsert behavior** (SwiftData `#Unique` / `@Attribute(.unique)` uses upsert-on-collision, NOT throw — inserting a duplicate updates the existing row): insert two `DailyMetrics` with the same date, save, confirm exactly **1 row** exists for that date with the latest values. Repeat for `FeatureVector.date`, `Baseline(metric, windowDays)`, `LibraryIngest.source`, `UserPrefs.id`, `ConsentState.version`. *(Updated from feedback review: SwiftData uniqueness is upsert-based per WWDC24, not throw-based.)* Compare every attribute against the old `ManagedObjects.swift` — nothing missed.

- [ ] **P0-01b** (NEW) | Create Sendable DTO snapshot types for cross-actor APIs
  **Create:** `Packages/PulsumTypes/Sources/PulsumTypes/ModelSnapshots.swift`
  **Why this is required:** `@Model` classes are NOT Sendable — they cannot cross actor boundaries in Swift 6 strict concurrency. When a `@ModelActor` agent (e.g., DataAgent) returns data to the orchestrator or a `@MainActor` ViewModel, it must return Sendable types, not model objects. Without this, every cross-actor call will fail to compile or force `@unchecked Sendable` (which the plan bans).
  **What to create:** Sendable snapshot structs that mirror the model properties needed by callers:
  ```swift
  // In PulsumTypes (no SwiftData import needed)
  public struct DailyMetricsSnapshot: Sendable, Codable {
      public let date: Date
      public let hrvMedian: Double?
      public let nocturnalHRPercentile10: Double?
      public let restingHR: Double?
      public let totalSleepTime: Double?
      public let sleepDebt: Double?
      public let respiratoryRate: Double?
      public let steps: Double?
  }

  public struct WellbeingScoreSnapshot: Sendable, Codable {
      public let date: Date
      public let score: Double
      public let label: String
      public let contributing: [String: Double]
  }

  public struct JournalEntrySnapshot: Sendable, Codable {
      public let id: UUID
      public let date: Date
      public let transcript: String
      public let sentiment: Double
  }
  ```
  **Pattern for agent APIs:** Agents fetch `@Model` objects internally, then map to snapshots before returning:
  ```swift
  @ModelActor actor DataAgent {
      func fetchMetrics(since date: Date) throws -> [DailyMetricsSnapshot] {
          let descriptor = FetchDescriptor<DailyMetrics>(...)
          return try modelContext.fetch(descriptor).map { $0.snapshot }
      }
  }
  // Extension on @Model class (inside PulsumData, not PulsumTypes):
  extension DailyMetrics {
      var snapshot: DailyMetricsSnapshot { ... }
  }
  ```
  **Where snapshots live:** `PulsumTypes` (shared package) — so both agents and ViewModels can use them without importing SwiftData. The `.snapshot` mapping extensions live in `PulsumData` (which imports both SwiftData and PulsumTypes).
  **When to use `PersistentIdentifier` instead:** For write operations where the caller needs to reference a specific object (e.g., "mark this recommendation as completed"), pass `PersistentIdentifier` (which is Sendable/Codable) and let the receiving agent refetch by ID.
  *(Added from feedback review: @Model objects are not Sendable — this is a Swift 6 compiler blocker without DTO boundaries.)*
  **Verify:** All agent public APIs return Sendable types (snapshots or PersistentIdentifier). `grep -r "-> \[DailyMetrics\]" Packages/` returns zero (only snapshot arrays cross actor boundaries).

- [ ] **P0-02** | Replace DataStack with SwiftData `ModelContainer`  
  **File:** `Packages/PulsumData/Sources/PulsumData/DataStack.swift`  
  **What to change:**
  - Replace `NSPersistentContainer` with `ModelContainer`
  - The init MUST be `throws` (not `fatalError`) — this fixes CRIT-004
  - Apply `NSFileProtectionCompleteUnlessOpen` to the store URL's parent directory. **Do NOT use `NSFileProtectionComplete`** — it makes the store inaccessible when the device is locked, which breaks HealthKit background delivery (the app can be woken while locked to ingest new samples). `CompleteUnlessOpen` allows writes to finish on open file handles while still protecting data at rest. *(Updated from feedback review: Complete breaks background HealthKit delivery.)*
  - Enable backup exclusion on data directories
  - Keep the `StoragePaths` struct for directory management
  ```swift
  public final class DataStack: Sendable {
      public let container: ModelContainer
      
      public init() throws {
          let schema = Schema([JournalEntry.self, DailyMetrics.self, /* ...all 9... */])
          let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
          self.container = try ModelContainer(for: schema, configurations: [config])
          // Apply file protection to store directory
      }
  }
  ```
  **Verify:** App launches. SQLite file created at expected path. No `fatalError` calls in file. **Locked-device test (do once after Phase 0 complete):** Lock device, wait 30 seconds, trigger HealthKit background delivery (e.g., complete a workout on Apple Watch). Verify the app successfully writes to the SwiftData store in the background without errors. If it fails, evaluate switching to `NSFileProtectionCompleteUntilFirstUserAuthentication` instead. *(Added from feedback review: test file protection against real HealthKit background behavior on locked devices.)*

- [ ] **P0-03** | Replace PulsumData static facade with injectable access
  **File:** `Packages/PulsumData/Sources/PulsumData/PulsumData.swift`
  **What to change:** Remove ALL `static` accessors (`PulsumData.container`, `.viewContext`, etc.). The `ModelContainer` is created in the **App layer** (AppViewModel or PulsumApp) via `DataStack`, and injected into both: (1) the SwiftUI view hierarchy via `.modelContainer(container)` so `@Query` works, and (2) the `AgentOrchestrator` and agents via their init parameters. *(Updated from feedback review: SwiftUI's @Query requires the container at the app root via .modelContainer(), not buried inside the orchestrator.)*
  **Verify:** `grep -r "PulsumData\\.container" Packages/` returns zero results.

- [ ] **P0-04** | Delete PulsumManagedObjectModel.swift  
  **File:** `Packages/PulsumData/Sources/PulsumData/PulsumManagedObjectModel.swift`  
  SwiftData defines models in code — no bundle-based model loading needed. Delete entirely.

- [ ] **P0-05** | Remove Core Data artifacts  
  **Delete:** `ManagedObjects.swift`, `Pulsum.xcdatamodeld/` (entire directory), `PulsumCompiled.momd/` (entire directory), `Bundle+PulsumDataResources.swift` (if only used for Core Data model loading).  
  **Update:** `Packages/PulsumData/Package.swift` — remove `.process("PulsumData/Resources/Pulsum.xcdatamodeld")` and `.process("PulsumData/Resources/PulsumCompiled.momd")` from resources array.  
  **Verify:** Build succeeds. No references to deleted files.

- [ ] **P0-06** | Update DataAgent for SwiftData using `@ModelActor`  
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`  
  **Key changes:**
  - Change declaration to `@ModelActor actor DataAgent` — this automatically provides `modelContainer` and `modelContext` properties that are properly isolated
  - Do NOT manually create `ModelContext(container)` or store a context as a property — `@ModelActor` handles this
  - Replace `NSFetchRequest` with `FetchDescriptor` + `#Predicate`
  - Replace `context.save()` with `try modelContext.save()`
  - Remove `performAndWait {}` blocks entirely — `@ModelActor` context is actor-isolated
  **Example pattern:**
  ```swift
  @ModelActor
  actor DataAgent {
      // modelContext is automatically provided by @ModelActor

      // PUBLIC API: returns Sendable snapshots (cross-actor safe)
      func fetchMetrics(since startDate: Date) throws -> [DailyMetricsSnapshot] {
          let descriptor = FetchDescriptor<DailyMetrics>(
              predicate: #Predicate { $0.date >= startDate }
          )
          return try modelContext.fetch(descriptor).map { $0.snapshot }
      }

      // INTERNAL: @Model objects stay inside this actor
      private func fetchRawMetrics(since startDate: Date) throws -> [DailyMetrics] {
          let descriptor = FetchDescriptor<DailyMetrics>(
              predicate: #Predicate { $0.date >= startDate }
          )
          return try modelContext.fetch(descriptor)
      }
  }
  ```
  *(Updated from feedback review: public APIs must return Sendable snapshots, not @Model objects. See P0-01b.)*
  **Search Apple docs for `@ModelActor` before starting. This is the recommended SwiftData concurrency pattern.**  
  **Verify:** Build succeeds. DataAgent tests pass after test helper update.

- [ ] **P0-07** | Update SentimentAgent for SwiftData  
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift`  
  **Same pattern as P0-06:** Replace `NSManagedObjectContext` → `ModelContext`, `NSFetchRequest` → `FetchDescriptor`, accept `ModelContainer` in init.  
  **Verify:** Build succeeds.

- [ ] **P0-08** | Update CoachAgent for SwiftData (eliminates HIGH-007)
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift`
  **Key change:** Delete the `contextPerformAndWait` helper entirely (lines ~698-709). Move all persistence work into the `@ModelActor`-provided `modelContext`. **Important: `ModelContext` is NOT Sendable** — do not pass it between actors or share it across isolation domains. Use `PersistentIdentifier` (which is Sendable/Codable) to pass object references between actors, and refetch on the receiving side. This eliminates HIGH-007 (main thread blocking). *(Updated from feedback review: clarified ModelContext isolation rules — it must stay confined to its owning @ModelActor, not used "from any actor.")*
  **Verify:** Build succeeds. CoachAgent tests pass.

- [ ] **P0-09** | Update LibraryImporter for SwiftData using `@ModelActor`
  **File:** `Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift`
  **Key changes:** Make LibraryImporter a **`@ModelActor actor`** — this is required because the importer does concurrent work (P2-17 documents a TaskGroup for embedding) AND persistence. Using `@ModelActor` ensures the `modelContext` is properly isolated and safe across suspension points. Do NOT manually create `ModelContext(container)` as a stored property.
  ```swift
  @ModelActor
  actor LibraryImporter {
      // modelContext is automatically provided and actor-isolated

      func importLibrary(_ data: LibraryData) async throws {
          // Phase 1: Insert MicroMoments via modelContext (actor-isolated)
          // Phase 2: Compute embeddings (can use TaskGroup for parallelism,
          //          but vector results must be Sendable — [Float] is fine)
          // Phase 3: Save all in one modelContext.save() call
      }
  }
  ```
  **Important:** The embedding TaskGroup produces `[Float]` vectors (Sendable), not model objects. Only the final persistence step (inserting/updating MicroMoments and LibraryIngest records) touches `modelContext`, and that stays on the actor. Replace `NSFetchRequest` patterns with `FetchDescriptor`.
  *(Updated from feedback review: LibraryImporter must be @ModelActor — not manual ModelContext — because it mixes concurrency (TaskGroup) with persistence, exactly where context/thread issues cause heisenbugs.)*
  **Verify:** Build succeeds. Library import creates MicroMoment records. No `ModelContext(container)` stored as a property.

- [ ] **P0-10** | Update AgentOrchestrator to receive container + move off @MainActor
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`
  **What to change:**
  - **Receive** `ModelContainer` from the App layer (created by AppViewModel/PulsumApp via `DataStack`). Do NOT create the container here — AppViewModel creates it so it can also inject it into SwiftUI via `.modelContainer()`. Pass the received container to DataAgent, SentimentAgent, CoachAgent, and LibraryImporter via their inits. *(Updated from feedback review: container must be created at App layer for @Query to work in views.)*
  - **Change AgentOrchestrator from `@MainActor` to `actor`.** The orchestrator coordinates agents, runs safety evaluation, and manages the chat pipeline — none of this is UI work. Only the ViewModels (AppViewModel, PulseViewModel, etc.) should be `@MainActor`. UI-facing properties that ViewModels read can be marked `@MainActor` individually if needed.
  - Update `#if DEBUG` test inits to accept `ModelContainer`.
  **Verify:** Build succeeds. Orchestrator creates and starts. Fix all call-site compiler errors (callers need `await`).

- [ ] **P0-11** | Update AppViewModel as ModelContainer composition root
  **File:** `Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift`
  **What to change:** AppViewModel is now the **composition root** for the `ModelContainer`:
  - Create `DataStack` (which creates `ModelContainer`) during startup. Handle init failure (it now throws) — use the existing `.blocked` startup state to show an error if the container can't be created.
  - Expose the `ModelContainer` as a property so `PulsumApp`/`PulsumRootView` can inject it into SwiftUI via `.modelContainer(viewModel.container)` — this is required for `@Query` to work in views.
  - Pass the same container to `AgentOrchestrator.init(container:)` so agents share the same store.
  *(Updated from feedback review: container creation moved here from orchestrator so both SwiftUI and agents can share it.)*
  **Verify:** App launches end-to-end. `@Query` works in views. Kill and relaunch — data persists.

- [ ] **P0-12** | Update test helpers for SwiftData  
  **Files:** `PulsumAgentsTests/TestCoreDataStack.swift`, `PulsumUITests/TestCoreDataStack.swift`  
  **What to change:** Replace in-memory `NSPersistentContainer` with:
  ```swift
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try ModelContainer(for: Schema([/* all models */]), configurations: [config])
  ```
  **Verify:** All package tests pass.

### 0.2 — Vector Index Replacement (eliminates 3 findings)

- [ ] **P0-13** | Build in-memory `VectorStore` actor  
  **Create:** `Packages/PulsumData/Sources/PulsumData/VectorStore.swift`  
  **What to build:** An `actor` holding vectors in memory with file-backed persistence.  
  ```swift
  import Foundation
  import Accelerate
  
  public actor VectorStore {
      private var entries: [String: [Float]] = [:]
      private let fileURL: URL
      private let dimension: Int
      private var isDirty = false
      
      public init(name: String, dimension: Int = 384, directory: URL) throws {
          self.dimension = dimension
          self.fileURL = directory.appendingPathComponent("\(name).vectorstore")
          try loadFromDisk()
      }
      
      public func upsert(id: String, vector: [Float]) throws {
          guard vector.count == dimension else { throw VectorStoreError.dimensionMismatch }
          entries[id] = vector
          isDirty = true
          // Does NOT persist immediately — call persist() explicitly or use bulkUpsert
      }
      
      /// Use during library import to avoid rewriting the file 500 times
      public func bulkUpsert(_ batch: [(id: String, vector: [Float])]) throws {
          for item in batch {
              guard item.vector.count == dimension else { throw VectorStoreError.dimensionMismatch }
              entries[item.id] = item.vector
          }
          isDirty = true
          try persist()  // Single write after all inserts
      }
      
      public func remove(id: String) throws {
          entries.removeValue(forKey: id)
          try persist()
      }
      
      public func search(query: [Float], topK: Int) -> [VectorMatch] {
          // Brute-force L2 using vDSP_distancesq from Accelerate
          // For 500 vectors this takes <1ms
      }
      
      /// Call after individual upserts are done, or periodically
      public func persist() throws {
          guard isDirty else { return }
          // Use BINARY format (not JSON) — 500 × 384 floats = ~770KB binary vs ~3MB JSON
          var data = Data()
          // Write entry count, then for each: id length + id bytes + float data
          // Use Data.write(to:options:.atomic) for crash safety
          try data.write(to: fileURL, options: [.atomic])
          isDirty = false
      }
  }
  ```
  **Key design choices:**
  - **Binary format, NOT JSON.** JSON-encoding 500×384 floats produces ~3MB; binary is ~770KB. Use a simple format: entry count (UInt32), then for each entry: id-length (UInt16) + id (UTF-8 bytes) + vector (384 × Float raw bytes).
  - **`bulkUpsert(_:)` for library import.** Inserts all vectors then persists once. Without this, importing 500 micro-moments rewrites the file 500 times.
  - **`persist()` is explicit, not per-upsert.** Call after a batch of changes, or periodically. The `isDirty` flag avoids redundant writes.
  - Use `vDSP_distancesq` from Accelerate for hardware-accelerated squared L2 distance (skip `sqrt` — it's monotonic for ranking).
  - Apply `NSFileProtectionCompleteUnlessOpen` to the file (same rationale as P0-02 — `Complete` breaks background HealthKit delivery when device is locked).
  - Actor isolation replaces all manual locking.  
  **Verify:** bulkUpsert 500 vectors in one call, verify single file write. Search returns correct top-K. File persists across actor restarts.

- [ ] **P0-14** | Update VectorIndexManager to use VectorStore  
  **File:** `Packages/PulsumData/Sources/PulsumData/VectorIndexManager.swift`  
  **What to change:** Replace internal `VectorIndex` with `VectorStore`. The `VectorIndexProviding` protocol stays the same — consumers don't change. Remove sharding logic.  
  **Verify:** Build succeeds. VectorIndexManager tests pass.

- [ ] **P0-15** | Delete old VectorIndex.swift  
  **Delete:** `Packages/PulsumData/Sources/PulsumData/VectorIndex.swift` (437 lines)  
  **Verify:** `grep -r "VectorIndexShard\|VectorRecordHeader\|VectorIndexHeader" Packages/` returns zero.

### 0.3 — Actor Isolation (eliminates ARCH-005)

- [ ] **P0-16** | Change CoachAgent from `@MainActor class` to `actor`  
  Files: `CoachAgent.swift`, `CoachAgent+Coverage.swift`. Fix call sites in `AgentOrchestrator.swift`.

- [ ] **P0-17** | Change SafetyAgent to a protocol-backed struct or service  
  **File:** `SafetyAgent.swift`  
  **What to change:** SafetyAgent is stateless after init (91 lines, no mutable state). Do NOT make it a "Sendable class" — that tempts `@unchecked Sendable` later. Instead: (a) define a `SafetyClassifying` protocol with `func classify(text:) async -> SafetyClassification`, (b) make SafetyAgent a `struct` conforming to `SafetyClassifying` + `Sendable`, (c) inject the classifiers (`FoundationModelsSafetyProvider`, `SafetyLocal`) via init with defaults for production.  
  **Why struct:** It has no mutable state, no lifecycle, no autonomy. A struct is the simplest correct type. Structs are automatically Sendable if all stored properties are Sendable.

### 0.4 — DataAgent Decomposition (eliminates ARCH-001)

**Current DataAgent (3,706 lines) handles 10+ responsibilities. Extract into focused types. DataAgent keeps its public API — callers don't change.**

- [ ] **P0-18** | Extract `HealthKitIngestionCoordinator`
  **Create:** `Packages/PulsumAgents/Sources/PulsumAgents/HealthKitIngestionCoordinator.swift`
  **Move from DataAgent:** HealthKit authorization requests, `requestAuthorization()`, `currentHealthAccessStatus()`, observer query setup/teardown (`observeSampleType`, `stopObserving`), background delivery registration, sample delivery callbacks, `HealthKitObservationToken` management, the `activeObserverQueries` and `activeAnchoredQueries` dictionaries.
  **DataAgent keeps:** A reference to the coordinator, delegates all HealthKit operations.
  **Critical: HealthKit background delivery completion handler.** When using `enableBackgroundDelivery(for:frequency:withCompletion:)` and observer queries, you MUST call the observer query's `completionHandler` when done processing samples. If you don't, the system throttles future deliveries. Ensure the extracted coordinator calls the completion handler in all code paths (success, error, empty data). Also verify the `com.apple.developer.healthkit.background-delivery` entitlement is present (it is — confirmed in `guidelines_report.md`). *(Added from feedback review: missing completion handler calls cause silent throttling of background deliveries.)*
  **Verify:** Gate3_HealthAccessStatusTests, Gate3_IngestionIdempotenceTests pass.

- [ ] **P0-19** | Extract `SampleProcessors`  
  **Create:** `Packages/PulsumAgents/Sources/PulsumAgents/SampleProcessing/` directory  
  **What to create:**
  - `SampleProcessing.swift` — define `protocol SampleProcessor { func process(samples:date:context:) }` 
  - `HRVProcessor.swift` — HRV sample extraction and SDNN computation
  - `HeartRateProcessor.swift` — heart rate processing including nocturnal HR percentile extraction
  - `SleepProcessor.swift` — sleep analysis processing including sleep debt calculation
  - `StepProcessor.swift` — daily step count aggregation
  - `RespiratoryRateProcessor.swift` — respiratory rate extraction  
  **Move from DataAgent:** All the per-sample-type processing logic scattered through the file. Each processor takes raw HKSamples and writes DailyMetrics fields.  
  **Benefit:** Adding a new HealthKit type (e.g., blood oxygen) = add one new file, not modify a 3,700-line actor.  
  **Verify:** Gate6_WellbeingBackfillPhasingTests pass.

- [ ] **P0-20** | Extract `BaselineCalculator`  
  **Create:** `Packages/PulsumAgents/Sources/PulsumAgents/BaselineCalculator.swift`  
  **Move from DataAgent:** Baseline entity CRUD (fetch/update/create Baseline records), z-score computation (calls `BaselineMath.robustStats` and `BaselineMath.zScore`), feature vector materialization (creating FeatureVector records from DailyMetrics + Baselines). This type takes raw metrics and produces normalized feature vectors.  
  **Verify:** Gate6_StateEstimatorWeightsAndLabelsTests pass.

- [ ] **P0-21** | Extract `BackfillCoordinator`  
  **Create:** `Packages/PulsumAgents/Sources/PulsumAgents/BackfillCoordinator.swift`  
  **Move from DataAgent:** The two-phase bootstrap lifecycle (warm start = 7 days, full backfill = 30 days), `DataAgentBootstrapPolicy`, retry/timeout/watchdog logic, `BackfillProgress` tracking, `bootstrapWatchdogTask`, the `DiagnosticsStallMonitor` usage.  
  **Verify:** Gate6_WellbeingBackfillPhasingTests, Gate7_FirstRunWatchdogTests pass.

- [ ] **P0-22** | Verify DataAgent is thin coordinator  
  **Target:** DataAgent.swift < 500 lines. It should now only contain: the public API surface, delegation to the 4 extracted types, `StateEstimator` coordination for wellbeing scoring, notification posting (`.pulsumScoresUpdated`), and the actor's stored properties.  
  **Verify:** `wc -l DataAgent.swift` < 500. ALL agent tests pass. Full build succeeds.

### 0.5 — SettingsViewModel Split (addresses ARCH-007)

- [ ] **P0-23** | Extract `HealthSettingsViewModel` (health access, authorization, toast)  
  Create: `Packages/PulsumUI/Sources/PulsumUI/HealthSettingsViewModel.swift`

- [ ] **P0-24** | Extract `DiagnosticsViewModel` (config, logs, export, FM status)  
  Create: `Packages/PulsumUI/Sources/PulsumUI/DiagnosticsViewModel.swift`

- [ ] **P0-25** | Update SettingsView to compose the split ViewModels

### 0.6 — State Observation Cleanup

- [ ] **P0-26** | Replace closure callbacks (`onConsentChanged`, `onSafetyDecision`) with observable properties  
  File: `AppViewModel.swift`. Ref: ARCH-008

### Phase 0 Done When:

- [ ] All 27 items checked (26 original + P0-01b)
- [ ] Full build passes
- [ ] All package tests pass
- [ ] `swiftformat .` clean
- [ ] `scripts/ci/check-privacy-manifests.sh` passes
- [ ] DataAgent.swift < 500 lines
- [ ] No `NSManagedObjectContext`, `NSPersistentContainer`, `performAndWait` in source
- [ ] No `VectorIndexShard`, `VectorRecordHeader` in source
- [ ] All agent public APIs return Sendable types (snapshots/DTOs), not `@Model` objects
- [ ] `SWIFT_DEFAULT_ACTOR_ISOLATION` is NOT set to MainActor in non-UI SPM packages
- [ ] Uniqueness constraints verified: inserting duplicate DailyMetrics for same date results in exactly 1 row (upsert, not throw)
- [ ] Locked-device HealthKit background delivery test passes (see P0-02 verify)

---

## Phase 1: Safety & Critical Bugs

**Goal:** Fix safety issues, critical bugs, App Store compliance blockers.  
**Effort:** ~2-3 days | **Branch:** `fix/phase1-safety` | **Requires:** Phase 0 complete

### 1.1 — Safety Fixes

- [ ] **P1-01** | CRIT-002 | FM guardrail violations → `.caution` not `.safe`  
  **File:** `Packages/PulsumML/Sources/PulsumML/Safety/FoundationModelsSafetyProvider.swift`  
  **Change:** In the `catch` block for `LanguageModelSession.GenerationError` (~lines 59-64), change both `.guardrailViolation` and `.refusal` cases from `return .safe` to `return .caution(reason: "Content flagged by on-device safety system")`.

- [ ] **P1-02** | CRIT-003 | Unify intentTopic enum  
  **Files:** `Packages/PulsumServices/Sources/PulsumServices/CoachPhrasingSchema.swift` (~line 30), `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift` (~line 862)  
  **Change:** Both must list: `["sleep","stress","energy","hrv","mood","movement","mindfulness","nutrition","goals","none"]`

- [ ] **P1-03** | CRIT-005 | Expand crisis keywords  
  **Files:** `Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift`, `Packages/PulsumAgents/Sources/PulsumAgents/SafetyAgent.swift`  
  **Add to BOTH lists:** `"want to die"`, `"self-harm"`, `"cut myself"`, `"cutting myself"`, `"overdose"`, `"no reason to live"`, `"jump off"`, `"hang myself"`, `"hurt myself"`, `"don't want to be here"`, `"can't go on"`, `"take all the pills"`, `"ending my life"`, `"not worth living"`, `"better off dead"`, `"wish I were dead"`, `"no way out"`  
  **False positive caution:** Some phrases are ambiguous ("jump off" could mean "jump off the couch"). Use case-insensitive matching and consider phrase boundaries. Test with realistic non-crisis sentences containing these words to ensure acceptable false-positive rate. Consider splitting into "high-risk phrases" (always crisis) and "medium-risk phrases" (require additional signal).

- [ ] **P1-04** | HIGH-010 | High-confidence crisis without keyword  
  **File:** `Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift` (~lines 100-113)  
  **Change:** When embedding similarity to crisis prototype > 0.85, return `.crisis` regardless of keyword presence. Only require keyword-AND-embedding for similarity 0.65–0.85.

- [ ] **P1-05** | MED-014 | Expand PII redaction  
  **File:** `Packages/PulsumML/Sources/PulsumML/Sentiment/PIIRedactor.swift`  
  **Add patterns:** SSN: `\d{3}-\d{2}-\d{4}`, credit card: `\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b` (add Luhn checksum validation to reduce false positives — otherwise any 16-digit number gets redacted), IP: `\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b`. Replace with `[REDACTED]`.

### 1.2 — ML Pipeline Fixes

- [ ] **P1-06** | HIGH-001 | Fix RecRanker Bradley-Terry gradient  
  **File:** `Packages/PulsumML/Sources/PulsumML/RecRanker.swift` (~lines 128-136)  
  **Change:** Replace independent gradients with correct pairwise formula:
  ```swift
  let gradient = logistic(dotOther - dotPreferred)
  for key in Set(preferred.vector.keys).union(other.vector.keys) {
      let xPref = preferred.vector[key] ?? 0
      let xOther = other.vector[key] ?? 0
      weights[key, default: 0] += learningRate * gradient * (xPref - xOther)
  }
  ```

- [ ] **P1-07** | HIGH-002 + MED-003 | Add NL sentiment fallback  
  **File:** `Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentService.swift`  
  **Change:** Add `NaturalLanguageSentimentProvider()` as the last provider in the default array. Before `return 0.0`, add `Diagnostics.log(level: .warn, category: .sentiment, name: "sentiment.allProvidersFailed")`.

- [ ] **P1-08** | HIGH-003 | Topic gate permissive when degraded  
  **File:** `Packages/PulsumML/Sources/PulsumML/TopicGate/EmbeddingTopicGateProvider.swift` (~lines 100-116)  
  **Change:** On embedding failure, return `GateDecision(isOnTopic: true, reason: "Embedding unavailable — permissive fallback", confidence: 0.0, topic: nil)` instead of `isOnTopic: false`.

- [ ] **P1-09** | MED-002 | Remove AFM gate on NLEmbedding  
  **File:** `Packages/PulsumML/Sources/PulsumML/Embedding/AFMTextEmbeddingProvider.swift` (~line 20)  
  **Change:** Remove the `availability() == .ready` check. `NLEmbedding` works on iOS 17+ regardless of Apple Intelligence status.

### 1.3 — App Store Compliance (from `guidelines_report.md`)

- [ ] **P1-10** | HIGH-005 | Fix stuck `isAnalyzing`  
  **File:** `Packages/PulsumUI/Sources/PulsumUI/PulseViewModel.swift`  
  **Change:** (1) Add `isAnalyzing = false` to `stopRecording()` (~line 127). (2) In `startRecording()`, wrap the recording task body in `defer { await MainActor.run { isAnalyzing = false } }` to ensure cleanup on all exit paths (cancel, error, success).

- [ ] **P1-11** | GL-1.4.1 FAIL | Add medical disclaimer  
  **Files:** `Packages/PulsumUI/Sources/PulsumUI/OnboardingView.swift`, `SettingsView.swift`, `CoachView.swift`  
  **Add this text:** "Pulsum is for general wellness and informational purposes only. It does not provide medical advice, diagnosis, or treatment. Always consult your healthcare provider before making health decisions."  
  **Where:** (1) OnboardingView — below welcome text, before "Get Started" button. (2) SettingsView — in Privacy section below privacy policy link. (3) CoachView — persistent footer near chat input: "AI-generated wellness suggestions. Not medical advice."  
  **Ref:** `guidelines_report.md` Blocker #1, #2 — this is the **#1 App Store rejection risk**.

- [ ] **P1-12** | GL-1.4.1 AT RISK | Add 988 Lifeline to SafetyCardView  
  **Files:** `Packages/PulsumUI/Sources/PulsumUI/SafetyCardView.swift`, `Packages/PulsumAgents/Sources/PulsumAgents/SafetyAgent.swift`  
  **Change SafetyCardView:** Add a `Link("988 Suicide & Crisis Lifeline", destination: URL(string: "tel:988")!)` button below the 911 button. Add text: "This app is not a substitute for professional mental health care."  
  **Change SafetyAgent (~line 86):** Update crisis message to: "If you need immediate help: call 911 or contact the 988 Suicide & Crisis Lifeline (call/text 988). Outside the US, contact your local emergency services."

- [ ] **P1-13** | GL-1.4.1 AT RISK | Label AI-generated content  
  **File:** `Packages/PulsumUI/Sources/PulsumUI/CoachView.swift`  
  **Change:** In `ChatBubble` (~lines 319-356), add a small `Text("AI").font(.caption2).padding(4).background(.secondary.opacity(0.2)).clipShape(Capsule())` badge to assistant messages. Add a persistent one-line disclaimer above the chat TextField: `Text("Responses are AI-generated and not medical advice").font(.caption).foregroundStyle(.secondary)`

- [ ] **P1-14** | GL-1.4.1 AT RISK | Score methodology disclosure  
  **File:** `Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownView.swift`  
  **Add footer:** `Text("Your wellbeing score is an estimated trend indicator based on statistical patterns in your recent health data. It is not a clinical measurement.").font(.caption).foregroundStyle(.secondary).padding(.top, 8)`

### Phase 1 Done When:

- [ ] All 14 items checked
- [ ] Full build passes, all tests pass, `swiftformat .` clean

---

## Phase 2: Concurrency & Cleanup

**Goal:** Fix thread safety, remaining bugs, code cleanup.  
**Effort:** ~3-5 days | **Branch:** `fix/phase2-cleanup` | **Requires:** Phase 1 complete

- [ ] **P2-01** | HIGH-004 | Add serial DispatchQueue to LegacySpeechBackend  
  **File:** `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift`  
  **Problem:** `LegacySpeechBackend` is `@unchecked Sendable` but mutates `audioEngine`, `recognitionTask`, `recognitionRequest`, `streamContinuation`, `levelContinuation` from multiple threads without synchronization. The `stop` closure (~line 362) calls `stopRecording()` from an arbitrary thread.  
  **Fix:** Add `private let stateQueue = DispatchQueue(label: "ai.pulsum.speech.backend")`. Wrap all reads/writes of the 5 mutable properties in `stateQueue.sync {}`.

- [ ] **P2-02** | MED-001 | Synchronize RecRanker + StateEstimator  
  **Files:** `Packages/PulsumML/Sources/PulsumML/RecRanker.swift`, `Packages/PulsumML/Sources/PulsumML/StateEstimator.swift`  
  **Problem:** Both are mutable `final class` types with no locking. `weights` and `bias`/`learningRate` are mutated in `update()` and read in `score()`/`predict()`. Called from actor-isolated contexts today but the types themselves are unsafe.  
  **Fix (preferred):** Keep RecRanker and StateEstimator non-Sendable and confined inside their owning actor (DataAgent owns StateEstimator, CoachAgent owns RecRanker). If they never leave the actor, no synchronization is needed — the actor provides it. Do NOT add NSLock (it forces `@unchecked Sendable` which the plan bans). Only convert to `actor` if they must be shared across isolation domains.

- [ ] **P2-03** | MED-007 | Fix HealthKitAnchorStore read/write asymmetry  
  **File:** `Packages/PulsumServices/Sources/PulsumServices/HealthKitAnchorStore.swift`  
  **Problem:** `anchor(for:)` uses `queue.sync` but `store(anchor:for:)` uses `queue.async`. A `store()` followed immediately by `anchor()` returns stale data.  
  **Fix:** Change `store()` to use `queue.sync` instead of `queue.async`.

- [ ] **P2-04** | MED-008 | Add reprocessDay to submitTranscript  
  **File:** `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`  
  **Problem:** `submitTranscript()` (~lines 416-419) calls `sentimentAgent.importTranscript()` but does NOT call `dataAgent.reprocessDay(date:)`. Compare with `finishVoiceJournalRecording()` (~line 389) which does.  
  **Fix:** Add `try await dataAgent.reprocessDay(date: result.date)` before the `return` in `submitTranscript()`.

- [ ] **P2-05** | MED-011 | Synchronize LLMGateway.inMemoryAPIKey  
  **File:** `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift`  
  **Problem:** `inMemoryAPIKey` (line ~294) is a mutable `var` on `@unchecked Sendable` class. Concurrent reads from key resolution and writes from `setAPIKey()` are unsynchronized.  
  **Fix (preferred):** Convert `LLMGateway` to an `actor` instead of adding locks. This also makes rate limiting (P3-07) and network checks cleaner. If converting to actor is too disruptive, isolate only the key storage in a small private actor or use `OSAllocatedUnfairLock`. Avoid NSLock + `@unchecked Sendable`.

- [ ] **P2-06** | MED-012 | Document testAPIConnection consent  
  **File:** `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift`  
  **Problem:** `testAPIConnection()` (~line 332) makes a real API call without checking cloud consent. It's a connectivity test that doesn't send user data, but this isn't documented.  
  **Fix:** Add a doc comment: `/// Tests API connectivity. This is a lightweight ping that sends no user data and does not require cloud consent.`

- [ ] **P2-07** | MED-016 | Verify day-boundary timezone handling  
  **File:** `Packages/PulsumTypes/Sources/PulsumTypes/DiagnosticsTypes.swift`  
  **Problem:** `DiagnosticsDayFormatter` (~line 244) uses `TimeZone(secondsFromGMT: 0)` (UTC). If this formatter is used for health metric day-boundary aggregation, users in UTC-8 get their sleep split across two days.  
  **Fix:** Add comment documenting UTC is intentional for diagnostics. Verify in DataAgent that metric aggregation uses `Calendar.current` (local timezone) for day boundaries, not this formatter.

- [ ] **P2-08** | LOW-002 | Guard zScore against zero MAD  
  **File:** `Packages/PulsumML/Sources/PulsumML/BaselineMath.swift`  
  **Problem:** `robustStats(for:)` clamps to `max(mad, 1e-6)`, but the public `RobustStats.init(median:mad:)` does NOT validate. Manual construction with `mad: 0` causes `Inf`/`NaN` in `zScore()`.  
  **Fix:** In `RobustStats.init`, add `self.mad = max(mad, 1e-6)`.

- [ ] **P2-09** | LOW-003 | NaN guard in StateEstimator  
  **File:** `Packages/PulsumML/Sources/PulsumML/StateEstimator.swift`  
  **Problem:** NaN in any feature value propagates through `predict()` to `update()` to ALL weight gradients, corrupting the entire model in one call.  
  **Fix:** At top of `predict()` and `update()`: `let safeFeatures = features.filter { !$0.value.isNaN }`.

- [ ] **P2-10** | LOW-004 | Fix sanitize punctuation  
  **Files:** `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift` (~line 479), `FoundationModelsCoachGenerator.swift` (~line 90)  
  **Problem:** `split(whereSeparator:)` consumes `!` and `?` delimiters. "Great job! Keep going?" → "Great job. Keep going." (all punctuation replaced with periods).  
  **Fix:** Use regex split that preserves delimiters, or use `components(separatedBy: CharacterSet)` with post-processing to retain original sentence-ending punctuation.

- [ ] **P2-11** | LOW-005 | Remove duplicate `#if DEBUG`  
  **File:** `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift` (~lines 419-420)  
  **Problem:** Two nested `#if DEBUG` guards (copy-paste error). Harmless but messy.  
  **Fix:** Remove the inner duplicate `#if DEBUG`. Keep one.

- [ ] **P2-12** | LOW-006 | Fix speech timeout task leak  
  **File:** `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift` (~lines 352-358)  
  **Problem:** The max-duration timeout `Task` is fire-and-forget. If recording stops early, the task lives until `maxDuration` expires, then calls `stopRecording()` on an already-stopped backend.  
  **Fix:** Store the task as a property: `private var timeoutTask: Task<Void, Never>?`. Cancel in `stopRecording()`: `timeoutTask?.cancel(); timeoutTask = nil`.

- [ ] **P2-13** | LOW-007 | Log RecRanker state version mismatch  
  **File:** `Packages/PulsumML/Sources/PulsumML/RecRanker.swift` (~lines 188-194)  
  **Problem:** `apply(state:)` silently ignores state when `version != schemaVersion`. Learned preferences are silently lost with no log.  
  **Fix:** Add before the silent return: `Diagnostics.log(level: .warn, category: .coach, name: "recranker.state.versionMismatch", fields: ["stored": .int(state.version), "current": .int(schemaVersion)])`.

- [ ] **P2-14** | LOW-008 + LOW-009 | Fix ViewModel task leaks  
  **Files:** `Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift`, `PulseViewModel.swift`  
  **Problem:** CoachViewModel has no `deinit` — 3 stored tasks (`recommendationsTask`, `recommendationsDebounceTask`, `recommendationsSoftTimeoutTask`) are never cancelled. `scheduleCheerReset()` and `scheduleSubmissionReset()` create unstored fire-and-forget tasks that accumulate.  
  **Fix:** (1) Add `deinit { recommendationsTask?.cancel(); recommendationsDebounceTask?.cancel(); recommendationsSoftTimeoutTask?.cancel() }` to CoachViewModel. (2) In `scheduleCheerReset()`/`scheduleSubmissionReset()`, store the task as a property and cancel the previous one before creating a new one.

- [ ] **P2-15** | LOW-010 | Cache DateFormatters  
  **Files:** `Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownView.swift` (~line 91), `SettingsView.swift` (~line 753)  
  **Problem:** `DateFormatter()` and `RelativeDateTimeFormatter()` allocated in computed properties that run on every SwiftUI evaluation. These are expensive objects.  
  **Fix:** Replace with `static let` cached formatters: `private static let dateFormatter: DateFormatter = { let f = DateFormatter(); f.dateStyle = .medium; return f }()`.

- [ ] **P2-16** | LOW-001 | Clean up EvidenceScorer dead domains  
  **File:** `Packages/PulsumData/Sources/PulsumData/EvidenceScorer.swift`  
  **Problem:** `"pubmed"` never matches (real host is `pubmed.ncbi.nlm.nih.gov`). `"nih.gov"` is redundant with `".gov"`. `"harvard.edu"` in mediumDomains is shadowed by `".edu"` in strongDomains.  
  **Fix:** Change `"pubmed"` to `"pubmed.ncbi.nlm.nih.gov"`. Remove `"nih.gov"`. Move `"harvard.edu"` to strongDomains or remove (already covered by `.edu`).

- [ ] **P2-17** | MED-006 | Fix LibraryImporter non-atomic 3-phase commit  
  **File:** `Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift`  
  **Problem:** Phase 1 (`context.save()` for MicroMoments) commits before Phase 3 (`context.save()` for LibraryIngest tracking). A crash between phases causes Phase 1 to re-run on next launch, repeating all embedding work. The concurrent task group in Phase 2 also cancels all remaining tasks on single-element failure, leaving partial indexing.  
  **Fix:** Combine all three phases into a single `context.save()`. Save MicroMoments and LibraryIngest records together. Or save LibraryIngest first as "pending" and update to "complete" after all phases.

- [ ] **P2-18** | MED-010 | Fix OnboardingView bypassing orchestrator auth tracking  
  **File:** `Packages/PulsumUI/Sources/PulsumUI/OnboardingView.swift` (~lines 300-312)  
  **Problem:** When `orchestrator` is nil, OnboardingView creates a fresh `HKHealthStore` and requests authorization directly, bypassing DataAgent's auth tracking, read-access probe cache, and observer/backfill scheduling. User grants permissions but the orchestrator doesn't know.  
  **Fix:** Either wait for orchestrator to be ready before requesting HealthKit auth, or store the auth result in UserDefaults and replay it when the orchestrator initializes.

- [ ] **P2-19** | STUB-003 | Fix FM TopicGate returning nil topic field  
  **File:** `Packages/PulsumML/Sources/PulsumML/TopicGate/FoundationModelsTopicGateProvider.swift` (~lines 48-52)  
  **Problem:** The FM path returns `GateDecision` with `topic: nil` always, while the embedding path provides topic identification. This loses topic-specific coaching granularity when Foundation Models are available.  
  **Fix:** Add a `topic` field to the `OnTopic` `@Generable` struct. Include topic identification in the FM prompt. Map the generated topic to the `GateDecision.topic` field.

### Phase 2 Done When:

- [ ] All 19 items checked
- [ ] Full build passes, all tests pass, `swiftformat .` clean

---

## Phase 3: Production Readiness

**Goal:** Add production infrastructure for App Store submission.  
**Effort:** ~1-2 weeks | **Branch:** `feat/phase3-production` | **Requires:** Phase 2 complete

### 3.1 — Compliance

- [ ] **P3-01** | PROD-006 | Add "Delete All Data" to Settings (GDPR)
  **Files:** `Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift`, `SettingsViewModel.swift`, `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`
  **What to build:** (1) Add `deleteAllData()` method to AgentOrchestrator that uses **SwiftData bulk delete** for each model type — no need to fetch then delete individually:
  ```swift
  try modelContext.delete(model: JournalEntry.self)
  try modelContext.delete(model: DailyMetrics.self)
  try modelContext.delete(model: Baseline.self)
  try modelContext.delete(model: FeatureVector.self)
  try modelContext.delete(model: MicroMoment.self)
  try modelContext.delete(model: RecommendationEvent.self)
  try modelContext.delete(model: LibraryIngest.self)
  try modelContext.delete(model: UserPrefs.self)
  try modelContext.delete(model: ConsentState.self)
  try modelContext.save()
  ```
  Then: delete the VectorStore file, remove API key from Keychain (`KeychainService.shared.removeSecret`), clear HealthKit anchor store files, clear diagnostics exports, clear UserDefaults except `hasLaunched`, reset `hasCompletedOnboarding` to false. *(Updated from feedback review: SwiftData supports bulk delete per model type — simpler and less error-prone than fetch-and-delete loops.)*
  (2) Add "Delete All My Data" button (`.destructive` role) in SettingsView Privacy section with a two-step confirmation (`.confirmationDialog`). (3) After deletion, set `AppViewModel.startupState = .idle` to trigger onboarding.

- [ ] **P3-02** | PROD-007 | Persist onboarding completion  
  **File:** `Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift`  
  **What to change:** Add `@AppStorage("ai.pulsum.hasCompletedOnboarding") private var hasCompletedOnboarding = false`. Set to `true` after user completes full onboarding flow (health permissions + consent). In `PulsumRootView`, use this flag (not just `firstLaunch`) to decide whether to show onboarding.

### 3.2 — Observability

- [ ] **P3-03** | PROD-002 | Add MetricKit crash diagnostics  
  **Create:** `Packages/PulsumServices/Sources/PulsumServices/CrashDiagnosticsSubscriber.swift`  
  **What to build:** A class conforming to `MXMetricManagerSubscriber`. In `didReceive(_ payloads: [MXDiagnosticPayload])`, log each payload via `Diagnostics.log(level: .error, category: .app, name: "crash.diagnostic")`. Register the subscriber in `AppViewModel.start()`: `MXMetricManager.shared.add(subscriber)`. MetricKit is Apple-native — zero external dependencies.

- [ ] **P3-04** | PROD-003 | Add analytics event structure  
  **Create:** `Packages/PulsumTypes/Sources/PulsumTypes/AnalyticsEvent.swift`  
  **What to build:** (1) `enum AnalyticsEvent: String` with cases: `onboardingCompleted`, `journalRecorded`, `scoreViewed`, `recommendationTapped`, `recommendationCompleted`, `chatSent`, `settingsChanged`, `apiKeyAdded`. (2) `protocol AnalyticsProvider: Sendable { func track(_ event: AnalyticsEvent, properties: [String: String]) }`. (3) `final class NoOpAnalyticsProvider: AnalyticsProvider` (default — does nothing). A real SDK (TelemetryDeck, PostHog) can be plugged in later by conforming to the protocol.

### 3.3 — Network

- [ ] **P3-05** | PROD-004 | Build NetworkMonitor  
  **Create:** `Packages/PulsumServices/Sources/PulsumServices/NetworkMonitor.swift`  
  **What to build:** An `@Observable` class (or actor) wrapping `NWPathMonitor`. Publish `var isConnected: Bool`. Start monitoring in `AppViewModel.start()`. In `LLMGateway.generateCoachResponse()`, check `NetworkMonitor.shared.isConnected` — if false, skip cloud and go directly to on-device generator (saves the 60s URLSession timeout wait). **Search Apple docs for `NWPathMonitor` current API.**

- [ ] **P3-06** | PROD-016 | Offline banner in CoachView  
  **File:** `Packages/PulsumUI/Sources/PulsumUI/CoachView.swift`  
  **What to change:** When `NetworkMonitor.shared.isConnected == false` AND `consentGranted == true`, show a subtle banner at the top of the chat area: `Text("You're offline — using on-device coaching").font(.caption).foregroundStyle(.secondary).padding(8).background(.ultraThinMaterial)`.

- [ ] **P3-07** | PROD-015 | Rate limiter for LLMGateway  
  **File:** `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift`  
  **What to build:** A simple time-window rate limiter: track `lastCloudRequestTime` and `cloudRequestCountThisHour`. If < 3 seconds since last request OR > 20 requests this hour, skip cloud and use on-device. Log: `Diagnostics.log(level: .info, category: .llm, name: "llm.rateLimited")`.

### 3.4 — Accessibility

- [ ] **P3-08** | HIGH-006 | Dynamic Type support  
  **File:** `Packages/PulsumUI/Sources/PulsumUI/PulsumDesignSystem.swift`  
  **Problem:** All fonts use `Font.system(size:)` with hardcoded sizes (34, 28, 22, 17, 15, 13, 12). These do NOT scale with Dynamic Type.  
  **Fix:** Replace with semantic font styles. Map: `pulsumLargeTitle` → `.largeTitle`, `pulsumTitle` → `.title`, `pulsumTitle2` → `.title2`, `pulsumHeadline` → `.headline`, `pulsumBody` → `.body`, `pulsumCallout` → `.callout`, `pulsumCaption` → `.caption`, `pulsumFootnote` → `.footnote`. Apply `.bold()` or `.weight()` modifiers as needed. **Search Apple docs for SwiftUI font and Dynamic Type best practices before changing.**

### 3.5 — Build & Ops

- [ ] **P3-09** | PROD-013 | Auto-increment build number  
  **What to change:** Add a Run Script build phase (before Compile Sources) to the Pulsum target in Xcode: `CURRENT_PROJECT_VERSION=$(git rev-list --count HEAD)`. Or set it in the xcconfig. This ensures each commit has a unique build number for TestFlight and crash reports.

- [ ] **P3-10** | PROD-017 | Centralize UserDefaults keys  
  **Create:** `Packages/PulsumTypes/Sources/PulsumTypes/PulsumDefaults.swift`  
  **What to build:** `enum PulsumDefaults { static let hasLaunched = "ai.pulsum.hasLaunched"; static let hasCompletedOnboarding = "ai.pulsum.hasCompletedOnboarding"; static let diagnosticsConfig = "ai.pulsum.diagnostics.config" }`. Update all UserDefaults access sites to use these constants instead of raw strings.

- [ ] **P3-11** | LOW-012 + LOW-013 | Fix empty PulsumTests + enable in scheme  
  **Files:** `PulsumTests/PulsumTests.swift` (delete or add real tests), `Pulsum.xcodeproj/xcshareddata/xcschemes/Pulsum.xcscheme` (change `skipped = "YES"` to `skipped = "NO"` on the PulsumTests testable reference ~line 52).

- [ ] **P3-12** | LOW-014 | Compile-gate KeychainService UITest fallback  
  **File:** `Packages/PulsumServices/Sources/PulsumServices/KeychainService.swift`  
  **Problem:** The UITest fallback from Keychain to UserDefaults is gated by a runtime check (`AppRuntimeConfig.disableKeychain`), not a compile-time `#if DEBUG`. All other UITest stubs use compile-time gating.  
  **Fix:** Wrap the `useFallbackStore` / UserDefaults code path in `#if DEBUG`.

- [ ] **P3-13** | PROD-011 | App rating prompt  
  **Files:** `Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift`, relevant View file  
  **Important:** `@Environment(\.requestReview)` is a SwiftUI environment value — it ONLY works inside a View body, NOT in a ViewModel. The ViewModel must expose a flag; the View calls the action.  
  **What to add:** (1) In AppViewModel: track score view count in UserDefaults. After the 5th view, set `shouldRequestReview = true`. Track last prompted version to avoid re-prompting. (2) In the View that displays the score (e.g., PulsumRootView or ScoreBreakdownView): observe `shouldRequestReview`, and when it flips to true, call `requestReview()` from the View's body/onChange and reset the flag.

- [ ] **P3-14** | PROD-014 | Audit Release logging for PHI leaks  
  **Files:** `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift` (line ~765), `Packages/PulsumTypes/Sources/PulsumTypes/DiagnosticsLogger.swift`  
  **Problem:** LLMGateway line 765 has a parenthesis bug: `, privacy: .public)` is inside the string interpolation instead of being an os_log privacy attribute. The GPT response snippet is logged in Release mode.  
  **Fix:** Fix the logging call to use proper os_log privacy syntax. Audit all `.error` and `.warn` level logs in Release for PHI/PII content. The `DiagnosticsReportBuilder` includes `wellbeingScore` in exports — add a warning when users export diagnostics.

- [ ] **P3-15** | PROD-010 | SSL certificate pinning for API — EVALUATE, MAY DEFER  
  **File:** `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift`  
  **Problem:** API keys and coaching context sent to `api.openai.com` without cert pinning.  
  **Warning:** Certificate pinning is NOT "free security" — it's high-maintenance and can brick your app if certs rotate and you haven't updated pins. OWASP treats pinning as optional and warns about operational burden. **Only implement if you have:** (a) SPKI-based pinning (not certificate pinning), (b) multiple backup pins, (c) a remote-config fallback to disable pinning in emergency, (d) a fast app update pipeline. **If you don't have these, defer to v1.1.** Standard HTTPS with App Transport Security is sufficient for v1.0 — the real fix is moving the API key to your backend (Phase 4.5 in `master_plan_1_1_FUTURE.md`) which eliminates the API key exposure entirely.

- [ ] **P3-16** | PROD-018 | Add units and context to health data display  
  **File:** `Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownView.swift`  
  **Problem:** Health metrics may be displayed without units (ms for HRV, bpm for heart rate, hours for sleep, steps). This can confuse users.  
  **Fix:** Ensure each metric in the breakdown view shows its unit: "HRV: 45 ms", "Resting HR: 62 bpm", "Sleep: 7.2 hrs", "Steps: 8,432", "Respiratory Rate: 16 br/min".

### 3.6 — Test Coverage (addresses GAP-001 through GAP-007)

- [ ] **P3-17** | GAP-002 | Write safety classifier tests (crisis detection is undertested)  
  **Create:** Expand `Packages/PulsumML/Tests/PulsumMLTests/SafetyLocalTests.swift`  
  **What to add:** Test every crisis keyword from P1-03 classifies as `.crisis`. Test paraphrased crisis text without keywords (>0.85 embedding similarity). Test boundary between `.caution` and `.crisis`. Test safe text returns `.safe`. Target: 20+ test cases for the safety classifier (currently only 3-4).

- [ ] **P3-18** | GAP-001 | Write voice journal streaming tests  
  **Create:** Expand `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate2_JournalSessionTests.swift`  
  **What to add:** Test full lifecycle: `beginVoiceJournal()` → stream segments → `finishVoiceJournal()`. Test error mid-stream (speech recognition failure). Test duplicate `begin` calls (should throw `.sessionAlreadyActive`). Test PII redaction in finish.

- [ ] **P3-19** | GAP-004 + GAP-005 | Write wellbeing score pipeline and LLM integration tests  
  **What to add:** (1) End-to-end test: raw health metrics → DailyMetrics → Baseline → FeatureVector → StateEstimator → score. Verify each mathematical step. (2) LLM Gateway test: mock cloud client, verify request body structure, response parsing, consent enforcement, fallback to on-device on failure.

### Phase 3 Done When:

- [ ] All 19 items checked
- [ ] Full build passes, all tests pass
- [ ] Dynamic Type works on all screens
- [ ] Data deletion resets to onboarding
- [ ] Offline indicator shows in CoachView
- [ ] `swiftformat .` + `scripts/ci/check-privacy-manifests.sh` clean

---

## Progress Tracker

| Phase | Items | Done | Status |
|---|---|---|---|
| Phase 0: Architecture | 27 | 0 | Not Started |
| Phase 1: Safety & Bugs | 14 | 0 | Not Started |
| Phase 2: Cleanup | 19 | 0 | Not Started |
| Phase 3: Production + Tests | 19 | 0 | Not Started |
| **Total** | **79** | **0** | **0%** |

---

## Intentionally Deferred to v1.1 (NOT forgotten — decided to skip for v1.0)

| Finding | Description | Why Deferred |
|---|---|---|
| HIGH-008 / STUB-001 | ModernSpeechBackend is a stub | Works via legacy fallback. Implement when Apple ships SpeechAnalyzer/SpeechTranscriber APIs. |
| STUB-002 | BGTaskScheduler not implemented | Only HealthKit background delivery is needed for v1.0. True background processing is v1.1. |
| LOW-011 | Duplicate TestCoreDataStack files | Resolved by P0-12 (SwiftData test helper rewrite removes both old files). |
| LOW-015 | Evaluate Spline dependency | Decision item. Spline is used for 3D animation — keep for v1.0, evaluate alternatives later. |
| PROD-001 | No monetization infrastructure (StoreKit) | D9 decided: BYOK optional for v1.0. Build subscriptions in v1.1 after user feedback. |
| PROD-008 | All 500+ strings hardcoded (no localization) | English-only for v1.0. Extract to String Catalog for v1.1. Large effort (~2 weeks). |
| PROD-012 | No Widget/Siri/App Intents | Platform integrations for v1.1. Core app functionality first. |
| GAP-003 | HealthKit integration tests (requires real device) | Can't unit test HealthKit properly — requires device. Use stubs + manual testing for v1.0. |
| GAP-006 | Main app target has empty test | Addressed by P3-11 (remove empty test / enable scheme). |
| GAP-007 | UI/ViewModel layer only 12 tests | Partially addressed by architecture improvements (protocol DI makes VMs testable). Add more tests in v1.1. |
| MED-009 | SafetyAgent crisis message US-centric | Partially addressed by P1-12 (adds "Outside the US, contact your local emergency services"). Full locale-aware resources in v1.1. |
| ARCH-002 | Mixed DI patterns (singletons + init injection) | Addressed by D5 (remove CD singletons) + P0-03 (injectable access). Remaining DI inconsistencies are cosmetic. |
| ARCH-003 | NotificationCenter + closures + @Observable mixed observation | Addressed by D6 (keep @Observable + NotificationCenter, drop closures) + P0-26. |
| ARCH-004 | No protocol abstraction for agents | Acceptable for v1.0 — agents are already behind the orchestrator facade. Add protocols in v1.1 for testability. |
| ARCH-009 | PulsumUI depends on PulsumData (bypasses layering) | Addressed by D10 — with SwiftData, PulsumUI→PulsumData is correct for @Query. |
| PROD-005 | No structured error recovery UI | Partially addressed by P0-11 (.blocked startup state). Full error recovery UX in v1.1. |
| GL-2.1 | DataStack fatalError crash paths | Directly addressed by P0-02 (throws init, no fatalError). |
| CALC-001 → 012 | Calculation and logic audit findings | Verified correct or addressed by: P1-06 (RecRanker gradient), P2-08 (zScore guard), P2-09 (NaN guard), P1-07 (sentiment fallback). Remaining CALC findings were verified correct — no remediation needed. |

---

## Finding ID Quick Reference

Look up full details in `master_report.md` by finding ID:

| ID Range | Severity | Count | Section in master_report.md |
|---|---|---|---|
| CRIT-001 → 005 | Critical | 5 | Critical Issues |
| HIGH-001 → 010 | High | 10 | High-Priority Issues |
| MED-001 → 016 | Medium | 16 | Medium-Priority Issues |
| LOW-001 → 015 | Low | 15 | Low-Priority Issues |
| ARCH-001 → 009 | Architecture | 9 | Architecture Design Review |
| PROD-001 → 018 | Production | 18 | Production-Readiness Findings |
| GL-1.4.1, GL-2.1 | Compliance | 7 | `guidelines_report.md` |
| CALC-001 → 012 | Logic | 12 | Calculation and Logic Audit |
| GAP-001 → 007 | Test gaps | 7 | Test Coverage Gaps |
