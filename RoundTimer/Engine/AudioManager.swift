import AVFoundation

@MainActor
class AudioManager {
    static let shared = AudioManager()

    private var players: [SoundEvent: AVAudioPlayer] = [:]
    private var lastCountdownTick: Int = 0

    private let soundFileNames: [SoundEvent: String] = [
        .workStart: "work_start",
        .restStart: "rest_start",
        .warmupStart: "warmup_start",
        .cooldownStart: "cooldown_start",
        .countdownBeep: "countdown_beep",
        .halfTime: "half_time",
        .timerComplete: "timer_complete"
    ]

    func configure() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        preloadSounds()
    }

    private func preloadSounds() {
        for (event, name) in soundFileNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
                print("Sound file not found: \(name).wav")
                continue
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.volume = event == .countdownBeep || event == .halfTime ? 0.5 : 0.8
                players[event] = player
            } catch {
                print("Failed to load sound \(event): \(error)")
            }
        }
    }

    func play(_ event: SoundEvent) {
        guard SettingsManager.shared.isSoundEnabled else { return }
        if let player = players[event] {
            player.currentTime = 0
            player.play()
        }
    }

    func playCountdownIfNeeded(secondsLeft: Int) {
        guard secondsLeft != lastCountdownTick else { return }
        guard SettingsManager.shared.countdownBeepsEnabled else { return }
        // Bail out BEFORE marking the tick played. Otherwise, if Sound Effects
        // were toggled off mid-countdown we'd record the tick as "handled" and
        // then skip it permanently when sound is re-enabled at the same second.
        guard SettingsManager.shared.isSoundEnabled else { return }
        lastCountdownTick = secondsLeft
        play(.countdownBeep)
    }

    func resetCountdown() {
        lastCountdownTick = 0
    }
}
