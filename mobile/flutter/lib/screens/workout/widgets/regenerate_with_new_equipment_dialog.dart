// Mid-workout decision dialog shown after the user changes equipment from
// inside an active workout. Two paths:
//
//   • Regenerate this workout — opens the existing streaming regenerate sheet
//     (showRegenerateWorkoutSheet) keyed to the active workout id. The
//     backend matches exercises by exercise_id; any set logs already saved
//     for surviving exercises remain attached to the workout server-side.
//
//   • Continue current — just dismiss. The user keeps their current plan.
//     Future workouts pick up the new equipment automatically because
//     gym_profile_provider.updateProfile already invalidates the today/all
//     workout caches.
//
// In BOTH cases the equipment edit was already persisted to the gym profile
// before this dialog was shown — that's the caller's responsibility (see
// showChangeEquipmentSheet in workout_sheets_mixin).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/workout.dart';
import '../../home/widgets/regenerate_workout_sheet.dart';

class RegenerateWithNewEquipmentDialog {
  /// Shows the choice dialog. Returns the *new* workout if the user
  /// regenerated and approved it; null if they chose Continue or cancelled.
  static Future<Workout?> show(
    BuildContext context,
    WidgetRef ref, {
    required Workout activeWorkout,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final fg = isDark ? Colors.white : Colors.black;

    final choice = await showDialog<_Choice>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor:
            isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.fitness_center_rounded,
                        color: accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Equipment updated',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: fg)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Want to regenerate this workout with your new equipment, or '
                'finish what you started?',
                style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: fg.withValues(alpha: 0.75)),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  HapticService.instance.tap();
                  Navigator.of(ctx).pop(_Choice.regenerate);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Regenerate this workout',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  HapticService.instance.tap();
                  Navigator.of(ctx).pop(_Choice.keep);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: BorderSide(color: fg.withValues(alpha: 0.18)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Continue current',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: fg.withValues(alpha: 0.82))),
              ),
              const SizedBox(height: 4),
              Text(
                'Either way, future workouts will use your updated equipment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: fg.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice != _Choice.regenerate) return null;
    if (!context.mounted) return null;

    // Hand off to the streaming regenerate sheet — it owns Replace/Keep
    // semantics, preview/commit, and refreshes the workout caches so the
    // active workout screen picks up the new plan. Set logs already saved
    // server-side stay keyed to (workout_id, exercise_id), so surviving
    // exercises keep their completed sets after the swap.
    return showRegenerateWorkoutSheet(context, ref, activeWorkout);
  }
}

enum _Choice { regenerate, keep }
