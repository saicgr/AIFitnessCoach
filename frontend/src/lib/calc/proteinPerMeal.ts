// Optimal per-meal protein split for maximizing muscle protein synthesis (MPS).
//
// Research basis: 0.4-0.55 g/kg bodyweight per meal is the dose that maximally
// stimulates MPS in resistance-trained adults. Below ~0.3 g/kg the leucine
// threshold for full MPS activation is often missed. Above ~0.55 g/kg the
// extra protein is still useful for daily totals but adds little to that
// meal's MPS spike. Roughly 3-5 g leucine per meal is the practical leucine
// trigger.
//
// Practical implication: spreading 2 g/kg/day across 4 meals of 0.5 g/kg
// each maximally stimulates MPS 4x per day. Spreading the same total
// across 2 huge meals of 1.0 g/kg each leaves MPS "flat" for the other
// 16 waking hours.
//
// Algorithm:
//   evenPerMeal = totalProtein / meals
//   optimalPerMeal = clamp(totalProtein / meals, 0.4 g/kg, 0.55 g/kg)
//   If even split exceeds 0.55 g/kg, suggest more meals.
//   If even split falls below 0.4 g/kg, suggest more total protein or fewer meals.
//
// References:
//   Schoenfeld BJ, Aragon AA (2018). How much protein can the body use in a
//     single meal for muscle-building? Implications for daily protein
//     distribution. JISSN 15:10.
//   Moore DR et al. (2009). Ingested protein dose response of muscle and
//     albumin protein synthesis after resistance exercise in young men.
//     AJCN 89(1):161-8.
//   Macnaughton LS et al. (2016). The response of muscle protein synthesis
//     following whole-body resistance exercise is greater following 40 g
//     than 20 g of ingested whey protein. Physiol Rep 4(15):e12893.
//   Areta JL et al. (2013). Timing and distribution of protein ingestion
//     during prolonged recovery from resistance exercise alters myofibrillar
//     protein synthesis. J Physiol 591(9):2319-31.

import { round } from './units';

export interface ProteinPerMealInputs {
  totalProteinG: number;
  meals: number;             // 2-6
  bodyweightKg: number;
}

export interface MealProtein {
  mealNum: number;
  proteinG: number;
  perKg: number;
  hitsLeucineThreshold: boolean;  // ≥0.4 g/kg
  hitsOptimal: boolean;            // 0.4-0.55 g/kg
}

export interface ProteinPerMealResult {
  evenSplit: MealProtein[];
  perKgEven: number;
  withinOptimalBand: boolean;
  recommendation: string;
  optimalMeals: number;        // suggested meal count for current total
  cappedSplit: MealProtein[] | null;  // if even split overshoots cap
}

// Bands from Schoenfeld & Aragon 2018.
const LEUCINE_THRESHOLD_G_PER_KG = 0.4;
const OPTIMAL_CAP_G_PER_KG = 0.55;

export function calculateProteinPerMeal(inputs: ProteinPerMealInputs): ProteinPerMealResult {
  const { totalProteinG, meals, bodyweightKg } = inputs;
  const perMealEven = totalProteinG / meals;
  const perKgEven = round(perMealEven / bodyweightKg, 3);
  const capG = OPTIMAL_CAP_G_PER_KG * bodyweightKg;

  const evenSplit: MealProtein[] = Array.from({ length: meals }, (_, i) => ({
    mealNum: i + 1,
    proteinG: round(perMealEven, 1),
    perKg: perKgEven,
    hitsLeucineThreshold: perKgEven >= LEUCINE_THRESHOLD_G_PER_KG,
    hitsOptimal: perKgEven >= LEUCINE_THRESHOLD_G_PER_KG && perKgEven <= OPTIMAL_CAP_G_PER_KG,
  }));

  const withinOptimalBand = perKgEven >= LEUCINE_THRESHOLD_G_PER_KG && perKgEven <= OPTIMAL_CAP_G_PER_KG;

  // Suggest meal count that lands per-meal protein in the optimal band.
  // Pick the meal count that brings per-meal protein closest to 0.475 g/kg
  // (midpoint of the band).
  const midpoint = (LEUCINE_THRESHOLD_G_PER_KG + OPTIMAL_CAP_G_PER_KG) / 2;
  const idealMeals = Math.max(2, Math.min(6, Math.round(totalProteinG / (midpoint * bodyweightKg))));

  // Capped split: if even split overshoots the cap, distribute by clamping
  // each meal at capG and rolling the remainder into extra meals.
  let cappedSplit: MealProtein[] | null = null;
  if (perMealEven > capG) {
    const mealsNeeded = Math.ceil(totalProteinG / capG);
    const perMealCapped = totalProteinG / mealsNeeded;
    cappedSplit = Array.from({ length: mealsNeeded }, (_, i) => {
      const pk = round(perMealCapped / bodyweightKg, 3);
      return {
        mealNum: i + 1,
        proteinG: round(perMealCapped, 1),
        perKg: pk,
        hitsLeucineThreshold: pk >= LEUCINE_THRESHOLD_G_PER_KG,
        hitsOptimal: pk >= LEUCINE_THRESHOLD_G_PER_KG && pk <= OPTIMAL_CAP_G_PER_KG,
      };
    });
  }

  let recommendation: string;
  if (withinOptimalBand) {
    recommendation = `Your split of ${meals} meals at ${round(perMealEven, 0)} g each (${perKgEven} g/kg) sits in the optimal MPS-stimulating range. Hold this.`;
  } else if (perKgEven < LEUCINE_THRESHOLD_G_PER_KG) {
    recommendation = `Per-meal protein is below the leucine threshold (0.4 g/kg). Drop to ${idealMeals} meals, or raise total daily protein. Otherwise some meals won't fully trigger MPS.`;
  } else {
    recommendation = `Per-meal protein exceeds 0.55 g/kg. Above this point the extra protein still counts for daily totals but adds little to that meal's MPS response. Spread it across ${idealMeals} meals for better stimulation across the day.`;
  }

  return {
    evenSplit,
    perKgEven,
    withinOptimalBand,
    recommendation,
    optimalMeals: idealMeals,
    cappedSplit,
  };
}

export const PROTEIN_BANDS = {
  leucineThresholdPerKg: LEUCINE_THRESHOLD_G_PER_KG,
  optimalCapPerKg: OPTIMAL_CAP_G_PER_KG,
};
