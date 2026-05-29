/// Glassmorphic "Log" quick-actions sheet — opened from the metric card's Log
/// button (Direction C). Uses the app-standard [GlassSheet]. Each action routes
/// into an existing logging flow; nothing here owns business logic.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/quick_actions_sheet.dart';
import '../../nutrition/log_meal_sheet.dart';

/// One quick-log action. [isMore] flags the trailing "More" tile, which is
/// styled as system chrome (muted) and opens the full quick-actions sheet.
class _QuickAction {
  final IconData icon;
  final String label;
  final void Function(BuildContext, WidgetRef) onTap;
  final bool isMore;
  const _QuickAction(this.icon, this.label, this.onTap, {this.isMore = false});
}

void _closeThen(BuildContext context, VoidCallback action) {
  Navigator.of(context).pop();
  action();
}

/// Compact action set (issue 2): the eight highest-frequency log actions in a
/// tidy 3×3 grid, with mood + mindful folded in (issue 6 — they no longer live
/// as standalone home cards). The 9th cell is "More", which dismisses this
/// sheet and opens the full quick-actions sheet so nothing is lost.
final List<_QuickAction> _actions = [
  _QuickAction(
    Icons.photo_camera_outlined,
    'Snap meal',
    (c, ref) =>
        _closeThen(c, () => showLogMealSheet(c, ref, autoOpenCamera: true)),
  ),
  _QuickAction(
    Icons.restaurant_menu_outlined,
    'Scan menu',
    (c, ref) =>
        _closeThen(c, () => showLogMealSheet(c, ref, autoOpenMenuScan: true)),
  ),
  _QuickAction(
    Icons.search_rounded,
    'Search food',
    (c, ref) => _closeThen(c, () => showLogMealSheet(c, ref)),
  ),
  _QuickAction(
    Icons.exposure_plus_1_rounded,
    'Quick add',
    (c, ref) => _closeThen(c, () => showLogMealSheet(c, ref)),
  ),
  _QuickAction(
    Icons.local_drink_outlined,
    'Log water',
    (c, ref) => _closeThen(c, () => c.push('/nutrition')),
  ),
  _QuickAction(
    Icons.monitor_weight_outlined,
    'Weigh in',
    (c, ref) => _closeThen(c, () => c.push('/profile?tab=body')),
  ),
  _QuickAction(
    Icons.mood_outlined,
    'Log mood',
    (c, ref) => _closeThen(c, () => c.push('/recovery')),
  ),
  _QuickAction(
    Icons.self_improvement_outlined,
    'Mindful',
    (c, ref) => _closeThen(
        c, () => c.push('/mindfulness/session?source=breathwork&duration=5')),
  ),
  _QuickAction(
    Icons.more_horiz_rounded,
    'More',
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
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 0.92,
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
              color: c.surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: c.cardBorder),
            ),
            child: Icon(
              action.icon,
              size: 23,
              // "More" reads as system chrome, not a primary log action.
              color: action.isMore ? c.textSecondary : c.accent,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            action.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
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
