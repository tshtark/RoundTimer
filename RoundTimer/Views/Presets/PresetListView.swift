import SwiftUI

struct PresetListView: View {
    @State private var store = PresetStore()
    @State private var engine = TimerEngine()
    @State private var showingTimer = false
    @State private var selectedPreset: TimerPreset?
    @State private var showingBuilder = false
    @State private var editingPreset: TimerPreset?
    @State private var duplicatingPreset: TimerPreset?

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.presets) { preset in
                    PresetRow(preset: preset)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPreset = preset
                            store.markUsed(preset)
                            configureEngineCallbacks()
                            engine.start(preset: preset)
                            showingTimer = true
                        }
                        .contextMenu {
                            if !preset.isBuiltIn {
                                Button {
                                    editingPreset = preset
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                            }
                            Button {
                                duplicatingPreset = preset
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                        }
                        .deleteDisabled(preset.isBuiltIn)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let preset = store.presets[index]
                        store.delete(preset)
                    }
                }
            }
            .navigationTitle("RoundTimer")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingBuilder = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingBuilder) {
                PresetBuilderView(store: store)
            }
            .sheet(item: $editingPreset) { preset in
                PresetBuilderView(store: store, editing: preset)
            }
            .sheet(item: $duplicatingPreset) { preset in
                PresetBuilderView(store: store, duplicating: preset)
            }
            .fullScreenCover(isPresented: $showingTimer) {
                ActiveTimerView(engine: engine) {
                    engine.stop()
                    showingTimer = false
                }
            }
        }
    }

    private func configureEngineCallbacks() {
        engine.onPhaseChange = { phase in
            AudioManager.shared.resetCountdown()
            AudioManager.shared.play(phase.soundEvent)
            HapticManager.shared.phaseTransition(phase)
        }
        engine.onCountdownTick = { seconds in
            AudioManager.shared.playCountdownIfNeeded(secondsLeft: seconds)
            HapticManager.shared.countdownTick()
        }
        engine.onComplete = {
            AudioManager.shared.play(.timerComplete)
            HapticManager.shared.timerComplete()
        }
    }
}

struct PresetRow: View {
    let preset: TimerPreset

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(preset.name)
                        .font(.headline)
                    if preset.isBuiltIn {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }

                HStack(spacing: 12) {
                    Label("\(preset.rounds) rounds", systemImage: "repeat")
                    Label(preset.formattedDuration, systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    ForEach(preset.intervals) { interval in
                        Text(interval.phase.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(interval.phase.color.opacity(0.2))
                            .foregroundStyle(interval.phase.color)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Image(systemName: "play.circle.fill")
                .font(.title)
                .foregroundStyle(.green)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PresetListView()
}
