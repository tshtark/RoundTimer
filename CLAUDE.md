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

## Prerequisites

- **`xcode-select` must point to Xcode.app**, not CommandLineTools: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`. Without this, `xcrun simctl` and XcodeBuildMCP fail.

## Commands

```bash
# Regenerate Xcode project after changing project.yml
xcodegen generate

# Build for simulator (no DEVELOPER_DIR needed if xcode-select is set correctly)
xcodebuild -project RoundTimer.xcodeproj -scheme RoundTimer \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# After adding/moving/deleting Swift files: always regenerate
xcodegen generate && xcodebuild -project RoundTimer.xcodeproj -scheme RoundTimer \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```

## Simulator Interaction (XcodeBuildMCP)

XcodeBuildMCP is configured as an MCP server for simulator workflows. Config: `.xcodebuildmcp/config.yaml`.

```bash
# Use XcodeBuildMCP tools instead of manual simctl commands:
# - screenshot, snapshot_ui (UI hierarchy with coordinates), tap (by label or coordinates)
# - build_run_sim (build + install + launch in one step)
# - Session defaults are set: project, scheme, simulatorId, bundleId
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

**TimerEngine** is an `@MainActor @Observable` class. Works identically on iPhone and Watch.

## Key Rules

1. **Audio MUST use `.ambient` + `.mixWithOthers`** — timer sounds play over Spotify. Using `.playback` (the default) steals audio focus. This is the #1 competitor complaint.
2. **Live Activity uses `Text(timerInterval:countsDown:)`** — OS-native countdown, no push infra needed, works even if app is killed.
3. **Shared files between app and widget extension:** `TimerPhase.swift` and `SoundEvent.swift` are added to both targets in `project.yml`. `TimerActivityAttributes` is defined directly in the widget bundle.
4. **After adding/moving/deleting any Swift file**, run `xcodegen generate` to regenerate the project.
5. **Widget extension Info.plist** — `NSExtension.NSExtensionPointIdentifier` must be set via `info.properties` in project.yml (not via build settings like `INFOPLIST_KEY_*`).
6. **Swift 6 strict concurrency** — Classes using UIKit types (UIImpactFeedbackGenerator, etc.) need `@MainActor`. `Timer.scheduledTimer` closures need `MainActor.assumeIsolated { }` wrapper.
5. **Wall-clock time for accuracy** — Timer tick uses `Timer.scheduledTimer` but actual countdown is calculated from `Date()` difference. Ticks drift; wall clock doesn't.
6. **Screen stays awake** during active timer: `UIApplication.shared.isIdleTimerDisabled = true`

## Working Conventions

- Developer (Tal) is a senior TS/Node developer, zero Swift experience — Claude writes ALL Swift code
- Tal handles: product decisions, audio asset sourcing, App Store listing, real device testing
- Claude handles: all Swift/SwiftUI code, project configuration, architecture
- Ship iteratively — V1 without Watch, validate with real sales, then add complexity
- When uncertain about Swift APIs, check context7 docs or experiment first
