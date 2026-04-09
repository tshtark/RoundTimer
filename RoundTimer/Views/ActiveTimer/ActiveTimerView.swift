import SwiftUI

struct ActiveTimerView: View {
    @Bindable var engine: TimerEngine
    var onStop: () -> Void
    @State private var showStopConfirmation = false
    @State private var celebrationScale: CGFloat = 0.3
    @State private var celebrationOpacity: Double = 0

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    engine.currentPhase.color.opacity(0.4),
                    engine.currentPhase.color.opacity(0.15),
                    Color(.systemBackground).opacity(0.9)
                ],
                center: .center,
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: engine.currentPhase)

            VStack(spacing: 20) {
                Spacer()

                // Phase name
                Text(engine.currentPhase.displayName)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(engine.currentPhase.color)

                // Interval name
                if let name = engine.intervalName {
                    Text(name)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                // Half-time indicator
                if engine.isHalfTime {
                    Text("HALFWAY")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(engine.currentPhase.color.opacity(0.8))
                        .clipShape(Capsule())
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(duration: 0.3), value: engine.isHalfTime)
                }

                // Circular progress ring with countdown
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(engine.currentPhase.color.opacity(0.15), lineWidth: 12)
                    // Progress ring
                    Circle()
                        .trim(from: 0, to: engine.progress)
                        .stroke(
                            engine.currentPhase.color,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: engine.progress)
                    // Countdown text
                    Text(formatTime(engine.timeRemaining))
                        .font(.system(size: 72, weight: .bold, design: .monospaced))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(engine.timeRemaining <= 10 && engine.timeRemaining > 0 ? .red : .primary)
                        .accessibilityLabel("\(Int(ceil(engine.timeRemaining))) seconds remaining")
                        .contentTransition(.numericText())
                        .animation(.linear(duration: 0.1), value: Int(engine.timeRemaining))
                        .phaseAnimator([false, true], trigger: Int(ceil(engine.timeRemaining))) { content, phase in
                            content
                                .scaleEffect(engine.timeRemaining <= 10 && engine.timeRemaining > 0 && phase ? 1.08 : 1.0)
                        } animation: { _ in
                            .easeInOut(duration: 0.3)
                        }
                }
                .frame(width: 260, height: 260)
                .padding(.vertical, 8)

                // Round progress
                Text("Round \(engine.currentRound) / \(engine.totalRounds)")
                    .font(.title2)
                    .fontWeight(.medium)

                // Round dots
                if engine.totalRounds > 0 && engine.totalRounds <= 20 {
                    RoundDotsView(
                        current: engine.currentRound,
                        total: engine.totalRounds,
                        color: engine.currentPhase.color
                    )
                }

                // Next phase preview
                if let nextInfo = engine.nextPhaseDescription {
                    Text(nextInfo)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }

                Spacer()

                // Controls
                HStack(spacing: 40) {
                    // Pause / Resume
                    Button {
                        if engine.isPaused {
                            engine.resume()
                        } else {
                            engine.pause()
                        }
                    } label: {
                        Image(systemName: engine.isPaused ? "play.circle.fill" : "pause.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel(engine.isPaused ? "Resume" : "Pause")
                    .sensoryFeedback(.impact(flexibility: .soft), trigger: engine.isPaused)

                    // Skip — disabled on the final phase so users can't fake-complete a workout
                    Button {
                        engine.skip()
                    } label: {
                        Image(systemName: "forward.end.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(engine.isOnFinalPhase ? Color.primary.opacity(0.3) : .primary)
                    }
                    .disabled(engine.isOnFinalPhase)
                    .accessibilityLabel("Skip to next interval")
                    .accessibilityHint(engine.isOnFinalPhase ? "Disabled on the final interval" : "")
                    .sensoryFeedback(.impact(flexibility: .rigid), trigger: engine.currentIntervalIndex)

                    // Stop
                    Button {
                        showStopConfirmation = true
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red)
                    }
                    .accessibilityLabel("Stop timer")
                    .sensoryFeedback(.warning, trigger: showStopConfirmation)
                }
                .padding(.bottom, 20)
                .alert("Stop Timer?", isPresented: $showStopConfirmation) {
                    Button("Stop", role: .destructive) {
                        onStop()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Your workout progress will be lost.")
                }

                // Elapsed + remaining time + preset info
                VStack(spacing: 4) {
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "stopwatch")
                                .font(.caption2)
                            Text(formatElapsed(engine.elapsedTime))
                                .monospacedDigit()
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "hourglass")
                                .font(.caption2)
                            Text("-\(formatElapsed(engine.totalRemainingTime))")
                                .monospacedDigit()
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Text("\(engine.presetName) — Interval \(engine.currentIntervalIndex + 1)/\(engine.totalIntervals)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 8)
            }
        }
        .overlay {
            if engine.isPaused && !engine.isFinished {
                VStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                        Text("PAUSED")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(.black.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    Spacer()
                    Spacer()
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: engine.isPaused)
            }
        }
        .overlay {
            if engine.isFinished {
                finishedOverlay
            }
        }
        .onChange(of: engine.isFinished) { _, finished in
            if !finished {
                celebrationScale = 0.3
                celebrationOpacity = 0
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = SettingsManager.shared.keepScreenAwake
        }
        .onChange(of: SettingsManager.shared.keepScreenAwake) { _, newValue in
            UIApplication.shared.isIdleTimerDisabled = newValue
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private var finishedOverlay: some View {
        ZStack {
            Color(red: 0.08, green: 0.09, blue: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                    .scaleEffect(celebrationScale)
                    .opacity(celebrationOpacity)

                Text("WORKOUT COMPLETE!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(celebrationOpacity)

                Text(engine.presetName)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
                    .opacity(celebrationOpacity)

                Text(motivationalMessage)
                    .font(.subheadline)
                    .foregroundStyle(.green.opacity(0.8))
                    .italic()
                    .opacity(celebrationOpacity)
                    .padding(.top, -8)

                // Stats grid
                HStack(spacing: 24) {
                    statCard(
                        icon: "clock.fill",
                        value: formatElapsed(engine.finalElapsedTime),
                        label: "Duration"
                    )
                    statCard(
                        icon: "repeat",
                        value: "\(engine.totalRounds)",
                        label: "Rounds"
                    )
                    statCard(
                        icon: "bolt.fill",
                        value: "\(engine.totalRounds * engine.totalIntervals)",
                        label: "Intervals"
                    )
                }
                .padding(.vertical, 8)
                .opacity(celebrationOpacity)

                Spacer()

                // Share + Done buttons
                VStack(spacing: 12) {
                    ShareLink(item: workoutShareText) {
                        HStack {
                            Spacer()
                            Label("Share Workout", systemImage: "square.and.arrow.up")
                                .font(.body)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundStyle(.green)
                        .padding(.vertical, 14)
                        .background(.green.opacity(0.15))
                        .clipShape(Capsule())
                    }

                    Button("Done") {
                        onStop()
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.green)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .opacity(celebrationOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                celebrationScale = 1.0
                celebrationOpacity = 1.0
            }
        }
    }

    private var motivationalMessage: String {
        let messages = [
            "Great work! You crushed it!",
            "Another one in the books!",
            "Strong finish!",
            "Way to push through!",
            "That's how it's done!",
            "Beast mode activated!",
            "Consistency builds champions!",
            "One step closer to your goals!"
        ]
        return messages[abs(engine.presetName.hashValue) % messages.count]
    }

    private var workoutShareText: String {
        let duration = formatElapsed(engine.finalElapsedTime)
        let rounds = engine.totalRounds
        let intervals = engine.totalRounds * engine.totalIntervals
        return """
        \(engine.presetName) — Done!
        \(duration) · \(rounds) \(rounds == 1 ? "round" : "rounds") · \(intervals) intervals

        Tracked with RoundTimer
        """
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.green)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let total = max(0, Int(ceil(time)))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func formatElapsed(_ time: TimeInterval) -> String {
        let total = max(0, Int(time))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct RoundDotsView: View {
    let current: Int
    let total: Int
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...total, id: \.self) { round in
                Circle()
                    .fill(round <= current ? color : color.opacity(0.15))
                    .frame(width: 16, height: 16)
                    .overlay {
                        if round <= current {
                            Circle()
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        }
                    }
                    .scaleEffect(round == current ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: current)
            }
        }
    }
}
