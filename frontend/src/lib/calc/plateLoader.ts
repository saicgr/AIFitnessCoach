// Plate loader.
//
// Given a target weight on the bar, a bar weight, and the available plate
// inventory, returns the optimal per-side plate combination using a greedy
// descending algorithm. Greedy is provably optimal here because barbell
// plates are a canonical coin system (each denomination is a multiple of
// the next smaller one, or close enough that greedy never errs in practice).
//
// All math is unit-agnostic. The caller chooses lb or kg sets.

export interface PlateLoadResult {
  perSide: number[];        // descending list of plates loaded on one side
  loaded: number;           // total weight actually loaded (bar + 2 * sum(perSide))
  remaining: number;        // target minus loaded (>=0)
  exact: boolean;           // true if loaded === target
}

export function loadPlates(
  targetWeight: number,
  barWeight: number,
  plates: number[],
): PlateLoadResult {
  if (targetWeight <= barWeight) {
    return {
      perSide: [],
      loaded: barWeight,
      remaining: Math.max(0, targetWeight - barWeight),
      exact: targetWeight === barWeight,
    };
  }

  // Weight to put on each side
  let perSideTarget = (targetWeight - barWeight) / 2;
  const sortedPlates = [...plates].sort((a, b) => b - a);
  const loaded: number[] = [];

  // Greedy: pick the largest plate that fits, repeat.
  // Allow up to 10 of each plate (sensible per-side cap).
  for (const plate of sortedPlates) {
    while (perSideTarget >= plate - 1e-6 && loaded.length < 20) {
      loaded.push(plate);
      perSideTarget -= plate;
      perSideTarget = Math.round(perSideTarget * 100) / 100;
    }
  }

  const perSideLoaded = loaded.reduce((a, b) => a + b, 0);
  const totalLoaded = barWeight + 2 * perSideLoaded;
  const remaining = Math.max(0, targetWeight - totalLoaded);

  return {
    perSide: loaded,
    loaded: Math.round(totalLoaded * 100) / 100,
    remaining: Math.round(remaining * 100) / 100,
    exact: remaining < 1e-6,
  };
}

// Standard inventories
export const PLATES_LB: number[] = [45, 35, 25, 15, 10, 5, 2.5];
export const PLATES_KG: number[] = [25, 20, 15, 10, 5, 2.5, 1.25];

// Standard bar weights
export const BAR_LB = 45;
export const BAR_KG = 20;

// Convenience: full plate inventory with fractional ("change") plates.
export const PLATES_LB_WITH_FRACTIONAL: number[] = [45, 35, 25, 15, 10, 5, 2.5, 1.25, 0.5, 0.25];
export const PLATES_KG_WITH_FRACTIONAL: number[] = [25, 20, 15, 10, 5, 2.5, 1.25, 0.5, 0.25];
