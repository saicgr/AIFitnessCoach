// Sweat rate calculator.
//
// Standard pre/post weight protocol used in ACSM Position Stand on fluid
// replacement. Sweat rate = weight lost + fluid consumed, divided by duration.
//
// Reference:
//   Sawka MN, Burke LM, Eichner ER, Maughan RJ, Montain SJ, Stachenfeld NS
//   (2007). "American College of Sports Medicine position stand. Exercise
//   and fluid replacement". Medicine and Science in Sports and Exercise
//   39(2):377-390.

import { round, lbToKg } from './units';
import type { WeightUnit } from './units';

export interface SweatInputs {
  preWeight: number;
  postWeight: number;
  weightUnit: WeightUnit;
  fluidIntakeL: number;   // liters consumed during the session
  durationMin: number;    // session length in minutes
}

export interface SweatResult {
  sweatRateLPerHr: number;
  totalSweatLossL: number;
  recommendedReplaceL: number;     // 1.5L per 1L lost, within 4-6h
  needsElectrolytes: boolean;      // > 1.2 L/hr AND > 2hr session
  classification: string;          // Low / Moderate / High / Very high
  notes: string[];
}

function toKg(value: number, unit: WeightUnit): number {
  return unit === 'lb' ? lbToKg(value) : value;
}

function classifyRate(lPerHr: number): string {
  if (lPerHr < 0.5) return 'Low';
  if (lPerHr < 1.0) return 'Moderate';
  if (lPerHr < 1.5) return 'High';
  return 'Very high';
}

export function calculateSweatRate(inputs: SweatInputs): SweatResult | null {
  const { preWeight, postWeight, weightUnit, fluidIntakeL, durationMin } = inputs;
  if (
    preWeight <= 0 ||
    postWeight <= 0 ||
    durationMin <= 0 ||
    fluidIntakeL < 0
  ) {
    return null;
  }

  const preKg = toKg(preWeight, weightUnit);
  const postKg = toKg(postWeight, weightUnit);
  const lossKg = preKg - postKg;
  // 1 kg body mass change ≈ 1 L water.
  const totalSweatLossL = lossKg + fluidIntakeL;
  if (totalSweatLossL <= 0) {
    return {
      sweatRateLPerHr: 0,
      totalSweatLossL: round(totalSweatLossL, 2),
      recommendedReplaceL: 0,
      needsElectrolytes: false,
      classification: 'Net gain',
      notes: [
        'You finished heavier than you started. Either fluid intake was higher than sweat loss, or one of the measurements is off.',
      ],
    };
  }

  const durationHr = durationMin / 60;
  const sweatRateLPerHr = totalSweatLossL / durationHr;
  const recommendedReplaceL = totalSweatLossL * 1.5;
  const needsElectrolytes = sweatRateLPerHr > 1.2 && durationHr > 2;

  const notes: string[] = [];
  if (sweatRateLPerHr > 1.5) {
    notes.push('Very high sweat rate. Plan fluids before, during, and after sessions of any length.');
  }
  if (needsElectrolytes) {
    notes.push('High sweat rate plus a long session raises hyponatremia risk. Include electrolytes (sodium 300-700 mg/L) in your replacement fluid.');
  }
  if (lossKg > preKg * 0.02) {
    notes.push('You lost more than 2% of body mass. That level of dehydration impairs performance and cognition.');
  }
  notes.push('Aim to replace 1.5 L per 1 L lost within 4-6 hours post-session.');

  return {
    sweatRateLPerHr: round(sweatRateLPerHr, 2),
    totalSweatLossL: round(totalSweatLossL, 2),
    recommendedReplaceL: round(recommendedReplaceL, 2),
    needsElectrolytes,
    classification: classifyRate(sweatRateLPerHr),
    notes,
  };
}
