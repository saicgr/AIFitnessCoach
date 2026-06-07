import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/nutrition_stats_layout_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';

/// Bottom sheet to reorder and show/hide the NUTRITION STATS cards.
///
/// Drag the handle to reorder; tap the eye to hide/show. Changes persist
/// instantly via [nutritionStatsLayoutProvider]; the section re-renders live.
class NutritionStatsCustomizeSheet extends ConsumerWidget {
  final bool isDark;
  const NutritionStatsCustomizeSheet({super.key, required this.isDark});

  static Future<void> show(BuildContext context, {required bool isDark}) {
    return showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(
        maxHeightFraction: 0.8,
        child: NutritionStatsCustomizeSheet(isDark: isDark),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(nutritionStatsLayoutProvider);
    final notifier = ref.read(nutritionStatsLayoutProvider.notifier);
    final accent = ref.colors(context).accent;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final tileColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 20, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Customize stats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  HapticService.light();
                  notifier.reset();
                },
                child: Text('Reset',
                    style: TextStyle(fontSize: 13, color: textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Drag to reorder. Tap the eye to hide a card.',
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              buildDefaultDragHandles: false,
              itemCount: layout.order.length,
              onReorder: (oldIndex, newIndex) {
                HapticService.light();
                notifier.reorder(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final card = layout.order[index];
                final hidden = layout.isHidden(card);
                return Padding(
                  key: ValueKey(card.key),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Icon(Icons.drag_indicator_rounded,
                              color: textMuted, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            card.label,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: hidden ? textMuted : textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            HapticService.light();
                            notifier.toggleHidden(card);
                          },
                          icon: Icon(
                            hidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: hidden ? textMuted : accent,
                          ),
                          tooltip: hidden ? 'Show' : 'Hide',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
