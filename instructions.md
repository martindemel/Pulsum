Pulsum — Final Production Build Spec (iOS 26, Liquid Glass, Agent‑First)

ROLE
You are a principal iOS architect and staff‑level Swift engineer. Build a production, App‑Store‑ready version of Pulsum—no placeholders, no mock UIs, no fake backends. Every feature must function end‑to‑end.
Initially, analyze the entire codebase, including all folders and subfolders, as well as all files within these folders, to understand what is already available from the Xcode project. Do not skip lines; read it all. I have also added instructions.md that have these instructions and you can read it whenever required to ensure you adhere 100%. Create a todolist.md file where you will track all the details and activities as you split this work into several milestones. That way, if required, I can use the next chat window to continue from where you left off. Ensure you always update the todolist.md file when completing such work or task part.

⸻

NON‑NEGOTIABLE CONSTRAINTS
• Privacy: No personal health information (HealthKit data, derived features, journal text/embeddings) is stored in iCloud/CloudKit. PHI stays on‑device (NSFileProtectionComplete) + Keychain for secrets. For the API key, use a single injected key in code for testing purposes for now.
• Models & routing: Primary phrasing model = GPT‑5 (cloud) only with explicit in‑app consent; on‑device Apple Foundation Models (AFM) for sensitive text and embeddings; AFM is the offline fallback if consent is off or network is unavailable.
• No rule engines: Agent decisions (recommendation ranking, chat policy) are ML‑driven; the only deterministic math is statistical baselining (z‑scores, EWMA).
• Liquid Glass: Use iOS 26 material system and components referenced in /ios support documents/.
• Main visual: Load a Spline scene from the cloud; local fallback allowed.
• Files present:
– /ios support documents/ – Liquid Glass + AFM notes.
– /json database/ – podcastrecommendations*.json (micro‑moment source).
– Optional local Spline asset mainanimation.splineswift at project root (fallback only).

⸻

XCODE PROJECT SETUP (do immediately)
• Deployment Target: iOS 26 (REQUIRED for Foundation Models framework).
• Capabilities: HealthKit (read), Speech Recognition, Microphone, Keychain only. Do NOT enable Keychain Sharing; Background Modes only if HealthKit delivery explicitly needed.
• Swift Packages: SplineRuntime, FoundationModels framework.
• Core Data: Local only (CloudKit sync OFF).
• File protection: Ensure on‑device stores use NSFileProtectionComplete.
• Purpose strings: Health, Microphone/Speech.
• App Privacy labels: Local‑only storage for health/journal.

⸻

TECH STACK (fixed)
• Language/Frameworks: Swift 5.10+, SwiftUI, FoundationModels, Observation, Combine (where helpful), Metal as needed by Liquid Glass APIs, SplineRuntime for the main visual.
• Persistence: Core Data (SQLite) via NSPersistentContainer at Application Support/Pulsum.sqlite; no CloudKit.
• Vector store: In‑process L2 index (memory‑mapped shards) at Application Support/VectorIndex/.
– Text Generation: Foundation Models SystemLanguageModel with guided generation (@Generable structs)
– Embeddings: NLContextualEmbedding for vectors; Foundation Models for text understanding; Core ML 384‑d fallback. Never send journal text to cloud for embeddings.

⸻

INFORMATION ARCHITECTURE (packages/targets)

PulsumApp (iOS 26 target)

Packages/
PulsumUI/
– MainView (root screen; Spline visual; header + bottom controls)
– CoachView (recommendation cards + always‑visible chat input)
– PulseView (journaling: slide‑to‑record + sliders)
– SettingsView (privacy/consent)
– SafetyCardView (US 911 emergency)
– JournalRecorder (voice; requiresOnDeviceRecognition when supported)

PulsumAgents/
– AgentOrchestrator (manager pattern; single user‑facing agent, other agents as tools)
– DataAgent (HealthKit ingest, stats, features)
– SentimentAgent (STT→transcript; AFM sentiment + on‑device embedding; PII redaction)
– CoachAgent (RAG/CAG over library; pairwise ranker; on‑topic chat)
– SafetyAgent (local safety classifier + crisis routing)
– CheerAgent (positive reinforcement/haptics)

PulsumData/
– Core Data entities: JournalEntry, DailyMetrics, Baseline, FeatureVector, MicroMoment, LibraryIngest, UserPrefs, ConsentState, RecommendationEvent
– VectorIndex (binary shards)
– LibraryImporter (JSON → normalized items)
– EvidenceScorer (domain policy)

PulsumServices/
– HealthKitService (anchors, observers)
– SpeechService (on‑device when available)
– LLMGateway (cloud phrasing; minimized context; consent gate)

PulsumML/
– BaselineMath (median/MAD z‑scores; EWMA λ=0.2)
– StateEstimator (online ridge regression)
– RecRanker (pairwise logistic scorer)
– SafetyLocal (keywords + small on‑device classifier)

Gate 5 data integrity (current state)
• Vector index stack is actorized: `VectorIndexProviding` is `Sendable`, `VectorIndexManager` is an actor with DI init + `shared`, and shard cache creation happens inside a single critical section.
• File handles in the vector index are wrapped in `withHandle` so they close exactly once; close errors propagate as `VectorIndexError.ioFailure`.
• `LibraryImporter.ingestIfNeeded()` discovers URLs, loads/decodes JSON off the main actor via detached task, performs Core Data upserts on a background context, indexes via injected `VectorIndexProviding` outside Core Data, and persists checksum only after successful indexing.
• Canonical `Pulsum.xcdatamodeld` lives at `Packages/PulsumData/Sources/PulsumData/Resources/` and loads via `Bundle.pulsumDataResources`; dataset deduped to `podcastrecommendations 2.json` with CI hash guard/backup ban in `scripts/ci/integrity.sh` and `scripts/ci/test-harness.sh`.

⸻

UI & NAVIGATION (fixed)

Main (default root view)
• Header: top‑left Pulse button (tap → open PulseView); top‑right avatar (tap → SettingsView).
• Center: Spline scene (cloud first, local fallback). Load using SplineRuntime:
– Cloud: https://build.spline.design/ke82QL0jX3kJzGuGErDD/scene.splineswift
– Fallback: bundled mainanimation.splineswift if offline.
Use this embed for now:

import SplineRuntime
import SwiftUI

struct ContentView: View {
    var body: some View {
        // fetching from cloud
        let url = URL(string: "https://build.spline.design/ke82QL0jX3kJzGuGErDD/scene.splineswift")!

        // fetching from local
        // let url = Bundle.main.url(forResource: "scene", withExtension: "splineswift")!

        SplineView(sceneFileURL: url).ignoresSafeArea(.all)
    }
}

• Bottom left: segmented control Main | Coach (start on Main).
• Bottom right: AI button. Tap → switch to Coach and focus the chat input.
• Style: apply Liquid Glass elements (from support docs) to header bar, bottom control surfaces, AI button, sheets.

UI ARCHITECTURE (Milestone 4 Implementation)
• Create @MainActor view models binding to AgentOrchestrator with async/await patterns
• Display loading states during async Foundation Models operations (sentiment, safety, coaching)
• Show Foundation Models availability status in SettingsView (orchestrator.foundationModelsStatus)
• Implement fallback messaging when Foundation Models unavailable
• Connect UI ONLY to AgentOrchestrator (single orchestrator, not individual agents)
• Handle async/await errors gracefully (guardrailViolation, refusal, timeouts)

Coach
• Content: recommendation cards (Top Pick expanded + up to 2 collapsed that expand on tap).
• Sticky chat input at bottom; keyboard appears on first tap.
• Completing a card logs an event and triggers CheerAgent (brief supportive toast + haptic).

Pulse (formerly check‑in)
• Opened by tapping the Pulse button on Main.
• Contains a slide‑to‑record voice journal (max 30 s) with visible recording indicator + countdown; stop on background/interrupt; never store audio—transcript only.
• After recording (or skip), show three sliders (1–7): Stress (SISQ wording), Energy (NRS wording), Sleep Quality (SQS wording). Auto‑dismiss ≤3 s after submit.

Settings
• Privacy/consent toggles:
– Cloud Processing (default Off; banner explains what leaves device; one‑tap revoke).
• Foundation Models Status Display:
– Show orchestrator.foundationModelsStatus
– Messages: "Apple Intelligence is ready" / "Preparing AI model..." / "Enable Apple Intelligence in Settings" / etc.
– Provide guidance link if Apple Intelligence needs enabling
• Safety resources link; Privacy Policy link.

⸻

HEALTH & STATS (science‑backed)

Ingestion (HealthKit): Use HKAnchoredObjectQuery + HKObserverQuery; persist an HKQueryAnchor per type.

Daily features & baselines
• HRV (SDNN, overnight): query heartRateVariabilitySDNN overlapping sleep stages (asleepCore/deep/REM). Nightly summary = median SDNN across available samples. Sparse‑friendly: accept ≥1 sample in sleep window; if none, use most restful 1–2 h sedentary window; if still none, carry forward yesterday’s value with imputed=true.
• Nocturnal HR: from heartRate in sleep window; nightly feature = 10th percentile (or lowest 5‑min rolling mean).
• Resting Heart Rate: use HealthKit restingHeartRate; if unavailable, derive from ≥30 min low‑activity daytime windows.
• Sleep sufficiency & debt: from sleepAnalysis (stages). Compute TST; rolling 7‑day sleep debt vs personalized need (start 7.5 h; adapt to long‑term mean with cap ±45 min).
• Steps: daily total from stepCount (weight 0 if Motion not authorized).
• Respiratory rate (optional, low weight): sleep RR nightly mean when present.

Baselines & smoothing
• Rolling window 21–30 days; robust z‑scores via median/MAD; EWMA λ=0.2.
• Quality gates: Sleep features require ≥3 h valid sleep else mark lowConfidence and widen estimator variance; HRV sparse rule as above; Steps require Motion auth.

Internal score (hidden)
• WellbeingScore = output of StateEstimator (online ridge regression with SGD, α=0.05, λ=1e‑3, weight caps ±2.0) over features:
– z‑scores: HRV_SDNN, NocturnalHR, RestingHR, SleepDebt, Steps, RR (low weight)
– subjective: Stress, Energy, SleepQuality
– journal: on‑device sentiment/arousal and embedding summary
• Initialize weights: {HRV:-0.6, NocturnalHR:+0.5, RestingHR:+0.4, SleepDebt:+0.5, Steps:-0.2, RR:+0.1, Stress:+0.6, Energy:-0.6, SleepQuality:+0.4}.
• Update nightly with bounded LR; 7–10‑day warm‑up flag; no population priors. Persist per‑feature contributions for internal debugging (not user‑visible).

⸻

AGENT SYSTEM (manager pattern; deterministic interfaces)

AgentOrchestrator (single user‑facing agent; other agents exposed as tools)
• Loop per request: Observe → Decide → Act → Update.
• Tools: DataAgent, SentimentAgent, CoachAgent, SafetyAgent, CheerAgent.
• @MainActor isolation for UI compatibility
• Async/await interfaces throughout
• Foundation Models availability tracking via foundationModelsStatus property
• UI Layer: Connect ONLY to AgentOrchestrator, never directly to individual agents

DataAgent
• Runs HK ingestion; computes baselines + z‑scores; emits daily FeatureVector.
• Handles anchors, backfills, idempotent reducers.

SentimentAgent
• STT via Apple Speech: 
  - iOS 26+: Use SpeechAnalyzer/SpeechTranscriber APIs (official on-device STT replacement, faster, long-form capable)
  - Pre-iOS 26: Fallback to SFSpeechRecognizer with requiresOnDeviceRecognition = true
  - Always show visible recording indicator + countdown
• Foundation Models SystemLanguageModel for sentiment analysis with guided generation (@Generable); fallback to Core ML when AFM unavailable; contextual embeddings for vectors; redact PII for any cloud call (only minimized context allowed with consent). Audio is never stored; transcripts stored locally only.

CoachAgent (recommendations + on‑topic chat)
• Library ingestion: On first run, parse /json database/podcastrecommendations*.json. For each episode, normalize each recommendations[] item into a MicroMoment with fields {id, title, short, detail, tags[], estimatedTimeSec, difficulty, category, sourceURL, cooldownSec?}.
• Evidence scoring: Strong = (pubmed|nih.gov|.gov$|.edu$|who.int|cochrane.org); Medium = (nature.com|sciencedirect.com|mayoclinic.org|harvard.edu); Weak = other. Prefer Strong/Medium for Top Pick; exclude affiliate/advertorial.
• Indexing: Embed titles/details with contextual embeddings; build/update local vector index.
• Ranking (no rules): Retrieve candidates by vector similarity + context filters (cooldowns, novelty). Rank Top Pick + 2 alternates via pairwise logistic model using features: WellbeingScore, evidence strength, novelty, cooldown, user past acceptances, time‑cost fit, current z‑scores. Online updates with bounded LR.
• Chat: Always on‑topic (relevance guardrail with Two-Wall system). Answers must ground in current FeatureVector, sliders, and recent completions. Use GPT‑5 only for phrasing when Cloud Processing is On; otherwise generate with Foundation Models SystemLanguageModel. ≤2 sentences; no medical claims. Cards show a source badge.
  - Two-Wall Guardrails: Wall-1 (on-device): Safety → TopicGate (0.59 threshold) → Coverage (0.68 threshold, median-based); Wall-2 (cloud): GPT-5 schema validation with grounding score ≥0.5
  - Deterministic Intent Routing (4-step pipeline eliminates "wobble"):
    1) Start with Wall-1 topic classification (sleep, stress, energy, hrv, mood, movement, mindfulness, goals, or nil for greetings)
    2) Phrase override: Direct substring matching (e.g., "rmssd" → hrv, "insomnia" → sleep)
    3) Candidate moments override: Retrieve top-2 moments, infer dominant topic via keyword scoring
    4) Data-dominant fallback: Choose signal with highest |z-score| if no topic matched
  - Final topSignal → context mapping ensures consistent topic→signal pairing for GPT-5
  - Coverage robustness: Require ≥3 matches, median similarity ≥0.25, using 1/(1+d) transformation
  - Structured outputs: CoachReplyPayload {coachReply, nextAction?} wired end-to-end (cloud→gateway→agent→orchestrator)
• Caution messages: Use Foundation Models to intelligently assess activity risk based on current wellbeing state.
• Output schema: {title, body, caution?, sourceBadge}.

SafetyAgent
• Foundation Models SystemLanguageModel for safety classification with guided generation; fallback to local keyword/regex + embedding classifier. On high‑risk:
– Block any cloud call.
– Show CrisisCard with US: 911.
– Never send risky content to cloud.

⸻

CONSENT, TRANSPARENCY & COMPLIANCE
Recording transparency: While mic is active, show always‑visible indicator + countdown; stop on background/interrupt.
Cloud consent banner (exact copy):
"Pulsum can optionally use GPT-5 to phrase brief coaching text. If you allow cloud processing, Pulsum sends only minimized context (no journals, no raw health data, no identifiers). PII is redacted. You can turn this off anytime in Settings ▸ Cloud Processing."
Revocation: Settings contains Cloud Processing toggle, a secure field to paste/save the GPT-5 key, and a “Test Connection” button so users can validate connectivity; when the toggle is Off, all requests remain on-device regardless of key state.

Privacy Manifest (iOS 26 - MANDATORY for App Store)
• Create PrivacyInfo.xcprivacy for main app and all packages (PulsumData, PulsumServices, PulsumML, PulsumAgents)
• Declare Required-Reason APIs:
  - File timestamp access (reason code: C617.1 - access info about files inside app container)
  - Disk space queries (reason code: E174.1 - display disk space information to user)
  - User defaults access (reason code: CA92.1 - access info previously stored by app)
• Aggregate third-party SDK manifests (SplineRuntime)
• Required for App Store submission - app will be rejected without proper manifests
• No ads/marketing using HealthKit data.

QA SMOKE — FIRST RUN & JOURNALING
1. Run `scripts/ci/scan-secrets.sh` to ensure no credentials are bundled before installing.
2. Install the app on a clean simulator/device so no permissions are cached.
3. Launch Pulsum → expect sequential prompts for speech recognition permission (entitlement temporarily removed from signing) and microphone access; decline/accept paths must surface actionable errors.
4. Tap the Pulse button, start a 5–10s recording, cancel midway, and verify haptics fire, the waveform stays smooth (no frame drops), and storage isn’t blocked by the “Storage Not Secured” overlay.
5. Complete a journal (begin → stream → finish) and confirm transcripts stream live, the “Saved to Journal” toast appears then dismisses, the transcript remains until you tap Clear, and wellbeing/coach cards refresh automatically (watch `.pulsumScoresUpdated` logs).
6. Use the `Retry` button on the startup overlay to re-check storage security after toggling iCloud backup or sandbox settings.

HOW TO RUN PRIVACY REPORT & SECRET SCANS
• Secret scan (repo + optional .app/.ipa): `scripts/ci/scan-secrets.sh [path/to/Pulsum.app or Pulsum.ipa]`
• Privacy manifests + optional Xcode Privacy Report: `scripts/ci/check-privacy-manifests.sh` (set `RUN_PRIVACY_REPORT=1` to run `xcrun privacyreport generate --project Pulsum.xcodeproj --scheme Pulsum`). **Note:** `privacyreport` ships with Xcode 16+; install the latest Xcode command line tools if the binary is missing, otherwise leave `RUN_PRIVACY_REPORT` unset and run the report manually once the tool is available.
• Release build gate (TSan off, `OTHER_SWIFT_FLAGS` applied): `scripts/ci/build-release.sh` (disables code signing so CI can run the Release build without provisioning—remove the `CODE_SIGNING_*` overrides when archiving for App Store).

RUN THE TEST HARNESS (GATE 1)
• Use `scripts/ci/test-harness.sh` to run the end-to-end Gate 1 sweep locally—it now **first runs** `xcodebuild -scheme Pulsum -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build` so SwiftUI/compiler errors surface before tests, then chains the secret scan, privacy manifest check, `xcodebuild test -scheme Pulsum -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0'` (auto-falling back to iPhone 15), and `swift test --package-path Packages/Pulsum{Services,Data,ML} --filter 'Gate0_|Gate1_'`.
• Logs land under `/tmp` as `pulsum_xcode_tests.log`, `pulsum_services_gate.log`, etc., so you can inspect failures quickly or attach them to PRs.
• GitHub Actions (`.github/workflows/test-harness.yml`) invokes the same script on `macos-14` runners with Xcode 16 selected.

UITEST ENVIRONMENT FLAGS
| Flag | Purpose | Notes |
| --- | --- | --- |
| `UITEST_USE_STUB_LLM=1` | Forces `LLMGateway` to use an on-device stub client that produces deterministic, grounded replies (no network/API key required). | Keeps consent logic intact; still sanitizes outputs. |
| `UITEST_FAKE_SPEECH=1` | Routes `SpeechService` to a deterministic fake backend that streams known transcript segments and audio levels. | Avoids microphone/audio-engine access during automation. |
| `UITEST_AUTOGRANT=1` | When paired with the fake speech backend, skips mic/speech permission prompts for fast simulator runs. | Leave unset when manually verifying the real permission UX. |
| `PULSUM_HEALTHKIT_STATUS_OVERRIDE` | Comma-separated list of `identifier=state` pairs (`granted`, `denied`, `notDetermined`) to simulate per-type authorization in DEBUG/UITest builds. | Example: `HKCategoryTypeIdentifierSleepAnalysis=denied,HKQuantityTypeIdentifierStepCount=granted`. |
| `PULSUM_HEALTHKIT_REQUEST_BEHAVIOR` | Controls how `requestHealthKitAuthorization()` behaves in UITests (`grantAll`, unset for normal behavior). | Set to `grantAll` to flip all required types to granted after tapping “Request Health Access”. |
| `UITEST_CAPTURE_URLS=1` | Records every Settings deep link (Apple Intelligence CTA) into `UserDefaults(suiteName: "ai.pulsum.uiautomation")` under `LastOpenedURL`. | Lets UI tests assert fallback URLs without launching Safari. |
| `UITEST_FORCE_SETTINGS_FALLBACK=1` | Skips `UIApplication.openSettingsURLString` and forces Settings CTA to open the Apple Intelligence support article while logging it. | Use with `UITEST_CAPTURE_URLS` to exercise fallback behavior deterministically. |

RESOLVING DUPLICATE PRIVACYINFO.XCPRIVACY WARNINGS
1. Keep a single canonical manifest at `Pulsum/PrivacyInfo.xcprivacy`. Do **not** add package manifests or workspace copies to the app target.
2. In `Pulsum.xcodeproj/project.pbxproj`, the Pulsum target’s “Copy Bundle Resources” list must show exactly **one** `PrivacyInfo.xcprivacy in Resources`. Remove any duplicate `PBXBuildFile` entries if present.
3. Run `scripts/ci/check-privacy-manifests.sh`—it now fails if `project.pbxproj` tries to copy more than one manifest or if any plist is missing. Re-run `xcodebuild -scheme Pulsum -configuration Release build` to confirm the “Multiple commands produce … PrivacyInfo.xcprivacy” warning is gone.

GATE-0 TEST SUBSET
Run these focused tests and gates before shipping any security/build fixes:
```
swift test --package-path Packages/PulsumServices --filter Gate0_
swift test --package-path Packages/PulsumData --filter Gate0_
swift test --package-path Packages/PulsumML --filter Gate0_
xcodebuild -scheme Pulsum -configuration Release -destination 'platform=iOS Simulator,name=iPhone 15' build -derivedDataPath Build
scripts/ci/scan-secrets.sh Build/Products/Release-iphonesimulator/Pulsum.app
scripts/ci/check-privacy-manifests.sh
RUN_PRIVACY_REPORT=1 scripts/ci/check-privacy-manifests.sh || true   # optional if privacyreport is installed
```

FOUNDATION MODELS REQUIREMENTS (Milestone 3 - IMPLEMENTED ✅)
• Apple Intelligence must be enabled on device for Foundation Models features
• All Foundation Models operations use async/await with proper error handling
• Use @Generable structs for structured output (sentiment analysis, safety classification)
• LanguageModelSession for all text generation with appropriate Instructions
• Availability checking mandatory before Foundation Models operations - graceful fallbacks required
• Built-in guardrails handle sensitive content - catch LanguageModelSession.GenerationError appropriately
• Never include PHI in Foundation Models prompts - use minimized context only
• Temperature settings: 0.1 for classification tasks, 0.6 for generation, 0.0 for safety assessment
• Preserve UI guardrails: SplineRuntime on Main and Liquid Glass for chrome/AI button remain unchanged
• Scope hygiene: No notifications, tests/CI, crash/telemetry, export/delete UI; single injected API key for GPT‑5

FOUNDATION MODELS INTEGRATION POINTS (Milestone 3 Implementation Reference)
• Sentiment Analysis: FoundationModelsSentimentProvider with @Generable SentimentAnalysis
• Safety Classification: FoundationModelsSafetyProvider with @Generable SafetyAssessment  
• Coach Generation: FoundationModelsCoachGenerator with LanguageModelSession
• Intelligent Caution: CoachAgent.generateFoundationModelsCaution() for activity risk assessment
• Provider Cascades: Foundation Models → Improved Legacy → Core ML fallbacks throughout
• Availability Utility: FoundationModelsAvailability.checkAvailability() for status checking
• All implementations in Packages/PulsumML/Sources/PulsumML/Sentiment|Safety, Packages/PulsumServices/Sources/PulsumServices

⸻

DATA MODELS (Core Data)
• JournalEntry(id, date, transcript, sentiment, embeddedVectorURL, sensitiveFlags)
• DailyMetrics(date, HRV_median, noctHR_p10, restingHR, TST, sleepDebt, RR_mean, steps, flags)
• Baseline(metric, windowDays, median, mad, ewma, updatedAt)
• FeatureVector(date, z_hrv, z_nocthr, z_resthr, z_sleepDebt, z_rr, z_steps, subj_stress, subj_energy, subj_sleepQuality, sentiment, imputedFlags)
• MicroMoment(id, title, short, detail, tags[], estimatedTimeSec, difficulty, category, sourceURL, evidenceBadge, cooldownSec)
• RecommendationEvent(momentId, date, accepted, completedAt)
• UserPrefs(consentCloud)
• ConsentState(version, grantedAt, revokedAt)

⸻

ROUTING & MINIMIZED CONTEXT (cloud)
• Cloud requests include only: {userToneHints, topSignal, topMomentId?, brief rationale, high‑level z‑score summary}.
• Never include transcripts or raw health series.

⸻

BUILD & DELIVERY (sequence)
✅ MILESTONES 0-3 COMPLETE (Foundation complete, ready for UI)
0. Scan existing repo ✅ DONE
1. Scaffold packages/targets; entitlements ✅ DONE
2. Core Data stack + entities; file protection Complete ✅ DONE
3. HealthKitService (anchors/observers) + reducers → DailyMetrics ✅ DONE
4. BaselineMath + FeatureVector emission; StateEstimator ✅ DONE
5. Foundation Models integration: async agents with SystemLanguageModel ✅ DONE
6. LibraryImporter → parse JSON; EvidenceScorer; VectorIndex ✅ DONE
7. RecRanker + CoachAgent; Foundation Models generation; LLMGateway ✅ DONE
8. Swift 6 concurrency hardening ✅ DONE

⏳ MILESTONE 4 (NEXT) - UI & EXPERIENCE BUILD
8. Create @MainActor view models binding to AgentOrchestrator
9. MainView with SplineRuntime (cloud URL + local fallback)
10. PulseView (slide‑to‑record + sliders); CoachView (cards + chat); SettingsView (consent + Foundation Models status); SafetyCard
11. Display loading states for async operations; handle Foundation Models errors
12. Implement fallback messaging when Foundation Models unavailable
13. Apply Liquid Glass design language; accessibility/localization

⏳ MILESTONE 5 - SAFETY, CONSENT, PRIVACY COMPLIANCE
14. Wire consent UX; create Privacy Manifests (PrivacyInfo.xcprivacy) for app + all packages
15. Validate data protection end-to-end; aggregate SDK privacy manifests

⏳ MILESTONE 6 - QA, TESTING, RELEASE PREP
16. Foundation Models-specific tests; Swift 6 validation
17. Performance profiling (@MainActor responsiveness, Foundation Models latency); conditional optimizations if needed
18. Evaluate BGTaskScheduler integration (conditional on monitoring data)
19. App Store assets; TestFlight build

⸻

MILESTONE 4 UI IMPLEMENTATION GUIDE (AgentOrchestrator Integration)

View Model Pattern (Required for Milestone 4)
• All views must use @MainActor view models that bind to AgentOrchestrator
• Example pattern:
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

Foundation Models Status Display (SettingsView)
• Read orchestrator.foundationModelsStatus property
• Display current availability state
• Show user-friendly messages:
  – "Apple Intelligence is ready"
  – "Preparing AI model... This may take a few minutes"
  – "Enable Apple Intelligence in Settings to use AI features"
  – "This device doesn't support Apple Intelligence"
• Provide Settings deep link when Apple Intelligence needs enabling

Loading States (All Async Operations)
• Show ProgressView during Foundation Models operations
• Disable inputs while processing
• Examples:
  – Journal recording: "Analyzing..."
  – Safety check: "Checking content safety..."
  – Chat response: "Generating response..."
  – Recommendations: "Finding personalized suggestions..."

Error Handling (Foundation Models Operations)
• Catch LanguageModelSession.GenerationError.guardrailViolation
  → Display: "Let's keep the focus on supportive wellness actions"
• Catch LanguageModelSession.GenerationError.refusal
  → Display: "Unable to process that request. Try rephrasing."
• Generic errors → Fall back to on-device alternatives
• Never expose technical error details to users

Fallback Messaging
• When Foundation Models unavailable, show in UI:
  – "Enhanced AI features require Apple Intelligence. Using on-device intelligence."
  – Position: Below chat input or in SettingsView
  – Style: Secondary text, non-intrusive

Safety Decision Handling
• Always check JournalCaptureResponse.safety before proceeding
• If !allowCloud and classification == .crisis:
  – Show CrisisCard with copy: "If you're in the United States, call 911 right away"
  – Block all other operations
  – Provide crisis resources
• If classification == .caution:
  – Proceed with on-device only
  – Show supportive message

⸻

COPY & TONE (Coach)
• Persona: calm, supportive, matter‑of‑fact; ≤2 sentences per response.
• Avoid diagnoses/medical claims. Anchor to current context (“low HRV + high stress today; try …”).
• Cards show source badge (Strong/Medium/Weak); expand to see short source text.

⸻

WHAT TO CODE NOW (Milestone 4 - UI Implementation)
• Implement SwiftUI views with @MainActor view models binding to AgentOrchestrator
• Use the manager‑pattern AgentOrchestrator; UI connects ONLY to orchestrator, never directly to individual agents
• Display Foundation Models availability status in SettingsView using orchestrator.foundationModelsStatus
• Implement loading states for all async operations (journal, chat, recommendations)
• Handle Foundation Models errors gracefully (guardrailViolation, refusal) with user-friendly messages
• Show fallback messaging when Foundation Models unavailable
• Ensure the Liquid Glass match the provided assets; the Spline visual loads from the cloud with local fallback
• Do not deviate from data handling rules, consent, or storage constraints
• Respect SafetyDecision.allowCloud and display crisis messaging when needed

MILESTONE 3 COMPLETION STATUS
✅ AgentOrchestrator: Complete with Foundation Models integration, async API, @MainActor isolation
✅ DataAgent: Complete with sophisticated health analytics (1,017 lines), HealthKit ingestion, StateEstimator
✅ SentimentAgent: Complete with Foundation Models sentiment, PII redaction, on-device STT, vector persistence
✅ CoachAgent: Complete with RecRanker ML, vector search, Foundation Models intelligent caution, consent routing
✅ SafetyAgent: Complete with dual-provider (Foundation Models + SafetyLocal), crisis detection
✅ CheerAgent: Complete with time-aware celebration
✅ All ML algorithms: StateEstimator, RecRanker, BaselineMath fully implemented
✅ All services: HealthKit, Speech, LLMGateway, Keychain operational
✅ All data infrastructure: Core Data, VectorIndex, LibraryImporter ready
✅ Swift 6 compliance: Zero concurrency warnings, all tests passing
✅ Ready for Milestone 4 UI integration

REFERENCE (design alignment): A practical guide to building agents.

# CI Gate Harness
- Run `scripts/ci/test-harness.sh` to auto-discover every `GateN_` XCTest across `PulsumServices`, `PulsumAgents`, `PulsumML`, and `PulsumData` by parsing `swift test --list-tests`, building a combined regex, and executing the suites in parallel. Packages without Gate coverage are reported and skipped without failing CI.
- The harness also launches the shared Pulsum Xcode scheme UI tests on the first available iOS simulator (fallback `iPhone 16 Pro`) with `UITEST_FAKE_SPEECH=1` and `UITEST_AUTOGRANT=1` so DEBUG-only seams stay isolated while tests remain deterministic. Hosts lacking Xcode/simulators skip gracefully.
- `scripts/ci/integrity.sh` now invokes the harness immediately after the placeholder/secret/privacy scans, guaranteeing Gate 0/1/2 (and future Gate suites) run automatically before the Release build.
- `.github/workflows/test-harness.yml` calls the same script for every push/PR. Run the harness locally before opening a Gate PR to mirror CI results.
