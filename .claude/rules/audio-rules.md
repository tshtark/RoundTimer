---
paths:
  - "RoundTimer/Engine/AudioManager*"
  - "RoundTimer/Resources/Sounds/**"
---

# Audio Rules (CRITICAL — #1 product differentiator)

Timer sounds MUST play over Spotify/Apple Music. This is the #1 competitor complaint and our core selling point.

1. **AVAudioSession** — `.ambient` category with `.mixWithOthers` option. Set in `configure()`, called from `ContentView.onAppear`.

2. **AVAudioPlayer only** — NEVER use `AudioServicesPlaySystemSound`. It bypasses the audio session entirely and will interrupt user's music. This was a bug that survived 47 development runs before being caught.

3. **Bundled .wav files** — Sound files live in `Resources/Sounds/`. System sound paths (`/System/Library/Audio/UISounds/`) do NOT exist on real iOS devices. Always use `Bundle.main.url(forResource:withExtension:)`.

4. **Preload sounds** — Call `preloadSounds()` during `configure()` to avoid first-play latency. Each sound gets its own `AVAudioPlayer` instance stored in the `players` dictionary.

5. **Volume levels** — Countdown beeps and half-time at 0.5, phase transitions and completion at 0.8. Low enough to not overpower music, loud enough to hear during exercise.

6. **Current sounds are generated tones** — V1 ships with programmatically generated .wav files. V1.1 should replace these with professionally recorded sounds (boxing bell, whistle, gym beeps).
