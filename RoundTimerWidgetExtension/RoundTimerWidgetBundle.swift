import WidgetKit
import SwiftUI

@main
struct RoundTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        RoundTimerLiveActivity()
    }
}

struct RoundTimerLiveActivity: Widget {
    let kind: String = "RoundTimerLiveActivity"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SimpleProvider()) { entry in
            Text("RoundTimer")
        }
        .configurationDisplayName("Timer")
        .description("Shows your active interval timer.")
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct SimpleProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}
