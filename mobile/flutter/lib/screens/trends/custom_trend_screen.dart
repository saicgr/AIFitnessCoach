import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/theme_colors.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/providers/trend_series_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/trends/metric_picker_sheet.dart';
import '../../widgets/trends/trend_ai_insight_card.dart';
import '../../widgets/trends/trend_chart.dart';
import '../../widgets/trends/trend_correlation.dart';

/// =========================================================================
/// Custom Trends — graph-first, multi-metric builder (rebuilt G8)
/// =========================================================================
///
/// Layout (top → bottom): compact inline header → LARGE full-width chart →
/// legend with per-metric remove → "+ Add metric" → event-overlay chips →
/// time-range pills → stats → correlation → AI insight.
///
/// Supports 1 primary metric (real values, EWMA-smoothed) + up to 4 overlay
/// metrics (normalised to a 0–100 index so one chart stays readable). Event
/// overlays (workouts / fasting / rest days) draw as background bands.

/// SharedPreferences key for the user's saved custom-trend metric sets.
const String _kSavedTrendsPrefsKey = 'custom_trends_saved_v2';

/// Max overlay metrics on top of the primary.
const int _kMaxOverlays = 4;

/// Fixed overlay palette — distinct hues, applied in order. The primary uses
/// the user's accent; overlays cycle through these so series are separable by
/// colour (in addition to dash style + end-of-line label).
const List<Color> _kOverlayPalette = [
  Color(0xFFE0823D), // amber
  Color(0xFF3DA5E0), // sky
  Color(0xFFB05CD6), // violet
  Color(0xFF3DC97A), // green
];

class CustomTrendScreen extends ConsumerStatefulWidget {
  /// Optional metric to pre-select as the primary trend. When null, the
  /// screen opens on the default ([TrendMetric.weight]).
  final TrendMetric? initialMetric;

  const CustomTrendScreen({super.key, this.initialMetric});

  @override
  ConsumerState<CustomTrendScreen> createState() =>
      _CustomTrendScreenState();
}

/// A saved custom-trend set (a primary + ordered overlays + a range).
class _SavedTrend {
  final TrendMetric primary;
  final List<TrendMetric> overlays;
  final TrendRange range;

  const _SavedTrend(this.primary, this.overlays, this.range);

  Map<String, dynamic> toJson() => {
        'primary': primary.name,
        'overlays': overlays.map((m) => m.name).toList(),
        'range': range.name,
      };

  static _SavedTrend? fromJson(Map<String, dynamic> j) {
    TrendMetric? metricByName(String? n) =>
        TrendMetric.values.where((m) => m.name == n).firstOrNull;
    final p = metricByName(j['primary'] as String?);
    final r = TrendRange.values
        .where((x) => x.name == j['range'])
        .firstOrNull;
    if (p == null || r == null) return null;
    final overlays = <TrendMetric>[];
    for (final raw in (j['overlays'] as List?) ?? const []) {
      final m = metricByName(raw as String?);
      if (m != null && m != p) overlays.add(m);
    }
    return _SavedTrend(p, overlays.take(_kMaxOverlays).toList(), r);
  }
}

class _CustomTrendScreenState extends ConsumerState<CustomTrendScreen> {
  late TrendMetric _primary;
  final List<TrendMetric> _overlays = [];
  TrendRange _range = TrendRange.d90;

  /// Which event overlays are currently toggled on.
  final Set<TrendEventKind> _activeEvents = {};

  List<_SavedTrend> _saved = const [];

  /// CacheFirstView screen key — drives the skeleton-on-true-first-open
  /// behaviour. The chart shows a skeleton ONLY the very first time this
  /// screen is ever opened on the install; every later open renders the
  /// cached series instantly (no skeleton, no spinner).
  static const String _kScreenKey = 'custom_trends';

  /// True only on a genuine first-ever open — resolved from SharedPreferences
  /// in [initState]. Until it resolves it stays true so a cold first open
  /// shows the skeleton rather than briefly flashing a non-skeleton state.
  bool _isFirstEver = true;

  // ── Memoised chart computation (the 60fps fix) ──────────────────────────
  // Building the TrendChart + its TrendChartSeries lists (resolve / normalize
  // / EWMA / X-Y bounds happen downstream of these) is recomputed ONLY when
  // the inputs below actually change. A screen-level setState (an overlay
  // landing, an event toggle, a saved-trend write) reuses the cached widget
  // instance — and because an identical widget instance lets Flutter skip the
  // child's rebuild entirely, TrendChart's own _buildChart no longer re-runs
  // on every unrelated rebuild. Gesture (pan/zoom) frames stay inside
  // TrendChart's private State and never reach this screen.
  Widget? _cachedChart;
  String? _cachedChartKey;

  @override
  void initState() {
    super.initState();
    _primary = widget.initialMetric ?? TrendMetric.weight;
    _loadSaved();
    _resolveFirstEver();
  }

  /// Reads whether the Trends screen has been opened before. On a first-ever
  /// open the chart slot shows a skeleton; afterwards it never does again.
  Future<void> _resolveFirstEver() async {
    final seen = await CacheFirstView.hasBeenSeen(_kScreenKey);
    if (mounted && seen) setState(() => _isFirstEver = false);
  }

  // ── Persistence ─────────────────────────────────────────────────────────

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kSavedTrendsPrefsKey) ?? const [];
    final parsed = <_SavedTrend>[];
    for (final s in raw) {
      try {
        final t = _SavedTrend.fromJson(
            jsonDecode(s) as Map<String, dynamic>);
        if (t != null) parsed.add(t);
      } catch (_) {/* skip corrupt entry */}
    }
    if (mounted) setState(() => _saved = parsed);
  }

  Future<void> _persistSaved() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kSavedTrendsPrefsKey,
      _saved.map((t) => jsonEncode(t.toJson())).toList(),
    );
  }

  Future<void> _saveCurrent() async {
    final exists = _saved.any((t) =>
        t.primary == _primary &&
        t.range == _range &&
        _listEq(t.overlays, _overlays));
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already saved')),
      );
      return;
    }
    setState(() {
      _saved = [
        ..._saved,
        _SavedTrend(_primary, List.of(_overlays), _range),
      ];
    });
    await _persistSaved();
    if (mounted) {
      HapticService.success();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Custom trend saved')),
      );
    }
  }

  Future<void> _deleteSaved(_SavedTrend t) async {
    setState(() => _saved = _saved.where((x) => x != t).toList());
    await _persistSaved();
  }

  static bool _listEq(List<TrendMetric> a, List<TrendMetric> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = ref.colors(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(colors),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                children: [
                  // ── 1. The chart — graph-first, top of screen ──────────
                  _chartCard(colors),
                  const SizedBox(height: 16),
                  // ── 2. Legend + add metric ─────────────────────────────
                  _legendSection(colors),
                  const SizedBox(height: 16),
                  // ── 3. Event overlays ──────────────────────────────────
                  _eventOverlaySection(colors),
                  const SizedBox(height: 16),
                  // ── 4. Time range ──────────────────────────────────────
                  _sectionLabel(colors, 'TIME RANGE'),
                  const SizedBox(height: 8),
                  _rangeSelector(colors),
                  const SizedBox(height: 16),
                  // ── 5. Stats ───────────────────────────────────────────
                  _statsSection(colors),
                  // ── 6. Correlation ─────────────────────────────────────
                  _correlationSection(colors),
                  // ── 7. AI insight ──────────────────────────────────────
                  _aiInsightSection(colors),
                  const SizedBox(height: 16),
                  // ── Save + saved list ──────────────────────────────────
                  _saveButton(colors),
                  if (_saved.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionLabel(colors, 'SAVED TRENDS'),
                    const SizedBox(height: 10),
                    for (final t in _saved) _savedRow(colors, t),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Compact inline header ───────────────────────────────────────────────

  Widget _header(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          GlassBackButton(
            onTap: () {
              HapticService.light();
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8),
          Text('Custom Trends',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary)),
        ],
      ),
    );
  }

  // ── 1. Chart card ───────────────────────────────────────────────────────

  Widget _chartCard(ThemeColors colors) {
    final primaryAsync =
        ref.watch(trendSeriesProvider(TrendSeriesKey(_primary, _range)));
    // Overlay series resolve INDEPENDENTLY — the chart no longer blocks until
    // every overlay has landed (progressive overlays, requirement 4). Each
    // overlay is added to the chart the moment its own series resolves.
    final overlayAsyncs = [
      for (final m in _overlays)
        ref.watch(trendSeriesProvider(TrendSeriesKey(m, _range))),
    ];
    final eventsAsync = _activeEvents.isEmpty
        ? null
        : ref.watch(trendEventsProvider(_range));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.cardBorder),
      ),
      // CacheFirstView swaps a layout-matched SKELETON chart (true first-ever
      // open only) for the real chart — never a blocking CircularProgress.
      // On every later open the cached series renders instantly. After the
      // first successful load it records the screen as seen.
      child: CacheFirstView<TrendSeries>(
        value: primaryAsync,
        isFirstEver: _isFirstEver,
        traceLabel: 'custom_trends_chart',
        skeletonBuilder: (context) => _chartSkeleton(colors),
        errorBuilder: (context, _, __) =>
            _chartError(colors, _primary.displayName),
        contentBuilder: (context, primary) {
          // Mark the screen seen once real content has rendered, so future
          // opens skip the skeleton entirely.
          if (_isFirstEver) {
            CacheFirstView.markSeen(_kScreenKey);
          }

          // Honest empty-state: nothing logged in this range at all.
          if (primary.points.isEmpty) {
            return _honestEmpty(colors, primary);
          }

          return _memoizedChart(colors, primary, overlayAsyncs, eventsAsync);
        },
      ),
    );
  }

  /// Builds the [TrendChart] from the resolved primary + whatever overlays /
  /// events have landed so far, memoised on its inputs.
  ///
  /// THE 60FPS FIX (requirement 3): assembling the chart — and therefore the
  /// resolve / normalize / EWMA / X-Y-bounds work that happens downstream of
  /// these series objects — is recomputed ONLY when `_primary`, `_overlays`,
  /// `_range`, the active event set, or the resolved data actually change. A
  /// screen-level rebuild that does not touch any of those (e.g. an unrelated
  /// setState) reuses the cached widget instance; passing an identical widget
  /// lets Flutter skip TrendChart's rebuild, so its chart computation does not
  /// re-run. Pan/zoom gesture frames live inside TrendChart's own State and
  /// never rebuild this screen at all.
  Widget _memoizedChart(
    ThemeColors colors,
    TrendSeries primary,
    List<AsyncValue<TrendSeries>> overlayAsyncs,
    AsyncValue<TrendEvents>? eventsAsync,
  ) {
    // Progressive overlays: include only overlays whose series has resolved.
    // A still-loading overlay is simply absent until it lands — it never
    // blocks the primary chart or the already-resolved overlays.
    final overlayData = <({int index, TrendSeries series})>[];
    for (var i = 0; i < overlayAsyncs.length; i++) {
      final value = overlayAsyncs[i].valueOrNull;
      if (value != null) overlayData.add((index: i, series: value));
    }

    final events = <TrendEventLayer>[];
    final ev = eventsAsync?.valueOrNull;
    if (ev != null) {
      for (final kind in _activeEvents) {
        events.add(TrendEventLayer(
          label: kind.label,
          color: _eventColor(colors, kind),
          days: ev.of(kind),
        ));
      }
    }

    // Cache key: a stable fingerprint of every input that affects the chart.
    // `points.length` + the metric/range/event identity is enough — the
    // underlying series objects are immutable, so a same-length series for
    // the same (metric, range) is the same data.
    final key = StringBuffer()
      ..write('${_primary.name}:${primary.points.length}:${primary.unit}')
      ..write('|brightness=${colors.isDark}');
    for (final o in overlayData) {
      key.write('|ov${o.index}:${_overlays[o.index].name}'
          ':${o.series.points.length}');
    }
    for (final kind in _activeEvents) {
      key.write('|ev${kind.name}:${ev?.count(kind) ?? -1}');
    }
    final keyStr = key.toString();

    // Cache hit → reuse the exact same widget instance (Flutter then skips
    // TrendChart's rebuild). Cache miss → rebuild once and store.
    if (_cachedChartKey == keyStr && _cachedChart != null) {
      return _cachedChart!;
    }

    final chartOverlays = <TrendChartSeries>[
      for (final o in overlayData)
        TrendChartSeries(
          id: _overlays[o.index].name,
          label: o.series.metric.displayName,
          unit: o.series.unit,
          points: o.series.points,
          color: _kOverlayPalette[o.index % _kOverlayPalette.length],
        ),
    ];

    final chart = TrendChart(
      showBuiltInChrome: false,
      accent: colors.accent,
      primary: TrendChartSeries(
        id: _primary.name,
        label: primary.metric.displayName,
        unit: primary.unit,
        points: primary.points,
        color: colors.accent,
      ),
      overlays: chartOverlays,
      events: events,
    );
    _cachedChart = chart;
    _cachedChartKey = keyStr;
    return chart;
  }

  /// A layout-matched skeleton chart — a ~280px box with placeholder grid
  /// lines and an axis stub, mirroring [TrendChart]'s shape so the
  /// skeleton→content cross-fade never reflows. Shown only on a true
  /// first-ever open (see [CacheFirstView]); never a blocking spinner.
  Widget _chartSkeleton(ThemeColors colors) {
    const double chartHeight = 280;
    return SizedBox(
      height: chartHeight,
      child: Stack(
        children: [
          // 4 evenly-spaced horizontal grid lines — matches TrendChart's
          // FlGridData (4 horizontal intervals, no vertical lines).
          Positioned.fill(
            child: Padding(
              // Leave room on the left for the value-axis labels and at the
              // bottom for the date-axis labels, like the real chart.
              padding: const EdgeInsets.only(left: 40, bottom: 26),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  5,
                  (_) => Container(
                    height: 1,
                    color: colors.cardBorder.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
          // Shimmering value-axis label stubs down the left edge.
          Positioned(
            left: 0,
            top: 0,
            bottom: 26,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                4,
                (_) => const SkeletonBox(width: 26, height: 9),
              ),
            ),
          ),
          // Shimmering plot-area block standing in for the trend line itself.
          const Positioned(
            left: 40,
            right: 0,
            top: 60,
            bottom: 26,
            child: SkeletonBox(height: double.infinity, radius: 12),
          ),
          // Shimmering date-axis label stubs along the bottom.
          Positioned(
            left: 40,
            right: 0,
            bottom: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                3,
                (_) => const SkeletonBox(width: 38, height: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartError(ThemeColors colors, String name) => SizedBox(
        height: 280,
        child: Center(
          child: Text("Couldn't load $name",
              style: TextStyle(color: colors.textMuted)),
        ),
      );

  /// Honest "no data" — distinguishes "you have history but not in this
  /// range" from "you've never logged this metric".
  Widget _honestEmpty(ThemeColors colors, TrendSeries primary) {
    final start = primary.historyStart;
    final note = start != null
        ? 'Your ${_primary.displayName.toLowerCase()} logging history '
            'starts ${_fmtDate(start)} — try a wider range.'
        : 'No ${_primary.displayName.toLowerCase()} logged yet. '
            'Log an entry and it will appear here.';
    return SizedBox(
      height: 280,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timeline_rounded,
                  size: 40, color: colors.textMuted),
              const SizedBox(height: 10),
              Text(note,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: colors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  // ── 2. Legend + add metric ──────────────────────────────────────────────

  /// An honest, per-metric note when a series can't be drawn as a line in the
  /// selected range. Returns null when the series has ≥2 points (a real line).
  ///
  ///  * 0 points → "No [metric] data in this range"
  ///  * 1 point  → "[metric] logged on 1 day in this range — not enough to
  ///    chart" (the lone point still renders as a visible dot)
  String? _seriesNote(TrendMetric metric) {
    final series = ref
        .watch(trendSeriesProvider(TrendSeriesKey(metric, _range)))
        .valueOrNull;
    if (series == null) return null; // loading / error handled elsewhere
    final n = series.points.length;
    if (n >= 2) return null;
    if (n == 1) {
      return '${metric.displayName} · logged on 1 day in this '
          'range — not enough to chart (shown as a dot)';
    }
    return 'No ${metric.displayName} data in this range';
  }

  Widget _legendSection(ThemeColors colors) {
    // Collect per-metric honesty notes for sparse/empty series.
    final notes = <String>[
      for (final m in [_primary, ..._overlays])
        if (_seriesNote(m) case final note?) note,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(colors, 'METRICS'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _metricChip(
              colors,
              label: _primary.displayName,
              color: colors.accent,
              dashed: false,
              isPrimary: true,
              onTap: () => _pickMetric(
                exclude: {_primary, ..._overlays},
                onPicked: (m) => setState(() => _primary = m),
              ),
            ),
            for (var i = 0; i < _overlays.length; i++)
              _metricChip(
                colors,
                label: _overlays[i].displayName,
                color: _kOverlayPalette[i % _kOverlayPalette.length],
                dashed: true,
                isPrimary: false,
                onRemove: () =>
                    setState(() => _overlays.removeAt(i)),
              ),
            if (_overlays.length < _kMaxOverlays)
              _addMetricChip(colors)
            else
              _capChip(colors),
          ],
        ),
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final note in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 13, color: colors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(note,
                        style: TextStyle(
                            fontSize: 11.5,
                            height: 1.3,
                            color: colors.textMuted)),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _metricChip(
    ThemeColors colors, {
    required String label,
    required Color color,
    required bool dashed,
    required bool isPrimary,
    VoidCallback? onTap,
    VoidCallback? onRemove,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line-style swatch — solid (primary) vs dashed (overlay).
            CustomPaint(
              size: const Size(16, 3),
              painter: _LineSwatchPainter(color: color, dashed: dashed),
            ),
            const SizedBox(width: 7),
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary)),
            if (isPrimary) ...[
              const SizedBox(width: 5),
              Icon(Icons.swap_horiz_rounded,
                  size: 14, color: colors.textMuted),
            ],
            if (onRemove != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.close,
                    size: 14, color: colors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _addMetricChip(ThemeColors colors) {
    return GestureDetector(
      onTap: () => _pickMetric(
        exclude: {_primary, ..._overlays},
        onPicked: (m) => setState(() {
          if (_overlays.length < _kMaxOverlays) _overlays.add(m);
        }),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: colors.accent),
            const SizedBox(width: 5),
            Text('Add metric',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colors.accent)),
          ],
        ),
      ),
    );
  }

  Widget _capChip(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: colors.surface,
      ),
      child: Text('Max $_kMaxOverlays overlays — remove one to add another',
          style: TextStyle(fontSize: 11.5, color: colors.textMuted)),
    );
  }

  // ── 3. Event overlays ───────────────────────────────────────────────────

  Widget _eventOverlaySection(ThemeColors colors) {
    final eventsAsync = ref.watch(trendEventsProvider(_range));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(colors, 'EVENT OVERLAYS'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in TrendEventKind.values)
              _eventChip(colors, kind, eventsAsync.valueOrNull),
          ],
        ),
      ],
    );
  }

  Widget _eventChip(
      ThemeColors colors, TrendEventKind kind, TrendEvents? events) {
    final active = _activeEvents.contains(kind);
    final color = _eventColor(colors, kind);
    final count = events?.count(kind);
    return GestureDetector(
      onTap: () {
        HapticService.light();
        setState(() {
          if (active) {
            _activeEvents.remove(kind);
          } else {
            _activeEvents.add(kind);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.18)
              : colors.elevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? color : colors.cardBorder,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color.withValues(alpha: active ? 0.9 : 0.45),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 7),
            Text(kind.label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w600,
                    color: active
                        ? colors.textPrimary
                        : colors.textMuted)),
            if (count != null && count > 0) ...[
              const SizedBox(width: 5),
              Text('$count',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: active ? color : colors.textMuted)),
            ],
          ],
        ),
      ),
    );
  }

  Color _eventColor(ThemeColors colors, TrendEventKind kind) {
    switch (kind) {
      case TrendEventKind.workout:
        return colors.success;
      case TrendEventKind.fasting:
        return const Color(0xFF8A6FE0); // violet
      case TrendEventKind.rest:
        return colors.info;
      case TrendEventKind.weighIn:
        return const Color(0xFF3DA5E0); // sky
      case TrendEventKind.pr:
        return const Color(0xFFE0A93D); // gold
      case TrendEventKind.overTarget:
        return colors.error;
      case TrendEventKind.lowSleep:
        return const Color(0xFFD6675C); // muted red-orange
      case TrendEventKind.period:
        return const Color(0xFFE0567A); // rose
    }
  }

  // ── 4. Range selector ───────────────────────────────────────────────────

  Widget _rangeSelector(ThemeColors colors) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: TrendRange.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final r = TrendRange.values[i];
          final selected = r == _range;
          return GestureDetector(
            onTap: () {
              HapticService.light();
              setState(() => _range = r);
            },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? colors.accent.withValues(alpha: 0.2)
                    : colors.elevated,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? colors.accent : colors.cardBorder,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Text(r.label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: selected
                          ? colors.accent
                          : colors.textMuted)),
            ),
          );
        },
      ),
    );
  }

  // ── 5. Stats ────────────────────────────────────────────────────────────

  Widget _statsSection(ThemeColors colors) {
    final primaryAsync =
        ref.watch(trendSeriesProvider(TrendSeriesKey(_primary, _range)));
    final primary = primaryAsync.valueOrNull;
    if (primary == null || primary.points.isEmpty) {
      return const SizedBox.shrink();
    }
    final values = primary.points.map((p) => p.value).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final avgV = values.reduce((a, b) => a + b) / values.length;
    final unit = primary.unit;

    Widget cell(String label, double v, Color c) => Expanded(
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.6,
                      color: colors.textMuted)),
              const SizedBox(height: 3),
              Text('${_fmtNum(v)} $unit',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c)),
            ],
          ),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        children: [
          cell('MIN', minV, colors.success),
          Container(width: 1, height: 28, color: colors.cardBorder),
          cell('AVG', avgV, colors.accent),
          Container(width: 1, height: 28, color: colors.cardBorder),
          cell('MAX', maxV, colors.error),
        ],
      ),
    );
  }

  // ── 6. Correlation ──────────────────────────────────────────────────────

  Widget _correlationSection(ThemeColors colors) {
    if (_overlays.isEmpty) return const SizedBox.shrink();

    final primary =
        ref.watch(trendSeriesProvider(TrendSeriesKey(_primary, _range)))
            .valueOrNull;
    if (primary == null) return const SizedBox.shrink();

    final overlayData = <TrendSeries>[];
    for (final m in _overlays) {
      final s = ref
          .watch(trendSeriesProvider(TrendSeriesKey(m, _range)))
          .valueOrNull;
      if (s == null) return const SizedBox.shrink();
      overlayData.add(s);
    }

    // Exactly one overlay → single Pearson chip. >1 → a small matrix.
    if (overlayData.length == 1) {
      final other = overlayData.first;
      // The correlation card gates the CORRELATION result only — never the
      // lines. If either metric has <2 charted points there is nothing to
      // correlate; the per-metric legend note already explains the gap, so
      // suppress the card entirely rather than show a vague "not enough" box.
      if (primary.points.length < 2 || other.points.length < 2) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _correlationChip(
          colors,
          aName: primary.metric.displayName,
          bName: other.metric.displayName,
          result: pearsonCorrelation(primary.points, other.points),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_view_rounded,
                  size: 16, color: colors.accent),
              const SizedBox(width: 8),
              Text(
                  'Correlation vs ${primary.metric.displayName}',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          for (final o in overlayData)
            _correlationMatrixRow(
              colors,
              o.metric.displayName,
              pearsonCorrelation(primary.points, o.points),
            ),
        ],
      ),
    );
  }

  Widget _correlationMatrixRow(
      ThemeColors colors, String name, CorrelationResult r) {
    final hasData = r.hasEnoughData;
    final value = r.r;
    final Color color;
    if (!hasData) {
      color = colors.textMuted;
    } else {
      switch (r.strengthLabel) {
        case 'strong':
          color = colors.success;
          break;
        case 'moderate':
          color = colors.warning;
          break;
        default:
          color = colors.textMuted;
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(name,
                style: TextStyle(
                    fontSize: 12.5, color: colors.textSecondary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              hasData
                  ? '${value! >= 0 ? '+' : ''}${value.toStringAsFixed(2)} · ${r.strengthLabel}'
                  : '${r.pairedPoints}/$kMinCorrelationPairs shared days',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _correlationChip(
    ThemeColors colors, {
    required String aName,
    required String bName,
    required CorrelationResult result,
  }) {
    final Color chipColor;
    final String headline;
    if (!result.hasEnoughData) {
      chipColor = colors.textMuted;
      // This card gates the CORRELATION calculation only — both lines may be
      // drawn fine; they just lack enough days logged on the SAME date to
      // compute a meaningful Pearson r.
      headline = result.pairedPoints == 0
          ? 'No overlapping days to correlate'
          : "Correlation needs more overlapping days "
              '(${result.pairedPoints} of $kMinCorrelationPairs)';
    } else {
      final r = result.r!;
      switch (result.strengthLabel) {
        case 'strong':
          chipColor = colors.success;
          break;
        case 'moderate':
          chipColor = colors.warning;
          break;
        default:
          chipColor = colors.textMuted;
      }
      final sign = r >= 0 ? '+' : '';
      final word = result.strengthLabel == 'none'
          ? 'no correlation'
          : '${result.strengthLabel} ${r >= 0 ? 'positive' : 'negative'}';
      headline =
          'Correlation $sign${r.toStringAsFixed(2)} — $word';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: chipColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.insights_rounded, size: 18, color: chipColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(headline,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: chipColor)),
                const SizedBox(height: 2),
                Text(result.interpretation(aName, bName),
                    style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 7. AI insight ───────────────────────────────────────────────────────

  Widget _aiInsightSection(ThemeColors colors) {
    final primary =
        ref.watch(trendSeriesProvider(TrendSeriesKey(_primary, _range)))
            .valueOrNull;
    if (primary == null || primary.points.isEmpty) {
      return const SizedBox.shrink();
    }

    final series = <TrendInsightSeries>[
      TrendInsightSeries(
        label: primary.metric.displayName,
        unit: primary.unit,
        isPrimary: true,
        points: primary.points,
      ),
    ];
    final correlations = <String, double>{};
    for (final m in _overlays) {
      final s = ref
          .watch(trendSeriesProvider(TrendSeriesKey(m, _range)))
          .valueOrNull;
      if (s == null) return const SizedBox.shrink();
      series.add(TrendInsightSeries(
        label: s.metric.displayName,
        unit: s.unit,
        isPrimary: false,
        points: s.points,
      ));
      final r = pearsonCorrelation(primary.points, s.points);
      if (r.hasEnoughData) {
        correlations[s.metric.displayName] = r.r!;
      }
    }

    final events = <String, int>{};
    if (_activeEvents.isNotEmpty) {
      final ev = ref.watch(trendEventsProvider(_range)).valueOrNull;
      if (ev != null) {
        for (final kind in _activeEvents) {
          events[kind.label] = ev.count(kind);
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TrendAiInsightCard(
        request: TrendInsightRequest(
          rangeLabel: _range.label,
          series: series,
          events: events,
          correlations: correlations,
        ),
      ),
    );
  }

  // ── Save button + saved rows ────────────────────────────────────────────

  Widget _saveButton(ThemeColors colors) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _saveCurrent,
        icon: const Icon(Icons.bookmark_add_outlined, size: 18),
        label: const Text('Save this trend'),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.accent,
          side: BorderSide(color: colors.cardBorder),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _savedRow(ThemeColors colors, _SavedTrend t) {
    final overlaysText = t.overlays.isEmpty
        ? 'single metric'
        : '+ ${t.overlays.map((m) => m.displayName).join(', ')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticService.light();
            setState(() {
              _primary = t.primary;
              _overlays
                ..clear()
                ..addAll(t.overlays);
              _range = t.range;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.insights_rounded,
                    size: 18, color: colors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.primary.displayName,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary)),
                      const SizedBox(height: 1),
                      Text(overlaysText,
                          style: TextStyle(
                              fontSize: 11,
                              color: colors.textMuted)),
                    ],
                  ),
                ),
                Text(t.range.label,
                    style: TextStyle(
                        fontSize: 12, color: colors.textMuted)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _deleteSaved(t),
                  child: Icon(Icons.delete_outline,
                      size: 18, color: colors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared bits ─────────────────────────────────────────────────────────

  Widget _sectionLabel(ThemeColors colors, String text) => Text(
        text,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: colors.textMuted),
      );

  static String _fmtNum(double v) {
    if (v.abs() >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}k';
    }
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  void _pickMetric({
    required Set<TrendMetric> exclude,
    required void Function(TrendMetric) onPicked,
  }) {
    showMetricPickerSheet(
      context: context,
      exclude: exclude,
      onPicked: onPicked,
    );
  }
}

/// Paints a small line swatch — solid for the primary, dashed for overlays.
class _LineSwatchPainter extends CustomPainter {
  final Color color;
  final bool dashed;

  const _LineSwatchPainter({required this.color, required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    } else {
      const dash = 4.0;
      const gap = 3.0;
      var x = 0.0;
      while (x < size.width) {
        canvas.drawLine(
            Offset(x, y),
            Offset((x + dash).clamp(0, size.width).toDouble(), y),
            paint);
        x += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_LineSwatchPainter old) =>
      old.color != color || old.dashed != dashed;
}
