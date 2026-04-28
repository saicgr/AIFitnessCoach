import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/accent_color_provider.dart';
import '../../data/models/wrapped_data.dart';
import '../shareable_data.dart';

/// Adapter that maps `WrappedData` (year-in-review stats) into the unified
/// `Shareable` payload so Wrapped flows through the same `ShareableSheet`
/// as every other share surface — no more isolated WrappedShareSheet path
/// with hardcoded card-by-card alignment quirks.
class WrappedAdapter {
  static Shareable fromWrapped({
    required WidgetRef ref,
    required WrappedData data,
  }) {
    final accent = ref.read(accentColorProvider).getColor(true);
    final highlights = <ShareableMetric>[
      if (data.totalWorkouts > 0)
        ShareableMetric(
          label: 'WORKOUTS',
          value: '${data.totalWorkouts}',
          icon: Icons.fitness_center_rounded,
        ),
      if (data.totalDurationMinutes > 0)
        ShareableMetric(
          label: 'TIME',
          value: _fmtDuration(data.totalDurationMinutes),
          icon: Icons.timer_outlined,
        ),
      if (data.totalVolumeLbs > 0)
        ShareableMetric(
          label: 'VOLUME',
          value: '${data.totalVolumeLbs.round()} lbs',
          icon: Icons.bar_chart_rounded,
        ),
      if (data.totalSets > 0)
        ShareableMetric(
          label: 'SETS',
          value: '${data.totalSets}',
          icon: Icons.repeat_rounded,
        ),
      if (data.totalReps > 0)
        ShareableMetric(
          label: 'REPS',
          value: '${data.totalReps}',
          icon: Icons.bolt_rounded,
        ),
      if (data.personalRecordsCount > 0)
        ShareableMetric(
          label: 'NEW PRS',
          value: '${data.personalRecordsCount}',
          icon: Icons.emoji_events_rounded,
          accent: const Color(0xFFFCD34D),
        ),
      if (data.streakBest > 0)
        ShareableMetric(
          label: 'STREAK',
          value: '${data.streakBest} days',
          icon: Icons.local_fire_department_rounded,
          accent: const Color(0xFFFF6B35),
        ),
      if (data.favoriteExercise != 'N/A')
        ShareableMetric(
          label: 'FAVORITE',
          value: data.favoriteExercise,
          icon: Icons.favorite_rounded,
        ),
    ];

    return Shareable(
      kind: ShareableKind.wrapped,
      title: 'Your ${data.monthDisplayName} ${data.yearDisplay} Wrapped',
      periodLabel: '${data.monthDisplayName} ${data.yearDisplay}',
      heroValue: data.totalWorkouts,
      heroUnitSingular: 'workout',
      heroSuffix: data.totalWorkouts == 1 ? null : 's',
      highlights: highlights,
      subMetrics: [
        if (data.fitnessPersonality.isNotEmpty)
          ShareableMetric(label: 'YOU ARE', value: data.fitnessPersonality),
        if (data.mostActiveDayOfWeek != 'N/A')
          ShareableMetric(label: 'TOP DAY', value: data.mostActiveDayOfWeek),
      ],
      accentColor: accent,
    );
  }

  static String _fmtDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
