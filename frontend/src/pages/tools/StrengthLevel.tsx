// /tools/strength-level
//
// Estimates a lifter's percentile vs. the broader trained-lifter population
// based on their 1RM, bodyweight, sex, and lift. Math from
// lib/calc/strengthLevel.ts.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import {
  strengthPercentile,
  LIFT_LABELS,
  LEVEL_LABELS,
  LEVEL_DESCRIPTIONS,
  type Lift,
} from '../../lib/calc/strengthLevel';
import { type WeightUnit, type Sex, toWeight, round, kgToLb } from '../../lib/calc/units';

const LIFT_OPTIONS: { value: Lift; label: string }[] = [
  { value: 'squat', label: 'Squat' },
  { value: 'bench', label: 'Bench' },
  { value: 'deadlift', label: 'Deadlift' },
  { value: 'overhead-press', label: 'OHP' },
];

export default function StrengthLevel() {
  const [lift, setLift] = useState<Lift>('bench');
  const [oneRm, setOneRm] = useState<number | ''>(225);
  const [bodyweight, setBodyweight] = useState<number | ''>(180);
  const [sex, setSex] = useState<Sex>('male');
  const [unit, setUnit] = useState<WeightUnit>('lb');

  const result = useMemo(() => {
    if (typeof oneRm !== 'number' || typeof bodyweight !== 'number') return null;
    const rmKg = toWeight(oneRm, unit, 'kg');
    const bwKg = toWeight(bodyweight, unit, 'kg');
    return strengthPercentile(lift, rmKg, bwKg, sex);
  }, [lift, oneRm, bodyweight, sex, unit]);

  // Build a threshold table the user can read in their unit
  const thresholdRows = useMemo(() => {
    if (!result || typeof bodyweight !== 'number') return [];
    const bwKg = toWeight(bodyweight, unit, 'kg');
    const display = (ratio: number): string => {
      const kg = ratio * bwKg;
      const v = unit === 'lb' ? kgToLb(kg) : kg;
      return `${round(v, 0)} ${unit}`;
    };
    return [
      { level: 'beginner' as const, weight: display(result.thresholds.beginner) },
      { level: 'novice' as const, weight: display(result.thresholds.novice) },
      { level: 'intermediate' as const, weight: display(result.thresholds.intermediate) },
      { level: 'advanced' as const, weight: display(result.thresholds.advanced) },
      { level: 'elite' as const, weight: display(result.thresholds.elite) },
    ];
  }, [result, bodyweight, unit]);

  return (
    <CalculatorShell
      slug="strength-level"
      title="Strength Level Calculator"
      metaDescription="Free strength standards calculator. See your percentile and level (beginner, novice, intermediate, advanced, elite) for squat, bench, deadlift, and overhead press."
      intro="See where your one-rep max ranks against the broader trained-lifter population. Standards are bodyweight-adjusted and triangulated from publicly available lifter databases."
      faqs={[
        {
          q: 'How was the percentile data collected?',
          a: 'Standards are triangulated from publicly available lifter databases including StrengthLevel.com, Symmetric Strength, and ExRx.net, then bodyweight-adjusted with a multiplier curve. Underlying samples are self-reported, so treat percentiles as directional rather than clinical.',
        },
        {
          q: "What counts as 'intermediate'?",
          a: 'Roughly two plus years of consistent, structured training. Most committed gym regulars peak somewhere in the intermediate to early advanced range. Beginner is your first six months. Novice is six to twelve months. Advanced and elite require five plus years and serious programming.',
        },
        {
          q: 'Why does the standard change with bodyweight?',
          a: 'Strength scales sub-linearly with bodyweight. A 60 kg lifter benching 1.5x their bodyweight is impressive; a 120 kg lifter at the same ratio is more common. We apply a multiplier curve fit against published standards at 60, 75, 90, 110, and 140 kg.',
        },
        {
          q: 'Are these standards for raw or geared lifters?',
          a: 'Raw. Add roughly 10 to 15% for a squat suit or bench shirt at intermediate level, more at advanced and elite.',
        },
        {
          q: 'Which squat variation is the standard for?',
          a: 'High-bar back squat to roughly parallel. Low-bar typically nets 5 to 10% more weight at the same effort. Front squats run roughly 70 to 80% of back squat.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <div className="flex justify-between items-center mb-6 flex-wrap gap-3">
          <h2 className="text-lg font-bold text-white">Your lift</h2>
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
              value={unit}
              options={[
                { value: 'lb', label: 'lb' },
                { value: 'kg', label: 'kg' },
              ]}
              onChange={setUnit}
            />
          </div>
        </div>

        <div className="mb-4">
          <span className="block text-sm font-medium text-zinc-300 mb-1.5">Lift</span>
          <div className="inline-flex rounded-lg border border-zinc-700 bg-zinc-900 p-0.5 flex-wrap">
            {LIFT_OPTIONS.map((opt) => {
              const active = opt.value === lift;
              return (
                <button
                  key={opt.value}
                  type="button"
                  onClick={() => setLift(opt.value)}
                  className={`px-3 py-1.5 text-xs font-medium rounded-md transition ${
                    active ? 'bg-emerald-500 text-zinc-900' : 'text-zinc-400 hover:text-white'
                  }`}
                >
                  {opt.label}
                </button>
              );
            })}
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <NumberInput
            label={`${LIFT_LABELS[lift]} 1RM`}
            value={oneRm}
            onChange={setOneRm}
            unit={unit}
            min={0}
            step={2.5}
          />
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

      {result && (
        <section className="rounded-2xl border border-emerald-500/30 bg-gradient-to-br from-emerald-950/50 to-zinc-900 p-8 text-center">
          <p className="text-sm text-zinc-400 uppercase tracking-widest mb-2">Your level</p>
          <p className="text-5xl font-bold text-emerald-400 mb-2">{LEVEL_LABELS[result.level]}</p>
          <p className="text-2xl font-mono text-white mb-3">{result.percentile}th percentile</p>
          <p className="text-sm text-zinc-400 max-w-md mx-auto">{LEVEL_DESCRIPTIONS[result.level]}</p>
          <p className="text-xs text-zinc-500 mt-3">
            Ratio: {round(result.ratio, 2)}x bodyweight
          </p>
        </section>
      )}

      {thresholdRows.length > 0 && (
        <section>
          <h2 className="text-lg font-bold text-white mb-1">Thresholds at your bodyweight</h2>
          <p className="text-sm text-zinc-400 mb-4">
            What you would need to lift to hit each level at your current bodyweight.
          </p>
          <div className="overflow-x-auto rounded-2xl border border-zinc-800">
            <table className="w-full text-sm">
              <thead className="bg-zinc-900 border-b border-zinc-800">
                <tr>
                  <th className="text-left px-4 py-3 font-semibold text-zinc-300">Level</th>
                  <th className="text-right px-4 py-3 font-semibold text-zinc-300">Target 1RM</th>
                </tr>
              </thead>
              <tbody>
                {thresholdRows.map((row) => {
                  const isCurrent = result?.level === row.level;
                  return (
                    <tr
                      key={row.level}
                      className={`border-b border-zinc-800 last:border-b-0 ${
                        isCurrent ? 'bg-emerald-950/30' : 'bg-zinc-950'
                      }`}
                    >
                      <td className="px-4 py-2.5">
                        <div className="flex items-center gap-2">
                          <span className="font-medium text-white">{LEVEL_LABELS[row.level]}</span>
                          {isCurrent && (
                            <span className="text-[10px] px-1.5 py-0.5 rounded bg-emerald-500/20 text-emerald-400 font-semibold uppercase tracking-wide">
                              You
                            </span>
                          )}
                        </div>
                      </td>
                      <td className="px-4 py-2.5 text-right font-mono font-semibold text-white">
                        {row.weight}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </section>
      )}

      <InstallCta
        slug="strength-level"
        result={
          result
            ? { lift, level: result.level, percentile: result.percentile, ratio: round(result.ratio, 2) }
            : undefined
        }
        primary="See where every lift ranks against the database"
        secondary="Zealova ranks your squat, bench, deadlift, and OHP after every working set so you watch your level climb session to session."
      />

      <MethodologyFooter
        citations={[
          { text: 'Kilgore L (2007). Beginning Strength Standards. CrossFit Journal.' },
          { text: 'StrengthLevel.com strength standards database, accessed 2026-05.', url: 'https://strengthlevel.com/' },
          { text: 'Symmetric Strength percentile tables, accessed 2026-05.', url: 'https://symmetricstrength.com/' },
          { text: 'ExRx.net Powerlifting and Weightlifting Standards.', url: 'https://exrx.net/Testing/WeightLifting/StrengthStandards' },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
