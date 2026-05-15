// Ideal body weight (IBW) estimation formulas.
//
// All four classical formulas (Robinson, Miller, Devine, Hamwi) were derived
// from drug-dosing tables developed in mid-20th-century clinical settings.
// They take only height and sex, so they will return identical numbers for a
// sedentary office worker and an elite athlete of the same height. Treat the
// output as a coarse reference, not a target.
//
// The BMI-range method returns a healthy weight range (BMI 18.5 to 24.9) and
// is generally the most physiologically reasonable for modern adults.
//
// References:
//   Robinson JD, Lupkiewicz SM, Palenik L et al. (1983). Determination of
//     ideal body weight for drug dosage calculations. Am J Hosp Pharm 40(6).
//   Miller DR, Carlson JD, Lloyd BJ et al. (1983). Determining ideal body
//     weight. Am J Hosp Pharm 40(10).
//   Devine BJ (1974). Gentamicin therapy. Drug Intell Clin Pharm 8.
//   Hamwi GJ (1964). Therapy: changing dietary concepts. In: Diabetes Mellitus.
//     American Diabetes Association.

import { round } from './units';

export type Sex = 'male' | 'female';

export type IdealWeightFormula = 'robinson' | 'miller' | 'devine' | 'hamwi' | 'bmi-range';

export interface IdealWeightFormulaInfo {
  key: IdealWeightFormula;
  name: string;
  year: number;
  note: string;
  citation: string;
}

export const IDEAL_WEIGHT_FORMULAS: IdealWeightFormulaInfo[] = [
  {
    key: 'robinson',
    name: 'Robinson (1983)',
    year: 1983,
    note: 'Modern refinement of Devine. Often used in clinical pharmacy.',
    citation: 'Robinson JD et al. (1983), Am J Hosp Pharm 40(6)',
  },
  {
    key: 'miller',
    name: 'Miller (1983)',
    year: 1983,
    note: 'Slightly higher estimates than Robinson at most heights.',
    citation: 'Miller DR et al. (1983), Am J Hosp Pharm 40(10)',
  },
  {
    key: 'devine',
    name: 'Devine (1974)',
    year: 1974,
    note: 'Original drug-dosing formula. Underestimates for shorter people.',
    citation: 'Devine BJ (1974), Drug Intell Clin Pharm 8',
  },
  {
    key: 'hamwi',
    name: 'Hamwi (1964)',
    year: 1964,
    note: 'Oldest and quickest mental math. Used in diabetes nutrition.',
    citation: 'Hamwi GJ (1964), in Diabetes Mellitus, ADA',
  },
  {
    key: 'bmi-range',
    name: 'BMI healthy range',
    year: 2000,
    note: 'Returns a range, not a point. Generally the most physiologically grounded.',
    citation: 'WHO (2000), Technical Report Series 894',
  },
];

// Inches over 5 feet, clamped at zero for shorter heights.
function inchesOver5ft(heightCm: number): number {
  const totalIn = heightCm / 2.54;
  return Math.max(0, totalIn - 60);
}

export const idealWeight = {
  robinson: (heightCm: number, sex: Sex): number => {
    const extra = inchesOver5ft(heightCm);
    return sex === 'male' ? 52 + 1.9 * extra : 49 + 1.7 * extra;
  },
  miller: (heightCm: number, sex: Sex): number => {
    const extra = inchesOver5ft(heightCm);
    return sex === 'male' ? 56.2 + 1.41 * extra : 53.1 + 1.36 * extra;
  },
  devine: (heightCm: number, sex: Sex): number => {
    const extra = inchesOver5ft(heightCm);
    return sex === 'male' ? 50 + 2.3 * extra : 45.5 + 2.3 * extra;
  },
  hamwi: (heightCm: number, sex: Sex): number => {
    const extra = inchesOver5ft(heightCm);
    return sex === 'male' ? 48 + 2.7 * extra : 45.5 + 2.2 * extra;
  },
};

export interface IdealWeightResult {
  formula: IdealWeightFormula;
  name: string;
  valueKg: number;       // single point estimate (0 for bmi-range)
  rangeKg?: { low: number; high: number };
  note: string;
  citation: string;
}

export function calculateAllIdealWeight(
  heightCm: number,
  sex: Sex,
): IdealWeightResult[] {
  if (heightCm <= 0) return [];

  const results: IdealWeightResult[] = IDEAL_WEIGHT_FORMULAS.filter(
    (f) => f.key !== 'bmi-range',
  ).map((f) => ({
    formula: f.key,
    name: f.name,
    valueKg: round(idealWeight[f.key as Exclude<IdealWeightFormula, 'bmi-range'>](heightCm, sex), 1),
    note: f.note,
    citation: f.citation,
  }));

  // BMI range as a range.
  const m = heightCm / 100;
  const low = round(18.5 * m * m, 1);
  const high = round(24.9 * m * m, 1);
  const bmiInfo = IDEAL_WEIGHT_FORMULAS.find((f) => f.key === 'bmi-range')!;
  results.push({
    formula: 'bmi-range',
    name: bmiInfo.name,
    valueKg: 0,
    rangeKg: { low, high },
    note: bmiInfo.note,
    citation: bmiInfo.citation,
  });

  return results;
}
