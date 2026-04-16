/// Scheduled recipe log models — recurring + batch (cook-once-eat-many).
library;

enum ScheduleMode {
  recurring('recurring'),
  batch('batch');

  final String value;
  const ScheduleMode(this.value);
  static ScheduleMode fromValue(String? v) =>
      ScheduleMode.values.firstWhere((e) => e.value == v, orElse: () => ScheduleMode.recurring);
}

enum ScheduleKind {
  daily('daily'),
  weekdays('weekdays'),
  weekends('weekends'),
  custom('custom');

  final String value;
  const ScheduleKind(this.value);
  static ScheduleKind? fromValue(String? v) =>
      v == null ? null : ScheduleKind.values.firstWhere((e) => e.value == v, orElse: () => ScheduleKind.daily);
}

enum MealSlot {
  breakfast('breakfast'),
  lunch('lunch'),
  dinner('dinner'),
  snack('snack');

  final String value;
  const MealSlot(this.value);
  static MealSlot fromValue(String? v) =>
      MealSlot.values.firstWhere((e) => e.value == v, orElse: () => MealSlot.lunch);
}

class BatchSlot {
  final DateTime localDate; // date-only; .day/month/year used
  final MealSlot mealType;
  final String localTime;   // "HH:MM" 24h
  final double servings;

  const BatchSlot({
    required this.localDate,
    required this.mealType,
    required this.localTime,
    this.servings = 1.0,
  });

  factory BatchSlot.fromJson(Map<String, dynamic> json) => BatchSlot(
        localDate: DateTime.parse(json['local_date'] as String),
        mealType: MealSlot.fromValue(json['meal_type'] as String?),
        localTime: json['local_time'] as String,
        servings: (json['servings'] as num?)?.toDouble() ?? 1.0,
      );

  Map<String, dynamic> toJson() => {
        'local_date': '${localDate.year.toString().padLeft(4, '0')}-'
            '${localDate.month.toString().padLeft(2, '0')}-'
            '${localDate.day.toString().padLeft(2, '0')}',
        'meal_type': mealType.value,
        'local_time': localTime,
        'servings': servings,
      };
}

class ScheduledRecipeLogCreate {
  final String recipeId;
  final ScheduleMode scheduleMode;
  final MealSlot mealType;
  final double servings;
  final String timezone;
  final bool silentLog;
  // recurring
  final ScheduleKind? scheduleKind;
  final List<int>? daysOfWeek; // 0=Sun..6=Sat
  final String? localTime;     // "HH:MM"
  // batch
  final String? cookEventId;
  final List<BatchSlot>? batchSlots;

  const ScheduledRecipeLogCreate({
    required this.recipeId,
    required this.mealType,
    required this.timezone,
    this.scheduleMode = ScheduleMode.recurring,
    this.servings = 1.0,
    this.silentLog = false,
    this.scheduleKind,
    this.daysOfWeek,
    this.localTime,
    this.cookEventId,
    this.batchSlots,
  });

  Map<String, dynamic> toJson() => {
        'recipe_id': recipeId,
        'schedule_mode': scheduleMode.value,
        'meal_type': mealType.value,
        'servings': servings,
        'timezone': timezone,
        'silent_log': silentLog,
        if (scheduleKind != null) 'schedule_kind': scheduleKind!.value,
        if (daysOfWeek != null) 'days_of_week': daysOfWeek,
        if (localTime != null) 'local_time': localTime,
        if (cookEventId != null) 'cook_event_id': cookEventId,
        if (batchSlots != null)
          'batch_slots': batchSlots!.map((s) => s.toJson()).toList(),
      };
}

class ScheduledRecipeLog {
  final String id;
  final String userId;
  final String? recipeId;
  final ScheduleMode scheduleMode;
  final MealSlot mealType;
  final double servings;
  final ScheduleKind? scheduleKind;
  final List<int>? daysOfWeek;
  final String? localTime;
  final String timezone;
  final DateTime nextFireAt;
  final DateTime? lastFiredAt;
  final String? cookEventId;
  final List<BatchSlot>? batchSlots;
  final int nextSlotIndex;
  final DateTime? pausedUntil;
  final bool enabled;
  final bool silentLog;

  const ScheduledRecipeLog({
    required this.id,
    required this.userId,
    required this.scheduleMode,
    required this.mealType,
    required this.servings,
    required this.timezone,
    required this.nextFireAt,
    required this.nextSlotIndex,
    required this.enabled,
    required this.silentLog,
    this.recipeId,
    this.scheduleKind,
    this.daysOfWeek,
    this.localTime,
    this.lastFiredAt,
    this.cookEventId,
    this.batchSlots,
    this.pausedUntil,
  });

  factory ScheduledRecipeLog.fromJson(Map<String, dynamic> json) => ScheduledRecipeLog(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        recipeId: json['recipe_id'] as String?,
        scheduleMode: ScheduleMode.fromValue(json['schedule_mode'] as String?),
        mealType: MealSlot.fromValue(json['meal_type'] as String?),
        servings: (json['servings'] as num?)?.toDouble() ?? 1.0,
        scheduleKind: ScheduleKind.fromValue(json['schedule_kind'] as String?),
        daysOfWeek: (json['days_of_week'] as List?)?.map((e) => e as int).toList(),
        localTime: json['local_time'] as String?,
        timezone: json['timezone'] as String,
        nextFireAt: DateTime.parse(json['next_fire_at'] as String),
        lastFiredAt: json['last_fired_at'] != null ? DateTime.parse(json['last_fired_at']) : null,
        cookEventId: json['cook_event_id'] as String?,
        batchSlots: (json['batch_slots'] as List?)
            ?.map((e) => BatchSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextSlotIndex: (json['next_slot_index'] as int?) ?? 0,
        pausedUntil: json['paused_until'] != null ? DateTime.parse(json['paused_until']) : null,
        enabled: json['enabled'] as bool? ?? true,
        silentLog: json['silent_log'] as bool? ?? false,
      );
}

class UpcomingScheduledFire {
  final String scheduleId;
  final String? recipeId;
  final String? recipeName;
  final String? recipeImageUrl;
  final MealSlot mealType;
  final double servings;
  final DateTime fireAt;
  final ScheduleMode scheduleMode;
  final bool isBatchLastSlot;

  const UpcomingScheduledFire({
    required this.scheduleId,
    required this.mealType,
    required this.servings,
    required this.fireAt,
    required this.scheduleMode,
    required this.isBatchLastSlot,
    this.recipeId,
    this.recipeName,
    this.recipeImageUrl,
  });

  factory UpcomingScheduledFire.fromJson(Map<String, dynamic> json) => UpcomingScheduledFire(
        scheduleId: json['schedule_id'] as String,
        recipeId: json['recipe_id'] as String?,
        recipeName: json['recipe_name'] as String?,
        recipeImageUrl: json['recipe_image_url'] as String?,
        mealType: MealSlot.fromValue(json['meal_type'] as String?),
        servings: (json['servings'] as num?)?.toDouble() ?? 1.0,
        fireAt: DateTime.parse(json['fire_at'] as String),
        scheduleMode: ScheduleMode.fromValue(json['schedule_mode'] as String?),
        isBatchLastSlot: json['is_batch_last_slot'] as bool? ?? false,
      );
}
