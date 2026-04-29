/// Workout Top Bar V2
///
/// MacroFactor Workouts 2026 inspired top bar.
/// Features:
/// - Hamburger menu on left (opens workout plan drawer)
/// - Workout timer in center
/// - Rest timer with icon and mini progress bar on right
/// - 3-way tier toggle [Easy|Simple|Advanced] — reads/writes workoutUiModeProvider.
///   Sits in the slot previously occupied by the favorite heart (per the
///   Easy/Simple/Advanced rework plan). Favorite heart shifts one slot right.
/// - [kg|lb] unit chip — surfaces the existing useKgForWorkoutProvider so users
///   can flip units without diving into settings.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/workout_design.dart';
import '../../../core/providers/workout_ui_mode_provider.dart';
import '../controllers/workout_timer_controller.dart';
import '../shared/unit_chip.dart';

/// MacroFactor-style workout top bar
class WorkoutTopBarV2 extends ConsumerWidget {
  /// Total workout seconds elapsed
  final int workoutSeconds;

  /// Current rest timer seconds remaining (null if not resting)
  final int? restSecondsRemaining;

  /// Total rest duration (for progress calculation)
  final int? totalRestSeconds;

  /// Whether workout is paused
  final bool isPaused;

  /// Whether to show back button instead of hamburger menu (for warmup flow)
  final bool showBackButton;

  /// Label to show next to back button (e.g., "Warmup")
  final String? backButtonLabel;

  /// Callback to open workout plan drawer (hamburger menu)
  final VoidCallback onMenuTap;

  /// Callback for back button (when showBackButton is true)
  final VoidCallback? onBackTap;

  /// Callback to close/quit workout
  final VoidCallback onCloseTap;

  /// Callback to toggle pause
  final VoidCallback? onTimerTap;

  /// Callback to minimize workout to mini player
  final VoidCallback? onMinimize;

  /// Callback to toggle favorite for current exercise
  final VoidCallback? onFavoriteTap;

  /// Whether current exercise is favorited
  final bool isFavorite;

  /// Optional "Complete workout now" overflow action. When non-null, an
  /// overflow menu (⋮) renders next to the timer with a single item that
  /// invokes this callback. Distinct from `onCloseTap` (which quits and
  /// discards the in-progress session) — `onCompleteWorkoutNow` finalizes
  /// the workout with whatever sets the user has already logged so the
  /// session counts toward streaks / PRs / history.
  final VoidCallback? onCompleteWorkoutNow;

  /// Optional "Skip exercise" overflow action. Skips to the next exercise.
  final VoidCallback? onSkipExercise;

  const WorkoutTopBarV2({
    super.key,
    required this.workoutSeconds,
    this.restSecondsRemaining,
    this.totalRestSeconds,
    required this.isPaused,
    this.showBackButton = false,
    this.backButtonLabel,
    required this.onMenuTap,
    this.onBackTap,
    required this.onCloseTap,
    this.onTimerTap,
    this.onMinimize,
    this.onFavoriteTap,
    this.isFavorite = false,
    this.onCompleteWorkoutNow,
    this.onSkipExercise,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Narrow-width guard: on devices under ~360 pt the full segmented pill with
    // Easy/Simple/Advanced labels crowds the rest of the bar. We collapse to
    // single-char [E|S|A] in that case.
    final screenWidth = MediaQuery.of(context).size.width;
    // iPhone 17 Pro / 16 Pro are 393pt; the cluster (favorite + minimize +
    // timer + overflow) plus the full "Advanced" pill overflows by ~45pt at
    // that width. Bump threshold to 420 so common Pro widths get the compact
    // [E|S|A] tier toggle.
    final useCompactTierToggle = screenWidth < 420;

    return Container(
      color: isDark ? WorkoutDesign.background : Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WorkoutDesign.paddingMedium,
            vertical: 8,
          ),
          child: Row(
            children: [
              // Back/close button on left with optional label
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TopBarButton(
                    icon: showBackButton ? Icons.arrow_back_rounded : Icons.arrow_back_rounded,
                    onTap: showBackButton ? (onBackTap ?? onCloseTap) : onCloseTap,
                    isDark: isDark,
                  ),
                  // Label next to back button (e.g., "Warmup")
                  if (backButtonLabel != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      backButtonLabel!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? WorkoutDesign.textSecondary : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),

              const Spacer(),

              // Tier toggle [E|S|A] — slot previously occupied by the favorite
              // heart. The heart has moved one slot to the right (into the
              // cluster below).
              _TierToggle(
                isDark: isDark,
                compact: useCompactTierToggle,
              ),

              const SizedBox(width: 8),

              // Favorite + Minimize + Timer on the right. UnitChip was
              // dropped from this cluster so the row already fits inside
              // the 370-pt budget; no FittedBox wrapper needed (and that
              // wrapper was tripping `!semantics.parentDataDirty` because
              // the nested Semantics widgets from IconButton/UnitChip
              // didn't play nice under a scaling RenderObject).
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Favorite button (now sits right of the tier toggle)
                  if (onFavoriteTap != null)
                    _TopBarButton(
                      icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                      onTap: onFavoriteTap!,
                      isDark: isDark,
                      iconColor: isFavorite ? Colors.red : null,
                    ),

                  // Unit chip removed from Advanced top bar — Advanced
                  // already has a per-stepper kg/lb toggle, and the
                  // duplicate was pushing the cluster off-screen.

                  // Minimize button (PiP style)
                  if (onMinimize != null)
                    _TopBarButton(
                      icon: Icons.picture_in_picture_alt,
                      onTap: onMinimize!,
                      isSubdued: true,
                      isDark: isDark,
                    ),

                  // Total time elapsed with timer icon
                  GestureDetector(
                    onTap: onTimerTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: isPaused
                              ? WorkoutDesign.warning
                              : (isDark ? WorkoutDesign.textSecondary : Colors.grey.shade600),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          WorkoutTimerController.formatTime(workoutSeconds),
                          style: WorkoutDesign.timerStyle.copyWith(
                            fontSize: 16,
                            color: isPaused
                                ? WorkoutDesign.warning
                                : (isDark ? WorkoutDesign.textSecondary : Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Overflow menu — Skip exercise + Complete workout now
                  if (onCompleteWorkoutNow != null || onSkipExercise != null) ...[
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: 20,
                          color: isDark
                              ? WorkoutDesign.textSecondary
                              : Colors.grey.shade700,
                        ),
                        tooltip: 'More',
                        onSelected: (v) {
                          HapticFeedback.selectionClick();
                          if (v == 'skip_exercise') {
                            onSkipExercise?.call();
                          } else if (v == 'complete_now') {
                            onCompleteWorkoutNow?.call();
                          }
                        },
                        itemBuilder: (ctx) => [
                          if (onSkipExercise != null)
                            const PopupMenuItem<String>(
                              value: 'skip_exercise',
                              child: Row(children: [
                                Icon(Icons.skip_next_rounded, size: 18),
                                SizedBox(width: 10),
                                Text('Skip exercise'),
                              ]),
                            ),
                          if (onCompleteWorkoutNow != null)
                            const PopupMenuItem<String>(
                              value: 'complete_now',
                              child: Row(children: [
                                Icon(Icons.check_circle_rounded, size: 18),
                                SizedBox(width: 10),
                                Text('Complete workout'),
                              ]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3-way segmented tier toggle `[Easy|Simple|Advanced]`.
///
/// Collapses to single-character `[E|S|A]` on narrow widths (< 380 pt) to
/// preserve room for the rest of the top bar. Writes through
/// `workoutUiModeProvider.setMode(...)` which persists locally and to Supabase.
class _TierToggle extends ConsumerWidget {
  final bool isDark;
  final bool compact;
  const _TierToggle({required this.isDark, required this.compact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(workoutUiModeProvider.select((s) => s.mode));
    final notifier = ref.read(workoutUiModeProvider.notifier);

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final tier in WorkoutUiMode.activeValues)
            _TierSegment(
              // Selected segment shows the full word so the user always
              // knows what mode they're in; inactive stays a single
              // letter so the cluster still fits. The UnitChip was dropped
              // from this top bar which frees ~68pt for the full label.
              // In compact mode (< 420pt), use the single-letter shortLabel
              // even for the selected tier so the cluster fits within the
              // top-bar row budget. On wider screens we keep the full word
              // for the selected tier so the user always knows the mode.
              label: (mode == tier && !compact) ? tier.label : tier.shortLabel,
              selected: mode == tier,
              isDark: isDark,
              compact: compact,
              onTap: () async {
                if (mode == tier) return;
                HapticFeedback.selectionClick();
                await notifier.setMode(tier);
              },
            ),
        ],
      ),
    );
  }
}

class _TierSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final bool compact;
  final VoidCallback onTap;

  const _TierSegment({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.75);
    final bg = selected
        ? (isDark ? Colors.white : Colors.black)
        : Colors.transparent;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: compact ? 12 : 12,
            fontWeight: FontWeight.w700,
            color: fg,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

/// Top bar icon button
class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isSubdued;
  final bool isDark;
  final Color? iconColor;

  const _TopBarButton({
    required this.icon,
    required this.onTap,
    this.isSubdued = false,
    this.isDark = true,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 24,
          color: iconColor ??
              (isSubdued
                  ? (isDark ? WorkoutDesign.textMuted : Colors.grey.shade500)
                  : (isDark ? WorkoutDesign.textPrimary : Colors.grey.shade800)),
        ),
      ),
    );
  }
}

// NOTE: a private `_RestTimerChip` used to live here but was never wired
// into the top bar (the total-time chip on the right is built inline). It
// was flagged as dead code during the Easy/Simple/Advanced rework audit and
// removed. If a dedicated rest-timer chip is needed in the top bar later,
// resurrect from git history (see commit HEAD~ on this file).
