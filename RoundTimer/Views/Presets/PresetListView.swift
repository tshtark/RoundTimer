import SwiftUI
import StoreKit

struct PresetListView: View {
    @Environment(\.requestReview) private var requestReview
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(weeklyRecords.count) \(weeklyRecords.count == 1 ? "workout" : "workouts") this week")

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
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Total time this week, \(accessibleWeeklyDuration(weeklyTotalDuration))")

                            Divider()

                            VStack(spacing: 4) {
                                Text("\(currentStreak)")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(currentStreak > 0 ? .orange : .secondary)
                                Text("Day Streak")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(currentStreak) day streak")
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("This Week")
                    }
                }

                ForEach(sortedPresets) { preset in
                    Button {
                        startPreset(preset)
                    } label: {
                        PresetRow(preset: preset, isLastUsed: preset.lastUsedAt != nil && preset.id == sortedPresets.first?.id)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(presetAccessibilityLabel(for: preset))
                    .accessibilityHint("Starts this workout")
                    .accessibilityAddTraits(.isButton)
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
                        ShareLink(item: shareText(for: preset)) {
                            Label("Share", systemImage: "square.and.arrow.up")
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
            // At the largest accessibility text sizes the large title's
            // ascender pokes into the system status bar. Force the inline
            // (compact) title at those sizes so it never overlaps the clock.
            .navigationBarTitleDisplayMode(dynamicTypeSize.isAccessibilitySize ? .inline : .automatic)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityIdentifier("settingsButton")

                    Button {
                        showingHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .accessibilityLabel("Workout History")
                    .accessibilityIdentifier("historyButton")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingBuilder = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Custom Preset")
                    .accessibilityIdentifier("addPresetButton")
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
                        currentRound: engine.currentRound,
                        intervalName: engine.intervalName
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
        // Round to the nearest minute instead of flooring so 2m 32s shows as "3m"
        // (the prior floor produced "2m" — undercounting effort).
        let totalSeconds = max(0, Int(duration))
        let roundedMinutes = Int((Double(totalSeconds) / 60.0).rounded())
        let hours = roundedMinutes / 60
        let minutes = roundedMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(roundedMinutes)m"
    }

    private func accessibleWeeklyDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        var parts: [String] = []
        if hours > 0 {
            parts.append("\(hours) \(hours == 1 ? "hour" : "hours")")
        }
        if minutes > 0 || hours == 0 {
            parts.append("\(minutes) \(minutes == 1 ? "minute" : "minutes")")
        }
        return parts.joined(separator: " ")
    }

    private func presetAccessibilityLabel(for preset: TimerPreset) -> String {
        var parts: [String] = [preset.name]
        if preset.isBuiltIn { parts.append("built-in preset") }
        if preset.lastUsedAt != nil && preset.id == sortedPresets.first?.id {
            parts.append("recently used")
        }
        parts.append("\(preset.rounds) \(preset.rounds == 1 ? "round" : "rounds")")
        parts.append(preset.formattedDuration)
        return parts.joined(separator: ", ")
    }

    private func startPreset(_ preset: TimerPreset) {
        selectedPreset = preset
        store.markUsed(preset)
        configureEngineCallbacks()
        engine.start(preset: preset)
        TimerActivityManager.shared.start(
            presetName: preset.name,
            totalRounds: preset.rounds,
            phase: engine.currentPhase,
            intervalEndDate: engine.phaseEndDate,
            currentRound: engine.currentRound,
            intervalName: engine.intervalName
        )
        showingTimer = true
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
        engine.onPauseStateChange = { [engine] isPaused in
            TimerActivityManager.shared.update(
                phase: engine.currentPhase,
                currentRound: engine.currentRound,
                intervalEndDate: engine.phaseEndDate,
                intervalName: engine.intervalName,
                isPaused: isPaused
            )
        }
        engine.onCountdownTick = { seconds in
            AudioManager.shared.playCountdownIfNeeded(secondsLeft: seconds)
            HapticManager.shared.countdownTickIfEnabled()
        }
        engine.onHalfTime = {
            AudioManager.shared.play(.halfTime)
            HapticManager.shared.halfTimeTick()
        }
        engine.onComplete = { [engine, historyStore, requestReview] in
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

            // Prompt for rating after 3rd, 10th, and 25th workout
            let count = historyStore.records.count
            if count == 3 || count == 10 || count == 25 {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1))
                    requestReview()
                }
            }
        }
    }

    private func shareText(for preset: TimerPreset) -> String {
        var lines: [String] = []
        lines.append("\(preset.name)")
        lines.append("\(preset.rounds) \(preset.rounds == 1 ? "round" : "rounds") · \(preset.formattedDuration)")
        lines.append("")
        for (i, interval) in preset.intervals.enumerated() {
            let duration = Int(interval.duration)
            let m = duration / 60
            let s = duration % 60
            let timeStr = m > 0 ? "\(m):\(String(format: "%02d", s))" : "0:\(String(format: "%02d", s))"
            let name = interval.name.map { " — \($0)" } ?? ""
            lines.append("\(i + 1). \(interval.phase.displayName) \(timeStr)\(name)")
        }
        if let warmup = preset.warmup, warmup > 0 {
            lines.append("Warmup: \(Int(warmup))s")
        }
        if let cooldown = preset.cooldown, cooldown > 0 {
            lines.append("Cooldown: \(Int(cooldown))s")
        }
        lines.append("")
        lines.append("Shared from RoundTimer")
        return lines.joined(separator: "\n")
    }
}

struct PresetRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    if preset.isBuiltIn {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                            .accessibilityHidden(true)
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

                metadataLayout

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
                .accessibilityHidden(true)
        }
        .padding(.vertical, 6)
    }

    /// Stack metadata vertically at accessibility text sizes so labels stay
    /// adjacent to their numbers. The horizontal layout fragments at the
    /// largest Dynamic Type tiers (e.g. "rounds m 0s" wraps as one phrase).
    @ViewBuilder
    private var metadataLayout: some View {
        let roundsLabel = "\(preset.rounds) \(preset.rounds == 1 ? "round" : "rounds")"
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                Label(roundsLabel, systemImage: "repeat")
                Label(preset.formattedDuration, systemImage: "clock")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        } else {
            HStack(spacing: 12) {
                Label(roundsLabel, systemImage: "repeat")
                Label(preset.formattedDuration, systemImage: "clock")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
    }
}

#Preview {
    PresetListView()
}
