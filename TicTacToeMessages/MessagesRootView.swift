import Messages
import SwiftUI

/// Messages gives an app two shapes: a short strip above the keyboard
/// (`.compact`) and a full sheet (`.expanded`). The board only fits in the
/// latter, so compact is a status line and a way in.
struct MessagesRootView: View {
    @ObservedObject var game: MessageSession

    var body: some View {
        ZStack {
            NeonBackground()

            if game.presentationStyle == .compact {
                CompactView(game: game)
            } else {
                ExpandedView(game: game)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Compact

private struct CompactView: View {
    @ObservedObject var game: MessageSession

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("TIC · TAC · TOE")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Theme.text)
                Text(game.statusText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(game.statusColor)
            }

            Spacer(minLength: 8)

            Button {
                Haptics.light()
                game.expand()
            } label: {
                Text(game.canMove ? "PLAY" : "VIEW")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(
                        Capsule().fill(Theme.cyan.opacity(0.12))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Theme.cyan.opacity(0.9), lineWidth: 1.5)
                            .neonGlow(Theme.cyan, radius: 8)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
    }
}

// MARK: - Expanded

private struct ExpandedView: View {
    @ObservedObject var game: MessageSession

    var body: some View {
        VStack(spacing: 14) {
            scoreBar
            status

            BoardView(
                board: game.state.board,
                winningLine: game.state.win?.line,
                winner: game.state.win?.player,
                interactive: game.canMove && !game.awaitingSend,
                onTap: { game.play($0) }
            )
            .padding(.horizontal, 4)

            controls
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: Scoreboard

    private var scoreBar: some View {
        HStack(spacing: 12) {
            scoreChip(player: .x, score: game.state.scoreX)
            VStack(spacing: 2) {
                Text("Draws").font(.system(size: 12, weight: .bold, design: .rounded))
                Text("\(game.state.draws)").font(.system(size: 20, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(Theme.dim)
            scoreChip(player: .o, score: game.state.scoreO)
        }
    }

    private func scoreChip(player: Player, score: Int) -> some View {
        // Highlight whoever is on the clock, but only while the game is live.
        let active = game.state.next == player && !game.state.isOver
        return VStack(spacing: 4) {
            Text(player.rawValue)
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

    private var status: some View {
        VStack(spacing: 4) {
            Text(game.statusText)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .tracking(1)
                .foregroundStyle(game.statusColor)
                .neonGlow(game.state.isOver ? game.statusColor : .clear, radius: 10)

            Text(game.hintText ?? " ")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.dim)
                .multilineTextAlignment(.center)
        }
        .frame(height: 46)
        .animation(.easeOut(duration: 0.2), value: game.statusText)
    }

    // MARK: Controls

    @ViewBuilder
    private var controls: some View {
        if game.state.isOver && !game.awaitingSend {
            NeonButton("NEW ROUND", color: Theme.cyan) {
                withAnimation(.easeOut(duration: 0.2)) { game.newRound() }
            }
        } else {
            // Keeps the board from jumping around as the buttons come and go.
            Color.clear.frame(height: 1)
        }
    }
}
