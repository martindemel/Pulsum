import SwiftUI
import HealthKit

struct OnboardingView: View {
    @Binding var isPresented: Bool
    let onComplete: () async -> Void

    @State private var currentPage = 0
    @State private var isRequestingHealthKit = false
    @State private var healthKitError: String?

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

                // Data types list
                VStack(alignment: .leading, spacing: PulsumSpacing.sm) {
                    healthDataRow(icon: "waveform.path.ecg", text: "Heart Rate Variability")
                    healthDataRow(icon: "heart.fill", text: "Heart Rate & Resting HR")
                    healthDataRow(icon: "bed.double.fill", text: "Sleep Analysis")
                    healthDataRow(icon: "figure.walk", text: "Step Count & Activity")
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

    private func healthDataRow(icon: String, text: String) -> some View {
        HStack(spacing: PulsumSpacing.sm) {
            Image(systemName: icon)
                .font(.pulsumCallout)
                .foregroundStyle(Color.pulsumGreenSoft)
                .frame(width: 24)
            Text(text)
                .font(.pulsumCallout)
                .foregroundStyle(Color.pulsumTextPrimary)
            Spacer()
        }
    }

    // MARK: - HealthKit Authorization

    private func requestHealthKitAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthKitError = "Health data is not available on this device"
            return
        }

        isRequestingHealthKit = true
        healthKitError = nil

        do {
            let healthStore = HKHealthStore()
            let readTypes: Set<HKSampleType> = {
                var types: Set<HKSampleType> = []
                if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { types.insert(hrv) }
                if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) { types.insert(heartRate) }
                if let restingHR = HKObjectType.quantityType(forIdentifier: .restingHeartRate) { types.insert(restingHR) }
                if let respiratoryRate = HKObjectType.quantityType(forIdentifier: .respiratoryRate) { types.insert(respiratoryRate) }
                if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) { types.insert(steps) }
                if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
                return types
            }()

            try await healthStore.requestAuthorization(toShare: [], read: readTypes)

            // Move to next page on success
            withAnimation(.pulsumStandard) {
                currentPage = 2
            }
        } catch {
            healthKitError = error.localizedDescription
        }

        isRequestingHealthKit = false
    }
}
