import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/utils/macro_rebalance.dart';

void main() {
  group('kcalOf', () {
    test('uses Atwater 4/4/9', () {
      expect(kcalOf(50, 47, 14), 50 * 4 + 47 * 4 + 14 * 9);
      expect(kcalOf(0, 0, 0), 0);
      expect(kcalOf(100, 0, 0), 400);
      expect(kcalOf(0, 0, 10), 90);
    });
  });

  // Integer grams can't always hit the locked kcal exactly: when fat (9 kcal/g)
  // is the residual-absorbing macro, the leftover can be a non-multiple of 4,
  // and the carbs-reconcile step (4 kcal/g) can only land within a few kcal.
  // The protein/carbs-held cases (fat absorbs) and the fat/carbs-held cases
  // (carbs absorbs) are therefore checked within this tolerance — matching the
  // corrected mockup JS, which reconciles drift into carbs only.
  const tol = 5;

  group('rebalanceLocked — protein changed', () {
    test('dragging protein up holds the meal kcal', () {
      // Breakfast from the mockup: 50P/47C/14F = 514 kcal.
      const locked = 514;
      expect(kcalOf(50, 47, 14), locked);
      final r = rebalanceLocked(
        p: 50,
        c: 47,
        f: 14,
        lockedKcal: locked,
        changed: MacroField.protein,
        newValue: 60,
      );
      expect(r.p, 60);
      expect(kcalOf(r.p, r.c, r.f), closeTo(locked, tol));
    });

    test('preserves carbs:fat kcal ratio when protein drops', () {
      const locked = 514;
      // Start with carbs-heavy split; drop protein → carbs/fat both grow,
      // keeping roughly their existing kcal ratio.
      final r = rebalanceLocked(
        p: 50,
        c: 47,
        f: 14,
        lockedKcal: locked,
        changed: MacroField.protein,
        newValue: 30,
      );
      expect(r.p, 30);
      expect(kcalOf(r.p, r.c, r.f), closeTo(locked, tol));
      // carbs should still hold the majority of the non-protein kcal.
      expect(r.c * 4, greaterThan(r.f * 9));
    });

    test('protein hard-stops at floor(T/4)', () {
      const locked = 514;
      final r = rebalanceLocked(
        p: 50,
        c: 47,
        f: 14,
        lockedKcal: locked,
        changed: MacroField.protein,
        newValue: 999,
      );
      expect(r.p, locked ~/ 4); // 128
      // The other two are driven to (near) zero — only the <4 kcal protein
      // remainder can leak into a single carb gram via the reconcile pass.
      expect(r.c, lessThanOrEqualTo(1));
      expect(r.f, 0);
    });
  });

  group('rebalanceLocked — carbs changed', () {
    test('fat absorbs, protein + kcal held', () {
      const locked = 514;
      final r = rebalanceLocked(
        p: 50,
        c: 47,
        f: 14,
        lockedKcal: locked,
        changed: MacroField.carbs,
        newValue: 60,
      );
      expect(r.p, 50); // protein untouched
      expect(r.c, 60);
      // Fat (9 kcal/g) absorbs the remainder → within integer-gram tolerance.
      expect(kcalOf(r.p, r.c, r.f), closeTo(locked, tol));
    });

    test('carbs hard-stop floors fat at 0', () {
      const locked = 514;
      final r = rebalanceLocked(
        p: 50,
        c: 47,
        f: 14,
        lockedKcal: locked,
        changed: MacroField.carbs,
        newValue: 999,
      );
      // maxC = floor((514 - 200)/4) = 78; reconcile may add the <4 kcal
      // remainder as one extra carb gram.
      expect(r.c, inInclusiveRange(78, 79));
      expect(r.f, 0);
      expect(r.p, 50);
    });
  });

  group('rebalanceLocked — fat changed', () {
    test('carbs absorb, protein + kcal held', () {
      const locked = 514;
      final r = rebalanceLocked(
        p: 50,
        c: 47,
        f: 14,
        lockedKcal: locked,
        changed: MacroField.fat,
        newValue: 20,
      );
      expect(r.p, 50);
      expect(r.f, 20);
      expect(kcalOf(r.p, r.c, r.f), closeTo(locked, tol));
    });

    test('fat hard-stops floors carbs at 0', () {
      const locked = 514;
      final r = rebalanceLocked(
        p: 50,
        c: 47,
        f: 14,
        lockedKcal: locked,
        changed: MacroField.fat,
        newValue: 999,
      );
      // maxF = floor((514 - 200)/9) = 34; the <9 kcal remainder lands in
      // carbs via the absorb + reconcile steps.
      expect(r.f, 34);
      expect(r.c, lessThanOrEqualTo(2));
      expect(r.p, 50);
    });
  });

  group('rebalanceLocked — rounding reconcile', () {
    test('kcal stays within integer-gram tolerance across a protein sweep', () {
      const locked = 1722 ~/ 3; // ~574 per meal
      for (int newP = 0; newP <= 140; newP += 7) {
        final r = rebalanceLocked(
          p: 50,
          c: 60,
          f: 18,
          lockedKcal: locked,
          changed: MacroField.protein,
          newValue: newP,
        );
        expect(kcalOf(r.p, r.c, r.f), closeTo(locked, tol),
            reason: 'protein=$newP should hold ~$locked kcal');
        expect(r.p, greaterThanOrEqualTo(0));
        expect(r.c, greaterThanOrEqualTo(0));
        expect(r.f, greaterThanOrEqualTo(0));
      }
    });

    test('kcal holds across a carbs sweep', () {
      const locked = 600;
      for (int newC = 0; newC <= 120; newC += 5) {
        final r = rebalanceLocked(
          p: 40,
          c: 50,
          f: 20,
          lockedKcal: locked,
          changed: MacroField.carbs,
          newValue: newC,
        );
        expect(kcalOf(r.p, r.c, r.f), closeTo(locked, tol),
            reason: 'carbs=$newC');
      }
    });

    test('kcal holds across a fat sweep', () {
      const locked = 600;
      for (int newF = 0; newF <= 60; newF += 3) {
        final r = rebalanceLocked(
          p: 40,
          c: 50,
          f: 20,
          lockedKcal: locked,
          changed: MacroField.fat,
          newValue: newF,
        );
        expect(kcalOf(r.p, r.c, r.f), closeTo(locked, tol), reason: 'fat=$newF');
      }
    });
  });

  group('rebalanceLocked — edge cases', () {
    test('zero-kcal carbs+fat baseline still distributes on protein drop', () {
      // All non-protein kcal are zero — the C:F ratio is undefined. The
      // algorithm (matching the mockup) sends carbs to 0 then loads the
      // remainder into fat, with rounding reconciled into carbs.
      const locked = 400;
      final r = rebalanceLocked(
        p: 100,
        c: 0,
        f: 0,
        lockedKcal: locked,
        changed: MacroField.protein,
        newValue: 50,
      );
      expect(r.p, 50);
      expect(kcalOf(r.p, r.c, r.f), closeTo(locked, tol));
      expect(r.f, greaterThan(0)); // remainder lands in fat
    });

    test('degenerate locked budget of 0 zeroes the others', () {
      final r = rebalanceLocked(
        p: 50,
        c: 47,
        f: 14,
        lockedKcal: 0,
        changed: MacroField.protein,
        newValue: 30,
      );
      expect(r, (p: 30, c: 0, f: 0));
    });

    test('negative newValue clamps to 0', () {
      const locked = 514;
      final r = rebalanceLocked(
        p: 50,
        c: 47,
        f: 14,
        lockedKcal: locked,
        changed: MacroField.carbs,
        newValue: -10,
      );
      expect(r.c, 0);
      expect(kcalOf(r.p, r.c, r.f), closeTo(locked, tol));
    });
  });
}
