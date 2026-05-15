// Adaptive macro simulator. The marquee nutrition calculator.
//
// Models a 4-week dieting cycle the way MacroFactor, Carbon, and Stronger U
// do it under the hood: pick a starting target, observe weekly weight change,
// and nudge calories up or down to keep the actual trajectory matching the
// goal trajectory. Carbs absorb the calorie change; protein and fat stay
// roughly constant because their roles (muscle synthesis, hormones) aren't
// trajectory-dependent.
//
// Why weekly, not daily: day-to-day weight has 1-2 kg of water + glycogen
// noise that swamps real fat change. Aggregating to a 7-day trend filters
// most of that. (See Hall 2008 for the energy-balance physiology.)
//
// Adjustment rules:
//   - Δactual within ±25% of goal → hold (you're on track).
//   - Loss too slow / gain too slow → -100 kcal/day (cut) or +100 (bulk).
//   - Loss too fast / gain too fast → +100 kcal/day (cut) or -100 (bulk).
//   - 3 consecutive holds with no progress → plateau. Apply a 2x adjustment
//     and recommend a diet break.
//
// Metabolic adaptation: NEAT and BMR drop during a cut as adaptive
// thermogenesis kicks in. A static target loses effectiveness after ~3
// weeks. This is exactly what adaptive macros are designed to solve.
// (Trexler, Smith-Ryan, Norton 2014.)
//
// References:
//   Hall KD (2008). What is the required energy deficit per unit weight
//     loss? Int J Obes (Lond) 32(3):573-6.
//   Trexler ET, Smith-Ryan AE, Norton LE (2014). Metabolic adaptation to
//     weight loss: implications for the athlete. JISSN 11:7.
//   Mifflin MD, St Jeor ST et al. (1990). Am J Clin Nutr 51(2):241-7.

import { round } from './units';
import { estimateTdee, calculateMacros, type MacroGoal } from './macros';

export interface AdaptiveMacroInputs {
  startingWeightKg: number;
  heightCm: number;
  age: number;
  sex: 'male' | 'female';
  activityMultiplier: number;
  goal: MacroGoal;             // 'cut' or 'bulk' (maintain has no trajectory)
  weeklyTargetKg: number;      // positive number; sign comes from goal
}

export interface AdaptiveMacroWeek {
  weekNum: number;
  projectedWeight: number;
  actualWeeklyChange: number;
  calorieTarget: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
  adjustment: number;
  note: string;
}

export interface AdaptiveMacroResult {
  weeks: AdaptiveMacroWeek[];
  summary: string;
  startingTdee: number;
}

// Energy density of body tissue: ~7,700 kcal per kg of mixed lean + fat
// loss. This is the textbook "1 lb = 3,500 kcal" rule expressed in metric.
const KCAL_PER_KG = 7700;

// Calorie adjustment per step.
const STEP_KCAL = 100;

// Simulated noise: real weight loss tracks roughly the target but with
// adaptive thermogenesis dragging it down over weeks. We model this by
// having actual change drift below target as the cut continues.
function simulateActualChange(
  weekNum: number,
  targetChange: number,
  goal: MacroGoal,
): number {
  // Adaptive thermogenesis: weight change slows ~5-10% per week in a cut
  // once you're past week 1. Bulks get smoother for a different reason
  // (calorie partitioning improves with training adaptation), so we
  // mirror it.
  const adaptationDrag = goal === 'cut' ? 0.93 ** weekNum : 1.02 ** weekNum;
  return round(targetChange * adaptationDrag, 2);
}

export function calculateAdaptiveMacros(inputs: AdaptiveMacroInputs): AdaptiveMacroResult {
  const {
    startingWeightKg,
    heightCm,
    age,
    sex,
    activityMultiplier,
    goal,
    weeklyTargetKg,
  } = inputs;

  const startingTdee = estimateTdee(startingWeightKg, heightCm, age, sex, activityMultiplier);

  // Direction-aware target: cut = negative weight change, bulk = positive.
  const signedTarget = goal === 'cut' ? -Math.abs(weeklyTargetKg) : Math.abs(weeklyTargetKg);
  const dailyDeficit = (signedTarget * KCAL_PER_KG) / 7;

  // Week 0 calorie target derived from TDEE + the energy-balance math
  // (not from a flat goal multiplier), so it's calibrated to the user's
  // actual weekly rate.
  let calorieTarget = Math.round(startingTdee + dailyDeficit);

  // Hard floors so the calculator never recommends an unsafe intake.
  const minCalories = sex === 'male' ? 1500 : 1200;
  calorieTarget = Math.max(calorieTarget, minCalories);

  const weeks: AdaptiveMacroWeek[] = [];
  let currentWeight = startingWeightKg;
  let holdsWithoutProgress = 0;

  for (let weekNum = 1; weekNum <= 4; weekNum++) {
    // What actually happens this week (simulated).
    const actualChange = simulateActualChange(weekNum, signedTarget, goal);
    currentWeight = round(currentWeight + actualChange, 2);

    // Compute macro split for this week's calorie target.
    const macros = calculateMacros({
      tdee: calorieTarget / 1.0, // calorieTarget already equals daily intake
      bodyweightKg: currentWeight,
      goal: 'maintain',           // we already baked the deficit in
      preset: 'balanced',
    });

    // Compare actual vs. target. Tolerance is ±25% of target rate.
    const diff = actualChange - signedTarget;
    const tolerance = Math.abs(signedTarget) * 0.25;
    let adjustment = 0;
    let note = 'Holding steady. Trajectory is on target.';

    if (Math.abs(diff) <= tolerance) {
      holdsWithoutProgress += Math.abs(actualChange) < 0.05 ? 1 : 0;
      if (holdsWithoutProgress >= 3) {
        // Plateau. Larger correction + diet break suggestion.
        adjustment = goal === 'cut' ? -STEP_KCAL * 2 : STEP_KCAL * 2;
        note = 'Three weeks without progress. Plateau detected. Take a 7-day diet break at maintenance, then resume at the new target.';
        holdsWithoutProgress = 0;
      }
    } else if (goal === 'cut') {
      if (actualChange > signedTarget) {
        // Losing too slowly (actualChange less negative than target).
        adjustment = -STEP_KCAL;
        note = `Loss is slower than goal. Cutting 100 kcal from daily target.`;
      } else {
        // Losing too fast.
        adjustment = STEP_KCAL;
        note = `Loss is faster than goal. Adding 100 kcal back to protect lean mass.`;
      }
      holdsWithoutProgress = 0;
    } else {
      if (actualChange < signedTarget) {
        adjustment = STEP_KCAL;
        note = `Gain is slower than goal. Adding 100 kcal to the daily target.`;
      } else {
        adjustment = -STEP_KCAL;
        note = `Gain is faster than goal (likely excess fat). Trimming 100 kcal.`;
      }
      holdsWithoutProgress = 0;
    }

    weeks.push({
      weekNum,
      projectedWeight: currentWeight,
      actualWeeklyChange: actualChange,
      calorieTarget,
      proteinG: macros.protein_g,
      carbsG: macros.carbs_g,
      fatG: macros.fat_g,
      adjustment,
      note,
    });

    // Apply the adjustment to next week's target.
    calorieTarget = Math.max(calorieTarget + adjustment, minCalories);
  }

  const totalChange = round(currentWeight - startingWeightKg, 2);
  const summary =
    goal === 'cut'
      ? `Projected loss over 4 weeks: ${Math.abs(totalChange)} kg. Final daily target: ${weeks[weeks.length - 1].calorieTarget} kcal. The algorithm adjusted ${weeks.filter((w) => w.adjustment !== 0).length} time(s) to stay on trajectory.`
      : `Projected gain over 4 weeks: ${totalChange} kg. Final daily target: ${weeks[weeks.length - 1].calorieTarget} kcal. The algorithm adjusted ${weeks.filter((w) => w.adjustment !== 0).length} time(s) to stay on trajectory.`;

  return {
    weeks,
    summary,
    startingTdee,
  };
}
