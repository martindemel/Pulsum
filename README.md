<p align="center">
  <img src="logo2.png" alt="Pulsum Logo" width="120" height="120" style="border-radius: 24px;">
</p>

<h1 align="center">Pulsum</h1>

<p align="center">
  <strong>AI-Powered Wellness Coach for iOS 26+</strong>
</p>

<p align="center">
  <em>Privacy-first • On-device Intelligence • Agentic Architecture</em>
</p>

<p align="center">
  <a href="#overview">Overview</a> •
  <a href="#app-preview">Preview</a> •
  <a href="#ai-powered-intelligence">AI Intelligence</a> •
  <a href="#agentic-system">Agentic System</a> •
  <a href="#key-features">Features</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#installation">Installation</a> •
  <a href="#license">License</a>
</p>

---

## Overview

**Pulsum** is a next-generation iOS wellness coaching application that combines Apple's Foundation Models, HealthKit integration, and a sophisticated agentic AI system to deliver personalized wellbeing support. Built exclusively for iOS 26+, Pulsum leverages on-device machine learning to analyze health data, process voice journals, and generate contextual coaching—all while keeping your personal health information completely private.

Unlike traditional wellness apps that rely entirely on cloud processing, Pulsum implements a **privacy-first architecture** where sensitive health data never leaves your device. The app uses Apple Intelligence (Foundation Models) for local AI processing, with optional cloud integration (GPT-5) only for enhanced text phrasing—and only with explicit user consent.

### Why Pulsum?

- 🔒 **Privacy-First**: All health data stays on-device with NSFileProtectionComplete encryption
- 🧠 **On-Device AI**: Leverages Apple Intelligence for sentiment analysis, safety classification, and coaching
- 📊 **Science-Backed**: Uses validated health metrics (HRV, sleep analysis, heart rate variability) with robust statistical methods
- 🤖 **Agentic Architecture**: Multiple specialized AI agents work together to provide personalized recommendations
- 🛡️ **Safety Guardrails**: Two-wall safety system with crisis detection and content filtering
- ✨ **Beautiful UI**: iOS 26 Liquid Glass design language with smooth animations

---

## App Preview

<p align="center">
  <img src="main.gif" alt="Pulsum App Preview" width="300"/>
</p>

<p align="center">
  <em>Experience Pulsum's fluid Liquid Glass interface and AI-powered coaching in action</em>
</p>

---

## AI-Powered Intelligence

Pulsum integrates multiple layers of AI technology to provide intelligent, context-aware wellness coaching.

### Apple Foundation Models Integration

The app uses iOS 26's Foundation Models framework as the primary AI engine:

| Capability | Description | Fallback |
|------------|-------------|----------|
| **Sentiment Analysis** | Analyzes voice journal transcripts to understand emotional state | Core ML model |
| **Safety Classification** | Detects crises and sensitive content | Local keyword + embedding classifier |
| **Text Embeddings** | Generates semantic vectors for similarity search | Bundled 384-dimensional Core ML model |
| **Coach Generation** | Creates personalized coaching responses | On-device generation |

### Multi-Tier Fallback Strategy

```text
┌─────────────────────────────────────────────────────────────────┐
│                    AI Provider Cascade                          │
├─────────────────────────────────────────────────────────────────┤
│  Tier 1: Apple Foundation Models (iOS 26+ with Apple Intelligence)│
│     ↓ (if unavailable)                                          │
│  Tier 2: AFM Alternative Providers                              │
│     ↓ (if unavailable)                                          │
│  Tier 3: Core ML Models (bundled on-device)                     │
│     ↓ (if unavailable)                                          │
│  Tier 4: Natural Language Framework (Apple NL APIs)             │
└─────────────────────────────────────────────────────────────────┘
```

### Cloud Processing (Optional)

When enabled with user consent, Pulsum can enhance coaching responses using GPT-5:

- **Minimized Context Only**: Only tone hints, topic signals, and anonymized summaries are sent
- **No PHI Transmitted**: Transcripts, raw health data, and identifiers never leave the device
- **PII Redaction**: Automatic removal of emails, phone numbers, and names before any cloud processing
- **One-Tap Revocation**: Users can disable cloud processing anytime in Settings

---

## Agentic System

Pulsum implements a sophisticated **manager-pattern agent architecture** where a central AgentOrchestrator coordinates specialized AI agents as tools.

### Architecture Overview

```text
┌─────────────────────────────────────────────────────────────────┐
│                      AgentOrchestrator                          │
│        (Single User-Facing Agent • @MainActor Isolated)         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌──────────────┐  ┌───────────────┐  ┌──────────────┐        │
│   │  DataAgent   │  │ SentimentAgent│  │  CoachAgent  │        │
│   │              │  │               │  │              │        │
│   │ • HealthKit  │  │ • Voice STT   │  │ • RAG Search │        │
│   │ • Baselines  │  │ • Sentiment   │  │ • RecRanker  │        │
│   │ • Z-Scores   │  │ • Embeddings  │  │ • Phrasing   │        │
│   │ • Features   │  │ • PII Redact  │  │ • Cards      │        │
│   └──────────────┘  └───────────────┘  └──────────────┘        │
│                                                                 │
│   ┌──────────────┐  ┌───────────────┐                          │
│   │ SafetyAgent  │  │  CheerAgent   │                          │
│   │              │  │               │                          │
│   │ • Crisis Det.│  │ • Celebrations│                          │
│   │ • Content    │  │ • Haptics     │                          │
│   │   Filtering  │  │ • Toasts      │                          │
│   └──────────────┘  └───────────────┘                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Agent Responsibilities

| Agent | Purpose | Key Capabilities |
|-------|---------|------------------|
| **AgentOrchestrator** | Central coordinator | Request routing, consent gating, safety enforcement |
| **DataAgent** | Health data processing | HealthKit ingestion, baseline computation, feature vectors, wellbeing scoring |
| **SentimentAgent** | Voice journal processing | Speech-to-text, sentiment analysis, embedding generation, PII redaction |
| **CoachAgent** | Recommendation engine | Vector similarity search, ML ranking, content generation, evidence scoring |
| **SafetyAgent** | Content safety | Crisis detection, content classification, cloud routing decisions |
| **CheerAgent** | Positive reinforcement | Completion celebrations, time-aware messaging, haptic feedback |

### Two-Wall Guardrail System

Pulsum implements a dual-layer safety architecture:

**Wall 1 (On-Device)**
- Safety classification via Foundation Models or local ML
- Topic gating with 0.59 confidence threshold
- Coverage validation with median-based similarity scoring
- Blocks unsafe content before any cloud processing

**Wall 2 (Cloud)**
- GPT-5 schema validation with structured outputs
- Grounding score ≥0.5 requirement
- Response validation against user context
- Fallback to on-device generation if validation fails

### Deterministic Intent Routing

The coaching system uses a 4-step pipeline to eliminate response variability:

1. **Topic Classification**: Wall-1 ML classification (sleep, stress, energy, HRV, mood, movement, mindfulness, goals)
2. **Phrase Override**: Direct substring matching for specific terms
3. **Candidate Moments**: Top-2 moment retrieval with keyword scoring
4. **Data-Dominant Fallback**: Highest |z-score| signal selection

---

## Key Features

### 🎤 Voice Journaling

Record voice journals up to 30 seconds with real-time transcription:

- **On-device STT**: Uses iOS Speech framework with `requiresOnDeviceRecognition`
- **Live Waveform**: Visual feedback during recording
- **Countdown Timer**: Clear recording progress indication
- **Auto-Stop**: Recording halts on background/interrupt
- **Transcript Only**: Audio is never stored—only transcripts are persisted

### 📊 Health Metrics Integration

Comprehensive HealthKit integration with science-backed analysis:

| Metric | Source | Analysis |
|--------|--------|----------|
| **HRV (SDNN)** | Heart Rate Variability | Median across overnight samples |
| **Nocturnal HR** | Heart Rate | 10th percentile during sleep |
| **Resting HR** | Resting Heart Rate | Derived from low-activity periods |
| **Sleep Quality** | Sleep Analysis | Total sleep time, debt calculation |
| **Steps** | Step Count | Daily activity tracking |
| **Respiratory Rate** | Respiratory Rate | Sleep-time averages |

### 🎯 Personalized Recommendations

ML-powered recommendation system with evidence scoring:

- **Vector Similarity Search**: Custom L2 index with 16 shards
- **RecRanker ML Model**: Pairwise logistic scorer with online learning
- **Evidence Badges**: Strong (research papers) → Medium → Weak classification
- **Cooldown Management**: Prevents recommendation fatigue
- **Contextual Filtering**: Recommendations match current wellbeing state

### 📈 Statistical Baselines

Robust statistical methods for personalization:

- **30-Day Rolling Window**: Long-term trend analysis
- **Median/MAD Z-Scores**: Robust to outliers
- **EWMA Smoothing**: λ=0.2 for trend detection
- **Online Ridge Regression**: StateEstimator with SGD updates

### 🎨 Subjective Check-ins

Three validated slider scales (1-7):

| Scale | Type | Validated Instrument |
|-------|------|---------------------|
| Stress | SISQ | Single Item Stress Questionnaire |
| Energy | NRS | Numeric Rating Scale |
| Sleep Quality | SQS | Sleep Quality Scale |

---

## Architecture

### Package Structure

Pulsum uses a modular Swift Package Manager architecture:

```text
Pulsum/
├── Pulsum (Main App Target)
│   ├── PulsumApp.swift          # @main entry point
│   ├── Assets.xcassets          # App icons and colors
│   ├── PrivacyInfo.xcprivacy    # Privacy manifest
│   └── Pulsum.entitlements      # HealthKit, Keychain
│
└── Packages/
    ├── PulsumUI/                 # UI Layer (SwiftUI)
    │   ├── Views
    │   │   ├── PulsumRootView   # Tab navigation
    │   │   ├── CoachView        # Recommendations + chat
    │   │   ├── PulseView        # Voice journaling
    │   │   ├── SettingsView     # Consent & privacy
    │   │   └── SafetyCardView   # Crisis resources
    │   └── ViewModels           # @MainActor MVVM
    │
    ├── PulsumAgents/             # Agent Layer
    │   ├── AgentOrchestrator    # Central coordinator
    │   ├── DataAgent            # HealthKit + features
    │   ├── SentimentAgent       # Voice processing
    │   ├── CoachAgent           # Recommendations
    │   ├── SafetyAgent          # Content safety
    │   └── CheerAgent           # Celebrations
    │
    ├── PulsumServices/           # Service Layer
    │   ├── HealthKitService     # HK anchored queries
    │   ├── SpeechService        # On-device STT
    │   ├── LLMGateway           # Cloud API routing
    │   └── KeychainService      # Secure storage
    │
    ├── PulsumData/               # Data Layer
    │   ├── Core Data Stack      # Local persistence
    │   ├── VectorIndex          # Similarity search
    │   └── LibraryImporter      # Content ingestion
    │
    ├── PulsumML/                 # ML Layer
    │   ├── Embeddings           # Text vectorization
    │   ├── Sentiment            # Emotion analysis
    │   ├── Safety               # Classification
    │   ├── StateEstimator       # Wellbeing scoring
    │   └── RecRanker            # Recommendation ML
    │
    └── PulsumTypes/              # Shared Types
        └── SpeechTypes          # Cross-layer contracts
```

### Dependency Flow

```text
                    ┌─────────────┐
                    │  Main App   │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │  PulsumUI   │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
       ┌──────▼──────┐     │     ┌──────▼──────┐
       │PulsumAgents │     │     │PulsumTypes  │
       └──────┬──────┘     │     └─────────────┘
              │            │
       ┌──────▼──────┐     │
       │PulsumServices│    │
       └──────┬──────┘     │
              │            │
     ┌────────┼────────────┘
     │        │
┌────▼────┐ ┌─▼──────────┐
│PulsumML │ │ PulsumData │
└─────────┘ └────────────┘
```

### Core Data Entities

| Entity | Purpose |
|--------|---------|
| `JournalEntry` | Voice transcripts with sentiment scores |
| `DailyMetrics` | Aggregated HealthKit data |
| `Baseline` | Statistical baselines per metric |
| `FeatureVector` | Normalized ML input features |
| `MicroMoment` | Wellness recommendations |
| `RecommendationEvent` | User interaction tracking |
| `UserPrefs` | Consent and preferences |
| `ConsentState` | Cloud processing consent |

---

## Installation

### Requirements

- **macOS**: Latest macOS with Xcode
- **Xcode**: Version supporting iOS 26 SDK
- **iOS Device/Simulator**: iOS 26.0+
- **Apple Developer Account**: Required for HealthKit entitlements

### Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/pulsum.git
   cd pulsum
   ```

2. **Create Configuration File**
   ```bash
   cp Config.xcconfig.template Config.xcconfig
   ```

3. **Add API Key Locally** (optional, for cloud features)
   
   Configure your OpenAI key on your machine only (never commit secrets). Either set `PULSUM_COACH_API_KEY` via `launchctl setenv`/your shell environment, or add `OPENAI_API_KEY = YOUR_OPENAI_API_KEY_HERE` to your untracked `Config.xcconfig`.
   > ⚠️ Keep `Config.xcconfig` untracked; only the template lives in git.

4. **Open in Xcode**
   ```bash
   open Pulsum.xcodeproj
   ```

5. **Build & Run**
   - Select the `Pulsum` scheme
   - Choose an iOS 26+ simulator or device
   - Press `Cmd + R` to build and run

### Build Commands

```bash
# Build the main app
xcodebuild -scheme Pulsum -sdk iphoneos

# Build all packages
swift build

# Run all tests
swift test

# Run specific package tests
swift test --package-path Packages/PulsumAgents

# Lint code
swiftformat --lint .

# Format code
swiftformat .
```

### CI Scripts

```bash
# Run full test harness
scripts/ci/test-harness.sh

# Check privacy manifests
scripts/ci/check-privacy-manifests.sh

# Scan for secrets
scripts/ci/scan-secrets.sh

# Build release
scripts/ci/build-release.sh
```

---

## Privacy & Security

### Data Protection

| Data Type | Storage | Protection |
|-----------|---------|------------|
| Health metrics | Core Data (local) | NSFileProtectionComplete |
| Journal transcripts | Core Data (local) | NSFileProtectionComplete |
| Embeddings | Binary files | NSFileProtectionComplete |
| API keys | Keychain | Secure Enclave |

### Privacy Guarantees

- ✅ **No iCloud/CloudKit sync** for health data
- ✅ **Audio never stored** (transcript only)
- ✅ **PII auto-redaction** before any processing
- ✅ **Explicit consent** required for cloud features
- ✅ **One-tap revocation** of cloud permissions
- ✅ **Privacy manifests** for App Store compliance

### Consent Model

```text
Cloud Processing: OFF by default

When enabled:
• Only minimized context sent (tone hints, topic signals)
• No transcripts, raw health data, or identifiers
• PII automatically redacted
• Revocable anytime in Settings
```

---

## Technology Stack

| Component | Technology |
|-----------|------------|
| **Language** | Swift 5.10+ |
| **UI Framework** | SwiftUI |
| **AI Framework** | Apple Foundation Models |
| **Design System** | iOS 26 Liquid Glass |
| **Persistence** | Core Data (SQLite) |
| **Health Data** | HealthKit |
| **Speech** | Apple Speech Framework |
| **ML Models** | Core ML |
| **Cloud AI** | OpenAI GPT-5 (optional) |
| **Concurrency** | Swift Concurrency (async/await, actors) |

---

## Project Status

### Completed Milestones

- ✅ **Milestone 0**: Project scaffolding and architecture
- ✅ **Milestone 1**: Package structure and entitlements
- ✅ **Milestone 2**: Core Data stack with file protection
- ✅ **Milestone 3**: HealthKit integration with anchored queries
- ✅ **Milestone 4**: Baseline math and StateEstimator
- ✅ **Milestone 5**: Foundation Models integration
- ✅ **Milestone 6**: Library import and vector indexing
- ✅ **Milestone 7**: RecRanker and CoachAgent
- ✅ **Milestone 8**: Swift 6 concurrency compliance

### Current Focus

- 🔄 UI refinements and animations
- 🔄 Performance optimization
- 🔄 Additional test coverage

---

## Contributing

This project is for **educational and non-commercial purposes only**. If you'd like to learn from or reference this codebase:

1. Read the architecture documentation
2. Explore the package structure
3. Study the agentic AI implementation
4. Review the privacy-first patterns

For questions or educational discussions, please open an issue.

---

## Author

**Martin Demel**

- Created: September 2025
- Platform: iOS 26+
- Focus: Privacy-first AI wellness coaching

---

## License

### Educational & Non-Commercial Use Only

Copyright © 2025 Martin Demel. All Rights Reserved.

This project is made public for **educational and reference purposes only**. 

#### Permitted
- ✅ Viewing and studying the source code
- ✅ Learning from the architecture and patterns
- ✅ Referencing for educational purposes
- ✅ Personal, non-commercial experimentation

#### Not Permitted
- ❌ Commercial use of any kind
- ❌ Redistribution or sublicensing
- ❌ Creating derivative works for commercial purposes
- ❌ Using in production applications
- ❌ Selling or monetizing this code

For any other use, explicit written permission from the author is required.

---

## Acknowledgments

- Apple Foundation Models team for on-device AI capabilities
- OpenAI for GPT-5 API (optional cloud enhancement)
- The iOS developer community for inspiration and patterns

---

<p align="center">
  <strong>Built with ❤️ for privacy-conscious wellness</strong>
</p>

<p align="center">
  <em>Pulsum: Your wellbeing, on your device, under your control.</em>
</p>
