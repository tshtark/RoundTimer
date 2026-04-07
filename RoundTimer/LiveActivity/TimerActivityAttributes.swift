import ActivityKit
import Foundation

struct TimerActivityAttributes: ActivityAttributes {
    let presetName: String
    let totalRounds: Int

    struct ContentState: Codable, Hashable {
        let phase: String
        let phaseColorHex: String
        let currentRound: Int
        let intervalEndDate: Date
        let intervalName: String?
        let isPaused: Bool
    }
}
