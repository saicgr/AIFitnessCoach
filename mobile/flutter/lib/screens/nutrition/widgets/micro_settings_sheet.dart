/// Glassmorphic "Customize nutrients" sheet — opened from the Hero Nutrition
/// carousel's tune gear (beside the page dots). Mirrors the home metric deck's
/// customize sheet: drag-to-reorder the visible micronutrient tiles, tap to
/// hide, and add hidden ones back. Goals stay FDA Daily Values — this only
/// controls which tiles appear and in what order.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/micronutrient_catalog.dart';
import '../../../data/providers/micronutrient_visibility_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';

/// Show the glassmorphic micronutrient-customization sheet.
Future<void> showMicroSettingsSheet(BuildContext context, WidgetRef ref) {
  return showGlassSheet<void>(
    context: context,
    builder: (ctx) => const GlassSheet(child: _MicroSettingsContent()),
  );
}

class _MicroSettingsContent extends ConsumerWidget {
  const _MicroSettingsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final visibleIds = ref.watch(microVisibilityProvider);
    final visible = [
      for (final id in visibleIds)
        if (microEntryById(id) != null) microEntryById(id)!,
    ];
    final hidden = ref.watch(hiddenMicrosProvider);
    final notifier = ref.read(microVisibilityProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'CUSTOMIZE NUTRIENTS',
                style: ZType.lbl(15, color: c.textPrimary, letterSpacing: 1.2),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  notifier.resetToDefault();
                },
                child: Text(
                  'RESET',
                  style: ZType.lbl(12, color: c.accent, letterSpacing: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Drag to reorder. Tap − to hide a nutrient, + to add it back. '
            'Targets use FDA Daily Values.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: c.textSecondary),
          ),
          const SizedBox(height: 14),

          // ── Visible (reorderable) ──────────────────────────────────────
          Text(
            'SHOWN',
            style: ZType.lbl(10, color: c.textMuted, letterSpacing: 1.8),
          ),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No nutrient tiles shown — add some below.',
                style: TextStyle(fontSize: 12.5, color: c.textMuted),
              ),
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) {
                HapticService.selection();
                final ids = [...visibleIds];
                if (newIndex > oldIndex) newIndex -= 1;
                final moved = ids.removeAt(oldIndex);
                ids.insert(newIndex, moved);
                notifier.setOrder(ids);
              },
              children: [
                for (var i = 0; i < visible.length; i++)
                  _VisibleRow(
                    key: ValueKey('micro_${visible[i].id}'),
                    entry: visible[i],
                    index: i,
                    color: c,
                    onHide: () {
                      HapticService.light();
                      notifier.hide(visible[i].id);
                    },
                  ),
              ],
            ),

          // ── Hidden (add) ───────────────────────────────────────────────
          if (hidden.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'HIDDEN',
              style: ZType.lbl(10, color: c.textMuted, letterSpacing: 1.8),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in hidden)
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      notifier.show(e.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: e.color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: e.color.withValues(alpha: 0.22)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e.emoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            e.name,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.add_rounded, size: 15, color: e.color),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _VisibleRow extends StatelessWidget {
  final MicroCatalogEntry entry;
  final int index;
  final ThemeColors color;
  final VoidCallback onHide;

  const _VisibleRow({
    super.key,
    required this.entry,
    required this.index,
    required this.color,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    final c = color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: entry.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(entry.emoji, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
            // Hide button.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onHide,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Icon(Icons.remove_circle_outline_rounded,
                    size: 20, color: c.textMuted),
              ),
            ),
            const SizedBox(width: 4),
            // Drag handle.
            ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_handle_rounded, size: 20, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
