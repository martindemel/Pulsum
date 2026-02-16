import PulsumAgents
import SwiftUI

struct SafetyCardView: View {
    let message: String
    let crisisResources: CrisisResourceInfo?
    let dismiss: () -> Void

    private var emergencyNumber: String {
        crisisResources?.emergencyNumber ?? "911"
    }

    private var emergencyTelURL: URL? {
        let digits = emergencyNumber.filter(\.isNumber)
        return URL(string: "tel://\(digits)") ?? URL(string: "tel://911")
    }

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
                    Text(String(localized: "safety.card.title", defaultValue: "We noticed something important"))
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
                    if let url = emergencyTelURL {
                        Link(destination: url) {
                            emergencyCallLabel
                        }
                    }

                    // Crisis Line Button (locale-aware) or findahelpline.com fallback
                    crisisLineButton

                    // I'm Safe Button
                    Button(action: dismiss) {
                        Text(String(localized: "safety.card.dismiss", defaultValue: "I'm safe"))
                            .font(.pulsumBody)
                            .foregroundStyle(Color.pulsumTextPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, PulsumSpacing.sm)
                    }
                    .glassEffect(.regular.tint(Color.gray.opacity(0.3)).interactive())
                }
            }
            .padding(PulsumSpacing.xl)
            .background {
                RoundedRectangle(cornerRadius: PulsumRadius.xxl, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: PulsumRadius.xxl, style: .continuous)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    }
            }
            .shadow(
                color: Color.black.opacity(0.15),
                radius: 24,
                x: 0,
                y: 12
            )
            .padding(PulsumSpacing.lg)
        }
    }

    private var emergencyCallLabel: some View {
        HStack {
            Image(systemName: "phone.fill")
                .font(.pulsumHeadline)
            Text(String(localized: "Call \(emergencyNumber)"))
                .font(.pulsumHeadline)
        }
        .foregroundStyle(Color.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, PulsumSpacing.md)
        .background(Color.pulsumError)
        .cornerRadius(PulsumRadius.md)
    }

    @ViewBuilder
    private var crisisLineButton: some View {
        if let name = crisisResources?.crisisLineName,
           let number = crisisResources?.crisisLineNumber,
           let url = crisisLineTelURL(for: number) {
            Link(destination: url) {
                crisisLineLinkLabel(name: name, number: number)
            }
        } else if let url = URL(string: "https://findahelpline.com") {
            Link(destination: url) {
                findHelplineLinkLabel
            }
        }
    }

    private func crisisLineTelURL(for number: String) -> URL? {
        let crisisDigits = number.filter(\.isNumber)
        return URL(string: "tel://\(crisisDigits)") ?? URL(string: "tel://988")
    }

    private func crisisLineLinkLabel(name: String, number: String) -> some View {
        HStack {
            Image(systemName: "phone.fill")
                .font(.pulsumHeadline)
            Text("\(name) (\(number))")
                .font(.pulsumHeadline)
        }
        .foregroundStyle(Color.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, PulsumSpacing.md)
        .background(Color.pulsumWarning)
        .cornerRadius(PulsumRadius.md)
    }

    private var findHelplineLinkLabel: some View {
        HStack {
            Image(systemName: "globe")
                .font(.pulsumHeadline)
            Text(String(localized: "Find a Helpline"))
                .font(.pulsumHeadline)
        }
        .foregroundStyle(Color.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, PulsumSpacing.md)
        .background(Color.pulsumWarning)
        .cornerRadius(PulsumRadius.md)
    }
}
