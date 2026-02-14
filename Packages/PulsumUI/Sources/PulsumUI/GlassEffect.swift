import SwiftUI

public struct GlassEffectStyle: Equatable {
    public enum Intensity: Equatable {
        case ultraThin
        case thin
        case regular
        case thick
        case ultraThick

        var material: Material {
            switch self {
            case .ultraThin: return .ultraThinMaterial
            case .thin: return .thinMaterial
            case .regular: return .regularMaterial
            case .thick: return .thickMaterial
            case .ultraThick: return .ultraThickMaterial
            }
        }

        var shadowRadius: CGFloat {
            switch self {
            case .ultraThin: return 6
            case .thin: return 8
            case .regular: return 12
            case .thick: return 16
            case .ultraThick: return 20
            }
        }
    }

    public static var ultraThin: GlassEffectStyle { GlassEffectStyle(intensity: .ultraThin) }
    public static var thin: GlassEffectStyle { GlassEffectStyle(intensity: .thin) }
    public static var regular: GlassEffectStyle { GlassEffectStyle(intensity: .regular) }
    public static var thick: GlassEffectStyle { GlassEffectStyle(intensity: .thick) }
    public static var ultraThick: GlassEffectStyle { GlassEffectStyle(intensity: .ultraThick) }

    public var intensity: Intensity = .regular
    public var tintColor: Color?
    public var cornerRadius: CGFloat?
    public var isInteractive: Bool = false

    public init(intensity: Intensity = .regular,
                tintColor: Color? = nil,
                cornerRadius: CGFloat? = nil,
                isInteractive: Bool = false) {
        self.intensity = intensity
        self.tintColor = tintColor
        self.cornerRadius = cornerRadius
        self.isInteractive = isInteractive
    }

    public func tint(_ color: Color) -> GlassEffectStyle {
        var copy = self
        copy.tintColor = color
        return copy
    }

    public func cornerRadius(_ value: CGFloat) -> GlassEffectStyle {
        var copy = self
        copy.cornerRadius = value
        return copy
    }

    public func interactive(_ value: Bool = true) -> GlassEffectStyle {
        var copy = self
        copy.isInteractive = value
        return copy
    }
}

private struct GlassEffectModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let style: GlassEffectStyle
    private let defaultCornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        let radius = style.cornerRadius ?? defaultCornerRadius

        content
            .buttonStyle(GlassButtonStyle(style: style, cornerRadius: radius))
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(style.intensity.material)
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(style.tintColor ?? tintFallback)
                            .opacity(style.tintColor == nil ? 0.18 : 1)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.25 : 0.3), lineWidth: 1)
                    }
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.15),
                        radius: style.intensity.shadowRadius,
                        x: 0,
                        y: style.intensity.shadowRadius / 2
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    private var tintFallback: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.2)
    }
}

private struct GlassButtonStyle: ButtonStyle {
    let style: GlassEffectStyle
    let cornerRadius: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && style.isInteractive ? 0.96 : 1)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed && style.isInteractive ? 0.2 : 0))
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

public extension View {
    func glassEffect(_ style: GlassEffectStyle = .regular) -> some View {
        modifier(GlassEffectModifier(style: style))
    }
}

public struct GlassEffectContainer<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ZStack(alignment: .center) {
            content
        }
        .compositingGroup()
    }
}
