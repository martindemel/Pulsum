## 1. Title & Commit Info
- Repo: Pulsum — Revision: working tree (no VCS tag)
- Generated on: 2025-10-26T01:14:51Z UTC

## 2. Executive Summary
- Pulsum is an iOS 26+ wellbeing coach that boots an `AgentOrchestrator` to connect data ingestion, sentiment capture, safety vetting, and coaching agents behind the SwiftUI front end. (Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:45-175; Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:65-207)
- The orchestrator enforces a three-wall guardrail—safety classification, on-topic gating, and retrieval coverage—before escalating to the GPT-5 cloud pathway or falling back to on-device generation. (Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:221-399; Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:136-270)
- Health metrics and journals flow through a `DataAgent` actor that merges HealthKit streams, subjective sliders, and sentiment embeddings to drive a wellbeing score and metric breakdown surfaced in UI dashboards. (Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:46-216; Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownViewModel.swift:7-56)

## 3. Repository Map
- `Pulsum/` – App entry point, entitlements, and Core Data model bundle. (Pulsum/PulsumApp.swift:11-16; Pulsum/Pulsum.entitlements:5-8; Pulsum/Pulsum.xcdatamodeld/Pulsum.xcdatamodel/contents:3-80)
- `Packages/PulsumUI/` – SwiftUI presentation layer with tab shell, voice journal sheet, coach chat UI, settings, and design system. (Packages/PulsumUI/Package.swift:5-36; Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift:5-274)
- `Packages/PulsumAgents/` – Domain orchestrators, data ingestion, coaching logic, safety, and sentiment agents. (Packages/PulsumAgents/Package.swift:5-41; Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:65-404)
- `Packages/PulsumServices/` – Platform services: HealthKit wrapper, LLM gateway, speech capture, keychain, and diagnostics notifications. (Packages/PulsumServices/Package.swift:5-37; Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:136-304)
- `Packages/PulsumData/` – Core Data stack, vector index implementation, and library importer that seeds recommendation content. (Packages/PulsumData/Package.swift:5-36; Packages/PulsumData/Sources/PulsumData/DataStack.swift:18-137; Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift:41-168)
- `Packages/PulsumML/` – On-device ML utilities for embeddings, sentiment, topic gating, safety heuristics, and state estimation. (Packages/PulsumML/Package.swift:5-40; Packages/PulsumML/Sources/PulsumML/Embedding/EmbeddingService.swift:4-74; Packages/PulsumML/Sources/PulsumML/TopicGate/EmbeddingTopicGateProvider.swift:4-168)
- `PulsumTests/` & `PulsumUITests/` – Unit/UI scaffolding; agents and services also ship dedicated test targets under their packages. (PulsumTests/PulsumTests.swift:11-15; Packages/PulsumAgents/Tests/PulsumAgentsTests/ChatGuardrailAcceptanceTests.swift:12-183; Packages/PulsumServices/Tests/PulsumServicesTests/LLMGatewayTests.swift:64-215)
- `json database/` – Offline podcast recommendation corpus imported into Core Data and the vector index. (json database/podcastrecommendations.json:1-20; Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift:41-127)

```json
{
  "generated_at": "2025-10-26T01:02:02.195681Z",
  "total_files": 150,
  "read_counts": {"read": 112, "summarize_only": 38},
  "sample": [
    {"path": "Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift", "sha256": "145611068796e6bdcb5879c650a0a440817221ff485c18283e622bdbef2df387", "intent": "read"},
    {"path": "Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift", "sha256": "b9ea933fbb566b2e2868844047c47ec5808345b9366c9f7af25991bff9efe545", "intent": "read"},
    {"path": "json database/podcastrecommendations.json", "sha256": "50464a3a1673f4845622281d00ecf5099e62bd72d99099fe1ea7d218b0a1f35c", "intent": "read"}
  ]
}
```

## 4. Build Targets & Schemes
- Xcode project `Pulsum.xcodeproj` defines the app plus unit/UI test bundles; all targets share an iOS 26.0 deployment target and Swift concurrency options. (Pulsum.xcodeproj/project.pbxproj:398-406; Pulsum.xcodeproj/project.pbxproj:600-669)
- The main app target resolves local Swift package products `PulsumUI`, `PulsumAgents`, `PulsumData`, `PulsumServices`, and `PulsumML`, mirroring the modular folder layout. (Pulsum.xcodeproj/project.pbxproj:674-721)
- Swift packages declare iOS 26/macOS 14 support, ensuring APIs like Foundation Models are compiled conditionally. (Packages/PulsumUI/Package.swift:5-36; Packages/PulsumAgents/Package.swift:5-41; Packages/PulsumServices/Package.swift:5-37; Packages/PulsumData/Package.swift:5-36; Packages/PulsumML/Package.swift:5-40)

## 5. External Dependencies
- No remote SwiftPM packages are pinned; all products are first-party modules layered on Apple frameworks such as HealthKit, FoundationModels, Speech, and CoreData. (Packages/PulsumML/Package.swift:5-40; Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift:1-205)
- Cloud interaction is restricted to OpenAI’s Responses API via `LLMGateway`, which requires a GPT-5 API key supplied at runtime. (Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:136-270)

## 6. App Lifecycle & Entry Points
- `PulsumApp` is the @main entry that hosts `PulsumRootView`. (Pulsum/PulsumApp.swift:11-16)
- `AppViewModel` wires sub-view-models, persists consent, and asynchronously starts the orchestrator plus initial data sync. (Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:45-153)
- Startup handles HealthKit edge cases gracefully, marking the state failed only for unexpected errors while tolerating missing background delivery entitlements. (Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:111-133)

## 7. Modules & Layers
- **UI layer (PulsumUI)**: provides tab navigation, coach chat, pulse journal, settings, insights dashboards, and shared styling. View models encapsulate orchestrator calls and UI-specific state. (Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift:84-274; Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift:11-150; Packages/PulsumUI/Sources/PulsumUI/PulseViewModel.swift:8-189; Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift:9-205; Packages/PulsumUI/Sources/PulsumUI/PulsumDesignSystem.swift:6-172)
- **Agents layer (PulsumAgents)**: `AgentOrchestrator` composes agents for data, sentiment, coaching, safety, and celebrations, exposing async API to the UI. (Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:65-404)
  - `DataAgent` actor integrates HealthKit (observer + anchored queries), subjective inputs, Core Data persistence, state estimation, and score breakdown assembly. (Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:46-220; Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:117-216)
  - `CoachAgent` handles recommendation retrieval from the vector index, ranks with `RecRanker`, and gifts context to `LLMGateway` or on-device responders. (Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift:11-200; Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent+Coverage.swift:49-107)
  - `SentimentAgent` drives speech capture, real-time transcript streaming, PII redaction, sentiment scoring, and vector persistence. (Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift:24-178)
  - `SafetyAgent` cascades Foundation Models safety classification with a local embedding-based fallback. (Packages/PulsumAgents/Sources/PulsumAgents/SafetyAgent.swift:8-77; Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift:31-172)
  - `CheerAgent` creates completion badges with contextual messaging. (Packages/PulsumAgents/Sources/PulsumAgents/CheerAgent.swift:4-31)
- **Services layer (PulsumServices)**: includes reusable platform services for all modules.
  - `LLMGateway` validates JSON-schema payloads, manages API keys via Keychain or config, routes to GPT-5, and falls back to on-device generators. (Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:136-338; Packages/PulsumServices/Sources/PulsumServices/CoachPhrasingSchema.swift:6-65; Packages/PulsumServices/Sources/PulsumServices/KeychainService.swift:19-78)
  - `HealthKitService` encapsulates authorization, background delivery enablement, on-device anchoring, and anchored query wiring. (Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift:25-205)
  - `HealthKitAnchorStore` persists HKQueryAnchor instances with complete file protection. (Packages/PulsumServices/Sources/PulsumServices/HealthKitAnchorStore.swift:5-56)
  - `SpeechService` actor abstracts legacy vs. modern speech APIs, streaming audio levels and transcripts. (Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:33-307)
- **Data layer (PulsumData)**: Core Data stack, storage paths, and vector index.
  - `DataStack` provisions application-support directories, file protection attributes, and background contexts. (Packages/PulsumData/Sources/PulsumData/DataStack.swift:18-137)
  - `VectorIndex` persists float embeddings in sharded binary files; `VectorIndexManager` couples embeddings from `EmbeddingService`. (Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:268-337; Packages/PulsumData/Sources/PulsumData/VectorIndexManager.swift:11-36)
  - `LibraryImporter` ingests JSON podcast recommendations into Core Data entities and vector index entries, deduplicated by checksum. (Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift:41-168; json database/podcastrecommendations.json:1-20)
- **ML utilities (PulsumML)**: On-device embeddings, sentiment, safety, and ranking.
  - `EmbeddingService` selects AFM or Core ML fallback providers while ensuring 384-dim vectors. (Packages/PulsumML/Sources/PulsumML/Embedding/EmbeddingService.swift:4-74)
  - `EmbeddingTopicGateProvider` scores on-topic vs. out-of-domain using prototype embeddings and confidence margins. (Packages/PulsumML/Sources/PulsumML/TopicGate/EmbeddingTopicGateProvider.swift:4-168)
  - `SentimentService` chains Foundation Models, AFM templates, and Core ML classifiers. (Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentService.swift:3-38)
  - `SafetyLocal`, `StateEstimator`, and `RecRanker` provide local guardrails, wellbeing estimation, and recommendation ranking heuristics. (Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift:31-172; Packages/PulsumML/Sources/PulsumML/StateEstimator.swift:3-82; Packages/PulsumML/Sources/PulsumML/RecRanker.swift:3-160)

## 8. Data & Domain
- Core Data model defines journal entries, daily metrics, baselines, feature vectors, micro moments, recommendation events, ingest metadata, user consent, and consent state. (Pulsum/Pulsum.xcdatamodeld/Pulsum.xcdatamodel/contents:3-80)
- `DataAgent` constructs `FeatureVectorSnapshot` aggregates, persists subjective sliders, and materializes `ScoreBreakdown` metrics with baseline comparisons and imputation notes. (Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:8-44; Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:117-216)
- Journal embeddings are persisted as protected `.vec` files alongside Core Data entries to feed similarity search. (Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift:128-179)
- Recommendation content originates from bundled JSON (podcast recommendations) and is imported via `LibraryImporter`, which assigns evidence badges and populates the vector index. (Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift:41-127; json database/podcastrecommendations.json:1-20)

## 9. Networking
- All external networking is funneled through `LLMGateway`, which posts JSON-schema-bound requests to `https://api.openai.com/v1/responses` with strict max token clamping and error handling. (Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:184-304; Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:606-675)
- API keys are resolved from in-memory cache, Keychain, or the explicit `PULSUM_COACH_API_KEY` environment variable with validation—Info.plist is no longer consulted so secrets never ship inside the app bundle. `Gate0_LLMGatewayTests` guard the missing-key and precedence flows, and CI runs `scripts/ci/scan-secrets.sh` (repo + binary) after every build. (Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:136-210; scripts/ci/scan-secrets.sh; Packages/PulsumServices/Tests/PulsumServicesTests/Gate0_LLMGatewayTests.swift)

## 10. UI Composition & Navigation
- `PulsumRootView` renders a tab view with main dashboard, insights, and coach tabs, presenting pulse and settings sheets plus safety overlays. (Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift:5-274)
- `CoachView` delivers chat history, asynchronous send button, and real-time recommendation cards. (Packages/PulsumUI/Sources/PulsumUI/CoachView.swift:5-399)
- `PulseView` provides voice journal controls, waveform visualization, transcript playback, and subjective sliders with auto-dismiss messaging. (Packages/PulsumUI/Sources/PulsumUI/PulseView.swift:4-339)
- `ScoreBreakdownScreen` and `ScoreBreakdownViewModel` present wellbeing metrics, lifts/drags, and notes derived from `DataAgent`. (Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownView.swift:4-510; Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownViewModel.swift:7-56)
- Settings bundle toggles GPT consent, checks HealthKit authorization, tests API keys, and launches score breakdown navigation when available. (Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift:4-536; Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift:9-205)
- The design system codifies colors, spacing, typography, and glass effects reused across components. (Packages/PulsumUI/Sources/PulsumUI/PulsumDesignSystem.swift:6-172)

## 11. Error Handling, Logging, and Diagnostics
- Agents and services leverage `Logger` to trace routing decisions, LLM responses, and HealthKit errors, enabling debug-only NotificationCenter diagnostics. (Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:265-386; Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:136-270; Packages/PulsumServices/Sources/PulsumServices/DiagnosticsNotifications.swift:3-5)
- Guardrail breaches return safe messages (crisis or redirect) and emit debug telemetry. (Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:271-386)
- Errors from library import, sentiment capture, and API failures bubble up with localized messages for UI display. (Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift:36-45; Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift:75-118; Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:246-270)

## 12. Security & Privacy
- App entitlements declare HealthKit and background delivery, aligning with service usage. (Pulsum/Pulsum.entitlements:5-8)
- Data directories and vector embeddings are created with `.complete` file protection and excluded from iCloud backups. (Packages/PulsumData/Sources/PulsumData/DataStack.swift:71-135; Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift:164-178)
- Backup exclusion failures now surface as `BackupSecurityIssue`, block the UI at startup, and are covered by automated xattr tests (`Gate0_DataStackSecurityTests`), ensuring PHI never leaves the device. (Packages/PulsumData/Sources/PulsumData/DataStack.swift:18-137; Packages/PulsumData/Tests/PulsumDataTests/Gate0_DataStackSecurityTests.swift)
- SpeechService logging avoids PHI entirely in Release builds via `SpeechLoggingPolicy`; `Gate0_SpeechServiceLoggingTests` (built with the `RELEASE_LOG_AUDIT` flag) scan the compiled binary for the transcript marker to guarantee nothing leaks. (Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift; Packages/PulsumServices/Tests/PulsumServicesTests/Gate0_SpeechServiceLoggingTests.swift)
- Each target and Swift package ships a `PrivacyInfo.xcprivacy` manifest and CI enforces coverage via `scripts/ci/check-privacy-manifests.sh`; setting `RUN_PRIVACY_REPORT=1` runs `xcrun privacyreport` when the Xcode 16+ CLI tools are installed. The script now fails if the app target tries to copy more than one manifest, preventing duplicate-build warnings.
- PII is redacted from transcripts before sentiment scoring, and chat inputs are sanitized prior to routing. (Packages/PulsumML/Sources/PulsumML/Sentiment/PIIRedactor.swift:4-35; Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:221-234)
- GPT-5 API keys are injected at runtime via Keychain or the `PULSUM_COACH_API_KEY` environment variable—`Config.xcconfig.template` intentionally ships without secrets, and the Gate‑0 key-resolution tests prevent Info.plist regressions. (Packages/PulsumServices/Sources/PulsumServices/KeychainService.swift:19-78; Config.xcconfig.template)

## 13. Concurrency & Performance
- Critical components are Swift actors (`DataAgent`, `SpeechService`, `StubDataAgent` in tests) or use background Core Data contexts to avoid main-thread blocking. (Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:46-280; Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:33-307; Packages/PulsumAgents/Tests/PulsumAgentsTests/ChatGuardrailAcceptanceTests.swift:126-144)
- Async streams carry audio levels and transcripts to the UI, while Task groups coordinate HealthKit background delivery setup. (Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:96-225; Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift:80-146)
- Vector index read/writes are sharded with concurrent queues to scale recommendation searches. (Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:268-337)

## 14. Testing Strategy
- Guardrail acceptance tests exercise consent routing, cloud/on-device switching, and redirect messaging using stub vector indexes and LLM clients. (Packages/PulsumAgents/Tests/PulsumAgentsTests/ChatGuardrailAcceptanceTests.swift:12-183)
- Property-style tests cover topic gate margins, safety classification, and ranker heuristics. (Packages/PulsumAgents/Tests/PulsumAgentsTests/ChatGuardrailTests.swift:11-168; Packages/PulsumML/Tests/PulsumMLTests/TopicGateMarginTests.swift:6-34; Packages/PulsumML/Tests/PulsumMLTests/PackageEmbedTests.swift:4-69)
- Services tests validate HealthKit anchor persistence, Keychain storage, LLM schema compliance, and HTTP error handling via URL protocol stubs. (Packages/PulsumServices/Tests/PulsumServicesTests/HealthKitAnchorStoreTests.swift:5-44; Packages/PulsumServices/Tests/PulsumServicesTests/KeychainServiceTests.swift:5-14; Packages/PulsumServices/Tests/PulsumServicesTests/LLMGatewayTests.swift:64-215)
- Data tests ensure library ingestion seeds vector index matches. (Packages/PulsumData/Tests/PulsumDataTests/LibraryImporterTests.swift:5-33)
- UI test targets exist but currently contain boilerplate launch checks only. (PulsumUITests/PulsumUITests.swift:12-39)

## 15. Internationalization & Resources
- UI copy is hard-coded English within SwiftUI views; no localized `.strings` catalogs are configured. (Packages/PulsumUI/Sources/PulsumUI/CoachView.swift:15-386; Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift:28-526)
- Asset catalogs provide light branding images and accent colors; design tokens codify typography and spacing for consistency. (Pulsum/Assets.xcassets/Contents.json:1-6; Packages/PulsumUI/Sources/PulsumUI/PulsumDesignSystem.swift:6-172)
- Recommendation content ships as JSON resources bundled with the app and imported on first launch. (json database/podcastrecommendations.json:1-20; Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift:41-127)

## 16. CI/CD & Release
- No Fastlane scripts or platform-specific CI workflows are present in the scanned inventory; builds rely on Xcode schemes and manually provisioned API keys. (inventory.json:1-20; Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:136-210)
- Configuration uses per-developer `.xcconfig` files, but the checked-in template currently exposes a real API key, warranting rotation before release. (Config.xcconfig:1-5)

## 17. Risks, Gaps, and TODOs
1. **API key exposure** – Keep `Config.xcconfig.template` free of secrets and rely on Keychain/env injection plus the Gate‑0 secret scanner to prevent regressions. (Config.xcconfig.template; scripts/ci/scan-secrets.sh)
2. **Simulator limitations** – HealthKit background delivery requires entitlements; simulator starts log recoverable failures that should surface to the user for clarity. (Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:119-133)
3. **UI tests incomplete** – UITest targets are placeholders; expand coverage for voice journal, chat, and settings flows. (PulsumUITests/PulsumUITests.swift:12-39)
4. **Large bundled dataset** – The full recommendation corpus (>50 KB) is duplicated at the repo root; dedupe to single canonical source to avoid drift. (json database/podcastrecommendations.json:1-20; podcastrecommendations.json:1-20)
5. **On-device fallback quality** – Legacy coach generator returns a static message when Foundation Models are unavailable, potentially degrading UX; consider richer on-device templates. (Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:590-603)

## 18. Coverage Report
| Path | SHA-256 | Status | Reason |
|---|---|---|---|
| .DS_Store | 1a398ceb449cc415441ddd5593683a4cd7e6675c2b3f7ff639fa1991a46a2d15 | summarize_only | Not required for detailed read |
| .claude/settings.local.json | bf958c047a166e897967eb1ea15f63756cec69a4721964dbc685c16d0ac90ce4 | read | JSON resource |
| .github/coderabbit.yaml | f03696726f48b362128f629b36624fd88aebce0a0fe328262535340984e2fbda | summarize_only | Not required for detailed read |
| .github/workflows/auto-merge.yml | 0512dcbd61988c4f4229dfa033be784b9be92295e1ce6c65d8f2a4f5fe219ab9 | summarize_only | Not required for detailed read |
| .github/workflows/auto-pr.yml | 3065d4e0b62f2faf6cef076c3e9b55e42546f861e8bb8ba4532d10124ae331d3 | summarize_only | Not required for detailed read |
| .gitignore | d3c46a4b76a774dda3ff448241318cf82c4e3e8a3e9b680c4573880e1e96355e | summarize_only | Not required for detailed read |
| .vscode/settings.json | 6d24b0d571970e6716a61cc325add89c7003acf07228128ab62a725eead357a9 | read | JSON resource |
| Config.xcconfig | e2c5860800919e53b398da5079492b06908df4b74ac1a34728bc6af5d037e33a | read | Build configuration |
| Config.xcconfig.template | d75959e8c7c3d7dfda38118bb7367b04df93c6560e3134007f65f1aa862a213f | summarize_only | Not required for detailed read |
| Docs/COPY_PASTE_PROMPT_M4.txt | 3bb28db4a085ece3d40d6c532327a802ceb07c6a2bc25a5aa28e3f28c8e655ba | summarize_only | Not required for detailed read |
| Docs/FIX_SPLINE_CRASH_PROMPT.txt | 830c45a76c6a7109f038d5f4b20c12e8de841df58fa29d5710cafa11e46008d3 | summarize_only | Not required for detailed read |
| Docs/MILESTONE_4_UI_REDESIGN_PROMPT.txt | 1894a5d99cc06be2d3b3bd42d7af88083e3ded0edb11763af831a21a2c2a5ae7 | summarize_only | Not required for detailed read |
| Docs/SPLINE_CLOUD_ONLY_PROMPT.txt | fe4d1c4b9260fa05f4d20e904f9b0fc373b74008236ef8aecedcd7ca9b29e117 | summarize_only | Not required for detailed read |
| MAINDESIGN.png | 2b9e9954ae9bc6745f489cb2b13ca1107537986573244cfe11118addd2cd6975 | summarize_only | Image asset |
| Packages/.DS_Store | dbb72c8c84423ef5f3fcf5649bf1afa0622c8f0022a364b17068b78a870643f4 | summarize_only | Not required for detailed read |
| Packages/PulsumAgents/.DS_Store | 676c2a3d14fa299d3c059cfd9ea4deb91ce66c9611273da6ca7c589d9a3a277e | summarize_only | Not required for detailed read |
| Packages/PulsumAgents/.swiftpm/xcode/xcuserdata/martin.demel.xcuserdatad/xcschemes/xcschememanagement.plist | 400e7261567b2c66f00df6a6ef9609710b287dfed49a015de8f131a579611fd5 | read | Property list |
| Packages/PulsumAgents/Package.swift | f5489da0c2eba694906e2ae6af83ec91ab9383aa2a52b7cfe35237d7d4cfb9a3 | read | Swift package manifest |
| Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift | 145611068796e6bdcb5879c650a0a440817221ff485c18283e622bdbef2df387 | read | Swift source |
| Packages/PulsumAgents/Sources/PulsumAgents/CheerAgent.swift | a238c8f93627b3160af6095a401c582965aa587fd6acd03351cd186fdb1f899c | read | Swift source |
| Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent+Coverage.swift | e9c2e3796178d2f4022127ec33bcfbcbbad09cc841f3fad8f39dc31c8afb583e | read | Swift source |
| Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift | 4e69ebd17afacd4dc4319a98c7f37cebfe2e6eeb1d46afe9d4bd2445b5ee42fb | read | Swift source |
| Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift | 47389217ae9390a8a2d9712444e5425f6f7d81ae3bcad22674e084e1f6e407b8 | read | Swift source |
| Packages/PulsumAgents/Sources/PulsumAgents/PulsumAgents.swift | 919b178b1f5e8efd91958bce82d3fd0b7cbf9e36a67258fca205719d9ebf58ca | read | Swift source |
| Packages/PulsumAgents/Sources/PulsumAgents/SafetyAgent.swift | df5e3e88e486b0941a77de7c3b23e5d4e922232e5370bf16db61035d6dbf6b48 | read | Swift source |
| Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift | 4e07a7be23464f1678b23d34d6cb04be2190e6a1767ca32829788b10a811150e | read | Swift source |
| Packages/PulsumAgents/Tests/PulsumAgentsTests/AgentSystemTests.swift | 3e08b6dd780f678d0b7b71c66476e0c252bcdb63b7cd49fcba00cf3468137d92 | read | Swift source |
| Packages/PulsumAgents/Tests/PulsumAgentsTests/ChatGuardrailAcceptanceTests.swift | bf4b57c3a92039e245ecf2ea879555cfad525e7b56d0a342d570f2279726976c | read | Swift source |
| Packages/PulsumAgents/Tests/PulsumAgentsTests/ChatGuardrailTests.swift | fdc8da64eceb4587767c9bba72a4273a82327415bc801e0629d19c6a3cc703ee | read | Swift source |
| Packages/PulsumAgents/Tests/PulsumAgentsTests/TestCoreDataStack.swift | 325440f475ab5088304f4c558927608cc57367cf67237ee5fa089c64c88e1a72 | read | Swift source |
| Packages/PulsumData/.DS_Store | e823f0b81869cdc6b92af386bc3e933167a8d3610dfbabdfc2a5a7f64e3f9d1e | summarize_only | Not required for detailed read |
| Packages/PulsumData/.swiftpm/xcode/xcuserdata/martin.demel.xcuserdatad/xcschemes/xcschememanagement.plist | 966c52025741d1effce18ea3d7942ee138292c52f543d1a7ed02127ff3b3cf1a | read | Property list |
| Packages/PulsumData/Package.swift | 2125b2e2a0a810e14680f77eead1c5de50526b1e0f25bcc6e4360559f89a242b | read | Swift package manifest |
| Packages/PulsumData/Sources/PulsumData/DataStack.swift | 3779d5b57efc30687ac98caa21901e86d4ef1bdfcb5d392a0ee5b678612553b4 | read | Swift source |
| Packages/PulsumData/Sources/PulsumData/EvidenceScorer.swift | 0553ee1210ce86cfaaa494177ce1f3f4fc940f30fe660d9efcf787433f9673f0 | read | Swift source |
| Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift | 5b50d64185b3fc4ae2f79f3df7bd610a0338bd902255ccb977011b1dd9055311 | read | Swift source |
| Packages/PulsumData/Sources/PulsumData/Model/ManagedObjects.swift | c668eb983b01fca16b00fe51ab395c8234b820a8f91e04099cab7a03b87f10da | read | Swift source |
| Packages/PulsumData/Sources/PulsumData/PulsumData.swift | 15f617eb5ef2f161fbc8701c04e16b966a4476b7acc18ccbee685d6d7544937a | read | Swift source |
| Packages/PulsumData/Sources/PulsumData/VectorIndex.swift | a214853eb53e05c1aae13fd1c48d90d513b493f749ac3855d5363b1d7a315515 | read | Swift source |
| Packages/PulsumData/Sources/PulsumData/VectorIndexManager.swift | 4eeef318abf1f10edfa518682be2b01b0a5a5aca891b982c37963ddd9888d8f4 | read | Swift source |
| Packages/PulsumData/Tests/PulsumDataTests/LibraryImporterTests.swift | 2652eb06da2449680dbe99b8349ea024deaa750cb03c7be0e84486eed60d4a30 | read | Swift source |
| Packages/PulsumData/Tests/PulsumDataTests/PulsumDataBootstrapTests.swift | bed04ed0334fbac69018d6d040c366cf9a8ff4b49f88e00c6dac60adbc4a1b20 | read | Swift source |
| Packages/PulsumData/Tests/PulsumDataTests/Resources/podcasts_sample.json | 6a63e871a113e1294d5958150892d674f9098a7bade4bd18931c7a8ec02f96da | read | JSON resource |
| Packages/PulsumData/Tests/PulsumDataTests/VectorIndexTests.swift | 67512dad12b68e710c97d3c155fc1cfb54b654745b165455d804bd67cf306473 | read | Swift source |
| Packages/PulsumML/.DS_Store | edeccffeff3abc3898b11156c1bcc993332bd88f98f99ce293d5dd524cb64b99 | summarize_only | Not required for detailed read |
| Packages/PulsumML/.swiftpm/xcode/xcuserdata/martin.demel.xcuserdatad/xcschemes/xcschememanagement.plist | fdf3b5cb79da3fae44c56f2e5589a956889a3c0275d54846a2a3cc3f5b0f0359 | read | Property list |
| Packages/PulsumML/Package.swift | da715c8ccb68f3619abce7ccbb84a4bf0c96f1ec1ca792bf025da022dc93dd65 | read | Swift package manifest |
| Packages/PulsumML/Sources/PulsumML/AFM/FoundationModelsAvailability.swift | 62494100fc9ae10975f9d5d33774f16b711d0d9d9a33469742124e94b0f585f7 | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/AFM/FoundationModelsStub.swift | 346e380690aa3d6807236cbe178685fe9d6659efe7de4fe67537e2f891e8dab1 | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/BaselineMath.swift | 04a2a2371ae369542d5d792b812c753ff4bb560702dae336aef8ab1fd749bbf9 | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/Embedding/AFMTextEmbeddingProvider.swift | bfcffa0d81f216bce0aec01317ba82d05ef967e92e4491f7e935d39ac072172d | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/Embedding/CoreMLEmbeddingFallbackProvider.swift | 85bab243e12828f570fec20a772061d7011e5487dcebf7b0d3cd9fae929538d3 | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/Embedding/EmbeddingError.swift | 5844e56cc3a6982e0cb9c7dfe5a1cb52305e37bf06e60e79eda952a9e065d023 | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/Embedding/EmbeddingService.swift | 645d8e1cd38ef97d05cb808252b69b534eb0589585fa6f06cd0be47f0ba6ad1f | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/Embedding/TextEmbeddingProviding.swift | ed1277432b9d06cb1cb1824bacbeec59d895ce780c8280140695afe796246ab5 | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/Placeholder.swift | 9138cf8e32703915f9bfe588f627821a8dcd280ef0d3c7977b5c504ab5a50ffa | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/RecRanker.swift | 40752818d31aa5cc517e3bb0c99924d8ca134b8951316b8c5e05e0fa6e2bb1bc | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/Resources/PulsumFallbackEmbedding.mlmodel | 45cdcd3973bf5235162dd8038467d9d8d6e535712d422a068eaa298b26ba3115 | summarize_only | Not required for detailed read |
| Packages/PulsumML/Sources/PulsumML/Resources/PulsumSentimentCoreML.mlmodel | e3a2ba1a2ae59335543216765bcedded2bec92170b40bdbb59c505d88da52934 | summarize_only | Not required for detailed read |
| Packages/PulsumML/Sources/PulsumML/Safety/FoundationModelsSafetyProvider.swift | f02b563b8d2f63c4b38063ee2176a0244ecfd9056cbf6a1f69ea3edd5462fc0f | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift | 67b83d95d8fb6d274aa53f4467ac452435f3f148d9aed1edd980cd6515a9b065 | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/Sentiment/AFMSentimentProvider.swift | 1e4b896c7847b53e11df343154013050989eabeac000bbec124b11df54c80e54 | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/Sentiment/CoreMLSentimentProvider.swift | 01beab66dc851392e9b8e21d79ed3ee86c8afbf458961faaa0c0229967ef7cc9 | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/Sentiment/FoundationModelsSentimentProvider.swift | a262ac59a45b252ccc29ddb5719df73f16272820470f803dcbefe501f2b9c0e0 | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/Sentiment/NaturalLanguageSentimentProvider.swift | f1a4ccb297bcad228df67c8699ff45c5c3812a658202b047e057e5ade0b6794c | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/Sentiment/PIIRedactor.swift | e569fbeec0e7b15b77f98229582ce36cc636849abdf5dcef62aff81b65499847 | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentProviding.swift | cc7c462a2415e54cf5b0829d47d2911ea81e83065183347f1419fe883bace095 | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentService.swift | d6e476e54a4d7c8942ac814aa91c3e9b14f225d17117eabf421622a255dac823 | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/StateEstimator.swift | e07d876a3fea3dbbd331bd9402465e4eb71e0473eacf92f296c3f450ad528827 | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/TopicGate/EmbeddingTopicGateProvider.swift | 5b234bb0e6fd3c013e1ce0f96b70d4ce9c320b0ae396703b6dab4ec1c9489130 | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/TopicGate/FoundationModelsTopicGateProvider.swift | b239b2a812fd623b13c54196694ea2a84014808aa6b087d8084c9d7c866f89d5 | read | Swift source |
| Packages/PulsumML/Sources/PulsumML/TopicGate/TopicGateProviding.swift | a0f5256a0f83aa741bb31cd1b76c9e12f52ff21261997cc19a92a9b2dc7b8575 | read | Swift source |
| Packages/PulsumML/Tests/PulsumMLTests/PackageEmbedTests.swift | df3ee129e8246b5a238156fb58a901df2c3c2963d023e84a821ade5e5a5f713f | read | Swift source |
| Packages/PulsumML/Tests/PulsumMLTests/SafetyLocalTests.swift | 76fb751d8be17af00f3cf442d6dd5102020c259ab4d64d2dc3a3a0e894f13dd2 | read | Swift source |
| Packages/PulsumML/Tests/PulsumMLTests/TopicGateMarginTests.swift | 64a0fe5a5e3d765371fd2810a01d8b21bee3d1ce638d2b05cfbfebb70914c8e6 | read | Swift source |
| Packages/PulsumML/Tests/PulsumMLTests/TopicGateTests.swift | c332987b6df833cb7d190652c66379b6b475f4fb98f806ca26c9398497b8dbec | read | Swift source |
| Packages/PulsumServices/.DS_Store | 53b3bdf7a013918978f47a4459093e709b65514eae8ddc02d35fb4d8184aefc1 | summarize_only | Not required for detailed read |
| Packages/PulsumServices/.swiftpm/xcode/xcuserdata/martin.demel.xcuserdatad/xcschemes/xcschememanagement.plist | 49854046ee2c2c607d2863a43e51a124accd4f1c0544012a819ac21c7d33dc0f | read | Property list |
| Packages/PulsumServices/Package.swift | f002caff905dda0342f328427a2325f8e05e78d886038c597c1dba39fb9549c2 | read | Swift package manifest |
| Packages/PulsumServices/Sources/.DS_Store | 28bce63dc53e9887cf1e94ce4b263003f26138aa28231cccf590b29d6be1fbc3 | summarize_only | Not required for detailed read |
| Packages/PulsumServices/Sources/PulsumServices/CoachPhrasingSchema.swift | fb03e55fe72a1eabe811058bd87d6d58077a777e9794804f0394273f18c3d20b | read | Swift source |
| Packages/PulsumServices/Sources/PulsumServices/DiagnosticsNotifications.swift | a8b83a1cdd7a2d53e06bd975c3e58b499cd5199dc7b0a07f4f130f94780759d9 | read | Swift source |
| Packages/PulsumServices/Sources/PulsumServices/FoundationModelsCoachGenerator.swift | 60971352cdf6f3bac4be66adb8872ed0332fe5959aca07cbd457169ac38d0d73 | read | Swift source |
| Packages/PulsumServices/Sources/PulsumServices/HealthKitAnchorStore.swift | 764cde0834fb841207106f72ae68238256ecf73b622255fc2e770baf9ac62d68 | read | Swift source |
| Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift | e25ed111dad8e224268424a1e0b5bdb303cf410529a21a4a7916c398b4f5e1f8 | read | Swift source |
| Packages/PulsumServices/Sources/PulsumServices/KeychainService.swift | 24778f8f97364a805d7dcb126be6a95f4f5c4cc55ded669e402a51f3fded6d3e | read | Swift source |
| Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift | b9ea933fbb566b2e2868844047c47ec5808345b9366c9f7af25991bff9efe545 | read | Swift source |
| Packages/PulsumServices/Sources/PulsumServices/Placeholder.swift | 8939f52054e950b10a8b8936c3b7bd00d9da5254bea740a1aa0a04e347ea10b8 | read | Swift source |
| Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift | 4af43e63fbfda5af618598ad40a340cb89d9266b4f39c84eee83f0db12bffd3a | read | Swift source |
| Packages/PulsumServices/Tests/PulsumServicesTests/HealthKitAnchorStoreTests.swift | cf5714930608e9fd3231b12e646de79837ecba7543a3760c295275c747ab5ed6 | read | Swift source |
| Packages/PulsumServices/Tests/PulsumServicesTests/KeychainServiceTests.swift | 385fa2e3d8666fd9112ecddfccfd9c595c156d217d6e290872561811f28eb69c | read | Swift source |
| Packages/PulsumServices/Tests/PulsumServicesTests/LLMGatewaySchemaTests.swift | d5ea067803f60f483191e366aba5355edc66be5f5a21e2994ce7cdf467c5b320 | read | Swift source |
| Packages/PulsumServices/Tests/PulsumServicesTests/LLMGatewayTests.swift | d8142f57e793ac4a4f8c92bfdc99a7639a924fb5ea372d4ba874905c47dd6bad | read | Swift source |
| Packages/PulsumServices/Tests/PulsumServicesTests/PulsumServicesDependencyTests.swift | 1df9d256c36836d2610cfc95c7ccddc27ed8cc5b3e85eae388bac384acb7f6f2 | read | Swift source |
| Packages/PulsumServices/Tests/Support/LLMURLProtocolStub.swift | 23c942a7972247f22a1af5a7f4778248af3cd4d6b783451f31c52d529b68d9a8 | read | Swift source |
| Packages/PulsumUI/.DS_Store | 2cca71698fd0412f840443324b67c3416c8eae89ad4699212b0b25792ca96d10 | summarize_only | Not required for detailed read |
| Packages/PulsumUI/.swiftpm/xcode/xcuserdata/martin.demel.xcuserdatad/xcschemes/xcschememanagement.plist | df00e59ce927f2bb8b331d47d40ee8e66198c9db2fe494118149474107581220 | read | Property list |
| Packages/PulsumUI/Package.swift | 585083d098b01385e87f8a24fca024ee9d8127e7f37a05d62a440dd92a3036b2 | read | Swift package manifest |
| Packages/PulsumUI/Sources/.DS_Store | 53dab547b811d30d39c101d21efb48a102eb84666359dfc67a9ecf79fcbeb7a4 | summarize_only | Not required for detailed read |
| Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift | ee5895c8a22b9d4c8addf394019a063336f39f9c18d104412e44e6b957df533b | read | Swift source |
| Packages/PulsumUI/Sources/PulsumUI/CoachView.swift | ce85b5da30533ea7544a1460d71c7f2ffa41560d8e207e1f86bc825d5ab15c6b | read | Swift source |
| Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift | 4522419d0d3a7289a2365060e779fecf5ec66ed93581253177c0bc8c587e5246 | read | Swift source |
| Packages/PulsumUI/Sources/PulsumUI/ConsentBannerView.swift | 2c838b1b47dd2b59468c519b73a204014f0ba9e643851cd620935adf321d0a34 | read | Swift source |
| Packages/PulsumUI/Sources/PulsumUI/GlassEffect.swift | c2ae598acc53f0de0730b7ece4407590bd105593018c4b76e001069fac6294b5 | read | Swift source |
| Packages/PulsumUI/Sources/PulsumUI/LiquidGlassComponents.swift | dc0d1fc7d14677e5d0339a08bd00c7c5c8dc64e22cdfee7fcc6f8c47dffbeeb8 | read | Swift source |
| Packages/PulsumUI/Sources/PulsumUI/OnboardingView.swift | c5ea4d6beaa429640fdb06047222ba369284dc6f96e6c022ec6b30105e664e11 | read | Swift source |
| Packages/PulsumUI/Sources/PulsumUI/PulseView.swift | 001dd9b7bf32930814fb1e41576e0976e1ca01204d64b125942d470ac3682cf5 | read | Swift source |
| Packages/PulsumUI/Sources/PulsumUI/PulseViewModel.swift | e2ca1f57c41841d146e44ad69a78b9584bc9f090229e9b3c047fb96d5212b17e | read | Swift source |
| Packages/PulsumUI/Sources/PulsumUI/PulsumDesignSystem.swift | 1161eba2b1c5fd1e7416822f23f46e26b55657d2ee00af5d9f06b5bd32edd348 | read | Swift source |
| Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift | f088db87fa978494a888d5baefc94e2c041305490a95678cffb6ed8ba76002aa | read | Swift source |
| Packages/PulsumUI/Sources/PulsumUI/SafetyCardView.swift | 08166a48a28937cd545fa2faf66369993fc90823495946969ee0a881b9a43342 | read | Swift source |
| Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownView.swift | 655d627ead4a94c2885f50628faa9e7e52dc5ead3acb2a6472b4a538693b64a7 | read | Swift source |
| Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownViewModel.swift | 7371c226b1fdaf6935cdd7f6ac13be49f9cb3ac6c9ef942f21b2e560b9396710 | read | Swift source |
| Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift | 1948212450f9ed8622c26b71cae9a9a8e6d63bf94162cf21f529c9f7d4d84bd8 | read | Swift source |
| Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift | f278dd05deb7b183d07aea7d43a39ec12c317d5cb41105b95f68e1b0a9e6a0c0 | read | Swift source |
| Packages/PulsumUI/Tests/PulsumUITests/PulsumRootViewTests.swift | b1108a5b5668d328870a81bf9095e4bff0d37c1a5521d0e048c8f4134ab54ec7 | read | Swift source |
| Pulsum.xcodeproj/project.pbxproj | 49a79a523b33556eeb35d8a88ca5e6498127037a945e7079611a489fd042134d | read | Xcode project definition |
| Pulsum.xcodeproj/project.pbxproj.backup | 2c14bd6ff4178f37c6bfb66b7122145a61418ca184b5bd4e09b1db8ede720cff | summarize_only | Not required for detailed read |
| Pulsum.xcodeproj/project.xcworkspace/contents.xcworkspacedata | 7f3b00b5c3fdb45242d7b87e1e5c4e25d1fa8129a16c94295ecc4e8ea2235c5f | read | Workspace data |
| Pulsum.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved | 8bf18dd4796cc007db891a77adc93ed0093046e45a2653a15a47e180a5079cc5 | read | Swift package resolved versions |
| Pulsum.xcodeproj/project.xcworkspace/xcuserdata/martin.demel.xcuserdatad/UserInterfaceState.xcuserstate | f019e5f2686baf5537031d99cefb2926bb3f8d370ac44519ab11fcc95831d2b5 | summarize_only | Not required for detailed read |
| Pulsum.xcodeproj/xcshareddata/xcschemes/Pulsum.xcscheme | d0de317cfda800a7a4556bd2b20d1ac75f0cec0f91a3d7ca87414fdcfa5ac04e | summarize_only | Not required for detailed read |
| Pulsum.xcodeproj/xcuserdata/martin.demel.xcuserdatad/xcschemes/xcschememanagement.plist | 6b03dc5f6c660fb87121f97633bfaa32468de8d7655b640dd5282e3e13659d4f | read | Property list |
| Pulsum/.DS_Store | 4b25171370bb11d979f74be9d4d1005d89ea5ffce3cca81f2ccfa5077d9db0d8 | summarize_only | Not required for detailed read |
| Pulsum/Assets.xcassets/.DS_Store | cfd2ec1b89903f336dc718c9af7805867036ca31095162558123d780fbc2ecf4 | summarize_only | Not required for detailed read |
| Pulsum/Assets.xcassets/AccentColor.colorset/Contents.json | 9af65086fa30b49252fae1a1225731691de794f7775af74d71befeb507d12b7c | read | JSON resource |
| Pulsum/Assets.xcassets/AppIcon.appiconset/Contents.json | 0670fbf42754fed308e115f94562c52060c3ff7977adf215915b7814338bea3f | read | JSON resource |
| Pulsum/Assets.xcassets/AppIcon.appiconset/logo2_with_white_bg 1.png | 1324789f541cec13a666285b3b48dfc9eabe94c04aaeb4c0c01b8ff642616356 | summarize_only | Image asset |
| Pulsum/Assets.xcassets/AppIcon.appiconset/logo2_with_white_bg 2.png | 1324789f541cec13a666285b3b48dfc9eabe94c04aaeb4c0c01b8ff642616356 | summarize_only | Image asset |
| Pulsum/Assets.xcassets/AppIcon.appiconset/logo2_with_white_bg.png | 1324789f541cec13a666285b3b48dfc9eabe94c04aaeb4c0c01b8ff642616356 | summarize_only | Image asset |
| Pulsum/Assets.xcassets/Contents.json | 0fd49ba3c3585c709678e0046a821c3c60685ec7063720d30d3a3448be3a208b | read | JSON resource |
| Pulsum/Pulsum.entitlements | 3a0fe663304785c4f157a6a2dd599ff9c1abbd87138e73bb313b5141f3e27618 | read | Entitlements |
| Pulsum/Pulsum.xcdatamodeld/.xccurrentversion | 1139771d43c6b86db70dc760278d2b75b4e9593fdbce6deb0375024356b68f9d | read | Core Data current version marker |
| Pulsum/Pulsum.xcdatamodeld/Pulsum.xcdatamodel/contents | 170131f2cff09976cc8d085ecb8da51f9e8484805fefa0c615b4460e55bbbe15 | read | Core Data model contents |
| Pulsum/PulsumApp.swift | 029c3b42c425daa6b1a71b38cc55b64ff7b85ac93c97b64c89118d3cafcf29e4 | read | Swift source |
| PulsumTests/PulsumTests.swift | ff425d00e00d0177eb9adf347bb47c5f3e51fea00ab0c81e6b824b98d4c18ec9 | read | Swift source |
| PulsumUITests/PulsumUITests.swift | ec2c04a16c2160a40da089eedb1555b9b7f8c9b8c4b30650d6ccc76b08d2fb66 | read | Swift source |
| PulsumUITests/PulsumUITestsLaunchTests.swift | e9eb2ddd05dd7f31d5d230bbd7157e486733be81e019e0a55c047e4d54022e2e | read | Swift source |
| a-practical-guide-to-building-agents.pdf | 1903c2b1837b206d1951d8a3d1124515aee1bebebd8f2448c630c75a6b0aad86 | summarize_only | PDF asset |
| infinity_blubs_copy.splineswift | fe4f7c35996a6a20cf60816d913b93aa18ca959e8b8ef3bb5acfa04dd704c461 | summarize_only | Spline design asset |
| inventory.json | 65710ef7d90de6b9b747288abc0ae48759761b690c9a2909a85ecc64fd98ee12 | read | JSON resource |
| ios app mockup.png | a0d118c867dba9ef8f52097419c608d7912946fcd85e7584df81b189a38094ff | summarize_only | Image asset |
| ios support files/glow.swift | 59923efcc4ec5f2dabbd2dfd67bb10d0e73247d0334975d171ffa84fb5bd1535 | read | Swift source |
| json database/podcastrecommendations.json | 50464a3a1673f4845622281d00ecf5099e62bd72d99099fe1ea7d218b0a1f35c | read | JSON resource |
| logo.jpg | 49ecea236ea825afed3f4dbe6f374299cbbb87aadbaaf5ce029c8c7c1ca34de2 | summarize_only | Image asset |
| logo2.png | 0cb9ec37668a50f75151942e2d993608f7a9507c805fabac700cae47805bfe46 | summarize_only | Image asset |
| mainanimation.usdz | 9dd79ebe7c92c39a772b39316f8dbf3c4c459721363aaee27215453374e9a0e3 | summarize_only | 3D asset |
| podcastrecommendations 2.json | 50464a3a1673f4845622281d00ecf5099e62bd72d99099fe1ea7d218b0a1f35c | read | JSON resource |
| podcastrecommendations.json | 50464a3a1673f4845622281d00ecf5099e62bd72d99099fe1ea7d218b0a1f35c | read | JSON resource |
| streak_low_poly_copy.splineswift | 60b540c0a7857b24f6406627dd3f64b7760d08037d4384aaaf4e99b66a7fd9b9 | summarize_only | Spline design asset |

## 19. Confidence & Open Questions
- **Confidence** – High: orchestrator, services, UI, data, and ML layers were reviewed directly in source, enabling end-to-end tracing of data and control flows. (Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:65-404; Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:136-304; Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift:5-274; Packages/PulsumData/Sources/PulsumData/DataStack.swift:18-137)
- **Open Question 1** – Secret rotation plan for the bundled GPT-5 key remains unclear; confirm production sealing before release. (Config.xcconfig:1-5; Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:136-210)
- **Open Question 2** – Foundation Models availability paths rely on runtime Apple Intelligence settings; validate device UX when models are downloading or disabled. (Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:76-104; Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift:55-63)
- **Open Question 3** – Cloud fallback tests cover schema errors but broader resiliency (timeouts, rate limits) is still to be exercised. (Packages/PulsumServices/Tests/PulsumServicesTests/LLMGatewayTests.swift:154-215)
