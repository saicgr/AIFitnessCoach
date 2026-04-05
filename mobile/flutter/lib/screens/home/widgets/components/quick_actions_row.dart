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
          showLogMealSheet(context, ref);
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
    default:
      final action = quickActionRegistry[actionId];
      if (action == null) return const SizedBox.shrink();
      return _GridActionItem(
        icon: action.icon,
        label: action.label,
        iconColor: action.color,
        onTap: () {
          HapticService.light();
          context.push(action.route!);
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

/// Compact quick actions: single row of pinned actions + "+" button
/// When expanded preference is on, shows a second row with actions #5–#9
class CompactQuickActionsRow extends ConsumerWidget {
  const CompactQuickActionsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pinnedActions = ref.watch(pinnedQuickActionsProvider);
    final isExpanded = ref.watch(quickActionsExpandedProvider);
    final secondRow = isExpanded ? ref.watch(secondRowActionsProvider) : <QuickAction>[];
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
            // Row 1: pinned actions + More button
            Row(
              children: [
                for (int i = 0; i < pinnedActions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(child: buildQuickActionWidget(pinnedActions[i].id, isDark, context, ref)),
                ],
                const SizedBox(width: 4),
                Expanded(child: _MoreActionsButton(isDark: isDark)),
              ],
            ),
            // Row 2: next 5 actions (when expanded)
            if (isExpanded && secondRow.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  for (int i = 0; i < secondRow.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(child: buildQuickActionWidget(secondRow[i].id, isDark, context, ref)),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

