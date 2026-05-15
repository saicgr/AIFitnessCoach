// /tools/mesocycle-volume-calculator
//
// Builds a 4-6 week volume ramp for a chosen muscle, ending in a deload week.

import { useEffect, useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import {
  buildMesocycle,
  defaultsForMuscle,
  MUSCLE_OPTIONS,
} from '../../lib/calc/mesocycleVolume';

export default function MesocycleVolumeCalculator() {
  const [muscle, setMuscle] = useState<string>('Chest');
  const [startSets, setStartSets] = useState<number | ''>(10);
  const [peakSets, setPeakSets] = useState<number | ''>(20);
  const [weeks, setWeeks] = useState<4 | 5 | 6>(5);
  const [mv, setMv] = useState<number | ''>(6);

  // When the user picks a different muscle, prefill start, peak, and MV from
  // the landmarks. The user can still override.
  useEffect(() => {
    const d = defaultsForMuscle(muscle);
    if (d) {
      setStartSets(d.startSets);
      setPeakSets(d.peakSets);
      setMv(d.mv);
    }
  }, [muscle]);

  const plan = useMemo(() => {
    if (typeof startSets !== 'number' || typeof peakSets !== 'number' || typeof mv !== 'number') {
      return [];
    }
    return buildMesocycle({ muscle, startSets, peakSets, weeks, mv });
  }, [muscle, startSets, peakSets, weeks, mv]);

  return (
    <CalculatorShell
      slug="mesocycle-volume-calculator"
      title="Mesocycle Volume Calculator"
      metaDescription="Build a 4-6 week volume ramp for any muscle group, ending in a deload week. Based on the Renaissance Periodization hypertrophy algorithm."
      intro="Pick a muscle, a starting set count near MEV, and a peak near MAV. We will lay out the week-by-week ramp and the closing deload."
      faqs={[
        {
          q: 'What is MEV vs MAV vs MRV?',
          a: 'MEV is Minimum Effective Volume, the least amount of weekly work that still drives growth. MAV is Maximum Adaptive Volume, the productive sweet spot. MRV is Maximum Recoverable Volume, the ceiling before fatigue outpaces recovery. Mesocycles start at MEV and ramp toward MAV or just under MRV.',
        },
        {
          q: 'How long should a mesocycle be?',
          a: 'Four to six weeks for most lifters. Beginners can run shorter cycles because they recover faster. Advanced lifters often need the full six weeks to accumulate enough fatigue to make a deload worthwhile. Track your RPE and sleep across the block to confirm.',
        },
        {
          q: 'What if I hit the peak set count and still feel fresh?',
          a: 'Run the same block again starting one set higher. If you sail through that too, your true MAV has shifted up. Most lifters discover their actual MAV by overshooting a few times.',
        },
        {
          q: 'Should the rep range really drop late in the cycle?',
          a: 'Yes, the rep target drifts higher as fatigue accumulates. Heavy doubles in week 1 feel different from heavy doubles in week 4. Raising reps lets you keep stimulus while compensating for the drop in bar speed and recovery.',
        },
        {
          q: 'Do I need a deload at the end?',
          a: 'If you accumulated real fatigue, yes. The deload week protects the gains. Skipping it usually shows up two cycles later as a plateau or a tweaked joint.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8 space-y-5">
        <div>
          <h2 className="text-lg font-bold text-white mb-4">Mesocycle parameters</h2>
          <label className="block">
            <span className="block text-sm font-medium text-zinc-300 mb-1.5">Muscle group</span>
            <select
              value={muscle}
              onChange={(e) => setMuscle(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-base focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
            >
              {MUSCLE_OPTIONS.map((m) => (
                <option key={m} value={m}>
                  {m}
                </option>
              ))}
            </select>
          </label>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <NumberInput
            label="Starting sets (week 1)"
            value={startSets}
            onChange={setStartSets}
            min={0}
            step={1}
            help="Start at MEV"
          />
          <NumberInput
            label="Peak sets"
            value={peakSets}
            onChange={setPeakSets}
            min={1}
            step={1}
            help="MAV high or MRV minus 2"
          />
          <NumberInput
            label="Deload sets (final week)"
            value={mv}
            onChange={setMv}
            min={0}
            step={1}
            help="MV floor"
          />
        </div>

        <div>
          <span className="block text-sm font-medium text-zinc-300 mb-2">Cycle length</span>
          <div className="inline-flex rounded-lg border border-zinc-700 bg-zinc-950 p-0.5">
            {([4, 5, 6] as const).map((w) => {
              const active = weeks === w;
              return (
                <button
                  key={w}
                  type="button"
                  onClick={() => setWeeks(w)}
                  className={`px-4 py-2 text-sm font-medium rounded-md transition ${
                    active ? 'bg-emerald-500 text-zinc-900' : 'text-zinc-400 hover:text-white'
                  }`}
                >
                  {w} weeks
                </button>
              );
            })}
          </div>
        </div>
      </section>

      {plan.length > 0 && (
        <section>
          <h2 className="text-lg font-bold text-white mb-1">Your {muscle.toLowerCase()} mesocycle</h2>
          <p className="text-sm text-zinc-400 mb-4">
            Week-by-week set targets, rep ranges, and training intent.
          </p>
          <div className="overflow-x-auto rounded-2xl border border-zinc-800">
            <table className="w-full text-sm">
              <thead className="bg-zinc-900 border-b border-zinc-800">
                <tr>
                  <th className="text-left px-4 py-3 font-semibold text-zinc-300">Week</th>
                  <th className="text-right px-4 py-3 font-semibold text-zinc-300">Sets/wk</th>
                  <th className="text-right px-4 py-3 font-semibold text-zinc-300">Reps</th>
                  <th className="text-left px-4 py-3 font-semibold text-zinc-300 hidden md:table-cell">Intent</th>
                </tr>
              </thead>
              <tbody>
                {plan.map((w) => (
                  <tr
                    key={w.week}
                    className={`border-b border-zinc-800 last:border-b-0 ${
                      w.isDeload ? 'bg-emerald-950/30' : 'bg-zinc-950'
                    }`}
                  >
                    <td className="px-4 py-3">
                      <span className="font-medium text-white">Week {w.week}</span>
                      {w.isDeload && (
                        <span className="ml-2 text-[10px] px-1.5 py-0.5 rounded bg-emerald-500/20 text-emerald-400 font-semibold uppercase tracking-wide">
                          Deload
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-right font-mono font-semibold text-white">{w.sets}</td>
                    <td className="px-4 py-3 text-right font-mono text-zinc-300">{w.repRange}</td>
                    <td className="px-4 py-3 text-zinc-400 hidden md:table-cell">{w.intent}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}

      <InstallCta
        slug="mesocycle-volume-calculator"
        result={{ muscle, startSets, peakSets, weeks, mv }}
        primary="Let Zealova auto-generate your next 4-6 week mesocycle"
        secondary="Zealova picks exercises, sets your starting volume, ramps each week, and schedules the deload automatically across every muscle."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'Israetel M, Helms ER, Hoffmann J (2017). RP Hypertrophy Volume Algorithm. Renaissance Periodization.',
          },
          {
            text: 'Schoenfeld BJ, Ogborn D, Krieger JW (2017). Dose-response relationship between weekly resistance training volume and increases in muscle mass. J Sports Sci 35(11): 1073-1082.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/27433992/',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
