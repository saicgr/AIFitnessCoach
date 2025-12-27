import Foundation
import WidgetKit

/// Keys for UserDefaults shared between Flutter app and widgets
struct WidgetDataKeys {
    static let appGroupId = "group.com.aifitnesscoach.widgets"
    static let workout = "workout_data"
    static let streak = "streak_data"
    static let water = "water_data"
    static let food = "food_data"
    static let stats = "stats_data"
    static let challenges = "challenges_data"
    static let achievements = "achievements_data"
    static let goals = "goals_data"
    static let calendar = "calendar_data"
    static let aiCoach = "aicoach_data"
}

/// Provider to fetch shared data from Flutter app
class WidgetDataProvider {
    static let shared = WidgetDataProvider()

    private let userDefaults: UserDefaults?

    private init() {
        userDefaults = UserDefaults(suiteName: WidgetDataKeys.appGroupId)
    }

    // MARK: - Workout Data

    func getWorkoutData() -> WorkoutWidgetData {
        guard let jsonString = userDefaults?.string(forKey: WidgetDataKeys.workout),
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return WorkoutWidgetData.placeholder
        }

        return WorkoutWidgetData(
            id: json["id"] as? String,
            name: json["name"] as? String ?? "No Workout",
            duration: json["duration"] as? Int ?? 0,
            exerciseCount: json["exercises"] as? Int ?? 0,
            muscleGroup: json["muscle"] as? String ?? "",
            isRestDay: json["isRestDay"] as? Bool ?? false
        )
    }

    // MARK: - Streak Data

    func getStreakData() -> StreakWidgetData {
        guard let jsonString = userDefaults?.string(forKey: WidgetDataKeys.streak),
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return StreakWidgetData.placeholder
        }

        return StreakWidgetData(
            currentStreak: json["current"] as? Int ?? 0,
            longestStreak: json["longest"] as? Int ?? 0,
            motivationalMessage: json["message"] as? String ?? "Start your journey!",
            weeklyConsistency: json["weekly"] as? [Bool] ?? []
        )
    }

    // MARK: - Water Data

    func getWaterData() -> WaterWidgetData {
        guard let jsonString = userDefaults?.string(forKey: WidgetDataKeys.water),
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return WaterWidgetData.placeholder
        }

        return WaterWidgetData(
            currentMl: json["current"] as? Int ?? 0,
            goalMl: json["goal"] as? Int ?? 2500,
            percent: json["percent"] as? Int ?? 0
        )
    }

    // MARK: - Food Data

    func getFoodData() -> FoodWidgetData {
        guard let jsonString = userDefaults?.string(forKey: WidgetDataKeys.food),
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return FoodWidgetData.placeholder
        }

        return FoodWidgetData(
            calories: json["calories"] as? Int ?? 0,
            calorieGoal: json["calorieGoal"] as? Int ?? 2000,
            protein: json["protein"] as? Int ?? 0,
            carbs: json["carbs"] as? Int ?? 0,
            fat: json["fat"] as? Int ?? 0
        )
    }

    // MARK: - Stats Data

    func getStatsData() -> StatsWidgetData {
        guard let jsonString = userDefaults?.string(forKey: WidgetDataKeys.stats),
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return StatsWidgetData.placeholder
        }

        return StatsWidgetData(
            workoutsCompleted: json["workouts"] as? Int ?? 0,
            workoutsGoal: json["workoutsGoal"] as? Int ?? 5,
            totalMinutes: json["minutes"] as? Int ?? 0,
            caloriesBurned: json["calories"] as? Int ?? 0,
            currentStreak: json["streak"] as? Int ?? 0,
            prsThisWeek: json["prs"] as? Int ?? 0,
            weightChange: json["weightChange"] as? Double ?? 0.0
        )
    }

    // MARK: - Challenges Data

    func getChallengesData() -> ChallengesWidgetData {
        guard let jsonString = userDefaults?.string(forKey: WidgetDataKeys.challenges),
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ChallengesWidgetData.placeholder
        }

        let challengesJson = json["challenges"] as? [[String: Any]] ?? []
        let challenges = challengesJson.map { item -> ChallengeItem in
            ChallengeItem(
                id: item["id"] as? String ?? "",
                title: item["title"] as? String ?? "",
                yourScore: item["yourScore"] as? Int ?? 0,
                opponentScore: item["opponentScore"] as? Int ?? 0,
                opponentName: item["opponentName"] as? String ?? "",
                isLeading: item["isLeading"] as? Bool ?? false
            )
        }

        return ChallengesWidgetData(
            count: json["count"] as? Int ?? 0,
            challenges: challenges
        )
    }

    // MARK: - Achievements Data

    func getAchievementsData() -> AchievementsWidgetData {
        guard let jsonString = userDefaults?.string(forKey: WidgetDataKeys.achievements),
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return AchievementsWidgetData.placeholder
        }

        let achievementsJson = json["achievements"] as? [[String: Any]] ?? []
        let achievements = achievementsJson.map { item -> AchievementItem in
            AchievementItem(
                id: item["id"] as? String ?? "",
                name: item["name"] as? String ?? "",
                icon: item["icon"] as? String ?? ""
            )
        }

        return AchievementsWidgetData(
            achievements: achievements,
            totalPoints: json["points"] as? Int ?? 0,
            nextMilestone: json["nextMilestone"] as? String ?? "",
            progressToNext: json["progress"] as? Int ?? 0
        )
    }

    // MARK: - Goals Data

    func getGoalsData() -> GoalsWidgetData {
        guard let jsonString = userDefaults?.string(forKey: WidgetDataKeys.goals),
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return GoalsWidgetData.placeholder
        }

        let goalsJson = json["goals"] as? [[String: Any]] ?? []
        let goals = goalsJson.map { item -> GoalItem in
            GoalItem(
                id: item["id"] as? String ?? "",
                title: item["title"] as? String ?? "",
                progressPercent: item["progress"] as? Int ?? 0
            )
        }

        return GoalsWidgetData(goals: goals)
    }

    // MARK: - Calendar Data

    func getCalendarData() -> CalendarWidgetData {
        guard let jsonString = userDefaults?.string(forKey: WidgetDataKeys.calendar),
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return CalendarWidgetData.placeholder
        }

        let daysJson = json["days"] as? [[String: Any]] ?? []
        let days = daysJson.map { item -> CalendarDay in
            CalendarDay(
                dayName: item["day"] as? String ?? "",
                dayNumber: item["number"] as? Int ?? 0,
                hasWorkout: item["hasWorkout"] as? Bool ?? false,
                isCompleted: item["completed"] as? Bool ?? false,
                isRestDay: item["isRest"] as? Bool ?? false,
                workoutName: item["workoutName"] as? String
            )
        }

        return CalendarWidgetData(
            days: days,
            todayIndex: json["todayIndex"] as? Int ?? 0
        )
    }

    // MARK: - AI Coach Data

    func getAICoachData() -> AICoachWidgetData {
        guard let jsonString = userDefaults?.string(forKey: WidgetDataKeys.aiCoach),
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return AICoachWidgetData.placeholder
        }

        return AICoachWidgetData(
            lastMessagePreview: json["lastMessage"] as? String ?? "",
            lastAgent: json["lastAgent"] as? String ?? "coach",
            quickPrompts: json["prompts"] as? [String] ?? AICoachWidgetData.defaultPrompts
        )
    }
}

// MARK: - Data Models

struct WorkoutWidgetData {
    let id: String?
    let name: String
    let duration: Int
    let exerciseCount: Int
    let muscleGroup: String
    let isRestDay: Bool

    static let placeholder = WorkoutWidgetData(
        id: nil,
        name: "Upper Body Power",
        duration: 45,
        exerciseCount: 8,
        muscleGroup: "Chest, Shoulders",
        isRestDay: false
    )
}

struct StreakWidgetData {
    let currentStreak: Int
    let longestStreak: Int
    let motivationalMessage: String
    let weeklyConsistency: [Bool]

    static let placeholder = StreakWidgetData(
        currentStreak: 7,
        longestStreak: 14,
        motivationalMessage: "You're on fire!",
        weeklyConsistency: [true, true, true, false, true, true, false]
    )
}

struct WaterWidgetData {
    let currentMl: Int
    let goalMl: Int
    let percent: Int

    static let placeholder = WaterWidgetData(
        currentMl: 1500,
        goalMl: 2500,
        percent: 60
    )
}

struct FoodWidgetData {
    let calories: Int
    let calorieGoal: Int
    let protein: Int
    let carbs: Int
    let fat: Int

    static let placeholder = FoodWidgetData(
        calories: 1250,
        calorieGoal: 2000,
        protein: 85,
        carbs: 120,
        fat: 45
    )

    var mealTypeForCurrentTime: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<10: return "Breakfast"
        case 10..<14: return "Lunch"
        case 14..<17: return "Snack"
        case 17..<22: return "Dinner"
        default: return "Late Snack"
        }
    }

    var mealIconForCurrentTime: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<10: return "sunrise.fill"
        case 10..<14: return "sun.max.fill"
        case 14..<17: return "cup.and.saucer.fill"
        case 17..<22: return "moon.fill"
        default: return "moon.stars.fill"
        }
    }
}

struct StatsWidgetData {
    let workoutsCompleted: Int
    let workoutsGoal: Int
    let totalMinutes: Int
    let caloriesBurned: Int
    let currentStreak: Int
    let prsThisWeek: Int
    let weightChange: Double

    static let placeholder = StatsWidgetData(
        workoutsCompleted: 4,
        workoutsGoal: 5,
        totalMinutes: 245,
        caloriesBurned: 2100,
        currentStreak: 7,
        prsThisWeek: 2,
        weightChange: -0.5
    )
}

struct ChallengesWidgetData {
    let count: Int
    let challenges: [ChallengeItem]

    static let placeholder = ChallengesWidgetData(
        count: 2,
        challenges: [
            ChallengeItem(id: "1", title: "Weekly Volume", yourScore: 15000, opponentScore: 12000, opponentName: "John", isLeading: true),
            ChallengeItem(id: "2", title: "Workout Count", yourScore: 3, opponentScore: 4, opponentName: "Sarah", isLeading: false)
        ]
    )
}

struct ChallengeItem {
    let id: String
    let title: String
    let yourScore: Int
    let opponentScore: Int
    let opponentName: String
    let isLeading: Bool
}

struct AchievementsWidgetData {
    let achievements: [AchievementItem]
    let totalPoints: Int
    let nextMilestone: String
    let progressToNext: Int

    static let placeholder = AchievementsWidgetData(
        achievements: [
            AchievementItem(id: "1", name: "First Workout", icon: "star.fill"),
            AchievementItem(id: "2", name: "Week Warrior", icon: "flame.fill"),
            AchievementItem(id: "3", name: "PR Crusher", icon: "trophy.fill")
        ],
        totalPoints: 350,
        nextMilestone: "Fitness Pro",
        progressToNext: 70
    )
}

struct AchievementItem {
    let id: String
    let name: String
    let icon: String
}

struct GoalsWidgetData {
    let goals: [GoalItem]

    static let placeholder = GoalsWidgetData(
        goals: [
            GoalItem(id: "1", title: "Lose 10 lbs", progressPercent: 65),
            GoalItem(id: "2", title: "Run 5K", progressPercent: 40),
            GoalItem(id: "3", title: "100 Push-ups", progressPercent: 85)
        ]
    )
}

struct GoalItem {
    let id: String
    let title: String
    let progressPercent: Int
}

struct CalendarWidgetData {
    let days: [CalendarDay]
    let todayIndex: Int

    static let placeholder: CalendarWidgetData = {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today)!

        var days: [CalendarDay] = []
        let dayNames = ["S", "M", "T", "W", "T", "F", "S"]

        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: startOfWeek)!
            let dayNumber = calendar.component(.day, from: date)
            let isPast = date < today

            days.append(CalendarDay(
                dayName: dayNames[i],
                dayNumber: dayNumber,
                hasWorkout: i != 0 && i != 6,
                isCompleted: isPast && i != 0 && i != 6,
                isRestDay: i == 0 || i == 6,
                workoutName: i != 0 && i != 6 ? "Workout" : nil
            ))
        }

        return CalendarWidgetData(days: days, todayIndex: weekday - 1)
    }()
}

struct CalendarDay {
    let dayName: String
    let dayNumber: Int
    let hasWorkout: Bool
    let isCompleted: Bool
    let isRestDay: Bool
    let workoutName: String?
}

struct AICoachWidgetData {
    let lastMessagePreview: String
    let lastAgent: String
    let quickPrompts: [String]

    static let defaultPrompts = [
        "What should I eat today?",
        "Modify my workout",
        "I'm feeling tired"
    ]

    static let placeholder = AICoachWidgetData(
        lastMessagePreview: "Ready to help with your fitness journey!",
        lastAgent: "coach",
        quickPrompts: defaultPrompts
    )
}
