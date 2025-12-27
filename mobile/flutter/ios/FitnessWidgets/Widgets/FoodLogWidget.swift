import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct FoodLogProvider: TimelineProvider {
    func placeholder(in context: Context) -> FoodLogEntry {
        FoodLogEntry(date: Date(), data: FoodWidgetData.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (FoodLogEntry) -> Void) {
        let entry = FoodLogEntry(date: Date(), data: WidgetDataProvider.shared.getFoodData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FoodLogEntry>) -> Void) {
        let currentDate = Date()
        let entry = FoodLogEntry(date: currentDate, data: WidgetDataProvider.shared.getFoodData())

        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct FoodLogEntry: TimelineEntry {
    let date: Date
    let data: FoodWidgetData
}

// MARK: - Widget Views

struct FoodLogWidgetSmallView: View {
    let entry: FoodLogEntry

    var body: some View {
        SmallWidgetView {
            VStack(spacing: 8) {
                // Calorie display
                Text("\(entry.data.calories)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.widgetText)

                Text("cal today")
                    .font(.caption)
                    .foregroundColor(.widgetText.opacity(0.7))

                // Smart meal button (changes by time)
                Link(destination: WidgetDeepLinks.logFood(meal: entry.data.mealTypeForCurrentTime.lowercased(), mode: "text") ?? URL(string: "aifitnesscoach://nutrition")!) {
                    HStack(spacing: 4) {
                        Image(systemName: entry.data.mealIconForCurrentTime)
                            .font(.caption2)
                        Text("Log \(entry.data.mealTypeForCurrentTime)")
                            .font(.caption2.weight(.semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(WidgetGradients.food)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
            }
        }
    }
}

struct FoodLogWidgetMediumView: View {
    let entry: FoodLogEntry

    var body: some View {
        MediumWidgetView {
            VStack(spacing: 12) {
                // Top row - Calories and macros
                HStack {
                    // Calories
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(entry.data.calories)")
                            .font(.title.weight(.bold))
                            .foregroundColor(.widgetText)
                        Text("of \(entry.data.calorieGoal) cal")
                            .font(.caption)
                            .foregroundColor(.widgetText.opacity(0.7))
                    }

                    Spacer()

                    // Macro rings
                    HStack(spacing: 12) {
                        MacroRing(value: entry.data.protein, goal: 150, label: "P", color: .red, size: 36)
                        MacroRing(value: entry.data.carbs, goal: 200, label: "C", color: .blue, size: 36)
                        MacroRing(value: entry.data.fat, goal: 65, label: "F", color: .yellow, size: 36)
                    }
                }

                // Bottom row - Meal type and input methods
                HStack(spacing: 8) {
                    // Meal type buttons
                    MealTypeButton(icon: "sunrise.fill", label: "Brkfst", meal: "breakfast")
                    MealTypeButton(icon: "sun.max.fill", label: "Lunch", meal: "lunch")
                    MealTypeButton(icon: "moon.fill", label: "Dinner", meal: "dinner")

                    Spacer()

                    // Input method buttons
                    InputMethodButton(icon: "camera.fill", mode: "photo")
                    InputMethodButton(icon: "text.bubble.fill", mode: "text")
                    InputMethodButton(icon: "barcode", mode: "barcode")
                }
            }
        }
    }
}

struct FoodLogWidgetLargeView: View {
    let entry: FoodLogEntry

    var body: some View {
        LargeWidgetView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "fork.knife")
                        .foregroundStyle(WidgetGradients.food)
                    Text("Nutrition")
                        .font(.headline)
                        .foregroundColor(.widgetText.opacity(0.7))
                    Spacer()
                }

                // Calories section
                HStack(spacing: 20) {
                    // Calorie ring
                    ZStack {
                        CircularProgressView(
                            progress: Double(entry.data.calories) / Double(entry.data.calorieGoal),
                            lineWidth: 10,
                            gradient: WidgetGradients.food
                        )
                        .frame(width: 80, height: 80)

                        VStack(spacing: 0) {
                            Text("\(entry.data.calories)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.widgetText)
                            Text("cal")
                                .font(.caption2)
                                .foregroundColor(.widgetText.opacity(0.7))
                        }
                    }

                    // Macro breakdown
                    VStack(alignment: .leading, spacing: 8) {
                        MacroRow(label: "Protein", value: entry.data.protein, unit: "g", color: .red)
                        MacroRow(label: "Carbs", value: entry.data.carbs, unit: "g", color: .blue)
                        MacroRow(label: "Fat", value: entry.data.fat, unit: "g", color: .yellow)
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                // Meal type selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Log Meal")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.widgetText.opacity(0.7))

                    HStack(spacing: 8) {
                        LargeMealTypeButton(icon: "sunrise.fill", label: "Breakfast", meal: "breakfast")
                        LargeMealTypeButton(icon: "sun.max.fill", label: "Lunch", meal: "lunch")
                        LargeMealTypeButton(icon: "moon.fill", label: "Dinner", meal: "dinner")
                        LargeMealTypeButton(icon: "cup.and.saucer.fill", label: "Snack", meal: "snack")
                    }
                }

                // Input method selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Input Method")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.widgetText.opacity(0.7))

                    HStack(spacing: 12) {
                        LargeInputMethodButton(icon: "text.bubble.fill", label: "Text", mode: "text")
                        LargeInputMethodButton(icon: "camera.fill", label: "Photo", mode: "photo")
                        LargeInputMethodButton(icon: "barcode", label: "Scan", mode: "barcode")
                        LargeInputMethodButton(icon: "star.fill", label: "Saved", mode: "saved")
                    }
                }

                Spacer()
            }
        }
    }
}

// MARK: - Helper Views

struct MealTypeButton: View {
    let icon: String
    let label: String
    let meal: String

    var body: some View {
        Link(destination: WidgetDeepLinks.logFood(meal: meal, mode: "text") ?? URL(string: "aifitnesscoach://nutrition")!) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.system(size: 9))
            }
            .frame(width: 50, height: 36)
            .background(Color.white.opacity(0.1))
            .foregroundColor(.widgetText)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct LargeMealTypeButton: View {
    let icon: String
    let label: String
    let meal: String

    var body: some View {
        Link(destination: WidgetDeepLinks.logFood(meal: meal, mode: "text") ?? URL(string: "aifitnesscoach://nutrition")!) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.system(size: 10))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .foregroundColor(.widgetText)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct InputMethodButton: View {
    let icon: String
    let mode: String

    var body: some View {
        Link(destination: WidgetDeepLinks.logFood(meal: "auto", mode: mode) ?? URL(string: "aifitnesscoach://nutrition")!) {
            Image(systemName: icon)
                .font(.caption)
                .frame(width: 28, height: 28)
                .background(WidgetGradients.food)
                .foregroundColor(.white)
                .clipShape(Circle())
        }
    }
}

struct LargeInputMethodButton: View {
    let icon: String
    let label: String
    let mode: String

    var body: some View {
        Link(destination: WidgetDeepLinks.logFood(meal: "auto", mode: mode) ?? URL(string: "aifitnesscoach://nutrition")!) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(WidgetGradients.food)
                    .foregroundColor(.white)
                    .clipShape(Circle())

                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.widgetText.opacity(0.7))
            }
        }
    }
}

struct MacroRow: View {
    let label: String
    let value: Int
    let unit: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(.widgetText.opacity(0.7))
            Spacer()
            Text("\(value)\(unit)")
                .font(.caption.weight(.semibold))
                .foregroundColor(.widgetText)
        }
    }
}

// MARK: - Widget Configuration

struct FoodLogWidget: Widget {
    let kind: String = "FoodLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FoodLogProvider()) { entry in
            FoodLogWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quick Food Log")
        .description("Log meals with text, photo, barcode, or saved foods.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct FoodLogWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: FoodLogEntry

    var body: some View {
        switch family {
        case .systemSmall:
            FoodLogWidgetSmallView(entry: entry)
        case .systemMedium:
            FoodLogWidgetMediumView(entry: entry)
        case .systemLarge:
            FoodLogWidgetLargeView(entry: entry)
        default:
            FoodLogWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    FoodLogWidget()
} timeline: {
    FoodLogEntry(date: Date(), data: FoodWidgetData.placeholder)
}

#Preview(as: .systemMedium) {
    FoodLogWidget()
} timeline: {
    FoodLogEntry(date: Date(), data: FoodWidgetData.placeholder)
}

#Preview(as: .systemLarge) {
    FoodLogWidget()
} timeline: {
    FoodLogEntry(date: Date(), data: FoodWidgetData.placeholder)
}
