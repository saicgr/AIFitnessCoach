/// The Home metric tile grid — the section that replaced the four-cell
/// hero-score strip.
///
/// These tests hold the four promises the design makes and that a "the widget
/// builds" test would happily let regress:
///
///  1. **Chart treatment is a property of the size.** L is full-bleed with a
///     veil over the text zone; M and S get a lower-band chart and NO veil,
///     with the text zone laid out as the band's exact complement so the two
///     can never overlap.
///  2. **No data → no chart.** A source-less tile keeps its footprint, names
///     the reason in a capsule, shows an em-dash, and draws nothing. A flat
///     line through zero points would be a fabricated shape.
///  3. **Deviation colour is valence, never sign.** The same −12% tints
///     strain on steps and support on resting HR; a metric that declares no
///     direction (weight) stays neutral however big the move.
///  4. **The layout is the user's and it survives.** Reorder persists, and a
///     pre-tiles custom metric arrangement migrates across verbatim instead of
///     being reset to the default.
library;

import 'dart:convert';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/core/constants/app_colors.dart';
import 'package:fitwiz/core/providers/auth_provider.dart';
import 'package:fitwiz/core/stats/state_valence.dart';
import 'package:fitwiz/data/providers/home_metric_tiles_provider.dart';
import 'package:fitwiz/data/providers/metric_capability_provider.dart';
import 'package:fitwiz/data/providers/metric_layout_provider.dart'
    show MetricSize;
import 'package:fitwiz/data/providers/metric_tile_data_provider.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/home/widgets/home/metric_tile_card.dart';
import 'package:fitwiz/screens/home/widgets/home/metric_tile_grid.dart';
import 'package:fitwiz/screens/home/widgets/ring_catalog.dart';

const _userId = 'user-under-test';

MetricTileData _tile({
  String id = 'move',
  String label = 'Steps',
  String value = '6,412',
  String unit = '',
  bool hasData = true,
  String? noDataReason,
  bool noDataNamesSource = false,
  List<double> series = const [0.1, 0.4, 0.2, 0.8, 0.5, 0.9],
  double? baselineY = 0.5,
  bool claimsDeviation = true,
  double deviation = -12,
  double epsilon = 2,
  GoodDirection valence = GoodDirection.higher,
  String deviationLabel = '12% below your 30-day baseline',
  String deviationLabelShort = 'Below baseline',
  bool usesBars = false,
}) =>
    MetricTileData(
      id: id,
      label: label,
      value: value,
      unit: unit,
      hasData: hasData,
      noDataReason: noDataReason,
      noDataNamesSource: noDataNamesSource,
      series: series,
      baselineY: baselineY,
      claimsDeviation: claimsDeviation,
      deviation: deviation,
      deviationEpsilon: epsilon,
      valence: valence,
      deviationLabel: deviationLabel,
      deviationLabelShort: deviationLabelShort,
      usesBars: usesBars,
      route: '/metric/move',
    );

/// A dark tile, resolved through the SAME table the provider uses — so a copy
/// change cannot pass these tests by only changing the fixture.
MetricTileData _dark(String id, MetricEmptyReason reason) {
  final spec = kHomeMetricTileCatalog[id]!;
  final copy = metricEmptyCopyFor(id, reason, kMetricEmptyCopyEn);
  return MetricTileData(
    id: id,
    label: spec.tileLabel,
    value: '—',
    unit: '',
    hasData: false,
    emptyReason: reason,
    noDataReason: copy.long,
    noDataReasonShort: copy.short,
    noDataNamesSource: copy.namesSource,
    series: const [],
    valence: GoodDirection.neutral,
    deviationLabel: '',
    deviationLabelShort: '',
    route: spec.route,
  );
}

/// The state a real fresh iPhone was in: no Health, no plan, two in-app
/// metrics already carrying the user's own numbers.
const Map<String, MetricEmptyReason> _freshAccountDark = {
  kTodayScoreTileId: MetricEmptyReason.needsSetup,
  'move': MetricEmptyReason.healthDisconnected,
  'sleep': MetricEmptyReason.healthDisconnected,
  'recovery': MetricEmptyReason.healthDisconnected,
};

Widget _host(Widget child, {bool dark = true}) => ProviderScope(
      child: MaterialApp(
        // The tile resolves its empty-state copy from the bundles now, so the
        // delegates are load-bearing rather than decoration.
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: dark ? ThemeData.dark() : ThemeData.light(),
        home: Scaffold(
          body: Center(child: child),
        ),
      ),
    );

/// The tile's chart layer, located by its painter rather than by index so the
/// dashed-border and capsule painters can't be mistaken for it.
Finder _chartPaint() => find.byWidgetPredicate((w) {
      if (w is! CustomPaint) return false;
      final name = w.painter?.runtimeType.toString() ?? '';
      return name.contains('TileLinePainter') || name.contains('TileBarsPainter');
    });

/// The surface-colour veil that keeps the hero numeral legible over a
/// full-bleed chart. Only the L tile has one.
Finder _veil() => find.byWidgetPredicate((w) =>
    w is DecoratedBox &&
    w.decoration is BoxDecoration &&
    (w.decoration as BoxDecoration).gradient is LinearGradient);

/// Every card fill in the tile — the rounded 14pt decoration a tile paints
/// under its content. Empty and live tiles must return the same colour.
Color? _tileFill(WidgetTester tester) {
  final box = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).firstWhere(
        (w) =>
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).borderRadius ==
                BorderRadius.circular(14) &&
            (w.decoration as BoxDecoration).color != null,
      );
  return (box.decoration as BoxDecoration).color;
}

Color? _deviationColor(WidgetTester tester) {
  final text = tester.widget<Text>(
    find.descendant(
      of: find.byType(DeviationLine),
      matching: find.byType(Text),
    ),
  );
  return text.style?.color;
}

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [currentUserIdProvider.overrideWithValue(_userId)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─────────────────────────────────────────── 1. chart treatment by size

  group('chart treatment is a property of the tile size', () {
    testWidgets('L is full-bleed and veiled', (tester) async {
      await tester.pumpWidget(_host(
        MetricTileCard(data: _tile(), size: MetricSize.large, width: 358),
      ));

      expect(_chartPaint(), findsOneWidget);
      // Full-bleed: the chart layer is exactly as tall as the tile.
      expect(
        tester.getSize(_chartPaint()).height,
        moreOrLessEquals(metricTileHeight(MetricSize.large), epsilon: 0.5),
      );
      expect(_veil(), findsOneWidget,
          reason: 'the hero numeral must win over its own chart');
    });

    testWidgets('M confines the chart to a lower band, no veil', (tester) async {
      await tester.pumpWidget(_host(
        MetricTileCard(data: _tile(), size: MetricSize.wide, width: 174),
      ));

      expect(_chartPaint(), findsOneWidget);
      final chartHeight = tester.getSize(_chartPaint()).height;
      final tileHeight = metricTileHeight(MetricSize.wide);
      expect(chartHeight, lessThan(tileHeight / 2),
          reason: 'M draws in the lower band, not full-bleed');
      expect(_veil(), findsNothing,
          reason: 'treatment B needs no veil — the zones never overlap');
    });

    testWidgets('S confines the chart to a lower band, no veil', (tester) async {
      await tester.pumpWidget(_host(
        MetricTileCard(data: _tile(), size: MetricSize.small, width: 112),
      ));

      expect(_chartPaint(), findsOneWidget);
      expect(
        tester.getSize(_chartPaint()).height,
        lessThan(metricTileHeight(MetricSize.small) / 2),
      );
      expect(_veil(), findsNothing);
    });

    testWidgets('M/S text and chart zones do not overlap', (tester) async {
      for (final size in [MetricSize.wide, MetricSize.small]) {
        await tester.pumpWidget(_host(
          MetricTileCard(
            data: _tile(),
            size: size,
            width: size == MetricSize.wide ? 174 : 112,
          ),
        ));
        final chartTop = tester.getTopLeft(_chartPaint()).dy;
        final deviationBottom =
            tester.getBottomLeft(find.byType(DeviationLine)).dy;
        expect(deviationBottom, lessThanOrEqualTo(chartTop + 0.5),
            reason: '$size text must end before the chart band begins');
      }
    });

    testWidgets('S shortens the deviation, M/L keep the full sentence',
        (tester) async {
      await tester.pumpWidget(_host(
        MetricTileCard(data: _tile(), size: MetricSize.small, width: 112),
      ));
      expect(find.text('BELOW BASELINE'), findsOneWidget);
      expect(find.text('12% BELOW YOUR 30-DAY BASELINE'), findsNothing);

      await tester.pumpWidget(_host(
        MetricTileCard(data: _tile(), size: MetricSize.wide, width: 174),
      ));
      expect(find.text('12% BELOW YOUR 30-DAY BASELINE'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────── 2. empty / no-data state

  group('a tile with no source', () {
    testWidgets('names the reason, shows an em-dash, and draws NO chart',
        (tester) async {
      await tester.pumpWidget(_host(
        MetricTileCard(
          data: _tile(
            hasData: false,
            noDataReason: 'No source · connect Health',
            series: const [],
            baselineY: null,
            claimsDeviation: false,
          ),
          size: MetricSize.wide,
          width: 174,
        ),
      ));

      expect(_chartPaint(), findsNothing,
          reason: 'a chart with no points would be a fabricated shape');
      expect(find.text('NO SOURCE · CONNECT HEALTH'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.byType(DeviationLine), findsNothing,
          reason: 'no value means no deviation may be claimed');
      // The footprint is unchanged — an empty tile must not collapse the grid.
      expect(
        tester.getSize(find.byType(MetricTileCard)).height,
        metricTileHeight(MetricSize.wide),
      );
    });

    testWidgets('a long value shrinks rather than losing digits',
        (tester) async {
      await tester.pumpWidget(_host(
        MetricTileCard(
          data: _tile(id: 'weight', label: 'Weight', value: '1,183.4', unit: 'lb'),
          size: MetricSize.small,
          width: 89,
        ),
      ));
      final valueText = tester.widget<Text>(find.byWidgetPredicate(
        (w) => w is Text && (w.textSpan?.toPlainText() ?? '').startsWith('1,183.4'),
      ));
      expect(valueText.overflow, isNot(TextOverflow.visible));
      // A FittedBox is what makes the numeral shrink instead of ellipsising.
      expect(
        find.ancestor(
          of: find.byWidget(valueText),
          matching: find.byType(FittedBox),
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a single data point still draws no chart', (tester) async {
      await tester.pumpWidget(_host(
        MetricTileCard(
          data: _tile(series: const [0.5], baselineY: null),
          size: MetricSize.wide,
          width: 174,
        ),
      ));
      expect(_chartPaint(), findsNothing);
    });
  });

  // ─────────────────────────────── the tile's own chrome (mockup fidelity)

  group('tile chrome', () {
    testWidgets('an empty tile shares the live tile\'s fill; only the border '
        'differs', (tester) async {
      await tester.pumpWidget(_host(
        MetricTileCard(data: _tile(), size: MetricSize.wide, width: 174),
      ));
      final liveFill = _tileFill(tester);

      await tester.pumpWidget(_host(
        MetricTileCard(
          data: _tile(
            hasData: false,
            noDataReason: 'No source · connect Health',
            series: const [],
            baselineY: null,
            claimsDeviation: false,
          ),
          size: MetricSize.wide,
          width: 174,
        ),
      ));
      expect(_tileFill(tester), liveFill,
          reason: 'two card colours in one row read as a rendering fault');
      // The dashed border is what carries the whole distinction.
      expect(
        find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is MetricTileDashedBorder),
        findsWidgets,
      );
    });

    testWidgets('a source-naming capsule carries the circled-i, a short one '
        'does not', (tester) async {
      await tester.pumpWidget(_host(
        MetricTileCard(
          data: _tile(
            hasData: false,
            noDataReason: 'No source · connect Health',
            noDataNamesSource: true,
            series: const [],
            baselineY: null,
            claimsDeviation: false,
          ),
          size: MetricSize.wide,
          width: 174,
        ),
      ));
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      await tester.pumpWidget(_host(
        MetricTileCard(
          data: _tile(
            hasData: false,
            noDataReason: 'Needs HRV',
            series: const [],
            baselineY: null,
            claimsDeviation: false,
          ),
          size: MetricSize.small,
          width: 112,
        ),
      ));
      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    testWidgets('editing drops the ↗ and the reference line', (tester) async {
      await tester.pumpWidget(_host(
        MetricTileCard(data: _tile(), size: MetricSize.wide, width: 174),
      ));
      expect(find.byIcon(Icons.north_east_rounded), findsOneWidget);

      await tester.pumpWidget(_host(
        MetricTileCard(
          data: _tile(),
          size: MetricSize.wide,
          width: 174,
          chartRecedes: true,
          placementLine: 'M · page 1 · #2',
        ),
      ));
      expect(find.byIcon(Icons.north_east_rounded), findsNothing,
          reason: 'an edit tile must not read as tappable-through');
      // …and no dashed baseline: no deviation is being claimed while editing.
      final painter = tester.widget<CustomPaint>(_chartPaint()).painter!;
      expect(
        (painter as dynamic).baselineY,
        isNull,
        reason: 'edit tiles show structure only',
      );
    });

    testWidgets('the deviation sentence is never vertically clipped',
        (tester) async {
      for (final entry in const {
        MetricSize.wide: 174.0,
        MetricSize.small: 112.0,
      }.entries) {
        await tester.pumpWidget(_host(
          MetricTileCard(data: _tile(), size: entry.key, width: entry.value),
        ));
        final text = find.descendant(
          of: find.byType(DeviationLine),
          matching: find.byType(Text),
        );
        final box = tester.renderObject<RenderBox>(text);
        expect(
          box.size.height,
          greaterThanOrEqualTo(box.getMaxIntrinsicHeight(box.size.width)),
          reason: '${entry.key}: the text zone must fit the copy it carries — '
              'the chart band cannot be widened at its expense',
        );
      }
    });

    test('M/S curves ride a calm slice of their band, not its full extent', () {
      final ms = metricTileChartPlotBand(MetricSize.wide);
      expect(ms, metricTileChartPlotBand(MetricSize.small));
      expect(ms.top, greaterThanOrEqualTo(0.35));
      expect(ms.bottom, lessThanOrEqualTo(0.80));
      // The hero keeps the wider sweep — its curve is the tile's only texture.
      final large = metricTileChartPlotBand(MetricSize.large);
      expect(large.bottom - large.top, greaterThan(ms.bottom - ms.top));
    });

    test('normalisation pads the range so a flat week reads flat', () {
      // A 200-step spread on a 9,000-step week: without headroom this is
      // stretched edge to edge and reads as a dramatic zigzag.
      final quiet = normaliseTileSeries(
        const [9000, 9100, 9050, 9200, 9080, 9120],
        9080,
      );
      expect(quiet.series.reduce((a, b) => a < b ? a : b),
          greaterThan(0.0 + 1e-9));
      expect(quiet.series.reduce((a, b) => a > b ? a : b), lessThan(1.0 - 1e-9));
      // Shape is preserved — the padding is symmetric, not a rescale.
      expect(quiet.series[3], greaterThan(quiet.series[0]));
      expect(quiet.baselineY, isNotNull);

      // A genuinely flat series still collapses to the middle of the band.
      final flat = normaliseTileSeries(const [70, 70, 70], 70);
      expect(flat.series, everyElement(moreOrLessEquals(0.5, epsilon: 1e-9)));
    });
  });

  // ───────────────────────────────────────────── 3. valence, never the sign

  group('deviation colour encodes valence, not the sign', () {
    testWidgets('the SAME −12% strains steps and supports resting HR',
        (tester) async {
      await tester.pumpWidget(_host(
        MetricTileCard(
          data: _tile(valence: GoodDirection.higher), // steps: more is better
          size: MetricSize.wide,
          width: 174,
        ),
      ));
      expect(_deviationColor(tester), AppColors.stateStrains);

      await tester.pumpWidget(_host(
        MetricTileCard(
          data: _tile(
            id: 'heart_rate',
            label: 'Resting HR',
            valence: GoodDirection.lower, // RHR: less is better
          ),
          size: MetricSize.wide,
          width: 174,
        ),
      ));
      expect(_deviationColor(tester), AppColors.stateSupports,
          reason: 'below baseline is a WIN for resting heart rate');
    });

    testWidgets('a metric that declares no direction stays neutral',
        (tester) async {
      await tester.pumpWidget(_host(
        MetricTileCard(
          data: _tile(
            id: 'weight',
            label: 'Weight',
            valence: GoodDirection.neutral,
            deviation: -40,
          ),
          size: MetricSize.wide,
          width: 174,
        ),
      ));
      expect(_deviationColor(tester), AppColors.stateNeutral);
    });

    testWidgets('inside the noise floor it reads neutral, not a direction',
        (tester) async {
      await tester.pumpWidget(_host(
        MetricTileCard(
          data: _tile(deviation: 1, deviationLabel: 'On your 30-day baseline'),
          size: MetricSize.wide,
          width: 174,
        ),
      ));
      expect(_deviationColor(tester), AppColors.stateNeutral);
    });

    test('the ramp itself never reads the sign alone', () {
      expect(
        SemanticState.resolve(valence: GoodDirection.higher, deviation: -12),
        SemanticState.strains,
      );
      expect(
        SemanticState.resolve(valence: GoodDirection.lower, deviation: -12),
        SemanticState.supports,
      );
    });
  });

  // ───────────────────────────────────── the 30-day baseline claim itself

  group('baseline claims', () {
    test('excludes today from its own reference', () {
      final values = [
        for (var i = 0; i < 10; i++) 100.0, // ten flat days
        120.0, // today
      ];
      final dev = computeMetricDeviation(
        values,
        style: MetricDeviationStyle.percent,
      );
      expect(dev, isNotNull);
      expect(dev!.baseline, 100);
      expect(dev.amount, moreOrLessEquals(20, epsilon: 1e-9));
    });

    test('claims nothing below the minimum history', () {
      final values = [for (var i = 0; i < kMinBaselineHistory; i++) 100.0];
      expect(
        computeMetricDeviation(values, style: MetricDeviationStyle.percent),
        isNull,
        reason: 'a "baseline" from under a week of data is a rumour',
      );
    });

    test('scores are compared in points, body weight in absolute units', () {
      final values = [for (var i = 0; i < 10; i++) 70.0, 76.0];
      expect(
        computeMetricDeviation(values, style: MetricDeviationStyle.points)!
            .amount,
        moreOrLessEquals(6, epsilon: 1e-9),
      );
      expect(
        computeMetricDeviation(values, style: MetricDeviationStyle.absolute)!
            .amount,
        moreOrLessEquals(6, epsilon: 1e-9),
      );
    });
  });

  // ─────────────────────────────────────────── the tile kicker vocabulary

  group('tile kickers', () {
    test('a tile says what its number is, not what its ring is called', () {
      expect(kHomeMetricTileCatalog['move']!.tileLabel, 'Steps');
      expect(kHomeMetricTileCatalog['recovery']!.tileLabel, 'Ready');
      expect(kHomeMetricTileCatalog['hydration']!.tileLabel, 'Water');
      // The ring keeps its own name for lists and settings.
      expect(kHomeMetricTileCatalog['move']!.label, 'Move');
      // Everything else reuses the ring label verbatim.
      expect(kHomeMetricTileCatalog['sleep']!.tileLabel, 'Sleep');
      expect(kHomeMetricTileCatalog[kTodayScoreTileId]!.tileLabel,
          'Today Score');
      for (final spec in kHomeMetricTileCatalog.values) {
        expect(spec.tileLabel, isNotEmpty);
      }
    });
  });

  // ─────────────────────────────────────────────────── grid packing maths

  group('grid packing', () {
    test('packs L / M / S into 6-column rows in order', () {
      final rows = packMetricTileRows(const [
        HomeMetricTile(id: kTodayScoreTileId, size: MetricSize.large),
        HomeMetricTile(id: 'move', size: MetricSize.wide),
        HomeMetricTile(id: 'sleep', size: MetricSize.wide),
        HomeMetricTile(id: 'recovery', size: MetricSize.small),
        HomeMetricTile(id: 'hydration', size: MetricSize.small),
        HomeMetricTile(id: 'weight', size: MetricSize.small),
      ]);
      expect(rows.map((r) => r.length).toList(), [1, 2, 3]);
      expect(rows.first.single.id, kTodayScoreTileId);
    });

    test('page height is the sum of row heights plus gaps', () {
      const tiles = [
        HomeMetricTile(id: kTodayScoreTileId, size: MetricSize.large),
        HomeMetricTile(id: 'move', size: MetricSize.wide),
        HomeMetricTile(id: 'sleep', size: MetricSize.wide),
      ];
      expect(
        metricGridHeight(tiles),
        metricTileHeight(MetricSize.large) +
            metricTileHeight(MetricSize.wide) +
            kMetricTileGap,
      );
    });
  });

  // ─────────────────────────────────────────────── the composed grid

  group('the grid section', () {
    /// Feeds the grid synthetic tile data so the composition (packing, row
    /// widths, page dots, edit mode) is exercised without the live provider
    /// graph — which needs a Supabase session a bare widget test can't have.
    List<Override> tileOverrides(
      Iterable<String> ids, {
      bool needsHealthConnect = false,
      Map<String, MetricEmptyReason> dark = const {},
    }) =>
        [
          currentUserIdProvider.overrideWithValue(_userId),
          // The grid renders the CAPABILITY-FILTERED projection, not the raw
          // arrangement. These tests are about layout, so pass the arrangement
          // through unfiltered; capability itself is covered in
          // metric_capability_test.dart.
          mountedMetricTilesProvider.overrideWith(
            (ref) => ref.watch(homeMetricTilesProvider),
          ),
          // The connect card's gate reaches into the health plugin; the grid
          // reads it as one bool so a widget test can state the condition.
          metricTilesNeedHealthConnectProvider
              .overrideWithValue(needsHealthConnect),
          for (final id in ids)
            metricTileDataProvider(id).overrideWithValue(
              dark.containsKey(id)
                  ? _dark(id, dark[id]!)
                  : _tile(
                      id: id,
                      // The tile-facing kicker, NOT always the ring label.
                      label: kHomeMetricTileCatalog[id]!.tileLabel,
                    ),
            ),
        ];

    Future<void> pumpGrid(
      WidgetTester tester, {
      Map<String, Object> prefs = const {},
      double screenWidth = 390,
      double textScale = 1,
      bool needsHealthConnect = false,
      Map<String, MetricEmptyReason> dark = const {},
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(screenWidth, 2400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: tileOverrides(
          kHomeMetricTileCatalog.keys,
          needsHealthConnect: needsHealthConnect,
          dark: dark,
        ),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(child: HomeMetricTileGrid()),
          ),
        ),
      ));
      await tester.pump();
    }

    testWidgets('renders the default daily glance on one page', (tester) async {
      await pumpGrid(tester);

      expect(find.byType(MetricTileCard), findsNWidgets(kDefaultMetricTiles.length));
      expect(find.text('MY METRICS'), findsOneWidget);
      // Page 2 is empty by default, so there is no pager…
      expect(find.byType(PageView), findsNothing);
      // …and therefore no dots. A dot over a plain Column advertises a swipe
      // the widget tree cannot perform — which is exactly what shipped.
      expect(find.byKey(kMetricTilePageDotsKey), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the default kickers are the mockup\'s six', (tester) async {
      await pumpGrid(tester);
      for (final kicker in const [
        'TODAY SCORE',
        'STEPS',
        'SLEEP',
        'READY',
        'WATER',
        'WEIGHT',
      ]) {
        expect(find.text(kicker), findsOneWidget,
            reason: '$kicker is what the tile says, not its ring\'s name');
      }
      // The ring names those three tiles replaced must not surface here.
      for (final ringLabel in const ['MOVE', 'RECOVERY', 'HYDRATION']) {
        expect(find.text(ringLabel), findsNothing);
      }
    });

    testWidgets('the pencil opens edit mode with reorder, resize and add',
        (tester) async {
      await pumpGrid(tester);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();

      expect(find.byType(MetricTileGridEditor), findsOneWidget);
      expect(find.text('ADD METRIC'), findsOneWidget);
      // Drag-to-reorder ships in build one, not as a fast-follow. It is a
      // long-press lift so a plain vertical drag still scrolls Home.
      expect(find.byType(LongPressDraggable<String>), findsWidgets);
      expect(find.byIcon(Icons.remove), findsWidgets);
      expect(tester.takeException(), isNull);

      // Tapping a tile reveals its S/M/L control.
      await tester.tap(find.byType(MetricTileCard).first);
      await tester.pump();
      expect(find.text('S'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
    });

    testWidgets('lays out without overflow on a 320pt phone', (tester) async {
      await pumpGrid(tester, screenWidth: 320);
      expect(find.byType(MetricTileCard),
          findsNWidgets(kDefaultMetricTiles.length));
      expect(tester.takeException(), isNull);
    });

    testWidgets('tiles grow with the reader\'s type size instead of clipping it',
        (tester) async {
      for (final scale in [1.3, 2.0]) {
        await pumpGrid(tester, screenWidth: 320, textScale: scale);
        expect(tester.takeException(), isNull,
            reason: 'no overflow at textScale $scale on a 320pt phone');
        expect(
          tester.getSize(find.byType(MetricTileCard).first).height,
          moreOrLessEquals(metricTileHeight(MetricSize.large) * scale,
              epsilon: 0.5),
        );
      }
    });

    testWidgets('edit mode fits a 320pt phone, size control included',
        (tester) async {
      await pumpGrid(tester, screenWidth: 320);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();
      // Select the narrowest tile — its S/M/L segment is wider than the tile.
      await tester.tap(find.byType(MetricTileCard).last);
      await tester.pump();
      expect(find.text('S'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a page-2 tile is what creates the pager and its dots',
        (tester) async {
      await pumpGrid(tester, prefs: {
        homeMetricTilesStorageKey(_userId): jsonEncode([
          {'id': kTodayScoreTileId, 'size': 'large', 'page': 1},
          {'id': 'move', 'size': 'wide', 'page': 1},
          {'id': 'hrv', 'size': 'wide', 'page': 2},
        ]),
      });
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
      expect(find.byKey(kMetricTilePageDotsKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('page 1 stays flush left; only page 2 bleeds past the edge',
        (tester) async {
      await pumpGrid(tester, prefs: {
        homeMetricTilesStorageKey(_userId): jsonEncode([
          {'id': kTodayScoreTileId, 'size': 'large', 'page': 1},
          {'id': 'move', 'size': 'wide', 'page': 1},
          {'id': 'hrv', 'size': 'wide', 'page': 2},
        ]),
      });
      await tester.pump();

      final pager = tester.widget<PageView>(find.byType(PageView));
      expect(pager.padEnds, isFalse,
          reason: 'padEnds centres the page and insets the whole section');

      // The hero's left edge sits on the same 16pt gutter as every other Home
      // card — not half a peek in from it.
      final heroLeft = tester.getTopLeft(find.byType(MetricTileCard).first).dx;
      expect(heroLeft, moreOrLessEquals(16, epsilon: 0.5));

      // …and the peek is real: page 1 is narrower than the grid by ~22pt.
      final heroWidth = tester.getSize(find.byType(MetricTileCard).first).width;
      expect(390 - 32 - heroWidth, inInclusiveRange(18, 26));
    });

    testWidgets('edit mode swaps the masthead and collapses page 2',
        (tester) async {
      await pumpGrid(tester);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();

      expect(find.text('EDIT TILES'), findsOneWidget);
      expect(find.text('CHANGES SAVE INSTANTLY'), findsOneWidget,
          reason: 'there is no Cancel, so the promise has to be stated');
      expect(find.text('MY METRICS'), findsNothing);

      // An empty page 2 is one dashed strip, not a second grid with a label.
      expect(find.text('PAGE 2 · DRAG A TILE HERE'), findsOneWidget);
      expect(find.text('PAGE 1 · DAILY GLANCE'), findsNothing,
          reason: 'the only populated grid needs no label');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the Add slot is dashed, like every other placeholder',
        (tester) async {
      await pumpGrid(tester);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();

      final addSlot = find.ancestor(
        of: find.text('ADD METRIC'),
        matching: find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is MetricTileDashedBorder,
        ),
      );
      expect(addSlot, findsWidgets);
      expect(
        (tester.widgetList<CustomPaint>(addSlot).first.painter
                as MetricTileDashedBorder)
            .strokeWidth,
        1.5,
      );
      // …and it paints no solid border of its own.
      expect(
        find.descendant(
          of: addSlot.first,
          matching: find.byWidgetPredicate((w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).border != null),
        ),
        findsNothing,
      );
    });

    testWidgets('presets carry sizes and pages, and My layout comes back',
        (tester) async {
      await pumpGrid(tester);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();

      expect(find.text('PRESETS'), findsOneWidget);
      for (final p in kMetricTilePresets) {
        expect(find.text(p.label.toUpperCase()), findsOneWidget);
      }
      // Nothing matches a preset out of the box, so the dirty state is active.
      expect(find.text('MY LAYOUT'), findsOneWidget);

      await tester.tap(find.text('RECOVERY'));
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MetricTileGridEditor)),
      );
      final applied = container.read(homeMetricTilesProvider);
      final recovery =
          kMetricTilePresets.firstWhere((p) => p.id == 'recovery');
      expect(applied, recovery.tiles,
          reason: 'a preset carries size and page, not just the metric list');
      expect(container.read(activeMetricTilePresetProvider)?.id, 'recovery');

      // "My layout" is a destination, not decoration.
      await tester.tap(find.text('MY LAYOUT'));
      await tester.pump();
      expect(container.read(homeMetricTilesProvider), kDefaultMetricTiles);
      expect(container.read(activeMetricTilePresetProvider), isNull);
    });

    testWidgets('the connect card appears under the grid only when Health is '
        'dark and a sensor tile is placed', (tester) async {
      await pumpGrid(tester);
      expect(find.text('CONNECT HEALTH'), findsNothing);

      await pumpGrid(tester, needsHealthConnect: true);
      // Platform-aware since the Android-told-to-connect-Apple-Health fix:
      // the test binding reports TargetPlatform.android, so this resolves to
      // Health Connect. Asserting the prefix keeps the test honest on both.
      expect(find.textContaining('Connect '), findsWidgets);
      expect(
        find.textContaining('Apple Health'),
        findsNothing,
        reason: 'the default test platform is Android; naming Apple Health '
            'here is the exact defect this became a fix for',
      );
      expect(find.text('CONNECT HEALTH'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // …and never over the editor.
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();
      expect(find.text('CONNECT HEALTH'), findsNothing);
    });
  });

  // ─────────────────────────────── 3b. every sensor dark (the first run)

  // ─────────────── 3b. the state that used to need a panel cannot occur

  group('a tile that cannot fill is never mounted', () {
    // SUPERSEDES the round-4 "collapse >= 3 dark tiles" rule and the round-5
    // MetricSetupPanel. Both existed to make a page of unfillable tiles look
    // acceptable. Neither is reachable now: a tile mounts only if the user's
    // sources can produce its number, so "every sensor dark" is not a state
    // the grid can enter — those tiles were never mounted.
    //
    // The rule itself is tested in metric_capability_test.dart; these two
    // assert that the machinery it replaced is really gone, so nobody
    // re-introduces a second empty-state path alongside it.

    test('the collapse threshold no longer restructures the grid', () {
      final src = File(
        'lib/screens/home/widgets/home/metric_tile_grid.dart',
      ).readAsStringSync();
      expect(
        RegExp(r'const collapsed1 = false;').hasMatch(src),
        isTrue,
        reason: 'collapse is pinned off — a page of dark tiles is no longer '
            'reachable, so restructuring around one would be dead code that '
            'quietly diverges from the capability rule',
      );
    });

    test('the grid renders the capability-filtered projection', () {
      final src = File(
        'lib/screens/home/widgets/home/metric_tile_grid.dart',
      ).readAsStringSync();
      expect(
        src.contains('ref.watch(mountedMetricTilesProvider)'),
        isTrue,
        reason: 'reading homeMetricTilesProvider directly would render tiles '
            'the user has no source for — the defect this replaced',
      );
    });
  });


  // ───────────────────────────────────── 3c. pages, dots and the swipe

  group('page dots describe only reachable pages', () {
    Future<void> pumpPages(
      WidgetTester tester, {
      required bool populatePageTwo,
    }) async {
      SharedPreferences.setMockInitialValues({
        if (populatePageTwo)
          homeMetricTilesStorageKey(_userId): jsonEncode([
            {'id': kTodayScoreTileId, 'size': 'large', 'page': 1},
            {'id': 'move', 'size': 'wide', 'page': 1},
            {'id': 'sleep', 'size': 'wide', 'page': 1},
            {'id': 'hrv', 'size': 'wide', 'page': 2},
            {'id': 'stress', 'size': 'wide', 'page': 2},
          ]),
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 2400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(_userId),
          metricTilesNeedHealthConnectProvider.overrideWithValue(false),
          // Layout test: pass the arrangement through unfiltered. Capability
          // is covered in metric_capability_test.dart.
          mountedMetricTilesProvider.overrideWith(
            (ref) => ref.watch(homeMetricTilesProvider),
          ),
          for (final id in kHomeMetricTileCatalog.keys)
            metricTileDataProvider(id).overrideWithValue(
              _tile(id: id, label: kHomeMetricTileCatalog[id]!.tileLabel),
            ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: SingleChildScrollView(child: HomeMetricTileGrid()),
          ),
        ),
      ));
      await tester.pump();
    }

    /// The dots themselves — one Container per page, widened when active.
    List<Container> dots(WidgetTester tester) => tester
        .widgetList<Container>(find.descendant(
          of: find.byKey(kMetricTilePageDotsKey),
          matching: find.byType(Container),
        ))
        .toList();

    testWidgets('an empty page 2 draws NO dots at all', (tester) async {
      await pumpPages(tester, populatePageTwo: false);
      expect(find.byType(PageView), findsNothing);
      expect(find.byKey(kMetricTilePageDotsKey), findsNothing);
    });

    testWidgets('a populated page 2 draws exactly one dot per reachable page',
        (tester) async {
      await pumpPages(tester, populatePageTwo: true);
      expect(find.byType(PageView), findsOneWidget);
      expect(dots(tester).length, 2);
    });

    testWidgets('the pager answers a real horizontal drag, and the dots follow',
        (tester) async {
      await pumpPages(tester, populatePageTwo: true);

      double dotWidth(int i) =>
          (dots(tester)[i].constraints?.maxWidth) ?? double.nan;

      // Page 1 active at rest.
      expect(dotWidth(0), greaterThan(dotWidth(1)));

      // A real gesture, not a controller call: the whole defect was that the
      // dots described a swipe nothing in the tree could perform, and the
      // pager sits inside Home's vertical scroll where the gesture arena has
      // to disambiguate by axis.
      await tester.drag(find.byType(PageView), const Offset(-320, 0));
      await tester.pumpAndSettle();

      expect(dotWidth(1), greaterThan(dotWidth(0)),
          reason: 'the drag actually paged the grid');

      // …and back.
      await tester.drag(find.byType(PageView), const Offset(320, 0));
      await tester.pumpAndSettle();
      expect(dotWidth(0), greaterThan(dotWidth(1)));
      expect(tester.takeException(), isNull);
    });
  });

  // ───────────────────────────────────────── 4. persistence and migration

  group('layout persistence', () {
    test('a reorder is written through and reloads on the next launch',
        () async {
      SharedPreferences.setMockInitialValues({});
      final container = _container();
      final notifier = container.read(homeMetricTilesProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      final before = container.read(homeMetricTilesProvider);
      expect(before.first.id, kTodayScoreTileId);

      notifier.reorder(0, 2); // hero drops to third
      await Future<void>.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(homeMetricTilesStorageKey(_userId));
      expect(raw, isNotNull);
      final persisted = [
        for (final e in jsonDecode(raw!) as List) (e as Map)['id'] as String,
      ];
      expect(persisted[2], kTodayScoreTileId);

      // A fresh container (== a fresh launch) reads the same order back.
      final relaunched = _container();
      relaunched.read(homeMetricTilesProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      expect(
        relaunched.read(homeMetricTilesProvider).map((t) => t.id).toList(),
        persisted,
      );
    });

    test('a resize and a page move persist', () async {
      SharedPreferences.setMockInitialValues({});
      final container = _container();
      final notifier = container.read(homeMetricTilesProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      notifier.setSize('move', MetricSize.large);
      notifier.setPage('weight', 2);
      await Future<void>.delayed(Duration.zero);

      final relaunched = _container();
      relaunched.read(homeMetricTilesProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      final tiles = relaunched.read(homeMetricTilesProvider);
      expect(tiles.firstWhere((t) => t.id == 'move').size, MetricSize.large);
      expect(tiles.firstWhere((t) => t.id == 'weight').page, 2);
      // Page 1 tiles still lead the flat list.
      expect(tilesOnPage(tiles, 2).map((t) => t.id), ['weight']);
    });

    test('removing a tile hides it without touching the metric', () async {
      SharedPreferences.setMockInitialValues({});
      final container = _container();
      final notifier = container.read(homeMetricTilesProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      notifier.remove('sleep');
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(homeMetricTilesProvider).any((t) => t.id == 'sleep'),
        isFalse,
      );
      // …and it is offered back in the Add sheet, not destroyed.
      expect(
        container.read(unplacedMetricTilesProvider).map((s) => s.id),
        contains('sleep'),
      );
    });

    test('every preset places only real metrics, and none fills page 2',
        () async {
      for (final preset in kMetricTilePresets) {
        for (final tile in preset.tiles) {
          expect(kHomeMetricTileCatalog.containsKey(tile.id), isTrue,
              reason: '${preset.id} places an unknown metric "${tile.id}"');
          expect(tile.page, 1,
              reason: 'a preset must not invent a page-2 dumping ground');
        }
        expect(
          preset.tiles.map((t) => t.id).toSet().length,
          preset.tiles.length,
          reason: '${preset.id} places the same metric twice',
        );
      }
    });

    test('a preset applies through the store and is detected as active',
        () async {
      SharedPreferences.setMockInitialValues({});
      final container = _container();
      final notifier = container.read(homeMetricTilesProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(activeMetricTilePresetProvider), isNull);
      notifier.applyPreset(kMetricTilePresets.first);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(activeMetricTilePresetProvider)?.id,
          kMetricTilePresets.first.id);
      // …and it persists like any other layout edit.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(homeMetricTilesStorageKey(_userId)), isNotNull);

      notifier.restoreLayoutBeforePreset();
      expect(container.read(homeMetricTilesProvider), kDefaultMetricTiles);
    });

    test('nothing is ever auto-assigned to page 2', () async {
      SharedPreferences.setMockInitialValues({});
      final container = _container();
      container.read(homeMetricTilesProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      expect(tilesOnPage(container.read(homeMetricTilesProvider), 2), isEmpty);
    });
  });

  group('migration off the pre-tiles metric layout', () {
    test('a custom ring arrangement carries across verbatim', () async {
      // What the user arranged in My Space → Metrics before tiles existed.
      SharedPreferences.setMockInitialValues({
        ringOrderStorageKey(_userId):
            jsonEncode(['sleep', 'move', 'hrv', 'hydration']),
      });
      final container = _container();
      container.read(homeMetricTilesProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      final tiles = container.read(homeMetricTilesProvider);
      expect(
        tiles.map((t) => t.id).toList(),
        // Their sequence, untouched — with the hero the ring list could never
        // hold prepended.
        [kTodayScoreTileId, 'sleep', 'move', 'hrv', 'hydration'],
      );
      expect(tiles.every((t) => t.page == 1), isTrue,
          reason: 'a migration must not invent a page-2 dumping ground');

      // And it is now written under the tile key, so the migration is one-shot.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(homeMetricTilesStorageKey(_userId)), isNotNull);
    });

    test('an already-persisted tile layout always wins over the ring order',
        () async {
      SharedPreferences.setMockInitialValues({
        ringOrderStorageKey(_userId): jsonEncode(['sleep', 'move']),
        homeMetricTilesStorageKey(_userId): jsonEncode([
          {'id': 'weight', 'size': 'large', 'page': 1},
          {'id': 'move', 'size': 'small', 'page': 2},
        ]),
      });
      final container = _container();
      container.read(homeMetricTilesProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      final tiles = container.read(homeMetricTilesProvider);
      expect(tiles.map((t) => t.id).toList(), ['weight', 'move']);
      expect(tiles.first.size, MetricSize.large);
      expect(tiles.last.page, 2);
    });

    test('a user who never customised gets the daily-glance default', () async {
      SharedPreferences.setMockInitialValues({});
      final container = _container();
      container.read(homeMetricTilesProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(homeMetricTilesProvider), kDefaultMetricTiles);
    });

    test('a corrupt or stale blob drops unknown ids instead of crashing',
        () async {
      SharedPreferences.setMockInitialValues({
        homeMetricTilesStorageKey(_userId): jsonEncode([
          {'id': 'a_ring_that_no_longer_exists', 'size': 'wide', 'page': 1},
          {'id': 'move', 'size': 'wide', 'page': 1},
          {'id': 'move', 'size': 'small', 'page': 2}, // duplicate
          {'id': 'sleep', 'size': 'wide', 'page': 9}, // impossible page
        ]),
      });
      final container = _container();
      container.read(homeMetricTilesProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      final tiles = container.read(homeMetricTilesProvider);
      expect(tiles.map((t) => t.id).toList(), ['move', 'sleep']);
      expect(tiles.last.page, 1, reason: 'pages are clamped to 1..2');
    });
  });
}
