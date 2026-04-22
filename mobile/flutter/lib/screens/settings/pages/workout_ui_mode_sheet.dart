// Modal bottom sheet that explains the three active-workout UI tiers and lets
// the user pick one. Surfaces behind every entry point that changes
// `workoutUiModeProvider` (Settings row tap, "?" explainer, etc.).
//
// Design rules followed:
//  - AccentColorScope.of(context) for the selected-card accent — never a
//    hardcoded brand color (see feedback_accent_colors.md).
//  - Tier descriptions use the exact copy in the approved plan — no
//    paraphrasing (the product voice was approved verbatim).
//  - Tapping any card OR the segmented control writes to the provider and
//    dismisses the sheet, so users never have to hunt for a "Done" button.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/workout_ui_mode_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Entry point — mirrors the codebase's `showReplayTutorialsSheet` style.
/// Pass `context` from a ConsumerStatefulWidget's `build`.
Future<void> showWorkoutUiModeSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _WorkoutUiModeSheet(),
  );
}

class _WorkoutUiModeSheet extends ConsumerWidget {
  const _WorkoutUiModeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = AccentColorScope.of(context).getColor(isDark);

    final current = ref.watch(workoutUiModeProvider.select((s) => s.mode));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle — identical geometry to _showReplayTutorialsSheet.
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Workout Mode',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick the level of detail you want while logging sets. You can change this any time.',
              style: TextStyle(fontSize: 13, color: textMuted, height: 1.35),
            ),
            const SizedBox(height: 16),

            _TierCard(
              mode: WorkoutUiMode.easy,
              icon: Icons.spa_outlined,
              title: 'Easy',
              description:
                  "Polished default. Steppers, AI coach, rest timer, notes with audio + photo, tap-to-edit past sets. Perfect for most sessions.",
              selected: current == WorkoutUiMode.easy,
              accent: accent,
              isDark: isDark,
              onTap: () => _pick(context, ref, WorkoutUiMode.easy),
            ),
            const SizedBox(height: 10),
            _TierCard(
              mode: WorkoutUiMode.advanced,
              icon: Icons.tune_rounded,
              title: 'Advanced',
              description:
                  'Everything — warmup/stretch phases, RPE/RIR, pyramid, supersets, drop sets, ±2.5 kg increments, plate chart.',
              selected: current == WorkoutUiMode.advanced,
              accent: accent,
              isDark: isDark,
              onTap: () => _pick(context, ref, WorkoutUiMode.advanced),
            ),
            const SizedBox(height: 18),

            // Segmented footer — the same selector that lives on every other
            // entry point, so users learn one control and use it everywhere.
            WorkoutUiModeSegmentedControl(
              onChanged: (mode) => _pick(context, ref, mode),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    WorkoutUiMode mode,
  ) async {
    HapticService.selection();
    await ref.read(workoutUiModeProvider.notifier).setMode(mode);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _TierCard extends StatelessWidget {
  final WorkoutUiMode mode;
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _TierCard({
    required this.mode,
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final borderColor = selected
        ? accent
        : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder);
    final bg = selected ? accent.withValues(alpha: 0.08) : elevated;

    return Semantics(
      button: true,
      selected: selected,
      label: '$title mode',
      hint: description,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon well
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: selected ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (selected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Selected',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.black : Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable 3-way segmented control bound to `workoutUiModeProvider`.
///
/// Exposed publicly so Profile + Workouts-tab header can render the identical
/// pill without duplicating the Riverpod plumbing or the accent treatment.
///
/// `onChanged` is optional — when omitted the control writes to the provider
/// itself. The sheet passes a callback so it can both persist *and* dismiss.
class WorkoutUiModeSegmentedControl extends ConsumerWidget {
  final ValueChanged<WorkoutUiMode>? onChanged;

  /// When `true` the segment labels collapse to `E / S / A` so the control
  /// fits in narrow placements (e.g. the Workouts-tab floating header next to
  /// the title pill + Library + Settings buttons).
  final bool compact;

  /// Height of the control. Default 34 pt reads well in settings rows and in
  /// the profile-card inline placement without dominating the layout.
  final double height;

  const WorkoutUiModeSegmentedControl({
    super.key,
    this.onChanged,
    this.compact = false,
    this.height = 34,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final current = ref.watch(workoutUiModeProvider.select((s) => s.mode));

    final border = (isDark ? Colors.white : Colors.black).withValues(
      alpha: 0.14,
    );

    final control = Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: border),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: WorkoutUiMode.values.map((mode) {
          return _Segment(
            label: compact ? mode.shortLabel : mode.label,
            selected: current == mode,
            accent: accent,
            isDark: isDark,
            height: height - 4,
            onTap: () => _select(ref, mode),
          );
        }).toList(),
      ),
    );

    // Frosted-glass wrapper lets the header placement sit naturally on top of
    // the hero carousel without clashing with the title pill's own blur.
    if (!compact) return control;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: control,
      ),
    );
  }

  Future<void> _select(WidgetRef ref, WorkoutUiMode mode) async {
    HapticService.selection();
    if (onChanged != null) {
      onChanged!(mode);
    } else {
      await ref.read(workoutUiModeProvider.notifier).setMode(mode);
    }
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final bool isDark;
  final double height;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.78);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        height: height,
        // Symmetric padding keeps the three segments equal-width regardless of
        // label length ("Advanced" is longest, "Easy" shortest).
        padding: EdgeInsets.symmetric(horizontal: label.length <= 1 ? 10 : 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: label.length <= 1 ? 13 : 12.5,
            fontWeight: FontWeight.w700,
            color: fg,
            height: 1.0,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
