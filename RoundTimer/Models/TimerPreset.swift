import Foundation

struct TimerPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var intervals: [TimerInterval]
    var rounds: Int
    var warmup: TimeInterval?
    var cooldown: TimeInterval?
    var isBuiltIn: Bool
    var lastUsedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        intervals: [TimerInterval],
        rounds: Int,
        warmup: TimeInterval? = nil,
        cooldown: TimeInterval? = nil,
        isBuiltIn: Bool = false,
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.intervals = intervals
        self.rounds = rounds
        self.warmup = warmup
        self.cooldown = cooldown
        self.isBuiltIn = isBuiltIn
        self.lastUsedAt = lastUsedAt
    }

    var totalDuration: TimeInterval {
        let intervalTime = intervals.reduce(0) { $0 + $1.duration }
        let roundsTime = intervalTime * Double(rounds)
        return (warmup ?? 0) + roundsTime + (cooldown ?? 0)
    }

    var formattedDuration: String {
        let total = Int(totalDuration)
        let minutes = total / 60
        let seconds = total % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}
