/// Pure, testable calorie-lock macro rebalance helpers for the per-meal /
/// by-day targets editors.
///
/// "Meals drive the day" — each meal can hold a locked calorie budget while
/// the user drags one macro; the other two rebalance to keep the meal's
/// calories exactly equal to its captured `lockedKcal`. This mirrors the
/// corrected JS demo in
/// `docs/planning/nutrition-per-meal-2026-06/mockup.html` and is kept as a
/// standalone library so the algorithm can be unit-tested without a widget
/// tree (see `test/utils/macro_rebalance_test.dart`).
library;

/// Kilocalories per gram, by macro. Protein 4, carbs 4, fat 9 (Atwater).
const int kKcalPerGramProtein = 4;
const int kKcalPerGramCarbs = 4;
const int kKcalPerGramFat = 9;

/// Identifies which macro the user just dragged, so the rebalance pass knows
/// which two OTHER macros to recompute. Mirrors the edit sheet's private
/// `_MacroField` but lives here so the pure helpers don't depend on UI code.
enum MacroField { protein, carbs, fat }

/// A `(p, c, f)` macro triplet in grams.
typedef MacroGrams = ({int p, int c, int f});

/// Total kilocalories of a `(p, c, f)` gram triplet.
int kcalOf(int p, int c, int f) =>
    p * kKcalPerGramProtein + c * kKcalPerGramCarbs + f * kKcalPerGramFat;

/// Rebalances a locked-calorie meal after the user changes one macro.
///
/// Given the meal's current grams [p]/[c]/[f], its captured [lockedKcal]
/// budget (`T` below), the macro the user [changed] and the [newValue] they
/// dragged it to, returns a new `(p, c, f)` triplet whose total kcal equals
/// [lockedKcal] (subject to integer-gram resolution — the reconcile step
/// pushes any rounding drift into the *absorbing* macro, never the macro the
/// user just dragged, so `kcalOf` lands as close to `T` as integer grams
/// allow).
///
/// Behaviour by [changed] (matching the mockup JS exactly):
///  - **protein**: hard-stop protein at `floor(T/4)` so it can't exceed the
///    budget; the remaining kcal split across carbs/fat *preserving their
///    current C:F kcal ratio*; clamp ≥ 0, push any leftover into the other.
///  - **carbs**: protein + calories held → fat absorbs. Carbs hard-stop at
///    `floor((T - p*4)/4)`.
///  - **fat**: protein + calories held → carbs absorb. Fat hard-stops at
///    `floor((T - p*4)/9)`.
///
/// Then a reconcile pass folds integer-rounding drift into carbs.
MacroGrams rebalanceLocked({
  required int p,
  required int c,
  required int f,
  required int lockedKcal,
  required MacroField changed,
  required int newValue,
}) {
  final int t = lockedKcal;
  // Degenerate budget — nothing to distribute. Zero everything out.
  if (t <= 0) {
    switch (changed) {
      case MacroField.protein:
        return (p: newValue < 0 ? 0 : newValue, c: 0, f: 0);
      case MacroField.carbs:
        return (p: 0, c: newValue < 0 ? 0 : newValue, f: 0);
      case MacroField.fat:
        return (p: 0, c: 0, f: newValue < 0 ? 0 : newValue);
    }
  }

  int np = p;
  int nc = c;
  int nf = f;

  switch (changed) {
    case MacroField.protein:
      final int maxP = t ~/ kKcalPerGramProtein; // floor(T/4)
      int v = newValue;
      if (v < 0) v = 0;
      if (v > maxP) v = maxP;
      final int rem = t - v * kKcalPerGramProtein;
      final int cK = c * kKcalPerGramCarbs;
      final int fK = f * kKcalPerGramFat;
      final int tot = (cK + fK) == 0 ? 1 : (cK + fK); // preserve C:F ratio
      int newC = _max0(((rem * (cK / tot)) / kKcalPerGramCarbs).round());
      int newF =
          _max0(((rem - newC * kKcalPerGramCarbs) / kKcalPerGramFat).round());
      if (newF < 0) {
        newF = 0;
        newC = _max0((rem / kKcalPerGramCarbs).round());
      }
      np = v;
      nc = newC;
      nf = newF;
      break;

    case MacroField.carbs:
      final int maxC = _max0((t - p * kKcalPerGramProtein) ~/ kKcalPerGramCarbs);
      int v = newValue;
      if (v < 0) v = 0;
      if (v > maxC) v = maxC;
      nc = v;
      nf = _max0(
          ((t - p * kKcalPerGramProtein - v * kKcalPerGramCarbs) /
                  kKcalPerGramFat)
              .round());
      break;

    case MacroField.fat:
      final int maxF = _max0((t - p * kKcalPerGramProtein) ~/ kKcalPerGramFat);
      int v = newValue;
      if (v < 0) v = 0;
      if (v > maxF) v = maxF;
      nf = v;
      nc = _max0(
          ((t - p * kKcalPerGramProtein - v * kKcalPerGramFat) /
                  kKcalPerGramCarbs)
              .round());
      break;
  }

  // Reconcile integer-rounding drift into the ABSORBING macro so the meal
  // kcal lands as close to T as integer grams allow — never the macro the
  // user just dragged (that would move their explicit value off-target).
  //   protein changed → carbs/fat absorbed → reconcile into carbs
  //   carbs   changed → fat absorbed       → reconcile into fat
  //   fat     changed → carbs absorbed     → reconcile into carbs
  switch (changed) {
    case MacroField.protein:
    case MacroField.fat:
      final int drift = ((t - kcalOf(np, nc, nf)) / kKcalPerGramCarbs).round();
      if (drift != 0 && nc + drift >= 0) nc += drift;
      break;
    case MacroField.carbs:
      final int drift = ((t - kcalOf(np, nc, nf)) / kKcalPerGramFat).round();
      if (drift != 0 && nf + drift >= 0) nf += drift;
      break;
  }

  return (p: np, c: nc, f: nf);
}

int _max0(int v) => v < 0 ? 0 : v;
