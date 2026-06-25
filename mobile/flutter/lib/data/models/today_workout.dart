/// Models for the today's workout quick start feature
library;

import 'package:flutter/foundation.dart';

import 'exercise.dart';
import 'workout.dart';

/// Summary info for quick display on home screen
class TodayWorkoutSummary {
  final String id;
  final String name;
  final String type;
  final String difficulty;
  final int durationMinutes;
  final int? durationMinutesMin;
  final int? durationMinutesMax;
  final int exerciseCount;
  final List<String> primaryMuscles;
  final String scheduledDate;
  final bool isToday;
  final bool isCompleted;
  final List<WorkoutExercise> exercises;
  final String? generationMethod;

  // ── Program provenance (Program Library integration) ──────────────────────
  // The backend tags each program-sourced workout in the /today payload with
  // these fields. They flow through [toWorkout] into `generation_metadata` so
  // the codegen-locked [Workout] (no build_runner — see project_codegen_gotcha)
  // can carry them to the carousel / active-workout banner via
  // [WorkoutProgramContext].
  final String? programId;
  final String? programName;
  final int? programWeek;

  /// `primary` drives the home hero; `addon` stacks beneath it. Defaults to
  /// `primary` for back-compat with untagged (AI / ad-hoc) workouts.
  final String programSlot;
  final String? assignmentId;
  final int? programDurationWeeks;

  const TodayWorkoutSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.difficulty,
    required this.durationMinutes,
    this.durationMinutesMin,
    this.durationMinutesMax,
    required this.exerciseCount,
    required this.primaryMuscles,
    required this.scheduledDate,
    required this.isToday,
    required this.isCompleted,
    this.exercises = const [],
    this.generationMethod,
    this.programId,
    this.programName,
    this.programWeek,
    this.programSlot = 'primary',
    this.assignmentId,
    this.programDurationWeeks,
  });

  /// True when this workout came from an enrolled program.
  bool get isFromProgram => programId != null && programId!.isNotEmpty;

  /// True when this is a stacked add-on (vs the primary plan for the day).
  bool get isProgramAddon => programSlot.toLowerCase() == 'addon';

  /// Get formatted duration display (e.g., "45-60m" or "45m")
  String get formattedDurationShort {
    if (durationMinutesMin != null && durationMinutesMax != null &&
        durationMinutesMin != durationMinutesMax) {
      return '$durationMinutesMin-${durationMinutesMax}m';
    }
    return '${durationMinutes}m';
  }

  factory TodayWorkoutSummary.fromJson(Map<String, dynamic> json) {
    // Parse exercises from JSON array
    final exercisesJson = json['exercises'] as List<dynamic>? ?? [];
    debugPrint('🔍 [TodayWorkoutSummary.fromJson] workout_id=${json['id']}, '
        'exercises_count=${exercisesJson.length}, '
        'exercise_count_field=${json['exercise_count']}');

    final exercises = exercisesJson
        .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
        .toList();

    // Program tags can arrive as top-level snake_case keys (the /today row) or
    // nested inside generation_metadata. Read top-level first, fall back to the
    // nested blob.
    final meta = json['generation_metadata'];
    final metaMap = meta is Map ? Map<String, dynamic>.from(meta) : const {};
    String? pick(String key) =>
        (json[key] ?? metaMap[key])?.toString();
    int? pickInt(String key) => _summaryInt(json[key] ?? metaMap[key]);

    return TodayWorkoutSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Workout',
      type: json['type'] as String? ?? 'strength',
      difficulty: json['difficulty'] as String? ?? 'medium',
      durationMinutes: json['duration_minutes'] as int? ?? 45,
      durationMinutesMin: json['duration_minutes_min'] as int?,
      durationMinutesMax: json['duration_minutes_max'] as int?,
      exerciseCount: json['exercise_count'] as int? ?? 0,
      primaryMuscles: (json['primary_muscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      scheduledDate: json['scheduled_date'] as String? ?? '',
      isToday: json['is_today'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      exercises: exercises,
      generationMethod: json['generation_method'] as String?,
      programId: pick('program_id'),
      programName: pick('program_name'),
      programWeek: pickInt('program_week'),
      programSlot: pick('program_slot') ?? 'primary',
      assignmentId: pick('assignment_id'),
      programDurationWeeks:
          pickInt('program_duration_weeks') ?? pickInt('duration_weeks'),
    );
  }

  /// Loose int coercion for the program tags (backend may emit num/str).
  static int? _summaryInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'difficulty': difficulty,
        'duration_minutes': durationMinutes,
        'duration_minutes_min': durationMinutesMin,
        'duration_minutes_max': durationMinutesMax,
        'exercise_count': exerciseCount,
        'primary_muscles': primaryMuscles,
        'scheduled_date': scheduledDate,
        'is_today': isToday,
        'is_completed': isCompleted,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'generation_method': generationMethod,
        if (programId != null) 'program_id': programId,
        if (programName != null) 'program_name': programName,
        if (programWeek != null) 'program_week': programWeek,
        'program_slot': programSlot,
        if (assignmentId != null) 'assignment_id': assignmentId,
        if (programDurationWeeks != null)
          'program_duration_weeks': programDurationWeeks,
      };

  /// Convert to full Workout object for NextWorkoutCard compatibility.
  ///
  /// Program tags ride through `generation_metadata` (the codegen-locked
  /// [Workout] can't grow new typed columns — see project_codegen_gotcha), so
  /// [WorkoutProgramContextX.programContext] can read them on the carousel /
  /// active-workout banner.
  Workout toWorkout() => Workout(
        id: id,
        name: name,
        type: type,
        difficulty: difficulty,
        durationMinutes: durationMinutes,
        durationMinutesMin: durationMinutesMin,
        durationMinutesMax: durationMinutesMax,
        scheduledDate: scheduledDate,
        isCompleted: isCompleted,
        exercisesJson: exercises.map((e) => e.toJson()).toList(),
        // Pass the API's exercise count so it can be used as fallback
        knownExerciseCount: exerciseCount,
        generationMethod: generationMethod,
        generationMetadata: isFromProgram
            ? {
                'program_id': programId,
                if (programName != null) 'program_name': programName,
                if (programWeek != null) 'program_week': programWeek,
                'program_slot': programSlot,
                if (assignmentId != null) 'assignment_id': assignmentId,
                if (programDurationWeeks != null)
                  'program_duration_weeks': programDurationWeeks,
              }
            : null,
      );
}

/// Response model for today's workout endpoint
class TodayWorkoutResponse {
  final bool hasWorkoutToday;
  final TodayWorkoutSummary? todayWorkout;
  final TodayWorkoutSummary? nextWorkout;
  final int? daysUntilNext;
  final String? restDayMessage;
  // Completed workout info (if user already completed today's workout)
  final bool completedToday;
  final TodayWorkoutSummary? completedWorkout;
  // Extra today workouts (quick workouts coexisting with scheduled workout)
  final List<TodayWorkoutSummary> extraTodayWorkouts;
  // Generation status fields - used when auto-generating workout
  final bool isGenerating;
  final String? generationMessage;
  // Auto-generation trigger fields
  final bool needsGeneration;
  final String? nextWorkoutDate;  // YYYY-MM-DD format for frontend to generate
  // Gym profile context
  final String? gymProfileId;  // Active gym profile ID used for filtering
  // Set when auto-generation polling caps out OR the backend returns a
  // terminal "no workout, no next, not generating" state for the user's
  // selected day. Hero card renders a "tap to retry" CTA when this is
  // populated instead of falling through to a silent "No workout yet"
  // dead-end. Frontend-only field, not persisted in the API contract.
  final String? lastGenerationError;

  /// Whether there's any displayable content for the home screen.
  /// Used by provider normalization and loading screen to make display decisions.
  /// When true, isGenerating should never block the UI from showing content.
  bool get hasDisplayableContent =>
      todayWorkout != null || nextWorkout != null || completedToday || restDayMessage != null;

  /// Today's PRIMARY workout (the home hero). The backend marks the primary
  /// plan via `program_slot != 'addon'` (or no slot at all for AI / ad-hoc).
  /// Falls back to [todayWorkout] which is already the primary by contract.
  TodayWorkoutSummary? get primaryTodayWorkout {
    final t = todayWorkout;
    if (t != null && !t.isProgramAddon) return t;
    // If today_workout itself is an add-on (unusual), surface the first
    // non-add-on extra as the primary instead.
    for (final e in extraTodayWorkouts) {
      if (!e.isProgramAddon) return e;
    }
    return t;
  }

  /// Today's ADD-ON workouts — program-sourced stacked sessions (e.g. a
  /// 7-minute core add-on) that ride on top of the primary plan. Drawn from the
  /// extra-today list plus a today_workout that happens to be an add-on.
  List<TodayWorkoutSummary> get addonTodayWorkouts {
    final out = <TodayWorkoutSummary>[];
    final t = todayWorkout;
    if (t != null && t.isProgramAddon) out.add(t);
    for (final e in extraTodayWorkouts) {
      if (e.isProgramAddon) out.add(e);
    }
    return out;
  }

  const TodayWorkoutResponse({
    required this.hasWorkoutToday,
    this.todayWorkout,
    this.nextWorkout,
    this.daysUntilNext,
    this.restDayMessage,
    this.completedToday = false,
    this.completedWorkout,
    this.extraTodayWorkouts = const [],
    this.isGenerating = false,
    this.generationMessage,
    this.needsGeneration = false,
    this.nextWorkoutDate,
    this.gymProfileId,
    this.lastGenerationError,
  });

  factory TodayWorkoutResponse.fromJson(Map<String, dynamic> json) {
    // Back-compat for a pure-LIST `workouts:[...]` payload (multi-assignment
    // day). When present and the object-shaped today_workout/extra fields are
    // absent, split the list into primary (first non-add-on, today-dated) +
    // add-ons so the rest of the pipeline (carousel / cache) is unchanged.
    final rawList = json['workouts'];
    if (rawList is List &&
        rawList.isNotEmpty &&
        json['today_workout'] == null &&
        json['extra_today_workouts'] == null) {
      final all = rawList
          .whereType<Map>()
          .map((e) => TodayWorkoutSummary.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      // Today's items only for the hero/add-on split; future ones become next.
      final todays = all.where((w) => w.isToday).toList();
      final future = all.where((w) => !w.isToday).toList();
      TodayWorkoutSummary? primary;
      final addons = <TodayWorkoutSummary>[];
      for (final w in todays) {
        if (!w.isProgramAddon && primary == null) {
          primary = w;
        } else {
          addons.add(w);
        }
      }
      // Pick the soonest future workout as `next` (the list is normally sorted).
      final next = future.isNotEmpty ? future.first : null;
      return TodayWorkoutResponse(
        hasWorkoutToday: primary != null || addons.isNotEmpty,
        todayWorkout: primary,
        nextWorkout: next,
        extraTodayWorkouts: addons,
        isGenerating: json['is_generating'] as bool? ?? false,
        generationMessage: json['generation_message'] as String?,
        needsGeneration: json['needs_generation'] as bool? ?? false,
        nextWorkoutDate: json['next_workout_date'] as String?,
        gymProfileId: json['gym_profile_id'] as String?,
        completedToday: json['completed_today'] as bool? ?? false,
        completedWorkout: json['completed_workout'] != null
            ? TodayWorkoutSummary.fromJson(
                json['completed_workout'] as Map<String, dynamic>)
            : null,
        lastGenerationError: json['last_generation_error'] as String?,
      );
    }

    return TodayWorkoutResponse(
      hasWorkoutToday: json['has_workout_today'] as bool? ?? false,
      todayWorkout: json['today_workout'] != null
          ? TodayWorkoutSummary.fromJson(
              json['today_workout'] as Map<String, dynamic>)
          : null,
      nextWorkout: json['next_workout'] != null
          ? TodayWorkoutSummary.fromJson(
              json['next_workout'] as Map<String, dynamic>)
          : null,
      daysUntilNext: json['days_until_next'] as int?,
      restDayMessage: json['rest_day_message'] as String?,
      completedToday: json['completed_today'] as bool? ?? false,
      completedWorkout: json['completed_workout'] != null
          ? TodayWorkoutSummary.fromJson(
              json['completed_workout'] as Map<String, dynamic>)
          : null,
      extraTodayWorkouts: (json['extra_today_workouts'] as List<dynamic>?)
              ?.map((e) =>
                  TodayWorkoutSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isGenerating: json['is_generating'] as bool? ?? false,
      generationMessage: json['generation_message'] as String?,
      needsGeneration: json['needs_generation'] as bool? ?? false,
      nextWorkoutDate: json['next_workout_date'] as String?,
      gymProfileId: json['gym_profile_id'] as String?,
      lastGenerationError: json['last_generation_error'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'has_workout_today': hasWorkoutToday,
        'today_workout': todayWorkout?.toJson(),
        'next_workout': nextWorkout?.toJson(),
        'days_until_next': daysUntilNext,
        'rest_day_message': restDayMessage,
        'completed_today': completedToday,
        'completed_workout': completedWorkout?.toJson(),
        'extra_today_workouts':
            extraTodayWorkouts.map((e) => e.toJson()).toList(),
        'is_generating': isGenerating,
        'generation_message': generationMessage,
        'needs_generation': needsGeneration,
        'next_workout_date': nextWorkoutDate,
        'gym_profile_id': gymProfileId,
        if (lastGenerationError != null)
          'last_generation_error': lastGenerationError,
      };

  TodayWorkoutResponse copyWith({
    bool? hasWorkoutToday,
    TodayWorkoutSummary? todayWorkout,
    TodayWorkoutSummary? nextWorkout,
    int? daysUntilNext,
    String? restDayMessage,
    bool? completedToday,
    TodayWorkoutSummary? completedWorkout,
    List<TodayWorkoutSummary>? extraTodayWorkouts,
    bool? isGenerating,
    String? generationMessage,
    bool? needsGeneration,
    String? nextWorkoutDate,
    String? gymProfileId,
    String? lastGenerationError,
  }) =>
      TodayWorkoutResponse(
        hasWorkoutToday: hasWorkoutToday ?? this.hasWorkoutToday,
        todayWorkout: todayWorkout ?? this.todayWorkout,
        nextWorkout: nextWorkout ?? this.nextWorkout,
        daysUntilNext: daysUntilNext ?? this.daysUntilNext,
        restDayMessage: restDayMessage ?? this.restDayMessage,
        completedToday: completedToday ?? this.completedToday,
        completedWorkout: completedWorkout ?? this.completedWorkout,
        extraTodayWorkouts: extraTodayWorkouts ?? this.extraTodayWorkouts,
        isGenerating: isGenerating ?? this.isGenerating,
        generationMessage: generationMessage ?? this.generationMessage,
        needsGeneration: needsGeneration ?? this.needsGeneration,
        nextWorkoutDate: nextWorkoutDate ?? this.nextWorkoutDate,
        gymProfileId: gymProfileId ?? this.gymProfileId,
        lastGenerationError: lastGenerationError ?? this.lastGenerationError,
      );
}
