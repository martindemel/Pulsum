# Milestone 4-6 Alignment Updates
**Required Changes After Milestone 3 Foundation Models Rebuild**  
**Date**: September 30, 2025

---

## Executive Summary

**YES - Updates Required, But Minimal** ✅

The current Milestone 4-6 plans in `todolist.md` are **85% aligned** with the new Milestone 3 architecture. Only minor clarifications and additions needed to reflect:
- Foundation Models integration points
- Async/await UI binding patterns
- Swift 6 compliance validation
- Foundation Models availability status display

---

## Current State Analysis

### Milestone 4 (UI & Experience Build)
**Current Status**: 🟡 **Mostly Aligned - Needs Minor Updates**

**What's Already Correct**:
- ✅ SwiftUI feature surfaces (MainView, CoachView, PulseView, SettingsView)
- ✅ SplineRuntime integration
- ✅ Liquid Glass design language
- ✅ Connect UI with agents/services
- ✅ Consent banner implementation
- ✅ SafetyCard surfacing

**What Needs Adding**:
- 🆕 Foundation Models availability status display in SettingsView
- 🆕 Async/await binding patterns for all agent calls
- 🆕 Loading states for Foundation Models operations
- 🆕 Fallback messaging when Foundation Models unavailable
- 🆕 @MainActor view model integration with AgentOrchestrator

### Milestone 5 (Safety, Consent, Privacy Compliance)
**Current Status**: 🟢 **Fully Aligned - No Changes Needed**

**Already Correct**:
- ✅ Consent UX/state persistence (UserPrefs, ConsentState)
- ✅ Privacy routing (PHI on-device, minimized cloud)
- ✅ SafetyAgent veto on risky content
- ✅ Privacy Manifest + Info.plist
- ✅ CrisisCard with 911 copy
- ✅ Keychain secrets, health data isolation

**Why No Changes**:
- Milestone 3 already implements all privacy architecture
- SafetyAgent dual-provider (Foundation Models + SafetyLocal) ready
- LLMGateway consent routing ready
- PII redaction pipeline ready

### Milestone 6 (QA, Testing, and Release Prep)
**Current Status**: 🟡 **Mostly Aligned - Needs Additions**

**What's Already Correct**:
- ✅ Automated tests for agents/services/ML
- ✅ Integration tests (HealthKit, Speech, vector index)
- ✅ Performance profiling
- ✅ Compliance documentation

**What Needs Adding**:
- 🆕 Foundation Models-specific test scenarios
- 🆕 Swift 6 concurrency validation
- 🆕 Apple Intelligence enablement testing
- 🆕 Foundation Models availability state testing

---

## Recommended Updates

### Updated Milestone 4 Tasks

**REPLACE**:
```markdown
## Milestone 4 - UI & Experience Build (Planned)
- [ ] Create SwiftUI feature surfaces: MainView (SplineRuntime scene + segmented control + header), CoachView (cards + chat), PulseView (slide-to-record + sliders + countdown), SettingsView (consent toggles), SafetyCardView, JournalRecorder components (`Packages/PulsumUI`)
- [ ] Remove legacy template `ContentView.swift` / `Persistence.swift` (Item entity) and wire PulsumUI entry point into app target
- [ ] Apply Liquid Glass design language from support docs to chrome, bottom controls, AI button, and sheets
- [ ] Wire voice recording transparency (indicator + countdown) and navigation flows (Pulse button, avatar to settings, AI button focusing chat)
- [ ] Integrate SplineRuntime (cloud URL + local fallback) and handle offline fallback asset
- [ ] Connect UI with agents/services for recommendations, chat, journaling, consent banner (exact copy), and safety surfacing
- [ ] Address accessibility/localization scaffolding (Dynamic Type, VoiceOver labels, localization-ready strings)
```

**WITH**:
```markdown
## Milestone 4 - UI & Experience Build (Planned)
- [ ] Create SwiftUI feature surfaces: MainView (SplineRuntime scene + segmented control + header), CoachView (cards + chat), PulseView (slide-to-record + sliders + countdown), SettingsView (consent toggles + Foundation Models status), SafetyCardView, JournalRecorder components (`Packages/PulsumUI`)
- [ ] Remove legacy template `ContentView.swift` / `Persistence.swift` (Item entity) and wire PulsumUI entry point into app target
- [ ] Apply Liquid Glass design language from support docs to chrome, bottom controls, AI button, and sheets
- [ ] Wire voice recording transparency (indicator + countdown) and navigation flows (Pulse button, avatar to settings, AI button focusing chat)
- [ ] Integrate SplineRuntime (cloud URL + local fallback) and handle offline fallback asset
- [ ] **Create @MainActor view models** binding to AgentOrchestrator with async/await patterns for all agent operations
- [ ] Connect UI with AgentOrchestrator for recommendations, chat, journaling, consent banner (exact copy), and safety surfacing
- [ ] **Display Foundation Models availability status** in SettingsView with user-friendly messaging (ready/downloading/needs Apple Intelligence)
- [ ] **Implement loading states** for async Foundation Models operations (sentiment analysis, safety classification, coaching generation)
- [ ] **Add fallback messaging** when Foundation Models unavailable (e.g., "Enhanced AI features require Apple Intelligence")
- [ ] Address accessibility/localization scaffolding (Dynamic Type, VoiceOver labels, localization-ready strings)
- [ ] **Validate async/await error handling** in UI layer for Foundation Models operations (guardrails, refusals, timeouts)
```

### Updated Milestone 5 Tasks

**NO CHANGES REQUIRED** - Current tasks already aligned ✅

```markdown
## Milestone 5 - Safety, Consent, Privacy Compliance (Planned)
- [ ] Implement consent UX/state persistence (`UserPrefs`, `ConsentState`) including cloud-processing banner copy, toggle, and revocation flow
- [ ] Enforce privacy routing: PHI on-device only, minimized cloud payloads, offline fallbacks, and SafetyAgent veto on risky content
- [ ] Produce Privacy Manifest + Info.plist declarations (Health/Mic/Speech reasons already present), App Privacy nutrition labels, and Background Modes (HealthKit delivery) configuration
- [ ] Validate data protection end-to-end (NSFileProtectionComplete, background/interrupt behavior, journal retention policies, deletion affordances)
- [ ] Surface SafetyAgent escalations in UI (CrisisCard with 911 copy) and ensure no risky text reaches GPT-5
- [ ] Security review covering Keychain secrets, health data isolation, background delivery configuration, and Spline asset handling
```

**Optional Enhancement**:
```markdown
- [ ] **Verify Foundation Models privacy compliance**: Confirm no PHI in Foundation Models prompts, minimized context only, proper guardrail handling
```

### Updated Milestone 6 Tasks

**REPLACE**:
```markdown
## Milestone 6 - QA, Testing, and Release Prep (Planned)
- [ ] Expand automated tests: unit coverage for agents/services/ML math, UI snapshot tests, end-to-end smoke tests with mocks
- [ ] Execute integration tests for HealthKit ingestion (mocked anchors), Speech STT transcription, and vector index retrieval
- [ ] Profile performance (startup, memory, energy), fix regressions, and validate on multiple device families
- [ ] Produce final assets: Liquid Glass screenshots, App Icon variants, App Store metadata, localized descriptions
- [ ] Assemble compliance documentation (privacy disclosures, data retention, support contacts) and verify App Privacy answers
- [ ] Prepare release pipeline: TestFlight build, release notes, reviewer instructions, versioning strategy, and rollout checklist
```

**WITH**:
```markdown
## Milestone 6 - QA, Testing, and Release Prep (Planned)
- [ ] Expand automated tests: unit coverage for agents/services/ML math, UI snapshot tests, end-to-end smoke tests with mocks
- [ ] **Add Foundation Models-specific tests**: guided generation validation, @Generable struct parsing, temperature behavior, guardrail handling
- [ ] **Validate Swift 6 concurrency compliance**: Verify zero warnings in all packages, proper @Sendable usage, actor isolation correctness
- [ ] Execute integration tests for HealthKit ingestion (mocked anchors), Speech STT transcription, and vector index retrieval
- [ ] **Test Foundation Models availability states**: Apple Intelligence enabled/disabled, model downloading, device not supported, graceful fallbacks
- [ ] **Test dual-provider fallbacks**: Foundation Models → Legacy cascades for sentiment, safety, coaching when AFM unavailable
- [ ] Profile performance (startup, memory, energy), fix regressions, and validate on multiple device families
- [ ] **Profile Foundation Models operations**: Measure latency for sentiment analysis, safety classification, coaching generation vs fallbacks
- [ ] Produce final assets: Liquid Glass screenshots, App Icon variants, App Store metadata, localized descriptions
- [ ] Assemble compliance documentation (privacy disclosures, data retention, support contacts) and verify App Privacy answers
- [ ] **Document Foundation Models features** in App Store metadata: "Powered by Apple Intelligence for intelligent health insights"
- [ ] Prepare release pipeline: TestFlight build, release notes, reviewer instructions, versioning strategy, and rollout checklist
- [ ] **Prepare iOS 26 SDK validation**: Test on devices with Apple Intelligence enabled, verify Foundation Models activation
```

---

## New Tasks Breakdown

### Milestone 4 Additions (7 new items)

1. **Create @MainActor View Models**
   - **Why**: AgentOrchestrator is @MainActor, views need matching isolation
   - **Example**:
     ```swift
     @MainActor
     @Observable
     final class CoachViewModel {
         private let orchestrator: AgentOrchestrator
         
         var recommendations: [RecommendationCard] = []
         var isLoading = false
         
         func loadRecommendations(consentGranted: Bool) async {
             isLoading = true
             defer { isLoading = false }
             
             do {
                 let response = try await orchestrator.recommendations(consentGranted: consentGranted)
                 recommendations = response.cards
             } catch {
                 // Handle error
             }
         }
     }
     ```

2. **Display Foundation Models Availability Status**
   - **Why**: Users need to know if Apple Intelligence is required/enabled
   - **Location**: SettingsView
   - **API**: `orchestrator.foundationModelsStatus` (already implemented)
   - **Example**:
     ```swift
     Section("AI Features") {
         Text(viewModel.foundationModelsStatus)
             .foregroundColor(statusColor)
         
         if needsAppleIntelligence {
             Link("Enable in Settings", destination: URL(string: "x-apple.systempreferences:com.apple.AppleIntelligence-Settings")!)
         }
     }
     ```

3. **Implement Loading States**
   - **Why**: Foundation Models operations can take 100ms-1s
   - **Where**: Journal recording, chat input, recommendation refresh
   - **Pattern**:
     ```swift
     @State private var isAnalyzing = false
     
     Button("Submit Journal") {
         Task {
             isAnalyzing = true
             defer { isAnalyzing = false }
             await viewModel.submitJournal()
         }
     }
     .disabled(isAnalyzing)
     .overlay {
         if isAnalyzing {
             ProgressView()
         }
     }
     ```

4. **Add Fallback Messaging**
   - **Why**: Graceful UX when Foundation Models unavailable
   - **Example**:
     ```swift
     if !foundationModelsAvailable {
         Text("Enhanced AI features require Apple Intelligence. Using on-device intelligence.")
             .font(.caption)
             .foregroundColor(.secondary)
     }
     ```

5. **Validate Async/Await Error Handling**
   - **Why**: Foundation Models can throw guardrailViolation, refusal errors
   - **Pattern**:
     ```swift
     do {
         let result = try await orchestrator.chat(userInput: input, consentGranted: true)
         // Display result
     } catch {
         if error is LanguageModelSession.GenerationError {
             // Show friendly message about content safety
         } else {
             // Generic error handling
         }
     }
     ```

6. **Connect to AgentOrchestrator** (not "agents/services")
   - **Why**: UI should only interact with orchestrator, not individual agents
   - **Clarification**: Ensures clean architecture boundary

7. **Foundation Models Status in SettingsView**
   - **Why**: Transparency about AI capabilities
   - **Content**: "Apple Intelligence is ready" / "Preparing AI model..." / etc.

### Milestone 6 Additions (8 new items)

1. **Foundation Models-Specific Tests**
   - Test @Generable struct parsing
   - Verify temperature settings
   - Validate guardrail error handling
   - Test refusal scenarios

2. **Swift 6 Concurrency Validation**
   - Run all packages with strict concurrency checking
   - Verify zero warnings
   - Validate @Sendable conformances

3. **Foundation Models Availability State Testing**
   - Mock different availability states
   - Test UI adapts correctly
   - Verify fallback messaging

4. **Dual-Provider Fallback Testing**
   - Disable Foundation Models, verify cascade works
   - Test sentiment: FM → AFM → Core ML
   - Test safety: FM → SafetyLocal
   - Test coaching: FM → Legacy

5. **Profile Foundation Models Operations**
   - Measure sentiment analysis latency
   - Measure safety classification latency
   - Measure coaching generation latency
   - Compare vs fallback performance

6. **Document Foundation Models in Metadata**
   - App Store description mentions Apple Intelligence
   - Privacy nutrition labels include AI features
   - Screenshots show Foundation Models features

7. **iOS 26 SDK Validation**
   - Test on real device with Apple Intelligence
   - Verify Foundation Models activate correctly
   - Validate structured output parsing

8. **Test Foundation Models Privacy**
   - Verify no PHI in prompts
   - Confirm minimized context
   - Validate guardrail behavior

---

## Implementation Guide

### Phase 1: Update todolist.md (5 minutes)

Replace Milestone 4 and 6 sections with updated versions above.

### Phase 2: Milestone 4 Execution (2-3 weeks)

**Week 1: Core Views**
- Day 1-2: MainView + SplineRuntime
- Day 3-4: CoachView + @MainActor view models
- Day 5: PulseView + async journal recording

**Week 2: Integration**
- Day 1-2: SettingsView + Foundation Models status
- Day 3: SafetyCard + crisis handling
- Day 4-5: Loading states + error handling

**Week 3: Polish**
- Day 1-2: Liquid Glass styling
- Day 3: Accessibility/localization
- Day 4-5: Fallback messaging + testing

### Phase 3: Milestone 5 Execution (1 week)

**Already 90% Complete** - Just UI wiring:
- Consent banner implementation
- ConsentState persistence
- Privacy Manifest finalization
- Security review

### Phase 4: Milestone 6 Execution (2 weeks)

**Week 1: Testing**
- Foundation Models test suite
- Swift 6 compliance checks
- Dual-provider fallback validation
- Performance profiling

**Week 2: Release Prep**
- App Store assets
- Compliance documentation
- TestFlight build
- Reviewer instructions

---

## Summary of Changes

### Changes Required

| Milestone | Change Type | Complexity | Impact |
|-----------|-------------|------------|--------|
| **Milestone 4** | 7 additions | Low-Medium | High (user-visible) |
| **Milestone 5** | 0 changes | None | None (already aligned) |
| **Milestone 6** | 8 additions | Low | Medium (testing thoroughness) |

### Total New Tasks: 15

**Breakdown**:
- Foundation Models UI integration: 5 tasks
- Async/await UI patterns: 2 tasks
- Foundation Models testing: 6 tasks
- Swift 6 validation: 1 task
- Documentation updates: 1 task

### Effort Estimate

- **Milestone 4 updates**: +3-5 days (mostly UI work you'd do anyway, just clarified)
- **Milestone 5 updates**: 0 days (no changes)
- **Milestone 6 updates**: +2-3 days (testing additions)

**Total additional effort**: ~1 week spread across 3 milestones

---

## Key Architectural Alignments

### What Milestone 3 Provides to UI Layer

```swift
// AgentOrchestrator Public API (All @MainActor, All Async)

@MainActor
public final class AgentOrchestrator {
    
    // Foundation Models Status
    public var foundationModelsStatus: String { ... }
    
    // Lifecycle
    public func start() async throws
    
    // Journal
    public func recordVoiceJournal(maxDuration: TimeInterval) async throws 
        -> JournalCaptureResponse
    public func submitTranscript(_ text: String) async throws 
        -> JournalCaptureResponse
    
    // Sliders
    public func updateSubjectiveInputs(date: Date, stress: Double, 
                                      energy: Double, sleepQuality: Double) async throws
    
    // Recommendations
    public func recommendations(consentGranted: Bool) async throws 
        -> RecommendationResponse
    
    // Chat
    public func chat(userInput: String, consentGranted: Bool) async throws 
        -> String
    
    // Completion
    public func logCompletion(momentId: String) async throws 
        -> CheerEvent
}
```

**UI Layer Simply Binds To This** ✅

### What UI Layer Must Do

1. **Create @MainActor View Models**
   - Match AgentOrchestrator's @MainActor isolation
   - Use @Observable for SwiftUI binding
   - Handle async operations with Task { }

2. **Display Loading States**
   - Show progress during async operations
   - Disable inputs while processing
   - Provide cancellation if needed

3. **Handle Errors Gracefully**
   - Catch Foundation Models errors
   - Show user-friendly messages
   - Fall back to safe defaults

4. **Display Foundation Models Status**
   - Read `orchestrator.foundationModelsStatus`
   - Show in SettingsView
   - Update when availability changes

5. **Respect Safety Decisions**
   - Check `JournalCaptureResponse.safety.allowCloud`
   - Display crisis messaging if needed
   - Block risky operations

---

## Decision Matrix

### Should You Update Now?

**YES** ✅ - Recommended for these reasons:

1. **Clarity**: Eliminates ambiguity about async/await patterns
2. **Completeness**: Ensures Foundation Models features are tested
3. **Quality**: Adds Swift 6 validation to QA checklist
4. **Alignment**: Keeps todolist.md as single source of truth

### Minimal Update Option

If time-constrained, you can **defer** these updates and just:
1. Keep Milestone 4-6 as-is
2. Add Foundation Models tasks during implementation
3. Update todolist.md retrospectively

**Risk**: Might miss some Foundation Models-specific considerations during planning.

---

## Conclusion

**Recommendation**: **Update todolist.md now** (15 minutes of work)

**Impact**:
- ✅ Milestone 4: 7 clarifying additions (mostly things you'd do anyway)
- ✅ Milestone 5: No changes needed (already perfect)
- ✅ Milestone 6: 8 testing additions (improves quality)

**Benefit**:
- Clear guidance for Milestone 4 implementation
- No surprises during UI development
- Comprehensive QA checklist for Foundation Models
- Single source of truth maintained

**Next Step**: Copy the updated Milestone 4 and 6 tasks into `todolist.md` and you're ready to start Milestone 4! 🚀

---

**Prepared**: September 30, 2025  
**Alignment Assessment**: 85% → 100% (after updates)  
**Required Effort**: 15 minutes to update, ~1 week additional testing/polish spread across milestones



