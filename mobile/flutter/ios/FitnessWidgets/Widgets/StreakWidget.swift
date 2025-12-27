import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), data: StreakWidgetData.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        let entry = StreakEntry(date: Date(), data: WidgetDataProvider.shared.getStreakData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let currentDate = Date()
        let entry = StreakEntry(date: currentDate, data: WidgetDataProvider.shared.getStreakData())

        // Refresh daily at midnight
        let tomorrow = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!)
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct StreakEntry: TimelineEntry {
    let date: Date
    let data: StreakWidgetData
}

// MARK: - Widget Views

struct StreakWidgetSmallView: View {
    let entry: StreakEntry

    var body: some View {
        SmallWidgetView {
            VStack(spacing: 8) {
                // Fire icon with animation effect
                ZStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(WidgetGradients.fire)
                        .shadow(color: .orange.opacity(0.5), radius: 10, y: 5)
                }

                // Streak count
                Text("\(entry.data.currentStreak)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.widgetText)

                Text("day streak")
                    .font(.caption)
                    .foregroundColor(.widgetText.opacity(0.7))
            }
        }
        .widgetURL(WidgetDeepLinks.stats)
    }
}

struct StreakWidgetMediumView: View {
    let entry: StreakEntry

    var body: some View {
        MediumWidgetView {
            HStack(spacing: 16) {
                // Left - Fire and streak
                VStack(spacing: 4) {
                    ZStack {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 35))
                            .foregroundStyle(WidgetGradients.fire)
                            .shadow(color: .orange.opacity(0.5), radius: 8, y: 4)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(entry.data.currentStreak)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.widgetText)
                        Text("days")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.widgetText.opacity(0.7))
                    }
                }
                .frame(width: 80)

                // Right - Message and record
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.data.motivationalMessage)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.widgetText)
                        .lineLimit(2)

                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("Longest: \(entry.data.longestStreak) days")
                            .font(.caption)
                            .foregroundColor(.widgetText.opacity(0.7))
                    }
                }

                Spacer()
            }
        }
        .widgetURL(WidgetDeepLinks.stats)
    }
}

struct StreakWidgetLargeView: View {
    let entry: StreakEntry

    var body: some View {
        LargeWidgetView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Streak")
                        .font(.headline)
                        .foregroundColor(.widgetText.opacity(0.7))
                    Spacer()
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("Best: \(entry.data.longestStreak)")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.widgetText.opacity(0.7))
                }

                // Main streak display
                VStack(spacing: 8) {
                    ZStack {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(WidgetGradients.fire)
                            .shadow(color: .orange.opacity(0.5), radius: 15, y: 8)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(entry.data.currentStreak)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.widgetText)
                        Text("day streak")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.widgetText.opacity(0.7))
                    }
                }

                // Motivational message
                Text(entry.data.motivationalMessage)
                    .font(.body.weight(.medium))
                    .foregroundColor(.widgetText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                // Weekly consistency chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("This Week")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.widgetText.opacity(0.7))

                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { index in
                            let isCompleted = index < entry.data.weeklyConsistency.count && entry.data.weeklyConsistency[index]
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(isCompleted ? WidgetGradients.fire : Color.gray.opacity(0.3))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        isCompleted ?
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                        : nil
                                    )

                                Text(["S", "M", "T", "W", "T", "F", "S"][index])
                                    .font(.system(size: 10))
                                    .foregroundColor(.widgetText.opacity(0.6))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .widgetURL(WidgetDeepLinks.stats)
    }
}

// MARK: - Widget Configuration

struct StreakWidget: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Streak & Motivation")
        .description("Track your workout streak and stay motivated.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct StreakWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: StreakEntry

    var body: some View {
        switch family {
        case .systemSmall:
            StreakWidgetSmallView(entry: entry)
        case .systemMedium:
            StreakWidgetMediumView(entry: entry)
        case .systemLarge:
            StreakWidgetLargeView(entry: entry)
        default:
            StreakWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakEntry(date: Date(), data: StreakWidgetData.placeholder)
}

#Preview(as: .systemMedium) {
    StreakWidget()
} timeline: {
    StreakEntry(date: Date(), data: StreakWidgetData.placeholder)
}

#Preview(as: .systemLarge) {
    StreakWidget()
} timeline: {
    StreakEntry(date: Date(), data: StreakWidgetData.placeholder)
}
