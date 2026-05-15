// Healthy weight range from height, with adjustments for age and frame size.
//
// The default range uses WHO BMI 18.5 to 24.9. For older adults (65+), large
// meta-analyses (Winter et al. 2014, Janssen et al. 2005) consistently find
// that mortality risk is lowest at BMI 23 to 28, so we shift the range up for
// that group. Frame size adjustment uses a small ±5% shift, based on the
// classic Metropolitan Life Insurance frame tables.
//
// References:
//   WHO (2000). Obesity: Preventing and Managing the Global Epidemic.
//     WHO Technical Report Series 894. Geneva.
//   Winter JE, MacInnis RJ, Wattanapenpaiboon N, Nowson CA (2014). BMI and
//     all-cause mortality in older adults: a meta-analysis. Am J Clin Nutr 99(4).
//   Janssen I, Mark AE (2007). Elevated body mass index and mortality risk in
//     the elderly. Obes Rev 8(1).
//   Metropolitan Life Insurance Co (1983). Height and weight tables.

import { round } from './units';

export type Sex = 'male' | 'female';
export type Frame = 'small' | 'medium' | 'large';

export interface HealthyWeightInput {
  heightCm: number;
  age: number;
  sex: Sex;
  frame: Frame;
}

export interface HealthyWeightRange {
  lowKg: number;
  highKg: number;
  bmiLow: number;
  bmiHigh: number;
  ageAdjusted: boolean;
  frameAdjustmentPct: number; // e.g. -0.05, 0, +0.05
  notes: string[];
}

// Frame adjustments: small frame trims 5%, large frame adds 5%.
const FRAME_ADJUSTMENT: Record<Frame, number> = {
  small: -0.05,
  medium: 0,
  large: 0.05,
};

export function healthyWeightRange(input: HealthyWeightInput): HealthyWeightRange {
  const { heightCm, age, frame } = input;
  const heightM = heightCm / 100;

  const ageAdjusted = age >= 65;
  const bmiLow = ageAdjusted ? 23 : 18.5;
  const bmiHigh = ageAdjusted ? 28 : 24.9;

  const baseLow = bmiLow * heightM * heightM;
  const baseHigh = bmiHigh * heightM * heightM;

  const frameMultiplier = 1 + FRAME_ADJUSTMENT[frame];
  const lowKg = round(baseLow * frameMultiplier, 1);
  const highKg = round(baseHigh * frameMultiplier, 1);

  const notes: string[] = [];
  if (ageAdjusted) {
    notes.push(
      'Range shifted to BMI 23 to 28. In adults 65 and older, this band is associated with the lowest all-cause mortality.',
    );
  }
  if (frame === 'small') {
    notes.push('Small frame trims the range by 5 percent to reflect lower lean mass at the same height.');
  } else if (frame === 'large') {
    notes.push('Large frame raises the range by 5 percent to reflect higher lean mass at the same height.');
  }
  notes.push(
    'Healthy weight is a range because two people at the same height carry different muscle, bone, and organ mass.',
  );

  return {
    lowKg,
    highKg,
    bmiLow,
    bmiHigh,
    ageAdjusted,
    frameAdjustmentPct: FRAME_ADJUSTMENT[frame],
    notes,
  };
}

// Where a given weight sits relative to the healthy range.
export type RangePosition = 'below' | 'in-range' | 'above';

export function rangePosition(weightKg: number, range: HealthyWeightRange): RangePosition {
  if (weightKg < range.lowKg) return 'below';
  if (weightKg > range.highKg) return 'above';
  return 'in-range';
}
