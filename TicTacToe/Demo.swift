import Foundation

/// Screenshot harness. Reads launch environment to preset a board state for
/// App Store captures. Does nothing unless the TTT_DEMO_* vars are set, so it
/// has no effect in the shipped app.
enum Demo {
    private static var env: [String: String] { ProcessInfo.processInfo.environment }

    static var mode: GameMode? {
        switch env["TTT_DEMO_MODE"] {
        case "pvp": .pvp
        case "ai": .ai(.unbeatable)
        default: nil
        }
    }

    static var board: [Player?]? {
        guard let s = env["TTT_DEMO_BOARD"], s.count == 9 else { return nil }
        return s.map { c in c == "X" ? .x : (c == "O" ? .o : nil) }
    }

    static var showDifficulty: Bool { env["TTT_DEMO_DIFF"] == "1" }
    static var turn: Player { env["TTT_DEMO_TURN"] == "O" ? .o : .x }
    static var scoreX: Int { Int(env["TTT_DEMO_SX"] ?? "") ?? 0 }
    static var scoreO: Int { Int(env["TTT_DEMO_SO"] ?? "") ?? 0 }
    static var draws: Int { Int(env["TTT_DEMO_DR"] ?? "") ?? 0 }
}
