/// Reorderable list of nudge categories — the user's override for
/// [SubCardRanker]. Mounted inside [AISettingsScreen]; persists through
/// [coachUiSettingsProvider]. Reorder = drag the handle on the right.
///
/// Default order (industry pyramid): healthAlert > timeSensitive > streak >
/// habit > educational > social. Reset → falls back to the default.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/contextual_nudge.dart' show NudgeCategory;
import '../../data/providers/ai_settings_provider.dart';

class NudgePrioritySection extends ConsumerWidget {
  const NudgePrioritySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final settings = ref.watch(coachUiSettingsProvider);
    final order = settings.effectiveCategoryOrder;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'COACH CARD PRIORITIES',
                  style: ZType.lbl(11.5, color: c.textMuted, letterSpacing: 2.0),
                ),
              ),
              if (settings.categoryOrder.isNotEmpty)
                TextButton(
                  onPressed: () => ref
                      .read(coachUiSettingsProvider.notifier)
                      .resetCategoryOrder(),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Drag to reorder. Higher = appears first in coach card.',
            style: TextStyle(
              fontSize: 11.5,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.cardBorder),
            ),
            child: ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: (oldIdx, newIdx) {
                final list = [...order];
                if (newIdx > oldIdx) newIdx -= 1;
                final item = list.removeAt(oldIdx);
                list.insert(newIdx, item);
                ref.read(coachUiSettingsProvider.notifier).setCategoryOrder(list);
              },
              children: [
                for (var i = 0; i < order.length; i++)
                  _CategoryRow(
                    key: ValueKey(order[i].name),
                    index: i,
                    isLast: i == order.length - 1,
                    category: order[i],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final int index;
  final bool isLast;
  final NudgeCategory category;
  const _CategoryRow({
    super.key,
    required this.index,
    required this.isLast,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Container(
      key: key,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : c.cardBorder,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: c.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(_iconFor(category), style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _labelFor(category),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: Icon(Icons.drag_handle, size: 20, color: c.textMuted),
          ),
        ],
      ),
    );
  }

  static String _iconFor(NudgeCategory cat) {
    switch (cat) {
      case NudgeCategory.healthAlert:
        return '🚨';
      case NudgeCategory.timeSensitive:
        return '⏰';
      case NudgeCategory.streak:
        return '🔥';
      case NudgeCategory.habit:
        return '✅';
      case NudgeCategory.educational:
        return '📚';
      case NudgeCategory.social:
        return '👥';
    }
  }

  static String _labelFor(NudgeCategory cat) {
    switch (cat) {
      case NudgeCategory.healthAlert:
        return 'Health alerts';
      case NudgeCategory.timeSensitive:
        return 'Time-sensitive';
      case NudgeCategory.streak:
        return 'Streak risk';
      case NudgeCategory.habit:
        return 'Habit nudges';
      case NudgeCategory.educational:
        return 'Educational';
      case NudgeCategory.social:
        return 'Social';
    }
  }
}
