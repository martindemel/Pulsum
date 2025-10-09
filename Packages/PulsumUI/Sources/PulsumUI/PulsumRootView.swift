import SwiftUI
import Observation
import Foundation
#if canImport(SplineRuntime)
import SplineRuntime
#endif

public struct PulsumRootView: View {
    @State private var viewModel = AppViewModel()

    public init() {}

    public var body: some View {
        ZStack {
            MainContainerView(viewModel: viewModel)
                .blur(radius: viewModel.startupState == .ready ? 0 : 6)
                .allowsHitTesting(viewModel.startupState == .ready)
                .animation(.easeInOut(duration: 0.25), value: viewModel.startupState)

            if viewModel.startupState != .ready {
                overlay(for: viewModel.startupState)
                    .transition(.opacity)
            }
        }
        .task { viewModel.start() }
        .onChange(of: viewModel.startupState) { _, newValue in
            print("[PulsumRootView] startupState ->", String(describing: newValue))
        }
    }

    @ViewBuilder
    private func overlay(for state: AppViewModel.StartupState) -> some View {
        switch state {
        case .idle, .loading:
            Color.black.opacity(0.15)
                .ignoresSafeArea()
                .overlay(alignment: .center) {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("Preparing Pulsum...")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
        case .failed(let message):
            Color.black.opacity(0.15)
                .ignoresSafeArea()
                .overlay(alignment: .center) {
                    failureOverlay(message: message)
                }
        case .ready:
            EmptyView()
        }
    }

    private func failureOverlay(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.orange)
            Text("Something went wrong")
                .font(.title2)
                .bold()
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Retry") {
                viewModel.retryStartup()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct MainContainerView: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        ZStack {
            backgroundLayer

            TabView(selection: $viewModel.selectedTab) {
                mainTab
                    .tag(AppViewModel.Tab.main)
                insightsTab
                    .tag(AppViewModel.Tab.insights)
                coachTab
                    .tag(AppViewModel.Tab.coach)
            }
            .tabViewStyle(.automatic)
        }
        .animation(.pulsumStandard, value: viewModel.selectedTab)
        .safeAreaInset(edge: .top, spacing: 0) {
            topOverlay
        }
        .sheet(isPresented: $viewModel.isPresentingPulse) {
            PulseView(
                viewModel: viewModel.pulseViewModel,
                isPresented: $viewModel.isPresentingPulse
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: $viewModel.isPresentingSettings) {
            SettingsScreen(
                viewModel: viewModel.settingsViewModel,
                wellbeingScore: viewModel.coachViewModel.wellbeingScore
            )
        }
        .overlay {
            if viewModel.isShowingSafetyCard {
                SafetyCardView(message: viewModel.safetyMessage ?? "If in danger, call 911") {
                    viewModel.dismissSafetyCard()
                }
            }
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.pulsumBackgroundBeige,
                    Color.pulsumBackgroundCream
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            AnimatedSplineBackgroundView()
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var mainTab: some View {
        VStack {
            Spacer()
            GlassEffectContainer {
                CoachShortcutButton {
                    viewModel.triggerCoachFocus()
                }
            }
            .padding(.bottom, PulsumSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.trailing, 24)
        .tabItem {
            Image(systemName: AppViewModel.Tab.main.iconName)
            Text(AppViewModel.Tab.main.displayName)
        }
    }

    @ViewBuilder
    private var insightsTab: some View {
        InsightsScreen(
            viewModel: viewModel.coachViewModel,
            foundationStatus: viewModel.orchestrator?.foundationModelsStatus ?? "",
            consentGranted: viewModel.consentGranted,
            triggerSettings: { viewModel.isPresentingSettings = true }
        )
        .tabItem {
            Image(systemName: AppViewModel.Tab.insights.iconName)
            Text(AppViewModel.Tab.insights.displayName)
        }
    }

    @ViewBuilder
    private var coachTab: some View {
        CoachScreen(
            viewModel: viewModel.coachViewModel,
            showChatInput: true
        )
        .tabItem {
            Image(systemName: AppViewModel.Tab.coach.iconName)
            Text(AppViewModel.Tab.coach.displayName)
        }
    }

    private var topOverlay: some View {
        VStack(spacing: PulsumSpacing.md) {
            HeaderView(viewModel: viewModel)

            if viewModel.showConsentBanner {
                ConsentBannerView(
                    openSettings: { viewModel.isPresentingSettings = true },
                    dismiss: { viewModel.dismissConsentBanner() }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, PulsumSpacing.sm)
        .padding(.bottom, PulsumSpacing.md)
        .background(
            Color.clear
                .background(.ultraThinMaterial)
                .mask(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 10)
                .padding(.horizontal, 8)
        )
        .padding(.horizontal, 12)
    }
}

struct HeaderView: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        HStack {
            Button {
                viewModel.isPresentingPulse = true
            } label: {
                Label("Pulse", systemImage: "waveform.path.ecg")
                    .font(.headline)
                    .foregroundStyle(Color.pulsumTextPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .glassEffect(.regular.tint(Color.white.opacity(0.3)).interactive())

            Spacer()

            Button {
                viewModel.isPresentingSettings = true
            } label: {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.pulsumTextPrimary)
                    .padding(4)
            }
            .glassEffect(.regular.tint(Color.white.opacity(0.3)).interactive())
            .accessibilityLabel("Open settings")
        }
    }
}

// DashboardView removed - MainView now only shows Spline animation
// Wellbeing score moved to SettingsView for backend transparency

struct CoachShortcutButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "sparkles")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.pulsumTextPrimary)
                .frame(width: 56, height: 56)
        }
        .glassEffect(.regular.tint(Color.pulsumBlueSoft.opacity(0.7)).interactive())
        .shadow(
            color: Color.pulsumBlueSoft.opacity(0.3),
            radius: 12,
            x: 0,
            y: 6
        )
        .accessibilityLabel("Jump to coach chat")
    }
}

struct AnimatedSplineBackgroundView: View {
    private let cloudURL = URL(string: "https://build.spline.design/Wp1o27Ds7nsPAHPrlN6K/scene.splineswift")
    private let localURL = Bundle.main.url(forResource: "infinity_blubs_copy", withExtension: "splineswift")

    var body: some View {
        splineScene
            .ignoresSafeArea()
    }

    private var fallbackGradient: some View {
        LinearGradient(
            colors: [
                Color.pulsumBackgroundBeige,
                Color.pulsumBackgroundCream
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private var splineScene: some View {
        #if canImport(SplineRuntime)
        if let url = localURL ?? cloudURL { // Try local file first, then cloud
            ZStack {
                Color.pulsumBackgroundBeige // Background color while loading

                SplineView(sceneFileURL: url)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(1.0) // Adjust this to zoom in/out (try 0.5, 0.8, 1.2, etc.)
                    .offset(x: 0, y: 0) // Adjust position (x: horizontal, y: vertical)
                    .allowsHitTesting(false) // Prevents interaction with Spline (let UI controls work)
            }
            .ignoresSafeArea()
        } else {
            fallbackGradient
        }
        #else
        fallbackGradient
        #endif
    }
}

// WellbeingScoreView moved to SettingsView only - not displayed on MainView
