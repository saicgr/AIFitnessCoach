/// Summary Exercise Table Widget
///
/// Read-only display version of SetTrackingTable for the workout summary screen.
/// Shows completed exercise data with set details, timing, and RIR badges.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/workout_design.dart';

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
  final String? completedAt;

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
    this.completedAt,
  });

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
      completedAt: json['completed_at'] as String?,
    );
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
          _SummaryTableHeader(useKg: useKg, isDark: isDark),
          for (final set in exercise.sets) ...[
            _SummarySetRow(set: set, useKg: useKg, isDark: isDark),
            if (set.durationSeconds != null)
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
                        const Icon(Icons.star, size: 16, color: Color(0xFFEAB308)),
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
                          label: 'Skipped',
                          color: isDark ? AppColors.error : AppColorsLight.error,
                          isDark: isDark,
                        ),
                      if (e1rm != null && !exercise.isSkipped)
                        _BadgeChip(
                          label:
                              'e1RM ${e1rm.toStringAsFixed(0)} ${useKg ? 'kg' : 'lb'}',
                          color: isDark ? AppColors.purple : AppColorsLight.purple,
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

  const _SummaryTableHeader({required this.useKg, required this.isDark});

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
              'Set',
              style: WorkoutDesign.tableHeaderStyle
                  .copyWith(color: headerColor),
            ),
          ),
          // Previous
          Expanded(
            flex: 3,
            child: Text(
              'Previous',
              style: WorkoutDesign.tableHeaderStyle
                  .copyWith(color: headerColor),
            ),
          ),
          // Target
          Expanded(
            flex: 3,
            child: Text(
              'TARGET',
              style: WorkoutDesign.tableHeaderStyle.copyWith(
                color: WorkoutDesign.accentBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
          // Reps
          SizedBox(
            width: 48,
            child: Text(
              'Reps',
              style: WorkoutDesign.tableHeaderStyle
                  .copyWith(color: headerColor),
              textAlign: TextAlign.center,
            ),
          ),
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
  String? completedAt,
}) {
  final bg = isDark ? const Color(0xFF111111) : Colors.white;
  final fg = isDark ? Colors.white : Colors.black87;
  final muted = isDark ? Colors.white60 : Colors.black54;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                    notes.length == 1 ? '1 note' : '${notes.length} notes',
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (notes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No notes saved on this set.',
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

  const _SummarySetRow({
    required this.set,
    required this.useKg,
    required this.isDark,
  });

  /// Format weight for display. Returns "BW" for bodyweight (0 or null).
  String _formatWeight(double? weightKg, double? weightLbs) {
    final weight = useKg ? weightKg : weightLbs;
    if (weight == null || weight == 0) return 'BW';
    return weight.toStringAsFixed(0);
  }

  /// Format "weight x reps" for previous/target columns.
  String _formatWeightReps(double? weightKg, double? weightLbs, int? reps) {
    if (weightKg == null && weightLbs == null && reps == null) return '—';

    final weight = useKg ? weightKg : weightLbs;
    final unit = useKg ? 'kg' : 'lb';

    if (weight != null && weight > 0 && reps != null) {
      return '${weight.toStringAsFixed(0)} $unit x $reps';
    } else if (weight != null && weight > 0) {
      return '${weight.toStringAsFixed(0)} $unit';
    } else if (reps != null) {
      return 'BW x $reps';
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
    final hasNotes = set.notes.isNotEmpty;

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

          // Actual weight
          SizedBox(
            width: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  weightText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? WorkoutDesign.textPrimary
                        : WorkoutDesign.textPrimaryLight,
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
                      completedAt: set.completedAt,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.sticky_note_2_outlined,
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

          // Actual reps
          SizedBox(
            width: 48,
            child: Text(
              set.actualReps?.toString() ?? '—',
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

          const SizedBox(width: 4),

          // RIR badge
          SizedBox(
            width: 26,
            child: set.rir != null
                ? _SummaryRirBadge(rir: set.rir!, isDark: isDark)
                : const SizedBox.shrink(),
          ),
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

    final duration = _formatDuration(set.durationSeconds!);
    final setLabel = 'set ${set.setNumber}';
    String label = '$setLabel: $duration';

    if (set.restSeconds != null) {
      if (set.restSeconds! < 3) {
        label = '$setLabel: $duration · skipped rest';
      } else {
        label =
            '$setLabel: $duration · rested ${_formatDuration(set.restSeconds!)}';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Divider(
                height: 1, thickness: 0.5, color: borderColor),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: textMuted,
                fontStyle: FontStyle.italic,
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
