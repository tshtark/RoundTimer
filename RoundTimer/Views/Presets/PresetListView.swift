import SwiftUI

struct PresetListView: View {
    @State private var store = PresetStore()
    @State private var engine = TimerEngine()
    @State private var showingTimer = false
    @State private var selectedPreset: TimerPreset?
    @State private var showingBuilder = false
    @State private var editingPreset: TimerPreset?
    @State private var duplicatingPreset: TimerPreset?
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedPresets) { preset in
                    PresetRow(preset: preset, isLastUsed: preset.lastUsedAt != nil && preset.id == sortedPresets.first?.id)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPreset = preset
                            store.markUsed(preset)
                            configureEngineCallbacks()
                            engine.start(preset: preset)
                            TimerActivityManager.shared.start(
                                presetName: preset.name,
                                totalRounds: preset.rounds,
                                phase: engine.currentPhase,
                                intervalEndDate: engine.phaseEndDate,
                                currentRound: engine.currentRound
                            )
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
                    let sorted = sortedPresets
                    for index in indexSet {
                        let preset = sorted[index]
                        store.delete(preset)
                    }
                }

                if !store.presets.contains(where: { !$0.isBuiltIn }) {
                    Section {
                        VStack(spacing: 8) {
                            Image(systemName: "timer")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("Create Your Own Timer")
                                .font(.headline)
                            Text("Tap + to build a custom interval timer for your workout.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("RoundTimer")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingBuilder = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(settings: SettingsManager.shared)
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
                    TimerActivityManager.shared.end()
                    showingTimer = false
                }
            }
        }
    }

    private var sortedPresets: [TimerPreset] {
        store.presets.sorted { a, b in
            let aDate = a.lastUsedAt ?? .distantPast
            let bDate = b.lastUsedAt ?? .distantPast
            return aDate > bDate
        }
    }

    private func configureEngineCallbacks() {
        engine.onPhaseChange = { [engine] phase in
            AudioManager.shared.resetCountdown()
            AudioManager.shared.play(phase.soundEvent)
            HapticManager.shared.phaseTransition(phase)
            TimerActivityManager.shared.update(
                phase: phase,
                currentRound: engine.currentRound,
                intervalEndDate: engine.phaseEndDate,
                intervalName: engine.intervalName,
                isPaused: false
            )
        }
        engine.onCountdownTick = { seconds in
            AudioManager.shared.playCountdownIfNeeded(secondsLeft: seconds)
            HapticManager.shared.countdownTick()
        }
        engine.onComplete = {
            AudioManager.shared.play(.timerComplete)
            HapticManager.shared.timerComplete()
            TimerActivityManager.shared.end()
        }
    }
}

struct PresetRow: View {
    let preset: TimerPreset
    var isLastUsed: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(preset.name)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                    if preset.isBuiltIn {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                    if isLastUsed {
                        Text("Recent")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.purple.opacity(0.15))
                            .foregroundStyle(.purple)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 12) {
                    Label("\(preset.rounds) rounds", systemImage: "repeat")
                    Label(preset.formattedDuration, systemImage: "clock")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                HStack(spacing: 5) {
                    ForEach(preset.intervals) { interval in
                        Text(interval.phase.displayName)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(interval.phase.color.opacity(0.15))
                            .foregroundStyle(interval.phase.color)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Image(systemName: "play.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(TimerPhase.work.color)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    PresetListView()
}
