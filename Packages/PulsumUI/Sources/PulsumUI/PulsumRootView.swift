import SwiftUI
import Observation
import Foundation
import PulsumAgents
import PulsumTypes

public struct PulsumRootView: View {
    @State private var viewModel: AppViewModel

    public init() {
        _viewModel = State(initialValue: AppViewModel())
    }

    init(viewModel: AppViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            MainContainerView(viewModel: viewModel)
                .blur(radius: viewModel.startupState == .ready ? 0 : 6)
                .allowsHitTesting(viewModel.startupState == .ready)
                .animation(AppRuntimeConfig.disableAnimations ? nil : .easeInOut(duration: 0.25),
                           value: viewModel.startupState)

            if viewModel.startupState != .ready {
                overlay(for: viewModel.startupState)
                    .transition(.opacity)
            }
        }
        .task { viewModel.start() }
        .onChange(of: viewModel.startupState) { _, newValue in
            let label: String
            switch newValue {
            case .idle: label = "idle"
            case .loading: label = "loading"
            case .ready: label = "ready"
            case .failed: label = "failed"
            case .blocked: label = "blocked"
            }
            Diagnostics.log(level: .info,
                            category: .ui,
                            name: "ui.startupState.changed",
                            fields: [
                                "state": .safeString(.stage(label, allowed: ["idle", "loading", "ready", "failed", "blocked"]))
                            ])
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
        case .blocked(let message):
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .overlay(alignment: .center) {
                    blockedOverlay(message: message)
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

    private func blockedOverlay(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.red)
            Text("Storage Not Secured")
                .font(.title2)
                .bold()
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Check Again") {
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
    @Namespace private var transitionNamespace
    @State private var isUITestPresentingSettings = false

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
        .sheet(isPresented: $viewModel.isPresentingPulse) {
            PulseView(
                viewModel: viewModel.pulseViewModel,
                isPresented: $viewModel.isPresentingPulse
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: settingsSheetBinding) {
            SettingsScreen(
                viewModel: viewModel.settingsViewModel,
                wellbeingState: viewModel.coachViewModel.wellbeingState,
                snapshotKind: viewModel.coachViewModel.snapshotKind
            )
        }
        .overlay {
            if viewModel.isShowingSafetyCard {
                SafetyCardView(message: viewModel.safetyMessage ?? "If in danger, call 911") {
                    viewModel.dismissSafetyCard()
                }
            }
        }
        .overlay {
            if viewModel.showConsentBanner {
                VStack {
                    ConsentBannerView(
                        openSettings: { presentSettings() },
                        dismiss: { viewModel.dismissConsentBanner() }
                    )
                    .padding(.horizontal, PulsumSpacing.lg)
                    .padding(.top, PulsumSpacing.md)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
            }
        }
        .overlay(alignment: .topLeading) {
            if AppRuntimeConfig.settingsHookEnabled {
                Button {
                    presentSettings()
                } label: {
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .contentShape(Rectangle())
                .accessibilityIdentifier("SettingsTestHookButton")
                .accessibilityElement()
            }
        }
    }

    private var settingsSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isPresentingSettings || isUITestPresentingSettings },
            set: { newValue in
                viewModel.isPresentingSettings = newValue
                isUITestPresentingSettings = newValue
            }
        )
    }

    @MainActor
    private func presentSettings() {
        viewModel.isPresentingSettings = true
        if AppRuntimeConfig.settingsHookEnabled {
            isUITestPresentingSettings = true
        }
    }

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [
                Color.pulsumBackgroundBeige,
                Color.pulsumBackgroundCream
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var wellbeingCard: some View {
        switch viewModel.coachViewModel.wellbeingState {
        case let .ready(score, _):
            if let detailViewModel = viewModel.settingsViewModel.makeScoreBreakdownViewModel() {
                NavigationLink {
                    ScoreBreakdownScreen(viewModel: detailViewModel)
                } label: {
                    WellbeingScoreCard(score: score)
                }
                .buttonStyle(.plain)
            } else {
                WellbeingScoreCard(score: score)
            }
        case .loading:
            WellbeingScoreLoadingCard()
        case let .noData(reason):
            if viewModel.coachViewModel.snapshotKind == .placeholder, reason == .insufficientSamples {
                WellbeingPlaceholderCard()
            } else {
                WellbeingNoDataCard(reason: reason) {
                    Task { await viewModel.settingsViewModel.requestHealthKitAuthorization() }
                }
            }
        case let .error(message):
            WellbeingErrorCard(message: message) {
                viewModel.coachViewModel.reloadIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var mainTab: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: PulsumSpacing.xl) {
                    // Wellbeing Score Card
                    wellbeingCard
                }
                .frame(maxWidth: 520)
                .padding(.horizontal, PulsumSpacing.lg)
                .padding(.top, PulsumSpacing.lg)
                .padding(.bottom, PulsumSpacing.xxxl)
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { viewModel.isPresentingPulse = true } label: {
                        Label("Pulse", systemImage: "waveform.path.ecg").labelStyle(.titleAndIcon)
                    }
                    .pulsumToolbarButton()
                    .accessibilityIdentifier("PulseButton")
                    .accessibilityHidden(viewModel.selectedTab != .main)
                    .matchedTransitionSource(id: "pulseButton", in: transitionNamespace)
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
                    .accessibilityElement()
                    .accessibilityHidden(viewModel.selectedTab != .main)
                }
            }
            .toolbarBackground(.automatic, for: .navigationBar)
        }
        .tabItem {
            Image(systemName: AppViewModel.Tab.main.iconName)
            Text(AppViewModel.Tab.main.displayName)
        }
    }

    @ViewBuilder
    private var insightsTab: some View {
        NavigationStack {
            InsightsScreen(
                viewModel: viewModel.coachViewModel,
                foundationStatus: viewModel.orchestrator?.foundationModelsStatus ?? "",
                consentGranted: viewModel.consentGranted,
                triggerSettings: { presentSettings() }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.isPresentingPulse = true
                    } label: {
                        Label("Pulse", systemImage: "waveform.path.ecg")
                            .labelStyle(.titleAndIcon)
                    }
                    .pulsumToolbarButton()
                    .accessibilityIdentifier("PulseButton")
                    .accessibilityHidden(viewModel.selectedTab != .insights)
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
                    .accessibilityElement()
                    .accessibilityHidden(viewModel.selectedTab != .insights)
                }
            }
            .toolbarBackground(.automatic, for: .navigationBar)
        }
        .tabItem {
            Image(systemName: AppViewModel.Tab.insights.iconName)
            Text(AppViewModel.Tab.insights.displayName)
        }
    }

    @ViewBuilder
    private var coachTab: some View {
        NavigationStack {
            CoachScreen(
                viewModel: viewModel.coachViewModel,
                showChatInput: true
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.isPresentingPulse = true
                    } label: {
                        Label("Pulse", systemImage: "waveform.path.ecg")
                            .labelStyle(.titleAndIcon)
                    }
                    .pulsumToolbarButton()
                    .accessibilityIdentifier("PulseButton")
                    .accessibilityHidden(viewModel.selectedTab != .coach)
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
                    .accessibilityElement()
                    .accessibilityHidden(viewModel.selectedTab != .coach)
                }
            }
            .toolbarBackground(.automatic, for: .navigationBar)
        }
        .tabItem {
            Image(systemName: AppViewModel.Tab.coach.iconName)
            Text(AppViewModel.Tab.coach.displayName)
        }
    }

}
