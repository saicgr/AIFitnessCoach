// Carb cycling: high / medium / low carb days matched to training intensity.
//
// Premise: carbs are the dominant fuel for glycolytic training (sets of 5-15
// reps, intervals, sprints). On heavy training days carbs improve session
// quality and recovery. On rest days the body needs far less glycogen
// replenishment, so calories from carbs can be reduced and either pulled
// from the total (cut) or shifted to fat (maintain).
//
// Standard splits (Helms/Mata):
//   High day  → 4-5 g/kg carbs   (heavy compound days, long cardio)
//   Medium day → 2-3 g/kg carbs   (accessory, light lifting)
//   Low day    → 1 g/kg carbs     (full rest)
// Protein stays constant at ~2 g/kg every day (muscle protein synthesis
// is a daily requirement; it doesn't track training load).
// Fat fills the remaining calorie budget.
//
// Day-type distribution (default for a 4-day-per-week lifter):
//   ~50% of days high, ~30% medium, ~20% low. Adjustable based on actual
//   training schedule.
//
// Reference:
//   Mata F, Valenzuela PL, Gimenez J, Tur C, Ferreria D, Domínguez R,
//     Sanchez-Oliver AJ, Martínez Sanz JM (2019). Carbohydrate availability
//     and physical performance: physiological overview and practical
//     recommendations. Nutrients 11(5):1084.
//   Helms ER, Aragon AA, Fitschen PJ (2014). Evidence-based recommendations
//     for natural bodybuilding contest preparation. JISSN 11:20.

import { round } from './units';

export type DayType = 'high' | 'medium' | 'low';

export interface CarbCyclingInputs {
  bodyweightKg: number;
  trainingDaysPerWeek: number;   // 0-7
  goal: 'cut' | 'maintain';
  proteinPerKg?: number;          // default 2.0
}

export interface DayMacros {
  dayType: DayType;
  label: string;
  carbsG: number;
  carbsPerKg: number;
  proteinG: number;
  fatG: number;
  calories: number;
  daysPerWeek: number;
}

export interface CarbCyclingResult {
  days: DayMacros[];
  weeklyCarbsG: number;
  weeklyCaloriesAvg: number;
  exampleSchedule: string[];      // length 7
}

const CARBS_BY_DAY: Record<DayType, number> = {
  high: 4.5,
  medium: 2.5,
  low: 1.0,
};

const DAY_LABELS: Record<DayType, string> = {
  high: 'Heavy training day',
  medium: 'Light training day',
  low: 'Rest day',
};

const DAY_NAMES = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

export function calculateCarbCycling(inputs: CarbCyclingInputs): CarbCyclingResult {
  const { bodyweightKg, trainingDaysPerWeek, goal, proteinPerKg = 2.0 } = inputs;

  // Split training days into ~60% heavy (high), ~40% light (medium).
  // Non-training days are rest (low).
  const trainingDays = Math.max(0, Math.min(7, trainingDaysPerWeek));
  const restDays = 7 - trainingDays;
  const highDays = Math.ceil(trainingDays * 0.6);
  const mediumDays = trainingDays - highDays;
  const lowDays = restDays;

  const proteinG = Math.round(bodyweightKg * proteinPerKg);
  const proteinKcal = proteinG * 4;

  // Fat target: floor at 0.8 g/kg. On cut, lower fat on rest days. On
  // maintain, fat goes up on rest days to keep calories more even.
  const fatFloorG = Math.round(bodyweightKg * 0.8);
  const fatMaintainG = Math.round(bodyweightKg * 1.0);

  const buildDay = (dayType: DayType, daysPerWeek: number): DayMacros => {
    const carbsPerKg = CARBS_BY_DAY[dayType];
    const carbsG = Math.round(bodyweightKg * carbsPerKg);
    const carbsKcal = carbsG * 4;

    let fatG: number;
    if (goal === 'cut') {
      // Keep fat at floor every day to maximize carb availability for training.
      fatG = fatFloorG;
    } else {
      // On maintain, push fat slightly higher on low days for satiety.
      fatG = dayType === 'low' ? fatMaintainG : fatFloorG;
    }
    const fatKcal = fatG * 9;

    return {
      dayType,
      label: DAY_LABELS[dayType],
      carbsG,
      carbsPerKg,
      proteinG,
      fatG,
      calories: proteinKcal + carbsKcal + fatKcal,
      daysPerWeek,
    };
  };

  const days: DayMacros[] = [
    buildDay('high', highDays),
    buildDay('medium', mediumDays),
    buildDay('low', lowDays),
  ].filter((d) => d.daysPerWeek > 0);

  const weeklyCarbsG = days.reduce((sum, d) => sum + d.carbsG * d.daysPerWeek, 0);
  const weeklyKcal = days.reduce((sum, d) => sum + d.calories * d.daysPerWeek, 0);
  const weeklyCaloriesAvg = round(weeklyKcal / 7, 0);

  // Build an example 7-day schedule. Heavy days on Mon/Wed/Fri-style
  // spacing, light/medium interspersed, rest on weekends if possible.
  const schedule: DayType[] = [];
  let h = highDays;
  let m = mediumDays;
  let l = lowDays;
  const preferredOrder: DayType[] = ['high', 'low', 'high', 'medium', 'high', 'low', 'medium'];
  for (const slot of preferredOrder) {
    if (slot === 'high' && h > 0) { schedule.push('high'); h--; continue; }
    if (slot === 'medium' && m > 0) { schedule.push('medium'); m--; continue; }
    if (slot === 'low' && l > 0) { schedule.push('low'); l--; continue; }
    // Fallback: place whatever is left
    if (h > 0) { schedule.push('high'); h--; }
    else if (m > 0) { schedule.push('medium'); m--; }
    else if (l > 0) { schedule.push('low'); l--; }
  }
  // Pad if rounding left us short
  while (schedule.length < 7) {
    if (l > 0) { schedule.push('low'); l--; }
    else if (m > 0) { schedule.push('medium'); m--; }
    else if (h > 0) { schedule.push('high'); h--; }
    else schedule.push('low');
  }

  const exampleSchedule = schedule.slice(0, 7).map((d, i) => `${DAY_NAMES[i]}: ${DAY_LABELS[d]}`);

  return {
    days,
    weeklyCarbsG,
    weeklyCaloriesAvg,
    exampleSchedule,
  };
}
