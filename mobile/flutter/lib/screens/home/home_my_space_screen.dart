import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_colors.dart';
import '../../core/widgets/line_icon.dart';
import '../../data/providers/home_sections_provider.dart';
import '../../data/providers/metric_layout_provider.dart';
import '../../data/providers/metric_value_provider.dart';
import '../../data/providers/saved_trends_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_sheet.dart';
import 'widgets/home/metric_summary_deck.dart' show MetricRowViz;
import 'widgets/ring_catalog.dart';

import '../../l10n/generated/app_localizations.dart';

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
  late final TabController _tab = TabController(length: 3, vsync: this);

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
          AppLocalizations.of(context).programMenuButtonMySpace,
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
                AppLocalizations.of(context).trophyFilterReset,
                style: TextStyle(color: c.accent, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tab,
            children: const [_MetricsTab(), _CustomizeTab(), _DiscoverTab()],
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
          style: TextStyle(fontSize: 13, height: 1.45, color: c.textSecondary),
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
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 22,
                  color: c.textMuted,
                ),
              ),
            ),
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (visible ? c.accent : c.textMuted).withValues(
                  alpha: 0.14,
                ),
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
                            horizontal: 6,
                            vertical: 2,
                          ),
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
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
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
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: c.textMuted,
                ),
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
          AppLocalizations.of(context).homeMySpaceStartFromAReady,
          style: TextStyle(fontSize: 13, height: 1.45, color: c.textSecondary),
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
                        AppLocalizations.of(context).homeMySpaceCurrentLayout,
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
                        child: Text(
                          AppLocalizations.of(context).setAdjustmentSheetApply,
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
      case HomeSection.strainCoach:
        // Small flame-tinted chip — visual stand-in for the intensity pill.
        return Container(
          height: 9,
          width: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFE89A3E).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      case HomeSection.coachHero:
        // Sparkle + 2 thin lines — visual stand-in for the coach insight card.
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.accent.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 3),
            _MiniBar(muted),
            const SizedBox(height: 2),
            _MiniBar(muted),
          ],
        );
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
      case HomeSection.readiness:
        // Recovery Readiness preview — green traffic-light dot + a thin
        // intensity-bar; visually compact in the editor strip.
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 11,
              height: 11,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 28,
              height: 6,
              decoration: BoxDecoration(
                color: muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
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
              _segment(context, 'Metrics', 0),
              _segment(context, 'Sections', 1),
              _segment(context, 'Discover', 2),
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
        width: 98,
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

// Saved custom-trend rows + an add button for the Metrics tab.
class _SavedTrendsList extends ConsumerWidget {
  const _SavedTrendsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.colors(context);
    final saved = ref.watch(savedTrendsProvider).valueOrNull ?? const [];
    if (saved.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          'No custom trends yet. Build one to compare any metrics.',
          style: TextStyle(fontSize: 12, color: c.textMuted),
        ),
      );
    }
    return Column(
      children: [
        for (final t in saved)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => context.push('/trends/custom', extra: t.primary),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: c.elevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insights_rounded, size: 17, color: c.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      t.range.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AddTrendButton extends StatelessWidget {
  final ThemeColors colors;
  const _AddTrendButton({required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/trends/custom');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.accent.withValues(alpha: 0.4)),
        ),
        child: Text(
          '+ Add custom trend',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: c.accent,
          ),
        ),
      ),
    );
  }
}

// ============================================================ Metrics tab
//
// Direction C — edits the home metric deck: per-metric size (S/W/L), chart
// style, color and date range, plus show/hide. Every row shows a live
// mini-graph + number (see [MetricRowViz] + [metricValueProvider]). The Today
// score's contributors are core and can't be hidden. Reordering stays in the
// home customize-rings sheet.

const List<int> _kMetricSwatches = [
  0xFFEC8B2C,
  0xFF3E8FD0,
  0xFF3FA66B,
  0xFF8B5CF6,
  0xFFE5544D,
  0xFF06B6D4,
  0xFFA855F7,
  0xFF64748B,
];

class _MetricsTab extends ConsumerWidget {
  const _MetricsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 120),
      child: MetricsSettingsBody(),
    );
  }
}

/// The shared body of the metric-customization surface — used by both the
/// My Space "Metrics" tab and the glassmorphic settings sheet opened from the
/// home deck's tune button ([showMetricSettingsSheet]). Each row carries a
/// live mini-graph + current number ([MetricRowViz] + [metricValueProvider]);
/// the SHOWING set is drag-reorderable (long-press); core metrics are pinned.
class MetricsSettingsBody extends ConsumerWidget {
  /// When true (glass sheet), the intro paragraph is dropped — the sheet has
  /// its own title row.
  final bool compact;
  const MetricsSettingsBody({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.colors(context);
    final visible = ref.watch(ringVisibilityProvider);
    final hidden = ref.watch(hiddenRingsProvider);
    final core = visible.where((k) => kRingCatalog[k]!.isCore).toList();
    final showing = visible.where((k) => !kRingCatalog[k]!.isCore).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          Text(
            'Resize, restyle, recolor or hide each metric on your home deck. '
            'Drag to reorder; tap the gear to change its chart and date range.',
            style: TextStyle(fontSize: 13, height: 1.45, color: c.textSecondary),
          ),
          const SizedBox(height: 16),
        ],
        _label(c, 'CORE'),
        for (final k in core) _MetricRow(kind: k, colors: c, core: true),
        if (showing.isNotEmpty) ...[
          const SizedBox(height: 18),
          _label(c, 'SHOWING'),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: showing.length,
            onReorder: (oldIndex, newIndex) {
              HapticService.light();
              final reordered = List<RingKind>.of(showing);
              final idx = newIndex > oldIndex ? newIndex - 1 : newIndex;
              final moved = reordered.removeAt(oldIndex);
              reordered.insert(idx, moved);
              // Core stays pinned at the front; persist core + reordered tail.
              ref
                  .read(ringVisibilityProvider.notifier)
                  .setOrder([...core, ...reordered]);
            },
            itemBuilder: (context, i) {
              final k = showing[i];
              // Long-press anywhere on the row to drag — no extra handle, so
              // the rich trailing controls (size/gear/toggle) never overflow.
              return ReorderableDelayedDragStartListener(
                key: ValueKey('msrow_${k.id}'),
                index: i,
                child: _MetricRow(kind: k, colors: c),
              );
            },
          ),
        ],
        if (hidden.isNotEmpty) ...[
          const SizedBox(height: 18),
          _label(c, 'ADD METRIC'),
          for (final k in hidden) _MetricRow(kind: k, colors: c, off: true),
        ],
        const SizedBox(height: 18),
        _label(c, 'CUSTOM TRENDS'),
        const _SavedTrendsList(),
        const SizedBox(height: 10),
        _AddTrendButton(colors: c),
      ],
    );
  }

  Widget _label(ThemeColors c, String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: c.textMuted,
      ),
    ),
  );
}

class _MetricRow extends ConsumerWidget {
  final RingKind kind;
  final ThemeColors colors;
  final bool core;
  final bool off;
  const _MetricRow({
    required this.kind,
    required this.colors,
    this.core = false,
    this.off = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = colors;
    final m = ref.watch(metricValueProvider(kind));
    final cfg = ref.watch(metricLayoutProvider.notifier).configFor(kind);
    final layout = ref.read(metricLayoutProvider.notifier);
    final rings = ref.read(ringVisibilityProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: off ? c.textMuted.withValues(alpha: 0.4) : m.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                kRingCatalog[kind]!.label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: off ? c.textMuted : c.textPrimary,
                ),
              ),
            ),
            MetricRowViz(kind: kind),
            const SizedBox(width: 8),
            SizedBox(
              width: 52,
              child: Text(
                m.isEmpty
                    ? '—'
                    : '${m.headline}${m.unit.isNotEmpty ? ' ${m.unit}' : ''}',
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: off ? c.textMuted : c.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (off)
              _Toggle(
                on: false,
                color: c,
                onTap: () {
                  HapticService.light();
                  rings.addRing(kind);
                },
              )
            else if (core)
              _CorePill(c)
            else ...[
              _SizeChips(
                current: cfg.size,
                color: c,
                onPick: (s) {
                  HapticService.light();
                  layout.setSize(kind, s);
                },
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showMetricEditor(context, kind),
                child: Icon(
                  Icons.settings_outlined,
                  size: 18,
                  color: c.textMuted,
                ),
              ),
              const SizedBox(width: 4),
              _Toggle(
                on: true,
                color: c,
                onTap: () {
                  HapticService.light();
                  rings.removeRing(kind);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CorePill extends StatelessWidget {
  final ThemeColors c;
  const _CorePill(this.c);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: c.accent.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      'CORE',
      style: TextStyle(
        fontSize: 8.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        color: c.accent,
      ),
    ),
  );
}

class _SizeChips extends StatelessWidget {
  final MetricSize current;
  final ThemeColors color;
  final ValueChanged<MetricSize> onPick;
  const _SizeChips({
    required this.current,
    required this.color,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final c = color;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in MetricSize.values)
            GestureDetector(
              onTap: () => onPick(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: current == s ? c.textPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  s.shortLabel,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: current == s ? c.background : c.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool on;
  final ThemeColors color;
  final VoidCallback onTap;
  const _Toggle({required this.on, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 24,
        decoration: BoxDecoration(
          color: on ? c.accent : c.cardBorder,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 140),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(2.5),
            child: Container(
              width: 19,
              height: 19,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _showMetricEditor(BuildContext context, RingKind kind) {
  showGlassSheet<void>(
    context: context,
    builder: (ctx) => GlassSheet(child: _MetricEditor(kind: kind)),
  );
}

class _MetricEditor extends ConsumerWidget {
  final RingKind kind;
  const _MetricEditor({required this.kind});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.colors(context);
    final cfg = ref.watch(metricLayoutProvider.notifier).configFor(kind);
    final layout = ref.read(metricLayoutProvider.notifier);
    // ignore: deprecated_member_use
    final selectedColor = cfg.colorOverride ?? kRingCatalog[kind]!.color.value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kRingCatalog[kind]!.label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _editLabel(c, 'COLOR'),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  layout.setColor(kind, null);
                },
                child: Text(
                  'Default',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: c.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final sw in _kMetricSwatches)
                GestureDetector(
                  onTap: () {
                    HapticService.light();
                    layout.setColor(kind, sw);
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color(sw),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: selectedColor == sw
                            ? c.textPrimary
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _editLabel(c, 'CHART'),
          const SizedBox(height: 8),
          _chips<MetricChart>(
            c,
            values: MetricChart.values,
            current: cfg.chart,
            labelOf: (v) => v.label,
            onPick: (v) {
              HapticService.light();
              layout.setChart(kind, v);
            },
          ),
          const SizedBox(height: 18),
          _editLabel(c, 'RANGE'),
          const SizedBox(height: 8),
          _chips<MetricRange>(
            c,
            values: MetricRange.values,
            current: cfg.range,
            labelOf: (v) => v.label,
            onPick: (v) {
              HapticService.light();
              layout.setRange(kind, v);
            },
          ),
        ],
      ),
    );
  }

  Widget _editLabel(ThemeColors c, String t) => Text(
    t,
    style: TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
      color: c.textMuted,
    ),
  );

  Widget _chips<T>(
    ThemeColors c, {
    required List<T> values,
    required T current,
    required String Function(T) labelOf,
    required ValueChanged<T> onPick,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          GestureDetector(
            onTap: () => onPick(v),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: v == current ? c.textPrimary : c.surface,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: v == current ? c.textPrimary : c.cardBorder,
                ),
              ),
              child: Text(
                labelOf(v),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: v == current ? c.background : c.textMuted,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
