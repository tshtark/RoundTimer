# RoundTimer — Technical Architecture

## Overview

SwiftUI app with three targets: iOS app, WidgetKit extension (Live Activity), and watchOS app. No backend, no network, local persistence only.

## Data Models

### TimerPreset
A saved timer configuration. The unit of persistence.

```swift
struct TimerPreset: Identifiable, Codable {
    let id: UUID
    var name: String                    // "Tabata", "Boxing 12 Rounds"
    var intervals: [TimerInterval]      // ordered list of intervals
    var rounds: Int                     // how many times to repeat the interval set
    var warmup: TimeInterval?           // seconds, optional warmup before round 1
    var cooldown: TimeInterval?         // seconds, optional cooldown after final round
    var isBuiltIn: Bool                 // true = factory template, can't be deleted
    var lastUsedAt: Date?               // for sorting by recent
}
```

### TimerInterval
A single phase within a preset.

```swift
struct TimerInterval: Identifiable, Codable {
    let id: UUID
    var phase: TimerPhase               // work, rest
    var duration: TimeInterval          // seconds
    var name: String?                   // optional label ("jab combo", "plank")
}
```

### TimerPhase
Enum representing what kind of interval is active.

```swift
enum TimerPhase: String, Codable, CaseIterable {
    case warmup
    case work
    case rest
    case cooldown

    var displayName: String { ... }
    var color: Color { ... }            // green, blue, yellow, orange
    var defaultSound: SoundEvent { ... }
}
```

### TimerState
Runtime state during an active workout. NOT persisted — exists only while a timer is running.

```swift
@Observable
class TimerState {
    var currentPhase: TimerPhase = .warmup
    var timeRemaining: TimeInterval = 0
    var currentRound: Int = 1
    var totalRounds: Int = 1
    var currentIntervalIndex: Int = 0
    var totalIntervals: Int = 0
    var isRunning: Bool = false
    var isPaused: Bool = false
    var isFinished: Bool = false
    var presetName: String = ""
    var intervalName: String? = nil
    
    // Computed
    var phaseEndDate: Date { ... }      // used by Live Activity for Text(timerInterval:)
    var progress: Double { ... }        // 0.0 to 1.0 within current interval
}
```

## Timer Engine — State Machine

The `TimerEngine` is the brain. It's a plain Swift class with `@Observable` — no SwiftUI imports, no UIKit. This means it works identically on iPhone and Watch.

### State Machine Flow

```
[Idle] → start(preset) → [Warmup]* → [Work] ⇄ [Rest] → (repeat rounds) → [Cooldown]* → [Finished]
                                  skip↗  ↘skip
                                  
* Warmup and Cooldown are optional (only if preset defines them)
```

### Lifecycle

```
start(preset)
  ├── If warmup exists → enter warmup phase
  ├── Else → enter first work interval
  └── Start timer tick (every 1 second via Timer.scheduledTimer)

tick() — called every second
  ├── Decrement timeRemaining by 1
  ├── If timeRemaining == 3, 2, 1 → play countdown beep
  ├── If timeRemaining <= 0 → advanceToNextPhase()
  └── Update Live Activity if phase changed

advanceToNextPhase()
  ├── Current is warmup → enter intervals[0] (first work)
  ├── Current is work/rest and more intervals in set → next interval
  ├── Current is last interval in set and currentRound < totalRounds → round++, restart interval set
  ├── Current is last interval in last round → enter cooldown (or finish)
  └── Current is cooldown → finish

pause()  → stop timer tick, set isPaused = true, update Live Activity
resume() → restart timer tick, set isPaused = false, update Live Activity
stop()   → stop timer tick, reset all state, end Live Activity
skip()   → advance to next phase immediately
```

### Key Implementation Notes

- **Timer accuracy:** Use `Timer.scheduledTimer(withTimeInterval: 1.0)` for the tick. For the actual countdown display, calculate from `Date()` difference (wall clock), not accumulated ticks. Timer ticks can drift; wall clock doesn't.
- **Background behavior:** When app goes to background, the Timer still fires for ~30 seconds, then iOS suspends it. On returning to foreground, recalculate `timeRemaining` from wall clock. The Live Activity keeps showing the correct countdown regardless (it uses `Text(timerInterval:)` which is OS-rendered).
- **`return await` in any async catch blocks** — see error handling rules.

## Component Architecture

```
┌─────────────────────────────────────────────────┐
│                   SwiftUI Views                  │
│  PresetListView  PresetBuilderView  ActiveTimerView │
│         │              │                │        │
│         └──────────────┼────────────────┘        │
│                        │ observes                │
│                   TimerEngine (@Observable)       │
│                   │         │         │           │
│              AudioManager  HapticMgr  ActivityMgr │
│                   │                   │           │
│              AVAudioSession      ActivityKit      │
└─────────────────────────────────────────────────┘

┌─────────────────────────────┐
│   Widget Extension          │
│   TimerActivityAttributes   │  ← shared model between app and extension
│   TimerLiveActivity         │  ← lock screen / Dynamic Island UI
└─────────────────────────────┘

┌─────────────────────────────┐
│   Watch App (V1.1+)         │
│   WatchTimerView            │
│   WatchConnectivityMgr      │  ← sync with phone
│   TimerEngine (reused)      │  ← same engine, different UI
└─────────────────────────────┘
```

## Shared Code Between Targets

These files need to be shared between the iOS app and the Widget extension:

- `TimerActivityAttributes.swift` — defines the Live Activity data contract
- `TimerPhase.swift` — the phase enum (needed for rendering phase colors in the widget)

In xcodegen, this is handled by adding these files to both targets' source paths, or by creating a shared framework. For simplicity in V1, add them to both targets.

## Audio Architecture

```swift
class AudioManager {
    private var players: [SoundEvent: AVAudioPlayer] = [:]
    
    func configure() {
        // CRITICAL: .ambient + .mixWithOthers = play over music
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.ambient, options: [.mixWithOthers])
        try session.setActive(true)
    }
    
    func preloadSounds() {
        // Load all sound files into AVAudioPlayer instances at app launch
        // Avoids latency on first play
    }
    
    func play(_ event: SoundEvent) {
        players[event]?.currentTime = 0
        players[event]?.play()
    }
}

enum SoundEvent {
    case workStart
    case restStart
    case warmupStart
    case cooldownStart
    case countdownBeep       // 3, 2, 1
    case timerComplete
}
```

## Live Activity Architecture

### ActivityAttributes (shared between app and widget extension)

```swift
struct TimerActivityAttributes: ActivityAttributes {
    // Static — set once when activity starts, never changes
    let presetName: String
    let totalRounds: Int
    
    struct ContentState: Codable, Hashable {
        let phase: String           // "work", "rest", "warmup", "cooldown"
        let phaseColor: String      // hex color for the phase
        let currentRound: Int
        let intervalEndDate: Date   // for Text(timerInterval:) countdown
        let intervalName: String?
        let isPaused: Bool
    }
}
```

### Activity Lifecycle

```
Timer starts    → Activity.request(attributes, contentState, pushType: nil)
Phase changes   → activity.update(ActivityContent(state: newState, staleDate: nextEndDate))
Timer pauses    → activity.update(state with isPaused: true)
Timer resumes   → activity.update(state with new intervalEndDate)
Timer completes → activity.end(state, dismissalPolicy: .default)
Timer cancelled → activity.end(state, dismissalPolicy: .immediate)
```

No push notification infrastructure needed. All updates are local.

## Persistence

### PresetStore

```swift
@Observable
class PresetStore {
    private(set) var presets: [TimerPreset] = []
    private let fileURL: URL  // Documents/presets.json
    
    func load()                          // read from disk on app launch
    func save()                          // write to disk after any mutation
    func add(_ preset: TimerPreset)
    func update(_ preset: TimerPreset)
    func delete(_ preset: TimerPreset)   // only if !isBuiltIn
    func reorder(from: IndexSet, to: Int)
    
    static func defaultPresets() -> [TimerPreset]  // factory templates
}
```

Using JSON file persistence (not SwiftData) for V1 — simpler, no migration headaches, easy to debug by reading the file.

## Navigation Flow

```
App Launch
  └── PresetListView (home)
        ├── Tap preset → ActiveTimerView (countdown running)
        │     ├── Pause/Resume
        │     ├── Skip interval
        │     └── Stop → back to PresetListView
        │
        ├── Tap "+" → PresetBuilderView
        │     ├── Add/remove/reorder intervals
        │     ├── Set rounds, warmup, cooldown
        │     ├── Name the preset
        │     └── Save → back to PresetListView
        │
        ├── Swipe to delete user preset
        ├── Tap to edit existing preset → PresetBuilderView (edit mode)
        └── Tap template → can duplicate & edit, can't delete original
```

## File → Target Mapping

```
RoundTimer (iOS app target)
├── App/RoundTimerApp.swift
├── App/ContentView.swift
├── Models/TimerPreset.swift
├── Models/TimerInterval.swift
├── Models/TimerPhase.swift          ← also in widget extension
├── Models/TimerState.swift
├── Engine/TimerEngine.swift
├── Engine/AudioManager.swift
├── Engine/HapticManager.swift
├── Views/Presets/PresetListView.swift
├── Views/Presets/PresetBuilderView.swift
├── Views/Presets/PresetTemplatesView.swift
├── Views/ActiveTimer/ActiveTimerView.swift
├── Views/ActiveTimer/TimerControlsView.swift
├── Views/Components/IntervalRow.swift
├── Views/Components/PhaseIndicator.swift
├── Views/Components/BigCountdown.swift
├── LiveActivity/TimerActivityAttributes.swift  ← also in widget extension
├── LiveActivity/TimerActivityManager.swift
├── Persistence/PresetStore.swift
└── Resources/Sounds/*.caf

RoundTimerWidgetExtension (widget target)
├── RoundTimerWidgetBundle.swift
├── TimerLiveActivity.swift          ← lock screen + Dynamic Island UI
├── TimerActivityAttributes.swift    ← shared
└── TimerPhase.swift                 ← shared

RoundTimerWatch (watchOS target, V1.1+)
├── App/RoundTimerWatchApp.swift
└── Views/WatchTimerView.swift
```

## Build System

- **xcodegen** generates `.xcodeproj` from `project.yml`
- `.xcodeproj` is gitignored — regenerate with `xcodegen generate`
- Xcode 26, Swift 6.0, iOS 17.0+, watchOS 10.0+
- Simulators available: iPhone 17 Pro (iOS 26.4)
- Build command: `xcodebuild -project RoundTimer.xcodeproj -scheme RoundTimer -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
