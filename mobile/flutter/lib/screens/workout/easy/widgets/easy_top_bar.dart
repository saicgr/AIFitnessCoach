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

import '../../../../core/providers/favorites_provider.dart';
import '../../../../core/providers/workout_ui_mode_provider.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../data/models/exercise.dart';
import '../../shared/tier_comparison_sheet.dart';

/// Fixed 48 pt top bar for the Easy-tier active workout screen.
class EasyTopBar extends ConsumerWidget {
  final int workoutSeconds;
  final VoidCallback onBack;
  final VoidCallback? onMinimize;

  /// "Quit workout" menu action — opens a confirmation and pops.
  final VoidCallback? onQuit;

  /// "Skip to next exercise" menu action.
  final VoidCallback? onSkipToNext;

  /// Current focal exercise — drives the favorite heart state + toggle
  /// target. Null hides the favorite button.
  final WorkoutExercise? exercise;

  const EasyTopBar({
    super.key,
    required this.workoutSeconds,
    required this.onBack,
    this.onMinimize,
    this.onQuit,
    this.onSkipToNext,
    this.exercise,
  });

  String _fmtStopwatch(int s) {
    final mins = (s ~/ 60).toString().padLeft(2, '0');
    final secs = (s % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
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
            // Back button — floating circular chip (matches the back
            // button style used on other detail screens).
            _FloatingBackButton(
              onTap: () async {
                await HapticService.instance.tap();
                onBack();
              },
              isDark: isDark,
              color: textColor,
            ),
            const Spacer(),
            // [E|S|A] tier toggle
            _TierPill(currentMode: currentMode, accent: accent, isDark: isDark),
            const Spacer(),
            if (exercise != null)
              _FavoriteButton(exercise: exercise!, color: textColor),
            if (onMinimize != null)
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.picture_in_picture_alt_outlined,
                      size: 20, color: textColor),
                  onPressed: () async {
                    await HapticService.instance.tap();
                    onMinimize!.call();
                  },
                  tooltip: 'Minimize workout',
                ),
              ),
            // Overflow menu — holds the quiet but essential Skip / Quit
            // actions so the top bar stays uncluttered.
            if (onSkipToNext != null || onQuit != null)
              SizedBox(
                width: 36,
                height: 36,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert_rounded,
                      size: 20, color: textColor),
                  tooltip: 'More',
                  onSelected: (v) async {
                    await HapticService.instance.tap();
                    if (v == 'skip' && onSkipToNext != null) {
                      onSkipToNext!();
                    } else if (v == 'quit' && onQuit != null) {
                      onQuit!();
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (onSkipToNext != null)
                      const PopupMenuItem(
                        value: 'skip',
                        child: Row(children: [
                          Icon(Icons.skip_next_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Skip to next exercise'),
                        ]),
                      ),
                    if (onQuit != null)
                      PopupMenuItem(
                        value: 'quit',
                        child: Row(children: [
                          Icon(Icons.close_rounded,
                              size: 18, color: Colors.redAccent),
                          const SizedBox(width: 10),
                          const Text('Quit workout',
                              style: TextStyle(color: Colors.redAccent)),
                        ]),
                      ),
                  ],
                ),
              ),
            // Stopwatch
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 18, color: textColor),
                const SizedBox(width: 4),
                Text(
                  _fmtStopwatch(workoutSeconds),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ],
        ),
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
      onLongPress: () async {
        await HapticService.instance.tap();
        await showTierComparisonSheet(context);
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
                  selected ? m.label : m.shortLabel,
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

/// Heart icon that toggles the current exercise in the favorites list.
/// Fills red when favorited; outlined otherwise.
class _FavoriteButton extends ConsumerWidget {
  final WorkoutExercise exercise;
  final Color color;

  const _FavoriteButton({required this.exercise, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoritesProvider).isFavorite(exercise.name);
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          size: 20,
          color: isFav ? Colors.redAccent : color,
        ),
        onPressed: () async {
          await HapticService.instance.tap();
          await ref.read(favoritesProvider.notifier).toggleFavorite(
                exercise.name,
                exerciseId: exercise.id ?? exercise.libraryId,
              );
        },
        tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
      ),
    );
  }
}
