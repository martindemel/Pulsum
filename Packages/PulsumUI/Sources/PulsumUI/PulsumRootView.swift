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
    @GestureState private var horizontalDrag: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let bottomInset = proxy.safeAreaInsets.bottom

            ZStack {
                backgroundLayer
                contentLayer
            }
            .animation(.pulsumStandard, value: viewModel.selectedTab)
            .safeAreaInset(edge: .top, spacing: 0) {
                topOverlay
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomControls(extraPadding: bottomInset == 0 ? PulsumSpacing.sm : 0)
            }
            .sheet(isPresented: $viewModel.isPresentingPulse) {
                PulseView(viewModel: viewModel.pulseViewModel,
                          isPresented: $viewModel.isPresentingPulse)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $viewModel.isPresentingSettings) {
                SettingsScreen(viewModel: viewModel.settingsViewModel,
                              wellbeingScore: viewModel.coachViewModel.wellbeingScore)
            }
            .overlay {
                if viewModel.isShowingSafetyCard {
                    SafetyCardView(message: viewModel.safetyMessage ?? "If in danger, call 911") {
                        viewModel.dismissSafetyCard()
                    }
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
    private var contentLayer: some View {
        Group {
            switch viewModel.selectedTab {
            case .main:
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
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 1.05).combined(with: .opacity)
                ))

            case .coach:
                CoachScreen(viewModel: viewModel.coachViewModel,
                            foundationStatus: viewModel.orchestrator?.foundationModelsStatus ?? "",
                            consentGranted: viewModel.consentGranted,
                            triggerSettings: { viewModel.isPresentingSettings = true },
                            showChatInput: false)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 1.05).combined(with: .opacity)
                    ))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scaleEffect(1 + min(abs(horizontalDrag) / 800, 0.03))
        .gesture(
            DragGesture(minimumDistance: 30)
                .updating($horizontalDrag) { value, state, _ in
                    state = value.translation.width
                }
                .onEnded { value in
                    let horizontalSwipe = value.translation.width

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if horizontalSwipe < -50 && viewModel.selectedTab == .main {
                            // Swipe left: Main → Coach
                            viewModel.selectedTab = .coach
                        } else if horizontalSwipe > 50 && viewModel.selectedTab == .coach {
                            // Swipe right: Coach → Main
                            viewModel.selectedTab = .main
                        }
                    }
                }
        )
    }

    private var topOverlay: some View {
        VStack(spacing: PulsumSpacing.md) {
            HeaderView(viewModel: viewModel)

            if viewModel.showConsentBanner {
                ConsentBannerView(openSettings: { viewModel.isPresentingSettings = true },
                                   dismiss: { viewModel.dismissConsentBanner() })
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

    private func bottomControls(extraPadding: CGFloat) -> some View {
        GlassEffectContainer {
            HStack(alignment: .bottom, spacing: PulsumSpacing.md) {
                LiquidGlassTabBar(
                    selectedTab: Binding(
                        get: { viewModel.selectedTab == .main ? 0 : 1 },
                        set: { viewModel.selectedTab = $0 == 0 ? .main : .coach }
                    ),
                    tabs: [
                        .init(icon: "gauge.with.needle", title: "Main"),
                        .init(icon: "text.bubble", title: "Coach")
                    ]
                )
                .scaleEffect(glassZoomScale)

                if viewModel.selectedTab == .coach {
                    Spacer(minLength: PulsumSpacing.md)

                    ChatInputView(viewModel: viewModel.coachViewModel)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .background {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                                }
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, max(8, extraPadding))
    }
}

extension MainContainerView {
    private var glassZoomScale: CGFloat {
        let clamped = max(min(horizontalDrag / 160, 1), -1)
        return 1 + abs(clamped) * 0.06
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
