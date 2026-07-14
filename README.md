# Tic Tac Toe: No Ads Ever

A neon-arcade Tic Tac Toe for iOS — beautiful, instant, and completely free of ads and tracking.

Built with SwiftUI. Play pass-and-play with a friend on one phone, or go solo against a minimax AI with three difficulty levels — including an Unbeatable mode that plays perfect Tic Tac Toe.

## Screenshots

<p align="center">
  <img src="screenshots/01-home.png" width="220" alt="Home / mode select">
  <img src="screenshots/02-vs-ai.png" width="220" alt="Solo vs computer">
  <img src="screenshots/03-win.png" width="220" alt="Win streak">
  <img src="screenshots/04-difficulty.png" width="220" alt="Difficulty select">
</p>

## Features

- **Neon arcade design** — glowing X/O marks, animated win-lines, haptics
- **Play in iMessage** — turn-based against a friend, right inside a conversation
- **Two-player** pass & play on a single device
- **Solo vs computer** — Easy, Medium, and Unbeatable (perfect-play minimax)
- **Alternating starts** — X and O take turns going first each round
- Running scoreboard across rounds
- **No ads. No tracking. No accounts. Fully offline.**

## Play in iMessage

The app ships an iMessage extension. Open Tic Tac Toe from the app drawer in any
conversation, tap a square, and send — the board rides along in the bubble.
Your friend taps it, plays their square, and sends it back.

The message *is* the save file: every bubble carries the whole game (board, turn,
series score) encoded in its URL. No server, no accounts, nothing stored — the
conversation is the state. Moves in one game update the same bubble in place
rather than flooding the transcript.

## Build & run

1. Clone the repo and open `TicTacToe.xcodeproj` in Xcode 16 or later.
2. Select the **TicTacToe** target → **Signing & Capabilities** and set your own Development Team.
3. Choose an iPhone simulator (or a connected device) and press **⌘R**.

To try the iMessage app, run the **TicTacToeMessages** scheme with Messages as the
host — the simulator's Messages app gives you both sides of a conversation.

Requires iOS 17+. No third-party dependencies.

## Tech

- SwiftUI, iOS 17+
- Minimax AI opponent (`Shared/AI.swift`)
- iMessage app built on `MSMessagesAppViewController`; game state serialized into
  the message URL (`Shared/GameState.swift`), board snapshotted into the bubble
  with `ImageRenderer`
- Icons generated programmatically with Core Graphics (`scripts/make_icon.swift`,
  `scripts/make_imessage_icons.swift`)
- File-system-synchronized Xcode project (objectVersion 77); `Shared/` belongs to
  both targets

## Layout

| Path | What |
|------|------|
| `Shared/` | Code used by both targets (game rules, board view, theme, wire format) |
| `TicTacToe/` | The app (home screen, solo vs AI, pass & play) |
| `TicTacToeMessages/` | The iMessage app |
| `scripts/` | Icon generators + App Store screenshot capture |
| `store/` | App Store listing copy, keywords, privacy answers |
| `screenshots/` | App Store screenshots (iPhone 6.9" + iPad 13") |

## Privacy

The app collects no data — no analytics, no tracking, no network calls. Full policy: <https://amk.solutions/tic-tac-toe-privacy>

## License

MIT — see [LICENSE](LICENSE).

---

Made by **Blin Kazazi** · [AMK Solutions](https://amk.solutions)
