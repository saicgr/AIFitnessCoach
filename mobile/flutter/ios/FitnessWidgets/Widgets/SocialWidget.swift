import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct SocialProvider: TimelineProvider {
    func placeholder(in context: Context) -> SocialEntry {
        SocialEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SocialEntry) -> Void) {
        let entry = SocialEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SocialEntry>) -> Void) {
        let currentDate = Date()
        let entry = SocialEntry(date: currentDate)

        // Refresh every 2 hours
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct SocialEntry: TimelineEntry {
    let date: Date
}

// MARK: - Widget Views

struct SocialWidgetSmallView: View {
    let entry: SocialEntry

    var body: some View {
        SmallWidgetView {
            VStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.title)
                    .foregroundStyle(WidgetGradients.primary)

                Link(destination: WidgetDeepLinks.shareWorkout() ?? URL(string: "aifitnesscoach://social")!) {
                    Text("Share Workout")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(WidgetGradients.primary)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

struct SocialWidgetMediumView: View {
    let entry: SocialEntry

    var body: some View {
        MediumWidgetView {
            HStack(spacing: 16) {
                // Left - Icon
                VStack {
                    Image(systemName: "person.2.fill")
                        .font(.title)
                        .foregroundStyle(WidgetGradients.primary)
                    Text("Share")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.widgetText.opacity(0.7))
                }
                .frame(width: 60)

                // Right - Share options
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        ShareOptionButton(icon: "dumbbell.fill", label: "Workout", type: "workout")
                        ShareOptionButton(icon: "trophy.fill", label: "Achievement", type: "achievement")
                        ShareOptionButton(icon: "camera.fill", label: "Progress", type: "progress")
                    }
                }
            }
        }
    }
}

struct SocialWidgetLargeView: View {
    let entry: SocialEntry

    var body: some View {
        LargeWidgetView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(WidgetGradients.primary)
                    Text("Social")
                        .font(.headline)
                        .foregroundColor(.widgetText.opacity(0.7))
                    Spacer()
                }

                // Share options
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Share")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.widgetText.opacity(0.7))

                    HStack(spacing: 12) {
                        LargeShareButton(icon: "dumbbell.fill", label: "Share\nWorkout", color: .widgetPrimary, type: "workout")
                        LargeShareButton(icon: "trophy.fill", label: "Share\nAchievement", color: .yellow, type: "achievement")
                        LargeShareButton(icon: "camera.fill", label: "Progress\nPhoto", color: .widgetSecondary, type: "progress")
                        LargeShareButton(icon: "text.bubble.fill", label: "Quick\nUpdate", color: .widgetAccent, type: "update")
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // Activity feed preview placeholder
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Activity")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.widgetText.opacity(0.7))

                    VStack(spacing: 8) {
                        ActivityPreviewRow(name: "Sarah", action: "completed Upper Body", time: "2h ago")
                        ActivityPreviewRow(name: "Mike", action: "earned Week Warrior", time: "4h ago")
                        ActivityPreviewRow(name: "You", action: "hit a new PR!", time: "Yesterday")
                    }
                }

                Spacer()

                // View all button
                Link(destination: WidgetDeepLinks.social ?? URL(string: "aifitnesscoach://social")!) {
                    Text("View All Activity")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.widgetText)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

// MARK: - Helper Views

struct ShareOptionButton: View {
    let icon: String
    let label: String
    let type: String

    var body: some View {
        Link(destination: URL(string: "aifitnesscoach://social/share?type=\(type)") ?? URL(string: "aifitnesscoach://social")!) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.system(size: 10))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.15))
            .foregroundColor(.widgetText)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct LargeShareButton: View {
    let icon: String
    let label: String
    let color: Color
    let type: String

    var body: some View {
        Link(destination: URL(string: "aifitnesscoach://social/share?type=\(type)") ?? URL(string: "aifitnesscoach://social")!) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .foregroundColor(.white)
                    .clipShape(Circle())

                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.widgetText.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct ActivityPreviewRow: View {
    let name: String
    let action: String
    let time: String

    var body: some View {
        HStack {
            Circle()
                .fill(WidgetGradients.primary)
                .frame(width: 28, height: 28)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("\(name) \(action)")
                    .font(.caption)
                    .foregroundColor(.widgetText)
                    .lineLimit(1)
                Text(time)
                    .font(.system(size: 10))
                    .foregroundColor(.widgetText.opacity(0.5))
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Widget Configuration

struct SocialWidget: Widget {
    let kind: String = "SocialWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SocialProvider()) { entry in
            SocialWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quick Social Post")
        .description("Share workouts, achievements, and progress with friends.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct SocialWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: SocialEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SocialWidgetSmallView(entry: entry)
        case .systemMedium:
            SocialWidgetMediumView(entry: entry)
        case .systemLarge:
            SocialWidgetLargeView(entry: entry)
        default:
            SocialWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    SocialWidget()
} timeline: {
    SocialEntry(date: Date())
}

#Preview(as: .systemMedium) {
    SocialWidget()
} timeline: {
    SocialEntry(date: Date())
}

#Preview(as: .systemLarge) {
    SocialWidget()
} timeline: {
    SocialEntry(date: Date())
}
