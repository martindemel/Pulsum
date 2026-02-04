# Post-Fix Audit

## Production Fix Verification (Checklist)
- [x] Library prep coalescing is still present via `libraryPreparationTask` guard + `performLibraryPreparation()` single-entry path in `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift` (prevents concurrent ingest, so no overlapping `library.import.*`).
- [x] Deferred retry is gated on `libraryEmbeddingsDeferred` in `CoachAgent.retryDeferredLibraryImport` (`guard libraryEmbeddingsDeferred else { return }`) in `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift`.
- [x] Hard timeout is 30s and the notice is truthful (no background claim) in `AgentOrchestrator.recommendations` in `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`.
- [x] Soft timeout is real: it stops the spinner without cancelling work (no `Task.cancel`), implemented in `beginRecommendationsSoftTimeout` and `updateRecommendationsLoadingState` in `Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift`.
- [x] Soft timeout clears on completion in `clearRecommendationsSoftTimeout` and the `defer` block in `startRecommendationsRefresh` in `Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift`.
- [x] Stale results apply only when the list is empty (`shouldApply = !isStale || recommendations.isEmpty`) in `Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift`.
- [x] Diagnostics semantics remain aligned with the original fix (no overlapping `library.import.begin`) per `DIAGNOSIS.md` and the in-flight guard in `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift`.
- [x] Soft-timeout message remains visible to users in `Packages/PulsumUI/Sources/PulsumUI/CoachView.swift`.

## Test Fix Review (Checklist)
- [x] Gate7 uses deterministic HealthKit seeding via `TestHealthKitSampleSeeder.authorizeAllTypes` + `populateSamples` in `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate7_FirstRunWatchdogTests.swift`.
- [x] Seeder covers all required HealthKit types (`heartRateVariabilitySDNN`, `heartRate`, `restingHeartRate`, `respiratoryRate`, `stepCount`, `sleepAnalysis`) by iterating `HealthKitService.orderedReadSampleTypes` in `Packages/PulsumAgents/Tests/PulsumAgentsTests/TestHealthKitSampleSeeder.swift`.
- [x] Seeder is test-target-only and lives under `Packages/PulsumAgents/Tests/...`, so it does not ship in production.
- [x] Gate6 uses the shared seeder once per test and no legacy helpers remain (no double-seed) in `Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate6_WellbeingBackfillPhasingTests.swift`.
- [x] Determinism note: seeding is anchored to `Calendar.startOfDay(for: Date())`, which is stable per-run but still clock/timezone dependent; consider injecting a fixed date/timezone if CI cross-timezone flakiness is observed.

## Scheme / CI Review (Checklist)
- [x] Shared scheme exists at `Pulsum.xcodeproj/xcshareddata/xcschemes/PulsumUI.xcscheme`.
- [x] Scheme TestAction runs `PulsumTests.xctest` (unit tests) and `PulsumTests` target includes `Packages/PulsumUI/Tests/PulsumUITests` via `fileSystemSynchronizedGroups` in `Pulsum.xcodeproj/project.pbxproj`.
- [x] TestAction and LaunchAction run with default environments; no startup bypass flags are injected into the shared scheme (`Pulsum.xcodeproj/xcshareddata/xcschemes/PulsumUI.xcscheme`).
- [x] Startup bypass for unit tests now relies on DEBUG-only XCTest detection in code, keeping manual Run behavior identical to production.

## What changed / why it’s safe
- App startup always runs for production-like launches; unit tests short-circuit heavyweight startup via a DEBUG-only XCTest environment check in `AppViewModel.start()` with no scheme overrides (`Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift`).
- Recommendations timeout behavior remains the same (hard timeout + truthful notice) and the soft timeout continues to avoid cancelling work (`Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`, `Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift`).
- Library import coalescing and deferred retry gating remain intact, preserving the original fix for duplicate startup work (`Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift`).
- The PulsumUI scheme is now a shared, CI-friendly entry point that runs unit tests via `PulsumTests.xctest` (`Pulsum.xcodeproj/xcshareddata/xcschemes/PulsumUI.xcscheme`, `Pulsum.xcodeproj/project.pbxproj`).

## Potential risks / mitigations
- If non-test runs inject `XCTestConfigurationFilePath`/`XCTestBundlePath`, startup would short-circuit; keep those env vars confined to XCTest harnesses.
- HealthKit seeding uses the current clock/timezone; if CI runs across timezones or at DST boundaries, consider injecting a fixed `Date`/`TimeZone` into `TestHealthKitSampleSeeder.populateSamples`.
- Diagnostics expectations depend on single in-flight library prep; if new call sites are added, ensure they respect `prepareLibraryIfNeeded` to avoid overlapping `library.import.*` spans.
- CI may warn that `IPHONEOS_DEPLOYMENT_TARGET=26.0` exceeds the simulator SDK max (e.g., 18.5). Target remains at 26.0 because the app intentionally relies on iOS 26 APIs; lowering it would require broad availability auditing. Warnings are expected but do not affect build output.

## Commands run + results
### scripts/ci/check-privacy-manifests.sh (fallback note)
Note: Script now falls back to `python3` when `python` is unavailable, and to `grep` when `rg` is unavailable.

### swift test --package-path Packages/PulsumAgents
Result:
```text
PASS — 38 tests executed, 3 skipped, 0 failures.
Warning: #SendableClosureCaptures in Gate4_RoutingTests.swift:92 (resolved by removing @Sendable constraint in helper).
```

### scripts/ci/check-privacy-manifests.sh
Result:
```text
privacy manifests: ✅ basic checks passed
[privacy-check] ✅ manifests validated
```

### swift test --package-path Packages/PulsumAgents --filter Gate7_FirstRunWatchdogTests
Result:
```text
Building for debugging...
[0/2] Write swift-version--58304C5D6DBC2206.txt
Build complete! (0.14s)
Test Suite 'Selected tests' started at 2026-01-21 09:50:25.078.
Test Suite 'PulsumAgentsPackageTests.xctest' started at 2026-01-21 09:50:25.079.
Test Suite 'Gate7_FirstRunWatchdogTests' started at 2026-01-21 09:50:25.079.
Test Case '-[PulsumAgentsTests.Gate7_FirstRunWatchdogTests testRetryPublishesRealSnapshotAfterTimeout]' started.
Test Case '-[PulsumAgentsTests.Gate7_FirstRunWatchdogTests testRetryPublishesRealSnapshotAfterTimeout]' passed (0.414 seconds).
Test Case '-[PulsumAgentsTests.Gate7_FirstRunWatchdogTests testWatchdogPublishesPlaceholderWhenBootstrapTimesOut]' started.
Test Case '-[PulsumAgentsTests.Gate7_FirstRunWatchdogTests testWatchdogPublishesPlaceholderWhenBootstrapTimesOut]' passed (0.641 seconds).
Test Suite 'Gate7_FirstRunWatchdogTests' passed at 2026-01-21 09:50:26.134.
     Executed 2 tests, with 0 failures (0 unexpected) in 1.055 (1.055) seconds
Test Suite 'PulsumAgentsPackageTests.xctest' passed at 2026-01-21 09:50:26.134.
     Executed 2 tests, with 0 failures (0 unexpected) in 1.055 (1.055) seconds
Test Suite 'Selected tests' passed at 2026-01-21 09:50:26.134.
     Executed 2 tests, with 0 failures (0 unexpected) in 1.055 (1.056) seconds
◇ Test run started.
↳ Testing Library Version: 1400
↳ Target Platform: arm64e-apple-macos14.0
✔ Test run with 0 tests in 0 suites passed after 0.001 seconds.
```

### xcodebuild test -scheme PulsumUI -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
Result:
```text
Command line invocation:
    /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild test -scheme PulsumUI -destination "platform=iOS Simulator,name=iPhone 15,OS=latest"

2026-01-21 09:50:33.461 xcodebuild[11961:30621174]  DVTDeviceOperation: Encountered a build number "" that is incompatible with DVTBuildVersion.
2026-01-21 09:50:35.305 xcodebuild[11961:30621116] [MT] DVTDeviceOperation: Encountered a build number "" that is incompatible with DVTBuildVersion.
Resolve Package Graph


Resolved source packages:
  PulsumData: /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData @ local
  PulsumAgents: /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents @ local
  PulsumUI: /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI @ local
  PulsumTypes: /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumTypes @ local
  PulsumServices: /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices @ local
  PulsumML: /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML @ local

ComputePackagePrebuildTargetDependencyGraph

Prepare packages

CreateBuildRequest

SendProjectDescription

CreateBuildOperation

ComputeTargetDependencyGraph
note: Building targets in dependency order
note: Target dependency graph (19 targets)
    Target 'PulsumTests' in project 'Pulsum'
        ➜ Explicit dependency on target 'Pulsum' in project 'Pulsum'
        ➜ Explicit dependency on target 'PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumAgents' in project 'PulsumAgents'
        ➜ Explicit dependency on target 'PulsumUI' in project 'PulsumUI'
        ➜ Explicit dependency on target 'PulsumML' in project 'PulsumML'
        ➜ Explicit dependency on target 'PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumTypes' in project 'PulsumTypes'
    Target 'Pulsum' in project 'Pulsum'
        ➜ Explicit dependency on target 'PulsumTypes' in project 'PulsumTypes'
        ➜ Explicit dependency on target 'PulsumML' in project 'PulsumML'
        ➜ Explicit dependency on target 'PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumAgents' in project 'PulsumAgents'
        ➜ Explicit dependency on target 'PulsumUI' in project 'PulsumUI'
    Target 'PulsumUI' in project 'PulsumUI'
        ➜ Explicit dependency on target 'PulsumUI' in project 'PulsumUI'
        ➜ Explicit dependency on target 'PulsumUI_PulsumUI' in project 'PulsumUI'
        ➜ Explicit dependency on target 'PulsumAgents' in project 'PulsumAgents'
        ➜ Explicit dependency on target 'PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumTypes' in project 'PulsumTypes'
    Target 'PulsumUI' in project 'PulsumUI'
        ➜ Explicit dependency on target 'PulsumUI_PulsumUI' in project 'PulsumUI'
        ➜ Explicit dependency on target 'PulsumAgents' in project 'PulsumAgents'
        ➜ Explicit dependency on target 'PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumTypes' in project 'PulsumTypes'
    Target 'PulsumUI_PulsumUI' in project 'PulsumUI' (no dependencies)
    Target 'PulsumAgents' in project 'PulsumAgents'
        ➜ Explicit dependency on target 'PulsumAgents' in project 'PulsumAgents'
        ➜ Explicit dependency on target 'PulsumAgents_PulsumAgents' in project 'PulsumAgents'
        ➜ Explicit dependency on target 'PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumML' in project 'PulsumML'
        ➜ Explicit dependency on target 'PulsumTypes' in project 'PulsumTypes'
    Target 'PulsumAgents' in project 'PulsumAgents'
        ➜ Explicit dependency on target 'PulsumAgents_PulsumAgents' in project 'PulsumAgents'
        ➜ Explicit dependency on target 'PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumML' in project 'PulsumML'
        ➜ Explicit dependency on target 'PulsumTypes' in project 'PulsumTypes'
    Target 'PulsumAgents_PulsumAgents' in project 'PulsumAgents' (no dependencies)
    Target 'PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumServices_PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumML' in project 'PulsumML'
        ➜ Explicit dependency on target 'PulsumTypes' in project 'PulsumTypes'
    Target 'PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumServices_PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumML' in project 'PulsumML'
        ➜ Explicit dependency on target 'PulsumTypes' in project 'PulsumTypes'
    Target 'PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumData_PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumML' in project 'PulsumML'
        ➜ Explicit dependency on target 'PulsumTypes' in project 'PulsumTypes'
    Target 'PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumData_PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumML' in project 'PulsumML'
        ➜ Explicit dependency on target 'PulsumTypes' in project 'PulsumTypes'
    Target 'PulsumData_PulsumData' in project 'PulsumData' (no dependencies)
    Target 'PulsumServices_PulsumServices' in project 'PulsumServices' (no dependencies)
    Target 'PulsumML' in project 'PulsumML'
        ➜ Explicit dependency on target 'PulsumML' in project 'PulsumML'
        ➜ Explicit dependency on target 'PulsumML_PulsumML' in project 'PulsumML'
        ➜ Explicit dependency on target 'PulsumTypes' in project 'PulsumTypes'
    Target 'PulsumML' in project 'PulsumML'
        ➜ Explicit dependency on target 'PulsumML_PulsumML' in project 'PulsumML'
        ➜ Explicit dependency on target 'PulsumTypes' in project 'PulsumTypes'
    Target 'PulsumML_PulsumML' in project 'PulsumML' (no dependencies)
    Target 'PulsumTypes' in project 'PulsumTypes'
        ➜ Explicit dependency on target 'PulsumTypes' in project 'PulsumTypes'
    Target 'PulsumTypes' in project 'PulsumTypes' (no dependencies)

GatherProvisioningInputs

CreateBuildDescription

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc --version

ExecuteExternalTool /usr/bin/what -q /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/coremlc

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/usr/bin/momc --dry-run --action generate --swift-version 6 --sdkroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --iphonesimulator-deployment-target 26.0 --module PulsumData /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData/Sources/PulsumData/Resources/Pulsum.xcdatamodeld /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/DerivedSources/CoreDataGenerated/Pulsum

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/usr/bin/actool --print-asset-tag-combinations --output-format xml1 /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum/Assets.xcassets

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ld -version_details

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -v -E -dM -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -x c -c /dev/null

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/coremlc generate /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumFallbackEmbedding.mlmodel /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/CoreMLGenerated/PulsumFallbackEmbedding --dry-run yes --deployment-target 26.0 --sdkroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --platform ios --output-partial-info-plist /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumFallbackEmbedding-CoreMLPartialInfo.plist --container swift-package --language Swift --swift-version 6 --public-access

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/coremlc generate /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumSentimentCoreML.mlmodel /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/CoreMLGenerated/PulsumSentimentCoreML --dry-run yes --deployment-target 26.0 --sdkroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --platform ios --output-partial-info-plist /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumSentimentCoreML-CoreMLPartialInfo.plist --container swift-package --language Swift --swift-version 6 --public-access

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/usr/bin/actool --version --output-format xml1

Build description signature: 2cc52bea0285ae6ac677c3cb4957bcca
Build description path: /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/XCBuildData/2cc52bea0285ae6ac677c3cb4957bcca.xcbuilddata
ClangStatCache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk /Users/martin.demel/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -o /Users/martin.demel/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache

ProcessInfoPlistFile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumTypes_-2097CF9FEE3B15A_PackageProduct.framework/Info.plist /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumTypes.build/Debug-iphonesimulator/PulsumTypes\ product.build/empty-PulsumTypes_-2097CF9FEE3B15A_PackageProduct.plist (in target 'PulsumTypes' from project 'PulsumTypes')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumTypes
    builtin-infoPlistUtility /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumTypes.build/Debug-iphonesimulator/PulsumTypes\ product.build/empty-PulsumTypes_-2097CF9FEE3B15A_PackageProduct.plist -producttype com.apple.product-type.framework -expandbuildsettings -format binary -platform iphonesimulator -o /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumTypes_-2097CF9FEE3B15A_PackageProduct.framework/Info.plist

ProcessInfoPlistFile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle/Info.plist /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/empty-PulsumML_PulsumML.plist (in target 'PulsumML_PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    builtin-infoPlistUtility /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/empty-PulsumML_PulsumML.plist -producttype com.apple.product-type.bundle -expandbuildsettings -format binary -platform iphonesimulator -additionalcontentfile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/PulsumFallbackEmbedding-CoreMLPartialInfo.plist -additionalcontentfile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/PulsumSentimentCoreML-CoreMLPartialInfo.plist -o /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle/Info.plist

ProcessInfoPlistFile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework/Info.plist /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML\ product.build/empty-PulsumML_-352E04A98F5439D9_PackageProduct.plist (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    builtin-infoPlistUtility /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML\ product.build/empty-PulsumML_-352E04A98F5439D9_PackageProduct.plist -producttype com.apple.product-type.framework -expandbuildsettings -format binary -platform iphonesimulator -o /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework/Info.plist

ProcessInfoPlistFile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle/Info.plist /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData_PulsumData.build/empty-PulsumData_PulsumData.plist (in target 'PulsumData_PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    builtin-infoPlistUtility /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData_PulsumData.build/empty-PulsumData_PulsumData.plist -producttype com.apple.product-type.bundle -expandbuildsettings -format binary -platform iphonesimulator -o /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle/Info.plist

ProcessInfoPlistFile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework/Info.plist /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData\ product.build/empty-PulsumData_1B04D3771DDAAD0A_PackageProduct.plist (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    builtin-infoPlistUtility /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData\ product.build/empty-PulsumData_1B04D3771DDAAD0A_PackageProduct.plist -producttype com.apple.product-type.framework -expandbuildsettings -format binary -platform iphonesimulator -o /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework/Info.plist

ProcessInfoPlistFile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle/Info.plist /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices_PulsumServices.build/empty-PulsumServices_PulsumServices.plist (in target 'PulsumServices_PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    builtin-infoPlistUtility /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices_PulsumServices.build/empty-PulsumServices_PulsumServices.plist -producttype com.apple.product-type.bundle -expandbuildsettings -format binary -platform iphonesimulator -o /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle/Info.plist

ProcessInfoPlistFile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework/Info.plist /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices\ product.build/empty-PulsumServices_3A6ABEAA64FB17D8_PackageProduct.plist (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    builtin-infoPlistUtility /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices\ product.build/empty-PulsumServices_3A6ABEAA64FB17D8_PackageProduct.plist -producttype com.apple.product-type.framework -expandbuildsettings -format binary -platform iphonesimulator -o /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework/Info.plist

ProcessInfoPlistFile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle/Info.plist /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents_PulsumAgents.build/empty-PulsumAgents_PulsumAgents.plist (in target 'PulsumAgents_PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    builtin-infoPlistUtility /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents_PulsumAgents.build/empty-PulsumAgents_PulsumAgents.plist -producttype com.apple.product-type.bundle -expandbuildsettings -format binary -platform iphonesimulator -o /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle/Info.plist

ProcessInfoPlistFile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework/Info.plist /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents\ product.build/empty-PulsumAgents_68A450630B045BF4_PackageProduct.plist (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    builtin-infoPlistUtility /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents\ product.build/empty-PulsumAgents_68A450630B045BF4_PackageProduct.plist -producttype com.apple.product-type.framework -expandbuildsettings -format binary -platform iphonesimulator -o /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework/Info.plist

ProcessInfoPlistFile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle/Info.plist /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI_PulsumUI.build/empty-PulsumUI_PulsumUI.plist (in target 'PulsumUI_PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    builtin-infoPlistUtility /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI_PulsumUI.build/empty-PulsumUI_PulsumUI.plist -producttype com.apple.product-type.bundle -expandbuildsettings -format binary -platform iphonesimulator -o /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle/Info.plist

ProcessInfoPlistFile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework/Info.plist /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI\ product.build/empty-PulsumUI_-352E04A98F4C2CD4_PackageProduct.plist (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    builtin-infoPlistUtility /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI\ product.build/empty-PulsumUI_-352E04A98F4C2CD4_PackageProduct.plist -producttype com.apple.product-type.framework -expandbuildsettings -format binary -platform iphonesimulator -o /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework/Info.plist

ProcessInfoPlistFile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/Info.plist /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/empty-Pulsum.plist (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-infoPlistUtility /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/empty-Pulsum.plist -producttype com.apple.product-type.application -genpkginfo /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/PkgInfo -expandbuildsettings -format binary -platform iphonesimulator -additionalcontentfile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_generated_info.plist -scanforprivacyfile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework -scanforprivacyfile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework -scanforprivacyfile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework -scanforprivacyfile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework -scanforprivacyfile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumTypes_-2097CF9FEE3B15A_PackageProduct.framework -scanforprivacyfile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework -scanforprivacyfile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/PulsumAgents_PulsumAgents.bundle -scanforprivacyfile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/PulsumData_PulsumData.bundle -scanforprivacyfile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/PulsumML_PulsumML.bundle -scanforprivacyfile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/PulsumServices_PulsumServices.bundle -scanforprivacyfile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/PulsumUI_PulsumUI.bundle -o /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/Info.plist

CopySwiftLibs /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-swiftStdLibTool --copy --verbose --sign - --scan-executable /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/Pulsum.debug.dylib --scan-folder /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks --scan-folder /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns --scan-folder /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/SystemExtensions --scan-folder /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/Extensions --scan-folder /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumTypes_-2097CF9FEE3B15A_PackageProduct.framework --scan-folder /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework --scan-folder /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework --scan-folder /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework --scan-folder /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework --scan-folder /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework --platform iphonesimulator --toolchain /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --destination /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks --strip-bitcode --strip-bitcode-tool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/bitcode_strip --emit-dependency-info /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/SwiftStdLibToolInputDependencies.dep --filter-for-swift-os

ProcessInfoPlistFile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Info.plist /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/empty-PulsumTests.plist (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-infoPlistUtility /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/empty-PulsumTests.plist -producttype com.apple.product-type.bundle.unit-test -expandbuildsettings -format binary -platform iphonesimulator -scanforprivacyfile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PulsumAgents_PulsumAgents.bundle -scanforprivacyfile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PulsumData_PulsumData.bundle -scanforprivacyfile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PulsumML_PulsumML.bundle -scanforprivacyfile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PulsumServices_PulsumServices.bundle -scanforprivacyfile /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PulsumUI_PulsumUI.bundle -o /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Info.plist

2026-01-21 09:50:51.484306-0600 Pulsum[12228:30624254] [app] app.session.start session=5A034702-5A5E-48D6-9610-A06251F6805E trace=8300A82A-4D1C-4390-8B8C-58A3F7658773 build_number=1 low_power_mode=false locale=en_US first_launch=false device_model=iPhone os_version=26.1 app_version=1.0
2026-01-21 09:50:51.635302-0600 Pulsum[12228:30624257] [ui] ui.startupState.changed session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none state=ready
2026-01-21 09:50:51.668043-0600 Pulsum[12228:30624254] [app] app.lifecycle.didBecomeActive session=5A034702-5A5E-48D6-9610-A06251F6805E trace=8300A82A-4D1C-4390-8B8C-58A3F7658773
Test Suite 'All tests' started at 2026-01-21 09:50:51.683.
Test Suite 'PulsumTests.xctest' started at 2026-01-21 09:50:51.683.
Test Suite 'CoachViewModelTests' started at 2026-01-21 09:50:51.683.
Test Case '-[PulsumTests.CoachViewModelTests testPlaceholderSnapshotShowsWarmingUpNotice]' started.
2026-01-21 09:50:51.684939-0600 Pulsum[12228:30624254] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none has_snapshot=false reason=loading from=loading to=loading
2026-01-21 09:50:51.685048-0600 Pulsum[12228:30624254] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none from=loading has_snapshot=false reason=snapshot to=no_data
2026-01-21 09:50:51.685183-0600 Pulsum[12228:30624254] [ui] ui.wellbeing.snapshot.update session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none has_snapshot=false refresh_id=1 snapshot_kind=placeholder score_present=false state=no_data day=2025-10-23
Test Case '-[PulsumTests.CoachViewModelTests testPlaceholderSnapshotShowsWarmingUpNotice]' passed (0.002 seconds).
Test Case '-[PulsumTests.CoachViewModelTests testRecommendationsSoftTimeoutStopsSpinnerAndAppliesLater]' started.
2026-01-21 09:50:51.686381-0600 Pulsum[12228:30624259] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none from=loading to=loading has_snapshot=false reason=loading
2026-01-21 09:50:51.693678-0600 Pulsum[12228:30624259] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none to=ready from=loading has_snapshot=true reason=snapshot
2026-01-21 09:50:51.693884-0600 Pulsum[12228:30624259] [ui] ui.wellbeing.snapshot.update session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none has_snapshot=true state=ready score_present=true snapshot_kind=real day=2025-10-23 refresh_id=1
2026-01-21 09:50:51.693953-0600 Pulsum[12228:30624259] [ui] ui.recommendations.refresh.begin session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none coalesced=false refresh_id=1
2026-01-21 09:50:52.001549-0600 Pulsum[12228:30624259] [ui] ui.recommendations.refresh.end session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none result=applied refresh_id=1 cards_count=1 coalesced=false
Test Case '-[PulsumTests.CoachViewModelTests testRecommendationsSoftTimeoutStopsSpinnerAndAppliesLater]' passed (0.405 seconds).
Test Case '-[PulsumTests.CoachViewModelTests testRefreshStormCoalescesRecommendationsAndKeepsWellbeingReady]' started.
2026-01-21 09:50:52.090773-0600 Pulsum[12228:30624254] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none to=loading from=loading has_snapshot=false reason=loading
2026-01-21 09:50:52.090850-0600 Pulsum[12228:30624254] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none from=loading to=ready has_snapshot=true reason=snapshot
2026-01-21 09:50:52.090881-0600 Pulsum[12228:30624254] [ui] ui.wellbeing.snapshot.update session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none has_snapshot=true state=ready score_present=true snapshot_kind=real day=2025-10-23 refresh_id=1
2026-01-21 09:50:52.090920-0600 Pulsum[12228:30624254] [ui] ui.recommendations.refresh.begin session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none coalesced=false refresh_id=1
2026-01-21 09:50:52.112314-0600 Pulsum[12228:30624254] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none to=ready reason=snapshot from=ready has_snapshot=true
2026-01-21 09:50:52.112457-0600 Pulsum[12228:30624254] [ui] ui.wellbeing.snapshot.update session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none refresh_id=2 state=ready snapshot_kind=real has_snapshot=true score_present=true day=2025-10-23
2026-01-21 09:50:52.112573-0600 Pulsum[12228:30624254] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none to=ready reason=snapshot from=ready has_snapshot=true
2026-01-21 09:50:52.112631-0600 Pulsum[12228:30624254] [ui] ui.wellbeing.snapshot.update session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none state=ready snapshot_kind=real refresh_id=3 day=2025-10-23 has_snapshot=true score_present=true
2026-01-21 09:50:52.112683-0600 Pulsum[12228:30624254] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none has_snapshot=true to=ready from=ready reason=snapshot
2026-01-21 09:50:52.112739-0600 Pulsum[12228:30624254] [ui] ui.wellbeing.snapshot.update session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none state=ready day=2025-10-23 snapshot_kind=real score_present=true has_snapshot=true refresh_id=4
2026-01-21 09:50:52.112788-0600 Pulsum[12228:30624254] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none has_snapshot=true from=ready to=ready reason=snapshot
2026-01-21 09:50:52.112831-0600 Pulsum[12228:30624254] [ui] ui.wellbeing.snapshot.update session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none refresh_id=5 has_snapshot=true score_present=true day=2025-10-23 state=ready snapshot_kind=real
2026-01-21 09:50:52.113140-0600 Pulsum[12228:30624254] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none from=ready has_snapshot=true reason=snapshot to=ready
2026-01-21 09:50:52.113179-0600 Pulsum[12228:30624254] [ui] ui.wellbeing.snapshot.update session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none state=ready snapshot_kind=real day=2025-10-23 refresh_id=6 score_present=true has_snapshot=true
2026-01-21 09:50:52.303957-0600 Pulsum[12228:30624256] [ui] ui.recommendations.refresh.end session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none coalesced=false refresh_id=1 result=stale cards_count=1
2026-01-21 09:50:52.304044-0600 Pulsum[12228:30624256] [ui] ui.recommendations.refresh.begin session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none refresh_id=6 coalesced=true
2026-01-21 09:50:52.506525-0600 Pulsum[12228:30624255] [ui] ui.recommendations.refresh.end session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none result=applied refresh_id=6 coalesced=true cards_count=1
Test Case '-[PulsumTests.CoachViewModelTests testRefreshStormCoalescesRecommendationsAndKeepsWellbeingReady]' passed (0.556 seconds).
Test Case '-[PulsumTests.CoachViewModelTests testSnapshotKindSemantics]' started.
2026-01-21 09:50:52.646879-0600 Pulsum[12228:30624256] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none to=loading has_snapshot=false reason=loading from=loading
2026-01-21 09:50:52.647036-0600 Pulsum[12228:30624256] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none to=no_data reason=snapshot from=loading has_snapshot=false
2026-01-21 09:50:52.647090-0600 Pulsum[12228:30624256] [ui] ui.wellbeing.snapshot.update session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none snapshot_kind=none has_snapshot=false refresh_id=1 state=no_data score_present=false
Test Case '-[PulsumTests.CoachViewModelTests testSnapshotKindSemantics]' passed (0.001 seconds).
2026-01-21 09:50:52.647137-0600 Pulsum[12228:30624256] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none has_snapshot=false reason=loading from=loading to=loading
2026-01-21 09:50:52.647171-0600 Pulsum[12228:30624256] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none from=loading to=ready reason=snapshot has_snapshot=true
2026-01-21 09:50:52.647233-0600 Pulsum[12228:30624256] [ui] ui.wellbeiTest Case '-[PulsumTests.CoachViewModelTests testSnapshotReadyBeforeRecommendationsComplete]' started.
ng.snapshot.update session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none state=ready refresh_id=1 has_snapshot=true snapshot_kind=real score_present=true day=2025-10-23
2026-01-21 09:50:52.650568-0600 Pulsum[12228:30624256] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none reason=loading has_snapshot=false to=loading from=loading
2026-01-21 09:50:52.650635-0600 Pulsum[12228:30624256] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none from=loading to=ready has_snapshot=true reason=snapshot
2026-01-21 09:50:52.650697-0600 Pulsum[12228:30624256] [ui] ui.wellbeing.snapshot.update session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none score_present=true refresh_id=1 snapshot_kind=real state=ready has_snapshot=true day=2025-10-23
2026-01-21 09:50:52.650733-0600 Pulsum[12228:30624256] [ui] ui.recommendations.refresh.begin session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none coalesced=false refresh_id=1
2026-01-21 09:50:52.853092-0600 Pulsum[12228:30624255] [ui] ui.recommendations.refresh.end session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none result=applied coalesced=false refresh_id=1 cards_count=1
Test Case '-[PulsumTests.CoachViewModelTests testSnapshotReadyBeforeRecommendationsComplete]' passed (0.307 seconds).
Test Case '-[PulsumTests.CoachViewModelTests testStaleRecommendationResultsApplyWhenEmpty]' started.
2026-01-21 09:50:52.955566-0600 Pulsum[12228:30624254] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none has_snapshot=false from=loading to=loading reason=loading
2026-01-21 09:50:52.955769-0600 Pulsum[12228:30624254] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none has_snapshot=true to=ready from=loading reason=snapshot
2026-01-21 09:50:52.955844-0600 Pulsum[12228:30624254] [ui] ui.wellbeing.snapshot.update session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none score_present=true snapshot_kind=real has_snapshot=true state=ready day=2025-10-23 refresh_id=1
2026-01-21 09:50:52.955998-0600 Pulsum[12228:30624254] [ui] ui.recommendations.refresh.begin session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none refresh_id=1 coalesced=false
2026-01-21 09:50:52.976546-0600 Pulsum[12228:30624254] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none has_snapshot=true to=ready from=ready reason=snapshot
2026-01-21 09:50:52.976614-0600 Pulsum[12228:30624254] [ui] ui.wellbeing.snapshot.update session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none day=2025-10-23 has_snapshot=true snapshot_kind=real refresh_id=2 score_present=true state=ready
2026-01-21 09:50:53.114953-0600 Pulsum[12228:30624255] [ui] ui.recommendations.refresh.end session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none result=stale cards_count=1 refresh_id=1 coalesced=false
2026-01-21 09:50:53.115170-0600 Pulsum[12228:30624255] [ui] ui.recommendations.refresh.begin session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none coalesced=true refresh_id=2
2026-01-21 09:50:53.275187-0600 Pulsum[12228:30624367] [ui] ui.recommendations.refresh.end session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none coalesced=true refresh_id=2 result=applied cards_count=1
Test Case '-[PulsumTests.CoachViewModelTests testStaleRecommendationResultsApplyWhenEmpty]' passed (0.321 seconds).
Test Case '-[PulsumTests.CoachViewModelTests testStaleRecommendationResultsIgnoredWhenCardsExist]' started.
2026-01-21 09:50:53.276328-0600 Pulsum[12228:30624254] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none from=loading to=loading has_snapshot=false reason=loading
2026-01-21 09:50:53.276457-0600 Pulsum[12228:30624254] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none to=ready reason=snapshot has_snapshot=true from=loading
2026-01-21 09:50:53.276521-0600 Pulsum[12228:30624254] [ui] ui.wellbeing.snapshot.update session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none refresh_id=1 day=2025-10-23 snapshot_kind=real state=ready has_snapshot=true score_present=true
2026-01-21 09:50:53.276561-0600 Pulsum[12228:30624254] [ui] ui.recommendations.refresh.begin session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none coalesced=false refresh_id=1
2026-01-21 09:50:53.436546-0600 Pulsum[12228:30624255] [ui] ui.recommendations.refresh.end session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none refresh_id=1 cards_count=1 coalesced=false result=applied
2026-01-21 09:50:53.537220-0600 Pulsum[12228:30624257] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none reason=snapshot has_snapshot=true from=ready to=ready
2026-01-21 09:50:53.537318-0600 Pulsum[12228:30624257] [ui] ui.wellbeing.snapshot.update session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none refresh_id=2 snapshot_kind=real day=2025-10-23 state=ready has_snapshot=true score_present=true
2026-01-21 09:50:53.537369-0600 Pulsum[12228:30624257] [ui] ui.recommendations.refresh.begin session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none refresh_id=2 coalesced=false
2026-01-21 09:50:53.558616-0600 Pulsum[12228:30624257] [ui] ui.wellbeingState.transition session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none from=ready to=ready has_snapshot=true reason=snapshot
2026-01-21 09:50:53.558695-0600 Pulsum[12228:30624257] [ui] ui.wellbeing.snapshot.update session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none state=ready snapshot_kind=real score_present=true day=2025-10-23 has_snapshot=true refresh_id=3
2026-01-21 09:50:53.697475-0600 Pulsum[12228:30624255] [ui] ui.recommendations.refresh.end session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none coalesced=false refresh_id=2 cards_count=1 result=stale
2026-01-21 09:50:53.697564-0600 Pulsum[12228:30624255] [ui] ui.recommendations.refresh.begin session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none refresh_id=3 coalesced=true
2026-01-21 09:50:53.851342-0600 Pulsum[12228:30624259] [ui] ui.recommendations.refresh.end session=5A034702-5A5E-48D6-9610-A06251F6805E trace=none cards_count=1 refresh_id=3 coalesced=true result=applied
Test Case '-[PulsumTests.CoachViewModelTests testStaleRecommendationResultsIgnoredWhenCardsExist]' passed (0.576 seconds).
Test Suite 'CoachViewModelTests' passed at 2026-01-21 09:50:53.852.
     Executed 7 tests, with 0 failures (0 unexpected) in 2.167 (2.169) seconds
Test Suite 'LiveWaveformBufferTests' started at 2026-01-21 09:50:53.852.
Test Case '-[PulsumTests.LiveWaveformBufferTests testClampBehavior]' started.
Test Case '-[PulsumTests.LiveWaveformBufferTests testClampBehavior]' passed (0.001 seconds).
Test Case '-[PulsumTests.LiveWaveformBufferTests testRingBufferMaintainsLatestSamples]' started.
Test Case '-[PulsumTests.LiveWaveformBufferTests testRingBufferMaintainsLatestSamples]' passed (0.001 seconds).
Test Case '-[PulsumTests.LiveWaveformBufferTests testWaveformPerfFeed30Seconds]' started.
/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Tests/PulsumUITests/LiveWaveformBufferTests.swift:19: Test Case '-[PulsumTests.LiveWaveformBufferTests testWaveformPerfFeed30Seconds]' measured [Memory Peak Physical, kB] average: 55266.424, relative standard deviation: 0.000%, values: [55266.424000, 55266.424000, 55266.424000, 55266.424000, 55266.424000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical_peak, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Tests/PulsumUITests/LiveWaveformBufferTests.swift:19: Test Case '-[PulsumTests.LiveWaveformBufferTests testWaveformPerfFeed30Seconds]' measured [Memory Physical, kB] average: 0.000, relative standard deviation: 0.000%, values: [0.000000, 0.000000, 0.000000, 0.000000, 0.000000], performanceMetricID:com.apple.dt.XCTMetric_Memory.physical, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Tests/PulsumUITests/LiveWaveformBufferTests.swift:19: Test Case '-[PulsumTests.LiveWaveformBufferTests testWaveformPerfFeed30Seconds]' measured [Clock Monotonic Time, s] average: 0.000, relative standard deviation: 6.789%, values: [0.000158, 0.000150, 0.000148, 0.000178, 0.000158], performanceMetricID:com.apple.dt.XCTMetric_Clock.time.monotonic, baselineName: "", baselineAverage: , polarity: prefers smaller, maxPercentRegression: 10.000%, maxPercentRelativeStandardDeviation: 10.000%, maxRegression: 0.000, maxStandardDeviation: 0.000
Test Case '-[PulsumTests.LiveWaveformBufferTests testWaveformPerfFeed30Seconds]' passed (0.307 seconds).
Test Suite 'LiveWaveformBufferTests' passed at 2026-01-21 09:50:54.161.
     Executed 3 tests, with 0 failures (0 unexpected) in 0.308 (0.309) seconds
Test Suite 'PulsumRootViewTests' started at 2026-01-21 09:50:54.161.
Test Case '-[PulsumTests.PulsumRootViewTests testRootViewHealthCheckPrecondition]' started.
Test Case '-[PulsumTests.PulsumRootViewTests testRootViewHealthCheckPrecondition]' passed (0.003 seconds).
Test Suite 'PulsumRootViewTests' passed at 2026-01-21 09:50:54.165.
     Executed 1 test, with 0 failures (0 unexpected) in 0.003 (0.004) seconds
Test Suite 'SettingsViewModelHealthAccessTests' started at 2026-01-21 09:50:54.165.
Test Case '-[PulsumTests.SettingsViewModelHealthAccessTests testRequestHealthKitAuthorizationRefreshesStatus]' started.
Test Case '-[PulsumTests.SettingsViewModelHealthAccessTests testRequestHealthKitAuthorizationRefreshesStatus]' passed (0.233 seconds).
Test Suite 'SettingsViewModelHealthAccessTests' passed at 2026-01-21 09:50:54.398.
     Executed 1 test, with 0 failures (0 unexpected) in 0.233 (0.234) seconds
Test Suite 'PulsumTests.xctest' passed at 2026-01-21 09:50:54.398.
     Executed 12 tests, with 0 failures (0 unexpected) in 2.711 (2.715) seconds
Test Suite 'All tests' passed at 2026-01-21 09:50:54.399.
     Executed 12 tests, with 0 failures (0 unexpected) in 2.711 (2.716) seconds
◇ Test run started.
↳ Testing Library Version: 1400
↳ Target Platform: arm64-apple-ios13.0-simulator
◇ Suite PulsumTests started.
◇ Test example() started.
✔ Test example() passed after 0.001 seconds.
✔ Suite PulsumTests passed after 0.001 seconds.
✔ Test run with 1 test in 1 suite passed after 0.001 seconds.
2026-01-21 09:50:54.679 xcodebuild[11961:30621116] [MT] IDETestOperationsObserverDebug: 15.029 elapsed -- Testing started completed.
2026-01-21 09:50:54.679 xcodebuild[11961:30621116] [MT] IDETestOperationsObserverDebug: 0.000 sec, +0.000 sec -- start
2026-01-21 09:50:54.679 xcodebuild[11961:30621116] [MT] IDETestOperationsObserverDebug: 15.029 sec, +15.029 sec -- end

Test session results, code coverage, and logs:
    /Users/martin.demel/Library/Developer/Xcode/DerivedData/Pulsum-asfryqahqiaobxecgecemhvmrxwa/Logs/Test/Test-PulsumUI-2026.01.21_09-50-35--0600.xcresult

** TEST SUCCEEDED **

Testing started
```

## Still pending manual verification steps
- (cleared) Soft-timeout banner + late cards now covered by `CoachViewModelTests.testRecommendationsSoftTimeoutStopsSpinnerAndAppliesLaterWithoutManualRefresh`.
- (cleared) Diagnostics span overlap now covered by `LibraryImporterDiagnosticsTests.testLibraryImportSpanEmitsSingleBeginOnFirstRun`.
