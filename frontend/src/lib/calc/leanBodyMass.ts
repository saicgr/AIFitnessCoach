// Lean Body Mass (LBM) estimation formulas.
//
// LBM = body mass minus fat mass. Useful as the denominator for protein
// targets, for dosing certain medications, and as a stable progress
// metric independent of fat fluctuations.
//
// We expose 3 published equations side-by-side:
//   - Boer (1984): most widely cited general formula
//   - James (1976): older but still commonly referenced
//   - Hume (1966): original LBM regression from cadaver data
//
// References:
//   Boer P (1984). Estimated lean body mass as an index for normalization
//     of body fluid volumes in humans. Am J Physiol 247(4 Pt 2):F632-6.
//   James W (1976). Research on Obesity: A Report of the DHSS/MRC Group.
//   Hume R (1966). Prediction of lean body mass from height and weight.
//     J Clin Pathol 19(4):389-91.

import { round } from './units';
import type { Sex } from './units';

export type LbmMethod = 'boer' | 'james' | 'hume';

export interface LbmMethodInfo {
  key: LbmMethod;
  name: string;
  bestFor: string;
  year: number;
  citation: string;
}

export const LBM_METHODS: LbmMethodInfo[] = [
  {
    key: 'boer',
    name: 'Boer',
    bestFor: 'Most cited modern formula. Best general default.',
    year: 1984,
    citation: 'Boer P (1984), Am J Physiol 247(4 Pt 2):F632-6',
  },
  {
    key: 'james',
    name: 'James',
    bestFor: 'Conservative for very heavy individuals. UK clinical use.',
    year: 1976,
    citation: 'James W (1976), Research on Obesity (DHSS/MRC)',
  },
  {
    key: 'hume',
    name: 'Hume',
    bestFor: 'Original LBM regression. Still used in pharmacology.',
    year: 1966,
    citation: 'Hume R (1966), J Clin Pathol 19(4):389-91',
  },
];

export function boer(weightKg: number, heightCm: number, sex: Sex): number {
  if (sex === 'male') {
    return 0.407 * weightKg + 0.267 * heightCm - 19.2;
  }
  return 0.252 * weightKg + 0.473 * heightCm - 48.3;
}

export function james(weightKg: number, heightCm: number, sex: Sex): number {
  const wh = weightKg / heightCm;
  if (sex === 'male') {
    return 1.1 * weightKg - 128 * wh * wh;
  }
  return 1.07 * weightKg - 148 * wh * wh;
}

export function hume(weightKg: number, heightCm: number, sex: Sex): number {
  if (sex === 'male') {
    return 0.32810 * weightKg + 0.33929 * heightCm - 29.5336;
  }
  return 0.29569 * weightKg + 0.41813 * heightCm - 43.2933;
}

export interface LbmInputs {
  weightKg: number;
  heightCm: number;
  sex: Sex;
}

export interface LbmResult {
  method: LbmMethod;
  name: string;
  lbmKg: number;
  fatMassKg: number;
  bodyFatPct: number;
  bestFor: string;
  citation: string;
}

export function calculateAllLbm(inputs: LbmInputs): LbmResult[] {
  const { weightKg, heightCm, sex } = inputs;
  if (weightKg <= 0 || heightCm <= 0) return [];

  return LBM_METHODS.map((m) => {
    let lbm = 0;
    switch (m.key) {
      case 'boer':
        lbm = boer(weightKg, heightCm, sex);
        break;
      case 'james':
        lbm = james(weightKg, heightCm, sex);
        break;
      case 'hume':
        lbm = hume(weightKg, heightCm, sex);
        break;
    }
    const lbmRounded = round(lbm, 1);
    const fat = round(weightKg - lbm, 1);
    const bf = round(((weightKg - lbm) / weightKg) * 100, 1);
    return {
      method: m.key,
      name: m.name,
      lbmKg: lbmRounded,
      fatMassKg: fat,
      bodyFatPct: bf,
      bestFor: m.bestFor,
      citation: m.citation,
    };
  });
}

// Protein needs anchored to LBM. Helton et al. + ISSN 2017 position stand
// suggest 1.6-2.2 g/kg of total body weight for resistance trainees, which
// maps to roughly 2.0-2.7 g/kg of LBM at 20-25 percent body fat.
export function proteinTargetFromLbm(lbmKg: number): { low: number; high: number } {
  return {
    low: round(lbmKg * 2.0, 0),
    high: round(lbmKg * 2.7, 0),
  };
}
