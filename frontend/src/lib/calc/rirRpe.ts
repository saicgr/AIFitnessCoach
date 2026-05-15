// RIR / RPE / %1RM converter (Helms-Zourdos chart).
//
// The RPE-to-%1RM mapping is from Zourdos et al. 2016, validated in
// powerlifting populations. Each cell is reps × RPE → %1RM. RIR = reps in
// reserve = 10 - RPE (in this scale).
//
// References:
//   Zourdos MC, Klemp A, Dolan C, Quiles JM, Schau KA, Jo E, Helms E,
//     Esgro B, Duncan S, Garcia Merino S, Blanco R (2016). "Novel
//     resistance training-specific rating of perceived exertion scale
//     measuring repetitions in reserve". J Strength Cond Res 30(1):267-275.
//   Helms ER, Brown SR, Cross MR, Storey A, Cronin J, Zourdos MC (2018).
//     "Self-rated accuracy of rating of perceived exertion-based load
//     prescription in powerlifters". J Strength Cond Res 32(8):2278-2288.

import { round } from './units';

export const RPE_VALUES = [10, 9.5, 9, 8.5, 8, 7.5, 7, 6.5, 6, 5.5, 5] as const;
export type Rpe = typeof RPE_VALUES[number];

export const REPS_RANGE = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as const;
export type Reps = typeof REPS_RANGE[number];

// Zourdos 2016 RPE × Reps → %1RM lookup table.
// Rows = RPE (10 down to 5), columns = reps 1..12.
// Values in percent of 1RM.
export const RPE_PCT_TABLE: Record<number, Record<number, number>> = {
  10:   { 1: 100.0, 2: 95.5, 3: 92.2, 4: 89.2, 5: 86.3, 6: 83.7, 7: 81.1, 8: 78.6, 9: 76.2, 10: 73.9, 11: 70.7, 12: 68.0 },
  9.5:  { 1: 97.8,  2: 93.9, 3: 90.7, 4: 87.8, 5: 85.0, 6: 82.4, 7: 79.9, 8: 77.4, 9: 75.1, 10: 72.3, 11: 69.4, 12: 66.7 },
  9:    { 1: 95.5,  2: 92.2, 3: 89.2, 4: 86.3, 5: 83.7, 6: 81.1, 7: 78.6, 8: 76.2, 9: 73.9, 10: 70.7, 11: 68.0, 12: 65.3 },
  8.5:  { 1: 93.9,  2: 90.7, 3: 87.8, 4: 85.0, 5: 82.4, 6: 79.9, 7: 77.4, 8: 75.1, 9: 72.3, 10: 69.4, 11: 66.7, 12: 64.0 },
  8:    { 1: 92.2,  2: 89.2, 3: 86.3, 4: 83.7, 5: 81.1, 6: 78.6, 7: 76.2, 8: 73.9, 9: 70.7, 10: 68.0, 11: 65.3, 12: 62.6 },
  7.5:  { 1: 90.7,  2: 87.8, 3: 85.0, 4: 82.4, 5: 79.9, 6: 77.4, 7: 75.1, 8: 72.3, 9: 69.4, 10: 66.7, 11: 64.0, 12: 61.3 },
  7:    { 1: 89.2,  2: 86.3, 3: 83.7, 4: 81.1, 5: 78.6, 6: 76.2, 7: 73.9, 8: 70.7, 9: 68.0, 10: 65.3, 11: 62.6, 12: 59.9 },
  6.5:  { 1: 87.8,  2: 85.0, 3: 82.4, 4: 79.9, 5: 77.4, 6: 75.1, 7: 72.3, 8: 69.4, 9: 66.7, 10: 64.0, 11: 61.3, 12: 58.6 },
  6:    { 1: 86.3,  2: 83.7, 3: 81.1, 4: 78.6, 5: 76.2, 6: 73.9, 7: 70.7, 8: 68.0, 9: 65.3, 10: 62.6, 11: 59.9, 12: 57.2 },
  5.5:  { 1: 85.0,  2: 82.4, 3: 79.9, 4: 77.4, 5: 75.1, 6: 72.3, 7: 69.4, 8: 66.7, 9: 64.0, 10: 61.3, 11: 58.6, 12: 55.9 },
  5:    { 1: 83.7,  2: 81.1, 3: 78.6, 4: 76.2, 5: 73.9, 6: 70.7, 7: 68.0, 8: 65.3, 9: 62.6, 10: 59.9, 11: 57.2, 12: 54.5 },
};

export function rirToRpe(rir: number): number {
  return 10 - rir;
}

export function rpeToRir(rpe: number): number {
  return 10 - rpe;
}

// Get %1RM for a given reps + RPE. Returns null if outside the table.
export function pctOfOneRm(reps: number, rpe: number): number | null {
  const row = RPE_PCT_TABLE[rpe];
  if (!row) return null;
  const v = row[reps];
  return typeof v === 'number' ? v : null;
}

// Given reps and RPE plus a 1RM, compute the load.
export function loadFromOneRm(
  oneRm: number,
  reps: number,
  rpe: number,
): number | null {
  const pct = pctOfOneRm(reps, rpe);
  if (pct == null) return null;
  return round((oneRm * pct) / 100, 1);
}

// Given a working weight, reps, and RPE, infer 1RM.
export function oneRmFromLoad(
  load: number,
  reps: number,
  rpe: number,
): number | null {
  const pct = pctOfOneRm(reps, rpe);
  if (pct == null || pct <= 0) return null;
  return round((load * 100) / pct, 1);
}

// Find the nearest RPE for a given reps + %1RM (used when user enters load+reps+1RM
// and wants to know the implied RPE/RIR).
export function rpeFromPct(reps: number, targetPct: number): number | null {
  let bestRpe: number | null = null;
  let bestDelta = Infinity;
  for (const rpe of RPE_VALUES) {
    const v = RPE_PCT_TABLE[rpe]?.[reps];
    if (typeof v !== 'number') continue;
    const delta = Math.abs(v - targetPct);
    if (delta < bestDelta) {
      bestDelta = delta;
      bestRpe = rpe;
    }
  }
  return bestRpe;
}

export interface ConverterInputs {
  oneRm?: number;       // user's known 1RM
  load?: number;        // working weight
  reps?: number;
  rpe?: number;
  rir?: number;         // alternate to rpe; rir = 10 - rpe
}

export interface ConverterResult {
  reps: number;
  rpe: number;
  rir: number;
  pct: number;
  load: number;
  oneRm: number;
}

// Solve the converter given any 2-3 of the inputs.
// Priority: if rpe given use it; otherwise compute from rir; otherwise null.
export function solveConverter(inputs: ConverterInputs): ConverterResult | null {
  const reps = inputs.reps;
  if (!reps || reps < 1 || reps > 12) return null;

  let rpe = inputs.rpe;
  if (rpe == null && typeof inputs.rir === 'number') {
    rpe = rirToRpe(inputs.rir);
  }

  // Case 1: have oneRm + reps + rpe → compute load
  if (typeof inputs.oneRm === 'number' && typeof rpe === 'number') {
    const pct = pctOfOneRm(reps, rpe);
    if (pct == null) return null;
    const load = round((inputs.oneRm * pct) / 100, 1);
    return {
      reps,
      rpe,
      rir: rpeToRir(rpe),
      pct: round(pct, 1),
      load,
      oneRm: inputs.oneRm,
    };
  }

  // Case 2: have load + reps + rpe → compute 1RM
  if (typeof inputs.load === 'number' && typeof rpe === 'number') {
    const pct = pctOfOneRm(reps, rpe);
    if (pct == null || pct <= 0) return null;
    const oneRm = round((inputs.load * 100) / pct, 1);
    return {
      reps,
      rpe,
      rir: rpeToRir(rpe),
      pct: round(pct, 1),
      load: inputs.load,
      oneRm,
    };
  }

  // Case 3: have load + reps + oneRm → infer RPE
  if (
    typeof inputs.load === 'number' &&
    typeof inputs.oneRm === 'number' &&
    inputs.oneRm > 0
  ) {
    const targetPct = (inputs.load / inputs.oneRm) * 100;
    const inferredRpe = rpeFromPct(reps, targetPct);
    if (inferredRpe == null) return null;
    return {
      reps,
      rpe: inferredRpe,
      rir: rpeToRir(inferredRpe),
      pct: round(targetPct, 1),
      load: inputs.load,
      oneRm: inputs.oneRm,
    };
  }

  return null;
}
