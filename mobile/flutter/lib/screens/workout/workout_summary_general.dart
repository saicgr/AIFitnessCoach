/// General view for the Workout Summary screen.
///
/// Displays header, hero stats grid, heart rate chart, muscles worked,
/// exercise table, personal records, AI coach review, and post-workout
/// feedback sections. Sections with no data are hidden entirely.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/heart_rate_provider.dart';
import '../../data/models/workout.dart';
import '../../widgets/heart_rate_chart.dart';
import '../library/providers/muscle_group_images_provider.dart';
import 'widgets/summary_exercise_table.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class WorkoutSummaryGeneral extends StatelessWidget {
  final WorkoutSummaryResponse? data;
  final Map<String, dynamic>? metadata;
  final double topPadding;

  const WorkoutSummaryGeneral({
    super.key,
    required this.data,
    required this.metadata,
    this.topPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = data!;
    final comparison = summary.performanceComparison;
    final wc = comparison?.workoutComparison;

    // Parse workout map fields
    final workoutName = summary.workout['name'] as String? ?? 'Workout';
    final scheduledDate = summary.workout['scheduled_date'] as String?;
    final exercisesJson = summary.workout['exercises_json'];

    // Parse exercises for muscles worked
    final exercises = _parseExercises(exercisesJson);

    // Build exercise table data from metadata sets_json (preferred) or set logs
    final exerciseTableData =
        _buildExerciseTableData(summary, metadata, exercises);

    // Heart rate
    final heartRateData = _parseHeartRate(metadata);

    // Coach review
    final coachReview = summary.parsedCoachReview;
    final rawCoachSummary = summary.coachSummary;

    // Personal records
    final personalRecords = summary.personalRecords;

    // Feedback from metadata
    final feedback = metadata?['workout_feedback'] as Map<String, dynamic>?;

    int sectionIndex = 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: topPadding + 56,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // 1. Header
          _HeaderSection(
            workoutName: workoutName,
            scheduledDate: scheduledDate,
            isMarkedDone: summary.isMarkedDone,
            completedAt: summary.completedAt,
          )
              .animate()
              .fadeIn(
                duration: 400.ms,
                delay: Duration(milliseconds: 100 * sectionIndex++),
              )
              .slideY(begin: 0.05, end: 0),

          const SizedBox(height: 16),

          // 2. Hero Stats Grid — render even when wc is null so older
          // workouts without a workout_performance_summary row still show
          // duration/exercises/volume/sets/reps computed from set_logs.
          _HeroStatsGrid(
            workoutComparison: wc,
            setLogs: summary.setLogs,
            exercises: exercises,
            metadata: metadata,
          )
              .animate()
              .fadeIn(
                duration: 400.ms,
                delay: Duration(milliseconds: 100 * sectionIndex++),
              )
              .slideY(begin: 0.05, end: 0),

          const SizedBox(height: 16),

          // 3. Heart Rate Section (always shown — placeholder when no data)
          _HeartRateSection(heartRateData: heartRateData, isDark: isDark)
              .animate()
              .fadeIn(
                duration: 400.ms,
                delay: Duration(milliseconds: 100 * sectionIndex++),
              )
              .slideY(begin: 0.05, end: 0),
          const SizedBox(height: 16),

          // 4. Muscles Worked
          if (exercises.isNotEmpty)
            _MusclesWorkedSection(
              exercises: exercises,
              setLogs: summary.setLogs,
              isDark: isDark,
            )
                .animate()
                .fadeIn(
                  duration: 400.ms,
                  delay: Duration(milliseconds: 100 * sectionIndex++),
                )
                .slideY(begin: 0.05, end: 0),

          if (exercises.isNotEmpty) const SizedBox(height: 16),

          // 5. Exercise Table
          if (exerciseTableData.isNotEmpty)
            _ExerciseTableSection(
              exercises: exerciseTableData,
              isDark: isDark,
            )
                .animate()
                .fadeIn(
                  duration: 400.ms,
                  delay: Duration(milliseconds: 100 * sectionIndex++),
                )
                .slideY(begin: 0.05, end: 0),

          if (exerciseTableData.isNotEmpty) const SizedBox(height: 16),

          // 5.5. Personal Records
          if (personalRecords.isNotEmpty)
            _PersonalRecordsSection(
              records: personalRecords,
              isDark: isDark,
            )
                .animate()
                .fadeIn(
                  duration: 400.ms,
                  delay: Duration(milliseconds: 100 * sectionIndex++),
                )
                .slideY(begin: 0.05, end: 0),

          if (personalRecords.isNotEmpty) const SizedBox(height: 16),

          // 6. AI Coach Review
          if (coachReview != null ||
              (rawCoachSummary != null && rawCoachSummary.isNotEmpty))
            _CoachReviewSection(
              coachReview: coachReview,
              rawSummary: rawCoachSummary,
              isDark: isDark,
            )
                .animate()
                .fadeIn(
                  duration: 400.ms,
                  delay: Duration(milliseconds: 100 * sectionIndex++),
                )
                .slideY(begin: 0.05, end: 0),

          if (coachReview != null ||
              (rawCoachSummary != null && rawCoachSummary.isNotEmpty))
            const SizedBox(height: 16),

          // 7. Post-Workout Feedback
          if (feedback != null)
            _PostWorkoutFeedbackSection(feedback: feedback, isDark: isDark)
                .animate()
                .fadeIn(
                  duration: 400.ms,
                  delay: Duration(milliseconds: 100 * sectionIndex++),
                )
                .slideY(begin: 0.05, end: 0),

          // 8. Bottom padding for floating pill clearance
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────

  List<Map<String, dynamic>> _parseExercises(dynamic exercisesJson) {
    if (exercisesJson == null) return [];
    try {
      if (exercisesJson is String) {
        final decoded = jsonDecode(exercisesJson);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      }
      if (exercisesJson is List) {
        return exercisesJson.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Builds exercise table data, preferring metadata['sets_json'] (richest
  /// source) and falling back to setLogs + exercises_json when unavailable.
  List<SummaryExerciseData> _buildExerciseTableData(
    WorkoutSummaryResponse summary,
    Map<String, dynamic>? metadata,
    List<Map<String, dynamic>> parsedExercises,
  ) {
    // Attempt to parse sets_json from metadata (richest data source)
    final setsJsonRaw = metadata?['sets_json'];
    if (setsJsonRaw != null) {
      final setsJsonList = _parseSetsJson(setsJsonRaw);
      if (setsJsonList.isNotEmpty) {
        return _buildFromSetsJson(
          setsJsonList,
          parsedExercises,
          summary.personalRecords,
          metadata,
        );
      }
    }

    // Fallback: build from setLogs + exercises_json
    return _buildFromSetLogs(summary, parsedExercises);
  }

  /// Parse sets_json from raw dynamic value into List<Map<String, dynamic>>.
  List<Map<String, dynamic>> _parseSetsJson(dynamic raw) {
    try {
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      }
      if (raw is List) {
        return raw.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Build from metadata['sets_json'] — the richest data source.
  List<SummaryExerciseData> _buildFromSetsJson(
    List<Map<String, dynamic>> setsJson,
    List<Map<String, dynamic>> parsedExercises,
    List<PersonalRecordInfo> personalRecords,
    Map<String, dynamic>? metadata,
  ) {
    // Group sets by exercise_name (case-insensitive)
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    final Map<String, int> exerciseIndexMap = {};

    for (final set in setsJson) {
      final name = (set['exercise_name'] as String? ?? 'Unknown').trim();
      final key = name.toLowerCase();
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(set);
      // Track the exercise_index from the first occurrence
      if (!exerciseIndexMap.containsKey(key)) {
        exerciseIndexMap[key] = set['exercise_index'] as int? ?? 0;
      }
    }

    // Parse drink events from metadata
    final drinkEvents = _parseDrinkEvents(metadata?['drink_events']);

    // Parse skipped exercise indices
    final skippedIndices = _parseSkippedIndices(metadata?['skipped_exercise_indices']);

    // Build a lookup map for exercises_json by name (case-insensitive)
    final Map<String, Map<String, dynamic>> exerciseLookup = {};
    for (int i = 0; i < parsedExercises.length; i++) {
      final ex = parsedExercises[i];
      final name = (ex['name'] as String? ?? '').trim().toLowerCase();
      if (name.isNotEmpty) {
        exerciseLookup[name] = ex;
      }
    }

    // Build a lookup for PRs by exercise name (case-insensitive)
    final Map<String, List<Map<String, dynamic>>> prLookup = {};
    for (final pr in personalRecords) {
      final key = pr.exerciseName.trim().toLowerCase();
      prLookup.putIfAbsent(key, () => []);
      prLookup[key]!.add({
        'exercise_name': pr.exerciseName,
        'weight_kg': pr.weightKg,
        'weight_lbs': pr.weightKg * 2.20462,
        'reps': pr.reps,
        'estimated_1rm_kg': pr.estimated1rmKg,
        'estimated_1rm_lbs': pr.estimated1rmKg * 2.20462,
        'previous_1rm_kg': pr.previous1rmKg,
        'improvement_kg': pr.improvementKg,
        'improvement_percent': pr.improvementPercent,
        'is_all_time_pr': pr.isAllTimePr,
        'celebration_message': pr.celebrationMessage,
      });
    }

    final List<SummaryExerciseData> result = [];

    for (final entry in grouped.entries) {
      final key = entry.key;
      final sets = entry.value;
      final exerciseIndex = exerciseIndexMap[key] ?? 0;

      // Look up planned exercise data from exercises_json
      final planned = exerciseLookup[key];

      // Build SummarySetData from each set map.
      //
      // Field-name contract must match `buildSetsJson()` in
      // mobile/flutter/lib/screens/workout/mixins/set_logging_mixin.dart —
      // the writer uses `weight_kg` (canonical) and `set_duration_seconds`.
      // Bare `weight` / `duration_seconds` are accepted as legacy fallbacks
      // for any workout logged before the field names were aligned, so
      // historic rows keep rendering correctly.
      final summarySetsList = sets.map((s) {
        final weightKg =
            (s['weight_kg'] as num?)?.toDouble() ?? (s['weight'] as num?)?.toDouble();
        final targetWeightKg = (s['target_weight_kg'] as num?)?.toDouble();
        final previousWeightKg = (s['previous_weight_kg'] as num?)?.toDouble();
        final durationSeconds = (s['set_duration_seconds'] as int?) ??
            (s['duration_seconds'] as int?);

        return SummarySetData(
          setNumber: s['set_number'] as int? ?? 1,
          targetReps: s['target_reps'] as int?,
          targetWeightKg: targetWeightKg,
          targetWeightLbs:
              targetWeightKg != null ? targetWeightKg * 2.20462 : null,
          actualReps: s['reps'] as int?,
          actualWeightKg: weightKg,
          actualWeightLbs: weightKg != null ? weightKg * 2.20462 : null,
          rir: s['rir'] as int?,
          rpe: (s['rpe'] as num?)?.toDouble(),
          durationSeconds: durationSeconds,
          restSeconds: s['rest_duration_seconds'] as int?,
          barType: s['bar_type'] as String?,
          previousWeightKg: previousWeightKg,
          previousWeightLbs:
              previousWeightKg != null ? previousWeightKg * 2.20462 : null,
          previousReps: s['previous_reps'] as int?,
          progressionModel: s['progression_model'] as String?,
          // Coerce list (new) or string (legacy) into the list shape.
          notes: SummarySetData.coerceNotes(s['notes']),
          completedAt: s['completed_at'] as String?,
        );
      }).toList();

      // Sort by set number
      summarySetsList.sort((a, b) => a.setNumber.compareTo(b.setNumber));

      // Filter drink events for this exercise
      final exerciseDrinks = drinkEvents
          .where(
              (d) => (d['exercise_name'] as String? ?? '').toLowerCase() == key)
          .toList();

      result.add(SummaryExerciseData(
        name: sets.first['exercise_name'] as String? ?? 'Unknown',
        exerciseIndex: exerciseIndex,
        muscleGroup: planned?['muscle_group'] as String? ??
            planned?['primary_muscle'] as String?,
        equipment: planned?['equipment'] as String?,
        libraryId: planned?['library_id'] as String?,
        imageUrl: planned?['image_url'] as String?,
        videoUrl: planned?['video_url'] as String?,
        sets: summarySetsList,
        prs: prLookup[key],
        drinks: exerciseDrinks.isNotEmpty ? exerciseDrinks : null,
      ));
    }

    // Add skipped exercises
    for (final skipIndex in skippedIndices) {
      if (skipIndex >= 0 && skipIndex < parsedExercises.length) {
        final ex = parsedExercises[skipIndex];
        final name = ex['name'] as String? ?? 'Unknown';
        final key = name.trim().toLowerCase();
        // Only add if not already in result
        if (!grouped.containsKey(key)) {
          result.add(SummaryExerciseData(
            name: name,
            exerciseIndex: skipIndex,
            isSkipped: true,
            muscleGroup: ex['muscle_group'] as String? ??
                ex['primary_muscle'] as String?,
            equipment: ex['equipment'] as String?,
            libraryId: ex['library_id'] as String?,
            imageUrl: ex['image_url'] as String?,
            videoUrl: ex['video_url'] as String?,
          ));
        }
      }
    }

    // Sort by exercise index
    result.sort((a, b) => a.exerciseIndex.compareTo(b.exerciseIndex));

    return result;
  }

  /// Fallback: build from setLogs + exercises_json (minimal data).
  List<SummaryExerciseData> _buildFromSetLogs(
    WorkoutSummaryResponse summary,
    List<Map<String, dynamic>> parsedExercises,
  ) {
    final grouped = summary.setLogsByExercise;
    if (grouped.isEmpty) return [];

    final List<SummaryExerciseData> result = [];
    int exerciseIndex = 0;

    for (final entry in grouped.entries) {
      final exerciseName = entry.key;
      final logs = entry.value;

      // Build sets from set logs
      final sets = logs.map((log) {
        return SummarySetData(
          setNumber: log.setNumber,
          actualReps: log.repsCompleted,
          actualWeightKg: log.weightKg,
          actualWeightLbs: log.weightKg * 2.20462,
          rir: log.rir,
          rpe: log.rpe,
        );
      }).toList();

      // Try to find planned exercise data from exercises_json
      Map<String, dynamic>? planned;
      for (final ex in parsedExercises) {
        if ((ex['name'] as String?)?.toLowerCase() ==
            exerciseName.toLowerCase()) {
          planned = ex;
          break;
        }
      }

      result.add(SummaryExerciseData(
        name: exerciseName,
        exerciseIndex: exerciseIndex,
        muscleGroup: planned?['muscle_group'] as String? ??
            planned?['primary_muscle'] as String?,
        equipment: planned?['equipment'] as String?,
        libraryId: planned?['library_id'] as String?,
        imageUrl: planned?['image_url'] as String?,
        videoUrl: planned?['video_url'] as String?,
        sets: sets,
      ));

      exerciseIndex++;
    }

    return result;
  }

  /// Parse drink_events from metadata.
  List<Map<String, dynamic>> _parseDrinkEvents(dynamic raw) {
    if (raw == null) return [];
    try {
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded.cast<Map<String, dynamic>>();
      }
      if (raw is List) return raw.cast<Map<String, dynamic>>();
    } catch (_) {}
    return [];
  }

  /// Parse skipped exercise indices from metadata.
  List<int> _parseSkippedIndices(dynamic raw) {
    if (raw == null) return [];
    try {
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded.cast<int>();
      }
      if (raw is List) return raw.cast<int>();
    } catch (_) {}
    return [];
  }

  _HeartRateInfo? _parseHeartRate(Map<String, dynamic>? metadata) {
    if (metadata == null) return null;
    final hrData = metadata['heart_rate'];
    if (hrData == null) return null;
    if (hrData is! Map<String, dynamic>) return null;

    final readingsRaw = hrData['readings'] as List<dynamic>?;
    if (readingsRaw == null || readingsRaw.isEmpty) return null;

    final readings = <HeartRateReading>[];
    for (final r in readingsRaw) {
      if (r is Map<String, dynamic>) {
        final bpm = (r['bpm'] as num?)?.toInt();
        final ts = r['timestamp'] as String?;
        if (bpm != null && ts != null) {
          final dt = DateTime.tryParse(ts);
          if (dt != null) {
            readings.add(HeartRateReading(bpm: bpm, timestamp: dt));
          }
        }
      }
    }

    if (readings.isEmpty) return null;

    return _HeartRateInfo(
      readings: readings,
      avgBpm: (hrData['avg_bpm'] as num?)?.toInt(),
      maxBpm: (hrData['max_bpm'] as num?)?.toInt(),
      minBpm: (hrData['min_bpm'] as num?)?.toInt(),
      maxHR: (hrData['max_hr'] as num?)?.toInt() ?? 190,
      durationMinutes: (hrData['duration_minutes'] as num?)?.toInt() ?? 60,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class _HeartRateInfo {
  final List<HeartRateReading> readings;
  final int? avgBpm;
  final int? maxBpm;
  final int? minBpm;
  final int maxHR;
  final int durationMinutes;

  const _HeartRateInfo({
    required this.readings,
    this.avgBpm,
    this.maxBpm,
    this.minBpm,
    this.maxHR = 190,
    this.durationMinutes = 60,
  });
}

class _MuscleInfo {
  final String name;
  final String? imagePath;
  final int setCount;
  final bool isPrimary;

  const _MuscleInfo({
    required this.name,
    this.imagePath,
    required this.setCount,
    required this.isPrimary,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION 1: HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _HeaderSection extends StatelessWidget {
  final String workoutName;
  final String? scheduledDate;
  final bool isMarkedDone;
  final String? completedAt;

  const _HeaderSection({
    required this.workoutName,
    this.scheduledDate,
    this.isMarkedDone = false,
    this.completedAt,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String dateStr = '';
    if (scheduledDate != null) {
      final dt = DateTime.tryParse(scheduledDate!);
      if (dt != null) {
        dateStr = DateFormat('EEEE, MMM d, yyyy').format(dt);
      }
    } else if (completedAt != null) {
      final dt = DateTime.tryParse(completedAt!);
      if (dt != null) {
        dateStr = DateFormat('EEEE, MMM d, yyyy').format(dt);
      }
    }

    final badgeLabel = isMarkedDone ? 'Marked Done' : 'Tracked';
    final badgeColor = isMarkedDone ? AppColors.yellow : AppColors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          workoutName,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimary : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (dateStr.isNotEmpty) ...[
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: isDark ? AppColors.textMuted : Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondary : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badgeColor.withOpacity(0.3)),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION 2: HERO STATS GRID (2x3)
// ═══════════════════════════════════════════════════════════════════════════════

class _HeroStatsGrid extends StatelessWidget {
  final WorkoutComparisonInfo? workoutComparison;
  final List<SetLogInfo> setLogs;
  final List<Map<String, dynamic>> exercises;
  final Map<String, dynamic>? metadata;

  const _HeroStatsGrid({
    required this.workoutComparison,
    this.setLogs = const [],
    this.exercises = const [],
    this.metadata,
  });

  /// Aggregate per-set logs into (volumeKg, sets, reps). Counts only sets
  /// that were actually completed (or that recorded reps > 0 — older logs
  /// don't carry the is_completed flag).
  ({double volumeKg, int sets, int reps}) _aggregateSetLogs() {
    double volume = 0;
    int sets = 0;
    int reps = 0;
    for (final log in setLogs) {
      final isCompleted = log.isCompleted ?? (log.repsCompleted > 0);
      if (!isCompleted) continue;
      sets += 1;
      reps += log.repsCompleted;
      volume += log.weightKg * log.repsCompleted;
    }
    return (volumeKg: volume, sets: sets, reps: reps);
  }

  /// Aggregate metadata['sets_json'] (richest source — written by the
  /// active-workout client). Same shape as performance_logs but lives on
  /// the workout_log row directly so it survives even if performance_logs
  /// rows weren't written.
  ({double volumeKg, int sets, int reps})? _aggregateSetsJson() {
    final raw = metadata?['sets_json'];
    if (raw == null) return null;
    List<dynamic>? list;
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) list = decoded;
      } catch (_) {}
    } else if (raw is List) {
      list = raw;
    }
    if (list == null || list.isEmpty) return null;
    double volume = 0;
    int sets = 0;
    int reps = 0;
    for (final item in list) {
      if (item is! Map) continue;
      final completedRaw = item['is_completed'];
      final repsCompleted =
          (item['reps_completed'] as num?)?.toInt() ?? 0;
      final isCompleted = completedRaw is bool
          ? completedRaw
          : repsCompleted > 0;
      if (!isCompleted) continue;
      final weightKg = (item['weight_kg'] as num?)?.toDouble() ?? 0;
      sets += 1;
      reps += repsCompleted;
      volume += weightKg * repsCompleted;
    }
    return (volumeKg: volume, sets: sets, reps: reps);
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0m';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String _formatVolume(double kg) {
    // Convert to lbs (user preference)
    final lbs = kg * 2.20462;
    if (lbs >= 1000) {
      return '${(lbs / 1000).toStringAsFixed(1)}k';
    }
    return lbs.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wc = workoutComparison;

    // Backend aggregates can be 0 (or wc itself null) for older workouts
    // whose workout_performance_summary row was never written. Fall back
    // to per-set data so the tiles always reflect what the user actually
    // logged. Prefer metadata['sets_json'] (richest), then setLogs.
    final fromSetsJson = _aggregateSetsJson();
    final fromSetLogs = setLogs.isNotEmpty ? _aggregateSetLogs() : null;
    final fallback = fromSetsJson ?? fromSetLogs;

    final currentVolumeKg = (wc?.currentTotalVolumeKg ?? 0) > 0
        ? wc!.currentTotalVolumeKg
        : (fallback?.volumeKg ?? 0);
    final currentSets = (wc?.currentTotalSets ?? 0) > 0
        ? wc!.currentTotalSets
        : (fallback?.sets ?? 0);
    final currentReps = (wc?.currentTotalReps ?? 0) > 0
        ? wc!.currentTotalReps
        : (fallback?.reps ?? 0);
    final currentDurationSeconds = wc?.currentDurationSeconds ?? 0;
    final currentExercises =
        (wc?.currentExercises ?? 0) > 0 ? wc!.currentExercises : exercises.length;
    final currentCalories = wc?.currentCalories ?? 0;

    final durationDelta = wc?.durationDiffPercent;
    final volumeDelta = wc?.volumeDiffPercent;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Column(
        children: [
          // Row 1
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.timer_outlined,
                  value: _formatDuration(currentDurationSeconds),
                  label: 'Duration',
                  delta: durationDelta,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  icon: Icons.fitness_center,
                  value: '$currentExercises',
                  label: 'Exercises',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  icon: Icons.local_fire_department_outlined,
                  value: currentCalories > 0 ? '$currentCalories' : '--',
                  label: 'Calories',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.show_chart,
                  value: _formatVolume(currentVolumeKg),
                  label: 'Volume (lb)',
                  delta: volumeDelta,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  icon: Icons.layers_outlined,
                  value: '$currentSets',
                  label: 'Sets',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  icon: Icons.repeat,
                  value: '$currentReps',
                  label: 'Reps',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final double? delta;
  final bool isDark;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.delta,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasValidDelta = delta != null && delta != 0;
    final isPositive = (delta ?? 0) >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.orange,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimary : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMuted : Colors.grey.shade500,
            ),
          ),
          if (hasValidDelta) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: (isPositive ? AppColors.green : AppColors.red)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${isPositive ? '+' : ''}${delta!.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isPositive ? AppColors.green : AppColors.red,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION 3: HEART RATE (always shown — placeholder when no data)
// ═══════════════════════════════════════════════════════════════════════════════

class _HeartRateSection extends StatelessWidget {
  final _HeartRateInfo? heartRateData;
  final bool isDark;

  const _HeartRateSection({
    required this.heartRateData,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, size: 16, color: Color(0xFFF44336)),
              const SizedBox(width: 6),
              Text(
                'Heart Rate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimary : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (heartRateData != null)
            HeartRateWorkoutChart(
              readings: heartRateData!.readings,
              avgBpm: heartRateData!.avgBpm,
              maxBpm: heartRateData!.maxBpm,
              minBpm: heartRateData!.minBpm,
              maxHR: heartRateData!.maxHR,
              durationMinutes: heartRateData!.durationMinutes,
              height: 160,
              showZoneBreakdown: true,
              showTrainingEffect: false,
              showVO2Max: false,
              showFatBurnMetrics: false,
            )
          else
            // Placeholder — no HR data
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 36,
                    color: isDark
                        ? AppColors.textMuted.withOpacity(0.5)
                        : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Connect a heart rate monitor\nto track your zones',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color:
                          isDark ? AppColors.textMuted : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION 4: MUSCLES WORKED
// ═══════════════════════════════════════════════════════════════════════════════

class _MusclesWorkedSection extends StatelessWidget {
  final List<Map<String, dynamic>> exercises;
  final List<SetLogInfo> setLogs;
  final bool isDark;

  const _MusclesWorkedSection({
    required this.exercises,
    required this.setLogs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final muscles = _extractMuscles();
    if (muscles.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MUSCLES WORKED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMuted : Colors.grey.shade500,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children:
                muscles.map((m) => _MuscleAvatar(muscle: m, isDark: isDark)).toList(),
          ),
        ],
      ),
    );
  }

  List<_MuscleInfo> _extractMuscles() {
    final Map<String, _MuscleInfo> muscleMap = {};

    // Count sets from set logs per exercise name
    final Map<String, int> setCountByExercise = {};
    for (final log in setLogs) {
      setCountByExercise[log.exerciseName.toLowerCase()] =
          (setCountByExercise[log.exerciseName.toLowerCase()] ?? 0) + 1;
    }

    for (final ex in exercises) {
      final primaryMuscle =
          ex['primary_muscle'] as String? ?? ex['muscle_group'] as String?;
      final exerciseName = (ex['name'] as String? ?? '').toLowerCase();
      final setsForExercise =
          setCountByExercise[exerciseName] ?? (ex['sets'] as int? ?? 0);

      if (primaryMuscle != null && primaryMuscle.isNotEmpty) {
        final normalized = _normalizeMuscle(primaryMuscle);
        final existing = muscleMap[normalized];
        muscleMap[normalized] = _MuscleInfo(
          name: normalized,
          imagePath: _findMuscleImage(normalized),
          setCount: (existing?.setCount ?? 0) + setsForExercise,
          isPrimary: true,
        );
      }

      // Secondary muscles
      final secondaries = _parseSecondaryMuscles(ex['secondary_muscles']);
      for (final sec in secondaries) {
        final normalized = _normalizeMuscle(sec);
        if (!muscleMap.containsKey(normalized)) {
          muscleMap[normalized] = _MuscleInfo(
            name: normalized,
            imagePath: _findMuscleImage(normalized),
            setCount: 0,
            isPrimary: false,
          );
        }
      }
    }

    final result = muscleMap.values.toList()
      ..sort((a, b) {
        if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
        return b.setCount.compareTo(a.setCount);
      });
    return result;
  }

  static String _normalizeMuscle(String name) {
    final stripped = name.trim().replaceAll(RegExp(r'\s*\(.*\)\s*$'), '');
    final lower = stripped.toLowerCase();
    const aliases = {
      'upper back': 'Back',
      'middle back': 'Back',
      'lats': 'Back',
      'latissimus dorsi': 'Back',
      'rear delts': 'Shoulders',
      'front delts': 'Shoulders',
      'side delts': 'Shoulders',
      'deltoids': 'Shoulders',
      'pecs': 'Chest',
      'pectorals': 'Chest',
      'abs': 'Core',
      'abdominals': 'Core',
      'obliques': 'Core',
      'quads': 'Quadriceps',
      'hamstrings': 'Hamstrings',
      'glutes': 'Glutes',
      'gluteus': 'Glutes',
      'calves': 'Calves',
      'biceps': 'Biceps',
      'triceps': 'Triceps',
      'forearms': 'Forearms',
      'lower back': 'Lower Back',
      'hip flexors': 'Hips',
      'hips': 'Hips',
      'chest': 'Chest',
      'back': 'Back',
      'shoulders': 'Shoulders',
      'core': 'Core',
      'arms': 'Arms',
      'legs': 'Legs',
      'quadriceps': 'Quadriceps',
    };
    return aliases[lower] ?? _titleCase(stripped);
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  static String? _findMuscleImage(String normalized) {
    if (muscleGroupAssets.containsKey(normalized)) {
      return muscleGroupAssets[normalized];
    }
    for (final entry in muscleGroupAssets.entries) {
      if (entry.key.toLowerCase() == normalized.toLowerCase()) {
        return entry.value;
      }
    }
    return null;
  }

  static List<String> _parseSecondaryMuscles(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (value is String && value.isNotEmpty) {
      return value
          .split(RegExp(r'[,;]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }
}

class _MuscleAvatar extends StatelessWidget {
  final _MuscleInfo muscle;
  final bool isDark;

  const _MuscleAvatar({required this.muscle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final borderColor = muscle.isPrimary
        ? AppColors.orange.withOpacity(0.6)
        : AppColors.purple.withOpacity(0.3);
    final textMuted = isDark ? AppColors.textMuted : Colors.grey.shade500;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2.5),
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
          ),
          child: ClipOval(
            child: muscle.imagePath != null
                ? Image.asset(
                    muscle.imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.fitness_center,
                      size: 22,
                      color: textMuted,
                    ),
                  )
                : Icon(
                    Icons.fitness_center,
                    size: 22,
                    color: textMuted,
                  ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 64,
          child: Text(
            muscle.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (muscle.setCount > 0)
          Text(
            '${muscle.setCount} sets',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: muscle.isPrimary ? AppColors.orange : textMuted,
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION 5: EXERCISE TABLE
// ═══════════════════════════════════════════════════════════════════════════════

class _ExerciseTableSection extends StatelessWidget {
  final List<SummaryExerciseData> exercises;
  final bool isDark;

  const _ExerciseTableSection({
    required this.exercises,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'EXERCISES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textMuted : Colors.grey.shade500,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SummaryExerciseTable(
            exercises: exercises,
            useKg: false,
            onExerciseTap: (name, libraryId) {
              // Return a callback that shows exercise info in a bottom sheet
              return () => _showExerciseSheet(context, name, libraryId);
            },
          ),
        ],
      ),
    );
  }

  void _showExerciseSheet(
      BuildContext context, String name, String? libraryId) {
    final isDarkSheet = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        decoration: BoxDecoration(
          color: isDarkSheet ? AppColors.glassSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: isDarkSheet
                ? AppColors.cardBorder
                : AppColorsLight.cardBorder,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      isDarkSheet ? AppColors.textMuted : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDarkSheet ? AppColors.textPrimary : Colors.black87,
              ),
            ),
            if (libraryId != null) ...[
              const SizedBox(height: 8),
              Text(
                'Library ID: $libraryId',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkSheet
                      ? AppColors.textMuted
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION 5.5: PERSONAL RECORDS
// ═══════════════════════════════════════════════════════════════════════════════

class _PersonalRecordsSection extends StatelessWidget {
  final List<PersonalRecordInfo> records;
  final bool isDark;

  const _PersonalRecordsSection({
    required this.records,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEAB308).withOpacity(isDark ? 0.10 : 0.08),
            const Color(0xFFF59E0B).withOpacity(isDark ? 0.06 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEAB308).withOpacity(0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEAB308), Color(0xFFF59E0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, size: 13, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                'Personal Records',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimary : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Each PR entry
          ...records.asMap().entries.map((entry) {
            final i = entry.key;
            final pr = entry.value;
            final weightLbs = pr.weightKg * 2.20462;
            final impPct = pr.improvementPercent ?? 0;
            final improvementStr = impPct > 0
                ? '+${impPct.toStringAsFixed(1)}%'
                : '${impPct.toStringAsFixed(1)}%';

            return Padding(
              padding: EdgeInsets.only(bottom: i < records.length - 1 ? 10 : 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trophy icon
                    Icon(
                      pr.isAllTimePr
                          ? Icons.emoji_events
                          : Icons.military_tech,
                      size: 20,
                      color: const Color(0xFFEAB308),
                    ),
                    const SizedBox(width: 10),
                    // PR details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pr.exerciseName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                '${weightLbs.toStringAsFixed(1)} lb x ${pr.reps} reps',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textSecondary
                                      : Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  improvementStr,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (pr.celebrationMessage != null &&
                              pr.celebrationMessage!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              pr.celebrationMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? AppColors.textMuted
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION 6: AI COACH REVIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _CoachReviewSection extends StatelessWidget {
  final CoachReview? coachReview;
  final String? rawSummary;
  final bool isDark;

  const _CoachReviewSection({
    this.coachReview,
    this.rawSummary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orange.withOpacity(isDark ? 0.08 : 0.06),
            AppColors.purple.withOpacity(isDark ? 0.05 : 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.orange.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.orange, AppColors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 13, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                'AI Coach Review',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimary : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (coachReview != null) ...[
            // Structured review
            _buildStructuredReview(coachReview!),
          ] else if (rawSummary != null) ...[
            // Raw text fallback
            Text(
              rawSummary!,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? AppColors.textSecondary : Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStructuredReview(CoachReview review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Star rating
        if (review.overallRating > 0) ...[
          Row(
            children: List.generate(10, (i) {
              return Icon(
                i < review.overallRating ? Icons.star : Icons.star_border,
                size: 18,
                color: i < review.overallRating
                    ? AppColors.yellow
                    : (isDark ? AppColors.textMuted : Colors.grey.shade300),
              );
            }),
          ),
          const SizedBox(height: 12),
        ],

        // Highlights
        if (review.highlights.isNotEmpty) ...[
          ...review.highlights.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: AppColors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        h,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark
                              ? AppColors.textSecondary
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
        ],

        // Areas to improve
        if (review.areasToImprove.isNotEmpty) ...[
          ...review.areasToImprove.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber,
                        size: 16, color: AppColors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark
                              ? AppColors.textSecondary
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
        ],

        // Summary
        if (review.summary.isNotEmpty) ...[
          Divider(
            height: 16,
            thickness: 0.5,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
          ),
          Text(
            review.summary,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.textMuted : Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION 7: POST-WORKOUT FEEDBACK
// ═══════════════════════════════════════════════════════════════════════════════

class _PostWorkoutFeedbackSection extends StatelessWidget {
  final Map<String, dynamic> feedback;
  final bool isDark;

  const _PostWorkoutFeedbackSection({
    required this.feedback,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final rating = (feedback['rating'] as num?)?.toInt();
    final difficulty = feedback['difficulty'] as String?;
    final energyLevel = feedback['energy_level'] as String?;

    // Only show if at least one field is present
    if (rating == null && difficulty == null && energyLevel == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'POST-WORKOUT FEEDBACK',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMuted : Colors.grey.shade500,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Star rating
              if (rating != null) ...[
                Expanded(
                  child: _FeedbackTile(
                    label: 'Rating',
                    isDark: isDark,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        return Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          size: 20,
                          color: i < rating
                              ? AppColors.yellow
                              : (isDark
                                  ? AppColors.textMuted
                                  : Colors.grey.shade300),
                        );
                      }),
                    ),
                  ),
                ),
              ],
              // Difficulty
              if (difficulty != null) ...[
                if (rating != null) const SizedBox(width: 8),
                Expanded(
                  child: _FeedbackTile(
                    label: 'Difficulty',
                    isDark: isDark,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.getDifficultyColor(difficulty)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _titleCase(difficulty),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getDifficultyColor(difficulty),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              // Energy level
              if (energyLevel != null) ...[
                if (rating != null || difficulty != null)
                  const SizedBox(width: 8),
                Expanded(
                  child: _FeedbackTile(
                    label: 'Energy',
                    isDark: isDark,
                    child: Text(
                      _titleCase(energyLevel),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? AppColors.textPrimary : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .split('_')
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

class _FeedbackTile extends StatelessWidget {
  final String label;
  final Widget child;
  final bool isDark;

  const _FeedbackTile({
    required this.label,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textMuted : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
