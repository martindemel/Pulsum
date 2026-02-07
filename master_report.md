# Pulsum Master Technical Analysis Report

**Generated:** 2026-02-05 (Updated: 2026-02-05 — Production-Readiness Audit Added)  
**Files Analyzed:** 142 (96 source files + 67 test files + 7 UI test files + 1 script + build configs)  
**Total Findings:** 112 (78 technical + 9 architecture + 25 production-readiness)  
**Overall Health Score:** 3.5 / 10  

**Rationale:** The score reflects three layers of issues. **Technically** (4.5/10): critical bugs in vector index sharding, safety false negatives, cloud API schema mismatch, and crash-on-filesystem-error. **Architecturally** (4.5/10): Core Data is a poor fit for this flat-table data model (SwiftData or GRDB would be better), the custom binary vector index is a maintenance liability with two critical bugs already found, the DataAgent is a 3,706-line God Object, agents are on `@MainActor` serializing computation on the UI thread, and 5 singletons create hidden coupling that makes testing impossible. **Operationally** (2.5/10): no monetization, no crash reporting, no analytics, no GDPR data deletion, no health disclaimer, no localization. The app's 6-package modular structure is sound and the dependency injection on agents is excellent, but the technology choices (Core Data for flat data, custom binary index, @MainActor for computation) and operational gaps make it a sophisticated prototype rather than a production application.

---

## Executive Summary

Pulsum is a well-architected iOS 26+ wellness coaching app with a clean 6-package modular design (PulsumTypes → PulsumML/PulsumData → PulsumServices → PulsumAgents → PulsumUI → App). The dependency graph is acyclic and mostly correct, the HealthKit integration is comprehensive, and the diagnostics/logging system is production-grade. The security fundamentals (NSFileProtectionComplete, Keychain access control, PII redaction, consent gating) demonstrate serious attention to health data protection.

However, the implementation has serious problems at multiple levels. **Technically**, the vector index uses `String.hashValue` for shard assignment (randomized per process, causing data corruption), the safety classifier has false negatives for dangerous content, the LLM schema/prompt enum mismatch causes guaranteed cloud API failures, and multiple concurrency violations hide behind `@unchecked Sendable`. **Operationally**, the app is fundamentally not ready for App Store distribution: there is no monetization infrastructure (no StoreKit, paywall, or subscription despite requiring paid API calls), zero crash reporting, zero analytics, no network monitoring, no GDPR-compliant data deletion, no health disclaimer (App Store rejection risk), no localization, and no Core Data migration strategy.

The "bring your own API key" model for cloud coaching is not viable for a mass-market App Store app — 99%+ of potential users don't have an OpenAI API key. The test suite has 179 methods but only ~15% meaningful coverage, with zero tests for the voice journal streaming API, the two-wall guardrail system, HealthKit integration, and the wellbeing score pipeline. The app reads as a technically sophisticated prototype that has never been through an App Store submission process.

---

## If You Only Fix 5 Things, Fix These

1. **CRIT-001** — VectorIndex uses non-deterministic `String.hashValue` for shard routing, causing duplicate entries and data corruption across app restarts
2. **CRIT-002** — FoundationModelsSafetyProvider defaults guardrail violations to `.safe`, creating false negatives for dangerous crisis content
3. **CRIT-003** — CoachPhrasingSchema `intentTopic` enum doesn't include `"nutrition"` but LLMGateway system prompt instructs the model to use it, causing live cloud API failures
4. **CRIT-004** — DataStack.init has 3 `fatalError()` calls for recoverable filesystem errors, causing unrecoverable crashes
5. **HIGH-001** — RecRanker pairwise gradient is mathematically incorrect, causing recommendation learning to converge toward 0.5 instead of learning preferences

---

## App Understanding

Pulsum is an iOS 26+ wellness coaching application that combines on-device ML, HealthKit integration, voice journaling, and optional cloud-powered AI coaching. Users can: (1) view a computed wellbeing score derived from HealthKit metrics (HRV, heart rate, sleep, steps, respiratory rate) and subjective inputs (stress, energy, sleep quality), (2) record voice journals that are transcribed, sentiment-analyzed, and PII-redacted, (3) receive personalized micro-moment recommendations ranked by a learning algorithm, (4) chat with an AI coach that routes between on-device Foundation Models and cloud GPT-5 based on user consent and safety classification. The app implements a two-wall safety system: Wall 1 (local ML classification) blocks unsafe content before cloud processing, and Wall 2 (grounding validation) ensures LLM responses are grounded in user data.

**Architecture:** 6 Swift packages in acyclic dependency order: PulsumTypes (shared types, diagnostics) → PulsumML (embeddings, sentiment, safety, state estimation) + PulsumData (Core Data, vector index) → PulsumServices (HealthKit, Speech, LLM Gateway, Keychain) → PulsumAgents (orchestrator, Data/Sentiment/Coach/Safety/Cheer agents) → PulsumUI (SwiftUI views, view models, design system) → Main App (PulsumApp.swift entry point).

**Key Dependencies:** Apple HealthKit, Speech framework, Foundation Models (iOS 26), Core Data, Natural Language framework, Core ML, Spline (3D animation). **Backend:** OpenAI GPT-5 via Responses API (consent-gated).

---

## Critical Issues (Immediate Action Required)

### CRIT-001: VectorIndex Uses Non-Deterministic String.hashValue for Shard Routing

**Severity:** Critical  
**Category:** Data Flow  
**Files:** `Packages/PulsumData/Sources/PulsumData/VectorIndex.swift`  
**Effort:** S  

**Description:** The `shard(for:)` method at line 383 uses `abs(id.hashValue) % shardCount` to determine which shard stores a vector. Since Swift 4.2, `String.hashValue` is seeded with a random value at process startup. The same ID maps to different shards across app launches.

**Impact:** (1) `upsert()` on relaunch checks the wrong shard's metadata, doesn't find the existing entry, and appends a duplicate. (2) Active records accumulate across all 16 shards for the same ID. (3) `search()` scans all shards and returns duplicate matches. (4) Metadata files and shard files grow unboundedly. (5) After weeks of use, search performance degrades linearly.

**Evidence:**
```swift
private func shard(for id: String) throws -> VectorIndexShard {
    let shardIndex = abs(id.hashValue) % shardCount
    return try shard(forShardIndex: shardIndex)
}
```

**Suggested Fix:** Replace with a deterministic hash function:
```swift
private func shard(for id: String) throws -> VectorIndexShard {
    let data = Data(id.utf8)
    let hash = data.withUnsafeBytes { ptr -> UInt64 in
        var h: UInt64 = 0xcbf29ce484222325 // FNV-1a offset basis
        for byte in ptr { h = (h ^ UInt64(byte)) &* 0x100000001b3 }
        return h
    }
    return try shard(forShardIndex: Int(hash % UInt64(shardCount)))
}
```

**Cross-File Impact:** `VectorIndexManager.swift` (calls `shard(for:)` indirectly via upsert/search)  
**Verification:** Write a test that creates a VectorIndex, upserts an entry, simulates a "restart" by creating a new VectorIndex over the same directory, and verifies the entry is found in the correct shard without duplication.  
**Regression Test:** `testShardAssignmentIsDeterministicAcrossInstances` — create two VectorIndex instances and verify `shard(for: "test-id")` returns the same shard index.

---

### CRIT-002: Foundation Models Safety Provider Defaults Guardrail Violations to .safe

**Severity:** Critical  
**Category:** Security  
**Files:** `Packages/PulsumML/Sources/PulsumML/Safety/FoundationModelsSafetyProvider.swift`  
**Effort:** S  

**Description:** Lines 59-64: When Apple's Foundation Models refuse to process content due to their own safety guardrails (`GenerationError.guardrailViolation`, `GenerationError.refusal`), the provider returns `.safe` instead of `.caution` or `.crisis`. This means content that Apple's own AI considers dangerous is passed through as safe.

**Impact:** Genuinely dangerous content (self-harm, violence) that triggers Apple's guardrails gets classified as safe by Pulsum's Wall 1. This content then passes to the cloud LLM or on-device coach without safety intervention. In a health/wellness app handling crisis scenarios, this is a patient safety risk.

**Evidence:**
```swift
} catch let error as LanguageModelSession.GenerationError {
    switch error {
    case .guardrailViolation:
        return .safe  // ← Should be .caution at minimum
    case .refusal:
        return .safe  // ← Should be .caution at minimum
    // ...
    }
}
```

**Suggested Fix:** Return `.caution(reason: "Content flagged by on-device safety system")` for guardrail violations and refusals. Consider returning `.crisis` for guardrail violations specifically, since Apple's guardrails trigger on severe content.

**Cross-File Impact:** `SafetyAgent.swift` (consumes this classification to set `allowCloud`)  
**Verification:** Mock the Foundation Models session to throw `guardrailViolation`, verify the result is `.caution` not `.safe`.  
**Regression Test:** `testGuardrailViolationReturnsNotSafe` — inject a throwing FM session, assert result is `.caution`.

---

### CRIT-003: Schema/Prompt intentTopic Enum Mismatch Causes Live Cloud Failures

**Severity:** Critical  
**Category:** LLM  
**Files:** `Packages/PulsumServices/Sources/PulsumServices/CoachPhrasingSchema.swift`, `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift`  
**Effort:** S  

**Description:** The `intentTopic` field in `CoachPhrasingSchema.json()` (line 30) enumerates: `["sleep","stress","energy","hrv","mood","movement","mindfulness","goals","none"]`. But the system prompt in `LLMGateway.swift` (line 862) tells GPT-5 to use: `["sleep","stress","energy","mood","movement","nutrition","goals"]`. The schema includes `"hrv"`, `"mindfulness"`, `"none"` that the prompt doesn't mention, and the prompt includes `"nutrition"` that the schema doesn't allow. With `strict: true` JSON mode, OpenAI's API rejects any response where `intentTopic` is not in the schema enum.

**Impact:** Any nutrition-related user query causes GPT-5 to return `"nutrition"` as the `intentTopic`, which fails schema validation. The request returns a 400 error, falling back to the on-device generator. Users asking about nutrition never get cloud-quality coaching. This also wastes API tokens on failed requests.

**Evidence:**
```swift
// CoachPhrasingSchema.swift line 30:
"enum": ["sleep","stress","energy","hrv","mood","movement","mindfulness","goals","none"]

// LLMGateway.swift line 862 (system prompt):
// ...one of ["sleep","stress","energy","mood","movement","nutrition","goals"]
```

**Suggested Fix:** Unify both lists. Add `"nutrition"` to the schema enum. Either add `"hrv"`, `"mindfulness"`, `"none"` to the system prompt, or remove them from the schema if they shouldn't be used.

**Cross-File Impact:** `CoachAgent.swift` (processes `intentTopic` from responses)  
**Verification:** Send a nutrition-related query to the cloud API and verify the response parses correctly.  
**Regression Test:** `testSchemaAndPromptEnumsMatch` — parse both the schema enum and the system prompt enum, assert they contain the same values.

---

### CRIT-004: DataStack.init Crashes on Recoverable Filesystem Errors

**Severity:** Critical  
**Category:** CoreData  
**Files:** `Packages/PulsumData/Sources/PulsumData/DataStack.swift`  
**Effort:** M  

**Description:** Three `fatalError()` calls in `DataStack.init` (lines 70, 77, 101) cause unrecoverable crashes when the filesystem is temporarily unavailable (disk full, permission denied, corrupted store file). The app cannot present an error message or attempt recovery.

**Impact:** Users whose devices run low on storage, or whose Core Data store gets corrupted (e.g., after a forced quit during a write), will experience a crash loop with no recovery path. The only fix is deleting and reinstalling the app, losing all data.

**Evidence:**
```swift
fatalError("Pulsum data directories could not be resolved: \(error)")
// ...
fatalError("Persistent store model could not be loaded: \(error)")
// ...
fatalError("Unresolved Core Data error: \(error)")
```

**Suggested Fix:** Replace `fatalError` with a throwing initializer or a factory method that returns `nil` / `Result`. The `AppViewModel` should catch the error and present a recovery UI (e.g., "Your data may be corrupted. Would you like to reset?").

**Cross-File Impact:** `PulsumData.swift` (calls DataStack.init), `AppViewModel.swift` (initializes orchestrator which uses DataStack)  
**Verification:** Simulate a full-disk condition, verify the app presents an error instead of crashing.  
**Regression Test:** `testDataStackInitHandlesCorruptStore` — provide a corrupted SQLite file and verify graceful failure.

---

### CRIT-005: Incomplete Crisis Keyword Lists in SafetyLocal and SafetyAgent

**Severity:** Critical  
**Category:** Security  
**Files:** `Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift`, `Packages/PulsumAgents/Sources/PulsumAgents/SafetyAgent.swift`  
**Effort:** S  

**Description:** `SafetyLocal` (line 18-19) has ~10 crisis keywords and `SafetyAgent` (line 12-18) has only 5. Missing common crisis phrases: "want to die", "self-harm", "cutting myself", "overdose", "no reason to live", "jump off", "hang myself", "take all the pills", "slit my wrists", "not want to live anymore". When Foundation Models are unavailable (simulators, older devices, first cold start), only keyword matching protects users.

**Impact:** Users expressing suicidal ideation in common but unlisted phrases (e.g., "I just want to die") may not trigger crisis detection, receiving coaching advice instead of crisis resources. This is a patient safety liability.

**Suggested Fix:** Expand both keyword lists to cover the expanded CDC/SAMHSA crisis language patterns. Add at minimum: "want to die", "self-harm", "cut myself", "cutting myself", "overdose", "no reason to live", "jump off", "hang myself", "hurt myself", "don't want to be here", "can't go on", "take all the pills", "ending my life".

**Cross-File Impact:** None (keyword lists are self-contained)  
**Verification:** Test each added phrase and verify `.crisis` classification.  
**Regression Test:** `testExpandedCrisisKeywordsCoverage` — iterate over all known crisis phrases and assert `.crisis` classification for each.

---

## High-Priority Issues (Should Fix Before Release)

### HIGH-001: RecRanker Pairwise Gradient Is Mathematically Incorrect

**Severity:** High  
**Category:** Logic  
**Files:** `Packages/PulsumML/Sources/PulsumML/RecRanker.swift`  
**Effort:** M  

**Description:** Lines 128-136: The standard Bradley-Terry pairwise update should use `gradient = sigma(score_other - score_preferred)` applied symmetrically. Instead, the code treats each item independently: `grad_preferred = 1 - sigma(w·x_preferred)` and `grad_other = -sigma(w·x_other)`. This pulls ALL item scores toward 0.5 regardless of preference ordering.

**Impact:** Recommendation ranking doesn't improve from user feedback. The "learning" algorithm is effectively a slow drift toward uniform scoring. Users see no personalization improvement over time.

**Evidence:**
```swift
let gradPreferred = 1.0 - logistic(dotPreferred)
let gradOther = -logistic(dotOther)
```

**Suggested Fix:** Implement correct Bradley-Terry gradient:
```swift
let margin = dotOther - dotPreferred
let gradient = logistic(margin) // sigma(s_other - s_preferred)
// Update: w_k += lr * gradient * (x_preferred_k - x_other_k)
```

**Cross-File Impact:** `CoachAgent.swift` (calls `update(preferred:other:)`)  
**Verification:** After 10 feedback rounds preferring item A over item B, verify `score(A) > score(B)`.  
**Regression Test:** `testPairwiseLearningConverges` — assert preferred item score increases monotonically.

---

### HIGH-002: SentimentService Returns Silent 0.0 on Total Provider Failure

**Severity:** High  
**Category:** ML  
**Files:** `Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentService.swift`  
**Effort:** S  

**Description:** Line 37: When ALL sentiment providers fail (FM, AFM, CoreML), the service returns `0.0` (neutral) with no logging and no error signal. Downstream consumers (StateEstimator, DataAgent) cannot distinguish "genuinely neutral text" from "complete system failure."

**Impact:** On devices where all ML providers fail (cold start, missing models), every journal entry gets sentiment 0.0. The wellbeing score uses this as a feature, so it systematically misrepresents the user's emotional state. Additionally, `NaturalLanguageSentimentProvider` (which works on all iOS versions) is NOT in the iOS 26 fallback chain.

**Suggested Fix:** (1) Add `NaturalLanguageSentimentProvider()` as the final provider in the chain. (2) Log a `.warn` diagnostic when all providers fail. (3) Consider returning `nil` instead of `0.0` so callers can distinguish failure from neutrality.

**Cross-File Impact:** `SentimentAgent.swift`, `DataAgent.swift` (consume sentiment scores)  
**Verification:** Mock all providers to fail, verify a diagnostic log is emitted and the return value is distinguishable from neutral.  
**Regression Test:** `testAllProviderFailureReturnsNilNotZero`

---

### HIGH-003: EmbeddingTopicGateProvider Blocks ALL Input When Embeddings Unavailable

**Severity:** High  
**Category:** ML  
**Files:** `Packages/PulsumML/Sources/PulsumML/TopicGate/EmbeddingTopicGateProvider.swift`  
**Effort:** S  

**Description:** Lines 100-116: When the embedding service is unavailable (cold start, degraded mode), the provider returns `isOnTopic: false` for ALL user input. Since the topic gate sits before the LLM call in the coaching pipeline, this blocks the entire coaching feature.

**Impact:** During the first minutes after app launch (before embeddings warm up), or on devices where the embedding model fails to load, users receive off-topic redirect messages for ALL queries, including perfectly valid wellness questions.

**Suggested Fix:** In degraded mode, return `isOnTopic: true` with a low confidence score, allowing input through while flagging the degradation.

**Cross-File Impact:** `CoachAgent.swift` (checks `gateDecision.isOnTopic`)  
**Verification:** Set embedding service to unavailable, send a wellness query, verify it passes the topic gate.  
**Regression Test:** `testDegradedModeAllowsInput`

---

### HIGH-004: LegacySpeechBackend Has Data Race on Mutable State

**Severity:** High  
**Category:** Concurrency  
**Files:** `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift`  
**Effort:** M  

**Description:** `LegacySpeechBackend` is marked `@unchecked Sendable` (line 417) but has mutable properties (`audioEngine`, `recognitionTask`, `recognitionRequest`, `streamContinuation`, `levelContinuation`) with no synchronization. The `stop` closure in `Session` (line 362-364) captures `[weak self]` and calls `stopRecording()` from an arbitrary thread, mutating all these properties concurrently with potential ongoing recognition callbacks.

**Impact:** Race conditions can cause crashes (double-free of audio resources), corrupted transcripts (continuation resumed twice), or silent failures (recognition task cancelled but stream not terminated).

**Suggested Fix:** Add a serial `DispatchQueue` to `LegacySpeechBackend` and dispatch all state mutations through it. Alternatively, convert it to an actor.

**Cross-File Impact:** `SpeechService` (actor, calls backend methods)  
**Verification:** Run concurrent start/stop cycles in a stress test, verify no crashes or TSAN violations.  
**Regression Test:** `testConcurrentStartStopDoesNotCrash`

---

### HIGH-005: PulseViewModel.isAnalyzing Can Get Permanently Stuck

**Severity:** High  
**Category:** UI  
**Files:** `Packages/PulsumUI/Sources/PulsumUI/PulseViewModel.swift`  
**Effort:** S  

**Description:** Line 63: `isAnalyzing` is set to `true` before the recording task starts. If the task is cancelled externally or throws before reaching cleanup at lines 118-119, `isAnalyzing` stays `true`. The `stopRecording()` method (line 127) does NOT reset `isAnalyzing`.

**Impact:** The user sees a permanent "Analyzing..." spinner with no way to dismiss it. The journal button becomes unresponsive until the app is force-quit and restarted.

**Suggested Fix:** Reset `isAnalyzing = false` in `stopRecording()` and in the catch block of the recording task. Use a `defer` to ensure cleanup regardless of exit path.

**Cross-File Impact:** `PulseView.swift` (renders based on `isAnalyzing`)  
**Verification:** Start recording, immediately cancel, verify spinner disappears.  
**Regression Test:** `testCancelledRecordingResetsAnalyzingState`

---

### HIGH-006: All Fonts Ignore Dynamic Type (Accessibility Failure)

**Severity:** High  
**Category:** Accessibility  
**Files:** `Packages/PulsumUI/Sources/PulsumUI/PulsumDesignSystem.swift`  
**Effort:** M  

**Description:** Lines 63-83: Every font in the design system uses `Font.system(size:)` with hardcoded sizes. These do NOT scale with Dynamic Type settings. Users with vision accessibility needs (approximately 25% of iOS users customize text size) will find the app unusable.

**Impact:** App is not accessible to users who need larger text. This is an Apple App Store review rejection risk under accessibility guidelines, and a legal risk under ADA/WCAG compliance.

**Evidence:**
```swift
static let pulsumLargeTitle = Font.system(size: 34, weight: .bold, design: .default)
static let pulsumTitle = Font.system(size: 28, weight: .bold, design: .default)
// ... all fixed-size fonts
```

**Suggested Fix:** Replace `Font.system(size:)` with semantic font styles (`Font.system(.title)`) or use `@ScaledMetric` / `.dynamicTypeSize()` modifiers. Apply `.minimumScaleFactor()` to prevent layout overflow.

**Cross-File Impact:** All 10+ view files that reference `PulsumDesign.pulsumTitle` etc.  
**Verification:** Set device to "Accessibility Large Text" in Settings, verify all text scales appropriately.  
**Regression Test:** Snapshot test with various `ContentSizeCategory` values.

---

### HIGH-007: CoachAgent.performAndWait Blocks MainActor

**Severity:** High  
**Category:** Concurrency  
**Files:** `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift`  
**Effort:** M  

**Description:** Lines 698-709: `CoachAgent` is `@MainActor`. The `contextPerformAndWait` helper synchronously blocks the main thread while executing Core Data fetches. During `recommendationCards()`, multiple sequential `performAndWait` calls stack up (makeCandidate, cooldownScore, acceptanceRate per candidate).

**Impact:** The UI freezes for the duration of all Core Data queries. With many MicroMoment records and recommendation events, this could be perceptible (50-200ms on older devices). Users experience jank when the Coach tab loads.

**Suggested Fix:** Replace `performAndWait` with `perform` (async) and restructure the pipeline to batch Core Data fetches. Alternatively, move `CoachAgent` off `@MainActor` and use `context.perform {}` with async/await.

**Cross-File Impact:** `CoachViewModel.swift` (calls `recommendationCards()` on main thread)  
**Verification:** Profile with Instruments Time Profiler, verify no main-thread blocks > 16ms during recommendation loading.  
**Regression Test:** N/A (performance regression, use profiling)

---

### HIGH-008: ModernSpeechBackend Is a Stub (Not Actually iOS 26)

**Severity:** High  
**Category:** Speech  
**Files:** `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift`  
**Effort:** L  

**Description:** Lines 528-531: The `ModernSpeechBackend` class (iOS 26 speech integration) is a known stub that simply delegates to `LegacySpeechBackend`. Despite the app targeting iOS 26 exclusively, no iOS 26 speech APIs (SpeechAnalyzer/SpeechTranscriber) are actually used.

**Impact:** The app misses iOS 26 speech improvements (better accuracy, lower latency, streaming enhancements). The feature flag infrastructure exists but the implementation is placeholder.

**Evidence:**
```swift
func startRecording(maxDuration: TimeInterval) async throws -> SpeechService.Session {
    // NOTE: When Apple ships public SpeechAnalyzer/SpeechTranscriber APIs, integrate them here.
    return try await fallback.startRecording(maxDuration: maxDuration)
}
```

**Suggested Fix:** Implement actual iOS 26 speech APIs when available, or remove the `ModernSpeechBackend` class and feature flag to reduce confusion. Document clearly in code that legacy speech is the only active backend.

**Cross-File Impact:** `BuildFlags.swift` (feature flag), `SpeechService` init (backend selection)  
**Verification:** Verify speech recognition works on iOS 26 devices using the legacy backend.  
**Regression Test:** `testSpeechRecordingProducesTranscript` (integration test)

---

### HIGH-009: Non-Atomic Multi-Step Writes in VectorIndex

**Severity:** High  
**Category:** Data Flow  
**Files:** `Packages/PulsumData/Sources/PulsumData/VectorIndex.swift`  
**Effort:** M  

**Description:** Lines 125-148: The `upsert()` method performs 4 sequential steps (mark old record deleted → append new record → persist metadata → update header count). A process crash between steps 2 and 3 leaves the new record active in the shard file but invisible to metadata. The ID effectively disappears.

**Impact:** After a crash during vector index writes, micro-moments can become invisible to similarity search. Users stop seeing certain recommendations with no obvious cause.

**Suggested Fix:** Write to a temporary file first, then atomically rename. Or implement a write-ahead log (WAL) pattern. At minimum, add a recovery check on startup that reconciles file records with metadata.

**Cross-File Impact:** `VectorIndexManager.swift`, `LibraryImporter.swift`  
**Verification:** Kill the process during a write, restart, verify all records are recoverable.  
**Regression Test:** `testRecoveryAfterCrashDuringUpsert`

---

### HIGH-010: SafetyLocal Crisis Classification Requires Both Embedding AND Keyword Match

**Severity:** High  
**Category:** Security  
**Files:** `Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift`  
**Effort:** S  

**Description:** Lines 100-113: Even when embedding similarity to a crisis prototype is very high (e.g., 0.9), the classification is downgraded from `.crisis` to `.caution` if no crisis keyword is found in the text. This misses paraphrased crisis language that uses synonyms or euphemisms.

**Impact:** A user saying "I've been thinking about making a permanent choice to stop the pain" gets `.caution` instead of `.crisis` because none of the exact keywords match, even though the embedding strongly indicates crisis content.

**Suggested Fix:** Remove the keyword requirement for crisis classification when embedding similarity exceeds a high threshold (e.g., 0.85). The AND requirement should only apply at moderate similarity levels.

**Cross-File Impact:** `SafetyAgent.swift` (consumes classification result)  
**Verification:** Test paraphrased crisis texts without exact keywords, verify `.crisis` classification.  
**Regression Test:** `testParaphrasedCrisisTextClassifiedAsCrisis`

---

## Medium-Priority Issues (Fix in Next Sprint)

### MED-001: RecRanker and StateEstimator Have No Synchronization (Data Races)

**Severity:** Medium  
**Category:** Concurrency  
**Files:** `Packages/PulsumML/Sources/PulsumML/RecRanker.swift`, `Packages/PulsumML/Sources/PulsumML/StateEstimator.swift`  
**Effort:** S  

**Description:** Both `RecRanker` (line 90) and `StateEstimator` (line 36) are mutable `final class` types with no locking. `weights` and `bias` are mutated in `update()` and read in `score()`/`predict()`. While they're currently called from actor-isolated contexts (CoachAgent, DataAgent), the types themselves are not safe for concurrent access.

**Impact:** If usage patterns change to include concurrent access (e.g., background learning + foreground scoring), silent data corruption occurs. The `@unchecked Sendable` conformance on wrappers masks the issue.

**Suggested Fix:** Convert both to actors, or add `NSLock` around mutable state access.

**Cross-File Impact:** `CoachAgent.swift`, `DataAgent.swift`  
**Verification:** TSAN (Thread Sanitizer) run with concurrent access patterns.  
**Regression Test:** `testConcurrentScoreAndUpdateDoesNotCrash`

---

### MED-002: AFMTextEmbeddingProvider Gates on AFM Availability Unnecessarily

**Severity:** Medium  
**Category:** ML  
**Files:** `Packages/PulsumML/Sources/PulsumML/Embedding/AFMTextEmbeddingProvider.swift`  
**Effort:** S  

**Description:** Line 20 checks `availability() == .ready` AND `#available(iOS 26.0, *)`, but the actual embedding uses `NLEmbedding` (Natural Language framework), which works on iOS 17+ regardless of Apple Intelligence status. Functional embeddings are unnecessarily blocked when AFM isn't ready.

**Impact:** During cold start before Apple Intelligence warms up, embeddings fail even though `NLEmbedding` is perfectly functional. This cascades to topic gate blocking (HIGH-003), safety degraded mode, and coaching unavailability.

**Suggested Fix:** Remove the AFM availability check. `NLEmbedding` doesn't depend on Foundation Models availability.

**Cross-File Impact:** `EmbeddingService.swift` (calls this provider)  
**Verification:** Set AFM availability to `.unsupportedDevice`, verify embedding still works.  
**Regression Test:** `testEmbeddingWorksWithoutAFM`

---

### MED-003: NaturalLanguageSentimentProvider Missing from iOS 26 Fallback Chain

**Severity:** Medium  
**Category:** ML  
**Files:** `Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentService.swift`  
**Effort:** S  

**Description:** On iOS 26, the sentiment provider chain is: FoundationModels → AFM → CoreML. `NaturalLanguageSentimentProvider` (which uses `NLTagger` and works universally) is NOT in the chain. If all three providers fail, the service silently returns 0.0.

**Suggested Fix:** Add `NaturalLanguageSentimentProvider()` as the final provider before the 0.0 default.

**Cross-File Impact:** None (additive change)  
**Verification:** Mock FM, AFM, and CoreML providers to fail, verify NL provider is tried.  
**Regression Test:** `testNLFallbackUsedWhenOthersFail`

---

### MED-004: Core Data Model Has 19 Scalar Type Mismatches with Swift Code

**Severity:** Medium  
**Category:** CoreData  
**Files:** `Packages/PulsumData/Sources/PulsumData/Model/ManagedObjects.swift`, `.xcdatamodeld`  
**Effort:** M  

**Description:** 19 attributes are declared as `usesScalarValueType="YES"` in the Core Data model XML but as `NSNumber?` in `ManagedObjects.swift`. While Core Data's KVC bridging handles this at runtime, the `Optional` type creates semantically misleading nil checks — Core Data always provides a default scalar value (0), so nil branches are unreachable for attributes with defaults.

**Impact:** Code that checks `if let sentiment = entry.sentiment?.doubleValue` suggests the value can be nil, when it never actually is. This leads to unnecessary nil-handling complexity and potential logic errors where developers write fallback paths for impossible states.

**Suggested Fix:** Change `NSNumber?` declarations to `Double` (or `Int16`, `Int32`, `Bool` as appropriate) to match the model's scalar type declarations.

**Cross-File Impact:** All code accessing Core Data entity properties (DataAgent, SentimentAgent, CoachAgent, LibraryImporter)  
**Verification:** Build succeeds, all existing tests pass.  
**Regression Test:** `testEntityPropertyTypesMatchModel`

---

### MED-005: Core Data Model Has Zero Relationships and Zero Fetch Indexes

**Severity:** Medium  
**Category:** CoreData  
**Files:** `Packages/PulsumData/Sources/PulsumData/Resources/Pulsum.xcdatamodeld`  
**Effort:** M  

**Description:** All 9 entities use manual String/UUID foreign keys (e.g., `RecommendationEvent.momentId` → `MicroMoment.id`) with no Core Data relationships. Zero `<fetchIndex>` elements exist despite frequent date-based and ID-based queries.

**Impact:** (1) No cascading deletes — deleting a MicroMoment silently orphans its RecommendationEvent records. (2) No referential integrity enforcement. (3) All predicated fetches are O(n) table scans — performance degrades linearly over months of daily use. (4) No Core Data prefetching or relationship faulting optimization.

**Suggested Fix:** (1) Add `<fetchIndex>` elements for `DailyMetrics.date`, `JournalEntry.date`, `FeatureVector.date`, `RecommendationEvent.momentId`, `LibraryIngest.source`, `MicroMoment.id`. (2) Consider adding relationships where logical (RecommendationEvent → MicroMoment).

**Cross-File Impact:** Requires lightweight migration  
**Verification:** Profile fetch times with 365 days of data, compare before/after indexing.  
**Regression Test:** N/A (schema migration test)

---

### MED-006: LibraryImporter Non-Atomic Three-Phase Commit

**Severity:** Medium  
**Category:** Data Flow  
**Files:** `Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift`  
**Effort:** M  

**Description:** Phase 1 (`context.save()` for MicroMoments) commits before Phase 3 (`context.save()` for LibraryIngest tracking). A crash between phases causes Phase 1 to re-run on next launch (no tracking record found), wasting work and potentially re-indexing all embeddings.

**Impact:** After a crash during library import, the next launch repeats all embedding work (potentially minutes of computation). The concurrent task group in Phase 2 also produces partial indexing on single-element failures.

**Suggested Fix:** Combine all three phases into a single `context.save()`, or save the LibraryIngest tracking record first as a "pending" marker and update it to "complete" after all phases succeed.

**Cross-File Impact:** None  
**Verification:** Simulate crash between phases, verify clean recovery on relaunch.  
**Regression Test:** `testCrashRecoveryAfterPartialImport`

---

### MED-007: HealthKitAnchorStore Read/Write Queue Asymmetry

**Severity:** Medium  
**Category:** HealthKit  
**Files:** `Packages/PulsumServices/Sources/PulsumServices/HealthKitAnchorStore.swift`  
**Effort:** S  

**Description:** `anchor(for:)` uses `queue.sync` (blocking read) while `store(anchor:for:)` uses `queue.async` (fire-and-forget write). A `store()` followed immediately by `anchor()` can return stale data since the write hasn't completed.

**Impact:** On app relaunch, anchor reads may return the pre-update anchor, causing HealthKit to re-deliver samples that were already processed. Data ingestion is idempotent but wastes computation.

**Suggested Fix:** Use `queue.sync` for both read and write operations, or switch to an actor.

**Cross-File Impact:** `HealthKitService.swift` (calls anchor store methods)  
**Verification:** Write anchor, immediately read back, assert equality.  
**Regression Test:** `testStoreAndImmediateReadReturnsNewAnchor`

---

### MED-008: submitTranscript Skips reprocessDay

**Severity:** Medium  
**Category:** Integration  
**Files:** `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift`  
**Effort:** S  

**Description:** Lines 416-419: `submitTranscript()` calls `sentimentAgent.importTranscript()` but does NOT call `dataAgent.reprocessDay(date:)` afterward. Compare with `finishVoiceJournalRecording()` (line 389) which does call `reprocessDay`.

**Impact:** Text-imported journal entries don't update the wellbeing score until the next background sync (which could be hours).

**Suggested Fix:** Add `try await dataAgent.reprocessDay(date: result.date)` before the return in `submitTranscript`.

**Cross-File Impact:** None  
**Verification:** Import a transcript, immediately check wellbeing score, verify it reflects the new sentiment.  
**Regression Test:** `testSubmitTranscriptTriggersScoreRefresh`

---

### MED-009: SafetyAgent Crisis Message Is US-Centric and Not Localized

**Severity:** Medium  
**Category:** UI  
**Files:** `Packages/PulsumAgents/Sources/PulsumAgents/SafetyAgent.swift`  
**Effort:** S  

**Description:** Line 86: Crisis message is hardcoded to "If you're in the United States, call 911 right away." International users receive inappropriate guidance. The 988 Suicide & Crisis Lifeline is not mentioned.

**Suggested Fix:** Use locale-aware crisis resource information. At minimum, mention the international crisis line (988 in the US, Samaritans in UK, etc.) and provide a general "contact your local emergency services" message.

**Cross-File Impact:** `SafetyCardView.swift` (displays the message)  
**Verification:** Manual review of displayed crisis information for multiple locales.  
**Regression Test:** N/A (content review)

---

### MED-010: OnboardingView Bypasses Orchestrator Authorization Tracking

**Severity:** Medium  
**Category:** Integration  
**Files:** `Packages/PulsumUI/Sources/PulsumUI/OnboardingView.swift`  
**Effort:** S  

**Description:** Lines 300-312: When `orchestrator` is nil, OnboardingView creates a fresh `HKHealthStore` and requests authorization directly. This bypasses DataAgent's authorization tracking, read-access probe cache, and observer/backfill scheduling.

**Impact:** The app may think health permissions are still pending after the user grants them during onboarding. The observer queries and backfill scheduling that normally follow authorization are never triggered.

**Suggested Fix:** Wait for the orchestrator to be ready, or store the authorization result and replay it when the orchestrator initializes.

**Cross-File Impact:** `AppViewModel.swift` (orchestrator lifecycle)  
**Verification:** Complete onboarding, verify HealthKit data appears without requiring an app restart.  
**Regression Test:** `testOnboardingAuthorizationSyncsWithOrchestrator`

---

### MED-011: LLMGateway.inMemoryAPIKey Has No Synchronization

**Severity:** Medium  
**Category:** Concurrency  
**Files:** `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift`  
**Effort:** S  

**Description:** Line 294: The `inMemoryAPIKey` property is a mutable `var` on a class marked `@unchecked Sendable`. Concurrent reads (from key resolution) and writes (from `setAPIKey()`) are unsynchronized.

**Suggested Fix:** Use an `NSLock`, an `os_unfair_lock`, or make `LLMGateway` an actor.

**Cross-File Impact:** None  
**Verification:** TSAN run with concurrent key access.  
**Regression Test:** N/A (threading infrastructure)

---

### MED-012: testAPIConnection Bypasses Cloud Consent Check

**Severity:** Medium  
**Category:** Security  
**Files:** `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift`  
**Effort:** S  

**Description:** `testAPIConnection()` (line 332-376) makes a real API call to `api.openai.com` without checking the cloud consent flag. While it's a connectivity test that doesn't send user data, it still contacts an external server without explicit consent.

**Suggested Fix:** Add a consent parameter or document that connectivity testing is consent-independent.

**Cross-File Impact:** `SettingsViewModel.swift` (calls `testAPIConnection`)  
**Verification:** With consent off, verify testAPIConnection either skips or is documented as consent-independent.  
**Regression Test:** N/A (policy decision)

---

### MED-013: Compiled .momd May Be Stale Relative to Source .xcdatamodeld

**Severity:** Medium  
**Category:** Build  
**Files:** `Packages/PulsumData/Package.swift`  
**Effort:** S  

**Description:** Lines 30-31: Both the raw `.xcdatamodeld` and compiled `.momd` are bundled as resources. `PulsumManagedObjectModel.swift` tries `.momd` first. If the XML source is edited without recompiling, the runtime silently uses the stale compiled model.

**Suggested Fix:** Remove the compiled `.momd` from resources and rely on Xcode's automatic compilation, or add a CI check that verifies the `.momd` matches the `.xcdatamodeld` source.

**Cross-File Impact:** `PulsumManagedObjectModel.swift`  
**Verification:** Edit the model XML, build, verify the runtime uses the updated model.  
**Regression Test:** CI script that checksums both files and fails if they diverge.

---

### MED-014: PII Redaction Gaps (SSN, Addresses, Credit Cards, URLs)

**Severity:** Medium  
**Category:** Security  
**Files:** `Packages/PulsumML/Sources/PulsumML/Sentiment/PIIRedactor.swift`  
**Effort:** M  

**Description:** `PIIRedactor` only covers emails, phone numbers, and personal names (iOS 17+ only). Missing: SSN (XXX-XX-XXXX), street addresses, credit card numbers, IP addresses, dates of birth, social media handles, URLs with user identifiers.

**Impact:** If a user dictates "my Social Security number is 123-45-6789" in a voice journal, and cloud consent is granted, the SSN could be transmitted to OpenAI.

**Suggested Fix:** Add regex patterns for: SSN (`\d{3}-\d{2}-\d{4}`), credit cards (Luhn-validatable 16-digit sequences), IP addresses, and URLs. Consider using `NSDataDetector` for addresses.

**Cross-File Impact:** None (additive)  
**Verification:** Test each new pattern type and verify redaction.  
**Regression Test:** `testSSNRedaction`, `testCreditCardRedaction`, etc.

---

### MED-015: NSLock Inside VectorIndex Actor (Anti-Pattern)

**Severity:** Medium  
**Category:** Concurrency  
**Files:** `Packages/PulsumData/Sources/PulsumData/VectorIndex.swift`  
**Effort:** S  

**Description:** Line 334: `VectorIndex` is an actor but contains an `NSLock` (and per-shard `DispatchQueue`s). The actor already serializes access, making the lock redundant overhead. Blocking primitives inside actors risk priority inversions with the cooperative thread pool.

**Suggested Fix:** Remove the `NSLock` and per-shard `DispatchQueue`s. The actor isolation is sufficient.

**Cross-File Impact:** None  
**Verification:** Remove locks, run all VectorIndex tests, verify pass.  
**Regression Test:** Existing `Gate5_VectorIndexConcurrencyTests` suffices.

---

### MED-016: DiagnosticsDayFormatter Uses UTC, Not User's Local Timezone

**Severity:** Medium  
**Category:** Logic  
**Files:** `Packages/PulsumTypes/Sources/PulsumTypes/DiagnosticsTypes.swift`  
**Effort:** S  

**Description:** Line 244: `DiagnosticsDayFormatter` uses `TimeZone(secondsFromGMT: 0)` (UTC). When used for daily health metric aggregation, a user in UTC-8 who sleeps from 11 PM to 7 AM has their sleep split across two UTC "days."

**Impact:** Daily metric aggregation may attribute health data to the wrong calendar day, particularly for sleep analysis which spans midnight in the user's local time.

**Suggested Fix:** Use the user's local timezone (`TimeZone.current`) for day-level aggregation, or document that this formatter is for diagnostics/logging only (not metric aggregation).

**Cross-File Impact:** Any code using `DiagnosticsDayFormatter` for metric aggregation  
**Verification:** Verify daily metrics are attributed to the correct local day for users in various timezones.  
**Regression Test:** `testDailyMetricsUseLocalTimezone`

---

## Low-Priority Issues (Technical Debt / Nice-to-Have)

### LOW-001: EvidenceScorer Has Dead Domain Entries

**Severity:** Low  
**Category:** Logic  
**Files:** `Packages/PulsumData/Sources/PulsumData/EvidenceScorer.swift`  
**Effort:** S  

**Description:** `"pubmed"` never matches real PubMed URLs (host is `pubmed.ncbi.nlm.nih.gov`). `"nih.gov"` is redundant with `".gov"`. `"harvard.edu"` in `mediumDomains` is shadowed by `".edu"` in `strongDomains`.

**Suggested Fix:** Remove dead entries; change `"pubmed"` to `"pubmed.ncbi.nlm.nih.gov"` if PubMed-specific scoring is desired.

---

### LOW-002: BaselineMath.zScore Division by Zero When RobustStats Manually Constructed

**Severity:** Low  
**Category:** Logic  
**Files:** `Packages/PulsumML/Sources/PulsumML/BaselineMath.swift`  
**Effort:** S  

**Description:** `robustStats(for:)` clamps MAD to `max(mad, 1e-6)`, but the public `RobustStats.init(median:mad:)` does NOT validate. A caller constructing `RobustStats(median: 5, mad: 0)` then calling `zScore` gets `Inf` or `NaN`.

**Suggested Fix:** Validate in `RobustStats.init` or make `init` internal.

---

### LOW-003: NaN Propagation in StateEstimator Corrupts All Weights

**Severity:** Low  
**Category:** Logic  
**Files:** `Packages/PulsumML/Sources/PulsumML/StateEstimator.swift`  
**Effort:** S  

**Description:** If any feature value is NaN, it propagates through `predict()` to `update()` to ALL weight gradients, corrupting the entire model in a single call.

**Suggested Fix:** Guard against NaN in feature values at the top of `predict()` and `update()`.

---

### LOW-004: Sanitize Response Drops Punctuation Marks

**Severity:** Low  
**Category:** LLM  
**Files:** `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift`, `FoundationModelsCoachGenerator.swift`  
**Effort:** S  

**Description:** `split(whereSeparator:)` consumes `!` and `?` delimiters. "Great job! Keep going?" becomes "Great job. Keep going." — all punctuation replaced with periods.

**Suggested Fix:** Use a regex-based split that preserves the delimiter, or use `components(separatedBy:)` with post-processing.

---

### LOW-005: Duplicate #if DEBUG in SpeechService.swift

**Severity:** Low  
**Category:** Build  
**Files:** `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift`  
**Effort:** S  

**Description:** Lines 419-420: Two nested `#if DEBUG` guards. Harmless but indicates a copy-paste error.

---

### LOW-006: Timeout Task Leak in LegacySpeechBackend

**Severity:** Low  
**Category:** Memory  
**Files:** `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift`  
**Effort:** S  

**Description:** Lines 352-358: The max-duration timeout `Task` is fire-and-forget. If recording stops early, the task remains alive until `maxDuration` expires, then calls `stopRecording()` on an already-cleaned-up backend.

**Suggested Fix:** Store the task and cancel it in `stopRecording()`.

---

### LOW-007: RecRanker Silent State Discard on Version Mismatch

**Severity:** Low  
**Category:** Logic  
**Files:** `Packages/PulsumML/Sources/PulsumML/RecRanker.swift`  
**Effort:** S  

**Description:** Lines 188-194: `apply(state:)` silently ignores state when version != schemaVersion. Learned preferences from a previous version are silently lost.

**Suggested Fix:** Log a `.warn` diagnostic when state is discarded due to version mismatch.

---

### LOW-008: CoachViewModel Missing deinit Task Cancellation

**Severity:** Low  
**Category:** Memory  
**Files:** `Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift`  
**Effort:** S  

**Description:** `recommendationsTask`, `recommendationsDebounceTask`, and `recommendationsSoftTimeoutTask` are stored but never cancelled on deallocation. Unlike `PulseViewModel` (which has proper `deinit` cleanup).

**Suggested Fix:** Add a `deinit` that cancels all three tasks.

---

### LOW-009: Multiple Fire-and-Forget Task Leaks in ViewModels

**Severity:** Low  
**Category:** Memory  
**Files:** `PulseViewModel.swift`, `CoachViewModel.swift`  
**Effort:** S  

**Description:** `scheduleCheerReset()` (CoachViewModel:253), `scheduleSubmissionReset()` (PulseViewModel:178) create unstored tasks. Multiple rapid calls accumulate tasks that can clear state prematurely.

**Suggested Fix:** Store each task and cancel the previous before creating a new one.

---

### LOW-010: ScoreBreakdownView and SettingsView Create DateFormatter Per Render

**Severity:** Low  
**Category:** Memory  
**Files:** `ScoreBreakdownView.swift`, `SettingsView.swift`  
**Effort:** S  

**Description:** DateFormatter and RelativeDateTimeFormatter are allocated in computed properties that run on every SwiftUI evaluation. These are expensive initializations.

**Suggested Fix:** Use static cached formatters or a shared formatting utility.

---

### LOW-011: Duplicate TestCoreDataStack Files

**Severity:** Low  
**Category:** Tests  
**Files:** `PulsumAgentsTests/TestCoreDataStack.swift`, `PulsumUITests/TestCoreDataStack.swift`  
**Effort:** S  

**Description:** Identical `TestCoreDataStack` implementations exist in both test targets. Changes to one must be manually replicated to the other.

**Suggested Fix:** Extract to a shared test support module.

---

### LOW-012: Empty PulsumTests.swift Inflates Green CI

**Severity:** Low  
**Category:** Tests  
**Files:** `PulsumTests/PulsumTests.swift`  
**Effort:** S  

**Description:** Contains a single test method with no assertions ("Write your test here"). Always passes, inflating CI green status while verifying nothing.

**Suggested Fix:** Either add meaningful tests or remove the file.

---

### LOW-013: PulsumTests Skipped in Xcode Scheme

**Severity:** Low  
**Category:** Build  
**Files:** `Pulsum.xcodeproj/xcshareddata/xcschemes/Pulsum.xcscheme`  
**Effort:** S  

**Description:** Line 52-53: `PulsumTests` TestableReference has `skipped = "YES"`. The main app test target never runs in the scheme even when explicitly running tests.

**Suggested Fix:** Set `skipped = "NO"` or remove the skip flag.

---

### LOW-014: KeychainService UITest Fallback Is Runtime-Gated Only

**Severity:** Low  
**Category:** Security  
**Files:** `Packages/PulsumServices/Sources/PulsumServices/KeychainService.swift`  
**Effort:** S  

**Description:** The UITest fallback from Keychain to UserDefaults is gated by `AppRuntimeConfig.disableKeychain` (a runtime check on environment variables), not a `#if DEBUG` compile-time guard. All other UITest stubs use compile-time gating.

**Suggested Fix:** Add `#if DEBUG` guard around the UserDefaults fallback code path.

---

### LOW-015: Spline Package Only Dependency — Evaluate Necessity

**Severity:** Low  
**Category:** Build  
**Files:** `Package.resolved`  
**Effort:** S  

**Description:** `spline-ios` (v0.2.48) is the only external dependency. It's used for a 3D animation resource (`streak_low_poly_copy.splineswift`). This adds binary size and build time.

**Suggested Fix:** Evaluate whether the Spline animation is worth the dependency. Consider a Lottie or native SwiftUI animation alternative.

---

## Stubs and Incomplete Implementations

### STUB-001: ModernSpeechBackend (iOS 26 Speech)

**File:** `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift`  
**Lines:** 528-531  
**What It Claims To Do:** Use iOS 26 SpeechAnalyzer/SpeechTranscriber APIs for improved speech recognition.  
**What It Actually Does:** Delegates entirely to `LegacySpeechBackend` (SFSpeechRecognizer + AVAudioEngine).  
**Impact:** Users get legacy speech recognition quality despite running iOS 26.

### STUB-002: BGTaskScheduler Integration

**File:** Not implemented  
**What It Claims To Do:** (Referenced in todolist.md) Enable true background processing for HealthKit data ingestion and model updates.  
**What It Actually Does:** Does not exist. Only HealthKit background delivery is implemented.  
**Impact:** The app cannot perform background ML model updates, library imports, or baseline recomputation.

### STUB-003: Foundation Models Topic Gate Topic Field

**File:** `Packages/PulsumML/Sources/PulsumML/TopicGate/FoundationModelsTopicGateProvider.swift`  
**Lines:** 48-52  
**What It Claims To Do:** Return topic classification with topic identification.  
**What It Actually Does:** Returns `GateDecision` with `topic: nil` always. The embedding path provides topic identification but the FM path does not.  
**Impact:** Topic-specific coaching granularity is lost when Foundation Models are available (the primary path).

---

## Calculation and Logic Audit

### CALC-001: Robust Median (Interpolated)

**File:** `BaselineMath.swift:32-39`  
**Formula:** `values[floor(idx)] * (1-w) + values[ceil(idx)] * w` where `idx = (count-1) * 0.5`  
**Assessment:** Correct  
**Issue:** None. Standard linear interpolation median for even-count arrays.

### CALC-002: Median Absolute Deviation (MAD)

**File:** `BaselineMath.swift:18-19`  
**Formula:** `median(|x_i - median|) * 1.4826`  
**Assessment:** Correct  
**Issue:** 1.4826 is the correct consistency constant for normal distributions.

### CALC-003: Z-Score

**File:** `BaselineMath.swift:23-24`  
**Formula:** `(value - median) / mad`  
**Assessment:** Edge Case Risk  
**Issue:** Division by zero possible when `RobustStats` is manually constructed with `mad: 0`.

### CALC-004: EWMA

**File:** `BaselineMath.swift:27-29`  
**Formula:** `lambda * newValue + (1-lambda) * previous`  
**Assessment:** Correct  
**Issue:** Default `lambda = 0.2` gives appropriate smoothing. No overflow risk.

### CALC-005: Wellbeing Score (StateEstimator)

**File:** `StateEstimator.swift:68-71`  
**Formula:** `bias + Σ(w_k * z_k)` (linear combination)  
**Assessment:** Correct but unbounded  
**Issue:** No activation function — output can be any real number. Downstream must handle arbitrary ranges.

### CALC-006: SGD Update with L2 Regularization

**File:** `StateEstimator.swift:73-88`  
**Formula:** `w -= lr * (-(target-pred)*x + lambda*w)`; `bias += lr * (target-pred)`  
**Assessment:** Correct  
**Issue:** NaN in any feature corrupts all weights in a single call. Weight clamping [-2, 2] prevents extreme drift.

### CALC-007: RecRanker Score (Logistic)

**File:** `RecRanker.swift:120-122, 180-182`  
**Formula:** `1 / (1 + exp(-w·x))`  
**Assessment:** Correct  
**Issue:** None for scoring; the learning update (CALC-008) is incorrect.

### CALC-008: RecRanker Pairwise Update

**File:** `RecRanker.swift:128-136`  
**Formula:** `grad_pref = 1-sigma(w·x_pref)`, `grad_other = -sigma(w·x_other)`  
**Assessment:** Incorrect  
**Issue:** Should be `gradient = sigma(s_other - s_preferred)` (Bradley-Terry). Current formula pushes all scores toward 0.5.

### CALC-009: Cosine Similarity

**File:** `SafetyLocal.swift:202`, `AFMSentimentProvider.swift:54`, `EmbeddingTopicGateProvider.swift:85`  
**Formula:** `(a·b) / (|a| * |b|)`  
**Assessment:** Correct  
**Issue:** All implementations guard `denominator > 0`. Consistent across files.

### CALC-010: Anchor-Based Sentiment

**File:** `AFMSentimentProvider.swift:39-42`  
**Formula:** `avg_cos(x, positiveAnchors) - avg_cos(x, negativeAnchors)`, clamped to [-1, 1]  
**Assessment:** Correct  
**Issue:** Casing inconsistency (input lowercased, anchors not).

### CALC-011: L2 Distance

**File:** `VectorIndex.swift:312-324`  
**Formula:** `sqrt(Σ(a_i - b_i)^2)`  
**Assessment:** Correct  
**Recommendation:** Use squared L2 for ranking (skip sqrt, monotonic).

### CALC-012: EvidenceScorer URL Domain Matching

**File:** `EvidenceScorer.swift:10-60`  
**Formula:** `host.hasSuffix(domain)` check against strong/medium domain lists  
**Assessment:** Edge Case Risk  
**Issue:** Dead entries (pubmed, nih.gov redundancy, harvard.edu shadowing).

---

## Integration Map

| Connection | Status | Issue | Files |
|---|---|---|---|
| HealthKit → HealthKitService → DataAgent | **Working** | Anchor store race (MED-007) | HealthKitService.swift, HealthKitAnchorStore.swift, DataAgent.swift |
| DataAgent → StateEstimator → WellbeingScoreState | **Working** | No NaN guard (LOW-003), unbounded output (CALC-005) | DataAgent.swift, StateEstimator.swift, WellbeingScoreState.swift |
| SpeechService → SentimentAgent → Core Data | **Working** | Thread safety (HIGH-004), session state race (SentimentAgent) | SpeechService.swift, SentimentAgent.swift |
| SentimentAgent → PIIRedactor → LLMGateway | **Partially Working** | PII gaps (MED-014), sentiment silent-0.0 (HIGH-002) | PIIRedactor.swift, SentimentAgent.swift, LLMGateway.swift |
| CoachAgent → TopicGate → LLMGateway (cloud) | **Broken** | Schema mismatch (CRIT-003), topic gate blocks all (HIGH-003) | CoachAgent.swift, CoachPhrasingSchema.swift, LLMGateway.swift |
| SafetyAgent → FoundationModelsSafetyProvider → Cloud routing | **Partially Working** | FM guardrails → safe (CRIT-002), keyword gap (CRIT-005) | SafetyAgent.swift, FoundationModelsSafetyProvider.swift |
| AgentOrchestrator → UI (notifications) | **Working** | submitTranscript skip (MED-008) | AgentOrchestrator.swift, PulseViewModel.swift |
| VectorIndex → LibraryImporter → MicroMoments | **Broken** | hashValue sharding (CRIT-001), atomicity (MED-006) | VectorIndex.swift, LibraryImporter.swift |
| SettingsViewModel → Runtime Config → Agents | **Working** | API key unsynchronized (MED-011) | SettingsViewModel.swift, LLMGateway.swift |
| DataStack → Core Data → All agents | **Working** | fatalError (CRIT-004), no indexes (MED-005) | DataStack.swift, ManagedObjects.swift |
| OnboardingView → HealthKit auth | **Partially Working** | Bypasses orchestrator (MED-010) | OnboardingView.swift, HealthKitService.swift |
| PulsumApp → PulsumRootView → AppViewModel | **Working** | No issues found | PulsumApp.swift, PulsumRootView.swift, AppViewModel.swift |

---

## Test Coverage Gaps

### GAP-001: Voice Journal Streaming API Has Zero Tests

**Risk Level:** Critical  
**Files That Need Tests:** `SentimentAgent.swift`, `AgentOrchestrator.swift`, `SpeechService.swift`  
**What Should Be Tested:** `beginVoiceJournal()` → stream consumption → `finishVoiceJournal()` full lifecycle; error mid-stream; duplicate begin calls; PII redaction in finish.

### GAP-002: Safety Two-Wall Guardrail System Has 3-4 Test Cases Total

**Risk Level:** Critical  
**Files That Need Tests:** `SafetyLocal.swift`, `SafetyAgent.swift`, `AgentOrchestrator.swift`  
**What Should Be Tested:** All CDC/SAMHSA crisis phrases; paraphrased crisis; boundary between caution/crisis; FM guardrail violation handling; Wall 2 grounding validation; cloud routing when safety blocks.

### GAP-003: HealthKit Integration Uses Only Stubs (Zero Real Tests)

**Risk Level:** High  
**Files That Need Tests:** `HealthKitService.swift`, `DataAgent.swift`  
**What Should Be Tested:** Observer query lifecycle; anchored query resumption; background delivery; authorization denial handling; date/timezone aggregation; idempotent ingestion.

### GAP-004: Wellbeing Score Computation Pipeline Has No End-to-End Test

**Risk Level:** High  
**Files That Need Tests:** `DataAgent.swift`, `StateEstimator.swift`, `BaselineMath.swift`  
**What Should Be Tested:** Raw HealthKit samples → DailyMetrics → Baseline → FeatureVector → StateEstimator → WellbeingScoreState → UI display. Verify each mathematical step.

### GAP-005: LLM Cloud Integration Has Zero Request/Response Tests

**Risk Level:** High  
**Files That Need Tests:** `LLMGateway.swift`, `CoachPhrasingSchema.swift`  
**What Should Be Tested:** Full request body construction; response parsing; schema validation; retry logic; token adjustment; consent enforcement; error fallback to local; payload minimization.

### GAP-006: Main App Target Has Empty Placeholder Test

**Risk Level:** Medium  
**Files That Need Tests:** `PulsumApp.swift`, `PulsumRootView.swift`  
**What Should Be Tested:** App launch lifecycle; service initialization order; environment variable handling; UITest stub isolation.

### GAP-007: UI/ViewModel Layer Has Only 12 Tests

**Risk Level:** Medium  
**Files That Need Tests:** `PulseViewModel.swift`, `AppViewModel.swift`, `CoachView.swift`, `OnboardingView.swift`  
**What Should Be Tested:** isAnalyzing stuck state; recording lifecycle; notification handling; consent banner visibility; score display formatting; navigation flow.

---

## End-to-End Flow Breakpoints

### Flow: App Launch and Initialization

1. `PulsumApp.init()` → disables animations if UITest — *no issues*
2. `PulsumRootView` creates `AppViewModel` — *no issues*
3. `AppViewModel.setupOrchestrator()` creates `DataStack` — **can crash (CRIT-004)**
4. `AgentOrchestrator.init()` creates all agents — *can fail if DataStack failed*
5. `orchestrator.start()` triggers backfill and library import — **non-atomic import (MED-006)**
6. `EmbeddingService.shared` probes availability — **may block thread (MED-002)**
7. Vector index loads with hashValue-based sharding — **duplicates across restarts (CRIT-001)**

### Flow: Voice Journal Recording

1. User taps record button — *no issues*
2. `PulseViewModel.startRecording()` sets `isAnalyzing = true` — **can get stuck (HIGH-005)**
3. `orchestrator.beginVoiceJournalRecording()` starts speech session — *no issues*
4. `SpeechService.startRecording()` creates `LegacySpeechBackend` — **thread safety (HIGH-004)**
5. Real-time transcript streaming via `AsyncThrowingStream` — *no issues*
6. User stops or max duration reached — **timeout task leak (LOW-006)**
7. `finishVoiceJournal()` persists transcript with PII redaction — **PII gaps (MED-014)**
8. `dataAgent.reprocessDay()` refreshes wellbeing score — *no issues*
9. Notification triggers UI update — *no issues*

### Flow: Wellbeing Score Computation and Display

1. HealthKit samples fetched via anchored queries — **anchor store race (MED-007)**
2. Samples aggregated into DailyMetrics — **timezone issue (MED-016)**
3. Baselines computed via `BaselineMath.robustStats()` — **NaN risk if data contains NaN**
4. FeatureVector z-scores computed — **division by zero risk (LOW-002)**
5. `StateEstimator.predict()` computes wellbeing score — **NaN propagation (LOW-003)**
6. Score stored in `WellbeingScoreState` — *no issues*
7. UI refreshes via notification — *no issues*

### Flow: Coach Recommendations

1. User navigates to Coach tab — *no issues*
2. `CoachViewModel.loadRecommendations()` calls `CoachAgent.recommendationCards()` — *no issues*
3. `CoachAgent.contextPerformAndWait()` fetches from Core Data — **blocks MainActor (HIGH-007)**
4. `TopicGateProvider.classify()` checks wellness relevance — **blocks all when embeddings down (HIGH-003)**
5. `RecRanker.rank()` ranks candidates — **incorrect learning (HIGH-001)**
6. Results displayed in coach view — *no issues*

### Flow: AI Chat

1. User sends message in CoachView — *no issues*
2. `orchestrator.performChat()` sanitizes input — *no issues*
3. `SafetyAgent.evaluate()` classifies safety — **FM guardrails → safe (CRIT-002), keyword gaps (CRIT-005)**
4. Topic gate check — **FM path loses topic info (STUB-003)**
5. Consent + safety check for cloud routing — *correct*
6. If cloud: `LLMGateway.generateCoachResponse()` — **schema mismatch (CRIT-003)**
7. Response parsed and returned — **punctuation loss (LOW-004)**
8. Grounding score validated — *correct*

### Flow: Settings Changes

1. User enters API key in Settings — *no issues*
2. `SettingsViewModel.saveAPIKey()` stores in Keychain — *no issues*
3. `orchestrator.setLLMAPIKey()` updates LLMGateway — **unsynchronized (MED-011)**
4. `testAPIConnection()` pings OpenAI — **bypasses consent (MED-012)**
5. Consent toggle updates `UserPrefs` — *no issues*
6. Cloud routing respects consent flag — *correct*

---

## Action Plan (Prioritized Fix Order)

### Week 1 — Critical Fixes and Blockers

1. **CRIT-001**: Replace `String.hashValue` with deterministic hash in VectorIndex (Effort: S)
2. **CRIT-002**: Change FM guardrail violation handling from `.safe` to `.caution` (Effort: S)
3. **CRIT-003**: Unify intentTopic enum between schema and system prompt (Effort: S)
4. **CRIT-005**: Expand crisis keyword lists in SafetyLocal and SafetyAgent (Effort: S)
5. **HIGH-005**: Fix `isAnalyzing` stuck state in PulseViewModel (Effort: S)
6. **HIGH-002**: Add NL fallback and logging to SentimentService (Effort: S)
7. **HIGH-003**: Make topic gate permissive when embeddings unavailable (Effort: S)
8. **HIGH-010**: Remove keyword-AND-embedding requirement for high-confidence crisis (Effort: S)

### Week 2 — High-Priority Fixes

1. **CRIT-004**: Replace `fatalError` in DataStack.init with graceful error handling (Effort: M)
2. **HIGH-001**: Fix RecRanker pairwise gradient to Bradley-Terry (Effort: M)
3. **HIGH-004**: Add synchronization to LegacySpeechBackend (Effort: M)
4. **HIGH-006**: Replace hardcoded font sizes with Dynamic Type support (Effort: M)
5. **HIGH-007**: Move CoachAgent Core Data access off MainActor (Effort: M)
6. **MED-002**: Remove unnecessary AFM availability gate on NLEmbedding (Effort: S)
7. **MED-008**: Add reprocessDay call to submitTranscript (Effort: S)
8. **MED-009**: Localize crisis message for international users (Effort: S)

### Week 3 — Medium-Priority and Integration Fixes

1. **HIGH-009**: Add crash recovery to VectorIndex write path (Effort: M)
2. **MED-001**: Add synchronization to RecRanker and StateEstimator (Effort: S)
3. **MED-004**: Fix Core Data scalar type mismatches (Effort: M)
4. **MED-005**: Add fetch indexes to Core Data model (Effort: M)
5. **MED-006**: Make LibraryImporter import atomic (Effort: M)
6. **MED-014**: Expand PII redaction patterns (Effort: M)
7. **MED-007**: Fix anchor store read/write race (Effort: S)
8. **MED-010**: Fix OnboardingView auth bypass (Effort: S)
9. **MED-011**: Synchronize LLMGateway.inMemoryAPIKey (Effort: S)
10. **MED-013**: Remove bundled .momd or add consistency check (Effort: S)

### Later — Technical Debt and Low-Priority Improvements

1. **LOW-001**: Clean up EvidenceScorer dead domains (Effort: S)
2. **LOW-002**: Guard BaselineMath.zScore against zero MAD (Effort: S)
3. **LOW-003**: Add NaN guard to StateEstimator (Effort: S)
4. **LOW-004**: Fix sanitize punctuation dropping (Effort: S)
5. **LOW-005**: Remove duplicate #if DEBUG (Effort: S)
6. **LOW-006**: Store and cancel timeout task in SpeechService (Effort: S)
7. **LOW-007**: Log RecRanker state version mismatch (Effort: S)
8. **LOW-008**: Add deinit to CoachViewModel (Effort: S)
9. **LOW-009**: Fix fire-and-forget task leaks (Effort: S)
10. **LOW-010**: Cache DateFormatters in views (Effort: S)
11. **LOW-011**: Deduplicate TestCoreDataStack (Effort: S)
12. **LOW-012**: Remove empty PulsumTests.swift (Effort: S)
13. **LOW-013**: Enable PulsumTests in scheme (Effort: S)
14. **LOW-014**: Compile-gate KeychainService UITest fallback (Effort: S)
15. **LOW-015**: Evaluate Spline dependency necessity (Effort: S)
16. **MED-015**: Remove NSLock from VectorIndex actor (Effort: S)
17. **MED-016**: Fix timezone in DiagnosticsDayFormatter (Effort: S)

### Quick Wins (Can Fix in Under 1 Hour Each)

1. **CRIT-002**: Change two `return .safe` lines to `return .caution(...)` (5 min)
2. **CRIT-003**: Add `"nutrition"` to schema enum, add `"hrv"`, `"mindfulness"`, `"none"` to prompt (15 min)
3. **CRIT-005**: Add 15 crisis keywords to two arrays (15 min)
4. **HIGH-005**: Add `isAnalyzing = false` to `stopRecording()` (5 min)
5. **HIGH-002**: Add `NaturalLanguageSentimentProvider()` to provider array (10 min)
6. **HIGH-003**: Return `isOnTopic: true` on embedding failure (10 min)
7. **MED-008**: Add one line: `try await dataAgent.reprocessDay(date: result.date)` (5 min)
8. **LOW-005**: Delete one duplicate `#if DEBUG` line (2 min)
9. **LOW-012**: Delete or populate `PulsumTests.swift` (5 min)
10. **LOW-013**: Set `skipped = "NO"` in scheme file (2 min)

---

## Summary Table

| ID | Severity | Category | Effort | Title | Files |
|---|---|---|---|---|---|
| CRIT-001 | Critical | Data Flow | S | VectorIndex non-deterministic hashValue sharding | VectorIndex.swift |
| CRIT-002 | Critical | Security | S | FM guardrail violations default to .safe | FoundationModelsSafetyProvider.swift |
| CRIT-003 | Critical | LLM | S | Schema/prompt intentTopic enum mismatch | CoachPhrasingSchema.swift, LLMGateway.swift |
| CRIT-004 | Critical | CoreData | M | DataStack.init crashes on filesystem errors | DataStack.swift |
| CRIT-005 | Critical | Security | S | Incomplete crisis keyword lists | SafetyLocal.swift, SafetyAgent.swift |
| HIGH-001 | High | Logic | M | RecRanker pairwise gradient incorrect | RecRanker.swift |
| HIGH-002 | High | ML | S | SentimentService silent 0.0 on total failure | SentimentService.swift |
| HIGH-003 | High | ML | S | TopicGate blocks all input when embeddings down | EmbeddingTopicGateProvider.swift |
| HIGH-004 | High | Concurrency | M | LegacySpeechBackend data race | SpeechService.swift |
| HIGH-005 | High | UI | S | isAnalyzing permanently stuck | PulseViewModel.swift |
| HIGH-006 | High | Accessibility | M | All fonts ignore Dynamic Type | PulsumDesignSystem.swift |
| HIGH-007 | High | Concurrency | M | CoachAgent performAndWait blocks MainActor | CoachAgent.swift |
| HIGH-008 | High | Speech | L | ModernSpeechBackend is a stub | SpeechService.swift |
| HIGH-009 | High | Data Flow | M | Non-atomic writes in VectorIndex | VectorIndex.swift |
| HIGH-010 | High | Security | S | Crisis requires both embedding+keyword | SafetyLocal.swift |
| MED-001 | Medium | Concurrency | S | RecRanker/StateEstimator unsynchronized | RecRanker.swift, StateEstimator.swift |
| MED-002 | Medium | ML | S | AFM gate blocks functional NLEmbedding | AFMTextEmbeddingProvider.swift |
| MED-003 | Medium | ML | S | NL sentiment provider missing from chain | SentimentService.swift |
| MED-004 | Medium | CoreData | M | 19 scalar type mismatches in ManagedObjects | ManagedObjects.swift |
| MED-005 | Medium | CoreData | M | Zero relationships and fetch indexes | Pulsum.xcdatamodeld |
| MED-006 | Medium | Data Flow | M | LibraryImporter non-atomic commit | LibraryImporter.swift |
| MED-007 | Medium | HealthKit | S | Anchor store read/write race | HealthKitAnchorStore.swift |
| MED-008 | Medium | Integration | S | submitTranscript skips reprocessDay | AgentOrchestrator.swift |
| MED-009 | Medium | UI | S | Crisis message US-centric | SafetyAgent.swift |
| MED-010 | Medium | Integration | S | OnboardingView bypasses orchestrator auth | OnboardingView.swift |
| MED-011 | Medium | Concurrency | S | LLMGateway.inMemoryAPIKey unsynchronized | LLMGateway.swift |
| MED-012 | Medium | Security | S | testAPIConnection bypasses consent | LLMGateway.swift |
| MED-013 | Medium | Build | S | Compiled .momd may be stale | Package.swift |
| MED-014 | Medium | Security | M | PII redaction gaps (SSN, addresses, etc.) | PIIRedactor.swift |
| MED-015 | Medium | Concurrency | S | NSLock inside VectorIndex actor | VectorIndex.swift |
| MED-016 | Medium | Logic | S | DiagnosticsDayFormatter uses UTC | DiagnosticsTypes.swift |
| LOW-001 | Low | Logic | S | Dead domain entries in EvidenceScorer | EvidenceScorer.swift |
| LOW-002 | Low | Logic | S | zScore division by zero risk | BaselineMath.swift |
| LOW-003 | Low | Logic | S | NaN propagation in StateEstimator | StateEstimator.swift |
| LOW-004 | Low | LLM | S | Sanitize drops punctuation | LLMGateway.swift, FoundationModelsCoachGenerator.swift |
| LOW-005 | Low | Build | S | Duplicate #if DEBUG | SpeechService.swift |
| LOW-006 | Low | Memory | S | Timeout task leak in speech | SpeechService.swift |
| LOW-007 | Low | Logic | S | Silent state discard in RecRanker | RecRanker.swift |
| LOW-008 | Low | Memory | S | CoachViewModel missing deinit | CoachViewModel.swift |
| LOW-009 | Low | Memory | S | Fire-and-forget task leaks | PulseViewModel.swift, CoachViewModel.swift |
| LOW-010 | Low | Memory | S | DateFormatter per render | ScoreBreakdownView.swift, SettingsView.swift |
| LOW-011 | Low | Tests | S | Duplicate TestCoreDataStack | PulsumAgentsTests/, PulsumUITests/ |
| LOW-012 | Low | Tests | S | Empty placeholder test | PulsumTests.swift |
| LOW-013 | Low | Build | S | PulsumTests skipped in scheme | Pulsum.xcscheme |
| LOW-014 | Low | Security | S | KeychainService runtime-gated fallback | KeychainService.swift |
| LOW-015 | Low | Build | S | Evaluate Spline dependency | Package.resolved |
| STUB-001 | Stub | Speech | L | ModernSpeechBackend is placeholder | SpeechService.swift |
| STUB-002 | Stub | Architecture | L | BGTaskScheduler not implemented | N/A |
| STUB-003 | Stub | ML | S | FM TopicGate returns nil topic | FoundationModelsTopicGateProvider.swift |
| GAP-001 | Test Gap | Speech | L | Voice journal streaming untested | SentimentAgent.swift, AgentOrchestrator.swift |
| GAP-002 | Test Gap | Security | M | Safety two-wall has 3-4 tests | SafetyLocal.swift, SafetyAgent.swift |
| GAP-003 | Test Gap | HealthKit | L | HealthKit uses only stubs | HealthKitService.swift |
| GAP-004 | Test Gap | Logic | M | Wellbeing pipeline untested E2E | DataAgent.swift, StateEstimator.swift |
| GAP-005 | Test Gap | LLM | M | Cloud integration untested | LLMGateway.swift |
| GAP-006 | Test Gap | Build | S | App target has empty test | PulsumTests.swift |
| GAP-007 | Test Gap | UI | M | UI/ViewModel barely tested | PulseViewModel.swift, AppViewModel.swift |

---

## Architecture Design Review

This section evaluates whether the application's architecture is well-designed, whether technology choices are correct, and whether patterns are appropriate or overengineered.

### ARCH-001: DataAgent Is a 3,706-Line God Object — The Biggest Architectural Problem

**Severity:** High  
**Category:** Architecture  
**Files:** `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift`  
**Effort:** L  

**Description:** At 3,706 lines, `DataAgent` is a single Swift `actor` handling **10+ distinct responsibilities**: HealthKit authorization management, observer query setup, two-phase bootstrap (warm + full backfill), 5 different HealthKit sample type processing, nocturnal heart rate extraction, sleep debt calculation, z-score normalization, baseline computation, feature vector materialization, wellbeing score generation, subjective input recording, and sedentary detection.

**Architectural Impact:** (1) Changes to any one concern (e.g., sleep debt calculation) require understanding 3,700 lines of context. (2) Unit testing any single behavior requires setting up the entire actor. (3) New HealthKit data types require modifying this one massive file. (4) New developers face a steep learning curve to understand the data pipeline.

**What Good Architecture Looks Like:** Decompose into focused types:
- `HealthKitIngestionService` — authorization + observer query management
- `SampleProcessor` protocol with concrete implementations per data type (`HRVProcessor`, `SleepProcessor`, `StepProcessor`, etc.)
- `BaselineCalculator` — z-score normalization and statistics
- `FeatureVectorBuilder` — materialize feature vectors from daily metrics
- `WellbeingScoreEngine` — coordinate `StateEstimator` and score computation
- `BackfillCoordinator` — manage warm + full backfill lifecycle

The `DataAgent` actor would then become a thin coordinator delegating to these types, similar to how `AgentOrchestrator` coordinates agents.

---

### ARCH-002: Core Data Is the Wrong Choice for This Data Model

**Severity:** High  
**Category:** Architecture  
**Files:** `Packages/PulsumData/Sources/PulsumData/DataStack.swift`, `ManagedObjects.swift`, `Pulsum.xcdatamodeld`  
**Effort:** L  

**Description:** The app uses Core Data with **9 entities, zero relationships, zero fetch indexes, and pure scalar/string attributes**. The entities are essentially independent flat tables joined by manual foreign keys (e.g., `RecommendationEvent.momentId` → `MicroMoment.id`). The code never uses Core Data's strengths: object graph management, relationship faulting, cascading deletes, undo management, or iCloud sync. It uses Core Data as a dumb key-value store with SQL-like queries.

**Why This Is a Problem:**
- Core Data adds significant complexity (managed object contexts, thread safety rules, migration requirements) for features the app doesn't use.
- The `performAndWait`/`perform` context dance causes main-thread blocking (see HIGH-007).
- The `NSNumber?` vs scalar mismatch (MED-004) is a Core Data-specific footgun that wouldn't exist with a simpler store.
- The `fatalError` in `DataStack.init` (CRIT-004) is a Core Data-specific crash path.
- No relationships means no referential integrity — `RecommendationEvent` records orphan silently when `MicroMoment` records are deleted.

**What Would Be Better:**
- **SwiftData** (iOS 17+): Same Apple persistence but with Swift-native models, `@Model` macro, automatic `@Query` in SwiftUI, simplified threading. Since the app already targets iOS 26, SwiftData is fully available and would eliminate the `NSManagedObject` boilerplate, the `NSNumber?` mismatch issue, and the context threading complexity.
- **GRDB/SQLite**: For a flat-table data model with no relationships, a direct SQLite wrapper would be simpler, faster, and more testable. GRDB provides value-type records, full-text search, and WAL mode out of the box.
- **If keeping Core Data:** Add relationships, fetch indexes, and use the `@FetchRequest` property wrapper in SwiftUI instead of manual fetches + NotificationCenter.

**Note:** Migrating the persistence layer is a large undertaking. If the team chooses to keep Core Data, the minimum fix is adding relationships and fetch indexes (MED-005) to at least use Core Data correctly.

---

### ARCH-003: Custom Binary VectorIndex Is a Maintenance Liability

**Severity:** Medium  
**Category:** Architecture  
**Files:** `Packages/PulsumData/Sources/PulsumData/VectorIndex.swift`  
**Effort:** M  

**Description:** The app implements a **custom binary vector index** from scratch: a proprietary format with magic numbers (`PSVI`), versioned headers, 16-shard partitioning, append-only records with soft-delete, metadata JSON sidecars, and manual L2 distance computation. This is 437 lines of low-level binary I/O that has already produced two critical bugs (CRIT-001: non-deterministic sharding, HIGH-009: non-atomic writes).

**Why Custom Is Risky:** Custom binary formats require: correct byte alignment, endianness handling, crash recovery, corruption detection, and migration when the format changes. Each is a class of bugs that mature libraries have already solved. The VectorIndex has no checksums, no WAL, and no corruption recovery.

**What Would Be Better:**
- **SQLite FTS5 with vector extension** — Store vectors as BLOBs in SQLite. Use the `sqlite-vss` extension for L2/cosine similarity search. Gets transactional writes, crash recovery, and indexing for free.
- **Apple's `NearestNeighbors` framework** (vDSP) — For the 200-500 items in the micro-moment library, a brute-force search using Accelerate's `vDSP_distancesq` would be faster than 16-shard I/O with no complexity.
- **For the current scale (~100-500 vectors of 384 dims):** An in-memory array with periodic file-based serialization (JSON or plist) would be simpler, faster, and correct. The sharding overhead only pays off at >100K vectors.

---

### ARCH-004: The Agent Pattern Is Appropriate but Inconsistently Applied

**Severity:** Medium  
**Category:** Architecture  
**Files:** All agent files in `PulsumAgents/`  
**Effort:** M  

**Description:** The 5-agent architecture (Data, Sentiment, Coach, Safety, Cheer) coordinated by `AgentOrchestrator` is a reasonable pattern for this domain. Each agent has a clear focus area, and the orchestrator provides a unified API to the UI. However, the implementation has significant inconsistencies:

| Agent | Isolation | Lines | DI Quality | Testability | Is It Really an "Agent"? |
|---|---|---|---|---|---|
| DataAgent | `actor` | 3,706 | Excellent | Moderate | Yes — autonomous data pipeline |
| SentimentAgent | `class` | 392 | Good | Good | Partially — more of a service |
| CoachAgent | `@MainActor class` | 770 | Excellent | Good | Yes — recommendation + chat |
| SafetyAgent | `@MainActor class` | 91 | **Poor** | **Poor** | No — just a function wrapper |
| CheerAgent | `@MainActor class` | ~60 | None | Poor | No — just a string generator |

**The real question: Are "agents" the right abstraction?**
- **DataAgent** is genuinely autonomous — it manages its own lifecycle, observers, and state. Agent pattern fits.
- **CoachAgent** coordinates multiple subsystems (vector search, ranking, LLM). Agent pattern fits.
- **SentimentAgent** manages recording sessions and persistence. Agent pattern fits.
- **SafetyAgent** is a pure function: text in, classification out. It has no state, no lifecycle, no autonomy. It should be a plain function or a service, not an "agent."
- **CheerAgent** returns a random string. It's a utility function, not an agent.

**Suggested Simplification:**
- Keep DataAgent, CoachAgent, SentimentAgent as agents.
- Convert SafetyAgent to a `SafetyClassifier` service in PulsumML (it already delegates to `SafetyLocal` and `FoundationModelsSafetyProvider`).
- Convert CheerAgent to a `CheerPhraseGenerator` utility struct (stateless, pure function).
- This removes 2 of 5 agents, simplifying the orchestrator's initialization and coordination.

---

### ARCH-005: @MainActor on Agents Serializes All Work on the UI Thread

**Severity:** High  
**Category:** Architecture  
**Files:** `AgentOrchestrator.swift`, `CoachAgent.swift`, `SafetyAgent.swift`  
**Effort:** M  

**Description:** `AgentOrchestrator`, `CoachAgent`, and `SafetyAgent` are all `@MainActor`. This means every method call on these types — including ML inference (`SafetyLocal.classify`), Core Data queries (`contextPerformAndWait`), embedding computation, vector search, and LLM network requests — is serialized on the main thread.

While `async` methods suspend and don't block the run loop directly, the hop back to the main actor after each await creates contention. During the recommendation pipeline (`recommendationCards()`), the sequence is: main actor → Core Data fetch (blocks main) → back to main → vector search (suspends) → back to main → ranking → back to main. Each hop involves the main dispatch queue.

**Why This Is Wrong:**
- `DataAgent` is correctly an `actor` (its own isolation domain).
- `CoachAgent` should be an `actor` too — it does heavy Core Data + vector search work.
- `SafetyAgent` does ML inference — shouldn't be on the main thread.
- Only the UI (ViewModels) should be `@MainActor`.

**Suggested Fix:** Change `CoachAgent` and `SafetyAgent` from `@MainActor final class` to `actor`. Change `AgentOrchestrator` to `actor` with `@MainActor`-isolated properties only for UI-facing state. This moves computation off the main thread while keeping UI updates on it.

---

### ARCH-006: Singleton Sprawl Creates Hidden Coupling

**Severity:** Medium  
**Category:** Architecture  
**Files:** Multiple  
**Effort:** M  

**Description:** The codebase has **5 singletons** that create invisible coupling:

| Singleton | File | Used By |
|---|---|---|
| `DataStack.shared` | DataStack.swift | PulsumData facade, all agents |
| `PulsumData.container` (via DataStack.shared) | PulsumData.swift | LibraryImporter, agents, tests |
| `EmbeddingService.shared` | EmbeddingService.swift | SafetyLocal, TopicGate, Sentiment, agents |
| `VectorIndexManager.shared` | VectorIndexManager.swift | LibraryImporter, CoachAgent |
| `KeychainService.shared` | KeychainService.swift | LLMGateway |

**The `PulsumData` facade is the worst offender.** It's 41 lines of static accessors that all delegate to `DataStack.shared`, creating a global entry point with zero injection capability. Any code that calls `PulsumData.viewContext` is permanently coupled to the shared Core Data stack and cannot be tested in isolation.

**Why This Is Harmful:**
- Hidden dependencies — you can't see them in function signatures or init parameters.
- Test pollution — tests using `PulsumData.container` share state and contaminate each other (confirmed: Gate5_LibraryImporterPerfTests and LibraryImporterTests both write to the real shared store).
- Can't run tests in parallel — all tests sharing the same singleton Core Data stack.
- Can't swap implementations (e.g., in-memory store for testing, different stores for different features).

**Suggested Fix:**
- Replace `PulsumData` static facade with constructor injection. Each consumer should receive `NSPersistentContainer` via its init.
- Make `EmbeddingService` init public (remove singleton, pass instances through the composition root).
- Define a composition root in `AppViewModel` where all dependencies are wired, rather than scattered singletons.

---

### ARCH-007: Inconsistent Dependency Injection Across ViewModels

**Severity:** Medium  
**Category:** Architecture  
**Files:** `PulseViewModel.swift`, `CoachViewModel.swift`, `SettingsViewModel.swift`  
**Effort:** S  

**Description:** The three main ViewModels have fundamentally different DI patterns:

| ViewModel | Orchestrator Dependency | Abstracted via Protocol? | Testable? |
|---|---|---|---|
| `CoachViewModel` | Late-bound via `bind()` | **Yes** — `CoachOrchestrating` | **Good** |
| `PulseViewModel` | Late-bound via `bind()` | **No** — concrete `AgentOrchestrator` | **Poor** |
| `SettingsViewModel` | Late-bound via `bind()` | **No** — concrete `AgentOrchestrator` | **Poor** |

`CoachViewModel` is the only ViewModel that defines a protocol (`CoachOrchestrating`) for its orchestrator dependency. This makes it testable with mock orchestrators. `PulseViewModel` and `SettingsViewModel` take the concrete `AgentOrchestrator`, making them untestable without a real orchestrator (which requires real Core Data, real HealthKit, etc.).

Additionally, `SettingsViewModel` (573 lines) is a **God Object** handling 7 distinct concerns: HealthKit status, API key management, consent management, diagnostics config, diagnostics export, FM status, and debug observers. It should be decomposed into at least 3 focused ViewModels.

**Suggested Fix:**
- Define `PulseOrchestrating` and `SettingsOrchestrating` protocols (like `CoachOrchestrating`).
- Decompose `SettingsViewModel` into: `HealthSettingsViewModel`, `APIKeyViewModel`, `ConsentViewModel`, `DiagnosticsViewModel`.

---

### ARCH-008: State Observation Is Fragmented (Three Different Patterns)

**Severity:** Medium  
**Category:** Architecture  
**Files:** All ViewModel + View files  
**Effort:** M  

**Description:** The app uses three different state observation mechanisms simultaneously:

1. **`@Observable` macro** (Observation framework) — used by all ViewModels for SwiftUI binding.
2. **`NotificationCenter`** — used for `pulsumScoresUpdated` (DataAgent → AppViewModel/PulseViewModel) and `pulsumChatRouteDiagnostics` (DEBUG).
3. **Closure callbacks** — used by AppViewModel (`onConsentChanged`, `onSafetyDecision`) to wire child ViewModels.

This fragmentation means: (a) a developer must check all three mechanisms to understand how a state change propagates, (b) notification-based updates can be lost if the observer is not registered when the notification fires, (c) closure callbacks create implicit coupling that's hard to trace.

**What Would Be Cleaner:**
- Use `@Observable` as the single source of truth for UI state.
- Replace `NotificationCenter` with direct property observation or `AsyncStream`-based publishers on the orchestrator.
- Replace closure callbacks with observable properties or Combine `@Published` (since the app targets iOS 26, it could use `Observable` throughout).
- Alternative: Adopt a unidirectional data flow architecture (like TCA or a simple Redux pattern) where all state mutations flow through a single reducer, making data flow completely traceable.

---

### ARCH-009: The 6-Package Decomposition Is Mostly Correct but PulsumTypes Is a Kitchen Sink

**Severity:** Low  
**Category:** Architecture  
**Files:** All Package.swift manifests  
**Effort:** S  

**Description:** The 6-package structure is sound in principle:

```
PulsumTypes (shared types) → base
PulsumML + PulsumData → same level (both depend on PulsumTypes)
PulsumServices → depends on ML + Data
PulsumAgents → depends on Services + Data + ML
PulsumUI → depends on Agents + Data + Services
```

However:
- **PulsumTypes is a kitchen sink.** It contains: diagnostics logging (500+ lines across 5 files), speech types, timeout utilities, notification names, runtime config, and wellbeing snapshot types. The diagnostics system alone could be its own package.
- **PulsumML depends on PulsumTypes** for diagnostics logging. This means a base-layer ML package has a dependency on a types package that contains runtime config, notification names, and other non-ML concerns. This breaks the "base layer has no dependencies" principle claimed in the AGENTS.md.
- **PulsumUI depends directly on PulsumData** — meaning the UI layer knows about Core Data `NSPersistentContainer`, `NSManagedObjectContext`, etc. Ideally, the UI should only depend on PulsumAgents (which provides the orchestrator facade), not on the data layer directly.

**Suggested Improvements:**
- Extract `PulsumDiagnostics` as a separate package.
- Remove PulsumUI's direct dependency on PulsumData — have the orchestrator expose all needed data through its API instead.

---

### Architecture Summary Score Card

| Dimension | Score | Assessment |
|---|---|---|
| **Package decomposition** | 7/10 | Good structure, minor package boundary issues |
| **Technology choices** | 4/10 | Core Data wrong fit, custom vector index risky, no backend for LLM |
| **Agent pattern** | 6/10 | Appropriate for 3/5 agents, overcomplicated for Safety/Cheer |
| **Dependency injection** | 5/10 | Excellent in agents, poor in ViewModels, singletons everywhere |
| **Testability** | 4/10 | Great DI on agents, untestable ViewModels, singleton Core Data |
| **Concurrency model** | 4/10 | DataAgent correct (actor), others wrong (@MainActor for computation) |
| **State management** | 5/10 | Three fragmented observation patterns |
| **Code organization** | 3/10 | DataAgent (3,700 lines), SettingsVM (573 lines) are God Objects |
| **Scalability** | 5/10 | Adding new HealthKit types requires touching the DataAgent monolith |
| **Overall Architecture** | 4.5/10 | Solid foundations, significant design issues |

---

## Production-Readiness and App Store Compliance Findings

This section was added on 2026-02-05 after a production-readiness audit that goes beyond code correctness to assess whether the app is built as a proper production iOS application suitable for App Store distribution.

### PROD-001: No Monetization Infrastructure (No StoreKit, No Paywall, No Subscriptions)

**Severity:** Critical (Business)  
**Category:** Architecture  
**Files:** None — entirely missing  
**Effort:** L  

**Description:** The app has zero StoreKit integration. There is no paywall, no subscription management, no in-app purchase flow, no receipt validation, and no "Restore Purchases" button. The app relies on the OpenAI GPT-5 API for cloud coaching, which costs money per API call. The current model requires users to bring their own API key (entered in Settings), which is viable for developer testing but not for mass-market App Store distribution.

**Impact:** (1) The average iOS user does not have an OpenAI API key and will not know how to obtain one. The cloud coaching feature is effectively inaccessible to 99%+ of potential users. (2) Without a revenue model, the app cannot sustain itself. (3) Apple may reject the app under Guideline 3.1.1 if it directs users to obtain a key outside the app for a paid service without using IAP.

**Suggested Fix:** Implement one of: (a) StoreKit 2 subscription with server-side API key management (the app calls your backend, which calls OpenAI); (b) A freemium model where on-device coaching is free and cloud coaching is a paid subscription; (c) If keeping BYOK, add clear onboarding explaining the API key requirement and make on-device coaching the primary experience with cloud as optional.

**What Should Exist:**
- `StoreKit/SubscriptionManager.swift` — manages subscription status
- `StoreKit/PaywallView.swift` — presents subscription tiers
- `StoreKit/ReceiptValidator.swift` — validates App Store receipts
- Server-side API key management (users pay you, you manage the OpenAI key)
- "Restore Purchases" in Settings

---

### PROD-002: Zero Crash Reporting — Production Crashes Are Invisible

**Severity:** Critical (Operations)  
**Category:** Observability  
**Files:** None — entirely missing  
**Effort:** M  

**Description:** No crash reporting SDK is integrated (no Firebase Crashlytics, Sentry, BugSnag, or even Apple's MetricKit/MXCrashDiagnostic). The app has 3 `fatalError()` calls in DataStack.init and multiple force-unwrap paths. When these crash in production, the team has no way to know — crashes go unreported and undiagnosed.

**Impact:** Users experience crashes silently. The team cannot prioritize fixes because they don't know which crashes are happening, how frequently, or on which devices/OS versions. This is especially dangerous for a health app where a crash during crisis detection could have serious consequences.

**Suggested Fix:** Integrate MetricKit (zero-dependency, Apple-native) at minimum:
```swift
import MetricKit
class CrashDiagnosticsSubscriber: NSObject, MXMetricManagerSubscriber {
    func didReceive(_ payloads: [MXDiagnosticPayload]) { /* log/upload */ }
}
```
For richer reporting, add Sentry or Crashlytics. Ensure symbolication is configured (dSYM upload in CI).

---

### PROD-003: Zero Analytics — No Way to Measure Product Success

**Severity:** High (Business)  
**Category:** Observability  
**Files:** None — entirely missing  
**Effort:** M  

**Description:** No analytics framework exists. The app has an excellent internal `DiagnosticsLogger` for technical debugging, but zero product analytics. There is no tracking of: onboarding completion rate, daily active users, journal recording frequency, coaching engagement, recommendation interaction rates, subscription conversion, or retention.

**Impact:** The team cannot measure whether the product is working. Product decisions (which features to improve, what's driving churn, what's the activation funnel) have no data backing. This makes product-market fit iteration impossible.

**Suggested Fix:** Integrate a privacy-respecting analytics framework. Options: TelemetryDeck (privacy-first, EU-hosted), PostHog (self-hostable), or Firebase Analytics. Track at minimum: `onboarding_completed`, `journal_recorded`, `score_viewed`, `recommendation_tapped`, `recommendation_completed`, `chat_sent`, `settings_changed`, `api_key_added`.

---

### PROD-004: No Network Reachability Monitor — No Offline Indicator

**Severity:** High (UX)  
**Category:** Networking  
**Files:** None — entirely missing  
**Effort:** S  

**Description:** The app does not use `NWPathMonitor` or any network reachability check. When the device is offline, cloud coaching silently fails and falls back to on-device, but the user receives no indication that they're offline or that the coaching quality may differ. The `LLMGateway` has no timeout configuration on its `URLSession` — it uses system defaults (60s resource timeout).

**Impact:** Users on airplane mode or with poor connectivity wait up to 60 seconds for a coaching response before the fallback activates. There's no "You're offline — using on-device coaching" message. Network errors surface as generic failures rather than user-friendly offline messages.

**Suggested Fix:** Add a `NetworkMonitor` actor using `NWPathMonitor`:
```swift
actor NetworkMonitor {
    static let shared = NetworkMonitor()
    var isConnected: Bool { /* NWPathMonitor */ }
}
```
Check connectivity before cloud requests. Show a subtle banner when offline. Set explicit timeouts on URLSession (15s for coaching requests).

---

### PROD-005: No Health Disclaimer — App Store Rejection Risk

**Severity:** High (Compliance)  
**Category:** Security  
**Files:** `OnboardingView.swift`, `SettingsView.swift`  
**Effort:** S  

**Description:** The app provides wellness coaching, wellbeing scores, and crisis detection but displays no health disclaimer stating "This app does not provide medical advice. Consult a healthcare professional for medical concerns." Apple's App Store Review Guidelines (4.2) require health apps to include such a disclaimer. The system prompt in `LLMGateway.swift` tells the model to "Avoid disclaimers," which may remove them from coaching responses.

**Impact:** Apple will likely reject the app during review. Without a disclaimer, the app may face liability if users rely on its wellness scores or coaching as medical advice, particularly given the crisis detection feature that recommends calling 911.

**Suggested Fix:** Add a health disclaimer to: (1) the onboarding flow (must acknowledge before proceeding), (2) the Settings screen (always accessible), (3) the app's App Store description. Review the LLM system prompt to ensure it includes appropriate wellness boundaries.

---

### PROD-006: No Data Deletion Capability — GDPR/CCPA Non-Compliance

**Severity:** High (Compliance)  
**Category:** Security  
**Files:** `SettingsView.swift`, `SettingsViewModel.swift`  
**Effort:** M  

**Description:** Settings has "Clear diagnostics" (logs only) but no "Delete All My Data" button. Users cannot delete their health data, journal entries, wellbeing scores, feature vectors, or recommendation history. Under GDPR (EU) and CCPA (California), users have the right to erasure of all personal data. Apple requires apps collecting health data to provide a data deletion mechanism (Guideline 5.1.1).

**Impact:** Non-compliant with GDPR/CCPA. Apple may require a data deletion mechanism during review. EU users have a legal right to request data deletion that the app cannot fulfill.

**Suggested Fix:** Add a "Delete All Data" action in Settings that:
1. Deletes all Core Data entities (JournalEntry, DailyMetrics, Baseline, FeatureVector, etc.)
2. Clears the vector index directory
3. Removes Keychain entries (API key)
4. Clears UserDefaults (except `hasLaunched`)
5. Resets the app to the onboarding state
6. Presents a confirmation dialog ("This cannot be undone")

---

### PROD-007: No Onboarding Persistence — Users May Re-Onboard

**Severity:** High (UX)  
**Category:** UI  
**Files:** `AppViewModel.swift`, `PulsumRootView.swift`  
**Effort:** S  

**Description:** Searching the codebase for `onboardingCompleted`, `hasCompletedOnboarding`, `showOnboarding`, or `needsOnboarding` returns zero results. The `firstLaunch` flag in `AppViewModel.swift` (line 74) uses a UserDefaults key `launchKey` to track first launch, but onboarding completion itself does not appear to be persisted. If the onboarding view's visibility is driven by HealthKit authorization status (which resets for new app installs), users may be shown onboarding repeatedly or never at all depending on the state.

**Impact:** Users who partially complete onboarding (grant some permissions but not others) may see the onboarding screen again on next launch. Or the app may skip onboarding for users who already have HealthKit permissions from a previous install, bypassing the consent flow.

**Suggested Fix:** Add an explicit `@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false` flag. Set it after the user completes the full onboarding flow (permissions + consent). Use it to drive onboarding visibility in `PulsumRootView`.

---

### PROD-008: All 500+ User-Facing Strings Are Hardcoded (No Localization)

**Severity:** Medium (Production)  
**Category:** UI  
**Files:** All UI view files  
**Effort:** L  

**Description:** Every user-facing string in every SwiftUI view is a hardcoded English literal. There are no `.strings` files, no String Catalogs, no `LocalizedStringKey` usage, and no `NSLocalizedString` calls. The project has `LOCALIZATION_PREFERS_STRING_CATALOGS = YES` in build settings but no string catalog files exist.

**Impact:** (1) The app cannot be localized to any other language without touching every view file. (2) Apple's localization infrastructure (String Catalogs, export for translators) cannot be used. (3) This is a massive technical debt that grows with every new string added.

**Suggested Fix:** For immediate release, this can remain English-only, but extract all strings to a String Catalog. SwiftUI's `Text("string")` automatically uses `LocalizedStringKey` — create a `Localizable.xcstrings` file and the existing strings become the English base. This is a one-time effort that enables future localization.

---

### PROD-009: No Core Data Migration Strategy

**Severity:** Medium (Production)  
**Category:** CoreData  
**Files:** `DataStack.swift`, `Pulsum.xcdatamodeld`  
**Effort:** M  

**Description:** `DataStack.swift` enables lightweight migration (`shouldMigrateStoreAutomatically = true` and `shouldInferMappingModelAutomatically = true` are the defaults). However, there is only one model version (verified by `.xccurrentversion`), and no explicit migration policy. The model has no versioned history. If a future update changes the Core Data model (adds attributes, changes types), the migration must be carefully planned. Currently, a model change that isn't lightweight-migration-compatible would crash the app on update.

**Impact:** Any non-trivial Core Data model change in a future version will either: (a) crash the app for existing users if the migration isn't lightweight-compatible, or (b) require a new model version + mapping model that doesn't exist yet.

**Suggested Fix:** (1) Enable explicit lightweight migration in `DataStack.swift` if not already present. (2) Before any model change, create a new model version in the `.xcdatamodeld`. (3) Add a CI check that verifies the current model is migration-compatible with the previous version.

---

### PROD-010: No SSL/Certificate Pinning for OpenAI API

**Severity:** Medium (Security)  
**Category:** Networking  
**Files:** `LLMGateway.swift`  
**Effort:** M  

**Description:** The app sends API keys and user context to `api.openai.com` via HTTPS, but does not implement certificate pinning. A man-in-the-middle attack with a compromised CA certificate could intercept API keys and user health context in transit.

**Impact:** On compromised networks (corporate proxies, state-level surveillance, rogue Wi-Fi hotspots), an attacker with a trusted root CA could intercept the OpenAI API key and all coaching context (which includes health metrics and journal sentiment).

**Suggested Fix:** Implement certificate pinning for `api.openai.com` using `URLSessionDelegate`'s `urlSession(_:didReceive:completionHandler:)` to validate the server certificate against a pinned public key.

---

### PROD-011: No App Rating Prompt

**Severity:** Low (Growth)  
**Category:** UI  
**Files:** None — missing  
**Effort:** S  

**Description:** No `SKStoreReviewController.requestReview()` or `@Environment(\.requestReview)` usage. The app never prompts users to rate it on the App Store.

**Impact:** Without rating prompts, the app accumulates no App Store ratings, which dramatically hurts discoverability and social proof. Health/wellness apps compete on trust, and ratings are a critical signal.

**Suggested Fix:** Add `requestReview()` after positive engagement moments (e.g., after a user views their wellbeing score for the 5th time, or after completing their 3rd journal entry). Limit to once per version.

---

### PROD-012: No Widget / Siri / App Intents Integration

**Severity:** Low (Growth)  
**Category:** Architecture  
**Files:** None — missing  
**Effort:** L  

**Description:** The app has zero platform integration beyond HealthKit. For a wellness app, these are expected iOS features: WidgetKit (at-a-glance wellbeing score on home screen), App Intents / Siri Shortcuts ("Hey Siri, how am I doing today?"), and Live Activities (during voice journal recording). None are implemented.

**Impact:** The app feels like a silo rather than a first-class iOS citizen. Users can't glance at their wellbeing score without opening the app. Siri integration would be natural for a voice-journal app.

**Suggested Fix:** Start with a simple WidgetKit widget displaying the latest wellbeing score. Add an `AppIntent` for "Check my wellbeing." These are relatively low-effort and high-impact for user engagement and App Store visibility.

---

### PROD-013: Version 1.0 Build 1 — No Versioning Strategy

**Severity:** Low (Operations)  
**Category:** Build  
**Files:** `project.pbxproj`  
**Effort:** S  

**Description:** `MARKETING_VERSION = 1.0` and `CURRENT_PROJECT_VERSION = 1` across all targets. There's no CI-driven build number increment, no version bumping script, and no apparent versioning strategy.

**Impact:** Multiple builds submitted to App Store Connect will conflict on the same build number. TestFlight builds will be indistinguishable. Crash reports won't map to specific builds.

**Suggested Fix:** Auto-increment `CURRENT_PROJECT_VERSION` in CI (e.g., from git commit count or CI build number). Use semantic versioning for `MARKETING_VERSION` (1.0.0 → 1.0.1 → 1.1.0).

---

### PROD-014: Debug Logging May Leak Sensitive Data in Release

**Severity:** Medium (Security)  
**Category:** Observability  
**Files:** `DiagnosticsLogger.swift`, `LLMGateway.swift`  
**Effort:** S  

**Description:** The `DiagnosticsLogger` is active in Release builds (configured with `minLevel: .info` in Release). While the diagnostics system uses `DiagnosticsSafeString` for redaction, the `LLMGateway.swift` line 765 logs GPT response snippets including the literal text `, privacy: .public)` as part of the string (a parenthesis bug). Additionally, the diagnostics report builder (`DiagnosticsReportBuilder`) includes the wellbeing score in export files that users can share.

**Impact:** Diagnostic exports shared by users (e.g., for bug reports) may contain wellbeing scores, which are PHI. The logging parenthesis bug means log lines contain unintended metadata strings.

**Suggested Fix:** (1) Audit all Release-mode log calls for PII/PHI content. (2) Fix the logging parenthesis bug in `LLMGateway.swift`. (3) Add a "Sensitive data may be included" warning when exporting diagnostics. (4) Consider stripping wellbeing scores from exports or requiring explicit user confirmation.

---

### PROD-015: No Rate Limiting on OpenAI API Calls

**Severity:** Medium (Operations)  
**Category:** Networking  
**Files:** `LLMGateway.swift`  
**Effort:** S  

**Description:** The `LLMGateway` has no client-side rate limiting. A user could rapidly send chat messages, each triggering a cloud API call. There's no throttle, no queue, and no usage counter.

**Impact:** (1) A user (or a bug in the UI) could burn through API quota rapidly. (2) OpenAI rate limits could be hit, causing cascading failures. (3) If the app manages API keys server-side in the future, unbounded client requests could cause significant cost.

**Suggested Fix:** Add a simple rate limiter (e.g., max 1 cloud request per 3 seconds, max 20 per hour). Show "Please wait" if the user sends messages too quickly.

---

### PROD-016: No Offline Mode Indicator or Graceful Degradation UX

**Severity:** Medium (UX)  
**Category:** UI  
**Files:** `CoachView.swift`, `PulseView.swift`  
**Effort:** S  

**Description:** When offline, the coaching chat silently falls back to on-device generation. The user has no indication that responses may be lower quality or that cloud features are unavailable. The "Test Connection" button in Settings is the only connectivity check, and it requires manual user action.

**Suggested Fix:** Show a subtle banner "You're offline — using on-device coaching" when `NWPathMonitor` reports no connectivity. Show a connectivity indicator in the coach view.

---

### PROD-017: UserDefaults Keys Are Raw Strings Without Type Safety

**Severity:** Low (Code Quality)  
**Category:** Architecture  
**Files:** `AppViewModel.swift`, `SettingsView.swift`, `DiagnosticsTypes.swift`  
**Effort:** S  

**Description:** UserDefaults keys are scattered raw strings: `"ai.pulsum.diagnostics.config"`, `"pulsum.uitest"`, and the `launchKey` in `AppViewModel`. There's no centralized key enum, no `@AppStorage` property wrappers for persistent settings, and no type-safe access pattern.

**Impact:** Typos between read and write sites would cause silent data loss. Adding new persisted settings requires knowing all existing keys to avoid collisions.

**Suggested Fix:** Create a `PulsumDefaults` enum with all keys:
```swift
enum PulsumDefaults {
    static let hasLaunched = "ai.pulsum.hasLaunched"
    static let diagnosticsConfig = "ai.pulsum.diagnostics.config"
    // ...
}
```

---

### PROD-018: HealthKit Data Displayed Without Units or Context

**Severity:** Low (UX)  
**Category:** UI  
**Files:** `ScoreBreakdownView.swift`  
**Effort:** S  

**Description:** The wellbeing score breakdown shows z-scores and raw metric values, but it's unclear whether the score display includes proper units (ms for HRV, bpm for heart rate, hours for sleep, steps for steps). Health data displayed without units can be misleading or confusing to users.

**Suggested Fix:** Ensure all health metrics are displayed with appropriate units and context labels (e.g., "HRV: 45 ms", "Resting HR: 62 bpm", "Sleep: 7.2 hrs").

---

## Production-Readiness Summary

| Area | Status | Key Gap |
|---|---|---|
| **Monetization** | Missing | No StoreKit, no paywall, BYOK API key model |
| **Crash Reporting** | Missing | No Crashlytics/Sentry/MetricKit |
| **Analytics** | Missing | No product analytics framework |
| **Network Monitoring** | Missing | No NWPathMonitor, no offline indicator |
| **Health Disclaimer** | Missing | No medical disclaimer (App Store rejection risk) |
| **Data Deletion** | Missing | No GDPR/CCPA data erasure capability |
| **Onboarding Persistence** | Unclear | No explicit completion flag found |
| **Localization** | Missing | 500+ hardcoded English strings |
| **Core Data Migration** | Minimal | Single model version, no migration plan |
| **SSL Pinning** | Missing | API key sent without certificate pinning |
| **App Rating** | Missing | No SKStoreReviewController |
| **Platform Integration** | Missing | No Widgets, Siri, App Intents |
| **Versioning** | Minimal | Version 1.0 Build 1, no CI automation |
| **Rate Limiting** | Missing | No client-side API request throttling |
| **Offline UX** | Missing | No offline indicator or degradation messaging |
| **Privacy Policy** | Partial | Link exists in Settings but no in-app disclaimer |
| **Data Export** | Missing | No health data export for users |
| **File Protection** | Present | NSFileProtectionComplete correctly applied |
| **Keychain Security** | Present | Correct accessibility attributes |
| **PII Redaction** | Partial | Covers emails/phones/names, misses SSN/cards |

### Production-Readiness Score: 2.5 / 10

The app has excellent architecture and competent security fundamentals (file protection, Keychain, PII redaction, consent gating) but is missing nearly every production operational requirement. It reads like a well-built prototype that has never been through an App Store submission.

---

## Updated Action Plan (Including Production Readiness)

### Pre-Submission Blockers (Must Fix Before App Store Submission)

1. **PROD-005**: Add health disclaimer to onboarding + settings (Effort: S) — **App Store rejection risk**
2. **PROD-006**: Add "Delete All Data" capability for GDPR/CCPA (Effort: M) — **Legal requirement**
3. **PROD-001**: Decide monetization model and implement StoreKit or document BYOK clearly (Effort: L) — **Business viability**
4. **PROD-002**: Integrate crash reporting (MetricKit minimum) (Effort: M) — **Operational necessity**
5. **CRIT-001-005**: Fix all Critical technical issues (Effort: S-M) — **App stability**

### Post-Submission Priority

6. **PROD-003**: Add analytics framework (Effort: M)
7. **PROD-004**: Add network reachability monitor + offline UX (Effort: S)
8. **PROD-007**: Persist onboarding completion state (Effort: S)
9. **HIGH-001-010**: Fix all High technical issues (Effort: M-L)
10. **PROD-013**: Set up CI versioning (Effort: S)

### Quick Production Wins (Under 1 Hour Each)

1. **PROD-005**: Add disclaimer text to OnboardingView (30 min)
2. **PROD-007**: Add `@AppStorage("hasCompletedOnboarding")` flag (15 min)
3. **PROD-011**: Add `requestReview()` after 5th score view (15 min)
4. **PROD-013**: Add build number from git count in CI (15 min)
5. **PROD-017**: Create centralized UserDefaults key enum (30 min)

---

## Updated Summary Table (Including Architecture + Production Findings)

### Architecture Findings

| ID | Severity | Category | Effort | Title | Files |
|---|---|---|---|---|---|
| ARCH-001 | High | Architecture | L | DataAgent is a 3,706-line God Object | DataAgent.swift |
| ARCH-002 | High | Architecture | L | Core Data is wrong choice for flat-table model | DataStack.swift, ManagedObjects.swift |
| ARCH-003 | Medium | Architecture | M | Custom binary VectorIndex is a liability | VectorIndex.swift |
| ARCH-004 | Medium | Architecture | M | Agent pattern inconsistently applied (Safety/Cheer aren't agents) | SafetyAgent.swift, CheerAgent.swift |
| ARCH-005 | High | Architecture | M | @MainActor on agents serializes computation on UI thread | AgentOrchestrator.swift, CoachAgent.swift |
| ARCH-006 | Medium | Architecture | M | 5 singletons create hidden coupling | DataStack.swift, PulsumData.swift, EmbeddingService.swift |
| ARCH-007 | Medium | Architecture | S | Inconsistent DI across ViewModels (only CoachVM uses protocol) | PulseViewModel.swift, SettingsViewModel.swift |
| ARCH-008 | Medium | Architecture | M | 3 fragmented state observation patterns | All ViewModels |
| ARCH-009 | Low | Architecture | S | PulsumTypes is a kitchen sink; PulsumUI depends on PulsumData | Package.swift files |

### Production Findings

| ID | Severity | Category | Effort | Title | Files |
|---|---|---|---|---|---|
| PROD-001 | Critical | Architecture | L | No monetization (StoreKit/paywall/subscription) | Missing |
| PROD-002 | Critical | Observability | M | Zero crash reporting | Missing |
| PROD-003 | High | Observability | M | Zero analytics framework | Missing |
| PROD-004 | High | Networking | S | No network reachability monitor | Missing |
| PROD-005 | High | Security | S | No health disclaimer (App Store rejection risk) | OnboardingView.swift, SettingsView.swift |
| PROD-006 | High | Security | M | No data deletion (GDPR/CCPA non-compliant) | SettingsViewModel.swift |
| PROD-007 | High | UI | S | No onboarding persistence | AppViewModel.swift, PulsumRootView.swift |
| PROD-008 | Medium | UI | L | All strings hardcoded (no localization) | All UI files |
| PROD-009 | Medium | CoreData | M | No migration strategy | DataStack.swift |
| PROD-010 | Medium | Networking | M | No SSL pinning for API | LLMGateway.swift |
| PROD-011 | Low | UI | S | No app rating prompt | Missing |
| PROD-012 | Low | Architecture | L | No Widget/Siri/App Intents | Missing |
| PROD-013 | Low | Build | S | Version 1.0 Build 1, no CI versioning | project.pbxproj |
| PROD-014 | Medium | Observability | S | Debug logging may leak PHI in Release | DiagnosticsLogger.swift, LLMGateway.swift |
| PROD-015 | Medium | Networking | S | No rate limiting on API calls | LLMGateway.swift |
| PROD-016 | Medium | UI | S | No offline mode indicator | CoachView.swift, PulseView.swift |
| PROD-017 | Low | Architecture | S | UserDefaults keys are raw strings | AppViewModel.swift, DiagnosticsTypes.swift |
| PROD-018 | Low | UI | S | Health data without units/context | ScoreBreakdownView.swift |
