// /tools/dots-calculator
//
// DOTS (2020) score from squat / bench / deadlift total and bodyweight.
// Math from lib/calc/powerlifting.ts.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import { dots, totalKg } from '../../lib/calc/powerlifting';
import { type WeightUnit, type Sex, toWeight, round } from '../../lib/calc/units';

export default function DotsCalculator() {
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
    return { total: tKg, score: dots(tKg, bwKg, sex) };
  }, [squat, bench, deadlift, bodyweight, sex, unit]);

  return (
    <CalculatorShell
      slug="dots-calculator"
      title="DOTS Calculator"
      metaDescription="Free DOTS score calculator using the 2020 coefficients. The modern replacement for Wilks, used by USAPL, IPL, and most US federations."
      intro="DOTS is the current default scoring formula in most US powerlifting federations. It corrects bias at the extremes of bodyweight that the original Wilks formula carried. Enter your total and bodyweight to see your DOTS score."
      faqs={[
        {
          q: "What's the difference between DOTS and Wilks?",
          a: 'DOTS uses a degree-4 polynomial in the denominator (Wilks uses degree 5). DOTS was fit on a more recent dataset and slightly favors lifters at the very light and very heavy ends of the bodyweight spectrum compared to Wilks. For mid-weight lifters the scores are usually within 5 to 10 points.',
        },
        {
          q: 'Which federations use DOTS?',
          a: 'USAPL, IPL, USPA (optional), and most national-level US federations have adopted DOTS as the default. The IPF uses its own IPF GL Points formula. Older meets still posted in Wilks.',
        },
        {
          q: 'What is a competitive DOTS score?',
          a: 'For natural lifters: 300 is a strong intermediate, 400 is advanced, 500 is competitive at regional level, and 600 plus is national class. Equipped scores skew 50 to 100 points higher.',
        },
        {
          q: 'Does DOTS work for individual lifts?',
          a: 'The formula is designed for full powerlifting total. You can apply it to a single lift but the percentile mapping is meaningless because the formula was fit against three-lift totals.',
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
          <p className="text-sm text-zinc-400 uppercase tracking-widest mb-2">DOTS score</p>
          <p className="text-6xl font-bold text-emerald-400 font-mono mb-2">{round(score.score, 1)}</p>
          <p className="text-sm text-zinc-400">
            Total: {round(toWeight(score.total, 'kg', unit), 1)} {unit}
          </p>
        </section>
      )}

      <InstallCta
        slug="dots-calculator"
        result={score ? { dots: round(score.score, 2), totalKg: round(score.total, 1) } : undefined}
        primary="Track your meet PRs and projected DOTS"
        secondary="Zealova logs every working set, projects your meet total from training, and updates your DOTS after each session."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'Konertz T, Tschanz R (2020). DOTS scoring formula. OpenPowerlifting documentation.',
            url: 'https://www.openpowerlifting.org/',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
