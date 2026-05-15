// Target heart rate + training zone calculator.
//
// Three HRmax formulas (Fox, Tanaka, Gulati) plus the Karvonen heart-rate
// reserve method. Returns 5 ACSM-style training zones.
//
// References:
//   Fox SM, Naughton JP, Haskell WL (1971). "Physical activity and the
//     prevention of coronary heart disease". Annals of Clinical Research
//     3(6):404-432. [Origin of 220 - age rule]
//   Tanaka H, Monahan KD, Seals DR (2001). "Age-predicted maximal heart rate
//     revisited". Journal of the American College of Cardiology 37(1):153-156.
//   Gulati M, Shaw LJ, Thisted RA, Black HR, Bairey Merz CN, Arnsdorf MF
//     (2010). "Heart rate response to exercise stress testing in asymptomatic
//     women". Circulation 122(2):130-137.
//   Karvonen MJ, Kentala E, Mustala O (1957). "The effects of training on
//     heart rate; a longitudinal study". Annales Medicinae Experimentalis
//     et Biologiae Fenniae 35(3):307-315.

import { round } from './units';
import type { Sex } from './units';

export type HrFormula = 'fox' | 'tanaka' | 'gulati';

export interface HrFormulaInfo {
  key: HrFormula;
  name: string;
  bestFor: string;
  citation: string;
}

export const HR_FORMULAS: HrFormulaInfo[] = [
  {
    key: 'fox',
    name: 'Fox (220 - age)',
    bestFor: 'Quick rule of thumb. Average error is ±10-12 bpm.',
    citation: 'Fox, Naughton, Haskell (1971)',
  },
  {
    key: 'tanaka',
    name: 'Tanaka (208 - 0.7 × age)',
    bestFor: 'More accurate across all ages, especially over 40.',
    citation: 'Tanaka et al. (2001), JACC 37(1):153',
  },
  {
    key: 'gulati',
    name: 'Gulati (206 - 0.88 × age)',
    bestFor: 'Women-specific. Most accurate for asymptomatic women.',
    citation: 'Gulati et al. (2010), Circulation 122(2):130',
  },
];

export function hrMax(formula: HrFormula, age: number, sex?: Sex): number {
  if (formula === 'fox') return 220 - age;
  if (formula === 'tanaka') return 208 - 0.7 * age;
  // Gulati was validated on women; for males we fall back to Tanaka.
  if (formula === 'gulati') {
    if (sex === 'male') return 208 - 0.7 * age;
    return 206 - 0.88 * age;
  }
  return 220 - age;
}

// Karvonen target HR. intensityPct is 0-1 (e.g. 0.7 for 70%).
export function karvonenTargetHr(
  age: number,
  restHr: number,
  intensityPct: number,
  formula: HrFormula = 'tanaka',
  sex?: Sex,
): number {
  const max = hrMax(formula, age, sex);
  const reserve = max - restHr;
  return reserve * intensityPct + restHr;
}

// Plain percentage-of-max target.
export function percentMaxTargetHr(
  age: number,
  intensityPct: number,
  formula: HrFormula = 'tanaka',
  sex?: Sex,
): number {
  return hrMax(formula, age, sex) * intensityPct;
}

// ---------- Training zones ----------

export interface Zone {
  zone: number;
  name: string;
  intensityLow: number;   // 0-1 fraction of HRmax or HRR
  intensityHigh: number;
  description: string;
}

export const ZONES: Zone[] = [
  {
    zone: 1,
    name: 'Recovery',
    intensityLow: 0.5,
    intensityHigh: 0.6,
    description: 'Active recovery, easy warmups, walking. Conversational.',
  },
  {
    zone: 2,
    name: 'Aerobic base',
    intensityLow: 0.6,
    intensityHigh: 0.7,
    description: 'Fat oxidation, mitochondrial development, long slow distance.',
  },
  {
    zone: 3,
    name: 'Aerobic / tempo',
    intensityLow: 0.7,
    intensityHigh: 0.8,
    description: 'Comfortably hard. Builds aerobic capacity. Talk in short sentences.',
  },
  {
    zone: 4,
    name: 'Threshold',
    intensityLow: 0.8,
    intensityHigh: 0.9,
    description: 'Lactate threshold. Sustainable for about 20-60 minutes when trained.',
  },
  {
    zone: 5,
    name: 'VO2 max / anaerobic',
    intensityLow: 0.9,
    intensityHigh: 1.0,
    description: 'All-out intervals. Builds VO2 max and anaerobic power.',
  },
];

export interface ZoneRange {
  zone: number;
  name: string;
  low: number;
  high: number;
  description: string;
}

export function computeZones(
  age: number,
  options: {
    formula?: HrFormula;
    sex?: Sex;
    restHr?: number;       // if provided, uses Karvonen HRR
  } = {},
): ZoneRange[] {
  const { formula = 'tanaka', sex, restHr } = options;
  const max = hrMax(formula, age, sex);
  const useKarvonen = typeof restHr === 'number' && restHr > 0;

  return ZONES.map((z) => {
    const low = useKarvonen
      ? karvonenTargetHr(age, restHr as number, z.intensityLow, formula, sex)
      : max * z.intensityLow;
    const high = useKarvonen
      ? karvonenTargetHr(age, restHr as number, z.intensityHigh, formula, sex)
      : max * z.intensityHigh;
    return {
      zone: z.zone,
      name: z.name,
      low: round(low, 0),
      high: round(high, 0),
      description: z.description,
    };
  });
}
