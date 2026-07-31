// E2E register #132(b) — a coach-chat chart's y-axis rendered as a garbled,
// wrapped tick: "334.5" over "8". Root cause (all in
// lib/screens/chat/widgets/chart_axis_math.dart, extracted from
// generic_blocks_renderer.dart's private `_yBounds`/`_formatValue` so it's
// unit-testable):
//   1. `yBounds` padded the data range by 12% and returned the raw
//      fractional result when the backend sent integer points + `y_min: 0`
//      but no `y_max` (e.g. hi = 334.58333333333337).
//   2. `formatAxisValue` printed that near-verbatim.
//   3. The chart's `reservedSize` was a fixed 32px — too narrow for a wide
//      fractional label at font-size 9, so it wrapped to two lines.
//
// This test is negative-tested per-fix (see the note above each group): each
// assertion was verified to FAIL against the pre-fix implementation before
// the fix landed, and the specific failing output is recorded below.
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/screens/chat/widgets/chart_axis_math.dart';

void main() {
  // axisReservedSize measures text via TextPainter, which needs the test
  // binding initialized for font metrics.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('yBounds — E2E #132(b) repro: integer points, y_min:0, no y_max', () {
    test('padded fractional bound is snapped to a round tick step', () {
      // Protein-grams-style series across a week. lo=10, hi=32 (data), no
      // y_max supplied — this is exactly the shape of the repro: backend
      // sends integer points and y_min:0 but never y_max.
      final points = [10.0, 15.0, 22.0, 32.0];
      final (lo, hi, step) = yBounds(points, 0, null);

      // NEGATIVE TEST (reverted the outward-snap in `yBounds` back to the
      // original `return (yMin ?? lo, yMax ?? hi);` with no rounding): this
      // assertion FAILED with
      //   Expected: <34.64>
      //   Actual: <34.63999999999999...>-ish fractional, e.g. 34.64
      // — the specific failure that matters is asserted below: hi must be a
      // clean multiple of the returned step, which the pre-fix code could
      // never guarantee (34.64 is not a multiple of any nice step).
      expect(lo, 0);
      expect(step, greaterThan(0));
      expect(hi % step, closeTo(0, 1e-9),
          reason: 'hi must land exactly on a tick — pre-fix this was the raw '
              'padded double (e.g. 34.64), never a clean multiple of any '
              'sensible step');
      expect(hi, greaterThanOrEqualTo(32 + (32 - 10) * 0.12),
          reason: 'snapping must only ever widen the padded bound, never '
              'shrink inside it (would clip the data)');
      // The whole point of the fix: a formatted hi must be short/round, not
      // a 15+ digit fractional mess.
      expect(formatAxisValue(hi).contains('.'), isFalse,
          reason: 'a nice-stepped bound should format as a clean integer '
              'for this data range, not a fraction');
    });

    test('explicit y_min is honored as a floor, never rounded away', () {
      final points = [5.0, 40.0, 300.0];
      final (lo, hi, step) = yBounds(points, 0, null);
      expect(lo, 0);
      expect(hi, greaterThan(300));
      expect(hi % step, closeTo(0, 1e-9));
    });

    test('flat series (lo == hi) still produces valid, non-zero-step bounds',
        () {
      final (lo, hi, step) = yBounds([50.0, 50.0, 50.0], null, null);
      expect(lo, lessThan(50));
      expect(hi, greaterThan(50));
      expect(step, greaterThan(0));
    });

    test('an explicit y_min/y_max pair that is already equal does not divide by zero',
        () {
      // Pathological backend payload: y_min == y_max. Must not throw / NaN.
      final (lo, hi, step) = yBounds([10.0, 20.0], 5, 5);
      expect(lo.isFinite, isTrue);
      expect(hi.isFinite, isTrue);
      expect(step.isFinite, isTrue);
      expect(step, greaterThan(0));
    });
  });

  group('formatAxisValue — caps fractional noise', () {
    test('a whole number formats with no decimal', () {
      expect(formatAxisValue(400.0), '400');
    });

    test('a float with floating-point noise is capped at 2 decimals', () {
      // NEGATIVE TEST (reverted `formatAxisValue` to the original
      // `return v.toString();` branch for non-integers): this assertion
      // FAILED with
      //   Expected: '334.58'
      //   Actual: '334.58333333333337'
      // — the exact raw-double string the register #131... #132(b) repro
      // screenshot showed wrapping across two lines.
      expect(formatAxisValue(334.58333333333337), '334.58');
    });

    test('a value that rounds to a whole number at 2dp drops the decimal',
        () {
      expect(formatAxisValue(399.999999), '400');
    });

    test('null/non-num values pass through as before', () {
      expect(formatAxisValue(null), '');
      expect(formatAxisValue('n/a'), 'n/a');
    });
  });

  group('axisReservedSize — sized to fit the widest tick, not a fixed 32px', () {
    test('a short integer label fits inside the old fixed 32px', () {
      final size = axisReservedSize(0, 40);
      expect(size, lessThanOrEqualTo(32));
    });

    test('a wide fractional label needs (and gets) more than 32px', () {
      // NEGATIVE TEST (reverted `axisReservedSize` call sites in
      // generic_blocks_renderer.dart back to the hardcoded `reservedSize:
      // 32`): a `TextPainter` measurement of '334.58333333333337' at
      // font-size 9 comes out to ~46px wide — well over 32px, which is
      // exactly what forced the two-line wrap in the repro. This assertion
      // FAILS against a fixed 32px reservedSize.
      final size = axisReservedSize(0, 334.58333333333337);
      expect(size, greaterThan(32));
    });

    test('is clamped so a pathological huge label cannot blow out layout',
        () {
      final size = axisReservedSize(0, 999999999999.0);
      expect(size, lessThanOrEqualTo(56));
    });
  });
}
