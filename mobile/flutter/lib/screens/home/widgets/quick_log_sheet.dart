/// Glassmorphic "Log" quick-actions sheet — opened from the metric card's Log
/// button (Direction C). Uses the app-standard [GlassSheet]. Each action routes
/// into an existing logging flow; nothing here owns business logic.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/quick_action.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/hydration_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/quick_actions_sheet.dart';
import '../../nutrition/log_meal_sheet.dart';
import '../../workout/widgets/hydration_dialog.dart';
import '../../workout/widgets/quick_workout_sheet.dart';

/// One quick-log action. [isMore] flags the trailing "More" tile, which is
/// styled as system chrome (muted) and opens the full quick-actions sheet.
///
/// Icon + color are derived from [quickActionRegistry] via [registryId] so the
/// LOG sheet, the home shortcut row, and the customize grid render an identical
/// glyph/color per shared action (no per-surface divergence). [iconOverride]
/// keeps a distinct glyph where intended (e.g. "Quick add" keeps its +1 mark)
/// while still inheriting the registry color. "More" passes a null
/// [registryId] → muted system chrome.
class _QuickAction {
  /// Registry id this action mirrors (icon + color). Null only for "More".
  final String? registryId;

  /// Optional glyph that overrides the registry icon (color still inherited).
  final IconData? iconOverride;

  /// Fallback glyph used when the registry has no matching entry.
  final IconData fallbackIcon;
  final String label;
  final void Function(BuildContext, WidgetRef) onTap;
  final bool isMore;
  const _QuickAction({
    required this.label,
    required this.onTap,
    this.registryId,
    this.iconOverride,
    this.fallbackIcon = Icons.bolt_outlined,
    this.isMore = false,
  });

  /// Resolved icon — override → registry → fallback.
  IconData get icon =>
      iconOverride ?? quickActionRegistry[registryId]?.icon ?? fallbackIcon;

  /// Resolved color — registry tint, or null for the muted "More" chrome.
  Color? get color => quickActionRegistry[registryId]?.color;
}

void _closeThen(BuildContext context, VoidCallback action) {
  Navigator.of(context).pop();
  action();
}

/// Open the real hydration tracker dialog directly from the sheet (same flow as
/// the Nutrition "Log water" card) and persist the logged amount.
Future<void> _logWater(BuildContext context, WidgetRef ref) async {
  final result = await showHydrationDialog(
    context: context,
    totalIntakeMl: ref.read(hydrationProvider).todaySummary?.totalMl ?? 0,
  );
  if (result == null) return;
  final userId = await ref.read(apiClientProvider).getUserId();
  if (userId == null) return;
  await ref
      .read(hydrationProvider.notifier)
      .quickLog(
        userId: userId,
        drinkType: result.drinkType.name,
        amountMl: result.amountMl,
      );
}

/// Open the workout generator from the sheet, then push the generated workout
/// (mirrors `quick_action_launcher.dart`'s `quick_workout` case). Distinct from
/// "Log workout", which routes to the Workouts tab to log a finished session.
Future<void> _generateWorkout(BuildContext context, WidgetRef ref) async {
  final workout = await showQuickWorkoutSheet(context, ref);
  if (workout != null && context.mounted) {
    context.push('/workout/${workout.id}', extra: workout);
  }
}

/// Full log surface — highest-frequency log/coach actions + a trailing "More"
/// tile that opens the full quick-actions sheet so nothing is lost. Each tile's
/// ICON + COLOR are inherited from [quickActionRegistry] (via `registryId`) so
/// this sheet stays in lock-step with the home row + customize grid; only the
/// onTap routing is local. Grouped by row: food logging / body + activity /
/// wellness + coach.
final List<_QuickAction> _actions = [
  // Row 1 — food logging
  _QuickAction(
    registryId: 'photo_food',
    label: 'Snap meal',
    onTap: (c, ref) =>
        _closeThen(c, () => showLogMealSheet(c, ref, autoOpenCamera: true)),
  ),
  _QuickAction(
    registryId: 'scan_menu',
    label: 'Scan menu',
    onTap: (c, ref) =>
        _closeThen(c, () => showLogMealSheet(c, ref, autoOpenMenuScan: true)),
  ),
  _QuickAction(
    registryId: 'food',
    iconOverride: Icons.search_rounded,
    label: 'Search food',
    onTap: (c, ref) => _closeThen(c, () => showLogMealSheet(c, ref)),
  ),
  // "Quick add" = drop in calories/macros without searching a food (the
  // MyFitnessPal-style manual entry). Keeps its +1 glyph, inherits the
  // registry green so it reads as a food action.
  _QuickAction(
    registryId: 'food',
    iconOverride: Icons.exposure_plus_1_rounded,
    label: 'Quick add',
    onTap: (c, ref) => _closeThen(c, () => showLogMealSheet(c, ref)),
  ),
  // Row 2 — body + activity
  _QuickAction(
    registryId: 'water',
    label: 'Log water',
    onTap: (c, ref) => _closeThen(c, () => _logWater(c, ref)),
  ),
  // Generate a fresh workout (AI generator), then launch it. Distinct from
  // "Log workout" below, which logs a finished session.
  _QuickAction(
    registryId: 'quick_workout',
    label: 'Generate workout',
    onTap: (c, ref) => _closeThen(c, () => _generateWorkout(c, ref)),
  ),
  _QuickAction(
    registryId: 'workout',
    label: 'Log workout',
    onTap: (c, ref) => _closeThen(c, () => c.go('/workouts')),
  ),
  _QuickAction(
    registryId: 'weight',
    label: 'Weigh in',
    onTap: (c, ref) => _closeThen(c, () => c.go('/profile?tab=body')),
  ),
  _QuickAction(
    registryId: 'mood',
    label: 'Log mood',
    onTap: (c, ref) => _closeThen(c, () => c.push('/recovery')),
  ),
  // Row 3 — wellness + coach
  _QuickAction(
    registryId: 'meditate',
    label: 'Mindful',
    onTap: (c, ref) => _closeThen(
      c,
      () => c.push('/mindfulness/session?source=breathwork&duration=5'),
    ),
  ),
  _QuickAction(
    registryId: 'fasting',
    label: 'Start fast',
    onTap: (c, ref) => _closeThen(c, () => c.push('/fasting')),
  ),
  _QuickAction(
    registryId: 'chat',
    label: 'Ask coach',
    onTap: (c, ref) => _closeThen(c, () => c.push('/chat?source=quick_log')),
  ),
  _QuickAction(
    label: 'More',
    fallbackIcon: Icons.more_horiz_rounded,
    onTap: (c, ref) => _closeThen(c, () => showQuickActionsSheet(c, ref)),
    isMore: true,
  ),
];

/// Show the glassmorphic quick-log sheet.
Future<void> showQuickLogSheet(BuildContext context, WidgetRef ref) {
  return showGlassSheet<void>(
    context: context,
    builder: (ctx) => GlassSheet(child: _QuickLogContent(parentRef: ref)),
  );
}

class _QuickLogContent extends StatelessWidget {
  final WidgetRef parentRef;
  const _QuickLogContent({required this.parentRef});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LOG',
            style: ZType.lbl(13, color: c.textMuted, letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 6,
            childAspectRatio: 0.80,
            children: [
              for (final a in _actions)
                _QuickTile(action: a, colors: c, parentRef: parentRef),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final _QuickAction action;
  final ThemeColors colors;
  final WidgetRef parentRef;
  const _QuickTile({
    required this.action,
    required this.colors,
    required this.parentRef,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    // "More" reads as muted system chrome; every other action gets its own tint
    // on a faintly color-washed chip so the grid scans as distinct surfaces.
    final tint = action.color ?? c.textSecondary;
    return GestureDetector(
      onTap: () {
        HapticService.light();
        action.onTap(context, parentRef);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: action.isMore
                  ? c.surface
                  : Color.alphaBlend(tint.withValues(alpha: 0.12), c.surface),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: action.isMore
                    ? c.cardBorder
                    : tint.withValues(alpha: 0.32),
              ),
            ),
            child: Icon(action.icon, size: 23, color: tint),
          ),
          const SizedBox(height: 7),
          Text(
            action.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
