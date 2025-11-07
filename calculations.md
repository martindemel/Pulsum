# Pulsum Scoring Calculations

This document captures how Pulsum derives every score that surfaces in the app today. It covers the raw signal preparation, normalization, model weighting, and storage pathways for:

1. Objective health metrics (Heart Rate Variability, Nocturnal HR, Resting HR, Sleep Debt, Respiratory Rate, Steps)
2. Subjective pulse inputs (Stress, Energy, Sleep Quality)
3. Voice journal sentiment
4. The aggregate wellbeing score and its per-feature contributions

All of the logic described below is implemented in `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`, `Packages/PulsumML/Sources/PulsumML/StateEstimator.swift`, and the supporting sentiment services in `Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift` and `Packages/PulsumML/Sources/PulsumML/Sentiment/*`.

---

## Data Flow Overview

1. **HealthKit ingestion** — `DataAgent` listens to anchored/observer queries for HRV, heart rate, respiratory rate, sleep analysis, and step count. Samples are accumulated as `DailyFlags` in Core Data and reprocessed whenever new data arrives.
2. **Daily summary** — When a day is reprocessed, `DataAgent.computeSummary` condenses raw samples into daily aggregates (median HRV, 10th percentile nocturnal HR, etc.) and tracks imputation flags when measurements are missing or low-confidence.
3. **Baselines & z-scores** — Robust rolling baselines (median & MAD) are computed over a 30-day window (`BaselineMath`). Objective metrics are expressed as z-scores relative to these baselines. Sleep debt uses a 7-day window.
4. **Feature vector** — For each calendar day, `FeatureVector` stores normalized objective metrics (z-scores), raw subjective slider values, and journal sentiment. Missing values default to `0` and are marked using imputation flags.
5. **State estimator** — The wellbeing score is the linear combination of feature values and learned weights plus a bias term. The same estimator tracks per-feature contributions for UI breakdowns. Weights are updated online via stochastic gradient descent.
6. **Score breakdown** — `ScoreBreakdown` surfaces the latest wellbeing score, per-metric values, z-scores, baselines, and imputation notes for Settings → Insights.

---

## Objective Metrics

All objective metrics are stored as z-scores (`z_*` keys). A z-score is computed as `(value - median) / MAD`, where median and MAD (median absolute deviation) come from the rolling baseline of prior days (`BaselineMath.robustStats`). Missing data is imputed from previous days when possible and flagged for display.

### Heart Rate Variability (`z_hrv`)
- **Raw signal:** Median SDNN (milliseconds) from HRV quantity samples that fall within sleep intervals. Sleep windows are derived from HealthKit sleep analysis segments where `stage.isAsleep` is true (`DailyFlags.sleepSegments`).
- **Fallbacks:** If no sleep-window samples are present, the algorithm looks at sedentary windows (≤30 steps/hour, ≥30 minutes) outside of sleep. If still empty, it reuses the most recent reliable HRV value and marks the metric as imputed (`imputed["hrv"] = true`).
- **Normalization:** Z-score against a 30-day baseline of historical HRV medians.

### Nocturnal Heart Rate (`z_nocthr`)
- **Raw signal:** 10th percentile of heart rate samples captured during sleep intervals. This highlights the lowest overnight heart rate.
- **Fallbacks:** Same hierarchy as HRV—sedentary windows, then previous day — with `imputed["nocturnalHR"]` flagged on fallback.
- **Normalization:** Z-score vs. 30-day nocturnal HR baseline.

### Resting Heart Rate (`z_resthr`)
- **Raw signal:** Latest heart rate sample tagged with `Context.resting`; if absent, average heart rate over sedentary windows.
- **Fallbacks:** Previous resting value if none are available (`imputed["restingHR"]`).
- **Normalization:** Z-score vs. 30-day resting HR baseline.

### Sleep Debt (`z_sleepDebt`)
- **Personal sleep need:** A rolling estimate of required sleep. Uses the average of the last up to 30 nights (`analysisWindowDays = 30`) bounded to `defaultNeed ± 0.75` hours (default need = 7.5h).
- **Daily sleep:** Sum of detected sleep-segment durations for the night. Less than 3 hours triggers a low-confidence flag (`imputed["sleep_low_confidence"]`).
- **Debt calculation:** For the past 7 days (`sleepDebtWindowDays = 7`), sum `max(0, personalNeed - actualHours)`.
- **Normalization:** Z-score against the 7-day rolling baseline of historical sleep debt hours.

### Respiratory Rate (`z_rr`)
- **Raw signal:** Mean breaths-per-minute from respiratory samples during sleep intervals. If intervals are empty, the metric is missing and flagged (`imputed["rr_missing"]`).
- **Normalization:** Z-score vs. 30-day respiratory rate baseline.

### Steps (`z_steps`)
- **Raw signal:** Total step count for the calendar day, aggregated from `StepBucket` samples.
- **Confidence flags:** Under 500 steps generates `imputed["steps_low_confidence"]`; missing data triggers `imputed["steps_missing"]`.
- **Normalization:** Z-score vs. 30-day steps baseline.

Each objective metric contributes to the wellbeing score through learned weights (see “Wellbeing Score” below). Even when a z-score is zero (due to missing data), imputation flags surface the data gap in the breakdown UI.

---

## Subjective Pulse Inputs

Subjective scores are collected via the Pulse check-in sliders (see `PulseViewModel.submitInputs`):

- **Stress (`subj_stress`)** — Integer 1–7 (1 = “very calm”, 7 = “overwhelmed”). Stored without normalization.
- **Energy (`subj_energy`)** — Integer 1–7 (1 = “depleted”, 7 = “fully charged”).
- **Sleep Quality (`subj_sleepQuality`)** — Integer 1–7 describing perceived restfulness.

`DataAgent.recordSubjectiveInputs` writes these values directly into the day’s `FeatureVector`. During reprocessing, they are copied into the feature bundle unchanged. Because they are raw scores, the state estimator learns weights that scale them appropriately. Imputation is not applied; missing subjective inputs default to `0` until the user submits a pulse check for the day.

---

## Voice Journal Sentiment

Voice journals (and imported transcripts) are processed by `SentimentAgent`:

1. Audio is transcribed on-device; text is sanitized (`PIIRedactor.redact`).
2. `SentimentService.sentiment(for:)` evaluates the text using a provider stack:
   - `FoundationModelsSentimentProvider` (when iOS 26 Apple Intelligence APIs are available)
   - `AFMSentimentProvider` (on-device Apple Foundation Model fallback)
   - `CoreMLSentimentProvider` (384-d Core ML model fallback)
3. Each provider returns a score in `[-1, 1]`. The first successful provider wins; errors or insufficient input move to the next provider. Empty transcripts default to `0`.
4. The score is clipped to [-1, 1] and stored in:
   - `JournalEntry.sentiment`
   - `FeatureVector.sentiment`

This sentiment value appears as the “Journal Sentiment” card in the score breakdown (kind `.sentiment`). It currently feeds the state estimator with a default weight of `0`, but the architecture allows future training to incorporate it.

---

## Wellbeing Score Computation

### Feature Vector
The feature bundle used for wellbeing prediction contains:
```
{
  "z_hrv", "z_nocthr", "z_resthr", "z_sleepDebt",
  "z_rr", "z_steps", "subj_stress", "subj_energy",
  "subj_sleepQuality", "sentiment"
}
```
Missing entries are filled with `0`. Imputation flags accompany the feature vector to explain gaps in the UI.

### Linear Model
`StateEstimator` maintains a weight per feature plus a scalar bias. Initial weights (when no learning has occurred) are:
```
 z_hrv: -0.6      z_nocthr: 0.5      z_resthr: 0.4
 z_sleepDebt: 0.5 z_steps: -0.2      z_rr: 0.1
 subj_stress: 0.6 subj_energy: -0.6  subj_sleepQuality: 0.4
 sentiment: 0      bias: 0
```
The predicted wellbeing score is:
```
wellbeing = bias + Σ(weight_i × feature_i)
```
`StateEstimator.contributionVector` exposes each `weight_i × feature_i` term so the UI can report “lifts” and “drags”.

### Online Weight Updates
Whenever a day is reprocessed, the estimator updates weights using stochastic gradient descent toward a handcrafted target score:
```
target = (-0.35 * z_hrv)
        + (-0.25 * z_steps)
        + (-0.40 * z_sleepDebt)
        + ( 0.45 * subj_stress)
        + (-0.40 * subj_energy)
        + ( 0.30 * subj_sleepQuality)
```
Notes:
- The target uses a subset of features; others (nocturnal/resting HR, respiratory rate, sentiment) learn indirectly through gradient updates if they correlate with the target.
- Learning rate = 0.05, L2 regularization = 1e-3, and weights are capped to [-2, 2].
- After each update, the estimator records the new wellbeing score and per-feature contributions in the `FeatureVector` metadata (`imputedFlags` JSON payload) for downstream use.

### Score Breakdown UI
`DataAgent.scoreBreakdown()` combines the latest `FeatureVectorSnapshot` with raw daily metrics and baselines to produce `ScoreBreakdown`:
- Objective metrics report raw value (where available), z-score, contribution, and baseline stats.
- Subjective metrics report the raw 1–7 value and contribution (z-score is nil).
- Sentiment reports the -1…1 value.
- `generalNotes` include any residual imputation messages not tied to specific metrics.

---

## Summary Table

| Feature | Input Range | Normalization | Stored Key | Weight Impact (initial) |
| --- | --- | --- | --- | --- |
| Heart Rate Variability | ms | z-score (30-day median/MAD) | `z_hrv` | -0.6 × z_hrv |
| Nocturnal Heart Rate | bpm | z-score (30-day) | `z_nocthr` | +0.5 × z_nocthr |
| Resting Heart Rate | bpm | z-score (30-day) | `z_resthr` | +0.4 × z_resthr |
| Sleep Debt | hours | z-score (7-day) | `z_sleepDebt` | +0.5 × z_sleepDebt |
| Respiratory Rate | breaths/min | z-score (30-day) | `z_rr` | +0.1 × z_rr |
| Steps | count | z-score (30-day) | `z_steps` | -0.2 × z_steps |
| Stress | 1–7 | none | `subj_stress` | +0.6 × stress |
| Energy | 1–7 | none | `subj_energy` | -0.6 × energy |
| Sleep Quality | 1–7 | none | `subj_sleepQuality` | +0.4 × quality |
| Journal Sentiment | -1…1 | none | `sentiment` | 0 (until the model learns a weight) |

---

## Key Implementation Files

- `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`
  - HealthKit ingestion (`start`, `processQuantitySamples`, `computeSummary`)
  - Baseline calculations and feature bundle assembly
  - Target computation and state estimator updates
  - Score breakdown generation and imputation messaging
- `Packages/PulsumML/Sources/PulsumML/StateEstimator.swift`
  - Linear wellbeing model, SGD updates, contribution reporting
- `Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift`
  - Journal capture, PIIRedaction, sentiment score persistence
- `Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentService.swift`
  - Provider stack for sentiment scoring (Foundation Models → AFM → Core ML)
- `Packages/PulsumML/Sources/PulsumML/BaselineMath.swift`
  - Robust statistics utils (median, MAD, EWMA) used across objective metrics

This documentation reflects the current implementation in the repository as of commit `1ceeac6`.
