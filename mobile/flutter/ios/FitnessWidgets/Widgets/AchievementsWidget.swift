import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct AchievementsProvider: TimelineProvider {
    func placeholder(in context: Context) -> AchievementsEntry {
        AchievementsEntry(date: Date(), data: AchievementsWidgetData.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (AchievementsEntry) -> Void) {
        let entry = AchievementsEntry(date: Date(), data: WidgetDataProvider.shared.getAchievementsData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AchievementsEntry>) -> Void) {
        let currentDate = Date()
        let entry = AchievementsEntry(date: currentDate, data: WidgetDataProvider.shared.getAchievementsData())

        // Refresh daily
        let tomorrow = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!)
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct AchievementsEntry: TimelineEntry {
    let date: Date
    let data: AchievementsWidgetData
}

// MARK: - Widget Views

struct AchievementsWidgetSmallView: View {
    let entry: AchievementsEntry

    var body: some View {
        SmallWidgetView {
            VStack(spacing: 8) {
                if let latest = entry.data.achievements.first {
                    // Badge icon
                    Image(systemName: latest.icon)
                        .font(.system(size: 36))
                        .foregroundStyle(WidgetGradients.achievement)
                        .shadow(color: .yellow.opacity(0.5), radius: 8, y: 4)

                    // Badge name
                    Text(latest.name)
                        .font(.caption.weight(.bold))
                        .foregroundColor(.widgetText)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    Text("Latest Badge")
                        .font(.system(size: 9))
                        .foregroundColor(.widgetText.opacity(0.6))
                } else {
                    Image(systemName: "star")
                        .font(.title)
                        .foregroundColor(.widgetText.opacity(0.3))
                    Text("No Badges Yet")
                        .font(.caption)
                        .foregroundColor(.widgetText.opacity(0.7))
                }
            }
        }
        .widgetURL(WidgetDeepLinks.achievements)
    }
}

struct AchievementsWidgetMediumView: View {
    let entry: AchievementsEntry

    var body: some View {
        MediumWidgetView {
            HStack(spacing: 16) {
                // Left - Points
                VStack(spacing: 4) {
                    Text("\(entry.data.totalPoints)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.widgetText)
                    Text("Points")
                        .font(.caption)
                        .foregroundColor(.widgetText.opacity(0.7))
                }
                .frame(width: 70)

                // Right - Recent badges
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Badges")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.widgetText.opacity(0.7))

                    HStack(spacing: 12) {
                        ForEach(entry.data.achievements.prefix(3), id: \.id) { achievement in
                            VStack(spacing: 4) {
                                Image(systemName: achievement.icon)
                                    .font(.title2)
                                    .foregroundStyle(WidgetGradients.achievement)
                                Text(achievement.name)
                                    .font(.system(size: 9))
                                    .foregroundColor(.widgetText.opacity(0.7))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .widgetURL(WidgetDeepLinks.achievements)
    }
}

struct AchievementsWidgetLargeView: View {
    let entry: AchievementsEntry

    var body: some View {
        LargeWidgetView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(WidgetGradients.achievement)
                    Text("Achievements")
                        .font(.headline)
                        .foregroundColor(.widgetText.opacity(0.7))
                    Spacer()
                    Text("\(entry.data.totalPoints) pts")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.yellow)
                }

                // Badge showcase
                HStack(spacing: 16) {
                    ForEach(entry.data.achievements.prefix(3), id: \.id) { achievement in
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(WidgetGradients.achievement)
                                    .frame(width: 56, height: 56)
                                    .shadow(color: .yellow.opacity(0.3), radius: 8, y: 4)

                                Image(systemName: achievement.icon)
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }

                            Text(achievement.name)
                                .font(.caption)
                                .foregroundColor(.widgetText)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // Next milestone
                if !entry.data.nextMilestone.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Next Milestone")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.widgetText.opacity(0.7))
                            Spacer()
                            Text("\(entry.data.progressToNext)%")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.widgetSecondary)
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.title2)
                                .foregroundColor(.widgetText.opacity(0.4))
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.data.nextMilestone)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.widgetText)

                                // Progress bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white.opacity(0.2))
                                            .frame(height: 6)

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(WidgetGradients.achievement)
                                            .frame(width: geometry.size.width * CGFloat(entry.data.progressToNext) / 100, height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }
                        }
                    }
                }

                Spacer()

                // View all button
                Link(destination: WidgetDeepLinks.achievements ?? URL(string: "aifitnesscoach://achievements")!) {
                    Text("View All Badges")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(WidgetGradients.achievement)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

// MARK: - Widget Configuration

struct AchievementsWidget: Widget {
    let kind: String = "AchievementsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AchievementsProvider()) { entry in
            AchievementsWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Achievements")
        .description("Showcase your fitness badges and milestones.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct AchievementsWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: AchievementsEntry

    var body: some View {
        switch family {
        case .systemSmall:
            AchievementsWidgetSmallView(entry: entry)
        case .systemMedium:
            AchievementsWidgetMediumView(entry: entry)
        case .systemLarge:
            AchievementsWidgetLargeView(entry: entry)
        default:
            AchievementsWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    AchievementsWidget()
} timeline: {
    AchievementsEntry(date: Date(), data: AchievementsWidgetData.placeholder)
}

#Preview(as: .systemMedium) {
    AchievementsWidget()
} timeline: {
    AchievementsEntry(date: Date(), data: AchievementsWidgetData.placeholder)
}

#Preview(as: .systemLarge) {
    AchievementsWidget()
} timeline: {
    AchievementsEntry(date: Date(), data: AchievementsWidgetData.placeholder)
}
