# CLAUDE.md

Guidance for working in this repository.

## What this is

**Tic Tac Toe: No Ads Ever** — a native iOS game (SwiftUI, iOS 17+) published to
the App Store by AMK Solutions. No third-party dependencies, no network, no data
collection.

## Architecture

All source lives in `TicTacToe/`. The Xcode project uses a **file-system-
synchronized group** (pbxproj `objectVersion = 77`), so any `.swift` file added
under `TicTacToe/` is picked up automatically — no pbxproj editing needed.

Key files:

- `TicTacToeApp.swift` — app entry point.
- `ContentView.swift` — root router between the home screen and an active game.
- `GameModel.swift` — `@MainActor ObservableObject` holding all game state (board,
  turn, outcome, scores) plus win detection and round management. The **starting
  player alternates each round** via `startingPlayer` + `startRound(with:)`.
- `AI.swift` — minimax opponent. `Difficulty` (easy / medium / unbeatable) sets a
  blunder rate; `unbeatable` plays perfectly (draw is the best a human can do).
- `HomeView.swift` / `GameView.swift` / `BoardView.swift` — the screens.
- `NeonComponents.swift` — reusable neon styling (glow modifier, animated X/O
  marks, buttons, background).
- `Theme.swift` — color tokens, the `Player` enum, and win-pattern constants.
- `Haptics.swift` — thin UIKit haptics wrapper.
- `Demo.swift` — **screenshot harness only**. Reads `TTT_DEMO_*` env vars to seed a
  fixed board/mode for App Store captures. No effect in normal use.

## Conventions

- In solo mode the human is always **X**; the computer is **O**.
- Logic is synchronous except the AI move, which runs in a `Task` with a short
  delay so moves don't feel instant.
- Match scores persist across rounds. `newRound()` alternates the starter;
  `resetMatch()` clears scores and restarts with X.

## Build & run

```sh
# Build for a simulator
xcodebuild -project TicTacToe.xcodeproj -scheme TicTacToe \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Regenerate the app icon (generated, not hand-drawn; must be opaque/no-alpha)
swift scripts/make_icon.swift TicTacToe/Assets.xcassets/AppIcon.appiconset/icon-1024.png
```

Signing uses automatic provisioning — set your own Development Team in the
target's **Signing & Capabilities** before building to a physical device.

## Screenshots

`scripts/ipad_shots.sh` (and the equivalent iPhone flow) launch the app in a
simulator with `SIMCTL_CHILD_TTT_DEMO_*` env vars to seed specific board states,
then capture App Store screenshots into `screenshots/`. The seeding logic is in
`Demo.swift`.

## Store assets

`store/APP_STORE_LISTING.md` holds the finalized App Store copy — name, subtitle,
description, keywords, and privacy answers.

## Gotchas

- App Store icons must be opaque with **no alpha channel** — `make_icon.swift`
  uses `CGImageAlphaInfo.noneSkipLast` to guarantee this.
- Adding `.swift` files under `TicTacToe/` needs no pbxproj change; adding a new
  top-level source folder would.
