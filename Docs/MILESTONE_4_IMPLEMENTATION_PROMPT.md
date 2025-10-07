# Pulsum Milestone 4 Implementation Prompt
**For New Coding Session - Complete Context Transfer**

---

## ROLE & OBJECTIVE

You are a principal iOS architect and senior SwiftUI engineer continuing the Pulsum health AI app. **Milestones 0-3 are complete** (agent system, data layer, services, Foundation Models integration). Your job is to implement **Milestone 4: UI & Experience Build** - the production SwiftUI interface that brings the sophisticated backend to life.

This is **production code for App Store submission** - no placeholders, no examples, no mock UIs. Every feature must be fully functional and beautiful.

---

## CRITICAL FIRST STEP: COMPREHENSIVE CODEBASE ANALYSIS

**Before reading documentation, analyze the ENTIRE codebase first:**

Initially, analyze the entire codebase, including all folders and subfolders, as well as all files within these folders, to understand what is already available from the Xcode project. **Do not skip lines; read it all.** This is critical to ensure you have complete context and can identify anything that might have been missed.

**What to Analyze**:
1. **Xcode Project**: `Pulsum.xcodeproj/project.pbxproj` - targets, build settings, capabilities
2. **App Target**: `Pulsum/PulsumApp.swift`, `Pulsum/ContentView.swift`, `Pulsum/Persistence.swift`
3. **Core Data Model**: `Pulsum/Pulsum.xcdatamodeld/Pulsum.xcdatamodel/contents` - all 9 entities
4. **Assets**: `Pulsum/Assets.xcassets/` - app icon, accent color
5. **Package: PulsumAgents**: All source files in `Packages/PulsumAgents/Sources/PulsumAgents/`
   - AgentOrchestrator.swift (144 lines)
   - DataAgent.swift (1,017 lines)
   - SentimentAgent.swift (106 lines)
   - CoachAgent.swift (265 lines)
   - SafetyAgent.swift (56 lines)
   - CheerAgent.swift (33 lines)
   - PulsumAgents.swift (API)
6. **Package: PulsumML**: All source files in `Packages/PulsumML/Sources/PulsumML/`
   - Foundation Models providers (Sentiment, Safety, Availability)
   - ML algorithms (StateEstimator, RecRanker, BaselineMath)
   - Embedding services
   - SafetyLocal
7. **Package: PulsumServices**: All source files in `Packages/PulsumServices/Sources/PulsumServices/`
   - HealthKitService, SpeechService, LLMGateway, KeychainService
   - FoundationModelsCoachGenerator
8. **Package: PulsumData**: All source files in `Packages/PulsumData/Sources/PulsumData/`
   - DataStack, VectorIndex, LibraryImporter, EvidenceScorer
   - Model/ManagedObjects.swift
9. **Package: PulsumUI**: Current state in `Packages/PulsumUI/Sources/PulsumUI/`
10. **All Package.swift files**: Verify dependencies, platform targets, linked frameworks
11. **Test files**: Understand test patterns and coverage
12. **Support files**: `/ios support documents/`, `/json database/`, `mainanimation.usdz`

**Why This Matters**: Ensures you know exactly what's implemented, what APIs are available, what patterns to follow, and can catch any discrepancies between documentation and code.

---

## THEN: READ THESE FILES (IN ORDER)

**Do not skip any lines. Read every file completely to understand the full context.**

### 1. Primary Specification (MUST READ FIRST)
```
@instructions.md
```
**Why**: Complete product specification, technical stack, UI navigation, agent system architecture, Foundation Models requirements, privacy rules

### 2. Project Status & Planning (MUST READ SECOND)
```
@todolist.md
```
**Why**: Milestone completion status (0-3 done, 4-6 pending), your specific tasks for Milestone 4, dependencies, notes

### 3. Architecture Validation (MUST READ THIRD)
```
@pulsumvalidationmilestone3.md
```
**Why**: Complete Milestone 3 architecture review (1,736 lines), agent system design, data flows, Foundation Models integration points, what's already built and ready for UI integration

### 4. Implementation Analysis (READ FOURTH)
```
@MILESTONE_3_COMPLETION_ANALYSIS.md
```
**Why**: Verification that Milestone 3 is 100% complete with no placeholders, Swift 6 compliance, production-ready status

### 5. Foundation Models Details (READ FIFTH)
```
@archchangem3.md
```
**Why**: Documents the complete Milestone 3 rebuild, what was implemented, architecture patterns, Foundation Models provider details

### 6. Recent Updates (READ SIXTH)
```
@DOCUMENTATION_UPDATES_SEPT_30.md
```
**Why**: Latest documentation alignment, Milestone 4 patterns, code examples for view models, error handling

### 7. External Review (READ SEVENTH)
```
@EXTERNAL_REVIEW_ANALYSIS.md
```
**Why**: Architecture validation (A- grade), SpeechAnalyzer migration requirement, Privacy Manifest requirement

---

## CURRENT PROJECT STATUS

### ✅ MILESTONES 0-3: COMPLETE (Production-Ready Foundation)

**What's Already Built for You**:

#### Agent System (Milestone 3 - COMPLETE ✅)
- **AgentOrchestrator** (144 lines): @MainActor manager pattern, Foundation Models-aware, async API
  - Public methods: start(), recordVoiceJournal(), submitTranscript(), updateSubjectiveInputs(), recommendations(), chat(), logCompletion()
  - Foundation Models status property: `foundationModelsStatus: String`
  
- **DataAgent** (1,017 lines): Sophisticated health analytics engine
  - HealthKit ingestion (6 sample types)
  - Baseline computation (Median/MAD/EWMA)
  - StateEstimator integration
  - Feature vector generation with z-scores
  
- **SentimentAgent** (106 lines): Journal processing with Foundation Models
  - On-device speech recognition
  - Foundation Models sentiment analysis cascade
  - PII redaction
  - Vector embedding persistence
  
- **CoachAgent** (265 lines): ML-driven recommendations
  - Vector similarity search
  - RecRanker pairwise logistic scoring
  - Foundation Models intelligent caution assessment
  - Consent-aware LLM routing
  
- **SafetyAgent** (56 lines): Dual-provider safety
  - Foundation Models safety classification (primary)
  - SafetyLocal keyword/embedding classifier (fallback)
  - Crisis detection with 911 messaging
  
- **CheerAgent** (33 lines): Positive reinforcement

#### Data Layer (Milestone 2 - COMPLETE ✅)
- Core Data with 9 entities (NSFileProtectionComplete)
- Vector index with memory-mapped shards (L2 search)
- LibraryImporter for JSON podcast recommendations
- EvidenceScorer for domain policy

#### Services (Milestone 2 - COMPLETE ✅)
- HealthKitService with anchored queries
- SpeechService (to be upgraded to SpeechAnalyzer in M4)
- LLMGateway with consent-aware routing
- KeychainService for secrets

#### ML Algorithms (Milestone 2 - COMPLETE ✅)
- StateEstimator (online ridge regression)
- RecRanker (pairwise logistic)
- BaselineMath (Median/MAD/EWMA)
- SafetyLocal (embedding classifier)

#### Foundation Models (Milestone 3 - COMPLETE ✅)
- 4 Foundation Models providers with @Generable structs
- Guided generation throughout
- Proper availability checking
- Graceful fallback cascades
- Swift 6 compliant (zero warnings)

**Build Status**: All packages compile successfully ✅  
**Test Status**: All test suites pass ✅  
**Concurrency**: Zero Swift 6 warnings ✅

---

## YOUR MILESTONE 4 TASKS (From todolist.md)

### UI Components to Build (14 tasks total):

1. **Create SwiftUI Views**:
   - MainView (SplineRuntime scene + segmented control + header)
   - CoachView (recommendation cards + chat)
   - PulseView (slide-to-record + sliders + countdown)
   - SettingsView (consent toggles + Foundation Models status)
   - SafetyCardView (crisis messaging)

2. **Remove Legacy Code**:
   - Delete `ContentView.swift` (template)
   - Delete `Persistence.swift` (template Item entity)
   - Wire PulsumUI as app entry point

3. **Apply Liquid Glass Design**:
   - Use iOS 26 material system
   - Apply to: header bar, bottom controls, AI button, sheets
   - Reference: `/ios support documents/` folder

4. **Navigation & Interactions**:
   - Pulse button → open PulseView
   - Avatar button → open SettingsView
   - AI button → switch to Coach + focus chat
   - Recording indicator + countdown
   - Auto-dismiss flows

5. **SplineRuntime Integration**:
   - Cloud URL: https://build.spline.design/ke82QL0jX3kJzGuGErDD/scene.splineswift
   - Local fallback: `mainanimation.splineswift`
   - Handle offline gracefully

6. **Foundation Models Integration (NEW)**:
   - Create @MainActor view models for all views
   - Bind to AgentOrchestrator with async/await
   - Display Foundation Models status in SettingsView
   - Show loading states during async operations
   - Handle Foundation Models errors (guardrailViolation, refusal)
   - Display fallback messaging when unavailable

7. **Speech API Migration (NEW)**:
   - Migrate to SpeechAnalyzer/SpeechTranscriber (iOS 26+)
   - Keep SFSpeechRecognizer fallback (pre-iOS 26)
   - Factory pattern based on availability

8. **Accessibility/Localization**:
   - Dynamic Type support
   - VoiceOver labels
   - Localization-ready strings

---

## ARCHITECTURE PATTERNS YOU MUST FOLLOW

### Pattern 1: @MainActor View Models (REQUIRED)

**From instructions.md lines 285-308**:

```swift
@MainActor
@Observable
final class CoachViewModel {
    private let orchestrator: AgentOrchestrator
    var recommendations: [RecommendationCard] = []
    var isLoading = false
    var errorMessage: String?
    
    init(orchestrator: AgentOrchestrator) {
        self.orchestrator = orchestrator
    }
    
    func loadRecommendations(consentGranted: Bool) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await orchestrator.recommendations(consentGranted: consentGranted)
            recommendations = response.cards
        } catch {
            errorMessage = "Unable to load recommendations"
        }
    }
}
```

**Apply this pattern to EVERY view** (MainView, CoachView, PulseView, SettingsView).

### Pattern 2: AgentOrchestrator as Single Entry Point

**CRITICAL**: UI connects **ONLY** to AgentOrchestrator, **NEVER** directly to individual agents.

```swift
// ✅ CORRECT:
@State private var orchestrator: AgentOrchestrator

Task {
    let response = try await orchestrator.recommendations(consentGranted: true)
}

// ❌ WRONG - DO NOT DO THIS:
@State private var coachAgent: CoachAgent  // NO!
```

### Pattern 3: Loading States for Async Operations

```swift
@State private var isLoading = false

Button("Submit Journal") {
    Task {
        isLoading = true
        defer { isLoading = false }
        await viewModel.submitJournal()
    }
}
.disabled(isLoading)
.overlay {
    if isLoading {
        ProgressView("Analyzing...")
    }
}
```

**Apply to**: Journal recording, chat input, recommendation refresh, slider submission

### Pattern 4: Foundation Models Error Handling

```swift
do {
    let result = try await orchestrator.chat(userInput: input, consentGranted: true)
    chatMessages.append(result)
} catch let error as LanguageModelSession.GenerationError {
    switch error {
    case .guardrailViolation:
        showError("Let's keep the focus on supportive wellness actions")
    case .refusal:
        showError("Unable to process that request. Try rephrasing.")
    default:
        showError("Something went wrong. Please try again.")
    }
} catch {
    showError("Unable to generate response")
}
```

### Pattern 5: Foundation Models Status Display

```swift
// In SettingsView:
Section("AI Features") {
    Text(orchestrator.foundationModelsStatus)
        .foregroundColor(statusColor(for: orchestrator.foundationModelsStatus))
    
    if orchestrator.foundationModelsStatus.contains("Enable") {
        Link("Open Settings", 
             destination: URL(string: "App-Prefs:root=APPLE_INTELLIGENCE")!)
    }
}
```

### Pattern 6: Safety Decision Handling

```swift
let journalResponse = try await orchestrator.recordVoiceJournal(maxDuration: 30)

// ALWAYS check safety before proceeding
if !journalResponse.safety.allowCloud {
    switch journalResponse.safety.classification {
    case .crisis:
        // Show CrisisCard
        showCrisisCard(message: journalResponse.safety.crisisMessage ?? "If you're in immediate danger, call 911")
        return  // Block further operations
    case .caution:
        // Proceed with on-device only
        showMessage("Processing on-device for your safety")
    case .safe:
        break
    }
}
```

---

## UI SPECIFICATIONS (From instructions.md)

### MainView Structure

```
┌─────────────────────────────────────────────┐
│  [Pulse 🔴]              [Avatar 👤]        │ ← Header (Liquid Glass)
├─────────────────────────────────────────────┤
│                                             │
│                                             │
│         SplineView (3D Animation)           │
│     https://build.spline.design/...         │
│                                             │
│                                             │
├─────────────────────────────────────────────┤
│  [Main | Coach]                     [AI 🤖] │ ← Bottom Controls (Liquid Glass)
└─────────────────────────────────────────────┘
```

**Header**:
- Top-left: Pulse button (SF Symbol: waveform.circle.fill) → opens PulseView
- Top-right: Avatar button (SF Symbol: person.crop.circle) → opens SettingsView
- Apply Liquid Glass material

**Center**:
- SplineView with cloud URL (primary)
- Local fallback if offline
- `.ignoresSafeArea(.all)`

**Bottom Left**:
- Segmented control: "Main" | "Coach"
- Start on Main
- Switching changes center content

**Bottom Right**:
- AI button with icon
- Tap → switch to Coach tab AND focus chat input
- Apply Liquid Glass glow effect

### CoachView Structure

```
┌─────────────────────────────────────────────┐
│  Recommendation Cards                       │
│  ┌───────────────────────────────────────┐ │
│  │ TOP PICK (Expanded)                   │ │
│  │ Title                                 │ │
│  │ Body (shortDescription + detail)      │ │
│  │ [Strong] badge                        │ │
│  │ Caution: "..." (if present)           │ │
│  └───────────────────────────────────────┘ │
│  ┌─────────────────┐ ┌─────────────────┐  │
│  │ Alt 1 (Compact) │ │ Alt 2 (Compact) │  │
│  │ (Tap to expand) │ │ (Tap to expand) │  │
│  └─────────────────┘ └─────────────────┘  │
│                                             │
│  [Scroll area]                              │
│                                             │
├─────────────────────────────────────────────┤
│  💬 Chat Input (Always visible, sticky)    │ ← Liquid Glass
│  [Type your message...]            [Send]  │
└─────────────────────────────────────────────┘
```

**Cards**:
- Top Pick: Expanded by default
- 2 alternates: Collapsed, tap to expand
- Show: title, body, sourceBadge (Strong/Medium/Weak)
- Caution message if present (Foundation Models intelligent assessment)
- Tap checkmark → logCompletion() → CheerAgent toast

**Chat**:
- Sticky bottom input (Liquid Glass)
- Keyboard on first tap
- Send → orchestrator.chat()
- Display loading state during generation
- Handle Foundation Models errors

### PulseView Structure

```
┌─────────────────────────────────────────────┐
│  Voice Journal                              │
│  ┌───────────────────────────────────────┐ │
│  │  ⏺ Slide to Record (≤30s)            │ │
│  │  [========>            ]              │ │
│  │  🔴 Recording... 0:23                 │ │ ← Always visible
│  └───────────────────────────────────────┘ │
│                                             │
│  OR  [Skip Recording]                       │
│                                             │
│  Sliders (1-7 scale):                       │
│  ────────────────────────────────────────  │
│  Stress Level                         [5]   │
│  (SISQ wording)                             │
│  ────────────────────────────────────────  │
│  Energy Level                         [3]   │
│  (NRS wording)                              │
│  ────────────────────────────────────────  │
│  Sleep Quality                        [4]   │
│  (SQS wording)                              │
│  ────────────────────────────────────────  │
│                                             │
│              [Submit Pulse]                 │
│  Auto-dismiss ≤3s after submit              │
└─────────────────────────────────────────────┘
```

**Voice Recording**:
- Slide-to-record gesture
- Max 30 seconds with countdown
- **Always-visible** recording indicator (red dot + timer)
- Stop on background/interrupt
- Call: `orchestrator.recordVoiceJournal(maxDuration: 30)`
- Check safety decision before proceeding

**Sliders**:
- Three sliders: Stress (1-7), Energy (1-7), Sleep Quality (1-7)
- Use research-validated wording (SISQ, NRS, SQS)
- Can skip recording and just submit sliders
- Call: `orchestrator.updateSubjectiveInputs(date:stress:energy:sleepQuality:)`

**Auto-dismiss**: ≤3 seconds after submit

### SettingsView Structure

```
┌─────────────────────────────────────────────┐
│  Privacy & Consent                          │
│  ────────────────────────────────────────  │
│  Cloud Processing              [Toggle OFF] │
│  ────────────────────────────────────────  │
│                                             │
│  AI Features                                │
│  ────────────────────────────────────────  │
│  Foundation Models Status:                  │
│  "Apple Intelligence is ready"              │
│  [or other status message]                  │
│  ────────────────────────────────────────  │
│                                             │
│  Resources                                  │
│  ────────────────────────────────────────  │
│  Safety Resources                      →    │
│  Privacy Policy                        →    │
│  ────────────────────────────────────────  │
└─────────────────────────────────────────────┘
```

**Cloud Processing Toggle**:
- Default: OFF
- UserPrefs.consentCloud persistence
- Show banner on first toggle to ON (exact copy in instructions.md)

**Foundation Models Status**:
- Read: `orchestrator.foundationModelsStatus`
- Display current status
- Provide Settings link if Apple Intelligence needs enabling

### SafetyCardView (Crisis Intervention)

```
┌─────────────────────────────────────────────┐
│  ⚠️  If You're In Immediate Danger          │
│                                             │
│  If you're in the United States,            │
│  call 911 right away.                       │
│                                             │
│  [Call 911]                                 │
│                                             │
│  Other Resources:                           │
│  • National Suicide Prevention: 988         │
│  • Crisis Text Line: Text HOME to 741741    │
│                                             │
│              [Close]                        │
└─────────────────────────────────────────────┘
```

**Trigger**: When `SafetyDecision.classification == .crisis`  
**Behavior**: Modal sheet, blocks all other operations until dismissed  
**Copy**: Exact wording above (US-focused for now)

---

## TECHNICAL REQUIREMENTS

### Swift & Frameworks
- **Swift 6.2** with strict concurrency checking
- **SwiftUI** with Observation framework
- **SplineRuntime** for 3D scene
- **iOS 26+** deployment target
- Import **PulsumAgents** package (not individual agent packages)

### Concurrency Model
- **@MainActor** for all view models
- **@Observable** for state management
- **async/await** for all AgentOrchestrator calls
- **Task { }** for SwiftUI async operations

### Error Handling
- Catch `LanguageModelSession.GenerationError.guardrailViolation`
- Catch `LanguageModelSession.GenerationError.refusal`
- Generic error catch for network/timeout
- Display user-friendly messages (see instructions.md lines 329-335)

### Loading States
- Show `ProgressView` during async operations
- Disable inputs while processing
- Messages: "Analyzing...", "Generating response...", "Finding suggestions..."

### Liquid Glass Design
- Reference files in `/ios support documents/`
- Apply to: header, bottom controls, AI button, modal sheets
- Use iOS 26 material system APIs
- Translucent, blurred backgrounds
- Proper depth and layering

---

## CRITICAL CONSTRAINTS

### Privacy (NON-NEGOTIABLE)
- ✅ No PHI leaves device (except minimized context with consent)
- ✅ Display consent banner before first cloud call
- ✅ Respect `SafetyDecision.allowCloud`
- ✅ Show crisis messaging when needed
- ✅ No audio storage (transcript only)

### Foundation Models (REQUIRED)
- ✅ Display `orchestrator.foundationModelsStatus` in SettingsView
- ✅ Show loading states for async operations
- ✅ Handle guardrail/refusal errors gracefully
- ✅ Display fallback messaging when unavailable

### Agent Interaction (REQUIRED)
- ✅ Connect ONLY to AgentOrchestrator
- ✅ Never import individual agent packages
- ✅ Use async/await for all orchestrator methods
- ✅ Handle all responses as async

### UI Quality (REQUIRED)
- ✅ Production-quality Liquid Glass styling
- ✅ Smooth animations and transitions
- ✅ Proper loading states (no frozen UI)
- ✅ Accessible (Dynamic Type, VoiceOver)
- ✅ No placeholders or "Coming Soon" stubs

---

## IMPLEMENTATION SEQUENCE

### Phase 1: Project Setup (Day 1)
1. Review all documentation files listed above
2. Understand AgentOrchestrator API (pulsumvalidationmilestone3.md has complete details)
3. Create PulsumUI package structure
4. Set up @MainActor view models

### Phase 2: Core Views (Days 2-5)
1. MainView with SplineRuntime integration
2. Navigation structure (Pulse button, Avatar, AI button)
3. Segmented control (Main | Coach)
4. SettingsView with Foundation Models status

### Phase 3: Feature Views (Days 6-10)
1. PulseView with voice recording + sliders
2. Migrate to SpeechAnalyzer/SpeechTranscriber
3. CoachView with recommendation cards
4. Chat input with async response handling
5. SafetyCardView for crisis intervention

### Phase 4: Polish (Days 11-15)
1. Apply Liquid Glass design throughout
2. Loading states and error handling
3. Foundation Models fallback messaging
4. Accessibility/localization
5. Remove legacy ContentView.swift

### Phase 5: Integration Testing (Days 16-20)
1. End-to-end flow testing
2. Foundation Models availability states
3. Safety decision handling
4. Consent flow validation
5. Performance validation

---

## WHAT YOU HAVE AVAILABLE (AgentOrchestrator API)

### Lifecycle
```swift
public func start() async throws
```

### Journal Capture
```swift
public func recordVoiceJournal(maxDuration: TimeInterval = 30) async throws 
    -> JournalCaptureResponse

public func submitTranscript(_ text: String) async throws 
    -> JournalCaptureResponse

// Returns:
struct JournalCaptureResponse {
    let result: JournalResult
    let safety: SafetyDecision  // ← ALWAYS CHECK THIS
}
```

### Subjective Inputs (Sliders)
```swift
public func updateSubjectiveInputs(
    date: Date, 
    stress: Double,      // 1-7
    energy: Double,      // 1-7
    sleepQuality: Double // 1-7
) async throws
```

### Recommendations
```swift
public func recommendations(consentGranted: Bool) async throws 
    -> RecommendationResponse

// Returns:
struct RecommendationResponse {
    let cards: [RecommendationCard]
    let wellbeingScore: Double
    let contributions: [String: Double]
}

struct RecommendationCard {
    let id: String
    let title: String
    let body: String
    let caution: String?        // Foundation Models intelligent assessment
    let sourceBadge: String     // "Strong" / "Medium" / "Weak"
}
```

### Chat
```swift
public func chat(userInput: String, consentGranted: Bool) async throws 
    -> String
```

### Completion Logging
```swift
public func logCompletion(momentId: String) async throws 
    -> CheerEvent

struct CheerEvent {
    let message: String
    let haptic: HapticStyle
    let timestamp: Date
}
```

### Foundation Models Status
```swift
public var foundationModelsStatus: String { get }
```

---

## DESIGN REFERENCE

### Liquid Glass Elements
- Check `/ios support documents/` for official Apple guidance
- Key files:
  - `Liquid Glass _ Apple Developer Documentation.pdf`
  - `Landmarks_ Building an app with Liquid Glass.pdf`
  - `Adopting Liquid Glass.pdf`

### SplineRuntime Integration
- Example in instructions.md lines 91-104
- Cloud URL: https://build.spline.design/ke82QL0jX3kJzGuGErDD/scene.splineswift
- Local fallback: `mainanimation.splineswift` in project root

### Consent Banner Copy (EXACT)
```
"Pulsum can optionally use GPT‑5 to phrase brief coaching text. If you allow cloud processing, Pulsum sends only minimized context (no journals, no raw health data, no identifiers). PII is redacted. You can turn this off anytime in Settings ▸ Cloud Processing."
```

---

## QUALITY STANDARDS

### Code Quality
- ✅ Zero Swift 6 concurrency warnings
- ✅ All views @MainActor
- ✅ All agent calls async/await
- ✅ Proper error handling
- ✅ No force unwraps
- ✅ No placeholders

### User Experience
- ✅ Smooth animations (60fps)
- ✅ Responsive (no frozen UI during async)
- ✅ Loading states always visible
- ✅ Error messages user-friendly
- ✅ Accessible (VoiceOver, Dynamic Type)
- ✅ Beautiful Liquid Glass styling

### Privacy Compliance
- ✅ Consent banner before cloud calls
- ✅ Safety decisions respected
- ✅ Crisis messaging displayed
- ✅ Recording indicator always visible
- ✅ No audio storage

---

## SUCCESS CRITERIA (Milestone 4 Complete When...)

1. ✅ All 5 views implemented and functional
2. ✅ SplineRuntime integration working (cloud + fallback)
3. ✅ Liquid Glass design applied throughout
4. ✅ All AgentOrchestrator methods wired to UI
5. ✅ Foundation Models status displayed
6. ✅ Loading states for all async operations
7. ✅ Error handling for Foundation Models operations
8. ✅ Safety decisions handled correctly
9. ✅ Consent flow implemented
10. ✅ SpeechAnalyzer migration complete
11. ✅ Legacy ContentView.swift removed
12. ✅ App runs end-to-end from launch to journal to recommendations to chat
13. ✅ Zero Swift 6 warnings
14. ✅ Accessible and localizable

---

## FILES YOU'LL CREATE

### New Files in Packages/PulsumUI/Sources/PulsumUI/
```
Views/
├── MainView.swift
├── CoachView.swift
├── PulseView.swift
├── SettingsView.swift
└── SafetyCardView.swift

ViewModels/
├── MainViewModel.swift
├── CoachViewModel.swift
├── PulseViewModel.swift
└── SettingsViewModel.swift

Components/
├── RecommendationCardView.swift
├── ChatInputView.swift
├── RecordingIndicatorView.swift
└── CheerToastView.swift

Utilities/
├── LiquidGlassModifiers.swift
└── SplineSceneLoader.swift
```

### Updates to Existing Files
- `Pulsum/PulsumApp.swift` - Wire PulsumUI as root
- Delete: `Pulsum/ContentView.swift`
- Delete: `Pulsum/Persistence.swift`

### New Service Migration
- `Packages/PulsumServices/Sources/PulsumServices/ModernSpeechService.swift` (SpeechAnalyzer)
- Update: `SpeechService.swift` to factory pattern

---

## VALIDATION CHECKLIST

Before considering Milestone 4 complete, verify:

- [ ] All views implemented with no placeholders
- [ ] @MainActor view models for each view
- [ ] AgentOrchestrator wired to all views
- [ ] Foundation Models status displayed in SettingsView
- [ ] Loading states on all async operations
- [ ] Foundation Models error handling implemented
- [ ] Safety decisions handled (crisis card shows)
- [ ] Consent banner implemented with exact copy
- [ ] SplineRuntime loads (cloud with fallback)
- [ ] Liquid Glass styling applied
- [ ] SpeechAnalyzer migration complete with fallback
- [ ] Legacy ContentView.swift deleted
- [ ] App builds with zero warnings
- [ ] App runs end-to-end successfully
- [ ] All Milestone 4 tasks in todolist.md checked off

---

## IMPORTANT REMINDERS

### What NOT to Do
- ❌ Do NOT modify agent system (Milestone 3 is complete)
- ❌ Do NOT modify Core Data schema
- ❌ Do NOT add new agents or services
- ❌ Do NOT bypass AgentOrchestrator
- ❌ Do NOT skip Foundation Models status display
- ❌ Do NOT skip loading states
- ❌ Do NOT use mock data
- ❌ Do NOT create placeholder views

### What TO Do
- ✅ Read ALL documentation files first (don't skip lines)
- ✅ Use AgentOrchestrator as single entry point
- ✅ Create @MainActor view models for state management
- ✅ Display Foundation Models status prominently
- ✅ Implement comprehensive loading states
- ✅ Handle all async errors gracefully
- ✅ Apply production-quality Liquid Glass design
- ✅ Make it beautiful and functional

---

## ARCHITECTURAL CONTEXT

### What You're Building On (Milestones 0-3)

**Foundation You Have**:
- 4,865+ lines of production-ready backend code
- Sophisticated health analytics (DataAgent: 1,017 lines)
- Foundation Models integration (4 providers)
- ML-driven recommendations (RecRanker, StateEstimator)
- Privacy-first architecture (NSFileProtectionComplete)
- Swift 6 compliant (zero warnings)

**Your Job**: Create the SwiftUI layer that makes this sophisticated backend accessible, beautiful, and delightful.

### Package Structure
```
PulsumApp (iOS 26 target)
    ↓ imports
PulsumUI (you're building this)
    ↓ imports
PulsumAgents (✅ COMPLETE - just use it)
    ↓ imports
PulsumServices + PulsumData + PulsumML (✅ COMPLETE - don't modify)
```

### Dependency Rules
- PulsumUI → imports **PulsumAgents only**
- PulsumUI → uses **AgentOrchestrator only**
- PulsumUI → **never imports** PulsumServices, PulsumData, or PulsumML directly

---

## EXPECTED DELIVERABLES

### At End of Milestone 4:

1. **Functional App** that:
   - Launches to beautiful MainView with Spline scene
   - Captures voice journals with safety checks
   - Records slider inputs
   - Displays ML-ranked recommendation cards
   - Provides on-topic chat
   - Shows Foundation Models status
   - Handles consent properly

2. **Code Quality**:
   - Zero Swift 6 warnings
   - All views production-ready
   - Liquid Glass design throughout
   - Comprehensive error handling
   - Accessibility support

3. **Documentation**:
   - Update todolist.md marking Milestone 4 complete
   - Note any architectural decisions made

---

## START HERE (First Steps - MANDATORY SEQUENCE)

### Phase 1: Complete Codebase Analysis (2-3 hours)
1. **Analyze entire codebase** - all folders, subfolders, files (see section above)
2. **Read every line** of existing implementation files
3. **Understand package structure** and dependencies
4. **Verify Core Data model** matches specification
5. **Review all agent implementations** to understand APIs
6. **Note any discrepancies** between docs and code

### Phase 2: Documentation Deep Dive (1-2 hours)
7. **Read all 7 documentation files** listed at the top (in order, don't skip lines)
8. **Cross-reference** documentation against actual code
9. **Understand AgentOrchestrator API** (it's your entire backend interface)
10. **Study UI patterns** in instructions.md
11. **Review success criteria** for Milestone 4

### Phase 3: Implementation (Days 1-15)
12. **Create MainViewModel** using the pattern from instructions.md
13. **Implement MainView** with SplineRuntime
14. **Test that orchestrator integration works**
15. **Then build other views** following same patterns
16. **Update todolist.md** as you complete tasks

---

## TONE & APPROACH

- **Production mindset**: This ships to App Store, not a prototype
- **Quality first**: Beautiful, smooth, accessible
- **Foundation Models aware**: Display status, handle errors, show loading
- **Privacy conscious**: Always check safety, respect consent
- **Architecture disciplined**: Use only AgentOrchestrator, follow patterns

---

## FINAL INSTRUCTION

Read the 7 documentation files in order. Understand the complete system. Then implement Milestone 4 following the patterns in instructions.md and tracking tasks in todolist.md.

The backend is production-ready and waiting for you. Build a UI worthy of the sophisticated agent system underneath.

**Good luck! 🚀**

---

**Prompt Prepared**: September 30, 2025  
**Target**: Milestone 4 UI Implementation  
**Context**: Complete (7 documentation files, 4,865+ lines of backend code)  
**Quality Bar**: Production-ready for App Store submission
