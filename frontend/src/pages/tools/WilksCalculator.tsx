// /tools/wilks-calculator
//
// Wilks (2020) score from a squat / bench / deadlift total and bodyweight.
// Math from lib/calc/powerlifting.ts.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import { wilks, totalKg } from '../../lib/calc/powerlifting';
import { type WeightUnit, type Sex, toWeight, round } from '../../lib/calc/units';

export default function WilksCalculator() {
  const [squat, setSquat] = useState<number | ''>(180);
  const [bench, setBench] = useState<number | ''>(120);
  const [deadlift, setDeadlift] = useState<number | ''>(220);
  const [bodyweight, setBodyweight] = useState<number | ''>(82.5);
  const [sex, setSex] = useState<Sex>('male');
  const [unit, setUnit] = useState<WeightUnit>('kg');

  const score = useMemo(() => {
    if (
      typeof squat !== 'number' ||
      typeof bench !== 'number' ||
      typeof deadlift !== 'number' ||
      typeof bodyweight !== 'number'
    )
      return null;
    const sKg = toWeight(squat, unit, 'kg');
    const bKg = toWeight(bench, unit, 'kg');
    const dKg = toWeight(deadlift, unit, 'kg');
    const bwKg = toWeight(bodyweight, unit, 'kg');
    const tKg = totalKg({ squatKg: sKg, benchKg: bKg, deadliftKg: dKg });
    return { total: tKg, score: wilks(tKg, bwKg, sex) };
  }, [squat, bench, deadlift, bodyweight, sex, unit]);

  return (
    <CalculatorShell
      slug="wilks-calculator"
      title="Wilks Calculator (2020 update)"
      metaDescription="Free Wilks score calculator using the 2020 refit coefficients. Enter your squat, bench, and deadlift total plus bodyweight to see your Wilks points for men or women."
      intro="Wilks normalizes your powerlifting total against bodyweight so lifters of different sizes can be compared on a single score. This calculator uses the 2020 refit coefficients, which corrected mid-weight bias in the original formula."
      faqs={[
        {
          q: 'Why was Wilks updated in 2020?',
          a: 'The original 1994 Wilks coefficients overscored lifters in the middle bodyweight classes and underscored very light and very heavy lifters. Robert Wilks refit the formula on a larger, more recent dataset in 2020. The 2020 version is the one used in serious comparisons today.',
        },
        {
          q: 'Wilks vs DOTS, which should I use?',
          a: 'DOTS is the modern default for most federations and is generally considered slightly more accurate at the extremes of bodyweight. Wilks is still widely cited for historical comparisons and is required by some federations. Most lifters compute both.',
        },
        {
          q: 'Does Wilks work for raw and equipped lifters?',
          a: 'The coefficients are the same. Equipment like squat suits and bench shirts adds raw kilos to the total, which pushes the Wilks score up directly. Comparing raw and equipped Wilks scores is therefore not apples to apples, even though the formula does not distinguish.',
        },
        {
          q: 'What is a good Wilks score?',
          a: 'For natural lifters: 300 is a solid intermediate, 400 is advanced, 500 is competitive at a regional level, and 600 plus is national or world class. Equipped scores run roughly 50 to 100 points higher.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <div className="flex justify-between items-center mb-6 flex-wrap gap-3">
          <h2 className="text-lg font-bold text-white">Your meet</h2>
          <div className="flex gap-2">
            <UnitToggle
              value={sex}
              options={[
                { value: 'male', label: 'Male' },
                { value: 'female', label: 'Female' },
              ]}
              onChange={setSex}
            />
            <UnitToggle
              value={unit}
              options={[
                { value: 'kg', label: 'kg' },
                { value: 'lb', label: 'lb' },
              ]}
              onChange={setUnit}
            />
          </div>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <NumberInput label="Squat" value={squat} onChange={setSquat} unit={unit} min={0} step={2.5} />
          <NumberInput label="Bench" value={bench} onChange={setBench} unit={unit} min={0} step={2.5} />
          <NumberInput label="Deadlift" value={deadlift} onChange={setDeadlift} unit={unit} min={0} step={2.5} />
          <NumberInput
            label="Bodyweight"
            value={bodyweight}
            onChange={setBodyweight}
            unit={unit}
            min={20}
            step={0.5}
          />
        </div>
      </section>

      {score && score.score > 0 && (
        <section className="rounded-2xl border border-emerald-500/30 bg-gradient-to-br from-emerald-950/50 to-zinc-900 p-8 text-center">
          <p className="text-sm text-zinc-400 uppercase tracking-widest mb-2">Wilks 2020</p>
          <p className="text-6xl font-bold text-emerald-400 font-mono mb-2">{round(score.score, 1)}</p>
          <p className="text-sm text-zinc-400">
            Total: {round(toWeight(score.total, 'kg', unit), 1)} {unit}
          </p>
        </section>
      )}

      <InstallCta
        slug="wilks-calculator"
        result={score ? { wilks: round(score.score, 2), totalKg: round(score.total, 1) } : undefined}
        primary="Track your meet PRs and projected Wilks"
        secondary="Zealova logs every working set, projects your meet total from training, and updates your Wilks after each session."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'Wilks R (2020). Updated Wilks coefficients. Published via OpenPowerlifting.',
            url: 'https://openpowerlifting.gitlab.io/opl-csv/',
          },
          {
            text: 'Vanderburgh PM, Batterham AM (1999). Validation of the Wilks powerlifting formula. Med Sci Sports Exerc 31(12).',
            url: 'https://pubmed.ncbi.nlm.nih.gov/10613452/',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
