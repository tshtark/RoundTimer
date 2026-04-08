# RoundTimer

Interval timer iOS app for HIIT, boxing, running, and custom workouts. Paid ($4.99), no ads, no accounts, no backend.

## Documentation

| Doc | What's In It |
|-----|-------------|
| `docs/prd.md` | Full product vision, features, phases, user stories, UI layouts |
| `docs/architecture.md` | Data models, state machine, component contracts, file→target mapping |
| `docs/market-research.md` | Why this app, competitive analysis, rejected ideas, pricing rationale |

**Read these before implementing.** They contain validated decisions — don't re-question them without new information.

| Doc | What's In It |
|-----|-------------|
| `docs/ship-summary.md` | App Store listing details, App ID, Bundle ID, Team ID, what was built, test results |
| `docs/future-features.md` | Planned features for V1.1/V1.2/V2.0, technical debt, ideas discussed |
| `docs/progress.md` | Detailed run log of all 49 development runs with QA results |

## Current Phase: V1.0 SUBMITTED to App Store

V1.0 submitted April 8, 2026. App Store ID: 6761851794. Bundle ID: com.roundtimer.app.
Waiting for Apple review (24-48 hours). Next phase: V1.1 (Watch + custom sounds).

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

## Building for Real Device & App Store

```bash
# Build and run on Tal's iPhone (must be connected via USB, Developer Mode enabled)
xcodebuild -project RoundTimer.xcodeproj -scheme RoundTimer \
  -destination 'platform=iOS,id=238F2C67-7800-582F-B432-6DC906C0F716' \
  -allowProvisioningUpdates build

# Archive for App Store
xcodebuild -project RoundTimer.xcodeproj -scheme RoundTimer \
  -destination 'generic/platform=iOS' \
  -archivePath /tmp/RoundTimer.xcarchive \
  -allowProvisioningUpdates archive

# Upload to App Store Connect (needs ExportOptions.plist with method=app-store-connect)
xcodebuild -exportArchive \
  -archivePath /tmp/RoundTimer.xcarchive \
  -exportOptionsPlist /tmp/ExportOptions.plist \
  -exportPath /tmp/RoundTimerExport \
  -allowProvisioningUpdates
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
2. **Audio MUST use AVAudioPlayer with bundled .wav files** — `AudioServicesPlaySystemSound` bypasses AVAudioSession entirely. System sound paths (`/System/Library/Audio/UISounds/`) don't exist on real devices. Always bundle sound files in `Resources/Sounds/`.
3. **Live Activity uses `Text(timerInterval:countsDown:)`** — OS-native countdown, no push infra needed, works even if app is killed.
4. **Live Activity Info.plist key** — Must use `INFOPLIST_KEY_NSSupportsLiveActivities: true` in project.yml (not bare `NSSupportsLiveActivities`). Without the `INFOPLIST_KEY_` prefix, xcodegen treats it as a build setting, not a plist entry, and Live Activities silently fail.
5. **Shared files between app and widget extension:** `TimerPhase.swift` and `SoundEvent.swift` are added to both targets in `project.yml`. `TimerActivityAttributes` is defined directly in the widget bundle.
6. **After adding/moving/deleting any Swift file**, run `xcodegen generate` to regenerate the project.
7. **Widget extension Info.plist** — `NSExtension.NSExtensionPointIdentifier` must be set via `info.properties` in project.yml (not via build settings like `INFOPLIST_KEY_*`).
8. **Swift 6 strict concurrency** — Classes using UIKit types (UIImpactFeedbackGenerator, etc.) need `@MainActor`. `Timer.scheduledTimer` closures need `MainActor.assumeIsolated { }` wrapper. Don't call `@MainActor` methods from `App.init()` — use `ContentView.onAppear` instead.
9. **Wall-clock time for accuracy** — Timer tick uses `Timer.scheduledTimer` but actual countdown is calculated from `Date()` difference. Ticks drift; wall clock doesn't.
10. **Screen stays awake** during active timer: `UIApplication.shared.isIdleTimerDisabled = true`
11. **App Store icon must have no alpha channel** — use `sips` or PIL to flatten transparency onto black background before submission.
12. **iPad screenshots required** even for iPhone-only apps — resize iPhone screenshots to 2048x2732 for submission.
13. **App Store archive** — use `xcodebuild archive` then `xcodebuild -exportArchive` with `app-store-connect` method. Need `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad` for all 4 orientations.

## Working Conventions

- Developer (Tal) is a senior TS/Node developer, zero Swift experience — Claude writes ALL Swift code
- Tal handles: product decisions, audio asset sourcing, App Store listing, real device testing
- Claude handles: all Swift/SwiftUI code, project configuration, architecture
- Ship iteratively — V1 without Watch, validate with real sales, then add complexity
- When uncertain about Swift APIs, check context7 docs or experiment first
