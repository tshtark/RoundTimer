import UIKit

@MainActor
class HapticManager {
    static let shared = HapticManager()

    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let notification = UINotificationFeedbackGenerator()

    func prepare() {
        heavy.prepare()
        medium.prepare()
        light.prepare()
        notification.prepare()
    }

    func phaseTransition(_ phase: TimerPhase) {
        guard SettingsManager.shared.isHapticsEnabled else { return }
        switch phase {
        case .work:
            heavy.impactOccurred()
        case .rest:
            medium.impactOccurred()
        case .warmup, .cooldown:
            light.impactOccurred()
        }
    }

    func countdownTick() {
        guard SettingsManager.shared.isHapticsEnabled else { return }
        light.impactOccurred()
    }

    /// 3-2-1 countdown haptic: gated by BOTH the global haptic toggle and the
    /// "Countdown Beeps (3-2-1)" toggle so users who turn off the countdown
    /// stop feeling the tick too.
    func countdownTickIfEnabled() {
        guard SettingsManager.shared.isHapticsEnabled,
              SettingsManager.shared.countdownBeepsEnabled else { return }
        light.impactOccurred()
    }

    /// Distinct from countdownTick so the half-time alert is distinguishable by
    /// feel from the 3-2-1 countdown.
    func halfTimeTick() {
        guard SettingsManager.shared.isHapticsEnabled else { return }
        medium.impactOccurred()
    }

    func timerComplete() {
        guard SettingsManager.shared.isHapticsEnabled else { return }
        notification.notificationOccurred(.success)
    }
}
