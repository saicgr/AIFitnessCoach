/// Email preferences model.
///
/// Represents user email subscription preferences for managing
/// what types of emails they receive from Zealova.
library;

class EmailPreferences {
  /// Unique identifier for the preferences record
  final String id;

  /// The user ID these preferences belong to
  final String userId;

  /// Workout reminder emails (before-session reminder, per-user time)
  final bool workoutReminders;

  /// Weekly progress summary (Sunday recap with nutrition + XP + streaks)
  final bool weeklySummary;

  /// Motivational nudges from the user's selected coach persona
  /// (day-3 activation, onboarding-incomplete, comeback, idle, one-workout-wonder).
  /// Formerly called "coachTips" — same column on the backend for compatibility.
  final bool coachTips;

  /// Product update emails (new features, release notes)
  final bool productUpdates;

  /// Promotional offers + discounts. Opt-in (false by default).
  final bool promotional;

  /// Streak-at-risk alerts. Independent of workoutReminders so users can
  /// keep streak protection without daily workout nudges.
  final bool streakAlerts;

  /// Missed-workout nudges (after the scheduled time passes without a log).
  final bool missedWorkoutAlerts;

  /// Achievement unlock emails (trophies + first-workout-done).
  final bool achievementAlerts;

  /// Billing & account emails (purchase, billing issue, trial expiry,
  /// cancellation). Cannot be disabled — legally required transactional.
  final bool billingAccount;

  /// Deliverable flag. Flipped to false after 3 hard bounces or a complaint;
  /// read-only in the UI. Displayed as a banner if false.
  final bool deliverable;

  /// Vacation mode — if set and in the future, all non-transactional sends
  /// are paused until this timestamp passes.
  final DateTime? notificationsPausedUntil;

  /// When the preferences were created
  final DateTime createdAt;

  /// When the preferences were last updated
  final DateTime updatedAt;

  const EmailPreferences({
    required this.id,
    required this.userId,
    this.workoutReminders = true,
    this.weeklySummary = true,
    this.coachTips = true,
    this.productUpdates = true,
    this.promotional = false,
    this.streakAlerts = true,
    this.missedWorkoutAlerts = true,
    this.achievementAlerts = true,
    this.billingAccount = true,
    this.deliverable = true,
    this.notificationsPausedUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create default preferences for a new user
  factory EmailPreferences.defaults(String userId) {
    final now = DateTime.now();
    return EmailPreferences(
      id: '',
      userId: userId,
      workoutReminders: true,
      weeklySummary: true,
      coachTips: true,
      productUpdates: true,
      promotional: false,
      streakAlerts: true,
      missedWorkoutAlerts: true,
      achievementAlerts: true,
      billingAccount: true,
      deliverable: true,
      notificationsPausedUntil: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create from JSON response
  factory EmailPreferences.fromJson(Map<String, dynamic> json) {
    return EmailPreferences(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      workoutReminders: json['workout_reminders'] as bool? ?? true,
      weeklySummary: json['weekly_summary'] as bool? ?? true,
      coachTips: json['coach_tips'] as bool? ?? true,
      productUpdates: json['product_updates'] as bool? ?? true,
      promotional: json['promotional'] as bool? ?? false,
      streakAlerts: json['streak_alerts'] as bool? ?? true,
      missedWorkoutAlerts: json['missed_workout_alerts'] as bool? ?? true,
      achievementAlerts: json['achievement_alerts'] as bool? ?? true,
      billingAccount: json['billing_account'] as bool? ?? true,
      deliverable: json['deliverable'] as bool? ?? true,
      notificationsPausedUntil: json['notifications_paused_until'] != null
          ? DateTime.parse(json['notifications_paused_until'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'workout_reminders': workoutReminders,
      'weekly_summary': weeklySummary,
      'coach_tips': coachTips,
      'product_updates': productUpdates,
      'promotional': promotional,
      'streak_alerts': streakAlerts,
      'missed_workout_alerts': missedWorkoutAlerts,
      'achievement_alerts': achievementAlerts,
      // billing_account is not sent in PUT — always true, cannot be disabled.
      if (notificationsPausedUntil != null)
        'notifications_paused_until': notificationsPausedUntil!.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  EmailPreferences copyWith({
    String? id,
    String? userId,
    bool? workoutReminders,
    bool? weeklySummary,
    bool? coachTips,
    bool? productUpdates,
    bool? promotional,
    bool? streakAlerts,
    bool? missedWorkoutAlerts,
    bool? achievementAlerts,
    bool? billingAccount,
    bool? deliverable,
    DateTime? notificationsPausedUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmailPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workoutReminders: workoutReminders ?? this.workoutReminders,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      coachTips: coachTips ?? this.coachTips,
      productUpdates: productUpdates ?? this.productUpdates,
      promotional: promotional ?? this.promotional,
      streakAlerts: streakAlerts ?? this.streakAlerts,
      missedWorkoutAlerts: missedWorkoutAlerts ?? this.missedWorkoutAlerts,
      achievementAlerts: achievementAlerts ?? this.achievementAlerts,
      billingAccount: billingAccount ?? this.billingAccount,
      deliverable: deliverable ?? this.deliverable,
      notificationsPausedUntil:
          notificationsPausedUntil ?? this.notificationsPausedUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if all marketing emails are disabled
  bool get isAllMarketingDisabled =>
      !weeklySummary && !coachTips && !productUpdates && !promotional;

  /// Check if all email types are enabled
  bool get isAllEnabled =>
      workoutReminders &&
      weeklySummary &&
      coachTips &&
      productUpdates &&
      promotional;

  /// Count of enabled email types
  int get enabledCount {
    int count = 0;
    if (workoutReminders) count++;
    if (weeklySummary) count++;
    if (coachTips) count++;
    if (productUpdates) count++;
    if (promotional) count++;
    return count;
  }

  @override
  String toString() {
    return 'EmailPreferences(id: $id, userId: $userId, '
        'workoutReminders: $workoutReminders, weeklySummary: $weeklySummary, '
        'coachTips: $coachTips, productUpdates: $productUpdates, '
        'promotional: $promotional)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmailPreferences &&
        other.id == id &&
        other.userId == userId &&
        other.workoutReminders == workoutReminders &&
        other.weeklySummary == weeklySummary &&
        other.coachTips == coachTips &&
        other.productUpdates == productUpdates &&
        other.promotional == promotional;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      workoutReminders,
      weeklySummary,
      coachTips,
      productUpdates,
      promotional,
    );
  }
}


/// Response from unsubscribe marketing action
class UnsubscribeMarketingResponse {
  final bool success;
  final String message;
  final EmailPreferences preferences;

  const UnsubscribeMarketingResponse({
    required this.success,
    required this.message,
    required this.preferences,
  });

  factory UnsubscribeMarketingResponse.fromJson(Map<String, dynamic> json) {
    return UnsubscribeMarketingResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      preferences: EmailPreferences.fromJson(
        json['preferences'] as Map<String, dynamic>,
      ),
    );
  }
}
