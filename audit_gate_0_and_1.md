# Pulsum – Gate 0 & Gate 1 Audit

## Executive Summary
- Overall status: PARTIAL — all Gate 1 checks pass, but Gate 0.1 still leaks a redacted OpenAI key reference inside `bugs.md`, so Gate 0 cannot be signed off.
- What passed at a glance: ✅ LLMGateway key precedence + tests, ✅ privacy manifests & validator script, ✅ speech entitlements/mic preflight/PHI logging guards, ✅ release parity scripts & platform gating, ✅ data-protection/vector-index hygiene, ✅ typed AFM stubs & Gate 1 scheme/workflow alignment.
- What needs work (S0): ❌ `bugs.md` still contains a literal `sk-proj-…` credential string that matches the Gate-0 secret-scanner pattern, meaning the repo still distributes part of the production key history.
- CI/PR state observed: `scripts/ci/integrity.sh` enforces HEAD/tag sync, secret scans (repo + bundle), privacy manifest checks, Release builds, and Gate0_* package tests; `.github/workflows/gate-tests` runs the same Gate0_/Gate1_ filters on Services/Data/ML packages on macOS-15.

## What I Read
- Repo HEAD `e77d36943ea080e2e71692da4a817f4ab1ab980f` plus gate-definition docs: `github_master_gate.md`, `fix.md`, `bugs.md`, `todolist.md`, `architecture.md`, and `CLAUDE.md`.
- Security/build artifacts: `Config.xcconfig`, `Config.xcconfig.template`, `scripts/ci/scan-secrets.sh`, `scripts/ci/check-privacy-manifests.sh`, `scripts/ci/build-release.sh`, `scripts/ci/integrity.sh`.
- Core implementation: `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift`, `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift`, `FoundationModelsCoachGenerator.swift`; `Packages/PulsumData/Sources/PulsumData/DataStack.swift`, `VectorIndex.swift`; `Packages/PulsumML/Sources/PulsumML/AFM/FoundationModelsStub.swift`; `Bundle+Pulsum*Resources.swift` helpers.
- Tests and harness: `Packages/PulsumServices/Tests/*Gate0*.swift`, `Gate1_SpeechFakeBackendTests.swift`, `Packages/PulsumData/Tests/Gate0_DataStackSecurityTests.swift`, `Packages/PulsumML/Tests/Gate0_EmbeddingServiceFallbackTests.swift`, `Pulsum.xcodeproj/xcshareddata/xcschemes/Pulsum.xcscheme`, `.github/workflows/test-harness.yml`.

## Gate 0 — Security & Build Blockers (evidence-backed checks)

### G0.1 Secrets removed & hardened key resolution
Status: ❌ NEEDS FIX  
Evidence:  
- `bugs.md:73-88` — `Config.xcconfig:5 … OPENAI_API_KEY = <redacted>...` keeps the key string in the repo.  
- `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:299-327` — `if inMemoryAPIKey?.trimmedNonEmpty != nil { return "memory" } … if Self.environmentAPIKey() != nil { return "env" }`.  
- `Packages/PulsumServices/Tests/PulsumServicesTests/Gate0_LLMGatewayTests.swift:45-54` — `XCTAssertEqual(try gateway.debugResolveAPIKey(), "memory-key" … "keychain-key" … "env-key")`.  
- `scripts/ci/scan-secrets.sh:15-64` — `REGEX_PATTERNS=('sk-[A-Za-z0-9_-]{10,}', …); rg … die "pattern '…' detected"`.  
Why it matters: Shipping (or even documenting) recognizable credential fragments keeps the S0 bug alive and makes the Gate-0 secret scanner fire on every run, blocking CI.  
Remediation (minimal patch):
```patch
*** Update File: bugs.md
@@
-  - Config.xcconfig:5  [sig8:0b61c5eb] — `OPENAI_API_KEY = <redacted>...` (full 176-char key hardcoded)
+  - Config.xcconfig:5  [sig8:0b61c5eb] — `OPENAI_API_KEY = <redacted in Gate 0 history>` (full 176-char key had been hardcoded)
```

### G0.2 Privacy manifests present & validated
Status: ✅ PASS  
Evidence:  
- `Packages/PulsumServices/Package.swift:28-33` — `.process("PulsumServices/PrivacyInfo.xcprivacy") … .linkedFramework("FoundationModels", .when(platforms: [.iOS]))`.  
- `Packages/PulsumML/Package.swift:25-33` — `.process("PulsumML/PrivacyInfo.xcprivacy")` lives next to the Core ML resources and conditional linker settings.  
- `scripts/ci/check-privacy-manifests.sh:15-67` — `MANIFESTS=(Pulsum/PrivacyInfo… Packages/PulsumAgents/… ) … die "missing manifest"`.  
Why it matters: Apple blocks binaries touching protected APIs without manifests; this setup keeps Gate-0 privacy promises enforceable.

### G0.3 Speech entitlement + mic preflight + PHI logging guardrails
Status: ✅ PASS  
Evidence:  
- `Pulsum/Pulsum.entitlements:5-10` — `<key>com.apple.developer.speech</key><true/>` ships with the app.  
- `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:34-44` — `AVAudioSession.sharedInstance().requestRecordPermission { granted in … }`.  
- `Packages/PulsumServices/Tests/PulsumServicesTests/Gate0_SpeechServiceAuthorizationTests.swift:34-45` — `let provider = … microphoneGranted: false` followed by `await expect(…, toThrow: .microphonePermissionDenied)`.  
- `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:281-288` — `if SpeechLoggingPolicy.transcriptLoggingEnabled { … "PULSUM_TRANSCRIPT_LOG_MARKER" }`.  
- `Packages/PulsumServices/Tests/PulsumServicesTests/Gate0_SpeechServiceLoggingTests.swift:5-22` — `#if RELEASE_LOG_AUDIT … XCTAssertFalse(SpeechLoggingPolicy.transcriptLoggingEnabled)` and binary scan.  
Why it matters: Speech APIs stay usable in production, while PHI never leaks into release logs or Console traces.

### G0.4 Release build parity & platform guards
Status: ✅ PASS  
Evidence:  
- `scripts/ci/build-release.sh:7-11` — `xcodebuild -scheme Pulsum -configuration Release build \ CODE_SIGNING_ALLOWED=NO`.  
- `Packages/PulsumUI/Sources/PulsumUI/PulseView.swift:1-5` — `#if canImport(UIKit) import UIKit #endif` keeps macOS previews compiling.  
- `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:3-5,175-200` — `#if os(iOS)` wraps AVFoundation imports and audio-session setup.  
Why it matters: Release builds match debug behavior in CI, and desktop builds continue to compile even when UIKit- or AVFoundation-only helpers exist.

### G0.5 Data protection hygiene
Status: ✅ PASS  
Evidence:  
- `Packages/PulsumData/Sources/PulsumData/DataStack.swift:89-95` — `backupSecurityIssue = DataStack.applyBackupExclusion(to: [applicationSupport, vectorIndexDirectory, healthAnchorsDirectory])`.  
- `Packages/PulsumData/Tests/PulsumDataTests/Gate0_DataStackSecurityTests.swift:14-20` — `XCTAssertEqual(values.isExcludedFromBackup, true)` for each directory.  
- `Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:103-109` — `defer { do { try handle.close() } catch { os_log("VectorIndex: close() failed") } }`.  
Why it matters: PHI stays off iCloud backups and long-running vector-index workloads don’t leak file handles or hide failures.

### G0.6 Foundation Models stubs typed & safe
Status: ✅ PASS  
Evidence:  
- `Packages/PulsumML/Sources/PulsumML/AFM/FoundationModelsStub.swift:18-31` — `public func respond<T: Decodable …> … throws -> LanguageModelResult<T> { throw FoundationModelsStubError.unavailable }`.  
- `Packages/PulsumML/Tests/PulsumMLTests/Gate0_EmbeddingServiceFallbackTests.swift:25-34` — `let service = … primary: .fails … fallback: .succeeds … XCTAssertEqual(result, fallbackVector)`.  
Why it matters: Devices without FoundationModels never crash, keeping Sentiment/Safety/Embedding providers aligned with Gate-0 expectations.

**Gate 0 Verdict:** PARTIAL — all criteria except G0.1 pass, but the lingering `sk-proj-…` string in `bugs.md` keeps the security gate from clearing until redacted.

## Gate 1 — Deterministic test harness & seams (evidence-backed checks)

### G1.1 FoundationModels linking gated to iOS only
Status: ✅ PASS  
Evidence:  
- `Packages/PulsumServices/Package.swift:28-33` — `.linkedFramework("FoundationModels", .when(platforms: [.iOS]))`.  
- `Packages/PulsumAgents/Package.swift:30-35` — identical conditional linker stanza on the agent library.  
- `Packages/PulsumServices/Package.swift:35-39` — `testTarget(name: "PulsumServicesTests", …)` without any linker settings.  
Why it matters: macOS builds and SwiftPM tests run without the beta FoundationModels SDK, preventing CI breakage.

### G1.2 Resource bundle access via `.module` (no fatal accessors)
Status: ✅ PASS  
Evidence:  
- `Packages/PulsumML/Sources/PulsumML/Bundle+PulsumMLResources.swift:3-6` — `extension Bundle { static var pulsumMLResources: Bundle { .module } }`.  
- `Packages/PulsumServices/Sources/PulsumServices/Bundle+PulsumServicesResources.swift:3-6` — same `.module` access.  
- `Packages/PulsumData/Sources/PulsumData/Bundle+PulsumDataResources.swift:3-6` — same `.module` access.  
Why it matters: Gate-1 requires deterministic bundle lookups without the old fatal helpers; `.module` keeps tests hermetic.

### G1.3 FoundationModels imports guarded
Status: ✅ PASS  
Evidence:  
- `Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift:1-5` — `#if canImport(FoundationModels) import FoundationModels #endif`.  
- `Packages/PulsumServices/Sources/PulsumServices/FoundationModelsCoachGenerator.swift:2-13` — `#if canImport(FoundationModels) && os(iOS)` before touching the framework.  
Why it matters: macOS simulators and READMEs can compile/tests run without the still-preview FoundationModels framework.

### G1.4 UITest seams compiled only for DEBUG & env-controlled
Status: ✅ PASS  
Evidence:  
- `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:168-183` — `#if DEBUG … if BuildFlags.uiTestSeamsCompiledIn && stubEnabled { resolvedCloudClient = UITestMockCloudClient() }`.  
- `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:362-367` — `#if DEBUG return ProcessInfo.processInfo.environment["UITEST_USE_STUB_LLM"] == "1"`.  
- `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:88-104` — `if BuildFlags.uiTestSeamsCompiledIn && overrides.useFakeBackend { backend = FakeSpeechBackend(...) }`.  
- `Packages/PulsumServices/Tests/PulsumServicesTests/Gate1_SpeechFakeBackendTests.swift:5-17` — `guard ProcessInfo.processInfo.environment["UITEST_FAKE_SPEECH"] == "1" else { throw XCTSkip }`.  
Why it matters: CI/UI tests stay deterministic without polluting release binaries.

### G1.5 Scheme & CI harness configuration
Status: ✅ PASS  
Evidence:  
- `Pulsum.xcodeproj/xcshareddata/xcschemes/Pulsum.xcscheme:32-47` — `<EnvironmentVariable key="UITEST_USE_STUB_LLM" value="1" …>` baked into the shared Test action.  
- `Pulsum.xcodeproj/xcshareddata/xcschemes/Pulsum.xcscheme:50-83` — `<TestableReference skipped="YES">…PulsumTests…</TestableReference>` followed by package testables with `skipped="NO"`.  
- `.github/workflows/test-harness.yml:20-25` — `swift test --package-path Packages/PulsumServices --filter 'Gate0_|Gate1_'` (and the same for Data/ML).  
Why it matters: Gate-1 mandates these bundles actually run on every PR, preventing regressions hidden behind the shared scheme.

### G1.6 Toolchain & platform floors aligned
Status: ✅ PASS  
Evidence:  
- `Packages/PulsumML/Package.swift:1-8` — `// swift-tools-version: 6.1 … platforms: [.iOS("26.0"), .macOS(.v14)]`.  
- `Packages/PulsumServices/Package.swift:1-8` — identical Swift 6.1 + iOS 26 floor.  
Why it matters: CI uses Swift 6.1 + iOS 26 APIs; these floors prevent accidental downgrades.

**Gate 1 Verdict:** PASS — every deterministic harness requirement is implemented with concrete evidence.

## CI & PR Signals Observed
- `scripts/ci/integrity.sh:11-90` enforces git sync, ensures `gate0-done` tag alignment, runs repo + bundle secret scans, validates privacy manifests, performs unsigned Release builds, and runs Gate0_ filters for Services/Data/ML before passing.
- `.github/workflows/test-harness.yml:1-25` runs on pushes/PRs, installs `rg`/`xcbeautify`, and executes Gate0_/Gate1_ package tests on macOS-15 so reviewers see deterministic logs.
- `Pulsum.xcodeproj/xcshareddata/xcschemes/Pulsum.xcscheme:32-83` bakes the UITest seam env vars and shared package testables directly in the scheme, ensuring local `Product ▸ Test` mirrors CI inputs.

## Missing or Ambiguous (with ranked risk)
| Item | Risk | Evidence | Suggested minimal fix |
| --- | --- | --- | --- |
| `bugs.md` still publishes `<redacted>...` | S0 | `bugs.md:73-88` — Gate-0 write-up quotes the credential string that the repo just removed elsewhere | Redact the literal key as shown in the remediation patch under G0.1 so the secret scanner stays quiet |

## Appendix A — All Queries I Ran
- `rg -n 'linkedFramework("FoundationModels'` → `Packages/PulsumServices/Package.swift:32`, `Packages/PulsumAgents/Package.swift:34`, `Packages/PulsumML/Package.swift:31` (conditional links) plus one README mention.
- `rg -n '#if canImport(FoundationModels)'` → SentimentAgent.swift, CoachAgent.swift, SafetyAgent.swift, AgentOrchestrator.swift, PulsumUI/CoachViewModel.swift, PulsumServices/FoundationModelsCoachGenerator.swift, ML providers (guards verified).
- `rg --files -g 'Bundle+Pulsum*.swift'` → located the PulsumML, PulsumServices, and PulsumData bundle helper files that use `.module`.
- `rg -n 'forPulsumML\('` → no matches, confirming the fatal legacy accessors are gone.
- `rg --pcre2 'sk-[A-Za-z0-9_-]{20,}'` → only hit `bugs.md:82`, revealing the lingering `sk-proj-…` reference.
- `rg -n 'OPENAI_API_KEY'` → occurrences limited to documentation/templates/scripts (no Info.plist build settings).
- `rg -n 'api_key'` → no matches; repo no longer embeds generic `api_key` literals.
- `rg -n 'Config\\.xcconfig'` → confirmed template references plus project-file wiring; verified the tracked `Config.xcconfig` is comment-only.
- `rg -n 'com\\.apple\\.developer\\.speech' Pulsum/Pulsum.entitlements` → line 9 shows the speech entitlement is present.
- `rg -n 'PrivacyInfo\\.xcprivacy'` → listed manifests for app + every SwiftPM package plus doc references, proving coverage.
- `rg -n 'PULSUM_TRANSCRIPT_LOG_MARKER'` → single occurrence at `SpeechService.swift:285`, guarded by `#if DEBUG`.
- `rg -n 'Gate[01]_' -g '*Tests*.swift'` → enumerated all Gate0_/Gate1_ test suites across Services/Data/ML (LLMGateway, Speech, DataStack, Embedding, etc.).
- `rg -n 'Gate0_|Gate1_' .github/workflows/test-harness.yml` → lines 23-25 show CI running the filtered package tests.
- `rg -n 'swift-tools-version: 6\\.1' -g 'Package.swift'` and `rg -n 'iOS\\("26\\.0"\)' -g 'Package.swift'` → every package declares Swift 6.1 + iOS 26 floors, matching Gate-1 requirements.
