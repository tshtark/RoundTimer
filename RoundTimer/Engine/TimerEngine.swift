import Foundation

@MainActor
@Observable
class TimerEngine {
    // MARK: - Published State
    var currentPhase: TimerPhase = .work
    var timeRemaining: TimeInterval = 0
    var currentRound: Int = 1
    var totalRounds: Int = 1
    var currentIntervalIndex: Int = 0
    var totalIntervals: Int = 0
    var isRunning: Bool = false
    var isPaused: Bool = false
    var isFinished: Bool = false
    var presetName: String = ""
    var intervalName: String? = nil

    // MARK: - Computed
    var phaseEndDate: Date {
        Date().addingTimeInterval(timeRemaining)
    }

    var nextPhaseDescription: String? {
        guard let preset = preset, isRunning, !isFinished else { return nil }
        switch currentPhase {
        case .warmup:
            if let first = preset.intervals.first {
                return "Next: \(first.phase.displayName) \(formatDuration(first.duration))"
            }
        case .work, .rest:
            let nextIndex = currentIntervalIndex + 1
            if nextIndex < preset.intervals.count {
                let next = preset.intervals[nextIndex]
                return "Next: \(next.phase.displayName) \(formatDuration(next.duration))"
            } else if currentRound < totalRounds {
                let first = preset.intervals[0]
                return "Next: Round \(currentRound + 1) — \(first.phase.displayName)"
            } else if let cooldown = preset.cooldown, cooldown > 0 {
                return "Next: Cooldown \(formatDuration(cooldown))"
            } else {
                return "Final interval!"
            }
        case .cooldown:
            return "Almost done!"
        }
        return nil
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let total = Int(duration)
        let minutes = total / 60
        let seconds = total % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        return "0:\(String(format: "%02d", seconds))"
    }

    var progress: Double {
        guard currentPhaseDuration > 0 else { return 0 }
        return 1.0 - (timeRemaining / currentPhaseDuration)
    }

    var totalRemainingTime: TimeInterval {
        guard let preset = preset, isRunning, !isFinished else { return 0 }
        var remaining = timeRemaining

        // During warmup we haven't started any interval yet, so include ALL intervals
        // of the current round. Otherwise add only the intervals AFTER the current one.
        let intervalDuration = preset.intervals.reduce(0.0) { $0 + $1.duration }
        let startFromIndex = (currentPhase == .warmup) ? 0 : (currentIntervalIndex + 1)
        for i in startFromIndex..<preset.intervals.count {
            remaining += preset.intervals[i].duration
        }

        // Add remaining FULL rounds. During warmup, the first round still needs to play
        // entirely (we just added it above), so remaining rounds = totalRounds - 1.
        let remainingRounds = (currentPhase == .warmup) ? (totalRounds - 1) : (totalRounds - currentRound)
        remaining += Double(max(0, remainingRounds)) * intervalDuration

        // Add cooldown if applicable
        if currentPhase != .cooldown, let cooldown = preset.cooldown, cooldown > 0 {
            remaining += cooldown
        }

        return remaining
    }

    /// True when calling `skip()` would cause workout completion (i.e., trigger `finish()`).
    /// Used to disable the Skip button on the final phase so users can't fake-complete a workout.
    var isOnFinalPhase: Bool {
        guard let preset = preset, isRunning, !isFinished else { return false }
        switch currentPhase {
        case .warmup:
            return false
        case .work, .rest:
            let isLastIntervalInRound = currentIntervalIndex + 1 >= preset.intervals.count
            let isLastRound = currentRound >= totalRounds
            let hasCooldown = (preset.cooldown ?? 0) > 0
            return isLastIntervalInRound && isLastRound && !hasCooldown
        case .cooldown:
            return true
        }
    }

    // MARK: - Elapsed Time
    var workoutStartDate: Date?
    var finalElapsedTime: TimeInterval = 0

    var elapsedTime: TimeInterval {
        guard let start = workoutStartDate else { return finalElapsedTime }
        return Date().timeIntervalSince(start)
    }

    // MARK: - Internal State
    private var preset: TimerPreset?
    private var timer: Timer?
    private var phaseStartDate: Date?
    private var pauseStartDate: Date?
    private(set) var currentPhaseDuration: TimeInterval = 0

    var isHalfTime: Bool = false
    private var halfTimeFired: Bool = false
    private var halfTimeDismissTask: Task<Void, Never>?

    // MARK: - Callbacks
    var onPhaseChange: (@MainActor (TimerPhase) -> Void)?
    var onCountdownTick: (@MainActor (Int) -> Void)?
    var onHalfTime: (@MainActor () -> Void)?
    var onComplete: (@MainActor () -> Void)?
    /// Fires whenever isPaused changes (true on pause, false on resume).
    var onPauseStateChange: (@MainActor (Bool) -> Void)?

    // MARK: - Controls

    func start(preset: TimerPreset) {
        // Defensive guard: a malformed preset (zero intervals) should never start a workout.
        // Otherwise the phase machine would recurse instantly through every round and fire
        // a fake completion (sound, history record, day-streak bump).
        guard !preset.intervals.isEmpty else { return }

        self.preset = preset
        self.presetName = preset.name
        self.totalRounds = preset.rounds
        self.totalIntervals = preset.intervals.count
        self.currentRound = 1
        self.currentIntervalIndex = 0
        self.isRunning = true
        self.isPaused = false
        self.isFinished = false
        self.workoutStartDate = Date()
        self.pauseStartDate = nil

        if let warmup = preset.warmup, warmup > 0 {
            enterPhase(.warmup, duration: warmup, name: nil)
        } else {
            enterInterval(index: 0)
        }

        startTick()
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        pauseStartDate = Date()
        stopTick()
        onPauseStateChange?(true)
    }

    func resume() {
        guard isRunning, isPaused else { return }
        isPaused = false
        // Push both the workout start and current phase start forward by the paused
        // duration so elapsedTime and tick() math both exclude the paused window.
        if let pauseStart = pauseStartDate {
            let pauseDuration = Date().timeIntervalSince(pauseStart)
            workoutStartDate = workoutStartDate?.addingTimeInterval(pauseDuration)
            phaseStartDate = phaseStartDate?.addingTimeInterval(pauseDuration)
        }
        pauseStartDate = nil
        startTick()
        onPauseStateChange?(false)
    }

    func stop() {
        stopTick()
        isRunning = false
        isPaused = false
        isFinished = false
        timeRemaining = 0
        preset = nil
        workoutStartDate = nil
        pauseStartDate = nil
    }

    func skip() {
        guard isRunning else { return }
        // Refuse to skip past the final phase. Otherwise the user could fake-complete
        // a workout in seconds (fires celebration sound, writes a fake WorkoutRecord,
        // bumps day streak). The Skip button is also disabled in the UI when on the
        // final phase, but this guard is the source of truth.
        guard !isOnFinalPhase else { return }
        advanceToNextPhase()
    }

    // MARK: - Phase Management

    private func enterPhase(_ phase: TimerPhase, duration: TimeInterval, name: String?) {
        currentPhase = phase
        currentPhaseDuration = duration
        timeRemaining = duration
        intervalName = name
        phaseStartDate = Date()
        halfTimeFired = false
        halfTimeDismissTask?.cancel()
        isHalfTime = false
        onPhaseChange?(phase)
    }

    private func enterInterval(index: Int) {
        guard let preset = preset, index < preset.intervals.count else {
            finishOrNextRound()
            return
        }
        currentIntervalIndex = index
        let interval = preset.intervals[index]
        enterPhase(interval.phase, duration: interval.duration, name: interval.name)
    }

    private func advanceToNextPhase() {
        guard let preset = preset else { return }

        switch currentPhase {
        case .warmup:
            enterInterval(index: 0)

        case .work, .rest:
            let nextIndex = currentIntervalIndex + 1
            if nextIndex < preset.intervals.count {
                enterInterval(index: nextIndex)
            } else {
                finishOrNextRound()
            }

        case .cooldown:
            finish()
        }
    }

    private func finishOrNextRound() {
        guard let preset = preset else { return }

        if currentRound < totalRounds {
            currentRound += 1
            enterInterval(index: 0)
        } else if let cooldown = preset.cooldown, cooldown > 0 {
            enterPhase(.cooldown, duration: cooldown, name: nil)
        } else {
            finish()
        }
    }

    private func finish() {
        stopTick()
        finalElapsedTime = elapsedTime
        isRunning = false
        isFinished = true
        onComplete?()
    }

    // MARK: - Timer Tick

    private func startTick() {
        stopTick()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
    }

    private func stopTick() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard let phaseStartDate = phaseStartDate else { return }

        let elapsed = Date().timeIntervalSince(phaseStartDate)
        let remaining = currentPhaseDuration - elapsed
        timeRemaining = max(0, remaining)

        // Half-time alert (only for intervals >= 10 seconds)
        if !halfTimeFired && currentPhaseDuration >= 10 {
            let halfPoint = currentPhaseDuration / 2.0
            if elapsed >= halfPoint {
                halfTimeFired = true
                isHalfTime = true
                onHalfTime?()
                halfTimeDismissTask?.cancel()
                halfTimeDismissTask = Task { [weak self] in
                    try? await Task.sleep(for: .seconds(2))
                    guard !Task.isCancelled else { return }
                    self?.isHalfTime = false
                }
            }
        }

        let secondsLeft = Int(ceil(timeRemaining))
        if secondsLeft <= 3 && secondsLeft > 0 && remaining > 0 {
            onCountdownTick?(secondsLeft)
        }

        if timeRemaining <= 0 {
            advanceToNextPhase()
        }
    }
}
