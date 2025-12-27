import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct StatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> StatsEntry {
        StatsEntry(date: Date(), data: StatsWidgetData.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (StatsEntry) -> Void) {
        let entry = StatsEntry(date: Date(), data: WidgetDataProvider.shared.getStatsData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsEntry>) -> Void) {
        let currentDate = Date()
        let entry = StatsEntry(date: currentDate, data: WidgetDataProvider.shared.getStatsData())

        // Refresh daily
        let tomorrow = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!)
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct StatsEntry: TimelineEntry {
    let date: Date
    let data: StatsWidgetData
}

// MARK: - Widget Views

struct StatsWidgetSmallView: View {
    let entry: StatsEntry

    var body: some View {
        SmallWidgetView {
            VStack(spacing: 8) {
                // Workouts progress ring
                ZStack {
                    CircularProgressView(
                        progress: Double(entry.data.workoutsCompleted) / Double(entry.data.workoutsGoal),
                        lineWidth: 8,
                        gradient: WidgetGradients.primary
                    )
                    .frame(width: 60, height: 60)

                    VStack(spacing: 0) {
                        Text("\(entry.data.workoutsCompleted)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.widgetText)
                        Text("/\(entry.data.workoutsGoal)")
                            .font(.caption2)
                            .foregroundColor(.widgetText.opacity(0.7))
                    }
                }

                Text("Workouts")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.widgetText.opacity(0.7))
            }
        }
        .widgetURL(WidgetDeepLinks.stats)
    }
}

struct StatsWidgetMediumView: View {
    let entry: StatsEntry

    var body: some View {
        MediumWidgetView {
            HStack(spacing: 16) {
                // Workout progress
                VStack(spacing: 4) {
                    ZStack {
                        CircularProgressView(
                            progress: Double(entry.data.workoutsCompleted) / Double(entry.data.workoutsGoal),
                            lineWidth: 6,
                            gradient: WidgetGradients.primary
                        )
                        .frame(width: 50, height: 50)

                        Text("\(entry.data.workoutsCompleted)/\(entry.data.workoutsGoal)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.widgetText)
                    }
                    Text("Workouts")
                        .font(.caption2)
                        .foregroundColor(.widgetText.opacity(0.7))
                }

                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    StatBox(icon: "clock", value: "\(entry.data.totalMinutes)", label: "min")
                    StatBox(icon: "flame.fill", value: "\(entry.data.caloriesBurned)", label: "cal")
                    StatBox(icon: "bolt.fill", value: "\(entry.data.currentStreak)", label: "streak")
                    StatBox(icon: "trophy.fill", value: "\(entry.data.prsThisWeek)", label: "PRs")
                }
            }
        }
        .widgetURL(WidgetDeepLinks.stats)
    }
}

struct StatsWidgetLargeView: View {
    let entry: StatsEntry

    var body: some View {
        LargeWidgetView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(WidgetGradients.primary)
                    Text("Weekly Stats")
                        .font(.headline)
                        .foregroundColor(.widgetText.opacity(0.7))
                    Spacer()
                }

                // Main workout progress
                HStack(spacing: 20) {
                    ZStack {
                        CircularProgressView(
                            progress: Double(entry.data.workoutsCompleted) / Double(entry.data.workoutsGoal),
                            lineWidth: 10,
                            gradient: WidgetGradients.primary
                        )
                        .frame(width: 80, height: 80)

                        VStack(spacing: 0) {
                            Text("\(entry.data.workoutsCompleted)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.widgetText)
                            Text("of \(entry.data.workoutsGoal)")
                                .font(.caption)
                                .foregroundColor(.widgetText.opacity(0.7))
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Workouts This Week")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.widgetText)

                        if entry.data.workoutsCompleted >= entry.data.workoutsGoal {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Goal reached!")
                                    .foregroundColor(.green)
                            }
                            .font(.caption)
                        } else {
                            Text("\(entry.data.workoutsGoal - entry.data.workoutsCompleted) more to reach goal")
                                .font(.caption)
                                .foregroundColor(.widgetText.opacity(0.7))
                        }
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    LargeStatBox(icon: "clock.fill", value: "\(entry.data.totalMinutes)", label: "Minutes", color: .widgetSecondary)
                    LargeStatBox(icon: "flame.fill", value: "\(entry.data.caloriesBurned)", label: "Calories", color: .orange)
                    LargeStatBox(icon: "bolt.fill", value: "\(entry.data.currentStreak)", label: "Day Streak", color: .yellow)
                    LargeStatBox(icon: "trophy.fill", value: "\(entry.data.prsThisWeek)", label: "New PRs", color: .purple)
                    LargeStatBox(
                        icon: entry.data.weightChange >= 0 ? "arrow.up" : "arrow.down",
                        value: String(format: "%.1f", abs(entry.data.weightChange)),
                        label: "Weight (lbs)",
                        color: entry.data.weightChange >= 0 ? .red : .green
                    )
                    LargeStatBox(icon: "percent", value: "\(Int(Double(entry.data.workoutsCompleted) / Double(entry.data.workoutsGoal) * 100))", label: "Goal %", color: .mint)
                }

                Spacer()

                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Weekly Progress")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.widgetText.opacity(0.7))
                        Spacer()
                        Text("\(Int(Double(entry.data.workoutsCompleted) / Double(entry.data.workoutsGoal) * 100))%")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.widgetText)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(WidgetGradients.primary)
                                .frame(width: geometry.size.width * CGFloat(entry.data.workoutsCompleted) / CGFloat(entry.data.workoutsGoal), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .widgetURL(WidgetDeepLinks.stats)
    }
}

// MARK: - Helper Views

struct StatBox: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.widgetSecondary)
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.widgetText)
            }
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.widgetText.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct LargeStatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.widgetText)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.widgetText.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Widget Configuration

struct StatsWidget: Widget {
    let kind: String = "StatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatsProvider()) { entry in
            StatsWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Stats Dashboard")
        .description("View your weekly fitness statistics at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct StatsWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: StatsEntry

    var body: some View {
        switch family {
        case .systemSmall:
            StatsWidgetSmallView(entry: entry)
        case .systemMedium:
            StatsWidgetMediumView(entry: entry)
        case .systemLarge:
            StatsWidgetLargeView(entry: entry)
        default:
            StatsWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    StatsWidget()
} timeline: {
    StatsEntry(date: Date(), data: StatsWidgetData.placeholder)
}

#Preview(as: .systemMedium) {
    StatsWidget()
} timeline: {
    StatsEntry(date: Date(), data: StatsWidgetData.placeholder)
}

#Preview(as: .systemLarge) {
    StatsWidget()
} timeline: {
    StatsEntry(date: Date(), data: StatsWidgetData.placeholder)
}
