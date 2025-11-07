# Pulsum vs. Demo Apps SwiftUI Architecture Review
- Date: 2025-11-02
- Repo root: Pulsum
- Commit: 1ceeac6

## Executive Summary
- Modular package layering, secure storage, and guardrail tests mirror the demos’ disciplined separation (Packages/PulsumData/Sources/PulsumData/DataStack.swift:71; Packages/PulsumServices/Tests/PulsumServicesTests/LLMGatewayTests.swift:64).
- Multiplatform target claims are undermined by UIKit-only code paths that break macOS builds (Packages/PulsumUI/Sources/PulsumUI/PulseView.swift:238 vs. Packages/PulsumUI/Package.swift:6).
- Startup orchestration relies on hard-coded factories and unstructured tasks, limiting testability and cancellation compared with FoodTruck’s scene-owned models (Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:89; demoapp/FoodTruckBuildingASwiftUIMultiplatformApp/App/App.swift:16).
- UI polish is strong but text uses fixed sizes and raw literals, falling short of Fruta’s dynamic type and localization coverage (Packages/PulsumUI/Sources/PulsumUI/PulsumDesignSystem.swift:40; demoapp/FrutaBuildingAFeatureRichAppWithSwiftUI/Shared/Recipe/RecipeList.swift:53).
- Navigation stays single-column regardless of device class, missing the adaptive split layout showcased in both samples (Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift:86; demoapp/FoodTruckBuildingASwiftUIMultiplatformApp/App/Navigation/ContentView.swift:39).
- Accessibility and i18n remain minimal (no `Localizable.strings`), diverging from the samples’ string catalogs and rotors (Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:29; demoapp/FrutaBuildingAFeatureRichAppWithSwiftUI/Shared/Recipe/RecipeList.swift:55).
- Waveform rendering duplicates large buffers every frame, unlike FoodTruck’s efficient updates (Packages/PulsumUI/Sources/PulsumUI/PulseView.swift:217; demoapp/FoodTruckBuildingASwiftUIMultiplatformApp/FoodTruckKit/Sources/Model/FoodTruckModel.swift:39).
- UI and scene coverage lack automated tests; only agents/services are exercised, whereas the demos lean on previews and environment-driven state (Packages/PulsumUI/Tests/PulsumUITests/PulsumRootViewTests.swift:4).
- Privacy manifest is absent despite the HealthKit stack and keychain usage; add parity with Apple guidance. Overall verdict: **B-** (robust agent/services foundation, needs multiplatform, accessibility, and structured startup polish).

## Side-by-Side Comparison Table
| Category | FoodTruck | Fruta | Pulsum | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| Architecture & Project Structure | `@StateObject` scene with macOS menu extras (`demoapp/FoodTruckBuildingASwiftUIMultiplatformApp/App/App.swift:16`) | Shared package + commands injection (`demoapp/FrutaBuildingAFeatureRichAppWithSwiftUI/Shared/FrutaApp.swift:15`) | Packages mirror domains but UIKit-only view code in mac target (`Packages/PulsumUI/Sources/PulsumUI/PulseView.swift:238`) | ⚠️ | Add platform guards to match declared `.macOS(.v14)` support. |
| State & Data Flow | Observable model exposes bindings for editing (`demoapp/FoodTruckBuildingASwiftUIMultiplatformApp/FoodTruckKit/Sources/Model/FoodTruckModel.swift:90`) | Single environment model with StoreKit/auth flows (`demoapp/FrutaBuildingAFeatureRichAppWithSwiftUI/Shared/Model/Model.swift:44`) | `@Observable` view models, but orchestrator factory hard-coded (Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:96) | ⚠️ | Introduce DI closure for orchestrator to aid previews/tests. |
| Concurrency & Data Layer | Background `Task` feeds UI with animation handover (`FoodTruckModel.swift:39`) | Store updates cancel in deinit (`Model.swift:64`) | HealthKit service uses task groups, but startup spawns nested `Task`s without handles (Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:92) | ⚠️ | Restructure startup to a single stored `Task` awaiting completion. |
| Navigation & Scene Management | `NavigationSplitView` + deep-link reset (`App/Navigation/ContentView.swift:39`) | Size-class driven tab vs sidebar (`Shared/Navigation/ContentView.swift:15`) | Single `TabView` regardless of device class (`PulsumRootView.swift:86`) | ⚠️ | Add split view for regular-width platforms. |
| UI Quality & UX | Searchable lists & toolbars (`App/Orders/OrdersView.swift:60`) | Accessibility rotors + unlock CTA previews (`Shared/Recipe/RecipeList.swift:55`) | Liquid Glass styling, safety overlay (`PulsumRootView.swift:109`) but fixed font sizes (`PulsumDesignSystem.swift:40`) | ⚠️ | Switch to dynamic type text styles and broaden previews. |
| Accessibility & Internationalization | Localized donut strings (`FoodTruckModel.swift:22`) + `Localizable.strings` | Extensive `.accessibilityLabel` and multilingual resources (`Shared/Recipe/RecipeList.swift:55`) | Few labels; no string catalog (`Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:29`) | ❌ | Adopt `String(localized:)` and provide `.strings` assets. |
| Performance & Reliability | Background tasks bounce to main actor (`FoodTruckModel.swift:43`) | StoreKit tasks cancelled in `deinit` (`Model.swift:64`) | Waveform recomputes arrays per sample (`PulseView.swift:317`) | ⚠️ | Use slices/ring buffer to avoid per-frame copies. |
| Testing & Tooling | Previews cover views (`App/Orders/OrdersView.swift:140`) | Multiple preview states (`Shared/Recipe/RecipeList.swift:87`) | Rich agent/service tests (`Packages/PulsumAgents/Tests/PulsumAgentsTests/ChatGuardrailAcceptanceTests.swift:12`) but UI tests are placeholders (`PulsumUITests/PulsumUITests.swift:25`) | ⚠️ | Add UI state tests leveraging injectable orchestrator. |
| Security & Privacy | n/a | n/a | Keychain secrets `WhenUnlockedThisDeviceOnly` (`KeychainService.swift:32`) yet no privacy manifest | ⚠️ | Ship `PrivacyInfo.xcprivacy` covering HealthKit, microphone, speech access. |

## Best-Practice Catalogue (Demo Apps)
#### Architecture & Project Structure
- FoodTruck keeps feature state in scene-level `@StateObject`s and provides macOS-specific scenes (`demoapp/FoodTruckBuildingASwiftUIMultiplatformApp/App/App.swift:16`).
- Fruta injects a shared `Model` using `.environmentObject` for consistent data flow across platforms (`demoapp/FrutaBuildingAFeatureRichAppWithSwiftUI/Shared/FrutaApp.swift:15`).

#### State & Data Flow
- FoodTruck’s model exposes `Binding` helpers to mutate lists safely (`FoodTruckKit/Sources/Model/FoodTruckModel.swift:90`).
- Fruta centralizes StoreKit, authentication, and search in one observable model (`Shared/Model/Model.swift:12`).

#### Concurrency & Data Layer
- FoodTruck seeds live orders via background `Task` and marshals updates back to the main actor with animation (`FoodTruckModel.swift:39`).
- Fruta listens for StoreKit updates in a structured `Task` cancelled in `deinit` (`Shared/Model/Model.swift:48`, `64`).

#### Navigation & Scene Management
- FoodTruck adapts navigation between split and stacked layouts and handles deep links (`App/Navigation/ContentView.swift:39`, `63`).
- Fruta switches between tab and sidebar navigation based on size class (`Shared/Navigation/ContentView.swift:15`).

#### UI Quality & UX
- FoodTruck combines `ToolbarItem`, `.searchable`, and context-sensitive sheets (`App/Orders/OrdersView.swift:60`).
- Fruta offers unlock flows with previews for locked/unlocked states (`Shared/Recipe/RecipeList.swift:87`).

#### Accessibility & Internationalization
- Fruta defines accessibility rotors and localized strings to support assistive tech (`Shared/Recipe/RecipeList.swift:55`).
- FoodTruck uses `String(localized:)` for donut defaults (`FoodTruckModel.swift:22`).

#### Performance & Reliability
- FoodTruck batches simulated order generation to avoid UI blocking (`FoodTruckModel.swift:39`).
- Fruta cancels StoreKit listeners on teardown, keeping actor lifetimes bounded (`Shared/Model/Model.swift:64`).

#### Testing & Tooling
- FoodTruck provides previews for major views, aiding regression checks (`App/Orders/OrdersView.swift:140`).
- Fruta ships multiple preview states for RecipeList to guard UI flows (`Shared/Recipe/RecipeList.swift:87`).

#### Security & Privacy
- (Not demonstrated in samples; both rely on demo data and omit privacy manifests.)

## Findings in Pulsum
### Architecture & Project Structure
**What’s good:** The app target is thin and delegates to modular packages (`Pulsum/PulsumApp.swift:12; Packages/PulsumData/Sources/PulsumData/DataStack.swift:71`), matching the demos’ separation of UI and data engines.  
**Gaps:** `PulsumUI` declares `.macOS(.v14)` support (`Packages/PulsumUI/Package.swift:6`) yet `PulseView` references `UIImpactFeedbackGenerator` without gating (`Packages/PulsumUI/Sources/PulsumUI/PulseView.swift:238`), breaking macOS builds.  
**Why it matters:** Shipping a multiplatform package that fails to compile stops distributing shared UI components to macOS or previews. FoodTruck and Fruta both compile on macOS via platform checks.  
**Fix:** Guard UIKit-only imports and wrap haptic triggers.
```diff
@@
-import SwiftUI
-import Observation
+import SwiftUI
+import Observation
+#if canImport(UIKit)
+import UIKit
+#endif
@@
-                    Button {
-                        let impact = UIImpactFeedbackGenerator(style: .medium)
-                        impact.impactOccurred()
+                    Button {
+#if canImport(UIKit)
+                        let impact = UIImpactFeedbackGenerator(style: .medium)
+                        impact.impactOccurred()
+#endif
                         stopAction()
@@
-                Button {
-                    let impact = UIImpactFeedbackGenerator(style: .heavy)
-                    impact.impactOccurred()
+                Button {
+#if canImport(UIKit)
+                    let impact = UIImpactFeedbackGenerator(style: .heavy)
+                    impact.impactOccurred()
+#endif
                     startAction()
                 } label: {
```
**Severity:** Major **Effort:** S

### State & Data Flow
**What’s good:** `AppViewModel` composes dedicated observable sub-view-models and wires consent callbacks (`Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:59-85`), similar to FoodTruck’s scene-owned models.  
**Gaps:** `AppViewModel.start()` instantiates an orchestrator via the static factory (`Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:96`), forcing production dependencies in tests and previews—unlike Fruta’s environment injection.  
**Why it matters:** Without dependency injection, UI tests and previews cannot substitute lightweight orchestrators, so coverage stalls at agents/services.  
**Fix:** Inject an orchestrator factory and reuse it in `start()`.
```diff
@@
-    private let consentStore = ConsentStore()
+    private let consentStore = ConsentStore()
+    private let makeOrchestrator: () throws -> AgentOrchestrator
@@
-    init() {
+    init(makeOrchestrator: @escaping () throws -> AgentOrchestrator = PulsumAgents.makeOrchestrator) {
+        self.makeOrchestrator = makeOrchestrator
         let consent = consentStore.loadConsent()
@@
-                let orchestrator = try PulsumAgents.makeOrchestrator()
+                let orchestrator = try makeOrchestrator()
```
**Severity:** Major **Effort:** M

### Concurrency & Data Layer
**What’s good:** Health ingestion uses structured concurrency with task groups and anchored queries (`Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift:80-189`), aligning with the demos’ background task patterns.  
**Gaps:** `AppViewModel.start()` spawns two nested `Task`s without retaining handles (`Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:92-134`), so cancellation and error propagation depend on implicit captures—unlike FoodTruck/Fruta, which keep long-lived tasks in model scope.  
**Why it matters:** Unstructured tasks risk duplicate startups, lost failures, and make unit testing harder because there’s no deterministic way to await completion.  
**Fix:** Track a single startup task, await orchestrator start inside it, and reset the state deterministically.
```diff
@@
-    @ObservationIgnored private(set) var orchestrator: AgentOrchestrator?
+    @ObservationIgnored private(set) var orchestrator: AgentOrchestrator?
+    @ObservationIgnored private var startupTask: Task<Void, Never>?
@@
-        Task { [weak self] in
-            guard let self else { return }
-            do {
-                print("[Pulsum] Attempting to make orchestrator")
-                let orchestrator = try makeOrchestrator()
-                print("[Pulsum] Orchestrator created")
+        startupTask?.cancel()
+        startupTask = Task { [weak self] in
+            guard let self else { return }
+            do {
+                let orchestrator = try makeOrchestrator()
                 self.orchestrator = orchestrator
@@
-                self.startupState = .ready
-                print("[Pulsum] Startup state set to ready")
-
-                Task { [weak self] in
-                    guard let self else { return }
-                    do {
-                        print("[Pulsum] Starting orchestrator start()")
-                        try await orchestrator.start()
-                        print("[Pulsum] Orchestrator start() completed")
-                        await self.coachViewModel.refreshRecommendations()
-                        print("[Pulsum] Recommendations refreshed")
-                    } catch {
-                        print("[Pulsum] Orchestrator start failed: \(error)")
-                        if let healthError = error as? HealthKitServiceError,
-                           case .healthDataUnavailable = healthError {
-                            return
-                        }
-                        if let healthError = error as? HealthKitServiceError,
-                           case let .backgroundDeliveryFailed(_, underlying) = healthError,
-                           shouldIgnoreBackgroundDeliveryError(underlying) {
-                            return
-                        }
-                        self.startupState = .failed(error.localizedDescription)
-                    }
-                }
+                try await orchestrator.start()
+                await self.coachViewModel.refreshRecommendations()
+                self.startupState = .ready
             } catch {
-                print("[Pulsum] Failed to create orchestrator: \(error)")
                 self.startupState = .failed(error.localizedDescription)
             }
+            self.startupTask = nil
         }
     }
```
**Severity:** Major **Effort:** M

### Navigation & Scene Management
**What’s good:** Tab scaffolding, modals, and safety overlays align with the product spec (`Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift:86-129`).  
**Gaps:** There is no adaptive split experience for iPad/macOS, whereas both samples pivot to split navigation (`demoapp/FoodTruckBuildingASwiftUIMultiplatformApp/App/Navigation/ContentView.swift:39`; `demoapp/FrutaBuildingAFeatureRichAppWithSwiftUI/Shared/Navigation/ContentView.swift:15`).  
**Why it matters:** Large-screen users lose the side-by-side insights/chat workflow highlighted in the demos.  
**Fix:** Add a size-class-aware split view around the existing tabs.
```swift
@Environment(\.horizontalSizeClass) private var horizontalSizeClass

var body: some View {
    Group {
        if horizontalSizeClass == .regular {
            NavigationSplitView {
                SidebarView(selectedTab: $viewModel.selectedTab,
                            wellbeingScore: viewModel.coachViewModel.wellbeingScore)
            } detail: {
                tabbedContent
            }
        } else {
            tabbedContent
        }
    }
    .sheet(isPresented: $viewModel.isPresentingPulse) { … }
}

private var tabbedContent: some View {
    TabView(selection: $viewModel.selectedTab) {
        mainTab.tag(AppViewModel.Tab.main)
        insightsTab.tag(AppViewModel.Tab.insights)
        coachTab.tag(AppViewModel.Tab.coach)
    }
    .tabViewStyle(.automatic)
}
```
**Severity:** Major **Effort:** M

### UI Quality & UX
**What’s good:** The Glass design, consent banner, and state-aware overlays provide polished flows (`PulsumRootView.swift:17-123`).  
**Gaps:** Typography relies on fixed-point sizes (`Packages/PulsumUI/Sources/PulsumUI/PulsumDesignSystem.swift:40-69`), so Dynamic Type and accessibility font scaling break—unlike Fruta’s reliance on text styles.  
**Why it matters:** Users with larger text settings get clipped copy, and system Dynamic Type audits will fail.  
**Fix:** Switch to text-style-based fonts (illustrated below for the main styles).
```diff
@@
-    static let pulsumLargeTitle = Font.system(size: 34, weight: .bold, design: .default)
-    static let pulsumTitle = Font.system(size: 28, weight: .bold, design: .default)
-    static let pulsumTitle2 = Font.system(size: 22, weight: .semibold, design: .default)
-    static let pulsumTitle3 = Font.system(size: 20, weight: .semibold, design: .default)
+    static let pulsumLargeTitle = Font.system(.largeTitle, design: .default).weight(.bold)
+    static let pulsumTitle = Font.system(.title, design: .default).weight(.bold)
+    static let pulsumTitle2 = Font.system(.title2, design: .default).weight(.semibold)
+    static let pulsumTitle3 = Font.system(.title3, design: .default).weight(.semibold)
@@
-    static let pulsumHeadline = Font.system(size: 17, weight: .semibold, design: .default)
-    static let pulsumBody = Font.system(size: 17, weight: .regular, design: .default)
-    static let pulsumCallout = Font.system(size: 16, weight: .regular, design: .default)
-    static let pulsumSubheadline = Font.system(size: 15, weight: .regular, design: .default)
-    static let pulsumFootnote = Font.system(size: 13, weight: .regular, design: .default)
-    static let pulsumCaption = Font.system(size: 12, weight: .regular, design: .default)
-    static let pulsumCaption2 = Font.system(size: 11, weight: .regular, design: .default)
+    static let pulsumHeadline = Font.system(.headline, design: .default)
+    static let pulsumBody = Font.system(.body, design: .default)
+    static let pulsumCallout = Font.system(.callout, design: .default)
+    static let pulsumSubheadline = Font.system(.subheadline, design: .default)
+    static let pulsumFootnote = Font.system(.footnote, design: .default)
+    static let pulsumCaption = Font.system(.caption, design: .default)
+    static let pulsumCaption2 = Font.system(.caption2, design: .default)
```
**Severity:** Major **Effort:** S

### Accessibility & Internationalization
**What’s good:** Some controls expose accessibility labels (`Packages/PulsumUI/Sources/PulsumUI/PulseView.swift:253`).  
**Gaps:** Tab titles and numerous strings are hard-coded English (`AppViewModel.swift:29-41`), and there is no `.strings` catalog, whereas both samples ship localized resources.  
**Why it matters:** Localizing the app (and even supporting English dialect variants) becomes intractable; VoiceOver announcements stay untranslated.  
**Fix:** Introduce keyed localization and string resources.
```diff
@@
         var displayName: String {
             switch self {
-            case .main: return "Main"
-            case .insights: return "Insights"
-            case .coach: return "Coach"
+            case .main: return String(localized: "tab.main.title", comment: "Main tab title")
+            case .insights: return String(localized: "tab.insights.title", comment: "Insights tab title")
+            case .coach: return String(localized: "tab.coach.title", comment: "Coach tab title")
             }
         }
```
Add a base localization file:
```
// Pulsum/Resources/Base.lproj/Localizable.strings
"tab.main.title" = "Main";
"tab.insights.title" = "Insights";
"tab.coach.title" = "Coach";
"pulse.record.prompt" = "Tap to record";
// …extend for all user-facing copy…
```
**Severity:** Critical **Effort:** M

### Performance & Reliability
**What’s good:** Consent and slider submissions debounce via short-lived tasks (`Packages/PulsumUI/Sources/PulsumUI/PulseViewModel.swift:183`).  
**Gaps:** The waveform renderer rebuilds an `Array` copy on every audio sample (`Packages/PulsumUI/Sources/PulsumUI/PulseView.swift:317`), causing unnecessary allocations under load. FoodTruck’s background updates avoid similar copies.  
**Why it matters:** On-device STT already taxes the CPU; extra allocations risk dropped frames precisely when the user views live audio.  
**Fix:** Iterate over a slice instead of allocating a new array.
```diff
-            let samplesToShow = min(audioLevels.count, barCount)
-            let startIndex = max(0, audioLevels.count - samplesToShow)
-            let samples = Array(audioLevels[startIndex..<audioLevels.count])
+            let samples = audioLevels.suffix(min(audioLevels.count, barCount))
 
             for (index, level) in samples.enumerated() {
```
**Severity:** Major **Effort:** S

### Testing & Tooling
**What’s good:** Agent guardrails and LLM fallbacks are thoroughly unit-tested (`Packages/PulsumAgents/Tests/PulsumAgentsTests/ChatGuardrailAcceptanceTests.swift:12-59; Packages/PulsumServices/Tests/PulsumServicesTests/LLMGatewayTests.swift:64-197`).  
**Gaps:** UI-level tests are placeholders (`PulsumUITests/PulsumUITests.swift:25`), and package tests only assert that the root view instantiates (`Packages/PulsumUI/Tests/PulsumUITests/PulsumRootViewTests.swift:5`).  
**Why it matters:** Without UI state tests or previews, regressions in startup gating, consent flows, or chat UI go undetected.  
**Fix:** Add an async test that exercises startup with the debug orchestrator initializer.
```swift
import XCTest
@testable import PulsumUI
@testable import PulsumAgents

@MainActor
final class AppViewModelTests: XCTestCase {
    func testStartTransitionsToReady() async throws {
        let orchestrator = try AgentOrchestrator(
            dataAgent: StubDataAgent(),
            sentimentAgent: SentimentAgent(),
            coachAgent: try CoachAgent(shouldIngestLibrary: false),
            safetyAgent: SafetyAgent(),
            cheerAgent: CheerAgent(),
            topicGate: EmbeddingTopicGateProvider()
        )
        let viewModel = AppViewModel { orchestrator }

        viewModel.start()
        await Task.yield()
        XCTAssertEqual(viewModel.startupState, .ready)
    }
}
```
(Reuse the `StubDataAgent` from acceptance tests to avoid duplication.)  
**Severity:** Major **Effort:** M

### Security & Privacy
**What’s good:** Secrets reside in `Keychain` with `WhenUnlockedThisDeviceOnly` protection (`Packages/PulsumServices/Sources/PulsumServices/KeychainService.swift:29-56`), and Core Data files are `NSFileProtectionComplete` (`Packages/PulsumData/Sources/PulsumData/DataStack.swift:75`).  
**Gaps:** The repository lacks a `PrivacyInfo.xcprivacy` manifest despite accessing HealthKit, microphone, and speech recognition. Apple now requires this metadata for App Store distribution.  
**Why it matters:** Without the manifest, App Review can reject the build; more importantly, it documents data usage for users.  
**Fix:** Add a privacy manifest describing the APIs Pulsum consumes.
```json
{
  "privacy": {
    "tracking": {
      "purposes": []
    },
    "accessedAPIs": [
      {
        "identifier": "NSPrivacyAccessedAPICategoryHealth",
        "description": "Pulsum ingests HRV, rest heart rate, breathing, steps, and sleep metrics to compute wellbeing trends."
      },
      {
        "identifier": "NSPrivacyAccessedAPICategoryMicrophone",
        "description": "Voice journals capture short audio clips for on-device transcription."
      },
      {
        "identifier": "NSPrivacyAccessedAPICategorySpeechRecognition",
        "description": "On-device speech recognition turns voice journals into text."
      }
    ]
  }
}
```
**Severity:** Major **Effort:** S

## Prioritized Backlog (Jira-ready)
- [P1] Guard UIKit-specific UI in PulseView  
  Context: macOS builds fail because `PulseView` calls UIKit haptics despite the package advertising macOS support.  
  Acceptance criteria:  
  - [ ] `Packages/PulsumUI` compiles for macOS without conditional compilation errors.  
  - [ ] Pulse journaling still triggers haptics on iOS.  
  - [ ] Add regression test/build step covering macOS compilation.  
  Owner: UI Platform Lead Effort: S Dependencies: none Risk: Low (UI-only change).

- [P1] Restructure AppViewModel startup for DI + structured concurrency  
  Context: Startup currently hardcodes orchestrator creation and runs untracked tasks, making tests flaky.  
  Acceptance criteria:  
  - [ ] `AppViewModel` accepts an orchestrator factory and stores a `startupTask`.  
  - [ ] `start()` cancels any prior task and awaits orchestrator start before setting `.ready`.  
  - [ ] Unit test covers ready/failure transitions via debug orchestrator initializer.  
  Owner: Application Architecture Effort: M Dependencies: Guard UIKit change merged to avoid conflicts Risk: Medium (touches core startup).

- [P2] Adopt localization + Dynamic Type for primary UI copy  
  Context: Fixed-size fonts and raw strings prevent accessibility scaling and localization.  
  Acceptance criteria:  
  - [ ] `PulsumDesignSystem` uses text-style-based fonts for all tokens.  
  - [ ] A Base `Localizable.strings` file exists; tab labels and key UI strings fetch localized values.  
  - [ ] Snapshot or UI test verifies large Dynamic Type renders without clipping.  
  Owner: UI/Accessibility Engineer Effort: M Dependencies: Startup refactor (for DI test harness) Risk: Medium.

- [P2] Publish privacy manifest  
  Context: HealthKit, microphone, and speech APIs require a `PrivacyInfo.xcprivacy`.  
  Acceptance criteria:  
  - [ ] `Pulsum/PrivacyInfo.xcprivacy` defines Health, Microphone, and Speech entries with accurate descriptions.  
  - [ ] Xcode build settings include the manifest in the app target.  
  - [ ] CI step validates the manifest with `plutil`.  
  Owner: Compliance Engineer Effort: S Dependencies: None Risk: Low.

## Code Snippet Appendix
- NavigationSplitView pattern from FoodTruck illustrating adaptive layout:  
  ```swift
  NavigationSplitView {
      Sidebar(selection: $selection)
  } detail: {
      NavigationStack(path: $path) {
          DetailColumn(selection: $selection, model: model)
      }
  }
  // demoapp/FoodTruckBuildingASwiftUIMultiplatformApp/App/Navigation/ContentView.swift:39
  ```
- Accessibility rotor usage from Fruta for quick VoiceOver navigation:  
  ```swift
  .accessibilityRotor("Smoothies", entries: smoothies, entryLabel: \.title)
  // demoapp/FrutaBuildingAFeatureRichAppWithSwiftUI/Shared/Recipe/RecipeList.swift:55
  ```

## Evidence Index
- demoapp/FoodTruckBuildingASwiftUIMultiplatformApp/App/App.swift:16 — Multiplatform scene configuration.
- demoapp/FoodTruckBuildingASwiftUIMultiplatformApp/FoodTruckKit/Sources/Model/FoodTruckModel.swift:22 — Localized strings & background tasks.
- demoapp/FoodTruckBuildingASwiftUIMultiplatformApp/App/Navigation/ContentView.swift:39 — Adaptive NavigationSplitView.
- demoapp/FoodTruckBuildingASwiftUIMultiplatformApp/App/Orders/OrdersView.swift:60 — Toolbar/searchable integration.
- demoapp/FrutaBuildingAFeatureRichAppWithSwiftUI/Shared/FrutaApp.swift:15 — EnvironmentObject injection.
- demoapp/FrutaBuildingAFeatureRichAppWithSwiftUI/Shared/Model/Model.swift:44 — Structured StoreKit tasks.
- demoapp/FrutaBuildingAFeatureRichAppWithSwiftUI/Shared/Navigation/ContentView.swift:15 — Size-class navigation switch.
- demoapp/FrutaBuildingAFeatureRichAppWithSwiftUI/Shared/Recipe/RecipeList.swift:55 — Accessibility rotors and localization.
- Packages/PulsumUI/Package.swift:6 — Declared platform support.
- Packages/PulsumUI/Sources/PulsumUI/PulseView.swift:238 — UIKit-only haptics on mac target.
- Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift:86 — Tab-only layout.
- Packages/PulsumUI/Sources/PulsumUI/PulsumDesignSystem.swift:40 — Fixed-size fonts.
- Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift:59,96 — View-model composition and orchestrator creation.
- Packages/PulsumUI/Sources/PulsumUI/PulseViewModel.swift:160 — Slider submission task handling.
- Packages/PulsumData/Sources/PulsumData/DataStack.swift:71 — Core Data setup with file protection.
- Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift:80 — Task group background delivery.
- Packages/PulsumServices/Sources/PulsumServices/KeychainService.swift:29 — Keychain storage protections.
- Packages/PulsumServices/Tests/PulsumServicesTests/LLMGatewayTests.swift:64 — Guardrail tests.
- Packages/PulsumAgents/Tests/PulsumAgentsTests/ChatGuardrailAcceptanceTests.swift:12 — Consent-routing acceptance tests.
- PulsumUITests/PulsumUITests.swift:25 — Placeholder UI tests.
