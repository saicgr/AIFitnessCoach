import SwiftUI
import WidgetKit

// MARK: - Color Palette

extension Color {
    static let widgetPrimary = Color(red: 99/255, green: 102/255, blue: 241/255) // Indigo
    static let widgetSecondary = Color(red: 34/255, green: 211/255, blue: 238/255) // Cyan
    static let widgetAccent = Color(red: 244/255, green: 114/255, blue: 182/255) // Pink
    static let widgetBackground = Color(red: 17/255, green: 24/255, blue: 39/255) // Dark
    static let widgetText = Color(red: 249/255, green: 250/255, blue: 251/255) // Light

    static let gradientStart = Color(red: 99/255, green: 102/255, blue: 241/255)
    static let gradientEnd = Color(red: 34/255, green: 211/255, blue: 238/255)
}

// MARK: - Gradients

struct WidgetGradients {
    static let primary = LinearGradient(
        colors: [.widgetPrimary, .widgetSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let fire = LinearGradient(
        colors: [.orange, .red, .yellow],
        startPoint: .bottom,
        endPoint: .top
    )

    static let water = LinearGradient(
        colors: [Color.blue.opacity(0.8), Color.cyan],
        startPoint: .bottom,
        endPoint: .top
    )

    static let food = LinearGradient(
        colors: [.green, .mint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let achievement = LinearGradient(
        colors: [.yellow, .orange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Glassmorphic Background

struct GlassmorphicBackground: View {
    var cornerRadius: CGFloat = 24

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Gradient Text

struct GradientText: View {
    let text: String
    var font: Font = .headline
    var gradient: LinearGradient = WidgetGradients.primary

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(gradient)
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    var progress: Double
    var lineWidth: CGFloat = 8
    var gradient: LinearGradient = WidgetGradients.primary
    var backgroundColor: Color = .gray.opacity(0.3)

    var body: some View {
        ZStack {
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}

// MARK: - Pill Button

struct PillButton: View {
    let title: String
    var icon: String? = nil
    var gradient: LinearGradient = WidgetGradients.primary

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(title)
                .font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(gradient)
        .foregroundColor(.white)
        .clipShape(Capsule())
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let value: String
    let label: String
    var icon: String? = nil

    var body: some View {
        VStack(spacing: 2) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.widgetSecondary)
            }
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundColor(.widgetText)
            Text(label)
                .font(.caption2)
                .foregroundColor(.widgetText.opacity(0.7))
        }
    }
}

// MARK: - Fire Badge

struct FireBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundStyle(WidgetGradients.fire)
            Text("\(streak)")
                .font(.title2.weight(.bold))
                .foregroundColor(.widgetText)
        }
    }
}

// MARK: - Water Droplet Progress

struct WaterDropletProgress: View {
    var percent: Int
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            // Droplet shape
            Image(systemName: "drop.fill")
                .font(.system(size: size))
                .foregroundColor(.blue.opacity(0.2))

            // Filled portion
            Image(systemName: "drop.fill")
                .font(.system(size: size))
                .foregroundStyle(WidgetGradients.water)
                .mask(
                    VStack {
                        Spacer()
                        Rectangle()
                            .frame(height: size * CGFloat(percent) / 100)
                    }
                )

            // Percentage text
            Text("\(percent)%")
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size * 1.2)
    }
}

// MARK: - Macro Ring

struct MacroRing: View {
    let value: Int
    let goal: Int
    let label: String
    let color: Color
    var size: CGFloat = 40

    var progress: Double {
        guard goal > 0 else { return 0 }
        return Double(value) / Double(goal)
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                CircularProgressView(
                    progress: progress,
                    lineWidth: 4,
                    gradient: LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: size, height: size)

                Text("\(value)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.widgetText)
            }
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.widgetText.opacity(0.7))
        }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let day: CalendarDay
    let isToday: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(day.dayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.widgetText.opacity(0.6))

            ZStack {
                if isToday {
                    Circle()
                        .fill(WidgetGradients.primary)
                        .frame(width: 24, height: 24)
                }

                Text("\(day.dayNumber)")
                    .font(.system(size: 12, weight: isToday ? .bold : .regular))
                    .foregroundColor(isToday ? .white : .widgetText)
            }

            // Status indicator
            if day.isRestDay {
                Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 6, height: 6)
            } else if day.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.green)
            } else if day.hasWorkout {
                Circle()
                    .fill(Color.widgetPrimary)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - AI Coach Avatar

struct AICoachAvatar: View {
    var size: CGFloat = 50
    var showPulse: Bool = true

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            if showPulse {
                Circle()
                    .fill(WidgetGradients.primary.opacity(0.3))
                    .frame(width: size + 10, height: size + 10)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .opacity(isPulsing ? 0 : 0.5)
            }

            Circle()
                .fill(WidgetGradients.primary)
                .frame(width: size, height: size)

            Image(systemName: "brain.head.profile")
                .font(.system(size: size * 0.5))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Quick Prompt Bubble

struct QuickPromptBubble: View {
    let text: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption2)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.15))
        .foregroundColor(.widgetText)
        .clipShape(Capsule())
    }
}

// MARK: - Widget Entry Point Views

struct SmallWidgetView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color.widgetBackground)

            content
                .padding(12)
        }
    }
}

struct MediumWidgetView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color.widgetBackground)

            content
                .padding(16)
        }
    }
}

struct LargeWidgetView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color.widgetBackground)

            content
                .padding(16)
        }
    }
}

// MARK: - Deep Link URLs

struct WidgetDeepLinks {
    static let baseURL = "aifitnesscoach://"

    static func workout(id: String?) -> URL? {
        if let id = id {
            return URL(string: "\(baseURL)workout/\(id)")
        }
        return URL(string: "\(baseURL)workout")
    }

    static func startWorkout(id: String) -> URL? {
        URL(string: "\(baseURL)workout/start/\(id)")
    }

    static func addWater(amount: Int) -> URL? {
        URL(string: "\(baseURL)hydration/add?amount=\(amount)")
    }

    static func logFood(meal: String, mode: String) -> URL? {
        URL(string: "\(baseURL)nutrition/log?meal=\(meal)&mode=\(mode)")
    }

    static func chat(prompt: String? = nil, agent: String? = nil) -> URL? {
        var urlString = "\(baseURL)chat"
        var params: [String] = []
        if let prompt = prompt {
            params.append("prompt=\(prompt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? prompt)")
        }
        if let agent = agent {
            params.append("agent=\(agent)")
        }
        if !params.isEmpty {
            urlString += "?" + params.joined(separator: "&")
        }
        return URL(string: urlString)
    }

    static let challenges = URL(string: "\(baseURL)challenges")
    static let achievements = URL(string: "\(baseURL)achievements")
    static let goals = URL(string: "\(baseURL)goals")
    static let schedule = URL(string: "\(baseURL)schedule")
    static let stats = URL(string: "\(baseURL)stats")
    static let social = URL(string: "\(baseURL)social")

    static func shareWorkout() -> URL? {
        URL(string: "\(baseURL)social/share?type=workout")
    }

    static func shareAchievement() -> URL? {
        URL(string: "\(baseURL)social/share?type=achievement")
    }
}
