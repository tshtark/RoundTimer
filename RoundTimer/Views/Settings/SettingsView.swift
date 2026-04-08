import SwiftUI
import StoreKit

struct SettingsView: View {
    @Bindable var settings: SettingsManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

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

                Section("Feedback") {
                    Button {
                        requestReview()
                    } label: {
                        Label("Rate RoundTimer", systemImage: "star.fill")
                    }

                    Button {
                        sendFeedbackEmail()
                    } label: {
                        Label("Send Feedback", systemImage: "envelope")
                    }
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

    private func sendFeedbackEmail() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let device = UIDevice.current.model
        let ios = UIDevice.current.systemVersion
        let subject = "RoundTimer Feedback (v\(version))"
        let body = "\n\n\n---\nApp: RoundTimer v\(version) (\(build))\nDevice: \(device)\niOS: \(ios)"

        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:shtark285@gmail.com?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SettingsView(settings: SettingsManager.shared)
}
