import Messages
import SwiftUI
import UIKit

/// The iMessage app. Turns the selected message bubble into a live game, and
/// turns the player's move back into a bubble for the other side.
///
/// There is no server and no shared store: each message carries the whole game
/// (see `GameState`), so the conversation itself is the state.
final class MessagesViewController: MSMessagesAppViewController {

    private let game = MessageSession()

    // MARK: - Setup

    override func viewDidLoad() {
        super.viewDidLoad()

        game.onSend = { [weak self] state, startsNewGame in
            self?.send(state, startsNewGame: startsNewGame)
        }
        game.onExpand = { [weak self] in
            self?.requestPresentationStyle(.expanded)
        }

        let host = UIHostingController(rootView: MessagesRootView(game: game))
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)
    }

    // MARK: - Conversation lifecycle

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        game.presentationStyle = presentationStyle
        adopt(conversation)
    }

    /// The player tapped a game bubble in the transcript.
    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        super.didSelect(message, conversation: conversation)
        adopt(conversation)
        requestPresentationStyle(.expanded)
    }

    /// The staged move was sent — get out of the way so they can see it land.
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        super.didStartSending(message, conversation: conversation)
        dismiss()
    }

    /// They deleted the staged move from the input field instead of sending it.
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        super.didCancelSending(message, conversation: conversation)
        adopt(conversation)
    }

    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.willTransition(to: presentationStyle)
        game.presentationStyle = presentationStyle
    }

    // MARK: - Bridging

    /// Rebuilds the on-screen game from whatever bubble is selected.
    private func adopt(_ conversation: MSConversation) {
        guard let selected = conversation.selectedMessage,
              let url = selected.url,
              let state = GameState(url: url)
        else {
            // Nothing selected (or a bubble we can't read) — offer a fresh game.
            game.adopt(state: .newGame, canMove: true, startsNewGame: true)
            return
        }

        // You may move when the game is live and the last move wasn't yours.
        // Comparing participant identifiers is what keeps a player from taking
        // both turns; the identifiers are stable across devices in a
        // conversation, so both sides agree on whose turn it is.
        let theirMove = selected.senderParticipantIdentifier != conversation.localParticipantIdentifier
        game.adopt(state: state, canMove: !state.isOver && theirMove, startsNewGame: false)
    }

    /// Stages the move in the input field. The player still taps Send — an
    /// extension isn't allowed to post to a conversation on its own.
    private func send(_ state: GameState, startsNewGame: Bool) {
        guard let conversation = activeConversation else { return }

        // Continuing a game reuses its session so Messages updates the existing
        // bubble in place instead of stacking one per move. A new game gets a
        // new session, which leaves the finished game's final board in the
        // transcript.
        let session = startsNewGame
            ? MSSession()
            : (conversation.selectedMessage?.session ?? MSSession())

        let message = MSMessage(session: session)
        message.url = state.url
        message.summaryText = state.summary
        message.layout = state.messageLayout()

        conversation.insert(message) { error in
            if let error {
                NSLog("TicTacToe: could not stage move — \(error.localizedDescription)")
            }
        }
        requestPresentationStyle(.compact)
    }
}
