/// Summary Exercise Table Widget
///
/// Read-only display version of SetTrackingTable for the workout summary screen.
/// Shows completed exercise data with set details, timing, and RIR badges.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/workout_design.dart';
import '../../../core/utils/weight_utils.dart';
import '../../../widgets/glass_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../core/theme/accent_color_provider.dart';
// ═══════════════════════════════════════════════════════════════════════════════
// METRIC KIND — reps vs distance/time/custom
// ═══════════════════════════════════════════════════════════════════════════════

/// Which real-world quantity a set's primary number represents. Used to pick
/// a per-exercise column header (see `_metricKindOf` callers in
/// [SummaryExerciseTable]) instead of always labelling the column "REPS" even
/// for a pure-distance or pure-timed exercise.
enum SetMetricKind { reps, distance, duration, custom, none }

/// Formats a logged distance for the summary table — same simple
/// metric convention as `LocationService.formatDistance` (m under 1000,
/// km with 1 decimal above), reimplemented here rather than importing that
/// service (it pulls in geolocator + location-permission plumbing this
/// read-only summary table has no business depending on). Displays whatever
/// value is stored, honestly — implausible values (a seed/stepper bug) are
/// tracked separately and are NOT clamped or sanity-checked here.
String formatSetDistanceMeters(double meters) {
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

/// Formats a logged set duration (seconds) for the summary table. Mirrors
/// `_SummaryTimingRow._formatDuration`'s m:ss-above-a-minute convention; kept
/// as a separate top-level function rather than sharing that private method
/// so this file's two duration-formatting call sites (the timing divider row
/// and the reps-column override) can evolve independently.
String formatSetDurationSeconds(int seconds) {
  if (seconds >= 60) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
  return '${seconds}s';
}

/// Picks the Reps column's header label for one exercise's sets. When every
/// set that carries a metric at all shares the SAME non-reps kind (a whole
/// exercise of distance sets, or a whole exercise of timed holds), the
/// column is honestly relabelled instead of staying "REPS" over a column of
/// distances/times. Mixed kinds (rare — some sets logged reps, others
/// distance) fall back to "REPS": the header can't honestly describe every
/// row at once, but [_SummarySetRow] still renders each row's REAL metric
/// (see [SummarySetData.hasAlternateMetric]) rather than a bogus "0" — the
/// header is a secondary cue, the per-row value is what actually matters.
String repsColumnLabel(BuildContext context, List<SummarySetData> sets) {
  final kinds = sets
      .map((s) => s.metricKind)
      .where((k) => k != SetMetricKind.none)
      .toSet();
  if (kinds.length == 1) {
    switch (kinds.first) {
      case SetMetricKind.distance:
        return 'DISTANCE';
      case SetMetricKind.duration:
        return 'TIME';
      case SetMetricKind.custom:
        return 'METRIC';
      case SetMetricKind.reps:
      case SetMetricKind.none:
        break;
    }
  }
  return AppLocalizations.of(context).workoutSummaryGeneralReps;
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

/// Data for a single set in a completed workout summary.
class SummarySetData {
  final int setNumber;
  final int? targetReps;
  final double? targetWeightKg;
  final double? targetWeightLbs;
  final int? actualReps;
  final double? actualWeightKg;
  final double? actualWeightLbs;
  final int? rir;
  final double? rpe;
  final int? durationSeconds;
  final int? restSeconds;
  final String? barType;
  final double? previousWeightKg;
  final double? previousWeightLbs;
  final int? previousReps;
  final String? progressionModel;
  // Multiple notes per set are preserved in order. Empty list = no notes.
  final List<String> notes;
  // Photo URLs (S3) or local paths captured alongside notes for this set.
  final List<String> notesPhotoUrls;
  final String? completedAt;

  /// True when the parent exercise is bodyweight (e.g. pushup, pullup).
  /// Drives the "BW" render branch — without this flag, machine exercises
  /// with weight=0 (logged carelessly) would falsely render as "BW" too.
  final bool isBodyweight;

  /// Logged distance in meters for a distance-based set (SkiErg, sled push,
  /// a tracked run) — parsed from `distance_meters`. `reps`/`weight_kg` are
  /// CORRECTLY zeroed for these sets (`easy_active_workout_state.dart`
  /// deliberately zeroes reps when the set is timed/distance), so a table
  /// that only knows about reps/weight renders them as a bare "0" — see
  /// [hasAlternateMetric].
  final double? distanceMeters;

  /// Extra tracked metrics keyed by the catalog's metric name (e.g.
  /// `{'box_height_cm': 60}`), parsed from `metrics`, for exercises whose
  /// primary output isn't reps/weight/distance/time. Null/empty for
  /// ordinary sets.
  final Map<String, num>? metrics;

  const SummarySetData({
    required this.setNumber,
    this.targetReps,
    this.targetWeightKg,
    this.targetWeightLbs,
    this.actualReps,
    this.actualWeightKg,
    this.actualWeightLbs,
    this.rir,
    this.rpe,
    this.durationSeconds,
    this.restSeconds,
    this.barType,
    this.previousWeightKg,
    this.previousWeightLbs,
    this.previousReps,
    this.progressionModel,
    this.notes = const [],
    this.notesPhotoUrls = const [],
    this.completedAt,
    this.isBodyweight = false,
    this.distanceMeters,
    this.metrics,
  });

  /// True when [actualReps] is absent/zero but a real alternative metric
  /// (distance, set duration, or a custom metrics-bag entry) was actually
  /// recorded — i.e. a distance/timed set, not a rep set someone forgot to
  /// log. Reps legitimately IS zero for these (see [distanceMeters] doc);
  /// showing a bare "0" in the Reps cell reads as data loss when a real
  /// number exists (production example: "Air Swing Running", 19,950 logged
  /// meters, rendered as "Reps 0" with the distance nowhere on screen).
  bool get hasAlternateMetric =>
      (actualReps == null || actualReps == 0) &&
      (((distanceMeters ?? 0) > 0) ||
          ((durationSeconds ?? 0) > 0) ||
          (metrics != null && metrics!.isNotEmpty));

  /// This set's dominant recorded metric, for deciding a per-exercise column
  /// header (see `_metricKindOf` callers). Preference order mirrors
  /// `easy_persistence_helpers.dart`'s "hasOtherMetric" treatment: a set
  /// with real reps is a rep set even if it also carries other fields.
  SetMetricKind get metricKind {
    if (actualReps != null && actualReps! > 0) return SetMetricKind.reps;
    if ((distanceMeters ?? 0) > 0) return SetMetricKind.distance;
    if ((durationSeconds ?? 0) > 0) return SetMetricKind.duration;
    if (metrics != null && metrics!.isNotEmpty) return SetMetricKind.custom;
    return SetMetricKind.none;
  }

  /// The alternate metric's display text, or null if [hasAlternateMetric] is
  /// false.
  String? get alternateMetricLabel {
    if ((distanceMeters ?? 0) > 0) return formatSetDistanceMeters(distanceMeters!);
    if ((durationSeconds ?? 0) > 0) return formatSetDurationSeconds(durationSeconds!);
    if (metrics != null && metrics!.isNotEmpty) {
      final entry = metrics!.entries.first;
      final value = entry.value;
      final formattedValue =
          value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
      final label = entry.key.replaceAll('_', ' ');
      return '$formattedValue $label';
    }
    return null;
  }

  factory SummarySetData.fromJson(Map<String, dynamic> json) {
    return SummarySetData(
      setNumber: json['set_number'] as int? ?? 1,
      targetReps: json['target_reps'] as int?,
      targetWeightKg: (json['target_weight_kg'] as num?)?.toDouble(),
      targetWeightLbs: (json['target_weight_lbs'] as num?)?.toDouble(),
      actualReps: json['actual_reps'] as int?,
      actualWeightKg: (json['actual_weight_kg'] as num?)?.toDouble(),
      actualWeightLbs: (json['actual_weight_lbs'] as num?)?.toDouble(),
      rir: json['rir'] as int?,
      rpe: (json['rpe'] as num?)?.toDouble(),
      durationSeconds: json['duration_seconds'] as int?,
      restSeconds: json['rest_seconds'] as int?,
      barType: json['bar_type'] as String?,
      previousWeightKg: (json['previous_weight_kg'] as num?)?.toDouble(),
      previousWeightLbs: (json['previous_weight_lbs'] as num?)?.toDouble(),
      previousReps: json['previous_reps'] as int?,
      progressionModel: json['progression_model'] as String?,
      // Backwards-compatible coercion — accepts a list (current shape), a
      // raw string (legacy rows pre-array migration), or null.
      notes: coerceNotes(json['notes']),
      notesPhotoUrls: coerceStringList(json['notes_photo_urls']),
      completedAt: json['completed_at'] as String?,
      // is_bodyweight on the set OR is_bodyweight_exercise on the parent —
      // both are accepted for forward-compat with backend payload shape.
      isBodyweight: (json['is_bodyweight'] as bool?) ??
          (json['is_bodyweight_exercise'] as bool?) ??
          false,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      metrics: coerceMetrics(json['metrics']),
    );
  }

  /// Coerces the generic metrics bag into `Map<String, num>`, tolerant of a
  /// null/missing/wrongly-shaped value (never throws).
  static Map<String, num>? coerceMetrics(dynamic raw) {
    if (raw is! Map) return null;
    final out = <String, num>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is num) out[entry.key.toString()] = value;
    }
    return out.isEmpty ? null : out;
  }

  static List<String> coerceStringList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) return [raw.trim()];
    return const [];
  }

  /// Public so other parsers reading the same `sets_json` shape can reuse
  /// the same coercion. Accepts list, string, or null.
  static List<String> coerceNotes(dynamic raw) {
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

/// Data for an exercise in a completed workout summary.
class SummaryExerciseData {
  final String name;
  final int exerciseIndex;
  final bool isSkipped;
  final double? estimated1rmKg;
  final double? estimated1rmLbs;
  final String? progressionModel;
  final String? equipment;
  final String? equipmentType;
  final String? muscleGroup;
  final String? libraryId;
  final String? imageUrl;
  final String? videoUrl;
  final List<SummarySetData> sets;
  final List<Map<String, dynamic>>? prs;
  final List<Map<String, dynamic>>? drinks;

  const SummaryExerciseData({
    required this.name,
    required this.exerciseIndex,
    this.isSkipped = false,
    this.estimated1rmKg,
    this.estimated1rmLbs,
    this.progressionModel,
    this.equipment,
    this.equipmentType,
    this.muscleGroup,
    this.libraryId,
    this.imageUrl,
    this.videoUrl,
    this.sets = const [],
    this.prs,
    this.drinks,
  });

  factory SummaryExerciseData.fromJson(Map<String, dynamic> json) {
    return SummaryExerciseData(
      name: json['name'] as String? ?? 'Unknown Exercise',
      exerciseIndex: json['exercise_index'] as int? ?? 0,
      isSkipped: json['is_skipped'] as bool? ?? false,
      estimated1rmKg: (json['estimated_1rm_kg'] as num?)?.toDouble(),
      estimated1rmLbs: (json['estimated_1rm_lbs'] as num?)?.toDouble(),
      progressionModel: json['progression_model'] as String?,
      equipment: json['equipment'] as String?,
      equipmentType: json['equipment_type'] as String?,
      muscleGroup: json['muscle_group'] as String?,
      libraryId: json['library_id'] as String?,
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      sets: (json['sets'] as List<dynamic>?)
              ?.map((s) => SummarySetData.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
      prs: (json['prs'] as List<dynamic>?)
          ?.map((p) => Map<String, dynamic>.from(p as Map))
          .toList(),
      drinks: (json['drinks'] as List<dynamic>?)
          ?.map((d) => Map<String, dynamic>.from(d as Map))
          .toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

/// Read-only exercise table for the workout summary screen.
///
/// Displays completed exercise data including sets, weights, reps, RIR,
/// and timing information. Mirrors the column layout of [SetTrackingTable]
/// but removes all interactive elements (inputs, checkboxes, swipe-to-delete).
class SummaryExerciseTable extends StatelessWidget {
  /// All exercises to display.
  final List<SummaryExerciseData> exercises;

  /// Whether to show weights in kg (true) or lbs (false).
  final bool useKg;

  /// Callback when an exercise header is tapped.
  /// Returns a [VoidCallback] to execute, or null to disable tap.
  final VoidCallback? Function(String exerciseName, String? libraryId)?
      onExerciseTap;

  const SummaryExerciseTable({
    super.key,
    required this.exercises,
    required this.useKg,
    this.onExerciseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < exercises.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _ExerciseSection(
            exercise: exercises[i],
            useKg: useKg,
            onExerciseTap: onExerciseTap,
          ),
        ],
      ],
    );
  }
}

/// Just the set grid (column header + set rows + timing rows) for ONE
/// exercise, WITHOUT the exercise-name header. Used by the collapsible
/// [SummaryExerciseCard] which renders its own richer header (AI button,
/// detail chevron, collapsed summary), so the table body must not repeat the
/// name. Adaptive columns match [SummaryExerciseTable] exactly.
class SummaryExerciseSetsTable extends StatelessWidget {
  final SummaryExerciseData exercise;
  final bool useKg;

  const SummaryExerciseSetsTable({
    super.key,
    required this.exercise,
    required this.useKg,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sets = exercise.sets;
    if (exercise.isSkipped || sets.isEmpty) return const SizedBox.shrink();

    final showPrevious = sets.any((s) =>
        (s.previousWeightKg ?? s.previousWeightLbs) != null ||
        s.previousReps != null);
    final showTarget = sets.any((s) =>
        (s.targetWeightKg ?? s.targetWeightLbs) != null || s.targetReps != null);
    final showRir = sets.any((s) => s.rir != null);
    final repsLabel = repsColumnLabel(context, sets);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryTableHeader(
          useKg: useKg,
          isDark: isDark,
          showPrevious: showPrevious,
          showTarget: showTarget,
          showRir: showRir,
          repsLabel: repsLabel,
        ),
        for (final set in sets) ...[
          _SummarySetRow(
            set: set,
            useKg: useKg,
            isDark: isDark,
            showPrevious: showPrevious,
            showTarget: showTarget,
            showRir: showRir,
          ),
          if (_SummaryTimingRow.hasMeaningfulTiming(set))
            _SummaryTimingRow(set: set, isDark: isDark),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXERCISE SECTION (header + table)
// ═══════════════════════════════════════════════════════════════════════════════

class _ExerciseSection extends StatelessWidget {
  final SummaryExerciseData exercise;
  final bool useKg;
  final VoidCallback? Function(String exerciseName, String? libraryId)?
      onExerciseTap;

  const _ExerciseSection({
    required this.exercise,
    required this.useKg,
    this.onExerciseTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Adaptive columns — only render Previous / Target / RIR when at least
    // one set in THIS exercise actually carries that data. A freshly tracked
    // workout collapses to Set / Weight / Reps instead of a wall of "—";
    // the columns reappear automatically once the data exists. Header and
    // rows share the same flags so cells stay aligned.
    final sets = exercise.sets;
    final showPrevious = sets.any((s) =>
        (s.previousWeightKg ?? s.previousWeightLbs) != null ||
        s.previousReps != null);
    final showTarget = sets.any((s) =>
        (s.targetWeightKg ?? s.targetWeightLbs) != null ||
        s.targetReps != null);
    final showRir = sets.any((s) => s.rir != null);
    final repsLabel = repsColumnLabel(context, sets);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exercise header
        _ExerciseHeader(
          exercise: exercise,
          useKg: useKg,
          isDark: isDark,
          onTap: onExerciseTap?.call(exercise.name, exercise.libraryId),
        ),

        // Column headers + set rows (skip for skipped exercises)
        if (!exercise.isSkipped && exercise.sets.isNotEmpty) ...[
          _SummaryTableHeader(
            useKg: useKg,
            isDark: isDark,
            showPrevious: showPrevious,
            showTarget: showTarget,
            showRir: showRir,
            repsLabel: repsLabel,
          ),
          for (final set in exercise.sets) ...[
            _SummarySetRow(
              set: set,
              useKg: useKg,
              isDark: isDark,
              showPrevious: showPrevious,
              showTarget: showTarget,
              showRir: showRir,
            ),
            if (_SummaryTimingRow.hasMeaningfulTiming(set))
              _SummaryTimingRow(set: set, isDark: isDark),
          ],
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXERCISE HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _ExerciseHeader extends StatelessWidget {
  final SummaryExerciseData exercise;
  final bool useKg;
  final bool isDark;
  final VoidCallback? onTap;

  const _ExerciseHeader({
    required this.exercise,
    required this.useKg,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrs = exercise.prs != null && exercise.prs!.isNotEmpty;
    final e1rm = useKg ? exercise.estimated1rmKg : exercise.estimated1rmLbs;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Exercise name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // PR gold star
                      if (hasPrs) ...[
                        const Icon(Icons.star, size: 16, color: Color(0xFFEAB308)),  // accent-allowlist: PR gold star, see comment above
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          exercise.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: exercise.isSkipped
                                ? (isDark
                                    ? WorkoutDesign.textMuted
                                    : Colors.grey.shade400)
                                : (isDark
                                    ? WorkoutDesign.textPrimary
                                    : WorkoutDesign.textPrimaryLight),
                            decoration: exercise.isSkipped
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: isDark
                                ? WorkoutDesign.textMuted
                                : Colors.grey.shade400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Badges row: Skipped / 1RM / Equipment
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (exercise.isSkipped)
                        _BadgeChip(
                          label: AppLocalizations.of(context).summaryExerciseTableSkipped,
                          color: isDark ? AppColors.error : AppColorsLight.error,  // accent-allowlist: error/destructive — must stay red
                          isDark: isDark,
                        ),
                      if (e1rm != null && !exercise.isSkipped)
                        _BadgeChip(
                          label:
                              'e1RM ${e1rm.toStringAsFixed(0)} ${useKg ? 'kg' : 'lb'}',
                          color: context.accentColor,
                          isDark: isDark,
                        ),
                      if (exercise.equipment != null &&
                          exercise.equipment!.isNotEmpty &&
                          !exercise.isSkipped)
                        _BadgeChip(
                          label: exercise.equipment!,
                          color: isDark
                              ? WorkoutDesign.textSecondary
                              : Colors.grey.shade600,
                          isDark: isDark,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron if tappable
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade400,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TABLE HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _SummaryTableHeader extends StatelessWidget {
  final bool useKg;
  final bool isDark;
  final bool showPrevious;
  final bool showTarget;
  final bool showRir;

  /// Overrides the "REPS" column label — pass the result of
  /// [repsColumnLabel] so a whole-exercise distance/timed table reads
  /// "DISTANCE"/"TIME" instead of a column of zeroes under "REPS". Null
  /// (the default) keeps the plain localized "REPS" string.
  final String? repsLabel;

  const _SummaryTableHeader({
    required this.useKg,
    required this.isDark,
    this.showPrevious = true,
    this.showTarget = true,
    this.showRir = true,
    this.repsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final headerColor =
        isDark ? WorkoutDesign.textMuted : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? WorkoutDesign.borderSubtle : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Set
          SizedBox(
            width: 32,
            child: Text(
              AppLocalizations.of(context).workoutSummaryAdvancedSet,
              style: WorkoutDesign.tableHeaderStyle
                  .copyWith(color: headerColor),
            ),
          ),
          // Previous
          if (showPrevious)
            Expanded(
              flex: 3,
              child: Text(
                AppLocalizations.of(context).summaryExerciseTablePrevious,
                style: WorkoutDesign.tableHeaderStyle
                    .copyWith(color: headerColor),
              ),
            ),
          // Target
          if (showTarget)
            Expanded(
              flex: 3,
              child: Text(
                AppLocalizations.of(context).summaryExerciseTableTarget,
                style: WorkoutDesign.tableHeaderStyle.copyWith(
                  color: WorkoutDesign.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          // Flexible filler keeps Weight/Reps anchored right when both
          // optional leading columns are hidden.
          if (!showPrevious && !showTarget) const Spacer(),
          // Weight
          SizedBox(
            width: 64,
            child: Text(
              useKg ? 'kg' : 'lb',
              style: WorkoutDesign.tableHeaderStyle
                  .copyWith(color: headerColor),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // Reps (or DISTANCE/TIME/METRIC — see [repsLabel]). FittedBox since
          // those replacement labels are longer than "REPS" and this column
          // is a fixed 48px.
          SizedBox(
            width: 48,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                repsLabel ?? AppLocalizations.of(context).workoutSummaryGeneralReps,
                maxLines: 1,
                style: WorkoutDesign.tableHeaderStyle
                    .copyWith(color: headerColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (showRir) ...[
            const SizedBox(width: 4),
            // RIR
            SizedBox(
              width: 26,
              child: Text(
                'RIR',
                style: WorkoutDesign.tableHeaderStyle.copyWith(
                  color: headerColor,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// NOTES VIEWER SHEET
// ═══════════════════════════════════════════════════════════════════════════════

/// Read-only notes viewer for a completed set. Opens when the user taps the
/// sticky-note icon on a set row. Displays every note in capture order with
/// the set number for context. Editing on the completed-summary screen is
/// intentionally deferred — the viewer is a focused fix for "I added
/// multiple notes but only see one" / "I tap the icon and nothing happens".
void _showSetNotesSheet({
  required BuildContext context,
  required bool isDark,
  required int setNumber,
  required List<String> notes,
  List<String> photoUrls = const [],
  String? completedAt,
}) {
  final fg = isDark ? Colors.white : Colors.black87;
  final muted = isDark ? Colors.white60 : Colors.black54;

  showGlassSheet<void>(
    context: context,
    builder: (ctx) {
      return GlassSheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sticky_note_2_rounded, color: fg, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Set $setNumber notes',
                    style: TextStyle(
                      color: fg,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    () {
                      final n = notes.length;
                      final p = photoUrls.length;
                      final parts = <String>[];
                      if (n > 0) parts.add(n == 1 ? '1 note' : '$n notes');
                      if (p > 0) parts.add(p == 1 ? '1 photo' : '$p photos');
                      return parts.isEmpty ? '0 notes' : parts.join(' · ');
                    }(),
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (photoUrls.isNotEmpty) ...[
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photoUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final src = photoUrls[i];
                      final isRemote = src.startsWith('http');
                      return GestureDetector(
                        onTap: () => _showPhotoFullscreen(context, photoUrls, i),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 96,
                            height: 96,
                            child: isRemote
                                ? Image.network(
                                    src,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: muted.withValues(alpha: 0.15),
                                      alignment: Alignment.center,
                                      child: Icon(Icons.broken_image, color: muted, size: 28),
                                    ),
                                  )
                                : Image.file(
                                    File(src),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: muted.withValues(alpha: 0.15),
                                      alignment: Alignment.center,
                                      child: Icon(Icons.broken_image, color: muted, size: 28),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (notes.isEmpty && photoUrls.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    AppLocalizations.of(context).summaryExerciseTableNoNotesOrPhotos,
                    style: TextStyle(color: muted, fontSize: 14),
                  ),
                )
              else if (notes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    AppLocalizations.of(context).summaryExerciseTableNoNotesSavedOn,
                    style: TextStyle(color: muted, fontSize: 14),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: notes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: AppColors.electricBlue
                                  .withValues(alpha: 0.18),
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: AppColors.electricBlue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                notes[i],
                                style: TextStyle(
                                  color: fg,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              if (completedAt != null && completedAt.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Logged ${_formatCompletedAt(completedAt)}',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

void _showPhotoFullscreen(BuildContext context, List<String> photos, int initialIndex) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      pageBuilder: (ctx, __, ___) {
        final controller = PageController(initialPage: initialIndex);
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                PageView.builder(
                  controller: controller,
                  itemCount: photos.length,
                  itemBuilder: (_, i) {
                    final src = photos[i];
                    final isRemote = src.startsWith('http');
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: isRemote
                            ? Image.network(src, fit: BoxFit.contain)
                            : Image.file(File(src), fit: BoxFit.contain),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

String _formatCompletedAt(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return 'at $h:$m $ampm';
  } catch (_) {
    return '';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SET ROW
// ═══════════════════════════════════════════════════════════════════════════════

class _SummarySetRow extends StatelessWidget {
  final SummarySetData set;
  final bool useKg;
  final bool isDark;
  final bool showPrevious;
  final bool showTarget;
  final bool showRir;

  const _SummarySetRow({
    required this.set,
    required this.useKg,
    required this.isDark,
    this.showPrevious = true,
    this.showTarget = true,
    this.showRir = true,
  });

  /// Gym-snapped display value (no unit). Prefers the canonical kg value so
  /// lbs entries round-trip exactly (57 lb stays "57", never "56.9" —
  /// see WeightUtils.formatWorkoutWeight); falls back to the pre-converted
  /// lbs/kg field for legacy rows that only carry one of the two.
  String? _displayWeight(double? weightKg, double? weightLbs) {
    if (weightKg != null && weightKg > 0) {
      return WeightUtils.formatWorkoutWeight(weightKg,
          useKg: useKg, withUnit: false);
    }
    final weight = useKg ? weightKg : weightLbs;
    if (weight == null || weight <= 0) return null;
    return WeightUtils.formatWeightValue(weight);
  }

  /// Format weight for display. Returns "BW" only when the exercise is
  /// genuinely bodyweight (set.isBodyweight=true); otherwise renders "—"
  /// for missing data so machine exercises don't get falsely BW-labeled.
  String _formatWeight(double? weightKg, double? weightLbs) {
    final display = _displayWeight(weightKg, weightLbs);
    if (display == null) {
      return set.isBodyweight ? 'BW' : '—';
    }
    return display;
  }

  /// Format "weight x reps" for previous/target columns. Same BW gating
  /// as `_formatWeight` — only render bare "BW" for genuine bodyweight
  /// exercises; render "BW x 12" when bodyweight + reps are known.
  String _formatWeightReps(double? weightKg, double? weightLbs, int? reps) {
    if (weightKg == null && weightLbs == null && reps == null) return '—';

    final display = _displayWeight(weightKg, weightLbs);
    final unit = WeightUtils.workoutUnitLabel(useKg);

    if (display != null && reps != null) {
      return '$display $unit x $reps';
    } else if (display != null) {
      return '$display $unit';
    } else if (reps != null) {
      // No weight logged. Bodyweight → "BW x N"; missing data → "— x N".
      return set.isBodyweight ? 'BW x $reps' : '— x $reps';
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final previousText = _formatWeightReps(
      set.previousWeightKg,
      set.previousWeightLbs,
      set.previousReps,
    );

    final targetText = _formatWeightReps(
      set.targetWeightKg,
      set.targetWeightLbs,
      set.targetReps,
    );

    final weightText = _formatWeight(set.actualWeightKg, set.actualWeightLbs);
    final hasNotes = set.notes.isNotEmpty || set.notesPhotoUrls.isNotEmpty;

    return Container(
      height: WorkoutDesign.setRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Set number badge
          SizedBox(
            width: 32,
            child: _SummarySetNumberBadge(
              number: set.setNumber,
              isDark: isDark,
            ),
          ),

          // Previous column
          if (showPrevious)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  previousText,
                  style: WorkoutDesign.autoTargetStyle.copyWith(
                    color:
                        isDark ? WorkoutDesign.textMuted : Colors.grey.shade500,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          // Target column
          if (showTarget)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  targetText,
                  style: WorkoutDesign.autoTargetStyle.copyWith(
                    color: isDark
                        ? WorkoutDesign.textSecondary
                        : Colors.grey.shade700,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          // Mirror of the header's filler — keeps cells column-aligned.
          if (!showPrevious && !showTarget) const Spacer(),

          // Actual weight
          SizedBox(
            width: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      weightText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? WorkoutDesign.textPrimary
                            : WorkoutDesign.textPrimaryLight,
                      ),
                    ),
                  ),
                ),
                if (hasNotes) ...[
                  const SizedBox(width: 2),
                  // Tap target sized up so the icon is actually hittable —
                  // 12px icons are below the 44pt iOS / 48dp Android touch
                  // target, hence the user's "I tap the icon and nothing
                  // happens" report.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showSetNotesSheet(
                      context: context,
                      isDark: isDark,
                      setNumber: set.setNumber,
                      notes: set.notes,
                      photoUrls: set.notesPhotoUrls,
                      completedAt: set.completedAt,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        set.notesPhotoUrls.isNotEmpty && set.notes.isEmpty
                            ? Icons.image_outlined
                            : Icons.sticky_note_2_outlined,
                        size: 14,
                        color: isDark
                            ? WorkoutDesign.textPrimary
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Actual reps — or the set's real alternate metric (distance/time/
          // custom) when reps is legitimately 0 but something else was
          // actually logged. Was a bare `set.actualReps?.toString() ?? '—'`,
          // which rendered literal "0" for a distance/timed set (e.g. a
          // logged 19,950m run showed "Reps 0" with the distance nowhere on
          // screen) — see [SummarySetData.hasAlternateMetric].
          SizedBox(
            width: 48,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                set.hasAlternateMetric
                    ? set.alternateMetricLabel!
                    : (set.actualReps?.toString() ?? '—'),
                maxLines: 1,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? WorkoutDesign.textPrimary
                      : WorkoutDesign.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          if (showRir) ...[
            const SizedBox(width: 4),

            // RIR badge
            SizedBox(
              width: 26,
              child: set.rir != null
                  ? _SummaryRirBadge(rir: set.rir!, isDark: isDark)
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TIMING ROW
// ═══════════════════════════════════════════════════════════════════════════════

class _SummaryTimingRow extends StatelessWidget {
  final SummarySetData set;
  final bool isDark;

  const _SummaryTimingRow({required this.set, required this.isDark});

  /// Rest shorter than this is timer noise (the user tapped through), not a
  /// real rest interval worth narrating.
  static const int _minMeaningfulRestSeconds = 15;

  /// Set durations under this are instant log-taps, not timed sets — showing
  /// "set 1: 3s" reads like a bug, so they're suppressed entirely.
  static const int _minMeaningfulSetSeconds = 30;

  /// Whether this set has any timing worth a divider row. Used by the parent
  /// section as the render gate so no empty rows are built.
  static bool hasMeaningfulTiming(SummarySetData set) {
    final rest = set.restSeconds;
    final duration = set.durationSeconds;
    return (rest != null && rest >= _minMeaningfulRestSeconds) ||
        (duration != null && duration >= _minMeaningfulSetSeconds);
  }

  String _formatDuration(int seconds) {
    if (seconds >= 60) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return '$m:${s.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final textMuted =
        isDark ? AppColors.textMuted : const Color(0xFF9CA3AF);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    final parts = <String>[];
    final rest = set.restSeconds;
    if (rest != null && rest >= _minMeaningfulRestSeconds) {
      parts.add('Rest ${_formatDuration(rest)}');
    }
    final duration = set.durationSeconds;
    if (duration != null && duration >= _minMeaningfulSetSeconds) {
      parts.add('${_formatDuration(duration)} set');
    }
    final label = parts.join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Divider(
                height: 1, thickness: 0.5, color: borderColor),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            child: Divider(
                height: 1, thickness: 0.5, color: borderColor),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SMALL REUSABLE COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════════

/// Set number circle badge (read-only, completed style).
class _SummarySetNumberBadge extends StatelessWidget {
  final int number;
  final bool isDark;

  const _SummarySetNumberBadge({required this.number, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isDark
            ? WorkoutDesign.textMuted.withOpacity(0.15)
            : Colors.grey.shade200,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? WorkoutDesign.textMuted.withOpacity(0.3)
              : Colors.grey.shade400,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

/// RIR badge for completed sets (color-coded circle).
class _SummaryRirBadge extends StatelessWidget {
  final int rir;
  final bool isDark;

  const _SummaryRirBadge({required this.rir, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = WorkoutDesign.getRirColor(rir);
    final textColor = WorkoutDesign.getRirTextColor(rir);

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$rir',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

/// Small colored chip for metadata badges (equipment, 1RM, skipped).
class _BadgeChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _BadgeChip({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
