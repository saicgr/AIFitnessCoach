import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct AICoachProvider: TimelineProvider {
    func placeholder(in context: Context) -> AICoachEntry {
        AICoachEntry(date: Date(), data: AICoachWidgetData.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (AICoachEntry) -> Void) {
        let entry = AICoachEntry(date: Date(), data: WidgetDataProvider.shared.getAICoachData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AICoachEntry>) -> Void) {
        let currentDate = Date()
        let entry = AICoachEntry(date: currentDate, data: WidgetDataProvider.shared.getAICoachData())

        // Refresh every 2 hours
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct AICoachEntry: TimelineEntry {
    let date: Date
    let data: AICoachWidgetData
}

// MARK: - Widget Views

struct AICoachWidgetSmallView: View {
    let entry: AICoachEntry

    var body: some View {
        SmallWidgetView {
            VStack(spacing: 12) {
                // Circular avatar with gradient border
                ZStack {
                    // Pulsing background
                    Circle()
                        .fill(WidgetGradients.primary.opacity(0.2))
                        .frame(width: 60, height: 60)

                    // Gradient border
                    Circle()
                        .strokeBorder(WidgetGradients.primary, lineWidth: 3)
                        .frame(width: 54, height: 54)

                    // AI icon
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundStyle(WidgetGradients.primary)
                }

                // Ask button
                Link(destination: WidgetDeepLinks.chat() ?? URL(string: "aifitnesscoach://chat")!) {
                    Text("Ask Coach")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(WidgetGradients.primary)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

struct AICoachWidgetMediumView: View {
    let entry: AICoachEntry

    var body: some View {
        MediumWidgetView {
            HStack(spacing: 16) {
                // Left - AI avatar
                ZStack {
                    Circle()
                        .fill(WidgetGradients.primary.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Circle()
                        .strokeBorder(WidgetGradients.primary, lineWidth: 2)
                        .frame(width: 46, height: 46)

                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundStyle(WidgetGradients.primary)
                }

                // Right - Quick prompts
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Coach")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.widgetText.opacity(0.7))

                    HStack(spacing: 6) {
                        QuickPromptLink(icon: "dumbbell.fill", label: "Workout", prompt: "Give me workout tips")
                        QuickPromptLink(icon: "fork.knife", label: "Nutrition", prompt: "What should I eat?")
                        QuickPromptLink(icon: "flame.fill", label: "Motivate", prompt: "I need motivation")
                    }
                }

                Spacer()
            }
        }
    }
}

struct AICoachWidgetLargeView: View {
    let entry: AICoachEntry

    var body: some View {
        LargeWidgetView {
            VStack(spacing: 16) {
                // Header with avatar
                HStack {
                    ZStack {
                        Circle()
                            .fill(WidgetGradients.primary.opacity(0.2))
                            .frame(width: 44, height: 44)

                        Circle()
                            .strokeBorder(WidgetGradients.primary, lineWidth: 2)
                            .frame(width: 40, height: 40)

                        Image(systemName: "brain.head.profile")
                            .font(.title3)
                            .foregroundStyle(WidgetGradients.primary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Coach")
                            .font(.headline)
                            .foregroundColor(.widgetText)
                        Text("Your personal fitness assistant")
                            .font(.caption)
                            .foregroundColor(.widgetText.opacity(0.7))
                    }

                    Spacer()
                }

                // Quick prompt buttons
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Actions")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.widgetText.opacity(0.7))

                    ForEach(entry.data.quickPrompts, id: \.self) { prompt in
                        Link(destination: WidgetDeepLinks.chat(prompt: prompt) ?? URL(string: "aifitnesscoach://chat")!) {
                            HStack {
                                Image(systemName: iconForPrompt(prompt))
                                    .foregroundStyle(WidgetGradients.primary)
                                    .frame(width: 24)

                                Text(prompt)
                                    .font(.subheadline)
                                    .foregroundColor(.widgetText)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.widgetText.opacity(0.4))
                            }
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // Agent shortcuts
                VStack(alignment: .leading, spacing: 8) {
                    Text("Specialized Agents")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.widgetText.opacity(0.7))

                    HStack(spacing: 12) {
                        AgentButton(icon: "figure.run", label: "Coach", agent: "coach", color: .widgetPrimary)
                        AgentButton(icon: "fork.knife", label: "Nutrition", agent: "nutrition", color: .green)
                        AgentButton(icon: "dumbbell.fill", label: "Workout", agent: "workout", color: .orange)
                        AgentButton(icon: "bandage.fill", label: "Injury", agent: "injury", color: .red)
                        AgentButton(icon: "drop.fill", label: "Hydration", agent: "hydration", color: .blue)
                    }
                }

                Spacer()

                // Last message preview
                if !entry.data.lastMessagePreview.isEmpty {
                    HStack {
                        Image(systemName: "text.bubble.fill")
                            .foregroundColor(.widgetText.opacity(0.4))
                        Text(entry.data.lastMessagePreview)
                            .font(.caption)
                            .foregroundColor(.widgetText.opacity(0.6))
                            .lineLimit(1)
                    }
                }

                // Open chat button
                Link(destination: WidgetDeepLinks.chat() ?? URL(string: "aifitnesscoach://chat")!) {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Open Chat")
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(WidgetGradients.primary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    func iconForPrompt(_ prompt: String) -> String {
        let lowercased = prompt.lowercased()
        if lowercased.contains("eat") || lowercased.contains("food") || lowercased.contains("nutrition") {
            return "fork.knife"
        } else if lowercased.contains("workout") || lowercased.contains("exercise") {
            return "dumbbell.fill"
        } else if lowercased.contains("tired") || lowercased.contains("motivation") {
            return "flame.fill"
        } else if lowercased.contains("water") || lowercased.contains("hydration") {
            return "drop.fill"
        } else if lowercased.contains("progress") {
            return "chart.line.uptrend.xyaxis"
        }
        return "bubble.left.fill"
    }
}

// MARK: - Helper Views

struct QuickPromptLink: View {
    let icon: String
    let label: String
    let prompt: String

    var body: some View {
        Link(destination: WidgetDeepLinks.chat(prompt: prompt) ?? URL(string: "aifitnesscoach://chat")!) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.system(size: 9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.15))
            .foregroundColor(.widgetText)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct AgentButton: View {
    let icon: String
    let label: String
    let agent: String
    let color: Color

    var body: some View {
        Link(destination: WidgetDeepLinks.chat(agent: agent) ?? URL(string: "aifitnesscoach://chat")!) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .frame(width: 32, height: 32)
                    .background(color)
                    .foregroundColor(.white)
                    .clipShape(Circle())

                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.widgetText.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Widget Configuration

struct AICoachWidget: Widget {
    let kind: String = "AICoachWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AICoachProvider()) { entry in
            AICoachWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("AI Coach Chat")
        .description("Quick access to your AI fitness coach with smart prompts.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct AICoachWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: AICoachEntry

    var body: some View {
        switch family {
        case .systemSmall:
            AICoachWidgetSmallView(entry: entry)
        case .systemMedium:
            AICoachWidgetMediumView(entry: entry)
        case .systemLarge:
            AICoachWidgetLargeView(entry: entry)
        default:
            AICoachWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    AICoachWidget()
} timeline: {
    AICoachEntry(date: Date(), data: AICoachWidgetData.placeholder)
}

#Preview(as: .systemMedium) {
    AICoachWidget()
} timeline: {
    AICoachEntry(date: Date(), data: AICoachWidgetData.placeholder)
}

#Preview(as: .systemLarge) {
    AICoachWidget()
} timeline: {
    AICoachEntry(date: Date(), data: AICoachWidgetData.placeholder)
}
