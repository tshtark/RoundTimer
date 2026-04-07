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
        case .warmup: Color(red: 1.0, green: 0.7, blue: 0.0)       // Amber
        case .work: Color(red: 0.0, green: 0.78, blue: 0.33)       // Emerald
        case .rest: Color(red: 0.16, green: 0.47, blue: 1.0)       // Steel blue
        case .cooldown: Color(red: 1.0, green: 0.43, blue: 0.0)    // Deep orange
        }
    }

    var colorHex: String {
        switch self {
        case .warmup: "#FFB300"
        case .work: "#00C853"
        case .rest: "#2979FF"
        case .cooldown: "#FF6D00"
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
