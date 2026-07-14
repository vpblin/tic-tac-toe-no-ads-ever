import Messages
import SwiftUI

/// What the SwiftUI game binds to. `MessagesViewController` feeds it state from
/// the selected bubble and hands the resulting move back to Messages.
@MainActor
final class MessageSession: ObservableObject {
    @Published private(set) var state: GameState = .newGame
    /// True when it's this player's turn on a live board.
    @Published private(set) var canMove = true
    /// True once they've placed a mark and the bubble is sitting in the input
    /// field waiting on the Send button.
    @Published private(set) var awaitingSend = false
    @Published var presentationStyle: MSMessagesAppPresentationStyle = .compact

    /// `startsNewGame` tells the controller whether to open a new bubble thread.
    var onSend: ((GameState, _ startsNewGame: Bool) -> Void)?
    var onExpand: (() -> Void)?

    private var startsNewGame = true

    func adopt(state: GameState, canMove: Bool, startsNewGame: Bool) {
        self.state = state
        self.canMove = canMove
        self.startsNewGame = startsNewGame
        self.awaitingSend = false
    }

    func play(_ index: Int) {
        guard canMove, !awaitingSend, let moved = state.playing(index) else { return }

        Haptics.place()
        if moved.win != nil {
            Haptics.win()
        } else if moved.isDraw {
            Haptics.draw()
        }

        state = moved
        canMove = false
        awaitingSend = true
        onSend?(moved, startsNewGame)
    }

    /// Clears the board locally and lets this player open the next round. The
    /// bubble isn't created until they actually place a mark.
    func newRound() {
        Haptics.light()
        state = state.nextRound()
        canMove = true
        awaitingSend = false
        startsNewGame = true
    }

    func expand() { onExpand?() }

    // MARK: - Copy

    var statusText: String {
        if awaitingSend { return "TAP SEND ↑" }
        if let win = state.win { return "\(win.player.rawValue) WINS!" }
        if state.isDraw { return "DRAW GAME" }
        if canMove { return "YOUR MOVE · \(state.next.rawValue)" }
        return "WAITING FOR \(state.next.rawValue)"
    }

    var statusColor: Color {
        if let win = state.win { return win.player.color }
        if state.isDraw { return Theme.text }
        return state.next.color
    }

    /// A one-liner under the status explaining what to do next.
    var hintText: String? {
        if awaitingSend { return "Your move is ready in the message field." }
        if state.isOver { return "Next round alternates who goes first." }
        if canMove { return nil }
        return "It's their turn. Tap their bubble when they reply."
    }
}
