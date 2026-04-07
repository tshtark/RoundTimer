import SwiftUI

@main
struct RoundTimerApp: App {
    init() {
        AudioManager.shared.configure()
        HapticManager.shared.prepare()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
