import SwiftUI
import Observation
#if canImport(UIKit)
import UIKit
#endif

struct PulseView: View {
    @Bindable var viewModel: PulseViewModel
    @Binding var isPresented: Bool

    @State private var autoDismissTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.pulsumBackgroundBeige, Color.pulsumBackgroundCream],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Content
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: PulsumSpacing.xl) {
                        journalSection
                        slidersSection
                    }
                    .padding(.horizontal, PulsumSpacing.lg)
                    .padding(.top, PulsumSpacing.md)
                    .padding(.bottom, PulsumSpacing.xxxl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Pulse Check-In")
            .navigationBarTitleDisplayMode(.inline)
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
            .toolbarBackground(.automatic, for: .navigationBar)
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
            Text("Voice journal")
                .font(.pulsumHeadline)
                .foregroundStyle(Color.pulsumTextPrimary)

            VoiceJournalButton(
                isRecording: viewModel.isRecording,
                isAnalyzing: viewModel.isAnalyzing,
                remaining: viewModel.recordingSecondsRemaining,
                audioLevels: viewModel.audioLevels,
                startAction: { viewModel.startRecording() },
                stopAction: { viewModel.stopRecording() }
            )
            
            // Real-time transcript display
            if let transcript = viewModel.transcript, !transcript.isEmpty, (viewModel.isRecording || viewModel.isAnalyzing) {
                VStack(alignment: .leading, spacing: PulsumSpacing.xs) {
                    HStack {
                        Text("Transcript")
                            .font(.pulsumFootnote)
                            .foregroundStyle(Color.pulsumTextSecondary)
                        
                        if viewModel.isRecording {
                            Text("• LIVE")
                                .font(.pulsumFootnote)
                                .foregroundStyle(Color.pulsumError)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    Text(transcript)
                        .font(.pulsumBody)
                        .foregroundStyle(Color.pulsumTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(PulsumSpacing.sm)
                        .background {
                            RoundedRectangle(cornerRadius: PulsumRadius.md, style: .continuous)
                                .fill(Color.pulsumBackgroundBeige.opacity(0.3))
                        }
                }
                .animation(.pulsumStandard, value: transcript)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            if let error = viewModel.analysisError {
                InfoBubble(icon: "exclamationmark.triangle", text: error, tint: Color.pulsumWarning)
            }
        }
        .padding(PulsumSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: PulsumRadius.xl, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: PulsumRadius.xl, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 16,
                    x: 0,
                    y: 6
                )
        }
    }

    private var slidersSection: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            Text("How are you feeling right now?")
                .font(.pulsumHeadline)
                .foregroundStyle(Color.pulsumTextPrimary)

            VStack(spacing: PulsumSpacing.sm) {
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
                Text(viewModel.isSubmittingInputs ? "Saving..." : "Save inputs")
                    .font(.pulsumHeadline)
                    .foregroundStyle(Color.pulsumTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PulsumSpacing.md)
            }
            .glassEffect(.regular.tint(Color.pulsumGreenSoft.opacity(0.8)).interactive())
            .disabled(viewModel.isSubmittingInputs)
        }
        .padding(PulsumSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: PulsumRadius.xl, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: PulsumRadius.xl, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 16,
                    x: 0,
                    y: 6
                )
        }
    }

    private func sliderRow(title: String, value: Binding<Double>, description: String) -> some View {
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
        .padding(PulsumSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: PulsumRadius.md, style: .continuous)
                .fill(Color.pulsumBackgroundBeige.opacity(0.3))
        }
    }
}

// Simple horizontal voice journal button
private struct VoiceJournalButton: View {
    let isRecording: Bool
    let isAnalyzing: Bool
    let remaining: Int
    let audioLevels: [CGFloat]
    let startAction: () -> Void
    let stopAction: () -> Void
    
    private let maxDuration: Double = 30
    
    var body: some View {
        HStack(spacing: PulsumSpacing.md) {
            if isRecording {
                // Recording state: waveform + stop button with progress
                waveformView
                
                ZStack {
                    // Progress ring background
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                        .frame(width: 56, height: 56)
                    
                    // Progress ring foreground
                    Circle()
                        .trim(from: 0, to: CGFloat(maxDuration - Double(remaining)) / maxDuration)
                        .stroke(Color.pulsumGreenSoft, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: remaining)
                    
                    // Stop button
                    Button {
                        performPulseHaptic(style: .medium)
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
                    .accessibilityLabel("Stop recording")
                    .accessibilityHint("Double tap to stop recording")
                }
            } else if isAnalyzing {
                // Processing state: spinner + text
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.pulsumGreenSoft)
                    .scaleEffect(1.2)
                    .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Analyzing...")
                        .font(.pulsumHeadline)
                        .foregroundStyle(Color.pulsumTextPrimary)
                    
                    Text("Processing your journal entry")
                        .font(.pulsumFootnote)
                        .foregroundStyle(Color.pulsumTextSecondary)
                }
            } else {
                // Idle state: record button + text
                Button {
                    performPulseHaptic(style: .heavy)
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
                .accessibilityLabel("Record voice journal")
                .accessibilityHint("Double tap to start recording")
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tap to record")
                        .font(.pulsumHeadline)
                        .foregroundStyle(Color.pulsumTextPrimary)
                    
                    Text("Up to 30 seconds")
                        .font(.pulsumFootnote)
                        .foregroundStyle(Color.pulsumTextSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.pulsumStandard, value: isRecording)
        .animation(.pulsumStandard, value: isAnalyzing)
    }
    
    private var waveformView: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let barWidth: CGFloat = 2.5
            let barSpacing: CGFloat = 2
            let barCount = Int(width / (barWidth + barSpacing))
            
            let samplesToShow = min(audioLevels.count, barCount)
            let startIndex = max(0, audioLevels.count - samplesToShow)
            let samples = Array(audioLevels[startIndex..<audioLevels.count])
            
            for (index, level) in samples.enumerated() {
                let x = CGFloat(index) * (barWidth + barSpacing)
                let normalizedLevel = max(0.05, min(1.0, level))
                let barHeight = height * normalizedLevel
                let y = (height - barHeight) / 2
                
                let rect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
                let roundedRect = RoundedRectangle(cornerRadius: barWidth / 2)
                
                context.fill(
                    roundedRect.path(in: rect),
                    with: .color(Color.pulsumGreenSoft.opacity(0.8))
                )
            }
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
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

#if canImport(UIKit)
private func performPulseHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.impactOccurred()
}
#else
private func performPulseHaptic(style: Any) {}
#endif
