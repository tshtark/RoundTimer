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

struct RoundTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock screen Live Activity
            HStack {
                Circle()
                    .fill(.green)
                    .frame(width: 12, height: 12)
                Text(context.state.phase.uppercased())
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text(context.state.intervalEndDate, style: .timer)
                    .font(.headline)
                    .monospacedDigit()
                Text("R \(context.state.currentRound)/\(context.attributes.totalRounds)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.phase.uppercased())
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Round \(context.state.currentRound)/\(context.attributes.totalRounds)")
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.intervalEndDate, style: .timer)
                        .font(.title)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.presetName)
                        .font(.caption)
                }
            } compactLeading: {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
            } compactTrailing: {
                Text(context.state.intervalEndDate, style: .timer)
                    .font(.caption)
                    .monospacedDigit()
            } minimal: {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
            }
        }
    }
}
