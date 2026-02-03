# Pulsum App Design (Implementation Reference)

This document captures how Pulsum's UI is built and styled in code so you can reuse the patterns in a new app. It focuses on the live implementation plus the design system and visual assets that shape the look.

## Scope and sources
- Primary UI implementation: `Packages/PulsumUI/Sources/PulsumUI`
- App entry and wiring: `Pulsum/PulsumApp.swift`
- Design system tokens: `Packages/PulsumUI/Sources/PulsumUI/PulsumDesignSystem.swift`
- Liquid Glass styling: `Packages/PulsumUI/Sources/PulsumUI/GlassEffect.swift`
- Optional Liquid Glass tab bar: `Packages/PulsumUI/Sources/PulsumUI/LiquidGlassComponents.swift`
- Design guidance: `liquidglass.md`, `Docs/architecture copy.md`, `instructions.md`
- Visual assets inventory: see "Visual assets inventory" section

Notes:
- Build artifacts (`Build/`, `DerivedData/`) are excluded from design analysis.
- PDFs, images, .splineswift, and .usdz are treated as non-text assets and not parsed.

## Design intent and visual language
Pulsum targets iOS 26 and adopts the Liquid Glass aesthetic: warm, airy backgrounds, minimal layout, translucent controls, and soft elevation. The palette is anchored in beige and cream with gentle mint/blue accents. Cards and controls float above a gradient background using glass materials, while core content stays opaque for readability.

## Design system tokens (as implemented)
Source: `Packages/PulsumUI/Sources/PulsumUI/PulsumDesignSystem.swift`

### Color palette
| Token | Hex | Usage notes |
| --- | --- | --- |
| pulsumBackgroundBeige | #F5F3ED | Primary background; warm beige |
| pulsumBackgroundCream | #FAF8F2 | Secondary background; soft cream |
| pulsumBackgroundLight | #F7F5F0 | Light beige surface |
| pulsumBackgroundPeach | #FCF5F0 | Peach tint for subtle variation |
| pulsumMintGreen | #D4EED4 | Assistant chat bubbles |
| pulsumMintLight | #E8F5E8 | Light mint highlight |
| pulsumBlueSoft | #A8D5F2 | Informational accents and badges |
| pulsumPinkSoft | #FAE3E3 | Secondary accent and health icon |
| pulsumGreenSoft | #7ACC7A | Primary action accent |
| pulsumTextPrimary | #2C2C2E | Primary text |
| pulsumTextSecondary | #8F8F94 | Secondary text |
| pulsumTextTertiary | #BCBCC0 | Tertiary text |
| pulsumSuccess | #34C759 | Success semantic |
| pulsumWarning | #FF9500 | Warning semantic |
| pulsumError | #FF3B30 | Error semantic |
| pulsumInfo | #0A84FF | Info semantic |

### Spacing scale
| Token | Value |
| --- | --- |
| xxs | 4 |
| xs | 8 |
| sm | 12 |
| md | 16 |
| lg | 24 |
| xl | 32 |
| xxl | 48 |
| xxxl | 64 |

### Corner radius scale
| Token | Value |
| --- | --- |
| xs | 8 |
| sm | 12 |
| md | 16 |
| lg | 20 |
| xl | 24 |
| xxl | 28 |
| xxxl | 32 |

### Typography
Pulsum uses system fonts with fixed sizes and weights (no Dynamic Type scaling yet).

| Token | Size | Weight | Design |
| --- | --- | --- | --- |
| pulsumLargeTitle | 34 | bold | default |
| pulsumTitle | 28 | bold | default |
| pulsumTitle2 | 22 | semibold | default |
| pulsumTitle3 | 20 | semibold | default |
| pulsumHeadline | 17 | semibold | default |
| pulsumBody | 17 | regular | default |
| pulsumCallout | 16 | regular | default |
| pulsumSubheadline | 15 | regular | default |
| pulsumFootnote | 13 | regular | default |
| pulsumCaption | 12 | regular | default |
| pulsumCaption2 | 11 | regular | default |
| pulsumDataXLarge | 58 | bold | rounded |
| pulsumDataLarge | 48 | bold | rounded |
| pulsumDataMedium | 32 | bold | rounded |
| pulsumDataSmall | 24 | semibold | rounded |

### Shadows and animations
| Token | Spec |
| --- | --- |
| PulsumShadow.small | radius 8, y 2, opacity 0.06 |
| PulsumShadow.medium | radius 12, y 4, opacity 0.08 |
| PulsumShadow.large | radius 20, y 8, opacity 0.08 |
| pulsumQuick | spring response 0.3, damping 0.75 |
| pulsumStandard | spring response 0.4, damping 0.8 |
| pulsumSmooth | spring response 0.5, damping 0.85 |
| pulsumBouncy | spring response 0.5, damping 0.6 |

## Liquid Glass implementation
Source: `Packages/PulsumUI/Sources/PulsumUI/GlassEffect.swift`

Pulsum implements a custom `glassEffect` modifier that:
- Wraps content in a `RoundedRectangle` with a Material background.
- Applies a tint overlay if provided.
- Adds a soft white stroke and a depth shadow based on intensity.
- Adds interactive scaling (0.96) on press when `interactive()` is enabled.

Example usage from UI:
```swift
Button("Action") { ... }
    .glassEffect(.regular.tint(Color.pulsumGreenSoft.opacity(0.6)).interactive())
```

There is also a `GlassEffectContainer` for grouped glass elements, and a custom `PulsumInteractiveButtonStyle` for non-glass buttons.

Exact glass background implementation (core lines):
```swift
RoundedRectangle(cornerRadius: radius, style: .continuous)
    .fill(style.intensity.material)
    .overlay {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(style.tintColor ?? tintFallback)
            .opacity(style.tintColor == nil ? 0.18 : 1)
    }
    .overlay {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.25 : 0.3), lineWidth: 1)
    }
    .shadow(
        color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.15),
        radius: style.intensity.shadowRadius,
        x: 0,
        y: style.intensity.shadowRadius / 2
    )
```

## UI architecture and layout framework
Source: `Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift`

Pulsum uses SwiftUI + Observation:
- View models are `@Observable` and bound with `@Bindable`.
- Root view is `PulsumRootView`, which hosts a `TabView` with three tabs.
- Each tab uses its own `NavigationStack`.
- Two sheets are presented from the root: `PulseView` and `SettingsScreen`.
- Overlays include startup blockers, a safety overlay, and a consent banner.
- Content width is capped at 520 for readability (`.frame(maxWidth: 520)`).
- Background is a warm gradient: `pulsumBackgroundBeige` to `pulsumBackgroundCream`.

Runtime config toggles (useful for UI test or reuse):
- Disable animations: `AppRuntimeConfig.disableAnimations` in `Packages/PulsumTypes/Sources/PulsumTypes/AppRuntimeConfig.swift`
- Hide consent banner: `AppRuntimeConfig.hideConsentBanner`
- Force settings fallback and test hooks in UI tests

### Toolbar chrome and scroll behavior (exact code)
Source: `Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift`

Navigation bars use the system default background and do not implement a custom scroll-driven fade or hide. The only explicit styling is:
```swift
.navigationBarTitleDisplayMode(.inline)
.toolbarBackground(.automatic, for: .navigationBar)
```

Scroll views hide indicators but do not animate toolbar transparency:
```swift
ScrollView {
    LazyVStack(spacing: PulsumSpacing.xl) { ... }
}
.scrollIndicators(.hidden)
```

If you want a semi-transparent nav bar that fades or disappears on scroll, that behavior is not present in the current codebase and would need to be added.

## Screen-by-screen design

### Root and startup overlays
Source: `Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift`
- Background: full-screen beige/cream gradient.
- Startup overlay states: idle/loading (blur content + progress card), failed (error card), blocked (storage security warning).
- Transition: opacity; blur animation uses `.easeInOut` when enabled.

### Main tab (Wellbeing)
Source: `Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift`
- Toolbar: leading Pulse button (waveform icon), trailing Settings gear.
- Content: a single card stack (currently one wellbeing score card).
- Card states:
  - Ready: `WellbeingScoreCard` with score, interpretation, and chevron.
  - Loading: `WellbeingScoreLoadingCard` with spinner and copy.
  - No data: `WellbeingNoDataCard` or `WellbeingPlaceholderCard`.
  - Error: `WellbeingErrorCard` with retry option.
- Cards are white with soft shadow and rounded corners.
- Navigation: tapping the card can push `ScoreBreakdownScreen`.

Exact toolbar button design (Pulse + Settings), including sizes and styling:
```swift
ToolbarItem(placement: .navigationBarLeading) {
    Button { viewModel.isPresentingPulse = true } label: {
        Label("Pulse", systemImage: "waveform.path.ecg").labelStyle(.titleAndIcon)
    }
    .pulsumToolbarButton()
    .accessibilityIdentifier("PulseButton")
}

ToolbarItem(placement: .navigationBarTrailing) {
    Button {
        presentSettings()
    } label: {
        Image(systemName: "gearshape")
            .frame(width: 44, height: 44, alignment: .center)
            .contentShape(Rectangle())
    }
    .pulsumToolbarButton()
    .accessibilityLabel("Settings")
    .accessibilityIdentifier("SettingsButton")
}
```

The `pulsumToolbarButton()` modifier that defines icon rendering and color:
```swift
func pulsumToolbarButton() -> some View {
    self
        .symbolRenderingMode(.monochrome)
        .foregroundStyle(Color.pulsumTextPrimary)
}
```

### Insights tab (Recommendations)
Source: `Packages/PulsumUI/Sources/PulsumUI/CoachView.swift`
- Title: "Today's picks".
- Loading indicator next to header.
- Optional banners: errors, soft timeout, wellbeing notices, consent prompt, Apple Intelligence status warning.
- Recommendation cards list:
  - Title + badge (source badge).
  - Body text.
  - Optional caution chip (orange).
  - "Mark complete" button in glass style.
- Cheer message bubble appears after completion.

### Coach tab (Chat)
Source: `Packages/PulsumUI/Sources/PulsumUI/CoachView.swift`
- Chat log: scrollable list with user and assistant bubbles.
- Bubble alignment: user bubbles right, assistant bubbles left.
- Assistant bubble background: mint green.
- Timestamp under each message (caption2, tertiary).
- Input bar:
  - Multiline `TextField` (1-3 lines).
  - Send button with paperplane icon and glass effect.
  - Close keyboard button appears only when focused.
- Keyboard behavior: `.scrollDismissesKeyboard(.interactively)`.

Exact chat input layout:
```swift
HStack(spacing: PulsumSpacing.sm) {
    TextField("Ask Pulsum anything about your recovery", text: $viewModel.chatInput, axis: .vertical)
        .lineLimit(1...3)
        .font(.pulsumBody)
        .foregroundStyle(Color.pulsumTextPrimary)
        .padding(PulsumSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: PulsumRadius.lg, style: .continuous)
                .fill(Color.pulsumCardWhite.opacity(0.9))
        )
        .overlay {
            RoundedRectangle(cornerRadius: PulsumRadius.lg, style: .continuous)
                .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
        }
        .focused($chatFieldInFocus)
        .disabled(viewModel.isSendingChat)

    Button {
        Task { await viewModel.sendChat() }
    } label: {
        Image(systemName: "paperplane.fill")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(
                viewModel.chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? Color.pulsumTextSecondary
                    : Color.pulsumTextPrimary
            )
            .frame(width: 44, height: 44)
    }
    .glassEffect(
        .regular.tint(
            (viewModel.chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? Color.gray.opacity(0.3)
                : Color.pulsumGreenSoft.opacity(0.7))
        ).interactive()
    )
    .accessibilityLabel("Send coach message")
    .accessibilityIdentifier("CoachSendButton")
    .disabled(viewModel.chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSendingChat)
}
```

### Pulse sheet (Check-in)
Source: `Packages/PulsumUI/Sources/PulsumUI/PulseView.swift`
- Presented as a large sheet (`.presentationDetents([.large])`).
- Background: beige/cream gradient.
- Two main cards: Voice journal and Sliders.
- Voice journal card:
  - Title, optional saved toast, recording control.
  - Three UI states:
    - Idle: green mic button + "Tap to record".
    - Recording: live waveform + progress ring + red stop button.
    - Analyzing: spinner + "Analyzing..." text.
  - Transcript block appears when text is non-empty and includes a "Clear" action.
  - Info bubbles for errors and messages.
  - Haptics on start/stop (UIKit impact).
- Sliders card:
  - Stress, Energy, Sleep Quality sliders (1-7).
  - Value shown in bold with monospaced digits.
  - Descriptive microcopy for each slider.
  - Save button with glass effect; auto-dismiss after save.

Exact voice journal button visuals (idle and recording states):
```swift
// Idle state (start recording)
Button {
    performPulseHaptic(.heavy)
    startAction()
} label: {
    ZStack {
        Circle()
            .fill(Color.pulsumGreenSoft)
            .frame(width: 48, height: 48)
        Image(systemName: "mic.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.white)
    }
}

// Recording state (stop + ring)
ZStack {
    Circle()
        .stroke(Color.gray.opacity(0.2), lineWidth: 3)
        .frame(width: 56, height: 56)
    Circle()
        .trim(from: 0, to: CGFloat(maxDuration - Double(remaining)) / maxDuration)
        .stroke(Color.pulsumGreenSoft, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .frame(width: 56, height: 56)
        .rotationEffect(.degrees(-90))
    Button {
        performPulseHaptic(.medium)
        stopAction()
    } label: {
        ZStack {
            Circle()
                .fill(Color.pulsumError)
                .frame(width: 48, height: 48)
            Image(systemName: "stop.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}
```

Exact slider row design (label, value, slider tint, helper copy):
```swift
VStack(alignment: .leading, spacing: PulsumSpacing.sm) {
    HStack {
        Text(title)
            .font(.pulsumBody.weight(.semibold))
            .foregroundStyle(Color.pulsumTextPrimary)
        Spacer()
        Text("\(Int(value.wrappedValue.rounded()))")
            .font(.pulsumTitle3.weight(.bold))
            .foregroundStyle(Color.pulsumGreenSoft)
            .monospacedDigit()
    }

    Slider(value: value, in: 1...7, step: 1)
        .tint(Color.pulsumGreenSoft)

    Text(description)
        .font(.pulsumCaption)
        .foregroundStyle(Color.pulsumTextSecondary)
        .lineSpacing(2)
}
```

### Settings sheet
Source: `Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift`
Sections are stacked as cards on a beige background. Major sections:
1) Cloud Processing
   - Toggle for GPT-5 phrasing.
   - Secure field for API key.
   - Save key and Test connection buttons (glass).
   - Status badge and descriptive status line.
2) Apple HealthKit
   - Summary row with icon and status.
   - Per-type access rows with status badges.
   - Request authorization button and explanatory copy.
   - Debug status summary with copy and refresh buttons.
3) AI Models
   - Foundation Models status line.
   - Link/button to enable Apple Intelligence (uses Settings or fallback support URL).
4) Safety
   - Call 911 and 988 links.
5) Privacy
   - Privacy policy link.
   - Copy explaining on-device storage.
6) Diagnostics (always visible, and an extra DEBUG panel in debug builds)
   - Toggles for diagnostics config.
   - Export and share diagnostics report.
   - Clear diagnostics action.

Dismiss behavior:
- Close button in nav bar (xmark circle) and escape-key support on supported platforms.
- Title in DEBUG can be tapped 3x to toggle diagnostics panel.

Exact close button design:
```swift
ToolbarItem(placement: .cancellationAction) {
    Button {
        dismiss()
    } label: {
        Image(systemName: "xmark.circle.fill")
            .font(.title3)
            .foregroundStyle(Color.pulsumTextSecondary)
            .symbolRenderingMode(.hierarchical)
    }
    .accessibilityLabel("Close Settings")
}
```

### Score breakdown
Source: `Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownView.swift`
- Summary card with date, score, and top drivers.
- Recommendation logic card (lifts and drags).
- Metric sections: Objective, Subjective, Journal + sentiment.
- Metric cards show value, z-score, baseline, coverage, and notes.
- Contribution badges: green for positive, orange for negative, blue for neutral.
- Empty and error states with icons and guidance copy.

### Onboarding (present but not wired)
Source: `Packages/PulsumUI/Sources/PulsumUI/OnboardingView.swift`
- Three pages in a `TabView`:
  1) Welcome: waveform icon, intro text, Get Started button.
  2) HealthKit: list of required data types with status badges, request/skip buttons.
  3) Ready: confirmation icon and Start Using Pulsum button.
- Progress indicator at top (capsules).
- Uses glass buttons and white cards.

### Safety card overlay
Source: `Packages/PulsumUI/Sources/PulsumUI/SafetyCardView.swift`
- Full-screen dimmed background.
- Centered glass card with warning icon, message, and two actions:
  - Call 911 (red button).
  - "I'm safe" glass button.

### Consent banner
Source: `Packages/PulsumUI/Sources/PulsumUI/ConsentBannerView.swift`
- Appears at top of root view.
- Lock icon, title, explanatory copy, and "Review Settings" button.
- Dismiss button at top right.

### Liquid Glass tab bar (unused in root)
Source: `Packages/PulsumUI/Sources/PulsumUI/LiquidGlassComponents.swift`
- Horizontal bar with glass background and per-tab glass capsules.
- Supports drag-to-select, matched geometry effect, and numeric badges.
- Uses tinted gradient for selected state.
- Not currently wired into `PulsumRootView`.

## Reusable components and patterns
Source references: `Packages/PulsumUI/Sources/PulsumUI`

Key reusable pieces:
- `pulsumCardStyle`: white card with padding, rounded corners, and soft shadow.
- `pulsumFloatingCard`: optional glass card for floating content.
- `InfoBubble`: alert/info row with icon and glass background.
- `SavedToastView`: simple toast used for journal save confirmation.
- `MessageBubble`: info card used across Insights and errors.
- `ChatBubble`: role-based chat bubble with timestamp.
- `BadgeView`: small tag badge for recommendation source.
- `ContributionBadge`: pill badge for metric contribution.
- `GlassEffectStyle`: configurable glass treatment for buttons and small surfaces.
- `LiveWaveformLevels`: ring buffer for waveform visualization.

### Reusable component snippets (verbatim)

InfoBubble (`Packages/PulsumUI/Sources/PulsumUI/PulseView.swift`):
```swift
private struct InfoBubble: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: PulsumSpacing.sm) {
            Image(systemName: icon)
                .font(.pulsumHeadline)
                .foregroundStyle(tint)
            Text(text)
                .font(.pulsumCallout)
                .foregroundStyle(Color.pulsumTextPrimary)
        }
        .padding(PulsumSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: PulsumRadius.md, style: .continuous)
                .fill(.thinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: PulsumRadius.md, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                }
        }
        .shadow(
            color: Color.black.opacity(0.06),
            radius: 8,
            x: 0,
            y: 3
        )
    }
}
```

MessageBubble (`Packages/PulsumUI/Sources/PulsumUI/CoachView.swift`):
```swift
private struct MessageBubble: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: PulsumSpacing.sm) {
            Image(systemName: icon)
                .font(.pulsumHeadline)
                .foregroundStyle(tint)
            Text(text)
                .font(.pulsumCallout)
                .foregroundStyle(Color.pulsumTextPrimary)
        }
        .padding(PulsumSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.pulsumCardWhite)
        .cornerRadius(PulsumRadius.lg)
        .shadow(
            color: PulsumShadow.small.color,
            radius: PulsumShadow.small.radius,
            x: PulsumShadow.small.x,
            y: PulsumShadow.small.y
        )
    }
}
```

ConsentBannerView (`Packages/PulsumUI/Sources/PulsumUI/ConsentBannerView.swift`):
```swift
struct ConsentBannerView: View {
    let openSettings: () -> Void
    let dismiss: () -> Void

    private let bannerCopy = "Pulsum can optionally use GPT‑5 to phrase brief coaching text. If you allow cloud processing, Pulsum sends only minimized context (no journals, no raw health data, no identifiers). PII is redacted. You can turn this off anytime in Settings ▸ Cloud Processing."

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.pulsumTitle3)
                    .foregroundStyle(Color.pulsumBlueSoft)
                    .symbolRenderingMode(.hierarchical)
                Spacer()
                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.pulsumTextSecondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .accessibilityLabel("Dismiss cloud processing banner")
            }

            Text("Cloud processing is optional")
                .font(.pulsumHeadline)
                .foregroundStyle(Color.pulsumTextPrimary)

            Text(bannerCopy)
                .font(.pulsumCallout)
                .foregroundStyle(Color.pulsumTextSecondary)
                .lineSpacing(4)

            Button(action: openSettings) {
                Text("Review Settings")
                    .font(.pulsumCallout.weight(.semibold))
                    .foregroundStyle(Color.pulsumTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PulsumSpacing.sm)
            }
            .glassEffect(.regular.tint(Color.pulsumBlueSoft.opacity(0.7)).interactive())
        }
        .padding(PulsumSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: PulsumRadius.xl, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: PulsumRadius.xl, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
        }
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 16,
            x: 0,
            y: 8
        )
    }
}
```

Wellbeing cards (`Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift`):
```swift
struct WellbeingScoreLoadingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                Text("Wellbeing score")
                    .font(.pulsumHeadline)
                    .foregroundStyle(Color.pulsumTextPrimary)
                Text("Calculated nightly from your data")
                    .font(.pulsumCaption)
                    .foregroundStyle(Color.pulsumTextSecondary)
            }

            HStack(alignment: .center, spacing: PulsumSpacing.lg) {
                VStack(alignment: .leading, spacing: PulsumSpacing.xs) {
                    HStack(spacing: PulsumSpacing.sm) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.pulsumGreenSoft)
                        Text("Calculating...")
                            .font(.pulsumTitle)
                            .foregroundStyle(Color.pulsumTextSecondary)
                    }
                    Text("Complete your first Pulse check-in")
                        .font(.pulsumCallout)
                        .foregroundStyle(Color.pulsumTextSecondary)
                }
                Spacer()
            }

            Text("Your score will appear here after your first nightly sync. Record a Pulse check-in to begin tracking your wellbeing.")
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumTextSecondary)
                .lineSpacing(2)
        }
        .padding(PulsumSpacing.lg)
        .background(Color.pulsumCardWhite)
        .cornerRadius(PulsumRadius.xl)
        .shadow(
            color: PulsumShadow.medium.color,
            radius: PulsumShadow.medium.radius,
            x: PulsumShadow.medium.x,
            y: PulsumShadow.medium.y
        )
    }
}

struct WellbeingPlaceholderCard: View {
    private let detail = "Health data may take a moment on first run. We'll update once your first sync completes."

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                Text("Wellbeing score")
                    .font(.pulsumHeadline)
                Text("Warming up")
                    .font(.pulsumTitle3)
                    .foregroundStyle(Color.pulsumTextPrimary)
                Text(detail)
                    .font(.pulsumCallout)
                    .foregroundStyle(Color.pulsumTextSecondary)
                    .lineSpacing(2)
            }
        }
        .padding(PulsumSpacing.lg)
        .background(Color.pulsumCardWhite)
        .cornerRadius(PulsumRadius.xl)
        .shadow(
            color: PulsumShadow.medium.color,
            radius: PulsumShadow.medium.radius,
            x: PulsumShadow.medium.x,
            y: PulsumShadow.medium.y
        )
    }
}

struct WellbeingNoDataCard: View {
    let reason: WellbeingNoDataReason
    var requestAccess: (() -> Void)?

    private var copy: (title: String, detail: String) {
        switch reason {
        case .healthDataUnavailable:
            return ("Health data unavailable",
                    "Health data is not available on this device. Try again on a device with Health access.")
        case .permissionsDeniedOrPending:
            return ("Health access needed",
                    "Pulsum needs permission to read Heart Rate Variability, Heart Rate, Resting Heart Rate, Respiratory Rate, Steps, and Sleep to compute your score.")
        case .insufficientSamples:
            return ("Waiting for data",
                    "We don't have enough recent Health data yet. Record a Pulse check-in or allow some time for HealthKit to sync.")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                Text("Wellbeing score")
                    .font(.pulsumHeadline)
                Text(copy.title)
                    .font(.pulsumTitle3)
                    .foregroundStyle(Color.pulsumTextPrimary)
                Text(copy.detail)
                    .font(.pulsumCallout)
                    .foregroundStyle(Color.pulsumTextSecondary)
                    .lineSpacing(2)
            }

            if let requestAccess, reason == .permissionsDeniedOrPending {
                Button {
                    requestAccess()
                } label: {
                    Text("Request Health Data Access")
                        .font(.pulsumCallout.weight(.semibold))
                        .foregroundStyle(Color.pulsumTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PulsumSpacing.sm)
                }
                .glassEffect(.regular.tint(Color.pulsumPinkSoft.opacity(0.6)).interactive())
            }
        }
        .padding(PulsumSpacing.lg)
        .background(Color.pulsumCardWhite)
        .cornerRadius(PulsumRadius.xl)
        .shadow(
            color: PulsumShadow.medium.color,
            radius: PulsumShadow.medium.radius,
            x: PulsumShadow.medium.x,
            y: PulsumShadow.medium.y
        )
    }
}

struct WellbeingErrorCard: View {
    let message: String
    var retry: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                Text("Wellbeing score")
                    .font(.pulsumHeadline)
                Text("Something went wrong")
                    .font(.pulsumTitle3)
                    .foregroundStyle(Color.pulsumWarning)
                Text(message)
                    .font(.pulsumCallout)
                    .foregroundStyle(Color.pulsumTextSecondary)
                    .lineSpacing(2)
            }

            if let retry {
                Button {
                    retry()
                } label: {
                    Text("Try again")
                        .font(.pulsumCallout.weight(.semibold))
                        .foregroundStyle(Color.pulsumTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PulsumSpacing.sm)
                }
                .glassEffect(.regular.tint(Color.pulsumBlueSoft.opacity(0.6)).interactive())
            }
        }
        .padding(PulsumSpacing.lg)
        .background(Color.pulsumCardWhite)
        .cornerRadius(PulsumRadius.xl)
        .shadow(
            color: PulsumShadow.medium.color,
            radius: PulsumShadow.medium.radius,
            x: PulsumShadow.medium.x,
            y: PulsumShadow.medium.y
        )
    }
}

struct WellbeingScoreCard: View {
    let score: Double

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                Text("Wellbeing score")
                    .font(.pulsumHeadline)
                    .foregroundStyle(Color.pulsumTextPrimary)
                Text("Calculated nightly from your data")
                    .font(.pulsumCaption)
                    .foregroundStyle(Color.pulsumTextSecondary)
            }

            HStack(alignment: .center, spacing: PulsumSpacing.lg) {
                VStack(alignment: .leading, spacing: PulsumSpacing.xs) {
                    Text(score.formatted(.number.precision(.fractionLength(2))))
                        .font(.pulsumDataLarge)
                        .foregroundStyle(scoreColor)
                    Text(interpretedScore)
                        .font(.pulsumCallout)
                        .foregroundStyle(Color.pulsumTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.pulsumTitle3)
                    .foregroundStyle(Color.pulsumTextTertiary)
            }

            Text("Tap for the full breakdown, including objective recovery signals and your subjective check-in inputs.")
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumTextSecondary)
                .lineSpacing(2)
        }
        .padding(PulsumSpacing.lg)
        .background(Color.pulsumCardWhite)
        .cornerRadius(PulsumRadius.xl)
        .shadow(
            color: PulsumShadow.medium.color,
            radius: PulsumShadow.medium.radius,
            x: PulsumShadow.medium.x,
            y: PulsumShadow.medium.y
        )
    }
}
```

## Motion, interaction, and haptics
- Primary animations use `pulsumStandard` (spring).
- Glass buttons scale slightly when pressed (interactive style).
- Pulse recording uses haptics on start/stop.
- Transitions: opacity, move-from-top for banners, and scale for chat controls.

## Accessibility and QA hooks
Source: `Packages/PulsumUI/Sources/PulsumUI`, `PulsumUITests/PulsumUITestCase.swift`
- Accessibility identifiers for key UI elements (Pulse button, settings, voice journal controls, transcript, debug controls).
- Explicit accessibility labels and hints for recording controls and settings.
- Chat input focus control uses `@FocusState` and a close keyboard button.
- Dynamic Type is not supported yet (fonts are fixed sizes).
- Copy strings are hard-coded (no localization files present).

## Visual assets inventory (non-text)
The following visual assets exist in the repo; they were not parsed as text.

| Path | Type | Size (bytes) |
| --- | --- | --- |
| `ios app mockup.png` | png | 2821699 |
| `ios support documents/Landmarks_ Refining the system provided Liquid Glass effect in toolbars _ Apple Developer Documentation.pdf` | pdf | 1398959 |
| `ios support documents/Landmarks_ Building an app with Liquid Glass _ Apple Developer Documentation.pdf` | pdf | 7313354 |
| `ios support documents/Improving the safety of generative model output _ Apple Developer Documentation.pdf` | pdf | 1137316 |
| `ios support documents/Liquid Glass _ Apple Developer Documentation.pdf` | pdf | 4276716 |
| `ios support documents/Support languages and locales with Foundation Models _ Apple Developer Documentation.pdf` | pdf | 388923 |
| `ios support documents/Landmarks_ Displaying custom activity badges _ Apple Developer Documentation.pdf` | pdf | 1873402 |
| `ios support documents/Adopting Liquid Glass _ Apple Developer Documentation.pdf` | pdf | 4863584 |
| `ios support documents/aGenerating content and performing tasks with Foundation Models _ Apple Developer Documentation.pdf` | pdf | 720230 |
| `ios support documents/Generating content and performing tasks with Foundation Models _ Apple Developer Documentation.pdf` | pdf | 721092 |
| `ios support documents/Adding intelligent app features with generative models _ Apple Developer Documentation.pdf` | pdf | 101354 |
| `ios support documents/iOS & iPadOS 26 Release Notes _ Apple Developer Documentation.pdf` | pdf | 1210570 |
| `ios support documents/SystemLanguageModel _ Apple Developer Documentation.pdf` | pdf | 351666 |
| `ios support documents/Foundation Models _ Apple Developer Documentation.pdf` | pdf | 790023 |
| `ios support documents/Landmarks_ Applying a background extension effect _ Apple Developer Documentation.pdf` | pdf | 2098656 |
| `ios support documents/Landmarks_ Extending horizontal scrolling under a sidebar or inspector _ Apple Developer Documentation.pdf` | pdf | 1632595 |
| `a-practical-guide-to-building-agents.pdf` | pdf | 7335065 |
| `infinity_blubs_copy.splineswift` | splineswift | 272828 |
| `main_screen.PNG` | png | 1106195 |
| `Docs/a-practical-guide-to-building-with-gpt-5.pdf` | pdf | 12010712 |
| `insights.PNG` | png | 1287335 |
| `iconnew.png` | png | 1003595 |
| `logo.jpg` | jpg | 152344 |
| `logo2.png` | png | 585439 |
| `mainanimation.usdz` | usdz | 47388 |
| `streak_low_poly_copy.splineswift` | splineswift | 49425 |
| `checkin.PNG` | png | 3611007 |
| `iconlogo.png` | png | 1075847 |
| `main.gif` | gif | 21811312 |
| `MAINDESIGN.png` | png | 3873254 |
| `ChatGPT for engineers - Resource _ OpenAI Academy.pdf` | pdf | 3977697 |
| `coach.PNG` | png | 923693 |
| `Pulsum/Assets.xcassets/AppIcon.appiconset/iconnew.png` | png | 1003595 |
| `Pulsum/Assets.xcassets/AppIcon.appiconset/iconnew 1.png` | png | 1003595 |
| `Pulsum/Assets.xcassets/AppIcon.appiconset/iconnew 2.png` | png | 1003595 |

Asset notes:
- App icon variants are defined in `Pulsum/Assets.xcassets/AppIcon.appiconset/Contents.json`.
- Accent color is not defined in `Pulsum/Assets.xcassets/AccentColor.colorset/Contents.json`.
- Spline assets exist but are not currently used in the SwiftUI views.

## Design deltas and known gaps (observed)
- Spline hero background is specified in docs but not wired in UI; the root background is a gradient only.
  - Spec references: `instructions.md`, `Docs/architecture copy.md`.
  - Current UI: `Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift`.
- Dynamic Type is not supported because fonts use fixed sizes in `PulsumDesignSystem.swift`.
- Localization is not implemented; all user-facing copy is hard-coded in views and view models.
- No custom scroll-driven toolbar fade or hide is implemented; navigation bars use `.toolbarBackground(.automatic, for: .navigationBar)` and default system behavior.
- `OnboardingView` exists but is not presented by `PulsumRootView`.
- `LiquidGlassTabBar` component exists but is not used by the root `TabView`.

## Reuse guidance for a new app
1) Copy the design system and glass effects:
   - `Packages/PulsumUI/Sources/PulsumUI/PulsumDesignSystem.swift`
   - `Packages/PulsumUI/Sources/PulsumUI/GlassEffect.swift`
2) Replicate the layout skeleton:
   - Root `ZStack` with gradient background.
   - `TabView` + `NavigationStack` per tab.
   - Sheets for secondary flows.
3) Reuse card patterns:
   - `pulsumCardStyle` for standard cards.
   - Glass buttons for primary actions.
   - Metric and message bubble styles for status content.
4) Keep the width cap (520) for text-heavy screens to improve readability on iPad.
5) If you want the full Liquid Glass hero, wire Spline as described in docs or replace with your own 3D/gradient asset.
