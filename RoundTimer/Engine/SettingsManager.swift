import Foundation

@MainActor
@Observable
final class SettingsManager {
    static let shared = SettingsManager()

    private static let keySound = "isSoundEnabled"
    private static let keyHaptics = "isHapticsEnabled"
    private static let keyScreenAwake = "keepScreenAwake"
    private static let keyCountdown = "countdownBeepsEnabled"

    var isSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(isSoundEnabled, forKey: Self.keySound) }
    }

    var isHapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(isHapticsEnabled, forKey: Self.keyHaptics) }
    }

    var keepScreenAwake: Bool {
        didSet { UserDefaults.standard.set(keepScreenAwake, forKey: Self.keyScreenAwake) }
    }

    var countdownBeepsEnabled: Bool {
        didSet { UserDefaults.standard.set(countdownBeepsEnabled, forKey: Self.keyCountdown) }
    }

    private init() {
        let defaults = UserDefaults.standard
        self.isSoundEnabled = Self.readBool(defaults, key: Self.keySound, defaultValue: true)
        self.isHapticsEnabled = Self.readBool(defaults, key: Self.keyHaptics, defaultValue: true)
        self.keepScreenAwake = Self.readBool(defaults, key: Self.keyScreenAwake, defaultValue: true)
        self.countdownBeepsEnabled = Self.readBool(defaults, key: Self.keyCountdown, defaultValue: true)
    }

    private static func readBool(_ defaults: UserDefaults, key: String, defaultValue: Bool) -> Bool {
        defaults.object(forKey: key) != nil ? defaults.bool(forKey: key) : defaultValue
    }
}
