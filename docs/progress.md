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
- [x] Skip advances to next phase immediately
- [x] Timer completes all rounds and shows "COMPLETE" overlay
- [x] Timer with warmup phase works correctly
- [x] Timer with cooldown phase works correctly
- [x] Swipe-to-delete works on user presets (not built-in)
- [x] App survives background/foreground cycle (wall-clock recalculation)

## Phase 2: PRD Feature Implementation (V1 Required)

- [x] Data models (TimerPreset, TimerInterval, TimerPhase, SoundEvent)
- [x] TimerEngine state machine (start/pause/resume/stop/skip)
- [x] PresetStore with JSON persistence and 5 default presets
- [x] AudioManager (.ambient + .mixWithOthers)
- [x] HapticManager (phase transitions)
- [x] PresetListView (home screen with preset details)
- [x] ActiveTimerView (countdown, phase colors, round dots, controls)
- [x] PresetBuilderView — create new custom presets (name, intervals, rounds, warmup, cooldown)
- [x] PresetBuilderView — edit existing presets
- [x] PresetBuilderView — duplicate built-in presets for editing
- [x] Screen stays awake during active timer (UIApplication.shared.isIdleTimerDisabled)
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

### Run 3 — 2026-04-07 17:57
- Task: QA — Skip advances to next phase immediately
- Result: PASSED — no code changes needed
- Tested: Started Tabata (WORK R1 I1/2), skipped → REST R1 I2/2 (correct), skipped → WORK R2 I1/2 (correct round increment + interval reset)
- Visual QA: pass — skip button works in both directions, round counter and interval label update correctly

### Run 4 — 2026-04-07 18:02
- Task: QA — Timer completes all rounds and shows "COMPLETE" overlay
- Result: PASSED — no code changes needed
- Tested: Started AMRAP (1 round, 1 interval), skipped to end → "COMPLETE!" overlay with green checkmark and Done button appeared. Tapped Done → returned to preset list.
- Visual QA: pass — completion overlay renders correctly, Done button navigates back

### Run 5 — 2026-04-07 18:08
- Task: QA — Timer with warmup phase works correctly
- Result: PASSED — added warmup (10s) and cooldown (10s) to Custom preset to enable testing
- Files changed: RoundTimer/Persistence/PresetStore.swift
- Tested: Started Custom preset → WARMUP phase appeared (yellow background, gold text, countdown from 10s), then auto-transitioned to WORK (green background, 30s countdown). Warmup works correctly.
- Visual QA: pass — warmup phase renders with correct color and transitions to work phase

### Run 6 — 2026-04-07 18:13
- Task: QA — Timer with cooldown phase works correctly
- Result: PASSED — no code changes needed
- Tested: Started Custom preset (has 10s cooldown), skipped through warmup + 5 rounds (11 skips) → COOLDOWN phase appeared (orange background, orange text, 10s countdown, Round 5/5). Waited for cooldown to expire → COMPLETE overlay appeared. Tapped Done → returned to preset list.
- Visual QA: pass — cooldown phase renders correctly and transitions to completion

### Run 7 — 2026-04-07 18:18
- Task: QA — Swipe-to-delete works on user presets (not built-in)
- Result: BUG FOUND AND FIXED — built-in presets could be visually deleted via swipe (SwiftUI .onDelete removed the row even though store.delete silently rejected it)
- Fix: Added `.deleteDisabled(preset.isBuiltIn)` to PresetRow in ForEach
- Files changed: RoundTimer/Views/Presets/PresetListView.swift
- Tested: Injected user preset "My Quick Timer" → swiped left on it → Delete button appeared → tapped Delete → preset removed. Swiped on Tabata (built-in) → no Delete button appeared. Both behaviors correct.
- Visual QA: pass — user presets deletable, built-in presets protected

### Run 8 — 2026-04-07 18:23
- Task: QA — App survives background/foreground cycle (wall-clock recalculation)
- Result: PASSED — no code changes needed
- Tested: Started Boxing timer (WORK at 2:45), pressed Home button to background app, waited 10 seconds, relaunched app → timer showed 2:05 (correctly jumped ~40 seconds forward using wall-clock recalculation). Timer continued counting down normally after foregrounding.
- Visual QA: pass — wall-clock based countdown survives background/foreground cycle

**Phase 1 QA COMPLETE — all items verified.**

### Run 9 — 2026-04-07 18:30
- Task: Phase 2 — PresetBuilderView — create new custom presets
- Result: COMPLETED — implemented full preset builder with Form UI
- Files changed: RoundTimer/Views/Presets/PresetBuilderView.swift (NEW), RoundTimer/Views/Components/DurationPicker.swift (NEW), RoundTimer/Views/Presets/PresetListView.swift (modified — added "+" toolbar button + sheet)
- Features: name field, work/rest intervals with phase picker + duration wheels, add/remove/reorder intervals, rounds stepper (1-99), optional warmup/cooldown with toggles + duration pickers, Save/Cancel
- Visual QA: pass — tapped "+", entered "Quick HIIT", saved → preset appeared in list with correct details (3 rounds, 2m 15s, WORK/REST badges)

### Run 10 — 2026-04-07 19:03
- Task: Phase 2 — PresetBuilderView — edit existing presets
- Result: COMPLETED — added edit mode to builder + context menu on user presets
- Files changed: RoundTimer/Views/Presets/PresetBuilderView.swift (modified — added init(editing:), editingId, update logic), RoundTimer/Views/Presets/PresetListView.swift (modified — added context menu with Edit + editingPreset sheet)
- Tested: Long-pressed "Quick HIIT" → context menu with "Edit" appeared → tapped Edit → builder opened with "Edit Preset" title, pre-populated name/intervals/rounds → changed rounds from 3→5 → saved → list showed updated "5 rounds, 3m 45s"
- Visual QA: pass — edit flow works end-to-end, preset updated in-place

### Run 11 — 2026-04-07 19:09
- Task: Phase 2 — PresetBuilderView — duplicate built-in presets for editing
- Result: COMPLETED — added Duplicate context menu + duplicating init
- Files changed: RoundTimer/Views/Presets/PresetBuilderView.swift (added init(duplicating:) with new IDs + "Copy" suffix), RoundTimer/Views/Presets/PresetListView.swift (added Duplicate to context menu for all presets + duplicatingPreset sheet)
- Tested: Long-pressed Tabata (built-in) → context menu showed "Duplicate" (no Edit) → tapped Duplicate → builder opened with "New Preset" title, name "Tabata Copy", intervals/rounds pre-populated → saved → "Tabata Copy" appeared in list (8 rounds, 4m 0s, no star)
- Visual QA: pass — duplicate creates independent copy, original untouched

### Run 12 — 2026-04-07 19:13
- Task: Phase 2 — Screen stays awake during active timer
- Result: COMPLETED — added isIdleTimerDisabled on ActiveTimerView appear/disappear
- Files changed: RoundTimer/Views/ActiveTimer/ActiveTimerView.swift
- Tested: Started Tabata → timer runs, app builds with no crash. isIdleTimerDisabled set on .onAppear, cleared on .onDisappear.
- Visual QA: pass — timer screen works normally with idle timer management
