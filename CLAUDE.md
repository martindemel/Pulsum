# Pulsum — Project Instructions

## What This Is
iOS 26+ wellness coaching app. Swift 6.1, SwiftUI, SwiftData (migrating from Core Data).

## Package Structure
6 SPM packages with strict dependency direction:
```
PulsumTypes -> PulsumML + PulsumData -> PulsumServices -> PulsumAgents -> PulsumUI -> App
```

## Key Files
- `master_plan_FINAL.md` — **Active remediation plan (USE THIS).** 42 findings (0 CRIT, 4 HIGH, 18 MED, 20 LOW), 6 batches, 41 actionable items.
- `batch_execution_prompts_v3.md` — Self-contained prompts for each batch. Copy-paste into a fresh Claude Code window.
- `master_report.md` — Full technical analysis report (42 findings, health score 8.0/10). Reference for finding details.
- `guidelines_report.md` — App Store compliance checks.

## Git Workflow
- **Small changes** (single-commit fixes, tweaks, config): push directly to `main`
- **Multi-commit or multi-file features**: create a feature branch, open a PR, then merge
- Branch naming: `feature/<short-description>` or `fix/<short-description>`
- Always build-verify before committing
- Commit messages: imperative verb + descriptive phrase (e.g., "Fix VectorIndex hash sharding")
- **Safe point**: Before executing any multi-file plan, commit current working state as a checkpoint so changes can be reverted cleanly

## Build & Test
```bash
# Simulator build (preferred for dev — no signing required)
xcodebuild -scheme Pulsum \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath /tmp/PulsumDerivedData \
  build

# Device build
xcodebuild -scheme Pulsum -sdk iphoneos -derivedDataPath /tmp/PulsumDerivedData

# SPM package tests
swift test --package-path Packages/PulsumML
swift test --package-path Packages/PulsumData
swift test --package-path Packages/PulsumServices
swift test --package-path Packages/PulsumAgents
swift test --package-path Packages/PulsumUI

swiftformat .
scripts/ci/check-privacy-manifests.sh
```

- DerivedData MUST be outside iCloud (`/tmp/PulsumDerivedData`) — iCloud `com.apple.provenance` xattrs break CodeSign
- Available simulators: iPhone 17, iPhone 17 Pro, iPhone 17 Pro Max, iPhone Air (no iPhone 16 series)

## New terms / fast-moving areas you MUST look up when referenced:
- Liquid Glass (new design system / UI material)
- FoundationModels (new framework for Apple foundation models)
- SwiftUI (rapidly evolving; do not assume older patterns are still best)

## Technical Rules
- `@ModelActor` for any actor that owns a SwiftData `ModelContext`
- `@Model` objects are NOT Sendable — return DTO snapshots across actor boundaries
- `PersistentIdentifier` (Sendable/Codable) for cross-actor object references
- `NSFileProtectionCompleteUnlessOpen` (not Complete) — HealthKit background delivery needs DB access while device is locked
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` is per-module. Only PulsumUI and the app target should have it — NOT PulsumML, PulsumData, PulsumServices, PulsumAgents, or PulsumTypes
- Use `Diagnostics.log()` from PulsumTypes for all logging (not `print()`)
- Use `FetchDescriptor` + `#Predicate`, not `NSFetchRequest`
- No `performAndWait` — `@ModelActor` context is actor-isolated

## SwiftData Migration Rules
- Lightweight migration only — no `VersionedSchema` unless explicitly discussed
- New properties on existing `@Model` types require default values
- `@Model` requires fully qualified enum defaults: `DateEntryMethod.dueDate` not `.dueDate`

## Xcode Gotchas
- File-system sync — `.swift` files in source directories are auto-included by Xcode
- `ButtonStyle` ternary (`.glass` vs `.glassProminent`) doesn't compile — use `if/else`
- Never use `fatalError` in `@main` `init` — test host crashes; use graceful fallback
- Stored property named `body` conflicts with SwiftUI `View` — use `content` instead
- `GENERATE_INFOPLIST_FILE` + custom `Info.plist` = "Multiple commands produce" build error

## Testing
- Test naming: `test_[unit]_[scenario]_[expected]`
- Use in-memory SwiftData containers for unit test isolation
- When adding or modifying Services, Models, or data parsing, add or update corresponding unit tests
- Prefer Swift Testing framework for new tests

## Scope Discipline
When executing a **batch or plan-driven prompt** (from `batch_execution_prompts*.md`, `master_plan_FINAL.md`, or any structured remediation/execution plan), follow these rules strictly. During normal interactive sessions (research, debugging, feature work, exploration, ad-hoc requests), use full autonomy and initiative — these constraints do not apply.

- **Only make changes explicitly listed in the prompt.** Do not make "bonus fixes", drive-by refactors, or adjacent improvements — no matter how obvious they seem.
- **If you encounter something unexpected outside the prompt scope** (build warnings, suspicious code, missing files, dead code), **write it in your final summary as an "Observation"** — do NOT fix it. Files may have been intentionally deleted or structured a certain way, and "fixing" it without context can cause regressions.
- **Never restore deleted files.** If a file is missing and something doesn't compile, report the error. Do not recreate files from memory or guesswork — the deletion was likely intentional.
- **When in doubt about scope, report — don't act.** Describe what you see and let the developer decide.

## Do NOT
- Use `@unchecked Sendable` on new code
- Use Combine — use async/await
- Add SPM dependencies without approval
- Store `ModelContext` across `await` boundaries unless `@ModelActor`-owned
- Modify `.xcdatamodeld` — it will be replaced by SwiftData
- Make changes outside the scope of a batch/plan prompt (see Scope Discipline above) — applies during plan-driven execution only, not during normal interactive work
- Restore or recreate deleted files without asking — they may have been intentionally removed
