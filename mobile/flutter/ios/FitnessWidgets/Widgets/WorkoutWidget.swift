import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct WorkoutProvider: TimelineProvider {
    func placeholder(in context: Context) -> WorkoutEntry {
        WorkoutEntry(date: Date(), data: WorkoutWidgetData.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (WorkoutEntry) -> Void) {
        let entry = WorkoutEntry(date: Date(), data: WidgetDataProvider.shared.getWorkoutData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkoutEntry>) -> Void) {
        let currentDate = Date()
        let entry = WorkoutEntry(date: currentDate, data: WidgetDataProvider.shared.getWorkoutData())

        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct WorkoutEntry: TimelineEntry {
    let date: Date
    let data: WorkoutWidgetData
}

// MARK: - Widget Views

struct WorkoutWidgetSmallView: View {
    let entry: WorkoutEntry

    var body: some View {
        SmallWidgetView {
            VStack(spacing: 8) {
                if entry.data.isRestDay {
                    Image(systemName: "bed.double.fill")
                        .font(.title)
                        .foregroundStyle(WidgetGradients.primary)

                    Text("Rest Day")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.widgetText)

                    Text("Recovery time")
                        .font(.caption)
                        .foregroundColor(.widgetText.opacity(0.7))
                } else {
                    Image(systemName: "dumbbell.fill")
                        .font(.title2)
                        .foregroundStyle(WidgetGradients.primary)

                    Text(entry.data.name)
                        .font(.caption.weight(.bold))
                        .foregroundColor(.widgetText)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    PillButton(title: "Start", icon: "play.fill")
                }
            }
        }
        .widgetURL(WidgetDeepLinks.workout(id: entry.data.id))
    }
}

struct WorkoutWidgetMediumView: View {
    let entry: WorkoutEntry

    var body: some View {
        MediumWidgetView {
            HStack(spacing: 16) {
                // Left side - Icon and name
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: entry.data.isRestDay ? "bed.double.fill" : "dumbbell.fill")
                            .font(.title2)
                            .foregroundStyle(WidgetGradients.primary)

                        Spacer()
                    }

                    Text(entry.data.isRestDay ? "Rest Day" : entry.data.name)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.widgetText)
                        .lineLimit(2)

                    if !entry.data.isRestDay {
                        Text(entry.data.muscleGroup)
                            .font(.caption)
                            .foregroundColor(.widgetText.opacity(0.7))
                    }
                }

                Spacer()

                // Right side - Stats and button
                if entry.data.isRestDay {
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("Take time to recover")
                            .font(.caption)
                            .foregroundColor(.widgetText.opacity(0.7))
                            .multilineTextAlignment(.trailing)

                        Image(systemName: "moon.stars.fill")
                            .font(.title)
                            .foregroundColor(.widgetSecondary)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 8) {
                        HStack(spacing: 12) {
                            StatPill(value: "\(entry.data.duration)", label: "min", icon: "clock")
                            StatPill(value: "\(entry.data.exerciseCount)", label: "exercises")
                        }

                        PillButton(title: "Start Workout", icon: "play.fill")
                    }
                }
            }
        }
        .widgetURL(WidgetDeepLinks.workout(id: entry.data.id))
    }
}

struct WorkoutWidgetLargeView: View {
    let entry: WorkoutEntry

    var body: some View {
        LargeWidgetView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: entry.data.isRestDay ? "bed.double.fill" : "dumbbell.fill")
                        .font(.title2)
                        .foregroundStyle(WidgetGradients.primary)

                    Text("Today's Workout")
                        .font(.headline)
                        .foregroundColor(.widgetText.opacity(0.7))

                    Spacer()
                }

                // Title
                Text(entry.data.isRestDay ? "Rest Day" : entry.data.name)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.widgetText)

                if entry.data.isRestDay {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(WidgetGradients.primary)

                        Text("Your body needs time to recover and grow stronger.")
                            .font(.body)
                            .foregroundColor(.widgetText.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    // Stats row
                    HStack(spacing: 20) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .foregroundColor(.widgetSecondary)
                            Text("\(entry.data.duration) min")
                                .foregroundColor(.widgetText)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .foregroundColor(.widgetSecondary)
                            Text("\(entry.data.exerciseCount) exercises")
                                .foregroundColor(.widgetText)
                        }
                    }
                    .font(.subheadline)

                    // Muscle groups
                    Text(entry.data.muscleGroup)
                        .font(.subheadline)
                        .foregroundColor(.widgetText.opacity(0.7))

                    Spacer()

                    // Preview placeholder
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 80)
                        .overlay(
                            Text("Exercise Preview")
                                .font(.caption)
                                .foregroundColor(.widgetText.opacity(0.5))
                        )

                    Spacer()

                    // Start button
                    HStack {
                        Spacer()
                        Link(destination: WidgetDeepLinks.startWorkout(id: entry.data.id ?? "") ?? URL(string: "aifitnesscoach://workout")!) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start Workout")
                            }
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(WidgetGradients.primary)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}

// MARK: - Widget Configuration

struct WorkoutWidget: Widget {
    let kind: String = "WorkoutWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkoutProvider()) { entry in
            WorkoutWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Workout")
        .description("View and start your scheduled workout for today.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct WorkoutWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WorkoutEntry

    var body: some View {
        switch family {
        case .systemSmall:
            WorkoutWidgetSmallView(entry: entry)
        case .systemMedium:
            WorkoutWidgetMediumView(entry: entry)
        case .systemLarge:
            WorkoutWidgetLargeView(entry: entry)
        default:
            WorkoutWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    WorkoutWidget()
} timeline: {
    WorkoutEntry(date: Date(), data: WorkoutWidgetData.placeholder)
}

#Preview(as: .systemMedium) {
    WorkoutWidget()
} timeline: {
    WorkoutEntry(date: Date(), data: WorkoutWidgetData.placeholder)
}

#Preview(as: .systemLarge) {
    WorkoutWidget()
} timeline: {
    WorkoutEntry(date: Date(), data: WorkoutWidgetData.placeholder)
}
