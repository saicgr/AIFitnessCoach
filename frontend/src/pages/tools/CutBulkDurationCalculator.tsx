// /tools/cut-bulk-duration-calculator
//
// Estimates the timeline for a cut (current bf -> target bf) or a lean bulk
// (current weight -> goal gain) and surfaces calorie targets and warnings.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import { estimateBulk, estimateCut, type Mode } from '../../lib/calc/cutBulkDuration';
import type { WeightUnit } from '../../lib/calc/units';

export default function CutBulkDurationCalculator() {
  const [mode, setMode] = useState<Mode>('cut');
  const [unit, setUnit] = useState<WeightUnit>('lb');

  // Cut state
  const [currentWeight, setCurrentWeight] = useState<number | ''>(190);
  const [currentBf, setCurrentBf] = useState<number | ''>(22);
  const [targetBf, setTargetBf] = useState<number | ''>(15);
  const [weeklyLossPct, setWeeklyLossPct] = useState<number | ''>(0.75);

  // Bulk state
  const [bulkWeight, setBulkWeight] = useState<number | ''>(170);
  const [goalGain, setGoalGain] = useState<number | ''>(10);
  const [weeklyGainPct, setWeeklyGainPct] = useState<number | ''>(0.35);

  const result = useMemo(() => {
    if (mode === 'cut') {
      if (
        typeof currentWeight !== 'number' ||
        typeof currentBf !== 'number' ||
        typeof targetBf !== 'number' ||
        typeof weeklyLossPct !== 'number'
      ) {
        return null;
      }
      return estimateCut({
        currentWeight,
        unit,
        currentBodyFatPct: currentBf,
        targetBodyFatPct: targetBf,
        weeklyLossPct,
      });
    }
    if (
      typeof bulkWeight !== 'number' ||
      typeof goalGain !== 'number' ||
      typeof weeklyGainPct !== 'number'
    ) {
      return null;
    }
    return estimateBulk({
      currentWeight: bulkWeight,
      unit,
      goalGain,
      weeklyGainPct,
    });
  }, [mode, currentWeight, currentBf, targetBf, weeklyLossPct, bulkWeight, goalGain, weeklyGainPct, unit]);

  return (
    <CalculatorShell
      slug="cut-bulk-duration-calculator"
      title="Cut & Bulk Duration Calculator"
      metaDescription="Estimate how many weeks your cut or lean bulk will take. Uses the Helms 0.5-1% weekly loss rate and the Aragon-Schoenfeld lean bulk guidance."
      intro="Choose cut or bulk. We will estimate the weeks required, the daily calorie target, and flag rates that historically cost muscle or pack on fat."
      faqs={[
        {
          q: 'How fast can I lose fat without losing muscle?',
          a: 'Roughly 0.5 to 1.0 percent of bodyweight per week (Helms et al. 2014). The Garthe study showed athletes losing weight at 0.7% per week kept lean mass, while those losing at 1.4% per week lost meaningful strength and muscle. Below 0.4% is unnecessarily slow for most people.',
        },
        {
          q: 'How slow should I bulk?',
          a: 'Intermediate lifters should aim for 0.25 to 0.5 percent of bodyweight per week. The Aragon-Schoenfeld guidance is on the lower end of that range. Faster than 0.5% usually means more fat per pound gained, which extends the cut needed afterward.',
        },
        {
          q: 'Why does the body fat math look so harsh?',
          a: 'When you cut, fat-free mass stays roughly constant. So losing 7 percentage points of body fat means losing the absolute pounds of fat, which is bigger than you might expect. The formula assumes ideal muscle retention. Real cuts run a touch longer because adherence dips.',
        },
        {
          q: 'Should I take diet breaks?',
          a: 'Yes, especially on long cuts. A 1-2 week refeed at maintenance every 8-12 weeks helps restore leptin, training quality, and adherence. The Matador study (Byrne 2018) showed intermittent dieters lost more fat than continuous dieters across the same total deficit.',
        },
        {
          q: 'My cut shows 30+ weeks. Now what?',
          a: 'Either set a more modest body fat target, raise the weekly loss rate toward 1%, or split the cut into two phases with a maintenance break in the middle. Trying to grind through six consecutive months of deficit almost always breaks before the target.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8 space-y-5">
        <div className="flex justify-between items-center flex-wrap gap-3">
          <div className="inline-flex rounded-lg border border-zinc-700 bg-zinc-950 p-0.5">
            {(['cut', 'bulk'] as const).map((m) => {
              const active = mode === m;
              return (
                <button
                  key={m}
                  type="button"
                  onClick={() => setMode(m)}
                  className={`px-5 py-2 text-sm font-medium rounded-md transition capitalize ${
                    active ? 'bg-emerald-500 text-zinc-900' : 'text-zinc-400 hover:text-white'
                  }`}
                >
                  {m}
                </button>
              );
            })}
          </div>
          <UnitToggle
            value={unit}
            options={[
              { value: 'lb', label: 'lb' },
              { value: 'kg', label: 'kg' },
            ]}
            onChange={setUnit}
          />
        </div>

        {mode === 'cut' ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <NumberInput
              label="Current weight"
              value={currentWeight}
              onChange={setCurrentWeight}
              unit={unit}
              min={50}
              step={1}
            />
            <NumberInput
              label="Weekly loss target"
              value={weeklyLossPct}
              onChange={setWeeklyLossPct}
              unit="% bw"
              min={0.1}
              max={2}
              step={0.05}
              help="0.5-1.0% retains the most muscle"
            />
            <NumberInput
              label="Current body fat"
              value={currentBf}
              onChange={setCurrentBf}
              unit="%"
              min={5}
              max={60}
              step={0.5}
            />
            <NumberInput
              label="Target body fat"
              value={targetBf}
              onChange={setTargetBf}
              unit="%"
              min={5}
              max={50}
              step={0.5}
            />
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <NumberInput
              label="Current weight"
              value={bulkWeight}
              onChange={setBulkWeight}
              unit={unit}
              min={50}
              step={1}
            />
            <NumberInput
              label="Weekly gain target"
              value={weeklyGainPct}
              onChange={setWeeklyGainPct}
              unit="% bw"
              min={0.05}
              max={1.5}
              step={0.05}
              help="0.25-0.5% stays lean"
            />
            <NumberInput
              label="Goal weight gain"
              value={goalGain}
              onChange={setGoalGain}
              unit={unit}
              min={1}
              step={1}
            />
          </div>
        )}
      </section>

      {result && (
        <section className="space-y-4">
          <div className="rounded-2xl border border-emerald-500/30 bg-emerald-500/5 p-6">
            <p className="text-xs uppercase tracking-wide text-emerald-400 mb-2">Estimated duration</p>
            <p className="text-4xl font-bold text-white">
              {result.weeks} <span className="text-2xl text-zinc-400">weeks</span>
            </p>
            <p className="text-sm text-zinc-400 mt-1">
              Roughly {Math.round(result.weeks / 4.345)} months at {result.weeklyChange} {unit}/week.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div className="rounded-xl border border-zinc-800 bg-zinc-950 p-4">
              <p className="text-xs uppercase tracking-wide text-zinc-500 mb-1">Total weight change</p>
              <p className="text-xl font-bold text-white">{result.weightChange} {unit}</p>
            </div>
            <div className="rounded-xl border border-zinc-800 bg-zinc-950 p-4">
              <p className="text-xs uppercase tracking-wide text-zinc-500 mb-1">Daily {mode === 'cut' ? 'deficit' : 'surplus'}</p>
              <p className="text-xl font-bold text-white">{result.dailyCalorieImpact} kcal</p>
            </div>
            <div className="rounded-xl border border-zinc-800 bg-zinc-950 p-4">
              <p className="text-xs uppercase tracking-wide text-zinc-500 mb-1">Total {mode === 'cut' ? 'deficit' : 'surplus'}</p>
              <p className="text-xl font-bold text-white">{result.totalCalorieImpact.toLocaleString()} kcal</p>
            </div>
          </div>

          {result.warnings.length > 0 && (
            <div className="rounded-2xl border border-amber-500/30 bg-amber-500/5 p-5">
              <p className="text-sm font-semibold text-amber-400 mb-2">Worth flagging</p>
              <ul className="space-y-1.5 text-sm text-zinc-300">
                {result.warnings.map((w, i) => (
                  <li key={i} className="leading-relaxed">
                    <span className="text-amber-400 mr-2">•</span>
                    {w}
                  </li>
                ))}
              </ul>
            </div>
          )}

          {result.notes.length > 0 && (
            <div className="rounded-2xl border border-zinc-800 bg-zinc-900 p-5">
              <p className="text-sm font-semibold text-zinc-300 mb-2">Notes</p>
              <ul className="space-y-1.5 text-sm text-zinc-400">
                {result.notes.map((n, i) => (
                  <li key={i} className="leading-relaxed">
                    <span className="text-emerald-500 mr-2">•</span>
                    {n}
                  </li>
                ))}
              </ul>
            </div>
          )}
        </section>
      )}

      <InstallCta
        slug="cut-bulk-duration-calculator"
        result={{ mode, weeks: result?.weeks, dailyCalorieImpact: result?.dailyCalorieImpact }}
        primary="Set your goal weight and let Zealova auto-adjust calories"
        secondary="Zealova reads your weekly weigh-ins, compares actual change to target, and nudges your daily calories so the cut or bulk lands on schedule."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'Helms ER et al. (2014). Evidence-based recommendations for natural bodybuilding contest preparation. JISSN 11:20.',
            url: 'https://jissn.biomedcentral.com/articles/10.1186/1550-2783-11-20',
          },
          {
            text: 'Garthe I et al. (2011). Effect of two different weight-loss rates on body composition and strength and power-related performance in elite athletes. IJSNEM 21(2): 97-104.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/21558571/',
          },
          {
            text: 'Aragon AA, Schoenfeld BJ (2013). Nutrient timing revisited: is there a post-exercise anabolic window? JISSN 10:5.',
            url: 'https://jissn.biomedcentral.com/articles/10.1186/1550-2783-10-5',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
