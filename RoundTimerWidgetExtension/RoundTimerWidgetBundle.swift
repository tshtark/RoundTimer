import WidgetKit
import SwiftUI
import ActivityKit

@main
struct RoundTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        RoundTimerLiveActivity()
    }
}

// TimerActivityAttributes is defined in shared file:
// RoundTimer/LiveActivity/TimerActivityAttributes.swift

/// Convert a hex string like "#34C759" or "34C759" to a SwiftUI Color.
/// Falls back to phase green if parsing fails.
private func colorFromHex(_ hex: String) -> Color {
    var s = hex
    if s.hasPrefix("#") { s.removeFirst() }
    guard s.count == 6, let value = UInt32(s, radix: 16) else { return .green }
    let r = Double((value >> 16) & 0xFF) / 255.0
    let g = Double((value >> 8) & 0xFF) / 255.0
    let b = Double(value & 0xFF) / 255.0
    return Color(red: r, green: g, blue: b)
}

struct RoundTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock screen Live Activity
            let phaseColor = colorFromHex(context.state.phaseColorHex)
            HStack(spacing: 10) {
                Circle()
                    .fill(phaseColor)
                    .frame(width: 12, height: 12)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.phase.uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(phaseColor)
                    if let name = context.state.intervalName, !name.isEmpty {
                        Text(name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if context.state.isPaused {
                    Label("PAUSED", systemImage: "pause.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                } else {
                    Text(context.state.intervalEndDate, style: .timer)
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(phaseColor)
                }
                Text("R \(context.state.currentRound)/\(context.attributes.totalRounds)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        } dynamicIsland: { context in
            let phaseColor = colorFromHex(context.state.phaseColorHex)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.phase.uppercased())
                            .font(.headline)
                            .foregroundStyle(phaseColor)
                        if let name = context.state.intervalName, !name.isEmpty {
                            Text(name)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Round \(context.state.currentRound)/\(context.attributes.totalRounds)")
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.center) {
                    if context.state.isPaused {
                        Label("PAUSED", systemImage: "pause.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(context.state.intervalEndDate, style: .timer)
                            .font(.title)
                            .monospacedDigit()
                            .foregroundStyle(phaseColor)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.presetName)
                        .font(.caption)
                }
            } compactLeading: {
                Circle()
                    .fill(phaseColor)
                    .frame(width: 8, height: 8)
            } compactTrailing: {
                if context.state.isPaused {
                    Image(systemName: "pause.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(context.state.intervalEndDate, style: .timer)
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(phaseColor)
                }
            } minimal: {
                Circle()
                    .fill(phaseColor)
                    .frame(width: 8, height: 8)
            }
        }
    }
}
