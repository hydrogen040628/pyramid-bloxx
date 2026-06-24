# 🏛️ Pyramid Bloxx

A classic block-stacking arcade game built with Flutter — inspired by the legendary **Pyramid Bloxx** gameplay. Stack blocks as high as you can to build the tallest pyramid!

## 📱 Screenshots

> Desert night sky, golden blocks, ancient pyramid vibes.

## 🎮 Gameplay

- Blocks swing left and right automatically
- **Tap** to drop the block
- Land it on the previous block — the more centered, the better
- **Perfect drop** = no trimming + combo bonus points
- Block gets trimmed each imperfect drop → game over when block is too thin

## ✨ Features

- Smooth 60fps gameplay with Flutter CustomPainter
- Combo system (perfect streak multiplier)
- Local high score (SharedPreferences)
- Level progression (speed increases)
- Desert/pyramid visual theme
- Haptic feedback on drop
- Portrait-only orientation

## 🚀 Build for iOS

### Option 1: Codemagic (Recommended — no Mac needed)

1. Push this repo to GitHub
2. Sign up at [codemagic.io](https://codemagic.io)
3. Connect your GitHub repo
4. The `codemagic.yaml` is already configured
5. Click **Start build** → get your `.ipa`

### Option 2: Local Mac build

```bash
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release
```

### Option 3: Run on simulator/device

```bash
flutter pub get
flutter run
```

## 🛠️ Tech Stack

| Layer | Tech |
|---|---|
| Framework | Flutter 3.x |
| Language | Dart |
| Rendering | CustomPainter (Canvas API) |
| Storage | shared_preferences |
| Build (iOS) | Codemagic CI/CD |

## 📁 Project Structure

```
lib/
├── main.dart              # App entry point
├── models/
│   └── game_model.dart    # Game logic, physics, state
├── screens/
│   ├── home_screen.dart   # Title screen
│   └── game_screen.dart   # Main gameplay + painter
└── utils/                 # (reserved for helpers)
```

## 📄 License

MIT — build, remix, enjoy.
