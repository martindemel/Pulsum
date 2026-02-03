# Unhealthy Files & Structure Report
Generated: 2026-02-02T19:38:55
Source: `/Users/martin.demel/Desktop/PULSUM/Pulsum/Docs/unused-files-report.md`

## Summary
- Scope: runtime risk + repo hygiene.
- This report derives from `Docs/unused-files-report.md` plus targeted verification of high-risk items.

## Criteria
- **Critical**: likely to break build/runtime or indicate misconfigured target membership.
- **High**: impacts app size/shipping risk or bundles unused resources into the app.
- **Medium**: repo hygiene issues that cause churn or developer friction.
- **Low/Informational**: unused support docs/assets; not runtime blockers.

## Critical Findings
### App entry point not referenced by Xcode project
Files: `Pulsum/PulsumApp.swift`
Evidence:
- No `PulsumApp.swift` reference found in `Pulsum.xcodeproj/project.pbxproj`.
Why this is unhealthy:
- If the app target does not include the SwiftUI `@main` entry point, the build can fail or produce a bundle without a valid launch entry, depending on Xcode target membership.
Safe next steps:
- Open the Pulsum target in Xcode and ensure `Pulsum/PulsumApp.swift` is checked under Target Membership.
- If it is missing, add it to the Pulsum target Sources build phase and commit the pbxproj change.
- Run `xcodebuild -scheme Pulsum -sdk iphoneos` to confirm build succeeds.

## High Findings
### Unused Spline asset bundled into app
Files: `streak_low_poly_copy.splineswift`
Evidence:
- Listed in `PBXResourcesBuildPhase` (bundled into app).
- No references in Swift sources.
Why this is unhealthy:
- Bundling unused binary assets increases app size and may introduce licensing/maintenance risk without any runtime value.
Safe next steps:
- If no UI uses this asset, remove it from `Pulsum.xcodeproj` Resources and delete the file.
- If it should be used, wire it into the relevant view and add a usage reference.

## Medium Findings
### Tracked user-specific Xcode state
Files: `Pulsum.xcodeproj/xcuserdata/martin.demel.xcuserdatad/xcschemes/xcschememanagement.plist`
Evidence:
- User-specific `xcuserdata` file is tracked.
Why this is unhealthy:
- These files are per-developer and cause noisy diffs/merge conflicts. They should be ignored and untracked.
Safe next steps:
- Remove the file from git history and add a `.gitignore` rule for `**/xcuserdata/**` if not already present.

### Large generated artifacts tracked in repo
Files: `_git_tracked_files.txt`, `_project_focus_files.txt`, `_project_tree.txt`, `baseline 5_2/baseline_5_2.md`, `baseline 5_2/baseline_appendix_5_2.md`, `baseline 5_2/baseline_file_inventory_5_2.json`
Evidence:
- Examples: `codex_inventory.json`, `coverage_ledger.json`, `files.zlist`, `sha256.txt`, baseline exports.
Why this is unhealthy:
- These files are generated snapshots. Keeping them tracked bloats the repo and creates churn without runtime benefit.
Safe next steps:
- If these are only for auditing, move them to `Docs/` or an external archive and untrack them.
- If required by CI, document them in `Docs/` and keep the minimal set.

## Low / Informational Findings
### Unused support Swift file
Files: `ios support files/glow.swift`
Evidence:
- No references in Swift sources or Xcode project.
Why this is unhealthy:
- Unused code in support directories can confuse future changes and suggests incomplete cleanup.
Safe next steps:
- Remove the file if it is not planned for use, or move it into a package/module and add references.

### Placeholder file in repo root
Files: `testfile`
Evidence:
- No references in code or build config.
Why this is unhealthy:
- Placeholder files add noise and can confuse audits.
Safe next steps:
- Delete the file if no longer needed.

### Large support assets and PDFs are not used by build/test
Files: `main.gif`, `export 2.md`, `Docs/a-practical-guide-to-building-with-gpt-5.pdf`, `a-practical-guide-to-building-agents.pdf`, `ios support documents/Landmarks_ Building an app with Liquid Glass _ Apple Developer Documentation.pdf`
Evidence:
- Listed in Top 10 Largest Non-Build/Test Candidates.
Why this is unhealthy:
- They do not affect the app runtime but increase repo size and slow clone/CI steps.
Safe next steps:
- Archive externally if not needed for active work.

## Expected / Non-Issues
- Core Data bundle internals in SwiftPM resources: `Packages/PulsumData/Sources/PulsumData/Resources/Pulsum.xcdatamodeld/.xccurrentversion`, `Packages/PulsumData/Sources/PulsumData/Resources/PulsumCompiled.momd/Pulsum.omo`, `Packages/PulsumData/Sources/PulsumData/Resources/PulsumCompiled.momd/VersionInfo.plist`
  - Listed as SwiftPM resources in `Packages/PulsumData/Package.swift`.
  - These files are part of the packaged Core Data model and are expected to be unreferenced by name at runtime.
- Podcast dataset is loaded by bundle scan: `podcastrecommendations 2.json`
  - Included in app Resources (pbx).
  - Library importer scans for JSON resources by extension.
  - `LibraryImporter` loads all JSON resources; explicit references are not required.

## Appendix: Unused Candidates
- `Pulsum/PulsumApp.swift` (tracked: yes, size: 671.0 B, modified: 2026-01-23T15:37:50)
- `ios support files/glow.swift` (tracked: yes, size: 4.5 KB, modified: 2025-10-06T23:00:11)
- `testfile` (tracked: yes, size: 2.0 B, modified: 2025-10-25T21:29:38)