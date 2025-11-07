import SwiftUI

struct ConsentBannerView: View {
    let openSettings: () -> Void
    let dismiss: () -> Void

    private let bannerCopy = "Pulsum can optionally use GPT‑5 to phrase brief coaching text. If you allow cloud processing, Pulsum sends only minimized context (no journals, no raw health data, no identifiers). PII is redacted. You can turn this off anytime in Settings ▸ Cloud Processing."

    var body: some View {
        VStack(alignment: .leading, spacing: PulsumSpacing.md) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.pulsumTitle3)
                    .foregroundStyle(Color.pulsumBlueSoft)
                    .symbolRenderingMode(.hierarchical)
                Spacer()
                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.pulsumTextSecondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .accessibilityLabel("Dismiss cloud processing banner")
            }

            Text("Cloud processing is optional")
                .font(.pulsumHeadline)
                .foregroundStyle(Color.pulsumTextPrimary)

            Text(bannerCopy)
                .font(.pulsumCallout)
                .foregroundStyle(Color.pulsumTextSecondary)
                .lineSpacing(4)

            Button(action: openSettings) {
                Text("Review Settings")
                    .font(.pulsumCallout.weight(.semibold))
                    .foregroundStyle(Color.pulsumTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PulsumSpacing.sm)
            }
            .glassEffect(.regular.tint(Color.pulsumBlueSoft.opacity(0.7)).interactive())
        }
        .padding(PulsumSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: PulsumRadius.xl, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: PulsumRadius.xl, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
        }
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 16,
            x: 0,
            y: 8
        )
    }
}
