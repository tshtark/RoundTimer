import Foundation

struct TimerInterval: Identifiable, Codable {
    let id: UUID
    var phase: TimerPhase
    var duration: TimeInterval
    var name: String?

    init(id: UUID = UUID(), phase: TimerPhase, duration: TimeInterval, name: String? = nil) {
        self.id = id
        self.phase = phase
        self.duration = duration
        self.name = name
    }
}
