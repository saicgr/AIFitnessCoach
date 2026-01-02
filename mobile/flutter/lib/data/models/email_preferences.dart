/// Email preferences model.
///
/// Represents user email subscription preferences for managing
/// what types of emails they receive from FitWiz.
library;

class EmailPreferences {
  /// Unique identifier for the preferences record
  final String id;

  /// The user ID these preferences belong to
  final String userId;

  /// Whether to receive daily workout reminder emails
  final bool workoutReminders;

  /// Whether to receive weekly progress summary emails
  final bool weeklySummary;

  /// Whether to receive AI coach tips and motivational emails
  final bool coachTips;

  /// Whether to receive product update emails (new features, updates)
  final bool productUpdates;

  /// Whether to receive promotional emails (offers, discounts)
  /// This is opt-in by default (false)
  final bool promotional;

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
