Repo Root: `/Users/martin.demel/Desktop/PULSUM/Pulsum`  
Commit: `4e32e275fb3ade8751eba1f1c56939a8b25c6ff2`  
Analysis Timestamp: `2025-10-08T00:00:00Z`

## 1. Repo Inventory (by package/target)

```text
PulsumApp (target) → PulsumUI → PulsumAgents → PulsumServices → PulsumData → PulsumML
```

- **PulsumApp target** (`Pulsum/PulsumApp.swift:11`) instantiates `PulsumRootView` as the only scene.
- **PulsumUI** (`Packages/PulsumUI/Package.swift:5`)
  - `AppViewModel` orchestrates startup, consent, and sheet routing (`Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:11`).
  - `CoachViewModel`, `PulseViewModel`, `SettingsViewModel` are all `@MainActor @Observable` front ends to `AgentOrchestrator` (`Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift:9`, `.../PulseViewModel.swift:5`, `.../SettingsViewModel.swift:7`).
  - `PulsumRootView` embeds Spline background, overlays navigation, and drives sheet presentation (`Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift:8`).
  - Liquid Glass utilities live in `GlassEffect.swift` and `LiquidGlassComponents.swift` (`Packages/PulsumUI/Sources/PulsumUI/GlassEffect.swift:1`, `.../LiquidGlassComponents.swift:1`).
  - Score analysis UI is centralized in `ScoreBreakdownViewModel.swift` / `ScoreBreakdownView.swift` (`Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownViewModel.swift:5`, `.../ScoreBreakdownView.swift:1`).
- **PulsumAgents** (`Packages/PulsumAgents/Package.swift:5`)
  - `AgentOrchestrator` is the single UI-facing gateway coordinating five agents and guardrails (`Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:64`).
  - `DataAgent` actor ingests HealthKit data and maintains baselines (`Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:46`).
  - `SentimentAgent`, `CoachAgent`, `SafetyAgent`, `CheerAgent` implement journaling, recommendations, safety, and celebration flows respectively (`Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift:10`, `.../CoachAgent.swift:12`, `.../SafetyAgent.swift:8`, `.../CheerAgent.swift:5`).
  - Coverage logic is isolated in `CoachAgent+Coverage.swift` (`Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent+Coverage.swift:1`).
- **PulsumServices** (`Packages/PulsumServices/Package.swift:5`)
  - `HealthKitService` encapsulates anchored queries and background delivery (`Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift:1`).
  - `SpeechService` abstracts SpeechAnalyzer/SFSpeechRecognizer backends (`Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:18`).
  - `LLMGateway` handles consent-aware routing, GPT-5 calls, schema validation, and sanitization (`Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:133`).
  - `KeychainService` provides secure API key storage (`Packages/PulsumServices/Sources/PulsumServices/KeychainService.swift:18`).
  - `FoundationModelsCoachGenerator` is the on-device fallback for phrasing (`Packages/PulsumServices/Sources/PulsumServices/FoundationModelsCoachGenerator.swift:7`).
- **PulsumData** (`Packages/PulsumData/Package.swift:5`)
  - `DataStack` provisions protected storage directories and Core Data container (`Packages/PulsumData/Sources/PulsumData/DataStack.swift:49`).
  - `PulsumData` facade exposes container paths (PHI directories) to other layers (`Packages/PulsumData/Sources/PulsumData/PulsumData.swift:4`).
  - `VectorIndex` and `VectorIndexManager` implement 16-shard binary vector storage/search (`Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:276`, `.../VectorIndexManager.swift:11`).
  - `LibraryImporter` and `EvidenceScorer` manage recommendation ingestion (`Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift:1`, `.../EvidenceScorer.swift:1`).
- **PulsumML** (`Packages/PulsumML/Package.swift:5`)
  - `BaselineMath`, `StateEstimator`, `RecRanker` implement robust statistics and ML ranking (`Packages/PulsumML/Sources/PulsumML/BaselineMath.swift:3`, `.../StateEstimator.swift:24`, `.../RecRanker.swift:3`).
  - `EmbeddingService` coordinates AFM/CoreML embedding providers (`Packages/PulsumML/Sources/PulsumML/Embedding/EmbeddingService.swift:4`).
  - `SentimentService` cascades Foundation Models, AFM, CoreML sentiment engines (`Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentService.swift:3`).
  - `SafetyLocal` provides keyword + embedding crisis detection (`Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift:31`).
  - Topic gate providers live under `TopicGate/` (`Packages/PulsumML/Sources/PulsumML/TopicGate/TopicGateProviding.swift:3`).

## 2. Doc → Code Cross-Check (Claim Ledger)

| Claim | Evidence in Code | Status | Notes |
| --- | --- | --- | --- |
| **Architecture:** “Agent-First Architecture: central AgentOrchestrator coordinates specialized agents (Data, Sentiment, Coach, Safety, Cheer)” (`architecture.md:39`) | `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:64-103`<br>```swift\n@MainActor\npublic final class AgentOrchestrator {\n    private let dataAgent: any DataAgentProviding\n    private let sentimentAgent: SentimentAgent\n    private let coachAgent: CoachAgent\n    private let safetyAgent: SafetyAgent\n    private let cheerAgent: CheerAgent\n    ...\n    self.dataAgent = DataAgent()\n    self.sentimentAgent = SentimentAgent()\n    self.coachAgent = try CoachAgent()\n    self.safetyAgent = SafetyAgent()\n    self.cheerAgent = CheerAgent()\n}\n``` | ✅ Verified | Constructor wires all five agents exactly as spec’d. |
| **Architecture:** “Chat Pipeline (Two-Wall Guardrails with deterministic intent routing)” (`architecture.md:456`) | `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:222-270`<br>```swift\n// WALL 1: Safety + On-Topic Guardrail\nlet safety = await safetyAgent.evaluate(text: userInput)\n...\nlet gateDecision = try await topicGate.classify(sanitizedInput)\n...\nlet coverageResult = try await coachAgent.coverageDecision(...)\n...\nlet payload = await coachAgent.chatResponse(... groundingFloor: groundingFloor)\n``` | ✅ Verified | Wall-1 safety/topic gate/coverage and Wall-2 grounding floor implemented. |
| **Architecture:** “ML-driven recommendations via vector search and pairwise ranking” (`architecture.md:24`) | `Packages/PulsumML/Sources/PulsumML/RecRanker.swift:3-105`<br>```swift\npublic struct RecommendationFeatures {\n    public var vector: [String: Double] {\n        var base = [\n            \"bias\": 1,\n            \"wellbeing\": wellbeingScore,\n            \"evidence\": evidenceStrength,\n            \"novelty\": novelty,\n            \"cooldown\": cooldown,\n            \"acceptance\": acceptanceRate,\n            \"timeCostFit\": timeCostFit\n        ]\n        for (key, value) in zScores { base[key] = value }\n        return base\n    }\n}\npublic final class RecRanker {\n    public func rank(_ candidates: [RecommendationFeatures]) -> [RecommendationFeatures] {\n        candidates.sorted { score(features: $0) > score(features: $1) }\n    }\n}\n``` | ✅ Verified | CoachAgent builds features then uses `RecRanker.rank` for top cards. |
| **Instructions:** “Display Foundation Models availability status in SettingsView (orchestrator.foundationModelsStatus)” (`instructions.md:113`) | `Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift:57-65` & `.../SettingsView.swift:155-177`<br>```swift\nfunc bind(orchestrator: AgentOrchestrator) {\n    self.orchestrator = orchestrator\n    foundationModelsStatus = orchestrator.foundationModelsStatus\n}\n...\nText(viewModel.foundationModelsStatus)\n    .font(.pulsumCallout)\n``` | ✅ Verified | Status string surfaced in view model and rendered in AI Models card. |
| **Instructions:** “Create @MainActor view models binding to AgentOrchestrator with async/await patterns” (`instructions.md:285`) | `Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:86-115`<br>```swift\nfunc start() {\n    guard startupState == .idle else { return }\n    startupState = .loading\n    Task { [weak self] in\n        guard let self else { return }\n        let orchestrator = try PulsumAgents.makeOrchestrator()\n        self.orchestrator = orchestrator\n        self.coachViewModel.bind(orchestrator: orchestrator, consentProvider: { [weak self] in\n            self?.consentGranted ?? false\n        })\n        self.pulseViewModel.bind(orchestrator: orchestrator)\n        self.settingsViewModel.bind(orchestrator: orchestrator)\n        ... try await orchestrator.start()\n    }\n}\n``` | ✅ Verified | App-level view model launches orchestrator inside `Task`. |
| **Instructions:** “Implement loading states for async Foundation Models operations” (`instructions.md:320`) | `Packages/PulsumUI/Sources/PulsumUI/CoachView.swift:105-170`<br>```swift\nHStack {\n    Text(\"Today's picks\")\n    if viewModel.isLoadingCards {\n        ProgressView()\n            .tint(Color.pulsumGreenSoft)\n    }\n}\n...\nif !consentGranted { ConsentPrompt(...) }\nif foundationStatus != \"Apple Intelligence is ready.\" {\n    MessageBubble(...)\n}\nif viewModel.recommendations.isEmpty && !viewModel.isLoadingCards {\n    MessageBubble(icon: \"clock.arrow.circlepath\", text: \"We're gathering more context...\", ...)\n}\nif viewModel.isSendingChat {\n    ProgressView()\n    Text(\"Analyzing...\")\n}\n``` | ✅ Verified | UI shows spinners and fallback messaging during async work. |
| **todolist:** “Milestone 3 – Rebuild DataAgent with async Core Data + health processing” (`todolist.md:36`) | `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:369-414`<br>```swift\nlet computation = try await context.perform { () throws -> FeatureComputation in\n    let metrics = try DataAgent.fetchDailyMetrics(...)\n    let summary = try DataAgent.computeSummary(...)\n    metrics.hrvMedian = summary.hrv.map(NSNumber.init(value:))\n    ...\n    let bundle = try DataAgent.buildFeatureBundle(...)\n    DataAgent.apply(features: bundle.values, to: featureVector)\n    return FeatureComputation(...)\n}\nlet snapshot = stateEstimator.update(features: computation.featureValues, target: target)\n``` | ✅ Verified | Actor reprocesses days asynchronously and updates estimator snapshot. |
| **todolist:** “Milestone 4 – Consent banner exact copy” (`todolist.md:59`) | `Packages/PulsumUI/Sources/PulsumUI/ConsentBannerView.swift:7-42`<br>```swift\nprivate let bannerCopy = \"Pulsum can optionally use GPT‑5 ...\"\n...\nText(\"Cloud processing is optional\")\nText(bannerCopy)\nButton(action: openSettings) { Text(\"Review Settings\") }\n``` | ✅ Verified | Copy matches instructions and renders in UI. |
| **todolist:** “Milestone 4 – SpeechAnalyzer/SpeechTranscriber migration (iOS 26)” (`todolist.md:70`) | `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:204-216`<br>```swift\nfunc startRecording(maxDuration: TimeInterval) async throws -> SpeechService.Session {\n    // Placeholder: integrate SpeechAnalyzer/SpeechTranscriber APIs when publicly available.\n    // For now we reuse the legacy backend\n    return try await fallback.startRecording(maxDuration: maxDuration)\n}\n``` | ⚠️ Partially Verified | Interface prepared but still delegates to legacy backend until APIs ship. |

## 3. Chat Guardrails (“Two-Wall”) — Implementation Map

**Wall 1 – On-device safety/topic enforcement**

| Layer | Implementation & Thresholds | Evidence |
| --- | --- | --- |
| Safety veto | `SafetyAgent` calls Foundation Models then `SafetyLocal` keywords before permitting cloud (`Packages/PulsumAgents/Sources/PulsumAgents/SafetyAgent.swift:27-76`). `SafetyLocalConfig` uses crisis ≥0.65, caution ≥0.35, margin ≥0.10 (`Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift:19-35`). | `SafetyLocal` thresholds enforce cautious bench-testing values and adjust keywords before allowing cloud. |
| Topic Gate | AFM topic classifier first (`Packages/PulsumML/Sources/PulsumML/TopicGate/FoundationModelsTopicGateProvider.swift:21-54`), fallback embedding gate with OOD margin 0.12, topic threshold 0.59 (`Packages/PulsumML/Sources/PulsumML/TopicGate/EmbeddingTopicGateProvider.swift:3-149`). | Classifiers return `GateDecision` (isOnTopic, reason, confidence/topic) used in orchestrator. |
| Coverage | `decideCoverage` evaluates vector matches with strong ≥0.42 median & ≥0.58 top; soft passes for on-topic ≥0.35 median or sparse data (`Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent+Coverage.swift:49-107`). Diagnostics logged via `emitRouteDiagnostics` (`Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:286-315`). | Ensures retrieval floor before any LLM call. |

**Deterministic Intent Routing**
- `AgentOrchestrator.performChat` ties Wall 1 results to deterministic signal mapping and data-dominant fallback (`Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:251-344`).
- `CoachAgent.mapTopicToSignal` maps canonical topics to feature keys (`Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift:113-129`).
- `CoachAgent.candidateMoments` returns privacy-safe snippets and `CoachAgent.chatResponse` packages redacted context with z-score rationale (`Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift:78-176`).

**Wall 2 – Cloud schema & grounding**

- Strict schema enforced through `CoachPhrasingSchema.responsesFormat()` (`Packages/PulsumServices/Sources/PulsumServices/CoachPhrasingSchema.swift:6-65`).
- `LLMGateway.GPT5Client` submits JSON-schema formatted requests (`Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:447-500`) and retries with adjusted token budgets (512 → 1024 or 128).
- Responses pass `parseAndValidateStructuredResponse` ensuring `isOnTopic`, `groundingScore`, schema fields, and rejecting incomplete/off-topic payloads (`Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:511-579`).
- Fail-closed fallback to on-device generator when schema/grounding fails (`Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:248-279`).

**Divergences from docs:** None functionally—the guardrail pipeline matches architecture.md; only SpeechAnalyzer backend remains placeholder (see §8).

## 4. LLM Gateway Facts

- **Endpoint & model:** Requests hit OpenAI Responses API `https://api.openai.com/v1/responses` with `"model": "gpt-5"` (`Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:192`, `.../GPT5Client.swift:442-447`).
- **Token budgets:** Default 512, clamps to 128–1024 via `clampTokens`, retries at 1024 or 128 on failure (`Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:447-503`, `660-674`).
- **Grounding rules:** Cloud result must set `isOnTopic == true` and `groundingScore ≥ groundingFloor` (0.50 for strong, 0.40 soft; see `AgentOrchestrator` routing at `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:320-344`).
- **Structured response:** `CoachPhrasing` requires fields (`coachReply`, `isOnTopic`, `groundingScore`, `intentTopic`, `refusalReason`, `nextAction`) with explicit min/max lengths (`Packages/PulsumServices/Sources/PulsumServices/CoachPhrasingSchema.swift:6-45`).
- **Sanitization:** All replies trimmed to ≤2 sentences and ≤280 chars (`Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:310-317`).
- **Consent & key management:** Cloud calls only when `SafetyDecision.allowCloud` and user consent are true (`Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:235-246`); secrets stored via `KeychainService` (`Packages/PulsumServices/Sources/PulsumServices/KeychainService.swift:29-65`).
- **Logging & retries:** Cloud diagnostics surfaced through `NotificationCenter` for QA (`Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:283-288`) and topic diagnostics notifications (`Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:286-315`).

## 5. Pipelines (facts only)

**HealthKit → DailyMetrics → StateEstimator**
1. `HealthKitService` requests read permissions and registers observer + anchored queries for HRV, HR, respiratory, steps, sleep (`Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift:47-198`).
2. `DataAgent.reprocessDay` computes summaries (HRV medians, sleep debt, steps) and updates Core Data entities with z-scores/imputation flags (`Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:369-514`).
3. `StateEstimator.update` ingests feature map, performs regularized gradient descent, and emits wellbeing score plus contribution vector (`Packages/PulsumML/Sources/PulsumML/StateEstimator.swift:24-65`).
4. Contributions persisted back into `FeatureVector` for transparency (`Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:412-423`).

**Recommendations & Chat**
1. `CoachAgent.recommendationCards` transforms snapshot contributions into a vector search query and fetches top 20 matches from `VectorIndex` (`Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift:47-76`).
2. Each candidate merges vector distance, evidence badge, novelty, cooldown, acceptance rate, and z-score map into `RecommendationFeatures` before `RecRanker.rank` produces top three cards (`Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift:123-205`, `Packages/PulsumML/Sources/PulsumML/RecRanker.swift:3-140`).
3. Chat requests go through Wall 1 & Wall 2, then `CoachAgent.chatResponse` constructs `CoachLLMContext` with redacted user tone, z-score summary, and top signal for `LLMGateway` (`Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift:78-110`).

**Voice Journaling & Sentiment**
1. `SpeechService` requests on-device recognition (legacy fallback while SpeechAnalyzer APIs ship) (`Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:33-212`).
2. `SentimentAgent.recordVoiceJournal` streams transcripts, redacts PII, computes sentiment via `SentimentService` cascade, and writes sanitized transcript/sentiment to Core Data (`Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift:33-93`).
3. Embeddings generated through `EmbeddingService` and persisted as `.vec` files under file protection complete (`Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift:96-111`).
4. Feature vectors update with sentiment for downstream analytics (`Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift:79-86`).

## 6. Privacy/Security Implementation

- **Protected storage:** `DataStack` creates Application Support subdirectories, sets `NSFileProtectionComplete`, and excludes PHI from backups (`Packages/PulsumData/Sources/PulsumData/DataStack.swift:71-136`).
- **PHI directories exposed for audits:** `PulsumData` facade provides `applicationSupportDirectory`, `vectorIndexDirectory`, and `healthAnchorsDirectory` paths (`Packages/PulsumData/Sources/PulsumData/PulsumData.swift:26-36`).
- **Vector files hardened:** Journaling vectors stored with file protection attributes at creation (`Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift:96-111`).
- **Secrets & consent:** API keys managed via `KeychainService` (`Packages/PulsumServices/Sources/PulsumServices/KeychainService.swift:29-65`); cloud requests happen only if user toggled consent and SafetyAgent permits (`Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:235-246`, `Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift:35-55`).
- **PII redaction:** `PIIRedactor` removes emails, phone numbers, and personal names before storage or cloud transmission (`Packages/PulsumML/Sources/PulsumML/Sentiment/PIIRedactor.swift:4-35`).
- **Vector index isolation:** `VectorIndexManager` writes embeddings through PulsumML, never exposing raw journal text (`Packages/PulsumData/Sources/PulsumData/VectorIndexManager.swift:21-36`).

## 7. UI Integration Points

- `PulsumRootView` launches `AppViewModel.start()` and controls sheet presentation for Pulse/Settings (`Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift:13-116`).
- `AppViewModel` binds orchestrator to `CoachViewModel`, `PulseViewModel`, and `SettingsViewModel`, surfaces consent banner and safety card state (`Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:52-170`).
- `CoachViewModel` manages async recommendation loading, chat sending, and cheer events with explicit loading/error flags (`Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift:28-147`).
- `CoachScreen` renders consent banner, Foundation Models fallback messaging, recommendation cards, and chat loader states (`Packages/PulsumUI/Sources/PulsumUI/CoachView.swift:105-176`).
- `PulseViewModel` drives voice recording countdowns, safety handling, and slider persistence via orchestrator (`Packages/PulsumUI/Sources/PulsumUI/PulseViewModel.swift:36-118`).
- `SettingsScreen` hosts wellbeing score drill-down, consent toggles, HealthKit authorization flow, and Foundation Models status copy (`Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift:13-200`).
- Crisis flows surface with `SafetyCardView` overlay triggered by `AppViewModel` safety callback (`Packages/PulsumUI/Sources/PulsumUI/SafetyCardView.swift:1-49`).

## 8. Doc/Code Deltas & Open Questions

- **SpeechAnalyzer migration incomplete:** `instructions.md` expects SpeechAnalyzer/SpeechTranscriber usage for iOS 26 (`instructions.md:180-182`), but `ModernSpeechBackend` still delegates to the legacy engine (commented placeholder) (`Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:208-212`). Clarify timeline for adopting new APIs.
- **SplineRuntime availability:** Architecture documents assume Liquid Glass Spline scene; code falls back to gradient when runtime missing. Confirm whether shipping build should bundle framework or keep gradient fallback (`Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift:120-131`).
- **Bench-test thresholds:** `SafetyLocal` uses elevated thresholds for simulator testing (`Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift:19-25`). Determine production values once HealthKit data is available; docs should capture environment-specific tuning.
