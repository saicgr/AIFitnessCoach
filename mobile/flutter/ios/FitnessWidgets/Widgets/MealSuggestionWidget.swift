// One-tap meal suggestion widget.
//
// Shown on the home screen + lock screen. Renders a structured meal idea
// populated by the Flutter MealSuggestionWidgetService via shared
// UserDefaults (app group: group.com.aifitnesscoach.widgets, key:
// meal_suggestion_json).
//
// Three tap targets:
//   • Whole widget surface  → opens app to nutrition chat with the prompt
//     pre-filled ("What should I eat right now?") so the user can see the
//     full reasoning + ask follow-ups.
//   • "Log it" button       → app opens briefly, logs the suggested meal,
//     widget refreshes to the next slot.
//   • "Refresh" button      → app opens briefly, fetches a new suggestion,
//     widget rerenders.
//
// For iOS 17+ we could convert the buttons to AppIntents so no app-open is
// required. Kept as URL-based Links for v1 to support iOS 14+ with zero
// extra target / provisioning setup; a future PR can add interactive
// intents for a seamless-no-app-open UX.

import WidgetKit
import SwiftUI

// MARK: - Deep link targets (widget → app)

private enum MealSuggestionDeepLinks {
    static func openChat() -> URL {
        URL(string: "fitwiz://chat/suggest-food")!
    }

    static func refresh() -> URL {
        URL(string: "fitwiz://chat/suggest-food?source=widget&action=refresh")!
    }

    static func logIt() -> URL {
        URL(string: "fitwiz://nutrition/widget-log?source=widget")!
    }
}

// MARK: - Timeline Provider

struct MealSuggestionProvider: TimelineProvider {
    func placeholder(in context: Context) -> MealSuggestionEntry {
        MealSuggestionEntry(date: Date(), data: MealSuggestionWidgetData.samplePlaceholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (MealSuggestionEntry) -> Void) {
        // Snapshot is used for widget gallery previews — show the sample so
        // users see what the widget will actually look like once populated.
        let data = context.isPreview
            ? MealSuggestionWidgetData.samplePlaceholder
            : WidgetDataProvider.shared.getMealSuggestionData()
        completion(MealSuggestionEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MealSuggestionEntry>) -> Void) {
        let now = Date()
        let entry = MealSuggestionEntry(
            date: now,
            data: WidgetDataProvider.shared.getMealSuggestionData()
        )
        // Reload every 30 min. The Flutter app also pushes fresh data on
        // resume + after every logged meal, which triggers a sooner reload
        // via HomeWidget.updateWidget — this .after policy is the floor.
        let nextReload = Calendar.current.date(byAdding: .minute, value: 30, to: now)!
        completion(Timeline(entries: [entry], policy: .after(nextReload)))
    }
}

struct MealSuggestionEntry: TimelineEntry {
    let date: Date
    let data: MealSuggestionWidgetData
}

// MARK: - Small family (glanceable)

struct MealSuggestionSmallView: View {
    let entry: MealSuggestionEntry

    var body: some View {
        Link(destination: MealSuggestionDeepLinks.openChat()) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.data.emoji)
                        .font(.system(size: 26))
                    Spacer()
                    if entry.data.stale {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.caption2)
                            .foregroundColor(.yellow.opacity(0.8))
                    }
                }
                Spacer(minLength: 2)
                Text(entry.data.isSignedOut ? entry.data.title : slotHeadline(entry.data.mealSlot))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.75))
                Text(entry.data.isSignedOut ? entry.data.subtitle : entry.data.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                if !entry.data.isSignedOut {
                    Text("\(entry.data.calories) cal")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(10)
        }
    }

    private func slotHeadline(_ slot: String) -> String {
        switch slot {
        case "breakfast": return "Breakfast idea"
        case "lunch":     return "Lunch idea"
        case "dinner":    return "Dinner idea"
        case "snack":     return "Snack idea"
        case "fasting":   return "Fasting"
        default:          return "Meal idea"
        }
    }
}

// MARK: - Medium family (the main surface)

struct MealSuggestionMediumView: View {
    let entry: MealSuggestionEntry

    var body: some View {
        ZStack {
            // Whole-card tap opens chat.
            Link(destination: MealSuggestionDeepLinks.openChat()) {
                Color.clear
            }

            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack(spacing: 6) {
                    Text(entry.data.emoji)
                        .font(.system(size: 20))
                    Text(slotHeadline(entry.data.mealSlot))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    if entry.data.stale {
                        Label("Offline", systemImage: "wifi.exclamationmark")
                            .font(.caption2)
                            .foregroundColor(.yellow.opacity(0.8))
                    }
                }

                // Title + subtitle
                if entry.data.isSignedOut {
                    Text(entry.data.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(entry.data.subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                } else {
                    Text(entry.data.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text(entry.data.subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)

                    // Macros row
                    HStack(spacing: 10) {
                        MacroPill(label: "\(entry.data.calories) cal", color: .orange)
                        MacroPill(label: "\(Int(entry.data.proteinG))P", color: .red)
                        MacroPill(label: "\(Int(entry.data.carbsG))C", color: .blue)
                        MacroPill(label: "\(Int(entry.data.fatG))F", color: .yellow)
                    }
                }

                Spacer(minLength: 2)

                // Action row
                if !entry.data.isSignedOut {
                    HStack(spacing: 8) {
                        ActionButton(
                            systemImage: "checkmark",
                            label: "Log it",
                            gradient: LinearGradient(
                                colors: [.green, .green.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            destination: MealSuggestionDeepLinks.logIt()
                        )
                        ActionButton(
                            systemImage: "arrow.clockwise",
                            label: "Refresh",
                            gradient: LinearGradient(
                                colors: [.white.opacity(0.2), .white.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            destination: MealSuggestionDeepLinks.refresh()
                        )
                    }
                }
            }
            .padding(12)
        }
    }

    private func slotHeadline(_ slot: String) -> String {
        switch slot {
        case "breakfast": return "BREAKFAST IDEA"
        case "lunch":     return "LUNCH IDEA"
        case "dinner":    return "DINNER IDEA"
        case "snack":     return "SNACK IDEA"
        case "fasting":   return "FASTING"
        default:          return "MEAL IDEA"
        }
    }
}

// MARK: - Large family (verbose)

struct MealSuggestionLargeView: View {
    let entry: MealSuggestionEntry

    var body: some View {
        ZStack {
            Link(destination: MealSuggestionDeepLinks.openChat()) {
                Color.clear
            }

            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 8) {
                    Text(entry.data.emoji)
                        .font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 0) {
                        Text("What should you eat?")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white.opacity(0.7))
                        Text(slotHeadline(entry.data.mealSlot))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    if entry.data.stale {
                        Label("Offline", systemImage: "wifi.exclamationmark")
                            .font(.caption2)
                            .foregroundColor(.yellow.opacity(0.8))
                    }
                }

                if entry.data.isSignedOut {
                    Spacer()
                    Text(entry.data.title)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                    Text(entry.data.subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                } else {
                    // Title + subtitle
                    Text(entry.data.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)

                    Text(entry.data.subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(3)

                    // Macros row
                    HStack(spacing: 10) {
                        MacroPill(label: "\(entry.data.calories) cal", color: .orange)
                        MacroPill(label: "\(Int(entry.data.proteinG))P", color: .red)
                        MacroPill(label: "\(Int(entry.data.carbsG))C", color: .blue)
                        MacroPill(label: "\(Int(entry.data.fatG))F", color: .yellow)
                    }

                    Divider()
                        .background(Color.white.opacity(0.15))

                    // Ingredient list
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(entry.data.foodItems.prefix(3), id: \.name) { item in
                            HStack {
                                Circle()
                                    .fill(Color.white.opacity(0.5))
                                    .frame(width: 4, height: 4)
                                Text(item.grams != nil ? "\(item.grams!)g \(item.name)" : item.name)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(1)
                                Spacer()
                                Text("\(item.calories)c")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }

                    Spacer(minLength: 2)

                    // Action row
                    HStack(spacing: 10) {
                        ActionButton(
                            systemImage: "checkmark",
                            label: "Log it",
                            gradient: LinearGradient(
                                colors: [.green, .green.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            destination: MealSuggestionDeepLinks.logIt()
                        )
                        ActionButton(
                            systemImage: "arrow.clockwise",
                            label: "Refresh",
                            gradient: LinearGradient(
                                colors: [.white.opacity(0.2), .white.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            destination: MealSuggestionDeepLinks.refresh()
                        )
                    }

                    if !entry.data.loggedAlready.isEmpty {
                        Text("✓ \(entry.data.loggedAlready.joined(separator: ", ")) logged today")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(14)
        }
    }

    private func slotHeadline(_ slot: String) -> String {
        switch slot {
        case "breakfast": return "Right now: breakfast"
        case "lunch":     return "Right now: lunch"
        case "dinner":    return "Right now: dinner"
        case "snack":     return "Right now: snack"
        case "fasting":   return "Fasting window"
        default:          return "Right now"
        }
    }
}

// MARK: - Helper views

struct MacroPill: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

struct ActionButton: View {
    let systemImage: String
    let label: String
    let gradient: LinearGradient
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.bold))
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(gradient)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Widget configuration

struct MealSuggestionWidget: Widget {
    let kind: String = "MealSuggestionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MealSuggestionProvider()) { entry in
            MealSuggestionEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("What Should I Eat?")
        .description("One tap for a meal idea that fits your macros.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct MealSuggestionEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: MealSuggestionEntry

    var body: some View {
        switch family {
        case .systemSmall:
            MealSuggestionSmallView(entry: entry)
        case .systemMedium:
            MealSuggestionMediumView(entry: entry)
        case .systemLarge:
            MealSuggestionLargeView(entry: entry)
        default:
            MealSuggestionMediumView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    MealSuggestionWidget()
} timeline: {
    MealSuggestionEntry(date: Date(), data: MealSuggestionWidgetData.samplePlaceholder)
}

#Preview(as: .systemMedium) {
    MealSuggestionWidget()
} timeline: {
    MealSuggestionEntry(date: Date(), data: MealSuggestionWidgetData.samplePlaceholder)
}

#Preview(as: .systemLarge) {
    MealSuggestionWidget()
} timeline: {
    MealSuggestionEntry(date: Date(), data: MealSuggestionWidgetData.samplePlaceholder)
}
