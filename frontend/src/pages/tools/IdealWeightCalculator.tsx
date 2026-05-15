// /tools/ideal-weight-calculator
//
// Five formulas side-by-side, since the four classical IBW formulas can
// disagree by 5 to 10 kg at the same height. We surface all of them, plus a
// BMI healthy range, so the user sees the spread instead of a false-precision
// single number.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import ResultsTable, { type ResultRow } from '../../components/tools/ResultsTable';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import { calculateAllIdealWeight, type Sex } from '../../lib/calc/idealWeight';
import type { WeightUnit, HeightUnit } from '../../lib/calc/units';
import { ftInToCm, kgToLb, round } from '../../lib/calc/units';

export default function IdealWeightCalculator() {
  const [sex, setSex] = useState<Sex>('male');
  const [heightUnit, setHeightUnit] = useState<HeightUnit>('ft');
  const [weightUnit, setWeightUnit] = useState<WeightUnit>('lb');
  const [heightCm, setHeightCm] = useState<number | ''>(178);
  const [feet, setFeet] = useState<number | ''>(5);
  const [inches, setInches] = useState<number | ''>(10);

  const heightInCm = useMemo(() => {
    if (heightUnit === 'cm') return typeof heightCm === 'number' ? heightCm : 0;
    const f = typeof feet === 'number' ? feet : 0;
    const i = typeof inches === 'number' ? inches : 0;
    return ftInToCm(f, i);
  }, [heightUnit, heightCm, feet, inches]);

  const results = useMemo(
    () => (heightInCm > 0 ? calculateAllIdealWeight(heightInCm, sex) : []),
    [heightInCm, sex],
  );

  const formatKg = (kg: number) =>
    weightUnit === 'lb' ? `${round(kgToLb(kg), 0)} lb` : `${round(kg, 1)} kg`;

  const rows: ResultRow[] = results.map((r) => ({
    name: r.name,
    value: r.rangeKg
      ? `${formatKg(r.rangeKg.low)} to ${formatKg(r.rangeKg.high)}`
      : formatKg(r.valueKg),
    note: r.note,
    citation: r.citation,
    recommended: r.formula === 'bmi-range',
  }));

  // Spread across the four point estimates (for the summary card).
  const pointValues = results.filter((r) => r.valueKg > 0).map((r) => r.valueKg);
  const minPoint = pointValues.length ? Math.min(...pointValues) : 0;
  const maxPoint = pointValues.length ? Math.max(...pointValues) : 0;

  return (
    <CalculatorShell
      slug="ideal-weight-calculator"
      title="Ideal Weight Calculator"
      metaDescription="Calculate ideal body weight using all 5 major methods: Robinson, Miller, Devine, Hamwi, and BMI healthy range. See why the formulas disagree."
      intro="Enter your height and sex to see what every major ideal body weight formula predicts. The numbers will spread by several kilograms, which is the honest answer: there is no single ideal weight, only a reasonable range."
      faqs={[
        {
          q: 'Why do the formulas disagree so much?',
          a: 'Each formula was derived from a different study population, mostly mid-20th-century clinical patients, and was originally built to estimate drug dosing rather than fitness goals. Robinson and Miller are modern updates of Devine. Hamwi is a quick mental-math shortcut from 1964. They all take only height and sex, so any difference between formulas reflects the source data, not your actual body.',
        },
        {
          q: 'Which formula should I use?',
          a: 'For a goal weight, the BMI healthy range is the most physiologically grounded because it returns a range and accounts for the fact that two people of the same height can carry different amounts of muscle and bone. The four point formulas are most useful in clinical contexts like medication dosing.',
        },
        {
          q: 'I lift weights. These numbers look too low.',
          a: 'Correct. None of these formulas account for trained muscle mass. A lifter or athlete at a healthy body fat will often be 5 to 15 kg above the calculated ideal weight. Use body fat percent instead, and treat the BMI range as a soft ceiling not a target.',
        },
        {
          q: 'Does ideal weight change with age?',
          a: 'Yes. Older adults (65 and up) have lower mortality at slightly higher BMI, roughly BMI 23 to 28. Use the Healthy Weight Range calculator for an age-adjusted range.',
        },
      ]}
    >
      {/* Inputs */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <div className="flex justify-between items-center mb-6 flex-wrap gap-3">
          <h2 className="text-lg font-bold text-white">Your inputs</h2>
          <div className="flex gap-2 flex-wrap">
            <UnitToggle
              value={sex}
              options={[
                { value: 'male', label: 'Male' },
                { value: 'female', label: 'Female' },
              ]}
              onChange={setSex}
            />
            <UnitToggle
              value={heightUnit}
              options={[
                { value: 'ft', label: 'ft / in' },
                { value: 'cm', label: 'cm' },
              ]}
              onChange={setHeightUnit}
            />
            <UnitToggle
              value={weightUnit}
              options={[
                { value: 'lb', label: 'lb' },
                { value: 'kg', label: 'kg' },
              ]}
              onChange={setWeightUnit}
            />
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {heightUnit === 'cm' ? (
            <NumberInput
              label="Height"
              value={heightCm}
              onChange={setHeightCm}
              unit="cm"
              min={50}
              max={250}
              step={0.5}
              placeholder="178"
            />
          ) : (
            <div className="grid grid-cols-2 gap-3">
              <NumberInput
                label="Height (feet)"
                value={feet}
                onChange={setFeet}
                unit="ft"
                min={3}
                max={8}
                step={1}
                placeholder="5"
              />
              <NumberInput
                label="Inches"
                value={inches}
                onChange={setInches}
                unit="in"
                min={0}
                max={11}
                step={0.5}
                placeholder="10"
              />
            </div>
          )}
        </div>
      </section>

      {/* Spread summary */}
      {pointValues.length > 0 && (
        <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
          <p className="text-sm text-zinc-400 mb-1">Spread across the four classical formulas</p>
          <p className="text-3xl font-bold text-white">
            {formatKg(minPoint)} to {formatKg(maxPoint)}
          </p>
          <p className="text-sm text-zinc-400 mt-2 leading-relaxed">
            The classical formulas were built for drug-dosing tables, not fitness goals. The BMI healthy range
            below is generally a better reference for setting a target weight.
          </p>
        </section>
      )}

      {/* All methods */}
      {results.length > 0 && (
        <section>
          <h2 className="text-lg font-bold text-white mb-1">All methods</h2>
          <p className="text-sm text-zinc-400 mb-4">
            Five methods compared. BMI healthy range is highlighted as the recommended reference.
          </p>
          <ResultsTable rows={rows} valueLabel="Ideal weight" />
        </section>
      )}

      <InstallCta
        slug="ideal-weight-calculator"
        result={{ heightCm: heightInCm, sex, unit: weightUnit }}
        primary="Set a goal weight in Zealova and auto-adjust your daily calorie target"
        secondary="Pick any of these numbers as your goal. Zealova rebuilds your macros every week based on your actual weight trend."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'Robinson JD, Lupkiewicz SM, Palenik L et al. (1983). Determination of ideal body weight for drug dosage calculations. Am J Hosp Pharm 40(6).',
            url: 'https://pubmed.ncbi.nlm.nih.gov/6869387/',
          },
          {
            text: 'Miller DR, Carlson JD, Lloyd BJ et al. (1983). Determining ideal body weight. Am J Hosp Pharm 40(10).',
            url: 'https://pubmed.ncbi.nlm.nih.gov/6638239/',
          },
          {
            text: 'Devine BJ (1974). Gentamicin therapy. Drug Intell Clin Pharm 8.',
          },
          {
            text: 'Hamwi GJ (1964). Therapy: changing dietary concepts. In: Diabetes Mellitus. American Diabetes Association.',
          },
          {
            text: 'WHO (2000). Obesity: Preventing and Managing the Global Epidemic. WHO Technical Report Series 894.',
            url: 'https://www.who.int/publications/i/item/WHO-TRS-894',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
