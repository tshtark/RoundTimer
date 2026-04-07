import SwiftUI

struct QuickTimerView: View {
    var onStart: (TimerPreset) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var workDuration: TimeInterval = 30
    @State private var restDuration: TimeInterval = 15
    @State private var rounds: Int = 3

    var body: some View {
        NavigationStack {
            Form {
                Section("Work") {
                    DurationPicker(label: "Duration", duration: $workDuration)
                }

                Section("Rest") {
                    DurationPicker(label: "Duration", duration: $restDuration)
                }

                Section("Rounds") {
                    Stepper("\(rounds) \(rounds == 1 ? "round" : "rounds")", value: $rounds, in: 1...20)
                }

                Section {
                    let totalSeconds = Int((workDuration + restDuration) * Double(rounds))
                    let minutes = totalSeconds / 60
                    let seconds = totalSeconds % 60
                    HStack {
                        Text("Total Duration")
                        Spacer()
                        Text(minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button {
                        let preset = buildPreset()
                        dismiss()
                        onStart(preset)
                    } label: {
                        HStack {
                            Spacer()
                            Label("Start Timer", systemImage: "play.fill")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(workDuration <= 0)
                    .listRowBackground(workDuration > 0 ? Color.green : Color.gray.opacity(0.3))
                    .foregroundStyle(.white)
                }
            }
            .navigationTitle("Quick Start")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func buildPreset() -> TimerPreset {
        var intervals = [TimerInterval(phase: .work, duration: workDuration)]
        if restDuration > 0 {
            intervals.append(TimerInterval(phase: .rest, duration: restDuration))
        }
        return TimerPreset(
            name: "Quick Timer",
            intervals: intervals,
            rounds: rounds
        )
    }
}

#Preview {
    QuickTimerView { preset in
        print("Starting: \(preset.name)")
    }
}
