import AVFoundation

@MainActor
class AudioManager {
    static let shared = AudioManager()

    private var players: [SoundEvent: AVAudioPlayer] = [:]
    private var lastCountdownTick: Int = 0

    private let soundFiles: [SoundEvent: String] = [
        .workStart: "/System/Library/Audio/UISounds/connect_power.caf",
        .restStart: "/System/Library/Audio/UISounds/SIMToolkitGeneralBeep.caf",
        .warmupStart: "/System/Library/Audio/UISounds/acknowledgment_sent.caf",
        .cooldownStart: "/System/Library/Audio/UISounds/acknowledgment_received.caf",
        .countdownBeep: "/System/Library/Audio/UISounds/Tock.caf",
        .halfTime: "/System/Library/Audio/UISounds/key_press_click.caf",
        .timerComplete: "/System/Library/Audio/UISounds/payment_success.caf"
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
        for (event, path) in soundFiles {
            let url = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: path) else { continue }
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
        lastCountdownTick = secondsLeft
        play(.countdownBeep)
    }

    func resetCountdown() {
        lastCountdownTick = 0
    }
}
