# Pulsum Project – Continuation Log (Chat 2)

## Milestone Status Snapshot (as of Chat 2)
- **Milestone 0 – Repository Audit:** Complete. Read entire template project, assets, and support docs.
- **Milestone 1 – Architecture & Scaffolding:** Complete. Created package layout (`PulsumUI`, `PulsumAgents`, `PulsumData`, `PulsumServices`, `PulsumML`), documented design (`Docs/architecture_and_scaffolding.md`), enabled required capabilities in Xcode project, and set up persistence strategy.
- **Milestone 2 – Data & Services Foundations:** Complete. Core Data model built; persistence stack secured (`NSFileProtectionComplete`); HealthKit, Speech, LibraryImporter, VectorIndexManager, EmbeddingService, and KeychainService implemented with tests.
- **Milestone 3 – Agent System Implementation:** Complete. Details below.
- **Milestones 4–6:** Planned. No implementation yet.

## Milestone 3 Detailed Completion Notes
### DataAgent (`Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`)
- Anchored HealthKit ingest with support for quantities (HRV SDNN, heart rate, resting HR, respiratory rate, steps) and sleep categories.
- Overnight HRV median computed from sleep intervals with sedentary fallback and imputation flags.
- Nocturnal heart-rate 10th percentile, resting HR prioritization, respiratory rate mean, step count totals, sleep debt via EWMA, and personalized sleep need (rolling window).
- Baselines: 30-day median/MAD z-scores with EWMA smoothing; stored in `Baseline` entity.
- Feature vectors persisted nightly, enriched with subjective inputs and sentiment; WellbeingScore updated via `StateEstimator`.
- Concurrency hardened: all Core Data work executed inside `await context.perform {}` with static helpers to avoid actor-isolation warnings.
- Debug hooks `_testProcessQuantitySamples`, `_testProcessCategorySamples`, `_testReprocess` enabled under `#if DEBUG` for unit testing.

### SentimentAgent (`Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift`)
- Utilizes `SpeechService` with `requiresOnDeviceRecognition` and 30 s clamp.
- Centralized PII redaction (`PIIRedactor`) before storage or cloud usage.
- Sentiment provided by new `SentimentService` cascade: Apple Foundation Models primary, optional Core ML (`PulsumSentimentCoreML`), no NLTagger fallback per updated spec.
- Embeddings stored using on-device AFM service with Core ML fallback; vectors written to Application Support with `NSFileProtectionComplete`.

### CoachAgent (`Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift`)
- Library ingestion (`LibraryImporter`) executed once; vector search via mockable `VectorIndexProviding` protocol.
- Recommendation ranking uses `RecRanker` extended for WellbeingScore + z-score features.
- Chat responses sanitize user input via `PIIRedactor`; `LLMGateway` re-sanitizes context before optional GPT-5 call.
- Core Data fetches isolated to `await context.perform {}` to eliminate sendable warnings.

### SafetyAgent & SafetyLocal
- `SafetyAgent` integrates `SafetyLocal` classifier to block cloud usage during high risk.
- `SafetyLocal` now uses `resolutionMargin` to reduce false crisis/caution positives and includes additional safe prototypes.
- Test suite expanded (`Packages/PulsumML/Tests/PulsumMLTests/SafetyLocalTests.swift`).

### CheerAgent (`Packages/PulsumAgents/Sources/PulsumAgents/CheerAgent.swift`)
- Added hooks for toast presentation, haptic triggers, and delayed dismissal via `NotificationCenter` to prepare for upcoming UI work.

### RecRanker Enhancements (`Packages/PulsumML/Sources/PulsumML/RecRanker.swift`)
- Feature vector includes z-score dictionary injection.
- Added adaptive learning APIs: `updateLearningRate`, `adaptWeights`, `getPerformanceMetrics` with supporting types (`AcceptanceHistory`, `UserFeedback`, `RankerMetrics`).

### Infrastructure & Tests
- `TestCoreDataStack.swift` synthesizes a Pulsum data model in-memory (entities: JournalEntry, DailyMetrics, Baseline, FeatureVector, MicroMoment, RecommendationEvent, UserPrefs, ConsentState).
- Unit tests cover DataAgent ingest (`DataAgentTests`), SentimentAgent redaction/persistence, CoachAgent ranking/event logging, and AgentOrchestrator safety behavior.
- `swift test` now finishes quickly for PulsumAgents; previous timeouts resolved.

### HealthKit Entitlements & Signing
- Updated `Pulsum/Pulsum.entitlements` to new format:
  - `com.apple.developer.healthkit` = true
  - `com.apple.developer.healthkit.background-delivery` = true
  - `com.apple.developer.healthkit.access` dictionary with `read` (list of HK identifiers) and empty `share` array.
- Regenerated iOS App Development provisioning profile to include HealthKit capability; guidance provided for future profile regeneration and TestFlight distribution.

## Outstanding Work (Future Milestones)
- **Milestone 4:** Implement SwiftUI surfaces (MainView, CoachView, PulseView, SettingsView, SafetyCardView, JournalRecorder) following Liquid Glass / SplineRuntime requirements; remove template ContentView; wire agents to UI.
- **Milestone 5:** Consent UX state persistence, privacy manifest, PHI routing, SafetyAgent UI integration, security review.
- **Milestone 6:** Expanded automated tests (agents/services/UI), integration tests, performance profiling, release assets, App Privacy disclosures, TestFlight/App Store readiness.

## Reference Tests & Commands
- `swift test` (Packages/PulsumAgents) – now passes (6 tests).
- `swift test --filter DataAgentTests/testIngestsSamplesAndComputesDailyMetrics`
- `swift test --filter SentimentAgentTests`
- `swift test --filter CoachAgentTests`
- `swift test --filter AgentSystemTests`
- `swift test` (Packages/PulsumML) – includes SafetyLocal coverage.

## Entitlement/Signing Notes
- After any entitlements change, regenerate provisioning profiles (iOS App Development for device testing, App Store Connect profile for TestFlight).
- HealthKit requires explicit Info.plist usage descriptions (already present) and matching App ID capability.

## Next Steps Checklist
1. Begin Milestone 4 UI build once agent wiring is finalized.
2. Create App Store Connect distribution profile before TestFlight upload.
3. Maintain `chat2.md` as ongoing log for future prompts.
