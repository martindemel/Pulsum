import SwiftUI
import Observation

struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: SettingsViewModel
    let wellbeingScore: Double?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: PulsumSpacing.lg) {
                    // Wellbeing Score Display (moved from MainView)
                    if let score = wellbeingScore {
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
                    }

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
                                    Text("We only send minimized context without journals or identifiers.")
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
                                    Text(viewModel.healthKitAuthorizationStatus)
                                        .font(.pulsumCallout)
                                        .foregroundStyle(Color.pulsumTextSecondary)
                                        .lineSpacing(2)
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
                            .disabled(viewModel.isRequestingHealthKitAuthorization)

                            Text("Pulsum needs access to Heart Rate Variability, Heart Rate, Resting Heart Rate, Respiratory Rate, Steps, and Sleep data to provide personalized recovery recommendations.")
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
                                Link(destination: URL(string: "x-apple.systempreferences:com.apple.AppleIntelligence-Settings")!) {
                                    Text("Enable Apple Intelligence in Settings")
                                        .font(.pulsumCallout)
                                        .foregroundStyle(Color.pulsumBlueSoft)
                                }
                            }

                            Divider()
                                .padding(.vertical, PulsumSpacing.xs)

                            // ChatGPT-5 API
                            HStack(alignment: .top, spacing: PulsumSpacing.sm) {
                                Image(systemName: "cpu")
                                    .font(.pulsumTitle3)
                                    .foregroundStyle(Color.pulsumGreenSoft)
                                VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                                    HStack(spacing: PulsumSpacing.xs) {
                                        Text("ChatGPT-5 API")
                                            .font(.pulsumHeadline)
                                            .foregroundStyle(Color.pulsumTextPrimary)
                                        Circle()
                                            .fill(viewModel.isGPTAPIWorking ? Color.green : Color.red)
                                            .frame(width: 8, height: 8)
                                    }
                                    Text(viewModel.gptAPIStatus)
                                        .font(.pulsumCallout)
                                        .foregroundStyle(Color.pulsumTextSecondary)
                                        .lineSpacing(2)
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
                                         cloudError: viewModel.lastCloudError)
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
                viewModel.refreshHealthKitStatus()
                await viewModel.checkGPTAPIKey()
            }
        }
    }

    private func needsEnableLink(status: String) -> Bool {
        status.localizedCaseInsensitiveContains("enable") || status.localizedCaseInsensitiveContains("require")
    }

    private func relativeDate(for date: Date) -> String? {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#if DEBUG
private struct DiagnosticsPanel: View {
    let routeHistory: [String]
    let coverageSummary: String
    let cloudError: String

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
