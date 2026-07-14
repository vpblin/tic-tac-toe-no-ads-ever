import SwiftUI

enum GameMode: Equatable {
    case pvp
    case ai(Difficulty)
}

enum Outcome: Equatable {
    case playing
    case win(Player)
    case draw
}

@MainActor
final class GameModel: ObservableObject {
    @Published private(set) var board: [Player?] = Array(repeating: nil, count: 9)
    @Published private(set) var current: Player = .x
    @Published private(set) var outcome: Outcome = .playing
    @Published private(set) var winningLine: [Int]?
    @Published private(set) var isThinking = false

    // Match scores persist across rounds.
    @Published private(set) var scoreX = 0
    @Published private(set) var scoreO = 0
    @Published private(set) var draws = 0

    let mode: GameMode

    /// Alternates each round so X and O take turns going first.
    private var startingPlayer: Player = .x

    /// In solo mode the human is always X; the computer plays O.
    var aiMark: Player? { if case .ai = mode { return .o } else { return nil } }

    init(mode: GameMode) {
        self.mode = mode
        applyDemoIfPresent()
    }

    /// Screenshot support only — seeds a fixed board when TTT_DEMO_* is set.
    private func applyDemoIfPresent() {
        guard let seeded = Demo.board else { return }
        board = seeded
        current = Demo.turn
        scoreX = Demo.scoreX
        scoreO = Demo.scoreO
        draws = Demo.draws
        if let win = findWin(seeded) {
            outcome = .win(win.player)
            winningLine = win.line
        } else if !seeded.contains(nil) {
            outcome = .draw
        }
    }

    var isOver: Bool { outcome != .playing }

    var winner: Player? {
        if case .win(let p) = outcome { return p }
        return nil
    }

    func play(_ index: Int) {
        guard board[index] == nil, !isOver, !isThinking else { return }
        board[index] = current
        Haptics.place()

        if resolve() { return }
        current = current.other
        scheduleAIMoveIfNeeded()
    }

    /// Applies win/draw detection. Returns true if the game just ended.
    private func resolve() -> Bool {
        if let win = findWin(board) {
            outcome = .win(win.player)
            winningLine = win.line
            switch win.player {
            case .x: scoreX += 1
            case .o: scoreO += 1
            }
            Haptics.win()
            return true
        }
        if !board.contains(nil) {
            outcome = .draw
            draws += 1
            Haptics.draw()
            return true
        }
        return false
    }

    private func scheduleAIMoveIfNeeded() {
        guard case .ai(let difficulty) = mode, current == aiMark, !isOver else { return }
        isThinking = true
        let snapshot = board
        let ai = AIPlayer(difficulty: difficulty, mark: current)
        Task {
            // A beat of "thinking" so moves don't feel instant.
            try? await Task.sleep(nanoseconds: 500_000_000)
            let move = ai.chooseMove(board: snapshot)
            isThinking = false
            if let move { play(move) }
        }
    }

    /// New round, same match — alternates who starts and keeps the scoreboard.
    func newRound() {
        startingPlayer = startingPlayer.other
        Haptics.light()
        startRound(with: startingPlayer)
    }

    /// Wipes the scoreboard and starts a fresh match (X leads off again).
    func resetMatch() {
        scoreX = 0
        scoreO = 0
        draws = 0
        startingPlayer = .x
        Haptics.light()
        startRound(with: startingPlayer)
    }

    /// Clears the board for a round begun by `starter`. In solo mode the AI
    /// opens the round automatically when it's the one to go first.
    private func startRound(with starter: Player) {
        board = Array(repeating: nil, count: 9)
        current = starter
        outcome = .playing
        winningLine = nil
        isThinking = false
        scheduleAIMoveIfNeeded()
    }
}
