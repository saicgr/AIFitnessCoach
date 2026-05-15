// /tools/tapering-calculator
//
// Builds a 4-week peak-week taper for a powerlifter targeting a meet.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import {
  buildTaper,
  LIFT_LABELS,
  OPENER_PCT_OF_1RM,
  type Lift,
} from '../../lib/calc/tapering';
import type { WeightUnit } from '../../lib/calc/units';
import { round } from '../../lib/calc/units';

export default function TaperingCalculator() {
  const [lift, setLift] = useState<Lift>('squat');
  const [oneRm, setOneRm] = useState<number | ''>(405);
  const [unit, setUnit] = useState<WeightUnit>('lb');

  const plan = useMemo(() => {
    if (typeof oneRm !== 'number') return [];
    return buildTaper({ lift, trueOneRm: oneRm, unit });
  }, [lift, oneRm, unit]);

  const opener = typeof oneRm === 'number' ? round(oneRm * OPENER_PCT_OF_1RM, 0) : 0;

  return (
    <CalculatorShell
      slug="tapering-calculator"
      title="Tapering Calculator"
      metaDescription="Build a 4-week powerlifting peak-week taper for squat, bench, or deadlift. Volume, intensification, peak, deload, and opener attempts laid out automatically."
      intro="Enter your true 1RM and the lift. We will plot the standard 4-week taper around a 91 percent opener, with sets, reps, and load for every week."
      faqs={[
        {
          q: 'Is tapering only for competition?',
          a: 'No. Any time you want to express maximal strength on a date, a taper helps. Mock meets, video PR attempts, and end-of-block testing all benefit from the same 4-week structure. Outside of competition or testing, sustained heavy singles are usually counterproductive.',
        },
        {
          q: 'What is the optimal taper length?',
          a: 'Four weeks is the consensus default for full-power lifters. Pritchard et al. (2015) surveyed strength athletes and found 7-14 day tapers were typical for upper body and 14-28 day tapers for lower body. A two-week taper works for shorter blocks, but the 4-week version handles accumulated meet prep fatigue best.',
        },
        {
          q: 'Why open at 91 percent?',
          a: 'An opener is the conservative first attempt you are certain to make on a bad day. 90-92 percent of your true 1RM clears that bar for most lifters. Opening lighter leaves attempts on the table. Opening heavier risks a bomb-out and ends the day before you make a single lift.',
        },
        {
          q: 'Should deadlift taper differently?',
          a: 'Yes. Deadlifts recover slower than squats or bench. The calculator drops volume in week minus 4, pulls the heavy single forward in week minus 2, and runs a lighter week minus 1. Same calendar, lower CNS load.',
        },
        {
          q: 'How do I pick second and third attempts?',
          a: 'A common rule is opener plus 2-3% for the second, then second plus 1-3% for the third based on how the second moved. The taper sets up the opener. Attempt selection on meet day is a separate skill, but a clean taper means the opener barely moves you and the third becomes a true PR attempt.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8 space-y-5">
        <div className="flex justify-between items-center flex-wrap gap-3">
          <h2 className="text-lg font-bold text-white">Your meet lift</h2>
          <UnitToggle
            value={unit}
            options={[
              { value: 'lb', label: 'lb' },
              { value: 'kg', label: 'kg' },
            ]}
            onChange={setUnit}
          />
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          {(Object.keys(LIFT_LABELS) as Lift[]).map((l) => {
            const active = lift === l;
            return (
              <button
                key={l}
                type="button"
                onClick={() => setLift(l)}
                className={`rounded-xl border p-3 transition text-sm font-semibold ${
                  active
                    ? 'border-emerald-500 bg-emerald-500/10 text-emerald-400'
                    : 'border-zinc-800 bg-zinc-950 text-white hover:border-zinc-700'
                }`}
              >
                {LIFT_LABELS[l]}
              </button>
            );
          })}
        </div>

        <NumberInput
          label="True 1RM"
          value={oneRm}
          onChange={setOneRm}
          unit={unit}
          min={1}
          step={2.5}
          help={`Opener will be calculated at ${Math.round(OPENER_PCT_OF_1RM * 100)}% of this number`}
        />

        {opener > 0 && (
          <p className="text-sm text-zinc-400">
            Planned opener: <span className="font-bold text-emerald-400">{opener} {unit}</span>.
          </p>
        )}
      </section>

      {plan.length > 0 && (
        <section>
          <h2 className="text-lg font-bold text-white mb-1">{LIFT_LABELS[lift]} taper plan</h2>
          <p className="text-sm text-zinc-400 mb-4">
            Working weights are percentages of your opener, rounded to the nearest 2.5 {unit}.
          </p>
          <div className="overflow-x-auto rounded-2xl border border-zinc-800">
            <table className="w-full text-sm">
              <thead className="bg-zinc-900 border-b border-zinc-800">
                <tr>
                  <th className="text-left px-4 py-3 font-semibold text-zinc-300">Week</th>
                  <th className="text-right px-4 py-3 font-semibold text-zinc-300">Sets x Reps</th>
                  <th className="text-right px-4 py-3 font-semibold text-zinc-300">Load (% opener)</th>
                  <th className="text-right px-4 py-3 font-semibold text-zinc-300">Weight ({unit})</th>
                  <th className="text-left px-4 py-3 font-semibold text-zinc-300 hidden md:table-cell">Intent</th>
                </tr>
              </thead>
              <tbody>
                {plan.map((w) => {
                  const isMeet = w.daysOut === 0;
                  return (
                    <tr
                      key={w.label}
                      className={`border-b border-zinc-800 last:border-b-0 ${
                        isMeet ? 'bg-emerald-950/40' : 'bg-zinc-950'
                      }`}
                    >
                      <td className="px-4 py-3">
                        <span className="font-medium text-white">{w.label}</span>
                        {isMeet && (
                          <span className="ml-2 text-[10px] px-1.5 py-0.5 rounded bg-emerald-500/20 text-emerald-400 font-semibold uppercase tracking-wide">
                            Meet
                          </span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-right font-mono text-zinc-300">
                        {w.sets} x {w.reps}
                      </td>
                      <td className="px-4 py-3 text-right font-mono text-zinc-400">
                        {w.pctLow === w.pctHigh ? `${w.pctLow}%` : `${w.pctLow}-${w.pctHigh}%`}
                      </td>
                      <td className="px-4 py-3 text-right font-mono font-semibold text-white">
                        {w.workingWeightLow === w.workingWeightHigh
                          ? w.workingWeightLow
                          : `${w.workingWeightLow}-${w.workingWeightHigh}`}
                      </td>
                      <td className="px-4 py-3 text-zinc-400 hidden md:table-cell">{w.intent}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </section>
      )}

      <InstallCta
        slug="tapering-calculator"
        result={{ lift, oneRm, unit }}
        primary="Generate your full peak-week plan in Zealova"
        secondary="Zealova schedules all three lifts across the 4-week taper, syncs warmup ramps to your true 1RMs, and reminds you to deload at the right time."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'Helms ER, Morgan A, Valdez A (2018). The Muscle and Strength Pyramid: Training, 2nd ed.',
          },
          {
            text: 'Pritchard H et al. (2015). Tapering practices of strength and power athletes. J Strength Cond Res 29(8): 2228-2236.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/25734779/',
          },
          {
            text: 'Israetel M et al. Renaissance Periodization powerlifting peaking guidance.',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
