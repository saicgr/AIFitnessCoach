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

  /// Total program length in WEEKS — how long the program runs end to end
  /// (distinct from [weekLength], the repeating cycle, and
  /// [deloadEveryNWeeks]). The scheduler expands this many weeks. Null = use
  /// the source program's duration / a sensible default.
  final int? durationWeeks;

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
    this.durationWeeks,
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
      durationWeeks: _asInt(json['duration_weeks']),
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
        if (durationWeeks != null) 'duration_weeks': durationWeeks,
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
    int? durationWeeks,
    bool clearDurationWeeks = false,
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
      durationWeeks:
          clearDurationWeeks ? null : (durationWeeks ?? this.durationWeeks),
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
// ProgramPhase — one authored block on the detail-page Overview (mig 2286).
// ---------------------------------------------------------------------------

class ProgramPhase {
  final int index;
  final String title;
  final String? subtitle;
  final int? weekStart;
  final int? weekEnd;

  const ProgramPhase({
    required this.index,
    required this.title,
    this.subtitle,
    this.weekStart,
    this.weekEnd,
  });

  factory ProgramPhase.fromJson(Map<String, dynamic> json) => ProgramPhase(
        index: _asInt(json['index']) ?? 0,
        title: _asString(json['title'], fallback: 'Phase'),
        subtitle: json['subtitle'] as String?,
        weekStart: _asInt(json['week_start']),
        weekEnd: _asInt(json['week_end']),
      );

  /// "Week 1–2" / "Week 6" / null when no range.
  String? get weekLabel {
    if (weekStart == null) return null;
    if (weekEnd == null || weekEnd == weekStart) return 'Week $weekStart';
    return 'Week $weekStart–$weekEnd';
  }
}

// ---------------------------------------------------------------------------
// ProgramVariantOption — one variant row for a multi-variant program.
// Source: `variant_options[]` on `GET /library/{id}`.
// ---------------------------------------------------------------------------

class ProgramVariantOption {
  /// The `program_variants.id` for this variant.
  final String variantId;

  /// Total program duration in weeks for this variant.
  final int weeks;

  /// Sessions per week for this variant.
  final int sessionsPerWeek;

  /// Intensity label — "Light", "Medium", "Hard", "Elite", etc.
  final String intensity;

  /// True when this variant is the program's default choice.
  final bool isDefault;

  const ProgramVariantOption({
    required this.variantId,
    required this.weeks,
    required this.sessionsPerWeek,
    required this.intensity,
    required this.isDefault,
  });

  factory ProgramVariantOption.fromJson(Map<String, dynamic> json) =>
      ProgramVariantOption(
        variantId: _asString(json['variant_id']),
        weeks: _asInt(json['weeks']) ?? 0,
        sessionsPerWeek: _asInt(json['sessions_per_week']) ?? 0,
        intensity: _asString(json['intensity'], fallback: 'Medium'),
        isDefault: _asBool(json['is_default']),
      );
}

// ---------------------------------------------------------------------------
// ProgramScheduleExercise — one exercise row in the schedule API response.
// Source: `GET /library/{id}/schedule?variant_id=`.
// ---------------------------------------------------------------------------

class ProgramScheduleExercise {
  /// Canonical library id — may be null if the exercise could not be resolved.
  final String? exerciseId;
  final String name;

  /// String form (e.g. "4", "3-4") — null when not specified.
  final String? sets;

  /// String form (e.g. "800 m", "12", "45 sec") — null when not specified.
  final String? reps;

  /// Duration string — null for rep-based exercises.
  final String? duration;

  /// Presigned S3 URL for the exercise image — null when unavailable.
  final String? imageUrl;

  /// Presigned S3 URL for the exercise video — null when unavailable.
  final String? videoUrl;

  /// GIF URL — null when unavailable.
  final String? gifUrl;

  const ProgramScheduleExercise({
    this.exerciseId,
    required this.name,
    this.sets,
    this.reps,
    this.duration,
    this.imageUrl,
    this.videoUrl,
    this.gifUrl,
  });

  factory ProgramScheduleExercise.fromJson(Map<String, dynamic> json) =>
      ProgramScheduleExercise(
        exerciseId: json['exercise_id']?.toString(),
        name: _asString(json['name'], fallback: 'Exercise'),
        sets: json['sets']?.toString(),
        reps: json['reps']?.toString(),
        duration: json['duration']?.toString(),
        imageUrl: json['image_url'] as String?,
        videoUrl: json['video_url'] as String?,
        gifUrl: json['gif_url'] as String?,
      );

  /// Compact "sets × reps" label; skips null side. E.g. "4 × 800 m", "3 sets".
  String get volumeLabel {
    final s = sets?.trim();
    final r = reps?.trim();
    final d = duration?.trim();
    if (s != null && s.isNotEmpty && r != null && r.isNotEmpty) {
      return '$s × $r';
    }
    if (s != null && s.isNotEmpty && d != null && d.isNotEmpty) {
      return '$s × $d';
    }
    if (r != null && r.isNotEmpty) return r;
    if (d != null && d.isNotEmpty) return d;
    if (s != null && s.isNotEmpty) return '$s sets';
    return '';
  }
}

// ---------------------------------------------------------------------------
// ProgramScheduleDay — one training day in the schedule response.
// ---------------------------------------------------------------------------

class ProgramScheduleDay {
  /// Display name — "Run Intervals", "Upper Body A", "Rest", etc.
  final String dayName;

  /// `strength | cardio | mobility | rest | ...`
  final String? workoutType;

  final List<ProgramScheduleExercise> exercises;

  const ProgramScheduleDay({
    required this.dayName,
    this.workoutType,
    this.exercises = const [],
  });

  bool get isRest =>
      (workoutType?.toLowerCase() == 'rest') ||
      (exercises.isEmpty && dayName.toLowerCase().contains('rest'));

  factory ProgramScheduleDay.fromJson(Map<String, dynamic> json) {
    final raw = json['exercises'];
    final exercises = <ProgramScheduleExercise>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          exercises.add(
              ProgramScheduleExercise.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return ProgramScheduleDay(
      dayName: _asString(json['day_name'], fallback: 'Day'),
      workoutType: json['workout_type'] as String?,
      exercises: exercises,
    );
  }
}

// ---------------------------------------------------------------------------
// ProgramScheduleWeek — one week in the schedule response.
// ---------------------------------------------------------------------------

class ProgramScheduleWeek {
  final int weekNumber;

  /// Phase/block title for this week — e.g. "Base & Stations". May be null.
  final String? phase;

  /// Focus subtitle — e.g. "Running intervals + station technique". May be null.
  final String? focus;

  final List<ProgramScheduleDay> days;

  const ProgramScheduleWeek({
    required this.weekNumber,
    this.phase,
    this.focus,
    this.days = const [],
  });

  factory ProgramScheduleWeek.fromJson(Map<String, dynamic> json) {
    final raw = json['days'];
    final days = <ProgramScheduleDay>[];
    if (raw is List) {
      for (final d in raw) {
        if (d is Map) {
          days.add(ProgramScheduleDay.fromJson(Map<String, dynamic>.from(d)));
        }
      }
    }
    return ProgramScheduleWeek(
      weekNumber: _asInt(json['week_number']) ?? 1,
      phase: json['phase'] as String?,
      focus: json['focus'] as String?,
      days: days,
    );
  }
}

// ---------------------------------------------------------------------------
// ProgramScheduleResponse — top-level response for
// `GET /library/{id}/schedule?variant_id=`.
// ---------------------------------------------------------------------------

class ProgramScheduleResponse {
  /// The resolved variant id (null for single-plan programs).
  final String? variantId;

  final List<ProgramScheduleWeek> weeks;

  const ProgramScheduleResponse({
    this.variantId,
    this.weeks = const [],
  });

  factory ProgramScheduleResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['weeks'];
    final weeks = <ProgramScheduleWeek>[];
    if (raw is List) {
      for (final w in raw) {
        if (w is Map) {
          weeks.add(ProgramScheduleWeek.fromJson(Map<String, dynamic>.from(w)));
        }
      }
    }
    return ProgramScheduleResponse(
      variantId: json['variant_id']?.toString(),
      weeks: weeks,
    );
  }
}

// ---------------------------------------------------------------------------
// ProgramLibraryCard — lightweight `GET /library` card DTO.
// ---------------------------------------------------------------------------

class ProgramLibraryCard {
  /// Raw id from the backend. For curated rows this is a plain id; for
  /// branded rows it is PREFIXED `branded:<uuid>` (see [source]). Always
  /// preserved verbatim — the preview/import routes expect the prefixed form.
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

  /// Editorial copy (migration 2283) for a rich, curated detail page. All
  /// nullable — fall back to [programName] / [description] when absent.
  /// [editorialName] is the human-facing display name; [tagline] a one-liner;
  /// [whoFor] / [whoNotFor] set expectations; [equipmentSummary] lists gear;
  /// [progressionNote] explains how the program advances in plain English.
  final String? editorialName;
  final String? tagline;
  final String? whoFor;
  final String? whoNotFor;
  final String? equipmentSummary;
  final String? progressionNote;

  /// Authored phase blocks (mig 2286) for the detail Overview. Empty when the
  /// program has none (the detail page derives a fallback split).
  final List<ProgramPhase> phases;

  /// Distinct users who have started this program (real count from
  /// user_program_assignments). Null when not hydrated (card payloads).
  final int? joinedCount;

  /// Which catalog this card came from — `library` (the curated 259-row
  /// `programs` table) or `branded` (the branded-program catalog, whose ids
  /// are namespaced `branded:<uuid>`). Defaults to `library` for older
  /// payloads that predate the unified contract.
  final String source;

  /// Whether `GET /library/{id}` can return a normalized day-by-day preview
  /// for this card. Branded programs without a normalizable structure return
  /// `preview_available: false`, in which case the preview sheet shows the
  /// card-level info instead of a day breakdown. Defaults to true.
  final bool previewAvailable;

  /// Variant rows for multi-variant programs. Empty for single-plan programs
  /// (30-Day Plank, HYROX Full Simulation, etc.) where `variant_base_id IS NULL`.
  final List<ProgramVariantOption> variantOptions;

  /// The default variant id — matches `ProgramVariantOption.variantId` for the
  /// variant with `is_default: true`. Null for single-plan programs.
  final String? defaultVariantId;

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
    this.editorialName,
    this.tagline,
    this.whoFor,
    this.whoNotFor,
    this.equipmentSummary,
    this.progressionNote,
    this.phases = const [],
    this.joinedCount,
    this.source = 'library',
    this.previewAvailable = true,
    this.variantOptions = const [],
    this.defaultVariantId,
  });

  factory ProgramLibraryCard.fromJson(Map<String, dynamic> json) {
    // Parse variant_options list — guard against nulls / non-maps gracefully.
    final rawVariants = json['variant_options'];
    final variantOptions = <ProgramVariantOption>[];
    if (rawVariants is List) {
      for (final v in rawVariants) {
        if (v is Map) {
          variantOptions.add(
              ProgramVariantOption.fromJson(Map<String, dynamic>.from(v)));
        }
      }
    }

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
      editorialName: json['editorial_name'] as String?,
      tagline: json['tagline'] as String?,
      whoFor: json['who_for'] as String?,
      whoNotFor: json['who_not_for'] as String?,
      equipmentSummary: json['equipment_summary'] as String?,
      progressionNote: json['progression_note'] as String?,
      phases: (json['phases'] is List)
          ? (json['phases'] as List)
              .whereType<Map>()
              .map((p) => ProgramPhase.fromJson(_asMap(p)))
              .toList()
          : const [],
      joinedCount: _asInt(json['joined_count']),
      source: _asString(json['source'], fallback: 'library'),
      previewAvailable: _asBool(json['preview_available'], fallback: true),
      variantOptions: variantOptions,
      defaultVariantId: json['default_variant_id']?.toString(),
    );
  }

  /// Human-facing display name — prefers the curated [editorialName].
  String get displayName {
    final e = editorialName?.trim();
    return (e != null && e.isNotEmpty) ? e : programName;
  }

  /// True when this card came from the branded-program catalog.
  bool get isBranded => source == 'branded';

  /// The branded program's bare uuid — `id` with the `branded:` prefix
  /// stripped. Used for the branded ASSIGN fallback when import is
  /// unsupported. Returns the raw `id` unchanged when it carries no prefix.
  String get bareBrandedId =>
      id.startsWith('branded:') ? id.substring('branded:'.length) : id;
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
