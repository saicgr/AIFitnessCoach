// Powerlifting peak-week taper builder.
//
// Standard 4-week taper applied to squat, bench, or deadlift. Weights are
// expressed as a percentage of the planned competition opener (which itself is
// ~90-92% of true 1RM). Sets and reps follow the volume -> intensification ->
// peak -> deload curve common to Helms/Israetel programming and Pritchard's
// taper review.
//
// References:
//   Helms ER, Morgan A, Valdez A (2018). The Muscle and Strength Pyramid:
//     Training. 2nd ed.
//   Pritchard H et al. (2015). Tapering practices of strength and power
//     athletes. JSCR 29(8): 2228-2236.

import { round } from './units';

export type Lift = 'squat' | 'bench' | 'deadlift';

export interface TaperInputs {
  lift: Lift;
  trueOneRm: number;          // user's actual 1RM
  unit: 'lb' | 'kg';
}

export interface TaperWeek {
  label: string;              // e.g. "Week -4"
  daysOut: number;
  pctLow: number;             // % of opener
  pctHigh: number;
  reps: string;               // "3-5"
  sets: number;
  intent: string;
  workingWeightLow: number;   // pre-rounded weight in input unit
  workingWeightHigh: number;
}

// Opener is the conservative first attempt on competition day, typically
// 90-92% of true 1RM. We anchor the taper percentages to this opener.
export const OPENER_PCT_OF_1RM = 0.91;

interface TaperTemplate {
  label: string;
  daysOut: number;
  pctLow: number;
  pctHigh: number;
  reps: string;
  sets: number;
  intent: string;
}

const SQUAT_BENCH_TEMPLATE: TaperTemplate[] = [
  {
    label: 'Week -4',
    daysOut: 28,
    pctLow: 70,
    pctHigh: 80,
    reps: '3-5',
    sets: 4,
    intent: 'Volume block. Build tissue capacity. Bar speed is the key signal.',
  },
  {
    label: 'Week -3',
    daysOut: 21,
    pctLow: 80,
    pctHigh: 85,
    reps: '3',
    sets: 3,
    intent: 'Intensification. Triples at moderate-heavy load. Keep technique tight.',
  },
  {
    label: 'Week -2',
    daysOut: 14,
    pctLow: 87,
    pctHigh: 92,
    reps: '1-2',
    sets: 3,
    intent: 'Peak. Heavy singles and doubles. Confirm opener feels easy.',
  },
  {
    label: 'Week -1',
    daysOut: 7,
    pctLow: 60,
    pctHigh: 70,
    reps: '2',
    sets: 2,
    intent: 'Deload. Keep the movement pattern grooved. RPE 5-6 maximum.',
  },
  {
    label: 'Competition day',
    daysOut: 0,
    pctLow: 90,
    pctHigh: 92,
    reps: '1',
    sets: 1,
    intent: 'Open here. Built to make it. Save peak attempts for second and third.',
  },
];

// Deadlift recovers slower than squat or bench. Pull the heavy peak week
// further from the meet by one extra day and reduce volume in week -4.
const DEADLIFT_TEMPLATE: TaperTemplate[] = [
  { label: 'Week -4', daysOut: 28, pctLow: 70, pctHigh: 78, reps: '3-5', sets: 3, intent: 'Volume block. Three back-off sets keep CNS load lower than squat or bench.' },
  { label: 'Week -3', daysOut: 21, pctLow: 80, pctHigh: 85, reps: '3', sets: 3, intent: 'Intensification. Triples with controlled lockout.' },
  { label: 'Week -2', daysOut: 15, pctLow: 87, pctHigh: 92, reps: '1', sets: 2, intent: 'Peak heavy single early in the week. Allow extra recovery before deload.' },
  { label: 'Week -1', daysOut: 7, pctLow: 55, pctHigh: 65, reps: '2', sets: 2, intent: 'Deload. Light pulls only. Keep your back fresh for meet day.' },
  { label: 'Competition day', daysOut: 0, pctLow: 90, pctHigh: 92, reps: '1', sets: 1, intent: 'Open conservative. Deadlift fatigue compounds across the meet day.' },
];

export function buildTaper(inputs: TaperInputs): TaperWeek[] {
  const { lift, trueOneRm } = inputs;
  if (trueOneRm <= 0) return [];
  const opener = trueOneRm * OPENER_PCT_OF_1RM;
  const template = lift === 'deadlift' ? DEADLIFT_TEMPLATE : SQUAT_BENCH_TEMPLATE;

  return template.map((t) => ({
    label: t.label,
    daysOut: t.daysOut,
    pctLow: t.pctLow,
    pctHigh: t.pctHigh,
    reps: t.reps,
    sets: t.sets,
    intent: t.intent,
    workingWeightLow: round(opener * (t.pctLow / 100) / 2.5) * 2.5,
    workingWeightHigh: round(opener * (t.pctHigh / 100) / 2.5) * 2.5,
  }));
}

export const LIFT_LABELS: Record<Lift, string> = {
  squat: 'Squat',
  bench: 'Bench Press',
  deadlift: 'Deadlift',
};
