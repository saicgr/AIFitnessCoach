// Body fat percentage estimation methods.
//
// We expose 5 published methods, each with different input requirements
// and accuracy bands:
//
//   - Navy (US Navy circumference): tape measure only, ~3-4 percent SEE
//   - Jackson-Pollock 3-site skinfold: calipers required, ~3 percent SEE
//   - Jackson-Pollock 7-site skinfold: calipers, most accurate field method
//   - Covert Bailey: simplified circumference, ~4-6 percent SEE
//   - RFM (Relative Fat Mass, Woolcott-Bergman 2018): waist + height only
//
// Skinfold methods compute body density (BD) first, then convert to body
// fat % via the Siri equation: BF% = (495 / BD) - 450.
//
// References:
//   Hodgdon JA, Beckett MB (1984). Prediction of percent body fat for
//     U.S. Navy men and women from body circumferences and height.
//     Naval Health Research Center Reports.
//   Jackson AS, Pollock ML (1978). Generalized equations for predicting
//     body density of men. Br J Nutr 40(3):497-504.
//   Jackson AS, Pollock ML, Ward A (1980). Generalized equations for
//     predicting body density of women. Med Sci Sports Exerc 12(3):175-81.
//   Siri WE (1961). Body composition from fluid spaces and density:
//     analysis of methods. UC Berkeley Donner Lab Report.
//   Woolcott OO, Bergman RN (2018). Relative Fat Mass (RFM) as a new
//     estimator of whole-body fat percentage. Sci Rep 8:10980.

import { round, cmToIn } from './units';
import type { Sex } from './units';

export type BodyFatMethod = 'navy' | 'jp3' | 'jp7' | 'bailey' | 'rfm';

export interface BodyFatMethodInfo {
  key: BodyFatMethod;
  name: string;
  bestFor: string;
  needs: string;
  citation: string;
}

export const BODY_FAT_METHODS: BodyFatMethodInfo[] = [
  {
    key: 'navy',
    name: 'US Navy',
    bestFor: 'Tape-measure-only method. Good baseline tracking.',
    needs: 'Height, neck, waist (men). Add hip for women.',
    citation: 'Hodgdon & Beckett (1984), Naval Health Research Center',
  },
  {
    key: 'jp3',
    name: 'Jackson-Pollock 3-site',
    bestFor: 'Skinfold method with 3 sites. Most popular gym standard.',
    needs: 'Skinfold calipers. Men: chest, abdomen, thigh. Women: triceps, suprailiac, thigh.',
    citation: 'Jackson & Pollock (1978, 1980)',
  },
  {
    key: 'jp7',
    name: 'Jackson-Pollock 7-site',
    bestFor: 'Most accurate field method. Used by ACSM and NSCA.',
    needs: 'Skinfold calipers. 7 sites: chest, midaxillary, triceps, subscapular, abdomen, suprailiac, thigh.',
    citation: 'Jackson & Pollock (1978, 1980)',
  },
  {
    key: 'bailey',
    name: 'Covert Bailey',
    bestFor: 'Simplified circumference method. Less rigorous, quick screen.',
    needs: 'Body weight plus simple circumference sites.',
    citation: 'Bailey C (1991), The New Fit or Fat',
  },
  {
    key: 'rfm',
    name: 'RFM (Woolcott-Bergman)',
    bestFor: 'Newest method. Waist and height only. Strong DEXA correlation.',
    needs: 'Height and waist circumference.',
    citation: 'Woolcott & Bergman (2018), Sci Rep 8:10980',
  },
];

// ---- Navy method (US Navy circumference) ----
// All inputs in inches. Heights and circumferences must be at consistent landmarks.
export interface NavyInputs {
  heightCm: number;
  neckCm: number;
  waistCm: number;
  hipCm?: number; // required for women
  sex: Sex;
}

export function navy(inputs: NavyInputs): number {
  const heightIn = cmToIn(inputs.heightCm);
  const neckIn = cmToIn(inputs.neckCm);
  const waistIn = cmToIn(inputs.waistCm);
  if (inputs.sex === 'male') {
    const diff = waistIn - neckIn;
    if (diff <= 0) return NaN;
    return 86.010 * Math.log10(diff) - 70.041 * Math.log10(heightIn) + 36.76;
  }
  const hipIn = inputs.hipCm ? cmToIn(inputs.hipCm) : 0;
  const sum = waistIn + hipIn - neckIn;
  if (sum <= 0 || !inputs.hipCm) return NaN;
  return 163.205 * Math.log10(sum) - 97.684 * Math.log10(heightIn) - 78.387;
}

// ---- Siri equation (1961) ----
function siri(bodyDensity: number): number {
  return 495 / bodyDensity - 450;
}

// ---- Jackson-Pollock 3-site skinfold ----
// Sites (mm):
//   Men: chest, abdomen, thigh
//   Women: triceps, suprailiac, thigh
export interface JP3Inputs {
  age: number;
  sex: Sex;
  // millimeters
  chest?: number;
  abdomen?: number;
  thigh: number;
  triceps?: number;
  suprailiac?: number;
}

export function jp3(inputs: JP3Inputs): number {
  if (inputs.sex === 'male') {
    if (
      inputs.chest === undefined ||
      inputs.abdomen === undefined ||
      inputs.thigh === undefined
    ) {
      return NaN;
    }
    const sum = inputs.chest + inputs.abdomen + inputs.thigh;
    const bd =
      1.10938 -
      0.0008267 * sum +
      0.0000016 * sum * sum -
      0.0002574 * inputs.age;
    return siri(bd);
  }
  if (
    inputs.triceps === undefined ||
    inputs.suprailiac === undefined ||
    inputs.thigh === undefined
  ) {
    return NaN;
  }
  const sum = inputs.triceps + inputs.suprailiac + inputs.thigh;
  const bd =
    1.0994921 -
    0.0009929 * sum +
    0.0000023 * sum * sum -
    0.0001392 * inputs.age;
  return siri(bd);
}

// ---- Jackson-Pollock 7-site skinfold ----
// Sites (mm): chest, midaxillary, triceps, subscapular, abdomen, suprailiac, thigh.
export interface JP7Inputs {
  age: number;
  sex: Sex;
  chest: number;
  midaxillary: number;
  triceps: number;
  subscapular: number;
  abdomen: number;
  suprailiac: number;
  thigh: number;
}

export function jp7(inputs: JP7Inputs): number {
  const sum =
    inputs.chest +
    inputs.midaxillary +
    inputs.triceps +
    inputs.subscapular +
    inputs.abdomen +
    inputs.suprailiac +
    inputs.thigh;
  if (sum <= 0) return NaN;
  let bd: number;
  if (inputs.sex === 'male') {
    bd =
      1.112 -
      0.00043499 * sum +
      0.00000055 * sum * sum -
      0.00028826 * inputs.age;
  } else {
    bd =
      1.097 -
      0.00046971 * sum +
      0.00000056 * sum * sum -
      0.00012828 * inputs.age;
  }
  return siri(bd);
}

// ---- Covert Bailey (simplified circumference) ----
// Bailey's published shortcut uses sex-specific circumference sums. We
// approximate with the same Navy-style inputs the user already provides,
// adjusted by Bailey's published lighter-touch coefficients. Marked as
// "less rigorous" in the UI for that reason.
export interface BaileyInputs {
  waistCm: number;
  hipCm?: number;
  heightCm: number;
  sex: Sex;
}

export function bailey(inputs: BaileyInputs): number {
  const waistIn = cmToIn(inputs.waistCm);
  const heightIn = cmToIn(inputs.heightCm);
  if (inputs.sex === 'male') {
    // Simplified: waist-to-height ratio × 100 - constant.
    return Math.max(2, 98.42 * (waistIn / heightIn) - 35.5);
  }
  const hipIn = inputs.hipCm ? cmToIn(inputs.hipCm) : 0;
  return Math.max(2, 76.5 * ((waistIn + hipIn) / heightIn) - 28);
}

// ---- RFM (Relative Fat Mass) ----
// Inputs in cm.
export interface RfmInputs {
  heightCm: number;
  waistCm: number;
  sex: Sex;
}

export function rfm(inputs: RfmInputs): number {
  if (inputs.waistCm <= 0) return NaN;
  const ratio = (20 * inputs.heightCm) / inputs.waistCm;
  return inputs.sex === 'male' ? 64 - ratio : 76 - ratio;
}

// ---- Bundled multi-method calculation ----
export interface BodyFatResult {
  method: BodyFatMethod;
  name: string;
  value: number; // %
  bestFor: string;
  citation: string;
  available: boolean;
}

export interface BodyFatAllInputs {
  // Common
  sex: Sex;
  age: number;
  heightCm?: number;
  weightKg?: number;
  // Navy / Bailey / RFM
  neckCm?: number;
  waistCm?: number;
  hipCm?: number;
  // Skinfolds (mm)
  chest?: number;
  abdomen?: number;
  thigh?: number;
  triceps?: number;
  suprailiac?: number;
  midaxillary?: number;
  subscapular?: number;
}

export function calculateAllBodyFat(inputs: BodyFatAllInputs): BodyFatResult[] {
  const results: BodyFatResult[] = [];

  // Navy
  if (
    inputs.heightCm &&
    inputs.neckCm &&
    inputs.waistCm &&
    (inputs.sex === 'male' || inputs.hipCm)
  ) {
    const v = navy({
      heightCm: inputs.heightCm,
      neckCm: inputs.neckCm,
      waistCm: inputs.waistCm,
      hipCm: inputs.hipCm,
      sex: inputs.sex,
    });
    results.push(buildResult('navy', v));
  } else {
    results.push(buildResult('navy', NaN, false));
  }

  // JP3
  const jp3Inputs: JP3Inputs = {
    age: inputs.age,
    sex: inputs.sex,
    chest: inputs.chest,
    abdomen: inputs.abdomen,
    thigh: inputs.thigh ?? 0,
    triceps: inputs.triceps,
    suprailiac: inputs.suprailiac,
  };
  const jp3Available =
    inputs.sex === 'male'
      ? inputs.chest !== undefined && inputs.abdomen !== undefined && inputs.thigh !== undefined
      : inputs.triceps !== undefined && inputs.suprailiac !== undefined && inputs.thigh !== undefined;
  results.push(buildResult('jp3', jp3Available ? jp3(jp3Inputs) : NaN, jp3Available));

  // JP7
  const jp7Ready =
    inputs.chest !== undefined &&
    inputs.midaxillary !== undefined &&
    inputs.triceps !== undefined &&
    inputs.subscapular !== undefined &&
    inputs.abdomen !== undefined &&
    inputs.suprailiac !== undefined &&
    inputs.thigh !== undefined;
  if (jp7Ready) {
    results.push(
      buildResult(
        'jp7',
        jp7({
          age: inputs.age,
          sex: inputs.sex,
          chest: inputs.chest!,
          midaxillary: inputs.midaxillary!,
          triceps: inputs.triceps!,
          subscapular: inputs.subscapular!,
          abdomen: inputs.abdomen!,
          suprailiac: inputs.suprailiac!,
          thigh: inputs.thigh!,
        }),
      ),
    );
  } else {
    results.push(buildResult('jp7', NaN, false));
  }

  // Bailey
  if (inputs.heightCm && inputs.waistCm && (inputs.sex === 'male' || inputs.hipCm)) {
    results.push(
      buildResult(
        'bailey',
        bailey({
          waistCm: inputs.waistCm,
          hipCm: inputs.hipCm,
          heightCm: inputs.heightCm,
          sex: inputs.sex,
        }),
      ),
    );
  } else {
    results.push(buildResult('bailey', NaN, false));
  }

  // RFM
  if (inputs.heightCm && inputs.waistCm) {
    results.push(
      buildResult(
        'rfm',
        rfm({
          heightCm: inputs.heightCm,
          waistCm: inputs.waistCm,
          sex: inputs.sex,
        }),
      ),
    );
  } else {
    results.push(buildResult('rfm', NaN, false));
  }

  return results;
}

function buildResult(method: BodyFatMethod, value: number, available = true): BodyFatResult {
  const info = BODY_FAT_METHODS.find((m) => m.key === method)!;
  const ok = available && Number.isFinite(value);
  return {
    method,
    name: info.name,
    value: ok ? round(value, 1) : 0,
    bestFor: info.bestFor,
    citation: info.citation,
    available: ok,
  };
}

// Recommended method, based on what data the user has.
export function recommendedBodyFatMethod(inputs: BodyFatAllInputs): BodyFatMethod {
  const jp7Ready =
    inputs.chest !== undefined &&
    inputs.midaxillary !== undefined &&
    inputs.triceps !== undefined &&
    inputs.subscapular !== undefined &&
    inputs.abdomen !== undefined &&
    inputs.suprailiac !== undefined &&
    inputs.thigh !== undefined;
  if (jp7Ready) return 'jp7';
  const jp3Ready =
    inputs.sex === 'male'
      ? inputs.chest !== undefined && inputs.abdomen !== undefined && inputs.thigh !== undefined
      : inputs.triceps !== undefined && inputs.suprailiac !== undefined && inputs.thigh !== undefined;
  if (jp3Ready) return 'jp3';
  if (inputs.neckCm && inputs.waistCm) return 'navy';
  return 'rfm';
}

// ACE-published body fat % categories (illustrative).
export function bodyFatCategory(bf: number, sex: Sex): string {
  if (sex === 'male') {
    if (bf < 6) return 'Essential fat';
    if (bf < 14) return 'Athletes';
    if (bf < 18) return 'Fitness';
    if (bf < 25) return 'Average';
    return 'Obese';
  }
  if (bf < 14) return 'Essential fat';
  if (bf < 21) return 'Athletes';
  if (bf < 25) return 'Fitness';
  if (bf < 32) return 'Average';
  return 'Obese';
}
