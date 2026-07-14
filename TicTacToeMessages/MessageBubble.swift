import Messages
import SwiftUI
import UIKit

extension GameState {
    /// How this game looks as a bubble in the transcript: the board rendered as
    /// an image, with the turn and the series score underneath.
    @MainActor
    func messageLayout() -> MSMessageTemplateLayout {
        let layout = MSMessageTemplateLayout()
        layout.image = BubbleImage.render(self)
        layout.caption = caption
        layout.subcaption = scoreLine
        return layout
    }
}

/// Draws the board into the picture that rides along in the message.
enum BubbleImage {
    /// Points; Messages scales this into the bubble.
    private static let side: CGFloat = 320

    @MainActor
    static func render(_ state: GameState) -> UIImage? {
        let renderer = ImageRenderer(
            content: BubbleCard(state: state).frame(width: side, height: side)
        )
        renderer.scale = 3
        renderer.isOpaque = true
        return renderer.uiImage
    }
}

/// The board on the neon backdrop, drawn flat.
///
/// Deliberately not `NeonBackground` — that one animates a breathing glow in
/// `onAppear`, and `ImageRenderer` has no view lifecycle to run it. Everything
/// here renders correctly on the very first frame.
private struct BubbleCard: View {
    let state: GameState

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
                endRadius: 260
            )
            .blendMode(.screen)

            BoardView(
                board: state.board,
                winningLine: state.win?.line,
                winner: state.win?.player,
                interactive: false,
                animated: false
            )
            .padding(34)
        }
    }
}
