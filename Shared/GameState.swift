import Foundation

/// A whole game of Tic Tac Toe, small enough to ride inside an iMessage.
///
/// The message *is* the save file: every bubble carries the full board, whose
/// turn it is, and the running series score, encoded in the message's URL. Both
/// devices rebuild the game from the message alone — nothing is stored, nothing
/// is synced, and no server is involved.
struct GameState: Equatable {
    /// Row-major, 9 cells.
    var board: [Player?]
    /// The mark to be played next.
    var next: Player
    /// Who opened this round. Kept so rounds can alternate who goes first.
    var starter: Player
    /// Series score across the conversation.
    var scoreX: Int
    var scoreO: Int
    var draws: Int

    static let newGame = GameState(
        board: Array(repeating: nil, count: 9),
        next: .x,
        starter: .x,
        scoreX: 0,
        scoreO: 0,
        draws: 0
    )
}

// MARK: - Outcome

extension GameState {
    var win: (player: Player, line: [Int])? { findWin(board) }
    var isDraw: Bool { win == nil && !board.contains(nil) }
    var isOver: Bool { win != nil || isDraw }

    /// The board after playing `next`'s mark at `index`, with the score
    /// updated if that move ended the game. Nil if the move isn't legal.
    func playing(_ index: Int) -> GameState? {
        guard board.indices.contains(index), board[index] == nil, !isOver else { return nil }

        var result = self
        result.board[index] = next

        if let win = result.win {
            switch win.player {
            case .x: result.scoreX += 1
            case .o: result.scoreO += 1
            }
        } else if result.isDraw {
            result.draws += 1
        } else {
            result.next = next.other
        }
        return result
    }

    /// A fresh board that keeps the series score and hands the opening move to
    /// whoever didn't get it last round.
    func nextRound() -> GameState {
        let starter = self.starter.other
        return GameState(
            board: Array(repeating: nil, count: 9),
            next: starter,
            starter: starter,
            scoreX: scoreX,
            scoreO: scoreO,
            draws: draws
        )
    }
}

// MARK: - Wire format

extension GameState {
    /// Nine characters — `X`, `O`, or `-` for an empty cell.
    var boardString: String {
        String(board.map { $0.map { Character($0.rawValue) } ?? "-" })
    }

    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "b", value: boardString),
            URLQueryItem(name: "n", value: next.rawValue),
            URLQueryItem(name: "s", value: starter.rawValue),
            URLQueryItem(name: "x", value: String(scoreX)),
            URLQueryItem(name: "o", value: String(scoreO)),
            URLQueryItem(name: "d", value: String(draws)),
        ]
    }

    init?(queryItems: [URLQueryItem]) {
        var values: [String: String] = [:]
        for item in queryItems { values[item.name] = item.value }

        guard let cells = values["b"], cells.count == 9,
              let next = values["n"].flatMap(Player.init(rawValue:)),
              let starter = values["s"].flatMap(Player.init(rawValue:))
        else { return nil }

        self.board = cells.map { cell -> Player? in
            switch cell {
            case "X": return .x
            case "O": return .o
            default: return nil
            }
        }
        self.next = next
        self.starter = starter
        self.scoreX = Int(values["x"] ?? "") ?? 0
        self.scoreO = Int(values["o"] ?? "") ?? 0
        self.draws = Int(values["d"] ?? "") ?? 0
    }

    /// The message payload. Also the fallback link for anyone who taps the
    /// bubble without the app installed.
    var url: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "amk.solutions"
        components.path = "/tictactoe"
        components.queryItems = queryItems
        return components.url!
    }

    init?(url: URL) {
        guard let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
            return nil
        }
        self.init(queryItems: items)
    }
}

// MARK: - Copy

extension GameState {
    /// Printed under the board in the message bubble. Both players see the same
    /// text, so it names the mark rather than saying "your turn".
    var caption: String {
        if let win { return "\(win.player.rawValue) wins!" }
        if isDraw { return "Draw game" }
        return "\(next.rawValue) to move"
    }

    var scoreLine: String {
        "X \(scoreX)   O \(scoreO)   Draws \(draws)"
    }

    /// Shown in notifications and in the transcript when the app can't render.
    var summary: String {
        if let win { return "Tic Tac Toe — \(win.player.rawValue) wins!" }
        if isDraw { return "Tic Tac Toe — draw game" }
        return "Tic Tac Toe — \(next.rawValue) to move"
    }
}
