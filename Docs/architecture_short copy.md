# Pulsum - Architecture Documentation (Condensed)

**Generated:** October 1, 2025
**iOS Target:** iOS 26+
**Swift Version:** 6.2
**Status:** Milestone 4 Complete

---

## 1. Project Overview

Pulsum is a research-grade iOS health and wellness app combining:
- **HealthKit integration** for physiological metrics (HRV, heart rate, sleep, steps)
- **Voice journaling** with on-device speech recognition and sentiment analysis
- **AI-powered coaching** using Apple Foundation Models and GPT-5
- **ML-driven recommendations** via vector search and pairwise ranking
- **Privacy-first design** with on-device processing and explicit cloud consent

### Core Philosophy

- **Agent-First Architecture**: Central `AgentOrchestrator` coordinates specialized agents (Data, Sentiment, Coach, Safety, Cheer)
- **ML Over Rules**: All decisions use machine learning; no deterministic rule engines
- **Privacy by Design**: PHI stays on-device with `NSFileProtectionComplete`; cloud features require explicit consent
- **Foundation Models First**: iOS 26+ leverages Apple Intelligence with graceful fallbacks

### Technology Stack

| Layer | Technologies |
|-------|-------------|
| **UI** | SwiftUI, Observation, SplineRuntime |
| **Concurrency** | Swift 6 strict concurrency, Actors, @MainActor |
| **ML/AI** | Apple Foundation Models (iOS 26+), Core ML, NaturalLanguage |
| **Cloud AI** | OpenAI GPT-5 API (consent-gated) |
| **Data** | Core Data (SQLite), Binary vector index (16 shards) |
| **Health** | HealthKit (HKAnchoredObjectQuery, background delivery) |
| **Security** | Keychain Services, FileProtectionType.complete |

---

## 2. System Architecture

### High-Level Architecture

```
PulsumApp (iOS 26+ Target)
    ↓
PulsumUI Package
    ├─> Views: PulsumRootView, CoachView, PulseView, SettingsView
    └─> ViewModels: @MainActor @Observable (App, Coach, Pulse, Settings)
    ↓
PulsumAgents Package
    ├─> AgentOrchestrator (@MainActor - central coordinator)
    └─> 5 Agents: DataAgent (actor), SentimentAgent, CoachAgent, SafetyAgent, CheerAgent
    ↓
PulsumServices Package
    ├─> HealthKitService, SpeechService, LLMGateway
    └─> KeychainService, FoundationModelsCoachGenerator
    ↓
PulsumML Package
    ├─> BaselineMath, StateEstimator, RecRanker
    ├─> EmbeddingService, SentimentService, SafetyLocal
    └─> Foundation Models Integration
    ↓
PulsumData Package
    ├─> DataStack (Core Data), VectorIndex, VectorIndexManager
    └─> 9 Core Data entities + binary vector storage
```

### Package Dependencies

```
PulsumApp → PulsumUI → PulsumAgents → PulsumServices → PulsumData → PulsumML
```

---

## 3. Package Structure (Summary)

### PulsumData
- **DataStack**: NSPersistentContainer with FileProtectionType.complete
- **VectorIndex**: 16-shard binary storage for 384-dim vectors
- **9 Entities**: JournalEntry, DailyMetrics, Baseline, FeatureVector, MicroMoment, RecommendationEvent, LibraryIngest, UserPrefs, ConsentState

### PulsumML
- **BaselineMath**: Robust statistics (median/MAD z-scores, EWMA)
- **StateEstimator**: Online ridge regression for wellbeing score
- **RecRanker**: Pairwise logistic ranking
- **EmbeddingService**: AFM → CoreML fallback (384-dim)
- **SentimentService**: FoundationModels → AFM → CoreML → NaturalLanguage
- **SafetyLocal**: Keyword + prototype-based classifier

### PulsumServices
- **HealthKitService**: HKObserverQuery + HKAnchoredObjectQuery with background delivery
- **SpeechService**: On-device recognition (actor)
- **LLMGateway**: Consent-aware routing (cloud GPT-5 / on-device)
- **KeychainService**: Secure credential storage

### PulsumAgents
- **AgentOrchestrator** (@MainActor): Central coordinator exposing unified API to UI
- **DataAgent** (actor): HealthKit ingestion, feature engineering, wellbeing scoring
- **SentimentAgent** (@MainActor): Voice journal recording, transcription, sentiment
- **CoachAgent** (@MainActor): Recommendations + chat with Two-Wall Guardrails
- **SafetyAgent** (@MainActor): Content safety classification
- **CheerAgent** (@MainActor): Positive reinforcement

### PulsumUI
- **PulsumRootView**: Root entry with tabs, gestures, sheets
- **ViewModels**: @MainActor @Observable (bind to AgentOrchestrator)
- **Design System**: Liquid glass effect, colors, typography, animations

---

## 4. Core Data Schema

| Entity | Key Attributes | Purpose |
|--------|----------------|---------|
| **JournalEntry** | id, date, transcript, sentiment, embeddedVectorURL | Voice journals with external vectors |
| **DailyMetrics** | date, hrvMedian, nocturnalHR, restingHR, sleepDebt, steps, flags (JSON) | HealthKit summary + raw samples |
| **Baseline** | metric, windowDays, median, mad, ewma | 30-day rolling baseline statistics |
| **FeatureVector** | date, z-scores (6 metrics), subjective inputs (3), sentiment, imputedFlags | Daily features for wellbeing scoring |
| **MicroMoment** | id, title, shortDescription, tags, estimatedTimeSec, difficulty, sourceURL | Recommendation library items |
| **RecommendationEvent** | momentId, date, accepted, completedAt | User interaction tracking |
| **UserPrefs** | id="default", consentCloud | Cloud consent gate |

**Store Configuration:**
- Location: `Application Support/Pulsum/Pulsum.sqlite`
- Protection: `FileProtectionType.complete`
- Backup: Excluded from iCloud
- Migration: Automatic inference

**Vector Storage:**
- Directory: `Application Support/Pulsum/VectorIndex/`
- Format: Binary float32 arrays (384 dimensions)
- Sharding: 16 shards for micro_moments, individual files for journal entries
- Protection: `FileProtectionType.complete`

---

## 5. ML/AI Pipeline

### Embedding Pipeline

```
Text Input → EmbeddingService
  ├─> AFMTextEmbeddingProvider (iOS 17+)
  │   └─> NLEmbedding.wordEmbedding → average pooling → 384-dim
  ├─> CoreMLEmbeddingFallbackProvider (bundled model)
  └─> Zero vector fallback
```

### Sentiment Pipeline

```
Transcript (PII-redacted) → SentimentService
  ├─> FoundationModelsSentimentProvider (iOS 26+)
  │   └─> @Generable SentimentAnalysis {label, score}, temp=0.1
  ├─> AFMSentimentProvider (anchor-based cosine similarity)
  ├─> CoreMLSentimentProvider (bundled model)
  ├─> NaturalLanguageSentimentProvider (NLTagger)
  └─> 0.0 neutral fallback
```

### Safety Pipeline

```
Text Input → SafetyAgent.evaluate()
  ├─> FoundationModelsSafetyProvider (iOS 26+)
  │   └─> @Generable SafetyAssessment {rating, reason}, temp=0.0
  └─> SafetyLocal.classify()
      ├─> Crisis keywords (5): "suicide", "kill myself", etc.
      ├─> Caution keywords (5): "depressed", "anxious", etc.
      ├─> Prototype embeddings (12): 4 crisis, 4 caution, 4 safe
      └─> Thresholds: crisis=0.65, caution=0.35, margin=0.10
```

**Safety Routing:**
- `.crisis` → blocks all cloud, shows US 911 overlay
- `.caution` → on-device only
- `.safe` → allows cloud if consent granted

### Wellbeing Score Pipeline

```
Daily HealthKit + Subjective Inputs + Journal Sentiment
  ↓
1. Compute Summary Metrics (HRV median, nocturnal HR p10, resting HR, sleep debt, RR, steps)
2. Update Baselines (30-day median, MAD, EWMA)
3. Build Feature Bundle (z-scores + subjective inputs)
4. Compute Target:
   target = -0.35*z_hrv + -0.25*z_steps + -0.4*z_sleepDebt
            + 0.45*subj_stress + -0.4*subj_energy + 0.3*subj_sleepQuality
5. StateEstimator.update() (gradient descent with L2 regularization)
   score = Σ(weight_i * feature_i) + bias
6. Persist FeatureVector with contributions and imputed flags
```

**StateEstimator Config:**
- Learning rate: 0.05
- Regularization λ: 0.001
- Weight cap: ±2.0

### Recommendation Ranking Pipeline

```
User Context (FeatureVectorSnapshot)
  ↓
1. Vector Search: Embed state → query top 20 MicroMoments
2. Feature Extraction:
   - wellbeingScore, evidenceStrength, novelty, cooldown
   - acceptanceRate, timeCostFit, z-scores
3. RecRanker.rank(): score = sigmoid(Σ(weight_i * feature_i))
4. Select top 3 cards: 1 "Top Pick" + 2 alternates
5. Generate caution (FoundationModels or heuristic)
```

**RecRanker Initial Weights:**
```swift
{
    "wellbeingScore": -0.2,      // Lower score → prefer safer
    "evidenceStrength": 0.6,     // Prefer strong evidence
    "novelty": 0.4,              // Prefer unseen
    "cooldown": -0.5,            // Penalize recently seen
    "acceptanceRate": 0.3,       // Prefer historically accepted
    "timeCostFit": 0.2           // Prefer time-appropriate
}
```

### Chat Response Pipeline - Two-Wall Guardrails with Deterministic Intent Routing

**COMPLETE TWO-WALL GUARDRAILS SYSTEM:**

This is the most critical component for ensuring safe, grounded, and contextually appropriate coaching responses. The system implements a fail-closed architecture with deterministic intent resolution to eliminate "wobble" (unstable topic detection).

#### Wall-1: On-Device Guardrails (4-Gate Pipeline)

**Gate 1: Safety Gate**
```
Text Input → SafetyAgent.evaluate()
  ├─> Crisis → BLOCK all processing, show US 911 message
  ├─> Caution → BLOCK cloud, allow on-device only
  └─> Safe → Proceed to Gate 2
```

**Gate 2: Topic Gate (ML Classification)**
```
ML Topic Classifier (AFM embedding → cosine similarity)
  ├─> Threshold: 0.59 for on-topic
  ├─> Canonical Topics: sleep, stress, energy, hrv, mood, movement, mindfulness, goals
  ├─> Special Vocabulary: HRV includes "rmssd", "vagal tone", "parasympathetic", "recovery"
  └─> Returns: topic or nil (for greetings like "hello")
```

**Gate 3: Deterministic Intent Routing (4-Step Pipeline - Eliminates Wobble)**

This is the critical innovation that eliminates unstable topic detection by establishing a deterministic intent hierarchy:

```
Step A: Start with Wall-1 Topic
  └─> Initial topic from Gate 2 ML classification

Step B: Phrase Override (Substring Matching)
  ├─> "insomnia" → sleep
  ├─> "rmssd" → hrv
  ├─> "micro" → goals
  ├─> "box breathing" → mindfulness
  └─> Overrides ML topic if matched

Step C: Candidate Moments Override (Retrieval-Based)
  ├─> Retrieve top-2 moments for current topic
  ├─> Keyword scoring: Count occurrences in {title, detail, tags}
  └─> Infer dominant topic from highest-scoring moment

Step D: Data-Dominant Fallback
  └─> Choose signal with highest |z-score| from:
      - subj_sleepQuality → sleep
      - subj_stress → stress
      - subj_energy → energy
      - hrv_rmssd_rolling_30d → hrv
      - sentiment_rolling_7d → mood
      - steps_rolling_7d → movement
```

**Why This Eliminates Wobble:**
- ML classification provides semantic understanding (Step A)
- Phrase overrides catch specific terminology (Step B)
- Moment retrieval grounds intent in actual content (Step C)
- Data fallback ensures deterministic resolution (Step D)
- Result: Same input → same topic every time

**Gate 4: Coverage Gate (Retrieval Similarity Check)**
```
Robustness Requirements:
  ├─> Retrieve top candidates from vector index
  ├─> Require ≥3 matches
  ├─> Compute median similarity using 1/(1+d) transformation
  ├─> Threshold: median ≥0.25 AND top match ≥0.68
  └─> Blocks off-topic fluff: "tell me a joke", "write me a poem"
```

**Coverage Gate Purpose:**
- Ensures library has relevant content for user query
- Prevents GPT-5 from generating generic/irrelevant responses
- Fail-closed: Low coverage → fallback to Foundation Models on-device

#### Wall-2: Cloud Schema Validation

**After Wall-1 passes, build structured context for GPT-5:**

```
CoachLLMContext {
    userToneHints: "supportive, concise"
    topSignal: "HRV low, stress elevated"           // From DataAgent
    intentTopic: "sleep"                            // From deterministic routing
    candidateMoments: [moment1, moment2]            // From retrieval
    rationale: "User asked about sleep quality"
    zScoreSummary: "HRV=-1.2, sleepDebt=+0.8, stress=6/7"
}
```

**GPT-5 Structured Output Schema:**

```swift
@Generable
public struct CoachReplyPayload {
    @Guide("Is the user input related to health/wellness?")
    public let isOnTopic: Bool

    @Guide("How well is the reply grounded in provided user data? 0.0-1.0, must be ≥0.5")
    public let groundingScore: Double

    @Guide("Brief coaching reply, max 280 chars, max 2 sentences")
    public let coachReply: String

    @Guide("Optional: Suggested micro-moment action, max 120 chars")
    public let nextAction: String?

    @Guide("Echo the intentTopic from context for validation")
    public let intentTopic: String?
}
```

**Schema Enforcement:**
- `isOnTopic` must be true
- `groundingScore` must be ≥0.5 (validates GPT-5 used user data)
- `coachReply` max 280 chars, max 2 sentences (enforced by character limit)
- `nextAction` optional but max 120 chars
- `intentTopic` echo validates GPT-5 understood context

**Fail-Closed Behavior:**
- Schema validation failures → fallback to Foundation Models on-device
- Grounding score <0.5 → fallback to Foundation Models on-device
- GPT-5 errors/refusals → fallback to Foundation Models on-device
- Result: User always gets a response, never a blank/error

#### Complete Two-Wall Flow

```
User Input: "I can't sleep"
  ↓
PII Redaction: "I can't sleep" (no PII)
  ↓
WALL-1 GATE 1 - Safety: .safe ✓
  ↓
WALL-1 GATE 2 - Topic: ML classifies as "sleep" (0.85 confidence) ✓
  ↓
WALL-1 GATE 3 - Deterministic Intent:
  Step A: Start with "sleep" from ML
  Step B: Check phrases → "insomnia" not found, keep "sleep"
  Step C: Retrieve top-2 moments → {sleep hygiene, meditation for sleep}
            Keyword score: "sleep"=8, "stress"=2 → dominant="sleep"
  Step D: Not needed, already resolved
  Final Intent: "sleep" ✓
  ↓
WALL-1 GATE 4 - Coverage:
  Retrieved 5 moments, median similarity=0.72, top=0.89
  ≥3 matches ✓, median ≥0.25 ✓, top ≥0.68 ✓
  Coverage sufficient ✓
  ↓
Build CoachLLMContext:
  topSignal: "Sleep debt +1.2h"
  intentTopic: "sleep"
  candidateMoments: ["sleep-hygiene-tips", "meditation-sleep"]
  zScoreSummary: "sleepDebt=+1.2, stress=5/7"
  ↓
WALL-2 - GPT-5 Structured Output:
  POST https://api.openai.com/v1/responses
  Payload: {model: "gpt-5", input: [...], schema: CoachReplyPayload}
  Response:
    {
      isOnTopic: true,
      groundingScore: 0.83,
      coachReply: "Your sleep debt is elevated. Try winding down 30 min earlier tonight.",
      nextAction: "Practice 4-7-8 breathing before bed",
      intentTopic: "sleep"
    }
  ↓
Schema Validation:
  isOnTopic=true ✓
  groundingScore=0.83 ≥0.5 ✓
  coachReply length=79 chars, 2 sentences ✓
  intentTopic="sleep" matches context ✓
  ↓
Return to UI: "Your sleep debt is elevated. Try winding down 30 min earlier tonight."
```

**Failure Scenarios and Fallbacks:**

| Failure Point | Fallback Action |
|--------------|-----------------|
| Safety = .crisis | Block all, show 911 card |
| Safety = .caution | Force on-device (Foundation Models) |
| Topic ML fails | Use data-dominant fallback (Step D) |
| Coverage insufficient | Foundation Models on-device |
| GPT-5 schema invalid | Foundation Models on-device |
| GPT-5 grounding <0.5 | Foundation Models on-device |
| GPT-5 timeout/error | Foundation Models on-device |
| Consent OFF | Foundation Models on-device |

**Foundation Models On-Device Fallback:**
```swift
SystemLanguageModel.default with Instructions:
  "You are a supportive wellness coach. Keep responses under 80 words, max 2 sentences.
   Ground advice in user's health signals (HRV, sleep, stress). Never diagnose."
Temperature: 0.6
Sanitize: max 2 sentences
```

**Key Innovations in Two-Wall Design:**

1. **Deterministic Intent (Eliminates Wobble)**
   - 4-step hierarchy ensures same input → same topic
   - Phrase overrides catch domain-specific terminology
   - Moment retrieval grounds in actual content
   - Data fallback provides deterministic resolution

2. **Fail-Closed Architecture**
   - Every gate has a fallback path
   - No user input results in blank/error state
   - Always returns a grounded, helpful response

3. **Structured Schema Validation**
   - Forces GPT-5 to ground responses in user data
   - Validates topic coherence via intentTopic echo
   - Enforces brevity via character limits
   - Blocks generic/off-topic fluff

4. **Coverage Robustness**
   - Requires ≥3 matches for reliability
   - Median similarity prevents outlier bias
   - Transformation 1/(1+d) normalizes distances
   - Blocks queries outside app domain

**Result:** The Two-Wall Guardrails system ensures every chat response is safe, on-topic, grounded in user data, and appropriate to the app's wellness domain. The deterministic intent routing eliminates topic "wobble" that plagued earlier ML-only approaches.

---

## 6. Agent System

### Manager Pattern

- **AgentOrchestrator** is the only agent exposed to UI layer
- 5 specialized agents are **tools** invoked by orchestrator
- UI layer **never** directly accesses individual agents

### Agent Descriptions

**1. AgentOrchestrator** (@MainActor)
- Central coordinator exposing unified API
- Key functions: `start()`, `recordVoiceJournal()`, `recommendations()`, `chat()`, `logCompletion()`, `scoreBreakdown()`
- Tracks Foundation Models availability status

**2. DataAgent** (actor)
- HealthKit ingestion via HKObserverQuery + HKAnchoredObjectQuery
- Daily reprocessing: summary metrics → baselines → features → wellbeing score
- Imputation rules for missing data (HRV, sleep, steps)

**3. SentimentAgent** (@MainActor)
- Voice recording via SpeechService (on-device)
- PII redaction → sentiment analysis → embedding → Core Data + vector storage

**4. CoachAgent** (@MainActor)
- **Recommendations**: Vector search → RecRanker → top 3 cards
- **Chat**: Two-Wall Guardrails (see section 5) with deterministic intent routing
- **Caution Generation**: Foundation Models (iOS 26+) or heuristic fallback

**5. SafetyAgent** (@MainActor)
- FoundationModels (iOS 26+) → SafetyLocal fallback
- Classifications: .safe, .caution(reason), .crisis(reason)

**6. CheerAgent** (@MainActor)
- Positive reinforcement on recommendation completion
- Time-based qualifiers (morning/midday/evening/late)

---

## 7. UI Architecture

### View Hierarchy

```
PulsumRootView
├─> Background: Spline 3D scene
├─> ConsentBannerView
├─> Content:
│   ├─> MainContainerView (Tab: Main)
│   └─> CoachScreen (Tab: Coach)
│       ├─> Recommendations (cards)
│       ├─> Chat messages
│       └─> ChatInputView
├─> Sheets: PulseView (journal), SettingsScreen
└─> Overlay: SafetyCardView (crisis)
```

### View Models

All @MainActor @Observable, bind to AgentOrchestrator:

- **AppViewModel**: Root coordinator, manages tabs/sheets/safety overlay
- **CoachViewModel**: Recommendations, chat, cheer messages
- **PulseViewModel**: Voice recording, subjective input sliders
- **SettingsViewModel**: Foundation Models status, consent, HealthKit auth
- **ScoreBreakdownViewModel**: Detailed metric breakdown

### Design System

**Colors:** pulsumBackgroundBeige, pulsumMintGreen, pulsumTextPrimary, etc.
**Spacing:** xxs=4 to xxxl=64
**Typography:** pulsumLargeTitle, pulsumBody, pulsumDataXLarge
**Animations:** pulsumQuick (0.2s), pulsumStandard (0.35s), pulsumSmooth (0.5s)
**Liquid Glass:** Material.ultraThin + white border + shadow + scale interaction

---

## 8. Data Flow (Key Scenarios)

### Journal Recording

```
User taps mic → PulseViewModel.startRecording()
  → AgentOrchestrator.recordVoiceJournal()
    → SentimentAgent: SpeechService → PII redaction → sentiment → embedding → Core Data + vector file
    → SafetyAgent: Evaluate transcript → SafetyDecision
  → Return JournalCaptureResponse
  → PulseViewModel: Display transcript/sentiment OR show crisis overlay
```

### HealthKit → Wellbeing Score

```
HKObserverQuery fires → HealthKitService → DataAgent
  → Append samples to DailyMetrics.flags (JSON)
  → reprocessDay(): Compute summaries → Update baselines → Build features → StateEstimator.update()
  → Persist FeatureVector with z-scores, wellbeing score, contributions
  → UI calls orchestrator.scoreBreakdown() → Display in ScoreBreakdownView
```

---

## 9. Privacy & Security

### File Protection

All data uses `FileProtectionType.complete` + backup exclusion:
- `Pulsum.sqlite` (Core Data)
- `VectorIndex/` directory
- `Anchors/` directory (HKQueryAnchors)
- Keychain: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`

### PII Redaction

**PIIRedactor** removes:
- Email addresses (regex)
- Phone numbers (US + international formats)
- Personal names (NLTagger with .nameType)

Applied before sentiment analysis and all cloud calls.

### Consent Gate

**UserPrefs.consentCloud** gates GPT-5 API usage:

| Consent | Safety | Cloud Allowed? | Route |
|---------|--------|----------------|-------|
| OFF | .safe | ❌ | On-device |
| OFF | .caution | ❌ | On-device |
| OFF | .crisis | ❌ | Blocked (911) |
| ON | .safe | ✅ | GPT-5 |
| ON | .caution | ❌ | On-device |
| ON | .crisis | ❌ | Blocked (911) |

### Minimized Context (Cloud Payloads)

**CoachLLMContext** sent to GPT-5:
- `topSignal`: e.g., "HRV low, stress elevated"
- `topMomentId`: e.g., "breathwork-box-breathing"
- `rationale`: e.g., "User asked about sleep"
- `zScoreSummary`: e.g., "HRV=-1.2, sleepDebt=+0.8, stress=6/7"

**NEVER sent:**
- Journal transcripts
- Raw HealthKit samples
- Personal identifiers (UUIDs, emails, names)
- Vector embeddings

---

## 10. API Reference (Key Types)

### AgentOrchestrator

```swift
@MainActor
public final class AgentOrchestrator {
    public init() throws
    public func start() async throws
    public var foundationModelsStatus: String { get }

    public func recordVoiceJournal(maxDuration: TimeInterval = 30) async throws -> JournalCaptureResponse
    public func updateSubjectiveInputs(date: Date, stress: Double, energy: Double, sleepQuality: Double) async throws
    public func recommendations(consentGranted: Bool) async throws -> RecommendationResponse
    public func chat(userInput: String, consentGranted: Bool) async throws -> String
    public func logCompletion(momentId: String) async throws -> CheerEvent
    public func scoreBreakdown() async throws -> ScoreBreakdown?
}

public struct RecommendationResponse {
    public let cards: [RecommendationCard]
    public let wellbeingScore: Double
    public let contributions: [String: Double]
}

public struct JournalCaptureResponse {
    public let result: JournalResult
    public let safety: SafetyDecision
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
```

### PulsumML

```swift
public enum BaselineMath {
    public struct RobustStats { let median: Double; let mad: Double }
    public static func robustStats(for: [Double]) -> RobustStats?
    public static func zScore(value: Double, stats: RobustStats) -> Double
    public static func ewma(previous: Double?, newValue: Double, lambda: Double = 0.2) -> Double
}

public final class StateEstimator {
    public struct Config {
        public let learningRate: Double        // 0.05
        public let regularizationLambda: Double // 0.001
        public let weightCap: Double           // 2.0
    }
    public init(config: Config = Config())
    public func predict(features: [String: Double]) -> Double
    public func update(features: [String: Double], target: Double) -> Snapshot
}

public final class RecRanker {
    public struct RecommendationFeatures {
        public let id, wellbeingScore, evidenceStrength, novelty, cooldown, acceptanceRate, timeCostFit: ...
        public let zScores: [String: Double]
    }
    public func rank(_ candidates: [RecommendationFeatures]) -> [RecommendationFeatures]
}
```

---

## 11. Implementation Details (Key Algorithms)

### BaselineMath

- **Robust z-score**: `(value - median) / (MAD * 1.4826)`
- **EWMA**: `λ * newValue + (1 - λ) * previous` (λ = 0.2)

### StateEstimator

**Linear Model:**
```
score = Σ(weight_i * feature_i) + bias
```

**Loss Function:**
```
L = (predicted - target)² + λ * Σ(weight_i²)
```

**Gradient Descent:**
```
weight_i -= α * [2 * (predicted - target) * feature_i + 2 * λ * weight_i]
weight_i = clamp(weight_i, -2.0, 2.0)
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

### SafetyLocal

**Keywords:**
- Crisis (5): "suicide", "kill myself", "end my life", "not worth living", "better off dead"
- Caution (5): "depressed", "anxious", "worthless", "hopeless", "overwhelming"

**Prototype Embeddings:** 12 total (4 crisis, 4 caution, 4 safe)

**Classification:**
- Compute cosine similarity to all prototypes
- Thresholds: crisis=0.65, caution=0.35, margin=0.10
- Upgrade to crisis only if keyword match found

### Vector Index Format

**Shard Header (16 bytes):**
```
magic: 0x50535649 ('PSVI')
version: 1
dimension: 384
recordCount: UInt64
```

**Record Structure:**
```
idLength: UInt16
flags: UInt16 (0=active, 1=deleted)
id: UTF-8 string (idLength bytes)
vector: float32[384] (1536 bytes)
```

**L2 Distance Search:**
```swift
distance = sqrt(Σ((query[i] - stored[i])²))
```

**Sharding:** `shardIndex = abs(id.hashValue) % 16`

### Foundation Models Integration

**Availability Checking:**
```swift
SystemLanguageModel.default.availability:
  - .available → "Apple Intelligence is ready"
  - .unavailable(.needsAppleIntelligence) → "Enable Apple Intelligence in Settings"
  - .unavailable(.downloading) → "Preparing AI model..."
  - .unavailable → "This device doesn't support Apple Intelligence"
```

**Structured Generation Example (Sentiment):**
```swift
@Generable
public struct SentimentAnalysis {
    @Guide("Categorical sentiment classification")
    public let label: SentimentLabel  // positive/neutral/negative

    @Guide("Continuous score in [-1.0, 1.0]")
    public let score: Double
}

let session = try LanguageModelSession(model: SystemLanguageModel.default)
let result: SentimentAnalysis = try await session.generate(prompt, options: .init(temperature: 0.1))
```

---

## Conclusion

This condensed document provides a complete overview of Pulsum's architecture with **full preservation of the Two-Wall Guardrails system**, which is the most critical innovation for ensuring safe, grounded, and contextually appropriate coaching responses. The deterministic intent routing eliminates "wobble" in topic detection, and the fail-closed architecture ensures users always receive helpful responses.

**Key Components:**
- ✅ 5 Swift packages (PulsumData, PulsumML, PulsumServices, PulsumAgents, PulsumUI)
- ✅ 9 Core Data entities + binary vector index
- ✅ Complete Two-Wall Guardrails with deterministic intent routing (FULLY PRESERVED)
- ✅ ML pipeline (embeddings, sentiment, safety, ranking, scoring)
- ✅ Agent system (manager pattern with 5 specialized agents)
- ✅ Privacy & security (file protection, PII redaction, consent gates)
- ✅ Foundation Models integration (iOS 26+ with graceful fallbacks)

**Status:** Production-ready architecture with Swift 6 compliance
**Lines:** ~1000 lines (condensed from 2507 lines, ~40% of original)

---

**Generated:** October 1, 2025
**Version:** Milestone 4 Complete (Condensed)
