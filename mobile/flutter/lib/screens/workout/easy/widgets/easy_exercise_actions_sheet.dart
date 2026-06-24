// Easy-mode per-exercise action sheet.
//
// Easy mode previously had NO swap UX — the focal column showed only a
// "Log set" button and the top bar's overflow menu only exposed
// Skip/Complete/Quit. Users had to leave the workout to swap an exercise.
//
// This sheet collects the most-used mid-workout actions for the focal
// exercise into one tap menu. Entry points (wired by easy_active_workout_state):
//   • "•••" IconButton at the right of the exercise header chip row, AND
//   • Long-press on the focal card body.
//
// Rows (in priority order — Swap is first because the user explicitly
// flagged that swap is buried):
//   1. Swap exercise        → opens the existing exercise swap sheet
//   2. Report pain          → opens ReportPainSheet (severity + window)
//   3. Change equipment     → opens showChangeEquipmentForActiveWorkout
//   4. Skip to next         → calls the same handler as the up-next chip
//   5. Show video           → existing onShowVideo handler
//
// Each row is a tall (56pt) tappable surface for thumb-friendly use during
// a workout. The sheet itself is the standard GlassSheet.

import 'package:flutter/material.dart';

import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../widgets/glass_sheet.dart';

import '../../../../l10n/generated/app_localizations.dart';
class EasyExerciseAction {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const EasyExerciseAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
  });
}

class EasyExerciseActionsSheet extends StatelessWidget {
  final String exerciseName;
  final List<EasyExerciseAction> actions;

  const EasyExerciseActionsSheet({
    super.key,
    required this.exerciseName,
    required this.actions,
  });

  /// Standard entry point. Builds the sheet from explicit handlers so the
  /// caller (easy_active_workout_state) controls which rows appear and what
  /// they do — keeps this widget free of provider/repo coupling.
  static Future<void> show(
    BuildContext context, {
    required String exerciseName,
    required VoidCallback onSwap,
    required VoidCallback onReportPain,
    required VoidCallback onChangeEquipment,
    required VoidCallback onSkipToNext,
    required VoidCallback onShowVideo,
    required VoidCallback onLogWater,
    required VoidCallback onSetIncrement,
    required String incrementLabel,
    VoidCallback? onCompleteWorkout,
    VoidCallback? onQuitWorkout,
  }) {
    return showGlassSheet(
      context: context,
      builder: (_) => GlassSheet(
        showHandle: true,
        child: EasyExerciseActionsSheet(
          exerciseName: exerciseName,
          actions: [
            // Per-equipment weight increment (the +/− step). Shows the current
            // value; tapping opens a quick picker.
            EasyExerciseAction(
              icon: Icons.tune_rounded,
              label: 'Increment',
              subtitle: incrementLabel,
              onTap: onSetIncrement,
            ),
            EasyExerciseAction(
              icon: Icons.swap_horiz_rounded,
              label: AppLocalizations.of(context).workoutReviewSwapExercise,
              subtitle: AppLocalizations.of(context).easyExerciseActionsPickADifferentMovement,
              onTap: onSwap,
            ),
            EasyExerciseAction(
              icon: Icons.healing_outlined,
              label: AppLocalizations.of(context).exerciseOptionsReportPain,
              subtitle: AppLocalizations.of(context).easyExerciseActionsSkipThisExerciseAvoid,
              onTap: onReportPain,
            ),
            EasyExerciseAction(
              icon: Icons.fitness_center_rounded,
              label: AppLocalizations.of(context).exerciseOptionsChangeEquipment,
              subtitle: AppLocalizations.of(context).easyExerciseActionsDonTHaveWhat,
              onTap: onChangeEquipment,
            ),
            EasyExerciseAction(
              icon: Icons.skip_next_rounded,
              label: AppLocalizations.of(context).easyTopBarSkipToNextExercise,
              onTap: onSkipToNext,
            ),
            EasyExerciseAction(
              icon: Icons.play_circle_outline_rounded,
              label: AppLocalizations.of(context).easyExerciseActionsShowVideo,
              onTap: onShowVideo,
            ),
            // Quick water log mid-workout (Easy redesign) — a cup (250 ml).
            EasyExerciseAction(
              icon: Icons.water_drop_outlined,
              label: 'Log water',
              subtitle: '+1 cup · 250 ml',
              onTap: onLogWater,
            ),
            // Workout-level actions — finalize now or quit (both confirm /
            // finalize on their own). Quit is tinted destructive.
            if (onCompleteWorkout != null)
              EasyExerciseAction(
                icon: Icons.check_circle_outline_rounded,
                label: AppLocalizations.of(context).workoutTopBarCompleteWorkout,
                subtitle: 'Finish now with your logged sets',
                onTap: onCompleteWorkout,
              ),
            if (onQuitWorkout != null)
              EasyExerciseAction(
                icon: Icons.close_rounded,
                label: AppLocalizations.of(context).easyTopBarQuitWorkout,
                onTap: onQuitWorkout,
                destructive: true,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final fg = isDark ? Colors.white : Colors.black;
    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            child: Text(
              exerciseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: fg.withValues(alpha: 0.55),
              ),
            ),
          ),
          for (final action in actions)
            _ActionRow(action: action, accent: accent, fg: fg, isDark: isDark),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final EasyExerciseAction action;
  final Color accent;
  final Color fg;
  final bool isDark;

  const _ActionRow({
    required this.action,
    required this.accent,
    required this.fg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tint = action.destructive ? Colors.redAccent : fg;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.instance.tap();
          Navigator.of(context).pop();
          action.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, color: accent, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: tint,
                      ),
                    ),
                    if (action.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        action.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: fg.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: fg.withValues(alpha: 0.28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
