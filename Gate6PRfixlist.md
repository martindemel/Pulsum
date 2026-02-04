You are Codex, swift ios architect based on GPT-5. You are running as a coding agent in the Codex CLI on a user's computer.

# Mission

Make PR #12 “Gate 6: aggregate HealthKit ingestion and bootstrap fallback” ready to **Squash & Merge** by fixing the **gate-tests CI failure** and addressing the highest‑impact review findings (CodeRabbit + Codex) with **targeted, minimal, behavior‑safe changes**.

# Progress Tracker (2026-02-03)
- P0.1 SentimentAgent Sendable/Core Data captures: ✅ Done (removed `@Sendable` capture lists on `context.perform` closures).
- P0.2 Deployment target warnings: ⚠️ Deferred with rationale documented in `POST_FIX_AUDIT.md`.
- P0.3 Remove unrelated doc `GPT 5.2 prompt guide 12_11_2025.md`: ✅ Done (removed from git).
- P0.4 Baseline missing `gpt5_1_prompt_guide.md`: ✅ Done (restored from commit `de3fc109d666173aa8fa94f6e6325f9eba4a7c90`).
- P1.1 HealthKit permission correctness: ✅ Done (denied stays denied; updated Gate3 health access test).
- P1.2 Reprocess pending journal embeddings: ✅ Done (retry hook already in orchestrator/foreground; added recovery test).
- P1.3 DebugLogBuffer consolidation: ✅ Already consolidated in `PulsumTypes` (no duplicate file).
- P1.4 SafetyLocal degraded semantics: ✅ Done (release warning for empty prototypes; no degraded flag on runtime embedding failures).
- P2.1 Deletion-only HealthKit aggregate invalidation: ✅ Done (clear cached aggregates on deleted samples).
- P2.2 EmbeddingService variable shadowing: ✅ Done.
- P2.3 CoachAgent diagnostics span leak: ✅ Done.
- P2.4 HealthKitService loop boundary: ✅ Already consistent (no change).
- P2.5 SettingsView clipboard on macOS: ✅ Done.
- P2.6 SettingsViewModel stale debug fields: ✅ Done.
- P3.1 FreshnessBus test strength: ✅ Done (explicit >=1 + debounce note).
- P3.2 SettingsViewModelHealthAccessTests polling: ✅ Done.
- P3.3 PulsumRootViewTests no-op assertion: ✅ Done (constructs view).
- P3.4 BackfillStateStoreSpy thread safety: ✅ Already thread-safe (NSLock).
- P3.5 CoachAgentKeywordFallbackTests save assertion: ✅ Done.
- P3.6 Markdownlint fixes: ✅ Done (baseline progress fences/headings, README headings, POST_FIX_AUDIT fences/tabs, baseline.md hyphen).

# Non‑negotiables

* Do not add new product features; do not expand Gate 6 scope beyond fixes listed in this prompt.
* Prefer minimal, surgical edits; preserve existing behavior unless the fix explicitly requires change.
* Swift 6 strict concurrency must pass; do not silence warnings/errors with broad `@preconcurrency` or widespread `@unchecked Sendable` in production code.
* No destructive git commands like `git reset --hard` or `git checkout --`.
* Do not ask me to clarify unless you are truly blocked; otherwise choose the simplest valid interpretation and proceed.
* Do not use `/mnt/data` paths; assume you’re in the repo working copy.
* i have created Gate6PRfixlist.md which is copy of this entire prompt with details, where you must track the progress of the implementation of all the items that needs to be fixed. that way you will not lose track of the progress. you can update the docuemnt accordingly.

# What is failing (from GitHub Actions gate-tests)

* Build fails with Swift 6 strict concurrency errors in `Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift`.

* Errors (must be eliminated):

  * `SentimentAgent.swift:149:24` capture of `context` (`NSManagedObjectContext`) in an `@Sendable` closure.
  * `SentimentAgent.swift:203:44` capture of `context` (`NSManagedObjectContext`) in an `@Sendable` closure.
  * `SentimentAgent.swift:282:47` capture of `context` (`NSManagedObjectContext`) in an `@Sendable` closure.
  * `SentimentAgent.swift:294:92` implicit capture of `context` requires `NSManagedObjectContext: Sendable`.

* CI also shows warnings like:

  * “iOS Simulator deployment target IPHONEOS_DEPLOYMENT_TARGET is set to 26.0, but supported deployment target versions are 12.0 to 18.5.99”
  * Treat these as “fix if feasible without opening a can of worms”; do not ignore if it might mask real CI fragility.

# Workflow (do this, but don’t write a long upfront plan)

* First, reproduce the failure locally with the same entrypoint as CI (prefer `scripts/ci/integrity.sh` if present; otherwise use `xcodebuild` and package tests).
* Fix the P0 build blocker first; rerun the same command until green.
* Then address the P0/P1 issues below in priority order, verifying with targeted tests after each group.
* End with a concise “changes + verification” summary with file references and commands run.

# P0 — Build blockers (must fix)

## P0.1 Fix Swift 6 Sendable/Core Data captures in SentimentAgent

* File: `Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift`
* Locations: `:149`, `:203`, `:282`, `:294`
* Goal: remove all captures of `NSManagedObjectContext` inside `@Sendable` closures and eliminate the implicit capture error.

Implementation requirements (choose the smallest refactor that is correct):

* Identify which closure is `@Sendable` at each location (common culprits: `Task.detached`, `TaskGroup.addTask`, `Task {}` closures, async callbacks imported as `@Sendable`).
* Refactor so Core Data work happens on the context’s queue without “sending” a context across concurrency boundaries.
* Use Core Data safe patterns:

  * Pass `NSManagedObjectID` (and plain value types) across tasks, not `NSManagedObject` or `NSManagedObjectContext`.
  * Perform fetch/create/update inside `context.perform { ... }` or a dedicated “CoreData executor/actor” that owns the context.
* Do not “paper over” by marking `NSManagedObjectContext` as sendable via unsafe tricks.
* After changes, scan for any new strict concurrency diagnostics in this file and the module; fix them.

Acceptance criteria:

* `xcodebuild` (or the repo CI build command) succeeds for the `Pulsum` scheme.
* `swift test --package-path Packages/PulsumAgents --filter Gate6_` passes.
* No remaining “capture of context with non-sendable type” errors anywhere in the build logs.

## P0.2 Decide what to do about IPHONEOS_DEPLOYMENT_TARGET warnings

* Files likely involved: `Pulsum.xcodeproj` settings and multiple package `Package.swift` files in `Packages/*/Package.swift`.
* Goal: eliminate the mismatch warnings if it can be done safely; if the repo intentionally targets 26.0, document the rationale and make CI coherent.

Constraints:

* Do not change the min deployment target if it would require large availability annotation work in many files.
* If you change deployment targets, rerun the same CI build command to ensure nothing regresses.

Acceptance criteria:

* Either warnings are removed, or you leave a short, concrete note in `POST_FIX_AUDIT.md` explaining why the warning is intentionally tolerated and why it’s safe.

# P0 — PR hygiene blockers (must fix)

## P0.3 Remove unrelated document from this PR

* File: `GPT 5.2 prompt guide 12_11_2025.md`
* Problem: CodeRabbit flagged as unrelated to Gate 6 Swift/HealthKit changes.
* Action: remove it from this branch/PR (revert the commit that added it or `git rm` it) and ensure no other unrelated docs were accidentally swept in.

Acceptance criteria:

* The file is not present in the PR diff for Gate 6.

## P0.4 Fix “missing file” integrity issue in baseline docs

* File: `baseline 5_2/baseline_5_2.md` mentions `gpt5_1_prompt_guide.md` missing and references commit `de3fc109d666173aa8fa94f6e6325f9eba4a7c90`.
* Action: either restore `gpt5_1_prompt_guide.md` from that commit into the repo, or remove all references and ensure it is explicitly untracked (use `git rm --cached` if needed).

Acceptance criteria:

* No baseline doc claims a tracked file is missing; `git ls-files` and baseline file lists agree.

# P1 — High-impact correctness fixes from Codex/CodeRabbit

## P1.1 HealthKit permission correctness

* File: `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`
* Issue (Codex P1): logic that treats `.sharingDenied` as granted when `HKAuthorizationRequestStatus.unnecessary` is returned.
* Fix: `.unnecessary` means “user already responded”, not “granted”; ensure denied stays denied and UI/debug reflects it.

Acceptance criteria:

* Denied types do not populate a “granted” set.
* Any downstream ingestion/observers are not started for denied types.
* Existing tests (or add a small new one) cover “denied + unnecessary” and confirm it remains denied.

## P1.2 Reprocess pending journal embeddings after failures

* File: `Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift`
* Issue (Codex P1): `embeddingPending = true` is set when embeddings unavailable, but pending journals are never retried; `reprocessPendingJournals()` exists but is unused.
* Fix: wire a retry hook that runs:

  * On app startup, or
  * When embedding availability transitions from unavailable → available, or
  * On a safe periodic timer/backoff.
* Avoid runaway background loops; make it bounded and observable (logging consistent with repo patterns).

Acceptance criteria:

* A journal saved while embeddings are unavailable eventually gets embedded and indexed once embeddings return.
* Add or update a test that simulates embedding failure then recovery and confirms pending entries are reprocessed.

## P1.3 Consolidate duplicate DebugLogBuffer

* Files:

  * `Packages/PulsumTypes/Sources/PulsumTypes/DebugLog.swift`
  * `Packages/PulsumAgents/Sources/PulsumAgents/DebugLogBuffer.swift`
* Issue (CodeRabbit major): two public `DebugLogBuffer` actors with different line limits; logs may split; ISO8601DateFormatter created per append is inefficient.
* Fix: consolidate into one canonical implementation (prefer `PulsumTypes` as shared), make the other module re-export or delete duplicate, and cache the formatter.

Acceptance criteria:

* Only one shared implementation exists and is used throughout.
* Formatter is reused (static stored property or equivalent).
* All builds and tests pass.

## P1.4 SafetyLocal degraded-mode visibility and semantics

* File: `Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift`
* Issues (CodeRabbit major):

  * Degraded keyword-only mode warning is inside `#if DEBUG`; should be visible in release for safety visibility.
  * `degraded = true` is set for runtime embedding failures, conflating “prototype missing” with “embedding failed”, causing unnecessary prototype refresh.
* Fix:

  * Emit warning when prototypes are empty in release builds too.
  * Only set `degraded = true` when prototypes are actually missing; track runtime embedding failures separately if needed.

Acceptance criteria:

* Release builds log degraded keyword-only mode when prototypes are empty.
* Runtime embedding failures do not incorrectly trigger prototype refresh.
* Tests still pass; add/adjust a small unit test if one exists for degraded behavior.

# P2 — Additional fixes worth doing if still present (verify first; some may already be addressed)

## P2.1 Aggregates correctness on deletion-only HealthKit updates

* File: `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`
* Issue (CodeRabbit + Codex P2): deletion-only anchored updates can leave aggregated step/sleep/nocturnal values stale because recompute paths are skipped.
* Fix options (pick the simplest correct):

  * If deletions affect steps/sleep/nocturnal HR days, re-fetch aggregates for those days, or
  * Clear aggregated cached fields for affected days so later computation falls back and refreshes.

Acceptance criteria:

* A deletion-only update cannot leave the daily aggregated totals permanently inflated.
* Add a focused unit test if feasible (stub deletion update triggers invalidation).

## P2.2 EmbeddingService variable shadowing

* File: `Packages/PulsumML/Sources/PulsumML/Embedding/EmbeddingService.swift`
* Issue (minor): inner `for index in 0..<dimension` shadows outer `index` from `enumerated()`, breaking debug log accuracy.
* Fix: rename inner loop variable to `i` (or similar) and log correct segment index.

Acceptance criteria:

* No shadowing; log prints the segment index.

## P2.3 CoachAgent diagnostics span not closed on early return

* File: `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift`
* Issue: span opened before checking candidates, early return leaks span.
* Fix: `defer` to close span or explicitly end it before the guard return.

Acceptance criteria:

* Span always ends, even when candidates is empty.

## P2.4 HealthKitService loop boundary correctness

* File: `Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift`
* Issue: loop condition uses `endDate` but computes `endBoundary`; final day can be skipped if `endDate` is at midnight.
* Fix: iterate using `endBoundary` consistently.

Acceptance criteria:

* Behavior matches stub logic; add a test or adjust existing ones to cover `endDate` at midnight.

## P2.5 SettingsView clipboard support on macOS

* File: `Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift`
* Issue: `copyToClipboard` is UIKit-only; copy buttons no-op on macOS.
* Fix: add `#if canImport(AppKit)` branch using `NSPasteboard`.

Acceptance criteria:

* Clipboard copy works on both platforms or copy UI is hidden/disabled on macOS with an explicit rationale.

## P2.6 SettingsViewModel stale debug fields when orchestrator is nil

* File: `Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift`
* Issue: early return leaves stale debug summary/log snapshot.
* Fix: clear `healthKitDebugSummary` and `debugLogSnapshot` (and related fields) when orchestrator is missing.

Acceptance criteria:

* UI does not show stale debug content when orchestrator disappears.

# P3 — Test and docs quality (do if quick; required if CI runs linters)

## P3.1 Strengthen tests that can pass on total failure

* File: `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate3_FreshnessBusTests.swift`
* Issue: assertion allows `posts.count == 0`.
* Fix: assert `>= 1`, validate `userInfo` contains expected day, and document debounce window if sleep remains.

Acceptance criteria:

* Test fails if notifications are never posted; validates correct day.

## P3.2 Replace fixed sleeps with deterministic polling in async tests

* File: `Packages/PulsumUI/Tests/PulsumUITests/SettingsViewModelHealthAccessTests.swift`
* Fix: polling helper with timeout; remove fixed `Task.sleep`.

Acceptance criteria:

* Test is reliable under slow CI.

## P3.3 Fix PulsumRootViewTests no-op assertion

* File: `Packages/PulsumUI/Tests/PulsumUITests/PulsumRootViewTests.swift`
* Fix: remove `XCTAssertNotNil(PulsumRootView.self)` or replace with meaningful runtime check; if only compile-time check is desired, add a comment explaining why and remove the tautology.

Acceptance criteria:

* Test provides real signal or is explicitly documented.

## P3.4 Make BackfillStateStoreSpy thread-safe

* File: `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate6_WellbeingBackfillPhasingTests.swift`
* Fix: convert spy to `actor` or add lock/queue around `savedState` and `loadStateReturn`.

Acceptance criteria:

* No data races; tests deterministic.

## P3.5 Make Core Data saves fail loudly in tests

* File: `Packages/PulsumAgents/Tests/PulsumAgentsTests/CoachAgentKeywordFallbackTests.swift`
* Fix: replace `try? viewContext.save()` with `XCTAssertNoThrow(try viewContext.save())`.

Acceptance criteria:

* Save failures fail test, not silently swallowed.

## P3.6 Markdownlint fixes if applicable

* Files:

  * `baseline 5_2/baseline_progress_5_2.md:55` add ```text language tag.
  * `baseline 5_2/baseline_progress_5_2.md:327` disambiguate duplicate “Progress Notes” heading.
  * `baseline.md:413` change “self project” to “self-project”.
  * `README.md` convert bold section markers to headings where flagged (MD036).
  * `POST_FIX_AUDIT.md` change fences to ```text and replace hard tabs with spaces (MD040/MD010).
* Also: if `bugs.md` references a missing `HealthKitServiceTests`, either add the test file or remove the stale reference.

Acceptance criteria:

* Any markdownlint job in CI passes; documents remain readable.

# Output requirements (what you must report back after code changes)

* Findings: list remaining issues you fixed, ordered by severity, with file references like `path/to/file.swift:123`.
* Fix summary: short bullets per fix explaining the change and why it is safe.
* Verification: exact commands you ran and whether they passed, including the CI-equivalent build/test command.
* If you decided not to fix something, state why it’s safe to defer and what evidence you gathered.
