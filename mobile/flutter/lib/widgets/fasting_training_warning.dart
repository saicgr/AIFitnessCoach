import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../data/providers/unified_state_provider.dart';
import '../data/models/fasting.dart';

/// A widget that displays fasting-related warnings for training
/// Shows when user is in a fasted state and may need to be aware
/// of the implications for their workout.
class FastingTrainingWarning extends ConsumerWidget {
  /// The intensity of the workout (low, moderate, high, very_high)
  final String? workoutIntensity;

  /// The type of workout (strength, cardio, hiit, etc.)
  final String? workoutType;

  /// Duration in minutes
  final int? durationMinutes;

  /// Whether to show in a compact mode
  final bool compact;

  const FastingTrainingWarning({
    super.key,
    this.workoutIntensity,
    this.workoutType,
    this.durationMinutes,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unifiedState = ref.watch(unifiedStateProvider);

    // Don't show if not fasting
    if (!unifiedState.isFasting || unifiedState.activeFast == null) {
      return const SizedBox.shrink();
    }

    final hoursFasted = unifiedState.hoursFasted;
    final currentZone = unifiedState.currentFastingZone ?? FastingZone.fed;

    // Determine warning level based on fasting hours and workout intensity
    final warningLevel = _getWarningLevel(
      hoursFasted: hoursFasted,
      intensity: workoutIntensity ?? 'moderate',
      workoutType: workoutType,
      durationMinutes: durationMinutes,
    );

    if (warningLevel == _WarningLevel.none) {
      return const SizedBox.shrink();
    }

    // Also check unified state conflicts
    final conflicts = unifiedState.conflicts;
    final hasRelevantConflict = conflicts.any((c) =>
      c.type == ConflictType.highIntensityExtendedFast ||
      c.type == ConflictType.enduranceDuringFast ||
      c.type == ConflictType.postWorkoutOutsideEatingWindow
    );

    return _buildWarningBanner(
      context,
      hoursFasted: hoursFasted,
      currentZone: currentZone,
      warningLevel: warningLevel,
      hasConflict: hasRelevantConflict,
      conflicts: conflicts,
    );
  }

  _WarningLevel _getWarningLevel({
    required int hoursFasted,
    required String intensity,
    String? workoutType,
    int? durationMinutes,
  }) {
    // Short fasts (< 12h) - generally fine for any workout
    if (hoursFasted < 12) {
      return _WarningLevel.none;
    }

    // 12-16h fasted - caution for high intensity
    if (hoursFasted < 16) {
      if (intensity == 'high' || intensity == 'very_high') {
        return _WarningLevel.info;
      }
      // Long endurance workouts
      if ((durationMinutes ?? 0) > 60) {
        return _WarningLevel.info;
      }
      return _WarningLevel.none;
    }

    // 16-20h fasted - warning for high intensity
    if (hoursFasted < 20) {
      if (intensity == 'high' || intensity == 'very_high') {
        return _WarningLevel.warning;
      }
      if (workoutType?.toLowerCase() == 'hiit') {
        return _WarningLevel.warning;
      }
      if ((durationMinutes ?? 0) > 60) {
        return _WarningLevel.warning;
      }
      // Moderate intensity is fine
      return _WarningLevel.info;
    }

    // 20h+ fasted - serious warning for any intense workout
    if (intensity == 'high' || intensity == 'very_high') {
      return _WarningLevel.danger;
    }
    if (workoutType?.toLowerCase() == 'hiit') {
      return _WarningLevel.danger;
    }
    if ((durationMinutes ?? 0) > 45) {
      return _WarningLevel.warning;
    }

    return _WarningLevel.warning;
  }

  Widget _buildWarningBanner(
    BuildContext context, {
    required int hoursFasted,
    required FastingZone currentZone,
    required _WarningLevel warningLevel,
    required bool hasConflict,
    required List<StateConflict> conflicts,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get colors based on warning level
    final Color backgroundColor;
    final Color borderColor;
    final Color iconColor;
    final IconData icon;
    final String title;
    final String message;

    switch (warningLevel) {
      case _WarningLevel.info:
        backgroundColor = isDark
            ? AppColors.cyan.withValues(alpha: 0.1)
            : AppColors.cyan.withValues(alpha: 0.08);
        borderColor = AppColors.cyan.withValues(alpha: 0.3);
        iconColor = AppColors.cyan;
        icon = Icons.info_outline;
        title = 'Training Fasted';
        message = _getInfoMessage(hoursFasted, currentZone);
      case _WarningLevel.warning:
        backgroundColor = isDark
            ? AppColors.orange.withValues(alpha: 0.1)
            : AppColors.orange.withValues(alpha: 0.08);
        borderColor = AppColors.orange.withValues(alpha: 0.3);
        iconColor = AppColors.orange;
        icon = Icons.warning_amber_rounded;
        title = 'Fasted Training Caution';
        message = _getWarningMessage(hoursFasted, currentZone);
      case _WarningLevel.danger:
        backgroundColor = isDark
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.08);
        borderColor = AppColors.error.withValues(alpha: 0.3);
        iconColor = AppColors.error;
        icon = Icons.warning_rounded;
        title = 'Extended Fast Warning';
        message = _getDangerMessage(hoursFasted);
      case _WarningLevel.none:
        return const SizedBox.shrink();
    }

    if (compact) {
      return _buildCompactBanner(
        context,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        iconColor: iconColor,
        icon: icon,
        title: title,
        hoursFasted: hoursFasted,
        zone: currentZone,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${hoursFasted}h fasted',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: currentZone.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            currentZone.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: currentZone.color,
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
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              height: 1.4,
            ),
          ),
          // Show suggestions if there are conflicts
          if (hasConflict && conflicts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggestions:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...conflicts.first.suggestions.take(3).map((suggestion) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.arrow_right,
                            size: 16,
                            color: iconColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactBanner(
    BuildContext context, {
    required Color backgroundColor,
    required Color borderColor,
    required Color iconColor,
    required IconData icon,
    required String title,
    required int hoursFasted,
    required FastingZone zone,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: iconColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: zone.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${hoursFasted}h',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: zone.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInfoMessage(int hoursFasted, FastingZone zone) {
    if (zone == FastingZone.fatBurning) {
      return 'You\'re in the fat-burning zone. Light to moderate exercise is excellent now. Stay hydrated!';
    }
    return 'You\'ve been fasting for $hoursFasted hours. Listen to your body and adjust intensity as needed.';
  }

  String _getWarningMessage(int hoursFasted, FastingZone zone) {
    if (zone == FastingZone.ketosis || zone == FastingZone.deepKetosis) {
      return 'Extended fasting may affect workout performance. Consider lighter intensity or having a small pre-workout snack.';
    }
    return 'At $hoursFasted hours fasted, high-intensity training may be challenging. Consider reducing intensity or eating first.';
  }

  String _getDangerMessage(int hoursFasted) {
    return 'After $hoursFasted+ hours of fasting, intense exercise is not recommended. Consider breaking your fast before this workout or switching to light activity.';
  }
}

enum _WarningLevel {
  none,
  info,
  warning,
  danger,
}
