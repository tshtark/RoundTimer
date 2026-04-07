import SwiftUI

struct ContentView: View {
    var body: some View {
        PresetListView()
            .onAppear {
                AudioManager.shared.configure()
                HapticManager.shared.prepare()
            }
    }
}

#Preview {
    ContentView()
}
