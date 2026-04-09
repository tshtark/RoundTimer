import SwiftUI

struct ContentView: View {
    var body: some View {
        PresetListView()
            .onAppear {
                AudioManager.shared.configure()
                HapticManager.shared.prepare()
                TimerActivityManager.shared.cleanupStaleActivities()
            }
    }
}

#Preview {
    ContentView()
}
