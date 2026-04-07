import SwiftUI

// MARK: - ViewModel

@MainActor
@Observable
final class PresetBuilderViewModel {
    var name: String
    var intervals: [TimerInterval]
    var rounds: Int
    var hasWarmup: Bool
    var warmupDuration: TimeInterval
    var hasCooldown: Bool
    var cooldownDuration: TimeInterval

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !intervals.isEmpty
    }

    init() {
        name = ""
        intervals = [
            TimerInterval(phase: .work, duration: 30),
            TimerInterval(phase: .rest, duration: 15),
        ]
        rounds = 3
        hasWarmup = false
        warmupDuration = 10
        hasCooldown = false
        cooldownDuration = 10
    }

    func addInterval(phase: TimerPhase) {
        let duration: TimeInterval = phase == .work ? 30 : 15
        intervals.append(TimerInterval(phase: phase, duration: duration))
    }

    func removeIntervals(at offsets: IndexSet) {
        intervals.remove(atOffsets: offsets)
    }

    func moveIntervals(from source: IndexSet, to destination: Int) {
        intervals.move(fromOffsets: source, toOffset: destination)
    }

    func save(to store: PresetStore) {
        let preset = TimerPreset(
            name: name.trimmingCharacters(in: .whitespaces),
            intervals: intervals,
            rounds: rounds,
            warmup: hasWarmup ? warmupDuration : nil,
            cooldown: hasCooldown ? cooldownDuration : nil
        )
        store.add(preset)
    }
}

// MARK: - Main View

struct PresetBuilderView: View {
    let store: PresetStore
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PresetBuilderViewModel()

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                intervalsSection
                roundsSection
                warmupSection
                cooldownSection
            }
            .navigationTitle("New Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save(to: store)
                        dismiss()
                    }
                    .disabled(!viewModel.isValid)
                }
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section("Preset Name") {
            TextField("e.g. My Tabata", text: $viewModel.name)
                .autocorrectionDisabled()
        }
    }

    private var intervalsSection: some View {
        Section {
            ForEach($viewModel.intervals) { $interval in
                IntervalEditorRow(interval: $interval)
            }
            .onDelete { viewModel.removeIntervals(at: $0) }
            .onMove { viewModel.moveIntervals(from: $0, to: $1) }

            HStack(spacing: 12) {
                Button {
                    viewModel.addInterval(phase: .work)
                } label: {
                    Label("Work", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.green)

                Button {
                    viewModel.addInterval(phase: .rest)
                } label: {
                    Label("Rest", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            }
            .padding(.vertical, 4)
        } header: {
            HStack {
                Text("Intervals")
                Spacer()
                EditButton()
                    .font(.caption)
                    .textCase(nil)
            }
        } footer: {
            if viewModel.intervals.isEmpty {
                Text("Add at least one interval to save.")
                    .foregroundStyle(.red)
            } else {
                Text("Drag to reorder. Swipe left to delete.")
            }
        }
    }

    private var roundsSection: some View {
        Section("Rounds") {
            Stepper(value: $viewModel.rounds, in: 1...99) {
                HStack {
                    Text("Rounds")
                    Spacer()
                    Text("\(viewModel.rounds)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
    }

    private var warmupSection: some View {
        Section {
            Toggle("Include Warmup", isOn: $viewModel.hasWarmup.animation())
            if viewModel.hasWarmup {
                DurationPicker(label: "Duration", duration: $viewModel.warmupDuration)
            }
        } header: {
            Text("Warmup")
        } footer: {
            Text("Countdown before the first work interval.")
        }
    }

    private var cooldownSection: some View {
        Section {
            Toggle("Include Cooldown", isOn: $viewModel.hasCooldown.animation())
            if viewModel.hasCooldown {
                DurationPicker(label: "Duration", duration: $viewModel.cooldownDuration)
            }
        } header: {
            Text("Cooldown")
        } footer: {
            Text("Countdown after the final round.")
        }
    }
}

// MARK: - Interval Editor Row

private struct IntervalEditorRow: View {
    @Binding var interval: TimerInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Phase", selection: $interval.phase) {
                Text("Work").tag(TimerPhase.work)
                Text("Rest").tag(TimerPhase.rest)
            }
            .pickerStyle(.segmented)

            DurationPicker(label: "Duration", duration: $interval.duration)

            TextField("Label (optional)", text: Binding(
                get: { interval.name ?? "" },
                set: { interval.name = $0.isEmpty ? nil : $0 }
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PresetBuilderView(store: PresetStore())
}
