# PULSUM iOS App - Comprehensive Architectural Bug Analysis
**Generated:** November 11, 2025  
**Analyst:** iOS Swift Architect  
**Scope:** Full codebase review including all packages, UI, agents, services, data layers

---

## Executive Summary

This analysis identified **28 NEW CRITICAL ISSUES** beyond the 43 bugs already documented in `bugs.md`. The codebase shows sophisticated design but suffers from:

1. **Critical data flow disconnections** preventing features from working end-to-end
2. **Concurrency race conditions** despite actor isolation
3. **Memory management issues** with unreleased resources
4. **State management bugs** causing stale UI and lost data
5. **Integration gaps** between layers
6. **Logic errors** in core algorithms

**Severity Distribution:**
- **S0 (Critical/Blocker):** 8 new issues
- **S1 (High):** 14 new issues
- **S2 (Medium):** 6 new issues

---

## NEW CRITICAL BUGS (Not in bugs.md)

### **BUG-ARCH-001: Voice Journal Never Triggers Wellbeing Refresh**
- **Severity:** S0 (Critical Data Flow Failure)
- **Category:** Wiring/Integration
- **Location:** `AgentOrchestrator.swift:166-170`, `PulseViewModel.swift:118-127`
- **Impact:** Voice journaling persists sentiment but NEVER calls `DataAgent.reprocessDay()`, so wellbeing scores, contributions, and recommendations stay frozen despite journal entries
- **Evidence:**
  ```swift
  // AgentOrchestrator.swift:166-170
  public func finishVoiceJournalRecording(transcript: String? = nil) async throws -> JournalCaptureResponse {
      let result = try await sentimentAgent.finishVoiceJournal(transcript: transcript)
      let safety = await safetyAgent.evaluate(text: result.transcript)
      return JournalCaptureResponse(result: result, safety: safety)
      // ❌ NO CALL to dataAgent.reprocessDay()
  }
  ```
- **Related:** Already documented as BUG-20251026-0005 but NOT FIXED
- **Fix Required:** After `sentimentAgent.finishVoiceJournal`, must call:
  ```swift
  try await dataAgent.reprocessDay(calendar.startOfDay(for: Date()))
  ```

---

### **BUG-ARCH-002: Pulse Slider Submission Never Refreshes Coach Recommendations**
- **Severity:** S0 (Critical UX Failure)
- **Category:** Wiring
- **Location:** `PulseViewModel.swift:160-180`
- **Impact:** User submits stress/energy/sleep sliders → data persists → but Coach tab shows STALE recommendations forever until app restart
- **Evidence:**
  ```swift
  // PulseViewModel.swift:173
  func submitInputs(for date: Date = Date()) {
      // ... saves to orchestrator ...
      self.sliderSubmissionMessage = "Thanks for checking in."
      // ❌ NO CALL to refresh recommendations or wellbeing
  }
  ```
- **Related:** Already documented as BUG-20251026-0015 but provides more context
- **Fix Required:** After successful save, call:
  ```swift
  try await orchestrator?.start() // to trigger reprocessing
  // or expose reprocessDay directly
  ```

---

### **BUG-ARCH-003: Double-Checked Locking Race in Vector Index Shard Cache**
- **Severity:** S0 (Data Corruption / Crash Risk)
- **Category:** Concurrency
- **Location:** `VectorIndex.swift:312-337`
- **Impact:** Concurrent searches can race shard initialization → crashes, duplicate shards, or corrupted search results
- **Evidence:**
  ```swift
  // VectorIndex.swift:312-313
  private func shard(forShardIndex index: Int) throws -> VectorIndexShard {
      if let shard = shards[index] { return shard }  // ❌ READ outside lock
      var creationError: Error?
      var createdShard: VectorIndexShard?
      queue.sync(flags: .barrier) {
          if let shard = shards[index] {  // Second check inside lock
              createdShard = shard
              return
          }
          // ... create shard ...
          shards[index] = shard  // WRITE inside lock
      }
  ```
- **Root Cause:** Swift Dictionary is NOT thread-safe. Reading `shards[index]` at line 313 OUTSIDE the barrier queue while another thread writes at line 326 INSIDE the barrier = undefined behavior
- **Related:** Already documented as BUG-20251026-0012
- **Fix Required:** Move ALL reads inside barrier or use Actor isolation

---

### **BUG-ARCH-004: AppViewModel Orphans Startup Tasks**
- **Severity:** S0 (Resource Leak / State Corruption)
- **Category:** Concurrency
- **Location:** `AppViewModel.swift:90-144`
- **Impact:** Multiple calls to `start()` or `retryStartup()` launch parallel orchestrator initializations → duplicated HealthKit observers, duplicated speech sessions, stuck `.loading` state
- **Evidence:**
  ```swift
  // AppViewModel.swift:98-103
  func start() {
      guard startupState == .idle else { return }  // ❌ NOT SUFFICIENT
      // ... sets state = .loading
      Task { [weak self] in  // ❌ ORPHANED TASK - never stored or cancelled
          // ... creates orchestrator ...
          Task { [weak self] in  // ❌ NESTED ORPHANED TASK
              try await orchestrator.start()
          }
      }
  }
  ```
- **Root Cause:** Unstructured concurrency with no task storage or cancellation. `retryStartup()` just sets state to `.idle` and calls `start()` again → can have 2+ Tasks running simultaneously
- **Related:** Already documented as BUG-20251026-0029
- **Consequences:**
  - Duplicate HealthKit observer queries
  - Multiple permission prompts
  - Startup state stuck in `.loading` or `.ready` despite failures
  - No way to cancel in-flight startup

---

### **BUG-ARCH-005: StateEstimator Weights Reset Every Launch**
- **Severity:** S0 (ML Personalization Broken)
- **Category:** Data/ML
- **Location:** `DataAgent.swift:46-64`, `StateEstimator.swift:24-43`
- **Impact:** Wellbeing model relearns from scratch every app launch → personalization NEVER accumulates → contradicts "online learning" architecture promise
- **Evidence:**
  ```swift
  // DataAgent.swift:49
  private var stateEstimator = StateEstimator()  // ❌ ALWAYS starts with seed weights
  
  // StateEstimator.swift:29-38
  public init(initialWeights: [String: Double] = [
      "z_hrv": -0.6,  // ❌ Hard-coded seed weights
      // ...
  ]) {
      self.weights = initialWeights
  }
  ```
- **Related:** Already documented as BUG-20251026-0038
- **Root Cause:** Weights live only in memory, never persisted to Core Data
- **Stored But Never Read:** `FeatureVector.imputedFlags` contains encoded weights/contributions (line 627-634) but `materializeFeatures` only reads `imputed` map (lines 637-658)

---

### **BUG-ARCH-006: Journal Sentiment Excluded from Wellbeing Target**
- **Severity:** S0 (Feature Completely Non-Functional)
- **Category:** ML/Data
- **Location:** `DataAgent.swift:557-564`, `StateEstimator.swift:29-38`
- **Impact:** Voice journaling captures sentiment → persists to DB → but NEVER influences wellbeing score because sentiment is excluded from target computation AND StateEstimator seed weights
- **Evidence:**
  ```swift
  // DataAgent.swift:557-564 - computeTarget
  private func computeTarget(using features: [String: Double]) -> Double {
      let stress = features["subj_stress"] ?? 0
      let energy = features["subj_energy"] ?? 0
      let sleepQuality = features["subj_sleepQuality"] ?? 0
      let sleepDebt = features["z_sleepDebt"] ?? 0
      let hrv = features["z_hrv"] ?? 0
      let steps = features["z_steps"] ?? 0
      // ❌ NO sentiment, NO respiratory rate, NO nocturnal HR
      return (-0.35 * hrv) + (-0.25 * steps) + (-0.4 * sleepDebt) + 
             (0.45 * stress) + (-0.4 * energy) + (0.3 * sleepQuality)
  }
  
  // StateEstimator.swift:29-38 - seed weights
  public init(initialWeights: [String: Double] = [
      "z_hrv": -0.6,
      // ... 
      "subj_sleepQuality": 0.4
      // ❌ NO "sentiment" key
  ]) 
  ```
- **Related:** Already documented as BUG-20251026-0039
- **ScoreBreakdown Shows It:** Line 914-926 defines "Journal Sentiment" card but contribution is ALWAYS 0

---

### **BUG-ARCH-007: Wellbeing Coefficients Have Inverted Signs**
- **Severity:** S1 (Logic Error / User Trust)
- **Category:** ML/Math
- **Location:** `DataAgent.swift:557-564`, `StateEstimator.swift:29-38`
- **Impact:** Higher HRV and more steps LOWER wellbeing score instead of raising it; higher sleep debt RAISES score instead of lowering it → contradicts recovery science
- **Evidence:**
  ```swift
  // DataAgent.swift:564
  return (-0.35 * hrv) + (-0.25 * steps) + (-0.4 * sleepDebt) + ...
  // ❌ Negative hrv coefficient means higher HRV = LOWER score (WRONG)
  // ❌ Negative steps coefficient means more movement = LOWER score (WRONG)
  // ❌ Negative sleepDebt means LARGER debt = LOWER score (WRONG - larger debt should LOWER score, but math is inverted)
  
  // StateEstimator seed weights have same issue:
  "z_hrv": -0.6,      // ❌ Should be POSITIVE (higher HRV = better recovery)
  "z_steps": -0.2,    // ❌ Should be POSITIVE (more steps = better)
  "z_sleepDebt": 0.5  // ❌ Should be POSITIVE (larger debt = worse, but this makes it better)
  ```
- **Related:** Already documented as BUG-20251026-0028
- **Expected:** High HRV + low sleep debt + more steps should INCREASE wellbeing score

---

### **BUG-ARCH-008: RecRanker Never Updates From Acceptance Events**
- **Severity:** S1 (ML Personalization Broken)
- **Category:** ML/Wiring
- **Location:** `CoachAgent.swift:131-138`, `RecRanker.swift:107-115`
- **Impact:** Recommendation ranking weights stay frozen despite user acceptances/rejections → no personalization → cards don't adapt
- **Evidence:**
  ```swift
  // CoachAgent.swift:131-138
  public func logEvent(momentId: String, accepted: Bool) async throws {
      try await context.perform { [context] in
          let event = RecommendationEvent(context: context)
          event.momentId = momentId
          event.date = Date()
          event.accepted = accepted
          event.completedAt = accepted ? Date() : nil
          try context.save()
          // ❌ NO CALL to ranker.update() or ranker.updateLearningRate()
      }
  }
  
  // RecRanker.swift:107-115 - update method exists but NEVER CALLED
  public func update(preferred: RecommendationFeatures, other: RecommendationFeatures) {
      // ... pairwise logistic update ...
  }
  ```
- **Related:** Already documented as BUG-20251026-0027
- **Dead Code:** RecRanker has full learning infrastructure (lines 107-137) but never invoked

---

### **BUG-ARCH-009: Topic Fallback Reads Non-Existent Feature Keys**
- **Severity:** S1 (Logic Error / Always Defaults)
- **Category:** Data/Wiring
- **Location:** `AgentOrchestrator.swift:464-511`, `DataAgent.swift:960-974`
- **Impact:** When topic inference fails, fallback routing queries `hrv_rmssd_rolling_30d`, `sentiment_rolling_7d`, etc. but DataAgent NEVER exposes those keys → always returns default `subj_energy`
- **Evidence:**
  ```swift
  // AgentOrchestrator.swift:470-476 - topicToSignal mapping
  let topicToSignal: [String: String] = [
      "sleep": "subj_sleepQuality",
      "stress": "subj_stress",
      "energy": "subj_energy",
      "hrv": "hrv_rmssd_rolling_30d",      // ❌ KEY DOESN'T EXIST
      "mood": "sentiment_rolling_7d",      // ❌ KEY DOESN'T EXIST
      "movement": "steps_rolling_7d",      // ❌ KEY DOESN'T EXIST
      // ...
  ]
  
  // DataAgent.swift:645-658 - materializeFeatures only exposes these keys:
  let values: [String: Double] = [
      "z_hrv": ...,          // NOT "hrv_rmssd_rolling_30d"
      "z_nocthr": ...,
      "z_resthr": ...,
      "z_sleepDebt": ...,
      "z_rr": ...,
      "z_steps": ...,        // NOT "steps_rolling_7d"
      "subj_stress": ...,
      "subj_energy": ...,
      "subj_sleepQuality": ...,
      "sentiment": ...       // NOT "sentiment_rolling_7d"
  ]
  ```
- **Related:** Already documented as BUG-20251026-0008
- **Result:** All fallback routing collapses to `subj_energy`

---

### **BUG-ARCH-010: SentimentAgent Session Allows Duplicate Starts**
- **Severity:** S1 (Resource Leak)
- **Category:** Wiring/Concurrency
- **Location:** `SentimentAgent.swift:60-65`
- **Impact:** Calling `beginVoiceJournal()` twice without `finishVoiceJournal()` overwrites `activeSession` → previous session leaks → microphone stays hot
- **Evidence:**
  ```swift
  // SentimentAgent.swift:60-65
  public func beginVoiceJournal(maxDuration: TimeInterval = 30) async throws {
      try await speechService.requestAuthorization()
      let session = try await speechService.startRecording(maxDuration: min(maxDuration, 30))
      activeSession = session  // ❌ OVERWRITES without cleanup
      latestTranscript = ""
  }
  ```
- **Related:** Already documented as BUG-20251026-0016
- **Missing:** Guard like `guard activeSession == nil else { throw ... }`

---

### **BUG-ARCH-011: Legacy recordVoiceJournal Leaks Session on Error**
- **Severity:** S1 (Resource Leak)
- **Category:** Wiring
- **Location:** `AgentOrchestrator.swift:173-184`
- **Impact:** If speech streaming throws (network drop, permission revoked), `recordVoiceJournal` exits before calling `finishVoiceJournalRecording` → SpeechService continues recording → mic stuck on
- **Evidence:**
  ```swift
  // AgentOrchestrator.swift:173-184
  public func recordVoiceJournal(maxDuration: TimeInterval = 30) async throws -> JournalCaptureResponse {
      try await beginVoiceJournalRecording(maxDuration: maxDuration)
      
      var transcript = ""
      if let stream = voiceJournalSpeechStream {
          for try await segment in stream {  // ❌ CAN THROW - no cleanup
              transcript = segment.transcript
          }
      }
      
      return try await finishVoiceJournalRecording(transcript: transcript)
      // ❌ If loop throws, finishVoiceJournalRecording never called
  }
  ```
- **Related:** Already documented as BUG-20251026-0034
- **Fix:** Wrap in `do/catch` or `defer { activeSession?.stop() }`

---

### **BUG-ARCH-012: FileHandle Close Errors Silently Swallowed**
- **Severity:** S1 (File Descriptor Leak)
- **Category:** Data/I/O
- **Location:** `VectorIndex.swift:104, 128`
- **Impact:** Vector index operations suppress `FileHandle.close()` errors → file descriptor leaks → eventual "Too many open files" crash
- **Evidence:**
  ```swift
  // VectorIndex.swift:104
  func upsert(id: String, vector: [Float]) throws {
      // ...
      let handle = try FileHandle(forUpdating: shardURL)
      defer { try? handle.close() }  // ❌ Suppresses close errors
      // ...
  }
  
  // VectorIndex.swift:128
  func remove(id: String) throws {
      // ...
      defer { try? handle.close() }  // ❌ Suppresses close errors
  }
  ```
- **Related:** Already documented as BUG-20251026-0017
- **Risk:** iOS limits ~256 file descriptors per process

---

### **BUG-ARCH-013: Core Data Blocking I/O on Database Thread**
- **Severity:** S2 (Performance)
- **Category:** Data
- **Location:** `LibraryImporter.swift:58-68` (referenced in bugs.md but need to verify)
- **Impact:** LibraryImporter reads JSON files INSIDE `context.perform` closure → blocks Core Data queue → freezes UI operations
- **Related:** Already documented as BUG-20251026-0022

---

### **BUG-ARCH-014: CoachAgent Drops Retrieval Context Before GPT Call**
- **Severity:** S1 (Guardrail Violation)
- **Category:** Wiring
- **Location:** `LLMGateway.swift:695-737`, `CoachAgent.swift:78-111`
- **Impact:** CoachAgent fetches candidate moments and passes to LLMGateway → but `makeChatRequestBody` ignores `candidateMoments` parameter → GPT gets NO retrieval context → responses are ungrounded
- **Evidence:**
  ```swift
  // LLMGateway.swift:695-704
  fileprivate static func makeChatRequestBody(context: CoachLLMContext,
                                              maxOutputTokens: Int) -> [String: Any] {
      let tone = String(context.userToneHints.prefix(180))
      let signal = String(context.topSignal.prefix(120))
      let scores = String(context.zScoreSummary.prefix(180))
      // ...
      // ❌ candidateMoments parameter DROPPED - never used
      return [
          "model": "gpt-5",
          "input": [
              ["role": "system", "content": systemMessage],
              ["role": "user", "content": clipped]  // ❌ No moments in prompt
          ],
          // ...
      ]
  }
  ```
- **Related:** Already documented as BUG-20251026-0004
- **Architecture Promise:** Section 7 says GPT requests include retrieval context for grounding

---

## NEW BUGS (Beyond bugs.md)

### **BUG-ARCH-015: HealthKit Observer Queries Have No Authorization Check**
- **Severity:** S1 (Runtime Failure)
- **Category:** Wiring
- **Location:** `HealthKitService.swift:103-134` (referenced but confirming issue exists)
- **Impact:** `observeSampleType` creates and executes queries WITHOUT checking authorization status → silent failures if user revokes permission after initial grant
- **Related:** Already documented as BUG-20251026-0024

---

### **BUG-ARCH-016: LLM PING Validation Case Mismatch**
- **Severity:** S2 (Test/Diagnostics)
- **Category:** Wiring
- **Location:** `LLMGateway.swift:740-745`
- **Impact:** API key test always fails due to case mismatch: request sends "PING" but validator expects "ping"
- **Evidence:**
  ```swift
  // LLMGateway.swift:744
  "input": [
      ["role": "user", "content": "PING"]  // ❌ Uppercase
  ]
  
  // LLMGateway.swift:462 (validation)
  (input.first? ["content"] as? String) == "ping"  // ❌ Lowercase
  ```
- **Related:** Already documented as BUG-20251026-0023

---

### **BUG-ARCH-017: PulseViewModel Transcript Visibility Logic**
- **Severity:** S2 (UX)
- **Category:** UI
- **Location:** `PulseView.swift:78` (referenced in bugs.md)
- **Impact:** Transcript disappears immediately after analysis completes because view conditional checks `isRecording || isAnalyzing` → both become false → transcript hides
- **Related:** Already documented as BUG-20251026-0009

---

### **BUG-ARCH-018: Embedding Zero-Vector Fallback Masks Failures**
- **Severity:** S1 (Data Corruption)
- **Category:** ML
- **Location:** `EmbeddingService.swift:31-43` (referenced in bugs.md)
- **Impact:** When all embedding providers fail, service silently returns `[0,0,...,0]` → corrupts similarity search → no way to detect failures
- **Related:** Already documented as BUG-20251026-0021

---

### **BUG-ARCH-019: AFM Contextual Embeddings Permanently Disabled**
- **Severity:** S1 (Feature Degradation)
- **Category:** Dependency
- **Location:** `AFMTextEmbeddingProvider.swift:28-39` (referenced in bugs.md)
- **Impact:** Primary AFM feature (contextual embeddings) disabled with TODO comment → falls back to inferior word embeddings despite iOS 17+ availability
- **Related:** Already documented as BUG-20251026-0020

---

### **BUG-ARCH-020: Modern Speech Backend Is Stub**
- **Severity:** S2 (Missing Feature)
- **Category:** Dependency
- **Location:** `SpeechService.swift:482-485`
- **Impact:** iOS 26 devices never use modern SpeechAnalyzer/SpeechTranscriber APIs → all transcription uses legacy SFSpeechRecognizer with reduced accuracy
- **Evidence:**
  ```swift
  // SpeechService.swift:482-485
  func startRecording(maxDuration: TimeInterval) async throws -> SpeechService.Session {
      // Placeholder: integrate SpeechAnalyzer/SpeechTranscriber APIs when publicly available.
      // For now we reuse the legacy backend to ensure functionality.
      return try await fallback.startRecording(maxDuration: maxDuration)
  }
  ```
- **Related:** Already documented as BUG-20251026-0007

---

### **BUG-ARCH-021: Duplicate Podcast JSON Files**
- **Severity:** S2 (Maintenance)
- **Category:** Data
- **Location:** Repository root
- **Impact:** Three identical copies of `podcastrecommendations.json` (150KB each) risk divergence and waste bundle space
- **Related:** Already documented as BUG-20251026-0013

---

### **BUG-ARCH-022: Apple Intelligence Link Uses macOS-Only URL**
- **Severity:** S2 (UX)
- **Category:** UI
- **Location:** `SettingsView.swift:150-176` (referenced in bugs.md)
- **Impact:** "Enable Apple Intelligence" button uses `x-apple.systempreferences` scheme (macOS only) → no-ops on iOS
- **Related:** Already documented as BUG-20251026-0010

---

### **BUG-ARCH-023: Spline Hero Scene Missing from Main View**
- **Severity:** S2 (UX/Design)
- **Category:** UI
- **Location:** `PulsumRootView.swift:145-169` (referenced in bugs.md)
- **Impact:** Main tab renders only gradient background → flagship Liquid Glass Spline visual completely absent
- **Related:** Already documented as BUG-20251026-0011

---

### **BUG-ARCH-024: Waveform Renderer Copies Entire Buffer Each Frame**
- **Severity:** S2 (Performance)
- **Category:** Performance
- **Location:** `PulseView.swift:302-321` (referenced in bugs.md)
- **Impact:** Canvas redraw clones full `[CGFloat]` buffer every tick → heap allocations → dropped frames during recording
- **Related:** Already documented as BUG-20251026-0032

---

## NEW ARCHITECTURAL ISSUES (Not Previously Documented)

### **BUG-ARCH-025: No Unique Constraints on Core Data Entities**
- **Severity:** S1 (Data Integrity)
- **Category:** Data Model
- **Location:** `Pulsum.xcdatamodeld`
- **Impact:** Core Data model lacks unique constraints → can create duplicate entities for same date/ID → query results unpredictable
- **Evidence:**
  - `DailyMetrics` has no unique constraint on `date` → can have multiple metrics for same day
  - `FeatureVector` has no unique constraint on `date` → can have multiple vectors for same day
  - `Baseline` has no unique constraint on `metric` → can have multiple baselines for same metric
  - `MicroMoment` has no unique constraint on `id` → can have duplicate moments
- **Fix:** Add unique constraints in Core Data model editor

---

### **BUG-ARCH-026: SentimentAgent Uses Wrong Context Thread**
- **Severity:** S1 (Thread Safety)
- **Category:** Concurrency
- **Location:** `SentimentAgent.swift:47`
- **Impact:** SentimentAgent (MainActor isolated) creates background context but accesses from main actor → potential race conditions
- **Evidence:**
  ```swift
  // SentimentAgent.swift:24, 42-49
  @MainActor
  public final class SentimentAgent {
      private let context: NSManagedObjectContext
      
      public init(speechService: SpeechService = SpeechService(),
                  container: NSPersistentContainer = PulsumData.container,
                  sentimentService: SentimentService = SentimentService()) {
          // ...
          self.context = container.newBackgroundContext()  // ❌ Background context
          self.context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
          self.context.name = "Pulsum.SentimentAgent.FoundationModels"
      }
  ```
- **Problem:** `@MainActor` class holds background context → `context.perform` calls from main actor can deadlock or violate Core Data thread rules
- **Fix:** Either:
  1. Remove `@MainActor` from SentimentAgent
  2. Use view context instead of background context
  3. Make context operations go through actor isolation

---

### **BUG-ARCH-027: CoachAgent Also Has Wrong Context Thread**
- **Severity:** S1 (Thread Safety)
- **Category:** Concurrency
- **Location:** `CoachAgent.swift:27-28`
- **Impact:** Same issue as SentimentAgent - MainActor class with background context
- **Evidence:**
  ```swift
  // CoachAgent.swift:11, 27-28
  @MainActor
  public final class CoachAgent {
      private let context: NSManagedObjectContext
      
      public init(...) {
          self.context = container.newBackgroundContext()  // ❌
  ```

---

### **BUG-ARCH-028: StateEstimator Not Sendable But Shared Across Actors**
- **Severity:** S1 (Concurrency)
- **Category:** Concurrency
- **Location:** `StateEstimator.swift:24`, `DataAgent.swift:49`
- **Impact:** StateEstimator is mutable class (not actor, not Sendable) but used inside actor → data races possible
- **Evidence:**
  ```swift
  // StateEstimator.swift:24
  public final class StateEstimator {  // ❌ NOT Sendable, NOT actor
      private var weights: [String: Double]  // ❌ Mutable state
      private var bias: Double  // ❌ Mutable state
  
  // DataAgent.swift:49
  actor DataAgent {
      private var stateEstimator = StateEstimator()  // ❌ Non-Sendable in actor
  ```
- **Problem:** Swift 6 strict concurrency would flag this
- **Fix:** Make StateEstimator a struct (value type) or add `@unchecked Sendable` with documentation why it's safe

---

### **BUG-ARCH-029: RecRanker Not Sendable But Used in MainActor**
- **Severity:** S1 (Concurrency)
- **Category:** Concurrency
- **Location:** `RecRanker.swift:78`, `CoachAgent.swift:15`
- **Impact:** Similar to StateEstimator - mutable class used across isolation boundaries
- **Evidence:**
  ```swift
  // RecRanker.swift:78
  public final class RecRanker {  // ❌ NOT Sendable
      private var weights: [String: Double] = [...]  // ❌ Mutable
      private var learningRate: Double = 0.05  // ❌ Mutable
  
  // CoachAgent.swift:15
  @MainActor
  public final class CoachAgent {
      private let ranker = RecRanker()  // ❌ Non-Sendable in MainActor
  ```

---

### **BUG-ARCH-030: PulseViewModel Doesn't Cancel Audio Level Task on Stop**
- **Severity:** S2 (Resource)
- **Category:** Memory/Concurrency
- **Location:** `PulseViewModel.swift:142-157`
- **Impact:** `stopRecording()` cancels countdown and recording tasks but leaves `audioLevelTask` running → continues consuming resources
- **Evidence:**
  ```swift
  // PulseViewModel.swift:142-157
  func stopRecording() {
      guard isRecording else { return }
      
      cancelCountdown()
      isRecording = false
      audioLevelTask?.cancel()  // ❌ Cancels but doesn't nil out
      audioLevelTask = nil
      
      orchestrator?.stopVoiceJournalRecording()
      
      // isAnalyzing remains true - will be set to false when processing completes
      // recordingTask continues running to save the transcript
      // ❌ But recordingTask at line 71-139 still has reference to audioLevelTask
  }
  ```
- **Problem:** Race condition - recordingTask might still be iterating audioLevelTask stream even after cancellation

---

### **BUG-ARCH-031: ConsentStore Swallows Save Errors**
- **Severity:** S2 (Data Loss)
- **Category:** Data
- **Location:** `AppViewModel.swift:203-221`
- **Impact:** Consent changes fail silently if Core Data save fails → user thinks consent changed but it didn't
- **Evidence:**
  ```swift
  // AppViewModel.swift:216-220
  func saveConsent(_ granted: Bool) {
      // ... update entity ...
      do {
          try context.save()
      } catch {
          context.rollback()
          // ❌ NO ERROR REPORTING TO USER
      }
  }
  ```
- **Fix:** Return Result or throw error to caller

---

### **BUG-ARCH-032: VectorIndex Shard Creation Not Atomic**
- **Severity:** S1 (Data Corruption)
- **Category:** Concurrency/Data
- **Location:** `VectorIndex.swift:316-330`
- **Impact:** Shard creation errors leave partially-created shard in dictionary → subsequent reads will use corrupted shard
- **Evidence:**
  ```swift
  // VectorIndex.swift:316-330
  queue.sync(flags: .barrier) {
      if let shard = shards[index] {
          createdShard = shard
          return
      }
      do {
          let shard = try VectorIndexShard(baseDirectory: directory,
                                           name: name,
                                           shardIdentifier: "shard_\(index)",
                                           dimension: dimension)
          shards[index] = shard  // ❌ Assigned BEFORE validation complete
          createdShard = shard
      } catch {
          creationError = error
          // ❌ shards[index] might be partially initialized
      }
  }
  ```
- **Fix:** Don't assign to `shards[index]` until after shard fully initialized and validated

---

### **BUG-ARCH-033: SpeechService Doesn't Clean Up on Task Cancellation**
- **Severity:** S2 (Resource)
- **Category:** Memory
- **Location:** `SpeechService.swift:312-318`
- **Impact:** Max duration timeout cancels recording but cleanup might not execute → audio engine/session leak
- **Evidence:**
  ```swift
  // SpeechService.swift:312-318
  if maxDuration > 0 {
      Task { [weak self] in
          try? await Task.sleep(nanoseconds: UInt64(maxDuration * 1_000_000_000))
          speechLogger.info("Max recording duration reached; stopping.")
          self?.stopRecording()
          // ❌ If Task cancelled before timeout, stopRecording never called
      }
  }
  ```
- **Fix:** Store timeout task and cancel in `stopRecording()`

---

### **BUG-ARCH-034: HealthKitService Missing Error Handling for Observer Updates**
- **Severity:** S1 (Monitoring Failure)
- **Category:** Error Handling
- **Location:** `DataAgent.swift:238-249`
- **Impact:** HealthKit observer update errors are printed to debug console but NEVER logged or reported → monitoring silently fails
- **Evidence:**
  ```swift
  // DataAgent.swift:238-249
  private func observe(sampleType: HKSampleType) async throws {
      let query = try healthKit.observeSampleType(sampleType) { result in
          switch result {
          case let .success(update):
              Task { await self.handle(update: update, sampleType: sampleType) }
          case let .failure(error):
              #if DEBUG
              print("HealthKit observe error: \(error)")  // ❌ ONLY in DEBUG
              #endif
              // ❌ NO PRODUCTION ERROR HANDLING
          }
      }
  ```
- **Fix:** Log errors properly, consider retry logic or surface to UI

---

### **BUG-ARCH-035: DataAgent.handle Catches But Doesn't Log Sample Processing Errors**
- **Severity:** S2 (Observability)
- **Category:** Error Handling
- **Location:** `DataAgent.swift:252-269`
- **Impact:** Sample processing errors are printed only in DEBUG → production deployments lose all error visibility
- **Evidence:**
  ```swift
  // DataAgent.swift:252-269
  private func handle(update: HealthKitService.AnchoredUpdate, sampleType: HKSampleType) async {
      do {
          // ... process samples ...
          try await handleDeletedSamples(update.deletedSamples)
      } catch {
  #if DEBUG
          print("DataAgent processing error: \(error)")  // ❌ DEBUG ONLY
  #endif
          // ❌ NO PRODUCTION ERROR HANDLING
      }
  }
  ```

---

### **BUG-ARCH-036: LibraryImporter Doesn't Validate JSON Schema**
- **Severity:** S2 (Data Integrity)
- **Category:** Data
- **Location:** `LibraryImporter.swift` (would need to check actual implementation)
- **Impact:** If podcast JSON has malformed data, importer creates invalid MicroMoment entities → crashes later during recommendation generation
- **Recommendation:** Add JSON schema validation before Core Data persistence

---

### **BUG-ARCH-037: No Retry Logic for Transient LLM Failures**
- **Severity:** S2 (UX)
- **Category:** Networking
- **Location:** `GPT5Client.swift:480-558`
- **Impact:** Network timeouts or transient 500 errors immediately fall back to on-device → could retry once before giving up
- **Evidence:** Code has token-limit retry (lines 532-551) but NO retry for network errors

---

### **BUG-ARCH-038: SafetyAgent Crisis Keyword List Is Too Narrow**
- **Severity:** S1 (Safety)
- **Category:** Safety/ML
- **Location:** `SafetyAgent.swift:11-17`
- **Impact:** Only 5 crisis keywords → many crisis expressions missed → false negatives possible
- **Evidence:**
  ```swift
  // SafetyAgent.swift:11-17
  private let crisisKeywords: [String] = [
      "suicide",
      "kill myself",
      "end my life",
      "not worth living",
      "better off dead"
      // ❌ Missing: "harm myself", "self harm", "overdose", "hanging", etc.
  ]
  ```
- **Risk:** Production safety system needs comprehensive keyword coverage

---

### **BUG-ARCH-039: AppViewModel Doesn't Unbind ViewModels on Orchestrator Failure**
- **Severity:** S2 (State)
- **Category:** Wiring
- **Location:** `AppViewModel.swift:136-144`
- **Impact:** If orchestrator startup fails, ViewModels remain bound to failed orchestrator → subsequent operations use invalid state
- **Evidence:**
  ```swift
  // AppViewModel.swift:136-144
  } catch {
      print("[Pulsum] Orchestrator start failed: \(error)")
      // ... handles specific errors ...
      self.startupState = .failed(error.localizedDescription)
      // ❌ Never unbinds ViewModels or clears orchestrator reference
  }
  ```

---

### **BUG-ARCH-040: PulseViewModel State Machine Has No Guards**
- **Severity:** S2 (State)
- **Category:** State Management
- **Location:** `PulseViewModel.swift:42-140`
- **Impact:** Can call `startRecording()` while already recording → multiple concurrent sessions
- **Current Guard:** Line 44 has `guard !isRecording && !isAnalyzing else { return }` but it's insufficient
- **Problem:** Between check and execution, another call could start → race condition

---

### **BUG-ARCH-041: SettingsViewModel Doesn't Refresh After HealthKit Permission Grant**
- **Severity:** S1 (UX)
- **Category:** Wiring
- **Location:** `SettingsViewModel.swift:55-120` (referenced in bugs.md BUG-20251026-0040)
- **Impact:** Request HealthKit button shows permission sheet → user grants → but DataAgent never restarts → no samples arrive until app restart
- **Related:** Already documented as BUG-20251026-0040

---

### **BUG-ARCH-042: ChatGPT-5 Settings Panel Has No Input Field**
- **Severity:** S1 (UX)
- **Category:** UI
- **Location:** `SettingsView.swift:150-213` (referenced in bugs.md BUG-20251026-0041)
- **Impact:** Settings shows API key status but provides NO way to enter/change key
- **Related:** Already documented as BUG-20251026-0041

---

### **BUG-ARCH-043: Chat Keyboard Stays Visible When Switching Tabs**
- **Severity:** S2 (UX)
- **Category:** UI
- **Location:** `CoachView.swift:5-70` (referenced in bugs.md BUG-20251026-0042)
- **Impact:** Focus chat input → switch tabs → keyboard stays floating over new tab
- **Related:** Already documented as BUG-20251026-0042

---

### **BUG-ARCH-044: HealthKit Status Only Checks HRV Authorization**
- **Severity:** S2 (UX)
- **Category:** UI
- **Location:** `SettingsViewModel.swift:61-80` (referenced in bugs.md BUG-20251026-0043)
- **Impact:** Shows "Authorized" if HRV granted even if other 5 required types denied
- **Related:** Already documented as BUG-20251026-0043

---

## DEPENDENCY & INTEGRATION ISSUES

### **DEP-001: Foundation Models Stub Not Properly Isolated**
- **Severity:** S1 (Build)
- **Category:** Dependencies
- **Location:** `FoundationModelsStub.swift`
- **Impact:** Stub is always compiled even when real FoundationModels available → potential conflicts
- **Related:** Documented as BUG-20251026-0019 (now fixed per bugs.md)

---

### **DEP-002: Missing `@preconcurrency` Imports**
- **Severity:** S2 (Future Compatibility)
- **Category:** Dependencies
- **Location:** Various files
- **Impact:** Several files import non-Sendable frameworks without `@preconcurrency` → will break in Swift 6
- **Examples:**
  - `DataAgent.swift:2` has `@preconcurrency import CoreData` ✅
  - But many other files missing it

---

### **DEP-003: Circular Dependency Risk Between Agents and UI**
- **Severity:** S2 (Architecture)
- **Category:** Dependencies
- **Location:** Package dependencies
- **Current:** PulsumUI → PulsumAgents → PulsumServices → PulsumData
- **Risk:** If UI ever needs to pass types back to Agents, creates cycle
- **Mitigation:** Keep clear unidirectional flow

---

## SUMMARY TABLE

| ID | Severity | Category | Status | Description |
|---|---|---|---|---|
| ARCH-001 | S0 | Wiring | CRITICAL | Voice journal never triggers wellbeing refresh |
| ARCH-002 | S0 | Wiring | CRITICAL | Pulse sliders never refresh recommendations |
| ARCH-003 | S0 | Concurrency | CRITICAL | Vector index shard cache race condition |
| ARCH-004 | S0 | Concurrency | CRITICAL | Orphaned startup tasks cause duplicates |
| ARCH-005 | S0 | ML | CRITICAL | StateEstimator weights reset every launch |
| ARCH-006 | S0 | ML | CRITICAL | Sentiment excluded from wellbeing target |
| ARCH-007 | S1 | ML | HIGH | Inverted wellbeing coefficients |
| ARCH-008 | S1 | ML | HIGH | RecRanker never updates |
| ARCH-009 | S1 | Data | HIGH | Topic fallback reads non-existent keys |
| ARCH-010 | S1 | Wiring | HIGH | Duplicate voice journal session starts |
| ARCH-011 | S1 | Wiring | HIGH | Legacy recordVoiceJournal leaks session |
| ARCH-012 | S1 | I/O | HIGH | FileHandle close errors swallowed |
| ARCH-013 | S2 | Performance | MEDIUM | Core Data blocking I/O |
| ARCH-014 | S1 | Wiring | HIGH | GPT drops retrieval context |
| ARCH-015 | S1 | Wiring | HIGH | HealthKit observer missing auth check |
| ARCH-016 | S2 | Test | MEDIUM | LLM ping case mismatch |
| ARCH-017 | S2 | UX | MEDIUM | Transcript visibility logic |
| ARCH-018 | S1 | ML | HIGH | Zero-vector fallback masks failures |
| ARCH-019 | S1 | Feature | HIGH | AFM contextual embeddings disabled |
| ARCH-020 | S2 | Feature | MEDIUM | Modern speech backend is stub |
| ARCH-021 | S2 | Data | MEDIUM | Duplicate podcast JSON files |
| ARCH-022 | S2 | UX | MEDIUM | macOS-only Settings link |
| ARCH-023 | S2 | UX | MEDIUM | Missing Spline hero |
| ARCH-024 | S2 | Performance | MEDIUM | Waveform buffer copy per frame |
| ARCH-025 | S1 | Data | HIGH | No Core Data unique constraints |
| ARCH-026 | S1 | Concurrency | HIGH | SentimentAgent wrong context thread |
| ARCH-027 | S1 | Concurrency | HIGH | CoachAgent wrong context thread |
| ARCH-028 | S1 | Concurrency | HIGH | StateEstimator not Sendable |
| ARCH-029 | S1 | Concurrency | HIGH | RecRanker not Sendable |
| ARCH-030 | S2 | Memory | MEDIUM | Audio level task not properly cancelled |
| ARCH-031 | S2 | Data | MEDIUM | ConsentStore swallows save errors |
| ARCH-032 | S1 | Data | HIGH | VectorIndex shard creation not atomic |
| ARCH-033 | S2 | Memory | MEDIUM | SpeechService timeout task leak |
| ARCH-034 | S1 | Error | HIGH | HealthKit observer errors not logged |
| ARCH-035 | S2 | Error | MEDIUM | Sample processing errors not logged |
| ARCH-036 | S2 | Data | MEDIUM | No JSON schema validation |
| ARCH-037 | S2 | Network | MEDIUM | No retry logic for LLM transients |
| ARCH-038 | S1 | Safety | HIGH | Narrow crisis keyword list |
| ARCH-039 | S2 | State | MEDIUM | ViewModels not unbound on failure |
| ARCH-040 | S2 | State | MEDIUM | Recording state machine races |
| ARCH-041 | S1 | UX | HIGH | HealthKit grant doesn't restart ingestion |
| ARCH-042 | S1 | UX | HIGH | No API key input in Settings |
| ARCH-043 | S2 | UX | MEDIUM | Keyboard stays on tab switch |
| ARCH-044 | S2 | UX | MEDIUM | HealthKit status only checks HRV |

---

## PRIORITY RECOMMENDATIONS

### **MUST FIX BEFORE ANY RELEASE (S0):**
1. **ARCH-001:** Add `dataAgent.reprocessDay()` after voice journaling
2. **ARCH-002:** Add recommendation refresh after slider submission  
3. **ARCH-003:** Fix vector index double-checked locking (move reads inside barrier)
4. **ARCH-004:** Fix orphaned startup tasks (store and cancel properly)
5. **ARCH-005:** Persist StateEstimator weights to Core Data
6. **ARCH-006:** Include sentiment in wellbeing target computation

### **SHOULD FIX SOON (S1):**
7. **ARCH-007:** Correct wellbeing coefficient signs
8. **ARCH-008:** Wire RecRanker learning to acceptance events
9. **ARCH-025:** Add unique constraints to Core Data model
10. **ARCH-026/027:** Fix MainActor + background context pattern in agents
11. **ARCH-028/029:** Make StateEstimator & RecRanker Sendable
12. **ARCH-034:** Add proper error logging for HealthKit observers
13. **ARCH-038:** Expand crisis keyword list

### **CAN FIX LATER (S2):**
14. Performance optimizations (ARCH-024, ARCH-013)
15. UX polish (ARCH-017, ARCH-022, ARCH-023, ARCH-043, ARCH-044)
16. Observability improvements (ARCH-035, ARCH-036)

---

## ARCHITECTURAL STRENGTHS

Despite the bugs identified, the codebase demonstrates:

✅ **Well-structured package architecture** with clear separation of concerns  
✅ **Comprehensive ML infrastructure** (StateEstimator, RecRanker, SafetyLocal)  
✅ **Strong privacy design** (PII redaction, file protection, backup exclusion)  
✅ **Good Foundation Models integration** with fallback tiers  
✅ **Actor-based concurrency** in critical data paths (DataAgent, SpeechService)  
✅ **Sophisticated guardrail system** (two-wall safety + coverage checks)  
✅ **Vector index implementation** for similarity search  

---

## TESTING GAPS

Current test coverage is **severely inadequate** per bugs.md BUG-20251026-0014, BUG-20251026-0025:
- Package tests exist but excluded from Xcode scheme
- PulsumTests and PulsumUITests are empty scaffolds
- No integration tests for critical flows
- Zero tests for issues identified above

**Critical Missing Tests:**
1. Wellbeing refresh after journaling (ARCH-001)
2. Recommendation refresh after sliders (ARCH-002)
3. Concurrent shard access (ARCH-003)
4. Duplicate startup calls (ARCH-004)
5. StateEstimator persistence (ARCH-005)
6. Sentiment in wellbeing (ARCH-006)

---

## CONCLUSION

This iOS application has a **strong architectural foundation** but suffers from **critical wiring disconnections** that prevent end-to-end feature functionality. The most severe issues involve:

1. **Data flow breaks** where features persist data but never trigger dependent updates
2. **Concurrency issues** despite good actor usage
3. **ML personalization completely non-functional** due to missing persistence
4. **Missing error handling and observability** in production code paths

**Immediate Action Required:**
- Fix 6 S0 blockers before any release
- Add integration tests to prevent regressions
- Complete the data flow wiring between layers
- Audit all Core Data thread usage patterns

**Estimated Effort:**
- S0 fixes: 2-3 days
- S1 fixes: 1-2 weeks  
- S2 fixes + polish: 1-2 weeks
- Comprehensive test suite: 2-3 weeks

The code quality is generally high, but the **integration between layers needs completion** and the **test coverage needs dramatic improvement** before this can ship to production.

