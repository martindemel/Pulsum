# Pulsum Architecture Snapshot

## Core Principles
- Agent-first wellness platform where a single `AgentOrchestrator` coordinates specialized agents (Data, Sentiment, Coach, Safety, Cheer) to keep all decision-making ML-driven and consistent with privacy policies.
- ML-over-rules philosophy: recommendations, chat tone, and scoring rely on learned models (StateEstimator, RecRanker, AFM-guided generation) with deterministic logic limited to statistical baselining.
- Privacy-first execution: health data, transcripts, embeddings, and vector indexes stay on-device under `NSFileProtectionComplete`; GPT-5 cloud calls only occur with explicit consent and minimal context.
- Targeting iOS 26+/Swift 6 strict concurrency with @MainActor view models, actors, and Sendable-safe APIs to align with Apple Intelligence requirements.

## Package Layout
- `PulsumUI`: SwiftUI surfaces (Main, Coach, Pulse, Settings, Safety) that render the Liquid Glass design, integrate a Spline scene, and bind to @MainActor view models.
- `PulsumAgents`: Agent system with orchestrator façade plus DataAgent (HealthKit ingest & analytics), SentimentAgent (speech-to-text, PII redaction, AFM sentiment), CoachAgent (RAG + pairwise ranking), SafetyAgent (dual-provider classification & guardrails), and CheerAgent (positive feedback).
- `PulsumData`: Core Data stack, binary vector index (16 memory-mapped shards), LibraryImporter, and evidence scoring utilities.
- `PulsumServices`: HealthKitService (anchored queries, observers), SpeechService (SpeechAnalyzer/SpeechTranscriber APIs with fallbacks), LLMGateway (consent-gated GPT-5 access), and supporting infrastructure.
- `PulsumML`: BaselineMath (median/MAD z-scores, EWMA λ=0.2), StateEstimator (online ridge regression), RecRanker (pairwise logistic scorer), SafetyLocal classifiers, and AFM availability helpers.

## Agent & Data Flow
1. HealthKit background delivery triggers DataAgent via HealthKitService; readings flow through StateEstimator to update Core Data entities (`DailyMetrics`, `Baseline`, `FeatureVector`).
2. Journaling begins in PulseView; SpeechService performs on-device STT, SentimentAgent redacts PII, computes sentiment, generates embeddings, and persists `JournalEntry` + vector index entries.
3. CoachAgent retrieves micro-moments (`MicroMoment`, `LibraryIngest`), runs vector search, applies RecRanker, and produces evidence-scored recommendations.
4. AgentOrchestrator exposes async interfaces for UI: `recommendations`, `chat`, `scoreBreakdown`, orchestrating SafetyAgent checks, CheerAgent responses, and consent-aware LLMGateway calls.
5. Two-Wall guardrails and deterministic intent routing ensure topic classification, safety gating (Wall-1 topic + Wall-2 safety), and crisis escalation before any cloud submission.

## Data & Storage Model
- Core Data entities cover objective metrics (`DailyMetrics`, `Baseline`, `FeatureVector`), subjective inputs (`JournalEntry`, `RecommendationEvent`), personalization (`UserPrefs`, `ConsentState`), and content libraries (`MicroMoment`, `LibraryIngest`).
- Vector embeddings persist to shard files in `Application Support/VectorIndex/` with checksums to avoid duplicate ingest; evidence scoring tags recommendations as Strong/Medium/Weak based on domain heuristics.
- LibraryImporter normalizes JSON assets (e.g., `json database/podcastrecommendations*.json`) and maintains ingest metadata for reproducibility.

## ML & Foundation Models Pipeline
- Primary inference uses Apple Foundation Models: guided sentiment classification, safety analysis, and coaching generation via `LanguageModelSession` with structured @Generable prompts.
- NLContextualEmbedding supplies contextual vectors; a bundled Core ML 384-d fallback keeps embeddings on-device when AFM unavailable.
- RecRanker and StateEstimator supply personalization, while Foundation Models availability helpers expose readiness states for UI display and fallback messaging.
- GPT-5 cloud access is strictly consent-gated through LLMGateway; payloads omit PHI and degrade gracefully to on-device generation when consent is revoked or network absent.

## UI Architecture
- SwiftUI scenes live under `PulsumUI`, each with dedicated @MainActor view models that call AgentOrchestrator asynchronously and expose loading/progress states.
- MainView hosts the SplineRuntime scene (cloud-first with local fallback), bottom controls, and navigation targets (PulseView, SettingsView).
- SettingsView surfaces consent toggles, Foundation Models availability, and score breakdowns; SafetyCardView presents crisis messaging when SafetyAgent blocks cloud flow.
- Accessibility and localization scaffolding (Dynamic Type, VoiceOver labels, localization-ready strings) are baked into Milestone 4 deliverables.

## Privacy, Safety, and Compliance
- ConsentState governs any cloud interaction; SafetyAgent vetoes dangerous content, triggering CrisisCard messaging and on-device-only handling.
- Keychain secures sensitive tokens; PHI never enters iCloud backups; Privacy Manifests (planned for Milestone 5) will document Required-Reason APIs for each package and dependency.
- Two-Wall guardrails plus cautious copy tone keep coaching supportive, short, and evidence-backed while preventing diagnosis or risky directives.

## Quality & Risk Snapshot
- Active stabilization phase: functionality is under review for regressions despite prior milestones reporting complete; expect drift between docs and implementation.
- Critical issues flagged October 23, 2025: outdated and misaligned tests across 18 files, Xcode scheme omitting Swift Package tests, and missing Core Data model resources that can break app launch.
- Key pipelines needing validation: new voice journal streaming APIs, CoachReplyPayload `nextAction` schema, Foundation Models fallback cascades, and background HealthKit delivery robustness.
- Compliance backlog remains: Privacy Manifests for all targets, SpeechAnalyzer/SpeechTranscriber adoption, and BGTaskScheduler integration are planned but not implemented.
