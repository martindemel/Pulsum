# Pulsum — v1.1+ Future Roadmap

**Purpose:** This document captures everything needed to take Pulsum from "shippable indie app" (v1.0) to "Oura/Fitbit-level product." It covers backend infrastructure, CI/CD, monetization, platform integrations, data sync, QA processes, and operational maturity.  
**Prerequisite:** Complete `master_plan_FINAL.md` (v1.0) first. This roadmap builds on top of the v1.0 foundation.  
**Reference:** Compared against Oura Ring app, Fitbit, Apple Health, Calm, and Headspace for feature parity.

---

## What v1.0 Delivers vs What Production Health Apps Have

| Capability | v1.0 (after master_plan_FINAL.md) | Oura / Fitbit / Apple | Gap |
|---|---|---|---|
| **Backend server** | None — all on-device + BYOK API key | Full backend (user accounts, API proxy, data sync, push notifications) | **Critical gap** |
| **User accounts** | None — no login, no identity | Email/Apple ID sign-in, user profiles | **Critical gap** |
| **Data sync** | None — data lives on one device only | Cross-device sync, web dashboard | **High gap** |
| **Monetization** | None — BYOK API key for cloud | Subscription via StoreKit, server-side receipt validation | **High gap** |
| **CI/CD pipeline** | Manual `xcodebuild` + `swiftformat` | Xcode Cloud / GitHub Actions + Fastlane, automated TestFlight, automated App Store submission | **High gap** |
| **Push notifications** | None | Daily summaries, coaching reminders, health alerts | **Medium gap** |
| **Feature flags** | None — all behavior hardcoded | Firebase Remote Config or custom — toggle features without app update | **Medium gap** |
| **A/B testing** | None | Test coaching prompts, UI variants, onboarding flows | **Medium gap** |
| **Device test matrix** | Developer's device only | 10+ device models, 3+ OS versions, automated via device farms | **Medium gap** |
| **Accessibility audit** | Dynamic Type (after Phase 3) | Full VoiceOver audit by real users, WCAG 2.1 AA compliance | **Medium gap** |
| **Crash reporting** | MetricKit (after Phase 3) | Crashlytics/Sentry with alerting, symbolication, trend analysis | **Low gap** |
| **Analytics** | Event structure only (after Phase 3) | Full analytics pipeline with dashboards, funnels, retention curves | **Low gap** |
| **Localization** | English only | 10-20 languages, RTL support | **Low gap for launch** |
| **Widgets** | None | Home screen widget showing daily score | **Low gap** |
| **Siri / App Intents** | None | "Hey Siri, how am I doing today?" | **Low gap** |
| **Apple Watch** | None | Companion app for wrist-based journaling and score glance | **Large effort** |
| **Web dashboard** | None | Browser-based view of trends, history, insights | **Large effort** |

---

## Phase 4.5: Backend Integration (Critical — Do Before App Store Launch)

**Goal:** Move the OpenAI API key off the device. Users authenticate with your backend; your backend calls OpenAI.  
**Effort:** ~1-2 weeks (backend + iOS changes)  
**Why before launch:** You said you don't want the API key in the app. Without a backend, cloud coaching doesn't work for normal users.

### Backend Architecture (Minimal Viable)

```
┌──────────────┐     HTTPS      ┌──────────────────┐     HTTPS      ┌─────────────┐
│  Pulsum iOS  │ ──────────────→│  api.pulsum.ai   │──────────────→ │ OpenAI API  │
│     App      │ ←──────────────│  (your backend)  │←────────────── │ (GPT-5)     │
└──────────────┘   user token   └──────────────────┘   your API key └─────────────┘
```

**Backend responsibilities:**
1. **Authentication** — Verify user identity (Apple Sign-In JWT or anonymous device token)
2. **API proxy** — Receive coaching request from iOS app, forward to OpenAI with YOUR API key, return response
3. **Rate limiting** — Max requests per user per hour (server-enforced, not client-side)
4. **Usage tracking** — Count tokens/requests per user for billing decisions
5. **Key management** — Store and rotate OpenAI API key securely (env var, not in code)
6. **Response caching** — Optional: cache identical requests to reduce API cost
7. **Audit logging** — Log requests (without PII) for debugging and abuse detection

**Technology options (pick one):**

| Option | Pros | Cons | Best For |
|---|---|---|---|
| **Cloudflare Workers** | Zero server management, global edge, cheap ($5/mo), JS/TS | Limited compute time (30s), cold starts | Simplest possible proxy |
| **Supabase Edge Functions** | Comes with auth + database + storage, Deno/TS | Vendor lock-in, less flexible | If you also need user accounts + database |
| **AWS Lambda + API Gateway** | Infinite scale, pay-per-use, any language | Complex setup, AWS learning curve | If you want full AWS ecosystem |
| **Fly.io + Swift Vapor** | Swift on server (same language as iOS), low latency | Self-managed, more ops work | If you want Swift everywhere |
| **Railway / Render + Node.js** | Simple deployment, auto-scaling, cheap | Less control than AWS | Quick MVP backend |

**My recommendation for v1.1:** Supabase. It gives you auth (Apple Sign-In support built-in), a Postgres database (for usage tracking), Edge Functions (for the API proxy), and Row Level Security (for HIPAA-adjacent data isolation) — all in one platform. You can have a working backend in 2-3 days.

### iOS-Side Changes for Backend Integration

- [ ] **F4.5-01** | Create `PulsumAPIClient` service  
  **Create:** `Packages/PulsumServices/Sources/PulsumServices/PulsumAPIClient.swift`  
  **What to build:** An actor or class that handles all communication with `api.pulsum.ai`. Methods: `generateCoachResponse(context:) async throws -> CoachReplyPayload`, `testConnection() async -> Bool`. Uses `URLSession` with certificate pinning for your domain. Sends user auth token in `Authorization` header.

- [ ] **F4.5-02** | Replace `GPT5Client` URL from OpenAI to your backend  
  **File:** `Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift`  
  **What to change:** The `CloudLLMClient` protocol stays the same. Create a new `PulsumCloudClient` that conforms to it but hits `api.pulsum.ai/v1/coach` instead of `api.openai.com/v1/responses`. Keep `GPT5Client` for local development/testing with BYOK.

- [ ] **F4.5-03** | Add user authentication (Apple Sign-In or anonymous)  
  **Create:** `Packages/PulsumServices/Sources/PulsumServices/AuthService.swift`  
  **What to build:** Manage user session tokens. Options: (a) Apple Sign-In (`ASAuthorizationAppleIDProvider`) for identified users, (b) anonymous device tokens for privacy-first users (generate a UUID, register with backend, get a session token). Store session token in Keychain.

- [ ] **F4.5-04** | Remove BYOK API key UI from Settings (or make it developer-only)  
  **File:** `Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift`  
  **What to change:** Hide the "API Key" section in production. Keep it behind a `#if DEBUG` flag for developer testing. Normal users authenticate via Apple Sign-In; their coaching requests go through your backend.

- [ ] **F4.5-05** | Update consent language for backend routing  
  **Files:** `ConsentBannerView.swift`, `CoachView.swift`  
  **What to change:** Update disclosure text from "sends to OpenAI" to "sends to Pulsum's servers for coaching (processed by AI, no raw health data sent)." The user consents to sending data to YOUR server, not directly to OpenAI.

- [ ] **F4.5-06** | Add token refresh / session management  
  **File:** `PulsumAPIClient.swift`  
  **What to build:** Handle expired tokens (401 response → re-authenticate → retry). Handle network errors gracefully. Fall back to on-device coaching if backend is unreachable.

---

## Phase 5: Monetization with StoreKit 2

**Goal:** Subscription model — free tier (on-device coaching) + paid tier (cloud coaching via your backend).  
**Effort:** ~2-3 weeks  
**Prerequisite:** Phase 4.5 (backend) complete

### Subscription Tiers

| Tier | Price | What You Get |
|---|---|---|
| **Free** | $0 | On-device Foundation Models coaching, HealthKit wellbeing score, voice journaling, crisis detection |
| **Pulsum Pro** | $4.99/mo or $39.99/yr | Cloud GPT-5 coaching (higher quality), unlimited chat, priority coaching, advanced score insights |

### iOS Implementation

- [ ] **F5-01** | Create StoreKit 2 configuration file  
  **Create:** `Pulsum/Configuration.storekit` (StoreKit Configuration File in Xcode)  
  Define products: `ai.pulsum.pro.monthly` ($4.99/mo auto-renewable), `ai.pulsum.pro.yearly` ($39.99/yr auto-renewable).

- [ ] **F5-02** | Build `SubscriptionManager`  
  **Create:** `Packages/PulsumServices/Sources/PulsumServices/SubscriptionManager.swift`  
  **What to build:** An `@Observable` class using StoreKit 2 (`Product`, `Transaction`). Methods: `fetchProducts()`, `purchase(_ product:)`, `restorePurchases()`, `var isProUser: Bool` (checks `Transaction.currentEntitlements`). Listen for transaction updates with `Transaction.updates`. **Search Apple docs for StoreKit 2 — the API changed significantly from StoreKit 1.**

- [ ] **F5-03** | Build `PaywallView`  
  **Create:** `Packages/PulsumUI/Sources/PulsumUI/PaywallView.swift`  
  **What to build:** A SwiftUI view showing subscription tiers, pricing, features comparison, "Subscribe" buttons, and "Restore Purchases" link. Present when free-tier user tries to use a Pro feature (cloud chat). Follow Apple's Human Interface Guidelines for subscription UX.

- [ ] **F5-04** | Gate cloud coaching behind subscription  
  **File:** `AgentOrchestrator.swift` or `CoachAgent.swift`  
  **What to change:** Before routing to cloud: check `SubscriptionManager.shared.isProUser`. If not Pro, show paywall. If Pro, proceed to backend API. On-device coaching always available regardless of subscription.

- [ ] **F5-05** | Server-side receipt validation  
  **Backend:** Add an endpoint `POST /v1/verify-receipt` that validates App Store receipts using Apple's `StoreKit Server API` or `App Store Server Notifications V2`. This prevents jailbroken devices from spoofing Pro status.

- [ ] **F5-06** | Add "Manage Subscription" link in Settings  
  **File:** `SettingsView.swift`  
  **What to add:** A link to `URL(string: "https://apps.apple.com/account/subscriptions")!` so users can manage/cancel their subscription. Apple requires this.

---

## Phase 6: CI/CD Pipeline

**Goal:** Automated builds, tests, and distribution.  
**Effort:** ~1 week setup  

### Option A: Xcode Cloud (Apple-native, simplest)

- [ ] **F6-01** | Set up Xcode Cloud workflow  
  **What to configure:** In Xcode → Product → Xcode Cloud: (1) Build on every push to `main`. (2) Run all package tests. (3) On successful build of `main`, distribute to TestFlight automatically. (4) Archive for App Store on tagged releases.

### Option B: GitHub Actions + Fastlane (more flexible)

- [ ] **F6-02** | Create GitHub Actions workflow  
  **Create:** `.github/workflows/ci.yml`  
  **What to build:** (1) On PR: `swift test` for all packages + `swiftformat --lint .` + `scripts/ci/check-privacy-manifests.sh`. (2) On merge to `main`: full `xcodebuild` + test + archive. (3) On tag: Fastlane → TestFlight upload.

- [ ] **F6-03** | Set up Fastlane  
  **Create:** `fastlane/Fastfile`  
  **Lanes:** `test` (run all tests), `beta` (build + upload to TestFlight), `release` (build + submit to App Store). Manage code signing via `match` (encrypted certificates in a private repo).

- [ ] **F6-04** | Set up code signing for CI  
  **What to do:** Export certificates and provisioning profiles. Store in GitHub Secrets or Fastlane Match. Configure automatic signing in CI environment.

---

## Phase 7: Push Notifications

**Goal:** Daily coaching reminders, weekly wellness summaries, streak encouragement.  
**Effort:** ~1 week  
**Prerequisite:** Backend (Phase 4.5) + user accounts

- [ ] **F7-01** | Add push notification entitlement  
  **File:** `Pulsum.entitlements` — add `aps-environment` entitlement.

- [ ] **F7-02** | Register for remote notifications in AppDelegate  
  **File:** `PulsumApp.swift` or create an AppDelegate adapter.  
  **What to do:** `UIApplication.shared.registerForRemoteNotifications()`. Handle `didRegisterForRemoteNotificationsWithDeviceToken` — send token to your backend.

- [ ] **F7-03** | Backend: send scheduled notifications  
  **What to build:** Daily coaching reminder at user's preferred time. Weekly wellness summary ("Your HRV improved 12% this week"). Streak encouragement ("5 journal entries this week — keep going!"). Use APNs (Apple Push Notification service) via your backend.

- [ ] **F7-04** | Handle notification taps  
  **What to do:** Deep-link from notification to the relevant screen (journal, coach, score breakdown).

---

## Phase 8: Platform Integrations

### 8.1 — Home Screen Widget (WidgetKit)

- [ ] **F8-01** | Create Pulsum Widget extension  
  **What to build:** A small/medium widget showing the latest wellbeing score, trend arrow (up/down/stable), and the interpretive label ("Positive momentum"). Uses `AppIntentTimelineProvider` for refresh. Reads score from shared `App Group` container or SwiftData with `App Group`.  
  **Search Apple docs for WidgetKit and App Groups before starting.**

### 8.2 — Siri / App Intents

- [ ] **F8-02** | Create App Intents for Siri  
  **What to build:** (1) `CheckWellbeingIntent` — "Hey Siri, how am I doing today?" → returns wellbeing score and label. (2) `StartJournalIntent` — "Hey Siri, start a voice journal" → opens app to recording screen. Uses the `AppIntents` framework.  
  **Search Apple docs for AppIntents and App Shortcuts.**

### 8.3 — Apple Watch Companion (Large Effort — v2.0)

- [ ] **F8-03** | Create watchOS target  
  **What to build:** A watchOS companion app with: (1) Wellbeing score complication for watch face. (2) Quick journal recording from wrist. (3) Coaching card swipe-through. Uses WatchConnectivity for data sync with the iOS app.  
  **Note:** This is a significant undertaking (~4-8 weeks). Defer to v2.0.

### 8.4 — Live Activities (During Recording)

- [ ] **F8-04** | Show Live Activity during voice journal recording  
  **What to build:** When the user starts recording, show a Live Activity on the Lock Screen and Dynamic Island with: recording timer, waveform animation, "Tap to return" action. Uses `ActivityKit`.  
  **Search Apple docs for ActivityKit and Live Activities.**

---

## Phase 9: Data Sync and User Accounts

**Goal:** Users can sign in, sync data across devices, and access a web dashboard.  
**Effort:** ~3-4 weeks  
**Prerequisite:** Backend (Phase 4.5)

### Option A: CloudKit (Apple-native, end-to-end encrypted)

- [ ] **F9-01** | Enable CloudKit sync for SwiftData  
  **What to do:** SwiftData supports CloudKit sync natively. Add the CloudKit entitlement, configure a CloudKit container, and mark model properties as syncable. User signs in with their Apple ID — no separate account needed. End-to-end encrypted by default.  
  **Pros:** Zero backend work for sync. Apple handles encryption, conflict resolution, storage.  
  **Cons:** No web dashboard (CloudKit JS exists but limited). Apple-only (no Android).

### Option B: Custom Backend Sync (Supabase / Firebase)

- [ ] **F9-02** | Build sync infrastructure  
  **What to do:** Store user data in your Supabase/Firebase database. Implement conflict resolution (last-write-wins or merge). Sync on app launch and periodically. Handle offline queue (save locally, sync when online).  
  **Pros:** Web dashboard possible. Cross-platform possible (Android someday).  
  **Cons:** You manage encryption, HIPAA compliance, data residency.

### Web Dashboard (v2.0)

- [ ] **F9-03** | Build web dashboard  
  **What to build:** A Next.js or Swift-on-server web app at `app.pulsum.ai` where users can: view their wellbeing score history as a chart, read past journal entries, review coaching recommendations, export their data (GDPR). Reads from the same backend database as the iOS app.

---

## Phase 10: Feature Flags and A/B Testing

**Goal:** Toggle features remotely. Test variations without app updates.  
**Effort:** ~1 week setup  

- [ ] **F10-01** | Integrate Firebase Remote Config (or custom)  
  **What to do:** Define flags: `cloud_coaching_enabled`, `safety_threshold`, `coaching_prompt_version`, `show_new_onboarding`. Fetch on app launch. Use throughout the app to gate features.

- [ ] **F10-02** | Set up A/B testing for coaching prompts  
  **What to do:** Create 2-3 variants of the LLM system prompt. Assign users randomly to variants. Measure engagement (chat messages sent, recommendations completed) per variant. Pick the winner.

---

## Phase 11: Localization

**Goal:** Support multiple languages.  
**Effort:** ~2-3 weeks (engineering) + translator time  

- [ ] **F11-01** | Extract all strings to String Catalog  
  **What to do:** Create `Localizable.xcstrings` in the main app target. SwiftUI `Text("string")` automatically uses `LocalizedStringKey`. Export for translators via Xcode's localization export. Start with: English (base), Spanish, German, French, Japanese.

- [ ] **F11-02** | Localize crisis resources  
  **What to do:** Create a locale-aware crisis resource map: US → 988, UK → 116 123 (Samaritans), DE → 0800 111 0 111 (TelefonSeelsorge), etc. Use `Locale.current.region?.identifier` to select.

- [ ] **F11-03** | Test RTL layout  
  **What to do:** Run the app in Arabic/Hebrew locale. Verify all layouts mirror correctly. Fix any hardcoded leading/trailing assumptions.

---

## Phase 12: Advanced QA and Compliance

### Device Test Matrix

| Device | Screen Size | Chip | Why Test |
|---|---|---|---|
| iPhone 16 Pro Max | 6.9" | A18 Pro | Largest screen, reference device |
| iPhone 16 | 6.1" | A18 | Standard size |
| iPhone SE (4th gen) | 6.1" | A18 | Budget device, different user demographic |
| iPhone 15 | 6.1" | A16 | Previous generation, iOS 26 support |
| iPad Pro 13" | 13" | M4 | Tablet layout (if supporting iPad) |

### Compliance Checklist for Scale

- [ ] **HIPAA Business Associate Agreement (BAA)** — If storing health data on YOUR server, you need a BAA with your hosting provider (Supabase, AWS, etc.)
- [ ] **GDPR Data Processing Agreement** — Required if you have EU users and process their data on your backend
- [ ] **SOC 2 Type II** — Not required for launch but investors/enterprise partners will ask for it
- [ ] **App Store Health & Fitness category requirements** — Re-review Apple guidelines before each major update
- [ ] **Accessibility audit by real users** — Hire a VoiceOver user to test all flows
- [ ] **Penetration test** — Before storing health data on a server, have a security firm audit your backend

---

## Priority Order for v1.1

If you can only do some of the above, prioritize in this order:

1. **Phase 4.5: Backend** — Removes API key from app. Enables monetization. Required for everything else.
2. **Phase 5: Monetization** — Revenue. Without it, the app can't sustain itself.
3. **Phase 6: CI/CD** — Reduces manual work. Catches regressions. Enables fast iteration.
4. **Phase 8.1: Widget** — Highest-impact platform integration for daily engagement.
5. **Phase 7: Push notifications** — Retention driver ("You haven't journaled in 3 days").
6. **Phase 11: Localization** — Expands addressable market 5-10x.
7. **Phase 8.2: Siri** — Natural for a voice-journal app.
8. **Phase 9: Data sync** — Users expect cross-device continuity.
9. **Phase 10: Feature flags** — Enables safe experimentation.
10. **Phase 12: Compliance** — Required at scale, not at launch.
11. **Phase 8.3: Apple Watch** — Large effort, defer to v2.0.
12. **Phase 9.3: Web dashboard** — Nice to have, defer to v2.0.

---

## Cost Estimates

| Component | Service | Monthly Cost (at launch) | At 10K users |
|---|---|---|---|
| Backend hosting | Supabase Pro | $25/mo | $75/mo |
| OpenAI API | GPT-5 | ~$50/mo (1K daily requests) | ~$500/mo |
| Push notifications | APNs (via backend) | Free | Free |
| CI/CD | Xcode Cloud | Free (25 hrs/mo) | Free |
| Analytics | TelemetryDeck | Free (100K signals/mo) | $9/mo |
| Crash reporting | MetricKit | Free | Free |
| Domain + SSL | Cloudflare | Free | Free |
| **Total** | | **~$75/mo** | **~$585/mo** |

At $4.99/mo subscription, you need **~15 paying users to break even at launch**, ~120 paying users to break even at 10K users (assuming 10% conversion to Pro).

---

## Reference

| Document | What It Contains |
|---|---|
| `master_plan_FINAL.md` | v1.0 remediation plan (78 items, 4 phases) — **complete this first** |
| `master_report.md` | 112 technical findings from the codebase audit |
| `guidelines_report.md` | App Store compliance checks (29 items) |
| `scan_prompt.md` | Reusable audit prompt for future code reviews |
