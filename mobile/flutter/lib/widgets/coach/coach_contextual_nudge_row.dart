/// One row of the stacked contextual-nudge list inside the Coach hero card.
/// Replaces the standalone `_HydrationResetRow` + `_BreakfastSlotRow` that
/// used to live inside `HomeNutritionCard`.
///
/// Layout: icon · (title + body) · CTA pill. The title + body region is one
/// tap target that opens `showCoachNudgeExplainer`; the CTA pill is a
/// separate target that dispatches the action directly. Swipe-left snoozes
/// the nudge for 4 hours via `nudgeSnoozeProvider`.
///
/// i18n width handling: the title + body Column uses `Expanded` with
/// `softWrap: false` + ellipsis on body so long localizations clip cleanly
/// (the same fix we shipped to the old `_BreakfastSlotRow` to resolve the
/// 61px overflow).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/contextual_nudge.dart';
import '../../data/providers/nudge_snooze_provider.dart';
import '../../data/providers/sub_card_shown_today_provider.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/repositories/hydration_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../screens/nutrition/log_meal_sheet.dart';
import 'coach_nudge_explainer_sheet.dart';

class CoachContextualNudgeRow extends ConsumerWidget {
  final ContextualNudge nudge;

  /// Optional override for the CTA tint. Defaults to `c.accent` — keeping
  /// it pluggable lets a future variant of the hydration nudge use the
  /// cyan macro tint without leaking the dependency back into the model.
  final Color? ctaColor;

  const CoachContextualNudgeRow({
    super.key,
    required this.nudge,
    this.ctaColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final tint = ctaColor ?? c.accent;

    return Dismissible(
      key: ValueKey('nudge_${nudge.id.name}'),
      direction: DismissDirection.endToStart,
      background: Container(
        // Non-directional alignment/padding: the Dismissible captures its
        // background widget and re-renders it during the dismiss
        // animation in a context that doesn't always carry Directionality.
        // Using `AlignmentDirectional`/`EdgeInsetsDirectional` here threw
        // "No TextDirection found" repeatedly mid-swipe.
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: c.cardBorder.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.snooze, size: 16, color: c.textMuted),
            const SizedBox(width: 6),
            Text(
              'Snooze 4h',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: c.textMuted,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        ref.read(nudgeSnoozeProvider.notifier).snooze(nudge.id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(nudge.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Semantics(
                button: true,
                label: '${nudge.title}. ${nudge.body}',
                hint: 'Double-tap to learn more, or use the action button.',
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => showCoachNudgeExplainer(
                    context,
                    nudge: nudge,
                    ref: ref,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          nudge.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: c.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          nudge.body,
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.3,
                            color: c.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _CtaPill(
              label: nudge.ctaLabel,
              color: tint,
              onTap: () => _dispatch(context, ref, nudge.action),
            ),
          ],
        ),
      ),
    );
  }

  /// Dispatch the action attached to the nudge. Kept in the row so the
  /// model (`ContextualNudge`) stays free of `BuildContext` / `WidgetRef`.
  Future<void> _dispatch(
    BuildContext context,
    WidgetRef ref,
    ContextualNudgeAction action,
  ) async {
    HapticService.light();
    switch (action.kind) {
      case ContextualNudgeActionKind.logHydration:
        final userId = ref.read(currentUserProvider).valueOrNull?.id;
        final amountMl = (action.args['amountMl'] as int?) ?? 500;
        if (userId != null) {
          await ref
              .read(hydrationProvider.notifier)
              .quickLog(userId: userId, amountMl: amountMl);
          // Once water is logged the trigger condition no longer holds —
          // clear any stale snooze so future re-eligibility isn't blocked.
          ref.read(nudgeSnoozeProvider.notifier).clear(nudge.id);
        } else if (context.mounted) {
          context.go('/nutrition');
        }
      case ContextualNudgeActionKind.quickLogMeal:
        final mealType = (action.args['mealType'] as String?) ?? '';
        if (!context.mounted) return;
        await showLogMealSheet(
          context,
          ref,
          initialMealType: mealType.isEmpty ? null : mealType,
        );
        ref.read(nudgeSnoozeProvider.notifier).clear(nudge.id);
      case ContextualNudgeActionKind.startWorkout:
        final today =
            ref.read(todayWorkoutProvider).valueOrNull?.todayWorkout;
        if (!context.mounted) return;
        if (today != null) {
          context.push('/workout/${today.id}', extra: today);
        } else {
          context.go('/workouts');
        }
      case ContextualNudgeActionKind.openJournal:
        // Journal screen ships in a later sprint; fall through to chat
        // so the CTA never dead-ends. The explainer modal makes the
        // intent clear.
        if (!context.mounted) return;
        context.push('/chat?source=wind_down');
      case ContextualNudgeActionKind.logMood:
        if (!context.mounted) return;
        // Mood logging surface ships later — open a chat thread tagged
        // with the source so the user still has somewhere to go.
        context.push('/chat?source=mood_checkin');
      case ContextualNudgeActionKind.startBreathwork:
        if (!context.mounted) return;
        // Breathwork player ships later — chat fallback for now.
        context.push('/chat?source=breathwork');
      case ContextualNudgeActionKind.openTomorrowPreview:
        if (!context.mounted) return;
        // Show tomorrow's workout (or the broader workouts list).
        context.go('/workouts');
      case ContextualNudgeActionKind.openDailyLesson:
        if (!context.mounted) return;
        // Lesson rotation is content-managed; route to /discover for now.
        context.push('/discover?source=daily_lesson');
      case ContextualNudgeActionKind.openAiSettings:
        if (!context.mounted) return;
        context.push('/ai-settings');
      case ContextualNudgeActionKind.navigateRoute:
        final route = (action.args['route'] as String?) ?? '';
        if (route.isEmpty || !context.mounted) return;
        // Use push so users can pop back to home.
        context.push(route);
      case ContextualNudgeActionKind.acknowledge:
        // No-op — the snooze below marks it shown for the day.
        break;
    }
    // Mark this dedupKey as "acted on" for the rest of the local day so
    // the ranker doesn't resurrect it after the user has dealt with it.
    unawaited(
      ref
          .read(subCardShownTodayProvider.notifier)
          .markShown(nudge.effectiveDedupKey),
    );
  }
}

class _CtaPill extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CtaPill({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Re-export so callers can pick a meaningful tint per nudge id without
/// re-declaring the mapping every call site.
Color ctaColorForNudge(NudgeId id) {
  // Names containing these substrings inherit the macro / hydration tint
  // so the expanded enum stays exhaustive without listing every id.
  final n = id.name.toLowerCase();
  if (n.contains('hydration') || n.contains('electrolyte')) {
    return AppColors.cyan;
  }
  if (n.contains('breakfast') ||
      n.contains('lunch') ||
      n.contains('dinner') ||
      n.contains('meal') ||
      n.contains('snack') ||
      n.contains('refuel') ||
      n.contains('protein') ||
      n.contains('fiber')) {
    return AppColors.macroCarbs;
  }
  if (n.contains('workout') ||
      n.contains('warmup') ||
      n.contains('strain') ||
      n.contains('readiness')) {
    return AppColors.macroProtein;
  }
  if (n.contains('sleep') ||
      n.contains('bedtime') ||
      n.contains('wind') ||
      n.contains('breath') ||
      n.contains('mood') ||
      n.contains('mindful')) {
    return AppColors.macroFat;
  }
  return AppColors.macroCarbs;
}
