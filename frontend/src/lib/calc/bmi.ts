// Body Mass Index (BMI) — kg / m².
//
// BMI is a population-level screening tool, not a diagnostic. It does not
// distinguish muscle from fat, so it consistently mislabels muscular athletes
// as overweight or obese, and can label sarcopenic older adults as healthy.
// We surface the value and category but flag those caveats prominently.
//
// References:
//   WHO (2000). Obesity: Preventing and Managing the Global Epidemic.
//     WHO Technical Report Series 894. Geneva.
//   NIH NHLBI (1998). Clinical Guidelines on the Identification, Evaluation,
//     and Treatment of Overweight and Obesity in Adults.

import { round } from './units';

export type BmiCategory =
  | 'underweight'
  | 'normal'
  | 'overweight'
  | 'obese-i'
  | 'obese-ii'
  | 'obese-iii';

export interface BmiCategoryInfo {
  key: BmiCategory;
  label: string;
  range: string;
  note: string;
  color: string; // tailwind text color class
}

export const BMI_CATEGORIES: BmiCategoryInfo[] = [
  {
    key: 'underweight',
    label: 'Underweight',
    range: 'BMI < 18.5',
    note: 'May indicate insufficient energy intake or undiagnosed health issues.',
    color: 'text-sky-400',
  },
  {
    key: 'normal',
    label: 'Normal weight',
    range: 'BMI 18.5 to 24.9',
    note: 'WHO-defined healthy range for the general adult population.',
    color: 'text-emerald-400',
  },
  {
    key: 'overweight',
    label: 'Overweight',
    range: 'BMI 25.0 to 29.9',
    note: 'Elevated cardiometabolic risk at the population level. Often misclassifies muscular individuals.',
    color: 'text-amber-400',
  },
  {
    key: 'obese-i',
    label: 'Obesity class I',
    range: 'BMI 30.0 to 34.9',
    note: 'Moderate health risk. Body composition still matters more than the number itself.',
    color: 'text-orange-400',
  },
  {
    key: 'obese-ii',
    label: 'Obesity class II',
    range: 'BMI 35.0 to 39.9',
    note: 'High health risk. Consider clinical evaluation alongside body composition data.',
    color: 'text-rose-400',
  },
  {
    key: 'obese-iii',
    label: 'Obesity class III',
    range: 'BMI 40.0 and above',
    note: 'Very high health risk. Often called severe or morbid obesity in clinical settings.',
    color: 'text-red-500',
  },
];

export function calculateBmi(weightKg: number, heightCm: number): number {
  if (weightKg <= 0 || heightCm <= 0) return 0;
  const heightM = heightCm / 100;
  return round(weightKg / (heightM * heightM), 1);
}

export function bmiCategory(bmi: number): BmiCategoryInfo {
  if (bmi < 18.5) return BMI_CATEGORIES[0];
  if (bmi < 25) return BMI_CATEGORIES[1];
  if (bmi < 30) return BMI_CATEGORIES[2];
  if (bmi < 35) return BMI_CATEGORIES[3];
  if (bmi < 40) return BMI_CATEGORIES[4];
  return BMI_CATEGORIES[5];
}

// Weight needed to reach a given BMI at this height.
export function weightForBmi(targetBmi: number, heightCm: number): number {
  const heightM = heightCm / 100;
  return round(targetBmi * heightM * heightM, 1);
}
