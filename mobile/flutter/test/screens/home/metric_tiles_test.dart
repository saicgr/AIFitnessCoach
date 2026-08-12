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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/core/constants/app_colors.dart';
import 'package:fitwiz/core/providers/auth_provider.dart';
import 'package:fitwiz/core/stats/state_valence.dart';
import 'package:fitwiz/data/providers/home_metric_tiles_provider.dart';
import 'package:fitwiz/data/providers/metric_layout_provider.dart'
    show MetricSize;
import 'package:fitwiz/data/providers/metric_tile_data_provider.dart';
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

Widget _host(Widget child, {bool dark = true}) => ProviderScope(
      child: MaterialApp(
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
    List<Override> tileOverrides(Iterable<String> ids) => [
          currentUserIdProvider.overrideWithValue(_userId),
          for (final id in ids)
            metricTileDataProvider(id).overrideWithValue(
              _tile(
                id: id,
                label: kHomeMetricTileCatalog[id]!.label,
              ),
            ),
        ];

    Future<void> pumpGrid(
      WidgetTester tester, {
      Map<String, Object> prefs = const {},
      double screenWidth = 390,
      double textScale = 1,
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(screenWidth, 2400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: tileOverrides(kHomeMetricTileCatalog.keys),
        child: MaterialApp(
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
      // Page 2 is empty by default, so there is no pager and no dots to explain.
      expect(find.byType(PageView), findsNothing);
      expect(tester.takeException(), isNull);
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
      expect(find.text('PAGE 2 · DEPTH'), findsOneWidget);
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
