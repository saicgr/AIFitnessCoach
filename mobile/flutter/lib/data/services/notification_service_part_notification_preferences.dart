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
  // Daily crate reminder (gamification)
  final bool dailyCrateReminders;
  final String dailyCrateReminderTime;

  // Proactive health coaching (Phase C2) — synced to backend
  // notification_preferences JSON; each type drives one cron nudge job.
  final bool dailyBriefingNudge;   // morning readiness briefing (anchor push)
  final String dailyBriefingTime;  // local delivery time, e.g. "08:00"
  final bool healthAnomalyNudge;   // resting-HR anomaly alert (event-driven)
  final bool activityGoalNudge;    // afternoon step-goal nudge
  final String activityNudgeTime;  // local delivery time for the step nudge

  // Frequency preset
  final String frequencyPreset; // 'minimal', 'balanced', 'full_coach'
  // Bundle times
  final String morningBundleTime;
  final String middayBundleTime;
  final String afternoonNudgeTime;
  final String eveningBundleTime;
  // Weekend scheduling
  final bool weekendTimesEnabled;
  final String morningBundleTimeWeekend;
  final String middayBundleTimeWeekend;
  final String eveningBundleTimeWeekend;
  // Bundle content toggles
  final bool morningIncludeWorkout;
  final bool morningIncludeBreakfast;
  final bool morningIncludeMotivation;
  final bool middayIncludeLunch;
  final bool middayIncludeHydration;
  final bool eveningIncludeDinner;
  final bool eveningIncludeStreak;
  final bool eveningIncludeProgress;
  // Style preferences
  final bool notificationEmoji;
  final bool notificationVibration;

  // ── Cycle tracking reminders (Phase E) ──────────────────────────
  // `cycleRemindersMaster` gates the whole group; each sub-type has its own
  // toggle. All cycle reminders respect the global quiet hours. The
  // fertile-window + peak-fertility reminders are only meaningful (and only
  // scheduled) in TTC mode — see `cycleTrackingMode`.
  final bool cycleRemindersMaster;
  final bool cyclePeriodApproaching;
  final bool cyclePeriodStart;
  final bool cycleFertileWindow;
  final bool cyclePeakFertility;
  final bool cycleBbtReminder;
  final String cycleBbtReminderTime;
  final bool cycleSymptomCheckin;
  final String cycleSymptomCheckinTime;
  final bool cycleLatePeriodAlert;
  /// Default time-of-day for the date-anchored cycle reminders (period
  /// approaching / start / fertile / peak / late). The user picks one time
  /// that applies to all of them — keeps the settings UI compact.
  final String cycleReminderTimeOfDay;
  /// Days before the predicted period the "approaching" reminder fires (1-5).
  final int cyclePeriodApproachingLeadDays;
  /// The current cycle tracking mode (`tracking` | `ttc` | `pregnancy`).
  /// Stored here so scheduling can decide whether to schedule the TTC-only
  /// fertility reminders without reaching into the hormonal profile.
  final String cycleTrackingMode;

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
    // Daily crate reminder
    this.dailyCrateReminders = true,
    this.dailyCrateReminderTime = '10:00',
    // Proactive health coaching (Phase C2)
    this.dailyBriefingNudge = true,
    this.dailyBriefingTime = '08:00',
    this.healthAnomalyNudge = true,
    this.activityGoalNudge = true,
    this.activityNudgeTime = '15:00',
    // Frequency preset
    this.frequencyPreset = 'balanced',
    // Bundle times
    this.morningBundleTime = '07:30',
    this.middayBundleTime = '12:30',
    this.afternoonNudgeTime = '15:00',
    this.eveningBundleTime = '19:00',
    // Weekend scheduling
    this.weekendTimesEnabled = false,
    this.morningBundleTimeWeekend = '09:30',
    this.middayBundleTimeWeekend = '13:00',
    this.eveningBundleTimeWeekend = '20:00',
    // Bundle content toggles
    this.morningIncludeWorkout = true,
    this.morningIncludeBreakfast = true,
    this.morningIncludeMotivation = true,
    this.middayIncludeLunch = true,
    this.middayIncludeHydration = true,
    this.eveningIncludeDinner = true,
    this.eveningIncludeStreak = true,
    this.eveningIncludeProgress = true,
    // Style preferences
    this.notificationEmoji = true,
    this.notificationVibration = true,
    // Cycle tracking reminders (Phase E) — default ON when the cycle feature
    // is enabled; the group is also gated by `cycleRemindersMaster`.
    this.cycleRemindersMaster = true,
    this.cyclePeriodApproaching = true,
    this.cyclePeriodStart = true,
    this.cycleFertileWindow = true,
    this.cyclePeakFertility = true,
    this.cycleBbtReminder = false,
    this.cycleBbtReminderTime = '07:00',
    this.cycleSymptomCheckin = false,
    this.cycleSymptomCheckinTime = '20:00',
    this.cycleLatePeriodAlert = true,
    this.cycleReminderTimeOfDay = '09:00',
    this.cyclePeriodApproachingLeadDays = 2,
    this.cycleTrackingMode = 'tracking',
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
    // Daily crate reminder
    bool? dailyCrateReminders,
    String? dailyCrateReminderTime,
    // Proactive health coaching (Phase C2)
    bool? dailyBriefingNudge,
    String? dailyBriefingTime,
    bool? healthAnomalyNudge,
    bool? activityGoalNudge,
    String? activityNudgeTime,
    // Frequency preset
    String? frequencyPreset,
    // Bundle times
    String? morningBundleTime,
    String? middayBundleTime,
    String? afternoonNudgeTime,
    String? eveningBundleTime,
    // Weekend scheduling
    bool? weekendTimesEnabled,
    String? morningBundleTimeWeekend,
    String? middayBundleTimeWeekend,
    String? eveningBundleTimeWeekend,
    // Bundle content toggles
    bool? morningIncludeWorkout,
    bool? morningIncludeBreakfast,
    bool? morningIncludeMotivation,
    bool? middayIncludeLunch,
    bool? middayIncludeHydration,
    bool? eveningIncludeDinner,
    bool? eveningIncludeStreak,
    bool? eveningIncludeProgress,
    // Style preferences
    bool? notificationEmoji,
    bool? notificationVibration,
    // Cycle tracking reminders (Phase E)
    bool? cycleRemindersMaster,
    bool? cyclePeriodApproaching,
    bool? cyclePeriodStart,
    bool? cycleFertileWindow,
    bool? cyclePeakFertility,
    bool? cycleBbtReminder,
    String? cycleBbtReminderTime,
    bool? cycleSymptomCheckin,
    String? cycleSymptomCheckinTime,
    bool? cycleLatePeriodAlert,
    String? cycleReminderTimeOfDay,
    int? cyclePeriodApproachingLeadDays,
    String? cycleTrackingMode,
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
      // Daily crate reminder
      dailyCrateReminders: dailyCrateReminders ?? this.dailyCrateReminders,
      dailyCrateReminderTime: dailyCrateReminderTime ?? this.dailyCrateReminderTime,
      // Proactive health coaching (Phase C2)
      dailyBriefingNudge: dailyBriefingNudge ?? this.dailyBriefingNudge,
      dailyBriefingTime: dailyBriefingTime ?? this.dailyBriefingTime,
      healthAnomalyNudge: healthAnomalyNudge ?? this.healthAnomalyNudge,
      activityGoalNudge: activityGoalNudge ?? this.activityGoalNudge,
      activityNudgeTime: activityNudgeTime ?? this.activityNudgeTime,
      // Frequency preset
      frequencyPreset: frequencyPreset ?? this.frequencyPreset,
      // Bundle times
      morningBundleTime: morningBundleTime ?? this.morningBundleTime,
      middayBundleTime: middayBundleTime ?? this.middayBundleTime,
      afternoonNudgeTime: afternoonNudgeTime ?? this.afternoonNudgeTime,
      eveningBundleTime: eveningBundleTime ?? this.eveningBundleTime,
      // Weekend scheduling
      weekendTimesEnabled: weekendTimesEnabled ?? this.weekendTimesEnabled,
      morningBundleTimeWeekend: morningBundleTimeWeekend ?? this.morningBundleTimeWeekend,
      middayBundleTimeWeekend: middayBundleTimeWeekend ?? this.middayBundleTimeWeekend,
      eveningBundleTimeWeekend: eveningBundleTimeWeekend ?? this.eveningBundleTimeWeekend,
      // Bundle content toggles
      morningIncludeWorkout: morningIncludeWorkout ?? this.morningIncludeWorkout,
      morningIncludeBreakfast: morningIncludeBreakfast ?? this.morningIncludeBreakfast,
      morningIncludeMotivation: morningIncludeMotivation ?? this.morningIncludeMotivation,
      middayIncludeLunch: middayIncludeLunch ?? this.middayIncludeLunch,
      middayIncludeHydration: middayIncludeHydration ?? this.middayIncludeHydration,
      eveningIncludeDinner: eveningIncludeDinner ?? this.eveningIncludeDinner,
      eveningIncludeStreak: eveningIncludeStreak ?? this.eveningIncludeStreak,
      eveningIncludeProgress: eveningIncludeProgress ?? this.eveningIncludeProgress,
      // Style preferences
      notificationEmoji: notificationEmoji ?? this.notificationEmoji,
      notificationVibration: notificationVibration ?? this.notificationVibration,
      // Cycle tracking reminders (Phase E)
      cycleRemindersMaster: cycleRemindersMaster ?? this.cycleRemindersMaster,
      cyclePeriodApproaching:
          cyclePeriodApproaching ?? this.cyclePeriodApproaching,
      cyclePeriodStart: cyclePeriodStart ?? this.cyclePeriodStart,
      cycleFertileWindow: cycleFertileWindow ?? this.cycleFertileWindow,
      cyclePeakFertility: cyclePeakFertility ?? this.cyclePeakFertility,
      cycleBbtReminder: cycleBbtReminder ?? this.cycleBbtReminder,
      cycleBbtReminderTime: cycleBbtReminderTime ?? this.cycleBbtReminderTime,
      cycleSymptomCheckin: cycleSymptomCheckin ?? this.cycleSymptomCheckin,
      cycleSymptomCheckinTime:
          cycleSymptomCheckinTime ?? this.cycleSymptomCheckinTime,
      cycleLatePeriodAlert: cycleLatePeriodAlert ?? this.cycleLatePeriodAlert,
      cycleReminderTimeOfDay:
          cycleReminderTimeOfDay ?? this.cycleReminderTimeOfDay,
      cyclePeriodApproachingLeadDays:
          cyclePeriodApproachingLeadDays ?? this.cyclePeriodApproachingLeadDays,
      cycleTrackingMode: cycleTrackingMode ?? this.cycleTrackingMode,
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
        // Daily crate reminder
        'daily_crate_reminders': dailyCrateReminders,
        'daily_crate_reminder_time': dailyCrateReminderTime,
        // Proactive health coaching (Phase C2) — keys consumed by the
        // push_nudge_cron daily_readiness / health_anomaly / activity_goal jobs.
        'daily_briefing_nudge': dailyBriefingNudge,
        'daily_briefing_time': dailyBriefingTime,
        'health_anomaly_nudge': healthAnomalyNudge,
        'activity_goal_nudge': activityGoalNudge,
        'activity_nudge_time': activityNudgeTime,
        // Frequency preset
        'frequency_preset': frequencyPreset,
        // Bundle times
        'morning_bundle_time': morningBundleTime,
        'midday_bundle_time': middayBundleTime,
        'afternoon_nudge_time': afternoonNudgeTime,
        'evening_bundle_time': eveningBundleTime,
        // Weekend scheduling
        'weekend_times_enabled': weekendTimesEnabled,
        'morning_bundle_time_weekend': morningBundleTimeWeekend,
        'midday_bundle_time_weekend': middayBundleTimeWeekend,
        'evening_bundle_time_weekend': eveningBundleTimeWeekend,
        // Bundle content toggles
        'morning_include_workout': morningIncludeWorkout,
        'morning_include_breakfast': morningIncludeBreakfast,
        'morning_include_motivation': morningIncludeMotivation,
        'midday_include_lunch': middayIncludeLunch,
        'midday_include_hydration': middayIncludeHydration,
        'evening_include_dinner': eveningIncludeDinner,
        'evening_include_streak': eveningIncludeStreak,
        'evening_include_progress': eveningIncludeProgress,
        // Style preferences
        'notification_emoji': notificationEmoji,
        'notification_vibration': notificationVibration,
        // Cycle tracking reminders (Phase E). Synced so the backend can also
        // suppress its server-side cycle nudges per the user's choice — only
        // CONTENT-FREE booleans / times leave the device, never cycle data.
        'cycle_reminders_master': cycleRemindersMaster,
        'cycle_period_approaching': cyclePeriodApproaching,
        'cycle_period_start': cyclePeriodStart,
        'cycle_fertile_window': cycleFertileWindow,
        'cycle_peak_fertility': cyclePeakFertility,
        'cycle_bbt_reminder': cycleBbtReminder,
        'cycle_bbt_reminder_time': cycleBbtReminderTime,
        'cycle_symptom_checkin': cycleSymptomCheckin,
        'cycle_symptom_checkin_time': cycleSymptomCheckinTime,
        'cycle_late_period_alert': cycleLatePeriodAlert,
        'cycle_reminder_time_of_day': cycleReminderTimeOfDay,
        'cycle_period_approaching_lead_days': cyclePeriodApproachingLeadDays,
        'cycle_tracking_mode': cycleTrackingMode,
      };
}


/// Callback type for storing received notifications
typedef OnNotificationReceivedCallback = void Function({
  required String title,
  required String body,
  String? type,
  Map<String, dynamic>? data,
});

