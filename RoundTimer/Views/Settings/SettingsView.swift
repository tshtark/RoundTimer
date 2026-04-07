import SwiftUI

struct SettingsView: View {
    @Bindable var settings: SettingsManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Sound & Haptics") {
                    Toggle("Sound Effects", isOn: $settings.isSoundEnabled)
                    Toggle("Haptic Feedback", isOn: $settings.isHapticsEnabled)
                }

                Section("Timer") {
                    Toggle("Keep Screen Awake", isOn: $settings.keepScreenAwake)
                    Toggle("Countdown Beeps (3-2-1)", isOn: $settings.countdownBeepsEnabled)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundStyle(.secondary)
                    }
                    Text("Made with \u{2764}\u{FE0F} for athletes")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(settings: SettingsManager.shared)
}
