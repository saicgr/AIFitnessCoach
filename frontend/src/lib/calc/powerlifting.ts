// Powerlifting scoring formulas: Wilks (2020), DOTS (2020), IPF GL Points (2020),
// and Schwartz-Malone (classic). All formulas normalize a total (squat + bench
// + deadlift) against bodyweight so lifters of different sizes can be compared
// on a single score.
//
// All inputs are in KG. Total is the sum of the best squat, bench, and deadlift
// in KG. Score is dimensionless points.
//
// References:
//   Wilks 2020 coefficients: published by Robert Wilks via OpenPowerlifting
//     after a 2020 refit. See https://openpowerlifting.gitlab.io/opl-csv/
//   DOTS 2020: Tim Konertz and Roland Tschanz, used by IPL and many federations.
//     https://gitlab.com/openpowerlifting/opl-data
//   IPF GL Points: International Powerlifting Federation, adopted Jan 2020,
//     replacing IPF Wilks. https://www.powerlifting.sport/
//   Schwartz-Malone: classic 1980s formulas. Lyle Schwartz published the men's
//     formula; Pat Malone derived the women's equivalent. Largely superseded
//     by DOTS, but still requested for historical comparison.
//
// Coefficient accuracy: Wilks/DOTS/IPF GL coefficients here are the publicly
// documented values. Schwartz-Malone uses a polynomial approximation of the
// original lookup tables and is accurate to roughly +/- 0.5 points.

import type { Sex } from './units';

// ---------- Wilks (2020) ----------
const WILKS_MALE = {
  A: -216.0475144,
  B: 16.2606339,
  C: -0.002388645,
  D: -0.00113732,
  E: 7.01863e-6,
  F: -1.291e-8,
};

const WILKS_FEMALE = {
  A: 594.31747775582,
  B: -27.23842536447,
  C: 0.82112226871,
  D: -0.00930733913,
  E: 4.731582e-5,
  F: -9.054e-8,
};

export function wilks(totalKg: number, bodyweightKg: number, sex: Sex): number {
  if (totalKg <= 0 || bodyweightKg <= 0) return 0;
  const c = sex === 'male' ? WILKS_MALE : WILKS_FEMALE;
  const bw = bodyweightKg;
  const denom =
    c.A +
    c.B * bw +
    c.C * bw * bw +
    c.D * bw * bw * bw +
    c.E * bw * bw * bw * bw +
    c.F * bw * bw * bw * bw * bw;
  if (denom === 0) return 0;
  const coeff = 500 / denom;
  return totalKg * coeff;
}

// ---------- DOTS (2020) ----------
const DOTS_MALE = {
  A: -307.75076,
  B: 24.0900756,
  C: -0.1918759221,
  D: 0.0007391293,
  E: -0.000001093,
};

const DOTS_FEMALE = {
  A: -57.96288,
  B: 13.6175032,
  C: -0.1126655495,
  D: 0.0005158568,
  E: -0.0000010706,
};

export function dots(totalKg: number, bodyweightKg: number, sex: Sex): number {
  if (totalKg <= 0 || bodyweightKg <= 0) return 0;
  const c = sex === 'male' ? DOTS_MALE : DOTS_FEMALE;
  const bw = bodyweightKg;
  const denom =
    c.A + c.B * bw + c.C * bw * bw + c.D * bw * bw * bw + c.E * bw * bw * bw * bw;
  if (denom === 0) return 0;
  const coeff = 500 / denom;
  return totalKg * coeff;
}

// ---------- IPF GL Points (2020) ----------
// "Classic" (raw / unequipped) coefficients for the full powerlifting total.
// Equipped lifters have separate coefficients; we expose classic only since
// most casual users are raw.
const IPF_GL_MALE = { A: 1199.72839, B: 1025.18162, C: 0.00921 };
const IPF_GL_FEMALE = { A: 610.32796, B: 1045.59282, C: 0.03048 };

export function ipfGl(totalKg: number, bodyweightKg: number, sex: Sex): number {
  if (totalKg <= 0 || bodyweightKg <= 0) return 0;
  const c = sex === 'male' ? IPF_GL_MALE : IPF_GL_FEMALE;
  const denom = c.A - c.B * Math.exp(-c.C * bodyweightKg);
  if (denom <= 0) return 0;
  const coeff = 100 / denom;
  return totalKg * coeff;
}

// ---------- Schwartz-Malone (classic) ----------
// Polynomial approximation of the original published tables. The original
// Schwartz (men) and Malone (women) formulas were lookup tables; the curves
// below are best-fits used widely in spreadsheet implementations. Accuracy
// is approximately +/- 0.5 points versus the original tables.
//
// Coefficient source: best-fit polynomials commonly used in lifter
// spreadsheets, derived from the published tables. Less authoritative than
// Wilks/DOTS/IPF GL — verify against an official table for meet purposes.

const SCHWARTZ_MALE = {
  A: 0.631926,
  B: -0.262349e-2,
  C: 0.511550e-5,
  D: -0.519738e-8,
  E: 0.267626e-11,
  F: -0.540132e-15,
  // Constant offset for low bodyweights
  bwFloor: 40,
};

const MALONE_FEMALE = {
  A: 0.84653,
  B: -0.61264e-2,
  C: 0.20316e-4,
  D: -0.31338e-7,
  E: 0.22610e-10,
  F: -0.62029e-14,
  bwFloor: 36,
};

export function schwartzMalone(
  totalKg: number,
  bodyweightKg: number,
  sex: Sex,
): number {
  if (totalKg <= 0 || bodyweightKg <= 0) return 0;
  const c = sex === 'male' ? SCHWARTZ_MALE : MALONE_FEMALE;
  const bw = Math.max(bodyweightKg, c.bwFloor);
  const coeff =
    c.A +
    c.B * bw +
    c.C * bw * bw +
    c.D * bw * bw * bw +
    c.E * bw * bw * bw * bw +
    c.F * bw * bw * bw * bw * bw;
  // Coefficient is multiplied directly against the total in KG.
  return totalKg * coeff;
}

// ---------- Shared helpers ----------
export interface PowerliftingInputs {
  squatKg: number;
  benchKg: number;
  deadliftKg: number;
  bodyweightKg: number;
  sex: Sex;
}

export function totalKg(inputs: Pick<PowerliftingInputs, 'squatKg' | 'benchKg' | 'deadliftKg'>): number {
  return inputs.squatKg + inputs.benchKg + inputs.deadliftKg;
}

export interface PowerliftingScoreRow {
  formula: 'wilks' | 'dots' | 'ipfGl' | 'schwartzMalone';
  name: string;
  score: number;
  year: number;
  note: string;
}

export function allPowerliftingScores(inputs: PowerliftingInputs): PowerliftingScoreRow[] {
  const total = totalKg(inputs);
  return [
    {
      formula: 'dots',
      name: 'DOTS',
      score: dots(total, inputs.bodyweightKg, inputs.sex),
      year: 2020,
      note: 'Modern default. Used by USAPL, IPL, and most US federations.',
    },
    {
      formula: 'ipfGl',
      name: 'IPF GL Points',
      score: ipfGl(total, inputs.bodyweightKg, inputs.sex),
      year: 2020,
      note: 'Official IPF score since 2020. Replaced IPF Wilks.',
    },
    {
      formula: 'wilks',
      name: 'Wilks (2020)',
      score: wilks(total, inputs.bodyweightKg, inputs.sex),
      year: 2020,
      note: 'Classic score, refit in 2020 to reduce mid-weight bias.',
    },
    {
      formula: 'schwartzMalone',
      name: 'Schwartz-Malone',
      score: schwartzMalone(total, inputs.bodyweightKg, inputs.sex),
      year: 1980,
      note: 'Historical formula. Polynomial approximation of original tables.',
    },
  ];
}
