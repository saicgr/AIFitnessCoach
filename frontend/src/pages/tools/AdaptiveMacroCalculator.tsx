// /tools/adaptive-macro-calculator
//
// The marquee nutrition tool. Mimics what MacroFactor ($11.99/mo) does
// under the hood: adjusts macros weekly based on observed weight trend.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import { calculateAdaptiveMacros } from '../../lib/calc/adaptiveMacros';
import type { MacroGoal } from '../../lib/calc/macros';
import { type WeightUnit, lbToKg, kgToLb, inToCm, round } from '../../lib/calc/units';

export default function AdaptiveMacroCalculator() {
  const [unit, setUnit] = useState<WeightUnit>('lb');
  const [weight, setWeight] = useState<number | ''>(180);
  const [heightIn, setHeightIn] = useState<number | ''>(70);
  const [age, setAge] = useState<number | ''>(30);
  const [sex, setSex] = useState<'male' | 'female'>('male');
  const [activity, setActivity] = useState<number>(1.55);
  const [goal, setGoal] = useState<MacroGoal>('cut');
  const [weeklyTarget, setWeeklyTarget] = useState<number | ''>(0.5);  // kg/wk OR lb/wk

  const result = useMemo(() => {
    if (typeof weight !== 'number' || typeof heightIn !== 'number' || typeof age !== 'number' || typeof weeklyTarget !== 'number') {
      return null;
    }
    const bwKg = unit === 'lb' ? lbToKg(weight) : weight;
    const heightCm = unit === 'lb' ? inToCm(heightIn) : heightIn;
    const weeklyKg = unit === 'lb' ? lbToKg(weeklyTarget) : weeklyTarget;
    return calculateAdaptiveMacros({
      startingWeightKg: bwKg,
      heightCm,
      age,
      sex,
      activityMultiplier: activity,
      goal: goal === 'maintain' ? 'cut' : goal,
      weeklyTargetKg: weeklyKg,
    });
  }, [weight, heightIn, age, sex, activity, goal, weeklyTarget, unit]);

  const displayWeight = (kg: number) => unit === 'lb' ? `${round(kgToLb(kg), 1)} lb` : `${round(kg, 1)} kg`;
  const displayChange = (kg: number) => {
    const v = unit === 'lb' ? kgToLb(kg) : kg;
    const sign = v >= 0 ? '+' : '';
    return `${sign}${round(v, 2)} ${unit}`;
  };

  return (
    <CalculatorShell
      slug="adaptive-macro-calculator"
      title="Adaptive Macro Calculator"
      metaDescription="See a 4-week macro simulation that adjusts weekly based on your weight trend. The same algorithm MacroFactor charges $11.99/mo for. Free."
      intro="Static macros stop working after week 3. Your metabolism adapts. This simulator shows how an adaptive algorithm would tune your calories and macros every week to keep you on trajectory, instead of grinding away at a stale target."
      faqs={[
        {
          q: 'How is this different from MacroFactor?',
          a: 'The math is the same. MacroFactor charges $11.99/mo for ongoing adjustments tied to your daily logs. This calculator runs the 4-week simulation in your browser for free, so you can see the algorithm in action. Get continuous weekly updates inside Zealova once you sign up.',
        },
        {
          q: 'Why adjust weekly, not daily?',
          a: 'Day-to-day bodyweight swings 1 to 2 kg from water, glycogen, sodium, and gut content. Aggregating to a 7-day trend filters most of that noise. Weekly adjustments react to real fat-mass changes instead of chasing water fluctuations.',
        },
        {
          q: 'What about water-weight fluctuations?',
          a: 'Weekly averaging handles the obvious sources (carb refeeds, salt, cycle phase). For larger one-off swings (travel, alcohol, fasted weigh-in vs. fed) the algorithm will still see them as noise. The 25% tolerance band on the target rate is wide enough that one bad weigh-in does not trigger a wrong adjustment.',
        },
        {
          q: 'What if I stop losing for 3 weeks?',
          a: 'The algorithm flags a plateau, doubles the adjustment, and recommends a 7-day diet break at maintenance calories. Plateaus during a cut are usually metabolic adaptation, not lack of compliance. A diet break gives leptin and thyroid hormones time to recover before the next push.',
        },
        {
          q: 'Why does the projected loss slow down each week?',
          a: 'That is adaptive thermogenesis. NEAT (fidgeting, posture, spontaneous activity) drops as you lose weight, and BMR drops modestly. We model a 5 to 7% per-week drag on the loss rate. This is real, and it is exactly why a static calorie target fails.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <div className="flex justify-between items-center mb-6 flex-wrap gap-3">
          <h2 className="text-lg font-bold text-white">Your starting point</h2>
          <UnitToggle
            value={unit}
            options={[{ value: 'lb', label: 'lb / in' }, { value: 'kg', label: 'kg / cm' }]}
            onChange={setUnit}
          />
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <NumberInput label="Starting weight" value={weight} onChange={setWeight} unit={unit} min={1} step={0.5} />
          <NumberInput label="Height" value={heightIn} onChange={setHeightIn} unit={unit === 'lb' ? 'in' : 'cm'} min={1} step={0.5} />
          <NumberInput label="Age" value={age} onChange={setAge} unit="yrs" min={13} max={100} step={1} />
          <label className="block">
            <span className="block text-sm font-medium text-zinc-300 mb-1.5">Sex</span>
            <select value={sex} onChange={(e) => setSex(e.target.value as 'male' | 'female')} className="w-full px-4 py-3 rounded-xl bg-zinc-900 border border-zinc-700 text-white focus:outline-none focus:ring-2 focus:ring-emerald-500">
              <option value="male">Male</option>
              <option value="female">Female</option>
            </select>
          </label>
          <label className="block">
            <span className="block text-sm font-medium text-zinc-300 mb-1.5">Activity level</span>
            <select value={activity} onChange={(e) => setActivity(parseFloat(e.target.value))} className="w-full px-4 py-3 rounded-xl bg-zinc-900 border border-zinc-700 text-white focus:outline-none focus:ring-2 focus:ring-emerald-500">
              <option value={1.2}>Sedentary</option>
              <option value={1.375}>Lightly active</option>
              <option value={1.55}>Moderately active</option>
              <option value={1.725}>Very active</option>
              <option value={1.9}>Athlete</option>
            </select>
          </label>
          <label className="block">
            <span className="block text-sm font-medium text-zinc-300 mb-1.5">Goal</span>
            <select value={goal} onChange={(e) => setGoal(e.target.value as MacroGoal)} className="w-full px-4 py-3 rounded-xl bg-zinc-900 border border-zinc-700 text-white focus:outline-none focus:ring-2 focus:ring-emerald-500">
              <option value="cut">Cut (lose weight)</option>
              <option value="bulk">Bulk (gain weight)</option>
            </select>
          </label>
          <NumberInput
            label={`Weekly weight ${goal === 'cut' ? 'loss' : 'gain'} target`}
            value={weeklyTarget}
            onChange={setWeeklyTarget}
            unit={`${unit}/wk`}
            min={0.1}
            max={unit === 'lb' ? 2 : 1}
            step={0.1}
            help={unit === 'lb' ? '0.5-1.0 lb/wk is the standard safe range' : '0.25-0.5 kg/wk is the standard safe range'}
          />
        </div>
      </section>

      {result && (
        <>
          <section>
            <h2 className="text-lg font-bold text-white mb-1">4-week simulation</h2>
            <p className="text-sm text-zinc-400 mb-4">
              Starting TDEE estimate: <span className="font-mono text-white">{result.startingTdee} kcal</span>. Watch how calories adjust as the trend evolves.
            </p>
            <div className="overflow-x-auto rounded-2xl border border-zinc-800">
              <table className="w-full text-sm">
                <thead className="bg-zinc-900 border-b border-zinc-800">
                  <tr>
                    <th className="text-left px-4 py-3 font-semibold text-zinc-300">Week</th>
                    <th className="text-right px-4 py-3 font-semibold text-zinc-300">Weight</th>
                    <th className="text-right px-4 py-3 font-semibold text-zinc-300">Change</th>
                    <th className="text-right px-4 py-3 font-semibold text-zinc-300">Calories</th>
                    <th className="text-right px-4 py-3 font-semibold text-zinc-300 hidden md:table-cell">P / C / F</th>
                  </tr>
                </thead>
                <tbody>
                  {result.weeks.map((w) => (
                    <tr key={w.weekNum} className={`border-b border-zinc-800 last:border-b-0 ${w.adjustment !== 0 ? 'bg-amber-950/20' : 'bg-zinc-950'}`}>
                      <td className="px-4 py-3 font-medium text-white">Week {w.weekNum}</td>
                      <td className="px-4 py-3 text-right font-mono text-white">{displayWeight(w.projectedWeight)}</td>
                      <td className="px-4 py-3 text-right font-mono text-zinc-300">{displayChange(w.actualWeeklyChange)}</td>
                      <td className="px-4 py-3 text-right font-mono font-semibold text-white">{w.calorieTarget}</td>
                      <td className="px-4 py-3 text-right font-mono text-zinc-400 hidden md:table-cell">{w.proteinG} / {w.carbsG} / {w.fatG}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <div className="mt-4 space-y-2">
              {result.weeks.map((w) => (
                <div key={w.weekNum} className="text-sm text-zinc-400">
                  <span className="font-semibold text-white">Week {w.weekNum}:</span> {w.note}
                </div>
              ))}
            </div>
            <p className="mt-6 text-sm text-emerald-300 bg-emerald-950/30 border border-emerald-500/20 rounded-xl px-4 py-3">
              {result.summary}
            </p>
          </section>

          <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6">
            <h3 className="font-bold text-white mb-3">How the adjustments work</h3>
            <ul className="space-y-2 text-sm text-zinc-400">
              <li><span className="text-emerald-400">On target (±25% of goal rate):</span> hold calories. The plan is working.</li>
              <li><span className="text-amber-400">Too slow:</span> drop 100 kcal/day. The metabolism likely adapted.</li>
              <li><span className="text-amber-400">Too fast:</span> add 100 kcal/day. Aggressive deficits risk muscle loss.</li>
              <li><span className="text-rose-400">3-week plateau:</span> double adjustment plus a 7-day diet break at maintenance.</li>
            </ul>
          </section>
        </>
      )}

      <InstallCta
        slug="adaptive-macro-calculator"
        result={result ? { ...result } as unknown as Record<string, unknown> : undefined}
        primary="Skip the spreadsheet. Get this weekly adjustment automatically every Sunday in Zealova."
        secondary="We pull your weekly weight average and food log, run the same algorithm, and push the new target to your plan. No re-entering data, ever."
      />

      <MethodologyFooter
        citations={[
          { text: 'Hall KD (2008). What is the required energy deficit per unit weight loss? Int J Obes 32(3):573-6.', url: 'https://pubmed.ncbi.nlm.nih.gov/17848938/' },
          { text: 'Trexler ET, Smith-Ryan AE, Norton LE (2014). Metabolic adaptation to weight loss: implications for the athlete. JISSN 11:7.', url: 'https://jissn.biomedcentral.com/articles/10.1186/1550-2783-11-7' },
          { text: 'Mifflin MD, St Jeor ST et al. (1990). A new predictive equation for resting energy expenditure in healthy individuals. Am J Clin Nutr 51(2):241-7.', url: 'https://pubmed.ncbi.nlm.nih.gov/2305711/' },
          { text: 'Helms ER, Aragon AA, Fitschen PJ (2014). Evidence-based recommendations for natural bodybuilding contest preparation. JISSN 11:20.', url: 'https://jissn.biomedcentral.com/articles/10.1186/1550-2783-11-20' },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
