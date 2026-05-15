// 1RM (one-rep max) estimation formulas.
//
// Inputs are weight lifted and reps completed at submaximal effort (typically
// 2-10 reps). Each formula has known accuracy bands; consensus is to use
// Epley above ~5 reps and Brzycki below ~5 reps. We expose all 7 and let the
// user compare side-by-side.
//
// References:
//   Epley B (1985). "Poundage Chart". Boyd Epley Workout. Lincoln, NE.
//   Brzycki M (1993). "Strength testing — predicting a 1RM from reps-to-fatigue".
//     Journal of Physical Education, Recreation & Dance 64(1).
//   Lombardi VP (1989). Beginning Weight Training: The Safe and Effective Way.
//   Lander J (1985). "Maximum based on reps". NSCA Journal 6(60-61).
//   O'Conner B, Simmons J, O'Shea P (1989). Weight Training Today.
//   Mayhew JL, Ball TE, Arnold MD, Bowen JC (1992). "Relative muscular
//     endurance performance as a predictor of bench press strength in college
//     men and women". Journal of Applied Sport Science Research 6(4).
//   Wathen D (1994). "Load assignment". Essentials of Strength Training
//     and Conditioning (NSCA).

import { round } from './units';

export type OneRmFormula =
  | 'epley'
  | 'brzycki'
  | 'lombardi'
  | 'lander'
  | 'oconnor'
  | 'mayhew'
  | 'wathen';

export interface OneRmFormulaInfo {
  key: OneRmFormula;
  name: string;
  bestFor: string;
  year: number;
  citation: string;
}

export const ONE_RM_FORMULAS: OneRmFormulaInfo[] = [
  {
    key: 'epley',
    name: 'Epley',
    bestFor: 'Most accurate for 2-10 reps; best general-purpose default',
    year: 1985,
    citation: 'Epley (1985), Boyd Epley Workout',
  },
  {
    key: 'brzycki',
    name: 'Brzycki',
    bestFor: 'Most accurate at 2-5 reps (low rep / strength range)',
    year: 1993,
    citation: 'Brzycki (1993), JOPERD 64(1)',
  },
  {
    key: 'lombardi',
    name: 'Lombardi',
    bestFor: 'Conservative estimate, best for technique work',
    year: 1989,
    citation: 'Lombardi (1989), Beginning Weight Training',
  },
  {
    key: 'lander',
    name: 'Lander',
    bestFor: 'Good for upper-body lifts at 3-10 reps',
    year: 1985,
    citation: 'Lander (1985), NSCA Journal',
  },
  {
    key: 'oconnor',
    name: "O'Conner",
    bestFor: 'Linear formula; conservative at high reps',
    year: 1989,
    citation: "O'Conner et al. (1989)",
  },
  {
    key: 'mayhew',
    name: 'Mayhew',
    bestFor: 'Bench press specifically; validated in college men/women',
    year: 1992,
    citation: 'Mayhew et al. (1992), JASSR 6(4)',
  },
  {
    key: 'wathen',
    name: 'Wathen',
    bestFor: 'NSCA-published; bench, squat, deadlift',
    year: 1994,
    citation: 'Wathen (1994), NSCA Essentials',
  },
];

// All formulas accept weight in any unit and return same unit (they're scale-invariant).
export const oneRm = {
  epley: (w: number, r: number): number => w * (1 + r / 30),
  brzycki: (w: number, r: number): number => (w * 36) / (37 - r),
  lombardi: (w: number, r: number): number => w * Math.pow(r, 0.1),
  lander: (w: number, r: number): number => (100 * w) / (101.3 - 2.67123 * r),
  oconnor: (w: number, r: number): number => w * (1 + 0.025 * r),
  mayhew: (w: number, r: number): number =>
    (100 * w) / (52.2 + 41.9 * Math.exp(-0.055 * r)),
  wathen: (w: number, r: number): number =>
    (100 * w) / (48.8 + 53.8 * Math.exp(-0.075 * r)),
};

export interface OneRmResult {
  formula: OneRmFormula;
  name: string;
  value: number;
  bestFor: string;
}

export function calculateAllOneRm(weight: number, reps: number): OneRmResult[] {
  if (reps < 1 || reps > 20 || weight <= 0) {
    return [];
  }
  // At reps = 1, every formula returns weight unchanged. Show explicit message
  // upstream in the UI.
  return ONE_RM_FORMULAS.map((f) => ({
    formula: f.key,
    name: f.name,
    value: round(oneRm[f.key](weight, reps), 1),
    bestFor: f.bestFor,
  }));
}

// Recommended formula given rep count.
export function recommendedFormula(reps: number): OneRmFormula {
  if (reps <= 5) return 'brzycki';
  if (reps <= 10) return 'epley';
  return 'lombardi';
}

// Percentage tables: given 1RM, show typical reps possible at each %.
// Useful for converting between 1RM and working sets.
export const REP_PERCENTAGE_TABLE: { reps: number; pct: number }[] = [
  { reps: 1, pct: 100 },
  { reps: 2, pct: 95 },
  { reps: 3, pct: 93 },
  { reps: 4, pct: 90 },
  { reps: 5, pct: 87 },
  { reps: 6, pct: 85 },
  { reps: 8, pct: 80 },
  { reps: 10, pct: 75 },
  { reps: 12, pct: 70 },
  { reps: 15, pct: 65 },
];

export function repsAtPercent(oneRmValue: number, pct: number): number {
  return round((oneRmValue * pct) / 100, 1);
}
