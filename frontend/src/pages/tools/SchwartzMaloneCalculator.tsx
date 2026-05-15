// /tools/schwartz-malone-calculator
//
// Schwartz-Malone classic powerlifting score. Polynomial approximation of
// the original published lookup tables. Math from lib/calc/powerlifting.ts.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import { schwartzMalone, totalKg } from '../../lib/calc/powerlifting';
import { type WeightUnit, type Sex, toWeight, round } from '../../lib/calc/units';

export default function SchwartzMaloneCalculator() {
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
    return { total: tKg, score: schwartzMalone(tKg, bwKg, sex) };
  }, [squat, bench, deadlift, bodyweight, sex, unit]);

  const formulaUsed = sex === 'male' ? 'Schwartz' : 'Malone';

  return (
    <CalculatorShell
      slug="schwartz-malone-calculator"
      title="Schwartz-Malone Calculator"
      metaDescription="Free Schwartz-Malone score calculator. Classic powerlifting formula from the 1980s. Schwartz coefficients for men, Malone for women."
      intro="Schwartz-Malone is the historical predecessor to Wilks. Lyle Schwartz published the men's coefficients and Pat Malone derived the women's equivalent. Still requested for legacy comparisons and older meet results."
      faqs={[
        {
          q: 'Is Schwartz-Malone still used?',
          a: 'Rarely in modern meets. Most federations moved to Wilks in the 1990s and to DOTS or IPF GL Points after 2020. The formula remains useful for comparing scores in historical meet records from the 1980s and early 1990s.',
        },
        {
          q: 'How does Schwartz-Malone differ from Wilks?',
          a: 'Schwartz-Malone produces a coefficient that is multiplied directly against the total. Wilks computes a multiplier that scales the total to a 500-point reference. The two scores live on completely different scales. A Schwartz score of 400 is roughly equivalent to a Wilks of 380 to 410 for most lifters.',
        },
        {
          q: 'Why does the men/women calculation differ in name?',
          a: 'Schwartz published the men\'s table; Malone published the women\'s table separately a few years later. Convention combines them under "Schwartz-Malone" since both are used together for mixed comparisons.',
        },
        {
          q: 'How accurate is the polynomial fit?',
          a: 'This calculator uses a polynomial approximation of the original lookup tables. Accuracy is approximately plus or minus 0.5 points versus the official tables across the bodyweight range from 50 to 140 kg. For meet-day purposes use a federation-approved table.',
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
          <p className="text-sm text-zinc-400 uppercase tracking-widest mb-2">{formulaUsed} score</p>
          <p className="text-6xl font-bold text-emerald-400 font-mono mb-2">{round(score.score, 2)}</p>
          <p className="text-sm text-zinc-400">
            Total: {round(toWeight(score.total, 'kg', unit), 1)} {unit}
          </p>
        </section>
      )}

      <InstallCta
        slug="schwartz-malone-calculator"
        result={score ? { schwartzMalone: round(score.score, 2), totalKg: round(score.total, 1) } : undefined}
        primary="Track your meet PRs and projected scores"
        secondary="Zealova logs every working set, projects your meet total from training, and updates your scoring formulas after each session."
      />

      <MethodologyFooter
        citations={[
          { text: 'Schwartz LD (1985). Powerlifting coefficient tables. Strength & Health Magazine.' },
          { text: 'Malone P (1987). Coefficient tables for female powerlifters.' },
          {
            text: 'Polynomial approximation derived from the original Schwartz and Malone tables. Approximate to within +/- 0.5 points across 50 to 140 kg bodyweight.',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
