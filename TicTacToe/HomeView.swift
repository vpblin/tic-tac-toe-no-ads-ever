import SwiftUI

struct HomeView: View {
    let onStart: (GameMode) -> Void
    @State private var showDifficulty = Demo.showDifficulty

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            titleBlock

            Spacer(minLength: 28)

            if showDifficulty {
                difficultyBlock
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                modeBlock
                    .transition(.opacity)
            }

            Spacer(minLength: 24)

            VStack(spacing: 4) {
                Text("No ads. No tracking. No nonsense.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.dim)
                Text("Made by Blin Kazazi · AMK Solutions")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.dim.opacity(0.7))
            }
            .multilineTextAlignment(.center)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 28)
    }

    // MARK: Title

    private var titleBlock: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Text("X").foregroundStyle(Theme.cyan).neonGlow(Theme.cyan, radius: 12)
                Text("O").foregroundStyle(Theme.magenta).neonGlow(Theme.magenta, radius: 12)
                Text("X").foregroundStyle(Theme.cyan).neonGlow(Theme.cyan, radius: 12)
            }
            .font(.system(size: 34, weight: .heavy, design: .rounded))

            VStack(spacing: 2) {
                Text("TIC · TAC · TOE")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(Theme.text)
                Text("NO ADS EVER")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(Theme.magenta)
                    .neonGlow(Theme.magenta, radius: 8)
            }
        }
    }

    // MARK: Mode picker

    private var modeBlock: some View {
        VStack(spacing: 16) {
            NeonButton("2 PLAYERS", subtitle: "Pass & play on one phone", color: Theme.cyan) {
                onStart(.pvp)
            }
            NeonButton("VS COMPUTER", subtitle: "Play solo against the AI", color: Theme.magenta) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showDifficulty = true
                }
            }
        }
    }

    // MARK: Difficulty picker

    private var difficultyBlock: some View {
        VStack(spacing: 14) {
            Text("Choose your opponent")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundStyle(Theme.dim)

            ForEach(Difficulty.allCases) { level in
                NeonButton(level.rawValue.uppercased(), subtitle: level.blurb, color: Theme.magenta) {
                    onStart(.ai(level))
                }
            }

            Button {
                Haptics.light()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showDifficulty = false
                }
            } label: {
                Text("← Back")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.dim)
            }
            .padding(.top, 4)
        }
    }
}
