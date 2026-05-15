// Unit conversion helpers shared across all calculators.
// All math functions internally use metric (kg, cm, m, mL).
// UI toggles convert at display + input boundaries.

export type WeightUnit = 'kg' | 'lb';
export type LengthUnit = 'cm' | 'in';
export type HeightUnit = 'cm' | 'ft';
export type Sex = 'male' | 'female';

export const KG_PER_LB = 0.45359237;
export const CM_PER_IN = 2.54;

export const lbToKg = (lb: number): number => lb * KG_PER_LB;
export const kgToLb = (kg: number): number => kg / KG_PER_LB;

export const inToCm = (inches: number): number => inches * CM_PER_IN;
export const cmToIn = (cm: number): number => cm / CM_PER_IN;

export const ftInToCm = (ft: number, inches: number): number =>
  ftInToIn(ft, inches) * CM_PER_IN;

export const ftInToIn = (ft: number, inches: number): number =>
  ft * 12 + inches;

export const cmToFtIn = (cm: number): { ft: number; in: number } => {
  const totalIn = cm / CM_PER_IN;
  const ft = Math.floor(totalIn / 12);
  const inches = Math.round((totalIn - ft * 12) * 10) / 10;
  return { ft, in: inches };
};

export const round = (n: number, digits = 1): number =>
  Math.round(n * 10 ** digits) / 10 ** digits;

export const toWeight = (value: number, from: WeightUnit, to: WeightUnit): number => {
  if (from === to) return value;
  return from === 'lb' ? lbToKg(value) : kgToLb(value);
};

export const toLength = (value: number, from: LengthUnit, to: LengthUnit): number => {
  if (from === to) return value;
  return from === 'in' ? inToCm(value) : cmToIn(value);
};

export const formatWeight = (kg: number, unit: WeightUnit, digits = 1): string => {
  const v = unit === 'lb' ? kgToLb(kg) : kg;
  return `${round(v, digits)} ${unit}`;
};

export const formatLength = (cm: number, unit: LengthUnit, digits = 1): string => {
  const v = unit === 'in' ? cmToIn(cm) : cm;
  return `${round(v, digits)} ${unit}`;
};
