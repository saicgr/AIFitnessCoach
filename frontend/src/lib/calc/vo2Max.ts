// VO2 max estimation protocols.
//
// VO2 max is the maximum rate at which the body can consume oxygen during
// exercise, measured in mL/kg/min. We expose 5 validated field-test protocols
// so users can pick the one whose equipment they have. All return VO2 max in
// mL/kg/min plus an ACSM age/sex classification.
//
// References:
//   Cooper KH (1968). "A means of assessing maximal oxygen intake".
//     JAMA 203(3):201-204.
//   ACSM's Guidelines for Exercise Testing and Prescription, 10th ed (2017).
//   McArdle WD, Katch FI, Pechar GS, Jacobson L, Ruck S (1972). "Reliability
//     and interrelationships between maximal oxygen intake, physical work
//     capacity and step-test scores in college women".
//     Medicine and Science in Sports 4(4):182-186.
//   Bruce RA, Kusumi F, Hosmer D (1973). "Maximal oxygen intake and nomographic
//     assessment of functional aerobic impairment in cardiovascular disease".
//     American Heart Journal 85(4):546-562.

import { round } from './units';
import type { Sex } from './units';

export type Vo2Method =
  | 'cooper12run'
  | 'milesAndHalf'
  | 'cooper12alt'
  | 'bruce'
  | 'queens';

export interface Vo2Result {
  method: Vo2Method;
  name: string;
  vo2max: number;
  classification: string;
  citation: string;
}

// ---------- Individual formulas ----------

// Cooper 12-minute run. distanceMeters is total distance covered in 12 min.
export function cooper12Run(distanceMeters: number): number {
  if (distanceMeters <= 504.9) return 0;
  return (distanceMeters - 504.9) / 44.73;
}

// 1.5-mile run test (Larsen / ACSM regression).
// timeMin in decimal minutes (e.g. 12:30 = 12.5). weightKg = body mass.
export function mileAndHalfRun(
  timeMin: number,
  weightKg: number,
  sex: Sex,
): number {
  const sexFlag = sex === 'male' ? 1 : 0;
  return 88.02 + 3.716 * sexFlag - 0.1656 * weightKg - 2.767 * timeMin;
}

// Cooper 12-minute alternate input (same equation, kept separate so the UI can
// expose a second mile/km input format).
export function cooper12Alt(distanceMeters: number): number {
  return cooper12Run(distanceMeters);
}

// Bruce treadmill protocol. timeMin = total stage-graded time to exhaustion.
export function bruceTreadmill(timeMin: number, sex: Sex): number {
  if (sex === 'male') {
    return (
      14.8 -
      1.379 * timeMin +
      0.451 * Math.pow(timeMin, 2) -
      0.012 * Math.pow(timeMin, 3)
    );
  }
  return 4.38 * timeMin - 3.9;
}

// Queens College Step Test. 3 minutes stepping on a 16.25-in step at
// 22 (women) or 24 (men) steps/min, then recovery HR measured 5-20s post.
export function queensCollegeStep(recoveryHr: number, sex: Sex): number {
  if (sex === 'male') return 111.33 - 0.42 * recoveryHr;
  return 65.81 - 0.1847 * recoveryHr;
}

// ---------- ACSM age + sex classification ----------
//
// Simplified ACSM 10th-edition normative bands (mL/kg/min). Categories:
// Poor / Fair / Good / Excellent / Superior.

interface Band {
  poor: number;
  fair: number;
  good: number;
  excellent: number;
  // Above excellent → Superior
}

function getBand(age: number, sex: Sex): Band {
  // Coarse 10-year buckets sourced from ACSM Guidelines 10th ed Tables 4.7/4.8.
  if (sex === 'male') {
    if (age < 30) return { poor: 38, fair: 44, good: 51, excellent: 56 };
    if (age < 40) return { poor: 34, fair: 42, good: 47, excellent: 53 };
    if (age < 50) return { poor: 30, fair: 38, good: 43, excellent: 49 };
    if (age < 60) return { poor: 25, fair: 34, good: 39, excellent: 45 };
    return { poor: 21, fair: 30, good: 35, excellent: 41 };
  }
  if (age < 30) return { poor: 28, fair: 34, good: 40, excellent: 46 };
  if (age < 40) return { poor: 27, fair: 33, good: 38, excellent: 44 };
  if (age < 50) return { poor: 25, fair: 30, good: 35, excellent: 41 };
  if (age < 60) return { poor: 21, fair: 27, good: 32, excellent: 37 };
  return { poor: 19, fair: 24, good: 28, excellent: 33 };
}

export function classifyVo2(
  vo2: number,
  age: number,
  sex: Sex,
): string {
  if (!Number.isFinite(vo2) || vo2 <= 0) return 'Not available';
  const b = getBand(age, sex);
  if (vo2 < b.poor) return 'Very poor';
  if (vo2 < b.fair) return 'Poor';
  if (vo2 < b.good) return 'Fair';
  if (vo2 < b.excellent) return 'Good';
  if (vo2 < b.excellent + 8) return 'Excellent';
  return 'Superior';
}

// ---------- Aggregate helpers ----------

export interface CooperInputs {
  distanceMeters: number;
}

export interface MileAndHalfInputs {
  timeMin: number;
  weightKg: number;
  sex: Sex;
}

export interface BruceInputs {
  timeMin: number;
  sex: Sex;
}

export interface QueensInputs {
  recoveryHr: number;
  sex: Sex;
}

const NAMES: Record<Vo2Method, string> = {
  cooper12run: 'Cooper 12-minute run',
  milesAndHalf: '1.5-mile run',
  cooper12alt: 'Cooper 12-min (alt input)',
  bruce: 'Bruce treadmill protocol',
  queens: 'Queens College step test',
};

const CITATIONS: Record<Vo2Method, string> = {
  cooper12run: 'Cooper (1968), JAMA 203(3):201',
  milesAndHalf: 'ACSM Guidelines 10th ed (2017)',
  cooper12alt: 'Cooper (1968), JAMA 203(3):201',
  bruce: 'Bruce, Kusumi, Hosmer (1973), Am Heart J 85(4):546',
  queens: 'McArdle et al. (1972), MSSE 4(4):182',
};

export function buildResult(
  method: Vo2Method,
  vo2max: number,
  age: number,
  sex: Sex,
): Vo2Result {
  return {
    method,
    name: NAMES[method],
    vo2max: round(vo2max, 1),
    classification: classifyVo2(vo2max, age, sex),
    citation: CITATIONS[method],
  };
}
