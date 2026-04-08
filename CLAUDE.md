# RoundTimer

Interval timer iOS app for HIIT, boxing, running, and custom workouts. Paid ($4.99), no ads, no accounts, no backend.

## Status: V1.0 SUBMITTED to App Store

V1.0 submitted April 8, 2026. Next phase: V1.1 (Watch + custom sounds).
See `docs/ship-summary.md` for App Store IDs, URLs, and test results.

## Documentation

| Doc | Purpose |
|-----|---------|
| `docs/prd.md` | Product vision, features, phases, user stories |
| `docs/architecture.md` | Data models, state machine, component contracts |
| `docs/ship-summary.md` | App Store listing details, App/Bundle/Team IDs, what was built |
| `docs/future-features.md` | V1.1/V1.2/V2.0 roadmap, technical debt |
| `docs/progress.md` | Run log of all 49 development runs with QA results |

**Read `docs/ship-summary.md` first** — it has all the IDs and URLs you need.

## Tech Stack

- **Language:** Swift 6.0, SwiftUI, iOS 17.0+
- **Frameworks:** ActivityKit (Live Activities), AVFoundation (audio)
- **Persistence:** JSON file in app documents (not SwiftData)
- **Project generation:** xcodegen (`project.yml` → `.xcodeproj`)
- **Xcode:** 26.4, simulators: iPhone 17 Pro (iOS 26.4)

## Commands

```bash
# Regenerate project (REQUIRED after adding/moving/deleting Swift files)
xcodegen generate

# Build for simulator
xcodebuild -project RoundTimer.xcodeproj -scheme RoundTimer \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Build for Tal's iPhone (connected via USB, Developer Mode enabled)
xcodebuild -project RoundTimer.xcodeproj -scheme RoundTimer \
  -destination 'platform=iOS,id=238F2C67-7800-582F-B432-6DC906C0F716' \
  -allowProvisioningUpdates build

# Archive + upload to App Store Connect
xcodebuild -project RoundTimer.xcodeproj -scheme RoundTimer \
  -destination 'generic/platform=iOS' -archivePath /tmp/RoundTimer.xcarchive \
  -allowProvisioningUpdates archive
xcodebuild -exportArchive -archivePath /tmp/RoundTimer.xcarchive \
  -exportOptionsPlist /tmp/ExportOptions.plist -exportPath /tmp/RoundTimerExport \
  -allowProvisioningUpdates
```

## Architecture

```
RoundTimer/              (iOS app target)
├── App/                 — entry point (RoundTimerApp), navigation (ContentView)
├── Models/              — TimerPreset, TimerInterval, TimerPhase, WorkoutRecord
├── Engine/              — TimerEngine (@Observable state machine), AudioManager, HapticManager, SettingsManager
├── Views/               — SwiftUI views (Presets/, ActiveTimer/, Settings/, History/, QuickTimer/)
├── LiveActivity/        — TimerActivityManager + TimerActivityAttributes (shared with widget)
├── Persistence/         — PresetStore, WorkoutHistoryStore (JSON files)
└── Resources/Sounds/    — 7 bundled .wav files

RoundTimerWidgetExtension/  — Live Activity + Dynamic Island rendering
RoundTimerWatch/            — watchOS app (V1.1, defer for now)
```

**TimerEngine** is `@MainActor @Observable`. Callbacks: `onPhaseChange`, `onCountdownTick`, `onHalfTime`, `onComplete`.

## Key Rules

1. **Audio plays over music** — `.ambient` + `.mixWithOthers` via `AVAudioPlayer` with bundled `.wav` files. NEVER use `AudioServicesPlaySystemSound` (bypasses audio session).
2. **Wall-clock countdown** — `Timer.scheduledTimer` for tick, but remaining time calculated from `Date()` difference. Ticks drift; wall clock doesn't.
3. **Swift 6 concurrency** — `@MainActor` on all engine/manager classes. `MainActor.assumeIsolated {}` in Timer closures. Don't call `@MainActor` methods from `App.init()`.
4. **xcodegen regenerate** — after ANY Swift file add/move/delete.
5. **Screen stays awake** during timer: `UIApplication.shared.isIdleTimerDisabled = true`.

## Working Conventions

- Tal is a senior TS/Node developer, zero Swift — Claude writes ALL Swift code
- Tal handles: product decisions, real device testing, App Store listing
- Ship iteratively — validate with real sales before adding complexity
- When uncertain about Swift APIs, check context7 docs first
