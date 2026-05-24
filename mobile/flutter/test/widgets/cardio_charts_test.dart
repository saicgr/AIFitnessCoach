import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/widgets/cardio/elevation_profile.dart';
import 'package:fitwiz/widgets/cardio/pace_chart.dart';
import 'package:fitwiz/widgets/cardio/splits_chart.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('PaceChart', () {
    testWidgets('empty input renders SizedBox.shrink', (tester) async {
      await tester.pumpWidget(_wrap(const PaceChart(
        paceSeries: [],
        distanceUnit: 'mi',
      )));
      // No card, no fl_chart — just an empty shrink.
      expect(find.byType(LineChart), findsNothing);
      expect(find.text('Pace'), findsNothing);
    });

    test('pause segment emits null spots into the bar', () {
      final t0 = DateTime(2026, 1, 1, 8, 0, 0);
      final samples = <PaceSample>[
        for (var i = 0; i < 10; i++)
          (t: t0.add(Duration(seconds: i * 5)), secPerKm: 300.0),
      ];
      // Pause covers seconds 20-35 inclusive → indices 4..6.
      final pauses = <PauseSegment>[
        (
          start: t0.add(const Duration(seconds: 20)),
          end: t0.add(const Duration(seconds: 35)),
        ),
      ];
      final spots = PaceChart.buildSpots(
        PaceChart.smoothPace(samples),
        pauses,
        'km',
      );
      final nullCount = spots.where((s) => s == FlSpot.nullSpot).length;
      // The pause [20s, 35s) covers samples at t=20,25,30 → 3 null spots.
      expect(nullCount, 3);
      expect(spots.length, samples.length);
    });

    test('formatPace handles standard and edge values', () {
      expect(PaceChart.formatPace(300), '5:00');
      expect(PaceChart.formatPace(305), '5:05');
      expect(PaceChart.formatPace(-1), '—');
      expect(PaceChart.formatPace(double.nan), '—');
    });
  });

  group('ElevationProfile', () {
    test('totalAscent sums positive deltas only', () {
      final series = <AltitudeSample>[
        (meters: 100, cumulativeDistanceM: 0),
        (meters: 120, cumulativeDistanceM: 200), // +20
        (meters: 110, cumulativeDistanceM: 400), // -10 (ignored)
        (meters: 150, cumulativeDistanceM: 600), // +40
        (meters: 150, cumulativeDistanceM: 800), // 0
      ];
      expect(ElevationProfile.totalAscentMeters(series), 60);
    });

    test('empty / single-point series → 0 ascent', () {
      expect(ElevationProfile.totalAscentMeters(const []), 0);
      expect(
        ElevationProfile.totalAscentMeters(
            [(meters: 100, cumulativeDistanceM: 0)]),
        0,
      );
    });

    testWidgets('empty input renders SizedBox.shrink', (tester) async {
      await tester.pumpWidget(_wrap(const ElevationProfile(
        altitudeSeries: [],
        distanceUnit: 'mi',
      )));
      expect(find.byType(LineChart), findsNothing);
    });
  });

  group('SplitsChart', () {
    testWidgets('<1 unit total → SizedBox.shrink', (tester) async {
      // 400m total — less than 1 km, less than 1 mi.
      const splits = <SplitSample>[
        (kmOrMiIndex: 1, durationSec: 120, distanceM: 400.0),
      ];
      await tester.pumpWidget(_wrap(const SplitsChart(
        splits: splits,
        distanceUnit: 'km',
      )));
      expect(find.byType(BarChart), findsNothing);
      expect(find.text('Splits'), findsNothing);
    });

    test('faster-than-avg gets green tint, slower gets red tint', () {
      const base = Color(0xFF888888);
      // Faster: pace 270 vs avg 300 → green tint
      final faster = SplitsChart.tintForPace(base: base, pace: 270, avg: 300);
      // Slower: pace 330 vs avg 300 → red tint
      final slower = SplitsChart.tintForPace(base: base, pace: 330, avg: 300);
      // Equal: returns base
      final equal = SplitsChart.tintForPace(base: base, pace: 300, avg: 300);

      // Compare green vs red channels to confirm direction of tint.
      expect(faster.g, greaterThan(base.g));
      expect(slower.r, greaterThan(base.r));
      expect(slower.g, lessThanOrEqualTo(faster.g));
      // Equal stays exactly at base (delta = 0 → t = 0).
      expect(equal.r, base.r);
      expect(equal.g, base.g);
      expect(equal.b, base.b);
    });

    test('splitPaceSecPerUnit normalizes partial splits to per-unit pace', () {
      // 0.5 km in 150s = 5:00/km equivalent.
      const partial =
          (kmOrMiIndex: 5, durationSec: 150, distanceM: 500.0);
      expect(
        SplitsChart.splitPaceSecPerUnit(partial, 'km'),
        closeTo(300, 0.001),
      );
      // 1 mi in 480s = 8:00/mi exactly.
      const full =
          (kmOrMiIndex: 1, durationSec: 480, distanceM: 1609.344);
      expect(
        SplitsChart.splitPaceSecPerUnit(full, 'mi'),
        closeTo(480, 0.001),
      );
    });
  });
}
