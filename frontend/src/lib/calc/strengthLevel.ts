// Strength level / percentile estimator.
//
// Given a 1RM (in KG), bodyweight (in KG), sex, and lift, returns:
//   - a level bucket: beginner | novice | intermediate | advanced | elite
//   - an approximate percentile (0-100) versus other lifters at the same
//     bodyweight bucket.
//
// Method: a deterministic lookup of bodyweight-ratio standards per lift.
// The ratios are pulled from publicly available strength-standards tables
// (StrengthLevel.com, Symmetric Strength, ExRx.net) and triangulated. The
// underlying populations are self-reported lifter logs, so treat percentiles
// as directional, not clinical.
//
// Lifts supported: squat (high-bar back squat), bench (paused or touch-and-go
// flat bench), deadlift (conventional or sumo), overhead press (standing
// barbell strict press).
//
// Levels (per StrengthLevel.com convention):
//   beginner     : roughly the strongest 50% of new lifters
//   novice       : 6-12 months of consistent training
//   intermediate : 2+ years, structured programming
//   advanced     : 5+ years, competitive amateur
//   elite        : national / world class, top ~1% of trained lifters

import type { Sex } from './units';

export type Lift = 'squat' | 'bench' | 'deadlift' | 'overhead-press';
export type Level = 'beginner' | 'novice' | 'intermediate' | 'advanced' | 'elite';

// Bodyweight-ratio standards. Values are 1RM divided by bodyweight.
// Source: triangulated from StrengthLevel.com, Symmetric Strength, ExRx.net,
// and Lon Kilgore's "Beginning Strength Standards" (2007).
interface LevelRatios {
  beginner: number;
  novice: number;
  intermediate: number;
  advanced: number;
  elite: number;
}

const RATIOS_MALE: Record<Lift, LevelRatios> = {
  squat:           { beginner: 0.75, novice: 1.25, intermediate: 1.75, advanced: 2.25, elite: 2.75 },
  bench:           { beginner: 0.50, novice: 0.90, intermediate: 1.25, advanced: 1.75, elite: 2.10 },
  deadlift:        { beginner: 1.00, novice: 1.50, intermediate: 2.00, advanced: 2.50, elite: 3.00 },
  'overhead-press':{ beginner: 0.35, novice: 0.55, intermediate: 0.80, advanced: 1.10, elite: 1.40 },
};

const RATIOS_FEMALE: Record<Lift, LevelRatios> = {
  squat:           { beginner: 0.50, novice: 0.80, intermediate: 1.25, advanced: 1.75, elite: 2.25 },
  bench:           { beginner: 0.25, novice: 0.50, intermediate: 0.75, advanced: 1.10, elite: 1.50 },
  deadlift:        { beginner: 0.60, novice: 1.00, intermediate: 1.50, advanced: 2.00, elite: 2.50 },
  'overhead-press':{ beginner: 0.20, novice: 0.35, intermediate: 0.55, advanced: 0.80, elite: 1.10 },
};

// Bodyweight correction. Heavier lifters lift proportionally less per kg,
// lighter lifters proportionally more. We scale ratios by a curve fit
// against published standards at 60 / 75 / 90 / 110 / 140 kg bodyweights.
// Returns multiplier applied to the base ratio.
function bodyweightMultiplier(bwKg: number, sex: Sex): number {
  // Reference bodyweight where multiplier = 1.0
  const ref = sex === 'male' ? 84 : 64;
  // Diminishing returns at high bodyweight
  // Empirical fit: 1.0 at ref, 1.15 at 0.6*ref, 0.85 at 1.7*ref
  const ratio = bwKg / ref;
  if (ratio <= 1) {
    return 1 + (1 - ratio) * 0.35;
  }
  return 1 - (ratio - 1) * 0.18;
}

function effectiveRatio(oneRmKg: number, bwKg: number): number {
  if (bwKg <= 0) return 0;
  return oneRmKg / bwKg;
}

export interface StrengthResult {
  level: Level;
  percentile: number;
  ratio: number;
  thresholds: LevelRatios;
}

export function strengthPercentile(
  lift: Lift,
  oneRmKg: number,
  bodyweightKg: number,
  sex: Sex,
): StrengthResult {
  const base = sex === 'male' ? RATIOS_MALE[lift] : RATIOS_FEMALE[lift];
  const mult = bodyweightMultiplier(bodyweightKg, sex);
  const thresholds: LevelRatios = {
    beginner: base.beginner * mult,
    novice: base.novice * mult,
    intermediate: base.intermediate * mult,
    advanced: base.advanced * mult,
    elite: base.elite * mult,
  };

  const ratio = effectiveRatio(oneRmKg, bodyweightKg);

  // Determine level
  let level: Level = 'beginner';
  if (ratio >= thresholds.elite) level = 'elite';
  else if (ratio >= thresholds.advanced) level = 'advanced';
  else if (ratio >= thresholds.intermediate) level = 'intermediate';
  else if (ratio >= thresholds.novice) level = 'novice';

  // Percentile: linearly interpolate within bucket.
  // beginner < novice (5th-25th), novice < intermediate (25th-50th),
  // intermediate < advanced (50th-80th), advanced < elite (80th-99th).
  const buckets: { lo: number; hi: number; pctLo: number; pctHi: number }[] = [
    { lo: 0,                       hi: thresholds.beginner,    pctLo: 0,  pctHi: 5  },
    { lo: thresholds.beginner,     hi: thresholds.novice,      pctLo: 5,  pctHi: 25 },
    { lo: thresholds.novice,       hi: thresholds.intermediate,pctLo: 25, pctHi: 50 },
    { lo: thresholds.intermediate, hi: thresholds.advanced,    pctLo: 50, pctHi: 80 },
    { lo: thresholds.advanced,     hi: thresholds.elite,       pctLo: 80, pctHi: 99 },
  ];

  let percentile = 99;
  for (const b of buckets) {
    if (ratio < b.hi) {
      const span = b.hi - b.lo;
      const within = span > 0 ? (ratio - b.lo) / span : 0;
      percentile = b.pctLo + within * (b.pctHi - b.pctLo);
      break;
    }
  }
  // Above elite stays at 99
  if (ratio >= thresholds.elite) percentile = 99;
  percentile = Math.max(0, Math.min(99, Math.round(percentile)));

  return { level, percentile, ratio, thresholds };
}

export const LIFT_LABELS: Record<Lift, string> = {
  squat: 'Back squat',
  bench: 'Bench press',
  deadlift: 'Deadlift',
  'overhead-press': 'Overhead press',
};

export const LEVEL_LABELS: Record<Level, string> = {
  beginner: 'Beginner',
  novice: 'Novice',
  intermediate: 'Intermediate',
  advanced: 'Advanced',
  elite: 'Elite',
};

export const LEVEL_DESCRIPTIONS: Record<Level, string> = {
  beginner: 'Stronger than an untrained lifter of the same sex and bodyweight.',
  novice: 'Roughly 6 to 12 months of consistent, structured training.',
  intermediate: 'Two plus years of programmed training. Most gym regulars peak here.',
  advanced: 'Five plus years, competitive amateur, top ~20% of trained lifters.',
  elite: 'National or world-class. Roughly the top 1% of trained lifters.',
};
