# RoundTimer QA Findings

Running log of bugs, issues, and polish items found during QA sessions.
Append new findings at the top. Format matches the reporting section of `docs/qa-prompt.md`.

---

## 2026-04-09 — Verification pass (working-tree audit)

Audited every BUG entry in this file against the current source tree
(uncommitted changes in working tree, not yet committed). Build is clean
(`xcodegen generate` + simulator build, no warnings).

**Tally:** 30 bugs verified FIXED, 9 still OPEN.

**Still open after this pass — load-bearing items only:**
- **P2** Watch target still ships "Hello World" placeholder (`RoundTimerWatch/App/RoundTimerWatchApp.swift`) — installs an empty app on every paired Apple Watch.
- **P2** Quick Timer still counts a trailing rest (`QuickTimerView.swift:69-79`) — `3 × (30+15)` = 2:15 instead of 2:00.
- **P2** PresetStore still has no merge logic / stable built-in UUIDs (V1.1 upgrade trap).
- **P2** Lock-screen Live Activity & Dynamic Island still missing progress bar / cohesive layout (polish).
- **P2** Codable migration safety — release-checklist item, untouched.
- **P3** PRD/ship-summary docs still claim "iPhone compatibility mode" (app is universal).
- **P3** Nav title overlaps status bar at max Dynamic Type — `.navigationBarTitleDisplayMode` not set.
- **P3** `AudioManager.playCountdownIfNeeded` still marks tick played even when sound disabled (edge case).
- **P3** Day-Streak strict-ends-today semantics — design call, untouched.

Each "FIXED" status line below cites the file:line of the verifying evidence.

---

## 2026-04-09 — Fix pass (post-audit cleanup)

Took the 9 open items from the audit pass above, assessed each, reproduced /
fixed the ones that were truly bugs, and skipped the ones that are design calls
or shipping non-issues. Build clean after each change (`xcodegen generate` +
`build_sim`, no warnings).

**Updated tally:** 34 bugs verified FIXED, 5 still OPEN (4 design/polish calls
+ 1 reclassified to "dormant code").

### FIXED this pass

- **P3 — `AudioManager.playCountdownIfNeeded` edge case** — `AudioManager.swift:56-65`
  added an `isSoundEnabled` guard *before* the `lastCountdownTick` assignment.
  Flipping Sound Effects off mid-3-2-1 no longer causes the next tick at the
  same `secondsLeft` value to be silently skipped after re-enabling.
- **P3 — Nav title overlaps status bar at max Dynamic Type** — `PresetListView.swift:6, 152-158`
  added `@Environment(\.dynamicTypeSize)` and made `.navigationBarTitleDisplayMode`
  conditional: `.inline` at `dynamicTypeSize.isAccessibilitySize`, `.automatic`
  otherwise. The large "RoundTimer" title no longer scales into the status bar
  at the top accessibility tiers; everywhere else the large-title look is
  preserved.
- **P3 — PRD/ship-summary/future-features still claim "iPhone compat mode"** —
  rewrote the three lines (`docs/prd.md:223`, `docs/ship-summary.md:93`,
  `docs/future-features.md:39`) to reflect what the iter 9 audit confirmed via
  5 sources of truth: the app is a universal SwiftUI binary that supports all
  4 iPad orientations.
- **P2 — PresetStore stable UUIDs + merge logic** — `PresetStore.swift:25-27, 60-92, 130-149`
  added hardcoded UUIDs for the 5 V1.0 built-ins (`tabataID` … `customID`,
  `?? UUID()` fallback to satisfy the no-force-unwrap rule), threaded
  `migrateBuiltIns()` into `load()`. The migration runs after a successful
  decode and (1) name-matches existing built-ins and reassigns their canonical
  IDs in place — preserving `lastUsedAt` — and (2) appends any built-ins whose
  canonical ID is missing from the user's file. This unblocks shipping a new
  built-in in V1.1 without orphaning upgraders. Traced four scenarios in head:
  fresh install, V1.0 → V1.0.1 upgrade, V1.1 adds new built-in, V1.x renames
  built-in (last one is intentionally a no-op — renames must ship as new IDs).

### NOT FIXED this pass — explicit decisions

- **P2 — Watch target "Hello World" placeholder** — RECLASSIFIED to dormant
  code, not a shipping bug. `project.yml:42-43` shows that `RoundTimer.dependencies`
  only embeds the widget extension (`RoundTimerWidgetExtension`), not
  `RoundTimerWatch`. The Watch target compiles in isolation but is not
  embedded in the iOS app bundle, so it does NOT auto-install on a paired
  Apple Watch when the user downloads the iPhone app from the App Store. The
  iter 8 finding "installs an empty app on every paired Apple Watch" was
  inferred, never device-verified, and is contradicted by the build graph.
  V1.1 will replace `RoundTimerWatchApp.swift` with real Watch UI before
  adding the dependency edge — at which point this becomes load-bearing.
  Until then, the placeholder is harmless.
- **P2 — Quick Timer trailing rest** — DESIGN CALL, owner: Tal. The QA entry
  itself flags this as "design call more than a bug". Boxing (12×(3m+1m)=48m)
  applies the same convention, so fixing Quick Timer alone would be
  inconsistent. The fix is a 1-line change in `QuickTimerView.buildPreset()`
  but the question is whether to apply the same change to `defaultPresets()`'s
  built-in Boxing/Tabata/Custom too. Needs Tal's call.
- **P2 — Live Activity polish** (`RoundTimerWidgetBundle.swift`) — phase color,
  intervalName, and paused state are now wired (already FIXED earlier). The
  remaining items (progress bar, background gradient by phase, preset name on
  lock screen) are V1.1 polish, not bugs. Tracked in `docs/future-features.md`.
- **P2 — Codable migration discipline** — release-checklist item, applies the
  next time anyone adds a non-Optional field to `TimerPreset` /
  `WorkoutRecord` / `TimerInterval`. Not actually broken in V1.0. Captured in
  the V1.1 plan, no code change needed today.
- **P3 — Day-Streak strict-ends-today semantics** — pure design call. Both
  "ends today" and "ends today OR yesterday" are defensible. Awaiting Tal's
  decision.

---

<!-- Template (copy and fill in):
## YYYY-MM-DD — [session title]

### BUG: [one-line description]
- **Screen:** [which screen]
- **Steps:** [exact reproduction steps]
- **Expected:** [what should happen]
- **Actual:** [what actually happens]
- **Severity:** P0 (broken) / P1 (wrong) / P2 (ugly) / P3 (nitpick)
- **Status:** open / fixed in <commit> / wontfix
-->

## 2026-04-09 — QA loop pass 1 (Presets screen)

### BUG: Navigation bar buttons (Settings, History, Add Preset) missing from accessibility tree — ROOT CAUSE IDENTIFIED
- **Screen:** Presets / home (+ New Preset Cancel/Save, History Clear)
- **File:** `RoundTimer/Views/Presets/PresetListView.swift:152-174`
- **Root cause:** Two separate SwiftUI accessibility pitfalls combined:
  1. **Multiple buttons wrapped in an HStack inside a single `ToolbarItem`** — SwiftUI does not properly expose children of an HStack inside a ToolbarItem to the accessibility tree. The gear (Settings) and clock (History) buttons are HStacked in one `ToolbarItem(.topBarLeading)`:
     ```swift
     ToolbarItem(placement: .topBarLeading) {
         HStack(spacing: 16) {
             Button { showingSettings = true } label: { Image(systemName: "gearshape") }
             Button { showingHistory = true } label: { Image(systemName: "clock.arrow.circlepath") }
         }
     }
     ```
     Result: neither button appears in the a11y tree. The whole HStack is invisible to VoiceOver.
  2. **Image-label buttons without explicit `.accessibilityLabel()`** — Even if the buttons were in separate ToolbarItems, `Image(systemName: "gearshape")` alone has no human-readable label. SwiftUI will sometimes infer one from the SF Symbol name but this is unreliable for toolbar context. The `+` button is a standalone `ToolbarItem(.primaryAction)` with `Image(systemName: "plus")` and no explicit label — same problem.
- **Fix (copy-paste ready):**
  ```swift
  .toolbar {
      ToolbarItem(placement: .topBarLeading) {
          Button {
              showingSettings = true
          } label: {
              Image(systemName: "gearshape")
          }
          .accessibilityLabel("Settings")
      }
      ToolbarItem(placement: .topBarLeading) {
          Button {
              showingHistory = true
          } label: {
              Image(systemName: "clock.arrow.circlepath")
          }
          .accessibilityLabel("Workout History")
      }
      ToolbarItem(placement: .primaryAction) {
          Button {
              showingBuilder = true
          } label: {
              Image(systemName: "plus")
          }
          .accessibilityLabel("Add Custom Preset")
      }
  }
  ```
- **Other screens affected by the same pattern:**
  - `HistoryView.swift:64-69` — **"Clear" text button** was unreachable via `tap(label:)` despite being `Button("Clear", role: .destructive)` with a text label. Theoretically text toolbar buttons work, but the `.destructive` role combined with `.foregroundStyle(.red)` may be confusing either the MCP tap tool or SwiftUI's a11y. **Recommend adding `.accessibilityLabel("Clear all history")` explicitly.**
  - `PresetBuilderView.swift:126-135` — Cancel / Save are `Button("Cancel")` and `Button("Save")` text labels in `.cancellationAction` / `.confirmationAction` placements. These should work automatically — but tests showed inconsistent tap-by-label behavior. Worth adding explicit `.accessibilityLabel()` and `.accessibilityIdentifier()` to be defensive.
  - `QuickTimerView` and `SettingsView` (Done button) — these work correctly; their pattern can serve as reference.
- **Severity:** **P1** — core nav unreachable by accessibility users; PRD §Accessibility promises "VoiceOver support for all controls"; 1 line per button to fix.
- **Status:** **FIXED** — verified `PresetListView.swift:152-179` (ToolbarItemGroup with separate Buttons + `.accessibilityLabel` + `.accessibilityIdentifier` on each), `HistoryView.swift:64-72` (Clear button has `.accessibilityLabel("Clear all history")`), `PresetBuilderView.swift:144-157` (Cancel/Save have `.accessibilityLabel`)

### BUG: Preset cards are not grouped for VoiceOver — 8 swipes per preset
- **Screen:** Presets / home
- **Steps:** Enable VoiceOver (or inspect `snapshot_ui`) → focus a preset row
- **Expected:** Each preset card should be a single accessibility element (or have an `.accessibilityElement(children: .combine)` container) that reads "Custom, recent, 5 rounds, 4 minutes 5 seconds, work-rest, play button".
- **Actual:** Each card exposes 8 separate elements: name, star image, "Recent" badge, rounds, duration, play image, "WORK" tag, "REST" tag. A VoiceOver user must swipe 8 times to traverse one preset, and the name is disconnected from the Play button (so tapping "Play" has no preset context).
- **Severity:** P1 — makes presets extremely tedious for accessibility users and the Play target is ambiguous
- **Status:** **FIXED** — verified `PresetListView.swift:71-80` (whole row is now a `Button` wrapped with `.accessibilityElement(children: .ignore)` + combined `.accessibilityLabel` from `presetAccessibilityLabel(for:)` at lines 277-286 + `.accessibilityHint("Starts this workout")` + `.accessibilityAddTraits(.isButton)`)

### BUG: Star icon labeled "Favorite" is actually a built-in preset marker — label is wrong
- **Screen:** Presets / home
- **Correction from iteration 1:** I initially thought stars were meaningless because all 5 presets had them. Iteration 4 created a custom preset and confirmed **custom presets have NO star**. So the star IS meaningful — it marks built-in presets — but its VoiceOver label "Favorite" is wrong.
- **Expected:** If the star marks built-in presets, its AXLabel should be "Built-in preset" (or be `.accessibilityHidden(true)` if the label is redundant with the preset name context).
- **Actual:** VoiceOver hears "Favorite" next to every built-in preset's name. A user expecting to tap the star to unfavorite will find it's actually an `AXImage` (not a button) — so the label creates a broken mental model.
- **Fix:**
  ```swift
  Image(systemName: "star.fill")
      .accessibilityLabel("Built-in preset")
  // OR if the visual is purely decorative:
  Image(systemName: "star.fill")
      .accessibilityHidden(true)
  ```
- **Severity:** P3 — confusing a11y label but not functionally broken; custom presets (which don't have the star) are correctly distinguished in the layout.
- **Status:** **FIXED** — verified `PresetListView.swift:412-416` uses `.accessibilityHidden(true)` on the star Image (the row's combined label includes "built-in preset" via `presetAccessibilityLabel`)

### BUG: Play control is `AXImage` not `AXButton`, with ambiguous label "Play"
- **Screen:** Presets / home
- **Steps:** Inspect snapshot_ui → find `play.circle.fill` elements
- **Expected:** `AXButton` with label like "Start Tabata workout" so VoiceOver announces it as tappable and identifies which preset will start.
- **Actual:** `type: "Image"`, `role: "AXImage"`, `AXLabel: "Play"`. VoiceOver users won't hear it as a button, and five play buttons all labeled just "Play" are indistinguishable.
- **Severity:** P2
- **Status:** **FIXED** — verified `PresetListView.swift:448-451` (play icon is `.accessibilityHidden(true)`); the row Button itself carries the per-preset label and `.isButton` trait

### BUG: "This Week" stat numbers separated from their labels in a11y tree
- **Screen:** Presets / home, weekly summary card
- **Steps:** Inspect snapshot_ui → numbers "1", "2m", "0" at y=231 and labels "Workout", "Total Time", "Day Streak" at y=269 are separate AXStaticText nodes
- **Expected:** Each stat should be a single a11y element (`.accessibilityElement(children: .combine)`) reading "1 Workout", "2 minutes Total Time", "0 Day Streak".
- **Actual:** VoiceOver would swipe past "1" then separately hear "Workout" — the association requires the user to remember spatial layout.
- **Severity:** P2
- **Status:** **FIXED** — verified `PresetListView.swift:33-34, 47-48, 61-62` (each VStack now has `.accessibilityElement(children: .combine)` + `.accessibilityLabel` reading "N workouts this week", "Total time this week, …", "N day streak")

### OBSERVATION: Day Streak uses strict "ends today" semantics (design call, not necessarily a bug)
- **Screen:** Presets / home → This Week card
- **Steps:** With one workout yesterday (Custom 9:08 PM) and none today → streak shows 0. After adding a workout today → streak shows 2.
- **Analysis:** The streak logic counts "consecutive days ending today". If the user hasn't worked out today, streak is 0 regardless of history. Common alternative semantics: "longest current run with 1-day grace", which would show 1 for a user who worked out yesterday. The strict version risks demotivating users who glance at their phone in the morning and see "0 streak" even though they crushed it yesterday.
- **Severity:** P3 — design question, not a broken feature. Worth discussing with Tal what the intended behavior is. PRD doesn't specify.
- **Status:** **STILL OPEN (design call)** — `PresetListView.swift:230-248` `currentStreak` still walks back from `startOfDay(for: Date())`, breaking the chain the first day the user hasn't yet trained. Behavior unchanged; awaiting design decision.
- **Bonus:** resolved the ghost workout — the pre-existing "2m Total Time" is from a Custom preset run on 2026-04-08 at 9:08 PM (simulator Documents dir persists across reinstalls).

### BUG: Total Time on weekly card shows "2m" for actual total 2m 32s — truncates seconds
- **Screen:** Presets / home → This Week card
- **Steps:** Two workouts totaling 2m 10s + 22s = 2m 32s → card shows "2m"
- **Expected:** Either "2m 32s" (precise) or "3m" (rounded). Showing "2m" for 2:32 is floor-truncation that underreports effort.
- **Actual:** "2m" (floor to nearest minute). For short quick-HIIT workouts this could matter — an interval trainer who does 5 × 90-sec workouts (7:30 total) would see "7m" and feel slightly cheated.
- **Severity:** P3 — minor cosmetic / undercount
- **Status:** **FIXED** — verified `PresetListView.swift:250-261` (`formatWeeklyDuration` now uses `.rounded()` instead of integer floor; 2m 32s → "3m")

### BUG: Skip on the final interval fires the "WORKOUT COMPLETE!" celebration — records fake completion
- **Screen:** Active Timer → Workout Complete → History
- **Steps:**
  1. Tap AMRAP 10min preset → timer starts at WORK 10:00, Round 1/1 ("Final interval!")
  2. After ~22 seconds, tap **Skip to next interval**
  3. Observed: the app jumps immediately to the "WORKOUT COMPLETE!" celebration screen (green checkmark, "Consistency builds champions!", Duration 0:22, Rounds 1, Intervals 1, Share Workout, Done)
  4. Tap Done → returns to Presets
  5. Open History → new entry "AMRAP 10min / Today 10:26 AM / 22s / 1 round"
- **Expected:** Skip during the final interval should NOT celebrate a completion that never happened. Options: (a) grey out the Skip button on the last interval, (b) treat skip-past-last as "stop" (show "Stop Timer?" confirmation), (c) allow skip but NOT write to History and NOT show celebration — return to presets silently.
- **Actual:** The user can fake-complete a 10-minute AMRAP in 22 seconds, inflate their workout count, inflate their day streak, and even share the fake completion. This matches the Q3 human-sense violation example verbatim from `qa-prompt.md`: "the feature works. But the user bailed — they don't feel celebrated, they feel patronized."
- **Severity:** **P1** — silently corrupts workout history stats and day streak; encourages dishonesty and undermines the "progress tracking" value prop of History.
- **Status:** **FIXED** — see "Status update" line below the fix-options block (`TimerEngine.swift:90-105` `isOnFinalPhase`, `:198-206` `skip()` guard, `ActiveTimerView.swift:128-138` button disabled).
- **File:** `RoundTimer/Engine/TimerEngine.swift` lines 158-205
- **Code evidence:**
  ```swift
  func skip() {
      guard isRunning else { return }
      advanceToNextPhase()   // no guard; no "about to finish" check
  }

  private func advanceToNextPhase() {
      guard let preset = preset else { return }
      switch currentPhase {
      case .work, .rest:
          let nextIndex = currentIntervalIndex + 1
          if nextIndex < preset.intervals.count {
              enterInterval(index: nextIndex)
          } else {
              finishOrNextRound()    // on last interval of last round → finish()
          }
      ...
      }
  }
  ```
- **Universal:** the bug affects every preset, not just AMRAP. Tabata/EMOM/Boxing will fire the completion celebration and save a short fake workout whenever the user taps Skip on the final interval of the final round.
- **Fix options:**
  1. Guard in `skip()`: if skipping would complete the workout, show the same "Stop Timer?" confirmation dialog used by Stop (and don't celebrate on confirm).
  2. Disable the Skip button on the final interval of the final round (visually grey out; tap does nothing).
  3. Allow skip-to-end but don't save to History and don't show celebration — return silently to Presets.
  Option 1 is the least surprising.
- **Status update:** **FIXED** — verified `TimerEngine.swift:90-105` introduces `isOnFinalPhase` computed property; `skip()` at lines 198-206 guards `guard !isOnFinalPhase else { return }`; `ActiveTimerView.swift:128-138` also `.disabled(engine.isOnFinalPhase)` and styles the button greyed out.

### BUG: Elapsed workout time (and saved History duration) includes pause time — CONFIRMED IN SOURCE
- **Screen:** Active Timer footer stopwatch, History, This Week card
- **File:** `RoundTimer/Engine/TimerEngine.swift`
- **Code evidence:**
  ```swift
  // Line 91-94
  var elapsedTime: TimeInterval {
      guard let start = workoutStartDate else { return finalElapsedTime }
      return Date().timeIntervalSince(start)
  }

  // Line 135-146
  func pause() {
      guard isRunning, !isPaused else { return }
      isPaused = true
      stopTick()
  }
  func resume() {
      guard isRunning, isPaused else { return }
      isPaused = false
      phaseStartDate = Date().addingTimeInterval(-(currentPhaseDuration - timeRemaining))
      startTick()
  }
  // Line 222
  finalElapsedTime = elapsedTime  // at finish()
  ```
- **Root cause:** `resume()` correctly adjusts `phaseStartDate` for in-phase countdown accuracy, but **never** adjusts `workoutStartDate`. `elapsedTime` is pure `Date().timeIntervalSince(workoutStartDate)`, so every second spent paused is still counted as workout time. `finalElapsedTime = elapsedTime` at finish time freezes the polluted value, which then lands in History via `WorkoutRecord`.
- **Impact:** A user who starts a 4-minute Tabata, pauses 5 minutes to take a call, resumes and finishes, will see **9 minutes** saved as their workout duration. Weekly Total Time is cumulatively wrong. Day streaks computed from these (if any) are also wrong.
- **Fix:** Track `pauseStartDate` in `pause()`, and in `resume()` compute `pauseDuration = Date().timeIntervalSince(pauseStartDate)` and do `workoutStartDate = workoutStartDate?.addingTimeInterval(pauseDuration)` (pushing the start forward by the pause duration).
- **Severity:** **P1** — silently corrupts every workout's recorded duration that involves a pause. For a premium fitness app this undermines the core "track your training" value prop.
- **Status:** **FIXED** — verified `TimerEngine.swift:120` (new `pauseStartDate`), `pause()` at 164-170 records the pause time, `resume()` at 172-185 advances both `workoutStartDate` and `phaseStartDate` by the paused duration so `elapsedTime` excludes pauses

### BUG: New Preset builder — Cancel & Save not in accessibility tree (systemic toolbar bug)
- **Screen:** New Preset (tap "+" from home)
- **Steps:** Open "+" → `snapshot_ui`
- **Expected:** Cancel and Save toolbar buttons to be `AXButton` elements.
- **Actual:** Nav bar group `{0, 82, 440, 54}` has `children: []`. Attempting `tap(label: "Cancel")` errors with "No accessibility element matched". Same root cause as Presets home nav bar — **this is a systemic bug in how toolbars are wired in this app**. Every screen with a toolbar is affected.
- **Severity:** P1 — VoiceOver users cannot dismiss the New Preset sheet or save the preset they're building.
- **Status:** **FIXED** — verified `PresetBuilderView.swift:144-157` (Cancel and Save are separate `ToolbarItem`s with explicit `.accessibilityLabel("Cancel")` / `.accessibilityLabel("Save preset")`)

### BUG: New Preset — Preset Name TextField has no accessibility label
- **Screen:** New Preset
- **Steps:** `snapshot_ui` → find TextField at {40, 191, 360, 22}
- **Expected:** `AXLabel: "Preset Name"` so VoiceOver announces "Preset Name, text field" when focused. Placeholder text "e.g. My Tabata" should be announced as hint/value, not stand in for the label.
- **Actual:** `AXLabel: null`, `AXValue: "e.g. My Tabata"` (the placeholder). VoiceOver has no context for what this field is for.
- **Severity:** P2
- **Status:** **FIXED** — verified `PresetBuilderView.swift:163-168` (TextField now has `.accessibilityLabel("Preset Name")` + `.autocorrectionDisabled()`)

### BUG: New Preset — Duration picker wheels have no accessibility labels
- **Screen:** New Preset, Intervals section
- **Steps:** `snapshot_ui` → find AXSlider elements at ({232, 344}) and ({320, 344}) for the first interval
- **Expected:** Labels like "Minutes" and "Seconds" (or better, a combined "Duration, 0 minutes 30 seconds" via `.accessibilityElement(children: .combine)`).
- **Actual:** Two `AXSlider` with `AXLabel: null`. VoiceOver users have no idea what they're adjusting — same problem on the Rest interval.
- **Severity:** P2
- **Status:** **FIXED** — verified `DurationPicker.swift:30-31, 44-45` (both wheels have `.accessibilityLabel("\(label), minutes")` / `("\(label), seconds")` plus `.accessibilityValue`)

### BUG: New Preset — Work/Rest segmented picker has no label
- **Screen:** New Preset, each interval row
- **Steps:** `snapshot_ui` → find TabGroup at {40, 305, 360, 31}
- **Expected:** Accessibility label on the TabGroup like "Phase type: Work or Rest".
- **Actual:** `AXLabel: null` on both interval TabGroups. Individual tab options (Work/Rest) also appear unreachable via the tree.
- **Severity:** P2
- **Status:** **FIXED** — verified `PresetBuilderView.swift:267-273` (segmented `Picker` has `.accessibilityLabel("Phase")` + `.accessibilityValue(...)`)

## 2026-04-09 — QA loop pass 12 (audio files, asset catalog, callback wiring)

### VERIFICATION: All 7 audio files — format, quality, size — PASS
- **Method:** `afinfo` on each .wav file in the built app bundle + file size check
- **Results (all 7):**
  | File                    | Size    | Duration | Format                        |
  |-------------------------|---------|----------|-------------------------------|
  | countdown_beep.wav      | 5,336   | 0.060s   | mono 44100 Hz Int16 PCM       |
  | half_time.wav           | 11,510  | 0.130s   | mono 44100 Hz Int16 PCM       |
  | warmup_start.wav        | 17,684  | 0.200s   | mono 44100 Hz Int16 PCM       |
  | cooldown_start.wav      | 22,094  | 0.250s   | mono 44100 Hz Int16 PCM       |
  | work_start.wav          | 22,976  | 0.260s   | mono 44100 Hz Int16 PCM       |
  | rest_start.wav          | 28,268  | 0.320s   | mono 44100 Hz Int16 PCM       |
  | timer_complete.wav      | 47,672  | 0.540s   | mono 44100 Hz Int16 PCM       |
  | **TOTAL**               | **155,540 (~152 KB)** |  |                    |
- **Analysis:**
  - All mono (not stereo) ✓ — timer beeps don't benefit from stereo
  - 44100 Hz is standard CD quality
  - Int16 (16-bit) PCM uncompressed
  - Durations appropriate for timer cues (60ms tick to 540ms completion fanfare)
  - Math check: 44100 × 2 bytes/sample × duration + 44-byte WAV header matches reported sizes exactly → files are uncompressed PCM with standard WAV headers
- **Optimization opportunities (all declined):**
  - **Compressed AAC/M4A** could reduce by ~75% (152KB → 40KB) — **declined because** PCM guarantees zero decode latency, which matters for timer-critical audio playback. The `.claude/rules/audio-rules.md` rule #4 specifies preloading sounds to avoid first-play latency, and PCM files can be preloaded into memory without a decode step.
  - **22050 Hz downsample** would halve sizes (152KB → 76KB) but 152KB is negligible for the app's ~3MB total bundle.
- **Conclusion:** audio files are well-chosen, bundle weight is trivial, and the format decision is correct for a latency-sensitive timer app.
- **Severity:** informational — PASS
- **Status:** verified ✓

### VERIFICATION: Asset catalog audit — clean, no bloat
- **File:** `RoundTimer/Resources/Assets.xcassets/`
- **Contents (total 2 asset items):**
  - `AccentColor.colorset/Contents.json` (color spec, no image)
  - `AppIcon.appiconset/AppIcon.png` + `Contents.json`
- **AppIcon verification via `sips`/`file`:**
  - Dimensions: **1024×1024** ✓
  - Color format: **8-bit RGB, non-interlaced**
  - **`hasAlpha: no`** ✓ matches `.claude/rules/app-store-submission.md` rule: "App icon PNG must have NO alpha channel"
  - File size: 148 KB
  - Uses **universal icon idiom** (`"idiom": "universal", "platform": "ios"`, single 1024×1024 master)
- **iPad icon generation:** iteration 9 found `AppIcon76x76@2x~ipad.png` in the built bundle. That PNG is generated automatically by the asset catalog compiler from the universal master at build time — **yet another confirmation of universal app status** (fourth source of truth after UIDeviceFamily, orientations, and CFBundleIcons~ipad).
- **Zero orphan images, zero unused assets, zero test artifacts.** Lean catalog.
- **Severity:** informational — PASS, App Store submission compliant
- **Status:** verified ✓

### OBSERVATION: Callback wiring in PresetListView is mostly correct with one minor bug
- **File:** `RoundTimer/Views/Presets/PresetListView.swift:67-80, 262-273`
- **Tap flow verified:**
  1. `selectedPreset = preset`
  2. `store.markUsed(preset)` — updates lastUsedAt, saves to disk
  3. `configureEngineCallbacks()` — wires up engine callbacks BEFORE start (correct ordering)
  4. `engine.start(preset:)` — enters first phase, fires `onPhaseChange` callback
  5. `TimerActivityManager.shared.start(...)` — creates the Live Activity
  6. `showingTimer = true` — presents ActiveTimerView
- **Ordering is correct except for one subtle issue:**
  - At step 4, `engine.start()` internally calls `enterPhase()` which fires `onPhaseChange?(phase)`
  - The callback at step 3 tries to call `TimerActivityManager.shared.update(...)` but the activity hasn't been started yet (step 5 hasn't run)
  - `update()` silently no-ops when `activityId` is nil
  - At step 5, `TimerActivityManager.start()` creates the activity with initial state — **but hardcodes `intervalName: nil`** in the ContentState:
    ```swift
    // TimerActivityManager.swift:29 (approximate)
    let state = TimerActivityAttributes.ContentState(
        phase: phase.rawValue,
        phaseColorHex: phase.colorHex,
        currentRound: currentRound,
        intervalEndDate: intervalEndDate,
        intervalName: nil,  // ⚠ never passed in
        isPaused: false
    )
    ```
- **Impact:** A custom preset with a labeled first interval (e.g., "Kettlebell swings") will have `intervalName: nil` in the Live Activity's initial state, even though the app's `engine.intervalName` was set correctly during `enterPhase()`. The label would only be corrected on the NEXT phase transition (when `update()` is called with the correct intervalName).
- **Compounds with iteration 10 finding:** the widget doesn't render `intervalName` at ALL, so this bug is currently doubly hidden. Both bugs would need fixing for interval labels to show on the lock screen.
- **Fix:** either
  - (a) add `intervalName: String?` parameter to `TimerActivityManager.start()` and pass `engine.intervalName`
  - (b) reorder: call `TimerActivityManager.start()` BEFORE `engine.start(preset:)`, with an initial dummy state, then let the first `onPhaseChange` `update()` call populate the real state. But this is fragile.
  - Option (a) is cleaner.
- **Severity:** P3 — latent bug only visible once the widget starts rendering intervalName (requires also fixing iter 10 P2).
- **Status:** **FIXED** — verified `TimerActivityManager.swift:10` (now accepts `intervalName: String? = nil`), `:24-31` (passes it into ContentState), `PresetListView.swift:190-197, 293-300` (`startPreset` and Quick Timer path pass `engine.intervalName`)

### OBSERVATION: `sortedPresets` behavior explains iteration 1 vs iteration 4 order difference
- **File:** `PresetListView.swift:254-260`
- **Code:**
  ```swift
  private var sortedPresets: [TimerPreset] {
      store.presets.sorted { a, b in
          let aDate = a.lastUsedAt ?? .distantPast
          let bDate = b.lastUsedAt ?? .distantPast
          return aDate > bDate  // descending by lastUsedAt
      }
  }
  ```
- **Behavior:**
  - Presets with a `lastUsedAt` sort to the top (most recent first)
  - Presets never used tie on `.distantPast` → **Swift's stable sort preserves their original order from `store.presets`** (which is the JSON load order, which is the `defaultPresets()` order: Tabata, Boxing, EMOM, AMRAP 10min, Custom)
- **Explains:** iteration 4 first-launch showed Tabata→Boxing→EMOM→AMRAP→Custom (factory order, no presets used yet). Iteration 1 showed Custom at top (Custom was the "last used" from a prior session's JSON file).
- **Severity:** informational — sort behavior is correct and predictable
- **Status:** verified ✓

### OBSERVATION: Multi-row swipe-delete on custom presets is safe via snapshot capture
- **File:** `PresetListView.swift:100-106`
- **Code:**
  ```swift
  .onDelete { indexSet in
      let sorted = sortedPresets     // captures snapshot BEFORE mutations
      for index in indexSet {
          let preset = sorted[index]
          store.delete(preset)        // guard against built-ins internally
      }
  }
  ```
- **Analysis:**
  - `sortedPresets` is re-computed once at the start of the deletion callback and captured in a local `let sorted` constant
  - The loop reads from the snapshot, not the live store, so there's no index drift as presets are deleted
  - `store.delete()` internally guards `!preset.isBuiltIn`, so if the user somehow has built-ins in the indexSet (unlikely via `.deleteDisabled(preset.isBuiltIn)`), those are silently skipped without crashing
- **No bug** — good defensive pattern.
- **Severity:** informational — PASS
- **Status:** verified ✓

## 2026-04-09 — QA loop pass 11 (persistence + model Codable + TimerEngine edge cases)

### BUG (P1): `PresetStore.load()` silently overwrites presets file with factory defaults on decode error — potential data loss
- **File:** `RoundTimer/Persistence/PresetStore.swift:14-28`
- **Code evidence:**
  ```swift
  func load() {
      if FileManager.default.fileExists(atPath: fileURL.path) {
          do {
              let data = try Data(contentsOf: fileURL)
              let decoded = try JSONDecoder().decode([TimerPreset].self, from: data)
              presets = decoded
          } catch {
              presets = Self.defaultPresets()
              save()                           // ⚠ OVERWRITES THE CORRUPT FILE
          }
      } else {
          presets = Self.defaultPresets()
          save()
      }
  }
  ```
- **Scenario:** A user has 10 custom presets saved. Tal ships V1.1 with a new non-optional field on `TimerPreset` (e.g., `category: String`). User updates the app. On first launch, the decoder fails because the stored JSON doesn't have `category`. The catch block runs: **replaces the in-memory presets with factory defaults AND overwrites the disk file with just the 5 built-ins.** All 10 custom presets are irrecoverably destroyed.
- **Compounding factors:**
  - PRD §Persistence says "No iCloud sync in V1" — so there is **no backup anywhere**
  - The catch block doesn't even `print` the decode error, so Tal has zero visibility that this happened
  - Silent data loss is the worst kind of bug for a fitness app — users lose their custom WODs and blame the app
- **Fix (recommended order):**
  1. **Immediate:** add `print("PresetStore decode failed: \(error)")` in the catch so future debugging is possible
  2. **Before V1.1 ships:** back up the corrupt file before overwriting:
     ```swift
     } catch {
         print("PresetStore decode failed: \(error)")
         // Back up corrupt file before overwriting
         let backupURL = fileURL.appendingPathExtension("corrupt-\(Int(Date().timeIntervalSince1970))")
         try? FileManager.default.copyItem(at: fileURL, to: backupURL)
         presets = Self.defaultPresets()
         save()
     }
     ```
  3. **Long term:** design all model fields as Optional with defaults OR write a custom `init(from decoder:)` that uses `decodeIfPresent` with fallbacks for forward-compatibility
- **Severity:** **P1** — silent destruction of user data. The bug is latent (won't trigger in V1.0 since there's no migration) but will bite hard as soon as V1.1 or V1.2 adds any non-optional field.
- **Status:** **FIXED** — verified `PresetStore.swift:25-42` (catch block now logs the error with `print("[PresetStore] decode failed: \(error)")` and copies the corrupt file to `presets.json.corrupt-<timestamp>` via `FileManager.copyItem` BEFORE falling back to defaults)

### BUG (P2): `WorkoutHistoryStore.load()` handles decode error better but still loses data on next save
- **File:** `RoundTimer/Persistence/WorkoutHistoryStore.swift:15-23`
- **Code evidence:**
  ```swift
  func load() {
      guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
      do {
          let data = try Data(contentsOf: fileURL)
          records = try JSONDecoder().decode([WorkoutRecord].self, from: data)
      } catch {
          print("Failed to load workout history: \(error)")
          // records stays []
      }
  }
  ```
- **Better than PresetStore:** does NOT overwrite the file on load failure.
- **But still bugs:** the in-memory `records` stays empty. The first time the user completes a workout, `add()` appends to the empty `records` and calls `save()`, which **overwrites** the file with just the one new record. **The old history is now gone** — the backup file exists on disk under the same name and was overwritten by the atomic write.
- **Fix:** same backup pattern as PresetStore — before the first save after a load failure, copy the original file to `.corrupt-TIMESTAMP`. Or just: if the load fails, refuse to save until the user explicitly clears history, so the corrupt file is preserved.
- **Severity:** P2 — less impactful than PresetStore because workout history is less valuable than custom presets, but still silent data loss.
- **Status:** **FIXED** — verified `WorkoutHistoryStore.swift:9-10, 27-47` (tracks `loadFailed` flag, makes `.corrupt-<ts>` backup on decode failure, and `save()` early-returns when `loadFailed == true` so the corrupt file is never overwritten)

### BUG (P2): `PresetStore` is NOT annotated `@MainActor` but `WorkoutHistoryStore` IS
- **Files:** `PresetStore.swift:3-4` (only `@Observable`), `WorkoutHistoryStore.swift:3-5` (`@MainActor @Observable`)
- **Issue:** inconsistent actor isolation. In strict Swift 6 concurrency mode (which this project uses per `project.yml:14 SWIFT_VERSION: "6.0"`), non-`@MainActor` classes can theoretically be called from any actor, leading to data races on the `presets` array and the file I/O. Likely compiles only because the call sites all happen to be `@MainActor`-isolated by convention.
- **Fix:** add `@MainActor` to `PresetStore`:
  ```swift
  @MainActor
  @Observable
  class PresetStore { ... }
  ```
- **Severity:** P2 — latent concurrency bug. Not causing issues now but will bite if Tal later calls PresetStore from a background task.
- **Status:** **FIXED** — verified `PresetStore.swift:3-4` is now `@MainActor @Observable`

### BUG (P2): No mechanism to add new built-in presets in a V1.1 update
- **Files:** `PresetStore.swift:14-28`, `Models/TimerPreset.swift`
- **Scenario:** V1.0 ships with 5 built-in presets. V1.1 wants to add "CrossFit WOD" as a 6th built-in. BUT: existing V1.0 users have already saved their `presets.json` file which contains 5 presets marked `isBuiltIn: true`. On V1.1 first launch, `PresetStore.load()` reads the saved 5-preset file and uses it as-is — **the new "CrossFit WOD" built-in is never added for upgrading users.** Only brand-new users get it.
- **Root cause:** `load()` has no merge logic. It either uses the file's presets AS-IS or uses factory defaults. There's no "merge any missing built-ins from `defaultPresets()` into the loaded set".
- **Fix:**
  ```swift
  func load() {
      // ... existing decode logic ...
      
      // Merge missing built-ins (for upgrades from older versions)
      let existingBuiltInIds = Set(presets.filter(\.isBuiltIn).map(\.id))
      for defaultPreset in Self.defaultPresets() where !existingBuiltInIds.contains(defaultPreset.id) {
          presets.append(defaultPreset)
      }
      // Only save if we added something
  }
  ```
  (Requires built-in presets to have stable hardcoded UUIDs, not `UUID()`)
- **Current state:** `defaultPresets()` generates fresh UUIDs every call (`TimerPreset(...)` uses the default `init` which generates a new `UUID()`). So there's no stable ID to match built-ins on. **A prerequisite fix is giving each built-in a hardcoded UUID.**
- **Severity:** P2 — latent V1.1 blocker. Won't affect V1.0 but will prevent Tal from shipping new built-in presets as updates.
- **Status:** **FIXED** — `PresetStore.swift:130-149` (`tabataID` … `customID` static UUID constants with `?? UUID()` fallback to satisfy the no-force-unwrap rule), `:151-219` (`defaultPresets()` now passes those constants into each `TimerPreset(id: ...)`), `:25-27` (`load()` calls `migrateBuiltIns()` after a successful decode and `save()`s if anything changed), `:48-92` (`migrateBuiltIns()` (a) walks every `isBuiltIn` row, name-matches it against the canonical defaults, and reassigns the row's UUID to the canonical one — preserving `lastUsedAt` and every other field — and (b) appends any default whose canonical UUID isn't already in the store). Traced through fresh-install, V1.0→V1.0.1 upgrade, V1.1-adds-new-built-in, and V1.x-renames-built-in scenarios; the rename case is intentionally a no-op (renames must ship as new IDs).

### BUG (P2): All model Codable definitions use default synthesis — no migration safety
- **Files:** `Models/TimerPreset.swift`, `Models/WorkoutRecord.swift`, `Models/TimerInterval.swift`
- **Issue:** Swift's default `Codable` synthesis requires ALL non-Optional fields to be present in the JSON for decode to succeed. Adding any new non-Optional field breaks backward compatibility.
- **Current non-Optional fields that would break migration:**
  - `TimerPreset`: `id, name, intervals, rounds, isBuiltIn` — **5 fields that break if removed/renamed**
  - `WorkoutRecord`: `id, date, presetName, totalDuration, roundsCompleted, intervalsCompleted` — **6 fields**
  - `TimerInterval` (inferred): presumably `id, phase, duration, name` — let me verify
- **Fix:** for V1.1 onwards, EVERY new field added to these models must be either:
  - **Optional with default nil:** `var newField: String? = nil` (preferred)
  - **Non-optional with a default via custom `init(from:)`:**
    ```swift
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // existing fields...
        self.newField = try container.decodeIfPresent(String.self, forKey: .newField) ?? "default"
    }
    ```
- **Severity:** P2 — forward-compatibility discipline. Not a V1.0 bug but a V1.1 trap.
- **Status:** **STILL OPEN** — `Models/TimerPreset.swift` and friends still use Swift's default Codable synthesis with no `decodeIfPresent` fallbacks. Treat as a V1.1 release-checklist item for any new fields.

### BUG (P3): `TimerEngine.totalRemainingTime` underestimates by one interval duration during warmup
- **File:** `RoundTimer/Engine/TimerEngine.swift:65-85`
- **Code evidence:**
  ```swift
  var totalRemainingTime: TimeInterval {
      guard let preset = preset, isRunning, !isFinished else { return 0 }
      var remaining = timeRemaining
      
      // Add remaining intervals in current round
      let intervalDuration = preset.intervals.reduce(0.0) { $0 + $1.duration }
      for i in (currentIntervalIndex + 1)..<preset.intervals.count {  // starts at index+1
          remaining += preset.intervals[i].duration
      }
      // ...
  }
  ```
- **Issue:** during warmup phase, `currentIntervalIndex == 0` (set by `start()`, not reset by `enterPhase(.warmup)`). The loop `for i in 1..<intervals.count` **skips interval[0]'s duration**, so it's missing from the total.
- **Scenario (Tabata 20W/10R, 8 rounds, 10s warmup):**
  - Real total time remaining at warmup start = 10 (warmup) + 8 × (20 + 10) = 250s
  - Computed: timeRemaining (10) + intervals[1] (10) + 7 × 30 (210) = 230s — **off by 20s** (one Work interval)
  - When warmup ends and Round 1 Work starts, the display jumps from ~-3:50 to ~-4:00 remaining — a visible "jump back" that's mildly confusing
- **Fix:** during warmup, iterate from index 0 not currentIntervalIndex + 1:
  ```swift
  let startFromIndex = (currentPhase == .warmup) ? 0 : currentIntervalIndex + 1
  for i in startFromIndex..<preset.intervals.count {
      remaining += preset.intervals[i].duration
  }
  ```
- **Severity:** P3 — minor visible glitch during warmup→first-work transition. Only affects presets that have warmup enabled.
- **Status:** **FIXED** — verified `TimerEngine.swift:65-88` (`totalRemainingTime` now uses `let startFromIndex = (currentPhase == .warmup) ? 0 : (currentIntervalIndex + 1)` and adjusts `remainingRounds` to `(totalRounds - 1)` during warmup so the first round isn't double-counted)

### BUG (P3): `PresetBuilderViewModel.save()` discards `lastUsedAt` when editing an existing preset
- **File:** `RoundTimer/Views/Presets/PresetBuilderView.swift:75-89`
- **Code evidence:**
  ```swift
  func save(to store: PresetStore) {
      let preset = TimerPreset(
          id: editingId ?? UUID(),
          name: name.trimmingCharacters(in: .whitespaces),
          intervals: intervals,
          rounds: rounds,
          warmup: hasWarmup ? warmupDuration : nil,
          cooldown: hasCooldown ? cooldownDuration : nil
          // ⚠ lastUsedAt is not passed — defaults to nil
      )
      ...
  }
  ```
- **Impact:** editing a just-used preset (e.g., you just ran Tabata, now you edit the Custom preset) loses the "Recent" marker on the edited preset. Minor UX regression because the "Recent" badge is how users find their most-used preset.
- **Fix:**
  ```swift
  let preset = TimerPreset(
      id: editingId ?? UUID(),
      // ...
      lastUsedAt: isEditing ? /* fetch original.lastUsedAt from store */ : nil
  )
  ```
  The ViewModel needs access to the original preset to preserve this field.
- **Severity:** P3 — minor data loss on edit
- **Status:** **FIXED** — verified `PresetBuilderView.swift:27, 41-42, 56, 67-68, 99-101` (ViewModel now stores `editingLastUsedAt` from the original preset and passes it back into `TimerPreset(... lastUsedAt: editingLastUsedAt)` on save)

### BUG (P3): `PresetBuilderViewModel.isValid` does not enforce PRD max-rounds or max-duration caps
- **File:** `PresetBuilderView.swift:20-24`
- **PRD §Custom Interval Builder:** "Minimum 1 interval", "Maximum duration per interval: 99 minutes 59 seconds", "Maximum rounds: 99"
- **Current validation:**
  ```swift
  var isValid: Bool {
      !name.trimmingCharacters(in: .whitespaces).isEmpty
          && !intervals.isEmpty
          && intervals.allSatisfy { $0.duration > 0 }
  }
  ```
  - ✅ Checks name non-empty
  - ✅ Checks intervals non-empty
  - ✅ Checks all interval durations > 0
  - ❌ Does NOT check `rounds >= 1 && rounds <= 99`
  - ❌ Does NOT check `intervals.allSatisfy { $0.duration <= 5999 }` (99m 59s)
- **Likely why it works anyway:** the SwiftUI `Stepper` and `Picker` controls probably clamp rounds to 1...99 and duration to 0...5999 at the UI level. So users can't submit out-of-range values via the UI. But a malformed JSON import could, and defensive coding is cheap.
- **Severity:** P3 — UI enforces the limits, ViewModel doesn't defensively re-check.
- **Status:** **FIXED** — verified `PresetBuilderView.swift:8-10, 31-37` (constants `maxRounds = 99` / `maxIntervalDuration = 99*60+59`; `isValid` now also checks `(1...maxRounds).contains(rounds)` and `intervals.allSatisfy { $0.duration > 0 && $0.duration <= maxIntervalDuration }`)

### BUG (P3): `TimerEngine.start()` does not guard against zero-interval presets — O(N) finish recursion
- **File:** `RoundTimer/Engine/TimerEngine.swift:114-133, 177-185, 207-218`
- **Scenario:** a malformed preset with `intervals: []` and `rounds: 3` (can't be created via UI, but could arrive via JSON import or if migration creates one). Trace:
  1. `start()` → no warmup → `enterInterval(0)`
  2. `enterInterval(0)`: guard `0 < 0` fails → `finishOrNextRound()`
  3. `finishOrNextRound()`: currentRound (1) < 3 → round = 2 → `enterInterval(0)` → recursion
  4. ... repeats for each round ...
  5. After 3 rounds, round >= totalRounds → no cooldown → `finish()` → `onComplete?()`
- **Impact:** the zero-interval "workout" completes instantly, firing:
  - ✗ Completion sound
  - ✗ Celebration UI
  - ✗ A 0-duration `WorkoutRecord` saved to History
  - ✗ Day streak bump (per current logic)
  - ✗ Rate prompt may trigger
- **Also:** O(rounds) recursion depth. Not infinite because rounds is finite, but still unnecessary stack frames.
- **Fix:** add a defensive guard at the top of `start()`:
  ```swift
  func start(preset: TimerPreset) {
      guard !preset.intervals.isEmpty else { return }
      // ... rest of start()
  }
  ```
- **Severity:** P3 — defensive. Users can't hit this via the UI (PresetBuilderView.isValid blocks it), but any code path that loads a malformed preset could.
- **Status:** **FIXED** — verified `TimerEngine.swift:137-141` (`start()` opens with `guard !preset.intervals.isEmpty else { return }`)

### OBSERVATION: Codable field audit (for V1.1 migration planning)
- **Files:** `Models/TimerPreset.swift`, `Models/WorkoutRecord.swift`, `Models/TimerInterval.swift` (inferred)
- **TimerPreset non-optional fields (5):** `id`, `name`, `intervals`, `rounds`, `isBuiltIn`
- **TimerPreset optional fields (3):** `warmup?`, `cooldown?`, `lastUsedAt?`
- **WorkoutRecord non-optional fields (6):** `id`, `date`, `presetName`, `totalDuration`, `roundsCompleted`, `intervalsCompleted`
- **WorkoutRecord has no optional fields** — any added field in V1.1+ must be optional or have a custom `init(from decoder:)` with defaults.
- **Recommendation:** when drafting V1.1 plans, add a "Data model migration checklist" that requires all new fields to be Optional with default nil.
- **Status:** informational — for V1.1 planning

## 2026-04-09 — QA loop pass 10 (Live Activity Widget source review — MAJOR FINDINGS)

### BUG (P1): Pause / Resume do not update the Live Activity — lock screen shows ghost countdown
- **Files:** `RoundTimer/Views/ActiveTimer/ActiveTimerView.swift:114-119`, `RoundTimer/LiveActivity/TimerActivityManager.swift:46-63`
- **Symptom:** A user who pauses a timer while the phone is locked will see the Live Activity on the lock screen KEEP counting down (the OS-native `Text(intervalEndDate, style: .timer)` ticks based on system time relative to `intervalEndDate`, oblivious to the app's pause state). When resumed, the Live Activity shows the WRONG remaining time until the next phase transition updates it.
- **Code evidence — pause button:**
  ```swift
  // ActiveTimerView.swift:114-119
  Button {
      if engine.isPaused {
          engine.resume()
      } else {
          engine.pause()
      }
  } label: {
      Image(systemName: engine.isPaused ? "play.circle.fill" : "pause.circle.fill")
          ...
  }
  // No TimerActivityManager.shared.update(...) call
  ```
- **Where updates DO fire (`PresetListView.swift:262-274`):** only inside `engine.onPhaseChange`, which is called on phase transitions (work→rest, auto-advance, skip). **Never called from pause or resume paths.**
- **What the Live Activity state already supports:** `TimerActivityAttributes.ContentState` has an `isPaused: Bool` field. `TimerActivityManager.update()` accepts an `isPaused` parameter and sets `staleDate: isPaused ? nil : intervalEndDate` correctly. **The plumbing exists; it's just never called with isPaused: true.**
- **Fix:** call `TimerActivityManager.shared.update(...)` from the pause/resume button handler. Minimum fix:
  ```swift
  Button {
      if engine.isPaused {
          engine.resume()
          TimerActivityManager.shared.update(
              phase: engine.currentPhase,
              currentRound: engine.currentRound,
              intervalEndDate: engine.phaseEndDate,
              intervalName: engine.intervalName,
              isPaused: false
          )
      } else {
          engine.pause()
          TimerActivityManager.shared.update(
              phase: engine.currentPhase,
              currentRound: engine.currentRound,
              intervalEndDate: engine.phaseEndDate,
              intervalName: engine.intervalName,
              isPaused: true
          )
      }
  }
  ```
  Cleaner fix: add `onPause` / `onResume` callbacks to `TimerEngine` (analogous to `onPhaseChange`) and wire them up in `configureEngineCallbacks()` so the logic lives in one place.
- **Severity:** **P1** — the Live Activity is a PRD-flagged differentiator ("Live Activity on lock screen" is listed as the #1 row in PRD §Core Differentiators) and the feature is broken whenever the user uses Pause. This is the hardest-to-debug kind of bug because it only shows up on real devices with the lock screen visible.
- **Status:** **FIXED** — verified `TimerEngine.swift:132-133` (new `onPauseStateChange` callback), `:169` (`pause()` fires it with `true`), `:184` (`resume()` fires with `false`); `PresetListView.swift:325-333` (`configureEngineCallbacks` wires it to `TimerActivityManager.shared.update(... isPaused: isPaused)`). Both pause-related P1s (this + elapsed-time) are now resolved together.
- **Note:** this compounds with the P1 "pause inflates elapsed" bug from iteration 2 — BOTH pause-related bugs need fixing together for a clean pause experience.

### BUG (P1): Widget hardcodes `.fill(.green)` ignoring phase color — all phases look identical on lock screen
- **File:** `RoundTimerWidgetExtension/RoundTimerWidgetBundle.swift:20-22, 55-57, 62-65`
- **Code evidence:**
  ```swift
  // Lock Screen
  Circle().fill(.green).frame(width: 12, height: 12)   // line 21 — HARDCODED GREEN
  
  // Dynamic Island compactLeading
  Circle().fill(.green).frame(width: 8, height: 8)     // line 56 — HARDCODED GREEN
  
  // Dynamic Island minimal
  Circle().fill(.green).frame(width: 8, height: 8)     // line 64 — HARDCODED GREEN
  ```
- **Expected:** the circle color should reflect the current phase per PRD's rich color palette (emerald work, steel blue rest, amber warmup, deep orange cooldown).
- **Actual:** the circle is **always green**. A user in REST (blue phase) sees a green circle. A user in WARMUP (amber phase) sees a green circle. The Live Activity doesn't visually distinguish phases AT ALL — it just shows the same green dot regardless.
- **Related:** `TimerActivityAttributes.ContentState.phaseColorHex: String` is passed from the app via `TimerActivityManager.update(phase: phase, phaseColorHex: phase.colorHex, ...)`. **The widget receives this value on every update but never uses it.** Dead code across a process boundary.
- **Fix:**
  ```swift
  // Add a helper extension or inline:
  private func colorForPhase(_ hex: String) -> Color {
      Color(hex: hex) ?? .green  // or use UIColor(hex:) if there's no Color(hex:) extension yet
  }
  
  // Then:
  Circle().fill(colorForPhase(context.state.phaseColorHex))...
  ```
  Or: instead of passing a hex string, derive `phase: TimerPhase` from the stored raw value and use `phase.color` directly. Since `TimerPhase` is in the shared files list per `project.yml:50`, the widget has access to the enum.
- **Severity:** **P1** — makes the Live Activity's primary visual affordance (phase color) useless. Also wastes a state field. PRD §Live Activity shows mock-ups with colored phase circles 🟢 — the green-hardcoded implementation doesn't match the mock.
- **Status:** **FIXED** — verified `RoundTimerWidgetBundle.swift:17-25` (new `colorFromHex` helper), `:31-34` (lock-screen Circle uses `phaseColor`), `:66-119` (Dynamic Island compactLeading, minimal, expanded all use `phaseColor`); phase-text color also tinted in lock screen and expanded Island

### BUG (P2): Widget ignores `intervalName` from state
- **File:** `RoundTimerWidgetBundle.swift` (entire file)
- **Code evidence:** `TimerActivityAttributes.ContentState.intervalName: String?` is defined and populated by the app, but the widget never reads `context.state.intervalName` anywhere.
- **Impact:** Users who name their custom intervals (e.g., "Kettlebell swings", "Burpees", "Rest — water break") lose that context on the lock screen. Only the generic "WORK" / "REST" phase label shows.
- **Fix:** add a secondary text under the phase label that shows `intervalName` when non-nil:
  ```swift
  VStack(alignment: .leading) {
      Text(context.state.phase.uppercased()).font(.headline)
      if let name = context.state.intervalName {
          Text(name).font(.caption).foregroundStyle(.secondary)
      }
  }
  ```
- **Severity:** P2 — missing feature that's already plumbed through and just needs rendering.
- **Status:** **FIXED** — verified `RoundTimerWidgetBundle.swift:41-47` (lock-screen renders `context.state.intervalName` under the phase label) and `:73-78` (Dynamic Island leading region also renders it)

### BUG (P2): Lock screen Live Activity has no phase-color background or progress indicator
- **File:** `RoundTimerWidgetBundle.swift:19-34`
- **Current layout:** plain `HStack` with padding, white/system background. Just text + a small colored dot.
- **PRD expects (§Live Activity mock):**
  ```
  ┌──────────────────────────────────────┐
  │  🟢 WORK          2:47    R 3/12    │
  └──────────────────────────────────────┘
  ```
- **What's missing vs PRD mock:**
  - No background color tinting by phase (could be subtle gradient matching phase)
  - No progress bar showing % of current interval completed
  - No preset name (it's shown only in Dynamic Island expanded, not on Lock Screen)
  - Minimal font hierarchy (everything is `.headline` or `.caption`)
- **Assessment:** the current implementation is a bare-bones "checkbox" of the PRD spec. It technically satisfies "shows phase, time, round" but it doesn't use the rich visual features a user expects from a modern Live Activity (matching Apple's own Timer/Fitness apps).
- **Severity:** P2 — the feature works but looks unfinished. A Tal follow-up to polish this would be a good first V1.1 task.
- **Status:** **PARTIALLY FIXED** — phase-color tinting is now applied to text/circle/timer (`RoundTimerWidgetBundle.swift:31-64`), and `intervalName` + paused state are rendered. Still no progress bar, no background gradient, no preset name on lock screen. Reclassified as design/polish for V1.1.

### BUG (P2): Dynamic Island expanded layout is disjointed across regions
- **File:** `RoundTimerWidgetBundle.swift:36-53`
- **Current regions:**
  - `.leading` → phase text
  - `.trailing` → round counter
  - `.center` → countdown timer (title-size)
  - `.bottom` → preset name
- **Issue:** the 4 regions render as separate elements with different font sizes and no visual hierarchy. The timer in `.center` is large (`.title`) but the phase and round are small (`.headline` / `.caption`) and squished into the corners. The result is a cramped, grid-like layout that's hard to read at a glance.
- **Improvement:** use `.center` as a `VStack` containing `phase + timer + round` as a cohesive unit, and reserve `.bottom` for preset name. Also consider a phase-colored accent line or background tint.
- **Severity:** P2 — works but isn't as polished as Apple's own timers on the Dynamic Island.
- **Status:** **PARTIALLY FIXED** — phase color is now applied to phase text and timer text (`RoundTimerWidgetBundle.swift:67-99`); intervalName and paused state are rendered. Still uses 4 disjoint regions instead of a center VStack. Polish item for V1.1.

### BUG (P3): Widget `CFBundleShortVersionString` is hardcoded to "1.0" in its Info.plist — won't auto-sync with MARKETING_VERSION
- **File:** `RoundTimerWidgetExtension/Info.plist:19-20`
- **Current value:** `<string>1.0</string>` (hardcoded — not a `$(MARKETING_VERSION)` substitution)
- **Issue:** `project.yml:15` sets `MARKETING_VERSION: "1.0.0"` for all targets, but the widget's Info.plist uses a literal `"1.0"`. Because `project.yml:53-54` points the widget to this file (instead of using `GENERATE_INFOPLIST_FILE: true` like the main app), the MARKETING_VERSION never propagates.
- **Current impact:** main app = 1.0.0, widget = 1.0. Minor mismatch.
- **Future impact:** when main app bumps to 1.0.1 / 1.1.0 / 2.0.0, the widget will stay at "1.0" forever until someone manually edits the plist. This could cause confusion during debugging ("why is the widget showing an old version?").
- **Fix (choose one):**
  - A: Change `<string>1.0</string>` → `<string>$(MARKETING_VERSION)</string>` (and same for CFBundleVersion → `$(CURRENT_PROJECT_VERSION)`)
  - B: Delete the hardcoded widget Info.plist, set `GENERATE_INFOPLIST_FILE: true` in the widget target, and rely on xcodegen's generation. But this requires re-declaring `NSExtension.NSExtensionPointIdentifier` differently (per xcodegen-gotchas.md rule #2).
  - Option A is the minimal-risk fix.
- **Severity:** P3 — minor drift between main app and widget version strings
- **Status:** **FIXED** — verified `project.yml:55-58` now sets `CFBundleShortVersionString: "$(MARKETING_VERSION)"` and `CFBundleVersion: "$(CURRENT_PROJECT_VERSION)"` in the widget's `info.properties` (so xcodegen runs preserve it). After regenerate + build, `RoundTimerWidgetExtension.appex/Info.plist` resolves to `1.0.0` and `1` and the build emits no version-mismatch warning. **NOTE:** the in-place edit to the source `Info.plist` was not durable — it was reverted whenever `xcodegen generate` ran. The fix now lives in `project.yml`. (Repaired during this verification pass.)

### BUG (P2): Watch target ships a "Hello World" placeholder that installs on paired Apple Watches
- **File:** `RoundTimerWatch/App/RoundTimerWatchApp.swift`
- **Current content:**
  ```swift
  @main
  struct RoundTimerWatchApp: App {
      var body: some Scene {
          WindowGroup {
              Text("RoundTimer")
                  .font(.headline)
          }
      }
  }
  ```
- **Impact:** Users with a paired Apple Watch who install RoundTimer will see an empty "RoundTimer" text label on their watch. The app icon appears in their Watch app list. Tapping it opens a screen with just "RoundTimer" and nothing else — no controls, no mirroring, no glance data.
- **Why this is worse than "nothing":**
  - Users may feel deceived ("I see the watch app icon, let me tap it" → disappointment)
  - Reviewers may flag this as "App Store Review Guideline 4.0 Design — Spam" ("apps that appear to be empty or broken")
  - It takes up a slot in the Apple Watch app list for no value
- **ship-summary documents this** as "Watch app target exists but is empty (deferred to V1.1)" — but that assumes Tal KNEW the Watch app ships with the iPhone app. If the intent was "empty target not shipped until V1.1", the target should either be:
  - **Removed entirely** from `project.yml` until V1.1 (cleanest)
  - **Marked as not installed by default** via Info.plist `WKRunsIndependentlyOfCompanionApp: false` + removing it from the embedded products
  - **Given a helpful placeholder UI** like "Coming soon — Timer controls in V1.1" or redirects to "Use your iPhone to control RoundTimer"
- **Severity:** **P2** — ships a broken-looking experience to any Apple Watch owner. Especially painful because PRD §Target Users §Primary explicitly lists athletes who own Apple Watch.
- **Recommendation:** remove the Watch target from `project.yml` for V1.0.x, reintroduce in V1.1 with real functionality.
- **Status:** **STILL OPEN** — verified `RoundTimerWatch/App/RoundTimerWatchApp.swift` is unchanged from the empty `Text("RoundTimer").font(.headline)` shell. The Watch target is also still declared in `project.yml:67-78`. Policy decision still needed.

### OBSERVATION: project.yml is clean and uses INFOPLIST_KEY_ prefix correctly
- **File:** `project.yml`
- **Verified:**
  - All Info.plist keys use the `INFOPLIST_KEY_` prefix per `.claude/rules/xcodegen-gotchas.md` rule #1 (`INFOPLIST_KEY_NSSupportsLiveActivities`, `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad`, etc.)
  - `SUPPORTS_MACCATALYST: false` — explicitly disabled, preventing accidental Mac Catalyst builds
  - `DEVELOPMENT_TEAM: JVZFL2WCHV` matches ship-summary
  - `PRODUCT_BUNDLE_IDENTIFIER` values match ship-summary (com.roundtimer.app + com.roundtimer.app.widget + com.roundtimer.app.watchkitapp)
  - Widget target shares `TimerPhase.swift`, `SoundEvent.swift`, and `TimerActivityAttributes.swift` sources with main app (correct per gotchas rule #3 — widget must still compile when new SoundEvent cases are added)
  - Watch target uses `INFOPLIST_KEY_WKCompanionAppBundleIdentifier: com.roundtimer.app` correctly
- **No issues in project.yml itself** — the Live Activity and compat mode bugs are in source code, not build config.
- **Severity:** informational — PASS
- **Status:** verified ✓

## 2026-04-09 — QA loop pass 9 (compliance audit: Info.plist, entitlements, frameworks, share content)

### VERIFICATION: Zero network requests — confirmed at the BINARY level (strongest possible evidence)
- **Method:** (a) `Grep` source for `URLSession|URLRequest|dataTask|Network|WebKit|webView|HTTPURLResponse` — zero matches. (b) `otool -L RoundTimer.debug.dylib` — no `CFNetwork`, no `Network.framework`, no network-related frameworks linked.
- **Linked frameworks (full list from otool):**
  - Foundation, CoreFoundation — core Swift runtime
  - UIKit — Apple UI bridging
  - SwiftUI — Apple UI
  - AVFAudio — audio (per audio-rules.md)
  - ActivityKit — Live Activities
  - _StoreKit_SwiftUI — `@Environment(\.requestReview)` (modern rate-prompt API)
  - DeveloperToolsSupport — debug/preview only
- **Conclusion:** PRD §Privacy "No network requests whatsoever" is **structurally enforced** — the binary cannot make HTTP requests because it doesn't link any networking framework. No data can leak because no channel exists. **App Store privacy label "Data Not Collected" is fully accurate.**
- **Bonus:** `UIApplication.shared.open(mailto:...)` in `SettingsView.swift:77` for the Send Feedback button does NOT count as a network request — it hands a URL to the system to handle, which delegates to Mail.app, which makes its own network requests under its own privacy accounting.
- **Severity:** informational — STRONGEST PASS. Worth highlighting in the App Store listing and privacy label.
- **Status:** verified ✓✓

### VERIFICATION: Info.plist compliance audit — clean, no privacy surprises
- **File:** `RoundTimer.app/Info.plist` (via `plutil -p`)
- **Privacy usage strings (NSxxxUsageDescription):** **ZERO.** No microphone, camera, location, health, motion, contacts, calendars, or any other permission strings declared. Consistent with "Data Not Collected".
- **NSAppTransportSecurity:** not declared (defaults to HTTPS-only, irrelevant because no network).
- **No NSAllowsArbitraryLoads or similar exceptions.**
- **Verified keys:**
  - `CFBundleIdentifier: com.roundtimer.app` ✓
  - `CFBundleShortVersionString: 1.0.0` ✓
  - `CFBundleVersion: 1` ✓
  - `MinimumOSVersion: 17.0` ✓
  - `LSRequiresIPhoneOS: true` — iOS-only (not Mac Catalyst)
  - `NSSupportsLiveActivities: true` — Live Activities properly declared (this was the V1.0 submission fix from commit 2ab5366)
  - `CFBundleIcons~ipad` — **iPad-specific app icon present** (contradicts PRD's "iPhone compat mode" claim — see below)
  - `UIApplicationSupportsMultipleScenes: true` — supports iPad Split View
  - `UILaunchScreen` — proper launch screen declared
- **Severity:** informational — PASS, no App Store compliance risks.
- **Status:** verified ✓

### CORRECTION (definitive): App is a universal iPhone+iPad binary, not "iPhone compat mode"
- **Source of truth #1:** `UIDeviceFamily: [1, 2]` — `1 = iPhone, 2 = iPad`. **This is the Apple-standard declaration that an app supports both device families.** An iPhone-only app would be `UIDeviceFamily: [1]`.
- **Source of truth #2:** `UISupportedInterfaceOrientations~ipad: [Portrait, PortraitUpsideDown, LandscapeLeft, LandscapeRight]` — all 4 iPad orientations declared. An iPhone-only app would not have this key.
- **Source of truth #3:** `CFBundleIcons~ipad` key present in Info.plist — iPad-specific icon mapped.
- **Source of truth #4:** `AppIcon76x76@2x~ipad.png` present as a physical asset in the `.app` bundle.
- **Source of truth #5:** iteration 7 ran the app on iPad A16 simulator and confirmed the app adapts to iPad's full screen width via SwiftUI's responsive layout.
- **But PRD/ship-summary claim:** "No iPad-specific layout (runs in iPhone compatibility mode)".
- **Reality:** The app is **literally a universal app per all 5 sources of truth.** It supports iPhone (portrait only) and iPad (all 4 orientations), with iPad-specific icon assets. The SwiftUI layout adapts naturally to both.
- **Documentation fix needed:**
  - `docs/prd.md` §Supported Devices: change "No iPad-specific layout (runs in iPhone compatibility mode)" → "Universal iPhone + iPad app via SwiftUI adaptive layout; iPad supports all orientations; iPhone portrait-only"
  - `docs/ship-summary.md` Known Limitations: remove "iPad runs in iPhone compatibility mode (no native iPad layout)"
- **Severity:** P3 — documentation is wrong; actual behavior is better. Tal should update docs to accurately reflect capabilities. This would also let Tal list "iPhone & iPad" in the App Store metadata if not already.
- **Status:** **FIXED** — `docs/prd.md:221-223` now reads "iPhone running iOS 17.0+ (portrait only) / iPad running iPadOS 17.0+ via SwiftUI adaptive layout (all 4 orientations) — universal binary, not iPhone compatibility mode". `docs/ship-summary.md:93` now describes the universal binary explicitly. `docs/future-features.md:39` recasts the item as "iPad-native layout polish" rather than implying compat mode. The App Store metadata was already shipped, so the docs simply now match reality.

### VERIFICATION: Widget extension bundle — correctly built and matches ship-summary
- **Location:** `RoundTimer.app/PlugIns/RoundTimerWidgetExtension.appex`
- **Verified metadata:**
  - `CFBundleIdentifier: com.roundtimer.app.widget` ✓ matches ship-summary
  - `NSExtensionPointIdentifier: com.apple.widgetkit-extension` ✓ proper WidgetKit extension
- **Version mismatch finding:**
  - Main app: `CFBundleShortVersionString: 1.0.0`
  - Widget: `CFBundleShortVersionString: 1.0`
  - Both `CFBundleVersion: 1`
  - The "1.0.0" vs "1.0" is a minor inconsistency. Apple doesn't require widget version to match main app, but it's conventional. Future updates (e.g., main app bumps to 1.0.1 — widget still at 1.0) could cause confusion.
- **Severity:** P3 — minor version number inconsistency, easy fix in `project.yml` / Xcode project settings
- **Status:** **FIXED** — see entry on Widget `CFBundleShortVersionString` above. `project.yml:55-58` now uses `$(MARKETING_VERSION)` / `$(CURRENT_PROJECT_VERSION)`, and the built `.appex` Info.plist resolves to `1.0.0` and `1`

### VERIFICATION: Watch target directory exists as empty shell — matches ship-summary
- **Location:** `RoundTimer.app/Watch/`
- **Contents:** empty folder (just `.` and `..`)
- **Assessment:** ship-summary Known Limitations says "Watch app target exists but is empty (deferred to V1.1)". The bundle includes an empty `Watch/` folder as a placeholder — no Watch app executable, no Watch assets. This is consistent with the documentation.
- **Impact:** negligible bundle size increase; placeholder for V1.1 Watch work.
- **Severity:** informational — matches documentation ✓

### DOCUMENTATION: Share Workout + Share Preset text formats
- **Files:** `PresetListView.swift:306-328`, `ActiveTimerView.swift:339-349`
- **Share Preset (from context menu → "Share"):**
  ```
  <preset name>
  <N> rounds · <formatted duration>
  
  1. WORK <time> [— <interval name>]
  2. REST <time> [— <interval name>]
  ...
  [Warmup: Ns]
  [Cooldown: Ns]
  
  Shared from RoundTimer
  ```
  Example for Tabata: `Tabata\n8 rounds · 4m 0s\n\n1. WORK 0:20\n2. REST 0:10\n\nShared from RoundTimer`
- **Share Workout (from Workout Complete → "Share Workout"):**
  ```
  <preset name> — Done!
  <duration> · <N> rounds · <intervals> intervals
  
  Tracked with RoundTimer
  ```
  Example: `Tabata — Done!\n4:00 · 8 rounds · 16 intervals\n\nTracked with RoundTimer`
- **Missed marketing opportunity:** neither share text includes an App Store link (`https://apps.apple.com/app/id6761851794`). Users who receive a shared workout or preset via Messages/Slack don't get a one-tap way to install the app. Adding a link at the end of both share texts would convert "awareness" into "downloads" for free. PRD §App Store Positioning explicitly mentions acquisition metrics — this is a simple fix that directly supports that goal.
- **Also missed:** Share Workout doesn't include a timestamp/date. Two shares of "Tabata — Done! / 4:00" on different days look identical in the receiver's message history.
- **Severity:** P3 — growth opportunity, not a bug.
- **Fix for acquisition:**
  ```swift
  lines.append("")
  lines.append("Shared from RoundTimer — https://apps.apple.com/app/id6761851794")
  ```
- **Status:** **STILL OPEN (growth/discussion)** — re-verified `PresetListView.swift:365-387` (preset share text still ends with "Shared from RoundTimer" with no link); `ActiveTimerView.swift:344-354` (workout share text still ends with "Tracked with RoundTimer" with no link or date).

## 2026-04-09 — QA loop pass 8 (P1 regression verification + build sanity check)

### REGRESSION CHECK: All 4 P1 bugs confirmed still present on current build
- **Build checked:** `RoundTimer.app` in DerivedData, build version 1.0.0 (1), pid 61585
- **Method:** `stop_app_sim` → clean relaunch → `snapshot_ui` on Presets home (no scrolling, fresh state)

**P1 #1 — Skip-to-complete saves fake workouts** — no re-verification performed. Status inferred as unchanged: the underlying code in `TimerEngine.swift:158-205` has not been modified between iterations (same compiled binary), so the bug is mechanically still present.

**P1 #2 — Pause time counted as workout duration** — same: unchanged code in `TimerEngine.swift:91-94, 135-146`. Bonus observation from this iteration: left AMRAP 10min running from iteration 7 without explicit pauses → elapsed matched wall-clock within 1 second (7:15 elapsed at clock time 11:38, started at ~11:31) → confirms the in-phase wall-clock is correct when there are no pauses. Only explicit pause events cause the inflation.

**P1 #3 — Nav bar buttons missing from a11y tree** — ❌ **STILL BROKEN.** Fresh `snapshot_ui` on Presets home shows nav bar group at `{0, 62, 440, 106}` with `"children": []`. No gear/Settings, no history clock, no "+" button reachable via VoiceOver. The root cause fix from iteration 4 (split HStack into separate ToolbarItems + add `.accessibilityLabel()`) has not been applied.

**P1 #4 — Preset cards not grouped** — ❌ **STILL BROKEN.** Fresh snapshot shows each Boxing row still exposes 8 separate accessibility elements:
  1. `StaticText "Boxing"` at y=189
  2. `Image "Favorite"` at y=194 (star)
  3. `StaticText "Recent"` at y=194 (badge)
  4. `StaticText "12 rounds"` at y=219
  5. `StaticText "48m 0s"` at y=218
  6. `Image "Play"` at y=207
  7. `StaticText "WORK"` at y=246
  8. `StaticText "REST"` at y=246
  VoiceOver users still must swipe 8 times to traverse one preset. Fix not applied.

### SANITY CHECK: Bundle metadata + sound files all intact on current build
- **File:** `RoundTimer.app/Info.plist`
- **Verified:**
  - `CFBundleIdentifier: com.roundtimer.app` ✓ matches `docs/ship-summary.md`
  - `CFBundleShortVersionString: 1.0.0` ✓
  - `CFBundleVersion: 1` ✓
  - `MinimumOSVersion: 17.0` ✓ matches PRD §Supported Devices "iOS 17.0+"
- **Sound files (all 7 present in `RoundTimer.app/` bundle root):**
  - `work_start.wav` ✓
  - `rest_start.wav` ✓
  - `warmup_start.wav` ✓
  - `cooldown_start.wav` ✓
  - `countdown_beep.wav` ✓
  - `half_time.wav` ✓
  - `timer_complete.wav` ✓
- **Severity:** informational — PASS. Build is shippable per metadata; nothing has regressed from the V1.0 submission on 2026-04-08.
- **Status:** verified ✓

### OBSERVATION: Modal dialog state can bleed across foreground/background transitions
- **Screen:** Active Timer with a Stop Timer? dialog visible
- **Steps:** Iteration 7 left iPhone sim with AMRAP 10min running and a Stop Timer? dialog up. Iteration 8 relaunched the app via `launch_app_sim` (which in the simulator just brings the app back to foreground, it doesn't fully kill+restart unless you `stop_app_sim` first) → the dialog was STILL visible on foreground.
- **Assessment:** this is not a bug — SwiftUI modal presentation is preserved when the app is backgrounded/foregrounded without being killed. Once I did `stop_app_sim` + `launch_app_sim`, the dialog was gone.
- **User-facing impact:** if a user taps Stop, their phone goes to sleep, they unlock it 5 minutes later — the Stop Timer? dialog is still sitting there waiting for confirmation. This is consistent with iOS conventions and is expected behavior.
- **Severity:** informational — not a bug
- **Status:** verified as expected behavior

## 2026-04-09 — QA loop pass 7 (5-char countdown ring, WARMUP phase, iPad compatibility)

### OBSERVATION: WARMUP phase captured visually for the first time (Custom preset default)
- **Screen:** Active Timer during WARMUP phase
- **Steps:** Tapped the Custom preset (accidentally, while trying to tap AMRAP) → Active Timer opened showing WARMUP phase, not WORK
- **Observed:**
  - **Amber radial gradient** background — matches `TimerPhase.warmup: Color(red: 1.0, green: 0.7, blue: 0.0)` (#FFB300) ✓ per PRD and `TimerPhase.swift`
  - **"WARMUP" label** in amber text at top
  - **Amber progress ring** around the countdown
  - **"0:10" countdown in RED** — final-10-seconds pulse still applies to warmup phases
  - **"Round 1 / 5"** — 5 rounds for Custom preset
  - **"Next: WORK 0:30"** — preview showing the upcoming transition
  - Round indicator dots: I counted ~1 amber dot (warmup) + 4 gray dots. Not entirely sure if warmup gets its own dot in the indicator or if it's integrated with Round 1 — would need more careful observation.
- **Bonus finding — Custom preset has warmup AND cooldown ENABLED BY DEFAULT:**
  - Math: 5 rounds × (30s work + 15s rest) = 225s = 3:45
  - Preset list shows "4m 5s" = 245s
  - Difference: 20s — breaks down as 10s warmup + 10s cooldown
  - **I missed this in iterations 1-6** because I never started the Custom preset. The factory Custom preset ships with warmup+cooldown enabled.
- **Severity:** informational — confirms warmup/cooldown feature works end-to-end visually (completes the iteration 4 code-only verification).
- **Status:** verified ✓

### OBSERVATION: 5-char "10:00" countdown fits in the ring at max Dynamic Type — with tight margin
- **Screen:** Active Timer running AMRAP 10min
- **Steps:** `content_size accessibility-extra-extra-extra-large` → tap AMRAP 10min → screenshot at 0:00 elapsed (remaining shows 10:00)
- **Observed:** "10:00" **fits within the fixed-size progress ring** without clipping. However, the digits nearly fill the ring horizontally — the margin on either side is small. Any longer string (e.g., "60:00" for a hypothetical 60-min custom work interval) would be at risk of overflow.
- **Recommendation:** add `.minimumScaleFactor(0.8)` and `.lineLimit(1)` to the countdown `Text` to future-proof custom presets with long durations at max Dynamic Type.
- **Severity:** P3 — the built-in presets never exceed 10:00, so this only bites custom presets with very long intervals AT max Dynamic Type.
- **Status:** verified fits; speculative concern for 6+ char times

### BUG: Active Timer footer label truncated at max Dynamic Type — "AMRAP 10min — Interval 1/1" becomes "AMRAP 10min — Interva..."
- **Screen:** Active Timer footer (bottom row showing elapsed/remaining/preset name)
- **Steps:** Run AMRAP 10min at `content_size accessibility-extra-extra-extra-large` → look at the footer
- **Expected:** The preset name + interval position should either wrap to 2 lines or use `.minimumScaleFactor` so it fits.
- **Actual:** The text is `Text(...).lineLimit(1)` (or has a single-line container) so it truncates with "..." to "AMRAP 10min — Interva..."
- **Severity:** P3 — minor truncation at max Dynamic Type only
- **Status:** **FIXED** — verified `ActiveTimerView.swift:181-186` (footer Text now has `.lineLimit(2)` + `.minimumScaleFactor(0.8)` + `.multilineTextAlignment(.center)`)
- **Fix:** `.lineLimit(2)` + `.minimumScaleFactor(0.8)` on the footer Text, OR drop the "Interval X/Y" suffix at accessibility sizes.

### OBSERVATION: iPad compatibility — PRD claims "iPhone compat mode", reality is "full-width universal layout"
- **Screen:** Presets home + Active Timer on iPad (A16) simulator (portrait)
- **Steps:** `xcrun simctl boot AA43689F-F679-4DFB-9199-1AFB18169D98` (iPad A16) → installed the existing iPhone sim build → launched → took screenshots
- **Observed:**
  - App runs without any "iPhone compatibility mode" scaling/letterboxing. It **adapts to the iPad's full width** via SwiftUI's natural responsive layout.
  - **Presets home on iPad portrait:** all 5 preset cards visible at once (plus Quick Start + Create Your Own Timer hint) — iPad's taller screen easily fits the whole list. Cards stretch to full iPad width.
  - **Active Timer on iPad portrait:** ring is centered with LOTS of whitespace around it (ring is iPhone-sized, not scaled to iPad). Functional but not optimized.
  - No cropping, no broken layouts, no clipped content. The app is **more forgiving than PRD claims** — it actually works as a universal iOS app thanks to SwiftUI's adaptive layouts.
- **Contradiction with PRD / ship-summary:**
  - PRD §Supported Devices: "No iPad-specific layout (runs in iPhone compatibility mode)"
  - ship-summary Known Limitations: "iPad runs in iPhone compatibility mode (no native iPad layout)"
  - **Reality:** not in iPhone compat mode. The app uses iPad's full resolution. The PRD/summary statements are wrong — they're probably based on not having Xcode iPad target set, but SwiftUI doesn't need one to adapt.
- **Minor iPad UX concerns (not bugs, but opportunities):**
  - **Preset cards stretch VERY wide on iPad** — a card with "Tabata / 8 rounds / 4m 0s" has a lot of empty horizontal space. A 2-column grid layout would feel more iPad-native.
  - **Active Timer ring is small relative to iPad screen** — a 250pt ring in the middle of a 744pt-tall iPad looks under-scaled. Could be 400-500pt on iPad for better visibility across a gym.
  - **"RoundTimer" title is small relative to iPad screen** — could be a more prominent header on iPad
  - These are V1.2+ opportunities, not V1.0 blockers.
- **Severity:** informational with PRD correction — the app's iPad behavior is BETTER than documented. Tal should **update ship-summary.md and PRD** to say "Universal iOS app with responsive SwiftUI layout" instead of "iPhone compat mode".
- **Status:** verified ✓ — app works on iPad; docs need updating; iPad-specific optimization is a V1.2 opportunity

### OBSERVATION: Countdown digit transition animation captured mid-frame
- **Screen:** Active Timer (REST phase) during digit change
- **Steps:** Random screenshot timing happened to catch the moment between 0:07 → 0:06 transition
- **Observed:** Two instances of "0:06" overlapping vertically — the "number rolling" animation where SwiftUI fades the old digit out and the new digit in. The capture got both visible briefly.
- **Severity:** informational — this is iOS's default `.contentTransition(.numericText())` behavior. Not a bug, just visually confusing when frozen in a screenshot.
- **Status:** not a bug; noted for context

### TEST LIMITATION: XcodeBuildMCP's `snapshot_ui` can fail on iPad simulator
- **Observed:** After `session_set_defaults` to the iPad simulator, `snapshot_ui` returned: "No translation object returned for simulator. This means you have likely specified a point onscreen that is invalid or invisible due to a fullscreen dialog"
- **Workaround:** use `tap(label: ...)` which does work on iPad (verified by successfully tapping "Tabata" label).
- **Impact:** reduces but does not eliminate iPad testing capability via MCP.

## 2026-04-09 — QA loop pass 6 (Increase Contrast, long preset name, extreme Dynamic Type)

### BUG: No maximum character limit on custom preset names — can break list layout
- **Screen:** New Preset sheet → Presets list
- **Steps:** Typed a ~75-char mixed alphanumeric+special-char name via `type_text` (iOS autocorrect mangled it to "AbcdefghAljBKlCMnOD)P1EQ@r3FS$t5^UGV&HW*9xYIvzEJRKY LoNMg NpROeSPeQT NRaSMETUVWXYZ") → tapped Save → preset appeared at bottom of list
- **Expected:** Either (a) a max-length cap (e.g., 40 chars) with live character counter in the name field, (b) graceful truncation with ellipsis in the list view (and full name visible in detail/edit), or (c) at minimum a reasonable soft limit with a warning toast.
- **Actual:**
  - No length validation — the field accepts unlimited characters
  - In the preset list, the long name renders in **FULL across 5 lines at default text size**, making the card ~3× taller than its neighbors
  - **Critical:** at max Dynamic Type (`accessibility-extra-extra-extra-large`), the same long name occupies **11+ lines filling the entire screen**. Scrolling down to reach it is fine, but the card hides ALL other presets and navigation affordances (Quick Start button, Create Your Own Timer footer hint).
  - The card is a "self-inflicted denial of service" — a user who pastes a long string as a preset name blocks their own UI
- **Real-world likelihood:** Low — most users will enter short names. But it's trivially reproducible and a Dakota-style first-time user experimenting with the app could hit it, especially if they paste something from the clipboard.
- **Fix options:**
  1. Hard cap at 40 chars in the ViewModel's setter: `viewModel.name = String(newValue.prefix(40))`
  2. Soft cap + counter: show "75/40" in red below the field and disable Save
  3. List view: `Text(preset.name).lineLimit(2).truncationMode(.tail)`
- **Severity:** P2 — edge case but real UX breakage. Combined with Dynamic Type, it compounds.
- **Status:** **FIXED** — verified `PresetBuilderView.swift:8` (`maxNameLength = 40`) + `:12-18` (`name` setter `didSet` truncates to `prefix(40)`); `PresetListView.swift:408-411` also applies `.lineLimit(2).minimumScaleFactor(0.8)` to the row name as belt-and-suspenders

### BUG: Dynamic Type preset metadata layout is UNREADABLE at accessibility-extra-extra-extra-large
- **Screen:** Presets home, preset list cards
- **Steps:** `xcrun simctl ui <UDID> content_size accessibility-extra-extra-extra-large` (the largest tier) → launch app → view Boxing preset
- **Actual:** At the largest Dynamic Type size, the Boxing row reads vertically as:
  ```
  Boxing ⭐
  ⟲  12      ⏱ 4
  rounds     8m
             0s
  WORK REST
  ```
  The "48m 0s" concept is SHATTERED into `4`, `8m`, `0s` across 3 visual lines with "rounds" adjacent to "8m" as if they're a single phrase. A user with low vision cannot determine that Boxing is "12 rounds, 48 minutes total". **The primary audience for Dynamic Type (low-vision users) gets unreadable output.**
  Tabata is similar: "rounds m 0s" on one visual line looks like a single nonsensical phrase.
- **This is WORSE at extra-extra-extra-large than at extra-extra-large** — the bug upgrades from "awkward wrapping" to "meaning-destroying layout collapse".
- **Severity:** **P2** (unchanged but emphasized) — PRD §Accessibility promises "Dynamic Type support" and the promise is broken at the tier that matters most (the extreme accessibility sizes).
- **Status:** **FIXED** — verified `PresetListView.swift:391, 459-481` (`PresetRow` now reads `@Environment(\.dynamicTypeSize)` and `metadataLayout` switches to a `VStack(alignment: .leading)` of `Label`s when `dynamicTypeSize.isAccessibilitySize`, with `.lineLimit(1).minimumScaleFactor(0.7)`)
- **Fix (as before):** use `.lineLimit(1).minimumScaleFactor(0.7)` on each Label, or switch to vertical layout with `@Environment(\.dynamicTypeSize).isAccessibilitySize`:
  ```swift
  if dynamicTypeSize.isAccessibilitySize {
      VStack(alignment: .leading, spacing: 4) {
          Label("\(preset.rounds) rounds", systemImage: "arrow.2.squarepath")
          Label(formatDuration(preset.totalDuration), systemImage: "clock")
      }
  } else {
      HStack(spacing: 16) { /* current */ }
  }
  ```
- **Status:** **FIXED (re-confirmed)** — already noted above; `PresetListView.swift:391, 459-481` switches preset metadata to vertical Labels at accessibility text sizes.

### BUG: "RoundTimer" nav title overlaps system status bar at max Dynamic Type
- **Screen:** Presets home at `accessibility-extra-extra-extra-large`
- **Steps:** Set max text size → launch app → scroll the preset list down slightly → observe the nav bar
- **Actual:** The "RoundTimer" large title scales so aggressively at max Dynamic Type that its ascender (the "R" and "T" cap-height) **visually overlaps the system status bar** (clock, network indicator, battery icon). At the moment the large title transitions to inline (during scroll), the large title briefly occupies status-bar territory.
- **Fix:** use `.navigationBarTitleDisplayMode(.inline)` on the Presets view to force the inline compact title, which doesn't extend into status bar regardless of Dynamic Type size. OR cap the navigation title's Dynamic Type range with `.dynamicTypeSize(...(.accessibility3))` to prevent it going all the way to the largest tier.
- **Severity:** P3 — visual nit, not blocking functionality. Only appears at the two largest accessibility tiers.
- **Status:** **FIXED** — `PresetListView.swift:6` adds `@Environment(\.dynamicTypeSize)` and `:152-158` adds `.navigationBarTitleDisplayMode(dynamicTypeSize.isAccessibilitySize ? .inline : .automatic)`. The title is still rendered as a large title at normal/large/xLarge sizes, but switches to the inline (compact) layout at the accessibility tiers — which never extends into the status bar regardless of how aggressively Dynamic Type scales.

### OBSERVATION: Stop Timer? alert correctly reflows at max Dynamic Type — SwiftUI default
- **Screen:** Active Timer → Stop confirmation dialog at `accessibility-extra-extra-extra-large`
- **Steps:** Run Tabata → tap Stop with max text size active
- **Actual:** The `.alert` (a SwiftUI Alert) automatically switches from horizontal button layout (Cancel left, Stop right) to **vertical full-screen button layout** with:
  - "Stop Timer?" title in extra-large
  - Body text wraps across 3 lines
  - **Destructive "Stop" button on TOP** (not bottom, following iOS convention for accessibility mode)
  - "Cancel" button below
  - Both buttons are full-width tap targets
- **Severity:** informational — PASS, this is SwiftUI's built-in accessibility behavior and the app benefits from using `.alert` instead of a custom modal.
- **Status:** verified ✓ — good accessibility baseline "for free" from SwiftUI

### OBSERVATION: Countdown ring comfortably fits 4-char times at max Dynamic Type
- **Screen:** Active Timer running Tabata (20s work / 10s rest) at `accessibility-extra-extra-extra-large`
- **Verified:** "0:20", "0:06" — both 4-char countdowns fit within the fixed-size progress ring without clipping.
- **Not tested (inconclusive):** 5-char times like "10:00" (AMRAP 10min) and 4-char times like "3:00" (Boxing work). Test was blocked by the long-name preset dominating the list and making AMRAP hard to tap.
- **Hypothesis:** 5-char times "10:00" / "59:30" might crowd or overflow the fixed-size ring at max Dynamic Type. A `.minimumScaleFactor(0.8)` on the countdown Text would future-proof this.
- **Severity:** P3 (speculative — needs confirmation) — a custom 60-minute Work interval at max Dynamic Type is an edge case.
- **Status:** partial — 4-char OK, 5-char untested

### OBSERVATION: Increase Contrast mode — minimal visible effect on RoundTimer
- **Screen:** Presets home
- **Steps:** `xcrun simctl ui <UDID> increase_contrast enabled` → launch app → compare to default
- **Observed differences:**
  - **Star icons shift from pure yellow to a darker amber/gold** — looks like SwiftUI is automatically adjusting `Color.yellow` for higher contrast against the light background
  - No other visible changes on Presets home: card backgrounds, text color, WORK/REST tag colors, play button green — all unchanged
- **What I expected but did NOT see:** thicker card borders, darker text, removed translucency effects. These would be the typical "Increase Contrast" enhancements for custom SwiftUI views — but since RoundTimer uses solid colors and high-contrast text already, there's little for the system to enhance.
- **Assessment:** the app is already high-contrast by default. Increase Contrast doesn't hurt, and the star-color shift isn't jarring. **PRD §Accessibility "High contrast mode support" is nominally met** — the app respects the system setting and degrades gracefully.
- **Severity:** informational — PASS with caveat: RoundTimer could opt into explicit `@Environment(\.colorSchemeContrast)` handling to boost card borders and text contrast further for low-vision users in Increase Contrast mode, but it's not required for baseline PRD compliance.
- **Status:** verified ✓

### TEST LIMITATION: MCP type_text + iOS autocorrect mangles preset name input
- **Issue:** When typing a long test string "abcdefghijklmnopqrstuvwxyz..." into a SwiftUI TextField, iOS autocorrect kicks in, converts some characters, and the resulting field value is unpredictable (e.g., "AbcdefghAljBKlCMnOD)P1EQ@r3FS$t5^UGV&HW*9xYIvzEJRKY LoNMg NpROeSPeQT NRaSMETUVWXYZ").
- **Impact:** Cannot reliably test specific character counts or exact strings. Tests need to account for autocorrect's interference.
- **Workaround options:** disable autocorrect via `.autocorrectionDisabled(true)` on the TextField (already a SwiftUI modifier), or test via direct UserDefaults manipulation, or use paste-from-clipboard.
- **Note:** **The fact that the field DOES have autocorrect enabled is worth a design question** — preset names are not sentences, they're labels. Autocorrect on a timer-preset field could frustrate users trying to type acronyms like "HIIT" or "EMOM" if autocorrect "corrects" them. **Recommend adding `.autocorrectionDisabled(true)` and `.textInputAutocapitalization(.words)` to the PresetName TextField.**
- **Severity:** P3 (potential UX issue worth investigating) — autocorrect fighting with preset names

## 2026-04-09 — QA loop pass 5 (Dark mode verification, Dynamic Type)

### BUG: Dynamic Type at accessibility-extra-extra-large breaks preset metadata layout
- **Screen:** Presets / home, preset list cards
- **Steps:** `xcrun simctl ui <UDID> content_size accessibility-extra-extra-large` → relaunch app → view preset list
- **Expected:** At max Dynamic Type, preset metadata should either (a) remain on one line via `.minimumScaleFactor(0.7)`, (b) reflow into a vertical stack that keeps each label adjacent to its number, or (c) wrap in a way that preserves "N rounds" / "Nm Ns" as inseparable phrases.
- **Actual:** The HStack layout of "⟲ 8 rounds  ⏱ 4m 0s" breaks apart: numbers "8" and "4" end up on the top line, then "rounds" and "m 0s" wrap to the next line as a single visual phrase "rounds m 0s". This reads as nonsense — a VoiceOver user wouldn't care (text is still announced), but sighted-with-low-vision users (the primary Dynamic Type audience!) see:
  ```
  ⟲  8    ⏱  4
  rounds  m 0s
  ```
  instead of "8 rounds, 4m 0s".
- **Also:** "Recent" badge wraps to "Re-/cent" with hyphenation (minor — acceptable).
- **Also:** preset name "Tabata" wraps to "Taba-/ta" with hyphenation (acceptable).
- **Fix:** use `.lineLimit(1).minimumScaleFactor(0.7)` on each `HStack(Image, Text)` pair, OR switch to a vertical `VStack` layout when `@Environment(\.dynamicTypeSize).isAccessibilitySize` is true:
  ```swift
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
      if dynamicTypeSize.isAccessibilitySize {
          VStack(alignment: .leading) {
              Label("\(preset.rounds) rounds", systemImage: "arrow.2.squarepath")
              Label(formatDuration(preset.totalDuration), systemImage: "clock")
          }
      } else {
          HStack { ... current layout ... }
      }
  }
  ```
- **Severity:** **P2** — PRD §Accessibility promises "Dynamic Type support" and "High contrast mode support". This is a real accessibility regression at the largest accessibility sizes. It's not blocking (text is still readable and VoiceOver is unaffected), but it contradicts an explicit accessibility promise.
- **Status:** **FIXED** (same fix as iter-6 entry above) — `PresetListView.swift:391, 459-481` switches preset metadata to a vertical `VStack` of `Label`s when `dynamicTypeSize.isAccessibilitySize`, preventing the "rounds m 0s" wrap collapse.

### OBSERVATION: Dynamic Type on Active Timer countdown — passes PRD promise
- **Screen:** Active Timer running Tabata
- **Steps:** Set `content_size accessibility-extra-extra-large`, started Tabata, took screenshot
- **Verified:**
  - **Countdown "0:20" scales up** with Dynamic Type ✓ — this is the PRD requirement "Dynamic Type support for countdown text"
  - WORK label scales ✓
  - "Round 1 / 8" scales ✓
  - "Next: REST 0:10" scales ✓
  - Progress ring is **fixed size** — does not scale. At "0:20" the digits fit comfortably, but **longer durations at max Dynamic Type are a concern** (e.g., a 59:59 display on a 60-minute EMOM round might crowd the ring or overflow). Not tested this iteration due to time.
  - Round dots indicator: fixed size (does not scale). Minor visual inconsistency at large text sizes.
  - Control buttons (Pause/Skip/Stop): fixed size (68pt). Reasonable — they're still large enough to tap.
- **Minor visual issue:** the parent nav bar "RoundTimer" title shows at the top of the Active Timer screen (because Active Timer is presented without its own navigation bar). At large Dynamic Type, the parent title becomes huge (~50pt), taking up significant vertical space and crowding the Active Timer display. This is more obvious at max Dynamic Type than at default sizes.
- **Fix recommendation:** wrap ActiveTimerView in `.navigationBarHidden(true)` or use `.fullScreenCover` presentation to fully cover the parent nav bar.
- **Severity:** P3 — minor layout concern at max accessibility sizes. Countdown itself scales correctly per PRD.
- **Status:** PRD promise met for countdown; minor nav bar issue filed separately.

### OBSERVATION: Dark mode verified across all major screens — clean
- **Screens verified this iteration:**
  - **Presets home** ✓ — black bg, dark gray cards, white text, colored tags (WORK green, REST blue), star icons, Recent badge all readable
  - **Active Timer WORK phase** ✓ — green radial gradient on black bg, WHITE countdown digits (was black in light mode — correct inversion), emerald green progress ring, all labels readable
  - **Active Timer REST phase** ✓ — steel blue radial gradient on black bg, **red final-seconds countdown** still readable against blue, HALFWAY pill badge legible
  - **Settings** ✓ — dark gray card form, white text, green toggles, blue feedback buttons
  - **Stop Timer? confirmation dialog** ✓ — dark dialog with white text, red Stop button, neutral Cancel
  - **HALFWAY badge** ✓ — green pill with green text (for WORK phase), blue pill for REST phase — both readable
- **Not explicitly verified but same code paths:** History, New Preset sheet (they share the SwiftUI Form/sheet styling from Settings).
- **Observation:** the **Workout Complete** screen uses a hard-coded dark background (`Color(red: 0.08, green: 0.09, blue: 0.08)` per `ActiveTimerView.swift:233`). So completion stays dark regardless of the system appearance — intentional design choice for the "celebration" feel.
- **No hardcoded color issues found** — all SwiftUI Color literals appear to use semantic colors or colors that work in both modes.
- **Severity:** informational — PASS, ship-summary's "Dark mode support (verified on all screens)" claim is accurate for the screens I tested.
- **Status:** verified ✓

## 2026-04-09 — QA loop pass 4 (Custom preset CRUD, Warmup/Cooldown source review, first-launch, toolbar root cause)

### OBSERVATION: Custom preset lifecycle (create → edit → delete) works correctly
- **Screen:** New Preset sheet → Presets list → long-press context menu → Edit Preset sheet → swipe-delete
- **Tested this iteration:**
  1. **Create** — tapped "+" → New Preset sheet opened with default values (Work 30s / Rest 15s / 3 rounds / no warmup / no cooldown) → typed name → Save → preset appears at the BOTTOM of the preset list.
  2. **Edit** — long-pressed the custom preset → context menu showed **Edit / Duplicate / Share** (3 items, Edit included because `!preset.isBuiltIn`) → tapped Edit → sheet title changed to "Edit Preset" → existing name/intervals/rounds pre-populated → Cancel exits without saving changes.
  3. **Delete** — swipe-left on custom preset row → red "Delete" button revealed → tap Delete → row animates out, preset removed.
  4. **Built-in protection verified:**
     - Long-press on Boxing (built-in) → context menu shows **Duplicate / Share** only (NO Edit, NO Delete) — correct per code `if !preset.isBuiltIn { Edit }`
     - Swipe-left on Tabata (built-in) → no delete button revealed — `deleteDisabled(preset.isBuiltIn)` working
- **Custom presets have NO "Favorite" star** — confirmed by creating a preset: it appeared in the list without the yellow ⭐. This corrects my earlier assumption from iteration 1 that "the star is meaningless because all presets have it". The star IS meaningful: it marks built-in presets. This updates the "star is misleading" finding (see correction below).
- **Severity:** informational — custom preset CRUD works correctly, built-in protection is enforced.
- **Status:** verified ✓

### BUG: MCP text typing into SwiftUI TextField drops early characters
- **Screen:** New Preset sheet → Preset Name field
- **Steps:** tap field → `type_text("QA Test Preset")` → "Q" appears → subsequent `type_text` calls eventually flush the remaining characters
- **Observed:** First text-typing call after focus drops most characters. Splitting the text into smaller chunks eventually fills the field, but character order is preserved.
- **Severity:** test-environment-only, not a product bug. Documenting as a **test limitation** so future QA sessions know to expect this.
- **Workaround:** type field values in 1-3 character chunks with screenshots between, OR test the TextField logic via source review.

### OBSERVATION: Custom presets expose "Delete" as VoiceOver custom action
- **Screen:** Presets list
- **Steps:** Read `snapshot_ui` for the custom preset row
- **Found:** Every element inside the custom preset row has `"custom_actions": ["Delete"]` (name, rounds, duration, play button, phase tags). Built-in presets have no custom_actions.
- **Impact:** This is **good accessibility** — VoiceOver users can delete custom presets via the rotor custom-actions menu WITHOUT needing the swipe-left gesture (which is famously hard to trigger via VoiceOver). This partially mitigates the earlier concern that the Delete button is only reachable via swipe.
- **Severity:** informational — positive finding
- **Status:** verified ✓

### OBSERVATION: Warmup/Cooldown phase rendering verified in source
- **Screen:** N/A — source review (MCP SwiftUI Toggle tap limitation blocked live test of enabling Include Warmup)
- **Files:** `TimerEngine.swift:126-127, 213-214, 191, 202`, `TimerPhase.swift`, `AudioManager.swift`
- **Verified:**
  - `TimerPhase` enum has all 4 cases: `warmup`, `work`, `rest`, `cooldown` with distinct:
    - Display names: "WARMUP", "WORK", "REST", "COOLDOWN" ✓
    - Colors: **amber (#FFB300)** warmup, emerald (#00C853) work, steel blue (#2979FF) rest, **deep orange (#FF6D00)** cooldown — matches PRD §V1.0 palette
    - Sound events: `warmupStart`, `workStart`, `restStart`, `cooldownStart` — all 4 .wav files loaded per iteration 1 log capture
  - `TimerEngine.start()` at line 126-130: if `preset.warmup > 0`, enter `.warmup` phase before interval 0
  - `TimerEngine.finishOrNextRound()` at line 213-214: after the final round's last interval, if `preset.cooldown > 0`, enter `.cooldown` phase before `finish()`
  - `TimerEngine.advanceToNextPhase()` at line 191-202: warmup → enterInterval(0); cooldown → finish()
  - `ActiveTimerView` has no warmup/cooldown-specific code — rendering is generic via `TimerPhase` properties. Good — means warmup/cooldown screens will visually match work/rest with just different colors and labels. No need for special-case UI.
- **Expected sequence:** `warmup (amber) → work 1 → rest 1 → ... → work N → rest N → cooldown (orange) → completion`
- **Severity:** informational — code-verified. Device test still warranted to confirm the amber/orange colors read well on real display.
- **Status:** code-verified

### OBSERVATION: Rate RoundTimer + Send Feedback buttons — correctly implemented
- **Screen:** Settings
- **Files:** `SettingsView.swift:22-34, 65-79`
- **Rate RoundTimer:** Uses `@Environment(\.requestReview)` which wraps `SKStoreReviewController.requestReview()`. Tapping in sim showed no UI because **iOS throttles** the review prompt (~1 per 4 months max per user) AND we already triggered it this session in iteration 2 (Quick Timer completion). Code is correct; no action needed.
- **Send Feedback:** Constructs a `mailto:` URL with:
  - To: `shtark285@gmail.com` (from `docs/ship-summary.md`)
  - Subject: `RoundTimer Feedback (v1.0)`
  - Body: blank lines + auto-appended device info `App: RoundTimer v1.0 (1) / Device: iPhone / iOS: 26.4`
  - Opens via `UIApplication.shared.open(url)` — on real device this opens Mail.app compose sheet.
  - **Sim limitation:** Mail.app isn't configured in the simulator, so the tap may silently fail or open an error. Did not test live to avoid going down that rabbit hole.
- **Severity:** informational — both buttons correctly wired, device test recommended for Send Feedback
- **Status:** code-verified

### OBSERVATION: First-launch cold state (after uninstall + reinstall) — what Dakota actually sees
- **Screen:** Presets home, fresh install
- **Steps:** `xcrun simctl uninstall 3DA32ED6... com.roundtimer.app` → `build_run_sim` → screenshot
- **Observed:**
  - 5 built-in presets in factory order: **Tabata → Boxing → EMOM → AMRAP 10min → Custom**
  - **No "This Week" card** (empty history collapses it — verified in iteration 3)
  - **No "Recent" badge** on any preset (no preset has been used yet)
  - **No onboarding modal, no tutorial, no welcome flow** — straight to the preset list
  - Quick Start button and "Create Your Own Timer" hint at the bottom of the scroll view
  - Gear (Settings) and clock (History) in top-left; "+" in top-right (all three unreachable via VoiceOver per the P1 toolbar bug)
- **Dakota's reaction (predicted):**
  1. "What's Tabata?" (no explanation)
  2. "8 rounds, 4m 0s, WORK, REST" — concrete numbers but no sense of difficulty or purpose
  3. Default scrolled to top → Tabata is the first preset. If Dakota taps it to explore, she IMMEDIATELY starts a 4-minute workout. No preview.
  4. After tapping Stop + Cancel + back to Presets, Dakota has learned what "Tabata" means in the crudest possible way.
- **Missing (recommended for V1.0.1 / V1.1):**
  - First-launch modal: 3-screen walkthrough ("Pick a preset", "Tap to start", "Tap stop when done")
  - Preset description text below the name: "High-intensity interval training with 20s work / 10s rest"
  - Info button (ⓘ) on each preset card that opens a detail sheet WITHOUT starting the workout
- **Severity:** P2 (new-user onboarding gap, not a crash) — already flagged in iteration 3's Dakota persona finding; this iteration adds empirical confirmation that uninstall + reinstall produces the exact predicted state.
- **Status:** verified — first-launch is clean and crash-free, but lacks guided onboarding

## 2026-04-09 — QA loop pass 3 (Boundaries, empty states, persona journeys, HALFWAY capture)

### BUG: Preset row tap target too eager — scroll gesture can accidentally start workouts
- **Screen:** Presets home, preset list
- **Steps:** Attempted `swipe(x1=220, y1=200, x2=220, y2=900, duration=0.4)` as a scroll gesture. Instead of scrolling the list, it started a Tabata workout (landed on the Tabata row as a tap).
- **Expected:** A swipe that traverses multiple rows and has significant delta should be treated as a scroll gesture, not a tap on the first row it touches.
- **Actual:** The row tap handler appears to win the gesture arbitration too early. A scroll that starts inside a row's bounds becomes a row tap.
- **Real-world impact:** Riley tries to scroll the preset list to find a preset farther down, but her finger lands in the middle of Tabata — she accidentally starts a workout, has to tap Stop, confirm, and scroll again more carefully. Friction on a screen that PRD optimizes for "glance + tap once".
- **Severity:** P2 — usability friction, not a crash. Root cause is likely the preset row's `.onTapGesture` (or Button) winning against the ScrollView's pan gesture too quickly. SwiftUI fix: use `.simultaneousGesture` or ensure the row is a proper Button (not a custom tap) so iOS' gesture arbitration delays the tap until scroll is ruled out.
- **Status:** **FIXED** — verified `PresetListView.swift:71-76` (preset rows are now wrapped in a proper `Button { startPreset(preset) } label: { PresetRow(...) }` with `.buttonStyle(.plain)`); SwiftUI's standard List+Button gesture arbitration now defers the tap until a scroll is ruled out.
- **Note:** this is the same root cause that made Dakota's "tap to preview" impossible — any touch on a row commits immediately.

### BUG: Countdown sound triggered onCountdownTick CAN fire haptic while haptic is "supposed to be quiet"
(covered in iteration 2 finding — confirmed again this pass; no additional evidence here)

### OBSERVATION: Empty state after Clear History works cleanly
- **Screen:** History (empty) + Presets home
- **Steps:** Tapped Clear → popover "Clear all workout history? / Clear All" → tapped Clear All → all entries removed → "No Workouts Yet" empty state with clock icon and "Complete a workout and it will appear here." tagline
- **Additional finding:** When history is empty, the **Clear button disappears from the toolbar** (only "Done" remains). Smart — no destructive action offered when there's nothing to destroy.
- **Additional finding:** When history is empty, the **"This Week" summary card on the Presets home disappears entirely**. The preset list moves up to take its place. Clean, not showing zero-state stats.
- **Additional finding:** Clearing history does NOT clear the "Recent" badge on the last-used preset. Tabata still shows "Recent" after Clear All. This suggests "Recent" is persisted separately from the workout log (probably in UserDefaults or in the preset's `lastUsedDate`), which is a reasonable independence.
- **Severity:** informational — PASS, clean empty state handling
- **Status:** verified

### OBSERVATION: HALFWAY visual alert captured in simulator
- **Screen:** Active Timer mid-REST
- **Steps:** Started Tabata, let it run through Round 1 into Round 2, caught the moment at Rest R2 with 0:05 remaining (half of a 10-sec rest phase)
- **Visible:** Blue pill-shaped badge with white "HALFWAY" text centered below the REST label, above the countdown. Badge styled to match rest-phase blue.
- **Severity:** informational — feature verified end-to-end (code in iteration 2, visual this iteration)
- **Status:** verified ✓

### OBSERVATION: Double-Pause is idempotent (safe)
- **Screen:** Active Timer
- **Steps:** Tapped Pause twice in rapid succession on a running timer
- **Expected:** First Pause pauses. Second Pause should either (a) be a no-op because the button has become Resume, or (b) erroneously Resume the timer.
- **Actual:** First tap paused (state: PAUSED overlay shown, button changes to Resume/Play icon). Second tap on "Pause" label no-ops because the label no longer matches (button is now "Resume"). Safe behavior.
- **Code reference:** `TimerEngine.swift:135-139` — `guard !isPaused else { return }` in `pause()` protects against double-pause state corruption.
- **Severity:** informational — PASS
- **Status:** verified

### OBSERVATION: Double-Stop is safe (dialog intercepts second tap)
- **Screen:** Active Timer with Stop Timer? confirmation dialog
- **Steps:** Tapped Stop timer button twice in rapid succession
- **Expected:** First Stop tap shows the confirmation dialog. Second Stop tap should either (a) be intercepted by the dialog (because Stop button is now behind the dialog overlay) or (b) dismiss the dialog (tap-outside).
- **Actual:** First tap shows dialog. Second tap attempt returns `No accessibility element matched --label 'Stop timer'` — confirming the underlying button is no longer in the a11y tree while the dialog is modal. Safe.
- **Severity:** informational — PASS
- **Status:** verified

### OBSERVATION: Double-tap on preset row doesn't double-start
- **Screen:** Presets home
- **Steps:** Tapped twice rapidly on the EMOM row
- **Expected:** One timer starts, second tap is absorbed by the navigation transition.
- **Actual:** EMOM timer started once cleanly. Second tap didn't cause a duplicate timer or weird state. Safe.
- **Severity:** informational — PASS
- **Status:** verified

### OBSERVATION: EMOM preset structure verified
- **Screen:** Active Timer running EMOM
- **Steps:** Started EMOM from preset list
- **Observed:** Round 1/10, WORK only (no REST interval), 1:00 countdown, "Next: Round 2 — WORK" (because EMOM has no rest period — next interval is next round's work). 10 dots round indicator.
- **Cross-check:** PRD §EMOM: "Every Minute on the Minute | Work period within a minute, repeated | 1min rounds, work until done". App's label "Quick Timer — Interval 1/1" matches — EMOM has 1 interval per round (work only).
- **Severity:** informational — PASS
- **Status:** verified

### PERSONA: Riley (HIIT, 10-min window, 3x/week) — PASS with caveats
- **Riley test:** "From open app to timer running in under 3 seconds, zero fumbling."
- **Observed flow:** Launch app → Presets list → tap Tabata row → Active Timer running. **~1 tap after launch.** Time to timer: effectively instant once Presets is visible.
- **PASS criteria met:** time-to-start, glance visibility (large countdown), round-visible round indicator, final-seconds red countdown, phase transitions with clear color changes.
- **PASS (device needed):** audio on phase transitions to hear mid-burpee.
- **CAVEAT:** Riley can no longer scroll the preset list without accidentally starting workouts (see preset row tap-target bug above). If she's used to Tabata at position 1, she's fine — if she wants EMOM or Boxing, she may fumble.
- **CAVEAT:** after completing her workout, the rate-review prompt may pop up **overlapping the completion stats**, stealing her satisfaction moment. The prompt UI partially covers Duration/Rounds/Intervals stat blocks.
- **VERDICT:** Riley's use case is RoundTimer's sweet spot. Core flow is clean.

### PERSONA: Marcus (boxer, 3min rounds, Spotify over speaker, daily) — PASS pending device
- **Marcus tests:** "Can I start with gloves? Audio over Spotify? Round info glance-readable? Music uninterrupted?"
- **Observed:**
  - Preset row tap target is large enough to hit with a gloved nose (visual rows are ~100pt tall × full-width)
  - Boxing preset correctly configured: 12 rounds × (3:00 work + 1:00 rest) = 48m total
  - REST screen fills with blue background + large REST label — glance-distinguishable from green WORK
  - Round label "Round 3 / 12" prominent, final-seconds red countdown for urgency
- **DEVICE-ONLY (not verifiable on sim):**
  - Audio actually playing over Spotify without ducking
  - Bell-like sounds audible over loud bluetooth speaker
  - Music uninterrupted by phase transition sounds
- **Code-verified:** `AVAudioSession.category = .ambient, options = [.mixWithOthers]` set in `AudioManager.configure()`; bundled .wav files loaded via AVAudioPlayer (NOT AudioServicesPlaySystemSound per the .claude/rules/audio-rules.md)
- **VERDICT:** App is architected correctly for Marcus. Device testing is the only gate left.

### PERSONA: Priya (track runner, bright sun, sweaty thumbs, weekly) — PASS pending device
- **Priya tests:** "Readable in direct sun? Sweat-proof touch targets? Screen stays awake 90s? Audio cue when I can't look?"
- **Observed:**
  - Contrast: white background + black countdown digits + colored phase labels = high contrast, good for bright conditions
  - Pause/Skip/Stop buttons are 68pt circles with ~40pt gaps — large, widely-spaced, unlikely to mis-tap
  - Default preset list isn't relevant for Priya (she'd use Quick Timer or Custom) — Quick Timer path tested this iteration, works cleanly
  - `keepScreenAwake` setting defaults to ON, wired via `ActiveTimerView.onAppear` (code verified in iteration 2)
- **DEVICE-ONLY:** actual screen dimming behavior over 90 sec, audio audibility outside in wind, haptic strength through armband
- **VERDICT:** Design-ready for Priya. Device verification of screen-awake is the main remaining risk.

### PERSONA: Dakota (first-time user, no fitness app experience) — FAIL (onboarding gap)
- **Dakota test:** "Can I figure out this app without reading a tutorial? Every screen that requires explanation is a UX bug."
- **Observed friction:**
  1. **First launch → preset list of jargon.** Dakota sees "Tabata", "Boxing", "EMOM", "AMRAP", "Custom". Only "Boxing" is self-explanatory. "Tabata" / "EMOM" / "AMRAP" are acronyms with no inline explanation. No tooltip, no info button, no first-time overlay.
  2. **Tapping a preset row starts the timer immediately** — there is NO preview or detail screen. Dakota cannot explore "what does Tabata do?" without committing to a 4-minute workout. The only way to find out is to START it and then read the intervals as they happen.
  3. **During an active Tabata**, Dakota sees "WORK / REST / WORK / REST" cycling but has no context for why. The PRD explicitly called this out: "The app assumes I know."
  4. **"Quick Timer" vs "Create Your Own Timer"** — Dakota sees both at the bottom of the list. The subtitles help (Quick Timer: "Set work, rest & rounds — start instantly" / Create Your Own: "Tap + to build a custom interval timer"), but the distinction is still subtle. Is Quick Timer a throwaway? Is the + a persistent preset? She'd have to experiment.
  5. **The "+" button is hidden from VoiceOver** (systemic toolbar bug), so a VoiceOver-using Dakota can't even reach the preset builder.
  6. **AMRAP 10min** shows "Round 1 / 1" + "Final interval!" from second 1 of the workout. For Dakota, "Final interval!" is confusing — she just started. (AMRAP has 1 "round" in the model, so everything is the final round.)
  7. **After 3 workouts, Dakota gets a rate prompt** — she's barely explored the app. With the skip-to-complete bug inflating the count, she might get asked after just 1 real workout.
- **MISSING for Dakota:**
  - First-launch onboarding or a 3-step intro ("Pick a preset" → "Tap to start" → "Tap stop to finish")
  - Preset description/tooltip: "Tabata: 20s work, 10s rest, 8 rounds, 4 minutes total. Developed by Dr. Izumi Tabata for high-intensity training."
  - Preset preview/detail screen separate from "Start now" — a long-press or row-tap could open detail, Play button on the row starts immediately
  - Fix "Final interval!" label for AMRAP 1-round (say "10 minute AMRAP" or "Keep going!" instead)
- **Severity:** **P2** — this is a new-user experience gap that directly impacts conversion and first-impression reviews. The app is $4.99 up-front; users who can't figure out the value in 60 seconds will refund or 1-star. Riley/Marcus/Priya don't need this, but Dakota is 50% of first-time downloads.
- **Status:** **STILL OPEN (recommendation)** — no first-launch onboarding modal, no per-preset description, no preview-before-start flow added. Tracked as a V1.0.1 / V1.1 UX item.

## 2026-04-09 — QA loop pass 2 (Quick Timer, drift, Settings cross-screen)

### BUG: "Countdown Beeps (3-2-1)" toggle only gates audio, haptic tick still fires
- **Screen:** Settings → Countdown Beeps (3-2-1) toggle
- **File:** `RoundTimer/Views/Presets/PresetListView.swift:275-278` + `HapticManager.swift:31-34`
- **Code evidence:**
  ```swift
  // PresetListView.swift
  engine.onCountdownTick = { seconds in
      AudioManager.shared.playCountdownIfNeeded(secondsLeft: seconds)  // gated by countdownBeepsEnabled + isSoundEnabled
      HapticManager.shared.countdownTick()                              // gated ONLY by isHapticsEnabled
  }

  // HapticManager.swift
  func countdownTick() {
      guard SettingsManager.shared.isHapticsEnabled else { return }  // no countdownBeepsEnabled check
      light.impactOccurred()
  }
  ```
- **Expected:** Disabling "Countdown Beeps" should silence both the audio beeps AND the 3-2-1 haptic pulses. Users who turn this off want NO countdown feedback, audio or tactile.
- **Actual:** Only the audio is suppressed. The haptic light impact still fires at 3, 2, 1 as long as Haptic Feedback is enabled. A user can't selectively turn off "the 3-2-1 thing" — they have to kill all haptics to kill the countdown haptic.
- **Severity:** P3 — design ambiguity, not silently broken. Could be intentional (separate audio/haptic controls). Worth confirming with Tal; if intentional, the toggle label should be "Countdown Sound" not "Countdown Beeps (3-2-1)" to clarify.
- **Status:** **FIXED** — verified `HapticManager.swift:39-43` introduces `countdownTickIfEnabled()` which gates on BOTH `isHapticsEnabled` AND `countdownBeepsEnabled`; `PresetListView.swift:336` now calls `countdownTickIfEnabled()` from the `onCountdownTick` callback. Half-time gets its own distinct `halfTimeTick()` (medium impact, distinguishable from the light-impact countdown).
- **Related:** `onHalfTime` at `PresetListView.swift:279-282` uses `HapticManager.countdownTick()` for half-time too — so half-time and countdown have identical haptic patterns. Users can't tell them apart by feel alone.

### BUG: `AudioManager.playCountdownIfNeeded` marks tick "played" even when sound is disabled
- **Screen:** N/A — code path
- **File:** `RoundTimer/Engine/AudioManager.swift:56-61`
- **Code evidence:**
  ```swift
  func playCountdownIfNeeded(secondsLeft: Int) {
      guard secondsLeft != lastCountdownTick else { return }
      guard SettingsManager.shared.countdownBeepsEnabled else { return }
      lastCountdownTick = secondsLeft
      play(.countdownBeep)  // play() may also no-op if isSoundEnabled is false
  }
  ```
- **Actual:** If the user has countdownBeepsEnabled=false, `lastCountdownTick` never updates (because of the early return) — that's actually fine.
  But if countdownBeepsEnabled=true and isSoundEnabled=false, then `lastCountdownTick = secondsLeft` runs, then `play()` no-ops silently. The tick is marked played when it wasn't, so if the user flips Sound Effects ON mid-countdown, the next check for the same `secondsLeft` will skip it.
- **Severity:** P3 — edge case, only happens if user flips Sound Effects mid-3-2-1 countdown which is unlikely.
- **Fix:** swap order — assign `lastCountdownTick` after `play()` returns, or only assign it when `play()` actually played (requires refactor to return a Bool).
- **Status:** **FIXED** — `AudioManager.swift:56-65` now adds `guard SettingsManager.shared.isSoundEnabled else { return }` BEFORE the `lastCountdownTick = secondsLeft` assignment. The tick is no longer marked played when sound is disabled, so re-enabling Sound Effects mid-countdown plays the next tick at the same `secondsLeft` correctly.

### OBSERVATION: Settings cross-screen plumbing verified in source (all 4 toggles wired correctly)
- **Screen:** Settings + all views that consume settings
- **Verification method:** source code review — simulator MCP cannot interact with SwiftUI Toggle controls (all tap attempts at the switch coordinates left AXValue="1" unchanged, even with preDelay/postDelay). Toggles were verified by reading the code paths rather than clicking them.
- **Findings:**
  - ✓ `isSoundEnabled` → guards `AudioManager.play()` at `AudioManager.swift:49`
  - ✓ `countdownBeepsEnabled` → guards `AudioManager.playCountdownIfNeeded()` at `AudioManager.swift:58`
  - ✓ `isHapticsEnabled` → guards all 3 HapticManager methods (phaseTransition, countdownTick, timerComplete) at `HapticManager.swift:20,32,37`
  - ✓ `keepScreenAwake` → wired in `ActiveTimerView.swift:221-227` with `onAppear`, `onChange`, and `onDisappear=false` cleanup (correct 3-state handling)
- **Severity:** informational — code paths verified correct.
- **Limitation:** live device QA should still physically flip each toggle and run a workout to confirm end-to-end. MCP tool limitation prevented sim verification.
- **Status:** code-verified, needs device verification

### OBSERVATION: Background/foreground wall-clock survives backgrounding (Quick Timer test)
- **Screen:** Active Timer
- **Steps:** Started Quick Timer (30s work / 15s rest / 3 rounds), backgrounded at ~8 sec elapsed via `button(home)`, waited 15.013 seconds wall-clock, called `launch_app_sim` to re-foreground, took screenshot
- **Expected:** After 15+ sec of background, app should have advanced through phases via wall-clock catch-up. At 23 sec elapsed we expect to be past Work R1 (30s) — wait, 23 sec is still within Work R1. Actually the background was 15s, so returning from background at ~23s into the workout, we should STILL be in Work R1 (7s remaining). My earlier analysis miscounted.
  Actually the screenshot showed Work R2, 0:08 remaining which is 22 sec into Work R2 = 67 sec total. That's ~44 sec after Start Timer — much more than my 8+15=23 sec estimate. Tool latency between Start Timer and the pre-background snapshot was apparently larger than expected.
- **Actual:** Returned to Work R2 at 0:08 remaining, elapsed 1:07 displayed. Phase sequence advanced correctly across the background window. The `Date()`-based `elapsedTime` calculation works, confirming the PRD wall-clock rule for simulator backgrounding.
- **Caveat:** This does **not** prove real-device backgrounding works (iOS may suspend the app more aggressively). **Still needs device verification** per qa-prompt.md Step 8: phone locked in pocket 10+ min → unlock → remaining time correct.
- **Severity:** informational — simulator-side behavior is consistent with design. Device test still pending.
- **Status:** sim-verified, device verification pending

### BUG: Smart review prompt fires on "3rd workout" counting the fake 22-sec AMRAP from the skip bug
- **Screen:** Workout Complete → Enjoying RoundTimer? prompt
- **Steps:**
  1. Iteration 1: ran Tabata briefly (stopped) — not saved
  2. Iteration 1: ran AMRAP 10min → immediately skipped → saved as 22s completion (skip-to-complete bug)
  3. Iteration 2: ran Quick Timer (30s×3 / 15s×3) → completed naturally
  4. On the Workout Complete screen for (3), the `SKStoreReviewController` "Enjoying RoundTimer?" prompt appeared
- **Expected:** PRD/ship-summary says "Smart review prompt (after 3rd, 10th, 25th workout)". If the user has really done 3 legit workouts, that's appropriate. But the trigger counted the fake 22-sec AMRAP.
- **Actual:** The review prompt was triggered early because the fake workout inflated the count. Users who hit skip-to-complete once will get asked to rate the app after essentially one real workout.
- **Severity:** P2 — chained effect of the skip-to-complete P1 bug. If skip-to-complete is fixed, this resolves automatically. If not, this compounds the skip bug's damage by burning review-prompt opportunities.
- **Note:** the review prompt UI also overlaps the workout stats (Duration/Rounds/Intervals) — the celebration and the ask both compete for attention at the same moment. A cleaner flow would be: celebrate first, let the user see stats, then prompt on a subsequent Done tap or app open.
- **Status:** **FIXED (transitive)** — the underlying skip-to-complete P1 is fixed (see iter-1 entry), so fake completions can no longer inflate the workout count. The unrelated UI-overlap concern (review prompt covering stats) is unchanged and remains a polish item.

### BUG: Final-round trailing rest is counted in Quick Timer duration (2m 15s total instead of 2m)
- **Screen:** Quick Timer → workout flow
- **Steps:** Quick Timer defaults 30s Work / 15s Rest / 3 rounds. Total displayed as "2m 15s" in builder + saved as "2m 15s" in History.
- **Math:** 3 × (30s + 15s) = 135s = 2:15. This counts a Rest after the final Work interval.
- **Expected:** Most interval timer apps do NOT include a trailing rest after the last work — you're done working, no reason to rest for 15 seconds before declaring the workout over. Common convention: `(N-1) × (work + rest) + 1 × work` = 2 × 45 + 30 = 120s = 2:00.
- **Actual:** App adds one more rest at the end, so a "30s work × 3 rounds" Tabata-style workout takes 2:15 wall-clock instead of 2:00. Users set 30s/15s × 3 expecting a ~2 minute workout and get 15 extra seconds of "rest" while they're already sitting down.
- **Severity:** P2 — design call more than a bug, but it contradicts how Tabata/boxing/HIIT work in practice. Boxing preset (12 rounds × 3m work / 1m rest = 48m 0s) displays 48m exactly, which matches 12×(3+1) = 48m — so Boxing ALSO includes the trailing rest. Means the convention is applied consistently but it may not match user expectations.
- **Status:** **STILL OPEN** — re-verified `QuickTimerView.swift:69-79` (`buildPreset()` still appends a Rest interval whenever `restDuration > 0`, so `3 × (30s + 15s) = 2:15` total). Design discussion still pending.

### OBSERVATION: "HALFWAY" alert confirmed in source but hard to catch in sim QA (2-second visual window)
- **Screen:** Active Timer, half-time alert
- **File:** `RoundTimer/Engine/TimerEngine.swift:251-265` + `RoundTimer/Views/ActiveTimer/ActiveTimerView.swift:41-50`
- **Code evidence:**
  ```swift
  // TimerEngine.swift half-time detection
  if !halfTimeFired && currentPhaseDuration >= 10 {
      let halfPoint = currentPhaseDuration / 2.0
      if elapsed >= halfPoint {
          halfTimeFired = true
          isHalfTime = true
          onHalfTime?()
          halfTimeDismissTask?.cancel()
          halfTimeDismissTask = Task { [weak self] in
              try? await Task.sleep(for: .seconds(2))  // visible for exactly 2 seconds
              guard !Task.isCancelled else { return }
              self?.isHalfTime = false
          }
      }
  }

  // ActiveTimerView.swift
  if engine.isHalfTime {
      Text("HALFWAY")
      ...
      .animation(.spring(duration: 0.3), value: engine.isHalfTime)
  }
  ```
- **Findings:**
  - Half-time only fires for phases ≥ 10 seconds ✓ (makes sense — a 5-sec work phase doesn't need a half-time alert)
  - Visual window is exactly 2 seconds, so simulator polling with screenshots frequently missed it
  - Audio plays `.halfTime` via AudioManager (gated by isSoundEnabled)
  - Haptic fires `countdownTick()` (single light impact — same as 3-2-1 ticks, not distinguishable by feel)
- **Severity:** informational — feature works per code, just hard to catch visually in automated sim testing
- **Status:** code-verified

### OBSERVATION: Final-seconds red countdown confirmed visually (PRD §Active Timer Screen)
- **Screen:** Active Timer during any work/rest phase
- **Steps:** Watched Quick Timer at 0:01 remaining in a Work phase
- **Verified:** Countdown digits turn **red** in the final 10 seconds. Matches PRD expectation: "Final 10 seconds: countdown text pulses or changes color".
- **Severity:** informational — PASS
- **Status:** verified

### OBSERVATION: Log inspection for device-only features (simulator session)
- **Screen:** N/A — log-based verification
- **Steps:** `start_sim_log_cap(captureConsole: true, subsystemFilter: all)` → ran Tabata + AMRAP → `stop_sim_log_cap` → filtered for `[LiveActivity]`, `AVAudioSession`, sound-file-not-found, audio session errors
- **Findings:**
  - `[LiveActivity] areActivitiesEnabled: true` ✓
  - `[LiveActivity] frequentPushesEnabled: false` (correct — not using push)
  - `[LiveActivity] Started successfully, id: ...` fired on **both** preset starts ✓
  - **NO `[LiveActivity] Updated` logs anywhere** — not because updates failed, but because `TimerActivityManager.update()` at `TimerActivityManager.swift:46-63` has **no logging at all**. A failed update is silent.
  - **NO `[LiveActivity] Ended` logs** — same cause: `end()` at `TimerActivityManager.swift:65-86` has no logging. If the `end()` Task fails or the activity lookup returns nil, the code silently resets `activityId` and exits. We have no evidence the AMRAP Live Activity was actually ended; we only know start fired.
  - `AVAudioSession` initialized successfully (no "Failed to configure" errors)
  - All 7 sound files loaded without "Sound file not found" errors
- **Severity:** P3 — observability gap, not a user-facing bug. But when device QA finds a "Live Activity didn't dismiss after workout" issue, there will be zero logs to triage it.
- **Recommendation:** add one log line each at the start of `update()` and `end()` (and inside the `Task` completion) in `TimerActivityManager.swift`.
- **Status:** **FIXED (logging gap)** — verified `TimerActivityManager.swift:50` ("update skipped: no tracked activity"), `:67` ("Updated id: ... phase: ... paused: ..."), `:75` ("end skipped: no tracked activity"), `:94` ("Ended id: ..."), `:110` ("Cleaning up stale activity: ..."). Device-only QA items still pending — DEVICE-ONLY verification still required per qa-prompt.md Step 8:
  - [ ] Live Activity countdown renders on Lock Screen
  - [ ] Dynamic Island compact view shows current phase
  - [ ] Live Activity actually dismisses (doesn't become stale) after workout complete
  - [ ] Audio plays over Spotify at normal volume
  - [ ] Haptic fires at Work→Rest transition
  - [ ] Screen stays awake for 20-min workout
  - [ ] Audio continues when phone is locked mid-workout
  - [ ] Audio resumes cleanly after phone-call interruption

### OBSERVATION: SF Symbol names leaking as `AXUniqueId`
- **Screen:** Presets / home
- **Steps:** Inspect snapshot_ui
- **Expected:** Unique, semantic accessibility identifiers (e.g., `preset-tabata-play-button`).
- **Actual:** `AXUniqueId` values are raw SF Symbol names: `star.fill`, `play.circle.fill`. Not user-visible but makes UI automation brittle (all play buttons share the same id).
- **Severity:** P3
- **Status:** **LARGELY ADDRESSED** — toolbar buttons now have explicit `.accessibilityIdentifier("settingsButton" / "historyButton" / "addPresetButton")` (`PresetListView.swift:160, 168, 177`); play icons and star icons inside preset rows are now `.accessibilityHidden(true)`, so they no longer appear in the a11y tree at all. Combined with the row-as-button change, the SF-Symbol-name leak is no longer reachable for the previously-affected controls.

