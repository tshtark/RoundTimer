# RoundTimer — Ship Summary

## App Store Listing

| Field | Value |
|-------|-------|
| **App Name** | RoundTimer: Interval Timer |
| **App Store ID** | 6761851794 |
| **Bundle ID** | com.roundtimer.app |
| **Widget Bundle ID** | com.roundtimer.app.widget |
| **Team ID** | JVZFL2WCHV |
| **SKU** | roundtimer001 |
| **Price** | $4.99 USD |
| **Category** | Health & Fitness |
| **App Store URL** | `https://apps.apple.com/app/id6761851794` (live after approval) |
| **Privacy Policy** | `https://tshtark.github.io/RoundTimer/privacy-policy.html` |
| **Support URL** | `https://tshtark.github.io/RoundTimer/` |
| **Support Email** | shtark285@gmail.com |

## Submission Details

- **Version:** 1.0.0 (build 1)
- **Submitted:** April 8, 2026 at 9:50 PM
- **Submission ID:** 514a680e-58da-449f-9cdd-8cd1796d2034
- **Status:** Waiting for Review
- **Expected review:** 24-48 hours

## Developer Account

- **Account:** Tal Shtark (shtark285@gmail.com)
- **Program:** Apple Developer Program ($99/year)
- **Expiration:** April 9, 2027
- **Portal:** https://developer.apple.com/account
- **App Store Connect:** https://appstoreconnect.apple.com/apps/6761851794

## What Was Built (V1.0)

### Core Features (PRD Phase 1-2)
- Timer engine with work/rest/rounds/warmup/cooldown
- 5 built-in presets (Tabata, Boxing, EMOM, AMRAP, Custom)
- Custom preset builder (create, edit, duplicate, delete)
- Audio over music (.ambient + .mixWithOthers via AVAudioPlayer)
- Live Activity on lock screen (ActivityKit)
- Pause/Resume/Skip/Stop controls
- 3-2-1 countdown beeps
- JSON file persistence (presets + workout history)

### UI/UX (PRD Phase 3)
- Rich color palette (emerald, steel blue, amber, deep orange)
- Dark mode support (verified on all screens)
- Smooth phase transition animations
- VoiceOver labels + Dynamic Type support
- Confirmation dialog before stopping
- Large bold typography hierarchy

### Beyond PRD (Phase 4 — 22 features)
- Circular progress ring with radial gradient background
- Next phase preview ("Next: REST 0:10", "Final interval!")
- Half-time alert (visual badge + sound at 50%)
- Paused overlay badge
- Animated completion celebration with motivational messages
- Workout completion stats (duration, rounds, intervals)
- Share workout / Share preset via system share sheet
- Quick Start (instant timer without saving)
- Workout history with JSON persistence
- Weekly activity summary (workouts, total time, day streak)
- Settings (sound, haptics, screen awake, countdown beeps)
- Rate & Feedback (App Store review prompt + email)
- Haptic feedback on all control buttons
- Total remaining workout time display
- Preset color accent strips
- Grammar fix ("1 round" not "1 rounds")
- Elapsed time display
- Smart review prompt (after 3rd, 10th, 25th workout)

## Real Device Test Results (iPhone 13 Pro Max)

| Test | Result |
|------|--------|
| Audio over Spotify | PASS |
| Haptic feedback | PASS |
| Live Activity (lock screen) | PASS (fixed — needed INFOPLIST_KEY_ prefix) |
| Screen stays awake | PASS |
| Background/foreground | PASS (wall-clock recalculation works) |
| AirPods audio | PASS |

## Known Limitations

- Dynamic Island not available on iPhone 13 (requires 14 Pro+)
- Live Activity banner while in other apps only works on Dynamic Island devices
- App icon has rounded corners baked in by iOS (we provide square 1024x1024)
- Watch app target exists but is empty (deferred to V1.1)
- Universal iPhone + iPad binary via SwiftUI adaptive layout — no iPad-specific layout polish (e.g. multi-column preset grid) yet, but the app uses the iPad's full resolution and supports all 4 orientations on iPad

## Sound Files

7 bundled .wav files in `RoundTimer/Resources/Sounds/`:
- `work_start.wav` — rising double tone (880Hz→1760Hz)
- `rest_start.wav` — descending double tone (660Hz→440Hz)
- `warmup_start.wav` — gentle 523Hz tone
- `cooldown_start.wav` — medium 392Hz tone
- `countdown_beep.wav` — short 1000Hz tick
- `half_time.wav` — subtle double 600Hz tap
- `timer_complete.wav` — 3-note ascending fanfare (C-E-G)

These are programmatically generated tones. For V1.1, source real boxing bell, whistle, and gym sounds from royalty-free libraries.

## Development Stats

- **49 automated development runs** + multiple manual sessions
- **50+ commits** on main branch
- **~30 Swift files** across 3 targets
- **Zero prior Swift experience** — all code written by Claude
