// Calories burned during exercise, using MET values from the Compendium of
// Physical Activities (Ainsworth et al. 2011).
//
// Formula: kcal/min = (MET × 3.5 × weight_kg) / 200
// Then multiply by duration in minutes.
//
// MET values are population averages from indirect calorimetry studies. Real
// energy expenditure varies with fitness, body composition, mechanical
// efficiency, terrain, and equipment. Wearables that include heart rate data
// can produce different numbers, sometimes by 20 to 30 percent.
//
// References:
//   Ainsworth BE, Haskell WL, Herrmann SD et al. (2011). 2011 Compendium of
//     Physical Activities: a second update of codes and MET values.
//     Med Sci Sports Exerc 43(8):1575-1581.
//   Jetté M, Sidney K, Blümchen G (1990). Metabolic equivalents in exercise
//     testing, exercise prescription, and evaluation. Clin Cardiol 13(8).

import { round } from './units';

export interface ActivityMet {
  key: string;
  name: string;
  met: number;
  category: 'walking' | 'running' | 'cycling' | 'swimming' | 'weights' | 'cardio-machine' | 'mind-body' | 'sports' | 'other';
}

export const ACTIVITY_METS: ActivityMet[] = [
  { key: 'walk-3', name: 'Walking, 3 mph (level)', met: 3.5, category: 'walking' },
  { key: 'walk-4', name: 'Walking, 4 mph (brisk)', met: 5.0, category: 'walking' },
  { key: 'hike-pack', name: 'Hiking with backpack', met: 7.3, category: 'walking' },

  { key: 'run-5', name: 'Running, 5 mph (12 min/mi)', met: 8.3, category: 'running' },
  { key: 'run-6', name: 'Running, 6 mph (10 min/mi)', met: 9.8, category: 'running' },
  { key: 'run-7', name: 'Running, 7 mph (8.5 min/mi)', met: 11.0, category: 'running' },
  { key: 'run-8', name: 'Running, 8 mph (7.5 min/mi)', met: 11.8, category: 'running' },

  { key: 'cycle-12', name: 'Cycling, 12 to 14 mph', met: 8.0, category: 'cycling' },
  { key: 'cycle-14', name: 'Cycling, 14 to 16 mph', met: 10.0, category: 'cycling' },
  { key: 'cycle-16', name: 'Cycling, 16 to 19 mph', met: 12.0, category: 'cycling' },

  { key: 'swim-mod', name: 'Swimming, moderate freestyle', met: 7.0, category: 'swimming' },
  { key: 'swim-vig', name: 'Swimming, vigorous', met: 9.8, category: 'swimming' },

  { key: 'lift-light', name: 'Weight training, light or moderate', met: 3.5, category: 'weights' },
  { key: 'lift-vig', name: 'Weight training, vigorous', met: 6.0, category: 'weights' },

  { key: 'row-mod', name: 'Rowing machine, moderate', met: 7.0, category: 'cardio-machine' },
  { key: 'elliptical', name: 'Elliptical, moderate', met: 5.0, category: 'cardio-machine' },
  { key: 'stairmaster', name: 'Stairmaster', met: 9.0, category: 'cardio-machine' },

  { key: 'hiit', name: 'HIIT or CrossFit', met: 8.0, category: 'other' },
  { key: 'yoga-hatha', name: 'Yoga, hatha', met: 2.5, category: 'mind-body' },
  { key: 'yoga-power', name: 'Yoga, vinyasa or power', met: 4.0, category: 'mind-body' },
  { key: 'pilates', name: 'Pilates', met: 3.0, category: 'mind-body' },

  { key: 'box-spar', name: 'Boxing, sparring', met: 7.8, category: 'sports' },
  { key: 'basketball', name: 'Basketball, game', met: 8.0, category: 'sports' },
  { key: 'soccer', name: 'Soccer, competitive', met: 10.0, category: 'sports' },
  { key: 'tennis', name: 'Tennis, singles', met: 7.3, category: 'sports' },
];

export const ACTIVITY_CATEGORIES: { key: ActivityMet['category']; label: string }[] = [
  { key: 'walking', label: 'Walking and hiking' },
  { key: 'running', label: 'Running' },
  { key: 'cycling', label: 'Cycling' },
  { key: 'swimming', label: 'Swimming' },
  { key: 'weights', label: 'Weight training' },
  { key: 'cardio-machine', label: 'Cardio machines' },
  { key: 'mind-body', label: 'Yoga and Pilates' },
  { key: 'sports', label: 'Sports' },
  { key: 'other', label: 'HIIT and other' },
];

export function findActivity(key: string): ActivityMet | undefined {
  return ACTIVITY_METS.find((a) => a.key === key);
}

// Core formula. kcal = MET × 3.5 × kg / 200 × minutes.
export function caloriesBurned(met: number, weightKg: number, minutes: number): number {
  if (met <= 0 || weightKg <= 0 || minutes <= 0) return 0;
  const kcalPerMin = (met * 3.5 * weightKg) / 200;
  return round(kcalPerMin * minutes, 0);
}

export function kcalPerMinute(met: number, weightKg: number): number {
  if (met <= 0 || weightKg <= 0) return 0;
  return round((met * 3.5 * weightKg) / 200, 2);
}
