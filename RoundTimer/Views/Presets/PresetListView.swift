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
    @State private var showingQuickTimer = false
    @State private var showingHistory = false
    @State private var historyStore = WorkoutHistoryStore()

    var body: some View {
        NavigationStack {
            List {
                if !weeklyRecords.isEmpty {
                    Section {
                        HStack(spacing: 16) {
                            VStack(spacing: 4) {
                                Text("\(weeklyRecords.count)")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(TimerPhase.work.color)
                                Text(weeklyRecords.count == 1 ? "Workout" : "Workouts")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)

                            Divider()

                            VStack(spacing: 4) {
                                Text(formatWeeklyDuration(weeklyTotalDuration))
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(TimerPhase.work.color)
                                Text("Total Time")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)

                            Divider()

                            VStack(spacing: 4) {
                                Text("\(currentStreak)")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(currentStreak > 0 ? .orange : .secondary)
                                Text(currentStreak == 1 ? "Day Streak" : "Day Streak")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("This Week")
                    }
                }

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

                Section {
                    Button {
                        showingQuickTimer = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "bolt.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Quick Start")
                                    .font(.system(.title3, design: .rounded, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text("Set work, rest & rounds — start instantly")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
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
                    HStack(spacing: 16) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        Button {
                            showingHistory = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                        }
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
            .sheet(isPresented: $showingHistory) {
                HistoryView(store: historyStore)
            }
            .sheet(isPresented: $showingQuickTimer) {
                QuickTimerView { preset in
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

    private var weeklyRecords: [WorkoutRecord] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return historyStore.records.filter { $0.date >= startOfWeek }
    }

    private var weeklyTotalDuration: TimeInterval {
        weeklyRecords.reduce(0) { $0 + $1.totalDuration }
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while true {
            let hasWorkout = historyStore.records.contains { record in
                calendar.isDate(record.date, inSameDayAs: checkDate)
            }
            if hasWorkout {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previousDay
            } else {
                break
            }
        }
        return streak
    }

    private func formatWeeklyDuration(_ duration: TimeInterval) -> String {
        let total = max(0, Int(duration))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
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
        engine.onHalfTime = {
            AudioManager.shared.play(.halfTime)
            HapticManager.shared.countdownTick()
        }
        engine.onComplete = { [engine, historyStore] in
            AudioManager.shared.play(.timerComplete)
            HapticManager.shared.timerComplete()
            TimerActivityManager.shared.end()
            let record = WorkoutRecord(
                presetName: engine.presetName,
                totalDuration: engine.finalElapsedTime,
                roundsCompleted: engine.currentRound,
                intervalsCompleted: engine.totalRounds * engine.totalIntervals
            )
            historyStore.add(record)
        }
    }
}

struct PresetRow: View {
    let preset: TimerPreset
    var isLastUsed: Bool = false

    private var primaryColor: Color {
        preset.intervals.first?.phase.color ?? TimerPhase.work.color
    }

    var body: some View {
        HStack(spacing: 12) {
            // Color accent strip
            RoundedRectangle(cornerRadius: 2)
                .fill(primaryColor)
                .frame(width: 4, height: 56)

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
                    Label("\(preset.rounds) \(preset.rounds == 1 ? "round" : "rounds")", systemImage: "repeat")
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
