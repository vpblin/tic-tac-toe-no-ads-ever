import Foundation

enum Difficulty: String, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case unbeatable = "Unbeatable"

    var id: String { rawValue }

    var blurb: String {
        switch self {
        case .easy: "Loose play. Good for a warm-up."
        case .medium: "Sharp, but it slips sometimes."
        case .unbeatable: "Perfect play. Best you can do is draw."
        }
    }

    /// Odds the AI plays a random legal move instead of the optimal one.
    var blunderRate: Double {
        switch self {
        case .easy: 0.75
        case .medium: 0.35
        case .unbeatable: 0.0
        }
    }
}

/// Minimax opponent. `mark` is the side the AI plays.
struct AIPlayer {
    let difficulty: Difficulty
    let mark: Player

    func chooseMove(board: [Player?]) -> Int? {
        let empty = board.indices.filter { board[$0] == nil }
        guard !empty.isEmpty else { return nil }

        if Double.random(in: 0...1) < difficulty.blunderRate {
            return empty.randomElement()
        }
        return bestMove(board: board)
    }

    private func bestMove(board: [Player?]) -> Int? {
        var bestScore = Int.min
        var choice: Int?
        for i in board.indices where board[i] == nil {
            var next = board
            next[i] = mark
            let score = minimax(board: next, turn: mark.other, depth: 1)
            if score > bestScore {
                bestScore = score
                choice = i
            }
        }
        return choice
    }

    /// Positive favors the AI. Faster wins and slower losses score better,
    /// so the AI presses its advantage and stalls when behind.
    private func minimax(board: [Player?], turn: Player, depth: Int) -> Int {
        if let win = findWin(board) {
            return win.player == mark ? (10 - depth) : (depth - 10)
        }
        let empty = board.indices.filter { board[$0] == nil }
        if empty.isEmpty { return 0 }

        if turn == mark {
            var best = Int.min
            for i in empty {
                var next = board
                next[i] = turn
                best = max(best, minimax(board: next, turn: turn.other, depth: depth + 1))
            }
            return best
        } else {
            var best = Int.max
            for i in empty {
                var next = board
                next[i] = turn
                best = min(best, minimax(board: next, turn: turn.other, depth: depth + 1))
            }
            return best
        }
    }
}
