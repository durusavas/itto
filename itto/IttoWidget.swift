//
//  IttoWidget.swift
//  itto
//
//  Basic Home Screen Widget for Today summary and quick access to Timer.
//  To use: Add a new "Widget Extension" target in Xcode, then include this file in the widget target.
//  Requires WidgetKit and SwiftUI.

import WidgetKit
import SwiftUI

struct IttoEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let todayTasks: Int
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> IttoEntry {
        IttoEntry(date: Date(), streak: 3, todayTasks: 2)
    }

    func getSnapshot(in context: Context, completion: @escaping (IttoEntry) -> ()) {
        let entry = IttoEntry(date: Date(), streak: 5, todayTasks: 4)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<IttoEntry>) -> ()) {
        // For a basic widget, we use a static entry.
        // In a full implementation, use App Groups + shared UserDefaults from the main app
        // to pull real streak (from Reports) and today's task count (from DailySubjects).
        let entry = IttoEntry(date: Date(), streak: 5, todayTasks: 3)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct IttoWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("itto")
                    .font(.headline)
                Spacer()
                Image(systemName: "graduationcap")
            }
            Text(entry.date, style: .date)
                .font(.subheadline)
            HStack {
                Text("🔥 \(entry.streak)")
                Spacer()
                Text("\(entry.todayTasks) tasks")
            }
            .font(.caption)
            
            Link(destination: URL(string: "itto://timer")!) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Start Focus")
                }
                .font(.caption2)
                .padding(4)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(6)
            }
        }
        .padding(8)
    }
}

struct IttoWidget: Widget {
    let kind: String = "IttoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            IttoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("itto Today")
        .description("Your streak and quick access to focus timer.")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct IttoWidgetBundle: WidgetBundle {
    var body: some Widget {
        IttoWidget()
    }
}