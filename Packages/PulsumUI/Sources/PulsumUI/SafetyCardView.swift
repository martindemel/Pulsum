import SwiftUI

struct SafetyCardView: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .transition(.opacity)
                .animation(.pulsumStandard, value: true)

            VStack(spacing: PulsumSpacing.lg) {
                // Warning Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(Color.pulsumError)
                    .symbolRenderingMode(.hierarchical)

                VStack(spacing: PulsumSpacing.sm) {
                    Text("We noticed something important")
                        .font(.pulsumTitle2)
                        .foregroundStyle(Color.pulsumTextPrimary)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(.pulsumBody)
                        .foregroundStyle(Color.pulsumTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                VStack(spacing: PulsumSpacing.md) {
                    // Emergency Call Button
                    Link(destination: URL(string: "tel://911")!) {
                        HStack {
                            Image(systemName: "phone.fill")
                                .font(.pulsumHeadline)
                            Text("Call 911")
                                .font(.pulsumHeadline)
                        }
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, PulsumSpacing.md)
                        .background(Color.pulsumError)
                        .cornerRadius(PulsumRadius.md)
                    }

                    // I'm Safe Button
                    Button(action: dismiss) {
                        Text("I'm safe")
                            .font(.pulsumBody)
                            .foregroundStyle(Color.pulsumTextPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, PulsumSpacing.sm)
                    }
                    .glassEffect(.regular.tint(Color.gray.opacity(0.3)).interactive())
                }
            }
            .padding(PulsumSpacing.xl)
            .background(Color.pulsumCardWhite)
            .cornerRadius(PulsumRadius.xxl)
            .shadow(
                color: PulsumShadow.large.color,
                radius: PulsumShadow.large.radius,
                x: PulsumShadow.large.x,
                y: PulsumShadow.large.y
            )
            .padding(PulsumSpacing.lg)
        }
    }
}
