// Multi-day program-template models.
//
// HAND-WRITTEN — NO codegen. The repo's analyzer crashes on build_runner
// (see project_codegen_gotcha), so these models carry manual `fromJson` /
// `toJson` instead of Freezed/json_serializable. Keep them plain immutable
// classes with `copyWith` where the builder UI needs to mutate.
//
// Backed by `/api/v1/program-templates/*` (Phase B backend). The shapes here
// mirror that contract exactly:
//   - ProgramTemplate      → a saved `user_program_templates` row
//   - ProgramDay           → one day inside `days[]`
//   - ProgramExercise      → one exercise inside a day
//   - RepsSpec             → the normalized `reps_spec` blob
//   - ProgramLibraryCard   → a lightweight `GET /library` card DTO
//   - ScheduleResult       → the `POST /{id}/schedule` response

// ---------------------------------------------------------------------------
// Small parse helpers — tolerate the loose JSON the backend can emit.
// ---------------------------------------------------------------------------

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim());
  return null;
}

bool _asBool(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true' || v == '1';
  if (v is num) return v != 0;
  return fallback;
}

String _asString(dynamic v, {String fallback = ''}) {
  if (v == null) return fallback;
  if (v is String) return v;
  return v.toString();
}

List<String> _asStringList(dynamic v) {
  if (v is List) {
    return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
  }
  return const [];
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map) return Map<String, dynamic>.from(v);
  return const {};
}

// ---------------------------------------------------------------------------
// RepsSpec — normalized rep prescription.
// ---------------------------------------------------------------------------

/// How a set's "reps" should be interpreted. Mirrors the backend
/// `reps_spec.kind` enum.
enum RepsKind { fixed, range, time, amrap, freeform, distance }

RepsKind _repsKindFromString(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'fixed':
      return RepsKind.fixed;
    case 'range':
      return RepsKind.range;
    case 'time':
      return RepsKind.time;
    case 'amrap':
      return RepsKind.amrap;
    case 'distance':
      return RepsKind.distance;
    case 'freeform':
    default:
      return RepsKind.freeform;
  }
}

String _repsKindToString(RepsKind k) {
  switch (k) {
    case RepsKind.fixed:
      return 'fixed';
    case RepsKind.range:
      return 'range';
    case RepsKind.time:
      return 'time';
    case RepsKind.amrap:
      return 'amrap';
    case RepsKind.distance:
      return 'distance';
    case RepsKind.freeform:
      return 'freeform';
  }
}

/// Structured rep target. `{kind, min, max, unit, per_side, raw}` from the
/// backend's rep-string normalizer.
class RepsSpec {
  final RepsKind kind;
  final int? min;
  final int? max;

  /// Unit for `time`/`distance` kinds — e.g. `seconds`, `minutes`, `m`.
  final String? unit;

  /// True when the rep count is per side ("10 each leg").
  final bool perSide;

  /// Original unparsed string — always preserved so nothing is lost.
  final String? raw;

  const RepsSpec({
    required this.kind,
    this.min,
    this.max,
    this.unit,
    this.perSide = false,
    this.raw,
  });

  factory RepsSpec.fromJson(Map<String, dynamic> json) {
    return RepsSpec(
      kind: _repsKindFromString(json['kind'] as String?),
      min: _asInt(json['min']),
      max: _asInt(json['max']),
      unit: json['unit'] as String?,
      perSide: _asBool(json['per_side']),
      raw: json['raw'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': _repsKindToString(kind),
        if (min != null) 'min': min,
        if (max != null) 'max': max,
        if (unit != null) 'unit': unit,
        'per_side': perSide,
        if (raw != null) 'raw': raw,
      };

  /// Human-readable label for chips / preview rows. Never returns empty.
  String displayLabel() {
    switch (kind) {
      case RepsKind.amrap:
        return 'AMRAP';
      case RepsKind.time:
        final u = unit ?? 'sec';
        if (min != null && max != null && min != max) {
          return '$min-$max $u';
        }
        return '${min ?? max ?? 0} $u';
      case RepsKind.distance:
        final u = unit ?? 'm';
        if (min != null && max != null && min != max) {
          return '$min-$max $u';
        }
        return '${min ?? max ?? 0} $u';
      case RepsKind.range:
        final lo = min ?? 0;
        final hi = max ?? lo;
        return perSide ? '$lo-$hi / side' : '$lo-$hi reps';
      case RepsKind.fixed:
        final n = min ?? max ?? 0;
        return perSide ? '$n / side' : '$n reps';
      case RepsKind.freeform:
        final r = raw?.trim();
        return (r != null && r.isNotEmpty) ? r : 'reps';
    }
  }

  RepsSpec copyWith({
    RepsKind? kind,
    int? min,
    int? max,
    String? unit,
    bool? perSide,
    String? raw,
  }) {
    return RepsSpec(
      kind: kind ?? this.kind,
      min: min ?? this.min,
      max: max ?? this.max,
      unit: unit ?? this.unit,
      perSide: perSide ?? this.perSide,
      raw: raw ?? this.raw,
    );
  }
}

// ---------------------------------------------------------------------------
// ProgramExercise — one exercise inside a day.
// ---------------------------------------------------------------------------

class ProgramExercise {
  final String name;

  /// The name exactly as it appeared in the source program (before
  /// resolution). Useful so the review UI can show "we matched X to Y".
  final String? originalName;

  /// Resolved exercise-library id, when the resolver found a match.
  final String? exerciseId;

  final int sets;

  /// Legacy / display reps string. `repsSpec` is the structured truth.
  final String? reps;

  final RepsSpec? repsSpec;

  /// Whether this exercise is logged per side (mirror of repsSpec.perSide,
  /// kept top-level because some backend rows set it directly).
  final bool perSide;

  /// Reps-in-reserve target, when authored.
  final int? targetRir;

  /// Target working weight in KG (internal storage unit — display as lb).
  final double? targetWeightKg;

  final int? restSeconds;
  final String? notes;

  /// `normal | warmup | failure | amrap | drop | ...`
  final String? setType;

  /// Superset grouping key — exercises sharing a group run as a superset.
  final String? supersetGroup;

  /// True when the exercise name could not be resolved to any library row.
  final bool unresolved;

  /// Where the resolution came from — `exact | fuzzy | rag | custom | null`.
  final String? resolutionSource;

  /// True when the parser had to infer sets/reps (no scheme in source text).
  final bool inferred;

  const ProgramExercise({
    required this.name,
    this.originalName,
    this.exerciseId,
    this.sets = 3,
    this.reps,
    this.repsSpec,
    this.perSide = false,
    this.targetRir,
    this.targetWeightKg,
    this.restSeconds,
    this.notes,
    this.setType,
    this.supersetGroup,
    this.unresolved = false,
    this.resolutionSource,
    this.inferred = false,
  });

  factory ProgramExercise.fromJson(Map<String, dynamic> json) {
    final specRaw = json['reps_spec'];
    return ProgramExercise(
      name: _asString(json['name'], fallback: 'Exercise'),
      originalName: json['original_name'] as String?,
      exerciseId: json['exercise_id']?.toString(),
      sets: _asInt(json['sets']) ?? 3,
      reps: json['reps']?.toString(),
      repsSpec: specRaw is Map ? RepsSpec.fromJson(_asMap(specRaw)) : null,
      perSide: _asBool(json['per_side']),
      targetRir: _asInt(json['target_rir']),
      targetWeightKg: _asDouble(json['target_weight_kg']),
      restSeconds: _asInt(json['rest_seconds']),
      notes: json['notes'] as String?,
      setType: json['set_type'] as String?,
      supersetGroup: json['superset_group']?.toString(),
      unresolved: _asBool(json['unresolved']),
      resolutionSource: json['resolution_source'] as String?,
      inferred: _asBool(json['inferred']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (originalName != null) 'original_name': originalName,
        if (exerciseId != null) 'exercise_id': exerciseId,
        'sets': sets,
        if (reps != null) 'reps': reps,
        if (repsSpec != null) 'reps_spec': repsSpec!.toJson(),
        'per_side': perSide,
        if (targetRir != null) 'target_rir': targetRir,
        if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
        if (restSeconds != null) 'rest_seconds': restSeconds,
        if (notes != null) 'notes': notes,
        if (setType != null) 'set_type': setType,
        if (supersetGroup != null) 'superset_group': supersetGroup,
        'unresolved': unresolved,
        if (resolutionSource != null) 'resolution_source': resolutionSource,
        'inferred': inferred,
      };

  /// Short reps label for preview rows. Prefers the structured spec.
  String repsLabel() {
    if (repsSpec != null) return repsSpec!.displayLabel();
    final r = reps?.trim();
    if (r != null && r.isNotEmpty) return r;
    return 'reps';
  }

  ProgramExercise copyWith({
    String? name,
    String? originalName,
    String? exerciseId,
    int? sets,
    String? reps,
    RepsSpec? repsSpec,
    bool? perSide,
    int? targetRir,
    double? targetWeightKg,
    int? restSeconds,
    String? notes,
    String? setType,
    String? supersetGroup,
    bool? unresolved,
    String? resolutionSource,
    bool? inferred,
  }) {
    return ProgramExercise(
      name: name ?? this.name,
      originalName: originalName ?? this.originalName,
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      repsSpec: repsSpec ?? this.repsSpec,
      perSide: perSide ?? this.perSide,
      targetRir: targetRir ?? this.targetRir,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
      setType: setType ?? this.setType,
      supersetGroup: supersetGroup ?? this.supersetGroup,
      unresolved: unresolved ?? this.unresolved,
      resolutionSource: resolutionSource ?? this.resolutionSource,
      inferred: inferred ?? this.inferred,
    );
  }
}

// ---------------------------------------------------------------------------
// ProgramDay — one day inside a template.
// ---------------------------------------------------------------------------

class ProgramDay {
  /// 0-based index inside the template's `week_length` cycle.
  final int dayIndex;

  /// Display name — "Upper A", "Lower", "Rest", etc.
  final String dayName;

  final bool isRest;

  /// `strength | cardio | mobility | ...` — drives the active-workout UI.
  final String? workoutType;

  final List<ProgramExercise> exercises;

  const ProgramDay({
    required this.dayIndex,
    required this.dayName,
    this.isRest = false,
    this.workoutType,
    this.exercises = const [],
  });

  factory ProgramDay.fromJson(Map<String, dynamic> json) {
    final rawEx = json['exercises'];
    final exercises = <ProgramExercise>[];
    if (rawEx is List) {
      for (final e in rawEx) {
        if (e is Map) {
          exercises.add(ProgramExercise.fromJson(_asMap(e)));
        }
      }
    }
    return ProgramDay(
      dayIndex: _asInt(json['day_index']) ?? 0,
      dayName: _asString(json['day_name'], fallback: 'Day'),
      isRest: _asBool(json['is_rest']),
      workoutType: json['workout_type'] as String?,
      exercises: exercises,
    );
  }

  Map<String, dynamic> toJson() => {
        'day_index': dayIndex,
        'day_name': dayName,
        'is_rest': isRest,
        if (workoutType != null) 'workout_type': workoutType,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  /// A day with no exercises is effectively a rest day.
  bool get effectivelyRest => isRest || exercises.isEmpty;

  ProgramDay copyWith({
    int? dayIndex,
    String? dayName,
    bool? isRest,
    String? workoutType,
    List<ProgramExercise>? exercises,
  }) {
    return ProgramDay(
      dayIndex: dayIndex ?? this.dayIndex,
      dayName: dayName ?? this.dayName,
      isRest: isRest ?? this.isRest,
      workoutType: workoutType ?? this.workoutType,
      exercises: exercises ?? this.exercises,
    );
  }
}

// ---------------------------------------------------------------------------
// ProgramTemplate — a saved `user_program_templates` row.
// ---------------------------------------------------------------------------

class ProgramTemplate {
  /// Null for a not-yet-saved parsed/authored draft.
  final String? id;
  final String? userId;
  final String name;
  final String? description;

  /// Length of the repeating cycle in days (default 7, supports 1..N).
  final int weekLength;

  final List<ProgramDay> days;

  /// Run a deload every Nth week. Null = no scheduled deload (yoga etc).
  final int? deloadEveryNWeeks;

  /// `linear | wave | double | none`.
  final String progressionStrategy;

  /// Inject the user's staple exercises into expanded workouts.
  final bool applyStaples;

  /// `authored | parsed | duplicated | library`.
  final String source;

  /// When `source == 'library'`, the `programs` row it was cloned from.
  final String? sourceProgramId;

  /// Carried from the source program — drives default progression.
  final String? category;

  /// True when a parse only covered the base week (long-program guard).
  final bool baseWeekOnly;

  /// Suggested repeat count when `baseWeekOnly` is set.
  final int? repeatWeeksHint;

  final String? createdAt;
  final String? updatedAt;

  const ProgramTemplate({
    this.id,
    this.userId,
    required this.name,
    this.description,
    this.weekLength = 7,
    this.days = const [],
    this.deloadEveryNWeeks = 5,
    this.progressionStrategy = 'linear',
    this.applyStaples = true,
    this.source = 'authored',
    this.sourceProgramId,
    this.category,
    this.baseWeekOnly = false,
    this.repeatWeeksHint,
    this.createdAt,
    this.updatedAt,
  });

  factory ProgramTemplate.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    final days = <ProgramDay>[];
    if (rawDays is List) {
      for (final d in rawDays) {
        if (d is Map) days.add(ProgramDay.fromJson(_asMap(d)));
      }
    }
    return ProgramTemplate(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      name: _asString(json['name'], fallback: 'Program'),
      description: json['description'] as String?,
      weekLength: _asInt(json['week_length']) ?? 7,
      days: days,
      deloadEveryNWeeks: _asInt(json['deload_every_n_weeks']),
      progressionStrategy:
          _asString(json['progression_strategy'], fallback: 'linear'),
      applyStaples: _asBool(json['apply_staples'], fallback: true),
      source: _asString(json['source'], fallback: 'authored'),
      sourceProgramId: json['source_program_id']?.toString(),
      category: json['category'] as String?,
      baseWeekOnly: _asBool(json['base_week_only']),
      repeatWeeksHint: _asInt(json['repeat_weeks_hint']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  /// Body for `POST /` (create) and `PATCH /{id}` (edit). Intentionally
  /// excludes server-managed fields (`id`, `user_id`, timestamps).
  Map<String, dynamic> toCreateJson() => {
        'name': name,
        if (description != null) 'description': description,
        'week_length': weekLength,
        'days': days.map((d) => d.toJson()).toList(),
        'deload_every_n_weeks': deloadEveryNWeeks,
        'progression_strategy': progressionStrategy,
        'apply_staples': applyStaples,
        'source': source,
        if (sourceProgramId != null) 'source_program_id': sourceProgramId,
        if (category != null) 'category': category,
      };

  /// Full round-trip JSON (used for caching / debugging).
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (userId != null) 'user_id': userId,
        ...toCreateJson(),
        'base_week_only': baseWeekOnly,
        if (repeatWeeksHint != null) 'repeat_weeks_hint': repeatWeeksHint,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      };

  /// Non-rest day count — what the UI calls "training days".
  int get trainingDayCount =>
      days.where((d) => !d.effectivelyRest).length;

  /// At least one training day → schedulable.
  bool get hasTrainingDays => trainingDayCount > 0;

  /// Total exercises across every training day.
  int get totalExercises =>
      days.fold(0, (sum, d) => sum + d.exercises.length);

  /// Count of exercises the resolver could not match — drives the
  /// "needs review" badge.
  int get unresolvedCount => days.fold(
      0, (sum, d) => sum + d.exercises.where((e) => e.unresolved).length);

  ProgramTemplate copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    int? weekLength,
    List<ProgramDay>? days,
    int? deloadEveryNWeeks,
    bool clearDeload = false,
    String? progressionStrategy,
    bool? applyStaples,
    String? source,
    String? sourceProgramId,
    String? category,
    bool? baseWeekOnly,
    int? repeatWeeksHint,
    String? createdAt,
    String? updatedAt,
  }) {
    return ProgramTemplate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      weekLength: weekLength ?? this.weekLength,
      days: days ?? this.days,
      deloadEveryNWeeks:
          clearDeload ? null : (deloadEveryNWeeks ?? this.deloadEveryNWeeks),
      progressionStrategy: progressionStrategy ?? this.progressionStrategy,
      applyStaples: applyStaples ?? this.applyStaples,
      source: source ?? this.source,
      sourceProgramId: sourceProgramId ?? this.sourceProgramId,
      category: category ?? this.category,
      baseWeekOnly: baseWeekOnly ?? this.baseWeekOnly,
      repeatWeeksHint: repeatWeeksHint ?? this.repeatWeeksHint,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ---------------------------------------------------------------------------
// ProgramLibraryCard — lightweight `GET /library` card DTO.
// ---------------------------------------------------------------------------

class ProgramLibraryCard {
  final String id;
  final String programName;

  /// Top-level grouping — Celebrity / Sport / Goal-Based / Specialized / etc.
  final String? programCategory;
  final String? programSubcategory;

  /// Set for the ~40 celebrity programs — rendered as an eyebrow label.
  final String? celebrityName;

  final String? difficultyLevel;
  final int? durationWeeks;
  final int? sessionsPerWeek;
  final int? sessionDurationMinutes;
  final String? description;
  final List<String> goals;

  const ProgramLibraryCard({
    required this.id,
    required this.programName,
    this.programCategory,
    this.programSubcategory,
    this.celebrityName,
    this.difficultyLevel,
    this.durationWeeks,
    this.sessionsPerWeek,
    this.sessionDurationMinutes,
    this.description,
    this.goals = const [],
  });

  factory ProgramLibraryCard.fromJson(Map<String, dynamic> json) {
    return ProgramLibraryCard(
      id: _asString(json['id']),
      programName: _asString(json['program_name'], fallback: 'Program'),
      programCategory: json['program_category'] as String?,
      programSubcategory: json['program_subcategory'] as String?,
      celebrityName: json['celebrity_name'] as String?,
      difficultyLevel: json['difficulty_level'] as String?,
      durationWeeks: _asInt(json['duration_weeks']),
      sessionsPerWeek: _asInt(json['sessions_per_week']),
      sessionDurationMinutes: _asInt(json['session_duration_minutes']),
      description: json['description'] as String?,
      goals: _asStringList(json['goals']),
    );
  }
}

/// Paged result of `GET /library`.
class ProgramLibraryResult {
  final int total;
  final List<ProgramLibraryCard> programs;

  const ProgramLibraryResult({required this.total, required this.programs});

  factory ProgramLibraryResult.fromJson(Map<String, dynamic> json) {
    final raw = json['programs'];
    final programs = <ProgramLibraryCard>[];
    if (raw is List) {
      for (final p in raw) {
        if (p is Map) {
          programs.add(ProgramLibraryCard.fromJson(_asMap(p)));
        }
      }
    }
    return ProgramLibraryResult(
      total: _asInt(json['total']) ?? programs.length,
      programs: programs,
    );
  }
}

// ---------------------------------------------------------------------------
// ScheduleResult — response for both `POST /{id}/schedule` and
// `POST /{id}/regenerate-future`. Schedule populates workoutsCreated/
// skippedExisting/deloadWeeks; regenerate-future populates
// workoutsUpdated/workoutsRemoved. The other group stays null/0.
// ---------------------------------------------------------------------------

class ScheduleResult {
  final bool success;
  final String? templateId;
  final String? scheduleId;
  final int workoutsCreated;
  final int skippedExisting;
  final List<int> deloadWeeks;
  final int? workoutsUpdated;
  final int? workoutsRemoved;

  const ScheduleResult({
    required this.success,
    this.templateId,
    this.scheduleId,
    this.workoutsCreated = 0,
    this.skippedExisting = 0,
    this.deloadWeeks = const [],
    this.workoutsUpdated,
    this.workoutsRemoved,
  });

  factory ScheduleResult.fromJson(Map<String, dynamic> json) {
    final rawWeeks = json['deload_weeks'];
    final weeks = <int>[];
    if (rawWeeks is List) {
      for (final w in rawWeeks) {
        final i = _asInt(w);
        if (i != null) weeks.add(i);
      }
    }
    return ScheduleResult(
      success: _asBool(json['success']),
      templateId: json['template_id']?.toString(),
      scheduleId: json['schedule_id']?.toString(),
      workoutsCreated: _asInt(json['workouts_created']) ?? 0,
      skippedExisting: _asInt(json['skipped_existing']) ?? 0,
      deloadWeeks: weeks,
      workoutsUpdated: _asInt(json['workouts_updated']),
      workoutsRemoved: _asInt(json['workouts_removed']),
    );
  }
}

// ---------------------------------------------------------------------------
// ProgramParseException — thrown when `POST /parse` returns a 422 with a
// structured `not_a_program` / `parse_error` body. Lets the paste UI show
// the right copy instead of a generic network error.
// ---------------------------------------------------------------------------

class ProgramParseException implements Exception {
  /// `not_a_program` | `parse_error`.
  final String code;
  final String message;

  const ProgramParseException(this.code, this.message);

  /// True when the text simply was not a workout program.
  bool get isNotAProgram => code == 'not_a_program';

  @override
  String toString() => 'ProgramParseException($code): $message';
}
