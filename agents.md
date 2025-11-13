# CLAUDE.md

## Commands
- Lint: swiftformat --lint .
- Format: swiftformat .


This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ READ THIS FIRST

**CRITICAL CONTEXT** - These issues affect all development:

1. **Test Suite is 17 Days Outdated** (Oct 6 vs Oct 23 code)
   - 90% of tests don't reflect current behavior
   - New features have ZERO test coverage
   - See bugs.md for complete analysis

2. **Privacy Manifests Verified** (keep privacyreport gate green)
   - App target + all 5 packages now ship `PrivacyInfo.xcprivacy`
   - Run `scripts/ci/check-privacy-manifests.sh` (optionally `RUN_PRIVACY_REPORT=1`) before every push
   - Files must remain in XML/Property List format; `xcrun privacyreport` requires Xcode 16+ CLI tools

3. **Voice Journal API Changed** (Oct 23, 2025 - TODAY)
   - Old: `recordVoiceJournal()` single call
   - New: `beginVoiceJournal()` → consume stream → `finishVoiceJournal()`
   - Some docs still describe old API

4. **Some "Completed" Features Are Stubs**
   - iOS 26 ModernSpeechBackend just calls fallback
   - Verify implementation before assuming it works
   - See bugs.md section on "Known Stubs"

5. **Essential Reading Order**
   - **bugs.md** - All known issues (READ FIRST!)
   - **This file (CLAUDE.md)** - Current context
   - **instructions.md** - Requirements (some outdated)
   - **architecture.md** - System design (voice journal section outdated)

---

## Project Overview

Pulsum is an iOS 26+ wellness coaching application that combines machine learning, HealthKit integration, and AI-powered coaching. The app uses a multi-layered architecture with on-device ML processing, safety guardrails, and optional cloud integration for personalized wellbeing support.

## First-Time Setup

Before building the project for the first time:

1. Create configuration file from template:
   ```bash
   cp Config.xcconfig.template Config.xcconfig
   ```

2. Edit `Config.xcconfig` and replace `YOUR_OPENAI_API_KEY_HERE` with an actual OpenAI API key

3. The Config.xcconfig file is gitignored and must never be committed

## Build Commands

### Building the Project

```bash
# Build the main app target
xcodebuild -scheme Pulsum -sdk iphoneos

# Build all packages
swift build

# Build specific package
swift build --package-path Packages/PulsumAgents
```

### Running Tests

```bash
# Run all tests
swift test

# Run tests for specific package
swift test --package-path Packages/PulsumAgents

# Run specific test via xcodebuild
xcodebuild test -scheme PulsumAgents -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Clean Build (when encountering Foundation Models issues)

```bash
# Clean all build artifacts
rm -rf .build
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/org.swift.swiftpm

# Then in Xcode:
# Product → Clean Build Folder
# File → Packages → Reset Package Caches
# File → Packages → Resolve Package Versions
```

## Architecture

### Package Structure

The project uses a modular Swift Package Manager architecture with 5 local packages:

```
Pulsum (Main App)
├── PulsumML (Base Layer) - ML algorithms, embeddings, sentiment, safety
├── PulsumData (Data Layer) - Core Data models, repositories, vector index
├── PulsumServices (Service Layer) - HealthKit, Speech, LLM Gateway, Keychain
├── PulsumAgents (Agent Layer) - AgentOrchestrator, Data/Sentiment/Coach/Safety agents
└── PulsumUI (UI Layer) - SwiftUI views, design system, view models
```

**Dependency Flow** (acyclic):
- PulsumML and PulsumData are base layers (no dependencies on other Pulsum packages)
- PulsumServices depends on PulsumData and PulsumML
- PulsumAgents depends on PulsumServices, PulsumData, and PulsumML
- PulsumUI depends on all packages
- Main app target depends on PulsumUI

### Core Data Model

Key entities in `Pulsum.xcdatamodeld`:
- **JournalEntry**: Voice journal transcripts with sentiment scores
- **DailyMetrics**: Aggregated HealthKit data (HRV, sleep, steps, heart rate, respiratory rate)
- **Baseline**: Statistical baselines for personalization
- **FeatureVector**: ML-ready feature vectors with z-score normalization
- **MicroMoment**: Wellness intervention recommendations
- **RecommendationEvent**: User interaction tracking for ML ranking

### ML Provider Architecture

The system uses a **multi-tier fallback strategy** for ML operations:

1. **Foundation Models** (iOS 26+, when available) - Primary provider using Apple's latest AI
2. **AFM (Alternative Foundation Models)** - Secondary provider with iOS 26 APIs
3. **Core ML Models** - On-device fallback models (`PulsumFallbackEmbedding.mlmodel`, `PulsumSentimentCoreML.mlmodel`)
4. **Legacy NL Framework** - Final fallback using Natural Language framework

This pattern is used across:
- Sentiment analysis (PulsumML/Sentiment)
- Safety classification (PulsumML/Safety)
- Text embeddings (PulsumML/Embeddings)
- Coach text generation (PulsumServices/LLMGateway)

### Agent System

**AgentOrchestrator** coordinates specialized agents with a two-wall guardrail system:

- **Wall 1 (Safety)**: Local ML classification blocks unsafe content before cloud processing
- **Wall 2 (Grounding)**: Validates LLM responses are grounded in user data

Agent types:
- **DataAgent**: Computes wellbeing scores, health metrics, statistical analysis
- **SentimentAgent**: Processes voice journals, performs PII redaction, stores embeddings
- **CoachAgent**: Generates recommendations using ML ranking (RecRanker)
- **SafetyAgent**: Crisis detection, safety classification, cloud processing decisions
- **CheerAgent**: Positive reinforcement and encouragement

**Gate‑2 contract notes (2025‑11‑11):**
- `DataAgent` now exposes `reprocessDay(date:)` so journaling can refresh wellbeing immediately; `AgentOrchestrator.finishVoiceJournalRecording` awaits that call and emits `Notification.Name.pulsumScoresUpdated`.
- `SentimentAgent` uses an internal `JournalSessionState` (serial queue) to enforce a single `SpeechService.Session`; duplicate `beginVoiceJournal` calls throw `SentimentAgentError.sessionAlreadyActive`.
- UI surfaces `.savedToastMessage` + `updateVoiceJournalTranscript(_:)` via `PulseViewModel`, so transcripts remain visible until the user explicitly clears them.

## Key Technical Details

### iOS 26 Requirement

The app targets iOS 26+ to leverage Foundation Models. However, Foundation Models integration has fallback implementations so the app remains functional on devices without Apple Intelligence capabilities.

### HealthKit Integration

Required permissions:
- HRV (Heart Rate Variability)
- Heart Rate
- Sleep Analysis
- Step Count
- Respiratory Rate

HealthKit service uses:
- **Observer queries** for real-time monitoring
- **Anchored queries** for resumable data collection
- **Background delivery** when app is not running

### Vector Index

Custom binary format for similarity search:
- **Location**: `Application Support/VectorIndex/`
- **Sharding**: 16 shards for performance
- **Distance metric**: L2 (Euclidean distance)
- **File protection**: Complete protection for PHI compliance

### Privacy and Safety

- **PII Redaction**: Automatic removal of emails, phone numbers, names from journal entries
- **File Protection**: All health data stored with `NSFileProtectionComplete`
- **Consent Management**: Cloud processing is opt-in, disabled by default
- **Safety Classification**: Multi-tier crisis detection with configurable thresholds

## Testing Patterns

### ⚠️ CRITICAL: Test Suite Status

**As of Oct 23, 2025:**
- Tests last updated: Oct 6, 2025 (17 days ago)
- Code last updated: Oct 23, 2025 (TODAY)
- Alignment: 10.5% (only 2/19 tests current)
- SPM package tests: NOT running in Xcode scheme

**Impact:**
- Tests pass but test OLD behavior
- New features (voice streaming, LLM validation) have ZERO tests
- Don't assume tests validate current code

**See bugs.md for:**
- Complete test coverage analysis
- Which tests to trust
- Recommended fix strategy (3 options)

### Writing Tests

Tests use XCTest with these patterns:

```swift
import XCTest
@testable import PulsumAgents
@testable import PulsumData

@MainActor  // Required for agent tests
final class MyTests: XCTestCase {

    // Use #if guards for iOS-specific tests
    func testHealthKitFeature() async throws {
#if !os(iOS)
        throw XCTSkip("HealthKit only available on iOS")
#else
        // test code
#endif
    }

    // Use in-memory Core Data for testing
    private func makeInMemoryContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "Pulsum")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error { fatalError("In-memory store error: \(error)") }
        }
        return container
    }
}
```

### UITest Env Flags
- `UITEST_USE_STUB_LLM=1` routes `LLMGateway` to a deterministic stub so smoke tests never call GPT-5 or require API keys.
- `UITEST_FAKE_SPEECH=1` plus `UITEST_AUTOGRANT=1` swaps the speech backend with a deterministic transcript stream that auto-grants permissions—ideal for CI harnesses.
- `UITEST_AUTOGRANT=1` alone simply fast-tracks microphone permission prompts for simulator runs (ignored when the fake backend is off).

### iOS 26 Availability Checks

When working with Foundation Models or iOS 26 APIs:

```swift
if #available(iOS 26.0, *) {
    // Use Foundation Models provider
} else {
    // Use fallback implementation
}
```

## Known Stubs and Placeholders

Some features marked "completed" in instructions.md are actually stubs or partial implementations:

### iOS 26 ModernSpeechBackend
**File:** `Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift:272-303`
**Status:** STUB - Just calls legacy fallback
**Impact:** No actual iOS 26 speech APIs used, despite iOS 26 requirement
**Code:**
```swift
// Placeholder: integrate SpeechAnalyzer/SpeechTranscriber APIs when publicly available.
// For now we reuse the legacy backend to ensure functionality while maintaining the interface.
return try await fallback.startRecording(maxDuration: maxDuration)
```

### BGTaskScheduler Integration
**Mentioned in:** todolist.md
**Status:** NOT IMPLEMENTED
**Impact:** No true background processing (only HealthKit background delivery)

### Empty Test Placeholder
**File:** `PulsumTests/PulsumTests.swift`
**Status:** Empty implementation - no actual tests

See bugs.md for complete list of stubs and partial implementations.

---

## Important Implementation Notes

### Before Making Changes

**Always:**
1. Read bugs.md to check if area has known issues
2. Check git history: `git log --oneline <file>`
3. Verify tests exist AND are current (most are NOT)
4. Update BOTH code and tests together
5. Update relevant documentation

**Never:**
1. Trust test passing as proof of correctness (tests are outdated)
2. Assume "completed" features work (verify implementation)
3. Skip updating docs after changes
4. Use `@unchecked Sendable` without justification
5. Bypass safety guardrails or PII redaction

### When Modifying ML Providers

All ML providers should follow the multi-tier fallback pattern. Check existing implementations in:
- `PulsumML/Sources/PulsumML/Sentiment/`
- `PulsumML/Sources/PulsumML/Safety/`
- `PulsumML/Sources/PulsumML/Embeddings/`
- The Foundation Models stub now mirrors the real `LanguageModelSession` generic API; when AFM is unavailable the stub throws so providers must catch and fall back (see `EmbeddingServiceFallbackTests` for guardrails).

### When Adding Core Data Entities

1. Modify `Pulsum.xcdatamodeld` in main app target
2. Create lightweight migration or mapping model
3. Update repository layer in PulsumData
4. Add corresponding tests with in-memory container

### When Working with HealthKit

- Always check authorization status before queries
- Use anchored queries for efficiency
- Persist anchors securely for query resumption
- Handle background delivery properly

### Safety and Guardrails

The two-wall system is critical:
- Never bypass SafetyAgent classification
- Always redact PII before cloud processing
- Respect user consent preferences for cloud features
- Test crisis detection scenarios thoroughly

## Common Issues

### Test Suite Outdated (CRITICAL)

If tests pass but code seems broken:
- Tests were last updated Oct 6, 2025
- Code changed significantly Oct 8, 9, 19, 23
- See bugs.md for which tests to trust
- Don't rely on tests as proof of correctness

### Privacy Manifests (MANDATORY - Keep them in sync)

- App + all five Swift packages now ship `PrivacyInfo.xcprivacy` declarations (Gate 0 fix for BUG-20251026-0002).
- Run `scripts/ci/check-privacy-manifests.sh` to ensure they remain present; set `RUN_PRIVACY_REPORT=1` to invoke `xcrun privacyreport` when the Xcode 16+ CLI tools are installed.
- Manifests must stay in property-list (XML) format so Apple’s tooling can parse them; do not revert to JSON.

### Voice Journal API Changed (Oct 23, 2025)

**Old API (DO NOT USE):**
```swift
let result = try await sentimentAgent.recordVoiceJournal(maxDuration: 30)
```

**New API (USE THIS):**
```swift
// 1. Begin recording
try await sentimentAgent.beginVoiceJournal(maxDuration: 30)

// 2. Consume speech stream in real-time
var transcript = ""
if let stream = sentimentAgent.speechStream {
    for try await segment in stream {
        transcript = segment.transcript
        // Update UI with transcript in real-time
    }
}

// 3. Finish and persist
let result = try await sentimentAgent.finishVoiceJournal(transcript: transcript)
```

**Files affected:**
- `SentimentAgent.swift:56-98`
- `AgentOrchestrator.swift:159-184`
- `PulseView.swift`

### "Cannot find FoundationModels in scope"

The Foundation Models framework requires iOS 26 SDK. If encountering compilation issues:
1. Verify Xcode version supports iOS 26
2. Run clean build commands (see above)
3. Check that platform is set to `.iOS(.v26)` in Package.swift files

### Config.xcconfig Missing

If build fails with "OPENAI_API_KEY not defined":
1. Ensure `Config.xcconfig` exists (copy from template)
2. Add actual API key to the file
3. Clean build folder and rebuild

### Core Data Migration Issues

If seeing Core Data version mismatch errors:
1. Delete app from simulator/device
2. Clean build folder
3. Rebuild and reinstall

## Documentation

**Essential Files** (in priority order):
- **bugs.md** - Known issues and broken connections (READ FIRST!)
- **CLAUDE.md** (this file) - AI assistant context and current state
- **instructions.md** - Original requirements (some sections outdated)
- **architecture.md** - System design (voice journal section outdated)
- **todolist.md** - Planned work

Key documentation in `Docs/`:
- `COMPREHENSIVE_CODEBASE_ANALYSIS.md` - Detailed architecture analysis
- `CONFIG_SETUP.md` - API key configuration guide
- `Foundation_Models_Activation_Guide.md` - Foundation Models integration details
- `architecture_and_scaffolding.md` - Original architecture blueprint

## Deployment Requirements

- Xcode with iOS 26 SDK
- macOS development machine
- iOS 26+ device or simulator for testing
- Valid Apple Developer account for HealthKit entitlements
- OpenAI API key for cloud LLM features
