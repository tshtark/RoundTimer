import AVFoundation

@MainActor
class AudioManager {
    static let shared = AudioManager()

    private var players: [SoundEvent: AVAudioPlayer] = [:]
    private var lastCountdownTick: Int = 0

    func configure() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    func play(_ event: SoundEvent) {
        guard SettingsManager.shared.isSoundEnabled else { return }
        let soundID: UInt32
        switch event {
        case .workStart:
            soundID = 1304  // strong alert
        case .restStart:
            soundID = 1057  // soft tone
        case .warmupStart:
            soundID = 1110  // begin tone
        case .cooldownStart:
            soundID = 1114  // alert tone
        case .countdownBeep:
            soundID = 1103  // tock
        case .halfTime:
            soundID = 1113  // subtle double-tap
        case .timerComplete:
            soundID = 1025  // fanfare-ish
        }
        AudioServicesPlaySystemSound(soundID)
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
