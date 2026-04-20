import SwiftUI
import Combine

extension ShapeStyle where Self == Color {
    static var obsidianPurple: Color {
        Color(red: 0.608, green: 0.427, blue: 1.0) // #9B6DFF
    }
}

extension Font {
    static func firaCode(_ style: TextStyle, weight: Weight = .regular) -> Font {
        .custom(firaCodeName(for: weight), size: style.size, relativeTo: style)
    }

    static func firaCode(size: CGFloat, weight: Weight = .regular) -> Font {
        .custom(firaCodeName(for: weight), size: size)
    }

    private static func firaCodeName(for weight: Weight) -> String {
        switch weight {
        case .bold: "FiraCodeRoman-Bold"
        case .semibold: "FiraCodeRoman-SemiBold"
        case .medium: "FiraCodeRoman-Medium"
        case .light: "FiraCodeRoman-Light"
        default: "FiraCodeRoman-Regular"
        }
    }
}

extension Date {
    var compactRelative: String {
        let seconds = Int(-timeIntervalSinceNow)
        if seconds < 60 { return "now" }
        if seconds < 3600 { return "\(seconds / 60)m" }
        if seconds < 86400 { return "\(seconds / 3600)h" }
        if seconds < 604800 { return "\(seconds / 86400)d" }
        return "\(seconds / 604800)w"
    }
}

struct PulseModifier: ViewModifier {
    let active: Bool
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(pulsing ? 0.5 : 1.0)
            .onChange(of: active) {
                if active {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { pulsing = true }
                } else {
                    withAnimation(.default) { pulsing = false }
                }
            }
            .onAppear {
                if active {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { pulsing = true }
                }
            }
    }
}

struct SpinningIcon: View {
    var systemName: String

    @State private var angle: Double = 0

    var body: some View {
        Image(systemName: systemName)
            .rotationEffect(.degrees(angle))
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }
    }
}

struct AnimatedDotsText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }
    @State private var dotCount = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(text + String(repeating: ".", count: dotCount + 1))
            .onReceive(timer) { _ in
                dotCount = (dotCount + 1) % 3
            }
    }
}

private extension Font.TextStyle {
    var size: CGFloat {
        switch self {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline: 17
        case .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        @unknown default: 17
        }
    }
}
