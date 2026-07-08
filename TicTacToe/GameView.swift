import SwiftUI

struct GameView: View {
    @StateObject private var game: GameModel
    let onExit: () -> Void

    init(mode: GameMode, onExit: @escaping () -> Void) {
        _game = StateObject(wrappedValue: GameModel(mode: mode))
        self.onExit = onExit
    }

    var body: some View {
        VStack(spacing: 20) {
            topBar
            scoreBar
            statusLine
            BoardView(game: game)
                .padding(.horizontal, 6)
            controls
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            Button {
                Haptics.light()
                onExit()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Menu")
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.dim)
            }
            Spacer()
            Text(modeLabel)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(Theme.dim)
        }
    }

    private var modeLabel: String {
        switch game.mode {
        case .pvp: "2 PLAYERS"
        case .ai(let d): "VS \(d.rawValue.uppercased())"
        }
    }

    // MARK: Scoreboard

    private var scoreBar: some View {
        HStack(spacing: 12) {
            scoreChip(player: .x, name: "X", score: game.scoreX)
            VStack(spacing: 2) {
                Text("Draws").font(.system(size: 12, weight: .bold, design: .rounded))
                Text("\(game.draws)").font(.system(size: 20, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(Theme.dim)
            scoreChip(player: .o, name: oName, score: game.scoreO)
        }
    }

    private var oName: String {
        if case .ai = game.mode { return "CPU" }
        return "O"
    }

    private func scoreChip(player: Player, name: String, score: Int) -> some View {
        let active = game.current == player && !game.isOver
        return VStack(spacing: 4) {
            Text(name)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .tracking(1)
            Text("\(score)")
                .font(.system(size: 30, weight: .black, design: .rounded))
        }
        .foregroundStyle(player.color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(player.color.opacity(active ? 0.16 : 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(player.color.opacity(active ? 0.9 : 0.25), lineWidth: 1.5)
        )
        .neonGlow(active ? player.color : .clear, radius: active ? 8 : 0)
        .animation(.easeOut(duration: 0.2), value: active)
    }

    // MARK: Status

    private var statusLine: some View {
        Text(statusText)
            .font(.system(size: 20, weight: .heavy, design: .rounded))
            .tracking(1)
            .foregroundStyle(statusColor)
            .neonGlow(game.isOver ? statusColor : .clear, radius: 10)
            .frame(height: 26)
            .animation(.easeOut(duration: 0.2), value: statusText)
    }

    private var statusText: String {
        switch game.outcome {
        case .win(let p):
            if case .ai = game.mode {
                return p == .x ? "YOU WIN!" : "CPU WINS"
            }
            return "\(p.rawValue) WINS!"
        case .draw:
            return "DRAW GAME"
        case .playing:
            if game.isThinking { return "CPU THINKING…" }
            if case .ai = game.mode { return game.current == .x ? "YOUR MOVE" : "CPU’S MOVE" }
            return "\(game.current.rawValue) TO MOVE"
        }
    }

    private var statusColor: Color {
        switch game.outcome {
        case .win(let p): p.color
        case .draw: Theme.text
        case .playing: game.current.color
        }
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: 14) {
            NeonButton(game.isOver ? "PLAY AGAIN" : "RESTART", color: Theme.cyan) {
                withAnimation(.easeOut(duration: 0.2)) { game.newRound() }
            }
            NeonButton("RESET SCORE", color: Theme.magenta) {
                withAnimation(.easeOut(duration: 0.2)) { game.resetMatch() }
            }
        }
    }
}
