import SwiftUI
import Observation

struct PulseView: View {
    @Bindable var viewModel: PulseViewModel
    @Binding var isPresented: Bool

    @State private var autoDismissTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PulsumSpacing.lg) {
                    journalSection
                    slidersSection
                }
                .padding(.horizontal, PulsumSpacing.lg)
                .padding(.vertical, PulsumSpacing.lg)
            }
            .background(
                LinearGradient(
                    colors: [Color.pulsumBackgroundBeige, Color.pulsumBackgroundCream],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.pulsumTextSecondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .onDisappear { autoDismissTask?.cancel() }
            .onChange(of: viewModel.sliderSubmissionMessage) { _, message in
                guard message != nil else { return }
                autoDismissTask?.cancel()
                autoDismissTask = Task {
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    if !Task.isCancelled {
                        isPresented = false
                    }
                }
            }
        }
    }

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            Text("Pulse journal")
                .font(.pulsumHeadline)
                .foregroundStyle(Color.pulsumTextPrimary)

            TapToRecordButton(
                isRecording: viewModel.isRecording,
                remaining: viewModel.recordingSecondsRemaining,
                isProcessing: viewModel.isAnalyzing,
                startAction: { viewModel.startRecording() },
                stopAction: { viewModel.stopRecording() }
            )
            .frame(height: 70)
            .padding(.vertical, PulsumSpacing.sm)

            if let transcript = viewModel.transcript {
                VStack(alignment: .leading, spacing: PulsumSpacing.xs) {
                    Text("Latest transcript")
                        .font(.pulsumCaption)
                        .foregroundStyle(Color.pulsumTextSecondary)
                    Text(transcript)
                        .font(.pulsumBody)
                        .foregroundStyle(Color.pulsumTextPrimary)
                        .padding(PulsumSpacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.pulsumBackgroundCream)
                        .cornerRadius(PulsumRadius.md)
                    if let score = viewModel.sentimentScore {
                        HStack(spacing: PulsumSpacing.xs) {
                            Image(systemName: score >= 0 ? "face.smiling" : "face.dashed")
                                .font(.pulsumCaption)
                            Text("Sentiment: \(score.formatted(.number.precision(.fractionLength(2))))")
                                .font(.pulsumCaption)
                        }
                        .foregroundStyle(score >= 0 ? Color.pulsumSuccess : Color.pulsumWarning)
                    }
                }
            }

            if let error = viewModel.analysisError {
                InfoBubble(icon: "exclamationmark.triangle", text: error, tint: Color.pulsumWarning)
            }
        }
        .padding(PulsumSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: PulsumRadius.xl, style: .continuous)
                .fill(Color.pulsumCardWhite)
                .shadow(color: PulsumShadow.small.color, radius: PulsumShadow.small.radius, x: PulsumShadow.small.x, y: PulsumShadow.small.y)
        )
    }

    private var slidersSection: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            Text("How are you feeling right now?")
                .font(.pulsumHeadline)
                .foregroundStyle(Color.pulsumTextPrimary)

            VStack(spacing: PulsumSpacing.md) {
                sliderRow(title: "Stress", value: $viewModel.stressLevel, description: "1 = very calm, 7 = overwhelmed")
                sliderRow(title: "Energy", value: $viewModel.energyLevel, description: "1 = depleted, 7 = fully charged")
                sliderRow(title: "Sleep quality", value: $viewModel.sleepQualityLevel, description: "1 = poor, 7 = deeply restorative")
            }

            if let error = viewModel.sliderErrorMessage {
                InfoBubble(icon: "exclamationmark.octagon", text: error, tint: Color.pulsumWarning)
            }

            if let message = viewModel.sliderSubmissionMessage {
                InfoBubble(icon: "checkmark.circle.fill", text: message, tint: Color.pulsumSuccess)
            }

            Button {
                viewModel.submitInputs()
            } label: {
                Text(viewModel.isSubmittingInputs ? "Saving..." : "Save subjective inputs")
                    .font(.pulsumBody.weight(.semibold))
                    .foregroundStyle(Color.pulsumTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PulsumSpacing.sm)
            }
            .glassEffect(.regular.tint(Color.pulsumGreenSoft.opacity(0.7)).interactive())
            .disabled(viewModel.isSubmittingInputs)
        }
        .padding(PulsumSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: PulsumRadius.xl, style: .continuous)
                .fill(Color.pulsumCardWhite)
                .shadow(color: PulsumShadow.small.color, radius: PulsumShadow.small.radius, x: PulsumShadow.small.x, y: PulsumShadow.small.y)
        )
    }

    private func sliderRow(title: String, value: Binding<Double>, description: String) -> some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.sm) {
            HStack {
                Text(title)
                    .font(.pulsumBody.weight(.semibold))
                    .foregroundStyle(Color.pulsumTextPrimary)
                Spacer()
                Text("\(Int(value.wrappedValue.rounded()))")
                    .font(.pulsumCaption)
                    .foregroundStyle(Color.pulsumGreenSoft)
            }
            Slider(value: value, in: 1...7, step: 1)
                .tint(Color.pulsumGreenSoft)
            Text(description)
                .font(.pulsumCaption)
                .foregroundStyle(Color.pulsumTextSecondary)
        }
    }
}

private struct TapToRecordButton: View {
    let isRecording: Bool
    let remaining: Int
    let isProcessing: Bool
    let startAction: () -> Void
    let stopAction: () -> Void

    @State private var isPressed = false

    private let buttonHeight: CGFloat = 70

    var body: some View {
        Button {
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: isRecording ? .medium : .heavy)
            impact.impactOccurred()

            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isRecording {
                    stopAction()
                } else {
                    startAction()
                }
            }
        } label: {
            ZStack {
                // Background with liquid glass effect
                RoundedRectangle(cornerRadius: buttonHeight / 2, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: buttonHeight / 2, style: .continuous)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    }

                // Recording progress indicator
                if isRecording {
                    GeometryReader { geo in
                        let progress = CGFloat(30 - remaining) / 30.0
                        RoundedRectangle(cornerRadius: buttonHeight / 2, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.pulsumGreenSoft.opacity(0.3), Color.pulsumGreenSoft.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress)
                            .animation(.linear(duration: 1), value: remaining)
                    }
                }

                // Content
                HStack(spacing: 12) {
                    // Microphone/Stop Icon Circle
                    Circle()
                        .fill(.regularMaterial)
                        .overlay {
                            Circle()
                                .strokeBorder(.white.opacity(0.3), lineWidth: 2)
                        }
                        .overlay {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .symbolEffect(.pulse, isActive: isRecording)
                            }
                        }
                        .frame(width: 54, height: 54)
                        .shadow(color: (isRecording ? Color.pulsumError : Color.pulsumGreenSoft).opacity(0.4), radius: 12, x: 0, y: 4)

                    // Label
                    if isProcessing {
                        HStack(spacing: 8) {
                            Text("Processing...")
                                .font(.pulsumBody.weight(.semibold))
                                .foregroundStyle(Color.pulsumTextSecondary)
                        }
                    } else if isRecording {
                        HStack(spacing: 8) {
                            Text(formattedTime)
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(Color.pulsumTextPrimary)
                            Text("• Tap to stop")
                                .font(.pulsumCallout.weight(.medium))
                                .foregroundStyle(Color.pulsumError)
                        }
                    } else {
                        Text("Tap to record")
                            .font(.pulsumBody.weight(.semibold))
                            .foregroundStyle(Color.pulsumTextPrimary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 8)
            }
            .frame(height: buttonHeight)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .accessibilityLabel(isRecording ? "Stop recording" : (isProcessing ? "Processing journal" : "Start voice journal"))
        .accessibilityHint(isRecording ? "Tap to stop recording" : "Tap to start recording")
    }

    private var formattedTime: String {
        let mins = remaining / 60
        let secs = remaining % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

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
        .background(Color.pulsumCardWhite)
        .cornerRadius(PulsumRadius.md)
        .shadow(
            color: PulsumShadow.small.color,
            radius: PulsumShadow.small.radius,
            x: PulsumShadow.small.x,
            y: PulsumShadow.small.y
        )
    }
}
