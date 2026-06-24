// Easy tier — top bar.
//
// Layout (left → center → right):
//   [ ← back ]  [ E | S | A tier pill ]  [ ⏱  mm:ss stopwatch ]
//
// Beginner rule: NO favorite heart, NO mini-player icon. Those live in
// Simple/Advanced top bars. Easy's goal is to keep the cognitive surface
// as close to zero as possible — back, mode, time.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/workout_ui_mode_provider.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../data/models/exercise.dart';
import '../../shared/tier_comparison_sheet.dart';

import '../../../../l10n/generated/app_localizations.dart';
/// Fixed 48 pt top bar for the Easy-tier active workout screen.
class EasyTopBar extends ConsumerWidget {
  final int workoutSeconds;
  final VoidCallback onBack;
  final VoidCallback? onMinimize;

  /// "Quit workout" menu action — opens a confirmation and pops.
  final VoidCallback? onQuit;

  /// "Complete workout now" menu action — finalize with whatever sets the
  /// user has already logged (remaining sets are auto-stamped as zero) and
  /// route to the completion / summary screen.
  final VoidCallback? onCompleteNow;

  /// "Skip to next exercise" menu action.
  final VoidCallback? onSkipToNext;

  /// Current focal exercise — retained for callers; no longer drives a
  /// favorite heart (removed per the Easy redesign — no heart/PiP in Easy).
  final WorkoutExercise? exercise;

  /// Opens the full ⋯ actions sheet (This-exercise + Workout groups). When
  /// provided, the single ⋯ on the right routes here (matches the mockup);
  /// falls back to the legacy Skip/Complete/Quit popup when null.
  final VoidCallback? onShowActions;

  const EasyTopBar({
    super.key,
    required this.workoutSeconds,
    required this.onBack,
    this.onMinimize,
    this.onQuit,
    this.onCompleteNow,
    this.onSkipToNext,
    this.exercise,
    this.onShowActions,
  });

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textColor =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.88);
    final currentMode =
        ref.watch(workoutUiModeProvider.select((s) => s.mode));

    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Back button — confirms before leaving (parity with Advanced).
            _FloatingBackButton(
              onTap: () async {
                await HapticService.instance.tap();
                onBack();
              },
              isDark: isDark,
              color: textColor,
            ),
            const SizedBox(width: 8),
            // Elapsed-time pill (the mockup's left timer). Display-only — the
            // workout clock keeps running; no fragile half-wired pause.
            _TimerPill(label: _fmt(workoutSeconds), isDark: isDark, color: textColor),
            const Spacer(),
            // [Easy | Advanced] tier toggle
            _TierPill(currentMode: currentMode, accent: accent, isDark: isDark),
            const Spacer(),
            // Single ⋯ = ACTIONS (mockup). Opens the full action sheet
            // (Increment · Swap · Report pain · Change equipment · Skip ·
            // Show video · Log water · Complete · Quit). No heart, no PiP.
            SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_horiz_rounded, size: 22, color: textColor),
                tooltip: AppLocalizations.of(context).homeMore,
                onPressed: (onShowActions ??
                        onSkipToNext ??
                        onCompleteNow ??
                        onQuit) ==
                    null
                    ? null
                    : () async {
                        await HapticService.instance.tap();
                        if (onShowActions != null) {
                          onShowActions!();
                        } else if (onCompleteNow != null) {
                          onCompleteNow!();
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small rounded elapsed-time pill on the left of the Easy top bar.
class _TimerPill extends StatelessWidget {
  final String label;
  final bool isDark;
  final Color color;
  const _TimerPill(
      {required this.label, required this.isDark, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Space Mono',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 3-way segmented pill (E | S | A) — taps write to workoutUiModeProvider.
class _TierPill extends ConsumerWidget {
  final WorkoutUiMode currentMode;
  final Color accent;
  final bool isDark;
  const _TierPill({
    required this.currentMode,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () {
        HapticService.instance.tap();
        showTierComparisonSheet(context);
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: WorkoutUiMode.activeValues.map((m) {
          final selected = m == currentMode;
          // Selected segment shows the full label ("Easy" / "Simple" /
          // "Advanced") so the user always knows what mode they're in.
          // Inactive segments collapse to a single letter to keep the pill
          // compact. Tap expands that segment to its full word.
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              if (selected) return;
              await HapticService.instance.tap();
              await ref.read(workoutUiModeProvider.notifier).setMode(m);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 10),
              decoration: BoxDecoration(
                color: selected ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Text(
                  // Always show the FULL label so the inactive segment reads
                  // "Advanced" (not a bare "A") — per the Easy redesign.
                  m.label,
                  key: ValueKey('${m.name}_${selected ? 'full' : 'short'}'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.78),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
        ),
      ),
    );
  }
}

/// Rounded floating back chip — matches the style used on the other
/// detail screens in the app (subtle translucent bg, not a raw icon).
class _FloatingBackButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;
  final Color color;

  const _FloatingBackButton({
    required this.onTap,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10),
              width: 0.5,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.arrow_back_ios_new, size: 18, color: color),
        ),
      ),
    );
  }
}

