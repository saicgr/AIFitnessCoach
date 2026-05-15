// Estimate how many weeks a cut or lean bulk should take.
//
// Cut math:
//   weight_to_lose = current_weight * ((current_bf - target_bf) / (100 - target_bf))
//   weeks = weight_to_lose / weekly_loss_target
//   Recommended weekly loss: 0.5-1.0% of bodyweight (Helms et al. 2014).
//   Above 1% / week, lean mass loss climbs sharply (Garthe et al. 2011).
//
// Bulk math:
//   weight_to_gain = goal weight gain
//   weeks = weight_to_gain / weekly_gain_target
//   Recommended weekly gain: 0.25-0.5% bodyweight for intermediates
//   (Aragon-Schoenfeld 2013 lean bulk guidance, lower bound from Helms).
//
// Caloric impact:
//   1 lb of fat ~= 3500 kcal, 1 kg ~= 7700 kcal.
//
// References:
//   Helms ER et al. (2014). Evidence-based recommendations for natural
//     bodybuilding contest preparation. JISSN 11:20.
//   Garthe I et al. (2011). Effect of two different weight-loss rates on body
//     composition and strength and power-related performance in elite athletes.
//     IJSNEM 21(2): 97-104.
//   Aragon AA, Schoenfeld BJ (2013). Nutrient timing revisited. JISSN 10:5.

import { kgToLb, lbToKg, round, type WeightUnit } from './units';

export type Mode = 'cut' | 'bulk';

export interface CutInputs {
  currentWeight: number;
  unit: WeightUnit;
  currentBodyFatPct: number;        // e.g. 22
  targetBodyFatPct: number;         // e.g. 15
  weeklyLossPct: number;            // 0.5-1.0 recommended
}

export interface BulkInputs {
  currentWeight: number;
  unit: WeightUnit;
  goalGain: number;                 // in same unit as currentWeight
  weeklyGainPct: number;            // 0.25-0.5 recommended
}

export interface DurationResult {
  weightChange: number;             // positive number, in input unit
  weeks: number;
  weeklyChange: number;             // in input unit
  totalCalorieImpact: number;       // total kcal deficit (cut) or surplus (bulk)
  dailyCalorieImpact: number;
  warnings: string[];
  notes: string[];
}

const KCAL_PER_KG = 7700;

export function estimateCut(inputs: CutInputs): DurationResult | null {
  const { currentWeight, currentBodyFatPct, targetBodyFatPct, weeklyLossPct, unit } = inputs;
  if (currentWeight <= 0 || weeklyLossPct <= 0) return null;
  if (targetBodyFatPct >= currentBodyFatPct) return null;
  if (targetBodyFatPct < 5) return null;

  // Body recomposition math: fat-free mass stays constant during a clean cut.
  const weightToLose =
    currentWeight * ((currentBodyFatPct - targetBodyFatPct) / (100 - targetBodyFatPct));
  const weeklyChange = currentWeight * (weeklyLossPct / 100);
  const weeks = weightToLose / weeklyChange;

  const weightToLoseKg = unit === 'lb' ? lbToKg(weightToLose) : weightToLose;
  const totalCalorieImpact = weightToLoseKg * KCAL_PER_KG;
  const dailyCalorieImpact = totalCalorieImpact / (weeks * 7);

  const warnings: string[] = [];
  const notes: string[] = [];

  if (weeklyLossPct > 1) {
    warnings.push(
      `Losing ${weeklyLossPct}% of bodyweight per week is above the 1% threshold where lean mass loss accelerates (Garthe 2011). Expect muscle and strength to take a hit.`,
    );
  } else if (weeklyLossPct < 0.4) {
    notes.push(
      `${weeklyLossPct}% per week is gentle. Easier to retain muscle and adhere, but the cut runs long.`,
    );
  }

  if (targetBodyFatPct < 10) {
    notes.push('Target body fat under 10% is contest-prep territory. Expect hormonal and strength downsides.');
  }

  if (weeks > 24) {
    warnings.push('Cuts longer than 6 months tend to stall on hormones and adherence. Consider a diet break every 8-12 weeks.');
  }

  return {
    weightChange: round(weightToLose, 1),
    weeks: round(weeks, 1),
    weeklyChange: round(weeklyChange, 2),
    totalCalorieImpact: Math.round(totalCalorieImpact),
    dailyCalorieImpact: Math.round(dailyCalorieImpact),
    warnings,
    notes,
  };
}

export function estimateBulk(inputs: BulkInputs): DurationResult | null {
  const { currentWeight, goalGain, weeklyGainPct, unit } = inputs;
  if (currentWeight <= 0 || goalGain <= 0 || weeklyGainPct <= 0) return null;

  const weeklyChange = currentWeight * (weeklyGainPct / 100);
  const weeks = goalGain / weeklyChange;

  const goalGainKg = unit === 'lb' ? lbToKg(goalGain) : goalGain;
  const totalCalorieImpact = goalGainKg * KCAL_PER_KG;
  const dailyCalorieImpact = totalCalorieImpact / (weeks * 7);

  const warnings: string[] = [];
  const notes: string[] = [];

  if (weeklyGainPct > 0.5) {
    warnings.push(
      `Gaining ${weeklyGainPct}% per week tips into "dirty bulk" territory. Expect noticeable fat gain alongside muscle.`,
    );
  } else if (weeklyGainPct < 0.2) {
    notes.push('Very slow gain rate. Easier to stay lean, but progress will feel invisible week to week.');
  }

  if (dailyCalorieImpact > 700) {
    warnings.push(
      `That requires a ${Math.round(dailyCalorieImpact)} kcal/day surplus. Above ~500 kcal/day the extra calories rarely become muscle.`,
    );
  }

  return {
    weightChange: round(goalGain, 1),
    weeks: round(weeks, 1),
    weeklyChange: round(weeklyChange, 2),
    totalCalorieImpact: Math.round(totalCalorieImpact),
    dailyCalorieImpact: Math.round(dailyCalorieImpact),
    warnings,
    notes,
  };
}

// Convenience: convert kcal totals for display in lbs if needed.
export const kcalToLbFat = (kcal: number): number => round(kcal / 3500, 1);
export const kcalToKgFat = (kcal: number): number => round(kcal / KCAL_PER_KG, 2);
// silence unused-import warning when kgToLb isn't used directly elsewhere
void kgToLb;
