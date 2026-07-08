import SwiftUI

struct ContentView: View {
    @State private var activeMode: GameMode? = Demo.mode

    var body: some View {
        ZStack {
            NeonBackground()

            if let mode = activeMode {
                GameView(mode: mode) {
                    withAnimation(.easeInOut(duration: 0.25)) { activeMode = nil }
                }
                .id(gameID(for: mode))
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            } else {
                HomeView { mode in
                    withAnimation(.easeInOut(duration: 0.25)) { activeMode = mode }
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(false)
    }

    /// Distinct id per launched mode so a fresh game starts each time.
    private func gameID(for mode: GameMode) -> String {
        switch mode {
        case .pvp: "pvp"
        case .ai(let d): "ai-\(d.rawValue)"
        }
    }
}

#Preview {
    ContentView()
}
