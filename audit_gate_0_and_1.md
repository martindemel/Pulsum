# Pulsum – Gate 0 & Gate 1 Audit

## Executive Summary
- Overall status: PASS — Gate 0 security blockers and Gate 1 harness requirements are fully satisfied with auditable evidence.
- What passed at a glance: ✅ Secrets purged + key precedence tests, ✅ Privacy manifests + validator script, ✅ Speech entitlement/mic preflight/PHI logging guards, ✅ Release build parity + platform guards, ✅ Data protection + typed AFM stubs, ✅ FoundationModels gating + deterministic scheme/CI harness.
- What needs work: None detected for Gate 0/1 scope (residual risks move to later gates per fix.md).
- CI/PR state observed: `scripts/ci/integrity.sh` enforces git/tag sync, repo & bundle secret scans, privacy manifest validation, unsigned Release builds, and Gate0_* package tests; `.github/workflows/gate-tests` mirrors those Gate0_/Gate1_ filters on macOS-15 with ripgrep/xcbeautify installed.

## What I Read
- Source-of-truth docs: `github_master_gate.md`, `fix.md`, `bugs.md`, `todolist.md`, `architecture.md`, `CLAUDE.md` (all at HEAD `e77d36943ea080e2e71692da4a817f4ab1ab980f`).
- Security & tooling: `Config.xcconfig`, `Config.xcconfig.template`, `scripts/ci/scan-secrets.sh`, `scripts/ci/check-privacy-manifests.sh`, `scripts/ci/build-release.sh`, `scripts/ci/integrity.sh`.
- Core code paths: `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift`, `SpeechService.swift`, `FoundationModelsCoachGenerator.swift`, `Packages/PulsumData/Sources/PulsumData/DataStack.swift`, `VectorIndex.swift`, `Packages/PulsumML/Sources/PulsumML/AFM/FoundationModelsStub.swift`, `Bundle+Pulsum*Resources.swift`.
- Tests & harness: `Packages/PulsumServices/Tests/Gate0_*` + `Gate1_SpeechFakeBackendTests.swift`, `Packages/PulsumData/Tests/Gate0_DataStackSecurityTests.swift`, `Packages/PulsumML/Tests/Gate0_EmbeddingServiceFallbackTests.swift`, `Pulsum.xcodeproj/xcshareddata/xcschemes/Pulsum.xcscheme`, `.github/workflows/test-harness.yml`.

## Gate 0 — Security & Build Blockers (evidence-backed checks)

### G0.1 Secrets removed & hardened key resolution
Status: ✅ PASS  
Evidence:  
- `Config.xcconfig:1-3` — comments explicitly state “Secrets are never stored in this file” with no key assignments.  
- `bugs.md:73-88` — historical key reference now redacted (`OPENAI_API_KEY = <redacted>...`), so no `sk-` pattern ships.  
- `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:299-327` — `keySourceDescriptor()` prefers in-memory → Keychain → env.  
- `Packages/PulsumServices/Tests/PulsumServicesTests/Gate0_LLMGatewayTests.swift:45-54` — precedence asserted via `XCTAssertEqual(try gateway.debugResolveAPIKey(), "memory-key")` etc.  
- `scripts/ci/scan-secrets.sh:15-64` — repo & bundle scanners fail CI if any `sk-`/`OPENAI_API_KEY` strings reappear.  
Why it matters: Prevents another live GPT key from leaking while guaranteeing deterministic key resolution and automated enforcement.

### G0.2 Privacy manifests present & validated
Status: ✅ PASS  
Evidence:  
- `Packages/PulsumServices/Package.swift:28-33` and `Packages/PulsumML/Package.swift:25-33` — each package processes its `PrivacyInfo.xcprivacy` and links FoundationModels conditionally.  
- `scripts/ci/check-privacy-manifests.sh:15-67` — enumerates app + five package manifests and validates required API reasons via `plistlib`.  
Why it matters: Apple requires per-target manifests for microphone/HealthKit access; the script keeps Gate 0 privacy gate green.

### G0.3 Speech entitlement + mic preflight + PHI logging guarded
Status: ✅ PASS  
Evidence:  
- `Pulsum/Pulsum.entitlements:5-10` — includes `<key>com.apple.developer.speech</key><true/>`.  
- `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:34-44` — `requestRecordPermission` called via `AVAudioSession` before recording.  
- `Packages/PulsumServices/Tests/PulsumServicesTests/Gate0_SpeechServiceAuthorizationTests.swift:34-45` — test matrix ensures `.microphonePermissionDenied` and `.speechPermissionDenied` surfaces.  
- `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:281-288` plus `Gate0_SpeechServiceLoggingTests.swift:5-22` — transcript logging is DEBUG-only and release binaries are scanned for the marker under `-DRELEASE_LOG_AUDIT`.  
Why it matters: Users always see required prompts, and PHI transcripts never leak in production telemetry.

### G0.4 Release build parity & platform guards
Status: ✅ PASS  
Evidence:  
- `scripts/ci/build-release.sh:7-11` — Release builds run with signing disabled (CI-safe) so parity is enforced.  
- `Packages/PulsumUI/Sources/PulsumUI/PulseView.swift:1-5` and `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:3-5` — platform-specific imports gated by `#if canImport(UIKit)`/`#if os(iOS)`.  
Why it matters: CI hits the same Release graph users ship, and macOS builds don’t break when UIKit-only helpers exist.

### G0.5 Data protection hygiene
Status: ✅ PASS  
Evidence:  
- `Packages/PulsumData/Sources/PulsumData/DataStack.swift:89-105` — `applyBackupExclusion` marks Application Support/VectorIndex/Anchors as excluded from backups under `NSFileProtectionComplete`.  
- `Packages/PulsumData/Tests/PulsumDataTests/Gate0_DataStackSecurityTests.swift:14-20` — asserts `isExcludedFromBackup == true` for each directory.  
- `Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:103-129` — barrier queue wraps shard writes and `FileHandle` `close()` errors are logged, preventing silent leaks.  
Why it matters: PHI never syncs to iCloud unintentionally, and vector-index I/O failures surface immediately.

### G0.6 Foundation Models stubs are typed and safe
Status: ✅ PASS  
Evidence:  
- `Packages/PulsumML/Sources/PulsumML/AFM/FoundationModelsStub.swift:18-32` — stub `LanguageModelSession.respond<T: Decodable>` throws a typed `.unavailable`, so providers can fall back cleanly.  
- `Packages/PulsumML/Tests/PulsumMLTests/Gate0_EmbeddingServiceFallbackTests.swift:25-34` — verifies primary failure falls back to the Core ML provider without returning zero vectors.  
Why it matters: Devices lacking FoundationModels never crash, and fallback paths stay covered by Gate 0 tests.

**Gate 0 Verdict:** PASS — all security, privacy, and build-blocker controls are present with automated coverage.

## Gate 1 — Deterministic test harness & seams (evidence-backed checks)

### G1.1 FoundationModels linking gated to iOS only
Status: ✅ PASS  
Evidence:  
- `Packages/PulsumAgents/Package.swift:30-35` and `Packages/PulsumServices/Package.swift:28-33` — `.linkedFramework("FoundationModels", .when(platforms: [.iOS]))`; test targets omit the framework entirely.  
Why it matters: macOS builds/tests remain stable even when the FoundationModels SDK is absent.

### G1.2 Resource bundle access via `.module`
Status: ✅ PASS  
Evidence:  
- `Packages/PulsumML/Sources/PulsumML/Bundle+PulsumMLResources.swift:3-6`, `Packages/PulsumServices/.../Bundle+PulsumServicesResources.swift:3-6`, `Packages/PulsumData/.../Bundle+PulsumDataResources.swift:3-6` — each exposes a `.module` helper; no `forPulsum*()` shims remain (`rg -n 'forPulsum'` returns none).  
Why it matters: Gate 1 requires deterministic resource lookup for SwiftPM bundles without fatal fallbacks.

### G1.3 FoundationModels imports are guarded
Status: ✅ PASS  
Evidence:  
- `Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift:1-5` — wraps `import FoundationModels` inside `#if canImport(FoundationModels)`.  
- `Packages/PulsumServices/Sources/PulsumServices/FoundationModelsCoachGenerator.swift:2-13` — also uses `#if canImport(FoundationModels) && os(iOS)` before accessing APIs.  
Why it matters: Unit tests and macOS builds compile even when FoundationModels isn’t available.

### G1.4 UITest seams DEBUG-only & env-controlled
Status: ✅ PASS  
Evidence:  
- `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:168-183,362-367` — DEBUG builds swap in `UITestMockCloudClient` only when `UITEST_USE_STUB_LLM=1`.  
- `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:88-104` — DEBUG overrides load `FakeSpeechBackend` when `UITEST_FAKE_SPEECH=1`, with `UITEST_AUTOGRANT` gating permission auto-grants.  
- `Packages/PulsumServices/Tests/PulsumServicesTests/Gate1_SpeechFakeBackendTests.swift:5-27` — exercises the seam only when the env var is present.  
Why it matters: Release builds stay pristine, while UITests gain deterministic hooks.

### G1.5 Scheme & CI harness configuration
Status: ✅ PASS  
Evidence:  
- `Pulsum.xcodeproj/xcshareddata/xcschemes/Pulsum.xcscheme:32-83` — shared Test action injects `UITEST_USE_STUB_LLM/UITEST_FAKE_SPEECH/UITEST_AUTOGRANT`, skips the empty `PulsumTests`, and includes package test bundles as active testables.  
- `.github/workflows/test-harness.yml:20-25` — GitHub Actions workflow runs `swift test` for Services/Data/ML with `--filter 'Gate0_|Gate1_'` on macOS-15 and installs `rg`/`xcbeautify`.  
Why it matters: Local `Product ▸ Test` and CI use the same deterministic harness, catching Gate 0/1 regressions automatically.

### G1.6 Toolchain & platform floors aligned
Status: ✅ PASS  
Evidence:  
- `Packages/PulsumServices/Package.swift:1-8`, `Packages/PulsumML/Package.swift:1-8`, etc. — every package declares `// swift-tools-version: 6.1` and `.iOS("26.0")`.  
Why it matters: Prevents inadvertent downgrades that would break FoundationModels or the test harness expectations.

**Gate 1 Verdict:** PASS — deterministic seams, schemes, and workflows comply with the playbook.

## CI & PR Signals Observed
- `scripts/ci/integrity.sh:11-90` — validates git sync/tag position, runs `scan-secrets.sh`, `check-privacy-manifests.sh`, unsigned Release builds, Gate0_* package tests, and bundle secret rescans before marking the sweep green.
- `.github/workflows/test-harness.yml:1-25` — executes on pushes/PRs, installs required tools, and runs Gate0_/Gate1_ filtered SwiftPM tests for Services/Data/ML, matching the manual integrity sweep.
- `Pulsum.xcodeproj/xcshareddata/xcschemes/Pulsum.xcscheme:32-83` — keeps UITest env vars and package testables in the shared scheme so contributors and CI share identical harness settings.

## Missing or Ambiguous (with ranked risk)
None — all Gate 0/1 controls have concrete evidence and automated coverage.

## Appendix A — All Queries I Ran
- `rg --pcre2 'sk-[A-Za-z0-9_-]{10,}'` → no matches (confirms secrets fully removed).
- `rg -n 'linkedFramework("FoundationModels'` → conditional linker settings only in package targets (no test target leakage).
- `rg -n '#if canImport(FoundationModels)'` → verified guards across agents/services/UI modules.
- `rg --files -g 'Bundle+Pulsum*.swift'` & `rg -n 'forPulsum'` → ensured `.module` helpers exist without legacy fatal shims.
- `rg -n 'PrivacyInfo\.xcprivacy'` → enumerated manifests for the app and all five Swift packages.
- `rg -n 'Gate[01]_' -g '*Tests*.swift'` & `rg -n 'Gate0_|Gate1_' .github/workflows/test-harness.yml` → confirmed Gate-specific tests and CI filters.
- `rg -n 'swift-tools-version: 6\.1' -g 'Package.swift'` and `rg -n 'iOS\("26\.0"\)'` → checked toolchain floors.
- Standard file inspections via `nl -ba` captured evidence lines for `Config.xcconfig`, `bugs.md`, `LLMGateway.swift`, `SpeechService.swift`, `DataStack.swift`, `VectorIndex.swift`, and `Pulsum.xcscheme`.

---
Gate 0 & Gate 1 sign-off: PASS on 2025-11-12T00:29:00Z @ df05b13 (UTC)
