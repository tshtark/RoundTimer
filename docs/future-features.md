# RoundTimer — Future Features

Features discussed during V1 development, organized by priority. Items marked with PRD reference were in the original product requirements document.

## V1.1 — Watch Companion + Custom Sounds (PRD)

- [ ] Apple Watch companion app (mirrors phone timer state) — PRD V1.1
- [ ] Watch haptic feedback on phase transitions (wrist taps) — PRD V1.1
- [ ] Watch complication showing active timer or "start workout" shortcut — PRD V1.1
- [ ] Custom recorded sounds (boxing bell, whistle, gym beeps) — PRD V1.1
- [ ] Source sounds from royalty-free libraries (freesound.org) or record custom
- [ ] Replace programmatically generated .wav tones with professional audio

## V1.2 — Nested Intervals (PRD)

- [ ] Complex interval structures: e.g., "3 rounds of (4x 20s work / 10s rest), then 1min rest between rounds" — PRD V1.2
- [ ] Nested builder UI
- [ ] Template presets for common nested patterns (Tabata sets, boxing with breaks)

## V2.0 — Standalone Watch + Sharing (PRD)

- [ ] Apple Watch runs independently (no phone required) — PRD V2.0
- [ ] Preset sync via WatchConnectivity or iCloud — PRD V2.0
- [ ] Preset sharing via URL scheme (share timer configs with training partners) — PRD V2.0
- [ ] Siri Shortcuts integration ("Hey Siri, start my boxing timer") — PRD V2.0

## Discussed During V1 Development (Not in PRD)

### High Priority
- [ ] Local notifications for phase transitions when app is backgrounded — requested by Tal, deferred to post-V1
- [ ] Onboarding / first-launch tutorial — shows key features to new users
- [ ] Preset detail preview — tap info area to see interval breakdown before starting (currently tapping anywhere starts timer)
- [ ] Drag-to-reorder presets on the home screen

### Medium Priority
- [ ] Preset color customization — let users assign accent colors to presets
- [ ] Workout history chart/graph — visual progress over weeks/months
- [ ] Export workout history as CSV
- [ ] iPad-native layout (currently runs in iPhone compatibility mode)

### Low Priority / Ideas
- [ ] Apple Health integration — write workout data to HealthKit
- [ ] Countdown voice (spoken "3, 2, 1" instead of beeps)
- [ ] Background music integration (control Spotify play/pause from timer)
- [ ] Widget for home screen showing next scheduled workout or streak

## Technical Debt

- [ ] AudioManager: current sounds are programmatically generated tones — replace with professionally recorded .caf files
- [ ] PresetListView is ~320 lines — could extract weekly summary and Quick Start into separate views
- [ ] `currentStreak` computed property has O(n * days) complexity — should cache or use Set-based lookup
- [ ] `configureEngineCallbacks()` captures closures that could hold stale references — consider a more robust callback pattern
- [ ] Widget extension `SoundEvent` enum is shared but widget never uses it — could cause maintenance issues when adding new cases
