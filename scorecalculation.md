# Score Calculation Audit (Pulsum)

## Scope
- Focused on score computation, HealthKit ingestion, and sentiment/check-in input pipelines.
- Code paths reviewed across PulsumAgents, PulsumServices, PulsumML, PulsumData, and PulsumUI.

## Score Computation Flow (High-Level)
1. HealthKit data arrives via anchored/observer queries.
2. DailyMetrics and DailyFlags aggregate raw samples per day.
3. Baselines are computed (median + MAD) and objective metrics become z-scores.
4. FeatureVector stores z-scores, subjective check-in values, and sentiment.
5. StateEstimator produces a wellbeing score and per-feature contributions.
6. UI reads the latest snapshot to show cards and breakdowns.

## File Inventory (Scoring-Related)

### Core Computation + Storage
- `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`
  - Aggregates HealthKit samples, computes daily summaries, baselines, feature vectors, and wellbeing score.
- `Packages/PulsumML/Sources/PulsumML/StateEstimator.swift`
  - Linear model (weights + bias) that produces score and contributions.
- `Packages/PulsumML/Sources/PulsumML/BaselineMath.swift`
  - Robust statistics for baseline median/MAD and EWMA.
- `Packages/PulsumData/Sources/PulsumData/Model/ManagedObjects.swift`
  - Core Data schema for DailyMetrics, FeatureVector, Baseline, JournalEntry.
- `Packages/PulsumAgents/Sources/PulsumAgents/EstimatorStateStore.swift`
  - Persists learned estimator weights/bias.
- `Packages/PulsumAgents/Sources/PulsumAgents/WellbeingScoreState.swift`
  - UI state model for loading/ready/noData/error.

### HealthKit Loading + Ingestion
- `Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift`
  - HealthKit queries, observers, background delivery, and sample fetching.
- `Packages/PulsumServices/Sources/PulsumServices/HealthKitAnchorStore.swift`
  - Persists HealthKit anchors for resumable ingestion.
- `Packages/PulsumAgents/Sources/PulsumAgents/BackfillStateStore.swift`
  - Tracks warm start + full backfill progress.
- `Packages/PulsumUI/Sources/PulsumUI/HealthAccessRequirement.swift`
  - Lists required HealthKit types for UI.
- `Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift`
  - Requests HealthKit access, surfaces authorization state.
- `Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift`
  - Wires `.pulsumScoresUpdated` notification to refresh recommendations.

### Subjective Check-In Input
- `Packages/PulsumUI/Sources/PulsumUI/PulseView.swift`
  - Slider UI for stress/energy/sleep quality.
- `Packages/PulsumUI/Sources/PulsumUI/PulseViewModel.swift`
  - Calls orchestrator to persist subjective inputs.
- `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`
  - `updateSubjectiveInputs` to DataAgent.
- `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`
  - `recordSubjectiveInputs` writes to FeatureVector and reprocesses.

### Voice Journal + Sentiment Input
- `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift`
  - On-device speech capture and streaming transcription.
- `Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift`
  - Persists journal entries and writes sentiment into FeatureVector.
- `Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentService.swift`
  - Sentiment provider stack (Foundation Models -> AFM -> Core ML).
- `Packages/PulsumML/Sources/PulsumML/Sentiment/*Provider.swift`
  - Per-provider sentiment implementations.
- `Packages/PulsumML/Sources/PulsumML/Sentiment/PIIRedactor.swift`
  - Redacts PII before sentiment analysis.

### Score Display / UI
- `Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift`
  - Reads wellbeing score/state for the main UI.
- `Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift`
  - Wellbeing score card on main screen.
- `Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift`
  - Wellbeing score card + breakdown navigation.
- `Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownViewModel.swift`
  - Fetches ScoreBreakdown from orchestrator.
- `Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownView.swift`
  - Renders objective/subjective/sentiment metrics.
- `Packages/PulsumTypes/Sources/PulsumTypes/Notifications.swift`
  - `.pulsumScoresUpdated` notification.

### Docs / Reference
- `calculations.md`
- `review_calculation_summary.md`
- `bugs.md`

## Findings and Potential Problems

1. Subjective check-in values default to 0 even when no check-in happened.
   - `DataAgent.buildFeatureBundle` fills any missing keys with 0, including `subj_*` and `sentiment`. (`Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:2672`, `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:2703`)
   - `DataAgent.apply` persists those 0 values to Core Data. (`Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:2710`)
   - `ScoreBreakdown` always uses the feature values for subjective and sentiment metrics, so UI renders "0" instead of "No data today." (`Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:3102`, `Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownView.swift:214`)
   - Impact: This directly explains the reported issue (check-in shows 0 when no check-in occurred). It also affects the wellbeing score because 0 is treated as a real value.

2. Missing subjective/sentiment inputs are not flagged as imputed.
   - Imputation logic only handles objective metrics. (`Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:3260`)
   - There are no `subj_*_missing` or `sentiment_missing` flags, so the system cannot distinguish "no check-in / no journal" from valid neutral values.
   - Impact: Subjective and sentiment sections can look populated even when no user input exists.

3. The wellbeing score can appear "ready" with zeroed features.
   - Any non-placeholder FeatureVector yields a `.ready` state in recommendations. (`Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:443`)
   - If a FeatureVector exists (e.g., created during reprocess) but has zeros for many features, the UI can show a score even with missing data.
   - Impact: Users may see a score with no HealthKit data or check-in contribution, which can look like "0 by default."

4. Sentiment fallback is indistinguishable from neutral sentiment.
   - `SentimentService` returns `0` for empty input or provider errors. (`Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentService.swift:23`)
   - Combined with the default 0 fill in `DataAgent.buildFeatureBundle`, the UI can show "Journal Sentiment = 0" even when no journal exists or analysis failed.
   - Impact: The sentiment metric can appear valid when it is actually missing.

5. Score breakdown contributions may not align with displayed z-scores.
   - Contributions are computed from normalized and imputation-adjusted features. (`Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:3228`)
   - `ScoreBreakdown` shows raw z-scores (pre-clamp and pre-imputation adjustment). (`Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:3023`)
   - Impact: Users can see a z-score that does not correspond to the contribution magnitude.

6. Subjective inputs are not range-validated before being stored.
   - `recordSubjectiveInputs` writes raw Doubles without clamping. (`Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:2114`)
   - UI sliders are constrained to 1-7, but any external caller can write out-of-range values.
   - Impact: If invalid values are persisted (tests, future features, imports), the score can skew.

7. Documentation drift: `calculations.md` does not match the current implementation.
   - `calculations.md` lists default weights and target logic that differ from actual code. (`calculations.md`)
   - Actual defaults are in `StateEstimator.defaultWeights`. (`Packages/PulsumML/Sources/PulsumML/StateEstimator.swift:36`)
   - Target weights used for learning are in `WellbeingModeling.targetWeights`. (`Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:3214`)
   - Impact: Anyone debugging based on `calculations.md` will get misleading conclusions.

8. Known scoring-related issues listed in `bugs.md` to re-verify.
   - BUG-20251026-0005, 0015, 0024, 0028, 0038, 0039, 0040 reference scoring and HealthKit ingestion flows. (`bugs.md`)
   - Some appear addressed in current code (e.g., journal reprocess and refresh notifications), but they should be validated against the actual runtime behavior.

## Direct Root Cause for the Reported "Check-In = 0" Behavior
- Subjective and sentiment features default to 0 when missing (DataAgent fills required keys with 0). (`Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:2703`)
- UI only shows "No data today" when the value is nil, not when it is zero. (`Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownView.swift:214`)
- Result: The app displays "0" for check-in metrics even if the user never performed a check-in.
