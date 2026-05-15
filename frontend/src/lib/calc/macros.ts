// Daily macronutrient targets (protein, carbs, fat) given a calorie target
// and bodyweight. Protein and fat are anchored to bodyweight; carbs fill the
// remaining calorie budget.
//
// Protein bands: 1.6-2.2 g/kg bodyweight is the consensus range for active
// adults supporting lean-mass retention in a deficit or muscle gain in a
// surplus (Helms 2014, Aragon & Schoenfeld 2013, Morton 2018).
//
// Fat floor: 0.8-1.0 g/kg bodyweight is the practical minimum to preserve
// endocrine function (testosterone, sex hormones, fat-soluble vitamin
// absorption). Going lower is sustainable short-term but not optimal.
//
// References:
//   Helms ER, Aragon AA, Fitschen PJ (2014). Evidence-based recommendations
//     for natural bodybuilding contest preparation: nutrition and supplementation.
//     JISSN 11:20.
//   Aragon AA, Schoenfeld BJ (2013). Nutrient timing revisited: is there a
//     post-exercise anabolic window? JISSN 10:5.
//   Mettler S, Mitchell N, Tipton KD (2010). Increased protein intake reduces
//     lean body mass loss during weight loss in athletes. MSSE 42(2):326-37.
//   Morton RW et al. (2018). A systematic review, meta-analysis and
//     meta-regression of the effect of protein supplementation on resistance
//     training-induced gains in muscle mass and strength in healthy adults.
//     Br J Sports Med 52(6):376-384.

import { round } from './units';

export type MacroGoal = 'cut' | 'maintain' | 'bulk';
export type MacroPreset = 'balanced' | 'high_protein' | 'keto';

export interface MacroPresetInfo {
  key: MacroPreset;
  name: string;
  description: string;
  proteinPerKg: number;     // g/kg bodyweight
  fatPerKg: number;         // g/kg bodyweight (used when not fat-driven)
  fatKcalPct?: number;      // if set, fat is calculated as % of kcal instead
}

export const MACRO_PRESETS: MacroPresetInfo[] = [
  {
    key: 'balanced',
    name: 'Balanced',
    description: 'Standard split for most lifters. Protein high enough for recomp, carbs and fat balanced.',
    proteinPerKg: 2.0,
    fatPerKg: 0.9,
  },
  {
    key: 'high_protein',
    name: 'High-Protein Cut',
    description: 'Maximum protein for lean mass retention in a deficit. Fat at the floor, carbs fuel training.',
    proteinPerKg: 2.4,
    fatPerKg: 0.8,
  },
  {
    key: 'keto',
    name: 'Keto',
    description: 'Fat-driven, very-low-carb. Fat is 75% of calories. Carbs are leftovers, typically under 50 g.',
    proteinPerKg: 2.0,
    fatPerKg: 0,
    fatKcalPct: 0.75,
  },
];

export const GOAL_MULTIPLIERS: Record<MacroGoal, number> = {
  cut: 0.8,
  maintain: 1.0,
  bulk: 1.1,
};

export interface MacroInputs {
  tdee: number;                 // maintenance calories
  bodyweightKg: number;
  goal: MacroGoal;
  preset: MacroPreset;
}

export interface MacroResult {
  calories: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  protein_pct: number;
  carbs_pct: number;
  fat_pct: number;
  protein_per_kg: number;
  fat_per_kg: number;
  preset: MacroPreset;
  goal: MacroGoal;
}

export function findPreset(key: MacroPreset): MacroPresetInfo {
  return MACRO_PRESETS.find((p) => p.key === key) ?? MACRO_PRESETS[0];
}

export function calculateMacros(inputs: MacroInputs): MacroResult {
  const { tdee, bodyweightKg, goal, preset } = inputs;
  const presetInfo = findPreset(preset);
  const calories = Math.round(tdee * GOAL_MULTIPLIERS[goal]);

  const proteinG = Math.round(bodyweightKg * presetInfo.proteinPerKg);
  const proteinKcal = proteinG * 4;

  let fatG: number;
  if (presetInfo.fatKcalPct) {
    fatG = Math.round((calories * presetInfo.fatKcalPct) / 9);
  } else {
    fatG = Math.round(bodyweightKg * presetInfo.fatPerKg);
  }
  const fatKcal = fatG * 9;

  const remainingKcal = Math.max(0, calories - proteinKcal - fatKcal);
  const carbsG = Math.round(remainingKcal / 4);
  const carbsKcal = carbsG * 4;

  const total = proteinKcal + carbsKcal + fatKcal;
  return {
    calories,
    protein_g: proteinG,
    carbs_g: carbsG,
    fat_g: fatG,
    protein_pct: round((proteinKcal / total) * 100, 0),
    carbs_pct: round((carbsKcal / total) * 100, 0),
    fat_pct: round((fatKcal / total) * 100, 0),
    protein_per_kg: round(proteinG / bodyweightKg, 2),
    fat_per_kg: round(fatG / bodyweightKg, 2),
    preset,
    goal,
  };
}

// Quick TDEE estimate (Mifflin-St Jeor × activity) when user doesn't have one.
// This is a fallback. Direct TDEE input is preferred when available.
export function estimateTdee(
  bodyweightKg: number,
  heightCm: number,
  age: number,
  sex: 'male' | 'female',
  activityMultiplier: number,
): number {
  const s = sex === 'male' ? 5 : -161;
  const bmr = 10 * bodyweightKg + 6.25 * heightCm - 5 * age + s;
  return Math.round(bmr * activityMultiplier);
}
