/// Glassmorphic "Log" quick-actions sheet — opened from the metric card's Log
/// button (Direction C). Uses the app-standard [GlassSheet]. Each action routes
/// into an existing logging flow; nothing here owns business logic.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/hydration_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/quick_actions_sheet.dart';
import '../../nutrition/log_meal_sheet.dart';
import '../../workout/widgets/hydration_dialog.dart';

/// One quick-log action. [isMore] flags the trailing "More" tile, which is
/// styled as system chrome (muted) and opens the full quick-actions sheet.
/// [color] tints the action's icon/chip so each surface is visually distinct
/// (the user asked for per-action colors); "More" passes null → muted chrome.
class _QuickAction {
  final IconData icon;
  final String label;
  final Color? color;
  final void Function(BuildContext, WidgetRef) onTap;
  final bool isMore;
  const _QuickAction(this.icon, this.label, this.color, this.onTap,
      {this.isMore = false});
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
  await ref.read(hydrationProvider.notifier).quickLog(
        userId: userId,
        drinkType: result.drinkType.name,
        amountMl: result.amountMl,
      );
}

/// Full log surface (issue: 3×4 grid with per-action color). Eleven highest-
/// frequency log/coach actions + a trailing "More" tile that opens the full
/// quick-actions sheet so nothing is lost. Grouped by row: food logging /
/// body + activity / wellness + coach.
final List<_QuickAction> _actions = [
  // Row 1 — food logging
  _QuickAction(
    Icons.photo_camera_outlined,
    'Snap meal',
    const Color(0xFF34D399),
    (c, ref) =>
        _closeThen(c, () => showLogMealSheet(c, ref, autoOpenCamera: true)),
  ),
  _QuickAction(
    Icons.restaurant_menu_outlined,
    'Scan menu',
    const Color(0xFF2DD4BF),
    (c, ref) =>
        _closeThen(c, () => showLogMealSheet(c, ref, autoOpenMenuScan: true)),
  ),
  _QuickAction(
    Icons.search_rounded,
    'Search food',
    const Color(0xFF38BDF8),
    (c, ref) => _closeThen(c, () => showLogMealSheet(c, ref)),
  ),
  // "Quick add" = drop in calories/macros without searching a food (the
  // MyFitnessPal-style manual entry inside the log-meal sheet).
  _QuickAction(
    Icons.exposure_plus_1_rounded,
    'Quick add',
    const Color(0xFFFBBF24),
    (c, ref) => _closeThen(c, () => showLogMealSheet(c, ref)),
  ),
  // Row 2 — body + activity
  _QuickAction(
    Icons.local_drink_outlined,
    'Log water',
    const Color(0xFF22D3EE),
    (c, ref) => _closeThen(c, () => _logWater(c, ref)),
  ),
  _QuickAction(
    Icons.fitness_center_rounded,
    'Log workout',
    const Color(0xFFF87171),
    (c, ref) => _closeThen(c, () => c.go('/workouts')),
  ),
  _QuickAction(
    Icons.monitor_weight_outlined,
    'Weigh in',
    const Color(0xFFA855F7),
    (c, ref) => _closeThen(c, () => c.go('/profile?tab=body')),
  ),
  _QuickAction(
    Icons.mood_outlined,
    'Log mood',
    const Color(0xFFFB7185),
    (c, ref) => _closeThen(c, () => c.push('/recovery')),
  ),
  // Row 3 — wellness + coach
  _QuickAction(
    Icons.self_improvement_outlined,
    'Mindful',
    const Color(0xFF818CF8),
    (c, ref) => _closeThen(
        c, () => c.push('/mindfulness/session?source=breathwork&duration=5')),
  ),
  _QuickAction(
    Icons.timelapse_rounded,
    'Start fast',
    const Color(0xFFFB923C),
    (c, ref) => _closeThen(c, () => c.push('/fasting')),
  ),
  _QuickAction(
    Icons.auto_awesome,
    'Ask coach',
    const Color(0xFFFACC15),
    (c, ref) => _closeThen(c, () => c.push('/chat?source=quick_log')),
  ),
  _QuickAction(
    Icons.more_horiz_rounded,
    'More',
    null,
    (c, ref) => _closeThen(c, () => showQuickActionsSheet(c, ref)),
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
