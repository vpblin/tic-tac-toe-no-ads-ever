#!/bin/bash
set -e
cd "/Users/blinkazazi/projects/amk/Tic Tac Toe"
IPAD=0D2753D3-0A51-4C57-ADDC-2EE7870C72B3   # iPad Pro 13-inch (M5), OS 26.1
BID=solutions.amk.TicTacToe

echo "Booting iPad simulator..."
xcrun simctl boot "$IPAD" 2>/dev/null || true
xcrun simctl bootstatus "$IPAD" >/dev/null 2>&1 || true

echo "Building for iPad simulator..."
xcodebuild -project TicTacToe.xcodeproj -scheme TicTacToe -configuration Debug \
  -destination "id=$IPAD" build 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:" | head

SIMAPP=$(find ~/Library/Developer/Xcode/DerivedData -name "TicTacToe.app" -path "*Debug-iphonesimulator*" -maxdepth 6 2>/dev/null | head -1)
echo "Installing $SIMAPP"
xcrun simctl install "$IPAD" "$SIMAPP"

shot() { # $1=file  (env via SIMCTL_CHILD_*)
  xcrun simctl terminate "$IPAD" "$BID" >/dev/null 2>&1 || true
  xcrun simctl launch "$IPAD" "$BID" >/dev/null 2>&1
  sleep 3
  xcrun simctl io "$IPAD" screenshot "screenshots/$1" >/dev/null 2>&1
  echo "captured $1"
}

shot ipad-01-home.png
SIMCTL_CHILD_TTT_DEMO_DIFF=1 shot ipad-02-difficulty.png
SIMCTL_CHILD_TTT_DEMO_MODE=ai SIMCTL_CHILD_TTT_DEMO_BOARD="XO  X    " SIMCTL_CHILD_TTT_DEMO_TURN=X \
SIMCTL_CHILD_TTT_DEMO_SX=1 SIMCTL_CHILD_TTT_DEMO_SO=0 shot ipad-03-vs-ai.png
SIMCTL_CHILD_TTT_DEMO_MODE=pvp SIMCTL_CHILD_TTT_DEMO_BOARD="XO  XO  X" SIMCTL_CHILD_TTT_DEMO_SX=2 SIMCTL_CHILD_TTT_DEMO_SO=1 shot ipad-04-win.png

echo "--- sizes ---"
for f in screenshots/ipad-*.png; do sips -g pixelWidth -g pixelHeight "$f" 2>/dev/null | tail -2 | tr '\n' ' '; echo " $f"; done
echo "DONE"
