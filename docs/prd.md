# RoundTimer — Product Requirements Document

## Vision

A premium interval timer for athletes. Paid once ($4.99), no ads, no accounts, no backend. The app leverages iOS platform features (Live Activities, Apple Watch haptics, audio session mixing) that competitors either don't use or gate behind subscriptions.

**One-line pitch:** "The interval timer that works the way your workout does."

## Target Users

### Primary: Regular interval trainers
- HIIT practitioners (Tabata, circuit training)
- Boxers / MMA fighters (timed rounds with rest)
- CrossFit athletes (EMOM, AMRAP, custom WODs)
- Runners doing interval/fartlek training

### Secondary: Coaches and group fitness
- Personal trainers running group classes
- Boxing coaches timing rounds
- CrossFit coaches programming WODs

### User Persona
**"Active Alex"** — Works out 4-6x/week. Uses a timer every session. Currently uses Seconds (free version with ads) or the built-in Clock app. Annoyed by ads interrupting workouts and timer sounds cutting out Spotify. Owns an Apple Watch. Would pay $5 once to never deal with this friction again.

## Core Differentiators

| Feature | RoundTimer | Seconds ($7.99) | Intervals Pro ($70) |
|---------|-----------|-----------------|-------------------|
| Live Activity on lock screen | Yes | No | No |
| Apple Watch standalone | Yes (V2) | Limited | Yes |
| Price | $4.99 once | $7.99 once | $70 lifetime / subscription |
| Ads | Never | Free tier has ads | No |
| Audio over music | Correct implementation | Interrupts music | Varies |
| Nested intervals | Yes (V1.2) | Yes | Yes |

## Release Phases

### V1.0 — iPhone MVP
Ship the core product. Validate with real sales before investing more.

**Features:**
- Simple interval timer (work/rest/rounds with optional warmup/cooldown)
- Built-in preset templates (Tabata, Boxing, EMOM, AMRAP, custom)
- Custom interval builder (create, save, edit, delete presets)
- Active timer screen with large, high-contrast countdown visible from across the room
- Live Activity on lock screen and Dynamic Island showing current phase + countdown
- Audio that plays OVER music (Spotify, Apple Music) — not interrupting it
- Phase transition sounds (distinct sounds for work start, rest start, countdown beeps)
- Pause/resume/stop/skip controls
- Local persistence (saved presets survive app restart)

**Not in V1:**
- Apple Watch (companion or standalone)
- Nested intervals
- Custom recorded sounds (use system/basic sounds)
- Workout history or statistics
- Sharing or social features
- iCloud sync

### V1.1 — Watch Companion + Custom Sounds
- Apple Watch companion app (mirrors phone timer state)
- Haptic feedback on phase transitions (wrist taps when interval changes)
- Watch complication showing active timer or "start workout" shortcut
- Custom recorded sounds (boxing bell, whistle, gym beeps)
- Sourced from royalty-free libraries or custom recorded

### V1.2 — Nested Intervals
- Complex interval structures: e.g., "3 rounds of (4x 20s work / 10s rest), then 1min rest between rounds"
- Nested builder UI
- Template presets for common nested patterns (Tabata sets, boxing with breaks)

### V2.0 — Standalone Watch + Sharing
- Apple Watch runs independently (no phone required)
- Preset sync via WatchConnectivity or iCloud
- Preset sharing via URL scheme (share timer configs with training partners)
- Siri Shortcuts integration ("Hey Siri, start my boxing timer")

## Feature Details

### Preset Templates (V1)

| Template | Structure | Default Timing |
|----------|-----------|---------------|
| **Tabata** | Work → Rest, 8 rounds | 20s work, 10s rest |
| **Boxing** | Work → Rest, 12 rounds | 3min work, 1min rest |
| **EMOM** (Every Minute on the Minute) | Work period within a minute, repeated | 1min rounds, work until done |
| **AMRAP** (As Many Rounds As Possible) | Single long work period | Configurable (10/15/20min) |
| **Custom** | User-defined work → rest, N rounds | User sets everything |

All templates are editable — they're starting points, not locked configurations.

### Custom Interval Builder (V1)

The builder lets users create a timer from scratch:

1. **Set intervals:** Add work and rest phases with custom durations
2. **Set rounds:** How many times the interval set repeats
3. **Optional warmup:** A single countdown before the first work phase
4. **Optional cooldown:** A single countdown after the last rest phase
5. **Name it:** Give the preset a name for the list
6. **Save:** Persisted locally

**Builder constraints:**
- Minimum 1 interval
- Maximum duration per interval: 99 minutes 59 seconds
- Maximum rounds: 99
- Intervals can be reordered via drag
- Each interval has: phase type (work/rest), duration, optional name label

### Active Timer Screen (V1)

The workout screen during an active timer. Optimized for glanceability from across a gym.

**Layout:**
```
┌─────────────────────────────┐
│         WORK                │  ← Phase name (large, colored)
│                             │
│        2:47                 │  ← Countdown (very large, high contrast)
│                             │
│     Round 3 / 12            │  ← Round progress
│                             │
│  ● ● ● ○ ○ ○ ○ ○ ○ ○ ○ ○  │  ← Visual round indicator
│                             │
│   [⏸]   [⏭]   [⏹]        │  ← Pause / Skip / Stop
│                             │
│   Tabata - Interval 1/2     │  ← Preset name + interval position
└─────────────────────────────┘
```

**Behavior:**
- Screen stays awake during active timer (UIApplication.shared.isIdleTimerDisabled = true)
- Phase color fills the background (green=work, blue=rest, yellow=warmup, orange=cooldown)
- 3-2-1 countdown beeps before each phase transition
- Final 10 seconds: countdown text pulses or changes color
- Pause freezes everything (Live Activity shows "Paused")
- Skip jumps to next interval (if in work→rest, skips to rest; if in rest, skips to next work)
- Stop ends the workout, returns to preset list

### Live Activity (V1)

Shown on lock screen and Dynamic Island during an active timer.

**Lock Screen:**
```
┌──────────────────────────────────────┐
│  🟢 WORK          2:47    R 3/12    │
└──────────────────────────────────────┘
```

**Dynamic Island (compact):**
```
  🟢 2:47
```

**Dynamic Island (expanded):**
```
┌──────────────────────────┐
│  WORK         Round 3/12 │
│        2:47              │
│  Tabata                  │
└──────────────────────────┘
```

**Technical:**
- Uses `Text(timerInterval:countsDown:)` for OS-native countdown (no push infra needed)
- Persists even if app is killed
- Updates phase/round via `Activity.update()` on transitions
- `staleDate` set to current interval end time
- Maximum duration: 8 hours (iOS limit) — more than sufficient for any workout

### Audio System (V1)

**Critical requirement:** Timer sounds must play OVER music, not interrupt it.

**Implementation:**
- `AVAudioSession.category = .ambient` with `.mixWithOthers` option
- This mixes timer sounds with whatever audio is playing (Spotify, Apple Music, podcasts)
- Timer sounds are short audio files (.caf or .wav), not system sounds

**Sound events:**
| Event | Sound | Timing |
|-------|-------|--------|
| Work phase starts | Strong beep / boxing bell | At 0:00 of work |
| Rest phase starts | Softer tone | At 0:00 of rest |
| 3-2-1 countdown | Three quick beeps | At 3s, 2s, 1s before transition |
| Warmup starts | Distinct tone | At 0:00 of warmup |
| Cooldown starts | Distinct tone | At 0:00 of cooldown |
| Timer complete | Victory/completion sound | When all rounds finish |

**V1 uses bundled system-style sounds.** Custom recorded sounds (boxing bell, whistle) come in V1.1.

### Persistence (V1)

- Presets saved locally using SwiftData or JSON file in app documents
- No iCloud sync in V1
- Built-in templates are always available (can't be deleted, can be duplicated and edited)
- User presets can be created, edited, reordered, deleted
- Last-used preset is remembered and highlighted on app launch

## Non-Functional Requirements

### Performance
- Timer accuracy: ±50ms (imperceptible to humans)
- App launch to "start timer" in under 2 taps from a saved preset
- Smooth animations at 60fps during countdown

### Accessibility
- VoiceOver support for all controls
- Dynamic Type support for countdown text
- High contrast mode support
- Haptic feedback accompanies all sound events

### Privacy
- Zero data collection
- No analytics SDK
- No network requests whatsoever
- App Store privacy label: "Data Not Collected"

### Supported Devices
- iPhone running iOS 17.0+ (portrait only)
- iPad running iPadOS 17.0+ via SwiftUI adaptive layout (all 4 orientations) — universal binary, not iPhone compatibility mode
- Apple Watch running watchOS 10.0+ (V1.1+)

## Business Model

- **Price:** $4.99 one-time purchase (USD)
- **No ads, no subscription, no IAP** — this IS the marketing message
- **Apple Small Business Program:** 15% commission (net $4.24/sale)
- **Revenue target:** 1,000+ downloads/month = $4,240+/month

## App Store Positioning

**Category:** Health & Fitness
**Keywords:** interval timer, HIIT timer, tabata timer, boxing timer, workout timer, round timer, circuit training, CrossFit timer

**Subtitle (30 chars):** "HIIT, Boxing & Workout Timer"

**Promotional text:** "No ads. No subscription. Just the best interval timer on iPhone."

**Screenshot themes:**
1. Active timer screen with bold countdown (hero shot)
2. Live Activity on lock screen showing workout progress
3. Preset templates (Tabata, Boxing, EMOM)
4. Custom interval builder
5. "No ads. No subscription. Pay once." messaging screen

## Success Metrics

| Metric | Target (first 6 months) |
|--------|------------------------|
| Downloads | 5,000+ |
| Revenue | $20,000+ |
| App Store rating | 4.7+ stars |
| Retention (D7) | 40%+ (high for a utility) |
| Retention (D30) | 25%+ |

## Open Questions

- Final app name (RoundTimer is a working name — check App Store for trademark conflicts)
- App icon design (likely: bold timer graphic with phase colors)
- Exact sound design for V1 (source from freesound.org or similar)
- Whether to include iPad layout in V1 or defer
