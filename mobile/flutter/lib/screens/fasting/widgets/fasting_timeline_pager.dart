import 'package:flutter/material.dart';

import '../../../core/theme/theme_colors.dart';
import 'fasting_stage_model.dart';

import '../../../l10n/generated/app_localizations.dart';
/// A single page in the swipeable fasting timeline.
///
/// Pages come from two sources: the 7 live metabolic stages and the
/// multi-day educational marks (24h → 30d). This is a flat, display-ready
/// representation so the pager doesn't branch on source.
class _TimelinePage {
  final Color color;
  final IconData icon;
  final String hourLabel;
  final String title;
  final String tagline;
  final String body;
  final List<String> milestones;
  final String? safety;

  const _TimelinePage({
    required this.color,
    required this.icon,
    required this.hourLabel,
    required this.title,
    required this.tagline,
    required this.body,
    required this.milestones,
    this.safety,
  });
}

/// Horizontally swipeable replacement for the Guide's long-form fasting
/// timeline. One stage per page; swipe left/right to move through the
/// 0h → 30-day journey.
///
/// Affordances:
///  - an at-a-glance segmented progress track (each segment = one page),
///  - page-indicator dots,
///  - prev / next arrow buttons,
///  - live scale + fade as pages settle.
class FastingTimelinePager extends StatefulWidget {
  const FastingTimelinePager({super.key});

  @override
  State<FastingTimelinePager> createState() => _FastingTimelinePagerState();
}

class _FastingTimelinePagerState extends State<FastingTimelinePager> {
  late final PageController _controller;

  /// Fractional current page — drives the scale/fade settle animation and
  /// the indicator. Tracked continuously as the user drags.
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92)
      ..addListener(_onScroll);
  }

  void _onScroll() {
    final p = _controller.page;
    if (p != null && p != _page) {
      setState(() => _page = p);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Build the flat list of timeline pages: live stages first, then the
  /// multi-day educational marks.
  List<_TimelinePage> _buildPages() {
    final pages = <_TimelinePage>[];
    final stages = FastingStage.values;

    for (var i = 0; i < stages.length; i++) {
      final stage = stages[i];
      pages.add(
        _TimelinePage(
          color: stage.color,
          icon: stage.icon,
          hourLabel: i == stages.length - 1
              ? '${stage.startHour}h+'
              : '${stage.startHour}–${stage.endHour}h',
          title: stage.name,
          tagline: stage.tagline,
          body: stage.description,
          milestones: [
            for (final m in stage.milestones) '${m.hourOffset}h — ${m.text}',
          ],
        ),
      );
    }

    for (final mark in FastingStage.educationalMilestones) {
      pages.add(
        _TimelinePage(
          color: mark.color,
          icon: Icons.timelapse_rounded,
          hourLabel: mark.label,
          title: 'Extended fast · ${mark.label}',
          tagline: AppLocalizations.of(context).fastingTimelinePagerAdvancedTerritory,
          body: mark.effect,
          milestones: const [],
          safety: mark.safety,
        ),
      );
    }

    return pages;
  }

  void _goTo(int index, int count) {
    if (index < 0 || index >= count) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final pages = _buildPages();
    final current = _page.round().clamp(0, pages.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── At-a-glance segmented progress track ───────────────────────
        _SegmentedTrack(
          pages: pages,
          page: _page,
          onTapSegment: (i) => _goTo(i, pages.length),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            'Stage ${current + 1} of ${pages.length}  ·  ${pages[current].hourLabel}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Swipeable pages ────────────────────────────────────────────
        SizedBox(
          height: 360,
          child: PageView.builder(
            controller: _controller,
            itemCount: pages.length,
            itemBuilder: (context, index) {
              // Distance of this page from the settled centre (0 = centred).
              final delta = (_page - index).abs().clamp(0.0, 1.0);
              final scale = 1.0 - 0.06 * delta;
              final opacity = 1.0 - 0.45 * delta;
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: _TimelinePageCard(page: pages[index]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // ── Prev / dots / next affordance row ──────────────────────────
        Row(
          children: [
            _NavArrow(
              icon: Icons.chevron_left_rounded,
              enabled: current > 0,
              onTap: () => _goTo(current - 1, pages.length),
            ),
            Expanded(
              child: _Dots(count: pages.length, page: _page),
            ),
            _NavArrow(
              icon: Icons.chevron_right_rounded,
              enabled: current < pages.length - 1,
              onTap: () => _goTo(current + 1, pages.length),
            ),
          ],
        ),
      ],
    );
  }
}

/// Segmented mini progress bar — one segment per timeline page. The segments
/// up to and including the current page fill with that page's accent color;
/// the active segment is widened slightly so the user feels where they are.
class _SegmentedTrack extends StatelessWidget {
  final List<_TimelinePage> pages;
  final double page;
  final ValueChanged<int> onTapSegment;

  const _SegmentedTrack({
    required this.pages,
    required this.page,
    required this.onTapSegment,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final current = page.round();

    return Row(
      children: [
        for (var i = 0; i < pages.length; i++)
          Expanded(
            flex: i == current ? 16 : 10,
            child: GestureDetector(
              onTap: () => onTapSegment(i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  height: i == current ? 7 : 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: i <= current
                        ? pages[i].color.withValues(
                            alpha: i == current ? 1.0 : 0.55)
                        : colors.cardBorder,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Page-indicator dots — the active dot stretches into a pill and adopts the
/// active page's color, interpolated smoothly during a drag.
class _Dots extends StatelessWidget {
  final int count;
  final double page;

  const _Dots({required this.count, required this.page});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final active = page.round().clamp(0, count - 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 20 : 7,
            height: 7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: i == active
                  ? colors.accent
                  : colors.textMuted.withValues(alpha: 0.35),
            ),
          ),
      ],
    );
  }
}

/// Round prev/next arrow button. Dims + disables at the ends of the journey.
class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.3,
      child: Material(
        color: colors.surface,
        shape: CircleBorder(
          side: BorderSide(color: colors.cardBorder),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 22, color: colors.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// A single timeline page card — keeps the stage's icon, name, hour range,
/// description and milestones, styled to match the Guide's other cards.
class _TimelinePageCard extends StatelessWidget {
  final _TimelinePage page;

  const _TimelinePageCard({required this.page});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final color = page.color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: colors.isDark ? 0.18 : 0.11),
              color.withValues(alpha: colors.isDark ? 0.05 : 0.03),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: icon badge + title + hour pill.
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.18),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(page.icon, size: 23, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        page.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        page.tagline,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    page.hourLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Scrollable body so long stages never overflow the fixed page.
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      page.body,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: colors.textSecondary,
                      ),
                    ),
                    if (page.milestones.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      for (final m in page.milestones)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  m,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.4,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    if (page.safety != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: colors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 16, color: colors.warning),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                page.safety!,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
