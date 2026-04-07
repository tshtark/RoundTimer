import SwiftUI

enum TimerPhase: String, Codable, CaseIterable {
    case warmup
    case work
    case rest
    case cooldown

    var displayName: String {
        switch self {
        case .warmup: "WARMUP"
        case .work: "WORK"
        case .rest: "REST"
        case .cooldown: "COOLDOWN"
        }
    }

    var color: Color {
        switch self {
        case .warmup: .yellow
        case .work: .green
        case .rest: .blue
        case .cooldown: .orange
        }
    }

    var colorHex: String {
        switch self {
        case .warmup: "#FFD60A"
        case .work: "#34C759"
        case .rest: "#007AFF"
        case .cooldown: "#FF9500"
        }
    }

    var soundEvent: SoundEvent {
        switch self {
        case .warmup: .warmupStart
        case .work: .workStart
        case .rest: .restStart
        case .cooldown: .cooldownStart
        }
    }
}
