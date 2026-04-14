import WidgetKit
import SwiftUI

@main
struct FitnessWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // All home-screen widgets
        WorkoutWidget()
        StreakWidget()
        WaterLogWidget()
        FoodLogWidget()
        StatsWidget()
        SocialWidget()
        ChallengesWidget()
        AchievementsWidget()
        GoalsWidget()
        CalendarWidget()
        AICoachWidget()
        // One-tap "what should I eat" widget — staged under Settings →
        // Coming Soon. Uncomment once Runner.entitlements has the App
        // Groups capability and the provisioning profile is regenerated.
        // MealSuggestionWidget()
    }
}
