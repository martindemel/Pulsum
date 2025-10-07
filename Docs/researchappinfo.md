# Pulsum - Research Application Summary
**AI-Powered Wellbeing Coach for iOS 26**  
**Status**: Milestones 0-3 Complete (Agent System Ready) | Milestone 4 In Progress (UI Build)

---

## What It Does

**Pulsum** is an intelligent health companion that analyzes your physiological signals, sleep patterns, stress levels, and daily habits to provide personalized, science-backed wellness recommendations. Think of it as a **personal wellness coach powered by Apple Intelligence** that lives entirely on your device.

### Core Features

1. **Voice Journaling** - Capture how you feel with 30-second voice check-ins (on-device speech recognition, no audio stored)
2. **Health Analytics** - Automatically tracks HRV, heart rate, sleep quality, respiratory rate, and activity from HealthKit
3. **AI Recommendations** - Machine learning suggests personalized micro-activities (breathing exercises, movement breaks, sleep routines) ranked by your current state
4. **On-Topic Coaching Chat** - Ask wellness questions and get contextual advice grounded in your actual health data
5. **Safety Monitoring** - Built-in crisis detection with immediate resources (911 for emergencies)
6. **Privacy-First** - All personal health data stays on your device with military-grade encryption

---

## Architecture Overview

### Technology Stack

**Platform**: iOS 26+ (cutting-edge Apple Intelligence integration)  
**AI Engine**: Apple Foundation Models (on-device LLMs) + optional GPT-5 cloud (with consent)  
**Frameworks**: SwiftUI, FoundationModels, HealthKit, Speech, Core ML, SplineRuntime  
**Language**: Swift 6.2 with strict concurrency  
**Design**: Liquid Glass (iOS 26 material system)

### System Architecture (Layered)

```
┌─────────────────────────────────────────────────────┐
│ UI Layer (Milestone 4)                              │
│ SwiftUI + Liquid Glass + SplineRuntime              │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│ Agent System (Milestone 3 ✅)                       │
│ AgentOrchestrator (Manager Pattern)                 │
│  ├─ DataAgent: Health analytics + ML                │
│  ├─ SentimentAgent: Journal processing              │
│  ├─ CoachAgent: Recommendations + chat              │
│  ├─ SafetyAgent: Crisis detection                   │
│  └─ CheerAgent: Positive reinforcement              │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│ Services Layer (Milestone 2 ✅)                     │
│ HealthKit • Speech • LLM Gateway • Keychain         │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│ ML & Data Layer (Milestone 2 ✅)                    │
│ • StateEstimator (wellbeing scoring)                │
│ • RecRanker (recommendation ranking)                │
│ • VectorIndex (semantic search)                     │
│ • Core Data (9 entities, encrypted)                 │
└─────────────────────────────────────────────────────┘
```

### How It Works (User Journey)

**Daily Flow**:
1. **Morning Check-In** → User records voice journal ("I'm feeling tired today") → On-device sentiment analysis → Safety check → Stored encrypted
2. **Health Processing** → HealthKit delivers overnight HRV, heart rate, sleep data → Background processing computes baselines, z-scores → StateEstimator calculates wellbeing score
3. **Personalized Recommendations** → Vector search finds relevant activities → ML ranking (RecRanker) scores based on current state + evidence strength + user history → Top 3 displayed with intelligent caution messages
4. **Coaching Chat** → User asks "Why am I so tired?" → Safety check → Context assembly (current z-scores, recent trends) → Foundation Models or GPT-5 generates grounded response → "Low HRV + high sleep debt today; try a 20-min power nap"
5. **Completion Tracking** → User finishes recommendation → CheerAgent celebrates → Event logged for ML learning

---

## Key Innovations

### 1. Foundation Models Integration (Apple Intelligence)
- **Sentiment Analysis**: Uses @Generable structs for structured emotional assessment
- **Safety Classification**: AI-powered crisis detection with reasoning
- **Intelligent Coaching**: Contextual advice grounded in health signals
- **Smart Caution Messages**: Assesses activity risk based on current wellbeing state

### 2. Machine Learning Pipeline
- **StateEstimator**: Online ridge regression learns your wellbeing patterns
- **RecRanker**: Pairwise logistic model ranks recommendations (no rules)
- **Baseline Computation**: Robust statistics (Median/MAD) handle sparse/noisy data
- **Personalized Sleep**: Adapts to your actual need (7.5h ± 0.75h)

### 3. Privacy Architecture
- **On-Device First**: All PHI processed locally with NSFileProtectionComplete
- **PII Redaction**: Emails, phones, SSNs scrubbed before any storage
- **Consent-Aware Routing**: Cloud (GPT-5) only with explicit permission; defaults to on-device Foundation Models
- **Minimized Context**: Cloud calls receive only aggregated z-scores, never raw journals or health data
- **No Audio Storage**: Voice journals → transcript only → encrypted

### 4. Health Science
- **6 HealthKit Metrics**: HRV (SDNN), nocturnal HR, resting HR, sleep stages, respiratory rate, steps
- **Sparse Data Handling**: 3-tier fallback strategies (sleep → sedentary → previous day)
- **Evidence-Based Content**: 500+ micro-activities ranked by research quality (Strong: .gov/.edu/pubmed)
- **Validated Scales**: Stress (SISQ), Energy (NRS), Sleep Quality (SQS)

---

## Technical Highlights

### Advanced Features

**Smart Fallbacks**: Foundation Models → Improved Legacy → Core ML (3-tier cascade ensures functionality regardless of Apple Intelligence availability)

**Actor Isolation**: Health processing runs in isolated `actor DataAgent` (1,017 lines of sophisticated analytics) while UI agents use `@MainActor` for safe binding

**Dual-Provider Safety**: Primary Foundation Models classification + fallback keyword/embedding classifier ensures crisis detection even offline

**Intelligent Caution Assessment**: Foundation Models evaluates activity risk contextually (e.g., "hard yoga" gets different caution if user has low energy vs high energy)

**Vector Semantic Search**: Memory-mapped shards with L2 distance powered by Accelerate framework (384-d embeddings from NLContextualEmbedding)

**Online Learning**: StateEstimator and RecRanker adapt to user patterns over time with bounded learning rates

---

## Privacy & Security

**Data Protection**:
- All PHI encrypted at rest (NSFileProtectionComplete)
- Excluded from iCloud backup
- On-device processing default
- Keychain for API secrets

**Compliance**:
- HIPAA-aligned data handling
- App Store 5.1.3 privacy rules
- Privacy Manifest (Required-Reason APIs declared)
- No third-party analytics or tracking

**User Control**:
- Cloud processing: Default OFF, explicit opt-in
- One-tap revocation in Settings
- Transparent about what leaves device (minimized context only)
- Apple Intelligence status displayed

---

## Current Status (September 30, 2025)

### ✅ Complete (Production-Ready)
- **Milestone 0**: Repository audit
- **Milestone 1**: Architecture & scaffolding (5 packages)
- **Milestone 2**: Data & services (Core Data, HealthKit, Vector Index, LibraryImporter)
- **Milestone 3**: Foundation Models agent system (6 agents, 4 FM providers, Swift 6 compliant)
  - 4,865+ lines of production code
  - Zero placeholders
  - All tests passing
  - Zero Swift 6 warnings

### ⏳ In Progress
- **Milestone 4**: UI & Experience (SwiftUI + Liquid Glass + SplineRuntime)

### 📋 Planned
- **Milestone 5**: Privacy compliance finalization (Privacy Manifests, consent UX)
- **Milestone 6**: QA, testing, App Store prep

**Estimated Launch**: 4-6 weeks from now

---

## Technical Specifications

**Deployment Target**: iOS 26+ (requires Apple Intelligence)  
**Code Size**: ~4,865 lines (backend) + ~2,000 lines (UI target)  
**Packages**: 5 Swift Packages (Agents, ML, Services, Data, UI)  
**Entities**: 9 Core Data entities  
**ML Models**: 2 Core ML models (sentiment, embeddings) + Foundation Models  
**Vector Index**: 384-dimensional contextual embeddings  
**HealthKit Types**: 6 (HRV, HR, restingHR, RR, steps, sleepAnalysis)  
**Languages**: English (expandable to 15+ via Foundation Models)  
**Concurrency**: Swift 6 strict mode, zero warnings  
**Testing**: Comprehensive async test suites across all packages

---

## Competitive Differentiation

1. **True Apple Intelligence Integration** - Not wrappers, but proper FoundationModels framework usage with @Generable
2. **Sophisticated Health Analytics** - 1,017-line DataAgent with sparse data handling, personalized baselines
3. **ML-Driven (No Rules)** - StateEstimator + RecRanker learn user patterns, no if/else recommendation logic
4. **Privacy-First Architecture** - On-device default, consent-aware cloud, encrypted PHI
5. **Contextual AI** - Recommendations and coaching grounded in actual z-scores, not generic advice
6. **Beautiful Design** - Liquid Glass + SplineRuntime 3D scene + modern iOS 26 materials

---

## Target Audience

**Primary**: Health-conscious iOS users with Apple Intelligence-enabled devices (iPhone 15 Pro+, future devices)  
**Secondary**: Anyone wanting personalized wellness insights without cloud privacy concerns  
**Not for**: Clinical diagnosis, medical treatment, emergency mental health (provides 911 resources instead)

---

## Business Model (Future)

**V1.0**: Free with on-device AI  
**Potential**: Premium tier with GPT-5 cloud coaching (requires consent, privacy-preserving)  
**Revenue**: Subscription for advanced AI features  
**Data**: Never sold, never shared, never used for training

---

## Development Team Context

**Built By**: Principal iOS architect with staff-level Swift expertise  
**Architecture**: Foundation Models-first, privacy-first, agent-based  
**Quality Bar**: Production-ready, App Store submission quality, zero technical debt  
**Philosophy**: Sophisticated AI that respects user privacy and agency

---

**Document Purpose**: Quick research reference for stakeholders, investors, app reviewers, or technical documentation  
**Last Updated**: September 30, 2025  
**Status**: Milestone 3 complete (backend ready), Milestone 4 in progress (UI build)


