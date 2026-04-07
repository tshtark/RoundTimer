# RoundTimer

Interval timer iOS app for HIIT, boxing, running, and custom workouts. Paid ($4.99), no ads, no accounts, no backend.

## Documentation

| Doc | What's In It |
|-----|-------------|
| `docs/prd.md` | Full product vision, features, phases, user stories, UI layouts |
| `docs/architecture.md` | Data models, state machine, component contracts, file→target mapping |
| `docs/market-research.md` | Why this app, competitive analysis, rejected ideas, pricing rationale |

**Read these before implementing.** They contain validated decisions — don't re-question them without new information.

## Current Phase: V1 (iPhone MVP)

Simple work/rest/rounds timer with presets, Live Activity, audio over music. NO Watch app yet.

## Tech Stack

- **Language:** Swift 6.0, SwiftUI
- **Targets:** iOS 17.0+, watchOS 10.0+ (Watch target exists but is deferred to V1.1)
- **Key frameworks:** ActivityKit (Live Activities), AVFoundation (audio)
- **Persistence:** JSON file in app documents (not SwiftData)
- **Project generation:** xcodegen (`project.yml` → `.xcodeproj`)
- **Xcode:** 26.4, simulators: iPhone 17 Pro (iOS 26.4)

## Commands

```bash
# Regenerate Xcode project after changing project.yml
xcodegen generate

# Build for simulator
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project RoundTimer.xcodeproj \
  -scheme RoundTimer \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build

# Build and run in simulator
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project RoundTimer.xcodeproj \
  -scheme RoundTimer \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build | tail -5

# After adding/moving/deleting Swift files: always regenerate
xcodegen generate && xcodebuild -project RoundTimer.xcodeproj -scheme RoundTimer -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```

## Architecture Summary

```
RoundTimer/           (iOS app target)
├── App/              — entry point, navigation
├── Models/           — TimerPreset, TimerInterval, TimerPhase, TimerState
├── Engine/           — TimerEngine (state machine), AudioManager, HapticManager
├── Views/            — SwiftUI views
├── LiveActivity/     — ActivityKit manager + shared attributes
├── Persistence/      — PresetStore (JSON file)
└── Resources/Sounds/ — audio files (.caf/.wav)

RoundTimerWidgetExtension/  — Live Activity + Dynamic Island rendering
RoundTimerWatch/            — watchOS app (V1.1, defer for now)
```

**TimerEngine** is a plain `@Observable` class — no SwiftUI dependency. Works identically on iPhone and Watch.

## Key Rules

1. **Audio MUST use `.ambient` + `.mixWithOthers`** — timer sounds play over Spotify. Using `.playback` (the default) steals audio focus. This is the #1 competitor complaint.
2. **Live Activity uses `Text(timerInterval:countsDown:)`** — OS-native countdown, no push infra needed, works even if app is killed.
3. **Shared files between app and widget extension:** `TimerActivityAttributes.swift` and `TimerPhase.swift` must be in both targets' sources in `project.yml`.
4. **After adding/moving/deleting any Swift file**, run `xcodegen generate` to regenerate the project.
5. **Wall-clock time for accuracy** — Timer tick uses `Timer.scheduledTimer` but actual countdown is calculated from `Date()` difference. Ticks drift; wall clock doesn't.
6. **Screen stays awake** during active timer: `UIApplication.shared.isIdleTimerDisabled = true`

## Working Conventions

- Developer (Tal) is a senior TS/Node developer, zero Swift experience — Claude writes ALL Swift code
- Tal handles: product decisions, audio asset sourcing, App Store listing, real device testing
- Claude handles: all Swift/SwiftUI code, project configuration, architecture
- Ship iteratively — V1 without Watch, validate with real sales, then add complexity
- When uncertain about Swift APIs, check context7 docs or experiment first
