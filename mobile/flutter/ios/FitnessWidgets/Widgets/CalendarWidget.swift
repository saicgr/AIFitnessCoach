import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct CalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: Date(), data: CalendarWidgetData.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        let entry = CalendarEntry(date: Date(), data: WidgetDataProvider.shared.getCalendarData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        let currentDate = Date()
        let entry = CalendarEntry(date: currentDate, data: WidgetDataProvider.shared.getCalendarData())

        // Refresh hourly
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct CalendarEntry: TimelineEntry {
    let date: Date
    let data: CalendarWidgetData
}

// MARK: - Widget Views

struct CalendarWidgetSmallView: View {
    let entry: CalendarEntry

    var body: some View {
        SmallWidgetView {
            VStack(spacing: 8) {
                // Today indicator
                let today = entry.data.days.indices.contains(entry.data.todayIndex) ? entry.data.days[entry.data.todayIndex] : nil

                if let today = today {
                    // Day name and number
                    VStack(spacing: 4) {
                        Text(today.dayName)
                            .font(.caption.weight(.medium))
                            .foregroundColor(.widgetText.opacity(0.7))

                        ZStack {
                            Circle()
                                .fill(WidgetGradients.primary)
                                .frame(width: 40, height: 40)

                            Text("\(today.dayNumber)")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.white)
                        }
                    }

                    // Status
                    if today.isRestDay {
                        HStack(spacing: 4) {
                            Image(systemName: "moon.fill")
                                .font(.caption2)
                            Text("Rest Day")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundColor(.widgetText.opacity(0.7))
                    } else if today.isCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("Done!")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.green)
                        }
                    } else if today.hasWorkout {
                        HStack(spacing: 4) {
                            Image(systemName: "dumbbell.fill")
                                .font(.caption2)
                            Text("Workout")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundColor(.widgetSecondary)
                    }
                }
            }
        }
        .widgetURL(WidgetDeepLinks.schedule)
    }
}

struct CalendarWidgetMediumView: View {
    let entry: CalendarEntry

    var body: some View {
        MediumWidgetView {
            VStack(spacing: 8) {
                // Week header
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(WidgetGradients.primary)
                    Text("This Week")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.widgetText.opacity(0.7))
                    Spacer()
                }

                // Week strip
                HStack(spacing: 4) {
                    ForEach(Array(entry.data.days.enumerated()), id: \.offset) { index, day in
                        CalendarDayCell(day: day, isToday: index == entry.data.todayIndex)
                    }
                }
            }
        }
        .widgetURL(WidgetDeepLinks.schedule)
    }
}

struct CalendarWidgetLargeView: View {
    let entry: CalendarEntry

    var body: some View {
        LargeWidgetView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(WidgetGradients.primary)
                    Text("Weekly Schedule")
                        .font(.headline)
                        .foregroundColor(.widgetText.opacity(0.7))
                    Spacer()
                }

                // Week grid
                VStack(spacing: 8) {
                    // Day headers
                    HStack(spacing: 4) {
                        ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                            Text(day)
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.widgetText.opacity(0.6))
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // Day cells with details
                    HStack(spacing: 4) {
                        ForEach(Array(entry.data.days.enumerated()), id: \.offset) { index, day in
                            LargeCalendarDayCell(day: day, isToday: index == entry.data.todayIndex)
                        }
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // Today's details
                let today = entry.data.days.indices.contains(entry.data.todayIndex) ? entry.data.days[entry.data.todayIndex] : nil

                if let today = today {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Today")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.widgetText.opacity(0.7))

                            if today.isRestDay {
                                HStack(spacing: 8) {
                                    Image(systemName: "moon.fill")
                                        .foregroundColor(.purple)
                                    Text("Rest Day - Take time to recover")
                                        .font(.subheadline)
                                        .foregroundColor(.widgetText)
                                }
                            } else if let workoutName = today.workoutName {
                                HStack(spacing: 8) {
                                    Image(systemName: today.isCompleted ? "checkmark.circle.fill" : "dumbbell.fill")
                                        .foregroundColor(today.isCompleted ? .green : .widgetSecondary)
                                    Text(workoutName)
                                        .font(.subheadline)
                                        .foregroundColor(.widgetText)
                                    if today.isCompleted {
                                        Text("Completed")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                        Spacer()
                    }
                }

                Spacer()

                // View schedule button
                Link(destination: WidgetDeepLinks.schedule ?? URL(string: "aifitnesscoach://schedule")!) {
                    Text("View Full Schedule")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(WidgetGradients.primary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

// MARK: - Helper Views

struct LargeCalendarDayCell: View {
    let day: CalendarDay
    let isToday: Bool

    var body: some View {
        VStack(spacing: 4) {
            // Day number
            ZStack {
                if isToday {
                    Circle()
                        .fill(WidgetGradients.primary)
                        .frame(width: 28, height: 28)
                }

                Text("\(day.dayNumber)")
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundColor(isToday ? .white : .widgetText)
            }

            // Status icon
            if day.isRestDay {
                Image(systemName: "moon.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.purple.opacity(0.6))
            } else if day.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
            } else if day.hasWorkout {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.widgetSecondary)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 10, height: 10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isToday ? Color.white.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Widget Configuration

struct CalendarWidget: Widget {
    let kind: String = "CalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            CalendarWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Weekly Calendar")
        .description("View your weekly workout schedule at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct CalendarWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: CalendarEntry

    var body: some View {
        switch family {
        case .systemSmall:
            CalendarWidgetSmallView(entry: entry)
        case .systemMedium:
            CalendarWidgetMediumView(entry: entry)
        case .systemLarge:
            CalendarWidgetLargeView(entry: entry)
        default:
            CalendarWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    CalendarWidget()
} timeline: {
    CalendarEntry(date: Date(), data: CalendarWidgetData.placeholder)
}

#Preview(as: .systemMedium) {
    CalendarWidget()
} timeline: {
    CalendarEntry(date: Date(), data: CalendarWidgetData.placeholder)
}

#Preview(as: .systemLarge) {
    CalendarWidget()
} timeline: {
    CalendarEntry(date: Date(), data: CalendarWidgetData.placeholder)
}
