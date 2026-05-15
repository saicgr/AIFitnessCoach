// 6-week (or N-week) fat loss protocol math.
//
// Protocol per source:
//   Maintenance cal = bodyweight_lb × 15
//   Daily target = maintenance - 500
//   Fat mass = bodyweight × bf_pct
//   LBM = bodyweight - fat_mass
//   Daily protein floor = 1 g per lb of LBM
//   Per-meal protein = 30-40 g across 3-4 meals/day (~3g leucine per meal)
//
//   Base loss per week (calorie deficit alone) = 1 lb (500 cal × 7 / 3500)
//   Walking bonus: 2 sessions/wk @ 20-30 min, 150-200 cal/session.
//     Source quote: "over 6 weeks, ~2 lbs of additional fat loss"
//     Per-week rate: 2/6 ≈ 0.333 lb/week
//   Cutting weekday alcohol bonus: 300-700 cal/day saved on weekdays.
//     Source quote: "over 6 weeks, 1.5-2 lbs of additional fat loss" (1.75 avg)
//     Per-week rate: 1.75/6 ≈ 0.292 lb/week
//
// Sources:
//   Helms ER, Aragon AA, Fitschen PJ (2014). Evidence-based recommendations
//     for natural bodybuilding contest preparation. JISSN 11:20.
//   Aragon AA, Schoenfeld BJ (2013). Nutrient timing revisited. JISSN 10:5.
//   Schoenfeld BJ, Aragon AA (2018). How much protein can the body use per
//     meal for muscle-building? JISSN 15:10.
//   Mata F et al. (2019). Carbohydrate availability and physical performance.
//     Nutrients 11(5):1084.

export interface ProtocolInputs {
  bodyweightLb: number;
  bodyFatPct: number;        // 0-100
  durationWeeks: number;     // 1-52
  addWalking: boolean;
  cutWeekdayAlcohol: boolean;
}

export interface ProtocolResult {
  // Daily targets
  maintenanceCal: number;
  dailyCalTarget: number;
  fatMassLb: number;
  lbmLb: number;
  dailyProteinG: number;
  perMealProteinMinG: number;
  perMealProteinMaxG: number;
  recommendedMeals: number;
  proteinCalsPerDay: number;
  proteinPctOfDailyCal: number;

  // Loss projections
  baseLossLb: number;        // From calorie deficit alone
  walkingBonusLb: number;    // 0 if checkbox off
  alcoholBonusLb: number;    // 0 if checkbox off
  totalLossLb: number;
  weeklyLossLb: number;      // average per week
  projectedEndWeightLb: number;

  // Weekly projection trajectory (for chart)
  weeklyProjection: Array<{ week: number; weightLb: number }>;

  // Sanity flags
  unsafeLossRate: boolean;   // true if avg weekly loss exceeds 1% bodyweight
  proteinExceedsCalories: boolean; // true if protein alone exceeds target
}

export const BASE_LOSS_PER_WEEK = 1.0;          // lb, from 500 cal/day deficit
export const WALKING_BONUS_PER_WEEK = 2 / 6;    // ~0.333 lb/wk per source
export const ALCOHOL_BONUS_PER_WEEK = 1.75 / 6; // ~0.292 lb/wk per source (avg of 1.5-2)
export const SAFE_WEEKLY_LOSS_PCT_OF_BW = 0.01; // 1% per Helms 2014

export function calculateProtocol(input: ProtocolInputs): ProtocolResult {
  const {
    bodyweightLb,
    bodyFatPct,
    durationWeeks,
    addWalking,
    cutWeekdayAlcohol,
  } = input;

  const safeWeeks = Math.max(1, Math.min(52, durationWeeks));
  const safeBfPct = Math.max(3, Math.min(60, bodyFatPct));
  const safeWeight = Math.max(80, Math.min(700, bodyweightLb));

  const maintenanceCal = Math.round(safeWeight * 15);
  const dailyCalTarget = maintenanceCal - 500;

  const fatMassLb = round1(safeWeight * (safeBfPct / 100));
  const lbmLb = round1(safeWeight - fatMassLb);

  const dailyProteinG = Math.round(lbmLb); // 1 g per lb LBM
  const perMealProteinMinG = 30;
  const perMealProteinMaxG = 40;

  // Recommend 4 meals when daily protein ≥ 120 g, otherwise 3
  const recommendedMeals = dailyProteinG >= 120 ? 4 : 3;

  const proteinCalsPerDay = dailyProteinG * 4;
  const proteinPctOfDailyCal = round1((proteinCalsPerDay / dailyCalTarget) * 100);

  // Loss projections
  const baseLossLb = round2(BASE_LOSS_PER_WEEK * safeWeeks);
  const walkingBonusLb = addWalking
    ? round2(WALKING_BONUS_PER_WEEK * safeWeeks)
    : 0;
  const alcoholBonusLb = cutWeekdayAlcohol
    ? round2(ALCOHOL_BONUS_PER_WEEK * safeWeeks)
    : 0;
  const totalLossLb = round2(baseLossLb + walkingBonusLb + alcoholBonusLb);
  const weeklyLossLb = round2(totalLossLb / safeWeeks);
  const projectedEndWeightLb = round1(safeWeight - totalLossLb);

  // Weekly trajectory: linear interpolation
  const weeklyProjection: Array<{ week: number; weightLb: number }> = [];
  for (let w = 0; w <= safeWeeks; w++) {
    const lossSoFar = (totalLossLb / safeWeeks) * w;
    weeklyProjection.push({
      week: w,
      weightLb: round1(safeWeight - lossSoFar),
    });
  }

  const unsafeLossRate = weeklyLossLb / safeWeight > SAFE_WEEKLY_LOSS_PCT_OF_BW;
  const proteinExceedsCalories = proteinCalsPerDay > dailyCalTarget * 0.55;

  return {
    maintenanceCal,
    dailyCalTarget,
    fatMassLb,
    lbmLb,
    dailyProteinG,
    perMealProteinMinG,
    perMealProteinMaxG,
    recommendedMeals,
    proteinCalsPerDay,
    proteinPctOfDailyCal,

    baseLossLb,
    walkingBonusLb,
    alcoholBonusLb,
    totalLossLb,
    weeklyLossLb,
    projectedEndWeightLb,
    weeklyProjection,

    unsafeLossRate,
    proteinExceedsCalories,
  };
}

function round1(n: number): number {
  return Math.round(n * 10) / 10;
}

function round2(n: number): number {
  return Math.round(n * 100) / 100;
}
