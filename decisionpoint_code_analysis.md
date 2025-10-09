Repo Root: `/Users/martin.demel/Desktop/PULSUM/Pulsum`  
Commit: `4e32e275fb3ade8751eba1f1c56939a8b25c6ff2`  
Analysis Timestamp: `2025-10-08T00:00:00Z`

---

## 1. Code Inventory by Module

### PulsumApp (target)
- `Pulsum/PulsumApp.swift:11-17` – Minimal SwiftUI `App` entry point that instantiates `PulsumRootView`. No additional logic, guaranteeing all UI flows marshal through the orchestrated Swift package stack.

### PulsumUI (`Packages/PulsumUI`)
#### Package manifest
- `Package.swift:5-37` – Declares iOS 26/macOS 14 support with dependencies on PulsumAgents, PulsumServices, and PulsumData.

#### Core view models
- `AppViewModel` (`Sources/PulsumUI/AppViewModel.swift:11-170`)  
  - `start()` (lines 86-136) lazily builds `AgentOrchestrator` via `PulsumAgents.makeOrchestrator()`, binds all child view models, and kicks off asynchronous `orchestrator.start()`.  
  - Maintains state for tab selection, consent banner, safety overlays, and sheet presentation.
- `CoachViewModel` (`Sources/PulsumUI/CoachViewModel.swift:9-147`)  
  - Handles recommendation fetching (`refreshRecommendations()`, lines 53-66), chat pipeline (`sendChat()`, lines 102-121), and cheer events (`complete`, lines 83-94).  
  - Gracefully maps Foundation Models errors to human-friendly copy in `mapError`.
- `PulseViewModel` (`Sources/PulsumUI/PulseViewModel.swift:5-130`)  
  - Drives voice journaling countdown, manages asynchronous recording via `AgentOrchestrator.recordVoiceJournal`, and surfaces safety callbacks.
- `SettingsViewModel` (`Sources/PulsumUI/SettingsViewModel.swift:7-200`)  
  - Exposes API key testing (`saveAPIKeyAndTest`) and foundation model status refresh.  
  - Observes diagnostics in DEBUG builds via NotificationCenter hooks.
- `ScoreBreakdownViewModel` (`Sources/PulsumUI/ScoreBreakdownViewModel.swift:5-73`)  
  - Retrieves detailed metric breakdowns from orchestrator and derives lift/drag highlights.

#### Views & components
- `PulsumRootView` (`Sources/PulsumUI/PulsumRootView.swift:8-200`) – Wraps the Spline/gradient background, renders consent banner, safety overlay, and bottom navigation.  
- `CoachView.swift:5-200` – Shows recommendation deck, fallback messaging, and chat transcript.  
- `PulseView.swift:1-200` – Provides recording affordances, transcript display, and slider entry.  
- `SettingsView.swift:1-200` – Houses wellbeing score card, consent toggles, HealthKit authorization panel, Foundation Models status, and GPT-5 API tester.  
- Liquid glass helpers (`GlassEffect.swift`, `LiquidGlassComponents.swift`) provide reusable translucent containers and tab bars leveraged across screens.

### PulsumAgents (`Packages/PulsumAgents`)
#### Package manifest
- `Package.swift:5-43` – Links PulsumData, PulsumServices, PulsumML; pulls in FoundationModels framework for AFM topic gate and safety provider.

#### Orchestrator & agents
- `AgentOrchestrator.swift:64-415`  
  - Constructor wires default instances for `DataAgent` (actor), `SentimentAgent`, `CoachAgent`, `SafetyAgent`, and `CheerAgent`.  
  - `performChat()` (lines 217-344) enforces Wall-1 (safety/topic gate/coverage) and sets Wall-2 grounding floors before invoking LLM.
- `DataAgent.swift:46-1390`  
  - Actor that manages HealthKit observation (`start`, lines 190-204), processes anchored updates (`processQuantitySamples`, `processCategorySamples`, `handleDeletedSamples`), and reprocesses days with feature bundle creation (`reprocessDay`, lines 361-423).  
  - Updates `StateEstimator` and persists contribution/imputation metadata per feature vector.
- `SentimentAgent.swift:10-111` – Handles speech authorization, streaming transcription, sentiment using `SentimentService`, vector embedding storage, and Core Data persistence.
- `CoachAgent.swift:12-220` – Generates recommendation cards via vector search and `RecRanker`, constructs chat context, and logs recommendation events.
- `CoachAgent+Coverage.swift:1-113` – Implements coverage heuristics (strong/soft/fail) with median similarity thresholds and sparse-data fallback.
- `SafetyAgent.swift:8-78` – Calls Foundation Models safety provider (if available) with keyword adjustments, otherwise falls back to SafetyLocal; emits `SafetyDecision`.
- `CheerAgent.swift:1-35` (not shown earlier) – Creates trotted celebratory messages/haptic hints when users mark recommendation completion.

### PulsumServices (`Packages/PulsumServices`)
#### Package manifest
- `Package.swift:5-38` – Declares dependency on PulsumData and PulsumML, links FoundationModels.

#### Key services
- `HealthKitService.swift:1-200` – Wraps read authorization, background delivery, anchored queries, and anchor persistence.  
  - `enableBackgroundDelivery()` uses task groups to request immediate frequency per type.  
  - `observeSampleType` ties observer callbacks to anchored query execution.
- `SpeechService.swift:18-238` – Defines modern speech backend wrapper that will eventually use SpeechAnalyzer/SpeechTranscriber; currently falls back to legacy SFSpeechRecognizer while maintaining same interface.  
  - `SpeechService.Session` exposes async stream of `SpeechSegment` updates.
- `LLMGateway.swift:133-679` – Core of cloud/on-device phrasing orchestration.  
  - `generateCoachResponse`: Sanitizes context, gates by consent, routes to GPT-5 with JSON schema, validates response, falls back on on-device generator.  
  - `parseAndValidateStructuredResponse`: Parses Response API payload, checks grounding score, isOnTopic flag, and handles incomplete statuses.  
  - Helper `validateChatPayload` ensures outgoing schema formatting.
- `CoachPhrasingSchema.swift:1-67` – Declaratively describes strict JSON schema expected from GPT-5 (coachReply length limits, enum for intentTopic, etc.).
- `KeychainService.swift:18-78` – Minimal wrappers for storing/retrieving API secrets with `.whenUnlockedThisDeviceOnly` accessibility.
- `FoundationModelsCoachGenerator.swift:7-118` – On-device fallback generator using `SystemLanguageModel`, sanitized final reply, and temperature tuning (0.6).

### PulsumData (`Packages/PulsumData`)
#### Package manifest
- `Package.swift:5-34` – Depends on PulsumML (for embedding stats) and exposes PulsumData library/test target.

#### Persistence & ingestion
- `DataStack.swift:49-136` – Builds NSPersistentContainer, applies NSFileProtectionComplete, excludes Application Support subdirectories from backup, sets history tracking, and prepares directories.  
- `PulsumData.swift:4-36` – Static accessors for container, contexts, and key directories (Application Support, VectorIndex, Anchors).
- `VectorIndex.swift:19-324` – Implements binary shard storage with headers, record appends, deletion marking, and L2 distance search.
- `VectorIndexManager.swift:11-37` – Singleton that uses `EmbeddingService` to embed micro-moment segments, handles upsert/search operations.  
- `LibraryImporter.swift:1-164` – Ingests JSON resources, generates checksums, maps recommendation fields to Core Data plus vector index; uses `EvidenceScorer` to assign Strong/Medium/Weak badges.
- Managed object classes in `Model/ManagedObjects.swift` define Core Data entities for journaling, daily metrics, baselines, vector data, recommendation events, preferences, etc.

### PulsumML (`Packages/PulsumML`)
#### Package manifest
- `Package.swift:5-39` – No external dependencies; contains resources (ML models).

#### ML utilities
- `BaselineMath.swift:3-38` – Median/MAD calculations and EWMA smoothing with λ=0.2.
- `StateEstimator.swift:24-65` – Ridge-regression online model with weight caps (-2 to 2) for contributions and wellbeing predictions.
- `RecRanker.swift:3-160` – Logistic scoring of recommendation feature vectors plus learning rate adaptation and user feedback adjustments.
- `EmbeddingService.swift:4-69` – Provides primary (AFM) and fallback (CoreML) embeddings, averaging across segments, padded/truncated to 384 dims.
- Sentiment providers (`SentimentService.swift:3-38`, `FoundationModelsSentimentProvider.swift`, `AFMSentimentProvider.swift`, `CoreMLSentimentProvider.swift`) cascade to deliver [-1,1] scores.
- `SafetyLocal.swift:19-206` – Configurable crisis/caution thresholds, prototype embeddings, keyword fallbacks, logging in DEBUG.
- Topic gate protocol and implementations (`TopicGateProviding.swift:3-16`, `FoundationModelsTopicGateProvider.swift:7-67`, `EmbeddingTopicGateProvider.swift:3-168`).
- PII redaction (`Sentiment/PIIRedactor.swift:4-35`) ensures transcripts exclude emails, phone numbers, and personal names.

---

## 2. Chat Guardrail Implementation (Detailed Code Flow)

### Wall 1 – On-Device Filters
1. **Safety Classification**  
   - Invoked at `AgentOrchestrator.performChat` (`Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:222-247`).  
   - Uses `SafetyAgent.evaluate`, which prefers Foundation Models (`FoundationModelsSafetyProvider`) but falls back to `SafetyLocal`. Crisis classifications override consent, returning crisis messaging and blocking cloud access.

2. **Topic Gate**  
   - If safety allows, sanitized input passes to `topicGate.classify` (lines 255-270).  
   - `FoundationModelsTopicGateProvider` (`Packages/PulsumML/Sources/PulsumML/TopicGate/FoundationModelsTopicGateProvider.swift:21-54`) generates structured `OnTopic` with confidence.  
   - Fallback `EmbeddingTopicGateProvider` (`Packages/PulsumML/Sources/PulsumML/TopicGate/EmbeddingTopicGateProvider.swift:3-168`) uses cosine similarity vs wellbeing prototypes, applies ON_TOPIC_THRESHOLD (0.59) and OOD margin (0.12), and whitelists greetings.

3. **Coverage Check**  
   - `CoachAgent.coverageDecision` returns similarity stats (top, median, count) and reason (`Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift:205-220`).  
   - `decideCoverage` (`CoachAgent+Coverage.swift:49-107`) classifies into `.strong` (count≥3, med≥0.42, top≥0.58), `.soft` (median≥0.35 or cohesive/sparse allowances), or `.fail`.  
   - Fail branch triggers on-device-only response via `CoachAgent.generateResponse` (lines 320-343), bypassing GPT-5.

4. **Deterministic Intent Routing**  
   - `mapTopicToSignalOrDataDominant` ensures signal selection is reproducible (`AgentOrchestrator.swift:303-343`).  
   - `CoachAgent.chatResponse` composes `CoachLLMContext` with sanitized tone hints, z-score summaries, and top signal (`CoachAgent.swift:78-110`).

### Wall 2 – Cloud Schema & Grounding
1. **Structured Request**  
   - `LLMGateway.makeChatRequestBody` builds payload with `response_format` referencing `CoachPhrasing` JSON schema and clamps `max_output_tokens` (`Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:624-674`).
   - Additional metadata: `reasoning.effort = "low"`, `text.verbosity = "low"`, sanitized context fields to avoid PHI leakage.

2. **Response Validation**  
   - `parseAndValidateStructuredResponse` (`LLMGateway.swift:511-579`) ensures JSON structure, rejects `status == "incomplete"`, extracts parsed schema, and checks `isOnTopic` plus `groundingScore`.  
   - Grounding floor derived from Wall 1 coverage (strong -> 0.50, soft -> 0.40) before `CoachReplyPayload` is accepted.

3. **Fail-Closed Behavior**  
   - If schema or grounding fail, errors logged and fallback generator invoked (lines 248-279). `notifyCloudError` posts diagnostics in DEBUG for QA.

---

## 3. LLM Gateway Deep Dive

| Aspect | Implementation Details | References |
| --- | --- | --- |
| **HTTP Endpoint** | `GPT5Client.endpoint = https://api.openai.com/v1/responses`, `model = "gpt-5"`; uses POST with JSON body. | `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:192`, `.../GPT5Client.swift:442-447` |
| **Token Budgeting** | Default `max_output_tokens` of 512; `clampTokens` confines to 128–1024. Retry logic upgrades to 1024 if initial response incomplete or downgrades to 128 on 400 errors referencing tokens. | `LLMGateway.swift:447-507`, `660-674` |
| **Consent & Safety** | Cloud path only executes when user toggled consent (`SettingsView` toggle) and `SafetyDecision.allowCloud == true`. On caution/crisis, the system returns local guardrail messaging. | `AgentOrchestrator.swift:235-246`, `SafetyAgent.swift:27-76`, `SettingsView.swift:34-56` |
| **Sanitization** | Inputs sanitized by `PIIRedactor.redact` (emails, phone, names). Cloud payload includes only sanitized text, top signal, rationale, z-score summary. Responses truncated to ≤2 sentences/280 chars. | `AgentOrchestrator.swift:188-198`; `LLMGateway.swift:310-317`; `CoachAgent.chatResponse` constructs sanitized context. |
| **Schema Enforcement** | `CoachPhrasingSchema.json()` requires `coachReply`, `isOnTopic`, `groundingScore`, `intentTopic`, `refusalReason`, `nextAction`; all strict. JSON schema referenced via `response_format`. | `CoachPhrasingSchema.swift:6-65`; `LLMGateway.makeChatRequestBody`. |
| **Logging & Diagnostics** | Topic routing logs posted via `emitRouteDiagnostics`; schema/grounding errors emitted via `NotificationCenter` (`.pulsumChatCloudError`). DEBUG builds capture history in `SettingsViewModel`. | `AgentOrchestrator.swift:286-315`; `LLMGateway.swift:283-288`; `SettingsViewModel.swift:150-198`. |

---

## 4. Pipeline Walkthroughs

### 4.1 HealthKit → Feature Engineering → Wellbeing Score
1. `HealthKitService.requestAuthorization` prompts for all required quantity/category types (HRV SDNN, heart rate, resting HR, respiratory rate, steps, sleep) and stores anchors using `HealthKitAnchorStore`.  
2. Incoming updates (`AnchoredUpdate`) are processed within `DataAgent` – quantity handlers aggregate samples and mark dirty days.  
3. `reprocessDay` performs:  
   - Summary metrics (HRV median in sleep intervals, nocturnal HR percentiles, personalized sleep debt, step totals).  
   - Baseline updates using `BaselineMath.robustStats` and writes to `Baseline` entity.  
   - Feature bundle assembly with z-scores and subjective inputs, persisted in `FeatureVector`.  
   - `StateEstimator.update` recalculates wellbeing score, contributions stored via JSON for UI breakdown.
4. `ScoreBreakdownViewModel.refresh` uses orchestrator to fetch full `ScoreBreakdown` payload (metrics, baselines, notes, contribution, explanations) for Settings drill-down.

### 4.2 Recommendation Lifecycle
1. `CoachAgent.recommendationCards` creates query string from top contributions and wellbeing score; vector search returns top 20 micro-moments.  
2. Each candidate calculates features — evidence strength via badge, novelty from acceptance rates, cooldown, time cost fit, z-score subset, etc.  
3. `RecRanker.rank` logistic sorts the feature array and stops after selecting three cards.  
4. When user accepts completion, `CoachAgent.logEvent` persists event with timestamp, and `CheerAgent.celebrateCompletion` generates reinforcement copy/haptic type.

### 4.3 Chat Flow
1. User message sanitized; safety gate ensures crisis/caution redirection.  
2. Topic gate obtains canonical topic and top signal mapping; coverage decision sets grounding floor and candidate moments.  
3. On cloud-allowed path, `CoachLLMContext` includes user tone hints (sanitized), `topSignal`, `rationale` (top contributions), `zScoreSummary` (feature contributions).  
4. `LLMGateway.generateCoachResponse` handles schema, token budgets, and fallback to `FoundationModelsCoachGenerator`.  
5. Responses appended to chat log; loading state indicators and fallback messaging shown in `CoachScreen`.

### 4.4 Journaling & Sentiment
1. `SpeechService.startRecording` returns stream of `SpeechSegment`s; recording auto-stops at 30 seconds or manual stop.  
2. `SentimentAgent.persistJournal` redacts transcript, obtains sentiment via `SentimentService.sentiment` (FoundationModels → AFM → CoreML cascade), generates embedding, writes to `JournalEntry` and `FeatureVector`.  
3. Embedding saved as `.vec` file with file protection; directory created under Application Support/VectorIndex/JournalEntries.  
4. `PulseViewModel` updates UI with transcript, sentiment score, and recency stamp; slider submissions propagate subjective inputs to DataAgent for reprocessing.

---

## 5. Privacy & Security Controls (Code-Backed)

- **File Protection** – `DataStack.prepareDirectories` ensures Application Support, VectorIndex, and Anchors directories are created with `NSFileProtectionComplete`, and `isExcludedFromBackup = true` to keep PHI local.  
- **Context Accessors** – `PulsumData` exposes `vectorIndexDirectory` and `healthAnchorsDirectory` so higher layers can inspect or purge data if necessary.  
- **Consent State** – `AppViewModel` loads consent from Core Data (`UserPrefs`), displays consent banner, and ensures toggles propagate to `SettingsViewModel` and `CoachViewModel`.  
- **PII Redaction** – `PIIRedactor` invoked before journaling persistence and prior to constructing LLM contexts, guaranteeing no emails/phone numbers/personal names enter storage or cloud payloads.  
- **Safety Enforcement** – Crisis decisions yield direct messaging and overlay via `SafetyCardView`; caution prevents cloud usage but continues on-device suggestions.  
- **Keychain Storage** – API secrets stored with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, ensuring data never syncs across devices.

---

## 6. UI Integration & State Flow

| UI Component | Backing View Model | Key Interactions | Source |
| --- | --- | --- | --- |
| `PulsumRootView` | `AppViewModel` | Manages startup, tabs, consent banner, safety overlay, and sheet presentation. | `Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift:8-200` |
| `CoachScreen` | `CoachViewModel` | Renders recommendations, fallback messaging, chat transcript, loading states, consent prompt. | `Packages/PulsumUI/Sources/PulsumUI/CoachView.swift:66-200` |
| `PulseView` | `PulseViewModel` | Controls recording experience, shows transcript/sentiment, handles slider submission, displays analysis errors. | `Packages/PulsumUI/Sources/PulsumUI/PulseView.swift:1-200` |
| `SettingsScreen` | `SettingsViewModel` | Displays wellbeing score, consent toggles, HealthKit authorization, Foundation Models status, GPT API test UI, diagnostics. | `Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift:13-200` |
| `ScoreBreakdownScreen` | `ScoreBreakdownViewModel` | Summarizes metric contributions, baselines, notes, and highlights; accessible from Settings. | `Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownView.swift:1-200` |
| Consent Banner | & same | Exact copy from instructions, offers direct navigation to Settings, dismiss toggles `AppViewModel.shouldHideConsentBanner`. | `Packages/PulsumUI/Sources/PulsumUI/ConsentBannerView.swift:7-42` |
| Safety Card | `AppViewModel` | Triggered when `SafetyDecision` is crisis; overlays call-to-action (“Call 911”) with large accent icons. | `Packages/PulsumUI/Sources/PulsumUI/SafetyCardView.swift:1-49` |

---

## 7. Observations & Pending Considerations

1. **SpeechAnalyzer Integration** – Current `ModernSpeechBackend` still proxies legacy backend pending public APIs (`Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:208-216`). Future milestone must replace placeholder once official frameworks ship.  
2. **Safety Threshold Tuning** – `SafetyLocalConfig` uses conservative thresholds for simulator bench testing (crisis 0.65, caution 0.35, resolution margin 0.10). Production rollout should re-evaluate using real HealthKit data and potentially reinstate original 0.48/0.22 thresholds.  
3. **SplineRuntime Availability** – `AnimatedSplineBackgroundView` falls back to gradient when SplineRuntime is absent (`Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift:120-131`). Determine whether shipping build should bundle the xcframework or embrace gradient as primary experience.  
4. **Foundation Models Availability Messaging** – Settings surface currently displays `FoundationModelsAvailability.availabilityMessage`; ensure localization and user guidance align with Apple Intelligence roll-out states.

---
