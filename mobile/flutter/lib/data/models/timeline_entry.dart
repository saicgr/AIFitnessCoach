/// Timeline domain models — mirror the backend `/api/v1/timeline` response.
///
/// Layout:
///   TimelineResponse
///     ├── days: List<TimelineDay>
///     │     ├── date, dayLabel
///     │     ├── summary: TimelineSummary
///     │     ├── insights: List<String>
///     │     └── entries: List<TimelineEntry>
///     │           └── achievementChips: List<TimelineAchievement>
///
/// Plain Dart classes (no freezed/build_runner) to comply with the
/// project's "do NOT run build_runner" rule (memory).
library;

import 'package:flutter/foundation.dart';

@immutable
class TimelineSource {
  final String kind; // raw key (e.g. 'chat', 'menu_scan', 'apple_health')
  final String label; // human-readable ('Chat', 'Menu Scan', 'Apple Health')
  final String icon; // material icon name

  const TimelineSource({required this.kind, required this.label, required this.icon});

  factory TimelineSource.fromJson(Map<String, dynamic> json) => TimelineSource(
        kind: json['kind'] as String? ?? 'unknown',
        label: json['label'] as String? ?? 'Logged',
        icon: json['icon'] as String? ?? 'edit',
      );

  Map<String, dynamic> toJson() => {'kind': kind, 'label': label, 'icon': icon};
}

@immutable
class TimelineAchievement {
  final String kind; // strength_pr, e1rm_pr, weight_milestone, streak_milestone, ...
  final String label; // pre-formatted display string
  final String icon;
  final Map<String, dynamic> metadata;

  const TimelineAchievement({
    required this.kind,
    required this.label,
    required this.icon,
    this.metadata = const {},
  });

  factory TimelineAchievement.fromJson(Map<String, dynamic> json) => TimelineAchievement(
        kind: json['kind'] as String? ?? 'unknown',
        label: json['label'] as String? ?? '',
        icon: json['icon'] as String? ?? 'emoji_events',
        metadata: Map<String, dynamic>.from(json),
      );
}

@immutable
class TimelineEntry {
  /// e.g. "workout:<uuid>" / "food:<uuid>" / "water:<uuid>".
  final String id;

  /// One of: workout, food, water, sleep, weight, mood, habit, achievement.
  final String type;

  /// ISO8601 UTC timestamp. Frontend renders in user TZ.
  final String occurredAt;

  final String title;
  final String? subtitle;
  final String icon;
  final TimelineSource source;
  final Map<String, dynamic> metadata;

  /// Optional inline achievements (PRs, e1RM gains).
  final List<TimelineAchievement> achievementChips;

  /// Optional photo / video attachments — currently used only by food
  /// entries that include `image_url`.
  final List<Map<String, dynamic>> attachments;

  /// Optional coach commentary attached to this entry.
  final String? coachNote;

  /// Available actions for this entry (edit, delete, reLog, share).
  final List<String> actions;

  const TimelineEntry({
    required this.id,
    required this.type,
    required this.occurredAt,
    required this.title,
    required this.icon,
    required this.source,
    this.subtitle,
    this.metadata = const {},
    this.achievementChips = const [],
    this.attachments = const [],
    this.coachNote,
    this.actions = const [],
  });

  factory TimelineEntry.fromJson(Map<String, dynamic> json) {
    return TimelineEntry(
      id: json['id'] as String,
      type: json['type'] as String,
      occurredAt: json['occurred_at'] as String,
      title: json['title'] as String? ?? 'Logged',
      subtitle: json['subtitle'] as String?,
      icon: json['icon'] as String? ?? 'edit',
      source: TimelineSource.fromJson(
        (json['source'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      metadata: ((json['metadata'] as Map?)?.cast<String, dynamic>()) ?? const {},
      achievementChips: ((json['achievement_chips'] as List?) ?? const [])
          .map((e) => TimelineAchievement.fromJson(
              (e as Map).cast<String, dynamic>()))
          .toList(growable: false),
      attachments: ((json['attachments'] as List?) ?? const [])
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList(growable: false),
      coachNote: json['coach_note'] as String?,
      actions: ((json['actions'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
    );
  }
}

/// Per-day rollup numbers shown in the day-summary card.
@immutable
class TimelineSummary {
  final int workoutsCount;
  final int workoutsTotalMinutes;
  final int caloriesBurned;
  final int caloriesEaten;
  final int caloriesNet;
  final int proteinG;
  final int waterMl;
  final int waterGoalMl;
  final int sleepMinutes;
  final String? sleepQuality;
  final String? mood;
  final int habitsCompleted;
  final int? streakDay;
  final int? xpEarned;
  final int? steps;
  final int? activeMinutes;

  const TimelineSummary({
    this.workoutsCount = 0,
    this.workoutsTotalMinutes = 0,
    this.caloriesBurned = 0,
    this.caloriesEaten = 0,
    this.caloriesNet = 0,
    this.proteinG = 0,
    this.waterMl = 0,
    this.waterGoalMl = 0,
    this.sleepMinutes = 0,
    this.sleepQuality,
    this.mood,
    this.habitsCompleted = 0,
    this.streakDay,
    this.xpEarned,
    this.steps,
    this.activeMinutes,
  });

  factory TimelineSummary.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) =>
        v is int ? v : (v is num ? v.toInt() : (v is String ? int.tryParse(v) ?? 0 : 0));
    int? asNullableInt(dynamic v) =>
        v == null ? null : asInt(v);

    return TimelineSummary(
      workoutsCount: asInt(json['workouts_count']),
      workoutsTotalMinutes: asInt(json['workouts_total_minutes']),
      caloriesBurned: asInt(json['calories_burned']),
      caloriesEaten: asInt(json['calories_eaten']),
      caloriesNet: asInt(json['calories_net']),
      proteinG: asInt(json['protein_g']),
      waterMl: asInt(json['water_ml']),
      waterGoalMl: asInt(json['water_goal_ml']),
      sleepMinutes: asInt(json['sleep_minutes']),
      sleepQuality: json['sleep_quality'] as String?,
      mood: json['mood'] as String?,
      habitsCompleted: asInt(json['habits_completed']),
      streakDay: asNullableInt(json['streak_day']),
      xpEarned: asNullableInt(json['xp_earned']),
      steps: asNullableInt(json['steps']),
      activeMinutes: asNullableInt(json['active_minutes']),
    );
  }
}

@immutable
class TimelineDay {
  final String date; // YYYY-MM-DD (user-local)
  final String dayLabel; // "Today", "Yesterday", "Thu, May 7"
  final TimelineSummary summary;
  final List<String> insights;
  final List<TimelineEntry> entries;

  const TimelineDay({
    required this.date,
    required this.dayLabel,
    required this.summary,
    required this.insights,
    required this.entries,
  });

  factory TimelineDay.fromJson(Map<String, dynamic> json) {
    return TimelineDay(
      date: json['date'] as String,
      dayLabel: json['day_label'] as String? ?? json['date'] as String,
      summary: TimelineSummary.fromJson(
        (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      insights: ((json['insights'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      entries: ((json['entries'] as List?) ?? const [])
          .map((e) =>
              TimelineEntry.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false),
    );
  }
}

@immutable
class TimelineResponse {
  final String userId;
  final String userTz;
  final List<TimelineDay> days;
  final String generatedAt;

  const TimelineResponse({
    required this.userId,
    required this.userTz,
    required this.days,
    required this.generatedAt,
  });

  factory TimelineResponse.fromJson(Map<String, dynamic> json) {
    return TimelineResponse(
      userId: json['user_id'] as String? ?? '',
      userTz: json['user_tz'] as String? ?? 'UTC',
      days: ((json['days'] as List?) ?? const [])
          .map((e) =>
              TimelineDay.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false),
      generatedAt: json['generated_at'] as String? ?? '',
    );
  }
}

/// Frontend-only filter chips for the Timeline section header.
enum TimelineFilter { all, workouts, food, water, sleep, wellness }

extension TimelineFilterX on TimelineFilter {
  String get label {
    switch (this) {
      case TimelineFilter.all:
        return 'All';
      case TimelineFilter.workouts:
        return 'Workouts';
      case TimelineFilter.food:
        return 'Food';
      case TimelineFilter.water:
        return 'Water';
      case TimelineFilter.sleep:
        return 'Sleep';
      case TimelineFilter.wellness:
        return 'Wellness';
    }
  }

  bool matches(TimelineEntry e) {
    switch (this) {
      case TimelineFilter.all:
        return true;
      case TimelineFilter.workouts:
        return e.type == 'workout';
      case TimelineFilter.food:
        return e.type == 'food';
      case TimelineFilter.water:
        return e.type == 'water';
      case TimelineFilter.sleep:
        return e.type == 'sleep';
      case TimelineFilter.wellness:
        return e.type == 'mood' || e.type == 'weight' || e.type == 'habit';
    }
  }
}
