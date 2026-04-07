# RoundTimer V1 — Progress Tracker

This file is read and updated by the automated development loop. Each run picks the highest-priority incomplete item, implements it, QA's it visually, reviews the code, and commits.

## Status Legend
- [ ] Not started
- [~] In progress (may be partially done from a previous run)
- [x] Complete and visually verified

---

## Phase 1: QA — Visual & Interactive Testing of Existing Features

- [x] PresetListView renders all 5 built-in presets (Tabata, Boxing, EMOM, AMRAP, Custom)
- [x] Tapping a preset opens ActiveTimerView with countdown
- [x] WORK phase shows green background, REST phase shows blue background
- [x] Phase transitions work (WORK → REST → next round)
- [x] Round counter increments correctly
- [x] Stop button returns to preset list
- [x] Pause freezes countdown, Resume continues from where it stopped
- [ ] Skip advances to next phase immediately
- [ ] Timer completes all rounds and shows "COMPLETE" overlay
- [ ] Timer with warmup phase works correctly
- [ ] Timer with cooldown phase works correctly
- [ ] Swipe-to-delete works on user presets (not built-in)
- [ ] App survives background/foreground cycle (wall-clock recalculation)

## Phase 2: PRD Feature Implementation (V1 Required)

- [x] Data models (TimerPreset, TimerInterval, TimerPhase, SoundEvent)
- [x] TimerEngine state machine (start/pause/resume/stop/skip)
- [x] PresetStore with JSON persistence and 5 default presets
- [x] AudioManager (.ambient + .mixWithOthers)
- [x] HapticManager (phase transitions)
- [x] PresetListView (home screen with preset details)
- [x] ActiveTimerView (countdown, phase colors, round dots, controls)
- [ ] PresetBuilderView — create new custom presets (name, intervals, rounds, warmup, cooldown)
- [ ] PresetBuilderView — edit existing presets
- [ ] PresetBuilderView — duplicate built-in presets for editing
- [ ] Screen stays awake during active timer (UIApplication.shared.isIdleTimerDisabled)
- [ ] 3-2-1 countdown beeps with deduplicated firing (once per second, not per tick)
- [ ] Final 10 seconds visual indicator (pulse or color change on countdown text)
- [ ] Live Activity — start/update/end lifecycle wired to TimerEngine
- [ ] Live Activity — lock screen shows phase + countdown + round
- [ ] Live Activity — Dynamic Island compact and expanded views
- [ ] Last-used preset highlighted/sorted on app launch
- [ ] Built-in presets cannot be deleted (UI enforcement)
- [ ] Proper sound files for phase transitions (bundled .caf/.wav or system sounds that actually play)

## Phase 3: UI/UX Improvements

- [ ] Better color palette (not raw .green/.blue — use richer, gym-appropriate colors)
- [ ] Dark mode support and testing
- [ ] Smooth animations on phase transitions (background color crossfade)
- [ ] Countdown text pulse animation in final 10 seconds
- [ ] Larger, bolder round dots with better spacing
- [ ] Better typography hierarchy on PresetListView
- [ ] Empty state if no user presets yet (encouraging message)
- [ ] Confirmation dialog before stopping an active timer
- [ ] Smooth fullScreenCover transition animation
- [ ] Accessibility: VoiceOver labels on all controls
- [ ] Accessibility: Dynamic Type support on countdown text

## Phase 4: New Features (Beyond V1 PRD — Low Priority)

- [ ] (ideas will be added by the loop as inspiration strikes)

---

## Run Log

Each automated run appends a brief entry here.

### Run 1 — 2026-04-07 (manual session with Tal)
- Created all models, engine, persistence, views
- Built and verified in simulator: preset list + active timer with Tabata
- Set up XcodeBuildMCP with ui-automation for visual QA

### Run 2 — 2026-04-07 17:54
- Task: QA — Pause freezes countdown, Resume continues from where it stopped
- Result: PASSED — no code changes needed
- Tested: Started Tabata, paused at 0:13, waited 3 seconds (stayed at 0:13), resumed (continued counting down to 0:05), stopped and returned to preset list
- Visual QA: pass — app launched, pause/resume worked correctly, stop returned to home
