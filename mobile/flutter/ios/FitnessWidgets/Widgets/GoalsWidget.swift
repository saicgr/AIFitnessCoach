import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct GoalsProvider: TimelineProvider {
    func placeholder(in context: Context) -> GoalsEntry {
        GoalsEntry(date: Date(), data: GoalsWidgetData.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (GoalsEntry) -> Void) {
        let entry = GoalsEntry(date: Date(), data: WidgetDataProvider.shared.getGoalsData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GoalsEntry>) -> Void) {
        let currentDate = Date()
        let entry = GoalsEntry(date: currentDate, data: WidgetDataProvider.shared.getGoalsData())

        // Refresh every 4 hours
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct GoalsEntry: TimelineEntry {
    let date: Date
    let data: GoalsWidgetData
}

// MARK: - Widget Views

struct GoalsWidgetSmallView: View {
    let entry: GoalsEntry

    var body: some View {
        SmallWidgetView {
            if let topGoal = entry.data.goals.first {
                VStack(spacing: 8) {
                    // Target ring
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 8)
                            .frame(width: 60, height: 60)

                        Circle()
                            .trim(from: 0, to: CGFloat(topGoal.progressPercent) / 100)
                            .stroke(WidgetGradients.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))

                        Text("\(topGoal.progressPercent)%")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.widgetText)
                    }

                    Text(topGoal.title)
                        .font(.caption)
                        .foregroundColor(.widgetText)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.title)
                        .foregroundColor(.widgetText.opacity(0.3))
                    Text("No Goals Set")
                        .font(.caption)
                        .foregroundColor(.widgetText.opacity(0.7))
                }
            }
        }
        .widgetURL(WidgetDeepLinks.goals)
    }
}

struct GoalsWidgetMediumView: View {
    let entry: GoalsEntry

    var body: some View {
        MediumWidgetView {
            HStack(spacing: 16) {
                // Left - Target icon
                VStack {
                    Image(systemName: "target")
                        .font(.title)
                        .foregroundStyle(WidgetGradients.primary)
                    Text("Goals")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.widgetText.opacity(0.7))
                }
                .frame(width: 50)

                // Right - Goals list
                VStack(spacing: 8) {
                    ForEach(entry.data.goals.prefix(2), id: \.id) { goal in
                        GoalProgressRow(goal: goal)
                    }
                }
            }
        }
        .widgetURL(WidgetDeepLinks.goals)
    }
}

struct GoalsWidgetLargeView: View {
    let entry: GoalsEntry

    var body: some View {
        LargeWidgetView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "target")
                        .foregroundStyle(WidgetGradients.primary)
                    Text("Personal Goals")
                        .font(.headline)
                        .foregroundColor(.widgetText.opacity(0.7))
                    Spacer()
                }

                if entry.data.goals.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "target")
                            .font(.system(size: 50))
                            .foregroundColor(.widgetText.opacity(0.3))
                        Text("No Goals Set")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.widgetText.opacity(0.7))
                        Text("Set goals to track your fitness journey!")
                            .font(.caption)
                            .foregroundColor(.widgetText.opacity(0.5))
                    }
                    Spacer()
                } else {
                    // Goals list
                    ForEach(entry.data.goals, id: \.id) { goal in
                        LargeGoalRow(goal: goal)
                    }

                    Spacer()

                    // View all button
                    Link(destination: WidgetDeepLinks.goals ?? URL(string: "aifitnesscoach://goals")!) {
                        Text("View All Goals")
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
}

// MARK: - Helper Views

struct GoalProgressRow: View {
    let goal: GoalItem

    var body: some View {
        HStack {
            // Goal title
            Text(goal.title)
                .font(.caption)
                .foregroundColor(.widgetText)
                .lineLimit(1)

            Spacer()

            // Progress
            Text("\(goal.progressPercent)%")
                .font(.caption.weight(.bold))
                .foregroundColor(.widgetSecondary)
                .frame(width: 40, alignment: .trailing)

            // Mini progress bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 50, height: 6)

                RoundedRectangle(cornerRadius: 2)
                    .fill(WidgetGradients.primary)
                    .frame(width: 50 * CGFloat(goal.progressPercent) / 100, height: 6)
            }
        }
    }
}

struct LargeGoalRow: View {
    let goal: GoalItem

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 4)
                        .frame(width: 36, height: 36)

                    Circle()
                        .trim(from: 0, to: CGFloat(goal.progressPercent) / 100)
                        .stroke(WidgetGradients.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))

                    Text("\(goal.progressPercent)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.widgetText)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.widgetText)
                        .lineLimit(1)

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(WidgetGradients.primary)
                                .frame(width: geometry.size.width * CGFloat(goal.progressPercent) / 100, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Widget Configuration

struct GoalsWidget: Widget {
    let kind: String = "GoalsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GoalsProvider()) { entry in
            GoalsWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Personal Goals")
        .description("Track progress on your fitness goals.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct GoalsWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: GoalsEntry

    var body: some View {
        switch family {
        case .systemSmall:
            GoalsWidgetSmallView(entry: entry)
        case .systemMedium:
            GoalsWidgetMediumView(entry: entry)
        case .systemLarge:
            GoalsWidgetLargeView(entry: entry)
        default:
            GoalsWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    GoalsWidget()
} timeline: {
    GoalsEntry(date: Date(), data: GoalsWidgetData.placeholder)
}

#Preview(as: .systemMedium) {
    GoalsWidget()
} timeline: {
    GoalsEntry(date: Date(), data: GoalsWidgetData.placeholder)
}

#Preview(as: .systemLarge) {
    GoalsWidget()
} timeline: {
    GoalsEntry(date: Date(), data: GoalsWidgetData.placeholder)
}
