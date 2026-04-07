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

    var progress: Double {
        guard currentPhaseDuration > 0 else { return 0 }
        return 1.0 - (timeRemaining / currentPhaseDuration)
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
    private(set) var currentPhaseDuration: TimeInterval = 0

    private var halfTimeFired: Bool = false

    // MARK: - Callbacks
    var onPhaseChange: (@MainActor (TimerPhase) -> Void)?
    var onCountdownTick: (@MainActor (Int) -> Void)?
    var onHalfTime: (@MainActor () -> Void)?
    var onComplete: (@MainActor () -> Void)?

    // MARK: - Controls

    func start(preset: TimerPreset) {
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
        stopTick()
    }

    func resume() {
        guard isRunning, isPaused else { return }
        isPaused = false
        phaseStartDate = Date().addingTimeInterval(-(currentPhaseDuration - timeRemaining))
        startTick()
    }

    func stop() {
        stopTick()
        isRunning = false
        isPaused = false
        isFinished = false
        timeRemaining = 0
        preset = nil
        workoutStartDate = nil
    }

    func skip() {
        guard isRunning else { return }
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
                onHalfTime?()
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
