import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct WaterLogProvider: TimelineProvider {
    func placeholder(in context: Context) -> WaterLogEntry {
        WaterLogEntry(date: Date(), data: WaterWidgetData.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (WaterLogEntry) -> Void) {
        let entry = WaterLogEntry(date: Date(), data: WidgetDataProvider.shared.getWaterData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WaterLogEntry>) -> Void) {
        let currentDate = Date()
        let entry = WaterLogEntry(date: currentDate, data: WidgetDataProvider.shared.getWaterData())

        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct WaterLogEntry: TimelineEntry {
    let date: Date
    let data: WaterWidgetData
}

// MARK: - Widget Views

struct WaterLogWidgetSmallView: View {
    let entry: WaterLogEntry

    var body: some View {
        SmallWidgetView {
            VStack(spacing: 8) {
                // Droplet progress
                WaterDropletProgress(percent: entry.data.percent, size: 50)

                // Quick add button
                Link(destination: WidgetDeepLinks.addWater(amount: 250) ?? URL(string: "aifitnesscoach://hydration")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.caption2.weight(.bold))
                        Text("250ml")
                            .font(.caption2.weight(.semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(WidgetGradients.water)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
            }
        }
    }
}

struct WaterLogWidgetMediumView: View {
    let entry: WaterLogEntry

    var body: some View {
        MediumWidgetView {
            HStack(spacing: 16) {
                // Left - Progress
                VStack(spacing: 8) {
                    WaterDropletProgress(percent: entry.data.percent, size: 45)

                    Text("\(entry.data.currentMl) / \(entry.data.goalMl)ml")
                        .font(.caption)
                        .foregroundColor(.widgetText.opacity(0.7))
                }
                .frame(width: 80)

                // Right - Quick add buttons
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Add")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.widgetText.opacity(0.7))

                    HStack(spacing: 8) {
                        WaterQuickAddButton(amount: 250)
                        WaterQuickAddButton(amount: 500)
                        WaterQuickAddButton(amount: 750)
                        WaterQuickAddButton(amount: 1000, label: "1L")
                    }
                }
            }
        }
    }
}

struct WaterLogWidgetLargeView: View {
    let entry: WaterLogEntry

    var body: some View {
        LargeWidgetView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(WidgetGradients.water)
                    Text("Hydration")
                        .font(.headline)
                        .foregroundColor(.widgetText.opacity(0.7))
                    Spacer()
                }

                // Main progress
                HStack(spacing: 24) {
                    // Large droplet
                    WaterDropletProgress(percent: entry.data.percent, size: 80)

                    // Stats
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(entry.data.currentMl)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.widgetText)
                            Text("of \(entry.data.goalMl)ml goal")
                                .font(.subheadline)
                                .foregroundColor(.widgetText.opacity(0.7))
                        }

                        Text("\(entry.data.goalMl - entry.data.currentMl)ml to go")
                            .font(.caption)
                            .foregroundColor(.widgetSecondary)
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // Quick add section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Add")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.widgetText.opacity(0.7))

                    HStack(spacing: 12) {
                        WaterQuickAddButton(amount: 250, style: .large)
                        WaterQuickAddButton(amount: 500, style: .large)
                        WaterQuickAddButton(amount: 750, style: .large)
                        WaterQuickAddButton(amount: 1000, label: "1L", style: .large)
                    }
                }

                Spacer()

                // Drink type selector placeholder
                VStack(alignment: .leading, spacing: 8) {
                    Text("Drink Type")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.widgetText.opacity(0.7))

                    HStack(spacing: 12) {
                        DrinkTypeButton(icon: "drop.fill", label: "Water", isSelected: true)
                        DrinkTypeButton(icon: "cup.and.saucer.fill", label: "Coffee", isSelected: false)
                        DrinkTypeButton(icon: "leaf.fill", label: "Tea", isSelected: false)
                        DrinkTypeButton(icon: "bolt.fill", label: "Sports", isSelected: false)
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views

struct WaterQuickAddButton: View {
    let amount: Int
    var label: String? = nil
    var style: ButtonStyle = .small

    enum ButtonStyle {
        case small, large
    }

    var body: some View {
        Link(destination: WidgetDeepLinks.addWater(amount: amount) ?? URL(string: "aifitnesscoach://hydration")!) {
            VStack(spacing: 2) {
                Text("+")
                    .font(.system(size: style == .large ? 14 : 10, weight: .bold))
                Text(label ?? "\(amount)ml")
                    .font(.system(size: style == .large ? 12 : 10, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, style == .large ? 12 : 8)
            .background(Color.white.opacity(0.15))
            .foregroundColor(.widgetText)
            .clipShape(RoundedRectangle(cornerRadius: style == .large ? 12 : 8))
        }
    }
}

struct DrinkTypeButton: View {
    let icon: String
    let label: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isSelected ? .white : .widgetText.opacity(0.5))
                .frame(width: 40, height: 40)
                .background(isSelected ? WidgetGradients.water : Color.white.opacity(0.1))
                .clipShape(Circle())

            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.widgetText.opacity(0.7))
        }
    }
}

// MARK: - Widget Configuration

struct WaterLogWidget: Widget {
    let kind: String = "WaterLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WaterLogProvider()) { entry in
            WaterLogWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quick Water Log")
        .description("Track your hydration with quick-add buttons.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct WaterLogWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WaterLogEntry

    var body: some View {
        switch family {
        case .systemSmall:
            WaterLogWidgetSmallView(entry: entry)
        case .systemMedium:
            WaterLogWidgetMediumView(entry: entry)
        case .systemLarge:
            WaterLogWidgetLargeView(entry: entry)
        default:
            WaterLogWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    WaterLogWidget()
} timeline: {
    WaterLogEntry(date: Date(), data: WaterWidgetData.placeholder)
}

#Preview(as: .systemMedium) {
    WaterLogWidget()
} timeline: {
    WaterLogEntry(date: Date(), data: WaterWidgetData.placeholder)
}

#Preview(as: .systemLarge) {
    WaterLogWidget()
} timeline: {
    WaterLogEntry(date: Date(), data: WaterWidgetData.placeholder)
}
