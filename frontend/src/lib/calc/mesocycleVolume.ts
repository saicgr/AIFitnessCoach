// Mesocycle volume ramp builder.
//
// A mesocycle in the RP framework is a 4-6 week block where weekly volume
// climbs linearly from MEV (start) toward MRV (peak), with a deload at the end
// dropping back to MV. The rep range typically drifts within the cycle: lower
// reps and higher load early, slightly higher reps and accumulated fatigue
// late.
//
// References:
//   Israetel M, Helms ER, Hoffmann J (2017). Renaissance Periodization
//     Hypertrophy Volume Algorithm.

import { BASE_VOLUME_LANDMARKS } from './workoutVolume';

export interface MesocycleInputs {
  muscle: string;
  startSets: number;     // typically MEV
  peakSets: number;      // typically MAV high or MRV - 2
  weeks: 4 | 5 | 6;
  mv: number;            // floor for deload week
}

export interface MesocycleWeek {
  week: number;
  sets: number;
  repRange: string;
  intent: string;
  isDeload: boolean;
}

// Linear ramp from start to peak across (weeks - 1) accumulation weeks,
// then one deload week at MV.
export function buildMesocycle(inputs: MesocycleInputs): MesocycleWeek[] {
  const { startSets, peakSets, weeks, mv } = inputs;
  if (weeks < 4 || weeks > 6) return [];
  if (peakSets < startSets) return [];

  const accumulationWeeks = weeks - 1;
  const ramp = peakSets - startSets;
  const result: MesocycleWeek[] = [];

  for (let i = 0; i < accumulationWeeks; i++) {
    const progress = accumulationWeeks === 1 ? 1 : i / (accumulationWeeks - 1);
    const sets = Math.round(startSets + ramp * progress);
    result.push({
      week: i + 1,
      sets,
      repRange: repRangeForWeek(i, accumulationWeeks),
      intent: intentForWeek(i, accumulationWeeks),
      isDeload: false,
    });
  }

  result.push({
    week: weeks,
    sets: mv,
    repRange: '8-12',
    intent: 'Deload. Cut sets to MV, keep technique fresh, drop RPE to 5-6.',
    isDeload: true,
  });

  return result;
}

// Early weeks favor strength rep ranges, mid weeks hypertrophy, late weeks
// drift toward metabolic work as fatigue accumulates.
function repRangeForWeek(idx: number, total: number): string {
  const p = total <= 1 ? 0 : idx / (total - 1);
  if (p < 0.34) return '5-8';
  if (p < 0.67) return '8-12';
  return '12-20';
}

function intentForWeek(idx: number, total: number): string {
  const p = total <= 1 ? 0 : idx / (total - 1);
  if (p < 0.34) return 'Accumulate base volume. RPE 6-7. Add a rep or 5 lb each set.';
  if (p < 0.67) return 'Push volume. RPE 7-8. Focus on bar speed and form.';
  return 'Peak volume. RPE 8-9. Last hard week before deload.';
}

// Helper for the page: get default start/peak for a chosen muscle.
export function defaultsForMuscle(muscleName: string): {
  startSets: number;
  peakSets: number;
  mv: number;
} | null {
  const base = BASE_VOLUME_LANDMARKS.find((m) => m.muscle === muscleName);
  if (!base) return null;
  return {
    startSets: base.mev || 6,
    peakSets: Math.max(base.mavHigh, base.mrv - 2),
    mv: base.mv,
  };
}

export const MUSCLE_OPTIONS = BASE_VOLUME_LANDMARKS.map((m) => m.muscle);
