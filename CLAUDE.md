# RoundTimer

Interval timer iOS app for HIIT, boxing, running, and custom workouts. Paid ($4.99), no ads, no accounts, no backend.

## Product

- **V1 (current):** iPhone app with simple work/rest/rounds, built-in presets, custom builder, Live Activity, audio over music
- **V1.1:** Apple Watch companion (mirrors phone timer, haptics)
- **V1.2:** Nested intervals (complex multi-phase workouts)
- **V2:** Standalone Apple Watch (works without phone), preset sharing

## Tech Stack

- **Language:** Swift 6.0, SwiftUI
- **Targets:** iOS 17.0+, watchOS 10.0+
- **Key frameworks:** ActivityKit (Live Activities), AVFoundation (audio), WatchKit, WatchConnectivity
- **Persistence:** SwiftData or JSON (local only, no backend)
- **Project generation:** xcodegen (project.yml → .xcodeproj)

## Architecture

```
RoundTimer/
├── App/              — app entry point, navigation
├── Models/           — TimerPreset, TimerInterval, TimerPhase, TimerState
├── Engine/           — TimerEngine (state machine), AudioManager, HapticManager
├── Views/            — SwiftUI views (Presets/, ActiveTimer/, Components/)
├── LiveActivity/     — ActivityKit attributes, widget UI, manager
├── Persistence/      — PresetStore (save/load presets)
└── Resources/Sounds/ — custom audio files (.caf/.wav)

RoundTimerWidgetExtension/  — Live Activity + Dynamic Island rendering
RoundTimerWatch/            — Apple Watch app
```

## Key Design Decisions

- **TimerEngine is a plain @Observable class** — no SwiftUI dependency. Works identically on iPhone and Watch. Views observe it.
- **Audio uses `.ambient` category with `.mixWithOthers`** — timer sounds play over Spotify/Apple Music. Most competitors get this wrong.
- **Live Activity uses `Text(timerInterval:)`** — OS-native countdown, works even if app is killed. No push infrastructure needed.
- **One-time purchase, no subscription** — core differentiator against Seconds ($7.99) and Intervals Pro ($70 lifetime)

## Commands

```bash
# Regenerate Xcode project after changing project.yml
cd /Users/tal/WebstormProjects/RoundTimer && xcodegen generate

# Build (once project exists)
xcodebuild -project RoundTimer.xcodeproj -scheme RoundTimer -sdk iphonesimulator build

# Run in simulator
xcodebuild -project RoundTimer.xcodeproj -scheme RoundTimer -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Working Conventions

- Developer (Tal) is a senior TS/Node developer with zero Swift experience — Claude writes all Swift code
- Tal handles: product decisions, audio asset sourcing, App Store listing, real device testing
- Claude handles: all Swift/SwiftUI code, project configuration, architecture
- Ship iteratively — V1 without Watch, validate with real sales, then add complexity
