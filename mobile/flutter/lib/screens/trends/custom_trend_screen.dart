import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/theme_colors.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/providers/hormonal_health_provider.dart';
import '../../data/providers/trend_series_provider.dart';
import '../../data/providers/saved_trends_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/charts/cycle_phase_chart_overlay.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/trends/metric_picker_sheet.dart';
import '../../widgets/trends/mini_trend_sparkline.dart';
import '../../widgets/trends/trend_ai_insight_card.dart';
import '../../widgets/trends/premium_metric_chart.dart';
import '../../widgets/trends/trend_chart.dart';
import '../../widgets/trends/trend_correlation.dart';

import '../../l10n/generated/app_localizations.dart';
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

/// SharedPreferences key for the cycle-phases overlay toggle. Once a user
/// turns it off explicitly it stays off across sessions (otherwise it
/// defaults ON for users with cycle tracking enabled).
const String _kCyclePhasesOnPrefsKey = 'custom_trend_cycle_phases_on';

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

  /// Optional overlays to restore alongside [initialMetric] — set when opening
  /// a SAVED trend so the full set (primary + overlays + range) is rebuilt,
  /// not just the bare primary at the default range.
  final List<TrendMetric>? initialOverlays;

  /// Optional range to restore for a saved trend.
  final TrendRange? initialRange;

  const CustomTrendScreen({
    super.key,
    this.initialMetric,
    this.initialOverlays,
    this.initialRange,
  });

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

  /// User-selected chart style for the single-primary view (Line / Area / Bar).
  /// Only meaningful when there are no overlays; overlays always render as the
  /// normalised multi-line chart.
  PremiumChartType _ctType = PremiumChartType.line;
  TrendRange _range = TrendRange.d90;

  /// Which event overlays are currently toggled on.
  final Set<TrendEventKind> _activeEvents = {};

  /// Whether the cycle-phases background overlay is on. LOCAL state (not a
  /// Riverpod provider) so toggling never invalidates any data fetches — pure
  /// presentation flag layered on top of the already-cached prediction.
  ///
  /// Starts null while we resolve the persisted value; once resolved it is
  /// either the user's explicit choice or, on a first ever open, defaults to
  /// `true` for users with hormonal tracking enabled (else `false`).
  bool? _cyclePhasesOn;

  /// "Compare to last cycle" dashed overlay — when on, the primary series is
  /// duplicated and shifted backward by `avgCycleLength` days, rendered as a
  /// dashed overlay so the user can read this-cycle vs last-cycle at a
  /// glance (MacroFactor 1.11). Only enabled when the range covers ≥2
  /// cycles; below threshold a disabled hint is shown instead. LOCAL state
  /// for the same provider-storm reason as [_cyclePhasesOn].
  bool _compareLastCycleOn = false;

  List<_SavedTrend> _saved = const [];

  /// Scroll controller for the main builder list.
  final ScrollController _scrollController = ScrollController();

  /// True when the currently-built trend (primary + overlays + range) already
  /// exists in [_saved] — drives the "Saved ✓" state on the save button.
  bool get _isCurrentSaved => _saved.any((t) =>
      t.primary == _primary &&
      t.range == _range &&
      _listEq(t.overlays, _overlays));

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
    // Restore the FULL saved set when opened from a saved-trend row — overlays
    // and range, not just the primary (previously the carousel passed only the
    // primary, so tapping a saved trend silently dropped its overlays/range).
    if (widget.initialOverlays != null) {
      _overlays
        ..clear()
        ..addAll(
          widget.initialOverlays!
              .where((m) => m != _primary)
              .take(_kMaxOverlays),
        );
    }
    if (widget.initialRange != null) {
      _range = widget.initialRange!;
    }
    _loadSaved();
    _resolveFirstEver();
    _loadCyclePhasesPref();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Reads the persisted cycle-phases toggle. When unset (never toggled
  /// before), defers to the build-time default — leaves [_cyclePhasesOn] null
  /// here so the build can apply `hasHormonalTracking` as the seed default.
  Future<void> _loadCyclePhasesPref() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_kCyclePhasesOnPrefsKey);
    if (!mounted) return;
    setState(() => _cyclePhasesOn = stored);
  }

  Future<void> _persistCyclePhasesPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCyclePhasesOnPrefsKey, value);
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
    // #11: the home carousel's Trends page watches `savedTrendsProvider`, a
    // FutureProvider that reads prefs ONCE. Without this invalidation a newly
    // saved (or deleted) trend never appeared on the home carousel until an app
    // restart — which read as "I can't add my trend to the home screen."
    if (mounted) ref.invalidate(savedTrendsProvider);
  }

  Future<void> _saveCurrent() async {
    final exists = _saved.any((t) =>
        t.primary == _primary &&
        t.range == _range &&
        _listEq(t.overlays, _overlays));
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).menuAnalysisAlreadySaved)),
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
      // A confirmation with a direct "View" action so the user always knows
      // where the trend landed — the saved-trends sheet — without auto-opening
      // a modal over the chart they just built.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context).customTrendCustomTrendSaved),
          action: SnackBarAction(
            label: 'View',
            onPressed: _openSavedSheet,
          ),
        ),
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
        bottom: false,
        child: Column(
          children: [
            _header(colors),
            Expanded(
              child: ListView(
                controller: _scrollController,
                // Single consistent 16px left/right margin for every section —
                // cards, section labels, and chip rows all align to it. 12px
                // inter-card gap on the measurement-detail 8px grid.
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                children: [
                  // ── 1. The chart — graph-first, top of screen ──────────
                  _chartCard(colors),
                  const SizedBox(height: 12),
                  // ── 2. Metrics (primary + overlays + add) ──────────────
                  _legendSection(colors),
                  const SizedBox(height: 12),
                  // ── 3. Event overlays ──────────────────────────────────
                  _eventOverlaySection(colors),
                  const SizedBox(height: 12),
                  // ── 4. Time range ──────────────────────────────────────
                  _timeRangeSection(colors),
                  const SizedBox(height: 12),
                  // ── 5. Stats ───────────────────────────────────────────
                  _statsSection(colors),
                  // ── 6. Correlation ─────────────────────────────────────
                  _correlationSection(colors),
                  // ── 7. AI insight ──────────────────────────────────────
                  _aiInsightSection(colors),
                  // Saved trends now live in their own sheet — opened from the
                  // header "Saved (N)" pill or the footer save button — so they
                  // never clutter the builder scroll.
                  // ── About — explainer card, bottom of screen ───────────
                  const SizedBox(height: 24),
                  _aboutSection(colors),
                ],
              ),
            ),
          ],
        ),
      ),
      // Sticky save action — always reachable while scrolling the chart, so the
      // user never misses it (and it reflects the already-saved state).
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: _saveButton(colors),
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
          Text(AppLocalizations.of(context).statsRewardsCustomTrends,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary)),
          const Spacer(),
          // Top-right "Saved" access — opens the saved-trends sheet so saved
          // trends are reachable without hunting (only when some exist).
          if (_saved.isNotEmpty)
            GestureDetector(
              onTap: _openSavedSheet,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_rounded, size: 14, color: colors.accent),
                    const SizedBox(width: 5),
                    Text(
                      'Saved (${_saved.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: colors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── 1. Chart card ───────────────────────────────────────────────────────

  /// Resolved cycle-phases flag — the user's persisted choice if any, else
  /// ON when they have hormonal tracking enabled, else OFF. Single source
  /// of truth used everywhere in this build to avoid drift.
  bool _resolveCyclePhasesOn(bool hasHormonalTracking) {
    if (!hasHormonalTracking) return false;
    return _cyclePhasesOn ?? true;
  }

  Widget _chartTypeSelector(ThemeColors colors) {
    Widget seg(String label, IconData icon, PremiumChartType t) {
      final on = _ctType == t;
      return GestureDetector(
        onTap: () {
          HapticService.light();
          setState(() => _ctType = t);
        },
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: on
                ? colors.textPrimary.withValues(alpha: 0.12)
                : colors.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
                color: on
                    ? colors.textPrimary.withValues(alpha: 0.25)
                    : colors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 13, color: on ? colors.textPrimary : colors.textMuted),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: on ? colors.textPrimary : colors.textMuted)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        seg('Line', Icons.show_chart_rounded, PremiumChartType.line),
        seg('Area', Icons.area_chart_rounded, PremiumChartType.area),
        seg('Bars', Icons.bar_chart_rounded, PremiumChartType.bar),
      ],
    );
  }

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

    return _card(
      colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clear, data-driven title — "<Primary> [vs <Overlay>] over time".
          _cardTitle(colors, _chartTitle()),
          // Chart-type selector — single-primary only (bars/area can't carry
          // multiple normalised series).
          if (_overlays.isEmpty) ...[
            const SizedBox(height: 12),
            _chartTypeSelector(colors),
          ],
          const SizedBox(height: 16),
          // CacheFirstView swaps a layout-matched SKELETON chart (true
          // first-ever open only) for the real chart — never a blocking
          // CircularProgress. On every later open the cached series renders
          // instantly. After the first successful load it records the screen
          // as seen.
          CacheFirstView<TrendSeries>(
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

              // Honest single-point state: one logged day can't form a trend
              // line — show it as a single marker with a "log more" hint,
              // mirroring the measurement-detail single-point treatment.
              if (primary.points.length == 1) {
                return _singlePointChart(colors, primary);
              }

              return _memoizedChart(
                  colors, primary, overlayAsyncs, eventsAsync);
            },
          ),
        ],
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

    // Cycle-phases overlay subsumes the Period event band — painting both
    // shades the same calendar days twice, so suppress the period layer
    // whenever the cycle-phases overlay is on. The pill itself is also
    // hidden in `_eventOverlaySection` for the same reason.
    final hasHormonalTracking = ref.watch(hasHormonalTrackingProvider);
    final cyclePhasesOn = _resolveCyclePhasesOn(hasHormonalTracking);

    final events = <TrendEventLayer>[];
    final ev = eventsAsync?.valueOrNull;
    if (ev != null) {
      for (final kind in _activeEvents) {
        if (cyclePhasesOn && kind == TrendEventKind.period) continue;
        events.add(TrendEventLayer(
          label: kind.label,
          color: _eventColor(colors, kind),
          days: ev.of(kind),
        ));
      }
    }

    // Cycle prediction — read ONCE per build (cache-first provider, no fetch
    // storm). Drives both the overlay widget and the cache fingerprint so the
    // chart rebuilds when the prediction refreshes.
    final prediction = cyclePhasesOn
        ? ref.watch(cyclePredictionProvider).valueOrNull
        : null;
    final avgCycleLength = prediction?.stats.avgCycleLength?.round();
    // Coarse mode for long ranges (≥1Y): drop follicular/ovulation/luteal so
    // the overlay stays signal, not mush.
    final coarseOverlay = _range.days >= 365 || _range.days == 0;

    Widget? behindLayer;
    if (cyclePhasesOn &&
        CyclePhaseChartOverlay.canRender(prediction,
            avgCycleLength: avgCycleLength)) {
      final rangeStart = _range.startDate() ??
          (primary.points.isNotEmpty
              ? primary.points.first.date
              : DateTime.now().subtract(const Duration(days: 365)));
      final rangeEnd = DateTime.now();
      behindLayer = CyclePhaseChartOverlay(
        prediction: prediction,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        // Custom Trends chart reserves ~40px on the left for value labels and
        // ~26px on the bottom for date labels — mirror those insets so the
        // bands line up with the plot area, not the axis gutters.
        leftPadding: 40,
        bottomPadding: 26,
        coarse: coarseOverlay,
        darkModeBandOpacity: 0.20,
        avgCycleLength: avgCycleLength,
      );
    }

    // Cache key: a stable fingerprint of every input that affects the chart.
    // `points.length` + the metric/range/event identity is enough — the
    // underlying series objects are immutable, so a same-length series for
    // the same (metric, range) is the same data.
    final key = StringBuffer()
      ..write('${_primary.name}:${primary.points.length}:${primary.unit}')
      ..write('|brightness=${colors.isDark}')
      ..write('|ct=${_overlays.isEmpty ? _ctType.name : 'multi'}')
      ..write('|cyclePhases=$cyclePhasesOn')
      ..write('|compareLast=$_compareLastCycleOn')
      // Stable fingerprint for the cycle prediction — `nextPeriodDate` flips
      // whenever the backend recomputes (new period logged, stats updated),
      // forcing the cached chart widget to rebuild. Null when no prediction.
      ..write('|pred=${prediction?.nextPeriodDate?.toIso8601String() ?? 'none'}'
          ':${prediction?.lastPeriodStart?.toIso8601String() ?? 'none'}');
    for (final o in overlayData) {
      key.write('|ov${o.index}:${_overlays[o.index].name}'
          ':${o.series.points.length}');
    }
    for (final kind in _activeEvents) {
      // Mirror the suppression above — if period is hidden, exclude it from
      // the key too, otherwise toggling the (hidden) period flag would
      // needlessly invalidate the cache.
      if (cyclePhasesOn && kind == TrendEventKind.period) continue;
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

    // Compare-to-last-cycle: clone the primary's points shifted backward by
    // `avgCycleLength` days, render as a dashed violet overlay. Same metric +
    // unit so the comparison is honest (the chart still normalises when ANY
    // overlay is present; here that just superimposes the two cycles' shapes
    // on a shared 0-100 index, which is exactly what cycle-vs-cycle
    // comparison needs).
    if (_compareLastCycleOn && prediction != null) {
      final avg = prediction.stats.avgCycleLength?.round();
      final cycleLen = (avg != null && avg >= 21) ? avg : 28;
      // Guard the range gate again at render time — toggling the range below
      // the threshold while the chip stayed on must not render a phantom.
      final rangeOk = _range.days == 0 || _range.days >= 2 * cycleLen;
      if (rangeOk) {
        final shifted = <TrendPoint>[
          for (final p in primary.points)
            TrendPoint(
              date: p.date.subtract(Duration(days: cycleLen)),
              value: p.value,
            ),
        ];
        // Only render when at least one shifted point overlaps the visible
        // window — otherwise it's invisible chart chrome (edge case from the
        // plan: "skip render when no overlap with visible window").
        final rangeStartGate = _range.startDate();
        final hasOverlap = shifted.any((p) => rangeStartGate == null
            ? true
            : !p.date.isBefore(rangeStartGate));
        if (shifted.isNotEmpty && hasOverlap) {
          chartOverlays.add(TrendChartSeries(
            id: '${_primary.name}__prev_cycle',
            label: '${primary.metric.displayName} · last cycle',
            unit: primary.unit,
            points: shifted,
            color: const Color(0xFF8A6FE0),
          ));
        }
      }
    }

    final Widget chart;
    if (_overlays.isEmpty && _ctType != PremiumChartType.line) {
      // Single-primary Area / Bar — render through the premium custom painter
      // (gradient fill + glow + animated draw-on + scrub). Bars get a trend
      // overlay automatically.
      chart = SizedBox(
        height: 260,
        child: PremiumMetricChart(
          points: primary.points,
          type: _ctType,
          color: colors.accent,
          unit: primary.unit,
          height: 260,
        ),
      );
    } else {
      chart = TrendChart(
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
        behindLayer: behindLayer,
      );
    }
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

  /// Honest single-entry affordance — a centred glowing dot carrying the lone
  /// value + date and a "log again to start a trend" hint. No axis, no
  /// fabricated second point. Mirrors the measurement-detail single-point
  /// treatment so the two screens read identically when data is sparse.
  Widget _singlePointChart(ThemeColors colors, TrendSeries primary) {
    final point = primary.points.first;
    final unit = primary.unit;
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: colors.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              unit.isEmpty
                  ? _fmtNum(point.value)
                  : '${_fmtNum(point.value)} $unit',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _fmtDate(point.date),
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
            const SizedBox(height: 10),
            Text(
              '${_primary.displayName} logged on 1 day in this range — '
              'log it again to start a trend line.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: colors.textMuted.withValues(alpha: 0.7)),
            ),
          ],
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
    // Collect per-metric honesty notes for sparse/empty OVERLAY series. The
    // primary's single-point / empty state is already communicated inside the
    // chart card (single-point marker or empty placeholder), so listing it
    // again here would double up — only overlays get a legend note.
    final notes = <String>[
      for (final m in _overlays)
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
            Text(AppLocalizations.of(context).customTrendAddMetric,
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
    final hasHormonalTracking = ref.watch(hasHormonalTrackingProvider);
    final cyclePhasesOn = _resolveCyclePhasesOn(hasHormonalTracking);
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
              // Hide the Period pill while cycle phases is on — they paint
              // the same dates. The pill comes back the moment the user
              // toggles cycle phases off.
              if (!(cyclePhasesOn && kind == TrendEventKind.period))
                _eventChip(colors, kind, eventsAsync.valueOrNull),
            // Cycle phases pill — only for users with hormonal tracking.
            if (hasHormonalTracking)
              _cyclePhasesChip(colors, cyclePhasesOn),
            // Compare-to-last-cycle pill — only for tracking users; disabled
            // when the range is too short to contain two cycles.
            if (hasHormonalTracking) _compareLastCycleChip(colors),
          ],
        ),
      ],
    );
  }

  /// Pill for the dashed "compare to last cycle" overlay. When the current
  /// range covers fewer than 2 cycles, renders as a disabled hint instead.
  Widget _compareLastCycleChip(ThemeColors colors) {
    final prediction = ref.watch(cyclePredictionProvider).valueOrNull;
    final avg = prediction?.stats.avgCycleLength?.round();
    // Need a usable cycle length AND a range that spans ≥2 cycles. `All`
    // (days==0) is always wide enough.
    final cycleLen = (avg != null && avg >= 21) ? avg : 28;
    final enabled = _range.days == 0 || _range.days >= 2 * cycleLen;
    final active = enabled && _compareLastCycleOn;
    const color = Color(0xFF8A6FE0); // violet — distinct from period rose
    if (!enabled) {
      // Disabled hint pill — communicates the gate instead of silently
      // hiding the affordance.
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Text(
          AppLocalizations.of(context).customTrendCompareLastCycleNeeds,
          style: TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: colors.textMuted),
        ),
      );
    }
    return GestureDetector(
      onTap: () {
        HapticService.light();
        setState(() => _compareLastCycleOn = !_compareLastCycleOn);
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
            // Tiny dashed line swatch — communicates the dashed overlay style.
            CustomPaint(
              size: const Size(14, 3),
              painter: _LineSwatchPainter(color: color, dashed: true),
            ),
            const SizedBox(width: 7),
            Text(AppLocalizations.of(context).customTrendCompareLastCycle,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w600,
                    color: active
                        ? colors.textPrimary
                        : colors.textMuted)),
          ],
        ),
      ),
    );
  }

  /// Toggle pill for the cycle-phases background overlay. Shaped identically
  /// to [_eventChip] so it slots into the same row visually.
  Widget _cyclePhasesChip(ThemeColors colors, bool active) {
    const color = Color(0xFFE06FA8); // rose — matches Period swatch palette
    return GestureDetector(
      onTap: () {
        HapticService.light();
        setState(() => _cyclePhasesOn = !active);
        // Persist explicitly: once the user toggles off it stays off across
        // sessions (otherwise the default re-asserts).
        _persistCyclePhasesPref(!active);
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
            Text(AppLocalizations.of(context).customTrendCyclePhases,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w600,
                    color: active
                        ? colors.textPrimary
                        : colors.textMuted)),
          ],
        ),
      ),
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

  /// Labeled "TIME RANGE" section — the uppercase muted header above the
  /// scrollable range pills, consistent with METRICS / EVENT OVERLAYS.
  Widget _timeRangeSection(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(colors, 'TIME RANGE'),
        const SizedBox(height: 8),
        _rangeSelector(colors),
      ],
    );
  }

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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: colors.textMuted)),
              const SizedBox(height: 4),
              Text('${_fmtNum(v)} $unit',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: c)),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _card(
        colors,
        child: Row(
          children: [
            cell('MIN', minV, colors.success),
            Container(width: 1, height: 40, color: colors.cardBorder),
            cell('AVG', avgV, colors.accent),
            Container(width: 1, height: 40, color: colors.cardBorder),
            cell('MAX', maxV, colors.error),
          ],
        ),
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
        padding: const EdgeInsets.only(bottom: 12),
        child: _correlationChip(
          colors,
          aName: primary.metric.displayName,
          bName: other.metric.displayName,
          result: pearsonCorrelation(primary.points, other.points),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _card(
        colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grid_view_rounded, size: 18, color: colors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: _cardTitle(
                    colors,
                    'Correlation vs ${primary.metric.displayName}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final o in overlayData)
              _correlationMatrixRow(
                colors,
                o.metric.displayName,
                pearsonCorrelation(primary.points, o.points),
              ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(16),
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
    final saved = _isCurrentSaved;
    // When the current trend is already saved, the button flips to a "Saved"
    // state and instead opens the saved-trends sheet (so the action is never a
    // confusing no-op + the user learns where saved trends live).
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: saved ? _openSavedSheet : _saveCurrent,
        icon: Icon(
          saved ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
          size: 18,
        ),
        label: Text(
          saved
              ? 'Saved · view all'
              : AppLocalizations.of(context).customTrendSaveThisTrend,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: saved ? colors.success : colors.accent,
          backgroundColor:
              saved ? colors.success.withValues(alpha: 0.08) : null,
          side: BorderSide(
              color: saved
                  ? colors.success.withValues(alpha: 0.5)
                  : colors.cardBorder),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // ── About — bottom explainer card ───────────────────────────────────────

  /// "About custom trends" explainer card — mirrors the measurement-detail
  /// About card (info icon + title + height-1.5 body), grounding the screen
  /// with a short, honest description of what the multi-metric overlay does.
  Widget _aboutSection(ThemeColors colors) {
    return _card(
      colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: colors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'About custom trends',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Plot one primary metric in its real units, then layer up to '
            '$_kMaxOverlays more on a shared 0–100 index so different scales '
            'stay readable on one chart. Toggle event overlays to see how '
            'workouts, rest days, or fasting line up with the trend, and read '
            'the correlation as a relationship, not proof of cause. Save a set '
            'to pin it to your home screen for quick check-ins.',
            style: TextStyle(
                fontSize: 13, height: 1.5, color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  /// Opens the saved-trends sheet — a dedicated bottom sheet listing every
  /// saved set (each with a mini sparkline), tap-to-restore, and per-row
  /// delete. Replaces the old inline "SAVED TRENDS" section so saved trends
  /// live in their own surface instead of the bottom of the builder scroll.
  void _openSavedSheet() {
    HapticService.selection();
    final colors = ref.colors(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.background,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetCtx).size.height * 0.72,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.cardBorder,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Icon(Icons.bookmark_rounded,
                              size: 20, color: colors.accent),
                          const SizedBox(width: 8),
                          Text('Saved trends',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textPrimary)),
                          const Spacer(),
                          Text('${_saved.length}',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textMuted)),
                        ],
                      ),
                    ),
                    if (_saved.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        child: Text(
                          'No saved trends yet. Build a trend and tap Save to '
                          'pin it here and to your home screen.',
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: colors.textMuted),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          children: [
                            for (final t in _saved)
                              _SavedTrendSheetRow(
                                primary: t.primary,
                                overlays: t.overlays,
                                range: t.range,
                                onRestore: () {
                                  HapticService.light();
                                  setState(() {
                                    _primary = t.primary;
                                    _overlays
                                      ..clear()
                                      ..addAll(t.overlays);
                                    _range = t.range;
                                  });
                                  Navigator.of(sheetCtx).pop();
                                },
                                onDelete: () async {
                                  // Capture the navigator before the async gap
                                  // so we never touch sheetCtx after awaiting.
                                  final nav = Navigator.of(sheetCtx);
                                  await _deleteSaved(t);
                                  if (!mounted) return;
                                  if (_saved.isEmpty) {
                                    nav.pop();
                                  } else {
                                    setSheetState(() {});
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Shared bits ─────────────────────────────────────────────────────────

  /// Uppercase muted section label — matched to the measurement-detail
  /// redesign (fontSize 12 / w600 / letterSpacing 1.5) so every section header
  /// across the two screens reads identically.
  Widget _sectionLabel(ThemeColors colors, String text) => Text(
        text,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: colors.textMuted),
      );

  /// Shared card shell — the single source of truth for the redesign's card
  /// language (elevated fill, 16px radius, hairline border, 16px padding). All
  /// cards on this screen route through here so radius/border/padding never
  /// drift, exactly mirroring `_buildChartSection` et al. on the measurement
  /// detail screen.
  Widget _card(
    ThemeColors colors, {
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: child,
    );
  }

  /// A card title in the measurement-detail voice (fontSize 16 / w600).
  Widget _cardTitle(ThemeColors colors, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      );

  /// Human-readable chart title that names the series being plotted, e.g.
  /// "Weight over time" or "Weight vs Sleep over time". Built from the live
  /// metric selection so the copy always tracks what's on screen.
  String _chartTitle() {
    final primaryName = _primary.displayName;
    if (_overlays.isEmpty) {
      return '$primaryName over time';
    }
    if (_overlays.length == 1) {
      return '$primaryName vs ${_overlays.first.displayName} over time';
    }
    return '$primaryName vs ${_overlays.length} metrics over time';
  }

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

/// One row in the saved-trends sheet — the saved set's name + overlays, a live
/// mini sparkline of its primary series, its range, and a delete affordance.
/// Tapping the row restores the full set into the builder.
class _SavedTrendSheetRow extends ConsumerWidget {
  final TrendMetric primary;
  final List<TrendMetric> overlays;
  final TrendRange range;
  final VoidCallback onRestore;
  final Future<void> Function() onDelete;

  const _SavedTrendSheetRow({
    required this.primary,
    required this.overlays,
    required this.range,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors.of(context);
    final series = ref
        .watch(trendSeriesProvider(TrendSeriesKey(primary, range)))
        .valueOrNull;
    final points = series?.points ?? const <TrendPoint>[];
    final overlaysText = overlays.isEmpty
        ? 'single metric'
        : '+ ${overlays.map((m) => m.displayName).join(', ')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onRestore,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.insights_rounded, size: 18, color: colors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(primary.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary)),
                      const SizedBox(height: 1),
                      Text(overlaysText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: colors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Live mini sparkline of the saved primary series (≥2 points).
                if (points.length >= 2)
                  SizedBox(
                    width: 64,
                    height: 32,
                    child:
                        MiniTrendSparkline(points: points, color: colors.accent),
                  ),
                const SizedBox(width: 10),
                Text(range.label,
                    style: TextStyle(fontSize: 12, color: colors.textMuted)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    HapticService.light();
                    onDelete();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline,
                        size: 18, color: colors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
