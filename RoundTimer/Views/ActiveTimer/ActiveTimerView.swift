import SwiftUI

struct ActiveTimerView: View {
    @Bindable var engine: TimerEngine
    var onStop: () -> Void
    @State private var showStopConfirmation = false

    var body: some View {
        ZStack {
            engine.currentPhase.color
                .opacity(0.3)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: engine.currentPhase)

            VStack(spacing: 24) {
                // Interval progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(engine.currentPhase.color.opacity(0.2))
                            .frame(height: 6)
                        Capsule()
                            .fill(engine.currentPhase.color)
                            .frame(width: geo.size.width * engine.progress, height: 6)
                            .animation(.linear(duration: 0.1), value: engine.progress)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 24)
                .padding(.top, 8)

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

                // Big countdown
                Text(formatTime(engine.timeRemaining))
                    .font(.system(size: 96, weight: .bold, design: .monospaced))
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

                // Round progress
                Text("Round \(engine.currentRound) / \(engine.totalRounds)")
                    .font(.title2)
                    .fontWeight(.medium)

                // Round dots
                if engine.totalRounds <= 20 {
                    RoundDotsView(
                        current: engine.currentRound,
                        total: engine.totalRounds,
                        color: engine.currentPhase.color
                    )
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

                    // Skip
                    Button {
                        engine.skip()
                    } label: {
                        Image(systemName: "forward.end.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Skip to next interval")

                    // Stop
                    Button {
                        showStopConfirmation = true
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red)
                    }
                    .accessibilityLabel("Stop timer")
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

                // Elapsed time + preset info
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(formatElapsed(engine.elapsedTime))
                        .monospacedDigit()
                    Text("·")
                    Text("\(engine.presetName) — Interval \(engine.currentIntervalIndex + 1)/\(engine.totalIntervals)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
            }
        }
        .overlay {
            if engine.isFinished {
                finishedOverlay
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private var finishedOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)

                Text("COMPLETE!")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Button("Done") {
                    onStop()
                }
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(.green)
                .clipShape(Capsule())
            }
        }
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
