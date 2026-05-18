import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_colors.dart';
import '../../core/widgets/line_icon.dart';
import '../../data/providers/home_sections_provider.dart';
import '../../data/services/haptic_service.dart';

/// "My Space" — lets the user reorder and show/hide the customizable
/// sections of the unified home screen.
///
/// The home header, notification banners and rating prompt are fixed system
/// chrome and are intentionally not listed here. Everything else (quick
/// actions, week strip, workout card, nutrition card, metric trio) can be
/// dragged into any order or hidden; changes persist immediately via
/// [homeSectionsProvider] and the home screen rebuilds live.
class HomeMySpaceScreen extends ConsumerWidget {
  const HomeMySpaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.colors(context);
    final sections = ref.watch(homeSectionsProvider);
    final notifier = ref.read(homeSectionsProvider.notifier);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'My Space',
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: IconThemeData(color: c.textPrimary),
        actions: [
          if (!sections.isDefault)
            TextButton(
              onPressed: () {
                HapticService.medium();
                notifier.resetToDefault();
              },
              child: Text(
                'Reset',
                style: TextStyle(
                  color: c.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Drag to reorder. Toggle to show or hide a section on your home '
            'screen. The header and notifications always stay put.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) {
              HapticService.light();
              notifier.reorder(oldIndex, newIndex);
            },
            children: [
              for (int i = 0; i < sections.order.length; i++)
                _SectionRow(
                  key: ValueKey(sections.order[i]),
                  index: i,
                  section: sections.order[i],
                  visible: sections.isVisible(sections.order[i]),
                  colors: c,
                  onToggle: () {
                    HapticService.light();
                    notifier.toggle(sections.order[i]);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final int index;
  final HomeSection section;
  final bool visible;
  final ThemeColors colors;
  final VoidCallback onToggle;

  const _SectionRow({
    required super.key,
    required this.index,
    required this.section,
    required this.visible,
    required this.colors,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(Icons.drag_indicator_rounded,
                    size: 22, color: c.textMuted),
              ),
            ),
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (visible ? c.accent : c.textMuted)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: LineIcon(
                section.iconName,
                size: 19,
                color: visible ? c.accent : c.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: visible ? c.textPrimary : c.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    section.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: visible,
              activeThumbColor: c.accent,
              onChanged: (_) => onToggle(),
            ),
          ],
        ),
      ),
    );
  }
}
