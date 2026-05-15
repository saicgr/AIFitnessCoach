// /tools/ipf-gl-calculator
//
// IPF GL Points (2020 classic / raw) from squat / bench / deadlift total
// and bodyweight. Math from lib/calc/powerlifting.ts.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import { ipfGl, totalKg } from '../../lib/calc/powerlifting';
import { type WeightUnit, type Sex, toWeight, round } from '../../lib/calc/units';

export default function IpfGlCalculator() {
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
    return { total: tKg, score: ipfGl(tKg, bwKg, sex) };
  }, [squat, bench, deadlift, bodyweight, sex, unit]);

  return (
    <CalculatorShell
      slug="ipf-gl-calculator"
      title="IPF GL Points Calculator"
      metaDescription="Free IPF GL Points calculator using the official 2020 classic (raw) coefficients. Used by all IPF and IPF-affiliated federations since January 2020."
      intro="IPF GL Points is the official IPF scoring formula since January 2020. It replaced IPF Wilks (a separate refit of Wilks for IPF). This calculator uses the classic raw coefficients. Equipped lifters need a separate set."
      faqs={[
        {
          q: 'What replaced IPF Wilks?',
          a: 'IPF GL Points, adopted January 1, 2020. The IPF found the original Wilks and even their own refit overrewarded mid-weight lifters. GL Points uses an exponential decay against bodyweight instead of a polynomial, which behaves better at the extremes.',
        },
        {
          q: 'When was IPF GL adopted?',
          a: 'January 2020. All IPF-affiliated federations (USAPL was IPF-affiliated until 2021, IPL, BPU, GBPF, and many national federations) switched at that point. Some still publish Wilks for legacy comparisons.',
        },
        {
          q: 'IPF GL vs DOTS, which is higher?',
          a: 'They are calibrated to different scales. IPF GL tops out around 100 for elite lifters. DOTS tops out closer to 700. There is no clean conversion factor between them.',
        },
        {
          q: 'Does this calculator support equipped lifters?',
          a: 'The classic (raw) coefficients only. Equipped lifters need a different coefficient set that the IPF publishes separately. Add a note in the methodology if you compete equipped.',
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
          <p className="text-sm text-zinc-400 uppercase tracking-widest mb-2">IPF GL Points</p>
          <p className="text-6xl font-bold text-emerald-400 font-mono mb-2">{round(score.score, 2)}</p>
          <p className="text-sm text-zinc-400">
            Total: {round(toWeight(score.total, 'kg', unit), 1)} {unit}
          </p>
        </section>
      )}

      <InstallCta
        slug="ipf-gl-calculator"
        result={score ? { ipfGl: round(score.score, 2), totalKg: round(score.total, 1) } : undefined}
        primary="Track your meet PRs and projected IPF GL"
        secondary="Zealova logs every working set, projects your meet total from training, and updates your IPF GL after each session."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'International Powerlifting Federation (2020). IPF GL Points scoring system.',
            url: 'https://www.powerlifting.sport/rules/codes/info/ipf-formula',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
