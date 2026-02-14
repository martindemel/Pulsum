# Pulsum Master Fix Plan — Full End-to-End Deep-Dive Analysis

## Context

This plan is a comprehensive remediation roadmap for the Pulsum iOS 26+ wellness coaching app, synthesizing:
- **master_report.md**: 112 known findings (5 CRIT, 10 HIGH, 16 MED, 15 LOW, 3 stubs, 7 test gaps, 9 architecture, 18 production)
- **Agent 1 scan** (PulsumML + PulsumData): 30 findings
- **Agent 2 scan** (PulsumServices + PulsumTypes + App): 34 findings
- **Agent 3 scan** (PulsumAgents + PulsumUI): 38 findings
- **Manual analysis**: Privacy manifests, entitlements, project configuration

**Project stats**: 96 source files, 66 test files, 7 UI test files across 6 SPM packages.

---

## 1. EXECUTIVE SUMMARY

| Severity | Count | Effort |
|----------|-------|--------|
| CRITICAL | 12 | 5 x S, 4 x M, 3 x L |
| HIGH | 18 | 8 x S, 7 x M, 3 x L |
| MEDIUM | 24 | 14 x S, 8 x M, 2 x L |
| LOW | 20 | 18 x S, 2 x M |
| Production/Compliance | 18 | 6 x S, 7 x M, 5 x L |
| Test Gaps | 7 | 2 x S, 3 x M, 2 x L |
| **TOTAL** | **~99 unique** | |

**Estimated total effort**: ~3-4 weeks for 1 developer (CRITs in week 1, HIGHs in week 2, MEDs in week 3, LOWs ongoing).

---

## 2. CRITICAL FIXES (Must fix immediately — app stability & safety)

### CRIT-01: VectorIndex non-deterministic hashValue sharding
**File**: `Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:382-384`
**Problem**: `String.hashValue` is randomized per process (Swift 4.2+). Same ID maps to different shards across restarts -> duplicates, data corruption.
```swift
// CURRENT (line 383):
let shardIndex = abs(id.hashValue) % shardCount

// FIX:
private func shard(for id: String) throws -> VectorIndexShard {
    let data = Data(id.utf8)
    let hash = data.withUnsafeBytes { ptr -> UInt64 in
        var h: UInt64 = 0xcbf29ce484222325
        for byte in ptr { h = (h ^ UInt64(byte)) &* 0x100000001b3 }
        return h
    }
    return try shard(forShardIndex: Int(hash % UInt64(shardCount)))
}
```
**Effort**: S | **Depends on**: Nothing

### CRIT-02: FoundationModels safety provider returns .safe for guardrail violations
**File**: `Packages/PulsumML/Sources/PulsumML/Safety/FoundationModelsSafetyProvider.swift:72,86`
**Problem**: Apple's guardrail violations (dangerous content Apple's own AI refuses) get classified as `.safe`.
```swift
// CURRENT:
case .guardrailViolation: return .safe
case .refusal: return .safe

// FIX:
case .guardrailViolation:
    return .caution(reason: "Content flagged by on-device safety system")
case .refusal:
    return .caution(reason: "Content refused by on-device safety system")
```
**Effort**: S | **Depends on**: Nothing

### CRIT-03: Schema/prompt intentTopic enum mismatch causes cloud API failures
**Files**: `Packages/PulsumServices/Sources/PulsumServices/CoachPhrasingSchema.swift:30`, `LLMGateway.swift:862`
**Problem**: Schema allows `["sleep","stress","energy","hrv","mood","movement","mindfulness","goals","none"]` but prompt instructs `["sleep","stress","energy","mood","movement","nutrition","goals"]`.
```swift
// FIX in CoachPhrasingSchema.swift — unify to:
"enum": ["sleep","stress","energy","hrv","mood","movement","mindfulness","nutrition","goals","none"]

// FIX in LLMGateway.swift system prompt — update to match:
// one of ["sleep","stress","energy","hrv","mood","movement","mindfulness","nutrition","goals","none"]
```
**Effort**: S | **Depends on**: Nothing

### CRIT-04: DataStack.init crashes with fatalError on recoverable errors
**File**: `Packages/PulsumData/Sources/PulsumData/DataStack.swift:70,76,101`
**Problem**: 3 `fatalError()` calls crash the app on disk-full, permissions, or corrupt store.
```swift
// CURRENT (3 sites):
fatalError("Pulsum data directories could not be resolved: \(error)")
fatalError("Pulsum data directories could not be created: \(error)")
fatalError("Unresolved Core Data error: \(error)")

// FIX: Convert init to throwing:
public init() throws {
    // Replace each fatalError with: throw DataStackError.directoryResolution(error)
    // Add: enum DataStackError: Error { case directoryResolution(Error), directoryCreation(Error), storeLoad(Error) }
}
```
Also fix `PulsumManagedObjectModel.swift:87` — same fatalError pattern.
**Effort**: M | **Depends on**: AppViewModel.swift must handle errors

### CRIT-05: Incomplete crisis keyword lists
**Files**: `Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift:18-19`, `Packages/PulsumAgents/Sources/PulsumAgents/SafetyAgent.swift:12-18`
**Problem**: Only ~10-15 crisis keywords. Missing common phrases.
```swift
// ADD to both files:
"want to die", "self-harm", "cut myself", "cutting myself", "overdose",
"no reason to live", "jump off", "hang myself", "hurt myself",
"don't want to be here", "can't go on", "take all the pills",
"ending my life", "not want to live", "kill myself", "suicide"
```
**Effort**: S | **Depends on**: Nothing

### CRIT-06: File protection level wrong in 5+ files
**Files**: `RecRankerStateStore.swift:65,75,86`, `EstimatorStateStore.swift:65,75,86`, `BackfillStateStore.swift:112,122,133`, `SentimentAgent.swift:325,342`, `HealthKitAnchorStore.swift:65`
**Problem**: Using `FileProtectionType.complete` — but HealthKit background delivery needs DB access while locked.
```swift
// CURRENT:
FileProtectionType.complete

// FIX (all instances):
FileProtectionType.completeUnlessOpen
```
**Effort**: S | **Depends on**: Nothing

### CRIT-07: preconditionFailure in CoachAgent production code
**File**: `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift:706,718`
**Problem**: `preconditionFailure()` crashes in production. Forbidden per guidelines.
```swift
// CURRENT:
preconditionFailure("NSManagedObjectContext.performAndWait did not execute")

// FIX: Replace with proper error:
throw CoachAgentError.contextExecutionFailed
// Define: enum CoachAgentError: Error { case contextExecutionFailed }
```
**Effort**: S | **Depends on**: Nothing

### CRIT-08: Privacy manifest missing UserDefaults required reason API
**File**: `Pulsum/PrivacyInfo.xcprivacy` (and all SPM package manifests)
**Problem**: `NSPrivacyAccessedAPITypes` is empty, but the app uses `UserDefaults.standard`. Apple requires declaring this API usage.
```xml
<!-- ADD to NSPrivacyAccessedAPITypes: -->
<dict>
    <key>NSPrivacyAccessedAPIType</key>
    <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
    <key>NSPrivacyAccessedAPITypeReasons</key>
    <array>
        <string>CA92.1</string>
    </array>
</dict>
```
**Effort**: S | **Depends on**: Nothing

### CRIT-09: SafetyLocal crisis requires BOTH embedding AND keyword match
**File**: `Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift:100-113`
**Problem**: High-confidence embedding crisis gets downgraded to `.caution` if no exact keyword match. Paraphrased crisis language ("permanent solution to stop the pain") misses.
```swift
// FIX: When embedding similarity > 0.85, classify as .crisis regardless of keyword match
if embeddingSimilarity > 0.85 {
    return .crisis(reason: "High-confidence crisis embedding match")
} else if embeddingSimilarity > 0.65 && hasKeyword {
    return .crisis(reason: "Crisis keyword + embedding match")
}
```
**Effort**: S | **Depends on**: Nothing

### CRIT-10: Force unwrap on URL in LLMGateway
**File**: `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:351,618`
**Problem**: `URL(string: "...")!` — force unwrap forbidden.
```swift
// CURRENT:
private let endpoint = URL(string: "https://api.openai.com/v1/responses")!

// FIX:
private let endpoint: URL
init() throws {
    guard let url = URL(string: "https://api.openai.com/v1/responses") else {
        throw LLMGatewayError.invalidEndpointURL
    }
    self.endpoint = url
}
```
**Effort**: S | **Depends on**: Nothing

### CRIT-11: SentimentAgent JournalResult contains non-Sendable NSManagedObjectID
**File**: `Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift:141`
**Problem**: `JournalResult` is `@unchecked Sendable` but contains `NSManagedObjectID` which is not Sendable.
```swift
// FIX: Use PersistentIdentifier or UUID string instead of NSManagedObjectID
// This aligns with the project rule: use PersistentIdentifier for cross-actor refs
```
**Effort**: M | **Depends on**: Consumers of JournalResult

### CRIT-12: Timer leaks in glow.swift (4 instances)
**File**: `ios support files/glow.swift:11,20,29,38`
**Problem**: 4 `Timer.scheduledTimer` calls never invalidated. Fires indefinitely after view disappears.
```swift
// FIX: Store timer reference and cancel on disappear
@State private var timers: [Timer] = []

.onAppear {
    let t = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in ... }
    timers.append(t)
}
.onDisappear {
    timers.forEach { $0.invalidate() }
    timers.removeAll()
}
```
**Effort**: S | **Depends on**: Nothing

---

## 3. HIGH PRIORITY FIXES

### HIGH-01: RecRanker pairwise gradient mathematically incorrect
**File**: `Packages/PulsumML/Sources/PulsumML/RecRanker.swift:128-136`
**Problem**: Current formula pushes all scores toward 0.5 instead of learning preferences.
```swift
// CURRENT:
let gradPreferred = 1.0 - logistic(dotPreferred)
let gradOther = -logistic(dotOther)

// FIX (Bradley-Terry):
let margin = dotOther - dotPreferred
let gradient = logistic(margin)
for k in features.keys {
    let xPref = preferred.vector[k] ?? 0
    let xOther = other.vector[k] ?? 0
    weights[k, default: 0] += learningRate * gradient * (xPref - xOther)
}
```
**Effort**: M | **Depends on**: CRIT-01 (VectorIndex)

### HIGH-02: SentimentService returns silent 0.0 on total provider failure
**File**: `Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentService.swift:37`
```swift
// FIX: Add NaturalLanguageSentimentProvider as final fallback, return nil on total failure
```
**Effort**: S | **Depends on**: Nothing

### HIGH-03: EmbeddingTopicGateProvider blocks ALL input when embeddings unavailable
**File**: `Packages/PulsumML/Sources/PulsumML/TopicGate/EmbeddingTopicGateProvider.swift:100-116`
```swift
// FIX: In degraded mode, return isOnTopic: true with low confidence
```
**Effort**: S | **Depends on**: Nothing

### HIGH-04: LegacySpeechBackend data race on mutable state
**File**: `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:417`
```swift
// FIX: Convert to actor, or add serial DispatchQueue for all state mutations
```
**Effort**: M | **Depends on**: Nothing

### HIGH-05: PulseViewModel.isAnalyzing permanently stuck
**File**: `Packages/PulsumUI/Sources/PulsumUI/PulseViewModel.swift:63`
```swift
// FIX: Add defer { isAnalyzing = false } in recording task, and reset in stopRecording()
```
**Effort**: S | **Depends on**: Nothing

### HIGH-06: All fonts ignore Dynamic Type
**File**: `Packages/PulsumUI/Sources/PulsumUI/PulsumDesignSystem.swift:63-83`
```swift
// CURRENT:
static let pulsumLargeTitle = Font.system(size: 34, weight: .bold)

// FIX:
static let pulsumLargeTitle = Font.system(.largeTitle, weight: .bold)
static let pulsumTitle = Font.system(.title, weight: .bold)
static let pulsumHeadline = Font.system(.headline, weight: .semibold)
static let pulsumBody = Font.system(.body)
static let pulsumCaption = Font.system(.caption)
```
**Effort**: M | **Depends on**: Nothing (but test on all size categories after)

### HIGH-07: CoachAgent performAndWait blocks MainActor
**File**: `Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift:698-720`
```swift
// FIX: Replace performAndWait with async perform:
func contextPerform<T>(_ work: @escaping @Sendable (NSManagedObjectContext) -> T) async -> T {
    await context.perform { [context] in work(context) }
}
```
**Effort**: M | **Depends on**: CRIT-07

### HIGH-08: Force unwraps on HealthKit quantityType
**File**: `Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift:318,373`
```swift
// CURRENT:
let quantityType = HKObjectType.quantityType(forIdentifier: .stepCount)!

// FIX:
guard let quantityType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
    throw HealthKitServiceError.healthDataUnavailable
}
```
**Effort**: S | **Depends on**: Nothing

### HIGH-09: Non-atomic multi-step writes in VectorIndex
**File**: `Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:125-148`
```swift
// FIX: Write to temp file, atomically rename. Add startup recovery.
```
**Effort**: M | **Depends on**: CRIT-01

### HIGH-10: @unchecked Sendable overuse (7+ files)
**Files**: EmbeddingService.swift, SentimentService.swift, LibraryImporter.swift, HealthKitService.swift, KeychainService.swift, HealthKitAnchorStore.swift, EstimatorStateStore.swift
```swift
// FIX: Convert each to actor, or add proper synchronization (NSLock/DispatchQueue)
// Priority: HealthKitService (mutable dictionaries), LLMGateway (inMemoryAPIKey)
```
**Effort**: M (per file) | **Depends on**: Nothing

### HIGH-11: NSLock inside VectorIndex actor (anti-pattern)
**File**: `Packages/PulsumData/Sources/PulsumData/VectorIndex.swift:334,388-389`
```swift
// FIX: Remove NSLock and per-shard DispatchQueues. Actor isolation is sufficient.
```
**Effort**: S | **Depends on**: CRIT-01

### HIGH-12: Force unwrap in AgentOrchestrator
**File**: `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:859`
```swift
// CURRENT:
let context = coachAgent.minimalCoachContext(from: snapshot, topic: intentTopic!)

// FIX:
let context = coachAgent.minimalCoachContext(from: snapshot, topic: intentTopic ?? "wellbeing")
```
**Effort**: S | **Depends on**: Nothing

### HIGH-13: AFMTextEmbeddingProvider gates on AFM availability unnecessarily
**File**: `Packages/PulsumML/Sources/PulsumML/Embedding/AFMTextEmbeddingProvider.swift:20`
```swift
// FIX: Remove AFM availability check. NLEmbedding works on iOS 17+ regardless.
```
**Effort**: S | **Depends on**: Nothing

### HIGH-14: HealthKit AnchorStore read/write queue asymmetry
**File**: `Packages/PulsumServices/Sources/PulsumServices/HealthKitAnchorStore.swift`
```swift
// FIX: Use queue.sync for both read and write, or convert to actor
```
**Effort**: S | **Depends on**: Nothing

### HIGH-15: submitTranscript skips reprocessDay
**File**: `Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift:416-419`
```swift
// FIX: Add after submitTranscript processing:
try await dataAgent.reprocessDay(date: result.date)
```
**Effort**: S | **Depends on**: Nothing

### HIGH-16: LLMGateway.inMemoryAPIKey has no synchronization
**File**: `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift:294`
```swift
// FIX: Protect with os_unfair_lock or make LLMGateway an actor
private let apiKeyLock = NSLock()
private var _inMemoryAPIKey: String?
var inMemoryAPIKey: String? {
    get { apiKeyLock.withLock { _inMemoryAPIKey } }
    set { apiKeyLock.withLock { _inMemoryAPIKey = newValue } }
}
```
**Effort**: S | **Depends on**: Nothing

### HIGH-17: No health disclaimer (App Store blocker)
**Files**: `OnboardingView.swift`, `SettingsView.swift`
```swift
// FIX: Add mandatory health disclaimer to onboarding (must acknowledge) and settings
// "This app does not provide medical advice. Always consult a healthcare professional."
```
**Effort**: S | **Depends on**: Nothing

### HIGH-18: No data deletion capability (GDPR/CCPA)
**File**: `Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift`
```swift
// FIX: Add "Delete All My Data" function that:
// 1. Deletes all Core Data entities
// 2. Clears vector index directory
// 3. Removes Keychain entries
// 4. Clears UserDefaults
// 5. Resets to onboarding state
```
**Effort**: M | **Depends on**: Nothing

---

## 4. MEDIUM PRIORITY FIXES

| ID | File | Issue | Fix |
|----|------|-------|-----|
| MED-01 | RecRanker.swift, StateEstimator.swift | No synchronization (data races) | Convert to actors |
| MED-02 | SentimentService.swift | NL provider missing from fallback chain | Add NaturalLanguageSentimentProvider() |
| MED-03 | ManagedObjects.swift | 19 scalar type mismatches (NSNumber? vs Double) | Fix types |
| MED-04 | LibraryImporter.swift | Non-atomic three-phase commit | Single context.save() |
| MED-05 | PIIRedactor.swift | Missing SSN, address, credit card patterns | Add regex patterns |
| MED-06 | SafetyAgent.swift | Crisis message US-centric | Locale-aware resources |
| MED-07 | OnboardingView.swift | Bypasses orchestrator authorization | Wait for orchestrator |
| MED-08 | LLMGateway.swift | testAPIConnection bypasses consent | Add consent param |
| MED-09 | Package.swift (PulsumData) | Compiled .momd may be stale | Remove .momd or add check |
| MED-10 | DiagnosticsTypes.swift:244 | DayFormatter uses UTC | Use TimeZone.current |
| MED-11 | VectorIndex.swift:334 | NSLock inside actor | Remove (actor suffices) |
| MED-12 | FoundationModelsTopicGateProvider.swift | Returns nil topic always | Implement topic extraction |
| MED-13 | LLMGateway.swift | No rate limiting on API calls | Add max 1 req/3s |
| MED-14 | LLMGateway.swift, FoundationModelsCoachGenerator.swift | sanitize drops !? punctuation | Regex-based split |
| MED-15 | CoachAgent+Coverage.swift | Hard-coded thresholds undocumented | Add rationale comments |
| MED-16 | AppViewModel.swift, PulsumRootView.swift | No onboarding persistence | Add @AppStorage flag |
| MED-17 | LLMGateway.swift | No SSL pinning for OpenAI | Implement cert pinning |
| MED-18 | CoreMLEmbeddingFallbackProvider.swift:26 | assertionFailure only in DEBUG | Throw error in Release too |
| MED-19 | VectorIndex.swift:324 | sqrt() without NaN guard | `sqrt(max(sum, 0))` |
| MED-20 | SafetyAgent.swift | No timeout on FM classification | Add 5s timeout |
| MED-21 | SpeechService.swift:354-358 | Timeout task leak | Store and cancel task |
| MED-22 | All UI files | 500+ hardcoded English strings | Extract to String Catalog |
| MED-23 | SettingsViewModel.swift | 573-line God Object | Decompose into 4 VMs |
| MED-24 | glow.swift:76-78 | UIScreen.main.bounds hardcoded | Use GeometryReader |

---

## 5. LOW PRIORITY FIXES

| ID | File | Issue | Fix |
|----|------|-------|-----|
| LOW-01 | EvidenceScorer.swift | Dead domain entries | Remove "pubmed", fix others |
| LOW-02 | BaselineMath.swift | zScore division by zero risk | Guard in RobustStats.init |
| LOW-03 | StateEstimator.swift | NaN propagation corrupts weights | Guard NaN in predict/update |
| LOW-04 | SpeechService.swift | Duplicate #if DEBUG | Remove duplicate |
| LOW-05 | RecRanker.swift | Silent state discard on version mismatch | Log .warn |
| LOW-06 | CoachViewModel.swift | Missing deinit task cancellation | Add deinit |
| LOW-07 | PulseViewModel/CoachViewModel | Fire-and-forget task leaks | Store and cancel |
| LOW-08 | ScoreBreakdownView/SettingsView | DateFormatter per render | Static cached formatters |
| LOW-09 | Test files | Duplicate TestCoreDataStack | Extract shared module |
| LOW-10 | PulsumTests.swift | Empty placeholder test | Remove or populate |
| LOW-11 | Pulsum.xcscheme | PulsumTests skipped | Set skipped="NO" |
| LOW-12 | KeychainService.swift | UITest fallback runtime-gated | Add #if DEBUG guard |
| LOW-13 | BuildFlags.swift:13 | nonisolated(unsafe) mutable | Add lock for DEBUG |
| LOW-14 | AppViewModel.swift:70 | firstLaunch unused | Remove dead code |
| LOW-15 | glow.swift:114 | Hex color parsing no error check | Add guard on scanHexInt64 |
| LOW-16 | project.pbxproj | Version 1.0 Build 1, no CI versioning | Auto-increment in CI |
| LOW-17 | DiagnosticsLogger.swift | Weak self in Task.detached | Add nil check |
| LOW-18 | AppViewModel.swift | Raw UserDefaults keys | Create PulsumDefaults enum |
| LOW-19 | ScoreBreakdownView.swift | Health data without units | Add unit labels |
| LOW-20 | Spline dependency | Only external dep, evaluate need | Consider Lottie/native |

---

## 6. IMPLEMENTATION SEQUENCE

### Batch 1 — Quick Safety Wins (Day 1, 2-3 hours)
These are independent, tiny changes with maximum safety impact:
1. **CRIT-02**: Change 2 lines in FoundationModelsSafetyProvider.swift
2. **CRIT-03**: Unify enum in CoachPhrasingSchema.swift + LLMGateway.swift
3. **CRIT-05**: Add crisis keywords to SafetyLocal.swift + SafetyAgent.swift
4. **CRIT-06**: Change FileProtectionType in 5 files (find/replace)
5. **CRIT-07**: Replace preconditionFailure in CoachAgent.swift
6. **CRIT-09**: Fix SafetyLocal crisis classification threshold
7. **CRIT-10**: Remove force unwrap in LLMGateway.swift
8. **CRIT-12**: Fix timer leaks in glow.swift
9. **HIGH-05**: Fix isAnalyzing stuck in PulseViewModel.swift
10. **HIGH-08**: Guard HealthKit force unwraps
11. **HIGH-12**: Fix force unwrap in AgentOrchestrator.swift
12. **HIGH-13**: Remove AFM gate from embedding provider
13. **HIGH-14**: Fix anchor store read/write race
14. **HIGH-15**: Add reprocessDay to submitTranscript
15. **HIGH-16**: Synchronize LLMGateway.inMemoryAPIKey

### Batch 2 — Core Data Fixes (Day 2, 4-6 hours)
Must be done together since they touch the data layer:
1. **CRIT-01**: Fix VectorIndex hashValue sharding
2. **CRIT-04**: Make DataStack.init throwing (+ update AppViewModel)
3. **HIGH-09**: Add atomic writes to VectorIndex
4. **HIGH-11**: Remove NSLock from VectorIndex actor

### Batch 3 — ML Correctness (Day 3, 3-4 hours)
1. **HIGH-01**: Fix RecRanker Bradley-Terry gradient
2. **HIGH-02**: Add NL fallback to SentimentService
3. **HIGH-03**: Make topic gate permissive when degraded
4. **MED-01**: Add synchronization to RecRanker/StateEstimator

### Batch 4 — Concurrency Safety (Day 4-5, 6-8 hours)
1. **HIGH-04**: Fix LegacySpeechBackend data race
2. **HIGH-10**: Fix @unchecked Sendable across 7 files
3. **CRIT-11**: Fix SentimentAgent JournalResult Sendable
4. **CRIT-08**: Add UserDefaults to privacy manifest

### Batch 5 — UI & Accessibility (Day 6, 4-6 hours)
1. **HIGH-06**: Replace fixed fonts with Dynamic Type
2. **HIGH-07**: Replace performAndWait with async perform
3. **MED-24**: Fix UIScreen.main.bounds in glow.swift

### Batch 6 — App Store Compliance (Day 7-8, 6-8 hours)
1. **HIGH-17**: Add health disclaimer
2. **HIGH-18**: Add data deletion
3. **MED-16**: Add onboarding persistence
4. **MED-06**: Localize crisis message

### Batch 7 — Medium Priority (Week 2-3)
All MED items from section 4, in order listed.

### Batch 8 — Low Priority (Ongoing)
All LOW items from section 5.

---

## 7. CALCULATION CORRECTIONS

### RecRanker Pairwise Update (HIGH-01)
```swift
// BEFORE (RecRanker.swift:128-136):
let gradPreferred = 1.0 - logistic(dotPreferred)
let gradOther = -logistic(dotOther)
// Pushes ALL scores toward 0.5

// AFTER (correct Bradley-Terry):
let margin = dotOther - dotPreferred
let gradient = logistic(margin)  // sigma(s_other - s_preferred)
for k in allKeys {
    let xPref = preferred.vector[k] ?? 0
    let xOther = other.vector[k] ?? 0
    weights[k, default: 0] += learningRate * gradient * (xPref - xOther)
}
bias += learningRate * gradient
```

### BaselineMath Division by Zero (LOW-02)
```swift
// BEFORE (BaselineMath.swift:23):
(value - stats.median) / stats.mad  // Can be Inf if mad == 0

// AFTER:
(value - stats.median) / max(stats.mad, 1e-6)
```

### StateEstimator NaN Guard (LOW-03)
```swift
// ADD at top of predict() and update():
guard features.allSatisfy({ !$0.value.isNaN }) else {
    Diagnostics.log(level: .warn, category: .ml, name: "nan.features", fields: [:])
    return bias  // or throw
}
```

### VectorIndex sqrt NaN Guard (MED-19)
```swift
// BEFORE:
return sqrt(sum)
// AFTER:
return sqrt(max(sum, 0))
```

---

## 8. APP STORE BLOCKERS

| Blocker | Fix | Effort | Priority |
|---------|-----|--------|----------|
| No health disclaimer | Add to onboarding + settings | S | P0 |
| No data deletion (GDPR) | Add "Delete All Data" in settings | M | P0 |
| Privacy manifest incomplete | Add UserDefaults required reason | S | P0 |
| Crisis message US-only | Locale-aware crisis resources | S | P1 |
| BYOK model not documented | Clear onboarding explaining key requirement | S | P1 |
| PulsumTests skipped in scheme | Set skipped="NO" | S | P2 |
| No crash reporting | Add MetricKit minimum | M | P1 |
| Version 1.0 Build 1 | CI auto-increment | S | P2 |

---

## 9. QUICK WINS (Under 30 minutes each)

| Fix | Time | Impact |
|-----|------|--------|
| CRIT-02: Change 2 `return .safe` to `.caution` | 5 min | Safety-critical |
| CRIT-03: Add "nutrition" to schema enum | 10 min | Fixes cloud API failures |
| CRIT-05: Add 15 crisis keywords to 2 arrays | 15 min | Safety-critical |
| CRIT-06: Find/replace FileProtectionType in 5 files | 10 min | Security |
| CRIT-07: Replace 2 preconditionFailure calls | 5 min | Crash prevention |
| CRIT-08: Add UserDefaults to privacy manifest | 10 min | App Store compliance |
| CRIT-10: Remove force unwrap in LLMGateway | 5 min | Crash prevention |
| HIGH-05: Add isAnalyzing = false to stopRecording | 5 min | UI fix |
| HIGH-12: Fix force unwrap in AgentOrchestrator | 5 min | Crash prevention |
| HIGH-13: Remove AFM gate from embedding provider | 10 min | Fixes cold start |
| HIGH-15: Add reprocessDay to submitTranscript | 5 min | Score accuracy |
| LOW-04: Delete duplicate #if DEBUG line | 2 min | Cleanup |
| LOW-10: Delete empty PulsumTests.swift | 2 min | Cleanup |
| LOW-11: Set skipped="NO" in scheme | 2 min | CI fix |

**Total quick wins: ~95 minutes for 14 fixes**

---

## 10. VERIFICATION PLAN

After each batch:
1. Run full test suite: `swift test --package-path Packages/PulsumML && swift test --package-path Packages/PulsumData && swift test --package-path Packages/PulsumServices && swift test --package-path Packages/PulsumAgents && swift test --package-path Packages/PulsumUI`
2. Build for simulator: `xcodebuild -scheme Pulsum -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/PulsumDerivedData build`
3. Run swiftformat: `swiftformat .`
4. Run privacy manifest check: `scripts/ci/check-privacy-manifests.sh`

### Specific verification per batch:
- **Batch 1**: Run SafetyLocalTests, LLMGatewaySchemaTests, VectorIndexTests
- **Batch 2**: Run Gate5_VectorIndexConcurrencyTests, PulsumDataBootstrapTests
- **Batch 3**: Run Gate6_RecRankerLearningTests, EmbeddingServiceFallbackTests
- **Batch 4**: Run all concurrency tests with Thread Sanitizer enabled
- **Batch 5**: Manual test with Accessibility Large Text setting
- **Batch 6**: Manual test onboarding flow, data deletion, health disclaimer presence

---

## 11. FILES MODIFIED PER BATCH (for dependency tracking)

### Batch 1 (14 files):
- `FoundationModelsSafetyProvider.swift` (CRIT-02)
- `CoachPhrasingSchema.swift` + `LLMGateway.swift` (CRIT-03)
- `SafetyLocal.swift` + `SafetyAgent.swift` (CRIT-05, CRIT-09)
- `RecRankerStateStore.swift` + `EstimatorStateStore.swift` + `BackfillStateStore.swift` + `SentimentAgent.swift` + `HealthKitAnchorStore.swift` (CRIT-06)
- `CoachAgent.swift` (CRIT-07)
- `glow.swift` (CRIT-12)
- `PulseViewModel.swift` (HIGH-05)
- `HealthKitService.swift` (HIGH-08)
- `AgentOrchestrator.swift` (HIGH-12, HIGH-15)
- `AFMTextEmbeddingProvider.swift` (HIGH-13)

### Batch 2 (4 files):
- `VectorIndex.swift` (CRIT-01, HIGH-09, HIGH-11)
- `DataStack.swift` (CRIT-04)
- `PulsumManagedObjectModel.swift` (CRIT-04 related)
- `AppViewModel.swift` (error handling for DataStack)

### Batch 3 (4 files):
- `RecRanker.swift` (HIGH-01)
- `SentimentService.swift` (HIGH-02)
- `EmbeddingTopicGateProvider.swift` (HIGH-03)
- `StateEstimator.swift` (MED-01)

### Batch 4 (8+ files):
- `SpeechService.swift` (HIGH-04)
- `EmbeddingService.swift`, `SentimentService.swift`, `LibraryImporter.swift`, `HealthKitService.swift`, `KeychainService.swift`, `HealthKitAnchorStore.swift`, `EstimatorStateStore.swift` (HIGH-10)
- `SentimentAgent.swift` (CRIT-11)
- `PrivacyInfo.xcprivacy` (all packages) (CRIT-08)
