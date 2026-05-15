// /tools/workout-volume-calculator
//
// Weekly set targets per muscle group, indexed by experience level. Uses the
// Renaissance Periodization MV/MEV/MAV/MRV landmarks plus the Schoenfeld 2017
// dose-response data.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import {
  calculateAllVolumes,
  type ExperienceLevel,
} from '../../lib/calc/workoutVolume';

const LEVELS: { value: ExperienceLevel; label: string; help: string }[] = [
  { value: 'beginner', label: 'Beginner', help: 'Under 1 year consistent training. Gains come fast on lower volume.' },
  { value: 'intermediate', label: 'Intermediate', help: '1-3 years consistent. Use these landmarks as the default.' },
  { value: 'advanced', label: 'Advanced', help: '3+ years. Volume tolerance and need both climb.' },
];

export default function WorkoutVolumeCalculator() {
  const [experience, setExperience] = useState<ExperienceLevel>('intermediate');
  const volumes = useMemo(() => calculateAllVolumes(experience), [experience]);
  const activeLevel = LEVELS.find((l) => l.value === experience);

  return (
    <CalculatorShell
      slug="workout-volume-calculator"
      title="Workout Volume Calculator"
      metaDescription="Find your weekly set targets per muscle group using the Renaissance Periodization MV/MEV/MAV/MRV landmarks. Free, evidence-based, no signup."
      intro="Pick your experience level. We will show the maintenance, minimum effective, sweet spot, and maximum recoverable weekly set counts for every major muscle group."
      faqs={[
        {
          q: 'Are these numbers for beginners?',
          a: 'They scale. The intermediate column matches the Renaissance Periodization landmarks for someone with 1-3 years of consistent training. Beginners need roughly 70% of that volume to grow. Advanced lifters tolerate around 10% more. The calculator applies the multiplier automatically.',
        },
        {
          q: 'Should I count warmup sets?',
          a: 'No. Only count hard working sets taken within 1-3 reps of failure. A pyramid up to a top set of 8 might be four total sets on the bar, but only the last one or two count toward weekly volume.',
        },
        {
          q: 'How fast can I increase volume?',
          a: 'Add one set per muscle per week is the standard guideline, capped at MRV. If you bump volume and recovery markers like sleep, motivation, and joint health all hold steady, the new volume is fine. If they tank, back off.',
        },
        {
          q: 'Why is glute MV zero?',
          a: 'Most lifters get incidental glute work from squats, lunges, and walking. Maintenance happens without dedicated sets. To grow glutes you still need MEV (4 direct sets) per week.',
        },
        {
          q: 'What if I train a muscle twice a week?',
          a: 'The weekly total is what matters. Split it however your schedule allows. Two sessions of 8 sets equals one session of 16 sets for hypertrophy purposes, with the split usually producing slightly better results.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <h2 className="text-lg font-bold text-white mb-4">Your training experience</h2>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          {LEVELS.map((l) => {
            const active = experience === l.value;
            return (
              <button
                key={l.value}
                type="button"
                onClick={() => setExperience(l.value)}
                className={`text-left rounded-xl border p-4 transition ${
                  active
                    ? 'border-emerald-500 bg-emerald-500/10'
                    : 'border-zinc-800 bg-zinc-950 hover:border-zinc-700'
                }`}
              >
                <p className={`text-sm font-semibold mb-1 ${active ? 'text-emerald-400' : 'text-white'}`}>
                  {l.label}
                </p>
                <p className="text-xs text-zinc-400 leading-relaxed">{l.help}</p>
              </button>
            );
          })}
        </div>
        {activeLevel && (
          <p className="text-xs text-zinc-500 mt-4">
            Numbers below are scaled for {activeLevel.label.toLowerCase()} lifters.
          </p>
        )}
      </section>

      <section>
        <h2 className="text-lg font-bold text-white mb-1">Weekly sets per muscle</h2>
        <p className="text-sm text-zinc-400 mb-4">
          MV holds, MEV grows, MAV is the sweet spot, MRV is the ceiling. Aim for MAV most of the time.
        </p>
        <div className="overflow-x-auto rounded-2xl border border-zinc-800">
          <table className="w-full text-sm">
            <thead className="bg-zinc-900 border-b border-zinc-800">
              <tr>
                <th className="text-left px-4 py-3 font-semibold text-zinc-300">Muscle</th>
                <th className="text-right px-4 py-3 font-semibold text-zinc-300">MV</th>
                <th className="text-right px-4 py-3 font-semibold text-zinc-300">MEV</th>
                <th className="text-right px-4 py-3 font-semibold text-emerald-400">MAV</th>
                <th className="text-right px-4 py-3 font-semibold text-zinc-300">MRV</th>
              </tr>
            </thead>
            <tbody>
              {volumes.map((v) => (
                <tr key={v.muscle} className="border-b border-zinc-800 last:border-b-0 bg-zinc-950">
                  <td className="px-4 py-3 text-white font-medium">{v.muscle}</td>
                  <td className="px-4 py-3 text-right font-mono text-zinc-400">{v.mv}</td>
                  <td className="px-4 py-3 text-right font-mono text-zinc-300">{v.mev}</td>
                  <td className="px-4 py-3 text-right font-mono font-semibold text-emerald-400">
                    {v.mavLow}-{v.mavHigh}
                  </td>
                  <td className="px-4 py-3 text-right font-mono text-zinc-300">{v.mrv}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-4 gap-3 mt-4 text-xs">
          <div className="rounded-lg border border-zinc-800 bg-zinc-900 p-3">
            <p className="font-semibold text-zinc-300 mb-1">MV</p>
            <p className="text-zinc-500 leading-relaxed">Maintenance. Hold what you have during cuts or busy weeks.</p>
          </div>
          <div className="rounded-lg border border-zinc-800 bg-zinc-900 p-3">
            <p className="font-semibold text-zinc-300 mb-1">MEV</p>
            <p className="text-zinc-500 leading-relaxed">Minimum to grow. Start every mesocycle here.</p>
          </div>
          <div className="rounded-lg border border-emerald-500/40 bg-emerald-500/5 p-3">
            <p className="font-semibold text-emerald-400 mb-1">MAV</p>
            <p className="text-zinc-400 leading-relaxed">Sweet spot. Spend most weeks here.</p>
          </div>
          <div className="rounded-lg border border-zinc-800 bg-zinc-900 p-3">
            <p className="font-semibold text-zinc-300 mb-1">MRV</p>
            <p className="text-zinc-500 leading-relaxed">Max recoverable. Touch briefly, then deload.</p>
          </div>
        </div>
      </section>

      <InstallCta
        slug="workout-volume-calculator"
        result={{ experience }}
        primary="Apply this volume to your next mesocycle in Zealova"
        secondary="Zealova reads your training history, places you within these landmarks, and builds the next block so your weekly sets land in the right zone."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'Schoenfeld BJ, Ogborn D, Krieger JW (2017). Dose-response relationship between weekly resistance training volume and increases in muscle mass. J Sports Sci 35(11): 1073-1082.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/27433992/',
          },
          {
            text: 'Israetel M, Hoffmann J, Smith CW (2017). Scientific Principles of Hypertrophy Training. Renaissance Periodization.',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
