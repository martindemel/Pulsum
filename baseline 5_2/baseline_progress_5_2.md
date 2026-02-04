# Baseline Progress

Repo: /Users/martin.demel/Desktop/PULSUM/Pulsum
Started: 2025-11-11

## Environment
- uname: Darwin Martins-MacBook-Pro.local 25.2.0 (arm64)
- macOS: 26.2 (25C56)
- Xcode: 26.1.1 (17B100)

## Task Checklist
- [x] Task 1: Confirm repo root and tooling; record OS/toolchain versions if visible.
- [x] Task 2: Generate full tracked file list (git ls-files) and write to baseline_progress.
- [x] Task 3: Categorize files by type/role (Swift, md, json, plist, assets, scripts, tests).
- [x] Task 4: For each file in the tracked list: read entire file; append short File Summary entry to baseline.md appendix; record notable types/functions/constants.
- [x] Task 5: Identify build system(s): Package.swift, xcodeproj, workspaces; summarize.
- [x] Task 6: Identify app entrypoints; document lifecycle.
- [x] Task 7: Map modules/frameworks and dependencies; create a dependency diagram (Mermaid ok).
- [x] Task 8: Locate Core Data stack code; summarize configuration and file locations.
- [x] Task 9: Extract Core Data model entities + key attributes (especially Transformables); summarize.
- [x] Task 10: Locate HealthKit permission flow and purpose strings; document.
- [x] Task 11: Trace HealthKit read pipeline end-to-end into persistence.
- [x] Task 12: Trace backfill pipeline end-to-end; document warm vs full phases.
- [x] Task 13: Trace the “day key” logic; document all places where “today” is computed.
- [x] Task 14: Identify why values may not reset at midnight (cache keys, persistence keys, scheduling).
- [x] Task 15: Locate wellbeing scoring entrypoints; document function chain.
- [x] Task 16: Document baseline math / normalization; identify state that persists across days.
- [x] Task 17: Locate micro moments schema types and JSON files; document fields and meaning.
- [x] Task 18: Trace library import pipeline into Core Data; document idempotency and versioning.
- [x] Task 19: Trace embedding indexing pipeline; document when it runs and when it defers.
- [x] Task 20: Trace embeddings availability probing; document decision tree.
- [x] Task 21: Identify and document all embedding providers and their failure modes.
- [x] Task 22: Locate vector index storage/rebuild logic; document.
- [x] Task 23: Trace CoachAgent recommendation pipeline from UI trigger to returned cards.
- [x] Task 24: Document all “empty recommendations” paths and their conditions.
- [x] Task 25: Document keyword fallback and rule-based fallback presence/absence.
- [x] Task 26: Locate UI messaging for “limited recommendations”; document gating logic.
- [x] Task 27: Document notifications/events that refresh recommendations and scores.
- [x] Task 28: Document background tasks/timers/observers; note which are best-effort.
- [x] Task 29: Document logging/diagnostics patterns, redaction, and privacy posture.
- [x] Task 30: Review app capabilities/entitlements; document.
- [x] Task 31: Inventory test suite; map tests to features.
- [x] Task 32: Identify missing tests for (a) midnight reset, (b) recommendation non-empty, (c) embedding fallback availability.
- [x] Task 33: Produce “Top 10 Risks” list grounded in code evidence.
- [x] Task 34: Compare baseline.md conclusions with architecture.md; identify mismatches.
- [x] Task 35: Update architecture.md to resolve mismatches (additive/corrective only).
- [x] Task 36: Final pass: ensure baseline.md is coherent, navigable, and includes TOC + links.

## Progress Notes
- 2025-11-11: Task 1 completed. Created baseline_progress.md.

## Tracked Files (git ls-files)
Count: 269

```text
.github/coderabbit.yaml
.github/workflows/auto-merge.yml
.github/workflows/auto-pr.yml
.github/workflows/test-harness.yml
.gitignore
CLAUDE.md
COMPREHENSIVE_BUG_ANALYSIS.md
ChatGPT for engineers - Resource _ OpenAI Academy.pdf
Config.xcconfig.template
Docs/a-practical-guide-to-building-with-gpt-5.pdf
Docs/architecture copy.md
Docs/architecture_short copy.md
Docs/chat1.md
Docs/chat2.md
GITHUB_WORKFLOW.md
MAINDESIGN.png
Packages/PulsumAgents/Package.swift
Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift
Packages/PulsumAgents/Sources/PulsumAgents/BackfillStateStore.swift
Packages/PulsumAgents/Sources/PulsumAgents/CheerAgent.swift
Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent+Coverage.swift
Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift
Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift
Packages/PulsumAgents/Sources/PulsumAgents/EstimatorStateStore.swift
Packages/PulsumAgents/Sources/PulsumAgents/HealthAccessStatus.swift
Packages/PulsumAgents/Sources/PulsumAgents/PrivacyInfo.xcprivacy
Packages/PulsumAgents/Sources/PulsumAgents/PulsumAgents.swift
Packages/PulsumAgents/Sources/PulsumAgents/RecRankerStateStore.swift
Packages/PulsumAgents/Sources/PulsumAgents/SafetyAgent.swift
Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift
Packages/PulsumAgents/Sources/PulsumAgents/WellbeingScoreState.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/AgentSystemTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/ChatGuardrailAcceptanceTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/ChatGuardrailTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/DebugLogBufferTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate2_JournalSessionTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate2_OrchestratorLLMKeyAPITests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate2_TypesWiringTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate3_FreshnessBusTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate3_HealthAccessStatusTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate3_IngestionIdempotenceTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate4_ConsentRoutingTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate4_LLMKeyTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate4_RoutingTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate6_EmbeddingAvailabilityDegradationTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate6_RecRankerLearningTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate6_RecRankerPersistenceTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate6_SentimentJournalingFallbackTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate6_StateEstimatorPersistenceTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate6_StateEstimatorWeightsAndLabelsTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate6_WellbeingBackfillPhasingTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/Gate6_WellbeingStateMappingTests.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/HealthKitServiceStub.swift
Packages/PulsumAgents/Tests/PulsumAgentsTests/TestCoreDataStack.swift
Packages/PulsumData/Package.swift
Packages/PulsumData/Sources/PulsumData/Bundle+PulsumDataResources.swift
Packages/PulsumData/Sources/PulsumData/DataStack.swift
Packages/PulsumData/Sources/PulsumData/EvidenceScorer.swift
Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift
Packages/PulsumData/Sources/PulsumData/Model/ManagedObjects.swift
Packages/PulsumData/Sources/PulsumData/PrivacyInfo.xcprivacy
Packages/PulsumData/Sources/PulsumData/PulsumData.swift
Packages/PulsumData/Sources/PulsumData/PulsumManagedObjectModel.swift
Packages/PulsumData/Sources/PulsumData/Resources/Pulsum.xcdatamodeld/.xccurrentversion
Packages/PulsumData/Sources/PulsumData/Resources/Pulsum.xcdatamodeld/Pulsum.xcdatamodel/contents
Packages/PulsumData/Sources/PulsumData/Resources/PulsumCompiled.momd/Pulsum.mom
Packages/PulsumData/Sources/PulsumData/Resources/PulsumCompiled.momd/Pulsum.omo
Packages/PulsumData/Sources/PulsumData/Resources/PulsumCompiled.momd/VersionInfo.plist
Packages/PulsumData/Sources/PulsumData/VectorIndex.swift
Packages/PulsumData/Sources/PulsumData/VectorIndexManager.swift
Packages/PulsumData/Tests/PulsumDataTests/DataStackSecurityTests.swift
Packages/PulsumData/Tests/PulsumDataTests/Gate0_DataStackSecurityTests.swift
Packages/PulsumData/Tests/PulsumDataTests/Gate5_LibraryImporterAtomicityTests.swift
Packages/PulsumData/Tests/PulsumDataTests/Gate5_LibraryImporterPerfTests.swift
Packages/PulsumData/Tests/PulsumDataTests/Gate5_VectorIndexConcurrencyTests.swift
Packages/PulsumData/Tests/PulsumDataTests/Gate5_VectorIndexFileHandleTests.swift
Packages/PulsumData/Tests/PulsumDataTests/Gate5_VectorIndexManagerActorTests.swift
Packages/PulsumData/Tests/PulsumDataTests/LibraryImporterTests.swift
Packages/PulsumData/Tests/PulsumDataTests/PulsumDataBootstrapTests.swift
Packages/PulsumData/Tests/PulsumDataTests/Resources/podcasts_sample.json
Packages/PulsumData/Tests/PulsumDataTests/VectorIndexTests.swift
Packages/PulsumML/Package.swift
Packages/PulsumML/Sources/PulsumML/AFM/FoundationModelsAvailability.swift
Packages/PulsumML/Sources/PulsumML/AFM/FoundationModelsStub.swift
Packages/PulsumML/Sources/PulsumML/AFM/README_FoundationModels.md
Packages/PulsumML/Sources/PulsumML/BaselineMath.swift
Packages/PulsumML/Sources/PulsumML/Bundle+PulsumMLResources.swift
Packages/PulsumML/Sources/PulsumML/Embedding/AFMTextEmbeddingProvider.swift
Packages/PulsumML/Sources/PulsumML/Embedding/CoreMLEmbeddingFallbackProvider.swift
Packages/PulsumML/Sources/PulsumML/Embedding/EmbeddingError.swift
Packages/PulsumML/Sources/PulsumML/Embedding/EmbeddingService.swift
Packages/PulsumML/Sources/PulsumML/Embedding/TextEmbeddingProviding.swift
Packages/PulsumML/Sources/PulsumML/Placeholder.swift
Packages/PulsumML/Sources/PulsumML/PrivacyInfo.xcprivacy
Packages/PulsumML/Sources/PulsumML/RecRanker.swift
Packages/PulsumML/Sources/PulsumML/Resources/PulsumFallbackEmbedding.mlmodel
Packages/PulsumML/Sources/PulsumML/Resources/PulsumSentimentCoreML.mlmodel
Packages/PulsumML/Sources/PulsumML/Resources/README_CreateModel.md
Packages/PulsumML/Sources/PulsumML/Safety/FoundationModelsSafetyProvider.swift
Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift
Packages/PulsumML/Sources/PulsumML/Sentiment/AFMSentimentProvider.swift
Packages/PulsumML/Sources/PulsumML/Sentiment/CoreMLSentimentProvider.swift
Packages/PulsumML/Sources/PulsumML/Sentiment/FoundationModelsSentimentProvider.swift
Packages/PulsumML/Sources/PulsumML/Sentiment/NaturalLanguageSentimentProvider.swift
Packages/PulsumML/Sources/PulsumML/Sentiment/PIIRedactor.swift
Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentProviding.swift
Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentService.swift
Packages/PulsumML/Sources/PulsumML/StateEstimator.swift
Packages/PulsumML/Sources/PulsumML/TopicGate/EmbeddingTopicGateProvider.swift
Packages/PulsumML/Sources/PulsumML/TopicGate/FoundationModelsTopicGateProvider.swift
Packages/PulsumML/Sources/PulsumML/TopicGate/TopicGateProviding.swift
Packages/PulsumML/Tests/PulsumMLTests/EmbeddingServiceAvailabilityTests.swift
Packages/PulsumML/Tests/PulsumMLTests/EmbeddingServiceFallbackTests.swift
Packages/PulsumML/Tests/PulsumMLTests/Gate0_EmbeddingServiceFallbackTests.swift
Packages/PulsumML/Tests/PulsumMLTests/Gate6_EmbeddingProviderContextualTests.swift
Packages/PulsumML/Tests/PulsumMLTests/PackageEmbedTests.swift
Packages/PulsumML/Tests/PulsumMLTests/SafetyLocalTests.swift
Packages/PulsumML/Tests/PulsumMLTests/TopicGateMarginTests.swift
Packages/PulsumML/Tests/PulsumMLTests/TopicGateTests.swift
Packages/PulsumServices/Package.swift
Packages/PulsumServices/Sources/PulsumServices/BuildFlags.swift
Packages/PulsumServices/Sources/PulsumServices/Bundle+PulsumServicesResources.swift
Packages/PulsumServices/Sources/PulsumServices/CoachPhrasingSchema.swift
Packages/PulsumServices/Sources/PulsumServices/FoundationModelsCoachGenerator.swift
Packages/PulsumServices/Sources/PulsumServices/HealthKitAnchorStore.swift
Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift
Packages/PulsumServices/Sources/PulsumServices/KeychainService.swift
Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift
Packages/PulsumServices/Sources/PulsumServices/Placeholder.swift
Packages/PulsumServices/Sources/PulsumServices/PrivacyInfo.xcprivacy
Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift
Packages/PulsumServices/Tests/PulsumServicesTests/Gate0_LLMGatewayTests.swift
Packages/PulsumServices/Tests/PulsumServicesTests/Gate0_SpeechServiceAuthorizationTests.swift
Packages/PulsumServices/Tests/PulsumServicesTests/Gate0_SpeechServiceLoggingTests.swift
Packages/PulsumServices/Tests/PulsumServicesTests/Gate1_LLMGatewayUITestSeams.swift
Packages/PulsumServices/Tests/PulsumServicesTests/Gate1_SpeechFakeBackendTests.swift
Packages/PulsumServices/Tests/PulsumServicesTests/Gate2_ModernSpeechBackendTests.swift
Packages/PulsumServices/Tests/PulsumServicesTests/Gate4_LLMGatewayPingSeams.swift
Packages/PulsumServices/Tests/PulsumServicesTests/HealthKitAnchorStoreTests.swift
Packages/PulsumServices/Tests/PulsumServicesTests/KeychainServiceTests.swift
Packages/PulsumServices/Tests/PulsumServicesTests/LLMGatewaySchemaTests.swift
Packages/PulsumServices/Tests/PulsumServicesTests/LLMGatewayTests.swift
Packages/PulsumServices/Tests/PulsumServicesTests/PulsumServicesDependencyTests.swift
Packages/PulsumServices/Tests/PulsumServicesTests/SpeechServiceTests.swift
Packages/PulsumServices/Tests/Support/LLMURLProtocolStub.swift
Packages/PulsumTypes/Package.swift
Packages/PulsumTypes/Sources/PulsumTypes/DebugLog.swift
Packages/PulsumTypes/Sources/PulsumTypes/DiagnosticsLogger.swift
Packages/PulsumTypes/Sources/PulsumTypes/DiagnosticsReport.swift
Packages/PulsumTypes/Sources/PulsumTypes/DiagnosticsTypes.swift
Packages/PulsumTypes/Sources/PulsumTypes/Notifications.swift
Packages/PulsumTypes/Sources/PulsumTypes/SpeechTypes.swift
Packages/PulsumTypes/Tests/DiagnosticsLoggerTests.swift
Packages/PulsumUI/Package.swift
Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift
Packages/PulsumUI/Sources/PulsumUI/CoachView.swift
Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift
Packages/PulsumUI/Sources/PulsumUI/ConsentBannerView.swift
Packages/PulsumUI/Sources/PulsumUI/GlassEffect.swift
Packages/PulsumUI/Sources/PulsumUI/HealthAccessRequirement.swift
Packages/PulsumUI/Sources/PulsumUI/LiquidGlassComponents.swift
Packages/PulsumUI/Sources/PulsumUI/LiveWaveformLevels.swift
Packages/PulsumUI/Sources/PulsumUI/OnboardingView.swift
Packages/PulsumUI/Sources/PulsumUI/PrivacyInfo.xcprivacy
Packages/PulsumUI/Sources/PulsumUI/PulseView.swift
Packages/PulsumUI/Sources/PulsumUI/PulseViewModel.swift
Packages/PulsumUI/Sources/PulsumUI/PulsumDesignSystem.swift
Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift
Packages/PulsumUI/Sources/PulsumUI/SafetyCardView.swift
Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownView.swift
Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownViewModel.swift
Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift
Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift
Packages/PulsumUI/Tests/PulsumUITests/LiveWaveformBufferTests.swift
Packages/PulsumUI/Tests/PulsumUITests/PulsumRootViewTests.swift
Packages/PulsumUI/Tests/PulsumUITests/SettingsViewModelHealthAccessTests.swift
Pulsum.xcodeproj/project.pbxproj
Pulsum.xcodeproj/project.xcworkspace/contents.xcworkspacedata
Pulsum.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
Pulsum.xcodeproj/xcshareddata/xcschemes/Pulsum.xcscheme
Pulsum.xcodeproj/xcuserdata/martin.demel.xcuserdatad/xcschemes/xcschememanagement.plist
Pulsum/Assets.xcassets/AccentColor.colorset/Contents.json
Pulsum/Assets.xcassets/AppIcon.appiconset/Contents.json
Pulsum/Assets.xcassets/AppIcon.appiconset/iconnew 1.png
Pulsum/Assets.xcassets/AppIcon.appiconset/iconnew 2.png
Pulsum/Assets.xcassets/AppIcon.appiconset/iconnew.png
Pulsum/Assets.xcassets/Contents.json
Pulsum/PrivacyInfo.xcprivacy
Pulsum/Pulsum.entitlements
Pulsum/PulsumApp.swift
PulsumTests/PulsumTests.swift
PulsumUITests/FirstRunPermissionsUITests.swift
PulsumUITests/Gate3_HealthAccessUITests.swift
PulsumUITests/Gate4_CloudConsentUITests.swift
PulsumUITests/JournalFlowUITests.swift
PulsumUITests/PulsumUITestCase.swift
PulsumUITests/PulsumUITestsLaunchTests.swift
PulsumUITests/SettingsAndCoachUITests.swift
README.md
a-practical-guide-to-building-agents.pdf
agents.md
architecture.md
architecture_short.md
audit_gate_0_and_1.md
bugs.md
bugsplan.md
calculations.md
coderabit.md
codex_inventory.json
core/pulsum/review.md
core/pulsum/status.md
coverage_ledger.json
files.zlist
gate2_summary.md
gate3_summary.md
gate4_summary.md
gate5_summary.md
gate6_analysis.md
gate6_summary.md
gates.md
gates_learnings.md
geminibugs.md
github_cheat_sheet.md
github_master_gate.md
gpt5_1_prompt_guide.md
iconlogo.png
iconnew.png
infinity_blubs_copy.splineswift
instructions.md
inventory.json
ios app mockup.png
ios support documents/Adding intelligent app features with generative models _ Apple Developer Documentation.pdf
ios support documents/Adopting Liquid Glass _ Apple Developer Documentation.pdf
ios support documents/Foundation Models _ Apple Developer Documentation.pdf
ios support documents/Generating content and performing tasks with Foundation Models _ Apple Developer Documentation.pdf
ios support documents/Improving the safety of generative model output _ Apple Developer Documentation.pdf
ios support documents/Landmarks_ Applying a background extension effect _ Apple Developer Documentation.pdf
ios support documents/Landmarks_ Building an app with Liquid Glass _ Apple Developer Documentation.pdf
ios support documents/Landmarks_ Displaying custom activity badges _ Apple Developer Documentation.pdf
ios support documents/Landmarks_ Extending horizontal scrolling under a sidebar or inspector _ Apple Developer Documentation.pdf
ios support documents/Landmarks_ Refining the system provided Liquid Glass effect in toolbars _ Apple Developer Documentation.pdf
ios support documents/Liquid Glass _ Apple Developer Documentation.pdf
ios support documents/Support languages and locales with Foundation Models _ Apple Developer Documentation.pdf
ios support documents/SystemLanguageModel _ Apple Developer Documentation.pdf
ios support documents/aGenerating content and performing tasks with Foundation Models _ Apple Developer Documentation.pdf
ios support documents/iOS & iPadOS 26 Release Notes _ Apple Developer Documentation.pdf
ios support files/glow.swift
liquidglass.md
logo.jpg
logo2.png
main.gif
mainanimation.usdz
openai_summary_chat_gate4.md
podcastrecommendations 2.json
review_calculation_summary.md
scripts/ci/build-release.sh
scripts/ci/check-privacy-manifests.sh
scripts/ci/integrity.sh
scripts/ci/scan-placeholders.sh
scripts/ci/scan-secrets.sh
scripts/ci/test-harness.sh
scripts/ci/ui-tests.sh
sha256.txt
streak_low_poly_copy.splineswift
terminal_1.md
terminal_new.md
testfile
tests_automation.md
todolist.md
```

## Progress Notes (Completion Log)
- 2025-11-11: Task 1 completed. Created baseline_progress.md.
- 2025-11-11: Task 2 completed. Tracked file list recorded (269 files).
- 2025-11-11: Task 3 completed. Wrote baseline_file_inventory.json with per-file metadata. Category counts: swift 155, tests 68, markdown 40, binary_assets 35, plist/xcprivacy 8, json 8, shell 7, yaml 4, no_ext 4, config 1, text 1, other 6.
- 2025-11-11: Task 4 completed. baseline.md created with full appendix (269 entries) from baseline_appendix.md.
- 2025-11-11: Tasks 5-33 completed in baseline.md (build, entry points, architecture, pipelines, tests, risks).
- 2025-11-11: Task 34 completed. Identified architecture.md mismatches for update.
- 2025-11-11: Task 35 completed. architecture.md updated with ModernSpeechBackend stub note and xcconfig clarification.
- 2025-11-11: Task 36 completed. baseline.md reviewed for TOC, coherence, and appendix presence.
