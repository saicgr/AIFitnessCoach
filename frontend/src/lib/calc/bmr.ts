// Basal Metabolic Rate (BMR) equations.
//
// BMR = the calories your body burns at complete rest to maintain basic
// life function. It's the foundation of every TDEE/calorie-target
// calculation downstream.
//
// We expose 4 published equations side-by-side so the user can see the
// disagreement between them (often 100-300 kcal/day):
//   - Mifflin-St Jeor (1990): current gold standard for general population
//   - Harris-Benedict revised (Roza-Shizgal 1984): legacy reference
//   - Katch-McArdle: best for lean / athletic users with known body fat %
//   - Cunningham: highest multiplier on LBM; biased high for athletes
//
// References:
//   Mifflin MD, St Jeor ST et al. (1990). A new predictive equation for
//     resting energy expenditure in healthy individuals.
//     Am J Clin Nutr 51(2):241-7.
//   Roza AM, Shizgal HM (1984). The Harris Benedict equation reevaluated:
//     resting energy requirements and the body cell mass.
//     Am J Clin Nutr 40(1):168-82.
//   Katch FI, McArdle WD (1996). Exercise Physiology: Energy, Nutrition,
//     and Human Performance.
//   Cunningham JJ (1991). Body composition as a determinant of energy
//     expenditure: a synthetic review and a proposed general prediction
//     equation. Am J Clin Nutr 54(6):963-9.

import { round } from './units';
import type { Sex } from './units';

export type BmrMethod = 'mifflin' | 'harris' | 'katch' | 'cunningham';

export interface BmrMethodInfo {
  key: BmrMethod;
  name: string;
  bestFor: string;
  requiresBodyFat: boolean;
  citation: string;
}

export const BMR_METHODS: BmrMethodInfo[] = [
  {
    key: 'mifflin',
    name: 'Mifflin-St Jeor',
    bestFor: 'General population. Most accurate equation per ADA review.',
    requiresBodyFat: false,
    citation: 'Mifflin & St Jeor (1990), Am J Clin Nutr 51(2):241-7',
  },
  {
    key: 'harris',
    name: 'Harris-Benedict (revised)',
    bestFor: 'Legacy reference. Tends to overestimate by 5-15 percent.',
    requiresBodyFat: false,
    citation: 'Roza & Shizgal (1984), Am J Clin Nutr 40(1):168-82',
  },
  {
    key: 'katch',
    name: 'Katch-McArdle',
    bestFor: 'Lean and athletic users with known body fat percent.',
    requiresBodyFat: true,
    citation: 'Katch & McArdle (1996), Exercise Physiology',
  },
  {
    key: 'cunningham',
    name: 'Cunningham',
    bestFor: 'Athletes with high lean mass. Biases highest of the four.',
    requiresBodyFat: true,
    citation: 'Cunningham (1991), Am J Clin Nutr 54(6):963-9',
  },
];

// Mifflin-St Jeor (1990). Inputs metric.
export function mifflin(weightKg: number, heightCm: number, age: number, sex: Sex): number {
  const base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return sex === 'male' ? base + 5 : base - 161;
}

// Harris-Benedict revised by Roza & Shizgal (1984). Inputs metric.
export function harris(weightKg: number, heightCm: number, age: number, sex: Sex): number {
  if (sex === 'male') {
    return 88.362 + 13.397 * weightKg + 4.799 * heightCm - 5.677 * age;
  }
  return 447.593 + 9.247 * weightKg + 3.098 * heightCm - 4.330 * age;
}

// Katch-McArdle. Requires body fat percent.
export function katch(weightKg: number, bodyFatPct: number): number {
  const lbm = weightKg * (1 - bodyFatPct / 100);
  return 370 + 21.6 * lbm;
}

// Cunningham. Requires body fat percent.
export function cunningham(weightKg: number, bodyFatPct: number): number {
  const lbm = weightKg * (1 - bodyFatPct / 100);
  return 500 + 22 * lbm;
}

export interface BmrInputs {
  weightKg: number;
  heightCm: number;
  age: number;
  sex: Sex;
  bodyFatPct?: number; // optional. Required for katch and cunningham.
}

export interface BmrResult {
  method: BmrMethod;
  name: string;
  value: number; // kcal/day
  bestFor: string;
  citation: string;
  requiresBodyFat: boolean;
  available: boolean; // false if body fat % missing for katch/cunningham
}

export function calculateAllBmr(inputs: BmrInputs): BmrResult[] {
  const { weightKg, heightCm, age, sex, bodyFatPct } = inputs;
  if (weightKg <= 0 || heightCm <= 0 || age <= 0) return [];

  const hasBf = typeof bodyFatPct === 'number' && bodyFatPct > 0 && bodyFatPct < 70;

  return BMR_METHODS.map((m) => {
    let value = 0;
    let available = true;
    switch (m.key) {
      case 'mifflin':
        value = mifflin(weightKg, heightCm, age, sex);
        break;
      case 'harris':
        value = harris(weightKg, heightCm, age, sex);
        break;
      case 'katch':
        if (!hasBf) {
          available = false;
        } else {
          value = katch(weightKg, bodyFatPct!);
        }
        break;
      case 'cunningham':
        if (!hasBf) {
          available = false;
        } else {
          value = cunningham(weightKg, bodyFatPct!);
        }
        break;
    }
    return {
      method: m.key,
      name: m.name,
      value: round(value, 0),
      bestFor: m.bestFor,
      citation: m.citation,
      requiresBodyFat: m.requiresBodyFat,
      available,
    };
  });
}

// If the user has a body fat measurement, Katch-McArdle is the best fit.
// Otherwise Mifflin-St Jeor.
export function recommendedBmrMethod(hasBodyFat: boolean): BmrMethod {
  return hasBodyFat ? 'katch' : 'mifflin';
}
