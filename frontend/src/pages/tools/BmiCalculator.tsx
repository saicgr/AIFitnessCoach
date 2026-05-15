// /tools/bmi-calculator
//
// BMI is the simplest body-composition screening tool and the most commonly
// misused. We show the number and the category, but the page leads with the
// caveat for muscular and athletic users so they don't misread the result.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import { BMI_CATEGORIES, bmiCategory, calculateBmi, weightForBmi } from '../../lib/calc/bmi';
import type { WeightUnit, HeightUnit } from '../../lib/calc/units';
import { ftInToCm, kgToLb, lbToKg, round } from '../../lib/calc/units';

export default function BmiCalculator() {
  const [weight, setWeight] = useState<number | ''>(180);
  const [weightUnit, setWeightUnit] = useState<WeightUnit>('lb');
  const [heightUnit, setHeightUnit] = useState<HeightUnit>('ft');
  const [heightCm, setHeightCm] = useState<number | ''>(178);
  const [feet, setFeet] = useState<number | ''>(5);
  const [inches, setInches] = useState<number | ''>(10);

  const heightInCm = useMemo(() => {
    if (heightUnit === 'cm') return typeof heightCm === 'number' ? heightCm : 0;
    const f = typeof feet === 'number' ? feet : 0;
    const i = typeof inches === 'number' ? inches : 0;
    return ftInToCm(f, i);
  }, [heightUnit, heightCm, feet, inches]);

  const weightInKg = useMemo(() => {
    if (typeof weight !== 'number') return 0;
    return weightUnit === 'lb' ? lbToKg(weight) : weight;
  }, [weight, weightUnit]);

  const bmi = useMemo(() => calculateBmi(weightInKg, heightInCm), [weightInKg, heightInCm]);
  const category = bmi > 0 ? bmiCategory(bmi) : null;

  const targetLow = heightInCm > 0 ? weightForBmi(18.5, heightInCm) : 0;
  const targetHigh = heightInCm > 0 ? weightForBmi(24.9, heightInCm) : 0;
  const formatKg = (kg: number) =>
    weightUnit === 'lb' ? `${round(kgToLb(kg), 0)} lb` : `${round(kg, 1)} kg`;

  return (
    <CalculatorShell
      slug="bmi-calculator"
      title="BMI Calculator"
      metaDescription="Calculate your Body Mass Index with full category breakdown. Free BMI calculator with honest caveats for muscular and athletic users."
      intro="Enter your height and weight to see your BMI and where it lands on the WHO scale. BMI is a population screening tool, so the page also explains where it gets people wrong."
      faqs={[
        {
          q: 'Is BMI accurate for muscular people?',
          a: 'No. BMI uses only height and weight, so it cannot tell muscle from fat. Lifters, athletes, and most people with a regular strength-training habit will read as overweight or obese on BMI while having healthy or low body fat. For that group, use body fat percent or waist-to-height ratio instead.',
        },
        {
          q: 'What BMI is healthiest?',
          a: 'For adults under 65, the WHO normal range is BMI 18.5 to 24.9. For adults 65 and older, large meta-analyses find lowest all-cause mortality between BMI 23 and 28, so a slightly higher reading can be protective.',
        },
        {
          q: 'Should I use BMI or body fat percent?',
          a: 'Body fat percent is more informative because it separates lean mass from fat mass. BMI is fine as a quick screen, but body fat percent should drive any goal-setting. The Body Fat Calculator on this site gives a Navy method estimate with no equipment.',
        },
        {
          q: 'Does BMI apply to children or pregnant women?',
          a: 'No. Children use BMI-for-age percentile charts from the CDC. Pregnant women should not use adult BMI because weight gain is expected and tracked separately by a clinician.',
        },
      ]}
    >
      {/* Caveat banner */}
      <section className="rounded-2xl border border-amber-500/30 bg-amber-500/5 p-5">
        <p className="text-sm font-semibold text-amber-400 mb-1">Read this before you read your number</p>
        <p className="text-sm text-zinc-300 leading-relaxed">
          BMI cannot tell muscle from fat. If you lift weights regularly, BMI will likely overstate your risk.
          A 200 lb lifter at 12 percent body fat and a 200 lb sedentary adult at 30 percent body fat read the
          same on BMI. Use body fat percent or waist-to-height ratio if you want a body-composition number.
        </p>
      </section>

      {/* Inputs */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <div className="flex justify-between items-center mb-6 flex-wrap gap-3">
          <h2 className="text-lg font-bold text-white">Your measurements</h2>
          <div className="flex gap-2">
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
          <NumberInput
            label="Weight"
            value={weight}
            onChange={setWeight}
            unit={weightUnit}
            min={1}
            step={0.5}
            placeholder={weightUnit === 'lb' ? '180' : '82'}
          />
        </div>
      </section>

      {/* Results */}
      {bmi > 0 && category && (
        <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
          <p className="text-sm text-zinc-400 mb-1">Your BMI</p>
          <p className="text-5xl font-bold text-white tabular-nums">{bmi.toFixed(1)}</p>
          <p className={`mt-2 text-base font-semibold ${category.color}`}>{category.label}</p>
          <p className="text-sm text-zinc-400 mt-2 leading-relaxed">{category.note}</p>

          {targetLow > 0 && targetHigh > 0 && (
            <div className="mt-6 pt-6 border-t border-zinc-800">
              <p className="text-sm text-zinc-400">Healthy BMI range at your height</p>
              <p className="text-lg font-semibold text-white mt-1">
                {formatKg(targetLow)} to {formatKg(targetHigh)}
              </p>
              <p className="text-xs text-zinc-500 mt-1">Corresponds to BMI 18.5 to 24.9.</p>
            </div>
          )}
        </section>
      )}

      {/* All categories */}
      <section>
        <h2 className="text-lg font-bold text-white mb-1">BMI categories</h2>
        <p className="text-sm text-zinc-400 mb-4">
          WHO classification with the weight in your current unit at your height.
        </p>
        <div className="overflow-x-auto rounded-2xl border border-zinc-800">
          <table className="w-full text-sm">
            <thead className="bg-zinc-900 border-b border-zinc-800">
              <tr>
                <th className="text-left px-4 py-3 font-semibold text-zinc-300">Category</th>
                <th className="text-left px-4 py-3 font-semibold text-zinc-300">BMI range</th>
                <th className="text-right px-4 py-3 font-semibold text-zinc-300 hidden sm:table-cell">
                  Weight at your height
                </th>
              </tr>
            </thead>
            <tbody>
              {BMI_CATEGORIES.map((c, i) => {
                const isCurrent = category?.key === c.key;
                const lower = i === 0 ? 0 : [18.5, 25, 30, 35, 40][i - 1];
                const upper = [18.5, 25, 30, 35, 40, 100][i];
                const wLow = heightInCm > 0 ? weightForBmi(lower, heightInCm) : 0;
                const wHigh = heightInCm > 0 ? weightForBmi(upper, heightInCm) : 0;
                return (
                  <tr
                    key={c.key}
                    className={`border-b border-zinc-800 last:border-b-0 ${
                      isCurrent ? 'bg-emerald-950/30' : 'bg-zinc-950'
                    }`}
                  >
                    <td className="px-4 py-3">
                      <span className={`font-medium ${c.color}`}>{c.label}</span>
                      {isCurrent && (
                        <span className="ml-2 text-[10px] px-1.5 py-0.5 rounded bg-emerald-500/20 text-emerald-400 font-semibold uppercase tracking-wide">
                          You
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-zinc-300 font-mono">{c.range}</td>
                    <td className="px-4 py-3 text-right text-zinc-400 font-mono hidden sm:table-cell">
                      {heightInCm > 0
                        ? i === 5
                          ? `${formatKg(wLow)}+`
                          : `${formatKg(wLow)} to ${formatKg(wHigh)}`
                        : '–'}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </section>

      <InstallCta
        slug="bmi-calculator"
        result={{ bmi, weightKg: weightInKg, heightCm: heightInCm, category: category?.key }}
        primary="Track BMI alongside body fat for a complete picture"
        secondary="Zealova logs weight, body fat, waist, and BMI in one trend chart, so you see what is actually changing."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'WHO (2000). Obesity: Preventing and Managing the Global Epidemic. WHO Technical Report Series 894.',
            url: 'https://www.who.int/publications/i/item/WHO-TRS-894',
          },
          {
            text: 'NIH NHLBI (1998). Clinical Guidelines on the Identification, Evaluation, and Treatment of Overweight and Obesity in Adults.',
            url: 'https://www.nhlbi.nih.gov/health-topics/managing-overweight-obesity-in-adults',
          },
          {
            text: 'Winter JE, MacInnis RJ, Wattanapenpaiboon N, Nowson CA (2014). BMI and all-cause mortality in older adults. Am J Clin Nutr 99(4).',
            url: 'https://pubmed.ncbi.nlm.nih.gov/24452240/',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
