// Pace, speed, time, distance calculator with Riegel race-time predictor.
//
// All internal math runs in SI: distance in kilometers, time in seconds.
// The UI converts at the input/display boundary.
//
// Reference:
//   Riegel PS (1981). "Athletic records and human endurance".
//   American Scientist 69(3):285-290.

import { round } from './units';

export type DistanceUnit = 'mi' | 'km';
export type PaceUnit = 'minPerMi' | 'minPerKm';

export const MI_PER_KM = 0.621371;
export const KM_PER_MI = 1 / MI_PER_KM;

export const RACE_PRESETS: { label: string; km: number }[] = [
  { label: '1 mile', km: 1.60934 },
  { label: '5K', km: 5 },
  { label: '10K', km: 10 },
  { label: 'Half marathon', km: 21.0975 },
  { label: 'Marathon', km: 42.195 },
];

// ---------- Format helpers ----------

export function secondsToHms(totalSec: number): string {
  if (!Number.isFinite(totalSec) || totalSec <= 0) return '0:00';
  const h = Math.floor(totalSec / 3600);
  const m = Math.floor((totalSec % 3600) / 60);
  const s = Math.round(totalSec % 60);
  if (h > 0) {
    return `${h}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  }
  return `${m}:${String(s).padStart(2, '0')}`;
}

export function paceToString(secPerUnit: number): string {
  if (!Number.isFinite(secPerUnit) || secPerUnit <= 0) return '0:00';
  const m = Math.floor(secPerUnit / 60);
  const s = Math.round(secPerUnit % 60);
  return `${m}:${String(s).padStart(2, '0')}`;
}

export function hmsToSeconds(h: number, m: number, s: number): number {
  return h * 3600 + m * 60 + s;
}

// ---------- Core conversions ----------

export function distanceToKm(d: number, unit: DistanceUnit): number {
  return unit === 'mi' ? d * KM_PER_MI : d;
}

export function kmToDistance(km: number, unit: DistanceUnit): number {
  return unit === 'mi' ? km * MI_PER_KM : km;
}

// Compute pace (sec/unit) from total time and distance (in same unit).
export function paceFromTime(totalSec: number, distance: number): number {
  if (distance <= 0) return 0;
  return totalSec / distance;
}

// Compute speed (unit/hr) from total time and distance.
export function speedFromTime(totalSec: number, distance: number): number {
  if (totalSec <= 0) return 0;
  return distance / (totalSec / 3600);
}

// Convert pace (sec/unit) to speed (unit/hr).
export function paceToSpeed(secPerUnit: number): number {
  if (secPerUnit <= 0) return 0;
  return 3600 / secPerUnit;
}

// Compute total time from distance and pace.
export function timeFromPaceDistance(secPerUnit: number, distance: number): number {
  return secPerUnit * distance;
}

// ---------- Riegel race-time predictor ----------
//
// T2 = T1 × (D2 / D1)^1.06
// T1 is your known time at D1. Returns predicted time in seconds at D2.

export function riegelPredict(
  knownTimeSec: number,
  knownDistKm: number,
  targetDistKm: number,
): number {
  if (knownTimeSec <= 0 || knownDistKm <= 0 || targetDistKm <= 0) return 0;
  return knownTimeSec * Math.pow(targetDistKm / knownDistKm, 1.06);
}

export interface RacePrediction {
  label: string;
  distKm: number;
  timeSec: number;
  paceSecPerKm: number;
  paceSecPerMi: number;
}

export function predictAllRaces(
  knownTimeSec: number,
  knownDistKm: number,
): RacePrediction[] {
  return RACE_PRESETS.map((preset) => {
    const timeSec = riegelPredict(knownTimeSec, knownDistKm, preset.km);
    return {
      label: preset.label,
      distKm: preset.km,
      timeSec: round(timeSec, 0),
      paceSecPerKm: round(timeSec / preset.km, 0),
      paceSecPerMi: round(timeSec / (preset.km * MI_PER_KM), 0),
    };
  });
}
