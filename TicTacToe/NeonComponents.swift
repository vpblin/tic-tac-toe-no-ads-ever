import SwiftUI

// MARK: - Backdrop

/// Deep-space gradient with a soft breathing glow behind the board.
struct NeonBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.bg1, Theme.bg0],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Theme.cyan.opacity(0.16), .clear],
                center: .center,
                startRadius: 4,
                endRadius: pulse ? 460 : 380
            )
            .blendMode(.screen)
            .opacity(0.9)
        }
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

/// Applies a layered neon glow to any shape/text.
struct NeonGlow: ViewModifier {
    var color: Color
    var radius: CGFloat = 14
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.9), radius: radius * 0.35)
            .shadow(color: color.opacity(0.6), radius: radius)
            .shadow(color: color.opacity(0.35), radius: radius * 1.8)
    }
}

extension View {
    func neonGlow(_ color: Color, radius: CGFloat = 14) -> some View {
        modifier(NeonGlow(color: color, radius: radius))
    }
}

// MARK: - Mark shapes

struct XShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return p
    }
}

/// A mark that draws itself on with a glowing stroke.
struct NeonMark: View {
    let player: Player
    var lineWidth: CGFloat = 9
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let rect = CGRect(x: (geo.size.width - side) / 2,
                              y: (geo.size.height - side) / 2,
                              width: side, height: side)
                .insetBy(dx: side * 0.16, dy: side * 0.16)

            ZStack {
                if player == .x {
                    XShape().path(in: rect)
                        .trimmedStroke(progress, width: lineWidth)
                } else {
                    Circle().path(in: rect)
                        .trimmedStroke(progress, width: lineWidth)
                }
            }
            .foregroundStyle(player.color)
            .neonGlow(player.color, radius: 18)
        }
        .onAppear {
            if reduceMotion {
                progress = 1
            } else {
                withAnimation(.easeOut(duration: 0.4)) { progress = 1 }
            }
        }
    }
}

private extension Path {
    func trimmedStroke(_ progress: CGFloat, width: CGFloat) -> some View {
        self.trimmedPath(from: 0, to: progress)
            .stroke(style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
}

// MARK: - Buttons

struct NeonButton: View {
    let title: String
    var subtitle: String?
    var color: Color
    var action: () -> Void
    @State private var pressed = false

    init(_ title: String, subtitle: String? = nil, color: Color, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.action = action
    }

    var body: some View {
        Button {
            Haptics.light()
            action()
        } label: {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 21, weight: .heavy, design: .rounded))
                    .tracking(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.dim)
                }
            }
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(color.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(color.opacity(0.9), lineWidth: 1.5)
                    .neonGlow(color, radius: 10)
            )
            .scaleEffect(pressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { p in
            withAnimation(.easeOut(duration: 0.12)) { pressed = p }
        }, perform: {})
    }
}
