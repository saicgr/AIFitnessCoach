// Recalculate true TDEE from 7 days of real-world data: actual average
// intake, weight 7 days ago, weight today. Use the result to set a new
// calorie target that hits the goal weekly weight change.
//
// Why this matters: published TDEE equations (Mifflin, Harris-Benedict)
// have a standard error of ±200-300 kcal/day for any individual. They give
// a starting estimate, not a personal number. The only way to know your
// real maintenance is to measure energy in vs. weight change out.
//
// Math:
//   actualEnergyBalance_kcal_per_day = (weight_change_kg × 7700) / 7
//   trueMaintenance_kcal = averageIntake - actualEnergyBalance
//   newTarget = trueMaintenance + (goalWeeklyChange_kg × 7700 / 7)
//
// Worked example:
//   intake = 2400 kcal/day, lost 0.4 kg in 7 days, goal = lose 0.5 kg/wk.
//   actualBalance = (-0.4 × 7700) / 7 = -440 kcal/day deficit
//   trueMaintenance = 2400 - (-440) = 2840 kcal
//   newTarget = 2840 + ((-0.5 × 7700) / 7) = 2840 - 550 = 2290 kcal
//
// Reference:
//   Hall KD (2007). Body fat and fat-free mass inter-relationships:
//     Forbes's theory revisited. NEJM 357:1611. (Energy balance physiology.)

import { round } from './units';

export interface AdaptiveCalorieInputs {
  avgDailyCalories: number;
  weight7DaysAgoKg: number;
  weightTodayKg: number;
  goalWeeklyChangeKg: number;   // signed: negative for cut, positive for bulk
  assumedTdee?: number;          // user's previous target's implied TDEE
}

export interface AdaptiveCalorieResult {
  actualWeightChange: number;
  actualEnergyBalance: number;   // kcal/day, signed
  trueMaintenance: number;       // your real TDEE based on these 7 days
  previousAssumedTdee: number | null;
  tdeeError: number | null;      // assumed - true
  newDailyTarget: number;
  expectedWeeklyChange: number;  // == goal, returned for display
  note: string;
}

const KCAL_PER_KG = 7700;

export function calculateAdaptiveCalories(inputs: AdaptiveCalorieInputs): AdaptiveCalorieResult {
  const {
    avgDailyCalories,
    weight7DaysAgoKg,
    weightTodayKg,
    goalWeeklyChangeKg,
    assumedTdee,
  } = inputs;

  const actualWeightChange = round(weightTodayKg - weight7DaysAgoKg, 2);
  const actualEnergyBalance = round((actualWeightChange * KCAL_PER_KG) / 7, 0);
  const trueMaintenance = Math.round(avgDailyCalories - actualEnergyBalance);
  const newDailyTarget = Math.round(trueMaintenance + (goalWeeklyChangeKg * KCAL_PER_KG) / 7);

  const previousAssumedTdee = assumedTdee ?? null;
  const tdeeError = previousAssumedTdee !== null ? previousAssumedTdee - trueMaintenance : null;

  let note: string;
  if (tdeeError === null) {
    note = `Your true maintenance is ${trueMaintenance} kcal. Set your daily target at ${newDailyTarget} kcal to hit your goal.`;
  } else if (Math.abs(tdeeError) <= 50) {
    note = `Your previous TDEE estimate was within 50 kcal of reality. The new target reflects normal weekly fluctuation.`;
  } else if (tdeeError > 0) {
    note = `Your previous TDEE estimate (${previousAssumedTdee} kcal) was ${tdeeError} kcal too high. This explains why progress was slower than expected. New target accounts for this.`;
  } else {
    note = `Your previous TDEE estimate (${previousAssumedTdee} kcal) was ${Math.abs(tdeeError)} kcal too low. You can eat more and still hit your goal.`;
  }

  return {
    actualWeightChange,
    actualEnergyBalance,
    trueMaintenance,
    previousAssumedTdee,
    tdeeError,
    newDailyTarget,
    expectedWeeklyChange: goalWeeklyChangeKg,
    note,
  };
}
