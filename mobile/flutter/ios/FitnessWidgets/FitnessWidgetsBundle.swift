import WidgetKit
import SwiftUI

@main
struct FitnessWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // All 11 home screen widgets
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
    }
}
