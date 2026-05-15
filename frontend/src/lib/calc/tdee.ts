// Total Daily Energy Expenditure (TDEE).
//
// TDEE = BMR × activity multiplier. The multipliers below are the standard
// Harris-Benedict / Mifflin activity factors used in clinical nutrition
// and sports-science practice. They include NEAT (non-exercise activity)
// and average weekly training load, so do NOT add tracker calories on top.
//
// References:
//   Mifflin MD, St Jeor ST et al. (1990). Am J Clin Nutr 51(2):241-7.
//   Frankenfield D et al. (2005). Comparison of predictive equations for
//     resting metabolic rate in healthy nonobese and obese adults.
//     J Am Diet Assoc 105(5):775-89.

import { round } from './units';
import { calculateAllBmr, type BmrInputs, type BmrMethod } from './bmr';

export type ActivityLevel =
  | 'sedentary'
  | 'light'
  | 'moderate'
  | 'very'
  | 'athlete';

export interface ActivityInfo {
  key: ActivityLevel;
  name: string;
  description: string;
  multiplier: number;
}

export const ACTIVITY_LEVELS: ActivityInfo[] = [
  {
    key: 'sedentary',
    name: 'Sedentary',
    description: 'Desk job, little or no exercise.',
    multiplier: 1.2,
  },
  {
    key: 'light',
    name: 'Lightly active',
    description: 'Light exercise 1-3 days per week.',
    multiplier: 1.375,
  },
  {
    key: 'moderate',
    name: 'Moderately active',
    description: 'Moderate exercise 3-5 days per week.',
    multiplier: 1.55,
  },
  {
    key: 'very',
    name: 'Very active',
    description: 'Hard exercise 6-7 days per week.',
    multiplier: 1.725,
  },
  {
    key: 'athlete',
    name: 'Athlete',
    description: 'Twice-daily training or physically demanding job.',
    multiplier: 1.9,
  },
];

export function activityMultiplier(level: ActivityLevel): number {
  return ACTIVITY_LEVELS.find((a) => a.key === level)?.multiplier ?? 1.2;
}

export interface TdeeResult {
  method: BmrMethod;
  name: string;
  bmr: number;
  tdee: number;
  bestFor: string;
  citation: string;
  available: boolean;
}

export function calculateAllTdee(
  bmrInputs: BmrInputs,
  activity: ActivityLevel,
): TdeeResult[] {
  const m = activityMultiplier(activity);
  return calculateAllBmr(bmrInputs).map((r) => ({
    method: r.method,
    name: r.name,
    bmr: r.value,
    tdee: r.available ? round(r.value * m, 0) : 0,
    bestFor: r.bestFor,
    citation: r.citation,
    available: r.available,
  }));
}

// Calorie targets for common goals, anchored to a chosen TDEE.
// 500 kcal/day ≈ 1 lb/week weight change (textbook 7,700 kcal/kg rule).
export interface GoalTargets {
  cut: number;
  maintenance: number;
  bulk: number;
}

export function goalTargets(tdee: number): GoalTargets {
  return {
    cut: round(tdee - 500, 0),
    maintenance: round(tdee, 0),
    bulk: round(tdee + 300, 0),
  };
}
