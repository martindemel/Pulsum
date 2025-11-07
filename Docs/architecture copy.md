# Pulsum - Complete Architecture Documentation

**Generated:** October 1, 2025
**iOS Target:** iOS 26+
**Swift Version:** 6.2
**Status:** Milestone 4 Complete (UI & Experience Build)

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [System Architecture](#2-system-architecture)
3. [Package Structure](#3-package-structure)
4. [Core Data Schema](#4-core-data-schema)
5. [ML/AI Pipeline](#5-mlai-pipeline)
6. [Agent System](#6-agent-system)
7. [UI Architecture](#7-ui-architecture)
8. [Data Flow](#8-data-flow)
9. [Privacy & Security](#9-privacy--security)
10. [API Reference](#10-api-reference)
11. [Implementation Details](#11-implementation-details)

---

## 1. Project Overview

### What is Pulsum?

Pulsum is a research-grade iOS health and wellness app that combines:
- **HealthKit integration** for objective physiological metrics (HRV, heart rate, sleep, steps)
- **Voice journaling** with on-device speech recognition and sentiment analysis
- **AI-powered coaching** using Apple Foundation Models and GPT-5
- **ML-driven recommendations** based on vector search and pairwise ranking
- **Privacy-first design** with on-device processing and explicit consent for cloud features

### Core Philosophy

- **Agent-First Architecture**: Central `AgentOrchestrator` coordinates specialized agents (Data, Sentiment, Coach, Safety, Cheer)
- **ML Over Rules**: All decisions (ranking, scoring, recommendations) use machine learning; no deterministic rule engines
- **Privacy by Design**: PHI stays on-device with `NSFileProtectionComplete`; cloud features require explicit consent
- **Science-Backed**: Robust statistics (median/MAD z-scores), evidence-scored recommendations, sleep debt calculation
- **Foundation Models First**: iOS 26+ leverages Apple Intelligence for sentiment, safety, and coaching with graceful fallbacks

### Technology Stack

| Layer | Technologies |
|-------|-------------|
| **UI** | SwiftUI, Observation framework, SplineRuntime (3D graphics) |
| **Concurrency** | Swift 6 strict concurrency, Actors, @MainActor, async/await |
| **ML/AI** | Apple Foundation Models (iOS 26+), Core ML, NaturalLanguage, On-device embeddings |
| **Cloud AI** | OpenAI GPT-5 API (consent-gated) |
| **Data** | Core Data (SQLite), Custom binary vector index (16 shards) |
| **Health** | HealthKit (HKAnchoredObjectQuery, HKObserverQuery, background delivery) |
| **Speech** | Speech framework (on-device recognition) |
| **Security** | Keychain Services, FileProtectionType.complete |

---

## 2. System Architecture

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         PULSUM APP                               │
│                      (iOS 26+ Target)                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        PULSUMUI PACKAGE                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ PulsumRoot   │  │ MainView     │  │ CoachView    │          │
│  │ View         │──│ (Spline 3D)  │──│ (Cards+Chat) │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ PulseView    │  │ SettingsView │  │ SafetyCard   │          │
│  │ (Journal)    │  │ (Consent)    │  │ View         │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│  ┌──────────────────────────────────────────────────┐          │
│  │ @MainActor ViewModels (App, Coach, Pulse, etc.) │          │
│  └──────────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     PULSUMAGENTS PACKAGE                         │
│  ┌─────────────────────────────────────────────────────┐        │
│  │        @MainActor AgentOrchestrator                 │        │
│  │  (Central coordinator for all agent operations)     │        │
│  └─────────────────────────────────────────────────────┘        │
│           │          │         │         │          │           │
│           ▼          ▼         ▼         ▼          ▼           │
│  ┌────────┐  ┌──────────┐ ┌────────┐ ┌────────┐ ┌────────┐    │
│  │ Data   │  │Sentiment │ │ Coach  │ │ Safety │ │ Cheer  │    │
│  │ Agent  │  │  Agent   │ │ Agent  │ │ Agent  │ │ Agent  │    │
│  │(actor) │  │(@MainAct)│ │(@MainA)│ │(@MainA)│ │(@MainA)│    │
│  └────────┘  └──────────┘ └────────┘ └────────┘ └────────┘    │
└─────────────────────────────────────────────────────────────────┘
       │              │            │            │
       ▼              ▼            ▼            ▼
┌─────────────────────────────────────────────────────────────────┐
│                   PULSUMSERVICES PACKAGE                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ HealthKit    │  │ Speech       │  │ LLMGateway   │          │
│  │ Service      │  │ Service      │  │ (GPT-5/AFM)  │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│  ┌──────────────┐  ┌──────────────┐                            │
│  │ Keychain     │  │FoundationMod │                            │
│  │ Service      │  │CoachGenerator│                            │
│  └──────────────┘  └──────────────┘                            │
└─────────────────────────────────────────────────────────────────┘
       │                                    │
       ▼                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                      PULSUMML PACKAGE                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Baseline     │  │ State        │  │ RecRanker    │          │
│  │ Math         │  │ Estimator    │  │ (Pairwise ML)│          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Embedding    │  │ Sentiment    │  │ Safety       │          │
│  │ Service      │  │ Service      │  │ Local        │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Foundation   │  │ AFM/CoreML   │  │ PII          │          │
│  │ Models       │  │ Providers    │  │ Redactor     │          │
│  │ Integration  │  │              │  │              │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      PULSUMDATA PACKAGE                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ DataStack    │  │ Core Data    │  │ Vector       │          │
│  │ (NSPersist-  │  │ Entities     │  │ Index        │          │
│  │ entContainer)│  │ (9 types)    │  │ (16 shards)  │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│  ┌──────────────┐  ┌──────────────┐                            │
│  │ VectorIndex  │  │ Library      │                            │
│  │ Manager      │  │ Importer     │                            │
│  └──────────────┘  └──────────────┘                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PERSISTENCE LAYER                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Pulsum.sqlite│  │ VectorIndex/ │  │ Anchors/     │          │
│  │ (Core Data)  │  │ (binary      │  │ (HKQuery     │          │
│  │              │  │  shards)     │  │  anchors)    │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│         All protected with FileProtectionType.complete           │
│         Excluded from iCloud backup                              │
└─────────────────────────────────────────────────────────────────┘
```

### Package Dependency Graph

```
PulsumApp (main target)
    └─> PulsumUI
            └─> PulsumAgents
                    ├─> PulsumServices
                    │       ├─> PulsumData
                    │       │       └─> PulsumML
                    │       └─> PulsumML
                    ├─> PulsumData
                    │       └─> PulsumML
                    └─> PulsumML

Direct Dependencies:
- PulsumUI: PulsumAgents, PulsumServices, PulsumData
- PulsumAgents: PulsumData, PulsumServices, PulsumML
- PulsumServices: PulsumData, PulsumML
- PulsumData: PulsumML
- PulsumML: (no internal dependencies)
```

### Frameworks & External Dependencies

| Package | Linked Frameworks |
|---------|-------------------|
| PulsumML | FoundationModels, Accelerate, NaturalLanguage, CoreML |
| PulsumServices | FoundationModels, HealthKit, Speech, AVFoundation, Security |
| PulsumAgents | FoundationModels, CoreData |
| PulsumData | CoreData |
| PulsumUI | SwiftUI, HealthKit, SplineRuntime (SPM) |

---

## 3. Package Structure

### PulsumData Package

**Purpose:** Persistent storage infrastructure (Core Data + Vector Index)

```
Packages/PulsumData/
├── Package.swift (iOS 26+, depends on PulsumML)
├── Sources/PulsumData/
│   ├── PulsumData.swift           # Public facade
│   ├── DataStack.swift            # Core Data stack with file protection
│   ├── Model/
│   │   └── ManagedObjects.swift   # 9 Core Data entities
│   ├── VectorIndex.swift          # Binary vector storage (L2 search)
│   ├── VectorIndexManager.swift   # Semantic search interface
│   ├── LibraryImporter.swift      # JSON → Core Data + vector index
│   └── EvidenceScorer.swift       # URL domain → evidence badge
└── Tests/PulsumDataTests/
    ├── PulsumDataBootstrapTests.swift
    ├── VectorIndexTests.swift
    ├── LibraryImporterTests.swift
    └── Resources/podcasts_sample.json
```

**Key Types:**
- `DataStack` (singleton): NSPersistentContainer with FileProtectionType.complete
- `VectorIndex`: 16-shard binary storage for 384-dim float vectors
- `VectorIndexManager`: Embeds text → upserts/searches vectors
- `LibraryImporter`: SHA256-based incremental ingestion from JSON
- 9 Core Data entities: JournalEntry, DailyMetrics, Baseline, FeatureVector, MicroMoment, RecommendationEvent, LibraryIngest, UserPrefs, ConsentState

---

### PulsumML Package

**Purpose:** Machine learning algorithms, embeddings, sentiment, safety

```
Packages/PulsumML/
├── Package.swift (iOS 26+, links FoundationModels + Accelerate)
├── Sources/PulsumML/
│   ├── Placeholder.swift              # Public facade
│   ├── BaselineMath.swift             # Robust stats (median/MAD z-scores, EWMA)
│   ├── StateEstimator.swift           # Online ridge regression for wellbeing score
│   ├── RecRanker.swift                # Pairwise logistic ranking
│   ├── Embedding/
│   │   ├── TextEmbeddingProviding.swift        # Protocol
│   │   ├── EmbeddingService.swift              # Singleton with AFM + CoreML fallback
│   │   ├── AFMTextEmbeddingProvider.swift      # NLContextualEmbedding (iOS 17+)
│   │   ├── CoreMLEmbeddingFallbackProvider.swift # Bundled Core ML model
│   │   ├── EmbeddingError.swift
│   ├── Sentiment/
│   │   ├── SentimentProviding.swift            # Protocol
│   │   ├── SentimentService.swift              # Cascading provider
│   │   ├── FoundationModelsSentimentProvider.swift # iOS 26+ @Generable
│   │   ├── AFMSentimentProvider.swift          # Anchor-based embedding similarity
│   │   ├── CoreMLSentimentProvider.swift       # Bundled Core ML model
│   │   ├── NaturalLanguageSentimentProvider.swift # NLTagger fallback
│   │   └── PIIRedactor.swift                   # Regex + NLTagger PII removal
│   ├── Safety/
│   │   └── FoundationModelsSafetyProvider.swift # iOS 26+ @Generable safety classification
│   ├── SafetyLocal.swift              # Keyword + prototype-based classifier
│   ├── AFM/
│   │   ├── FoundationModelsAvailability.swift  # Status checking
│   │   ├── FoundationModelsStub.swift          # Stubs for iOS < 26
│   │   └── README_FoundationModels.md
│   └── Resources/
│       ├── PulsumFallbackEmbedding.mlmodel     # 384-dim word embeddings
│       ├── PulsumSentimentCoreML.mlmodel       # Sentiment classifier
│       └── README_CreateModel.md
└── Tests/PulsumMLTests/
    ├── PackageEmbedTests.swift
    └── SafetyLocalTests.swift
```

**Key Algorithms:**

1. **BaselineMath**
   - Robust z-scores: `(value - median) / (MAD * 1.4826)`
   - EWMA: `λ * newValue + (1 - λ) * previous` (λ = 0.2)

2. **StateEstimator** (Wellbeing Score)
   - Linear model: `score = Σ(weight_i * feature_i) + bias`
   - Initial weights: `{z_hrv: -0.6, z_nocthr: 0.5, z_resthr: 0.4, z_sleepDebt: 0.5, z_steps: -0.2, z_rr: 0.1, subj_stress: 0.6, subj_energy: -0.6, subj_sleepQuality: 0.4}`
   - Online update: Gradient descent with L2 regularization (α=0.05, λ=1e-3, weight cap ±2.0)

3. **RecRanker** (Recommendation Ranking)
   - Pairwise logistic regression: `score = sigmoid(Σ(weight_i * feature_i))`
   - Features: wellbeing score, evidence strength, novelty, cooldown, acceptance rate, time cost fit, z-scores
   - Update: Pairwise gradient on (preferred > other) examples

4. **SafetyLocal**
   - Crisis keywords: ["suicide", "kill myself", "end my life", "not worth living", "better off dead"]
   - Caution keywords: ["depressed", "anxious", "worthless", "hopeless", "overwhelming"]
   - 12 prototype embeddings (4 crisis, 4 caution, 4 safe)
   - Classification: cosine similarity with thresholds (crisis=0.65, caution=0.35, margin=0.10)
   - Upgrade to crisis requires keyword match

5. **Foundation Models Integration**
   - **Sentiment**: `@Generable struct SentimentAnalysis { label: SentimentLabel, score: Double }` with temperature=0.1
   - **Safety**: `@Generable struct SafetyAssessment { rating: SafetyRating, reason: String }` with temperature=0.0
   - **Availability**: Checks `SystemLanguageModel.default.availability` for status (ready/downloading/needsAppleIntelligence/unsupported)

---

### PulsumServices Package

**Purpose:** External services (HealthKit, Speech, LLM, Keychain)

```
Packages/PulsumServices/
├── Package.swift (iOS 26+, depends on PulsumData + PulsumML)
├── Sources/PulsumServices/
│   ├── Placeholder.swift                        # Public facade
│   ├── HealthKitService.swift                   # HKObserverQuery + HKAnchoredObjectQuery
│   ├── HealthKitAnchorStore.swift               # Persists HKQueryAnchor to disk
│   ├── SpeechService.swift                      # On-device speech recognition (actor)
│   ├── LLMGateway.swift                         # Consent-aware routing (cloud/on-device)
│   ├── FoundationModelsCoachGenerator.swift     # iOS 26+ coaching with SystemLanguageModel
│   └── KeychainService.swift                    # Keychain wrapper (singleton)
└── Tests/PulsumServicesTests/
    ├── HealthKitAnchorStoreTests.swift
    ├── KeychainServiceTests.swift
    ├── LLMGatewayTests.swift
    └── PulsumServicesDependencyTests.swift
```

**Key Services:**

1. **HealthKitService**
   - Requests authorization for: HRV (SDNN), heart rate, resting HR, respiratory rate, step count, sleep analysis
   - Enables background delivery for real-time updates
   - Manages `HKObserverQuery` + `HKAnchoredObjectQuery` per sample type
   - Persists anchors via `HealthKitAnchorStore` (NSKeyedArchiver with FileProtectionType.complete)

2. **SpeechService** (actor)
   - On-device speech recognition: `SFSpeechRecognizer` with `requiresOnDeviceRecognition = true`
   - Returns `AsyncThrowingStream<SpeechSegment>`
   - Auto-stops after maxDuration (default 30s)
   - Configures `AVAudioSession` for recording
   - Future: iOS 26+ uses `SpeechTranscriber`/`SpeechAnalyzer` APIs

3. **LLMGateway**
   - **Cloud Path** (consent required): OpenAI GPT-5 REST API
     - Endpoint: `https://api.openai.com/v1/responses`
     - Model: `gpt-5`
     - Payload: `{"model": "gpt-5", "input": [...], "max_output_tokens": 512, "reasoning": {"effort": "medium"}, "text": {"verbosity": "medium"}}`
     - Hardcoded API key: `sk-proj-CV00PjpfJjs...` (for testing)
   - **On-Device Path**: `FoundationModelsCoachGenerator` (iOS 26+) → `LegacyCoachGenerator` (phrase matching)
   - PII redaction via `PIIRedactor` before cloud calls
   - Response sanitization: max 2 sentences, 280 chars per sentence

4. **FoundationModelsCoachGenerator**
   - Uses `SystemLanguageModel.default` with `LanguageModelSession`
   - Instructions: "You are a supportive wellness coach. Keep responses under 80 words, max 2 sentences. Ground advice in user's health signals (HRV, sleep, stress). Never diagnose or make medical claims."
   - Temperature: 0.6
   - Handles `GenerationError.guardrailViolation` and `.refusal` gracefully
   - Sanitizes output to 2 sentences max
   - Fallback: keyword-based responses ("Your HRV is low today...")

5. **KeychainService**
   - Service identifier: `"ai.pulsum.app"`
   - Accessibility: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
   - Operations: `setSecret()`, `secret(for:)`, `removeSecret(for:)`

---

### PulsumAgents Package

**Purpose:** Agent coordination and specialized agents

```
Packages/PulsumAgents/
├── Package.swift (iOS 26+, depends on PulsumData + PulsumServices + PulsumML)
├── Sources/PulsumAgents/
│   ├── PulsumAgents.swift           # Public facade
│   ├── AgentOrchestrator.swift      # @MainActor central coordinator
│   ├── DataAgent.swift              # actor (HealthKit observation + feature engineering)
│   ├── SentimentAgent.swift         # @MainActor (voice journal + sentiment analysis)
│   ├── CoachAgent.swift             # @MainActor (recommendations + chat)
│   ├── SafetyAgent.swift            # @MainActor (content safety classification)
│   └── CheerAgent.swift             # @MainActor (positive reinforcement)
└── Tests/PulsumAgentsTests/
    ├── AgentSystemTests.swift
    └── TestCoreDataStack.swift
```

**Agent Descriptions:**

1. **AgentOrchestrator** (@MainActor)
   - **Role:** Central coordinator exposing unified API to UI layer
   - **Dependencies:** All 5 specialized agents
   - **Key Functions:**
     - `start()` → prepares library, starts DataAgent
     - `recordVoiceJournal(maxDuration:)` → SentimentAgent → SafetyAgent → JournalCaptureResponse
     - `submitTranscript(_:)` → SentimentAgent → SafetyAgent → JournalCaptureResponse
     - `updateSubjectiveInputs(date:stress:energy:sleepQuality:)` → DataAgent
     - `recommendations(consentGranted:)` → CoachAgent → RecommendationResponse
     - `chat(userInput:consentGranted:)` → PII redaction → SafetyAgent gate → CoachAgent
     - `logCompletion(momentId:)` → CoachAgent → CheerAgent → CheerEvent
     - `scoreBreakdown()` → DataAgent → ScoreBreakdown
   - **Foundation Models Status:** Tracks availability via `foundationModelsStatus` property

2. **DataAgent** (actor)
   - **Role:** HealthKit ingestion, feature engineering, wellbeing scoring
   - **Pipeline:**
     1. **Observation:** `HKObserverQuery` + `HKAnchoredObjectQuery` for 6 sample types
     2. **Storage:** Appends timestamped samples to `DailyMetrics.flags` (JSON)
     3. **Daily Reprocessing:**
        - **Summary:** Compute HRV median, nocturnal HR (10th percentile), resting HR, sleep debt, respiratory rate, steps
        - **Baseline:** Rolling 30-day robust stats (median, MAD, EWMA)
        - **Features:** Compute z-scores for each metric
        - **Scoring:** `StateEstimator.update()` with gradient descent
        - **Persistence:** `FeatureVector` with contributions and imputed flags
   - **Key Types:**
     - `FeatureVectorSnapshot`: Latest features + wellbeing score + contributions
     - `ScoreBreakdown`: Metric-by-metric detail with z-scores, baselines, explanations
     - `DailyFlags` (private): JSON-encoded sample arrays (HRV, heart rate, sleep segments, steps)
   - **Imputation Rules:**
     - HRV: Use sedentary intervals (≤30 steps/h, ≥30 min) if no overnight sleep data; carry forward previous value as last resort
     - Nocturnal HR: Same as HRV
     - Resting HR: Use latest HealthKit sample; carry forward if missing
     - Sleep debt: Personalized need = 7-day rolling average ± 0.75h around 7.5h default
     - Steps: Require Motion authorization; flag if missing or low confidence
   - **Target Computation** (for StateEstimator):
     - `target = -0.35*hrv + -0.25*steps + -0.4*sleepDebt + 0.45*stress + -0.4*energy + 0.3*sleepQuality`

3. **SentimentAgent** (@MainActor)
   - **Role:** Voice journal recording, transcription, sentiment analysis, embedding
   - **Pipeline:**
     1. Request Speech authorization
     2. Start recording via `SpeechService`
     3. Receive transcript stream
     4. Redact PII via `PIIRedactor`
     5. Compute sentiment via `SentimentService` (FoundationModels → AFM → CoreML → 0)
     6. Generate 384-dim embedding via `EmbeddingService`
     7. Persist `JournalEntry` to Core Data
     8. Persist vector to `VectorIndex/JournalEntries/{UUID}.vec` (binary float32 array)
     9. Update `FeatureVector.sentiment` for the day
   - **Key Functions:**
     - `recordVoiceJournal(maxDuration:)` → `JournalResult`
     - `importTranscript(_:)` → `JournalResult` (for manual text input)
     - `stopRecording()`
   - **PII Redaction:** Removes emails, phone numbers, personal names via regex + `NLTagger`

4. **CoachAgent** (@MainActor)
   - **Role:** Recommendation generation, chat responses, library management
   - **Recommendation Pipeline:**
     1. Vector search: Query current state → top 20 `MicroMoment` matches
     2. Feature computation:
        - Wellbeing score (from `StateEstimator`)
        - Evidence strength: Strong=1.0, Medium=0.7, Weak=0.3
        - Novelty: Days since last shown
        - Cooldown: `1 - (elapsed / cooldown)` if within cooldown window
        - Acceptance rate: `acceptances / total events` per moment
        - Time cost fit: `1 - (seconds / 1800)`, normalized to [0, 1]
        - Z-scores: From latest `FeatureVector`
     3. Rank: `RecRanker.rank(candidates)` → sort by score descending
     4. Select top 3: 1 "Top Pick" + 2 alternates
     5. Generate cards with:
        - Title, body (shortDescription), caution (intelligent or heuristic), source badge
   - **Chat Pipeline (Two-Wall Guardrails with Deterministic Intent Routing):**
     **Wall-1 (On-Device Guardrails):**
     1. **Safety Gate:** `SafetyAgent.evaluate()` → Crisis blocks all processing, Caution blocks cloud
     2. **Topic Gate:** ML classification (AFM → embedding fallback) → 0.59 threshold for on-topic
        - Returns canonical topic: sleep, stress, energy, hrv, mood, movement, mindfulness, goals, or nil (greetings)
        - HRV vocabulary: "rmssd", "vagal tone", "parasympathetic", "recovery"
     3. **Deterministic Intent Routing (4-step pipeline eliminates "wobble"):**
        a. Start with Wall-1 topic from gate decision
        b. Phrase override: Substring matching (e.g., "insomnia" → sleep, "rmssd" → hrv, "micro" → goals)
        c. Candidate moments override: Retrieve top-2 moments for topic, infer dominant via keyword scoring
        d. Data-dominant fallback: Choose signal with highest |z-score| (subj_sleepQuality, subj_stress, subj_energy, hrv_rmssd_rolling_30d, sentiment_rolling_7d, steps_rolling_7d)
     4. **Coverage Gate:** Retrieval similarity check → 0.68 threshold (median-based)
        - Robustness: Require ≥3 matches, median similarity ≥0.25, using 1/(1+d) transformation
        - Blocks off-topic fluff like "tell me a joke"
     **Wall-2 (Cloud Schema Validation):**
     5. Build `CoachLLMContext` with deterministic topSignal, intentTopic, candidateMoments
     6. GPT-5 structured output → `CoachReplyPayload {coachReply, nextAction?}`
        - Schema enforces: isOnTopic (bool), groundingScore (≥0.5 threshold), coachReply (≤280 chars, ≤2 sentences)
        - Optional: nextAction (≤120 chars), intentTopic echo
     7. Fail-closed: Schema/grounding failures → fallback to Foundation Models on-device
     **Output:**
     - CoachReplyPayload returned (≤2 sentences, grounded in user data, optional micro-moment action)
   - **Foundation Models Caution Generation** (iOS 26+):
     - Uses `SystemLanguageModel` with temperature=0.3
     - Prompt: "Given user's wellbeing state (HRV, sleep, stress), assess if activity '{title}' with difficulty '{difficulty}' carries elevated risk. Return NONE or brief 1-sentence caution."
     - Fallback: Heuristic (difficulty="hard" → "Take it easy if you're fatigued")
   - **Key Functions:**
     - `prepareLibraryIfNeeded()` → ingests JSON recommendations
     - `recommendationCards(for:consentGranted:)` → `[RecommendationCard]`
     - `chatResponse(userInput:snapshot:consentGranted:)` → `String`
     - `logEvent(momentId:accepted:)` → persists `RecommendationEvent`
     - `momentTitle(for:)` → lookup by ID

5. **SafetyAgent** (@MainActor)
   - **Role:** Content safety classification
   - **Pipeline:**
     1. Try `FoundationModelsSafetyProvider` (iOS 26+) with structured generation
     2. Fallback to `SafetyLocal` (keyword + prototype-based)
   - **Classifications:**
     - `.safe`: No concerns
     - `.caution(reason)`: Elevated concern (e.g., "mentions feeling overwhelmed")
     - `.crisis(reason)`: Immediate risk (e.g., "expresses suicidal ideation")
   - **Key Functions:**
     - `evaluate(text:)` → `SafetyDecision` (classification, allowCloud, crisisMessage)
   - **Routing Impact:**
     - `.crisis` → blocks cloud calls, shows US 911 message
     - `.caution` → allows on-device only
     - `.safe` → allows cloud (if consent granted)

6. **CheerAgent** (@MainActor)
   - **Role:** Positive reinforcement on recommendation completion
   - **Pipeline:**
     1. Check time of day
     2. Select randomized affirmation with time qualifier
   - **Time Qualifiers:**
     - Morning (5-11): "Great start to your day!"
     - Midday (11-16): "Nice midday reset!"
     - Evening (16-21): "Strong follow-through this evening!"
     - Late (21-5): "Impressive late-day commitment!"
   - **Affirmations:** 4 variants ("That's the kind of action that builds momentum", "You showed up for yourself", etc.)
   - **Key Functions:**
     - `celebrateCompletion(momentTitle:)` → `CheerEvent` (message, haptic, timestamp)

---

### PulsumUI Package

**Purpose:** SwiftUI views and view models

```
Packages/PulsumUI/
├── Package.swift (iOS 26+, depends on PulsumAgents + PulsumServices + PulsumData)
├── Sources/PulsumUI/
│   ├── PulsumRootView.swift               # Root entry point (tabs, gestures, sheets)
│   ├── PulsumDesignSystem.swift           # Colors, spacing, typography, modifiers
│   ├── GlassEffect.swift                  # Liquid glass material effect
│   ├── LiquidGlassComponents.swift        # Custom tab bar
│   ├── AppViewModel.swift                 # @MainActor root view model
│   ├── MainView/
│   │   ├── (Inline in PulsumRootView)     # Spline 3D scene background
│   ├── CoachView/
│   │   ├── CoachView.swift                # Recommendations + chat UI
│   │   └── CoachViewModel.swift           # @MainActor
│   ├── PulseView/
│   │   ├── PulseView.swift                # Journal recording + sliders
│   │   └── PulseViewModel.swift           # @MainActor
│   ├── SettingsView/
��   │   ├── SettingsView.swift             # Consent, privacy, AI status
│   │   ├── SettingsViewModel.swift        # @MainActor
│   │   ├── ScoreBreakdownView.swift       # Detailed score breakdown
│   │   └── ScoreBreakdownViewModel.swift  # @MainActor
│   ├── SafetyCardView.swift               # Crisis overlay (US 911)
│   ├── ConsentBannerView.swift            # Cloud processing consent
│   └── OnboardingView.swift               # 3-page onboarding flow
└── Tests/PulsumUITests/
    └── PulsumRootViewTests.swift
```

**View Hierarchy:**

```
PulsumRootView
├── Background: LinearGradient + AnimatedSplineBackgroundView
├── Header: HeaderView (Pulse button, Settings button)
├── ConsentBannerView (if not hidden)
├── Content:
│   ├── MainContainerView (Tab: Main)
│   │   └── CoachShortcutButton (sparkles icon, triggers Coach tab)
│   └── CoachScreen (Tab: Coach)
│       ├── Recommendations (cards)
│       ├── Chat messages
│       └── ChatInputView
├── BottomControls: LiquidGlassTabBar
├── Sheet: PulseView (journal + sliders)
├── Sheet: SettingsScreen
│   └── NavigationLink: ScoreBreakdownScreen
└── Overlay: SafetyCardView (if active)
```

**View Models:**

1. **AppViewModel** (@MainActor, @Observable)
   - **State:** `startupState`, `selectedTab`, `isPresentingPulse`, `isPresentingSettings`, `isShowingSafetyCard`, `safetyMessage`, `consentGranted`, `shouldHideConsentBanner`
   - **Children:** `CoachViewModel`, `PulseViewModel`, `SettingsViewModel`
   - **Key Functions:**
     - `start()` → creates `AgentOrchestrator`, binds view models, calls `orchestrator.start()`
     - `updateConsent(to:)` → persists via `ConsentStore` (UserPrefs entity with ID="default")
     - `triggerCoachFocus()` → switches to coach tab + focuses chat input
     - `handleRecommendationCompletion(_:)` → logs event, shows cheer message

2. **CoachViewModel** (@MainActor, @Observable)
   - **State:** `recommendations`, `wellbeingScore`, `contributions`, `messages`, `chatInput`, `isSendingChat`, `chatErrorMessage`, `cheerEventMessage`, `chatFocusToken`
   - **Key Functions:**
     - `bind(orchestrator:consentProvider:)` → establishes orchestrator connection
     - `refreshRecommendations()` → fetches from `orchestrator.recommendations(consentGranted:)`
     - `sendChat()` → appends user message, calls `orchestrator.chat()`, appends assistant message
     - `markCardComplete(_:)` → logs via orchestrator, shows cheer message (auto-hides after 4s)
     - `requestChatFocus()` → triggers UUID change to focus TextField

3. **PulseViewModel** (@MainActor, @Observable)
   - **State:** `isRecording`, `recordingSecondsRemaining`, `transcript`, `sentimentScore`, `analysisError`, `stressLevel`, `energyLevel`, `sleepQualityLevel`, `isSubmittingInputs`, `sliderSubmissionMessage`, `onSafetyDecision`
   - **Key Functions:**
     - `startRecording(maxDuration:)` → starts countdown task + recording task
     - `stopRecording()` → cancels tasks, calls `orchestrator.stopVoiceJournalRecording()`
     - `submitInputs(for:)` → saves subjective sliders via `orchestrator.updateSubjectiveInputs()`

4. **SettingsViewModel** (@MainActor, @Observable)
   - **State:** `foundationModelsStatus`, `consentGranted`, `healthKitAuthorizationStatus`, `isRequestingHealthKitAuthorization`, `healthKitError`, `gptAPIStatus`, `isGPTAPIWorking`, `onConsentChanged`
   - **Key Functions:**
     - `refreshFoundationStatus()` → gets status from `orchestrator.foundationModelsStatus`
     - `refreshHealthKitStatus()` → checks `HKHealthStore.authorizationStatus(for: hrvType)`
     - `requestHealthKitAuthorization()` → requests HealthKit access
     - `toggleConsent(_:)` → fires `onConsentChanged` callback
     - `checkGPTAPIKey()` → tests `LLMGateway.testAPIConnection()`

5. **ScoreBreakdownViewModel** (@MainActor, @Observable)
   - **State:** `breakdown`, `isLoading`, `errorMessage`
   - **Computed:** `objectiveMetrics`, `subjectiveMetrics`, `sentimentMetrics` (filters by kind)
   - **Key Functions:**
     - `refresh()` → fetches from `orchestrator.scoreBreakdown()`

**Design System (PulsumDesignSystem.swift):**

| Category | Examples |
|----------|----------|
| **Colors** | Backgrounds: pulsumBackgroundBeige (#F5F3ED), pulsumBackgroundCream, pulsumBackgroundLight, pulsumBackgroundPeach<br>Accents: pulsumMintGreen (#D4EED4), pulsumMintLight, pulsumBlueSoft, pulsumPinkSoft<br>Text: pulsumTextPrimary (#2C2C2E), pulsumTextSecondary, pulsumTextTertiary<br>Semantic: pulsumSuccess, pulsumWarning, pulsumError, pulsumInfo |
| **Spacing** | xxs=4, xs=8, sm=12, md=16, lg=24, xl=32, xxl=48, xxxl=64 |
| **Radius** | xs=8, sm=12, md=16, lg=20, xl=24, xxl=28, xxxl=32 |
| **Typography** | Display: pulsumLargeTitle (34pt bold), pulsumTitle (28pt bold)<br>Body: pulsumBody (17pt), pulsumCallout (16pt), pulsumSubheadline (15pt)<br>Data: pulsumDataXLarge (58pt bold rounded), pulsumDataLarge (48pt) |
| **Animations** | pulsumQuick (0.2s, dampingFraction=0.7)<br>pulsumStandard (0.35s, dampingFraction=0.65)<br>pulsumSmooth (0.5s, dampingFraction=0.85)<br>pulsumBouncy (0.6s, dampingFraction=0.6) |
| **Shadows** | small (radius=8, y=2), medium (radius=12, y=4), large (radius=20, y=8) |

**Liquid Glass Effect:**
- **Material:** `Material.ultraThin` (default) with optional tint overlay
- **Border:** White stroke (opacity 0.25-0.3)
- **Shadow:** Scales with intensity (6-20 radius)
- **Interactive:** Scale effect 0.96 on press
- **Usage:** Tab bar, buttons, cards, sheets

**Spline Integration:**
- **Cloud URL:** `https://build.spline.design/Wp1o27Ds7nsPAHPrlN6K/scene.splineswift`
- **Local Fallback:** `infinity_blubs_copy.splineswift` (bundled)
- **Fallback UI:** LinearGradient (beige → cream) if Spline unavailable
- **Implementation:** `SplineView(sceneFileURL:)` in background layer

---

## 4. Core Data Schema

### Entities

| Entity | Attributes | Purpose |
|--------|-----------|---------|
| **JournalEntry** | `id: UUID`<br>`date: Date`<br>`transcript: String`<br>`sentiment: Double?`<br>`embeddedVectorURL: String?`<br>`sensitiveFlags: String?` | Voice journal entries with PII redaction flags. Vectors stored externally (`VectorIndex/JournalEntries/{UUID}.vec`). |
| **DailyMetrics** | `date: Date`<br>`hrvMedian: Double?`<br>`nocturnalHRPercentile10: Double?`<br>`restingHR: Double?`<br>`totalSleepTime: Double?`<br>`sleepDebt: Double?`<br>`respiratoryRate: Double?`<br>`steps: Double?`<br>`flags: String?` | Summary metrics computed from HealthKit samples. `flags` contains JSON-encoded raw samples (HRVSample, HeartRateSample, SleepSegment, StepBucket arrays). |
| **Baseline** | `metric: String`<br>`windowDays: Int16`<br>`median: Double?`<br>`mad: Double?`<br>`ewma: Double?`<br>`updatedAt: Date?` | Rolling baseline statistics per metric (30-day default). Used for z-score computation. |
| **FeatureVector** | `date: Date`<br>`zHrv: Double?`<br>`zNocturnalHR: Double?`<br>`zRestingHR: Double?`<br>`zSleepDebt: Double?`<br>`zRespiratoryRate: Double?`<br>`zSteps: Double?`<br>`subjectiveStress: Double?`<br>`subjectiveEnergy: Double?`<br>`subjectiveSleepQuality: Double?`<br>`sentiment: Double?`<br>`imputedFlags: String?` | Normalized features + subjective inputs. One per day. `imputedFlags` JSON explains missing data handling. |
| **MicroMoment** | `id: String`<br>`title: String`<br>`shortDescription: String`<br>`detail: String?`<br>`tags: [String]?`<br>`estimatedTimeSec: Int32?`<br>`difficulty: String?`<br>`category: String?`<br>`sourceURL: String?`<br>`evidenceBadge: String?`<br>`cooldownSec: Int32?` | Recommendation library items ingested from JSON. Embeddings stored in separate vector index. |
| **RecommendationEvent** | `momentId: String`<br>`date: Date`<br>`accepted: Bool`<br>`completedAt: Date?` | User interaction tracking. Feeds acceptance rate feature for RecRanker. |
| **LibraryIngest** | `id: UUID`<br>`source: String`<br>`checksum: String?`<br>`ingestedAt: Date`<br>`version: String?` | SHA256-based deduplication for JSON library updates. |
| **UserPrefs** | `id: String`<br>`consentCloud: Bool`<br>`updatedAt: Date` | User preferences. ID="default" for singleton record. `consentCloud` gates GPT-5 API usage. |
| **ConsentState** | `id: UUID`<br>`version: String`<br>`grantedAt: Date?`<br>`revokedAt: Date?` | Consent audit log (not currently used in UI; reserved for versioned consent). |

### Store Configuration

- **Location:** `Application Support/Pulsum/Pulsum.sqlite`
- **Type:** `NSSQLiteStoreType`
- **File Protection:** `FileProtectionType.complete` (iOS only)
- **iCloud Sync:** **Disabled** (CloudKit sync OFF)
- **Backup Exclusion:** `isExcludedFromBackup = true`
- **Persistent History:** Enabled (`NSPersistentHistoryTrackingKey = true`)
- **Merge Policy:** `NSMergePolicy.mergeByPropertyObjectTrump`
- **Migration:** Automatic (`shouldInferMappingModelAutomatically = true`)

### Vector Storage

**Separate from Core Data to optimize memory-mapped L2 search.**

- **Directory:** `Application Support/Pulsum/VectorIndex/`
- **Indexes:**
  - `micro_moments/` (16 shards): Embeddings for MicroMoment titles/details/tags
  - `JournalEntries/` (individual files): `{UUID}.vec` binary float32 arrays (384 dimensions)
- **Format:**
  - **Shard Header** (16 bytes): magic (0x50535649 'PSVI'), version (1), dimension (384), recordCount (UInt64)
  - **Record Header** (4 bytes): idLength (UInt16), flags (UInt16, 0=active, 1=deleted)
  - **Record Body:** UTF-8 ID + float32 vector (384 * 4 = 1536 bytes)
- **Metadata:** JSON file per shard (`{shardName}.meta`) maps ID → file offset for fast lookup
- **Protection:** `FileProtectionType.complete` on all shard files

---

## 5. ML/AI Pipeline

### Embedding Pipeline

```
Text Input
    ↓
EmbeddingService.embedding(for:)
    ↓
Try AFMTextEmbeddingProvider (iOS 17+)
    ├─> NLContextualEmbedding.contextualEmbedding(for:) [TEMPORARILY DISABLED]
    └─> Fallback: NLEmbedding.wordEmbedding(for: .english)
        ├─> Token-level embeddings
        └─> Average pooling → adjust to 384 dimensions
    ↓ (on failure)
CoreMLEmbeddingFallbackProvider
    ├─> Load PulsumFallbackEmbedding.mlmodel
    └─> Adjust dimension to 384 via padding/truncation
    ↓ (on failure)
Return zero vector [0.0, 0.0, ..., 0.0] (384 dimensions)
```

**Design Note:** Contextual embeddings (iOS 17+) provide higher quality but require unsafe Objective-C runtime access (temporarily disabled for safety). Current default: word embeddings with average pooling.

---

### Sentiment Analysis Pipeline

```
Transcript (PII-redacted)
    ↓
SentimentService.sentiment(for:)
    ↓
Try FoundationModelsSentimentProvider (iOS 26+)
    ├─> SystemLanguageModel with @Generable SentimentAnalysis
    ├─> Structured output: {label: positive/neutral/negative, score: Double}
    └─> Temperature: 0.1
    ↓ (on failure or iOS < 26)
Try AFMSentimentProvider
    ├─> Embed input text
    ├─> Compute cosine similarity to 5 positive anchors
    ├─> Compute cosine similarity to 5 negative anchors
    └─> Score = avg(positive) - avg(negative), clamped to [-1, 1]
    ↓ (on failure)
Try CoreMLSentimentProvider
    ├─> Load PulsumSentimentCoreML.mlmodel
    └─> Return discrete: positive=0.7, negative=-0.7, neutral=0
    ↓ (on failure)
Try NaturalLanguageSentimentProvider
    └─> NLTagger with .sentimentScore scheme
    ↓ (on failure)
Return 0.0 (neutral fallback)
```

---

### Safety Classification Pipeline

```
Text Input
    ↓
SafetyAgent.evaluate(text:)
    ↓
Try FoundationModelsSafetyProvider (iOS 26+)
    ├─> SystemLanguageModel with @Generable SafetyAssessment
    ├─> Structured output: {rating: safe/caution/crisis, reason: String}
    ├─> Temperature: 0.0 (deterministic)
    └─> Guardrail violations → return .safe (fail-open)
    ↓ (on failure or iOS < 26)
SafetyLocal.classify(text:)
    ├─> Check crisis keywords (5): "suicide", "kill myself", "end my life", "not worth living", "better off dead"
    ├─> Check caution keywords (5): "depressed", "anxious", "worthless", "hopeless", "overwhelming"
    ├─> Embed text → compute cosine similarity to 12 prototypes (4 crisis, 4 caution, 4 safe)
    ├─> Thresholds: crisis=0.65, caution=0.35, margin=0.10
    └─> Upgrade to .crisis only if keyword match found
    ↓
Return SafetyDecision
    ├─> classification: SafetyClassification (.safe / .caution(reason) / .crisis(reason))
    ├─> allowCloud: Bool (false for .crisis, consent-dependent for .safe/.caution)
    └─> crisisMessage: String? ("If you're in the United States, call 911 right away")
```

**Safety Routing Impact:**
- `.crisis` → blocks all cloud calls, shows US 911 overlay
- `.caution` → allows on-device only (no GPT-5)
- `.safe` → allows cloud if consent granted

---

### Recommendation Ranking Pipeline

```
User Context (FeatureVectorSnapshot)
    ↓
CoachAgent.recommendationCards(for:consentGranted:)
    ↓
1. Vector Search
    ├─> Embed current wellbeing state + recent journal → query vector
    └─> VectorIndexManager.searchMicroMoments(query:topK: 20)
    ↓
2. Feature Extraction (per candidate)
    ├─> wellbeingScore: From StateEstimator
    ├─> evidenceStrength: EvidenceBadge → score (Strong=1.0, Medium=0.7, Weak=0.3)
    ├─> novelty: Days since last shown (0 if never shown, capped at 30)
    ├─> cooldown: 1 - (elapsedSec / cooldownSec) if within cooldown, else 1.0
    ├─> acceptanceRate: (acceptances / total) from RecommendationEvent, default 0.5
    ├─> timeCostFit: 1 - (estimatedTimeSec / 1800), normalized to [0, 1]
    └─> z-scores: {z_hrv, z_nocthr, z_resthr, z_sleepDebt, z_rr, z_steps}
    ↓
3. Ranking
    ├─> RecRanker.rank(candidates)
    │   └─> For each: score = sigmoid(Σ(weight_i * feature_i))
    └─> Sort descending by score
    ↓
4. Selection
    └─> Top 3 cards: 1 "Top Pick" + 2 alternates
    ↓
5. Card Generation
    ├─> title: MicroMoment.title
    ├─> body: MicroMoment.shortDescription
    ├─> caution: generateCautionMessage(for:snapshot:consentGranted:)
    │   ├─> iOS 26+ with consent: FoundationModels intelligent caution (temperature=0.3)
    │   └─> Fallback: Heuristic (difficulty="hard" → "Take it easy if fatigued")
    └─> sourceBadge: EvidenceBadge (Strong/Medium/Weak)
    ↓
Return [RecommendationCard]
```

**RecRanker Weights (initial):**
```swift
{
    "wellbeingScore": -0.2,      // Lower score → prefer easier/safer
    "evidenceStrength": 0.6,     // Prefer strong evidence
    "novelty": 0.4,              // Prefer unseen items
    "cooldown": -0.5,            // Penalize items recently seen
    "acceptanceRate": 0.3,       // Prefer historically accepted items
    "timeCostFit": 0.2,          // Prefer activities that fit available time
    "z_hrv": -0.1, "z_nocthr": 0.1, "z_resthr": 0.1,
    "z_sleepDebt": 0.15, "z_rr": 0.05, "z_steps": -0.05
}
```

**Online Updates:**
- Pairwise gradient: When user completes card A over card B, increase weights for features where A > B
- Manual feedback: User explicit preferences (not yet implemented)

---

### Wellbeing Score Pipeline

```
Daily HealthKit Samples + Subjective Inputs + Journal Sentiment
    ↓
DataAgent.reprocessDay(date:)
    ↓
1. Compute Summary Metrics
    ├─> HRV: Median SDNN in sleep window (or sedentary window, or carry forward)
    ├─> Nocturnal HR: 10th percentile in sleep window
    ├─> Resting HR: Latest HKQuantityTypeIdentifier.restingHeartRate
    ├─> Sleep Debt: Σ(personalizedNeed - TST) over past 7 days
    │   └─> personalizedNeed = 7-day rolling average ± 0.75h around 7.5h default
    ├─> Respiratory Rate: Average RR in sleep window
    └─> Steps: Total step count (requires Motion authorization)
    ↓
2. Update Baselines (30-day rolling window)
    ├─> Fetch past 30 days of DailyMetrics
    ├─> Compute robust stats: median, MAD * 1.4826
    ├─> Compute EWMA: λ * newValue + (1 - λ) * previous (λ=0.2)
    └─> Persist to Baseline entity per metric
    ↓
3. Build Feature Bundle
    ├─> Compute z-scores: (value - median) / MAD for each metric
    └─> Collect subjective inputs: stress, energy, sleepQuality (1-7 scale)
    ↓
4. Compute Target (for StateEstimator update)
    target = -0.35*z_hrv + -0.25*z_steps + -0.4*z_sleepDebt
             + 0.45*subj_stress + -0.4*subj_energy + 0.3*subj_sleepQuality
    ↓
5. Update StateEstimator
    ├─> Gradient descent: ∇L = 2 * (predicted - target) * features + 2 * λ * weights
    ├─> weights[i] -= α * ∇L[i]
    ├─> Clip weights to [-2.0, 2.0]
    └─> Predict wellbeing score: Σ(weight_i * feature_i) + bias
    ↓
6. Persist FeatureVector
    └─> Store z-scores, subjective inputs, sentiment, wellbeingScore, contributions, imputedFlags
```

**StateEstimator Config:**
```swift
StateEstimatorConfig(
    learningRate: 0.05,
    regularizationLambda: 0.001,
    weightCap: 2.0
)
```

**Initial Weights:**
```swift
{
    "z_hrv": -0.6,              // Lower HRV → worse wellbeing
    "z_nocthr": 0.5,            // Lower nocturnal HR → better recovery
    "z_resthr": 0.4,            // Lower resting HR → better fitness
    "z_sleepDebt": 0.5,         // More sleep debt → worse wellbeing
    "z_steps": -0.2,            // More steps → better activity
    "z_rr": 0.1,                // Elevated RR → slight concern
    "subj_stress": 0.6,         // Higher stress → worse wellbeing
    "subj_energy": -0.6,        // Lower energy → worse wellbeing
    "subj_sleepQuality": 0.4    // Better sleep quality → better wellbeing
}
```

---

### Chat Response Pipeline

```
User Input
    ↓
AgentOrchestrator.chat(userInput:consentGranted:)
    ↓
1. PII Redaction
    └─> PIIRedactor.redact(userInput) → removes emails, phones, names
    ↓
2. Safety Gate
    ├─> SafetyAgent.evaluate(redactedInput)
    └─> If .crisis → return crisis message, block cloud
        If .caution → force on-device only
    ↓
3. Build Context
    ├─> Fetch latest FeatureVectorSnapshot
    ├─> Extract: wellbeingScore, z-scores, subjective inputs, sentiment
    └─> Create CoachLLMContext:
        {
            userToneHints: "supportive, concise",
            topSignal: "HRV low, stress elevated",
            topMomentId?: "recent-rec-123",
            rationale: "User asked about sleep quality",
            zScoreSummary: "HRV=-1.2, sleepDebt=+0.8, stress=6/7"
        }
    ↓
4. Route via LLMGateway
    ├─> If consentGranted && safetyDecision.allowCloud:
    │   └─> GPT5Client.generateResponse(context:apiKey:)
    │       ├─> POST https://api.openai.com/v1/responses
    │       ├─> Payload: {"model": "gpt-5", "input": [...], ...}
    │       └─> Sanitize: max 2 sentences, 280 chars per sentence
    └─> Else:
        ├─> FoundationModelsCoachGenerator (iOS 26+)
        │   ├─> SystemLanguageModel with Instructions
        │   ├─> Temperature: 0.6
        │   └─> Sanitize: max 2 sentences
        └─> Fallback: LegacyCoachGenerator (phrase matching)
    ↓
Return response to UI
```

**GPT-5 Request Format:**
```json
{
  "model": "gpt-5",
  "input": [
    {"role": "system", "content": "You are a wellness coach..."},
    {"role": "user", "content": "How can I improve my sleep?"}
  ],
  "max_output_tokens": 512,
  "reasoning": {"effort": "medium"},
  "text": {"verbosity": "medium"}
}
```

---

## 6. Agent System

### Manager Pattern

Pulsum uses a **manager-pattern agent architecture** where:
- **AgentOrchestrator** is the only agent exposed to the UI layer
- All 5 specialized agents (Data, Sentiment, Coach, Safety, Cheer) are treated as **tools** invoked by the orchestrator
- UI layer **never** directly accesses individual agents

### Agent Coordination Flow

```
User Action (e.g., record journal)
    ↓
AppViewModel / PulseViewModel
    ↓
AgentOrchestrator.recordVoiceJournal(maxDuration:)
    ↓
1. SentimentAgent.recordVoiceJournal(maxDuration:)
    ├─> SpeechService: Start on-device recording
    ├─> Receive transcript stream
    ├─> PIIRedactor: Remove sensitive info
    ├─> SentimentService: Compute sentiment score
    ├─> EmbeddingService: Generate 384-dim vector
    ├─> Core Data: Persist JournalEntry
    ├─> File System: Write vector to VectorIndex/JournalEntries/{UUID}.vec
    └─> Update FeatureVector.sentiment for today
    ↓
2. SafetyAgent.evaluate(transcript)
    ├─> FoundationModelsSafetyProvider (iOS 26+) → SafetyLocal fallback
    └─> Return SafetyDecision (classification, allowCloud, crisisMessage)
    ↓
3. Return JournalCaptureResponse
    ├─> result: JournalResult (entryID, transcript, sentimentScore, vectorURL)
    └─> safety: SafetyDecision
    ↓
PulseViewModel receives response
    ├─> If .crisis: Trigger SafetyCardView overlay
    └─> Else: Display transcript + sentiment score
```

### Agent Isolation

| Agent | Isolation | Rationale |
|-------|----------|-----------|
| **AgentOrchestrator** | `@MainActor` | UI-facing API, all public functions called from SwiftUI views |
| **DataAgent** | `actor` | Heavy HealthKit processing + Core Data writes; isolated for concurrency |
| **SentimentAgent** | `@MainActor` | Manages SpeechService (actor), but itself is main-actor for UI callbacks |
| **CoachAgent** | `@MainActor` | Generates recommendations + chat responses; needs main-actor for consistency |
| **SafetyAgent** | `@MainActor` | Quick classification; main-actor for simplicity |
| **CheerAgent** | `@MainActor` | Lightweight reinforcement; main-actor for UI updates |

### Cross-Actor Communication

**Example:** UI triggers recommendation refresh

```swift
@MainActor
func refreshRecommendations() async {
    isLoading = true
    defer { isLoading = false }

    do {
        // AgentOrchestrator is @MainActor
        let response = try await orchestrator.recommendations(consentGranted: consentProvider())

        // Internally, orchestrator calls:
        // 1. DataAgent (actor).latestFeatureVector() → crosses actor boundary
        // 2. CoachAgent (@MainActor).recommendationCards(for:consentGranted:)

        self.recommendations = response.cards
        self.wellbeingScore = response.wellbeingScore
    } catch {
        errorMessage = "Unable to load recommendations"
    }
}
```

**DataAgent (actor) to AgentOrchestrator (@MainActor):**
```swift
// Inside AgentOrchestrator.recommendations()
let snapshot = try await dataAgent.latestFeatureVector()  // async call to actor
// snapshot is now Sendable, safe to use on @MainActor
let cards = try await coachAgent.recommendationCards(for: snapshot, consentGranted: consentGranted)
```

---

## 7. UI Architecture

### View Model Binding Pattern

All views bind to **@MainActor @Observable** view models that hold references to `AgentOrchestrator`.

**Example: CoachView + CoachViewModel**

```swift
// CoachViewModel.swift
@MainActor
@Observable
final class CoachViewModel {
    private var orchestrator: AgentOrchestrator?
    private var consentProvider: (() -> Bool)?

    var recommendations: [RecommendationCard] = []
    var wellbeingScore: Double?
    var messages: [ChatMessage] = []
    var chatInput: String = ""
    var isSendingChat: Bool = false

    func bind(orchestrator: AgentOrchestrator, consentProvider: @escaping () -> Bool) {
        self.orchestrator = orchestrator
        self.consentProvider = consentProvider
        Task { await refreshRecommendations() }
    }

    func refreshRecommendations() async {
        guard let orchestrator, let consentProvider else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await orchestrator.recommendations(consentGranted: consentProvider())
            self.recommendations = response.cards
            self.wellbeingScore = response.wellbeingScore
        } catch {
            errorMessage = "Unable to load recommendations: \(error.localizedDescription)"
        }
    }

    func sendChat() async {
        guard let orchestrator, let consentProvider else { return }
        guard !chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userText = chatInput
        chatInput = ""
        messages.append(ChatMessage(role: .user, text: userText))

        isSendingChat = true
        defer { isSendingChat = false }

        do {
            let response = try await orchestrator.chat(userInput: userText, consentGranted: consentProvider())
            messages.append(ChatMessage(role: .assistant, text: response))
        } catch {
            chatErrorMessage = "Unable to send message: \(error.localizedDescription)"
        }
    }
}

// CoachView.swift
struct CoachScreen: View {
    @State var viewModel: CoachViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Recommendations
            ScrollView {
                ForEach(viewModel.recommendations, id: \.id) { card in
                    RecommendationCardView(card: card) {
                        Task { await viewModel.markCardComplete(card) }
                    }
                }
            }

            // Chat
            ScrollView {
                ForEach(viewModel.messages) { message in
                    ChatBubble(message: message)
                }

                if viewModel.isSendingChat {
                    ProgressView("Analyzing...")
                }
            }

            // Input
            ChatInputView(text: $viewModel.chatInput, onSend: {
                Task { await viewModel.sendChat() }
            })
        }
    }
}
```

### Foundation Models Status Display

**SettingsView integration:**

```swift
// SettingsViewModel.swift
@MainActor
@Observable
final class SettingsViewModel {
    var foundationModelsStatus: String = "Checking..."

    func refreshFoundationStatus() {
        guard let orchestrator else { return }
        foundationModelsStatus = orchestrator.foundationModelsStatus
    }
}

// SettingsView.swift
Section("AI Models") {
    HStack {
        Image(systemName: "cpu")
        Text("Apple Intelligence")
        Spacer()
        Text(viewModel.foundationModelsStatus)
            .foregroundStyle(.secondary)
    }

    if viewModel.foundationModelsStatus.contains("needs") {
        Link("Open Settings", destination: URL(string: UIApplication.openSettingsURLString)!)
    }
}
```

**Status Messages:**
- `"Apple Intelligence is ready"` → Foundation Models available
- `"Preparing AI model... This may take a few minutes"` → Model downloading
- `"Enable Apple Intelligence in Settings to use AI features"` → Needs user action
- `"This device doesn't support Apple Intelligence"` → Hardware limitation
- `"Unknown status"` → Error or iOS < 26

### Loading States

All async operations show loading indicators:

```swift
// PulseViewModel.swift
@MainActor
@Observable
final class PulseViewModel {
    var isRecording: Bool = false
    var recordingSecondsRemaining: Int = 30
    var transcript: String?
    var analysisError: String?

    func startRecording(maxDuration: TimeInterval = 30) {
        guard let orchestrator else { return }
        isRecording = true
        recordingSecondsRemaining = Int(maxDuration)

        // Countdown task
        Task {
            while recordingSecondsRemaining > 0 && isRecording {
                try? await Task.sleep(for: .seconds(1))
                recordingSecondsRemaining -= 1
            }
        }

        // Recording task
        Task {
            do {
                let result = try await orchestrator.recordVoiceJournal(maxDuration: maxDuration)
                self.transcript = result.result.transcript
                self.sentimentScore = result.result.sentimentScore

                if !result.safety.allowCloud {
                    onSafetyDecision?(result.safety)
                }
            } catch {
                analysisError = error.localizedDescription
            }
            isRecording = false
        }
    }
}

// PulseView.swift
TapToRecordButton(
    isRecording: viewModel.isRecording,
    remainingSeconds: viewModel.recordingSecondsRemaining,
    onTap: {
        if viewModel.isRecording {
            viewModel.stopRecording()
        } else {
            Task { await viewModel.startRecording() }
        }
    }
)
.overlay {
    if viewModel.isRecording {
        CircularProgressView(progress: Double(30 - viewModel.recordingSecondsRemaining) / 30.0)
    }
}
```

### Error Handling

**Foundation Models Errors:**

```swift
// CoachViewModel.swift
func sendChat() async {
    // ... [truncated for brevity]

    do {
        let response = try await orchestrator.chat(userInput: userText, consentGranted: consentProvider())
        messages.append(ChatMessage(role: .assistant, text: response))
    } catch let error as LanguageModelSession.GenerationError {
        switch error {
        case .guardrailViolation:
            messages.append(ChatMessage(role: .system, text: "Let's keep the focus on supportive wellness actions."))
        case .refusal:
            messages.append(ChatMessage(role: .system, text: "Unable to process that request. Try rephrasing."))
        @unknown default:
            messages.append(ChatMessage(role: .system, text: "Switching to on-device intelligence."))
        }
    } catch {
        chatErrorMessage = "Unable to send message: \(error.localizedDescription)"
    }
}
```

**User-Facing Messages:**
- Guardrail violation → "Let's keep the focus on supportive wellness actions"
- Refusal → "Unable to process that request. Try rephrasing"
- Model unavailable → "Enhanced AI features require Apple Intelligence. Using on-device intelligence."

### Fallback Messaging

**ConsentPrompt (embedded in CoachView):**

```swift
if viewModel.foundationModelsStatus != "ready" && !consentGranted {
    VStack(spacing: Spacing.md) {
        Image(systemName: "info.circle")
        Text("Enhanced AI features require Apple Intelligence.")
            .font(.pulsumCallout)
            .foregroundStyle(.secondary)
        Text("Currently using on-device intelligence for all recommendations and chat.")
            .font(.pulsumFootnote)
            .foregroundStyle(.tertiary)
    }
    .padding()
    .background(Color.pulsumBlueSoft.opacity(0.3))
    .cornerRadius(Radius.md)
}
```

---

## 8. Data Flow

### End-to-End Flow: Journal Recording

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. User taps mic button in PulseView                            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. PulseViewModel.startRecording()                              │
│    - Sets isRecording = true                                    │
│    - Starts countdown timer task                                │
│    - Calls orchestrator.recordVoiceJournal(maxDuration: 30)    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. AgentOrchestrator.recordVoiceJournal()                       │
│    - Delegates to SentimentAgent.recordVoiceJournal()           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. SentimentAgent.recordVoiceJournal()                          │
│    a. SpeechService (actor): Start on-device recording          │
│       - SFSpeechRecognizer with requiresOnDeviceRecognition     │
│       - Returns AsyncThrowingStream<SpeechSegment>              │
│    b. Accumulate transcript as segments arrive                  │
│    c. PIIRedactor.redact(transcript)                            │
│    d. SentimentService.sentiment(for: redactedTranscript)       │
│       - Try FoundationModels → AFM → CoreML → NaturalLanguage   │
│    e. EmbeddingService.embedding(for: redactedTranscript)       │
│       - Try AFM → CoreML → zero vector                          │
│    f. Core Data write (background context):                     │
│       - Create JournalEntry with UUID, date, transcript, sentiment│
│    g. File System write:                                        │
│       - Write vector to VectorIndex/JournalEntries/{UUID}.vec   │
│       - Format: binary float32 array (384 * 4 = 1536 bytes)    │
│    h. Update FeatureVector.sentiment for today's date           │
│    i. Return JournalResult (entryID, transcript, sentiment, vectorURL)│
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. AgentOrchestrator: SafetyAgent.evaluate(transcript)          │
│    a. Try FoundationModelsSafetyProvider (iOS 26+)              │
│       - SystemLanguageModel with @Generable SafetyAssessment    │
│       - Temperature: 0.0 (deterministic)                        │
│    b. Fallback: SafetyLocal.classify(transcript)                │
│       - Keyword check + prototype-based embedding similarity    │
│    c. Return SafetyDecision (classification, allowCloud, crisisMessage)│
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 6. AgentOrchestrator returns JournalCaptureResponse             │
│    - result: JournalResult                                      │
│    - safety: SafetyDecision                                     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 7. PulseViewModel receives response                             │
│    - Sets transcript, sentimentScore                            │
│    - If safety.classification == .crisis:                       │
│      → Triggers onSafetyDecision callback                       │
│      → AppViewModel shows SafetyCardView overlay                │
│    - Else: Display transcript + sentiment in UI                 │
└─────────────────────────────────────────────────────────────────┘
```

### End-to-End Flow: HealthKit → Wellbeing Score

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. HealthKit background delivery fires HKObserverQuery          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. HealthKitService calls update handler                        │
│    - Executes HKAnchoredObjectQuery from last anchor            │
│    - Returns AnchoredUpdate (samples, deletedSamples, newAnchor)│
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. DataAgent (actor) receives update                            │
│    - processQuantitySamples() or processCategorySamples()       │
│    - Appends timestamped samples to DailyMetrics.flags (JSON)   │
│    - Persists new HKQueryAnchor via HealthKitAnchorStore        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. DataAgent.reprocessDay(date:)                                │
│    a. Fetch DailyMetrics.flags for date                         │
│    b. Decode JSON → DailyFlags (arrays of HRVSample, etc.)      │
│    c. Compute summary metrics:                                  │
│       - HRV: Median SDNN in sleep window                        │
│       - Nocturnal HR: 10th percentile in sleep window           │
│       - Resting HR: Latest sample                               │
│       - Sleep Debt: Σ(need - TST) over past 7 days             │
│       - Respiratory Rate: Average in sleep window               │
│       - Steps: Total step count                                 │
│    d. Update DailyMetrics entity with summary values            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. DataAgent.updateBaselines()                                  │
│    - Fetch past 30 days of DailyMetrics                         │
│    - For each metric:                                           │
│      a. Compute robust stats: median, MAD * 1.4826              │
│      b. Compute EWMA: λ * newValue + (1-λ) * previous (λ=0.2)   │
│      c. Persist to Baseline entity                              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 6. DataAgent.buildFeatureBundle()                               │
│    - For each metric: z-score = (value - median) / MAD          │
│    - Collect subjective inputs: stress, energy, sleepQuality    │
│    - Collect sentiment from JournalEntry (if any today)         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 7. StateEstimator.update()                                      │
│    a. Compute target:                                           │
│       target = -0.35*z_hrv + -0.25*z_steps + -0.4*z_sleepDebt   │
│                + 0.45*subj_stress + -0.4*subj_energy            │
│                + 0.3*subj_sleepQuality                          │
│    b. Predict: score = Σ(weight_i * feature_i) + bias           │
│    c. Gradient descent:                                         │
│       ∇L = 2 * (predicted - target) * features + 2 * λ * weights│
│       weights[i] -= α * ∇L[i]                                   │
│    d. Clip weights to [-2.0, 2.0]                               │
│    e. Return StateEstimatorSnapshot (weights, bias, score, contributions)│
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 8. DataAgent persists FeatureVector                             │
│    - date, z-scores, subjective inputs, sentiment, imputedFlags │
│    - Wellbeing score stored in StateEstimatorSnapshot (in-memory)│
│    - Contributions: per-feature impact on score                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 9. UI layer calls orchestrator.scoreBreakdown()                 │
│    - DataAgent returns ScoreBreakdown with metric-by-metric detail│
│    - ScoreBreakdownView displays wellbeing score + contributions│
└─────────────────────────────────────────────────────────────────┘
```

---

## 9. Privacy & Security

### File Protection

All persistent data uses **iOS Data Protection** with `FileProtectionType.complete`:

| Data Store | Protection | Backup Exclusion |
|------------|-----------|------------------|
| `Pulsum.sqlite` | `.complete` | ✅ Yes |
| `VectorIndex/` directory | `.complete` | ✅ Yes |
| `Anchors/` directory | `.complete` | ✅ Yes |
| Keychain items | `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` | ✅ Automatic |

**Implementation:**

```swift
// DataStack.swift (Core Data store)
let description = NSPersistentStoreDescription(url: sqliteStoreURL)
#if os(iOS)
description.setOption(FileProtectionType.complete as NSObject, forKey: NSPersistentStoreFileProtectionKey)
#endif

// VectorIndex.swift (shard files)
#if os(iOS)
try fileManager.createDirectory(at: shardDirectory, withIntermediateDirectories: true,
    attributes: [.protectionKey: FileProtectionType.complete])
#endif

// Backup exclusion
var resourceValues = URLResourceValues()
resourceValues.isExcludedFromBackup = true
var supportURL = storagePaths.applicationSupport
try? supportURL.setResourceValues(resourceValues)
```

### PII Redaction

**PIIRedactor** removes personally identifiable information before any cloud transmission:

```swift
public enum PIIRedactor {
    public static func redact(_ transcript: String) -> String {
        var text = transcript

        // Email addresses
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        text = text.replacingOccurrences(of: emailPattern, with: "[EMAIL]", options: .regularExpression)

        // Phone numbers (US format + international)
        let phonePatterns = [
            "\\+?1?\\s?\\(?\\d{3}\\)?[\\s.-]?\\d{3}[\\s.-]?\\d{4}",
            "\\d{3}-\\d{3}-\\d{4}",
            "\\(\\d{3}\\)\\s?\\d{3}-\\d{4}"
        ]
        for pattern in phonePatterns {
            text = text.replacingOccurrences(of: pattern, with: "[PHONE]", options: .regularExpression)
        }

        // Personal names via NLTagger
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let tags: [NLTag] = [.personalName]

        var redactedText = text
        var offset = 0
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, range in
            if let tag = tag, tags.contains(tag) {
                let startIndex = text.index(text.startIndex, offsetBy: text.distance(from: text.startIndex, to: range.lowerBound) + offset)
                let endIndex = text.index(text.startIndex, offsetBy: text.distance(from: text.startIndex, to: range.upperBound) + offset)
                let replacement = "[NAME]"
                redactedText.replaceSubrange(startIndex..<endIndex, with: replacement)
                offset += replacement.count - text.distance(from: range.lowerBound, to: range.upperBound)
            }
            return true
        }

        return redactedText
    }
}
```

**Applied:**
- Voice journal transcripts before sentiment analysis (if cloud provider)
- Chat user input before GPT-5 API calls
- All text before `LLMGateway.generateCoachResponse()`

### Consent Gate

**Cloud Processing Consent** (UserPrefs entity):

```swift
// ConsentStore (private in AppViewModel)
private final class ConsentStore {
    private let context = PulsumData.viewContext

    func loadConsentState() -> Bool {
        let fetchRequest = UserPrefs.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", "default")
        fetchRequest.fetchLimit = 1

        guard let prefs = try? context.fetch(fetchRequest).first else {
            return false  // Default: consent OFF
        }
        return prefs.consentCloud
    }

    func saveConsentState(_ granted: Bool) throws {
        let fetchRequest = UserPrefs.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", "default")
        fetchRequest.fetchLimit = 1

        let prefs = (try? context.fetch(fetchRequest).first) ?? {
            let new = UserPrefs(context: context)
            new.id = "default"
            return new
        }()

        prefs.consentCloud = granted
        prefs.updatedAt = Date()
        try context.save()
    }
}
```

**Routing Impact:**

| Consent | Safety Classification | Cloud Allowed? | LLM Route |
|---------|----------------------|----------------|-----------|
| OFF | .safe | ❌ No | On-device (FoundationModels → LegacyGenerator) |
| OFF | .caution | ❌ No | On-device |
| OFF | .crisis | ❌ No | Blocked (show 911 card) |
| ON | .safe | ✅ Yes | Cloud (GPT-5) |
| ON | .caution | ❌ No | On-device |
| ON | .crisis | ❌ No | Blocked (show 911 card) |

**Consent Banner Copy:**

```
"Pulsum can optionally use GPT-5 to phrase brief coaching text. If you allow cloud processing, Pulsum sends only minimized context (no journals, no raw health data, no identifiers). PII is redacted. You can turn this off anytime in Settings ▸ Cloud Processing."
```

### Minimized Context (Cloud Payloads)

**CoachLLMContext** structure sent to GPT-5:

```swift
public struct CoachLLMContext: Codable, Sendable {
    public let userToneHints: String         // e.g., "supportive, concise"
    public let topSignal: String             // e.g., "HRV low, stress elevated"
    public let topMomentId: String?          // e.g., "breathwork-box-breathing"
    public let rationale: String             // e.g., "User asked about sleep quality"
    public let zScoreSummary: String         // e.g., "HRV=-1.2, sleepDebt=+0.8, stress=6/7"
}
```

**What's NEVER sent to cloud:**
- Journal transcripts (stored locally only)
- Raw HealthKit samples (only z-scores sent)
- Personal identifiers (UUIDs, emails, names)
- Vector embeddings
- Sentiment scores (only summary text like "sentiment positive")

### Keychain Security

**KeychainService** for API keys:

```swift
public final class KeychainService {
    public static let shared = KeychainService()
    private let serviceIdentifier = "ai.pulsum.app"

    public func setSecret(_ value: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecValueData as String: value,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)  // Remove existing
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainServiceError.unableToStore(status: status)
        }
    }

    public func secret(for key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound { return nil }
            throw KeychainServiceError.unableToRetrieve(status: status)
        }

        return result as? Data
    }
}
```

**Current Usage:**
- GPT-5 API key (hardcoded for testing, but infrastructure ready for user-provided keys)

### Entitlements

**Pulsum.entitlements:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.healthkit</key>
    <true/>
    <key>com.apple.developer.healthkit.background-delivery</key>
    <true/>
</dict>
</plist>
```

**Info.plist Keys (required):**
- `NSHealthShareUsageDescription`: "Pulsum analyzes your heart rate, sleep, and activity to provide personalized wellness recommendations."
- `NSHealthUpdateUsageDescription`: (Not used; read-only access)
- `NSMicrophoneUsageDescription`: "Pulsum uses your microphone to record optional voice journals. Audio is processed on-device only."
- `NSSpeechRecognitionUsageDescription`: "Pulsum transcribes your voice journals on-device. Transcripts never leave your device unless you enable cloud processing."

---

## 10. API Reference

### AgentOrchestrator (Public API)

```swift
@MainActor
public final class AgentOrchestrator {
    // MARK: - Initialization
    public init() throws

    // MARK: - Lifecycle
    public func start() async throws

    // MARK: - Properties
    public var foundationModelsStatus: String { get }

    // MARK: - Voice Journal
    public func recordVoiceJournal(maxDuration: TimeInterval = 30) async throws -> JournalCaptureResponse
    public func submitTranscript(_ text: String) async throws -> JournalCaptureResponse
    public func stopVoiceJournalRecording()

    // MARK: - Subjective Inputs
    public func updateSubjectiveInputs(date: Date, stress: Double, energy: Double, sleepQuality: Double) async throws

    // MARK: - Recommendations
    public func recommendations(consentGranted: Bool) async throws -> RecommendationResponse
    public func scoreBreakdown() async throws -> ScoreBreakdown?

    // MARK: - Chat
    public func chat(userInput: String, consentGranted: Bool) async throws -> String

    // MARK: - Completion
    public func logCompletion(momentId: String) async throws -> CheerEvent
}

// MARK: - Response Types

public struct RecommendationResponse {
    public let cards: [RecommendationCard]
    public let wellbeingScore: Double
    public let contributions: [String: Double]
}

public struct RecommendationCard: Equatable {
    public let id: String
    public let title: String
    public let body: String
    public let caution: String?
    public let sourceBadge: String  // "Strong", "Medium", "Weak"
}

public struct JournalCaptureResponse {
    public let result: JournalResult
    public let safety: SafetyDecision
}

public struct JournalResult {
    public let entryID: UUID
    public let transcript: String
    public let sentimentScore: Double
    public let vectorURL: String
}

public struct SafetyDecision {
    public let classification: SafetyClassification
    public let allowCloud: Bool
    public let crisisMessage: String?
}

public enum SafetyClassification: Equatable {
    case safe
    case caution(reason: String)
    case crisis(reason: String)
}

public struct CheerEvent {
    public let message: String
    public let haptic: HapticType  // .success, .light, .heavy
    public let timestamp: Date
}

public struct ScoreBreakdown: Sendable {
    public let date: Date
    public let wellbeingScore: Double
    public let metrics: [MetricDetail]
    public let generalNotes: [String]

    public struct MetricDetail: Identifiable, Sendable {
        public let id: String
        public let name: String
        public let kind: MetricKind  // .objective, .subjective, .sentiment
        public let value: Double?
        public let unit: String?
        public let zScore: Double?
        public let contribution: Double?
        public let baselineMedian: Double?
        public let baselineEWMA: Double?
        public let baselineMAD: Double?
        public let rollingWindowDays: Int?
        public let explanation: String
        public let notes: [String]
    }
}
```

### DataAgent (Actor API)

```swift
public actor DataAgent {
    // MARK: - Initialization
    public init(healthKitService: HealthKitService) async

    // MARK: - Lifecycle
    public func start() async throws

    // MARK: - Queries
    public func latestFeatureVector() async throws -> FeatureVectorSnapshot?
    public func scoreBreakdown() async throws -> ScoreBreakdown?

    // MARK: - Updates
    public func recordSubjectiveInputs(date: Date, stress: Double, energy: Double, sleepQuality: Double) async throws
}

public struct FeatureVectorSnapshot: Sendable {
    public let date: Date
    public let wellbeingScore: Double
    public let contributions: [String: Double]
    public let imputedFlags: [String: Bool]
    public let featureVectorObjectID: NSManagedObjectID
    public let features: [String: Double]
}
```

### PulsumML (Public Facade)

```swift
public enum PulsumML {
    // MARK: - Embeddings
    public static func embedding(for text: String) -> [Float]
    public static func embedding(forSegments segments: [String]) -> [Float]
}

public enum BaselineMath {
    public struct RobustStats: Sendable {
        public let median: Double
        public let mad: Double
    }

    public static func robustStats(for values: [Double]) -> RobustStats?
    public static func zScore(value: Double, stats: RobustStats) -> Double
    public static func ewma(previous: Double?, newValue: Double, lambda: Double = 0.2) -> Double
}

public final class StateEstimator {
    public struct Config {
        public let learningRate: Double        // 0.05
        public let regularizationLambda: Double // 0.001
        public let weightCap: Double           // 2.0
    }

    public struct Snapshot: Sendable {
        public let weights: [String: Double]
        public let bias: Double
        public let wellbeingScore: Double
        public let contributions: [String: Double]
    }

    public init(config: Config = Config())
    public func predict(features: [String: Double]) -> Double
    public func update(features: [String: Double], target: Double) -> Snapshot
}

public final class RecRanker {
    public struct RecommendationFeatures {
        public let id: String
        public let wellbeingScore: Double
        public let evidenceStrength: Double
        public let novelty: Double
        public let cooldown: Double
        public let acceptanceRate: Double
        public let timeCostFit: Double
        public let zScores: [String: Double]
    }

    public init()
    public func score(features: RecommendationFeatures) -> Double
    public func rank(_ candidates: [RecommendationFeatures]) -> [RecommendationFeatures]
    public func update(preferred: RecommendationFeatures, other: RecommendationFeatures)
}

public final class SafetyLocal {
    public struct Config {
        public let crisisKeywords: [String]
        public let cautionKeywords: [String]
        public let crisisThreshold: Double    // 0.65
        public let cautionThreshold: Double   // 0.35
        public let margin: Double             // 0.10
    }

    public init(config: Config = Config())
    public func classify(text: String) -> SafetyClassification
}
```

### PulsumServices (Public Facade)

```swift
public enum PulsumServices {
    public static var healthKit: HealthKitService { get }
    public static var keychain: KeychainService { get }
    public static func storageMetadata() -> String
    public static func embeddingVersion() -> String
}

public final class HealthKitService {
    public static var readSampleTypes: Set<HKSampleType> { get }

    public func requestAuthorization() async throws
    public func enableBackgroundDelivery() async throws
    public func observeSampleType(_ sampleType: HKSampleType, predicate: NSPredicate?,
                                   updateHandler: @escaping AnchoredUpdateHandler) throws -> HKObserverQuery
    public func stopObserving(sampleType: HKSampleType, resetAnchor: Bool = false)
}

public actor SpeechService {
    public func requestAuthorization() async throws
    public func startRecording(maxDuration: TimeInterval = 30) async throws -> Session
    public func stopRecording()

    public struct Session: Sendable {
        public let stream: AsyncThrowingStream<SpeechSegment, Error>
        public let stop: @Sendable () -> Void
    }
}

public final class LLMGateway {
    public static let shared = LLMGateway()

    public func setAPIKey(_ key: String) throws
    public func testAPIConnection() async throws -> Bool
    public func generateCoachResponse(context: CoachLLMContext, consentGranted: Bool) async -> String
}

public struct CoachLLMContext: Codable, Sendable {
    public let userToneHints: String
    public let topSignal: String
    public let topMomentId: String?
    public let rationale: String
    public let zScoreSummary: String
}
```

### PulsumData (Public Facade)

```swift
public enum PulsumData {
    // MARK: - Core Data Stack
    public static var dataStack: DataStack { get }
    public static var container: NSPersistentContainer { get }
    public static var viewContext: NSManagedObjectContext { get }

    public static func newBackgroundContext(name: String = "Pulsum.Background") -> NSManagedObjectContext
    public static func performBackgroundTask(_ block: @Sendable @escaping (NSManagedObjectContext) -> Void)

    // MARK: - Paths
    public static var applicationSupportDirectory: URL { get }
    public static var sqliteStoreURL: URL { get }
    public static var vectorIndexDirectory: URL { get }
    public static var healthAnchorsDirectory: URL { get }
}

public final class VectorIndexManager: VectorIndexProviding {
    public static let shared: VectorIndexManager

    @discardableResult
    public func upsertMicroMoment(id: String, title: String, detail: String?, tags: [String]?) throws -> [Float]
    public func removeMicroMoment(id: String) throws
    public func searchMicroMoments(query: String, topK: Int) throws -> [VectorMatch]
}

public struct VectorMatch: Equatable {
    public let id: String
    public let score: Float  // L2 distance (lower = better)
}

public final class LibraryImporter {
    public struct Configuration {
        public let bundle: Bundle
        public let subdirectory: String?
        public let fileExtension: String
    }

    public init(configuration: Configuration,
                context: NSManagedObjectContext,
                vectorIndexManager: VectorIndexProviding)

    public func ingestIfNeeded() async throws
}
```

---

## 11. Implementation Details

### HealthKit Sample Processing

**DailyFlags Structure (JSON stored in DailyMetrics.flags):**

```swift
private struct DailyFlags: Codable {
    struct HRVSample: Codable {
        let timestamp: Date
        let sdnn: Double
        let source: String
    }

    struct HeartRateSample: Codable {
        let timestamp: Date
        let bpm: Double
        let source: String
    }

    struct RespiratorySample: Codable {
        let timestamp: Date
        let breathsPerMin: Double
        let source: String
    }

    struct SleepSegment: Codable {
        let start: Date
        let end: Date
        let value: Int  // HKCategoryValueSleepAnalysis rawValue
    }

    struct StepBucket: Codable {
        let hour: Int
        let count: Int
    }

    var hrvSamples: [HRVSample] = []
    var heartRateSamples: [HeartRateSample] = []
    var respiratorySamples: [RespiratorySample] = []
    var sleepSegments: [SleepSegment] = []
    var stepBuckets: [StepBucket] = []
    var restingHRLatest: Double?
    var restingHRTimestamp: Date?
}
```

**Summary Computation:**

1. **HRV Median:**
   - Identify sleep intervals from `sleepSegments` (inBed, asleepCore, asleepDeep, asleepREM)
   - Filter `hrvSamples` where `timestamp` falls within sleep intervals
   - If ≥1 sample: Compute median SDNN
   - Else: Use sedentary intervals (≤30 steps/hour, ≥30 min duration, not in sleep)
   - Else: Carry forward previous day's value with `imputedFlags["hrv"] = true`

2. **Nocturnal HR:**
   - Filter `heartRateSamples` where `timestamp` falls within sleep intervals
   - Compute 10th percentile (or lowest 5-min rolling mean)
   - Fallback: Same as HRV (sedentary → carry forward)

3. **Resting HR:**
   - Use latest `restingHRLatest` value from HealthKit
   - Fallback: Carry forward previous day with `imputedFlags["restingHR"] = true`

4. **Sleep Debt:**
   - Compute TST (total sleep time) from `sleepSegments` (sum durations of asleepCore/deep/REM)
   - Compute personalized need:
     ```swift
     let past7TST = // fetch past 7 days' TST
     let mean7 = past7TST.reduce(0, +) / Double(past7TST.count)
     let personalizedNeed = min(max(mean7, 7.5 - 0.75), 7.5 + 0.75)  // Clamp to [6.75, 8.25]
     ```
   - Sleep debt: `Σ(personalizedNeed - TST)` over past 7 days

5. **Respiratory Rate:**
   - Filter `respiratorySamples` where `timestamp` falls within sleep intervals
   - Compute average
   - Flag as `rr_missing` if no samples

6. **Steps:**
   - Sum `stepBuckets[*].count`
   - Require Motion authorization; else flag as `steps_missing`
   - Flag as `steps_low_confidence` if authorization not determined

**Baseline Update (30-day rolling window):**

```swift
private func updateBaselines() async throws {
    let metricsToBaseline = ["hrv", "nocturnalHR", "restingHR", "sleepDebt", "respiratoryRate", "steps"]

    for metricName in metricsToBaseline {
        let values = // fetch past 30 days' DailyMetrics[metricName]
        guard let robustStats = BaselineMath.robustStats(for: values) else { continue }

        let baseline = // fetch or create Baseline(metric: metricName)
        baseline.median = robustStats.median
        baseline.mad = robustStats.mad

        let latestValue = values.last!
        let previousEWMA = baseline.ewma ?? latestValue
        baseline.ewma = BaselineMath.ewma(previous: previousEWMA, newValue: latestValue, lambda: 0.2)
        baseline.windowDays = 30
        baseline.updatedAt = Date()
    }

    try context.save()
}
```

---

### Vector Index Format

**Binary Shard File Structure:**

```
Offset | Size (bytes) | Field             | Description
-------|--------------|-------------------|----------------------------------
0      | 4            | magic             | 0x50535649 ('PSVI')
4      | 2            | version           | 1
6      | 2            | dimension         | 384
8      | 8            | recordCount       | Number of active records
16     | variable     | records[]         | Record array (see below)
```

**Record Structure:**

```
Offset | Size (bytes) | Field             | Description
-------|--------------|-------------------|----------------------------------
0      | 2            | idLength          | Length of ID string
2      | 2            | flags             | 0=active, 1=deleted
4      | idLength     | id                | UTF-8 encoded ID string
4+idL  | 1536         | vector            | 384 * float32 (little-endian)
```

**Metadata File (JSON):**

```json
{
  "moment-123": 16,
  "moment-456": 1572,
  ...
}
```

Maps ID → file offset for fast lookup.

**Search Algorithm (L2 Distance):**

```swift
private func l2Distance(query: [Float], vectorData: Data) -> Float {
    var sum: Float = 0
    var index = vectorData.startIndex
    for value in query {
        let end = index + MemoryLayout<Float>.size
        let slice = vectorData[index..<end]
        let stored = Float(bitPattern: slice.toUInt32())
        let diff = value - stored
        sum += diff * diff
        index = end
    }
    return sqrt(sum)
}
```

**Sharding:**

```swift
let shardIndex = abs(id.hashValue) % 16
```

Top-K search queries all 16 shards in parallel, merges results, sorts by distance ascending.

---

### Foundation Models Integration Details

**Availability Checking:**

```swift
import FoundationModels

public enum AFMStatus {
    case ready
    case needsAppleIntelligence
    case downloading
    case unsupportedDevice
    case unknown
}

public final class FoundationModelsAvailability {
    @available(iOS 26.0, *)
    public static func checkAvailability() -> AFMStatus {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            return .ready
        case .unavailable(.needsAppleIntelligence):
            return .needsAppleIntelligence
        case .unavailable(.downloading):
            return .downloading
        case .unavailable:
            return .unsupportedDevice
        @unknown default:
            return .unknown
        }
    }

    public static func availabilityMessage(for status: AFMStatus) -> String {
        switch status {
        case .ready:
            return "Apple Intelligence is ready"
        case .needsAppleIntelligence:
            return "Enable Apple Intelligence in Settings to use AI features"
        case .downloading:
            return "Preparing AI model... This may take a few minutes"
        case .unsupportedDevice:
            return "This device doesn't support Apple Intelligence"
        case .unknown:
            return "Unknown status"
        }
    }
}
```

**Structured Generation Example (Sentiment):**

```swift
import FoundationModels

@available(iOS 26.0, *)
@Generable
public enum SentimentLabel: String {
    case positive
    case neutral
    case negative
}

@available(iOS 26.0, *)
@Generable
public struct SentimentAnalysis {
    @Guide("Categorical sentiment classification")
    public let label: SentimentLabel

    @Guide("Continuous sentiment score in range [-1.0, 1.0] where -1 is very negative and 1 is very positive")
    public let score: Double
}

@available(iOS 26.0, *)
public final class FoundationModelsSentimentProvider: SentimentProviding {
    public func sentimentScore(for text: String) async throws -> Double {
        let model = SystemLanguageModel.default
        let session = try LanguageModelSession(model: model)

        let instructions = Instructions(
            instructions: "Analyze the sentiment of the following text. Return a SentimentAnalysis object with label and score."
        )

        let prompt = Prompt(messages: [
            .init(role: .system, content: instructions.instructions),
            .init(role: .user, content: text)
        ])

        let options = GenerationOptions(temperature: 0.1)

        do {
            let result: SentimentAnalysis = try await session.generate(prompt, options: options)
            return result.score
        } catch let error as LanguageModelSession.GenerationError {
            switch error {
            case .guardrailViolation, .refusal:
                return 0.0  // Fail-safe: neutral
            default:
                throw SentimentProviderError.unavailable
            }
        }
    }
}
```

**Foundation Models Coaching Example:**

```swift
import FoundationModels

public final class FoundationModelsCoachGenerator: OnDeviceCoachGenerator {
    public func generate(context: CoachLLMContext) async -> String {
        guard #available(iOS 26.0, *) else {
            return fallbackKeywordResponse(context: context)
        }

        let model = SystemLanguageModel.default
        guard model.availability == .available else {
            return fallbackKeywordResponse(context: context)
        }

        do {
            let session = try LanguageModelSession(model: model)

            let instructions = Instructions(
                instructions: """
                You are a supportive wellness coach. Keep responses under 80 words, max 2 sentences.
                Ground advice in user's health signals (HRV, sleep, stress). Never diagnose or make medical claims.
                """
            )

            let userMessage = """
            User context: \(context.topSignal)
            Z-scores: \(context.zScoreSummary)
            User inquiry: \(context.rationale)
            """

            let prompt = Prompt(messages: [
                .init(role: .system, content: instructions.instructions),
                .init(role: .user, content: userMessage)
            ])

            let options = GenerationOptions(temperature: 0.6)
            let result = try await session.generate(prompt, options: options)

            return sanitize(result)
        } catch {
            return fallbackKeywordResponse(context: context)
        }
    }

    private func sanitize(_ response: String) -> String {
        let sentences = response.components(separatedBy: ". ")
        return sentences.prefix(2).joined(separator: ". ") + (sentences.count > 2 ? "." : "")
    }

    private func fallbackKeywordResponse(context: CoachLLMContext) -> String {
        if context.topSignal.contains("HRV low") {
            return "Your HRV is lower than usual. Consider gentle recovery activities today."
        } else if context.topSignal.contains("stress") {
            return "Elevated stress detected. Short breathing exercises may help recenter."
        } else {
            return "Based on your current signals, prioritize activities that feel sustainable today."
        }
    }
}
```

---

### Recommendation Library Format

**JSON Structure:**

```json
[
  {
    "episodeNumber": "199",
    "episodeTitle": "Arnold's Pump Club - #199 It Doesn't Fcking Matter",
    "recommendations": [
      {
        "timestamp": "approximate",
        "recommendation": "Focus your energy only on what truly matters",
        "shortDescription": "Arnold recommends that you stop caring about things...",
        "detailedDescription": "The episode discusses how people have been conditioned...",
        "microActivity": "Whenever you feel yourself getting worked up...",
        "researchLink": "https://nida.nih.gov/research-topics/...",
        "difficultyLevel": "Easy",
        "timeToComplete": "1 min (mental check-in)",
        "tags": ["mental health", "focus", "energy management", "mindfulness"],
        "category": "Mental Health",
        "subcategory": "Stress Management"
      }
    ]
  }
]
```

**Ingestion Pipeline:**

1. Compute SHA256 checksum of JSON file
2. Check `LibraryIngest` entity for existing checksum
3. If match found, skip ingestion
4. Parse JSON → `PodcastEpisode` array
5. For each episode:
   - For each recommendation:
     - Generate unique ID: `"\(episodeNumber)-\(index)"`
     - Parse `timeToComplete` (regex: `(\d+)\s*(min|sec|hour)`)
     - Score evidence badge via `EvidenceScorer`
     - Create `MicroMoment` entity
     - Embed `title + detail + tags.joined()` via `EmbeddingService`
     - Upsert embedding to vector index
6. Save new `LibraryIngest` record with checksum
7. Commit Core Data transaction

**Evidence Scoring:**

```swift
struct EvidenceScorer {
    static func badge(for urlString: String?) -> EvidenceBadge {
        guard let urlString = urlString?.lowercased() else { return .weak }

        let strongDomains = ["pubmed", "nih.gov", ".gov", ".edu", "who.int", "cochrane.org"]
        let mediumDomains = ["nature.com", "sciencedirect.com", "mayoclinic.org", "harvard.edu"]

        if strongDomains.contains(where: { urlString.contains($0) }) {
            return .strong
        } else if mediumDomains.contains(where: { urlString.contains($0) }) {
            return .medium
        } else {
            return .weak
        }
    }
}
```

---

### StateEstimator Mathematics

**Linear Model:**

```
score = Σ(weight_i * feature_i) + bias
```

**Loss Function (Mean Squared Error + L2 Regularization):**

```
L = (predicted - target)² + λ * Σ(weight_i²)
```

**Gradient:**

```
∇L / ∂weight_i = 2 * (predicted - target) * feature_i + 2 * λ * weight_i
∇L / ∂bias = 2 * (predicted - target)
```

**Update Rule:**

```
weight_i -= α * ∇L / ∂weight_i
bias -= α * ∇L / ∂bias
```

**Weight Clipping:**

```
weight_i = max(-2.0, min(2.0, weight_i))
```

**Implementation:**

```swift
public final class StateEstimator {
    private var weights: [String: Double]
    private var bias: Double
    private let config: Config

    public func update(features: [String: Double], target: Double) -> Snapshot {
        let predicted = predict(features: features)
        let error = predicted - target

        for (key, value) in features {
            let gradient = 2 * error * value + 2 * config.regularizationLambda * (weights[key] ?? 0)
            var newWeight = (weights[key] ?? 0) - config.learningRate * gradient
            newWeight = max(-config.weightCap, min(config.weightCap, newWeight))
            weights[key] = newWeight
        }

        let biasGradient = 2 * error
        bias -= config.learningRate * biasGradient

        let contributions = features.mapValues { value in
            (weights[$0.key] ?? 0) * value
        }

        return Snapshot(
            weights: weights,
            bias: bias,
            wellbeingScore: predict(features: features),
            contributions: contributions
        )
    }

    public func predict(features: [String: Double]) -> Double {
        var score = bias
        for (key, value) in features {
            score += (weights[key] ?? 0) * value
        }
        return score
    }
}
```

---

## Conclusion

This document provides a **complete architectural overview** of the Pulsum iOS app, covering:
- ✅ All 5 Swift packages with detailed file-by-file breakdown
- ✅ Core Data schema with 9 entities
- ✅ ML/AI pipeline (embeddings, sentiment, safety, ranking, scoring)
- ✅ Agent system architecture (manager pattern with 5 specialized agents)
- ✅ UI architecture (SwiftUI + @Observable view models + Liquid Glass design)
- ✅ Data flow (HealthKit → DataAgent → StateEstimator → UI)
- ✅ Privacy & security (file protection, PII redaction, consent gates, keychain)
- ✅ Complete API reference for all public interfaces
- ✅ Implementation details (HealthKit processing, vector index format, Foundation Models integration)

**Ready for copy-paste to ChatGPT or other analysis tools.**

---

**Generated:** October 1, 2025
**Version:** Milestone 4 Complete
**Lines of Code:** ~15,000+ across 78 Swift files
**Status:** Production-ready architecture with Swift 6 compliance
