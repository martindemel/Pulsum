# Pulsum iOS App — Full End-to-End Technical Analysis Prompt (V2)

## MISSION

You are a senior iOS engineer and systems architect performing a comprehensive, exhaustive technical audit of the Pulsum iOS application. Your job is to discover every iOS-relevant source file, read each from first line to last line, understand the entire system as a whole, and then produce two deliverables:

1. **`master_report.md`** — Technical findings report (bugs, architecture, calculations, production readiness, integration issues)
2. **`master_plan_FINAL.md`** — Actionable remediation plan with phased checkboxes

> **Note:** The App Store compliance report (`guidelines_report.md`) is produced by running `guidelines_checkV2.md` SEPARATELY — not as part of this scan. This scan focuses on technical correctness, architecture, and production readiness. The guidelines check focuses on Apple review compliance. Running them separately ensures each gets full attention without drift.

**PROJECT ROOT (mandatory):** Use the repository root containing `Pulsum.xcodeproj` and `Packages/` as working root for discovery and outputs.

You must not stop, pause, or ask for permission to continue. You will run until every file has been read, every finding documented, and both deliverables written. This is a single uninterrupted analysis session.

**TASK TRACKING (mandatory):** This audit has many steps. To avoid losing track, you MUST create a structured task list at the start of your work using whatever task/todo tracking the environment provides (TodoWrite, task lists, or a temporary `_scan_progress.md` file). The task list must include:
- [ ] Phase 0.0: Read AGENTS.md and project constraints (if exists)
- [ ] Phase 0.1-0.3: Discover and categorize file structure
- [ ] Phase 0.4: Resolve deployment target + Info.plist sources from build settings
- [ ] Phase 0.5: Read diagnostics_data.md (if exists)
- [ ] Phase 0.6: Process binary artifacts (metadata + bundle inclusion checks)
- [ ] Phase 1: Read all files (batch by package — one task per package)
- [ ] Phase 1.5: Append per-file digests to _scan_notes.md
- [ ] Phase 2.1-2.25: One task per analysis dimension (25 tasks)
- [ ] Phase 2.26: Snapshot and compare previous reports/plans (if they exist, BEFORE overwriting outputs)
- [ ] Phase 3A: Write master_report.md
- [ ] Phase 3B: Write master_plan_FINAL.md

Check off each task as you complete it. If you are interrupted or lose context, re-read the task list to see what remains. Do NOT proceed to Phase 3 (writing reports) until ALL Phase 2 analysis dimensions and Phase 2.26 are checked off. If using a temporary progress file, delete `_scan_progress.md` after all deliverables are written.

---

## PHASE 0: DISCOVER THE FILE STRUCTURE (Dynamic — do NOT use a hardcoded list)

The codebase changes between scans. You MUST dynamically discover all iOS-relevant source files rather than relying on a static list.

### 0.1 — Scan the project structure

Use glob/find/ls to discover all files matching these patterns from the project root:

```
**/*.swift           — All Swift source files
**/*.entitlements     — Entitlements
**/*.xcprivacy        — Privacy manifests
**/*.xcconfig         — Build configuration
**/*.pbxproj          — Xcode project
**/Info.plist         — App/target plist configuration
**/*.plist            — Relevant plist resources (filter to compliance/build-relevant files)
**/*.xcstrings        — String catalogs (localization/disclaimer text checks)
**/*.xcscheme         — Xcode schemes
**/*.xcworkspacedata  — Workspace
**/Package.swift      — SPM manifests
**/Package.resolved   — SPM lock file
**/*.xcdatamodel*     — Core Data / SwiftData models (if any remain)
**/*.momd/**          — Compiled models (if any remain)
**/*.mlmodel          — CoreML models
**/*.storekit         — StoreKit configuration (if exists)
**/Contents.json      — Asset catalog metadata
**/*.sh               — Scripts
```

### 0.2 — Exclude non-iOS files

Skip: `.pdf`, `.txt`, `.git/**`, `.DS_Store`, `DerivedData/**`, `.build/**`, image files (`.png`, `.jpg`, `.svg`, `.gif`), binary files (`.usdz`, `.splineswift`), `node_modules/**`, and most `.md` files.

**Markdown exceptions you MUST read if present:** `AGENTS.md`, `diagnostics_data.md`, existing `master_report.md`, existing `master_plan_FINAL.md`, existing `guidelines_report.md`, and any explicit previous snapshots (`*_PREV.md`) used for delta comparison.

**Additional documentation exceptions:** Read user-facing legal/disclaimer content even if it is markdown/html/txt when it is bundled into the app experience (privacy policy text, terms, safety disclaimers, crisis resources).

### 0.3 — Categorize discovered files

Group files into:
- Main app target (Pulsum/)
- Build/project configuration (.xcodeproj/, .xcconfig)
- Each SPM package (Packages/PulsumTypes/, PulsumML/, PulsumData/, PulsumServices/, PulsumAgents/, PulsumUI/ — or whatever packages exist)
- Unit tests (Tests/ directories)
- UI tests (PulsumUITests/)
- Scripts (scripts/)
- New packages or targets not in the original structure (flag these as NEW)

Report the file count per category. If the structure differs from what previous reports expected (6 packages, ~96 source files, ~67 test files), note the differences.

---

### 0.4 — Project Constraints + Deployment Target + Info.plist Resolution (mandatory)

Before deeper analysis, establish build/runtime facts from source:

- Read `AGENTS.md` if present. Treat its constraints as project policy input.
- Resolve deployment target from build settings (`IPHONEOS_DEPLOYMENT_TARGET` in `.pbxproj`/`.xcconfig`) and package manifests (`platforms` in `Package.swift` files).
- Determine how Info.plist values are provided:
  - Direct `Info.plist` file via `INFOPLIST_FILE`, and/or
  - Build-setting generated keys (`INFOPLIST_KEY_*`) in project/xcconfig.
- Extract and record protected-resource purpose strings from whichever source is authoritative. At minimum verify:
  - `NSHealthShareUsageDescription`
  - `NSHealthUpdateUsageDescription`
  - `NSMicrophoneUsageDescription`
  - `NSSpeechRecognitionUsageDescription`

Add a short "Build Facts" block to `_scan_notes.md` with:
- deployment target(s),
- Info.plist source strategy,
- protected-resource key coverage status.

All API suitability critiques must be gated by these resolved build facts, not prompt assumptions.

### 0.5 — Check for runtime diagnostics data (optional but valuable)

If `diagnostics_data.md` exists in the project root, read it. This file contains exported runtime diagnostics from an actual device run — log output, timing data, error traces, and health metric snapshots from the app's built-in `DiagnosticsLogger`.

**What to look for in diagnostics data:**
- **Startup timing:** How long did `orchestrator.start()` take? Did bootstrap stall? Did the watchdog fire?
- **HealthKit:** Did authorization succeed? Did observer queries fire? How many samples were ingested? Any errors?
- **Embedding service:** Did the availability probe succeed? Which provider was selected? Did fallback occur?
- **Sentiment analysis:** Which provider succeeded? Did any return 0.0 (total failure)?
- **LLM Gateway:** Did the API connection test pass? What was the response time? Any schema errors?
- **Safety classification:** Were any crisis/caution classifications triggered? False positives?
- **Errors:** Any `[ERROR]` lines? Stack traces? Unexpected states?
- **Stall warnings:** Any `.stall` diagnostic events indicating hung operations?

**How to use diagnostics data in the analysis:**
- Cross-reference runtime errors with code findings. If diagnostics show "embedding.probe.failed" but the code looks correct, the issue may be environmental or timing-related.
- If diagnostics show operations taking >1 second, flag as performance findings even if the code looks structurally correct.
- If diagnostics show repeated retries or fallbacks, the fallback chains may be misconfigured or the primary providers may be unreliable on real hardware.

If `diagnostics_data.md` does not exist, skip this step — the scan works without it. Note in the report: "No runtime diagnostics data provided. Findings are based on static analysis only. For more accurate results, export diagnostics from a real device run and save as diagnostics_data.md."

---

### 0.6 — Binary Artifact Handling (mandatory for non-text files)

For binary or compiled artifacts (`.mlmodel`, compiled `.momd`, and similar files), do NOT attempt full text ingestion.

Instead, verify:
- artifact presence,
- resource inclusion/target membership (Xcode target or SPM resource declarations),
- any available metadata (model name/version, file size, expected location).

Record binary-artifact verification results in `_scan_notes.md`. Mark unknowns explicitly as "Needs Verification" rather than guessing.

---

## PHASE 1: READ EVERY FILE (mandatory — no skipping)

Read every text-based file discovered in Phase 0 from start to end. Do not skim and do not skip. Use batch/parallel reads where possible for speed, but ensure every text file is fully ingested. For binary artifacts, follow Phase 0.6.

After each file read, append a short digest entry to `_scan_notes.md` (5-15 lines) including:
- file path and responsibility,
- key types/functions,
- risky APIs or edge-case hotspots,
- cross-file dependencies,
- open questions / verification targets.

These digests are required audit scaffolding. They do not replace full reads.

---

## PHASE 2: ANALYSIS DIMENSIONS

After reading every file, analyze the entire codebase across ALL of the following dimensions. Do not skip any dimension. For each one, trace the logic across file boundaries — most real problems live at integration seams, not inside a single file.

### 2.1 — Architectural Integrity

- Do the packages respect their declared dependency graph? Any circular or undeclared dependencies?
- Does each Package.swift accurately declare its dependencies, platforms, and targets?
- Are there import statements that violate the layered architecture?
- Is the acyclic dependency flow actually enforced?
- Are public/internal/private access levels correctly used across package boundaries?

### 2.2 — Data Flow and State Management

- Trace health data flow: HealthKit → service → agent → persistence → UI. Any drops, races, or stale data?
- Trace voice journal flow: microphone → speech service → sentiment agent → persistence → UI. Is the streaming API correctly wired?
- Trace wellbeing score computation: raw data → metrics → baselines → features → estimator → score → UI. Every step mathematically correct?
- Examine all @Observable, @Published, @StateObject, @ObservedObject, @EnvironmentObject, @Query usage. Retain cycles? Missing updates?
- Are Notification posts and observers correctly paired?
- Persistence context usage: are read/write contexts used correctly? Any main-thread violations?

### 2.3 — ML Pipeline Correctness

- Sentiment Analysis: Trace the full provider fallback chain. Does fallback work? Scores normalized consistently [-1, 1]?
- Embedding Service: Same fallback analysis. Dimensions consistent across providers?
- Safety Classification: Is the two-wall guardrail enforced? Can unsafe content bypass Wall 1? Can ungrounded responses bypass Wall 2? Do Foundation Model guardrail violations return .caution (not .safe)?
- RecRanker: Is the Bradley-Terry pairwise gradient correct? Weights updated properly? Cold-start handled?
- StateEstimator: Wellbeing state labels correctly mapped? Z-scores correct? NaN guards present?
- BaselineMath: Division by zero? NaN propagation? Empty data edge cases?
- TopicGate: Permissive in degraded mode (not blocking all input)? Thresholds reasonable?
- PII Redaction: Covers emails, phones, names, SSNs, credit cards, IPs? Luhn validation for credit cards?
- CoreML Models: Loaded correctly? Bundle paths correct?

### 2.4 — HealthKit Integration

- All required data types in entitlements and authorization flow?
- Observer queries, anchored queries, background delivery all correct?
- Anchor store persisting and resuming correctly? No read/write race?
- Timezone/date issues in daily metric aggregation?
- Graceful handling of no data, partial data, denied authorization?
- Idempotent ingestion?

### 2.5 — Persistence Layer

**NOTE: The app may use Core Data, SwiftData, or a mix. Adapt this section to whatever is found.**

If SwiftData:
- Are `@Model` classes correctly defined with proper types?
- Are `#Index` macros applied to frequently queried fields?
- Is `@ModelActor` used for actor-owned contexts (not manual `ModelContext(container)`)?
- Is `ModelContext` stored across `await` boundaries only in `@ModelActor`?
- Does `ModelContainer` init handle errors gracefully (no fatalError)?
- Is NSFileProtectionComplete applied to the store?
- Is there a `VersionedSchema` / `SchemaMigrationPlan` for future migrations?

If Core Data:
- Do entities, attributes, relationships match what Swift code expects?
- Missing inverse relationships? Missing fetch indexes?
- Is compiled .momd in sync with source .xcdatamodeld?
- Is performAndWait blocking the main thread?

### 2.6 — Vector Index / Vector Store

- Is the vector storage correct? (May be custom binary, in-memory, SQLite, or other)
- Is sharding deterministic? (No randomized hashValue)
- Is L2/cosine distance calculation correct?
- Is concurrent access safe? (Actor isolation, no data races)
- Are writes atomic/crash-safe?
- Is bulk upsert supported for batch operations (e.g., library import)?
- Is file protection applied?

### 2.7 — LLM / Cloud Integration

- API integration correct? Request/response schemas match?
- API key loaded securely? (Keychain, environment, backend — NOT hardcoded)
- Error handling for network failures, rate limits, timeouts?
- Schema and system prompt enums aligned? (e.g., intentTopic lists must match between schema and prompt)
- Foundation Models coach generator using APIs compatible with resolved deployment target? If target includes iOS 26+, verify `LanguageModelSession`, `@Generable`, and `GenerationOptions`.
- Cloud consent respected everywhere? No data leaks without consent?
- UITest stubs properly isolated (compile-gated, not just runtime)?
- Is there a backend proxy for API keys, or is the user providing their own key?
- Client-side rate limiting implemented?

### 2.8 — Speech / Voice Journal Integration

- Streaming API (begin → stream → finish) correctly wired end-to-end?
- Session state thread-safe?
- Modern Speech Backend: actual implementation or stub calling legacy?
- Microphone permissions properly requested and handled?
- Error handling for mid-stream failures?
- UITest fake backend properly isolated?
- Audio level processing correct?
- Timeout task properly stored and cancelled?

### 2.9 — Agent Orchestration

- Orchestrator correctly coordinates all agents?
- Initialization order correct?
- Error propagation — graceful degradation if one agent fails?
- reprocessDay triggered after journaling?
- Agent results correctly delivered to UI?
- Is the orchestrator an `actor` (not `@MainActor`) for non-UI work?
- Are agents using `@ModelActor` for SwiftData access?

### 2.10 — UI Layer

- All views correctly bind to view models?
- No @MainActor properties accessed from background threads?
- Onboarding flow complete? Completion state persisted?
- Navigation correct between all screens?
- Loading, error, empty states handled in every view?
- Design system consistently applied? Dynamic Type supported (no hardcoded font sizes)?
- Liquid Glass / Glass Effect using APIs valid for resolved deployment target? **Search Apple docs before evaluating.**
- Consent banner correctly shown/hidden?
- Safety card displayed for crisis content? Includes locale-appropriate crisis resources (988 for US users) + professional help disclaimer?
- Medical disclaimer visible in onboarding + settings + coach?
- AI-generated content labeled ("AI" badge on chat messages)?
- Score methodology disclosed?
- All UI test environment flags work correctly?

### 2.11 — Concurrency and Thread Safety

- Audit every actor, @MainActor, @ModelActor, @Sendable, nonisolated annotation.
- Any @unchecked Sendable? Justified or masking bugs?
- Data races in shared mutable state?
- Persistence operations on correct contexts?
- Speech session correctly serialized?
- Deadlock risks in async/await patterns?
- Task/Task.detached used correctly? Unstructured concurrency leaks?
- NSLock usage forcing @unchecked Sendable? (Prefer actor confinement instead.)

### 2.12 — Error Handling and Edge Cases

- All try calls properly caught? Silently swallowed errors?
- Force unwraps (!) — list every one and assess crash risk.
- Force casts (as!) — justified?
- First launch with no data — cold-start complete?
- No internet — graceful degradation with offline indicator?
- HealthKit fully denied — handled?
- API key missing — handled?
- Timeout handling for all async operations?

### 2.13 — Security and Privacy

- PII redaction before ALL cloud transmissions?
- NSFileProtectionComplete on all PHI stores?
- Keychain access control appropriate?
- All PrivacyInfo.xcprivacy manifests correct and consistent?
- Entitlements match actual capabilities?
- No hardcoded secrets in source?
- Cloud consent checked at every transmission point?
- Data deletion capability exists (GDPR/CCPA right to erasure)?

### 2.14 — Build Configuration and Deployment

- xcconfig properly structured?
- Schemes correctly configured for Debug/Release?
- Deployment target resolved from build settings and used consistently in critique?
- Info.plist coverage verified (direct file and/or `INFOPLIST_KEY_*` generated entries)?
- Protected-resource usage strings present and non-empty:
  - `NSHealthShareUsageDescription`
  - `NSHealthUpdateUsageDescription`
  - `NSMicrophoneUsageDescription`
  - `NSSpeechRecognitionUsageDescription`
- Package.resolved versions appropriate? Outdated or vulnerable?
- App target correctly linked to all packages?
- All resources (mlmodel, xcprivacy, xcassets, storekit) correctly included?
- Build number auto-incrementing?
- UserDefaults keys centralized (not raw strings)?

### 2.15 — Test Quality and Coverage

- Tests testing current behavior or outdated?
- False-positive tests (pass but test wrong thing)?
- Critical paths with zero coverage?
- Test helpers correct and sufficient?
- Gate-numbered tests correspond to actual gates?

### 2.16 — Calculations and Business Logic

- Wellbeing score formula correct? Weights reasonable? Missing metrics handled?
- Baseline statistics numerically stable?
- Z-score: (value - mean) / stddev correct? stddev = 0 guarded?
- RecRanker: Bradley-Terry pairwise update correct?
- Evidence scorer logic correct?
- Sentiment aggregation correct?
- State labels correctly mapped to score ranges?

### 2.17 — Integration Seams (Cross-File Problems)

- Orchestrator → agents: correct API (streaming vs single-call)?
- ViewModel → Orchestrator: correct observation pattern?
- DataAgent → UI: score refresh via notifications working?
- Coach context: correct wellbeing data passed?
- Safety → Coach: interception happens before processing?
- Settings → Runtime Config → Agents: changes propagate?
- App entry point: everything wired correctly?
- Type definitions in shared packages used consistently?

### 2.18 — Accessibility and Dynamic Type

- Accessibility labels/hints on all interactive elements?
- Dynamic Type supported (semantic fonts, not hardcoded sizes)?
- Contrast/legibility risks in glass effects?
- VoiceOver navigation logical on every screen?
- Loading/error/empty states communicated via accessibility, not just visually?
- Strings using `String(localized:)` or hardcoded?

### 2.19 — Memory and Lifecycle Management

- Retain cycles from closures capturing self strongly?
- Combine cancellables stored and cleaned up?
- NotificationCenter observers properly removed?
- Delegates weak where appropriate?
- Excessive memory patterns (large arrays, unbounded caches)?
- File handles, audio sessions, timers cleaned up?
- Task objects cancelled in deinit?
- `@Environment(\.requestReview)` called from a View (not ViewModel)?

### 2.20 — UserDefaults and Local Storage

- Key names consistent (no typos)?
- Type-safe access (enum or @AppStorage)?
- No large data in UserDefaults?
- Migration paths between versions?

### 2.21 — Observability and Logging

- Coherent logging strategy?
- Sensitive info in logs? (API keys, PII, health data)
- Crash reporting (MetricKit / Crashlytics)?
- Analytics events instrumented?
- Errors surfaced to user vs swallowed?

### 2.22 — Networking Resilience

- Retry/backoff for transient failures?
- Connectivity change handling (NWPathMonitor)?
- Timeout configuration for all requests?
- API key rotation handling?
- Session cleanup on key removal?
- URLs constructed safely?

### 2.23 — App Store Review Guidelines (LIGHT CHECK ONLY)

Perform a LIGHT compliance check as part of this technical scan. This is NOT the full guidelines audit — that is done separately via `guidelines_checkV2.md`. Here, only flag obvious compliance issues encountered during the technical analysis:

- Is a medical disclaimer present in any UI view? (yes/no)
- Are there `fatalError()` calls that could crash on launch? (Guideline 2.1 risk)
- Are UITest stubs compile-gated? (Guideline 2.3)
- Are PrivacyInfo.xcprivacy manifests present for all packages?
- Are entitlements minimal and matching actual usage?
- Is cloud consent checked before data transmission?
- Is PII redacted before cloud calls?
- Are crisis resources locale-aware for supported regions (988 for US, correct alternatives elsewhere)?

Do NOT attempt to produce `guidelines_report.md` from this scan. That report is produced by running `guidelines_checkV2.md` separately.

### 2.24 — Production Readiness

- Monetization strategy (StoreKit, paywall, BYOK)?
- Crash reporting (MetricKit minimum)?
- Analytics framework?
- Network reachability monitor?
- Health disclaimer present?
- Data deletion capability (GDPR)?
- Onboarding persistence?
- Localization readiness?
- Persistence migration strategy?
- App rating prompt?
- Build versioning strategy?

### 2.25 — Architecture Design Review

- **Technology stack fitness**: Is each technology choice (persistence, vector store, ML pipeline, LLM integration, speech, state management) the right tool for the job? Would alternatives be better?
- **Package assessment**: Each package justified? Dependencies optimal?
- **Agent architecture**: Agent pattern appropriate? Any agents that are just functions? God objects?
- **Dependency injection**: Consistent DI or mixed with singletons? Composition root?
- **God objects**: Files over 500 lines? Over 1000 lines? Types with 3+ concerns?
- **Concurrency architecture**: Coherent model? Agents on correct isolation domains?
- **Data flow**: Clear pipeline or tangled? Single source of truth?
- **Scalability**: Adding new HealthKit types, new agents, new LLM backend — how much changes?

---

### 2.26 — Baseline Comparison With Previous Reports (run BEFORE Phase 3 writes)

If existing output files are present, read and snapshot them before writing anything new. New reports overwrite prior files.

Preflight preference order for baselines:
- Prefer explicit baseline snapshots (`*_PREV.md`) when present.
- If snapshots are absent, read current output files into memory as baseline before writing replacements.

If `master_report.md` already exists:
- Capture prior health score, finding IDs, severities, and key unresolved items.
- Prepare delta metrics for the new report header: [N] fixed, [N] new, [N] regressions, health score change.

If `master_plan_FINAL.md` already exists:
- Capture header progress metadata: `Status`, `Progress`, and `Est. effort`.
- Capture items marked `[x]` and verify whether each is truly fixed in the current code.
- Preserve completion dates on checked items (`[x] *(YYYY-MM-DD)`).
- Any checked item still broken = regression finding in the new report.
- Snapshot project-specific plan sections so they can be preserved in the regenerated plan:
  - `## READ THIS FIRST`
  - `## Project Context`
  - `## Rules for AI Agents` (both DO and DO NOT)
  - `### Build & Verify`
- Snapshot structural execution sections so the regenerated plan keeps project execution shape:
  - `## Architecture Decisions (Confirmed)` with decision IDs (`D1`, `D2`, ...)
  - Per-phase metadata blocks (`Goal`, `Effort`, `Branch`, `Requires`)
  - Subphase headings (`0.1`, `0.2`, `1.1`, ...)
  - Per-phase completion gates (`### Phase N Done When`)
- Treat these as project policy/baseline, not disposable prose. Keep them unless there is concrete evidence they are outdated.

If `guidelines_report.md` already exists:
- Ingest current compliance status (PASS/FAIL/AT RISK) so unresolved compliance work is included in `master_plan_FINAL.md`.
- If a prior snapshot such as `guidelines_report_PREV.md` exists, compare status transitions and note improvements/regressions.

---

## PHASE 3: REPORT GENERATION

### 3A — Write `master_report.md`

Write technical findings to `master_report.md` in the project root. Follow this exact structure:

```
# Pulsum Master Technical Analysis Report

Generated: [date]
Deployment Target (resolved): [from build settings]
Files Analyzed: [count]
Total Findings: [count]
Overall Health Score: [0-10]

## Executive Summary

## If You Only Fix 5 Things, Fix These

## App Understanding

## Critical Issues (CRIT-001, CRIT-002, ...)
Each with: Severity, Category, Files, Effort (S/M/L), Description, Impact, Evidence, Suggested Fix, Cross-File Impact, Verification, Regression Test

## High-Priority Issues (HIGH-001, ...)
Same format.

## Medium-Priority Issues (MED-001, ...)
## Low-Priority Issues (LOW-001, ...)

## Architecture Design Review (ARCH-001, ...)
Including architecture score card.

## Production-Readiness Findings (PROD-001, ...)
Including production readiness score card.

## Stubs and Incomplete Implementations (STUB-001, ...)
## Calculation and Logic Audit (CALC-001, ...)
## Integration Map (table: connection, status, issue, files)
## Test Coverage Gaps (GAP-001, ...)
## End-to-End Flow Breakpoints (per major user flow)
## Summary Table (all findings in one table)
```

If Phase 2.26 had baseline data, include a delta summary at the top of `master_report.md`: findings fixed, new findings, regressions, and health score change. If no baseline exists, state that explicitly.

### 3B — Write `master_plan_FINAL.md`

**Before generating the plan, read `guidelines_report.md` if it exists.** It contains App Store compliance findings (PASS/FAIL/AT RISK) that must be included in the plan as compliance fix items alongside the technical fixes. If it doesn't exist, note in the plan: "Guidelines report not available — run guidelines_checkV2.md first for compliance items."

Generate an actionable remediation plan. Follow this structure:

```
# Pulsum — Master Remediation Plan

Status: [carry forward previous value if available] | Progress: [preserve completed/total from previous plan, then update] | Est. effort: [recomputed range]

## Plan Delta Since Previous Scan (table)
Columns: `Category` | `Count` | `Items`
Rows:
- Added this scan
- Removed this scan
- Regressions (previously done, now broken)
- Re-opened items
- Unchanged items

## READ THIS FIRST
- Critical execution warnings
- SwiftData concurrency rules (@ModelActor pattern)
- Technical guardrails (NSLock conflicts, @MainActor placement, @Environment(\.requestReview))
- Reference file table (master_report.md, guidelines_report.md)

## Project Context (table)
## Rules for AI Agents (DO / DO NOT)
## Build & Verify commands

## Architecture Decisions (Confirmed)
Use stable decision IDs (`D1`, `D2`, ...). If a previous plan has this table, preserve IDs and only edit decisions that changed with evidence.

## Phase 0: Architecture Foundation
Goal: [one sentence]
Effort: [range]
Branch: [branch name]
Requires: [prerequisite]
### 0.1 — [subphase]
### 0.2 — [subphase]
### Phase 0 Done When:
- [ ] [exit criterion]

## Phase 1: Safety & Critical Bugs
Goal: [one sentence]
Effort: [range]
Branch: [branch name]
Requires: [prerequisite]
### 1.1 — [subphase]
### 1.2 — [subphase]
### Phase 1 Done When:
- [ ] [exit criterion]

## Phase 2: Concurrency & Cleanup
Goal: [one sentence]
Effort: [range]
Branch: [branch name]
Requires: [prerequisite]
### 2.1 — [subphase]
### 2.2 — [subphase]
### Phase 2 Done When:
- [ ] [exit criterion]

## Phase 3: Production Readiness + Tests
Goal: [one sentence]
Effort: [range]
Branch: [branch name]
Requires: [prerequisite]
### 3.1 — [subphase]
### 3.2 — [subphase]
### Phase 3 Done When:
- [ ] [exit criterion]

Each item: [ ] **P[phase]-[number]** | [Finding ID or GL-ID] | [Title]
  File: [path]
  Problem: [what's wrong]
  Fix: [what to do]
  Verify: [exact build/test/manual check proving done]
  Depends on: [optional P-item IDs]
  Source: [master_report finding ID and/or guidelines_report guideline ID]

## Progress Tracker (table)
## Intentionally Deferred to v1.1 (table)
## Finding ID Quick Reference (table)
```

If a previous `master_plan_FINAL.md` exists, compare completed items (`[x]`) against current findings. Items marked done that still have issues should be flagged as **regressions**.

If a previous `master_plan_FINAL.md` exists, preserve project-specific operational content:
- Keep `READ THIS FIRST`, `Project Context`, `Rules for AI Agents`, and `Build & Verify` sections by default.
- Keep `Architecture Decisions (Confirmed)` with stable decision IDs (`D1`, `D2`, ...) by default.
- Keep phase metadata (`Goal`, `Effort`, `Branch`, `Requires`), subphase headings, and `Phase N Done When` blocks by default.
- Keep checked completion state and dates (`[x] *(YYYY-MM-DD)`) unless an item regressed.
- Update only lines that are objectively outdated based on current repo state (tooling, commands, package names, deployment target, architecture decisions).
- If you change preserved content, add a short note like: "Updated from previous plan: [reason]".
- If the previous plan is missing any of these sections, generate them from current project evidence (not generic boilerplate).
- Always include a `Plan Delta Since Previous Scan` table summarizing added/removed/regressed/re-opened/unchanged items.

Compliance traceability requirements for the plan:
- Every compliance item must use a `GL-*` identifier (for example `GL-1.4.1`) and cite `guidelines_report.md` as source evidence.
- Every compliance fix item must map to a concrete file change and verification step.

---

## EXECUTION RULES

1. **Use subagents aggressively.** This audit covers 100+ files and 25+ analysis dimensions. Launch subagents in parallel to read files by package (one agent per package) and analyze independent dimensions simultaneously. Do NOT read files sequentially when parallel reads are available. Write the two deliverables after analysis (sequentially) so overwrite/comparison logic stays deterministic.
2. **Discover files dynamically.** Do NOT rely on a hardcoded file list. The codebase changes between scans. Glob for `**/*.swift`, `**/*.entitlements`, `**/*.xcprivacy`, `**/Package.swift`, etc.
3. **Do not stop until both deliverables are written.** Read every file. Analyze every dimension. Write master_report.md and master_plan_FINAL.md. (guidelines_report.md is produced by a separate `guidelines_checkV2.md` run.)
4. **Do not replace full reads with summaries.** Read files fully first; `_scan_notes.md` digests are required supplements for cross-file reasoning.
5. **Trace across boundaries.** A function's signature might look correct in isolation but be called with wrong arguments from another file. Verify both sides of every integration point.
6. **Be specific.** Every finding must reference exact file paths, line numbers or code snippets. "The code could be improved" is not a finding. "BaselineMath.swift line 47 divides by count which can be 0 when no HealthKit data exists, causing NaN to propagate" is a finding.
7. **Group and number findings.** Every finding gets a unique ID: CRIT-001, HIGH-001, MED-001, LOW-001, ARCH-001, PROD-001, STUB-001, CALC-001, GAP-001.
8. **The reports must be actionable.** Someone should be able to take master_plan_FINAL.md, go through it item by item, and fix every issue without needing additional context.
9. **Do not fabricate issues.** Only report problems you can prove from code. If suspicious but unconfirmed, note as "Needs Verification."
10. **Read test files too.** Mismatches between test expectations and actual implementation are findings.
11. **Check persistence model carefully.** Whether Core Data or SwiftData: entity/model names, attribute types, relationships, indexes must match what the Swift code expects.
12. **Use web search for evolving APIs.** SwiftData, Foundation Models, Liquid Glass, and SwiftUI change rapidly. Search Apple developer docs before assuming any API shape is correct.
13. **Check @ModelActor patterns.** If SwiftData is used, verify that actors owning ModelContext use `@ModelActor`, not manual `ModelContext(container)` stored as properties.
14. **Verify @MainActor placement.** Only ViewModels should be @MainActor. Agents, services, and orchestrators doing computation should be actors or Sendable types, NOT @MainActor.
15. **Do not ask for confirmation.** Do not say "should I continue?" or "would you like me to look at more files?" Just keep going.
16. **Validate your own findings.** Before reporting a bug, re-read the relevant code to confirm. Cross-reference with tests — if a test already covers the behavior you think is broken, verify the test is correct before assuming the code is wrong.
17. **Always ingest AGENTS.md constraints if present.** They are part of project truth and can override generic assumptions.
18. **Treat binary artifacts with the Phase 0.6 protocol.** Verify presence and inclusion; do not fabricate byte-level analysis.
19. **Parallel safety rule.** If using subagents in parallel, do not let subagents write shared files (`_scan_notes.md`, `_scan_progress.md`) directly. Each subagent must write to its own file or return results to the primary agent, and the primary agent merges updates sequentially.
