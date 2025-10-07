# Pulsum Roadmap v3 - Architecture Review & Action Plan

**Generated:** October 1, 2025
**Based on:** Complete architecture analysis post-Milestone 4
**Status:** Milestone 4 complete, identifying issues before Milestone 5-6

---

## Executive Summary

Following a comprehensive codebase analysis of all 78 Swift files (~15,000 LOC) across 5 packages, this roadmap identifies **15 architectural issues** ranging from critical App Store blockers to future scalability concerns.

**Immediate blockers:** 3 critical issues must be resolved before App Store submission.
**ML/AI concerns:** 3 major issues affect model validity and personalization.
**Performance risks:** 2 issues may cause UI lag or data inconsistency at scale.

---

## Table of Contents

1. [Critical Issues (Must Fix Before Submission)](#1-critical-issues-must-fix-before-submission)
2. [Major Design Issues (Should Fix for v1.0)](#2-major-design-issues-should-fix-for-v10)
3. [Minor Issues (Future Improvements)](#3-minor-issues-future-improvements)
4. [Implementation Roadmap](#4-implementation-roadmap)
5. [Risk Assessment](#5-risk-assessment)
6. [Testing Strategy](#6-testing-strategy)

---

## 1. Critical Issues (Must Fix Before Submission)

### 🔴 Issue #1: Hardcoded API Key in Production Code

**Location:** `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift`

**Problem:**
```swift
// SECURITY BREACH: Hardcoded API key will be exposed in App Store binary
private let hardcodedAPIKey = "sk-proj-CV00PjpfJjs..."
```

**Impact:**
- ⚠️ **Security breach:** Anyone can decompile the app and extract the API key
- 💰 **Cost liability:** Malicious users could rack up OpenAI API charges
- 🚫 **App Store rejection risk:** Apple may reject apps with hardcoded credentials

**Solution:**
```swift
// Option A: Remove hardcoded key entirely
private let hardcodedAPIKey: String? = nil

// Option B: Use environment variable (for development only)
#if DEBUG
private let hardcodedAPIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
#else
private let hardcodedAPIKey: String? = nil
#endif

// Option C: Server-side proxy (recommended for production)
// Client → Your server → OpenAI API
// Never expose key to client
```

**Action Items:**
- [ ] Remove hardcoded key from `LLMGateway.swift`
- [ ] Update `LLMGateway.testAPIConnection()` to handle missing key gracefully
- [ ] Decide on key injection strategy:
  - User-provided keys (add UI in Settings)
  - Server-side proxy (requires backend infrastructure)
  - Disable GPT-5 entirely for v1.0 (rely on Foundation Models only)
- [ ] Audit entire codebase for other hardcoded secrets: `git grep -i "sk-proj"`, `git grep -i "api.*key"`

**Effort:** 🟢 Low (2-4 hours)
**Priority:** 🔴 **BLOCKER** - Must fix before submission

---

### 🔴 Issue #2: Missing Privacy Manifests (App Store Requirement)

**Location:** All packages + main app

**Problem:**
iOS 17+ requires `PrivacyInfo.xcprivacy` files for all packages using "Required-Reason APIs". Currently missing:
- `Pulsum/PrivacyInfo.xcprivacy` (main app)
- `Packages/PulsumData/PrivacyInfo.xcprivacy`
- `Packages/PulsumServices/PrivacyInfo.xcprivacy`
- `Packages/PulsumML/PrivacyInfo.xcprivacy`
- `Packages/PulsumAgents/PrivacyInfo.xcprivacy`

**Impact:**
- 🚫 **App Store rejection on submission** (automated rejection, no human review)

**Required Declarations:**

| API Category | Reason Code | Usage in Pulsum |
|--------------|-------------|-----------------|
| File timestamp APIs | C617.1 | Access info about files inside app container (Core Data, vector index) |
| Disk space APIs | E174.1 | Display disk space information to user (storage management) |
| User defaults APIs | CA92.1 | Access info previously stored by app (consent state, preferences) |

**Solution:**

Create `PrivacyInfo.xcprivacy` in each package:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <!-- File timestamp access -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string>
            </array>
        </dict>
        <!-- User defaults access -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
        <!-- Disk space (main app only) -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryDiskSpace</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>E174.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

**Action Items:**
- [ ] Create `Pulsum/PrivacyInfo.xcprivacy` (main app)
- [ ] Create `Packages/PulsumData/PrivacyInfo.xcprivacy`
- [ ] Create `Packages/PulsumServices/PrivacyInfo.xcprivacy`
- [ ] Create `Packages/PulsumML/PrivacyInfo.xcprivacy`
- [ ] Create `Packages/PulsumAgents/PrivacyInfo.xcprivacy`
- [ ] Add Privacy Manifests to Xcode project (must be in `Copy Bundle Resources`)
- [ ] Verify SplineRuntime SDK includes its own Privacy Manifest (check SPM package)
- [ ] Test App Store validation: `xcrun altool --validate-app` or upload to TestFlight

**Resources:**
- [Apple: Privacy Manifest Files](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [Apple: Required Reason API](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api)

**Effort:** 🟢 Low (4-6 hours)
**Priority:** 🔴 **BLOCKER** - Must fix before submission

---

### 🔴 Issue #3: Unsafe Objective-C Runtime Code (Currently Disabled)

**Location:** `Packages/PulsumML/Sources/PulsumML/Embedding/AFMTextEmbeddingProvider.swift`

**Problem:**
```swift
// TEMPORARILY DISABLED due to unsafe runtime code
// Original implementation used Objective-C runtime to access private NLContextualEmbedding APIs
// Currently falling back to NLEmbedding.wordEmbedding (lower quality)
```

**Impact:**
- 📉 **Reduced embedding quality:** Word embeddings are significantly lower quality than contextual embeddings
- 🎯 **Recommendation relevance:** Vector search may return less relevant results
- 😔 **Sentiment accuracy:** Sentiment analysis may miss nuanced emotions

**Current Fallback Chain:**
```
AFMTextEmbeddingProvider (disabled)
    ↓
NLEmbedding.wordEmbedding (current default)
    ↓
CoreMLEmbeddingFallbackProvider
    ↓
Zero vector [0.0, 0.0, ...]
```

**Solution Options:**

**Option A: Fine-tuned Core ML Model (Recommended)**
```swift
// Replace word embeddings with sentence transformer
// Model: all-MiniLM-L6-v2 (384 dimensions, 22MB)
// Export from HuggingFace → Core ML using coremltools

import CoreML

final class CoreMLSentenceEmbedding: TextEmbeddingProviding {
    private let model: MLModel

    func embedding(for text: String) -> [Float] {
        let input = SentenceEmbeddingInput(text: text)
        let output = try? model.prediction(from: input)
        return output?.embedding ?? [Float](repeating: 0, count: 384)
    }
}
```

**Option B: Use NLContextualEmbedding Safely (iOS 17+)**
```swift
// Apple officially supports NLContextualEmbedding in iOS 17+
// No private API access needed
if #available(iOS 17.0, *) {
    let embedding = NLContextualEmbedding.contextualEmbedding(
        for: .english,
        revision: NLContextualEmbeddingRevision.latest
    )
    // Use embedding.vector(for: sentence) with proper error handling
}
```

**Option C: Foundation Models Embeddings (iOS 26+)**
```swift
// Wait for Apple to expose embedding APIs in Foundation Models
// (Not available in current iOS 26 beta)
```

**Action Items:**
- [ ] Research safe NLContextualEmbedding API (iOS 17+) - verify no private APIs needed
- [ ] Test NLContextualEmbedding on iOS 17+ devices
- [ ] If safe API exists, re-enable contextual embeddings
- [ ] If not, create Core ML sentence transformer:
  - [ ] Export all-MiniLM-L6-v2 from HuggingFace
  - [ ] Convert to Core ML using `coremltools`
  - [ ] Add to `Resources/PulsumSentenceEmbedding.mlmodel`
  - [ ] Update `EmbeddingService` to use new provider
- [ ] Run embedding quality evaluation:
  - [ ] Create test set of 50 recommendation pairs
  - [ ] Measure cosine similarity for related vs. unrelated pairs
  - [ ] Compare word embeddings vs. new approach

**Effort:** 🔴 High (2-3 days for Core ML model export + integration)
**Priority:** 🟡 Medium - Affects quality but not functionality

---

## 2. Major Design Issues (Should Fix for v1.0)

### ⚠️ Issue #4: StateEstimator Training Target is Circular

**Location:** `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:857`

**Problem:**
```swift
// Circular logic: Model learns to predict a target computed from its own features
let target = -0.35 * z_hrv + -0.25 * z_steps + -0.4 * z_sleepDebt
             + 0.45 * subj_stress + -0.4 * subj_energy + 0.3 * subj_sleepQuality

// Then StateEstimator learns: score = Σ(weight_i * feature_i) + bias
// Model converges to replicate the hardcoded formula, defeating the purpose of ML
```

**Why This Is Wrong:**

1. **No Ground Truth:** What is "wellbeing"? The target formula is arbitrary.
2. **Contradictory Weights:** Target has `z_hrv: -0.35`, but StateEstimator initializes with `z_hrv: -0.6`
3. **Defeats ML Purpose:** The model learns to mimic a hardcoded formula instead of discovering patterns

**Impact:**
- 🤔 **Scientifically invalid:** Model isn't learning anything meaningful
- 📊 **No personalization:** All users converge to the same hardcoded weights
- 🚫 **Can't validate:** No way to measure if model is accurate

**Solution:**

**Option A: Subjective Wellbeing as Ground Truth (Recommended)**
```swift
// Use only subjective inputs as target
// Objective metrics (HRV, sleep, steps) are features
let subjectiveWellbeing = (
    (7 - subj_stress) +  // Invert stress (high stress = low wellbeing)
    subj_energy +
    subj_sleepQuality
) / 3.0  // Normalize to [1, 7] scale

// Model learns: Can we predict subjective wellbeing from objective health metrics?
let target = subjectiveWellbeing

// Then StateEstimator uses only objective features:
let features = [
    "z_hrv": z_hrv,
    "z_nocthr": z_nocthr,
    "z_resthr": z_resthr,
    "z_sleepDebt": z_sleepDebt,
    "z_rr": z_rr,
    "z_steps": z_steps
    // Note: No subjective inputs in features!
]
```

**Option B: Remove Supervised Learning Entirely**
```swift
// Use StateEstimator as a fixed scoring function (no training)
// Accept that weights are research-based, not learned
let estimator = StateEstimator(config: .fixedWeights)
estimator.disableTraining()

// Or use unsupervised approach:
// - Cluster users based on health patterns
// - Detect anomalies (when today's metrics deviate from baseline)
```

**Option C: Collect External Validation**
```swift
// Add daily prompt: "How are you feeling today?" (1-10 scale)
// Use this as ground truth for training
let target = userReportedWellbeing  // From daily check-in

// Model learns: Predict user's self-reported wellbeing from health metrics
```

**Action Items:**
- [ ] Decide on approach (Option A recommended for v1.0)
- [ ] If Option A:
  - [ ] Refactor `computeTarget()` to use only subjective inputs
  - [ ] Update `StateEstimator.update()` to use only objective features
  - [ ] Update `ScoreBreakdown` to clarify: "Predicted wellbeing based on health metrics"
- [ ] If Option B:
  - [ ] Remove training loop entirely
  - [ ] Document fixed weights in `StateEstimator.swift`
  - [ ] Add citation for weight sources (research papers, domain experts)
- [ ] If Option C:
  - [ ] Add daily wellbeing prompt to `PulseView`
  - [ ] Store in new Core Data entity: `DailyWellbeingReport`
  - [ ] Update training to use reported values

**Effort:** 🟡 Medium (1-2 days for refactor + testing)
**Priority:** 🟡 Medium - Affects ML validity but app still functions

---

### ⚠️ Issue #5: RecRanker Never Updates (No Training Data)

**Location:** `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift:417`

**Problem:**
```swift
// RecRanker.update(preferred:other:) is NEVER called in the codebase
// RecommendationEvent tracks user behavior but doesn't feed back to ranker
// Model never learns from user preferences
```

**Impact:**
- 🚫 **No personalization:** Recommendations won't improve over time
- 📊 **Wasted data:** App tracks acceptances/completions but doesn't use them
- 🤷 **Static ranking:** All users see the same ranking order

**Solution:**

**Implement Pairwise Feedback Loop:**

```swift
// When user completes a recommendation
func logCompletion(momentId: String) async throws -> CheerEvent {
    // 1. Log event (existing)
    let event = RecommendationEvent(context: context)
    event.momentId = momentId
    event.accepted = true
    event.completedAt = Date()
    try context.save()

    // 2. NEW: Update RecRanker with pairwise feedback
    try await updateRankerFromUserBehavior(completedId: momentId)

    // 3. Return cheer event (existing)
    return await cheerAgent.celebrateCompletion(momentTitle: title)
}

private func updateRankerFromUserBehavior(completedId: String) async throws {
    // Fetch last 3 recommendations shown to user
    let recentRecs = try fetchRecentRecommendations(limit: 3)

    // User completed `completedId` → treat as "preferred"
    guard let preferred = recentRecs.first(where: { $0.id == completedId }) else { return }

    // Other cards shown but not completed → treat as "not preferred"
    let others = recentRecs.filter { $0.id != completedId }

    // Pairwise update: preferred > others
    for other in others {
        let preferredFeatures = try buildFeatures(for: preferred)
        let otherFeatures = try buildFeatures(for: other)
        recRanker.update(preferred: preferredFeatures, other: otherFeatures)
    }
}
```

**Action Items:**
- [ ] Add `updateRankerFromUserBehavior()` to `CoachAgent`
- [ ] Call from `logCompletion()` after saving `RecommendationEvent`
- [ ] Persist RecRanker weights:
  - [ ] Add Core Data entity: `RankerWeights(feature: String, weight: Double, updatedAt: Date)`
  - [ ] Save weights after each update
  - [ ] Load weights on `CoachAgent` init
- [ ] Add batch training on app launch:
  - [ ] Fetch all `RecommendationEvent` since last training
  - [ ] Replay pairwise updates
  - [ ] Useful if user skips days between app opens
- [ ] Track metrics:
  - [ ] Log acceptance rate over time (should increase if model improves)
  - [ ] A/B test: Fixed weights vs. adaptive weights

**Effort:** 🟡 Medium (1-2 days for implementation + persistence)
**Priority:** 🟡 Medium - Affects personalization but not core functionality

---

### ⚠️ Issue #6: Actor Isolation Inconsistency

**Location:** `Packages/PulsumAgents/Sources/PulsumAgents/`

**Problem:**
```swift
@MainActor class AgentOrchestrator {
    actor DataAgent { ... }           // ✅ actor (heavy processing)
    @MainActor class SentimentAgent   // ❌ @MainActor (does embedding, Core Data writes)
    @MainActor class CoachAgent       // ❌ @MainActor (does vector search, ranking, LLM)
    @MainActor class SafetyAgent      // ✅ @MainActor (quick classification, okay)
    @MainActor class CheerAgent       // ✅ @MainActor (trivial, okay)
}
```

**Issues:**
- `CoachAgent` does heavy work on `@MainActor`:
  - Vector search (16 shards × linear scan)
  - RecRanker scoring (iterates all candidates)
  - LLM API calls (network I/O)
- `SentimentAgent` does embedding + Core Data writes on `@MainActor`
- Potential UI blocking during these operations (50-200ms+)

**Impact:**
- 🐌 **UI lag:** Janky scrolling/animations during recommendation refresh
- 📱 **Poor UX:** "Hang" perception when tapping buttons

**Solution:**

**Profile First, Then Refactor:**

```swift
// 1. Add performance instrumentation
import os.signpost

let log = OSLog(subsystem: "ai.pulsum", category: "performance")

func recommendationCards(...) async throws -> [RecommendationCard] {
    let signpostID = OSSignpostID(log: log)
    os_signpost(.begin, log: log, name: "RecommendationGeneration", signpostID: signpostID)
    defer { os_signpost(.end, log: log, name: "RecommendationGeneration", signpostID: signpostID) }

    // ... existing code ...
}

// 2. Profile in Instruments (Time Profiler + os_signpost)
// 3. If any operation takes >100ms on main thread, refactor to actor
```

**If Profiling Shows >100ms Lag:**

```swift
// Option A: Make CoachAgent an actor
actor CoachAgent {
    // All heavy operations now run on actor's serial executor
    func recommendationCards(...) async throws -> [RecommendationCard] {
        // Vector search, ranking, etc. happen off main thread
    }
}

// AgentOrchestrator calls remain the same (async already)
let cards = try await coachAgent.recommendationCards(...)
```

**Option B: Move specific operations to background**
```swift
@MainActor
class CoachAgent {
    private let vectorSearchQueue = DispatchQueue(label: "ai.pulsum.vectorsearch", qos: .userInitiated)

    func recommendationCards(...) async throws -> [RecommendationCard] {
        // Heavy work on background queue
        let matches = await withCheckedContinuation { continuation in
            vectorSearchQueue.async {
                let result = try? vectorIndexManager.searchMicroMoments(query: query, topK: 20)
                continuation.resume(returning: result ?? [])
            }
        }

        // Ranking on background queue
        let ranked = await Task.detached {
            recRanker.rank(candidates)
        }.value

        // UI updates back on main actor
        return ranked.map { buildCard(from: $0) }
    }
}
```

**Action Items:**
- [ ] Add os_signpost instrumentation to:
  - [ ] `CoachAgent.recommendationCards()`
  - [ ] `VectorIndexManager.searchMicroMoments()`
  - [ ] `RecRanker.rank()`
  - [ ] `SentimentAgent.recordVoiceJournal()`
- [ ] Profile in Instruments on real device (iPhone 12 or older for worst case)
- [ ] Measure main thread hangs:
  - [ ] Open Time Profiler
  - [ ] Filter to Main Thread
  - [ ] Look for >100ms gaps
- [ ] If lag detected:
  - [ ] Refactor CoachAgent to `actor` (preferred)
  - [ ] Or move specific operations to background queues
  - [ ] Re-profile to verify fix

**Effort:** 🟡 Medium (1 day for profiling, 1-2 days for refactor if needed)
**Priority:** 🟠 Low-Medium - Conditional on profiling results (per todolist.md)

---

### ⚠️ Issue #7: Vector Search Performance Concerns

**Location:** `Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:293`

**Problem:**
```swift
// Linear scan: O(n) time complexity for each shard
// Searches ALL 16 shards sequentially, computes L2 distance for every vector
func search(vector: [Float], topK: Int) throws -> [VectorMatch] {
    var allMatches: [VectorMatch] = []
    for shardIndex in 0..<shardCount {  // 16 shards
        let shard = try shard(forShardIndex: shardIndex)
        let matches = try shard.search(query: vector, topK: topK)  // O(n) scan
        allMatches.append(contentsOf: matches)
    }
    return Array(allMatches.sorted { $0.score < $1.score }.prefix(topK))
}
```

**Performance Analysis:**

| Library Size | Vectors per Shard | L2 Computations | Estimated Latency (iPhone 13) |
|--------------|-------------------|-----------------|-------------------------------|
| 1,000 items | 63 | 1,000 | ~20ms ✅ |
| 5,000 items | 313 | 5,000 | ~80ms ✅ |
| 10,000 items | 625 | 10,000 | ~150ms ⚠️ |
| 50,000 items | 3,125 | 50,000 | ~800ms 🔴 |

**Impact:**
- ✅ **Current:** With ~1,000 recommendations, acceptable performance
- ⚠️ **Future:** If library grows beyond 5,000 items, noticeable lag
- 🔴 **Blocker:** At 50,000+ items, search becomes unusable

**Solution:**

**Option A: Approximate Nearest Neighbor (ANN) with HNSW**

```swift
// Implement Hierarchical Navigable Small World (HNSW) graph
// Trade-off: 95-99% recall with 10-100x speedup

import Accelerate  // For optimized vector ops

final class HNSWIndex {
    private struct Node {
        let id: String
        let vector: [Float]
        var neighbors: [[String]]  // One layer per level
    }

    private var nodes: [String: Node] = [:]
    private let m: Int = 16  // Max connections per layer
    private let efConstruction: Int = 200  // Search width during construction

    func insert(id: String, vector: [Float]) {
        // Greedy search to find nearest neighbors
        // Insert node with bidirectional links
    }

    func search(query: [Float], topK: Int, ef: Int = 50) -> [VectorMatch] {
        // Start from entry point
        // Greedy search through graph layers
        // Return top-K closest nodes
    }
}
```

**Option B: Product Quantization (PQ)**

```swift
// Compress vectors: 384 * 4 bytes → 384 / 8 subvectors * 1 byte = 48 bytes (8x compression)
// Trade-off: Slight accuracy loss for 8x memory + speed improvement

final class PQIndex {
    private let numSubvectors = 48  // 384 / 8
    private var codebooks: [[Float]] = []  // 48 codebooks of 256 centroids each
    private var codes: [String: [UInt8]] = [:]  // Compressed vectors

    func train(vectors: [[Float]]) {
        // K-means clustering on subvectors
    }

    func encode(vector: [Float]) -> [UInt8] {
        // Quantize to nearest centroid in each subvector
    }

    func search(query: [Float], topK: Int) -> [VectorMatch] {
        // Compute asymmetric distances using lookup tables
    }
}
```

**Option C: External Vector Database**

- **SQLite with vec0 extension** (https://github.com/asg017/sqlite-vec)
  - Pros: Mature, integrates with Core Data
  - Cons: Adds dependency, larger binary size

- **Apple's MLVectorIndex** (iOS 18+)
  - Pros: Native, optimized for Apple Silicon
  - Cons: Not available on iOS 26 yet (future)

**Action Items:**
- [ ] Monitor library size in production:
  - [ ] Log `MicroMoment.count` on app launch
  - [ ] Alert if approaching 5,000 items
- [ ] If library grows beyond 5,000 items:
  - [ ] Implement HNSW (Option A, recommended)
  - [ ] Create `HNSWIndex` class
  - [ ] Add unit tests (recall, latency benchmarks)
  - [ ] Migrate existing VectorIndex data
- [ ] Or wait for iOS 18+ MLVectorIndex (future)

**Effort:** 🔴 High (5-7 days for HNSW implementation)
**Priority:** 🟢 Low - Conditional on library size (current: ~1,000 items, acceptable)

---

### ⚠️ Issue #8: Missing Sync Between Core Data and Vector Index

**Location:** `Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift:178`

**Problem:**
```swift
// No transaction coordination between Core Data and Vector Index
// Crash between these two operations → data inconsistency

let moment = MicroMoment(context: context)
moment.id = id
moment.title = title
// ... populate fields ...

// ❌ CRASH HERE = moment in Core Data, but not in vector index
let vector = try vectorIndexManager.upsertMicroMoment(id: id, title: title, ...)

try context.save()
```

**Failure Scenarios:**

1. **App crash after Core Data write, before vector index write:**
   - MicroMoment exists in Core Data
   - Not in vector index
   - Never appears in search results

2. **App crash after vector index write, before Core Data save:**
   - Vector exists in index
   - No corresponding MicroMoment entity
   - Search returns ID that can't be fetched

**Impact:**
- 🐛 **Silent data loss:** Recommendations exist but are invisible to users
- 🔍 **Search inconsistency:** Vector search returns IDs that don't resolve
- 🚫 **No automatic recovery:** User must reinstall app to fix

**Solution:**

**Option A: Consistency Check on Startup (Recommended)**

```swift
// DataAgent.swift
func start() async throws {
    // Existing: Start HealthKit observation
    try await startHealthKitObservation()

    // NEW: Reconcile Core Data ↔ Vector Index
    try await reconcileVectorIndex()
}

private func reconcileVectorIndex() async throws {
    let context = PulsumData.newBackgroundContext(name: "VectorReconciliation")

    // Fetch all MicroMoments from Core Data
    let fetchRequest = MicroMoment.fetchRequest()
    let moments = try context.fetch(fetchRequest)

    let vectorManager = VectorIndexManager.shared

    for moment in moments {
        // Check if vector exists in index
        let matches = try? vectorManager.searchMicroMoments(query: moment.id, topK: 1)
        let existsInIndex = matches?.first?.id == moment.id

        if !existsInIndex {
            // Rebuild missing vector
            print("⚠️ Rebuilding vector for missing moment: \(moment.id)")
            try vectorManager.upsertMicroMoment(
                id: moment.id,
                title: moment.title,
                detail: moment.detail,
                tags: moment.tags
            )
        }
    }

    print("✅ Vector index reconciliation complete")
}
```

**Option B: Store Embeddings in Core Data**

```swift
// ManagedObjects.swift
@objc(MicroMoment)
public final class MicroMoment: NSManagedObject {
    // ... existing fields ...
    @NSManaged public var embeddingData: Data?  // NEW: Store 384 * 4 = 1536 bytes
}

// Rebuild vector index from Core Data on startup
func rebuildVectorIndex() async throws {
    let moments = try fetchAllMicroMoments()

    for moment in moments {
        guard let data = moment.embeddingData else { continue }
        let vector = data.withUnsafeBytes { buffer in
            Array(buffer.bindMemory(to: Float.self))
        }
        try vectorIndex.upsert(id: moment.id, vector: vector)
    }
}
```

**Option C: Two-Phase Commit (Complex, Overkill)**

```swift
// Write-Ahead Log (WAL) for vector index operations
// Replay log on startup to recover from crashes
// Probably overkill for this use case
```

**Action Items:**
- [ ] Implement Option A (consistency check on startup)
- [ ] Add `reconcileVectorIndex()` to `DataAgent.start()`
- [ ] Test crash scenarios:
  - [ ] Force quit after Core Data save, before vector upsert
  - [ ] Verify reconciliation rebuilds missing vectors
- [ ] Add telemetry:
  - [ ] Log count of rebuilt vectors
  - [ ] Alert if >10% of library needs rebuilding (indicates systemic issue)
- [ ] Consider Option B for future (store embeddings in Core Data for easier backup/restore)

**Effort:** 🟡 Medium (1 day for implementation + testing)
**Priority:** 🟡 Medium - Affects data integrity but rare in practice

---

## 3. Minor Issues (Future Improvements)

### 🟠 Issue #9: Sleep Debt Calculation May Underestimate Chronic Sleep Deprivation

**Location:** `Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift:612`

**Problem:**
```swift
// If user consistently under-sleeps, personalized need adapts downward
let mean7 = past7TST.reduce(0, +) / Double(past7TST.count)
let personalizedNeed = min(max(mean7, 7.5 - 0.75), 7.5 + 0.75)  // [6.75, 8.25]

// Example: User sleeps 6h/night for a week
// mean7 = 6.0 → clamped to 6.75
// Model thinks user only needs 6.75h → underestimates sleep debt
```

**Impact:**
- 😴 Users with chronic sleep issues won't receive appropriate interventions
- 📉 Sleep debt metric becomes meaningless for chronically sleep-deprived users

**Solution:**

```swift
// Option A: Use fixed baseline (8 hours) for adults
let personalizedNeed = 8.0

// Option B: Age-adjusted baseline (if collecting user age)
let personalizedNeed: Double = {
    switch userAge {
    case 18...25: return 8.0
    case 26...64: return 7.5
    case 65...: return 7.0
    default: return 7.5
    }
}()

// Option C: Require 2-week calibration period
let personalizedNeed: Double = {
    guard daysOfData >= 14 else { return 8.0 }  // Default until calibrated
    let mean14 = past14TST.reduce(0, +) / Double(past14TST.count)
    return min(max(mean14, 7.0), 9.0)  // Wider bounds
}()
```

**Action Items:**
- [ ] Decide on approach (Option A simplest)
- [ ] Update `computePersonalizedSleepNeed()` in `DataAgent`
- [ ] Update `ScoreBreakdown` explanation: "Sleep debt vs. 8-hour baseline"
- [ ] Consider adding user age to `UserPrefs` for Option B (future)

**Effort:** 🟢 Low (1-2 hours)
**Priority:** 🟢 Low - Minor accuracy improvement

---

### 🟠 Issue #10: Foundation Models Availability Not Checked in CoachAgent

**Location:** `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift:569`

**Problem:**
```swift
@available(iOS 26.0, *)
private func generateFoundationModelsCaution(...) async -> String? {
    let model = SystemLanguageModel.default
    let session = try LanguageModelSession(model: model)  // ❌ Could crash if downloading
    // ...
}
```

**Impact:**
- 💥 Rare crash if Foundation Models is downloading or unavailable
- 🤔 Inconsistent with other providers (all check availability)

**Solution:**

```swift
@available(iOS 26.0, *)
private func generateFoundationModelsCaution(...) async -> String? {
    let model = SystemLanguageModel.default

    // ✅ Add availability check
    guard model.availability == .available else {
        return nil  // Fall back to heuristic caution
    }

    do {
        let session = try LanguageModelSession(model: model)
        // ... existing code ...
    } catch {
        return nil
    }
}
```

**Action Items:**
- [ ] Add `guard model.availability == .available` to `generateFoundationModelsCaution()`
- [ ] Audit all Foundation Models usage for missing checks:
  - [ ] `FoundationModelsSentimentProvider.swift` ✅ (already checks)
  - [ ] `FoundationModelsSafetyProvider.swift` ✅ (already checks)
  - [ ] `FoundationModelsCoachGenerator.swift` ✅ (already checks)
  - [ ] `CoachAgent.generateFoundationModelsCaution()` ❌ (needs fix)

**Effort:** 🟢 Low (15 minutes)
**Priority:** 🟠 Low - Edge case but easy fix

---

### 🟠 Issue #11: Inconsistent Error Handling

**Problem:** Mixed error handling patterns across codebase:

```swift
// Pattern A: Throws errors
func recommendations(consentGranted: Bool) async throws -> RecommendationResponse

// Pattern B: Returns fallback values
func generate(context: CoachLLMContext) async -> String  // Never throws

// Pattern C: Returns Result
func sentimentScore(for text: String) async -> Result<Double, Error>
```

**Impact:**
- 😕 Developer confusion when calling APIs
- 🐛 Inconsistent UI error handling

**Solution:**

Standardize on throwing functions:

```swift
// Preferred pattern: Throw errors, let caller decide on fallback
func generate(context: CoachLLMContext) async throws -> String

// Caller handles fallback
do {
    let response = try await generator.generate(context: context)
    return response
} catch {
    return "Based on your current signals, prioritize sustainable activities."
}
```

**Action Items:**
- [ ] Audit all public APIs for error handling consistency
- [ ] Document error handling strategy in architecture.md
- [ ] Consider adding `ErrorHandlingGuidelines.md` for future development

**Effort:** 🟡 Medium (2-3 days for refactor)
**Priority:** 🟢 Low - Technical debt, not user-facing

---

### 🟠 Issue #12: No Background Task for HealthKit Ingestion

**Status:** Conditional (per todolist.md Milestone 6)

**Problem:**
- Current: Relies on `HKObserverQuery` background delivery
- Risk: iOS may throttle/kill background delivery if app inactive for days

**Solution:**

```swift
import BackgroundTasks

// AppDelegate or @main
func application(_ application: UIApplication, didFinishLaunchingWithOptions ...) {
    BGTaskScheduler.shared.register(
        forTaskWithIdentifier: "ai.pulsum.healthkit.sync",
        using: nil
    ) { task in
        self.handleHealthKitSync(task: task as! BGProcessingTask)
    }
}

func handleHealthKitSync(task: BGProcessingTask) {
    let operation = DataAgent.shared.syncHealthKitData()

    task.expirationHandler = {
        operation.cancel()
    }

    Task {
        await operation.value
        task.setTaskCompleted(success: true)
        scheduleNextSync()
    }
}
```

**Action Items:**
- [ ] Monitor HealthKit delivery reliability in TestFlight:
  - [ ] Track time between updates (should be <1 hour for active users)
  - [ ] Alert if gaps >24 hours
- [ ] If reliability issues detected:
  - [ ] Implement `BGProcessingTask` as described above
  - [ ] Request `BGTaskSchedulerPermittedIdentifiers` in Info.plist
  - [ ] Test background scheduling with Xcode debugger

**Effort:** 🟡 Medium (1 day)
**Priority:** 🟢 Low - Conditional on production monitoring

---

### 🟠 Issue #13: No Offline Spline Fallback Asset Verification

**Location:** `Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift:156`

**Problem:**
```swift
// Fallback asset referenced but may not be bundled
let fallbackURL = Bundle.main.url(forResource: "infinity_blubs_copy", withExtension: "splineswift")
```

**Impact:**
- 🎨 Broken UI if cloud Spline URL fails AND fallback asset missing
- 😞 Bad first impression for offline users

**Solution:**

```swift
// Verify fallback asset at build time
func verifyAssets() {
    guard let _ = Bundle.main.url(forResource: "infinity_blubs_copy", withExtension: "splineswift") else {
        fatalError("❌ Spline fallback asset missing. Add to Copy Bundle Resources.")
    }
}

// Call in App init (DEBUG builds only)
#if DEBUG
init() {
    verifyAssets()
}
#endif
```

**Action Items:**
- [ ] Verify `infinity_blubs_copy.splineswift` is in Xcode project
- [ ] Check "Copy Bundle Resources" build phase includes fallback asset
- [ ] Test offline mode:
  - [ ] Enable Airplane Mode
  - [ ] Delete and reinstall app
  - [ ] Verify fallback Spline scene loads
- [ ] Add asset verification to CI/CD pipeline

**Effort:** 🟢 Low (30 minutes)
**Priority:** 🟢 Low - Easy verification

---

### 🟠 Issue #14: Cooldown Logic Too Restrictive

**Location:** `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift:447`

**Problem:**
```swift
// User can't repeat an activity within cooldown period (e.g., 24 hours)
// No override mechanism if user wants to repeat
let cooldown = 1.0 - (elapsed / cooldownSec)
```

**Impact:**
- 😤 User frustration if they want to repeat a helpful activity
- 🚫 No manual override

**Solution:**

```swift
// Option A: Exponential decay instead of linear
let cooldown = exp(-elapsed / cooldownSec)  // Approaches 0 but never blocks

// Option B: Add "Show again" button in UI
// MicroMoment.swift
@NSManaged public var userOverrideCooldown: Bool  // Persisted flag

// CoachAgent.swift
if moment.userOverrideCooldown {
    cooldown = 1.0  // Ignore cooldown
}
```

**Action Items:**
- [ ] Implement exponential decay (Option A, simple)
- [ ] Or add "Show again" button to recommendation cards (Option B, better UX)
- [ ] Collect user feedback: Do users want to repeat activities more frequently?

**Effort:** 🟢 Low (1-2 hours)
**Priority:** 🟢 Low - UX polish

---

### 🟠 Issue #15: No A/B Testing or Experimentation Framework

**Problem:** Can't measure impact of changes once app ships:
- Different RecRanker weights
- Different StateEstimator learning rates
- Foundation Models vs. legacy providers
- UI variations

**Solution:**

```swift
// Simple feature flag system
enum FeatureFlag: String {
    case useFoundationModels = "use_foundation_models"
    case recRankerLearningRate = "rec_ranker_lr"
    case stateEstimatorRegularization = "state_estimator_lambda"
}

struct FeatureFlags {
    static func bool(_ flag: FeatureFlag, default: Bool) -> Bool {
        UserDefaults.standard.object(forKey: flag.rawValue) as? Bool ?? `default`
    }

    static func double(_ flag: FeatureFlag, default: Double) -> Double {
        UserDefaults.standard.object(forKey: flag.rawValue) as? Double ?? `default`
    }
}

// Usage
let learningRate = FeatureFlags.double(.recRankerLearningRate, default: 0.01)
```

**Action Items:**
- [ ] Decide if A/B testing is needed for v1.0 (probably not)
- [ ] If yes:
  - [ ] Implement simple feature flag system
  - [ ] Add remote config (Firebase, CloudKit, or custom server)
  - [ ] Add anonymous telemetry with user consent
- [ ] Or accept manual iteration for research app

**Effort:** 🔴 High (3-5 days for full system)
**Priority:** 🟢 Low - Future enhancement

---

## 4. Implementation Roadmap

### Phase 1: Pre-Submission Blockers (Week 1)

**Goal:** Fix all App Store rejection risks

| Task | Owner | Effort | Status |
|------|-------|--------|--------|
| Remove hardcoded API key (#2) | Dev | 2h | ⬜ Not Started |
| Create Privacy Manifests (#3) | Dev | 6h | ⬜ Not Started |
| Verify Spline fallback asset (#13) | Dev | 30m | ⬜ Not Started |
| Add AFM availability check (#10) | Dev | 15m | ⬜ Not Started |
| Test TestFlight submission | QA | 4h | ⬜ Not Started |

**Success Criteria:**
- ✅ No hardcoded secrets in codebase
- ✅ All Privacy Manifests validated by App Store Connect
- ✅ Offline mode works (Spline fallback)
- ✅ No crashes in Foundation Models code paths

---

### Phase 2: ML/AI Improvements (Week 2-3)

**Goal:** Fix model validity and enable personalization

| Task | Owner | Effort | Status |
|------|-------|--------|--------|
| Fix StateEstimator target (#4) | ML Engineer | 2d | ⬜ Not Started |
| Implement RecRanker feedback (#5) | ML Engineer | 2d | ⬜ Not Started |
| Research safe contextual embeddings (#3) | ML Engineer | 1d | ⬜ Not Started |
| OR export Core ML sentence transformer (#3) | ML Engineer | 3d | ⬜ Not Started |

**Success Criteria:**
- ✅ StateEstimator predicts subjective wellbeing from objective metrics
- ✅ RecRanker updates from user completions
- ✅ Embedding quality improves (measured by test set similarity)

---

### Phase 3: Performance & Scalability (Week 4)

**Goal:** Ensure smooth UX at scale

| Task | Owner | Effort | Status |
|------|-------|--------|--------|
| Profile UI responsiveness (#6) | Dev | 1d | ⬜ Not Started |
| Refactor actors if needed (#6) | Dev | 2d | ⬜ Conditional |
| Implement Core Data ↔ Vector consistency (#8) | Dev | 1d | ⬜ Not Started |
| Monitor library size for HNSW trigger (#7) | PM | Ongoing | ⬜ Not Started |

**Success Criteria:**
- ✅ All UI operations <100ms on iPhone 12
- ✅ Zero data inconsistencies in testing
- ✅ Vector search scales to 5,000+ items

---

### Phase 4: Polish & Launch (Week 5)

**Goal:** Final testing and release

| Task | Owner | Effort | Status |
|------|-------|--------|--------|
| Fix sleep debt calculation (#9) | Dev | 2h | ⬜ Not Started |
| Exponential cooldown decay (#14) | Dev | 2h | ⬜ Not Started |
| TestFlight beta (100 users) | QA | 1w | ⬜ Not Started |
| Fix bugs from beta feedback | Dev | 3d | ⬜ Not Started |
| App Store submission | PM | 1d | ⬜ Not Started |

**Success Criteria:**
- ✅ Beta users report smooth experience
- ✅ No crashes or data loss
- ✅ App Store review passes

---

## 5. Risk Assessment

### High Risk (Will Block Release)

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| App Store rejection (Privacy Manifests) | 🔴 High | 🔴 Critical | Create manifests immediately (#3) |
| API key leak | 🔴 High | 🔴 Critical | Remove hardcoded key (#2) |
| Foundation Models crash (iOS 26 beta bugs) | 🟡 Medium | 🔴 Critical | Thorough fallback testing |

### Medium Risk (Affects Quality)

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| UI lag during recommendations | 🟡 Medium | 🟡 Medium | Profile early, refactor if needed (#6) |
| ML models don't converge | 🟡 Medium | 🟡 Medium | Fix training targets (#4, #5) |
| Vector search too slow at scale | 🟢 Low | 🟡 Medium | Monitor library size, implement HNSW (#7) |

### Low Risk (Nice to Have)

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| HealthKit background delivery throttled | 🟢 Low | 🟢 Low | Monitor in production (#12) |
| Embedding quality subpar | 🟢 Low | 🟢 Low | Replace with Core ML model (#3) |
| Users frustrated by cooldowns | 🟢 Low | 🟢 Low | Exponential decay (#14) |

---

## 6. Testing Strategy

### Pre-Submission Testing

**App Store Validation:**
- [ ] Upload to App Store Connect (TestFlight)
- [ ] Check for automatic rejection messages
- [ ] Verify Privacy Manifests accepted
- [ ] Test on iOS 26 beta devices

**Security Audit:**
- [ ] Run `git grep -i "api.*key"` → should find zero hardcoded keys
- [ ] Decompile IPA with Hopper/IDA → verify no secrets in binary
- [ ] Test LLMGateway with missing key → should gracefully fall back

**Offline Mode:**
- [ ] Enable Airplane Mode
- [ ] Delete and reinstall app
- [ ] Verify:
  - [ ] Spline fallback loads
  - [ ] Voice journal works (on-device STT)
  - [ ] Recommendations appear (vector search works)
  - [ ] No network error alerts

---

### ML Validation Testing

**StateEstimator:**
- [ ] Create synthetic dataset: 30 days × 10 users with known patterns
- [ ] Train model
- [ ] Measure MAE (mean absolute error) between predicted and actual
- [ ] Target: MAE < 1.0 on wellbeing scale

**RecRanker:**
- [ ] Simulate user behavior: 50 completions, 200 ignores
- [ ] Measure recommendation relevance before/after training
- [ ] Target: Acceptance rate increases by 10%+ after 30 days

**Embedding Quality:**
- [ ] Create test set: 50 recommendation pairs (25 related, 25 unrelated)
- [ ] Compute cosine similarity
- [ ] Measure AUC-ROC for relatedness classification
- [ ] Target: AUC > 0.85

---

### Performance Testing

**UI Responsiveness:**
- [ ] Profile on iPhone 12 (worst case for supported devices)
- [ ] Measure main thread hangs in Instruments
- [ ] Test scenarios:
  - [ ] Scroll recommendations while loading
  - [ ] Rapid navigation between tabs
  - [ ] Voice journal recording + simultaneous HealthKit sync
- [ ] Target: Zero hangs >100ms

**Vector Search Latency:**
- [ ] Benchmark with library sizes: 1k, 5k, 10k items
- [ ] Measure P50, P95, P99 latency
- [ ] Target: P95 < 200ms for 5k items

---

### Stress Testing

**HealthKit Ingestion:**
- [ ] Simulate 7 days of HealthKit data
- [ ] Force app termination mid-processing
- [ ] Verify:
  - [ ] Anchors persist correctly
  - [ ] No duplicate samples
  - [ ] Baselines recompute correctly

**Core Data + Vector Consistency:**
- [ ] Ingest 1,000 recommendations
- [ ] Force quit randomly during ingestion
- [ ] Run consistency check on restart
- [ ] Target: 100% consistency after reconciliation

---

## Appendix A: Quick Reference

### Priority Legend

| Icon | Priority | Description |
|------|----------|-------------|
| 🔴 | Critical | Blocks App Store submission |
| 🟡 | High | Affects core functionality or quality |
| 🟠 | Medium | Important but not blocking |
| 🟢 | Low | Nice to have, future improvement |

### Effort Legend

| Effort | Time Estimate |
|--------|---------------|
| Low | <1 day |
| Medium | 1-3 days |
| High | 4-7 days |

---

## Appendix B: Dependencies

### External Libraries

| Library | Version | Purpose | Issues |
|---------|---------|---------|--------|
| SplineRuntime | SPM latest | 3D animation | Verify Privacy Manifest included |
| FoundationModels | iOS 26 | Apple Intelligence | Beta stability concerns |

### System Frameworks

| Framework | Minimum iOS | Purpose |
|-----------|-------------|---------|
| HealthKit | 16.0 | Physiological metrics |
| Speech | 16.0 | On-device STT |
| NaturalLanguage | 17.0 | Embeddings, sentiment |
| CoreML | 16.0 | Fallback models |
| FoundationModels | 26.0 | Apple Intelligence |

---

## Appendix C: Contacts

**For questions about this roadmap:**
- Architecture issues: [Email/Slack]
- ML/AI concerns: [Email/Slack]
- App Store compliance: [Email/Slack]

**Key Resources:**
- [Apple Privacy Manifest Guide](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [Foundation Models Documentation](https://developer.apple.com/documentation/foundationmodels)
- [Swift Concurrency Guidelines](https://developer.apple.com/documentation/swift/concurrency)

---

**End of Roadmap v3**

Last updated: October 1, 2025
Next review: After Phase 1 completion
