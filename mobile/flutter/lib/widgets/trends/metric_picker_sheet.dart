import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/theme_colors.dart';
import '../../data/providers/trend_series_provider.dart';
import '../../data/services/haptic_service.dart';

/// =========================================================================
/// Metric picker — sectioned, searchable, collapsible (Wave 1 redesign)
/// =========================================================================
///
/// The Custom Trends catalog grew from ~30 to ~100 metrics. A flat list is
/// unusable at that size, so this picker:
///
///  * Groups metrics into collapsible CATEGORY sections (Body, Nutrition,
///    Micronutrients, Cardio, Workout, Activity, Wellbeing, Hormonal,
///    Glucose, Flexibility, Habits) — each with an icon + live count.
///  * Surfaces a RECENTLY-USED strip at the very top (persisted, max 6).
///  * Provides a SEARCH field that filters across every metric and, while
///    searching, flattens the result into one ranked list.
///  * Collapses the 38-strong Micronutrients section BY DEFAULT so it never
///    overwhelms — every other section opens expanded.
///  * Animates expand / collapse smoothly; adapts to light + dark; never
///    overflows (each row is a single line with an ellipsis-safe label).

/// SharedPreferences key for the user's recently-picked metrics.
const String _kRecentMetricsPrefsKey = 'trend_recent_metrics_v1';

/// Max recents surfaced at the top of the picker.
const int _kMaxRecents = 6;

/// Categories collapsed by default — large sections that would otherwise
/// dominate the picker on open.
const Set<TrendCategory> _kCollapsedByDefault = {
  TrendCategory.micronutrients,
};

/// Fixed section display order — keeps the picker scannable regardless of
/// enum declaration order.
const List<TrendCategory> _kCategoryOrder = [
  TrendCategory.body,
  TrendCategory.nutrition,
  TrendCategory.micronutrients,
  TrendCategory.cardio,
  TrendCategory.workout,
  TrendCategory.activity,
  TrendCategory.wellbeing,
  TrendCategory.hormonal,
  TrendCategory.glucose,
  TrendCategory.flexibility,
  TrendCategory.habits,
];

/// Records a metric pick into the persisted recently-used list (most-recent
/// first, deduped, capped). Best-effort — failures are swallowed.
Future<void> _recordRecentMetric(TrendMetric metric) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kRecentMetricsPrefsKey) ?? const [];
    final next = [metric.name, ...raw.where((n) => n != metric.name)]
        .take(_kMaxRecents)
        .toList();
    await prefs.setStringList(_kRecentMetricsPrefsKey, next);
  } catch (_) {/* non-fatal */}
}

/// Reads the persisted recently-used metrics, newest first.
Future<List<TrendMetric>> _loadRecentMetrics() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kRecentMetricsPrefsKey) ?? const [];
    final byName = {for (final m in TrendMetric.values) m.name: m};
    return [
      for (final n in raw)
        if (byName[n] case final m?) m,
    ];
  } catch (_) {
    return const [];
  }
}

/// Opens the sectioned metric-picker bottom sheet. [exclude] hides metrics
/// already plotted; [onPicked] fires with the chosen metric.
Future<void> showMetricPickerSheet({
  required BuildContext context,
  required Set<TrendMetric> exclude,
  required void Function(TrendMetric) onPicked,
}) {
  final colors = ThemeColors.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.background,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _MetricPickerSheet(
      exclude: exclude,
      onPicked: onPicked,
    ),
  );
}

class _MetricPickerSheet extends StatefulWidget {
  final Set<TrendMetric> exclude;
  final void Function(TrendMetric) onPicked;

  const _MetricPickerSheet({
    required this.exclude,
    required this.onPicked,
  });

  @override
  State<_MetricPickerSheet> createState() => _MetricPickerSheetState();
}

class _MetricPickerSheetState extends State<_MetricPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  /// Per-category expand state. Defaults large sections collapsed.
  final Map<TrendCategory, bool> _expanded = {
    for (final c in TrendCategory.values)
      c: !_kCollapsedByDefault.contains(c),
  };

  List<TrendMetric> _recents = const [];

  @override
  void initState() {
    super.initState();
    _loadRecentMetrics().then((r) {
      if (mounted) setState(() => _recents = r);
    });
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// All selectable (non-excluded) metrics for a category.
  List<TrendMetric> _metricsFor(TrendCategory c) => [
        for (final m in TrendMetric.values)
          if (m.category == c && !widget.exclude.contains(m)) m,
      ];

  /// Flat, ranked search hits across the whole catalog. Name prefix matches
  /// rank above substring matches; category-name matches are also allowed.
  List<TrendMetric> _searchHits() {
    final hits = <(TrendMetric, int)>[];
    for (final m in TrendMetric.values) {
      if (widget.exclude.contains(m)) continue;
      final name = m.displayName.toLowerCase();
      final cat = m.category.label.toLowerCase();
      int rank;
      if (name.startsWith(_query)) {
        rank = 0;
      } else if (name.contains(_query)) {
        rank = 1;
      } else if (cat.contains(_query)) {
        rank = 2;
      } else {
        continue;
      }
      hits.add((m, rank));
    }
    hits.sort((a, b) {
      final r = a.$2.compareTo(b.$2);
      return r != 0 ? r : a.$1.displayName.compareTo(b.$1.displayName);
    });
    return [for (final h in hits) h.$1];
  }

  void _pick(TrendMetric m) {
    HapticService.light();
    _recordRecentMetric(m);
    Navigator.pop(context);
    widget.onPicked(m);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final searching = _query.isNotEmpty;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (ctx, scrollCtrl) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: colors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text('Choose a metric',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary)),
            const SizedBox(height: 12),
            _searchField(colors),
            const SizedBox(height: 8),
            Expanded(
              child: searching
                  ? _searchResults(colors, scrollCtrl)
                  : _sectionedList(colors, scrollCtrl),
            ),
          ],
        );
      },
    );
  }

  // ── Search field ────────────────────────────────────────────────────────

  Widget _searchField(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: colors.elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search_rounded, size: 18, color: colors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(fontSize: 14, color: colors.textPrimary),
                cursorColor: colors.accent,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Search ${TrendMetric.values.length} metrics…',
                  hintStyle:
                      TextStyle(fontSize: 14, color: colors.textMuted),
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  FocusScope.of(context).unfocus();
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: colors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Flat search results ───────────────────────────────────────────────

  Widget _searchResults(ThemeColors colors, ScrollController ctrl) {
    final hits = _searchHits();
    if (hits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 40, color: colors.textMuted),
              const SizedBox(height: 10),
              Text('No metric matches “${_searchCtrl.text}”',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: colors.textMuted)),
            ],
          ),
        ),
      );
    }
    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Text('${hits.length} RESULTS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: colors.textMuted)),
        ),
        for (final m in hits) _metricRow(colors, m, showCategory: true),
      ],
    );
  }

  // ── Sectioned list ────────────────────────────────────────────────────

  Widget _sectionedList(ThemeColors colors, ScrollController ctrl) {
    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        if (_recents.isNotEmpty) ...[
          _recentsStrip(colors),
          const SizedBox(height: 14),
        ],
        for (final c in _kCategoryOrder)
          if (_metricsFor(c).isNotEmpty) _categorySection(colors, c),
      ],
    );
  }

  // ── Recently used ─────────────────────────────────────────────────────

  Widget _recentsStrip(ThemeColors colors) {
    final recents = [
      for (final m in _recents)
        if (!widget.exclude.contains(m)) m,
    ];
    if (recents.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Row(
            children: [
              Icon(Icons.history_rounded,
                  size: 14, color: colors.textMuted),
              const SizedBox(width: 6),
              Text('RECENTLY USED',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: colors.textMuted)),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final m in recents) _recentChip(colors, m)],
        ),
      ],
    );
  }

  Widget _recentChip(ThemeColors colors, TrendMetric m) {
    final color = m.accentColor;
    return GestureDetector(
      onTap: () => _pick(m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 7),
            Text(m.displayName,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary)),
          ],
        ),
      ),
    );
  }

  // ── Category section ──────────────────────────────────────────────────

  Widget _categorySection(ThemeColors colors, TrendCategory c) {
    final metrics = _metricsFor(c);
    final open = _expanded[c] ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        children: [
          // Header — tappable to expand / collapse.
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                HapticService.light();
                setState(() => _expanded[c] = !open);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 13),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(c.icon,
                          size: 17, color: colors.accent),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(c.label,
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${metrics.length}',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: colors.textMuted)),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          size: 22, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Body — animated expand / collapse.
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: open
                ? Column(
                    children: [
                      Divider(
                          height: 1,
                          thickness: 1,
                          color: colors.cardBorder),
                      for (var i = 0; i < metrics.length; i++) ...[
                        if (i > 0)
                          Divider(
                              height: 1,
                              thickness: 1,
                              indent: 14,
                              color: colors.cardBorder
                                  .withValues(alpha: 0.5)),
                        _metricRow(colors, metrics[i]),
                      ],
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  // ── Metric row ────────────────────────────────────────────────────────

  Widget _metricRow(
    ThemeColors colors,
    TrendMetric m, {
    bool showCategory = false,
  }) {
    final color = m.accentColor;
    final unit = m.unitOverride;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _pick(m),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              // Per-metric colour swatch — matches the chart line colour.
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary)),
                    if (showCategory) ...[
                      const SizedBox(height: 2),
                      Text(m.category.label,
                          style: TextStyle(
                              fontSize: 11, color: colors.textMuted)),
                    ],
                  ],
                ),
              ),
              if (unit != null && unit.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(unit,
                    style: TextStyle(
                        fontSize: 12, color: colors.textMuted)),
              ],
              const SizedBox(width: 8),
              Icon(Icons.add_circle_outline_rounded,
                  size: 18, color: colors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
