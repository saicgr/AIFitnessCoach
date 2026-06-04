import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/user_provider.dart' show useKgForWorkoutProvider;
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/exercise.dart';
import '../../data/models/workout.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/image_url_cache.dart';
import '../shareable_data.dart';

/// Builds a `Shareable` for a WEEK or MONTH of planned/completed workouts,
/// the source data the Hevy-style Week Grid / Month Grid share templates
/// render. One [SharablePlanDay] is emitted per calendar day in the window;
/// days with no workout are rest days. Mirrors [WorkoutAdapter] conventions:
/// reads the user's in-app accent + workout unit + display name from `ref`,
/// resolves exercise thumbnails through [ImageUrlCache], and returns `null`
/// (never a half-populated payload) when there is nothing to share.
class WeeklyPlanAdapter {
  /// Build a `Shareable` from the user's workouts intersecting
  /// [windowStart]..[windowEnd] (both inclusive, date-only). [isMonth]
  /// switches the title / period-label / kind between the week and month
  /// variants.
  ///
  /// Returns `null` when every day in the window is a rest day (no workout to
  /// show) so the catalog declines to offer the plan-grid templates rather
  /// than rendering an all-empty grid.
  static Shareable? fromWorkouts({
    required WidgetRef ref,
    required List<Workout> workouts,
    required DateTime windowStart,
    required DateTime windowEnd,
    required bool isMonth,
  }) {
    // Use the user's selected in-app accent so the share card reads as
    // colored (AppColors.accent resolves to white in dark mode). Mirrors
    // WorkoutAdapter.fromCompletion exactly.
    final accent = ref.read(accentColorProvider).getColor(true);
    // Workout-unit preference (lbs by default), not the body-weight unit.
    final useKg = ref.read(useKgForWorkoutProvider);
    final unit = useKg ? 'kg' : 'lbs';
    final displayName = ref.read(authStateProvider).user?.displayName;

    // Normalize the window to date-only bounds.
    final start = DateTime(windowStart.year, windowStart.month, windowStart.day);
    final end = DateTime(windowEnd.year, windowEnd.month, windowEnd.day);
    if (end.isBefore(start)) return null;

    // Bucket workouts by their tz-safe scheduled local date (NOT
    // DateTime.parse, which would shift across UTC). Multiple workouts on the
    // same day merge into one SharablePlanDay (their exercises concatenate).
    final byDay = <DateTime, List<Workout>>{};
    for (final w in workouts) {
      final d = w.scheduledLocalDate;
      if (d == null) continue;
      final key = DateTime(d.year, d.month, d.day);
      if (key.isBefore(start) || key.isAfter(end)) continue;
      byDay.putIfAbsent(key, () => []).add(w);
    }

    // Emit exactly one day per calendar day in the window (so rest days show
    // up as gaps in the grid, not as missing cells).
    final days = <SharablePlanDay>[];
    var totalExercises = 0;
    var nonRestDays = 0;
    for (var cursor = start;
        !cursor.isAfter(end);
        cursor = cursor.add(const Duration(days: 1))) {
      final dayWorkouts = byDay[cursor] ?? const <Workout>[];
      if (dayWorkouts.isEmpty) {
        days.add(SharablePlanDay(date: cursor));
        continue;
      }

      // Merge multiple-per-day: concatenate exercises, prefer the first
      // workout's name (most days have a single workout), OR-merge completion,
      // and sum durations.
      final exercises = <ShareableExercise>[];
      for (final w in dayWorkouts) {
        for (final ex in w.exercises) {
          exercises.add(_buildExercise(ex, useKg: useKg, unit: unit));
        }
      }
      if (exercises.isEmpty) {
        // A workout row with no exercises is still a rest day for display.
        days.add(SharablePlanDay(date: cursor));
        continue;
      }

      final name = _dayName(dayWorkouts);
      final completed = dayWorkouts.any((w) => w.isCompleted == true);
      final durationMin = dayWorkouts.fold<int>(
        0,
        (sum, w) =>
            sum + (w.estimatedDurationMinutes ?? w.durationMinutes ?? 0),
      );
      final type = dayWorkouts
          .map((w) => w.type)
          .firstWhere((t) => t != null && t.trim().isNotEmpty, orElse: () => null);

      days.add(SharablePlanDay(
        date: cursor,
        workoutName: name,
        workoutType: type,
        exercises: exercises,
        isCompleted: completed,
        durationMinutes: durationMin > 0 ? durationMin : null,
      ));
      totalExercises += exercises.length;
      nonRestDays += 1;
    }

    // Nothing to share - every day is rest. Decline rather than render an
    // all-empty grid (kills the white-bars bug).
    if (nonRestDays == 0) return null;

    final highlights = <ShareableMetric>[
      ShareableMetric(label: 'WORKOUTS', value: nonRestDays.toString()),
      ShareableMetric(label: 'EXERCISES', value: totalExercises.toString()),
    ];

    return Shareable(
      kind: isMonth ? ShareableKind.monthlyPlan : ShareableKind.weeklyPlan,
      title: _title(isMonth: isMonth, displayName: displayName, anchor: start),
      periodLabel:
          _periodLabel(isMonth: isMonth, start: start, end: end),
      heroValue: nonRestDays,
      heroUnitSingular: isMonth ? 'training day' : 'workout',
      highlights: highlights,
      planDays: days,
      userDisplayName: displayName,
      accentColor: accent,
    );
  }

  /// Build one [ShareableExercise] for a planned exercise, preferring the
  /// per-set AI targets ([WorkoutExercise.setTargets]) and synthesizing from
  /// the flat sets/reps/weight when targets are absent.
  static ShareableExercise _buildExercise(
    WorkoutExercise ex, {
    required bool useKg,
    required String unit,
  }) {
    return ShareableExercise(
      name: ex.name,
      imageUrl: _resolveThumb(ex),
      sets: _targetSets(ex, useKg: useKg, unit: unit),
    );
  }

  /// Resolves an HTTP image URL for an exercise so day-grid thumbnails render
  /// the actual illustration. Same priority as WorkoutAdapter:
  ///   1. Direct gifUrl when it's a full http(s) URL.
  ///   2. ImageUrlCache lookup by exercise name (the hot cache populated by
  ///      every ExerciseImage the user has rendered elsewhere).
  ///   3. null - the template's `_MicroThumb` falls back to a grey chip.
  static String? _resolveThumb(WorkoutExercise ex) {
    final gif = ex.gifUrl;
    if (gif != null && gif.startsWith('http')) return gif;
    final cached = ImageUrlCache.get(ex.name);
    if (cached != null && cached.isNotEmpty) return cached;
    return null;
  }

  /// Per-set [ShareableSet] list for a planned exercise. Prefers the AI
  /// per-set targets (`setTargets[].target_reps` / `target_weight_kg`); when
  /// absent, synthesizes one set per `ex.sets` from the flat `ex.reps` /
  /// `ex.weight`. Marks `isBodyweight` when the weight is null/0 AND the
  /// exercise uses bodyweight equipment, so the template renders "BW" rather
  /// than a blank dash for true bodyweight movements only.
  static List<ShareableSet> _targetSets(
    WorkoutExercise ex, {
    required bool useKg,
    required String unit,
  }) {
    final isBw = _isBodyweight(ex);
    final targets = ex.setTargets;
    if (targets != null && targets.isNotEmpty) {
      return targets.map((t) {
        final kg = t.targetWeightKg;
        final bw = isBw && (kg == null || kg == 0);
        return ShareableSet(
          weight: kg == null
              ? null
              : useKg
                  ? kg
                  : kg * 2.20462,
          unit: unit,
          reps: t.targetReps,
          targetReps: t.targetReps,
          targetWeight: kg == null
              ? null
              : useKg
                  ? kg
                  : kg * 2.20462,
          targetRir: t.targetRir,
          isBodyweight: bw,
        );
      }).toList();
    }

    // Synthesize from flat sets/reps/weight.
    final setCount = ex.sets ?? 0;
    final reps = ex.reps ?? 0;
    final w = ex.weight;
    final bw = isBw && (w == null || w == 0);
    return List.generate(
      setCount,
      (_) => ShareableSet(
        weight: w == null
            ? null
            : useKg
                ? w
                : w * 2.20462,
        unit: unit,
        reps: reps,
        isBodyweight: bw,
      ),
    );
  }

  /// True when the exercise is a bodyweight movement (so a null/0 weight is
  /// expected and should render "BW", not be treated as under-logged).
  static bool _isBodyweight(WorkoutExercise ex) {
    final eq = ex.equipment?.toLowerCase().trim();
    if (eq == null || eq.isEmpty) return false;
    return eq.contains('bodyweight') ||
        eq.contains('body weight') ||
        eq == 'none' ||
        eq == 'body only';
  }

  /// Pick a representative workout name for a day with one-or-more workouts.
  /// Single workout → its name; multiple → the first non-empty name (most
  /// days are single - this is a graceful merge, not a feature).
  static String _dayName(List<Workout> dayWorkouts) {
    for (final w in dayWorkouts) {
      final n = w.name?.trim();
      if (n != null && n.isNotEmpty) return n;
    }
    return 'Workout';
  }

  /// Title variant pool (≥4 each) - human voice, no em dashes, exact data is
  /// carried by the highlights/grid so the title stays evergreen. Deterministic
  /// per anchor date so the same week always renders the same title (a render
  /// of the same plan twice shouldn't flicker between variants).
  static String _title({
    required bool isMonth,
    required String? displayName,
    required DateTime anchor,
  }) {
    final first = _firstName(displayName);
    final week = <String>[
      'My Week',
      'This Week of Training',
      'My Training Week',
      'A Week in the Gym',
      if (first != null) "$first's Week",
    ];
    final month = <String>[
      'My Training Month',
      'A Month in the Gym',
      'My Month of Work',
      'This Month of Training',
      if (first != null) "$first's Month",
    ];
    final pool = isMonth ? month : week;
    // Deterministic pick: hash the anchor date into the pool.
    final idx = (anchor.year * 372 + anchor.month * 31 + anchor.day) % pool.length;
    return pool[idx];
  }

  static String? _firstName(String? displayName) {
    final n = displayName?.trim();
    if (n == null || n.isEmpty || n == 'User') return null;
    final first = n.split(RegExp(r'\s+')).first.trim();
    return first.isEmpty ? null : first;
  }

  /// Week: "Mon DD – Sun DD" using the actual window bounds (en route the
  /// caller passes a week-start-anchored start..+6d). Month: "Month YYYY".
  static String _periodLabel({
    required bool isMonth,
    required DateTime start,
    required DateTime end,
  }) {
    if (isMonth) {
      return '${_monthName(start.month)} ${start.year}';
    }
    return '${_monthName(start.month)} ${start.day} – '
        '${_monthName(end.month)} ${end.day}';
  }

  static String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[(month - 1).clamp(0, 11)];
  }
}
