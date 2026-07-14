import SwiftUI

/// Neon-arcade design tokens. One place to tune the whole look.
enum Theme {
    // Backdrop
    static let bg0 = Color(red: 0.02, green: 0.02, blue: 0.05)
    static let bg1 = Color(red: 0.05, green: 0.05, blue: 0.11)

    // Player marks
    static let cyan = Color(red: 0.14, green: 0.92, blue: 1.00)      // X
    static let magenta = Color(red: 1.00, green: 0.23, blue: 0.66)   // O

    // Structure & type
    static let grid = Color(red: 0.16, green: 0.22, blue: 0.40)
    static let text = Color(red: 0.93, green: 0.97, blue: 1.00)
    static let dim = Color(red: 0.62, green: 0.68, blue: 0.82)
}

enum Player: String {
    case x = "X"
    case o = "O"

    var other: Player { self == .x ? .o : .x }
    var color: Color { self == .x ? Theme.cyan : Theme.magenta }
}

/// The three winning-line triples on a 3×3 board.
let winPatterns: [[Int]] = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6]
]

func findWin(_ board: [Player?]) -> (player: Player, line: [Int])? {
    for line in winPatterns {
        if let p = board[line[0]], board[line[1]] == p, board[line[2]] == p {
            return (p, line)
        }
    }
    return nil
}
