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

    func timerComplete() {
        guard SettingsManager.shared.isHapticsEnabled else { return }
        notification.notificationOccurred(.success)
    }
}
