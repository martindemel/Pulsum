import SwiftUI
import HealthKit
import PulsumAgents

struct OnboardingView: View {
    @Binding var isPresented: Bool
    let onComplete: () async -> Void
    var orchestrator: AgentOrchestrator?

    @State private var currentPage = 0
    @State private var isRequestingHealthKit = false
    @State private var healthKitError: String?
    @State private var healthAccessSummary: String = "Checking..."
    @State private var healthAccessStatuses: [String: HealthAccessGrantState] = Dictionary(
        uniqueKeysWithValues: HealthAccessRequirement.ordered.map { ($0.id, .pending) }
    )

    var body: some View {
        ZStack {
            // Light gradient background
            LinearGradient(
                colors: [Color.pulsumBackgroundBeige, Color.pulsumBackgroundCream],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: PulsumSpacing.xs) {
                    ForEach(0..<3) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.pulsumGreenSoft : Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, PulsumSpacing.xl)
                .padding(.top, PulsumSpacing.xl)

                // Content
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    healthKitPage.tag(1)
                    readyPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.pulsumStandard, value: currentPage)
            }
        }
        .task {
            refreshHealthAccessStatus()
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: PulsumSpacing.xxl) {
            Spacer()

            // Logo/Icon
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 80, weight: .semibold))
                .foregroundStyle(Color.pulsumGreenSoft)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: PulsumSpacing.lg) {
                Text("Welcome to Pulsum")
                    .font(.pulsumLargeTitle)
                    .foregroundStyle(Color.pulsumTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Your personal recovery companion that helps you optimize your wellbeing using science-backed insights.")
                    .font(.pulsumBody)
                    .foregroundStyle(Color.pulsumTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, PulsumSpacing.xl)
            }

            Spacer()

            Button {
                withAnimation(.pulsumStandard) {
                    currentPage = 1
                }
            } label: {
                Text("Get Started")
                    .font(.pulsumHeadline)
                    .foregroundStyle(Color.pulsumTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PulsumSpacing.md)
            }
            .glassEffect(.regular.tint(Color.pulsumGreenSoft.opacity(0.7)).interactive())
            .padding(.horizontal, PulsumSpacing.xl)
            .padding(.bottom, PulsumSpacing.xxl)
        }
    }

    private var healthKitPage: some View {
        VStack(spacing: PulsumSpacing.xxl) {
            Spacer()

            // Health icon
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 80, weight: .semibold))
                .foregroundStyle(Color.pulsumPinkSoft)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: PulsumSpacing.lg) {
                Text("Connect Your Health Data")
                    .font(.pulsumTitle)
                    .foregroundStyle(Color.pulsumTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Pulsum analyzes your Heart Rate Variability, Heart Rate, Sleep, and Activity to provide personalized recommendations.")
                    .font(.pulsumBody)
                    .foregroundStyle(Color.pulsumTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, PulsumSpacing.xl)

                Text(healthAccessSummary)
                    .font(.pulsumCallout)
                    .foregroundStyle(Color.pulsumTextSecondary)
                    .multilineTextAlignment(.center)

                // Data types list
                VStack(alignment: .leading, spacing: PulsumSpacing.sm) {
                    ForEach(HealthAccessRequirement.ordered) { requirement in
                        onboardingHealthRow(for: requirement,
                                            status: healthAccessStatuses[requirement.id] ?? .pending)
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
                .padding(.horizontal, PulsumSpacing.xl)
            }

            if let error = healthKitError {
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
                .padding(.horizontal, PulsumSpacing.xl)
            }

            Spacer()

            VStack(spacing: PulsumSpacing.md) {
                Button {
                    Task {
                        await requestHealthKitAuthorization()
                    }
                } label: {
                    HStack {
                        if isRequestingHealthKit {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(Color.pulsumTextPrimary)
                            Text("Requesting...")
                                .font(.pulsumHeadline)
                                .foregroundStyle(Color.pulsumTextPrimary)
                        } else {
                            Text("Allow Health Data Access")
                                .font(.pulsumHeadline)
                                .foregroundStyle(Color.pulsumTextPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PulsumSpacing.md)
                }
                .glassEffect(.regular.tint(Color.pulsumPinkSoft.opacity(0.7)).interactive())
                .disabled(isRequestingHealthKit)

                Button {
                    withAnimation(.pulsumStandard) {
                        currentPage = 2
                    }
                } label: {
                    Text("Skip for Now")
                        .font(.pulsumCallout)
                        .foregroundStyle(Color.pulsumTextSecondary)
                }
            }
            .padding(.horizontal, PulsumSpacing.xl)
            .padding(.bottom, PulsumSpacing.xxl)
        }
    }

    private var readyPage: some View {
        VStack(spacing: PulsumSpacing.xxl) {
            Spacer()

            // Checkmark icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80, weight: .semibold))
                .foregroundStyle(Color.pulsumSuccess)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: PulsumSpacing.lg) {
                Text("You're All Set!")
                    .font(.pulsumTitle)
                    .foregroundStyle(Color.pulsumTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Start your recovery journey with Pulsum. Record your daily Pulse, get personalized recommendations, and optimize your wellbeing.")
                    .font(.pulsumBody)
                    .foregroundStyle(Color.pulsumTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, PulsumSpacing.xl)
            }

            Spacer()

            Button {
                Task {
                    await onComplete()
                    isPresented = false
                }
            } label: {
                Text("Start Using Pulsum")
                    .font(.pulsumHeadline)
                    .foregroundStyle(Color.pulsumTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PulsumSpacing.md)
            }
            .glassEffect(.regular.tint(Color.pulsumGreenSoft.opacity(0.7)).interactive())
            .padding(.horizontal, PulsumSpacing.xl)
            .padding(.bottom, PulsumSpacing.xxl)
        }
    }

    // MARK: - Helper Views

    private func onboardingHealthRow(for requirement: HealthAccessRequirement,
                                     status: HealthAccessGrantState) -> some View {
        HStack(spacing: PulsumSpacing.sm) {
            Image(systemName: requirement.iconName)
                .font(.pulsumTitle3)
                .foregroundStyle(Color.pulsumTextPrimary.opacity(0.8))
            VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                Text(requirement.title)
                    .font(.pulsumBody.weight(.semibold))
                    .foregroundStyle(Color.pulsumTextPrimary)
                Text(requirement.detail)
                    .font(.pulsumCaption)
                    .foregroundStyle(Color.pulsumTextSecondary)
            }
            Spacer()
            onboardingStatusBadge(for: status)
        }
    }

    // MARK: - HealthKit Authorization

    private func requestHealthKitAuthorization() async {
        isRequestingHealthKit = true
        healthKitError = nil

        if let orchestrator {
            do {
                let status = try await orchestrator.requestHealthAccess()
                applyHealthStatus(status)
                withAnimation(.pulsumStandard) {
                    currentPage = 2
                }
            } catch {
                healthKitError = error.localizedDescription
            }
            isRequestingHealthKit = false
            return
        }

        guard HKHealthStore.isHealthDataAvailable() else {
            healthKitError = "Health data is not available on this device"
            isRequestingHealthKit = false
            return
        }

        do {
            let healthStore = HKHealthStore()
            let readTypes = Set(HealthAccessRequirement.ordered.compactMap { requirement -> HKSampleType? in
                if let quantity = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: requirement.id)) {
                    return quantity
                }
                if let category = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: requirement.id)) {
                    return category
                }
                return nil
            })

            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            refreshHealthAccessStatus()
            withAnimation(.pulsumStandard) {
                currentPage = 2
            }
        } catch {
            healthKitError = error.localizedDescription
        }

        isRequestingHealthKit = false
    }

    private func refreshHealthAccessStatus() {
        guard let orchestrator else {
            healthAccessSummary = "Connect Pulsum to check permissions."
            return
        }
        Task {
            let status = await orchestrator.currentHealthAccessStatus()
            await MainActor.run {
                applyHealthStatus(status)
            }
        }
    }

    private func applyHealthStatus(_ status: HealthAccessStatus) {
        switch status.availability {
        case .available:
            if status.totalRequired > 0 {
                healthAccessSummary = "\(status.grantedCount)/\(status.totalRequired) granted"
            } else {
                healthAccessSummary = "Health data ready"
            }
        case .unavailable:
            healthAccessSummary = "Health data unavailable on this device"
        }

        var updated = healthAccessStatuses
        for requirement in HealthAccessRequirement.ordered {
            let identifier = requirement.id
            if status.granted.contains(where: { $0.identifier == identifier }) {
                updated[identifier] = .granted
            } else if status.denied.contains(where: { $0.identifier == identifier }) {
                updated[identifier] = .denied
            } else if status.notDetermined.contains(where: { $0.identifier == identifier }) {
                updated[identifier] = .pending
            }
        }
        healthAccessStatuses = updated
    }

    @ViewBuilder
    private func onboardingStatusBadge(for status: HealthAccessGrantState) -> some View {
        switch status {
        case .granted:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.pulsumGreenSoft)
        case .denied:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(Color.pulsumWarning)
        case .pending:
            Image(systemName: "questionmark.circle")
                .foregroundStyle(Color.pulsumTextSecondary)
        }
    }
}
