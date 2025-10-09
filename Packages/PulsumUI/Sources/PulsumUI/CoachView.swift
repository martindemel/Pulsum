import SwiftUI
import Observation
import PulsumAgents

public struct ChatInputView: View {
    @Bindable var viewModel: CoachViewModel
    @FocusState private var chatFieldInFocus: Bool

    init(viewModel: CoachViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack(spacing: PulsumSpacing.sm) {
            TextField("Ask Pulsum anything about your recovery", text: $viewModel.chatInput, axis: .vertical)
                .lineLimit(1...3)
                .font(.pulsumBody)
                .foregroundStyle(Color.pulsumTextPrimary)
                .padding(PulsumSpacing.md)
                .background(Color.pulsumCardWhite)
                .cornerRadius(PulsumRadius.lg)
                .shadow(
                    color: PulsumShadow.small.color,
                    radius: PulsumShadow.small.radius,
                    x: PulsumShadow.small.x,
                    y: PulsumShadow.small.y
                )
                .focused($chatFieldInFocus)
                .disabled(viewModel.isSendingChat)

            Button {
                Task { await viewModel.sendChat() }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.pulsumTextPrimary)
                    .frame(width: 44, height: 44)
            }
            .glassEffect(
                .regular.tint(
                    (viewModel.chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color.gray.opacity(0.3)
                        : Color.pulsumGreenSoft.opacity(0.7))
                ).interactive()
            )
            .disabled(viewModel.chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSendingChat)
        }
        .frame(maxWidth: .infinity)
        .onChange(of: viewModel.chatFocusToken) { _, _ in
            chatFieldInFocus = true
        }
    }
}

struct CoachScreen: View {
    @Bindable var viewModel: CoachViewModel
    let showChatInput: Bool

    private let chatBottomAnchor = "coach-chat-bottom"

    var body: some View {
        VStack(spacing: PulsumSpacing.lg) {
            chatMessagesOnly
        }
        .padding(.horizontal, PulsumSpacing.xl)
        .padding(.vertical, PulsumSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            Color.pulsumBackgroundBeige
                .ignoresSafeArea()
        )
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showChatInput {
                chatInputInset
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
#if canImport(UIKit)
            UIView.setAnimationsEnabled(true)
#endif
        }
        ._debugKeyboardLayoutFix()
    }

    private var chatMessagesOnly: some View {
        VStack(spacing: PulsumSpacing.md) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: PulsumSpacing.sm) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message)
                                .padding(message.role == .user ? .leading : .trailing, 48)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }

                        if viewModel.isSendingChat {
                            HStack(spacing: PulsumSpacing.xs) {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(Color.pulsumGreenSoft)
                                Text("Analyzing...")
                                    .font(.pulsumCallout)
                                    .foregroundStyle(Color.pulsumTextSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, PulsumSpacing.sm)
                        }

                        Color.clear
                            .frame(height: 1)
                            .id(chatBottomAnchor)
                    }
                    .padding(.vertical, PulsumSpacing.md)
                }
                .scrollDismissesKeyboard(.interactively)
                .onAppear {
                    proxy.scrollTo(chatBottomAnchor, anchor: .bottom)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    withAnimation(.pulsumStandard) {
                        proxy.scrollTo(chatBottomAnchor, anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.isSendingChat) { _, sending in
                    if sending {
                        withAnimation(.pulsumStandard) {
                            proxy.scrollTo(chatBottomAnchor, anchor: .bottom)
                        }
                    }
                }
            }

            if let message = viewModel.chatErrorMessage {
                MessageBubble(icon: "exclamationmark.circle", text: message, tint: Color.pulsumWarning)
            }
        }
        .frame(maxWidth: 520, alignment: .leading)
    }

    private var chatInputInset: some View {
        ChatInputView(viewModel: viewModel)
            .padding(.horizontal, PulsumSpacing.xl)
            .background(.ultraThinMaterial)
            .overlay(
                Divider()
                    .opacity(0.5),
                alignment: .top
            )
    }
}

struct InsightsScreen: View {
    @Bindable var viewModel: CoachViewModel
    let foundationStatus: String
    let consentGranted: Bool
    let triggerSettings: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: PulsumSpacing.lg) {
                todayPicksSection
                Divider()
                    .opacity(0)
                    .frame(height: PulsumSpacing.sm)
            }
            .frame(maxWidth: 520, alignment: .center)
            .padding(.horizontal, PulsumSpacing.sm)
        }
        .padding(.horizontal, PulsumSpacing.xl)
        .padding(.vertical, PulsumSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            Color.pulsumBackgroundBeige
                .ignoresSafeArea()
        )
        .task { await viewModel.refreshRecommendations() }
    }

    private var todayPicksSection: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.lg) {
            HStack(alignment: .center) {
                Text("Today's picks")
                    .font(.pulsumTitle2)
                    .foregroundStyle(Color.pulsumTextPrimary)
                Spacer()
                if viewModel.isLoadingCards {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.pulsumGreenSoft)
                }
            }
            .padding(.top, PulsumSpacing.sm)

            if let message = viewModel.cardErrorMessage {
                MessageBubble(icon: "exclamationmark.triangle", text: message, tint: Color.pulsumWarning)
            }

            if !consentGranted {
                ConsentPrompt(triggerSettings: triggerSettings)
            }

            if foundationStatus != "Apple Intelligence is ready." {
                MessageBubble(
                    icon: "sparkles.slash",
                    text: "Enhanced AI features require Apple Intelligence. Using on-device intelligence until it's ready.",
                    tint: Color.pulsumBlueSoft
                )
            }

            if viewModel.recommendations.isEmpty && !viewModel.isLoadingCards {
                MessageBubble(
                    icon: "clock.arrow.circlepath",
                    text: "We're gathering more context. Check back soon for fresh recommendations.",
                    tint: Color.pulsumTextSecondary
                )
            } else {
                VStack(spacing: PulsumSpacing.md) {
                    ForEach(viewModel.recommendations, id: \.id) { card in
                        RecommendationCardView(card: card) {
                            Task { await viewModel.markCardComplete(card) }
                        }
                    }
                }
            }

            if let cheerMessage = viewModel.cheerEventMessage {
                MessageBubble(icon: "heart.fill", text: cheerMessage, tint: Color.pulsumPinkSoft)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

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

private struct ConsentPrompt: View {
    let triggerSettings: () -> Void

    private let bannerCopy = "Pulsum can optionally use GPT‑5 to phrase brief coaching text. If you allow cloud processing, Pulsum sends only minimized context (no journals, no raw health data, no identifiers). PII is redacted. You can turn this off anytime in Settings ▸ Cloud Processing."

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            Text("Cloud processing is off")
                .font(.pulsumHeadline)
                .foregroundStyle(Color.pulsumTextPrimary)
            Text(bannerCopy)
                .font(.pulsumCallout)
                .foregroundStyle(Color.pulsumTextSecondary)
                .lineSpacing(4)
            Button(action: triggerSettings) {
                Text("Review Settings")
                    .font(.pulsumHeadline)
                    .foregroundStyle(Color.pulsumTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PulsumSpacing.sm)
            }
            .glassEffect(.regular.tint(Color.pulsumBlueSoft.opacity(0.7)).interactive())
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

private struct ChatBubble: View {
    let message: CoachViewModel.ChatMessage

    var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
            Text(message.text)
                .font(.pulsumBody)
                .foregroundStyle(message.role == .user ? Color.pulsumTextPrimary : Color.pulsumTextPrimary)
                .padding(.horizontal, PulsumSpacing.md)
                .padding(.vertical, PulsumSpacing.sm)
                .background(bubbleBackground)
                .cornerRadius(PulsumRadius.md)
                .shadow(
                    color: PulsumShadow.small.color,
                    radius: PulsumShadow.small.radius,
                    x: PulsumShadow.small.x,
                    y: PulsumShadow.small.y
                )

            Text(message.timestamp, style: .time)
                .font(.pulsumCaption2)
                .foregroundStyle(Color.pulsumTextTertiary)
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }

    private var bubbleBackground: Color {
        switch message.role {
        case .user:
            return Color.pulsumCardWhite
        case .assistant:
            return Color.pulsumMintGreen // Mint green for AI responses (from maindesign.png)
        case .system:
            return Color.pulsumBackgroundCream
        }
    }
}

private struct RecommendationCardView: View {
    let card: RecommendationCard
    let completionAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: PulsumSpacing.xxs) {
                    Text(card.title)
                        .font(.pulsumHeadline)
                        .foregroundStyle(Color.pulsumTextPrimary)
                        .lineSpacing(2)

                    BadgeView(text: card.sourceBadge)
                }

                Spacer()
            }

            Text(card.body)
                .font(.pulsumBody)
                .foregroundStyle(Color.pulsumTextSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if let caution = card.caution {
                HStack(spacing: PulsumSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.pulsumCaption)
                        .foregroundStyle(Color.pulsumWarning)
                    Text(caution)
                        .font(.pulsumCaption)
                        .foregroundStyle(Color.pulsumWarning.opacity(0.9))
                }
                .padding(.horizontal, PulsumSpacing.sm)
                .padding(.vertical, PulsumSpacing.xs)
                .background(Color.pulsumWarning.opacity(0.1))
                .cornerRadius(PulsumRadius.sm)
            }

            Button(action: completionAction) {
                Label("Mark complete", systemImage: "checkmark")
                    .font(.pulsumCallout.weight(.semibold))
                    .foregroundStyle(Color.pulsumTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PulsumSpacing.sm)
            }
            .glassEffect(.regular.tint(Color.pulsumGreenSoft.opacity(0.6)).interactive())
        }
        .padding(PulsumSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
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

private struct BadgeView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.pulsumCaption2.weight(.semibold))
            .foregroundStyle(Color.pulsumBlueSoft)
            .padding(.vertical, PulsumSpacing.xxs)
            .padding(.horizontal, PulsumSpacing.xs)
            .background(Color.pulsumBlueSoft.opacity(0.15))
            .cornerRadius(PulsumRadius.xs)
    }
}

extension View {
    @ViewBuilder func _debugKeyboardLayoutFix() -> some View {
#if DEBUG
        self.ignoresSafeArea(.keyboard, edges: .bottom)
#else
        self
#endif
    }
}
