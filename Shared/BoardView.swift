import SwiftUI

/// The 3×3 grid: glowing lines, animated marks, and the winning streak.
///
/// Stateless on purpose — it renders whatever board it's handed. The app drives
/// it from `GameModel`; the iMessage extension drives it from the board carried
/// in the selected message.
struct BoardView: View {
    let board: [Player?]
    var winningLine: [Int]?
    var winner: Player?
    /// When false, taps are ignored — game over, AI thinking, or not your turn.
    var interactive: Bool = true
    /// False for static snapshots (the message bubble image), which have no
    /// view lifecycle to drive the draw-on animations.
    var animated: Bool = true
    var onTap: (Int) -> Void = { _ in }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = side / 3

            ZStack {
                NeonGridLines(side: side)

                ForEach(0..<9, id: \.self) { i in
                    if let mark = board[i] {
                        NeonMark(player: mark, animated: animated)
                            .frame(width: cell * 0.62, height: cell * 0.62)
                            .position(center(of: i, cell: cell))
                            .id(i) // fresh view per placement so the draw-on animation runs
                    }
                }

                // Invisible tap targets over each cell.
                ForEach(0..<9, id: \.self) { i in
                    Rectangle()
                        .fill(Color.white.opacity(0.001))
                        .frame(width: cell, height: cell)
                        .position(center(of: i, cell: cell))
                        .onTapGesture { onTap(i) }
                        .allowsHitTesting(interactive && board[i] == nil)
                }

                if let winningLine, let winner {
                    WinStreak(line: winningLine, cell: cell, color: winner.color, animated: animated)
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func center(of index: Int, cell: CGFloat) -> CGPoint {
        let col = CGFloat(index % 3)
        let row = CGFloat(index / 3)
        return CGPoint(x: (col + 0.5) * cell, y: (row + 0.5) * cell)
    }
}

/// Two vertical + two horizontal neon rails.
private struct NeonGridLines: View {
    let side: CGFloat

    var body: some View {
        let cell = side / 3
        let inset = cell * 0.12
        ZStack {
            ForEach(1..<3, id: \.self) { i in
                // vertical
                Capsule()
                    .fill(Theme.grid)
                    .frame(width: 3, height: side - inset * 2)
                    .position(x: CGFloat(i) * cell, y: side / 2)
                // horizontal
                Capsule()
                    .fill(Theme.grid)
                    .frame(width: side - inset * 2, height: 3)
                    .position(x: side / 2, y: CGFloat(i) * cell)
            }
        }
        .neonGlow(Theme.cyan.opacity(0.5), radius: 6)
    }
}

/// The glowing line drawn through the three winning cells.
private struct WinStreak: View {
    let line: [Int]
    let cell: CGFloat
    let color: Color
    let animated: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat

    init(line: [Int], cell: CGFloat, color: Color, animated: Bool) {
        self.line = line
        self.cell = cell
        self.color = color
        self.animated = animated
        _progress = State(initialValue: animated ? 0 : 1)
    }

    var body: some View {
        Path { p in
            p.move(to: center(of: line.first!))
            p.addLine(to: center(of: line.last!))
        }
        .trimmedPath(from: 0, to: progress)
        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
        .foregroundStyle(color)
        .neonGlow(color, radius: 20)
        .onAppear {
            guard animated else { return }
            if reduceMotion {
                progress = 1
            } else {
                withAnimation(.easeOut(duration: 0.45).delay(0.1)) { progress = 1 }
            }
        }
    }

    private func center(of index: Int) -> CGPoint {
        let col = CGFloat(index % 3)
        let row = CGFloat(index / 3)
        return CGPoint(x: (col + 0.5) * cell, y: (row + 0.5) * cell)
    }
}
