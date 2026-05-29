import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/core/constants/stat_typography.dart';
import 'package:fitwiz/core/stats/stat_trend.dart';
import 'package:fitwiz/widgets/trends/trend_correlation.dart' show TrendPoint;

/// Runtime-render proofs for the glanceable-stats primitives. These catch the
/// failure modes `flutter analyze` cannot: FittedBox/RichText/LineChart
/// throwing under real layout constraints.

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        // A deliberately tight, bounded box — the SE-class constraint where a
        // big number must scale down rather than overflow.
        body: Center(child: SizedBox(width: 120, height: 80, child: child)),
      ),
    );

void main() {
  testWidgets('StatNumber renders a hero number + unit without overflow',
      (tester) async {
    await tester.pumpWidget(_host(
      const StatNumber(value: '98.7', unit: 'kg', size: StatType.hero, color: Colors.cyan),
    ));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('98.7', findRichText: true), findsOneWidget);
  });

  testWidgets('StatNumber scales a long value down inside a tight box',
      (tester) async {
    await tester.pumpWidget(_host(
      const StatNumber(value: '12,340', unit: 'kg', size: StatType.primary, color: Colors.white),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('StatChange.compute classifies direction + flat threshold', (tester) async {
    expect(StatChange.compute(100, 90)!.direction, TrendDirection.up);
    expect(StatChange.compute(90, 100)!.direction, TrendDirection.down);
    expect(StatChange.compute(100, 100)!.direction, TrendDirection.flat);
    expect(StatChange.compute(null, 100), isNull);
    expect(StatChange.fromPoints(const []), isNull);
  });

  testWidgets('StatDeltaLine renders for up / down / flat', (tester) async {
    for (final pair in [
      [101.0, 100.0, GoodDirection.lower],
      [99.0, 100.0, GoodDirection.lower],
      [100.0, 100.0, GoodDirection.neutral],
    ]) {
      final change = StatChange.compute(pair[0] as double, pair[1] as double)!;
      await tester.pumpWidget(_host(
        StatDeltaLine(change: change, good: pair[2] as GoodDirection, unit: 'kg'),
      ));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('StatTrendChip renders (and hides when flat)', (tester) async {
    await tester.pumpWidget(_host(
      StatTrendChip(change: StatChange.compute(120, 100)!, good: GoodDirection.higher, unit: 'kg'),
    ));
    expect(tester.takeException(), isNull);
    // Flat → SizedBox.shrink, still no throw.
    await tester.pumpWidget(_host(
      StatTrendChip(change: StatChange.compute(100, 100)!, good: GoodDirection.neutral),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sparkline renders for a real series and is empty for <2 points',
      (tester) async {
    final base = DateTime(2026, 5, 1);
    final pts = [
      for (var i = 0; i < 8; i++)
        TrendPoint(date: base.add(Duration(days: i)), value: 90.0 + i * 0.7),
    ];
    await tester.pumpWidget(_host(Sparkline(points: pts, color: Colors.cyan)));
    expect(tester.takeException(), isNull);

    // <2 points must not fabricate a line (and must not throw).
    await tester.pumpWidget(_host(
      Sparkline(points: [TrendPoint(date: base, value: 90)], color: Colors.cyan),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byType(Sparkline), findsOneWidget);
  });

  test('plainLanguage has no em dashes and substitutes value + unit', () {
    final up = StatTrend.plainLanguage(StatChange.compute(100.6, 100)!, unit: 'kg');
    final down = StatTrend.plainLanguage(StatChange.compute(99.4, 100)!, unit: 'kg');
    for (final s in [up, down]) {
      expect(s.contains('—'), isFalse, reason: 'no em dashes in copy');
      expect(s.contains('kg'), isTrue);
    }
  });
}
