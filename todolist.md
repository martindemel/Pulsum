# Pulsum Production Build - TODO

## Milestone 0 - Repository Audit (Complete)
- [x] Reviewed all existing source files (`PulsumApp.swift`, `ContentView.swift`, `Persistence.swift`, Core Data model, assets)
- [x] Inspected Xcode project settings (`Pulsum.xcodeproj`, workspace state, schemes)
- [x] Cataloged support materials (`ios support documents`, `ios support files/glow.swift`, `json database/podcastrecommendations (38).json`, media assets)
- Notes: Project currently reflects default SwiftUI + Core Data template; no production features implemented yet.

## Milestone 1 - Architecture & Scaffolding (Complete)
- [x] Document target modules (`PulsumUI`, `PulsumAgents`, `PulsumData`, `PulsumServices`, `PulsumML`) with clear responsibilities, public interfaces, and dependency directions (`Docs/architecture_and_scaffolding.md`)
- [x] Specify desired Xcode target + Swift Package structure (shared code, app target wiring, testing targets) and scaffold local packages under `Packages/`
- [x] Enumerate all third-party Swift Packages (SplineRuntime, potential AFM wrappers, Core ML models) and integration strategy
- [x] Define required capabilities/entitlements (HealthKit read, Speech Recognition, Microphone, Keychain Sharing, Background Modes) and project configuration updates (bundle ID variations, provisioning impacts)
- [x] Plan persistence foundations: Core Data model evolution, NSPersistentContainer configuration (Application Support path, `NSFileProtectionComplete`, migration policy), vector index directory layout (`Application Support/VectorIndex/`)
- [x] Outline consent/secrets configuration: on-device flags, injected API key handling (Keychain), feature gating for cloud processing, Privacy Manifest requirements
- Notes: Swift package scaffolding includes placeholder types/tests to keep build graph intact pending implementation.

## Milestone 2 - Data & Services Foundations (Complete)
- [x] Implement Core Data schema covering all specified entities with migration-ready model versioning (`Pulsum.xcdatamodeld` updated)
- [x] Build persistence layer (PersistentContainer wrapper with file protection, background contexts, batching utilities) (`Packages/PulsumData/Sources/PulsumData/DataStack.swift`)
- [x] Create HealthKit service scaffolding (authorization flow, HKAnchoredObjectQuery/HKObserverQuery management, anchor persistence) (`Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift` + `HealthKitAnchorStore.swift`)
- [x] Establish JSON/asset ingestion pipeline (LibraryImporter, EvidenceScorer wiring, local file protection)
- [x] Upgrade vector index storage to true memory-mapped shard files with efficient L2 search (replace current serialized dictionary approach) (`Packages/PulsumData/Sources/PulsumData/VectorIndex*.swift`)
- [x] Replace deterministic hash fallback with bundled AFM/Core ML sentence embedding fallback (384-dimension) (`Packages/PulsumML/Sources/PulsumML/Embedding/*`)
- [x] Validate secure storage practices (Keychain usage for secrets, exclusion of PHI from iCloud backups)

## Milestone 3 - Foundation Models Agent System Implementation (✅ VERIFIED COMPLETE + SWIFT 6 HARDENED)
- [x] Delete existing agent package and rebuild Foundation Models-first architecture
- [x] Update all package platforms to iOS 26+ for Foundation Models support (`Package.swift` files across all packages)
- [x] Add FoundationModels framework dependencies to PulsumML and PulsumServices packages
- [x] Convert SentimentProviding protocol to async interface for Foundation Models integration
- [x] Implement FoundationModelsSentimentProvider with guided generation using @Generable structs (`Packages/PulsumML/Sources/PulsumML/Sentiment/FoundationModelsSentimentProvider.swift`)
- [x] Create FoundationModelsCoachGenerator using LanguageModelSession for text generation (`Packages/PulsumServices/Sources/PulsumServices/FoundationModelsCoachGenerator.swift`)
- [x] Add FoundationModelsSafetyProvider with structured safety classification (`Packages/PulsumML/Sources/PulsumML/Safety/FoundationModelsSafetyProvider.swift`)
- [x] Rebuild AgentOrchestrator with Foundation Models coordination and availability checking (`Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`)
- [x] Rebuild DataAgent with improved async Core Data operations preserving sophisticated HealthKit processing (`Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`)
- [x] Rebuild SentimentAgent with async Foundation Models sentiment analysis (`Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift`)
- [x] Rebuild CoachAgent with Foundation Models intelligent caution assessment (`Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift`)
- [x] Rebuild SafetyAgent with Foundation Models primary and fallback to existing classifier (`Packages/PulsumAgents/Sources/PulsumAgents/SafetyAgent.swift`)
- [x] Implement CheerAgent with async interface (`Packages/PulsumAgents/Sources/PulsumAgents/CheerAgent.swift`)
- [x] Add Foundation Models availability utilities (`Packages/PulsumML/Sources/PulsumML/AFM/FoundationModelsAvailability.swift`)
- [x] Update contextual embeddings provider to use NLContextualEmbedding instead of legacy word embeddings
- [x] Create comprehensive Foundation Models test infrastructure with async test methods
- [x] Ensure graceful fallbacks when Foundation Models unavailable on older devices or when Apple Intelligence disabled
- [x] **Swift 6 Concurrency Hardening**: Apply @Sendable conformances, actor-safe patterns, eliminate all concurrency warnings (10 files, +67/-30 lines)
- [x] **Testing Verification**: All test suites pass with zero Swift 6 concurrency warnings across PulsumML, PulsumServices, and PulsumAgents packages
- Notes: Milestone 3 is production-hardened with Swift 6 compliance. Ready for Milestone 4 UI integration.

## Milestone 4 - UI & Experience Build (✅ COMPLETE - September 30, 2025)
- [x] Create SwiftUI feature surfaces: MainView (SplineRuntime scene + segmented control + header), CoachView (cards + chat), PulseView (slide-to-record + sliders + countdown), SettingsView (consent toggles + Foundation Models status), SafetyCardView, JournalRecorder components (`Packages/PulsumUI`)
- [x] Remove legacy template `ContentView.swift` / `Persistence.swift` (Item entity) and wire PulsumUI entry point into app target
- [x] Apply Liquid Glass design language from support docs to chrome, bottom controls, AI button, and sheets
- [x] Wire voice recording transparency (indicator + countdown) and navigation flows (Pulse button, avatar to settings, AI button focusing chat)
- [x] Integrate SplineRuntime (cloud URL + local fallback) and handle offline fallback asset
- [x] **Create @MainActor view models** binding to AgentOrchestrator with async/await patterns for all agent operations
- [x] Connect UI with AgentOrchestrator (single orchestrator, not individual agents) for recommendations, chat, journaling, consent banner (exact copy), and safety surfacing
- [x] **Display Foundation Models availability status** in SettingsView with user-friendly messaging (ready/downloading/needs Apple Intelligence)
- [x] **Implement loading states** for async Foundation Models operations (sentiment analysis, safety classification, coaching generation)
- [x] **Add fallback messaging** when Foundation Models unavailable (e.g., "Enhanced AI features require Apple Intelligence. Using on-device intelligence.")
- [x] Address accessibility/localization scaffolding (Dynamic Type, VoiceOver labels, localization-ready strings)
- [x] **Validate async/await error handling** in UI layer for Foundation Models operations (guardrails, refusals, timeouts)
- [x] **Migrate to SpeechAnalyzer/SpeechTranscriber APIs** (iOS 26+) with SFSpeechRecognizer fallback for compatibility (2-3 days; official replacement for live STT)
- Notes: Milestone 4 complete with production-ready UI (10 files, ~1,500 lines). All views implemented with @MainActor view models, Liquid Glass design, Foundation Models integration, SplineRuntime 3D scene, and comprehensive error handling. Ready for Milestone 5 privacy compliance.

### Recent additions
- [x] Added score breakdown detail screen in Settings with objective vs. subjective contributions, rolling baselines, and imputation notes.
- [x] Exposed `AgentOrchestrator.scoreBreakdown()` for UI consumption of feature vectors, contributions, and baseline metadata.
- [x] Updated `LibraryImporter` to fall back to root bundle resources when the "json database" subdirectory is missing (supports relocated `podcastrecommendations.json`).

## Milestone 4.5 - Two-Wall Guardrails & Intent-Aware Chat (✅ COMPLETE - October 3, 2025)
- [x] **Deterministic Intent Mapping (4-step override pipeline)**: Eliminated "wobble" in topic→topSignal selection
  - Step 1: Wall-1 topic classification (sleep, stress, energy, hrv, mood, movement, mindfulness, goals, greetings)
  - Step 2: Phrase override with substring matching (e.g., "rmssd" → hrv, "insomnia" → sleep, "micro" → goals)
  - Step 3: Candidate moments override using top-2 retrieval with keyword scoring
  - Step 4: Data-dominant fallback choosing signal with highest |z-score|
- [x] **Extended TopicGate HRV vocabulary**: Added "rmssd", "vagal tone", "parasympathetic", "recovery" to embedding prototypes
- [x] **Coverage robustness for sparse indexes**:
  - Floor 1: Require ≥3 matches (reject if less)
  - Floor 2: Median similarity ≥0.25 absolute floor
  - Used 1/(1+d) bounded transformation for robust scoring
- [x] **Wired nextAction end-to-end**: Created CoachReplyPayload struct, updated all protocols/implementations (CloudLLMClient, OnDeviceCoachGenerator, LLMGateway, CoachAgent, AgentOrchestrator)
- [x] **Verified Responses API payload correctness**: Confirmed no legacy parameters (no response_format, no modalities), using text.format with json_schema
- [x] **Fixed test suite compatibility**: Updated MockCloudClient, MockLocalGenerator, and LLMGatewayTests for CoachReplyPayload
- [x] **Updated documentation**:
  - instructions.md: Added Two-Wall Guardrails and Deterministic Intent Routing section
  - architecture.md: Enhanced CoachAgent Chat Pipeline with full 7-step Wall-1/Wall-2 breakdown
  - todolist.md: Documented Milestone 4.5 completion
- [x] **Validation**: All package tests pass (PulsumML: 14 tests, PulsumServices: 14 tests, PulsumAgents: 7 tests), app builds successfully
- Notes: Chat system now produces smart, intent-aware coaching with fail-closed Two-Wall guardrails and ML-only outputs (no rule engines). Ready for Milestone 5 privacy compliance.

## Gate 5 - Vector index & data I/O integrity (✅ COMPLETE - November 20, 2025)
- [x] Actorized `VectorIndex`/`VectorIndexManager`, guarded shard cache with a single critical section, and removed `@unchecked Sendable` cruft.
- [x] Wrapped shard file-handle work in `withHandle` to close exactly once and surface `VectorIndexError.ioFailure` on close failures.
- [x] Refactored `LibraryImporter.ingestIfNeeded()` to discover URLs, load/decode JSON off the main actor via detached task, run Core Data upserts on a background context, index outside Core Data with injected `VectorIndexProviding`, and persist checksum only after successful indexing.
- [x] Relocated canonical `Pulsum.xcdatamodeld` under `Packages/PulsumData/Sources/PulsumData/Resources/` and load via `Bundle.pulsumDataResources`.
- [x] Deduplicated podcast dataset to the single canonical `podcastrecommendations 2.json`; enforced hash uniqueness and banned `*.pbxproj.backup` in `scripts/ci/integrity.sh` and `scripts/ci/test-harness.sh`.
- [x] Added Gate5 suites (concurrency, file-handle failure, manager actor, importer perf/atomicity) and run package build/tests with `-Xswiftc -strict-concurrency=complete`.

## Gate 6 – Diagnostics Logging Upgrade (First-run stall investigation)
### A) PulsumTypes: Structured diagnostics layer
- [x] A1: Add DiagnosticsLevel/DiagnosticsCategory/DiagnosticsSafeString/DiagnosticsValue/DiagnosticsEvent types (Codable + Sendable), enforcing safe string/value rules.
- [x] A2: Implement DiagnosticsConfig (UserDefaults-backed) with DEBUG/RELEASE defaults and persistence flags.
- [x] A3: Build DiagnosticsLogger actor (singleton) with DebugLogBuffer mirroring, OSLog mirroring, rolling file persistence (protected, backup-excluded, rotation, batched flush), non-async front-door API.
- [x] A4: Add span helpers (DiagnosticsSpanToken, measure/span, os_signpost integration) with duration_ms.
- [x] A5: Create DiagnosticsStallMonitor (heartbeat + stall warn) and wire for backfill/pending work loops.

### B) Instrument first-run critical path
- [x] B0: Emit timeline.firstRun.start/checkpoint/end with coherent reasoning for “needs more time/analyzing”.
- [x] B1: AppViewModel lifecycle/session events with session_id and environment fields.
- [x] B2: AgentOrchestrator start spans/checkpoints (health access summary, embeddings availability, pending journals, deferred library import).
- [x] B3: EmbeddingService availability probes/changes/failures events.
- [x] B4: SentimentAgent persistence/reprocess/pending embedding instrumentation + stall monitor heartbeats.
- [x] B5: DataAgent/HealthKit bootstrap/backfill status/batch instrumentation + stall monitors + snapshot publish events.
- [x] B6: LibraryImporter/VectorIndex stats/import/deferred/retry instrumentation + stall monitors.
- [x] B7: CoachAgent recommendation/feedback instrumentation.
- [x] B8: UI wellbeing/analysis state transition events (including timeline.firstRun.end reasons).

### C) Settings UI controls + export
- [x] C1: Surface diagnostics config (enabled/minLevel/persistence/signposts/OSLog), session_id display, export diagnostics report (header + snapshot + log tails), and clear diagnostics (buffer + files) with warning copy.

### D) Remove/replace unsafe prints
- [x] D1: Remove or replace prints/unsafe logging (especially SafetyLocal) with safe Diagnostics events.

### TESTS
- [x] T1: PulsumTypesTests for formatting (single-line with session_id), file rotation/maxFiles, backup exclusion/file protection attempts, export report contents, forbidden-substring guard; keep DebugLogBufferTests passing.

### DOCS
- [x] Doc1: Update architecture/README to document on-device diagnostics, opt-in persistence, export flow, and privacy guarantees.

### Verification follow-up
- [x] Gate6 diagnostics hardening: actorized stall monitor, enforced single timeline start/end, and moved exports to protected Application Support/Diagnostics with backup exclusion.

## Gate 0 - Security & Build Blockers (✅ COMPLETE - November 9, 2025)
- [x] Remove Info.plist/OpenAI key paths, harden `LLMGateway` to Keychain/environment only, and add repo/binary secret scans (`scripts/ci/scan-secrets.sh`, LLMGateway precedence tests) — fixes BUG-20251026-0001.
- [x] Add PrivacyInfo manifests for app + all packages (XML plist format) and enforce them via `scripts/ci/check-privacy-manifests.sh` with optional `RUN_PRIVACY_REPORT=1` — fixes BUG-20251026-0002.
- [x] Wire `com.apple.developer.speech` entitlement, preflight microphone permission in `SpeechService`, and guard PHI logging with DEBUG-only markers/tests — fixes BUG-20251026-0003/0006/0033.
- [x] Enforce backup exclusion + typed AFM stubs + PulseView UIKit guard, then verify Release builds via `scripts/ci/build-release.sh` (signing disabled for CI) and `xcodebuild -scheme Pulsum -sdk iphonesimulator -configuration Release build` — fixes BUG-20251026-0018/0019/0035.

Next focus: Gate 1 (test harness on) — see Milestone 6 tasks for adding package test bundles to the shared scheme and authoring real UITests.

## Milestone 5 - Safety, Consent, Privacy Compliance (Planned)
- [ ] Implement consent UX/state persistence (`UserPrefs`, `ConsentState`) including cloud-processing banner copy, toggle, and revocation flow
- [ ] Enforce privacy routing: PHI on-device only, minimized cloud payloads, offline fallbacks, and SafetyAgent veto on risky content
- [ ] Produce Privacy Manifest + Info.plist declarations (Health/Mic/Speech reasons already present), App Privacy nutrition labels, and Background Modes (HealthKit delivery) configuration
- [x] Validate data protection end-to-end (NSFileProtectionComplete, background/interrupt behavior, journal retention policies, deletion affordances) — `DataStack` now surfaces backup failures and the app blocks sensitive flows until storage is secured.
- [ ] Surface SafetyAgent escalations in UI (CrisisCard with 911 copy) and ensure no risky text reaches GPT-5 or Foundation Models
- [ ] Security review covering Keychain secrets, health data isolation, background delivery configuration, and Spline asset handling
- [ ] **Verify Foundation Models privacy compliance**: Confirm no PHI in Foundation Models prompts, minimized context only, proper guardrail handling
- [x] **Create Privacy Manifests (PrivacyInfo.xcprivacy)** for main app and all packages (PulsumData, PulsumServices, PulsumML, PulsumAgents) with Required-Reason API declarations (MANDATORY for App Store) — verified via `scripts/ci/check-privacy-manifests.sh`.
- [ ] **Aggregate SDK privacy manifests** from third-party dependencies (SplineRuntime, any others)
- Notes: Milestone 3 already implements privacy architecture (NSFileProtectionComplete, PII redaction, consent routing). Milestone 5 focuses on UI wiring, compliance validation, and Privacy Manifest creation.

## Milestone 6 - QA, Testing, and Release Prep (In Progress)
- [x] Ensure PulsumAgents/PulsumServices/PulsumData/PulsumML test bundles are added to the shared Xcode scheme so Product ▸ Test + CI exercise package suites.
- [x] Replace placeholder UITests with real end-to-end coverage (onboarding permissions, journaling begin/stream/finish, consent toggles, coach chat, score refresh).
- [x] Gate 6 stabilization: embedding availability probe (AFM opportunistic, CoreML fallback) powers chat coverage and insights banners without false “generator unavailable”; zero-vector ban enforced.
- [x] Wellbeing score state machine (loading/ready/no data/error) plus HealthKit request wiring so “Calculating…” no longer spins when data/permissions are missing; Settings/Main show actionable messaging.
- [x] HealthKit request/status refresh uses the shared service and updates Settings/Main after authorization; request button disables when HealthKit is unavailable.
- [x] Embedding availability self-heals after cooldown/AFM readiness; journals persist with `embeddingPending` when embeddings fail; RecRanker state now persists across launches.
- [x] Restore 30-day HealthKit coverage with phased backfill: 2-day bootstrap for first score, then 7-day warm-start + persisted background batches to 30 days without blocking UI; debounced snapshot notifications. Added `BackfillStateStore` + `Gate6_WellbeingBackfillPhasingTests` to lock behavior.
- [ ] Expand automated tests: unit coverage for agents/services/ML math, UI snapshot tests, end-to-end smoke tests with mocks
- [ ] **Add Foundation Models-specific tests**: guided generation validation, @Generable struct parsing, temperature behavior, guardrail handling
- [ ] **Validate Swift 6 concurrency compliance**: Verify zero warnings in all packages, proper @Sendable usage, actor isolation correctness
- [ ] Execute integration tests for HealthKit ingestion (mocked anchors), Speech STT transcription, and vector index retrieval
- [ ] **Test Foundation Models availability states**: Apple Intelligence enabled/disabled, model downloading, device not supported, graceful fallbacks
- [ ] **Test dual-provider fallbacks**: Foundation Models → Legacy cascades for sentiment, safety, coaching when AFM unavailable
- [ ] Profile performance (startup, memory, energy), fix regressions, and validate on multiple device families
- [ ] **Profile Foundation Models operations**: Measure latency for sentiment analysis, safety classification, coaching generation vs fallbacks
- [ ] Produce final assets: Liquid Glass screenshots, App Icon variants, App Store metadata, localized descriptions
- [ ] Assemble compliance documentation (privacy disclosures, data retention, support contacts) and verify App Privacy answers
- [ ] **Document Foundation Models features** in App Store metadata: "Powered by Apple Intelligence for intelligent health insights"
- [ ] Prepare release pipeline: TestFlight build, release notes, reviewer instructions, versioning strategy, and rollout checklist
- [ ] **Prepare iOS 26 SDK validation**: Test on devices with Apple Intelligence enabled, verify Foundation Models activation
- [ ] **Profile @MainActor agent operations**: Measure UI responsiveness during Foundation Models operations; if >100ms lag detected, refactor ML ranking/embeddings to background actors (conditional optimization)
- [ ] **Evaluate BGTaskScheduler integration**: Monitor HealthKit background processing reliability in production; implement BGProcessingTask if observer callbacks show timeouts or battery impact (conditional enhancement)

### New follow-up
- [ ] Clean up legacy episode metadata in recommendation content: keep JSON as-is for now, but remove stored/displayed episode numbers/titles (e.g., “Episode #200: Arnold’s Pump Club...”) from micro-moment details. Ingestion no longer writes these headers and UI strips any existing ones; consider a reingest/cleanup task post-release to purge legacy episode lines from Core Data/vector index.

## Gate 3 - HealthKit ingestion & UI freshness (Complete)
- [x] Add `HealthAccessStatus` caching + `HealthKitServicing.authorizationStatus(for:)` to gate observers per-type and capture denied/notDetermined states.
- [x] Expose `requestHealthAccess()` / `restartIngestionAfterPermissionsChange()` so Settings/Onboarding can idempotently rebuild observers after the user re-grants data types.
- [x] Emit a unified `.pulsumScoresUpdated` notification whenever `DataAgent` recomputes a snapshot; bind App/Coach view models so journals, sliders, and HealthKit ingestion refresh the UI immediately.
- [x] Redesign Settings + Onboarding health sections to show 6/6 status, missing-type copy, toast feedback, and a real “Request Health Access” flow wired to the orchestrator.
- [x] Extend UITests with deterministic HealthKit seams (`PULSUM_HEALTHKIT_STATUS_OVERRIDE`, `PULSUM_HEALTHKIT_REQUEST_BEHAVIOR`) and add `Gate3_HealthAccessUITests`.
- [x] Add Gate3_* package tests (authorization gating, restart idempotence, freshness bus seam) under `Packages/PulsumAgents`.

### Gate 2/3 follow-ups
- [x] Expand UITests to cover real cloud consent flows once Settings surfaces runtime key entry and API health (Gate 4 — `Gate4_CloudConsentUITests` exercises Save/Test + Apple Intelligence fallback).
- [x] Add journal transcript persistence + Saved toast assertions after BUG-0009 is resolved (Gate 2). (`JournalFlowUITests.testRecordStreamFinish_showsSavedToastAndTranscript`)
- [x] Wire Gate Gate suites into CI via `scripts/ci/test-harness.sh`, `scripts/ci/integrity.sh`, and `.github/workflows/test-harness.yml` so Gate 0/1/2 (and future gates) run automatically.
- [x] Gate3 package + UI tests now live; harness auto-detects them via the existing regex (`Gate3_*`).
