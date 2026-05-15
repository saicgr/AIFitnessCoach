// /free-tools/caffeine-cutoff-calculator
//
// Models caffeine pharmacokinetics with a single-compartment exponential decay.
// Remaining(t) = dose * 0.5 ^ (t / halfLife). Default half-life 5h (range 3-7h).

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

interface Preset {
  label: string;
  mg: number;
}

const PRESETS: Preset[] = [
  { label: 'Espresso shot', mg: 63 },
  { label: 'Drip coffee', mg: 95 },
  { label: 'Cold brew', mg: 155 },
  { label: 'Pre-workout', mg: 200 },
  { label: 'Energy drink', mg: 160 },
  { label: 'Tea', mg: 50 },
];

const SAFE_THRESHOLD = 50;
const VERY_SAFE_THRESHOLD = 25;

function timeStringToMinutes(t: string): number {
  const [h, m] = t.split(':').map((x) => parseInt(x, 10));
  return h * 60 + m;
}

function minutesToTimeString(mins: number): string {
  const normalized = ((mins % 1440) + 1440) % 1440;
  const h = Math.floor(normalized / 60);
  const m = normalized % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
}

function hoursBetween(start: string, end: string): number {
  const s = timeStringToMinutes(start);
  const e = timeStringToMinutes(end);
  let diff = e - s;
  if (diff < 0) diff += 1440;
  return diff / 60;
}

function remaining(dose: number, hours: number, halfLife: number): number {
  return dose * Math.pow(0.5, hours / halfLife);
}

function hoursUntilThreshold(dose: number, threshold: number, halfLife: number): number {
  if (dose <= threshold) return 0;
  return Math.log(threshold / dose) / Math.log(0.5) * halfLife;
}

function format12h(t: string): string {
  const [h, m] = t.split(':').map((x) => parseInt(x, 10));
  const period = h >= 12 ? 'PM' : 'AM';
  const hr = h % 12 === 0 ? 12 : h % 12;
  return `${hr}:${String(m).padStart(2, '0')} ${period}`;
}

export default function CaffeineCutoffCalculator() {
  const [lastCoffee, setLastCoffee] = useState('14:00');
  const [bedtime, setBedtime] = useState('23:00');
  const [dose, setDose] = useState(95);
  const [halfLife, setHalfLife] = useState(5);

  const hoursToBed = useMemo(() => hoursBetween(lastCoffee, bedtime), [lastCoffee, bedtime]);
  const atBedtime = useMemo(
    () => remaining(dose, hoursToBed, halfLife),
    [dose, hoursToBed, halfLife],
  );
  const hoursToSafe = useMemo(
    () => hoursUntilThreshold(dose, SAFE_THRESHOLD, halfLife),
    [dose, halfLife],
  );
  const hoursToVerySafe = useMemo(
    () => hoursUntilThreshold(dose, VERY_SAFE_THRESHOLD, halfLife),
    [dose, halfLife],
  );

  const recommendedLastCoffee = useMemo(() => {
    const bedMin = timeStringToMinutes(bedtime);
    return minutesToTimeString(bedMin - Math.round(hoursToSafe * 60));
  }, [bedtime, hoursToSafe]);

  const recommendedVerySafe = useMemo(() => {
    const bedMin = timeStringToMinutes(bedtime);
    return minutesToTimeString(bedMin - Math.round(hoursToVerySafe * 60));
  }, [bedtime, hoursToVerySafe]);

  const willImpactSleep = atBedtime > SAFE_THRESHOLD;

  const decayCurve = useMemo(() => {
    const rows: { hour: number; mg: number }[] = [];
    for (let h = 0; h <= 12; h += 1) {
      rows.push({ hour: h, mg: remaining(dose, h, halfLife) });
    }
    return rows;
  }, [dose, halfLife]);

  return (
    <CalculatorShell
      slug="caffeine-cutoff-calculator"
      title="Caffeine Cutoff Calculator"
      metaDescription="Find out how much caffeine is still in your system at bedtime, and the latest you can drink coffee for clean sleep. Pharmacokinetic decay model with a 3-7 hour half-life slider."
      intro="Caffeine has a half-life around 5 hours. That afternoon coffee is still 25 percent in your system at midnight. Enter your dose and bedtime to see what is left when you try to sleep."
      faqs={[
        {
          q: 'How long does caffeine stay in your system?',
          a: 'Half-life averages 5 hours in healthy adults, with a normal range of 3 to 7 hours. That means after 5 hours, half the dose is still active. After 10 hours, 25 percent. Genetics, age, smoking status, pregnancy, and certain medications can push your personal half-life outside that range.',
        },
        {
          q: 'What is a safe amount of caffeine at bedtime?',
          a: 'Drake and colleagues found that 400 mg of caffeine taken 6 hours before bed still cut total sleep time by more than an hour. To minimize impact, aim for under 50 mg in your system at bedtime, and under 25 mg if you are caffeine-sensitive.',
        },
        {
          q: 'Why does my coffee not seem to keep me up?',
          a: 'You may still be experiencing reduced sleep depth even when you fall asleep fine. Studies show caffeine taken 6 hours before bed reduces objectively measured sleep efficiency without changing subjective sleep quality. You feel rested but your brain got less deep sleep.',
        },
        {
          q: 'Does this account for tolerance?',
          a: 'No. The half-life calculation is pharmacokinetic and does not change with tolerance. Tolerance affects how alert you feel from a given dose, not how long the molecule stays in your bloodstream. The mg-at-bedtime number is the same whether you drink coffee daily or never.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <h2 className="text-lg font-bold text-white mb-6">Your caffeine intake</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-6">
          <label className="block">
            <span className="block text-sm font-medium text-zinc-300 mb-1.5">Last coffee time</span>
            <input
              type="time"
              value={lastCoffee}
              onChange={(e) => setLastCoffee(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-base focus:outline-none focus:ring-2 focus:ring-emerald-500"
            />
          </label>
          <label className="block">
            <span className="block text-sm font-medium text-zinc-300 mb-1.5">Bedtime</span>
            <input
              type="time"
              value={bedtime}
              onChange={(e) => setBedtime(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-base focus:outline-none focus:ring-2 focus:ring-emerald-500"
            />
          </label>
        </div>

        <div className="mb-5">
          <span className="block text-sm font-medium text-zinc-300 mb-2">Caffeine dose</span>
          <div className="flex flex-wrap gap-2 mb-3">
            {PRESETS.map((p) => (
              <button
                key={p.label}
                onClick={() => setDose(p.mg)}
                className={`px-3 py-1.5 rounded-lg text-xs font-medium border transition ${
                  dose === p.mg
                    ? 'bg-emerald-500 text-zinc-900 border-emerald-500'
                    : 'bg-zinc-950 border-zinc-700 text-zinc-300 hover:border-zinc-500'
                }`}
              >
                {p.label} ({p.mg} mg)
              </button>
            ))}
          </div>
          <div className="relative">
            <input
              type="number"
              value={dose}
              onChange={(e) => setDose(parseFloat(e.target.value) || 0)}
              min={0}
              step={5}
              className="w-full px-4 py-3 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-base focus:outline-none focus:ring-2 focus:ring-emerald-500"
            />
            <span className="absolute right-4 top-1/2 -translate-y-1/2 text-sm text-zinc-500 font-medium pointer-events-none">
              mg
            </span>
          </div>
        </div>

        <label className="block">
          <span className="flex items-center justify-between text-sm font-medium text-zinc-300 mb-2">
            <span>Half-life</span>
            <span className="font-mono text-emerald-400">{halfLife.toFixed(1)} h</span>
          </span>
          <input
            type="range"
            min={3}
            max={7}
            step={0.5}
            value={halfLife}
            onChange={(e) => setHalfLife(parseFloat(e.target.value))}
            className="w-full accent-emerald-500"
          />
          <div className="flex justify-between text-xs text-zinc-500 mt-1">
            <span>3 h (fast metabolizer)</span>
            <span>5 h (average)</span>
            <span>7 h (slow)</span>
          </div>
        </label>
      </section>

      <section>
        <h2 className="text-lg font-bold text-white mb-4">At bedtime</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div
            className={`rounded-2xl border p-6 ${
              willImpactSleep
                ? 'border-amber-500/40 bg-amber-950/30'
                : 'border-emerald-500/30 bg-emerald-950/20'
            }`}
          >
            <p className="text-xs uppercase tracking-wide text-zinc-400 mb-2">Caffeine still active</p>
            <p className="text-4xl font-bold text-white">
              {atBedtime.toFixed(0)} <span className="text-lg text-zinc-400">mg</span>
            </p>
            <p className="text-sm text-zinc-400 mt-2">
              {willImpactSleep
                ? 'Likely to reduce sleep quality. Aim for under 50 mg.'
                : 'Below the 50 mg threshold. Sleep impact should be minor.'}
            </p>
          </div>
          <div className="rounded-2xl border border-zinc-800 bg-zinc-900 p-6">
            <p className="text-xs uppercase tracking-wide text-zinc-400 mb-2">Hours to clear</p>
            <p className="text-base text-zinc-300 mb-1">
              Under 50 mg in <span className="font-mono font-semibold text-white">{hoursToSafe.toFixed(1)} h</span>
            </p>
            <p className="text-base text-zinc-300">
              Under 25 mg in <span className="font-mono font-semibold text-white">{hoursToVerySafe.toFixed(1)} h</span>
            </p>
          </div>
        </div>
      </section>

      <section>
        <h2 className="text-lg font-bold text-white mb-4">Recommended cutoff times</h2>
        <div className="rounded-2xl border border-zinc-800 bg-zinc-900 p-6 space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-sm text-zinc-300">For minor sleep impact (under 50 mg)</span>
            <span className="font-mono font-semibold text-white">{format12h(recommendedLastCoffee)}</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-sm text-zinc-300">For near-zero impact (under 25 mg)</span>
            <span className="font-mono font-semibold text-emerald-400">{format12h(recommendedVerySafe)}</span>
          </div>
          <p className="text-xs text-zinc-500 pt-2 border-t border-zinc-800">
            Based on a {dose} mg dose and a {halfLife} hour half-life, working backwards from your {format12h(bedtime)} bedtime.
          </p>
        </div>
      </section>

      <section>
        <h2 className="text-lg font-bold text-white mb-1">Decay curve</h2>
        <p className="text-sm text-zinc-400 mb-4">Caffeine remaining after your last dose.</p>
        <div className="overflow-x-auto rounded-2xl border border-zinc-800">
          <table className="w-full text-sm">
            <thead className="bg-zinc-900 border-b border-zinc-800">
              <tr>
                <th className="text-left px-4 py-3 font-semibold text-zinc-300">Hours after dose</th>
                <th className="text-right px-4 py-3 font-semibold text-zinc-300">Caffeine remaining</th>
                <th className="text-right px-4 py-3 font-semibold text-zinc-300">% of dose</th>
              </tr>
            </thead>
            <tbody>
              {decayCurve.map((row) => (
                <tr key={row.hour} className="border-b border-zinc-800 last:border-b-0 bg-zinc-950">
                  <td className="px-4 py-2.5 text-white">+{row.hour} h</td>
                  <td className="px-4 py-2.5 text-right font-mono text-zinc-300">{row.mg.toFixed(1)} mg</td>
                  <td className="px-4 py-2.5 text-right font-mono text-zinc-500">
                    {((row.mg / dose) * 100).toFixed(0)}%
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <InstallCta
        slug="caffeine-cutoff-calculator"
        result={{ dose, lastCoffee, bedtime, atBedtime, halfLife }}
        primary="Get personalized caffeine reminders based on your sleep schedule in Zealova"
        secondary="Zealova learns your bedtime, tracks every coffee, and pings you when you are approaching your daily cutoff."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'Drake CL, Roehrs T, Shambroom J, Roth T (2013). Caffeine effects on sleep taken 0, 3, or 6 hours before going to bed. Journal of Clinical Sleep Medicine 9(11):1195-1200.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/24235903/',
          },
          {
            text: "O'Callaghan F, Muurlink O, Reid N (2018). Effects of caffeine on sleep quality and daytime functioning. Risk Management and Healthcare Policy 11:263-271.",
            url: 'https://pubmed.ncbi.nlm.nih.gov/30573997/',
          },
          {
            text: 'Institute of Medicine (2001). Caffeine for the Sustainment of Mental Task Performance. National Academies Press. Reference half-life range 3-7 hours.',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
