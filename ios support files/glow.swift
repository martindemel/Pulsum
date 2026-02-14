import SwiftUI

struct GlowEffect: View {
    @State private var gradientStops: [Gradient.Stop] = GlowEffect.generateGradientStops()
    @State private var timers: [Timer] = []

    var body: some View {
        ZStack {
            EffectNoBlur(gradientStops: gradientStops, width: 6)
            Effect(gradientStops: gradientStops, width: 9, blur: 4)
            Effect(gradientStops: gradientStops, width: 11, blur: 12)
            Effect(gradientStops: gradientStops, width: 15, blur: 15)
        }
        .onAppear {
            let intervals: [(TimeInterval, Double)] = [
                (0.4, 0.5), (0.4, 0.6), (0.4, 0.8), (0.5, 1.0)
            ]
            for (interval, duration) in intervals {
                let t = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: duration)) {
                        gradientStops = GlowEffect.generateGradientStops()
                    }
                }
                timers.append(t)
            }
        }
        .onDisappear {
            timers.forEach { $0.invalidate() }
            timers.removeAll()
        }
    }

    // Function to generate random gradient stops
    static func generateGradientStops() -> [Gradient.Stop] {
        [
            Gradient.Stop(color: Color(hex: "BC82F3"), location: Double.random(in: 0 ... 1)),
            Gradient.Stop(color: Color(hex: "F5B9EA"), location: Double.random(in: 0 ... 1)),
            Gradient.Stop(color: Color(hex: "8D9FFF"), location: Double.random(in: 0 ... 1)),
            Gradient.Stop(color: Color(hex: "FF6778"), location: Double.random(in: 0 ... 1)),
            Gradient.Stop(color: Color(hex: "FFBA71"), location: Double.random(in: 0 ... 1)),
            Gradient.Stop(color: Color(hex: "C686FF"), location: Double.random(in: 0 ... 1))
        ].sorted { $0.location < $1.location }
    }
}

struct Effect: View {
    var gradientStops: [Gradient.Stop]
    var width: CGFloat
    var blur: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 55)
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(stops: gradientStops),
                        center: .center
                    ),
                    lineWidth: width
                )
                .frame(
                    width: UIScreen.main.bounds.width,
                    height: UIScreen.main.bounds.height
                )
                .padding(.top, -17)
                .blur(radius: blur)
        }
    }
}

struct EffectNoBlur: View {
    var gradientStops: [Gradient.Stop]
    var width: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 55)
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(stops: gradientStops),
                        center: .center
                    ),
                    lineWidth: width
                )
                .frame(
                    width: UIScreen.main.bounds.width,
                    height: UIScreen.main.bounds.height
                )
                .padding(.top, -26)
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var hexNumber: UInt64 = 0
        scanner.scanHexInt64(&hexNumber)

        let r = Double((hexNumber & 0xff0000) >> 16) / 255
        let g = Double((hexNumber & 0x00ff00) >> 8) / 255
        let b = Double(hexNumber & 0x0000ff) / 255

        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    GlowEffect()
}
