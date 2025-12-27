import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct ChallengesProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChallengesEntry {
        ChallengesEntry(date: Date(), data: ChallengesWidgetData.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (ChallengesEntry) -> Void) {
        let entry = ChallengesEntry(date: Date(), data: WidgetDataProvider.shared.getChallengesData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChallengesEntry>) -> Void) {
        let currentDate = Date()
        let entry = ChallengesEntry(date: currentDate, data: WidgetDataProvider.shared.getChallengesData())

        // Refresh every 2 hours
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct ChallengesEntry: TimelineEntry {
    let date: Date
    let data: ChallengesWidgetData
}

// MARK: - Widget Views

struct ChallengesWidgetSmallView: View {
    let entry: ChallengesEntry

    var body: some View {
        SmallWidgetView {
            VStack(spacing: 8) {
                // Challenge icon with badge
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(WidgetGradients.achievement)

                    if entry.data.count > 0 {
                        Text("\(entry.data.count)")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Circle().fill(.red))
                            .offset(x: 8, y: -4)
                    }
                }

                Text(entry.data.count > 0 ? "\(entry.data.count) Active" : "No Challenges")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.widgetText)

                if let first = entry.data.challenges.first {
                    Text(first.isLeading ? "You're winning!" : "Catch up!")
                        .font(.caption2)
                        .foregroundColor(first.isLeading ? .green : .orange)
                }
            }
        }
        .widgetURL(WidgetDeepLinks.challenges)
    }
}

struct ChallengesWidgetMediumView: View {
    let entry: ChallengesEntry

    var body: some View {
        MediumWidgetView {
            if let challenge = entry.data.challenges.first {
                HStack(spacing: 16) {
                    // Left - Trophy and status
                    VStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.title)
                            .foregroundStyle(WidgetGradients.achievement)

                        Text(challenge.isLeading ? "Leading" : "Behind")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(challenge.isLeading ? .green : .orange)
                    }
                    .frame(width: 60)

                    // Right - Challenge details
                    VStack(alignment: .leading, spacing: 6) {
                        Text(challenge.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.widgetText)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("You")
                                    .font(.caption2)
                                    .foregroundColor(.widgetText.opacity(0.6))
                                Text("\(challenge.yourScore)")
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(.widgetText)
                            }

                            Text("vs")
                                .font(.caption)
                                .foregroundColor(.widgetText.opacity(0.5))

                            VStack(alignment: .trailing) {
                                Text(challenge.opponentName)
                                    .font(.caption2)
                                    .foregroundColor(.widgetText.opacity(0.6))
                                Text("\(challenge.opponentScore)")
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(.widgetText)
                            }
                        }
                    }

                    Spacer()
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.title)
                        .foregroundColor(.widgetText.opacity(0.5))
                    Text("No Active Challenges")
                        .font(.subheadline)
                        .foregroundColor(.widgetText.opacity(0.7))
                    Text("Challenge a friend!")
                        .font(.caption)
                        .foregroundColor(.widgetSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .widgetURL(WidgetDeepLinks.challenges)
    }
}

struct ChallengesWidgetLargeView: View {
    let entry: ChallengesEntry

    var body: some View {
        LargeWidgetView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(WidgetGradients.achievement)
                    Text("Active Challenges")
                        .font(.headline)
                        .foregroundColor(.widgetText.opacity(0.7))
                    Spacer()
                    if entry.data.count > 0 {
                        Text("\(entry.data.count)")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(.red))
                    }
                }

                if entry.data.challenges.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "trophy")
                            .font(.system(size: 50))
                            .foregroundColor(.widgetText.opacity(0.3))
                        Text("No Active Challenges")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.widgetText.opacity(0.7))
                        Text("Challenge your friends to stay motivated!")
                            .font(.caption)
                            .foregroundColor(.widgetText.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    // Challenge list
                    ForEach(entry.data.challenges.prefix(3), id: \.id) { challenge in
                        ChallengeRow(challenge: challenge)
                    }

                    Spacer()

                    // View all button
                    Link(destination: WidgetDeepLinks.challenges ?? URL(string: "aifitnesscoach://challenges")!) {
                        Text("View All Challenges")
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
}

// MARK: - Helper Views

struct ChallengeRow: View {
    let challenge: ChallengeItem

    var body: some View {
        HStack {
            // Status indicator
            Circle()
                .fill(challenge.isLeading ? Color.green : Color.orange)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.widgetText)
                Text("vs \(challenge.opponentName)")
                    .font(.system(size: 10))
                    .foregroundColor(.widgetText.opacity(0.6))
            }

            Spacer()

            // Score
            HStack(spacing: 8) {
                Text("\(challenge.yourScore)")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(challenge.isLeading ? .green : .widgetText)
                Text("-")
                    .foregroundColor(.widgetText.opacity(0.5))
                Text("\(challenge.opponentScore)")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(challenge.isLeading ? .widgetText : .orange)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Widget Configuration

struct ChallengesWidget: Widget {
    let kind: String = "ChallengesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChallengesProvider()) { entry in
            ChallengesWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Active Challenges")
        .description("Track your fitness challenges with friends.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ChallengesWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: ChallengesEntry

    var body: some View {
        switch family {
        case .systemSmall:
            ChallengesWidgetSmallView(entry: entry)
        case .systemMedium:
            ChallengesWidgetMediumView(entry: entry)
        case .systemLarge:
            ChallengesWidgetLargeView(entry: entry)
        default:
            ChallengesWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    ChallengesWidget()
} timeline: {
    ChallengesEntry(date: Date(), data: ChallengesWidgetData.placeholder)
}

#Preview(as: .systemMedium) {
    ChallengesWidget()
} timeline: {
    ChallengesEntry(date: Date(), data: ChallengesWidgetData.placeholder)
}

#Preview(as: .systemLarge) {
    ChallengesWidget()
} timeline: {
    ChallengesEntry(date: Date(), data: ChallengesWidgetData.placeholder)
}
