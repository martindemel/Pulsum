# Gemini 3 Technical Audit (`geminibugs.md`)

## 1. Architecture Consistency Check
- **Status:** Critical Deviations
- **Analysis:** The codebase generally follows the modular architecture defined in `architecture.md` with clear separation of Agents, Services, and Data. However, key "Modern" features relying on iOS 26+ are implemented as stubs or disabled, violating the functional promise of the architecture.
- **Violations:**
  - **SpeechService.swift**: The `ModernSpeechBackend` class exists but its `startRecording` method explicitly calls `fallback.startRecording`, bypassing any new Apple Intelligence Speech APIs.
  - **AFMTextEmbeddingProvider.swift**: The primary "Contextual Embedding" feature is commented out due to "unsafe runtime code", falling back to legacy `NLEmbedding` (word-based).
  - **DataAgent.swift**: The `StateEstimator` (Personalization Engine) is initialized fresh on every actor startup. It lacks any mechanism to load valid weights from `CoreData`, meaning it never "learns" across sessions as described in the design.

## 2. Score Calculation Logic Audit
- **Mathematical Integrity:** Fail
- **Formula Analysis:**
  - `DataAgent.computeTarget` calculates the daily wellbeing target label:
    `target = (-0.35 * hrv) + (-0.25 * steps) + (-0.4 * sleepDebt) + (0.45 * stress) + (-0.4 * energy) + (0.3 * sleepQuality)`
  - `StateEstimator.update` performs Online Ridge Regression (LMS gradient descent) to update weights based on this target.
- **Detected Errors:**
  - **Inverted Logic**: High HRV (Heart Rate Variability) and high Steps are universally considered positive for wellbeing. The formula multiplies them by negative coefficients (`-0.35`, `-0.25`), causing good health metrics to *lower* the wellbeing score.
  - **Missing Signal**: The `sentiment` feature from voice journals is extracted in `materializeFeatures` but is **completely absent** from the `computeTarget` formula and `StateEstimator` initial weights. Voice journals effectively have zero impact on the Wellbeing Score.
  - **Zero Persistence**: `StateEstimator` weights are stored only in RAM. Restarting the app resets `weights` to hardcoded defaults, erasing all personalization.
- **Optimization:**
  ```swift
  // Corrected computeTarget in DataAgent.swift
  private func computeTarget(using features: [String: Double]) -> Double {
      let stress = features["subj_stress"] ?? 0
      let energy = features["subj_energy"] ?? 0
      let sleepQuality = features["subj_sleepQuality"] ?? 0
      let sleepDebt = features["z_sleepDebt"] ?? 0
      let hrv = features["z_hrv"] ?? 0
      let steps = features["z_steps"] ?? 0
      let sentiment = features["sentiment"] ?? 0 // Added sentiment

      // Invert signs for HRV and Steps to be positive contributors
      return (0.35 * hrv) + (0.25 * steps) + (-0.4 * sleepDebt) +
             (0.45 * stress) + (-0.4 * energy) + (0.3 * sleepQuality) +
             (0.3 * sentiment) // Weighted sentiment inclusion
  }
  ```

## 3. Critical Blocking Issues & Bugs
- **Crash Risks:**
  - **EmbeddingService Silent Failure**: `embedding(for:)` returns `[0, 0, ...]` (Zero Vector) when providers fail. This doesn't crash but corrupts vector search, causing `VectorIndex` to return garbage matches with 0 distance, effectively "crashing" the logic of the recommendation engine.
- **UI/Integration Issues:**
  - **LibraryImporter Blocking I/O**: `ingestIfNeeded` reads file data (`Data(contentsOf: url)`) inside `context.perform`. This blocks the `Pulsum.LibraryImporter` background queue. While not the main thread, it halts all database write operations for that context during import.
  - **AppViewModel Startup Race**: `start()` spawns a detached `Task` without tracking it. Calling `retryStartup()` spawns a second concurrent orchestrator, leading to race conditions on HealthKit observers and indeterminate state.
- **Root Cause of `bugs.md` items:**
  - **BUG-20251026-0012 (VectorIndex Locking)**: *Analysis of current code shows this is fixed.* `shard(forShardIndex:)` uses `queue.sync(flags: .barrier)` for the entire lookup-and-create operation. It is thread-safe but potentially slow (serialized readers). The "Open" status in `bugs.md` seems outdated relative to the file content.
  - **BUG-20251026-0032 (PulseView Waveform)**: *Analysis of current code shows this is fixed.* `PulseViewModel` now uses `LiveWaveformLevels` (ring buffer), avoiding the massive array copy per frame.

## 4. Refactoring Recommendations

**A. Fix LibraryImporter Blocking I/O**
Move file reading outside the Core Data context block.

```swift
// Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift

public func ingestIfNeeded() async throws {
    // ... (setup code)
    
    let urlsCopy = urls
    // 1. Read data concurrently/asynchronously outside the lock
    let filePayloads: [(String, Data)] = try await withThrowingTaskGroup(of: (String, Data).self) { group in
        for url in urlsCopy {
            group.addTask {
                let data = try Data(contentsOf: url)
                return (url.lastPathComponent, data)
            }
        }
        var results: [(String, Data)] = []
        for try await result in group { results.append(result) }
        return results
    }

    // 2. Perform DB operations
    try await context.perform {
        for (filename, data) in filePayloads {
            try self.processFile(data: data, filename: filename, context: context)
        }
        if context.hasChanges { try context.save() }
    }
}
```

**B. Persist StateEstimator Weights**
Add saving/loading to `StateEstimator` and `DataAgent`.

```swift
// Packages/PulsumML/Sources/PulsumML/StateEstimator.swift

// Add Codable conformance to snapshot or custom serialization
public func weightsData() -> Data? {
    try? JSONEncoder().encode(weights)
}

public func loadWeights(from data: Data) {
    if let loaded = try? JSONDecoder().decode([String: Double].self, from: data) {
        self.weights = loaded
    }
}
```

```swift
// Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift

// In init or start():
if let data = try? Data(contentsOf: persistenceURL) {
    stateEstimator.loadWeights(from: data)
}

// In reprocessDayInternal (after update):
if let data = stateEstimator.weightsData() {
    try? data.write(to: persistenceURL)
}
```


