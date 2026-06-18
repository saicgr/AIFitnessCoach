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
import '../../core/utils/muscle_aliases.dart' as muscle_util;
import '../../core/utils/weight_utils.dart';
import '../../data/models/workout.dart';
import '../../widgets/heart_rate_chart.dart';
import '../library/providers/muscle_group_images_provider.dart';
import 'widgets/hr_connect_chip.dart';
import 'widgets/summary_exercise_card.dart';
import 'widgets/summary_exercise_table.dart';
import 'widgets/summary_floating_pill.dart';
import 'widgets/summary_hero_stats.dart';
import 'widgets/workout_ai_recap_card.dart';

import '../../l10n/generated/app_localizations.dart';
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

    // Parse workout map fields
    final workoutName = summary.workout['name'] as String? ?? 'Workout';
    final scheduledDate = summary.workout['scheduled_date'] as String?;
    final exercisesJson = summary.workout['exercises_json'];

    // Ids the per-exercise AI + detail nav need.
    final workoutId = summary.workout['id'] as String? ?? '';
    final workoutLogId = metadata?['id'] as String?;
    final gymProfileId = (metadata?['gym_profile_id'] ??
        summary.workout['gym_profile_id']) as String?;

    // Parse exercises for muscles worked
    final exercises = _parseExercises(exercisesJson);

    // Build exercise table data from metadata sets_json (preferred) or set logs
    final exerciseTableData =
        _buildExerciseTableData(summary, metadata, exercises);

    // Heart rate
    final heartRateData = _parseHeartRate(metadata);

    // Personal records
    final personalRecords = summary.personalRecords;

    // Feedback from metadata
    final feedback = metadata?['workout_feedback'] as Map<String, dynamic>?;

    int sectionIndex = 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsetsDirectional.only(start: 16,
        end: 16,
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

          // 2. AI coach recap — promoted to the top so it's the first thing
          // the user reads. Self-contained: instant skeleton, then the
          // persisted recap from GET/POST /feedback/recap (no per-view LLM
          // call). Quick pills are off because the hero stats grid right
          // below already shows those numbers; starts expanded so the full
          // review is visible without a tap.
          if (!summary.isMarkedDone && exerciseTableData.isNotEmpty)
            _buildCoachRecapCard(summary, exerciseTableData, exercises)
                .animate()
                .fadeIn(
                  duration: 400.ms,
                  delay: Duration(milliseconds: 100 * sectionIndex++),
                )
                .slideY(begin: 0.05, end: 0),

          if (!summary.isMarkedDone && exerciseTableData.isNotEmpty)
            const SizedBox(height: 16),

          // 3. Compact hero stats — only stats this session actually has;
          // no '--' tiles. Renders even when wc is null so older workouts
          // without a workout_performance_summary row still show
          // volume/sets/reps computed from set_logs.
          SummaryHeroStats(
            summary: summary,
            metadata: metadata,
            exercises: exercises,
          )
              .animate()
              .fadeIn(
                duration: 400.ms,
                delay: Duration(milliseconds: 100 * sectionIndex++),
              )
              .slideY(begin: 0.05, end: 0),

          const SizedBox(height: 16),

          // 4b. Achievements — promoted so PRs/accomplishments are front-and-
          // centre right under the headline numbers (not buried at the bottom).
          if (personalRecords.isNotEmpty) ...[
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
            const SizedBox(height: 16),
          ],

          // 4c. Hydration — water/drink intake logged during the session,
          // promoted out of the old buried "more details" disclosure.
          if (_HydrationStrip.totalMlOf(metadata) > 0) ...[
            _HydrationStrip(metadata: metadata, isDark: isDark)
                .animate()
                .fadeIn(
                  duration: 400.ms,
                  delay: Duration(milliseconds: 100 * sectionIndex++),
                )
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: 16),
          ],

          // 4. Heart Rate chart — only when the session has readings. The
          // no-monitor case is a slim hint chip near the bottom (section 8)
          // instead of a full-height empty card up here.
          if (heartRateData != null) ...[
            _HeartRateSection(heartRateData: heartRateData, isDark: isDark)
                .animate()
                .fadeIn(
                  duration: 400.ms,
                  delay: Duration(milliseconds: 100 * sectionIndex++),
                )
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: 16),
          ],

          // 5. Muscles Worked
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

          // 5. Exercises — collapsible per-exercise cards (tap to expand the
          // full set grid; "✨ AI" for a per-exercise breakdown; "›" opens the
          // exercise detail incl. its Form-video tab).
          if (exerciseTableData.isNotEmpty)
            _ExerciseCardsSection(
              exercises: exerciseTableData,
              workoutId: workoutId,
              workoutLogId: workoutLogId,
              gymProfileId: gymProfileId,
              isDark: isDark,
            )
                .animate()
                .fadeIn(
                  duration: 400.ms,
                  delay: Duration(milliseconds: 100 * sectionIndex++),
                )
                .slideY(begin: 0.05, end: 0),

          if (exerciseTableData.isNotEmpty) const SizedBox(height: 16),

          // 7. Post-Workout Feedback
          if (feedback != null) ...[
            _PostWorkoutFeedbackSection(feedback: feedback, isDark: isDark)
                .animate()
                .fadeIn(
                  duration: 400.ms,
                  delay: Duration(milliseconds: 100 * sectionIndex++),
                )
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: 16),
          ],

          // 8. No HR data → slim connect hint instead of an empty chart card.
          if (heartRateData == null)
            HrConnectChip(isDark: isDark)
                .animate()
                .fadeIn(
                  duration: 400.ms,
                  delay: Duration(milliseconds: 100 * sectionIndex++),
                ),

          // 9. Bottom padding so the last section scrolls clear of the
          // floating Detail/Summary/Advanced pill.
          SizedBox(height: SummaryFloatingPill.clearanceOf(context)),
        ],
      ),
    );
  }

  /// Builds the top-of-tab AI recap card from data this screen already has.
  /// Mirrors the payload the complete screen sends so POST /feedback/recap
  /// (first view of a pre-recap-era workout) generates an identical recap;
  /// for anything completed since, the GET path returns instantly.
  Widget _buildCoachRecapCard(
    WorkoutSummaryResponse summary,
    List<SummaryExerciseData> exerciseTableData,
    List<Map<String, dynamic>> parsedExercises,
  ) {
    double totalVolumeKg = 0;
    int totalSets = 0;
    int totalReps = 0;
    final recapExercises = <Map<String, dynamic>>[];
    for (final e in exerciseTableData) {
      if (e.isSkipped || e.sets.isEmpty) continue;
      double maxWeightKg = 0;
      int exerciseReps = 0;
      int exerciseSets = 0;
      for (final s in e.sets) {
        final reps = s.actualReps ?? 0;
        if (reps <= 0) continue;
        exerciseSets += 1;
        exerciseReps += reps;
        final weightKg = s.actualWeightKg ?? 0;
        totalVolumeKg += weightKg * reps;
        if (weightKg > maxWeightKg) maxWeightKg = weightKg;
      }
      if (exerciseSets == 0) continue;
      totalSets += exerciseSets;
      totalReps += exerciseReps;
      recapExercises.add(<String, dynamic>{
        'name': e.name,
        'sets': exerciseSets,
        'reps': exerciseReps,
        'weight_kg': maxWeightKg,
        'time_seconds': 0,
      });
    }

    final plannedExercises = parsedExercises
        .map((ex) => <String, dynamic>{
              'name': ex['name'] ?? '',
              'sets': (ex['sets'] as num?)?.toInt() ?? 0,
              'reps': (ex['reps'] as num?)?.toInt() ?? 0,
              'weight_kg': (ex['weight'] as num?)?.toDouble() ?? 0,
              'time_seconds': 0,
            })
        .toList();

    final earnedPRs = summary.personalRecords
        .map((pr) => <String, dynamic>{
              'exercise_name': pr.exerciseName,
              'detail':
                  '${WeightUtils.formatWorkoutWeight(pr.weightKg, useKg: false)} x ${pr.reps}',
            })
        .toList();

    final durationSeconds = summary.durationSeconds > 0
        ? summary.durationSeconds
        : ((metadata?['total_time_seconds'] as num?)?.toInt() ?? 0);

    return WorkoutAiRecapCard(
      workoutId: summary.workout['id'] as String? ?? '',
      workoutLogId: metadata?['id'] as String?,
      workoutName: summary.workout['name'] as String? ?? 'Workout',
      workoutType: summary.workout['type'] as String? ?? 'strength',
      exercises: recapExercises,
      plannedExercises: plannedExercises,
      totalTimeSeconds: durationSeconds,
      caloriesBurned: summary.caloriesKcal ?? 0,
      totalSets: totalSets,
      totalReps: totalReps,
      totalVolumeKg: totalVolumeKg,
      earnedPRs: earnedPRs,
      useKg: false,
      // The Summary tab has its own Muscles Worked section and hero stats —
      // suppress the card's duplicates and skip the level-up replay.
      workoutExercises: const [],
      trainedMuscles: const {},
      performanceComparison: summary.performanceComparison,
      showQuickPills: false,
      initiallyExpanded: true,
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
          summary,
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
    WorkoutSummaryResponse summary,
    Map<String, dynamic>? metadata,
  ) {
    final personalRecords = summary.personalRecords;
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

      // Previous-session sets for this exercise from the backend (keyed by
      // set_number). Used to backfill the "Previous" column when the active
      // client didn't embed previous_* into sets_json (Easy mode never did).
      final backendPrevious = <int, Map<String, dynamic>>{
        for (final p in summary.previousSetsFor(key) ?? const [])
          if (p['set_number'] is int) p['set_number'] as int: p,
      };

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
        final setNumber = s['set_number'] as int? ?? 1;
        final prevFromBackend = backendPrevious[setNumber];
        final previousWeightKg = (s['previous_weight_kg'] as num?)?.toDouble() ??
            (prevFromBackend?['weight_kg'] as num?)?.toDouble();
        final previousReps = (s['previous_reps'] as int?) ??
            (prevFromBackend?['reps_completed'] as num?)?.toInt();
        final durationSeconds = (s['set_duration_seconds'] as int?) ??
            (s['duration_seconds'] as int?);

        return SummarySetData(
          setNumber: setNumber,
          targetReps: s['target_reps'] as int?,
          targetWeightKg: targetWeightKg,
          targetWeightLbs:
              targetWeightKg != null ? targetWeightKg * 2.20462 : null,
          // Easy/Quick mode historically wrote `reps_completed`; Advanced
          // and post-fix Easy write canonical `reps`. Read both so logs from
          // either path render correctly in Summary.
          actualReps: (s['reps'] as int?) ?? (s['reps_completed'] as int?),
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
          previousReps: previousReps,
          progressionModel: s['progression_model'] as String?,
          // Coerce list (new) or string (legacy) into the list shape.
          notes: SummarySetData.coerceNotes(s['notes']),
          notesPhotoUrls: SummarySetData.coerceStringList(s['notes_photo_urls']),
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

      // Previous-session sets from the backend, keyed by set_number.
      final backendPrevious = <int, Map<String, dynamic>>{
        for (final p in summary.previousSetsFor(exerciseName) ?? const [])
          if (p['set_number'] is int) p['set_number'] as int: p,
      };

      // Build sets from set logs — carry the rich per-set fields
      // (targets, timing, notes) so this fallback renders the same table
      // as the sets_json path instead of a bare weight × reps grid.
      final sets = logs.map((log) {
        final prevFromBackend = backendPrevious[log.setNumber];
        final previousWeightKg =
            (prevFromBackend?['weight_kg'] as num?)?.toDouble();
        final previousReps =
            (prevFromBackend?['reps_completed'] as num?)?.toInt();
        return SummarySetData(
          setNumber: log.setNumber,
          targetReps: log.targetReps,
          targetWeightKg: log.targetWeightKg,
          targetWeightLbs: log.targetWeightKg != null
              ? log.targetWeightKg! * 2.20462
              : null,
          actualReps: log.repsCompleted,
          actualWeightKg: log.weightKg,
          actualWeightLbs: log.weightKg * 2.20462,
          rir: log.rir,
          rpe: log.rpe,
          durationSeconds: log.setDurationSeconds,
          restSeconds: log.restDurationSeconds,
          previousWeightKg: previousWeightKg,
          previousWeightLbs:
              previousWeightKg != null ? previousWeightKg * 2.20462 : null,
          previousReps: previousReps,
          notes: log.notes,
          notesPhotoUrls: log.notesPhotoUrls,
          completedAt: log.recordedAt,
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
              Flexible(
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondary : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
// SECTION 3: HEART RATE (rendered only when the session has readings —
// the no-monitor case is the slim HrConnectChip near the bottom of the tab)
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
              Expanded(
                child: Text(
                  AppLocalizations.of(context).workoutSummaryGeneralHeartRate,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimary : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
            AppLocalizations.of(context).workoutSummaryGeneralMusclesWorked,
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

  /// Delegates to the canonical alias util so chip names match the
  /// Advanced tab's body atlas highlighting. See
  /// `core/utils/muscle_aliases.dart` for the full alias table.
  static String _normalizeMuscle(String name) =>
      muscle_util.canonicalMuscle(name);

  static String? _findMuscleImage(String normalized) {
    if (muscleGroupAssets.containsKey(normalized)) {
      return muscleGroupAssets[normalized];
    }
    // Bridge canonical-bucket → asset-key for buckets where the asset
    // file uses the long anatomical name (Quads → Quadriceps,
    // Adductors → Legs, Cardio/Other → no asset).
    const bucketToAsset = {
      'Quads': 'Quadriceps',
      'Adductors': 'Legs',
      'Cardio': null,
      'Full Body': null,
      'Other': null,
    };
    if (bucketToAsset.containsKey(normalized)) {
      final mapped = bucketToAsset[normalized];
      if (mapped != null && muscleGroupAssets.containsKey(mapped)) {
        return muscleGroupAssets[mapped];
      }
      return null;
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
            AppLocalizations.of(context)!.workoutSummaryGeneralSets2(muscle.setCount),
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

/// The per-exercise list: a collapse/expand-all header + one
/// [SummaryExerciseCard] per exercise. Stateful only to own the broadcast
/// [ValueNotifier] that drives expand-all / collapse-all.
class _ExerciseCardsSection extends StatefulWidget {
  final List<SummaryExerciseData> exercises;
  final String workoutId;
  final String? workoutLogId;
  final String? gymProfileId;
  final bool isDark;

  const _ExerciseCardsSection({
    required this.exercises,
    required this.workoutId,
    required this.workoutLogId,
    required this.gymProfileId,
    required this.isDark,
  });

  @override
  State<_ExerciseCardsSection> createState() => _ExerciseCardsSectionState();
}

class _ExerciseCardsSectionState extends State<_ExerciseCardsSection> {
  final ValueNotifier<bool?> _expandAll = ValueNotifier<bool?>(null);
  bool _allExpanded = false;

  @override
  void dispose() {
    _expandAll.dispose();
    super.dispose();
  }

  void _toggleAll() {
    setState(() => _allExpanded = !_allExpanded);
    _expandAll.value = _allExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, right: 2, bottom: 8),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context).workoutSummaryGeneralExercises,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textMuted : Colors.grey.shade500,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleAll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _allExpanded ? 'Collapse all' : 'Expand all',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondary
                            : Colors.grey.shade700,
                      ),
                    ),
                    Icon(
                      _allExpanded
                          ? Icons.unfold_less_rounded
                          : Icons.unfold_more_rounded,
                      size: 16,
                      color:
                          isDark ? AppColors.textSecondary : Colors.grey.shade700,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (final ex in widget.exercises)
          SummaryExerciseCard(
            key: ValueKey('ex_${ex.exerciseIndex}_${ex.name}'),
            exercise: ex,
            workoutId: widget.workoutId,
            workoutLogId: widget.workoutLogId,
            gymProfileId: widget.gymProfileId,
            useKg: false,
            expandSignal: _expandAll,
          ),
      ],
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
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
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
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, size: 13, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).workoutSummaryGeneralPersonalRecords,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimary : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                              Flexible(
                                child: Text(
                                  AppLocalizations.of(context)!.workoutSummaryGeneralLbXReps(weightLbs.toStringAsFixed(1), pr.reps),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textSecondary
                                        : Colors.grey.shade700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
            AppLocalizations.of(context).workoutSummaryGeneralPostWorkoutFeedback,
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
                    label: AppLocalizations.of(context).workoutSummaryGeneralRating,
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
                    label: AppLocalizations.of(context).workoutSummaryGeneralDifficulty,
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
                    label: AppLocalizations.of(context).workoutSummaryGeneralEnergy,
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

// ═══════════════════════════════════════════════════════════════════════════════
// HYDRATION STRIP
// ═══════════════════════════════════════════════════════════════════════════════

class _HydrationStrip extends StatelessWidget {
  final Map<String, dynamic>? metadata;
  final bool isDark;

  const _HydrationStrip({required this.metadata, required this.isDark});

  /// Total drink intake (ml) for this session: prefers the rolled-up
  /// `drink_intake_ml`, else sums per-event amounts. 0 → strip is hidden.
  static int totalMlOf(Map<String, dynamic>? metadata) {
    if (metadata == null) return 0;
    final rolled = (metadata['drink_intake_ml'] as num?)?.toInt();
    if (rolled != null && rolled > 0) return rolled;
    final raw = metadata['drink_events'];
    if (raw is List) {
      var sum = 0;
      for (final e in raw) {
        if (e is Map) {
          final ml = (e['amount_ml'] ?? e['amountMl']) as num?;
          if (ml != null) sum += ml.toInt();
        }
      }
      return sum;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final totalMl = totalMlOf(metadata);
    final oz = (totalMl / 29.5735).round();
    const water = Color(0xFF38BDF8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: water.withValues(alpha: isDark ? 0.10 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: water.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.water_drop_rounded, size: 20, color: water),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HYDRATION',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: isDark ? AppColors.textMuted : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You drank $totalMl ml ($oz oz) during this session',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimary : Colors.black87,
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
