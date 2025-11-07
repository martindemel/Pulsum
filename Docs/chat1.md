# Pulsum Project – Progress Summary (Chat Session)

## Context
- Role: Principal iOS architect implementing Pulsum per `instructions.md` spec (iOS 26, Liquid Glass, agent-first).
- Milestones 0–2 completed; Milestone 3 currently in progress with substantial groundwork in place.

## Milestone 0 – Repository Audit
- Read entire repo (Pulsum app template, Xcode project, assets, support docs, JSON dataset).
- Logged findings in `todolist.md`.

## Milestone 1 – Architecture & Scaffolding
- Authored `Docs/architecture_and_scaffolding.md` detailing modules, dependencies, capabilities.
- Scaffolded Swift packages: `PulsumUI`, `PulsumAgents`, `PulsumData`, `PulsumServices`, `PulsumML` (with placeholder tests removed as work progressed).
- Added Xcode project integration: local packages + remote SplineRuntime dependency (GitHub).
- Configured entitlements (`Pulsum/Pulsum.entitlements`) + Info.plist purpose strings (Health, Microphone, Speech) via project settings.
- Ensured deployment target iOS 26, `NSFileProtectionComplete` plan, consent strategy captured.

## Milestone 2 – Data & Services Foundations (Complete)
- Core Data schema expanded to all required entities (in `Pulsum.xcdatamodeld` + managed object subclasses).
- Implemented `DataStack` with Application Support paths, vector & anchor directories, backup exclusion, iOS-only file protection.
- Built `HealthKitService` + `HealthKitAnchorStore` (public) handling authorization, anchored queries, secure anchor persistence.
- Added `SpeechService` scaffolding (on-device STT, iOS-only AVAudioSession handling).
- Created Library ingestion (`LibraryImporter`, `EvidenceScorer`) parsing podcast JSON into MicroMoments with evidence badges, vector embeddings.
- Implemented sharded memory-mapped vector index (`VectorIndex`, `VectorIndexManager`) with L2 search and file protection.
- Built `EmbeddingService` with AFM primary (`AFMTextEmbeddingProvider`) and bundled fallback Core ML embedding `PulsumFallbackEmbedding.mlmodel` (generated via CreateML script) plus tests.
- Added `KeychainService` for secrets; tests for anchors/keychain/gateway run successfully (`swift test` for PulsumServices & PulsumML packages).
- Updated Xcode project to include entitlements, Info.plist strings, package references, SplineRuntime dependency.

## Milestone 3 – Agent System (In Progress)

### DataAgent Status
- **Scope implemented**
  - Swapped template logic for the science-backed pipeline described in `instructions.md`.
  - Observes HealthKit quantity/category types (HRV SDNN, heart rate, resting HR, respiratory rate, steps, sleep analysis) using `HealthKitService` anchored queries.
  - Persists raw samples per-day inside `DailyFlags` (HRV, heart rate, respiratory, sleep segments, step buckets) to support re-computation and fallbacks.
  - Derives nightly metrics:
    - HRV median during sleep; falls back to sedentary windows or previous day when necessary.
    - Nocturnal heart-rate 10th percentile with same fallback behaviour.
    - Resting heart rate preferring HealthKit’s explicit samples, otherwise low-activity windows.
    - Sleep totals and sleep debt (personalized need based on recent averages, 7-day rolling debt, EWMA smoothing).
    - Respiratory rate averages from sleep/or overall.
    - Daily steps (sedentary detection uses step buckets to identify fallback windows).
  - Computes baselines via 30-day median/MAD z-scores (`BaselineMath`), includes step & respiratory gating, stores results in `DailyMetrics` + `Baseline` entities.
  - Writes feature vectors with z-scores + subjective sliders + sentiment, persists imputation metadata + contributions via JSON payload (for analytics/coach context).
  - Integrates `StateEstimator` nightly (online ridge regression) to produce WellbeingScore and feature contributions.
  - Handles subjective sliders (stress, energy, sleep quality) updates and triggers reprocessing for consistency.
- **Remaining gaps**
  - Address Swift actor warnings (`context.perform` closures capturing self) and ensure reprocessDay calls use `await` or restructure to avoid cross-actor sync.
  - Add final gating rules (e.g., low-confidence flags widening estimator variance) and ensure sedation thresholds align exactly with spec (20–30 steps/hour guidance).
  - Unit tests needed (requires packaging Core Data model for SwiftPM tests or using in-memory store fixtures).

### SentimentAgent Status
- Implemented end-to-end voice journal flow:
  - Uses `SpeechService` requiring on-device recognition when available, obeys max 30s, cleans up audio session on iOS only.
  - Sanitizes transcript via PII redactor (emails, phone numbers, NL personal-name tagging) before persistence or cloud usage.
  - Computes sentiment with `NLTagger` (AFM sentiment model still to integrate) and stores transcript/sentiment in Core Data (`JournalEntry` + `FeatureVector` sentiment field).
  - Embeds sanitized text via `EmbeddingService` (AFM primary, bundled Core ML fallback) and writes vector to Application Support with `NSFileProtectionComplete`.
- **TODOs**
  - Replace `NLTagger` sentiment scoring with AFM sentiment model per spec (e.g., on-device Foundation model or CreateML sentiment classifier).
  - Resolve actor warnings in persistence path (`context.perform` is async, nonisolated helper added but needs review).
  - Build unit tests (mock speech service + verifying PII redaction and sentiment embedding pipeline).

### CoachAgent Status
- Library ingestion already done; CoachAgent now performs:
  - Vector search via `VectorIndexManager` (top-k micro-moments) using z-score context summary.
  - Computes candidate features: evidence strength, novelty (1 - acceptance rate), cooldown, time-cost fit, plus distance-based similarity to blend with novelty.
  - Passes features to `RecRanker` for pairwise ranking; selects top three cards.
  - Builds card bodies with detail + cooldown note; caution messaging for harder routines/injury category.
  - Chat response builds `CoachLLMContext` with rationale/z-score summary and defers to `LLMGateway` (cloud or AFM fallback).
- **Pending**
  - Address sendable warnings: mark Core Data fetch closures `@MainActor` or use `@preconcurrency` (already added) plus ensure asynchronous context uses `await` properly.
  - Add historical acceptance/cooldown memory beyond simple rate if required (e.g., learning rate updates to `RecRanker`).
  - Unit tests for ranking logic (tie to library importer sample data).

### SafetyAgent Status
- Now leverages `SafetyLocal` (AFM embedding-based classifier with prototypes for crisis/caution/safe) plus keyword triggers.
- Returns `SafetyDecision` controlling cloud allowance and crisis messaging; orchestrator awaits evaluation before GPT-5 usage.
- **Future work:** potentially swap to a trained Core ML text classifier for caution/crisis detection and expand prototype set from curated dataset.

### CheerAgent Status
- Generates contextual reinforcement events: time-of-day categorization (morning/midday/evening/late) + affirmation pool, sets haptic style (success or light) and timestamp.
- Provides data to UI layer for toasts + haptics once UI is built.

### LLMGateway Status
- Cloud path unchanged (GPT-5 stub).
- Replaced Markov fallback with AFM-driven `AFMLocalCoachGenerator` that selects phrases based on cosine similarity to top signals/rationale embeddings.
- Ensures sanitized responses (≤2 sentences, trimmed).
- Tests updated (`LLMGatewayTests`) still rely on stub generator; need new tests covering AFM generator once additional fixtures added.

### AgentOrchestrator Status
- Coordinates DataAgent start, sentiment capture, recommendations, chat, and Cheering.
- Safety checks now awaited to respect actor isolation.
- On log completion, fetches moment title for CheerAgent messaging.

### Tests & Warnings
- `swift test` passes for PulsumML + PulsumServices packages with new models.
- PulsumAgents package builds successfully; `swift test` currently times out due to long compile but surfaces actor/sendable warnings. Need to resolve concurrency warnings and supply Core Data model for tests.

## Remaining Milestone 3 Tasks
1. **DataAgent** – Resolve Swift concurrency warnings (explicit `self`, restructure `context.perform`, ensure `await` usage). Confirm step gating/quality flags exactly match spec and add health confidence handling.
2. **SentimentAgent** – Integrate AFM sentiment model, finalize concurrency fixes, add automated tests.
3. **CoachAgent** – Finish RecRanker updates, add tests for card ranking, address sendable warnings.
4. **SafetyAgent** – Optionally incorporate dedicated on-device classifier; expand test coverage.
5. **CheerAgent** – Wire into UI once Milestone 4 begins; optionally expand haptic mapping.
6. **PulsumAgents Tests** – Provide Core Data model (or mocks) for SwiftPM tests to validate DataAgent/SentimentAgent/CoachAgent pipelines.

## Remaining Milestones Overview
- Milestone 3 steps above remain open; `todolist.md` reflects the exact tasks.
- Milestone 4–6 entries already aligned with `instructions.md` (Liquid Glass UI, consent flows/Privacy Manifest, QA/release prep).

## Key Artifacts
- `Docs/architecture_and_scaffolding.md` – architecture blueprint.
- `todolist.md` – current progress tracking.
- `Pulsum/Pulsum.entitlements` – HealthKit entitlements.
- `Packages/PulsumML/PulsumML/Resources/PulsumFallbackEmbedding.mlmodel` – bundled fallback embeddings.
- `chat1.md` (this file) – summary for future handoff.

## Next Steps (Milestone 3)
1. Resolve `DataAgent` actor isolation warnings (explicit `self`, `await` usage, potential restructuring of perform blocks) and ensure step gating weights align exactly with spec (sparse-friendly logic).
2. Swap NLTagger sentiment to AFM sentiment model (per instructions) and confirm embedded vectors respect PII redaction.
3. Continue CoachAgent work: integrate acceptance history weighting, ensure RecRanker online updates, add tests.
4. Finalize SafetyAgent classifier integration (potential Core ML small model) and ensure SafetyAgent interface is actor-safe.
5. Expand unit tests (PulsumAgents) once Core Data model accessible in test bundling; consider custom model bundle for SwiftPM tests.
