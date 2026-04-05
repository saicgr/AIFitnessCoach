part of 'notification_service.dart';


/// Notification preferences state
class NotificationPreferences {
  final bool workoutReminders;
  final bool nutritionReminders;
  final bool hydrationReminders;
  final bool aiCoachMessages;
  final bool streakAlerts;
  final bool weeklySummary;
  final bool billingReminders;
  final bool movementReminders;
  final bool liveChatMessages;
  final String quietHoursStart;
  final String quietHoursEnd;
  // Time preferences for scheduled notifications
  final String workoutReminderTime; // e.g. "08:00"
  final String nutritionBreakfastTime;
  final String nutritionLunchTime;
  final String nutritionDinnerTime;
  final String hydrationStartTime;
  final String hydrationEndTime;
  final int hydrationIntervalMinutes;
  final String streakAlertTime;
  final int weeklySummaryDay; // 0=Sunday, 6=Saturday
  final String weeklySummaryTime;
  // Movement reminder (NEAT) preferences
  final String movementReminderStartTime;
  final String movementReminderEndTime;
  final int movementStepThreshold; // Steps per hour threshold (default 250)
  // Smart timing
  final bool smartTimingEnabled;

  // Accountability Coach Nudge Preferences (synced to backend)
  final bool missedWorkoutNudge;
  final String missedWorkoutTime;
  final bool postWorkoutMealReminder;
  final int postWorkoutMealDelayMinutes;
  final bool habitReminders;
  final String habitReminderTime;
  final bool weeklyCheckinReminder;
  final int weeklyCheckinDay; // 0=Sunday
  final String weeklyCheckinTime;
  final bool streakCelebration;
  final bool milestoneCelebration;
  final int dailyNudgeLimit; // 1-8
  final String accountabilityIntensity; // gentle/balanced/tough_love/off
  final bool aiPersonalizedNudges;
  final bool guiltNotifications;

  const NotificationPreferences({
    this.workoutReminders = true,
    this.nutritionReminders = true,
    this.hydrationReminders = true,
    this.aiCoachMessages = true,
    this.streakAlerts = true,
    this.weeklySummary = true,
    this.billingReminders = true,
    this.movementReminders = true,
    this.liveChatMessages = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
    // Default times
    this.workoutReminderTime = '08:00',
    this.nutritionBreakfastTime = '08:00',
    this.nutritionLunchTime = '12:00',
    this.nutritionDinnerTime = '18:00',
    this.hydrationStartTime = '08:15',
    this.hydrationEndTime = '20:00',
    this.hydrationIntervalMinutes = 120, // Every 2 hours
    this.streakAlertTime = '18:00',
    this.weeklySummaryDay = 0, // Sunday
    this.weeklySummaryTime = '09:00',
    // Movement reminder defaults (work hours)
    this.movementReminderStartTime = '09:05',
    this.movementReminderEndTime = '17:00',
    this.movementStepThreshold = 250, // 250 steps per hour threshold
    // Smart timing
    this.smartTimingEnabled = false,
    // Accountability Coach defaults
    this.missedWorkoutNudge = true,
    this.missedWorkoutTime = '19:00',
    this.postWorkoutMealReminder = true,
    this.postWorkoutMealDelayMinutes = 30,
    this.habitReminders = true,
    this.habitReminderTime = '20:00',
    this.weeklyCheckinReminder = true,
    this.weeklyCheckinDay = 0,
    this.weeklyCheckinTime = '09:00',
    this.streakCelebration = true,
    this.milestoneCelebration = true,
    this.dailyNudgeLimit = 4,
    this.accountabilityIntensity = 'balanced',
    this.aiPersonalizedNudges = true,
    this.guiltNotifications = true,
  });

  NotificationPreferences copyWith({
    bool? workoutReminders,
    bool? nutritionReminders,
    bool? hydrationReminders,
    bool? aiCoachMessages,
    bool? streakAlerts,
    bool? weeklySummary,
    bool? billingReminders,
    bool? movementReminders,
    bool? liveChatMessages,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? workoutReminderTime,
    String? nutritionBreakfastTime,
    String? nutritionLunchTime,
    String? nutritionDinnerTime,
    String? hydrationStartTime,
    String? hydrationEndTime,
    int? hydrationIntervalMinutes,
    String? streakAlertTime,
    int? weeklySummaryDay,
    String? weeklySummaryTime,
    String? movementReminderStartTime,
    String? movementReminderEndTime,
    int? movementStepThreshold,
    bool? smartTimingEnabled,
    // Accountability Coach
    bool? missedWorkoutNudge,
    String? missedWorkoutTime,
    bool? postWorkoutMealReminder,
    int? postWorkoutMealDelayMinutes,
    bool? habitReminders,
    String? habitReminderTime,
    bool? weeklyCheckinReminder,
    int? weeklyCheckinDay,
    String? weeklyCheckinTime,
    bool? streakCelebration,
    bool? milestoneCelebration,
    int? dailyNudgeLimit,
    String? accountabilityIntensity,
    bool? aiPersonalizedNudges,
    bool? guiltNotifications,
  }) {
    return NotificationPreferences(
      workoutReminders: workoutReminders ?? this.workoutReminders,
      nutritionReminders: nutritionReminders ?? this.nutritionReminders,
      hydrationReminders: hydrationReminders ?? this.hydrationReminders,
      aiCoachMessages: aiCoachMessages ?? this.aiCoachMessages,
      streakAlerts: streakAlerts ?? this.streakAlerts,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      billingReminders: billingReminders ?? this.billingReminders,
      movementReminders: movementReminders ?? this.movementReminders,
      liveChatMessages: liveChatMessages ?? this.liveChatMessages,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      workoutReminderTime: workoutReminderTime ?? this.workoutReminderTime,
      nutritionBreakfastTime: nutritionBreakfastTime ?? this.nutritionBreakfastTime,
      nutritionLunchTime: nutritionLunchTime ?? this.nutritionLunchTime,
      nutritionDinnerTime: nutritionDinnerTime ?? this.nutritionDinnerTime,
      hydrationStartTime: hydrationStartTime ?? this.hydrationStartTime,
      hydrationEndTime: hydrationEndTime ?? this.hydrationEndTime,
      hydrationIntervalMinutes: hydrationIntervalMinutes ?? this.hydrationIntervalMinutes,
      streakAlertTime: streakAlertTime ?? this.streakAlertTime,
      weeklySummaryDay: weeklySummaryDay ?? this.weeklySummaryDay,
      weeklySummaryTime: weeklySummaryTime ?? this.weeklySummaryTime,
      movementReminderStartTime: movementReminderStartTime ?? this.movementReminderStartTime,
      movementReminderEndTime: movementReminderEndTime ?? this.movementReminderEndTime,
      movementStepThreshold: movementStepThreshold ?? this.movementStepThreshold,
      smartTimingEnabled: smartTimingEnabled ?? this.smartTimingEnabled,
      // Accountability Coach
      missedWorkoutNudge: missedWorkoutNudge ?? this.missedWorkoutNudge,
      missedWorkoutTime: missedWorkoutTime ?? this.missedWorkoutTime,
      postWorkoutMealReminder: postWorkoutMealReminder ?? this.postWorkoutMealReminder,
      postWorkoutMealDelayMinutes: postWorkoutMealDelayMinutes ?? this.postWorkoutMealDelayMinutes,
      habitReminders: habitReminders ?? this.habitReminders,
      habitReminderTime: habitReminderTime ?? this.habitReminderTime,
      weeklyCheckinReminder: weeklyCheckinReminder ?? this.weeklyCheckinReminder,
      weeklyCheckinDay: weeklyCheckinDay ?? this.weeklyCheckinDay,
      weeklyCheckinTime: weeklyCheckinTime ?? this.weeklyCheckinTime,
      streakCelebration: streakCelebration ?? this.streakCelebration,
      milestoneCelebration: milestoneCelebration ?? this.milestoneCelebration,
      dailyNudgeLimit: dailyNudgeLimit ?? this.dailyNudgeLimit,
      accountabilityIntensity: accountabilityIntensity ?? this.accountabilityIntensity,
      aiPersonalizedNudges: aiPersonalizedNudges ?? this.aiPersonalizedNudges,
      guiltNotifications: guiltNotifications ?? this.guiltNotifications,
    );
  }

  Map<String, dynamic> toJson() => {
        'workout_reminders': workoutReminders,
        'nutrition_reminders': nutritionReminders,
        'hydration_reminders': hydrationReminders,
        'ai_coach_messages': aiCoachMessages,
        'streak_alerts': streakAlerts,
        'weekly_summary': weeklySummary,
        'billing_reminders': billingReminders,
        'movement_reminders': movementReminders,
        'live_chat_messages': liveChatMessages,
        'quiet_hours_start': quietHoursStart,
        'quiet_hours_end': quietHoursEnd,
        'workout_reminder_time': workoutReminderTime,
        'nutrition_breakfast_time': nutritionBreakfastTime,
        'nutrition_lunch_time': nutritionLunchTime,
        'nutrition_dinner_time': nutritionDinnerTime,
        'hydration_start_time': hydrationStartTime,
        'hydration_end_time': hydrationEndTime,
        'hydration_interval_minutes': hydrationIntervalMinutes,
        'streak_alert_time': streakAlertTime,
        'weekly_summary_day': weeklySummaryDay,
        'weekly_summary_time': weeklySummaryTime,
        'movement_reminder_start_time': movementReminderStartTime,
        'movement_reminder_end_time': movementReminderEndTime,
        'movement_step_threshold': movementStepThreshold,
        'smart_timing_enabled': smartTimingEnabled,
        // Accountability Coach
        'missed_workout_nudge': missedWorkoutNudge,
        'missed_workout_time': missedWorkoutTime,
        'post_workout_meal_reminder': postWorkoutMealReminder,
        'post_workout_meal_delay_minutes': postWorkoutMealDelayMinutes,
        'habit_reminders': habitReminders,
        'habit_reminder_time': habitReminderTime,
        'weekly_checkin_reminder': weeklyCheckinReminder,
        'weekly_checkin_day': weeklyCheckinDay,
        'weekly_checkin_time': weeklyCheckinTime,
        'streak_celebration': streakCelebration,
        'milestone_celebration': milestoneCelebration,
        'daily_nudge_limit': dailyNudgeLimit,
        'accountability_intensity': accountabilityIntensity,
        'ai_personalized_nudges': aiPersonalizedNudges,
        'guilt_notifications': guiltNotifications,
      };
}


/// Callback type for storing received notifications
typedef OnNotificationReceivedCallback = void Function({
  required String title,
  required String body,
  String? type,
  Map<String, dynamic>? data,
});

