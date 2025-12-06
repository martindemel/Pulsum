import SwiftUI
import Observation
import PulsumAgents
#if canImport(UIKit)
import UIKit
#endif

struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Bindable var viewModel: SettingsViewModel
    let wellbeingState: WellbeingScoreState

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: PulsumSpacing.lg) {
                    // Wellbeing Score Display (moved from MainView)
                    wellbeingScoreSection

                    // Cloud Processing Section
                    VStack(alignment: .leading, spacing: PulsumSpacing.md) {
                        Text("Cloud Processing")
                            .font(.pulsumHeadline)
                            .foregroundStyle(Color.pulsumTextPrimary)
                            .padding(.horizontal, PulsumSpacing.lg)

                        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
                            Toggle(isOn: Binding(
                                get: { viewModel.consentGranted },
                                set: { viewModel.toggleConsent($0) }
                            )) {
                                VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                                    Text("Use GPT-5 phrasing")
                                        .font(.pulsumBody)
                                        .foregroundStyle(Color.pulsumTextPrimary)
                                    Text("Pulsum only sends minimized context (no journals, no identifiers, no raw health samples). Turn this off anytime.")
                                        .font(.pulsumCaption)
                                        .foregroundStyle(Color.pulsumTextSecondary)
                                        .lineSpacing(2)
                                }
                            }
                            .tint(Color.pulsumGreenSoft)

                            if let updated = relativeDate(for: viewModel.lastConsentUpdated) {
                                Text("Updated \(updated)")
                                    .font(.pulsumFootnote)
                                    .foregroundStyle(Color.pulsumTextTertiary)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: PulsumSpacing.sm) {
                                VStack(alignment: .leading, spacing: PulsumSpacing.xs) {
                                    Text("GPT-5 API Key")
                                        .font(.pulsumCallout.weight(.semibold))
                                        .foregroundStyle(Color.pulsumTextPrimary)
                                    SecureField("sk-...", text: $viewModel.gptAPIKeyDraft)
                                        .textFieldStyle(.roundedBorder)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .font(.pulsumBody)
                                        .foregroundStyle(Color.pulsumTextPrimary)
                                        .accessibilityIdentifier("CloudAPIKeyField")
                                }

                                HStack(spacing: PulsumSpacing.sm) {
                                    Button {
                                        Task { await viewModel.saveAPIKey(viewModel.gptAPIKeyDraft) }
                                    } label: {
                                        Text("Save Key")
                                            .font(.pulsumCallout.weight(.semibold))
                                            .foregroundStyle(Color.pulsumTextPrimary)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .glassEffect(.regular.tint(Color.pulsumGreenSoft.opacity(0.6)).interactive())
                                    .accessibilityIdentifier("CloudAPISaveButton")
                                    .disabled(viewModel.gptAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isTestingAPIKey)

                                    Button {
                                        Task { await viewModel.testCurrentAPIKey() }
                                    } label: {
                                        if viewModel.isTestingAPIKey {
                                            ProgressView()
                                                .progressViewStyle(.circular)
                                                .tint(Color.pulsumTextPrimary)
                                                .frame(maxWidth: .infinity)
                                        } else {
                                            Text("Test Connection")
                                                .font(.pulsumCallout.weight(.semibold))
                                                .foregroundStyle(Color.pulsumTextPrimary)
                                                .frame(maxWidth: .infinity)
                                        }
                                    }
                                    .glassEffect(.regular.tint(Color.pulsumBlueSoft.opacity(0.5)).interactive())
                                    .disabled(viewModel.isTestingAPIKey)
                                    .accessibilityIdentifier("CloudAPITestButton")
                                }

                                HStack(spacing: PulsumSpacing.sm) {
                                    gptStatusBadge(isWorking: viewModel.isGPTAPIWorking,
                                                   status: viewModel.gptAPIStatus)
                                    Text(viewModel.gptAPIStatus)
                                        .font(.pulsumFootnote)
                                        .foregroundStyle(Color.pulsumTextSecondary)
                                        .lineSpacing(2)
                                        .accessibilityIdentifier("CloudAPIStatusText")
                                }
                            }
                        }
                        .padding(PulsumSpacing.lg)
                        .background(Color.pulsumCardWhite)
                        .cornerRadius(PulsumRadius.xl)
                        .shadow(
                            color: PulsumShadow.small.color,
                            radius: PulsumShadow.small.radius,
                            x: PulsumShadow.small.x,
                            y: PulsumShadow.small.y
                        )
                    }

                    // HealthKit Section
                    VStack(alignment: .leading, spacing: PulsumSpacing.md) {
                        Text("Apple HealthKit")
                            .font(.pulsumHeadline)
                            .foregroundStyle(Color.pulsumTextPrimary)
                            .padding(.horizontal, PulsumSpacing.lg)

                        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
                            HStack(alignment: .top, spacing: PulsumSpacing.sm) {
                                Image(systemName: "heart.text.square.fill")
                                    .font(.pulsumTitle3)
                                    .foregroundStyle(Color.pulsumPinkSoft)
                                    .symbolRenderingMode(.hierarchical)
                                VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                                    Text("Health Data Access")
                                        .font(.pulsumHeadline)
                                        .foregroundStyle(Color.pulsumTextPrimary)
                                    Text(viewModel.healthKitSummary)
                                        .font(.pulsumCallout)
                                        .foregroundStyle(Color.pulsumTextSecondary)
                                        .lineSpacing(2)
                                        .accessibilityIdentifier("HealthAccessSummaryLabel")
                                }
                            }

                            if let detail = viewModel.missingHealthKitDetail {
                                Text(detail)
                                    .font(.pulsumCaption)
                                    .foregroundStyle(Color.pulsumTextSecondary)
                                    .padding(.horizontal, PulsumSpacing.xs)
                                    .padding(.vertical, PulsumSpacing.xxs)
                                    .background(Color.pulsumBackgroundCream.opacity(0.6))
                                    .cornerRadius(PulsumRadius.sm)
                                    .accessibilityIdentifier("HealthAccessMissingLabel")
                            }

                            if viewModel.showHealthKitUnavailableBanner {
                                HStack(spacing: PulsumSpacing.xs) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.pulsumCaption)
                                        .foregroundStyle(Color.pulsumWarning)
                                    Text("Health data is unavailable on this device.")
                                        .font(.pulsumCaption)
                                        .foregroundStyle(Color.pulsumWarning)
                                }
                                .padding(.horizontal, PulsumSpacing.sm)
                                .padding(.vertical, PulsumSpacing.xs)
                                .background(Color.pulsumWarning.opacity(0.1))
                                .cornerRadius(PulsumRadius.sm)
                            }

                            if let success = viewModel.healthKitSuccessMessage {
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(Color.pulsumGreenSoft)
                                    Text(success)
                                        .font(.pulsumCaption)
                                        .foregroundStyle(Color.pulsumGreenSoft)
                                    Spacer()
                                }
                                .padding(.horizontal, PulsumSpacing.sm)
                                .padding(.vertical, PulsumSpacing.xs)
                                .background(Color.pulsumGreenSoft.opacity(0.12))
                                .cornerRadius(PulsumRadius.sm)
                            }

                            Divider()
                                .padding(.vertical, PulsumSpacing.xs)

                            VStack(spacing: PulsumSpacing.sm) {
                                ForEach(viewModel.healthAccessRows) { row in
                                    HStack(spacing: PulsumSpacing.sm) {
                                        Image(systemName: row.iconName)
                                            .font(.pulsumTitle3)
                                            .foregroundStyle(Color.pulsumTextPrimary.opacity(0.7))
                                        VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                                            Text(row.title)
                                                .font(.pulsumCallout.weight(.semibold))
                                                .foregroundStyle(Color.pulsumTextPrimary)
                                            Text(row.detail)
                                                .font(.pulsumFootnote)
                                                .foregroundStyle(Color.pulsumTextSecondary)
                                        }
                                        Spacer()
                                        statusBadge(for: row.status)
                                    }
                                    .padding(.vertical, PulsumSpacing.xs)
                                    .accessibilityIdentifier("HealthAccessRow-\(row.id)")
                                }
                            }

                            if let error = viewModel.healthKitError {
                                HStack(spacing: PulsumSpacing.xs) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.pulsumCaption)
                                        .foregroundStyle(Color.pulsumWarning)
                                    Text(error)
                                        .font(.pulsumCaption)
                                        .foregroundStyle(Color.pulsumWarning)
                                }
                                .padding(.horizontal, PulsumSpacing.sm)
                                .padding(.vertical, PulsumSpacing.xs)
                                .background(Color.pulsumWarning.opacity(0.1))
                                .cornerRadius(PulsumRadius.sm)
                            }

                            Divider()
                                .padding(.vertical, PulsumSpacing.xs)

                            Button {
                                Task {
                                    await viewModel.requestHealthKitAuthorization()
                                }
                            } label: {
                                HStack {
                                    if viewModel.isRequestingHealthKitAuthorization {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .tint(Color.pulsumTextPrimary)
                                        Text("Requesting...")
                                            .font(.pulsumCallout.weight(.semibold))
                                            .foregroundStyle(Color.pulsumTextPrimary)
                                    } else {
                                        Text("Request Health Data Access")
                                            .font(.pulsumCallout.weight(.semibold))
                                            .foregroundStyle(Color.pulsumTextPrimary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, PulsumSpacing.sm)
                            }
                                    .glassEffect(.regular.tint(Color.pulsumPinkSoft.opacity(0.6)).interactive())
                                    .disabled(viewModel.isRequestingHealthKitAuthorization || !viewModel.canRequestHealthKitAccess)
                                    .accessibilityIdentifier("HealthAccessRequestButton")

                                Text("Pulsum needs access to Heart Rate Variability, Heart Rate, Resting Heart Rate, Respiratory Rate, Steps, and Sleep data to provide personalized recovery recommendations.")
                                    .font(.pulsumFootnote)
                                    .foregroundStyle(Color.pulsumTextSecondary)
                                    .lineSpacing(3)

                                Divider()
                                    .padding(.vertical, PulsumSpacing.xs)

                            VStack(alignment: .leading, spacing: PulsumSpacing.xs) {
                                Text("Health access status")
                                    .font(.pulsumFootnote.weight(.semibold))
                                    .foregroundStyle(Color.pulsumTextSecondary)
                                Text(viewModel.healthKitDebugSummary.isEmpty ? "Tap Refresh to fetch status" : viewModel.healthKitDebugSummary)
                                    .font(.system(.footnote, design: .monospaced))
                                    .foregroundStyle(Color.pulsumTextPrimary)
                                    .textSelection(.enabled)
                                    .accessibilityIdentifier("HealthAccessDebugSummaryLabel")
                                HStack(spacing: PulsumSpacing.sm) {
                                    Button("Refresh Status") {
                                        viewModel.refreshHealthAccessStatus()
                                    }
                                    .font(.pulsumFootnote.weight(.semibold))
                                    .foregroundStyle(Color.pulsumTextPrimary)
                                    .glassEffect(.regular.tint(Color.pulsumBlueSoft.opacity(0.5)).interactive())
                                    Button("Copy") {
                                        copyToClipboard(viewModel.healthKitDebugSummary)
                                    }
                                    .font(.pulsumFootnote.weight(.semibold))
                                    .foregroundStyle(Color.pulsumTextPrimary)
                                    .glassEffect(.regular.tint(Color.pulsumTextSecondary.opacity(0.3)).interactive())
                                    .accessibilityIdentifier("HealthAccessCopyButton")
                                }
                            }

                            Divider()
                                .padding(.vertical, PulsumSpacing.xs)

                            VStack(alignment: .leading, spacing: PulsumSpacing.xs) {
                                Text("App debug log")
                                    .font(.pulsumFootnote.weight(.semibold))
                                    .foregroundStyle(Color.pulsumTextSecondary)
                                Text(viewModel.debugLogSnapshot.isEmpty ? "Tap Refresh Log to capture recent events" : viewModel.debugLogSnapshot)
                                    .font(.system(.footnote, design: .monospaced))
                                    .foregroundStyle(Color.pulsumTextPrimary)
                                    .textSelection(.enabled)
                                    .accessibilityIdentifier("DebugLogSnapshotLabel")
                                    .frame(maxHeight: 160, alignment: .topLeading)
                                    .lineLimit(nil)
                                HStack(spacing: PulsumSpacing.sm) {
                                    Button("Refresh Log") {
                                        Task { await viewModel.refreshDebugLog() }
                                    }
                                    .font(.pulsumFootnote.weight(.semibold))
                                    .foregroundStyle(Color.pulsumTextPrimary)
                                    .glassEffect(.regular.tint(Color.pulsumBlueSoft.opacity(0.5)).interactive())
                                    Button("Copy Log") {
                                        copyToClipboard(viewModel.debugLogSnapshot)
                                    }
                                    .font(.pulsumFootnote.weight(.semibold))
                                    .foregroundStyle(Color.pulsumTextPrimary)
                                    .glassEffect(.regular.tint(Color.pulsumTextSecondary.opacity(0.3)).interactive())
                                    .accessibilityIdentifier("DebugLogCopyButton")
                                }
                            }
                        }
                        .padding(PulsumSpacing.lg)
                        .background(Color.pulsumCardWhite)
                        .cornerRadius(PulsumRadius.xl)
                        .shadow(
                            color: PulsumShadow.small.color,
                            radius: PulsumShadow.small.radius,
                            x: PulsumShadow.small.x,
                            y: PulsumShadow.small.y
                        )
                    }

                    // AI Models Section
                    VStack(alignment: .leading, spacing: PulsumSpacing.md) {
                        Text("AI Models")
                            .font(.pulsumHeadline)
                            .foregroundStyle(Color.pulsumTextPrimary)
                            .padding(.horizontal, PulsumSpacing.lg)

                        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
                            // Apple Intelligence
                            HStack(alignment: .top, spacing: PulsumSpacing.sm) {
                                Image(systemName: "sparkles")
                                    .font(.pulsumTitle3)
                                    .foregroundStyle(Color.pulsumBlueSoft)
                                VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                                    Text("Apple Intelligence")
                                        .font(.pulsumHeadline)
                                        .foregroundStyle(Color.pulsumTextPrimary)
                                    Text(viewModel.foundationModelsStatus)
                                        .font(.pulsumCallout)
                                        .foregroundStyle(Color.pulsumTextSecondary)
                                        .lineSpacing(2)
                                }
                            }

                            if needsEnableLink(status: viewModel.foundationModelsStatus) {
#if os(macOS)
                                Link(destination: URL(string: "x-apple.systempreferences:com.apple.AppleIntelligence-Settings")!) {
                                    appleIntelligenceLinkContent()
                                }
#else
                                Button {
                                    openAppleIntelligenceSettings()
                                } label: {
                                    appleIntelligenceLinkContent()
                                }
                                .accessibilityIdentifier("AppleIntelligenceLinkButton")
#endif
                            }

                        }
                        .padding(PulsumSpacing.lg)
                        .background(Color.pulsumCardWhite)
                        .cornerRadius(PulsumRadius.xl)
                        .shadow(
                            color: PulsumShadow.small.color,
                            radius: PulsumShadow.small.radius,
                            x: PulsumShadow.small.x,
                            y: PulsumShadow.small.y
                        )
                    }

                    // Safety Section
                    VStack(alignment: .leading, spacing: PulsumSpacing.md) {
                        Text("Safety")
                            .font(.pulsumHeadline)
                            .foregroundStyle(Color.pulsumTextPrimary)
                            .padding(.horizontal, PulsumSpacing.lg)

                        VStack(spacing: PulsumSpacing.sm) {
                            Link(destination: URL(string: "tel://911")!) {
                                HStack {
                                    Text("If you're in crisis, dial 911")
                                        .font(.pulsumBody)
                                        .foregroundStyle(Color.pulsumError)
                                    Spacer()
                                    Image(systemName: "phone.fill")
                                        .foregroundStyle(Color.pulsumError)
                                }
                            }

                            Divider()

                            Link(destination: URL(string: "tel://988")!) {
                                HStack {
                                    Text("988 Suicide & Crisis Lifeline")
                                        .font(.pulsumBody)
                                        .foregroundStyle(Color.pulsumTextPrimary)
                                    Spacer()
                                    Image(systemName: "phone.fill")
                                        .foregroundStyle(Color.pulsumTextSecondary)
                                }
                            }
                        }
                        .padding(PulsumSpacing.lg)
                        .background(Color.pulsumCardWhite)
                        .cornerRadius(PulsumRadius.xl)
                        .shadow(
                            color: PulsumShadow.small.color,
                            radius: PulsumShadow.small.radius,
                            x: PulsumShadow.small.x,
                            y: PulsumShadow.small.y
                        )
                    }

                    // Privacy Section
                    VStack(alignment: .leading, spacing: PulsumSpacing.md) {
                        Text("Privacy")
                            .font(.pulsumHeadline)
                            .foregroundStyle(Color.pulsumTextPrimary)
                            .padding(.horizontal, PulsumSpacing.lg)

                        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
                            Link(destination: URL(string: "https://pulsum.ai/privacy")!) {
                                HStack {
                                    Text("Privacy policy")
                                        .font(.pulsumBody)
                                        .foregroundStyle(Color.pulsumBlueSoft)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.pulsumCaption)
                                        .foregroundStyle(Color.pulsumTextSecondary)
                                }
                            }

                            Text("Pulsum stores all health data on-device with NSFileProtectionComplete and never uploads your journals.")
                                .font(.pulsumFootnote)
                                .foregroundStyle(Color.pulsumTextSecondary)
                                .lineSpacing(3)
                        }
                        .padding(PulsumSpacing.lg)
                        .background(Color.pulsumCardWhite)
                        .cornerRadius(PulsumRadius.xl)
                        .shadow(
                            color: PulsumShadow.small.color,
                            radius: PulsumShadow.small.radius,
                            x: PulsumShadow.small.x,
                            y: PulsumShadow.small.y
                        )
                    }

#if DEBUG
                    if viewModel.diagnosticsVisible {
                        DiagnosticsPanel(routeHistory: viewModel.routeHistory,
                                         coverageSummary: viewModel.lastCoverageSummary,
                                         cloudError: viewModel.lastCloudError,
                                         healthStatusSummary: viewModel.healthKitDebugSummary)
                            .transition(.opacity)
                    }
#endif
                }
                .padding(PulsumSpacing.lg)
                .padding(.bottom, PulsumSpacing.xxl)
            }
            .background(Color.pulsumBackgroundBeige.ignoresSafeArea())
#if DEBUG
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.pulsumHeadline)
                        .foregroundStyle(Color.pulsumTextPrimary)
                        .onTapGesture(count: 3) {
                            viewModel.toggleDiagnosticsVisibility()
                        }
                }
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
            }
            .toolbarBackground(.automatic, for: .navigationBar)
#else
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
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
            }
            .toolbarBackground(.automatic, for: .navigationBar)
#endif
            .task {
                viewModel.refreshFoundationStatus()
                viewModel.refreshHealthAccessStatus()
                await viewModel.testCurrentAPIKey()
            }
            .onEscapeDismiss {
                dismiss()
            }
        }
    }

    private func needsEnableLink(status: String) -> Bool {
        status.localizedCaseInsensitiveContains("enable") || status.localizedCaseInsensitiveContains("require")
    }

    private func copyToClipboard(_ text: String) {
#if canImport(UIKit)
        UIPasteboard.general.string = text
#endif
    }

    @ViewBuilder
    private var wellbeingScoreSection: some View {
        switch wellbeingState {
        case let .ready(score, _):
            if let detailViewModel = viewModel.makeScoreBreakdownViewModel() {
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
            WellbeingNoDataCard(reason: reason) {
                Task { await viewModel.requestHealthKitAuthorization() }
            }
        case let .error(message):
            WellbeingErrorCard(message: message)
        }
    }

    private func relativeDate(for date: Date) -> String? {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    @ViewBuilder
    private func appleIntelligenceLinkContent() -> some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
            HStack(spacing: PulsumSpacing.xs) {
                Text("Enable Apple Intelligence in Settings")
                    .font(.pulsumCallout)
                    .foregroundStyle(Color.pulsumBlueSoft)
                Image(systemName: "arrow.up.right")
                    .font(.pulsumCaption)
                    .foregroundStyle(Color.pulsumBlueSoft)
            }
            Text("Opens system Settings so you can turn on Apple Intelligence for GPT-5 routing.")
                .font(.pulsumFootnote)
                .foregroundStyle(Color.pulsumTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func statusBadge(for status: HealthAccessGrantState) -> some View {
        let (icon, color, label): (String, Color, String) = {
            switch status {
            case .granted:
                return ("checkmark.circle.fill", Color.pulsumGreenSoft, "Granted")
            case .denied:
                return ("xmark.circle.fill", Color.pulsumWarning, "Denied")
            case .pending:
                return ("questionmark.circle", Color.pulsumTextSecondary, "Pending")
            }
        }()

        HStack(spacing: PulsumSpacing.xxs) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)
            Text(label)
                .font(.pulsumCaption.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, PulsumSpacing.xs)
        .padding(.vertical, PulsumSpacing.xxs)
        .background(color.opacity(0.12))
        .cornerRadius(PulsumRadius.sm)
        .accessibilityIdentifier("CloudAPIStatusBadge")
    }

    private func gptStatusBadge(isWorking: Bool, status: String) -> some View {
        let (label, color): (String, Color) = {
            if isWorking {
                return ("OK", Color.pulsumGreenSoft)
            }
            if status.localizedCaseInsensitiveContains("missing") {
                return ("Missing", Color.pulsumTextSecondary)
            }
            return ("Check", Color.pulsumWarning)
        }()
        return HStack(spacing: PulsumSpacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.pulsumCaption.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, PulsumSpacing.xs)
        .padding(.vertical, PulsumSpacing.xxs)
        .background(color.opacity(0.12))
        .cornerRadius(PulsumRadius.sm)
    }

    private func openAppleIntelligenceSettings() {
        let forceFallback = ProcessInfo.processInfo.environment["UITEST_FORCE_SETTINGS_FALLBACK"] == "1"
#if canImport(UIKit)
        if !forceFallback,
           let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL, options: [:]) { success in
                if success {
                    logOpenedURL(settingsURL)
                } else {
                    openSupportArticle()
                }
            }
            return
        }
#endif
        openSupportArticle()
    }

    private func logOpenedURL(_ url: URL) {
        guard ProcessInfo.processInfo.environment["UITEST_CAPTURE_URLS"] == "1" else { return }
        let defaults = UserDefaults(suiteName: "ai.pulsum.uiautomation")
        defaults?.set(url.absoluteString, forKey: "LastOpenedURL")
    }

    private func openSupportArticle() {
        guard let supportURL = URL(string: "https://support.apple.com/en-us/HT213969") else { return }
        logOpenedURL(supportURL)
        _ = openURL(supportURL)
    }
}

private extension View {
    func onEscapeDismiss(_ action: @escaping () -> Void) -> some View {
        Group {
            if #available(iOS 17.0, macOS 14.0, *) {
                self.onKeyPress(.escape) {
                    action()
                    return .handled
                }
            } else {
                self
            }
        }
    }
}

#if DEBUG
private struct DiagnosticsPanel: View {
    let routeHistory: [String]
    let coverageSummary: String
    let cloudError: String
    let healthStatusSummary: String

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            Text("Diagnostics")
                .font(.pulsumHeadline)
                .foregroundStyle(Color.pulsumTextPrimary)

            VStack(alignment: .leading, spacing: PulsumSpacing.sm) {
                Text("Last routes")
                    .font(.pulsumCallout.weight(.semibold))
                    .foregroundStyle(Color.pulsumTextSecondary)

                if routeHistory.isEmpty {
                    Text("No recent routing data")
                        .font(.pulsumCaption)
                        .foregroundStyle(Color.pulsumTextTertiary)
                } else {
                    ForEach(routeHistory, id: \.self) { line in
                        Text(line)
                            .font(.pulsumCaption)
                            .foregroundStyle(Color.pulsumTextSecondary)
                    }
                }

                Text("Coverage: \(coverageSummary)")
                    .font(.pulsumCaption)
                    .foregroundStyle(Color.pulsumTextSecondary)

                Text("Health access: \(healthStatusSummary)")
                    .font(.pulsumCaption)
                    .foregroundStyle(Color.pulsumTextSecondary)
                    .textSelection(.enabled)

                Text("Last cloud error: \(cloudError)")
                    .font(.pulsumCaption)
                    .foregroundStyle(Color.pulsumWarning)
                    .lineLimit(3)
            }
        }
        .padding(PulsumSpacing.lg)
        .background(Color.pulsumCardWhite)
        .cornerRadius(PulsumRadius.xl)
        .shadow(
            color: PulsumShadow.small.color,
            radius: PulsumShadow.small.radius,
            x: PulsumShadow.small.x,
            y: PulsumShadow.small.y
        )
        .overlay(alignment: .topLeading) {
            Text("DEBUG")
                .font(.pulsumCaption2.weight(.bold))
                .foregroundStyle(Color.pulsumBlueSoft)
                .padding(.horizontal, PulsumSpacing.xs)
                .padding(.vertical, PulsumSpacing.xxs)
        }
        .accessibilityIdentifier("DiagnosticsPanel")
    }
}
#endif

// MARK: - Wellbeing Score Loading Card
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

// MARK: - Wellbeing Score Card
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

    private var scoreColor: Color {
        switch score {
        case ..<(-1): return Color.pulsumWarning
        case -1..<0.5: return Color.pulsumTextSecondary
        case 0.5..<1.5: return Color.pulsumGreenSoft
        default: return Color.pulsumSuccess
        }
    }

    private var interpretedScore: String {
        switch score {
        case ..<(-1): return "Let's go gentle today"
        case -1..<0.5: return "Maintaining base"
        case 0.5..<1.5: return "Positive momentum"
        default: return "Strong recovery"
        }
    }
}
