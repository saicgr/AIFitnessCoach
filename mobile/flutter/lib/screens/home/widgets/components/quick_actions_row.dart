import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/quick_action.dart';
import '../../../../data/providers/fasting_provider.dart';
import '../../../../data/providers/quick_action_provider.dart';
import '../../../../data/repositories/hydration_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../widgets/glass_sheet.dart';
import '../../../../widgets/main_shell.dart';
import '../../../../widgets/mood_picker_sheet.dart';
import '../../../../widgets/quick_actions_sheet.dart';
import '../../../fasting/widgets/log_weight_sheet.dart';
import '../../../nutrition/log_meal_sheet.dart';
import '../../../workout/widgets/quick_workout_sheet.dart';
import '../../../../widgets/app_tour/app_tour_controller.dart';
import '../../../../data/repositories/progress_photos_repository.dart';
import '../../../stats/widgets/photos_tab.dart';

part 'quick_actions_row_part_hero_action_card.dart';
part 'quick_actions_row_part_more_actions_button.dart';


/// Maps action IDs to the correct widget
Widget buildQuickActionWidget(String actionId, bool isDark, BuildContext context, WidgetRef ref) {
  switch (actionId) {
    case 'water':
      return _WaterGridActionItem(isDark: isDark);
    case 'weight':
      return _WeightGridActionItem(isDark: isDark);
    case 'fasting':
      return _FastGridActionItem(isDark: isDark);
    case 'mood':
      return _MoodGridActionItem(isDark: isDark);
    case 'food':
      return _GridActionItem(
        icon: Icons.restaurant_outlined,
        label: 'Food',
        iconColor: quickActionRegistry['food']!.color,
        onTap: () {
          HapticService.light();
          // Switch to Nutrition branch BEFORE showing the log sheet so the
          // floating nav reflects where the user actually is. When they
          // dismiss the sheet they land on the Nutrition tab (with the
          // just-logged meal visible) instead of being thrown back to Home.
          context.go('/nutrition');
          Future.microtask(() {
            if (context.mounted) showLogMealSheet(context, ref);
          });
        },
        isDark: isDark,
      );
    case 'quick_workout':
      return _GridActionItem(
        icon: Icons.flash_on,
        label: 'Quick',
        iconColor: quickActionRegistry['quick_workout']!.color,
        onTap: () async {
          HapticService.light();
          final workout = await showQuickWorkoutSheet(context, ref);
          if (workout != null && context.mounted) {
            context.push('/workout/${workout.id}', extra: workout);
          }
        },
        isDark: isDark,
      );
    case 'chat':
      return _GridActionItem(
        icon: Icons.auto_awesome,
        label: 'Chat',
        iconColor: quickActionRegistry['chat']!.color,
        onTap: () {
          HapticService.light();
          context.push('/chat');
        },
        isDark: isDark,
      );
    case 'scan_food':
      return _GridActionItem(
        icon: quickActionRegistry['scan_food']!.icon,
        label: quickActionRegistry['scan_food']!.label,
        iconColor: quickActionRegistry['scan_food']!.color,
        onTap: () {
          HapticService.light();
          // Mirror the working flow from the More sheet: hop to Nutrition
          // first so the user lands there after the sheet closes, then
          // open the log-meal sheet with the multi-image camera path armed.
          context.go('/nutrition');
          Future.microtask(() {
            if (context.mounted) {
              showLogMealSheet(context, ref, autoOpenMultiImage: true);
            }
          });
        },
        isDark: isDark,
      );
    case 'scan_menu':
      return _GridActionItem(
        icon: quickActionRegistry['scan_menu']!.icon,
        label: quickActionRegistry['scan_menu']!.label,
        iconColor: quickActionRegistry['scan_menu']!.color,
        onTap: () {
          HapticService.light();
          context.go('/nutrition');
          Future.microtask(() {
            if (context.mounted) {
              showLogMealSheet(context, ref, autoOpenMenuScan: true);
            }
          });
        },
        isDark: isDark,
      );
    default:
      final action = quickActionRegistry[actionId];
      if (action == null) return const SizedBox.shrink();
      return _GridActionItem(
        icon: action.icon,
        label: action.label,
        iconColor: action.color,
        onTap: () {
          HapticService.light();
          // Guard against registry entries that use a non-route behavior
          // (e.g. foodScan / menuScan) but were never explicit-cased here.
          // Without this, action.route! would throw and the tap would
          // silently fail from the user's POV.
          final route = action.route;
          if (route == null || route.isEmpty) {
            debugPrint(
              '⚠️ [QuickActions] No route / case handler for "$actionId" — tap ignored',
            );
            return;
          }
          context.push(route);
        },
        isDark: isDark,
      );
  }
}

/// A grid of quick action buttons (2 rows x 4 columns) with hero card
/// Replaces the FAB + button functionality directly on home screen
class QuickActionsGrid extends ConsumerWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allActions = ref.watch(orderedQuickActionsProvider);
    final gridActions = allActions.take(8).toList();
    final cardBg = isDark
        ? Colors.black.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hero card (Track Your Progress / Active Fasting)
            _HeroActionCard(),
            const SizedBox(height: 8),
            // Row 1: first 4 actions
            Row(
              children: [
                for (int i = 0; i < 4 && i < gridActions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(child: buildQuickActionWidget(gridActions[i].id, isDark, context, ref)),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // Row 2: next 4 actions
            Row(
              children: [
                for (int i = 4; i < 8 && i < gridActions.length; i++) ...[
                  if (i > 4) const SizedBox(width: 4),
                  Expanded(child: buildQuickActionWidget(gridActions[i].id, isDark, context, ref)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// QuickActionsRow: always uses compact mode (Minimalist)
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompactQuickActionsRow();
  }
}

/// Compact quick actions: 2 rows × 5 slots. Both rows are always visible.
/// Row 1: actions 1-5 (from [pinnedQuickActionsProvider]).
/// Row 2: actions 6-9 (from [secondRowActionsProvider]) + the fixed More tile
/// at slot 10, which opens the full QuickActionsSheet for the long-tail actions.
class CompactQuickActionsRow extends ConsumerWidget {
  const CompactQuickActionsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pinnedActions = ref.watch(pinnedQuickActionsProvider);
    final secondRow = ref.watch(secondRowActionsProvider);
    final cardBg = isDark
        ? Colors.black.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: slots 1-5 (pinned actions).
            Row(
              children: [
                for (int i = 0; i < pinnedActions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(child: buildQuickActionWidget(pinnedActions[i].id, isDark, context, ref)),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // Row 2: slots 6-9 (second row) + slot 10 = More (fixed).
            Row(
              children: [
                for (int i = 0; i < secondRow.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(child: buildQuickActionWidget(secondRow[i].id, isDark, context, ref)),
                ],
                if (secondRow.isNotEmpty) const SizedBox(width: 4),
                Expanded(child: _MoreActionsButton(isDark: isDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

