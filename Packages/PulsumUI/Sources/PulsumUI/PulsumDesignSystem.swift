import SwiftUI

// MARK: - Pulsum Design System
// Light, fresh, minimalistic aesthetic inspired by iOS 26 Liquid Glass principles

extension Color {
    // MARK: - Background Colors (Light, Fresh, Beige-based from maindesign.png)
    static let pulsumBackgroundBeige = Color(red: 0.96, green: 0.95, blue: 0.93) // #F5F3ED - warm beige primary
    static let pulsumBackgroundCream = Color(red: 0.98, green: 0.97, blue: 0.95) // #FAF8F2 - soft cream
    static let pulsumBackgroundLight = Color(red: 0.97, green: 0.96, blue: 0.94) // #F7F5F0 - light beige
    static let pulsumBackgroundPeach = Color(red: 0.99, green: 0.96, blue: 0.94) // #FCF5F0 - peachy tint

    // MARK: - Accent Colors (Soft & Energizing from mockups)
    static let pulsumMintGreen = Color(red: 0.83, green: 0.93, blue: 0.85) // #D4EED4 - mint green (chat bubbles)
    static let pulsumMintLight = Color(red: 0.91, green: 0.96, blue: 0.91) // #E8F5E8 - light mint
    static let pulsumBlueSoft = Color(red: 0.66, green: 0.84, blue: 0.95) // #A8D5F2 - soft blue
    static let pulsumPinkSoft = Color(red: 0.98, green: 0.89, blue: 0.89) // #FAE3E3 - soft pink (secondary)
    static let pulsumGreenSoft = Color(red: 0.48, green: 0.80, blue: 0.48) // #7ACC7A - soft green accent

    // MARK: - Text Colors (Dark on Light - high contrast)
    static let pulsumTextPrimary = Color(red: 0.17, green: 0.17, blue: 0.18) // #2C2C2E - dark charcoal
    static let pulsumTextSecondary = Color(red: 0.56, green: 0.56, blue: 0.58) // #8F8F94 - medium gray
    static let pulsumTextTertiary = Color(red: 0.74, green: 0.74, blue: 0.76) // #BCBCC0 - light gray

    // MARK: - Card & Surface Colors
    static let pulsumCardWhite = Color.white
    static let pulsumCardShadow = Color.black.opacity(0.06)
    static let pulsumCardShadowMedium = Color.black.opacity(0.08)
    static let pulsumCardBorder = Color.black.opacity(0.04)

    // MARK: - Semantic Colors
    static let pulsumSuccess = Color(red: 0.20, green: 0.78, blue: 0.35) // #34C759 - green
    static let pulsumWarning = Color(red: 1.0, green: 0.58, blue: 0.0) // #FF9500 - orange
    static let pulsumError = Color(red: 1.0, green: 0.23, blue: 0.19) // #FF3B30 - red
    static let pulsumInfo = Color(red: 0.04, green: 0.52, blue: 1.0) // #0A84FF - blue
}

// MARK: - Spacing System
enum PulsumSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Corner Radius System
enum PulsumRadius {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 28
    static let xxxl: CGFloat = 32
}

// MARK: - Typography Extensions
extension Font {
    // MARK: - Display Fonts
    static let pulsumLargeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let pulsumTitle = Font.system(size: 28, weight: .bold, design: .default)
    static let pulsumTitle2 = Font.system(size: 22, weight: .semibold, design: .default)
    static let pulsumTitle3 = Font.system(size: 20, weight: .semibold, design: .default)

    // MARK: - Body Fonts
    static let pulsumHeadline = Font.system(size: 17, weight: .semibold, design: .default)
    static let pulsumBody = Font.system(size: 17, weight: .regular, design: .default)
    static let pulsumCallout = Font.system(size: 16, weight: .regular, design: .default)
    static let pulsumSubheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let pulsumFootnote = Font.system(size: 13, weight: .regular, design: .default)
    static let pulsumCaption = Font.system(size: 12, weight: .regular, design: .default)
    static let pulsumCaption2 = Font.system(size: 11, weight: .regular, design: .default)

    // MARK: - Data Display (Rounded for Metrics)
    static let pulsumDataXLarge = Font.system(size: 58, weight: .bold, design: .rounded)
    static let pulsumDataLarge = Font.system(size: 48, weight: .bold, design: .rounded)
    static let pulsumDataMedium = Font.system(size: 32, weight: .bold, design: .rounded)
    static let pulsumDataSmall = Font.system(size: 24, weight: .semibold, design: .rounded)
}

// MARK: - Animation Presets
extension Animation {
    static let pulsumQuick = Animation.spring(response: 0.3, dampingFraction: 0.75)
    static let pulsumStandard = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let pulsumSmooth = Animation.spring(response: 0.5, dampingFraction: 0.85)
    static let pulsumBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
}

// MARK: - Shadow Styles
struct PulsumShadow {
    static let small = (color: Color.pulsumCardShadow, radius: CGFloat(8), x: CGFloat(0), y: CGFloat(2))
    static let medium = (color: Color.pulsumCardShadowMedium, radius: CGFloat(12), x: CGFloat(0), y: CGFloat(4))
    static let large = (color: Color.pulsumCardShadowMedium, radius: CGFloat(20), x: CGFloat(0), y: CGFloat(8))
}

// MARK: - View Modifiers
extension View {
    /// Applies Pulsum card style: white background with soft shadow
    func pulsumCardStyle(padding: CGFloat = 20, cornerRadius: CGFloat = PulsumRadius.xl) -> some View {
        self
            .padding(padding)
            .background(Color.pulsumCardWhite)
            .cornerRadius(cornerRadius)
            .shadow(
                color: PulsumShadow.medium.color,
                radius: PulsumShadow.medium.radius,
                x: PulsumShadow.medium.x,
                y: PulsumShadow.medium.y
            )
    }

    /// Applies Pulsum glass material style (for navigation/controls)
    func pulsumGlassMaterial(material: Material = .ultraThinMaterial) -> some View {
        self
            .background(material)
            .overlay(
                RoundedRectangle(cornerRadius: PulsumRadius.xl, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}
