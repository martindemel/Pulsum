# Pulsum Architecture & Scaffolding Blueprint

## Module Responsibilities & Dependency Flow

- `PulsumUI`
  - Owns SwiftUI screens (MainView, CoachView, PulseView, SettingsView, SafetyCardView) and composable UI components (Liquid Glass chrome, JournalRecorder UI).
  - Depends on `PulsumAgents` (AgentOrchestrator interface), `PulsumServices` (view-model service facades), and `PulsumData` for observable models.
  - Provides preview/test fixtures via conditional compilation.

- `PulsumAgents`
  - Hosts AgentOrchestrator plus agent tool implementations (DataAgent, SentimentAgent, CoachAgent, SafetyAgent, CheerAgent).
  - Depends on `PulsumServices` (HealthKitService, SpeechService, LLMGateway), `PulsumData` (repositories, Core Data models), and `PulsumML` (BaselineMath, StateEstimator, RecRanker, SafetyLocal).
  - Exposes protocol-based interfaces to decouple UI/services from concrete logic.

- `PulsumData`
  - Encapsulates Core Data entities, repositories, vector index management, JSON ingestion utilities (LibraryImporter), EvidenceScorer, persistence helpers.
  - Depends on system frameworks only (CoreData, Foundation); provides shared model definitions consumed by other modules.

- `PulsumServices`
  - Wraps HealthKit, Speech, networking, file management, and Keychain operations behind testable service abstractions.
  - Depends on `PulsumData` (for repositories) and optionally `PulsumML` (embedding runtime configuration) but avoids agent-specific logic.

- `PulsumML`
  - Packages domain ML utilities: BaselineMath, StateEstimator, RecRanker, SafetyLocal classifier, embedding adapters.
  - Lightweight dependencies on Accelerate/Metal/MLCompute as required; shared by `PulsumAgents` and `PulsumServices`.

Dependency direction is acyclic: `PulsumML` and `PulsumData` form the base, `PulsumServices` sits above them, `PulsumAgents` consumes all three, and `PulsumUI` consumes the upper layers.

## Swift Package & Target Layout

For clarity and incremental builds, each module is a local Swift package under `Packages/`. All libraries are static by default for iOS linking.

```
Packages/
  PulsumUI/
    Package.swift (library product `PulsumUI`)
    Sources/PulsumUI/
    Tests/PulsumUITests/
  PulsumAgents/
    Package.swift (library product `PulsumAgents`)
    Sources/PulsumAgents/
  PulsumData/
    Package.swift (library product `PulsumData`)
    Sources/PulsumData/
  PulsumServices/
    Package.swift (library product `PulsumServices`)
    Sources/PulsumServices/
  PulsumML/
    Package.swift (library product `PulsumML`)
    Sources/PulsumML/
```

Integration plan:
- Add each local package to the Xcode project as a Swift Package dependency (relative path) with primary product targets matching the library names above.
- The main app target `PulsumApp` will link against `PulsumUI`, `PulsumAgents`, `PulsumServices`, `PulsumData`, and `PulsumML` as required.
- Unit test targets will import specific modules (e.g., `PulsumAgentsTests` inside the package) and can be bridged into the main Xcode test targets for end-to-end coverage.

## Third-Party Dependencies

- `SplineRuntime` (via GitHub – https://github.com/spline-design/Spline-iOS): required for scene embedding in `PulsumUI`.
- Apple Foundation Models (AFM) APIs (system frameworks) – integrated via `Foundation` and `FoundationEssentials` imports, plus potential on-device Core ML model bundles for fallback embeddings.
- Potential `swift-algorithms` or `swift-collections` (Apple) for data pipelines – evaluate during implementation.
- No additional third-party networking stack; rely on `URLSession` and `Combine`.

Each local package declares only needed external dependencies to avoid circular references and keep compile times minimal.

## Capabilities & Entitlements Plan

- Enable in project: HealthKit (read), Speech Recognition, Microphone, Keychain Sharing, Background Modes (`fetch`, `processing`) if required for HealthKit delivery.
- Configure entitlements per target once packages are wired:
  - `PulsumApp.entitlements` will include HealthKit usage with read-only types (Heart Rate, HRV, sleep, steps, respiratory rate).
  - Keychain access groups limited to `ai.pulsum.shared` for secrets storage.
  - Background delivery for HealthKit anchored queries while observing Apple guidelines.
- Update Info.plist purpose strings: `NSHealthShareUsageDescription`, `NSSpeechRecognitionUsageDescription`, `NSMicrophoneUsageDescription`, etc., reflecting privacy copy from spec.

## Persistence & File Protection Strategy

- Core Data SQLite store lives at `Application Support/Pulsum.sqlite` with `NSPersistentStoreFileProtectionKey = NSFileProtectionComplete`.
- Vector index shards stored under `Application Support/VectorIndex/` with the same file protection.
- Leverage `FileManager.default.urls(for:in:)` to resolve container directories, ensuring `isExcludedFromBackupKey = true` for PHI directories.
- Migration path: establish model versioning (`Pulsum.xcdatamodeld`) with lightweight migrations where possible, fallback to custom mapping for vector metadata.
- Repository layer in `PulsumData` to provide background save contexts and fetch convenience wrappers for agents.

## Consent & Secrets Configuration

- `UserPrefs` + `ConsentState` persisted locally to capture consent version, granted/revoked timestamps.
- Cloud processing toggle stored in Core Data + `UserDefaults` mirror for fast access; default Off.
- API keys and GPT-5 credentials injected via compile-time `Secrets.plist` for development, stored securely using Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
- Cloud requests route through `LLMGateway`, validating consent and redacting PII before network transmission; SafetyAgent can veto the call.
- Privacy Manifest additions listing HealthKit reason codes, microphone, file timestamps, and networking usage.

## Project Configuration Checklist

1. Raise deployment target to iOS 26 across all targets.
2. Remove template Core Data `Item` usage from app target to avoid conflicts with new entities.
3. Create shared configuration `.xcconfig` files (Debug/Release) to centralize bundle identifiers, API endpoints, feature flags.
4. Ensure build settings enable Swift concurrency checks and strict warnings.
5. Establish scheme structure: `Pulsum` (app), `Pulsum – AgentsTests`, `Pulsum – UITests`, etc., once packages provide test bundles.
