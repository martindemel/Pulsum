# DataAgent.swift Summary

## Purpose
DataAgent is an `actor` that orchestrates HealthKit ingestion, Core Data feature-vector storage, and wellbeing score computation. It manages authorization state, background observation, staged bootstrapping, and backfill to ensure a usable first score quickly while progressively filling historical data.

## Key Types
- `FeatureVectorSnapshot`: Lightweight snapshot of a computed wellbeing score, feature values, contributions, imputed flags, and Core Data object ID.
- `ScoreBreakdown`: Detailed per-metric explanation for a day, including baselines, z-scores, coverage, and narrative notes.
- `SnapshotPlaceholder`: Marks synthetic placeholder snapshots (used when real data is unavailable) via a special imputed flag.
- `DataAgentBootstrapPolicy`: Configures timeouts, retry timing, and placeholder deadlines for the bootstrap pipeline.

## Core Responsibilities
- **Authorization/availability**: Determines HealthKit availability, probes read access, caches results briefly, and logs status.
- **Observation lifecycle**: Enables background delivery, starts observers for granted types, and tears down/revokes observers when permissions change.
- **Bootstrapping**: Performs a short-window (2-day) ingest for a fast first score, with timeouts per type and a watchdog that injects placeholders if no snapshot is produced.
- **Backfill**:
  - Warm start: 7-day backfill for granted types.
  - Full window: 30-day backfill executed in background batches, tracked in `BackfillProgress`.
- **Resilience**: Retries bootstrap failures with exponential backoff; ignores specific entitlement-related background delivery errors.
- **Snapshot access**: Returns latest feature vector (with/without placeholders) and provides a full `ScoreBreakdown` with baselines and coverage.

## Data Flow Highlights
1. `start()` or `requestHealthAccess()` refreshes status, schedules watchdog, runs bootstrap, configures observers, and schedules backfill.
2. Bootstrapping fetches per-type samples (steps, heart rate, generic samples), processes them into features, and publishes a snapshot update.
3. If no real snapshot exists, creates a placeholder snapshot so the UI can render.
4. Backfill continues in the background until the full 30-day window is covered.

## Notable Behaviors
- Uses a background Core Data context named `Pulsum.DataAgent` with merge-by-property-object-trump.
- Avoids prompting on startup; requests authorization only on explicit call.
- Treats read access via probes instead of `authorizationStatus(for:)` (write-only signal).
- Logs detailed diagnostics spans and metrics for bootstrap/backfill phases.

## Key Constants
- Warm start window: 7 days
- Full analysis window: 30 days
- Bootstrap window: 2 days
- Placeholder deadline: 5 seconds (default)
- Backfill batch size: 5 days

## File Location
`Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`
