import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/workout.dart';
import '../../../data/services/haptic_service.dart';
import '../../../utils/forecast_math.dart';

/// Workstream 1 (Day 0-7 retention magic moment).
///
/// Fires ONLY after the user's first-ever completed workout. Personalized
/// 30-day projection designed to make the app feel like it immediately
/// "knows" the user — research shows this kind of visible-progress moment
/// nearly doubles week-1 retention.
Future<void> showFirstWorkoutForecastSheet(
  BuildContext context, {
  required Workout workout,
  required double totalVolumeKg,
  required int caloriesBurned,
  required int durationMinutes,
  required int sessionsPerWeek,
  int firstWorkoutPrImprovementPercent = 0,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => _FirstWorkoutForecastSheet(
        workout: workout,
        totalVolumeKg: totalVolumeKg,
        caloriesBurned: caloriesBurned,
        durationMinutes: durationMinutes,
        sessionsPerWeek: sessionsPerWeek,
        firstWorkoutPrImprovementPercent:
            firstWorkoutPrImprovementPercent.toDouble(),
        scrollController: scrollController,
      ),
    ),
  );
}

class _FirstWorkoutForecastSheet extends ConsumerWidget {
  final Workout workout;
  final double totalVolumeKg;
  final int caloriesBurned;
  final int durationMinutes;
  final int sessionsPerWeek;
  final double firstWorkoutPrImprovementPercent;
  final ScrollController scrollController;

  const _FirstWorkoutForecastSheet({
    required this.workout,
    required this.totalVolumeKg,
    required this.caloriesBurned,
    required this.durationMinutes,
    required this.sessionsPerWeek,
    required this.firstWorkoutPrImprovementPercent,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = ref.watch(accentColorProvider).getColor(isDark);

    // Convert kg → lbs for user-facing volume (user prefers lb — project memory).
    final volumeThisWorkoutLbs = (totalVolumeKg * 2.20462).round();
    final effectiveSessions = sessionsPerWeek > 0 ? sessionsPerWeek : 3;

    final projected30dVolumeLbs = ForecastMath.projectVolumePerMonth(
      volumeThisWorkout: volumeThisWorkoutLbs.toDouble(),
      sessionsPerWeek: effectiveSessions,
    );
    final projected30dCalories = ForecastMath.projectCaloriesPerMonth(
      caloriesThisWorkout: caloriesBurned,
      sessionsPerWeek: effectiveSessions,
    );
    final projected30dMinutes = ForecastMath.projectMinutesPerMonth(
      durationMinutesThisWorkout: durationMinutes,
      sessionsPerWeek: effectiveSessions,
    );
    final projectedStrengthPercent = ForecastMath.projectStrengthGainPercent(
      firstWorkoutPrImprovementPercent: firstWorkoutPrImprovementPercent,
      sessionsPerWeek: effectiveSessions,
    );

    final volumeComparison = ForecastMath.poundsToCars(projected30dVolumeLbs);
    final caloriesComparison = ForecastMath.caloriesToBodyFat(projected30dCalories);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                // ── Hero header ──
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.7)]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🎉', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your first FitWiz workout',
                            style: TextStyle(fontSize: 13, color: textMuted, letterSpacing: 0.5),
                          ),
                          Text(
                            'Day 1 complete',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Today's receipt ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: elevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      _receiptStat('$volumeThisWorkoutLbs', 'lbs lifted', textColor, textMuted),
                      _divider(border),
                      _receiptStat('$caloriesBurned', 'cal burned', textColor, textMuted),
                      _divider(border),
                      _receiptStat('$durationMinutes', 'minutes', textColor, textMuted),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── 30-day forecast section ──
                Text(
                  'In 30 days at this pace',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                _forecastCard(
                  icon: '🏋️',
                  color: accent,
                  primary: '${ForecastMath.formatCompact(projected30dVolumeLbs)} lbs',
                  label: 'Total volume lifted',
                  subtitle: volumeComparison.isNotEmpty ? 'That\'s $volumeComparison' : null,
                  textColor: textColor,
                  textMuted: textMuted,
                  elevated: elevated,
                  border: border,
                ),
                const SizedBox(height: 10),
                _forecastCard(
                  icon: '🔥',
                  color: Colors.deepOrange,
                  primary: '${ForecastMath.formatCompact(projected30dCalories)} cal',
                  label: 'Calories burned',
                  subtitle: caloriesComparison.isNotEmpty ? 'That\'s $caloriesComparison' : null,
                  textColor: textColor,
                  textMuted: textMuted,
                  elevated: elevated,
                  border: border,
                ),
                const SizedBox(height: 10),
                _forecastCard(
                  icon: '💪',
                  color: Colors.purple,
                  primary: '+$projectedStrengthPercent%',
                  label: 'Projected strength gain on main lifts',
                  subtitle: 'Estimate based on $effectiveSessions sessions/week',
                  textColor: textColor,
                  textMuted: textMuted,
                  elevated: elevated,
                  border: border,
                ),
                const SizedBox(height: 10),
                _forecastCard(
                  icon: '⏱️',
                  color: Colors.teal,
                  primary: '${ForecastMath.formatCompact(projected30dMinutes)} min',
                  label: 'Total time trained',
                  subtitle: 'Across ~${(effectiveSessions * ForecastMath.weeksInMonth).round()} sessions',
                  textColor: textColor,
                  textMuted: textMuted,
                  elevated: elevated,
                  border: border,
                ),
                const SizedBox(height: 20),

                // ── CTA row ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticService.light();
                          Navigator.of(context).pop();
                          // Schedule screen scrolled to day 7 would be great,
                          // but schedule screen accepts its own routing —
                          // fall back to /schedule as a simple open.
                          context.push('/schedule');
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text('Show me Day 7'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(color: border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticService.light();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text("Let's go"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptStat(String value, String label, Color textColor, Color textMuted) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _divider(Color border) => Container(width: 1, height: 36, color: border);

  Widget _forecastCard({
    required String icon,
    required Color color,
    required String primary,
    required String label,
    String? subtitle,
    required Color textColor,
    required Color textMuted,
    required Color elevated,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primary,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: textMuted, height: 1.3),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
