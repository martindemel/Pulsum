# Pulsum — Project Instructions

## What This Is
iOS 26+ wellness coaching app. Swift 6.1, SwiftUI, SwiftData (migrating from Core Data).

## Package Structure
6 SPM packages with strict dependency direction:
```
PulsumTypes -> PulsumML + PulsumData -> PulsumServices -> PulsumAgents -> PulsumUI -> App
```

## Key Files
- `master_plan_FINAL.md` — Source of truth. 79 remediation items across 4 phases. Read before any architectural work.
- `plan_execution_prompts.md` — Step-by-step prompts for executing the plan. Run in order.
- `master_report.md` — 112 findings with full detail. Look up finding IDs (CRIT-XXX, HIGH-XXX, etc.) here.
- `guidelines_report.md` — App Store compliance checks.

## Build & Test
```bash
xcodebuild -scheme Pulsum -sdk iphoneos -derivedDataPath ./DerivedData
swift test --package-path Packages/PulsumML
swift test --package-path Packages/PulsumData
swift test --package-path Packages/PulsumServices
swift test --package-path Packages/PulsumAgents
swift test --package-path Packages/PulsumUI
swiftformat .
scripts/ci/check-privacy-manifests.sh
```

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

## Do NOT
- Use `@unchecked Sendable` on new code
- Use Combine — use async/await
- Add SPM dependencies without approval
- Store `ModelContext` across `await` boundaries unless `@ModelActor`-owned
- Modify `.xcdatamodeld` — it will be replaced by SwiftData
