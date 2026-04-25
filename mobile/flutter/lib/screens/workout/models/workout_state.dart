/// Workout state models for the active workout screen
///
/// These models encapsulate the state used during an active workout session.
library;

import 'package:flutter/material.dart';

/// Log for a single completed set
class SetLog {
  final int reps;
  final double weight;
  final DateTime completedAt;
  final String setType;
  final int? rpe; // Rate of Perceived Exertion (1-10)
  final int? rir; // Reps in Reserve (0-5)
  final int targetReps; // Original target reps for this set
  // Per-set notes. Each entry is a discrete note the user added during the
  // workout (multiple notes per set are preserved in order). Use [appendNote]
  // / [removeNoteAt] for mutations rather than copyWith(notes:) so order is
  // never accidentally clobbered.
  final List<String> notes;
  final String? aiInputSource; // Original AI input that created this set (e.g., "135*8", "+10")
  final DateTime? startedAt; // When the set started (after rest ended)
  final int? durationSeconds; // How long the set took (start → checkmark)
  final int? restDurationSeconds; // Actual rest taken before this set (null for first set)
  final double? previousWeightKg; // Weight from previous session for this set
  final int? previousReps; // Reps from previous session for this set
  // Active-workout UI tier the user was on when they finished this set.
  // 'easy' | 'simple' | 'advanced'. NULL on legacy rows (treat as 'advanced').
  final String? loggingMode;
  // Optional audio note attached to this set. Local file path before upload,
  // canonical S3 URL once persisted.
  final String? notesAudioPath;
  // Optional photo notes for this set. Same local-path → S3-URL lifecycle
  // as `notesAudioPath`. Default: empty list.
  final List<String> notesPhotoPaths;

  SetLog({
    required this.reps,
    required this.weight,
    DateTime? completedAt,
    this.setType = 'working',
    this.rpe,
    this.rir,
    this.targetReps = 0,
    this.notes = const [],
    this.aiInputSource,
    this.startedAt,
    this.durationSeconds,
    this.restDurationSeconds,
    this.previousWeightKg,
    this.previousReps,
    this.loggingMode,
    this.notesAudioPath,
    this.notesPhotoPaths = const [],
  }) : completedAt = completedAt ?? DateTime.now();

  SetLog copyWith({
    int? reps,
    double? weight,
    DateTime? completedAt,
    String? setType,
    int? rpe,
    int? rir,
    int? targetReps,
    List<String>? notes,
    String? aiInputSource,
    DateTime? startedAt,
    int? durationSeconds,
    int? restDurationSeconds,
    double? previousWeightKg,
    int? previousReps,
    String? loggingMode,
    String? notesAudioPath,
    List<String>? notesPhotoPaths,
  }) {
    return SetLog(
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      completedAt: completedAt ?? this.completedAt,
      setType: setType ?? this.setType,
      rpe: rpe ?? this.rpe,
      rir: rir ?? this.rir,
      targetReps: targetReps ?? this.targetReps,
      notes: notes ?? this.notes,
      aiInputSource: aiInputSource ?? this.aiInputSource,
      startedAt: startedAt ?? this.startedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      restDurationSeconds: restDurationSeconds ?? this.restDurationSeconds,
      previousWeightKg: previousWeightKg ?? this.previousWeightKg,
      previousReps: previousReps ?? this.previousReps,
      loggingMode: loggingMode ?? this.loggingMode,
      notesAudioPath: notesAudioPath ?? this.notesAudioPath,
      notesPhotoPaths: notesPhotoPaths ?? this.notesPhotoPaths,
    );
  }

  /// Append a new note. Empty / whitespace-only inputs are dropped so the
  /// inline-rest send button doesn't accidentally create blank entries.
  SetLog appendNote(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return this;
    return copyWith(notes: [...notes, trimmed]);
  }

  /// Remove the note at [idx]. No-op if out of bounds.
  SetLog removeNoteAt(int idx) {
    if (idx < 0 || idx >= notes.length) return this;
    final next = List<String>.from(notes)..removeAt(idx);
    return copyWith(notes: next);
  }

  /// Replace the note at [idx] with [text]. Trimmed; empty strings remove
  /// the entry to mirror the dialog's UX (clearing the text deletes it).
  SetLog replaceNoteAt(int idx, String text) {
    if (idx < 0 || idx >= notes.length) return this;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return removeNoteAt(idx);
    final next = List<String>.from(notes);
    next[idx] = trimmed;
    return copyWith(notes: next);
  }

  /// Convert to JSON for database persistence. `notes` is always emitted as
  /// a list (empty list when there are none) so the backend can rely on a
  /// stable shape regardless of client version.
  Map<String, dynamic> toJson() => {
        'reps': reps,
        'weight': weight,
        'completed_at': completedAt.toIso8601String(),
        'set_type': setType,
        'rpe': rpe,
        'rir': rir,
        'target_reps': targetReps,
        'notes': notes,
        'ai_input_source': aiInputSource,
        if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
        if (durationSeconds != null) 'set_duration_seconds': durationSeconds,
        if (restDurationSeconds != null) 'rest_duration_seconds': restDurationSeconds,
        if (previousWeightKg != null) 'previous_weight_kg': previousWeightKg,
        if (previousReps != null) 'previous_reps': previousReps,
        if (loggingMode != null) 'logging_mode': loggingMode,
        if (notesAudioPath != null && notesAudioPath!.isNotEmpty)
          'notes_audio_url': notesAudioPath,
        if (notesPhotoPaths.isNotEmpty) 'notes_photo_urls': notesPhotoPaths,
      };

  /// Create from JSON (database retrieval). Backwards-compatible across the
  /// notes-list rollout: a raw `String`, a `List`, or null/missing all map
  /// to a `List<String>`.
  factory SetLog.fromJson(Map<String, dynamic> json) {
    return SetLog(
      reps: json['reps'] as int? ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : DateTime.now(),
      setType: json['set_type'] as String? ?? 'working',
      rpe: json['rpe'] as int?,
      rir: json['rir'] as int?,
      targetReps: json['target_reps'] as int? ?? 0,
      notes: _coerceNotes(json['notes']),
      aiInputSource: json['ai_input_source'] as String?,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      durationSeconds: json['set_duration_seconds'] as int?,
      restDurationSeconds: json['rest_duration_seconds'] as int?,
      previousWeightKg: (json['previous_weight_kg'] as num?)?.toDouble(),
      previousReps: json['previous_reps'] as int?,
      loggingMode: json['logging_mode'] as String?,
      notesAudioPath: json['notes_audio_url'] as String?,
      notesPhotoPaths: (json['notes_photo_urls'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  /// Accept old (`String`), new (`List`), or absent shapes. Empty/whitespace
  /// entries are dropped so legacy rows with `notes = ""` migrate cleanly.
  static List<String> _coerceNotes(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (raw is String) {
      final trimmed = raw.trim();
      return trimmed.isEmpty ? const [] : [trimmed];
    }
    return const [];
  }
}

/// Enum for workout phase
enum WorkoutPhase {
  warmup,
  active,
  stretch,
  complete,
}

/// A single logged interval during a warmup cardio exercise
class WarmupInterval {
  final int startSeconds;
  int endSeconds;
  final double? speedMph;
  final double? incline;

  WarmupInterval({
    required this.startSeconds,
    this.endSeconds = 0,
    this.speedMph,
    this.incline,
  });

  Map<String, dynamic> toJson() => {
    'start_seconds': startSeconds,
    'end_seconds': endSeconds,
    'speed_mph': speedMph,
    'incline': incline,
  };
}

/// Standard warmup exercises data
class WarmupExerciseData {
  final String name;
  final int duration;
  final IconData icon;
  final double? inclinePercent;
  final double? speedMph;
  final int? rpm;
  final int? resistanceLevel;
  final int? strokeRateSpm;
  final String? equipment;
  final bool isStaple;

  const WarmupExerciseData({
    required this.name,
    required this.duration,
    required this.icon,
    this.inclinePercent,
    this.speedMph,
    this.rpm,
    this.resistanceLevel,
    this.strokeRateSpm,
    this.equipment,
    this.isStaple = false,
  });

  /// Whether this exercise uses cardio equipment with adjustable params
  bool get isCardioEquipment =>
      inclinePercent != null ||
      speedMph != null ||
      rpm != null ||
      resistanceLevel != null ||
      strokeRateSpm != null;

  /// Formatted cardio params for display (e.g., "3.0 mph | 2% incline")
  String get cardioParamsDisplay {
    final parts = <String>[];
    if (speedMph != null) parts.add('${speedMph!.toStringAsFixed(1)} mph');
    if (inclinePercent != null) parts.add('Incline ${inclinePercent!.toStringAsFixed(0)}');
    if (rpm != null) parts.add('$rpm RPM');
    if (resistanceLevel != null) parts.add('Resistance $resistanceLevel');
    if (strokeRateSpm != null) parts.add('$strokeRateSpm spm');
    return parts.join(' | ');
  }
}

/// Standard stretch exercises data
class StretchExerciseData {
  final String name;
  final int duration;
  final IconData icon;
  final double? inclinePercent;
  final double? speedMph;
  final int? rpm;
  final int? resistanceLevel;
  final int? strokeRateSpm;
  final String? equipment;

  const StretchExerciseData({
    required this.name,
    required this.duration,
    required this.icon,
    this.inclinePercent,
    this.speedMph,
    this.rpm,
    this.resistanceLevel,
    this.strokeRateSpm,
    this.equipment,
  });

  /// Whether this exercise uses cardio equipment with adjustable params
  bool get isCardioEquipment =>
      inclinePercent != null ||
      speedMph != null ||
      rpm != null ||
      resistanceLevel != null ||
      strokeRateSpm != null;

  /// Formatted cardio params for display
  String get cardioParamsDisplay {
    final parts = <String>[];
    if (speedMph != null) parts.add('${speedMph!.toStringAsFixed(1)} mph');
    if (inclinePercent != null) parts.add('Incline ${inclinePercent!.toStringAsFixed(0)}');
    if (rpm != null) parts.add('$rpm RPM');
    if (resistanceLevel != null) parts.add('Resistance $resistanceLevel');
    if (strokeRateSpm != null) parts.add('$strokeRateSpm spm');
    return parts.join(' | ');
  }
}

/// Default warmup exercises
// Hardcoded default warmup/stretch exercises removed.
// Warmup and stretch exercises are generated by the backend API,
// personalized to the workout type, user injuries, and staple preferences.

/// Rest interval tracking data
class RestInterval {
  final String? exerciseId;
  final String? exerciseName;
  final int? setNumber;
  final int restSeconds;
  final String restType;
  final DateTime recordedAt;

  RestInterval({
    this.exerciseId,
    this.exerciseName,
    this.setNumber,
    required this.restSeconds,
    required this.restType,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'set_number': setNumber,
        'rest_seconds': restSeconds,
        'rest_type': restType,
        'recorded_at': recordedAt.toIso8601String(),
      };
}
