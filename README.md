# {{NextFinder}}

A Flutter card game about finding **neighboring values**: flip two cards whose numbers (or letters) differ by exactly one. Two classic modes race the stopwatch, and an endless mode, **Next to Infinity**, rewards high scores.

{{SCREENSHOT_OR_GIF_HERE}}

## Features

- **Two board types:** Numbers and Letters.
- **Three board sizes:** 10, 18 and 26 cards.
- **Next to Infinity mode:** 12 cards, a 2-minute countdown, scaling points and endlessly replaced cards.
- **Local records:** the best result for every mode is saved on the device.
- **Theme color picker:** the board, background and cards follow the chosen color.
- **Sound and vibration toggles:** the choice is remembered between launches.
- **Animations:** 3D card flip, pop effect on matches, a red highlight for wrong pairs and a floating score indicator.
- **Responsive layout:** the number of columns adapts to portrait and landscape.
- **Game rules dialog:** available from the app bar.

## How to Play

### Classic modes (Numbers / Letters)

1. Tap a card to flip it, then tap a second one.
2. If the two values are neighbors (for example 4 and 5, or C and D), they stay revealed.
3. If they are not neighbors, both cards turn red briefly and flip back.
4. A card with **no neighbor left** on the board is revealed automatically.
5. The stopwatch starts on the first tap. Reveal all cards as fast as you can.
6. At the end, a summary shows your time. Your best time per mode is saved.

### Next to Infinity

1. Match cards whose values differ by one. Matched cards are replaced with new, higher numbers and the board is reshuffled.
2. Points per match: `100 + (highest matched value x 10)`.
3. A card with no neighbor on the board is a **lonely card** and gives `50 + (value x 5)` points.
4. The countdown starts at 2 minutes (120 seconds) and turns red in the last 30 seconds.
5. When the time is up, a summary shows your score, your best score and the highest card reached.

## Tech Stack

| Area | Details |
|---|---|
| Framework | Flutter ({{FLUTTER_VERSION}}) |
| Language | Dart ({{DART_VERSION}}) |
| Local storage | [`shared_preferences`](https://pub.dev/packages/shared_preferences) |
| Date formatting | [`intl`](https://pub.dev/packages/intl) |
| Tested platforms | {{PLATFORMS, e.g. Android}} |

## Project Structure

```
lib/
|-- main.dart                    # {{App entry point}}
|-- first_screen.dart         # Mode and board size selection
|-- card_finder_screen.dart      # Classic game (FlipNextCard) and GameType enum
|-- next_to_infinity_screen.dart    # Next to Infinity mode
|-- high_score.dart              # Record keys, JSON building, saving best results
|-- summary_screen.dart          # End-of-game dialog
|-- theme_color_picker.dart      # Theme color picker widget
`-- func.dart                    # Helpers (neighbor check, color utilities, rules dialog)
assets/
`-- images/nextFinderBG.png      # Background image
```

## Data Storage

All data stays on the device. No account or network connection is needed.

| Key | Type | Purpose |
|---|---|---|
| `sound_enabled` | bool | Sound toggle |
| `vibration_enabled` | bool | Vibration toggle |
| `infinity_best_score` | int | Best score in Next to Infinity |
| `{gameType}_{boardSize}` | String (JSON) | Best result for each classic mode, for example `numberGame_18` |

A classic record is stored as JSON with the fields `elapsedSecond` and `date`. It is only overwritten when the new time is better.

## Getting Started

### Requirements

- Tested with Flutter 3.47.6, Dart 3.13.5
- Android Studio / VS Code with the Flutter and Dart extensions
- An Android device or emulator {{or other target}}

### Run

```bash
git clone {{REPOSITORY_URL}}
cd {{PROJECT_FOLDER}}
flutter pub get
flutter run
```

### Windows notes

- Plugins need symlink support. Enable **Developer Mode** in the Windows settings (`start ms-settings:developers`).
- If the project and the Pub cache are on **different drives** (for example the project on `D:` and the cache on `C:`), the Kotlin build can fail with `this and base files have different roots`. Set the `PUB_CACHE` environment variable to a folder on the same drive as the project (for example `D:\PubCache`), restart the terminal, then run `flutter clean` and `flutter pub get`.

## Roadmap

- [ ] Show the best results above the mode selection on the home screen
- [ ] Player names for records
- [ ] iOS release (vagy Google Play release)
- [ ] Daily challenge mode

## Author

ZmintZolika - {{LINK_TO_GITHUB_OR_PORTFOLIO}}

## License

Copyright (c) 2026 Your Name. All rights reserved.
