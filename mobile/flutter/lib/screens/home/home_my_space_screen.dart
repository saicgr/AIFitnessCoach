import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_colors.dart';
import '../../core/widgets/line_icon.dart';
import '../../data/providers/home_sections_provider.dart';
import '../../data/services/haptic_service.dart';

/// "My Space" — customize the home screen.
///
/// Two tabs, switched from a floating bottom pill:
///  * Customize — drag to reorder, toggle to show/hide each section.
///  * Discover — apply a ready-made preset layout.
///
/// The header, notification banners and rating prompt are fixed system
/// chrome and are not listed here. The Today Score is a *core* section: it
/// can be reordered but never hidden.
class HomeMySpaceScreen extends ConsumerStatefulWidget {
  const HomeMySpaceScreen({super.key});

  @override
  ConsumerState<HomeMySpaceScreen> createState() => _HomeMySpaceScreenState();
}

class _HomeMySpaceScreenState extends ConsumerState<HomeMySpaceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: Stack(
        children: [
          TabBarView(
            controller: _tab,
            children: const [
              _CustomizeTab(),
              _DiscoverTab(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: _FloatingTabPill(controller: _tab, colors: c),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================ Customize tab

class _CustomizeTab extends ConsumerWidget {
  const _CustomizeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.colors(context);
    final sections = ref.watch(homeSectionsProvider);
    final notifier = ref.read(homeSectionsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        Text(
          'Drag to reorder. Toggle to show or hide a section on your home '
          'screen. The Today Score stays put — it can move, not hide.',
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          section.label,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: visible ? c.textPrimary : c.textMuted,
                          ),
                        ),
                      ),
                      if (section.isCore) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'CORE',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: c.accent,
                            ),
                          ),
                        ),
                      ],
                    ],
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
            // Core sections (Today Score) can be reordered but not hidden —
            // a lock replaces the visibility switch.
            if (section.isCore)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.lock_outline_rounded,
                    size: 18, color: c.textMuted),
              )
            else
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

// ============================================================= Discover tab

class _DiscoverTab extends ConsumerWidget {
  const _DiscoverTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.colors(context);
    final sections = ref.watch(homeSectionsProvider);
    final notifier = ref.read(homeSectionsProvider.notifier);
    final current = sections.visibleInOrder;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        Text(
          'Start from a ready-made layout, then fine-tune it in Customize.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        for (final preset in homeSectionPresets)
          _PresetCard(
            preset: preset,
            colors: c,
            isCurrent: listEquals(current, preset.visible),
            onApply: () {
              HapticService.medium();
              notifier.applyPreset(preset);
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text('${preset.name} layout applied'),
                    duration: const Duration(seconds: 2),
                  ),
                );
            },
          ),
      ],
    );
  }
}

class _PresetCard extends StatelessWidget {
  final HomeSectionPreset preset;
  final ThemeColors colors;
  final bool isCurrent;
  final VoidCallback onApply;

  const _PresetCard({
    required this.preset,
    required this.colors,
    required this.isCurrent,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent ? c.accent : c.cardBorder,
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PresetThumbnail(preset: preset, colors: c),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        preset.description,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        preset.visible.map((s) => s.label).join('  ·  '),
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: isCurrent
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '● Current layout',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: c.accent,
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: onApply,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A mini-render of a preset's home layout — the actual sections it places
/// on your home, stacked as little tiles, so the preview shows what you get.
class _PresetThumbnail extends StatelessWidget {
  final HomeSectionPreset preset;
  final ThemeColors colors;

  const _PresetThumbnail({required this.preset, required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      width: 62,
      height: 92,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final s in preset.visible.take(7)) ...[
            _mini(s, c),
            const SizedBox(height: 2),
          ],
        ],
      ),
    );
  }

  Widget _mini(HomeSection s, ThemeColors c) {
    final muted = c.textMuted.withValues(alpha: 0.30);
    switch (s) {
      case HomeSection.todayScore:
        return Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.accent, width: 2.4),
            ),
          ),
        );
      case HomeSection.workoutCard:
        return Container(
          height: 11,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE89A3E), Color(0xFFC96E18)],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      case HomeSection.nutritionCard:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _MiniBar(Color(0xFF8B5CF6)),
            SizedBox(height: 2),
            _MiniBar(Color(0xFF2BB6C4)),
          ],
        );
      case HomeSection.quickActions:
        return _dotRow(5, muted, 5);
      case HomeSection.habits:
        return _dotRow(6, muted, 5);
      case HomeSection.metricTrio:
        return _dotRow(3, muted, 7);
      case HomeSection.weeklyReport:
        return Container(
          height: 7,
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      case HomeSection.weekStrip:
        return Container(
          height: 4,
          decoration: BoxDecoration(
            color: muted,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case HomeSection.timeline:
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: muted,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case HomeSection.cycle:
        // Cycle card preview — a pink rounded block matching the feature
        // accent.
        return Container(
          height: 11,
          decoration: BoxDecoration(
            color: const Color(0xFFE5567B).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(3),
          ),
        );
    }
  }

  Widget _dotRow(int n, Color color, double dim) {
    return Row(
      children: [
        for (var i = 0; i < n; i++)
          Container(
            width: dim,
            height: dim,
            margin: const EdgeInsets.only(right: 2.5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}

class _MiniBar extends StatelessWidget {
  final Color color;
  const _MiniBar(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ============================================================ Floating pill

class _FloatingTabPill extends StatelessWidget {
  final TabController controller;
  final ThemeColors colors;

  const _FloatingTabPill({required this.controller, required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: c.elevated,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _segment(context, 'Customize', 0),
              _segment(context, 'Discover', 1),
            ],
          ),
        );
      },
    );
  }

  Widget _segment(BuildContext context, String label, int i) {
    final selected = controller.index == i;
    return GestureDetector(
      onTap: () => controller.animateTo(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? colors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
