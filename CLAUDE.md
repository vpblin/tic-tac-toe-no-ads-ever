# CLAUDE.md

Guidance for working in this repository.

## What this is

**Tic Tac Toe: No Ads Ever** — a native iOS game (SwiftUI, iOS 17+) published to
the App Store by AMK Solutions. No third-party dependencies, no network, no data
collection.

## Architecture

Two targets ship in one app:

| Folder | Target(s) | What it is |
| --- | --- | --- |
| `Shared/` | both | Game rules, theme, board view — no target-specific code |
| `TicTacToe/` | app | The standalone game (home screen, solo vs AI, pass & play) |
| `TicTacToeMessages/` | extension | The iMessage app (turn-based, over a conversation) |

The Xcode project uses **file-system-synchronized groups** (pbxproj
`objectVersion = 77`), so any `.swift` file added under one of these folders is
picked up automatically — no pbxproj editing needed. `Shared/` is listed in
*both* targets' `fileSystemSynchronizedGroups`, which is what gives both sides
the same code.

### Shared/

- `Theme.swift` — color tokens, the `Player` enum, and win-pattern constants.
- `AI.swift` — minimax opponent. `Difficulty` (easy / medium / unbeatable) sets a
  blunder rate; `unbeatable` plays perfectly (draw is the best a human can do).
  Used by the app only, but harmless in the extension.
- `BoardView.swift` — the 3×3 grid. **Stateless**: it renders the board it's
  handed and reports taps. The app drives it from `GameModel`; the extension
  drives it from the message payload.
- `NeonComponents.swift` — neon styling (glow modifier, animated X/O marks,
  buttons, background).
- `GameState.swift` — a whole game (board + turn + starter + series score) that
  serializes to a URL query. This is the iMessage wire format.
- `Haptics.swift` — thin UIKit haptics wrapper.

### TicTacToe/ (the app)

- `TicTacToeApp.swift` — app entry point.
- `ContentView.swift` — root router between the home screen and an active game.
- `GameModel.swift` — `@MainActor ObservableObject` holding all game state (board,
  turn, outcome, scores) plus win detection and round management. The **starting
  player alternates each round** via `startingPlayer` + `startRound(with:)`.
- `HomeView.swift` / `GameView.swift` — the screens.
- `Demo.swift` — **screenshot harness only**. Reads `TTT_DEMO_*` env vars to seed a
  fixed board/mode for App Store captures. No effect in normal use.

### TicTacToeMessages/ (the iMessage app)

Turn-based Tic Tac Toe played inside a conversation. **The message is the save
file**: every bubble carries the entire game in its URL, so there's no server, no
storage, and nothing to sync — which keeps the app's "no tracking, fully offline"
promise intact.

- `MessagesViewController.swift` — the `MSMessagesAppViewController`. Reads the
  selected bubble into a `GameState`, and stages the player's move as a new
  `MSMessage`.
- `MessageSession.swift` — `ObservableObject` the SwiftUI views bind to.
- `MessagesRootView.swift` — the compact (strip above the keyboard) and expanded
  (full board) presentations.
- `MessageBubble.swift` — renders the board into the bubble image via
  `ImageRenderer`.

## Conventions

- In solo mode the human is always **X**; the computer is **O**.
- Logic is synchronous except the AI move, which runs in a `Task` with a short
  delay so moves don't feel instant.
- Match scores persist across rounds. `newRound()` alternates the starter;
  `resetMatch()` clears scores and restarts with X.

### iMessage turn-taking

Whose turn it is comes from the message, not from stored state: you may move when
the selected bubble's `senderParticipantIdentifier` isn't your
`localParticipantIdentifier` and the game isn't over. These identifiers are stable
across devices within a conversation, so both phones agree — and neither player
can take two turns.

Moves within one game reuse the bubble's `MSSession`, so Messages updates the
existing bubble in place instead of stacking one per move. Starting a new round
creates a *new* `MSSession`, which leaves the finished game's final board in the
transcript.

An extension can't post to a conversation on its own: `conversation.insert(_:)`
only stages the move in the input field, and the player still taps Send.

## Build & run

```sh
# Build for a simulator (builds the app and embeds the iMessage extension)
xcodebuild -project TicTacToe.xcodeproj -scheme TicTacToe \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Regenerate the app icon (generated, not hand-drawn; must be opaque/no-alpha)
swift scripts/make_icon.swift TicTacToe/Assets.xcassets/AppIcon.appiconset/icon-1024.png

# Regenerate the iMessage app icons (all 12 sizes at once)
swift scripts/make_imessage_icons.swift \
  "TicTacToeMessages/Assets.xcassets/iMessage App Icon.stickersiconset"
```

Signing uses automatic provisioning — set your own Development Team in the
target's **Signing & Capabilities** before building to a physical device.

To exercise the iMessage app, run the **TicTacToeMessages** scheme and pick
Messages as the host app; the simulator's Messages app has a two-sided
conversation you can play against yourself.

## Screenshots

`scripts/ipad_shots.sh` (and the equivalent iPhone flow) launch the app in a
simulator with `SIMCTL_CHILD_TTT_DEMO_*` env vars to seed specific board states,
then capture App Store screenshots into `screenshots/`. The seeding logic is in
`Demo.swift`.

## Store assets

`store/APP_STORE_LISTING.md` holds the finalized App Store copy — name, subtitle,
description, keywords, and privacy answers.

## Gotchas

- App Store icons must be opaque with **no alpha channel** — both icon scripts
  use `CGImageAlphaInfo.noneSkipLast` to guarantee this.
- Adding `.swift` files under `Shared/`, `TicTacToe/`, or `TicTacToeMessages/`
  needs no pbxproj change; adding a new top-level source folder would.
- `ImageRenderer` has no view lifecycle, so it never runs `onAppear`. Anything
  that animates itself in from `onAppear` — `NeonMark`, the win streak — must be
  built with `animated: false` when snapshotted, or it renders **blank**. That's
  why `BoardView` takes an `animated` flag.
- The extension's `Info.plist` is excluded from its synchronized group via a
  `PBXFileSystemSynchronizedBuildFileExceptionSet`. Without that, the folder sync
  also copies it as a resource and the build fails with "Multiple commands
  produce .../Info.plist".
- The extension is a separate bundle ID (`solutions.amk.TicTacToe.Messages`) and
  therefore a separate App ID. Xcode registers it automatically with automatic
  signing.
