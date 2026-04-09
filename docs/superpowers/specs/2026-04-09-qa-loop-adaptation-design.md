# QA Loop Adaptation for RoundTimer

**Date:** 2026-04-09
**Status:** Approved — ready for implementation plan

## Goal

Give RoundTimer a proper QA prompt that Claude (or a subagent) can invoke to thoroughly test a change or feature before committing. Adapted from the shipped ParkTimer QA loop at `/Users/tal/WebstormProjects/ParkTimer/docs/qa-prompt.md`.

## Deliverables

1. **`docs/qa-prompt.md`** — the RoundTimer QA process (adapted from ParkTimer's 253-line version)
2. **`docs/qa-findings.md`** — empty-stub bug log, same format as ParkTimer's, ready to be appended to during QA runs

## What is preserved from the ParkTimer source

Structure and bones transfer 1:1 so muscle memory carries between apps:

- Mindset intro: "You are QA. Assume everything is broken until you prove it isn't."
- "Before You Start" section: read PRD + ship-summary, clear assumptions
- Numbered step structure (though one step is dropped — see below)
- "The Three Questions" framework (spec / functional / human sense)
- Persona Journeys format (narrative, emotional state, stress-test)
- "What the Simulator CANNOT Test" table
- Reporting format: `BUG: / Screen: / Steps: / Expected: / Actual: / Severity: P0–P3`
- XcodeBuildMCP tools reference
- "The Golden Rule" closer

## What is removed (ParkTimer-only)

- **All Free/Pro tier testing.** RoundTimer is $4.99 paid upfront, no IAP.
- **Step 5 "Leaked Feature Audit" entirely.** There are no gated features to leak. Step count drops from 9 → 8.
- **Parking personas** (Alex/Sam/Jordan/Morgan), Find Car flows, vehicle icon consistency, `store.proUnlocked` simctl commands, GPS simulation, location permission revoke.

## What is adapted (RoundTimer-specific content)

### Step 1: Look Before You Touch
Same 5 questions, framed around RoundTimer's screens (Presets / Active Timer / Quick Timer / Settings / History).

### Step 2: Interact With Everything
Same, reoriented to RoundTimer's controls:
- Preset list: swipe-to-delete, long-press, tap-to-edit, tap-to-start
- Active timer: Start/Pause/Resume/Skip/Stop (and the Stop confirmation dialog)
- Settings toggles: Sound, Haptics, Screen Awake, Countdown Beeps

### Step 3: Test the Boundaries
New edge cases grounded in `TimerEngine`:
- 0-second warmup (should skip cleanly to Work)
- 1-second interval (is half-time alert sensible? does it even fire?)
- 99 rounds (no overflow, display correct)
- Pause during 3-2-1 countdown beeps
- Skip during the final interval (transitions to completion, not an empty state)
- Tap Start twice, tap Stop twice
- Skip past the last phase

### Step 4: Test State Transitions
**The heart of the doc for RoundTimer** — TimerEngine is a state machine and transitions are where bugs live.

Transitions to test:
- Idle → Work (Start pressed)
- Work → Rest (auto-advance fires haptic + audio)
- Active → Paused → Resumed (wall-clock time preserved, zero drift)
- Normal → Half-time (50% mark fires audio + visual badge)
- Active → Stopped (confirmation dialog → clean return to presets)
- Active → Completed (final interval ends → celebration screen)
- **Background → Foreground drift test** (CLAUDE.md load-bearing rule): background for 60s, foreground, remaining time is accurate
- App killed mid-timer → Relaunched (graceful recovery OR clean reset — document which is correct)
- Spotify playing → Start timer (audio plays OVER, does not duck or interrupt)
- Phone call during timer (audio session interruption handled)

### Step 5: Cross-Screen Consistency (was Step 6)
Settings toggles must actually affect the active timer:
- Sound off → no audio on phase transitions or countdown
- Haptics off → no vibration on button taps or transitions
- Countdown beeps off → no 3-2-1 at interval end
- Screen awake off → screen can dim during timer
- Edit a preset → starting a timer from that preset reflects the edit
- Complete a workout → History reflects it, weekly summary updates

### Step 6: The Three Questions (was Step 7)
Framework kept verbatim. ParkTimer's "cost tracker" Q3 example replaced with a RoundTimer one:

> Tap Stop 10 seconds into round 1. Completion screen shows "GREAT JOB!" with celebration animation. The feature "works." But the user bailed — they don't feel celebrated, they feel patronized. That's not a spec violation and not a crash. It's a Question 3 violation — the feature made no sense in the moment the user was in.

### Step 7: Persona Journeys (was Step 8)
Four fitness personas, same narrative style as ParkTimer (emotional state + physical context + "the stress test"):

- **Riley — HIIT at home, 10-minute window.** Phone on the floor between sets. Needs one-tap Tabata start. Can't fumble with preset editing between rounds. Stress test: can Riley go from "open app" to "timer running" in under 3 seconds?
- **Marcus — boxer at the gym, Spotify playing through a bluetooth speaker.** Audio over music is CRITICAL. Needs clear round numbers at a glance through sweat and gloves. Stress test: can Marcus glance at the phone for 1 second and know the current round and phase?
- **Priya — track runner, outside in bright sun.** Screen visibility, big touch targets, screen must stay awake, one-handed operation. Stress test: can Priya pause with sweaty thumbs without accidentally hitting Stop?
- **Dakota — first-time downloader, no fitness app experience.** Do "interval," "round," "EMOM," "AMRAP," "Tabata" mean anything? Can Dakota figure out presets in 5 seconds without a tutorial? Stress test: does any screen require explanation? If yes, that's a UX bug.

### Step 8: What the Simulator CANNOT Test (was Step 9)

| Feature | Simulator CAN verify | Requires real device |
|---|---|---|
| Haptics | HapticManager call sites execute (no crash) | Actual vibration felt |
| Audio over music | AVAudioPlayer loads, `.play()` called, `.ambient + .mixWithOthers` session configured | Plays over Spotify in foreground AND when phone locked |
| Live Activity | ActivityKit code compiles, start/update/end logged | Renders on Lock Screen + Dynamic Island |
| Background timer accuracy | Wall-clock math via logs | Phone locked in pocket 10 min → unlock → time correct |
| Screen stays awake | `isIdleTimerDisabled = true` is set | Screen actually doesn't dim during a timer |
| Countdown beeps | `AudioManager.play()` called | Audible from pocket, audible over music |
| Phone call interruption | — | Audio session interruption + resume |

Same "How to verify what you can't see" sub-section (logs, code path inspection, device-only checklist), adapted to RoundTimer's log prefixes (`[AudioManager]`, `[HapticManager]`, `[LiveActivity]`, `[TimerEngine]`).

## `docs/qa-findings.md` stub

Empty stub matching ParkTimer's format. Header + one example entry commented out as a template so future QA runs know exactly how to append. Initial content:

```markdown
# RoundTimer QA Findings

Running log of bugs, issues, and polish items found during QA sessions.
Append new findings at the top. Format matches docs/qa-prompt.md reporting section.

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

_No findings yet._
```

## Length target

Roughly 200–220 lines for `qa-prompt.md` (down from ParkTimer's 253) — leaked-feature removal offsets the richer state-transition step and wall-clock emphasis.

## Out of scope

- The autonomous dev loop (`loop-prompt.md`) — not copied per user decision (Option A in brainstorming).
- Migrating past QA findings from ParkTimer — unrelated project.
- Changes to `CLAUDE.md` or other existing docs.

## Acceptance

- `docs/qa-prompt.md` exists, references RoundTimer's bundle ID (`com.roundtimer.app`), personas, screens, and state machine.
- `docs/qa-findings.md` exists as an empty stub with header and template.
- No mention of Pro/Free, Find Car, parking, vehicle icons, or GPS.
- Step count is 8 (not 9).
- Both files committed to git.
