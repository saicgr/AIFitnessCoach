// /tools/calories-burned-calculator
//
// MET-based calorie estimate. Pick an activity, enter weight + duration, get
// kcal. Honest about variance: MET values are population averages, so we say
// so up-front and note that smartwatches will disagree.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import {
  ACTIVITY_CATEGORIES,
  ACTIVITY_METS,
  caloriesBurned,
  findActivity,
  kcalPerMinute,
} from '../../lib/calc/caloriesBurned';
import type { WeightUnit } from '../../lib/calc/units';
import { lbToKg, round } from '../../lib/calc/units';

export default function CaloriesBurnedCalculator() {
  const [activityKey, setActivityKey] = useState<string>('run-6');
  const [weight, setWeight] = useState<number | ''>(180);
  const [weightUnit, setWeightUnit] = useState<WeightUnit>('lb');
  const [minutes, setMinutes] = useState<number | ''>(30);

  const activity = findActivity(activityKey);

  const weightKg = useMemo(() => {
    if (typeof weight !== 'number') return 0;
    return weightUnit === 'lb' ? lbToKg(weight) : weight;
  }, [weight, weightUnit]);

  const total = useMemo(() => {
    if (!activity || typeof minutes !== 'number') return 0;
    return caloriesBurned(activity.met, weightKg, minutes);
  }, [activity, weightKg, minutes]);

  const perMin = activity && weightKg > 0 ? kcalPerMinute(activity.met, weightKg) : 0;
  const perHour = round(perMin * 60, 0);

  // Comparison: same duration across selected activity's category.
  const sameCategory = activity
    ? ACTIVITY_METS.filter((a) => a.category === activity.category)
    : [];

  return (
    <CalculatorShell
      slug="calories-burned-calculator"
      title="Calories Burned Calculator"
      metaDescription="Calculate calories burned during 25+ activities using MET values from the Compendium of Physical Activities. Free workout calorie calculator."
      intro="Pick an activity, enter your weight and how long you trained, and we'll estimate calories burned using the standard MET equation. Numbers will be in the right ballpark, but real expenditure varies with fitness and effort."
      faqs={[
        {
          q: 'Why does my smartwatch show different numbers?',
          a: 'Smartwatches use heart-rate plus motion data, which captures effort better than a flat MET value. But they also have to guess your VO2 max, anaerobic threshold, and economy of movement, which they cannot measure directly. Wearables and MET formulas typically agree within 15 to 30 percent. Neither is a gold standard outside a metabolic lab.',
        },
        {
          q: 'Are MET values accurate?',
          a: 'They are population averages from indirect calorimetry studies. The Compendium of Physical Activities (Ainsworth et al. 2011) is the reference everyone uses, but a 1.0 MET difference between two activities reflects an average across hundreds of subjects, not a precise number for any single person. Treat the output as a reasonable estimate, not a measurement.',
        },
        {
          q: 'Does fitness level affect calories burned?',
          a: 'Yes. A trained runner uses less oxygen and burns slightly fewer calories at the same pace than a beginner, because they move more efficiently. Conversely, beginners working at the same external pace are usually working at a higher percent of their VO2 max. The standard MET formula does not adjust for this.',
        },
        {
          q: 'Why is weight training so low on the list?',
          a: 'MET values measure average oxygen cost, and weight training has long rest periods between sets. A 60-minute session might only have 15 minutes of actual work. The 3.5 to 6.0 MET range reflects that. If you want a fairer comparison, count only working minutes.',
        },
        {
          q: 'Should I eat back calories burned?',
          a: 'For weight loss, most coaches recommend eating back zero to half of estimated exercise calories, because MET and wearable estimates are typically high. For performance, eat back most or all of them to maintain training quality. Track weight trend over two to three weeks and adjust.',
        },
      ]}
    >
      {/* Inputs */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <div className="flex justify-between items-center mb-6 flex-wrap gap-3">
          <h2 className="text-lg font-bold text-white">Your workout</h2>
          <UnitToggle
            value={weightUnit}
            options={[
              { value: 'lb', label: 'lb' },
              { value: 'kg', label: 'kg' },
            ]}
            onChange={setWeightUnit}
          />
        </div>

        <label className="block mb-4">
          <span className="block text-sm font-medium text-zinc-300 mb-1.5">Activity</span>
          <select
            value={activityKey}
            onChange={(e) => setActivityKey(e.target.value)}
            className="w-full px-4 py-3 rounded-xl bg-zinc-900 border border-zinc-700 text-white text-base focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
          >
            {ACTIVITY_CATEGORIES.map((cat) => (
              <optgroup key={cat.key} label={cat.label}>
                {ACTIVITY_METS.filter((a) => a.category === cat.key).map((a) => (
                  <option key={a.key} value={a.key}>
                    {a.name} ({a.met} MET)
                  </option>
                ))}
              </optgroup>
            ))}
          </select>
        </label>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <NumberInput
            label="Your weight"
            value={weight}
            onChange={setWeight}
            unit={weightUnit}
            min={1}
            step={0.5}
            placeholder={weightUnit === 'lb' ? '180' : '82'}
          />
          <NumberInput
            label="Duration"
            value={minutes}
            onChange={setMinutes}
            unit="min"
            min={1}
            max={600}
            step={1}
            placeholder="30"
          />
        </div>
      </section>

      {/* Result card */}
      {total > 0 && activity && (
        <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
          <p className="text-sm text-zinc-400 mb-1">Estimated calories burned</p>
          <p className="text-5xl font-bold text-white tabular-nums">{total}</p>
          <p className="text-base text-zinc-300 mt-1">kcal</p>
          <div className="mt-5 pt-5 border-t border-zinc-800 grid grid-cols-2 gap-4 text-sm">
            <div>
              <p className="text-zinc-500">Per minute</p>
              <p className="text-white font-semibold mt-0.5">{perMin} kcal</p>
            </div>
            <div>
              <p className="text-zinc-500">Per hour</p>
              <p className="text-white font-semibold mt-0.5">{perHour} kcal</p>
            </div>
          </div>
          <p className="text-xs text-zinc-500 mt-4 leading-relaxed">
            Based on {activity.met} MET for {activity.name.toLowerCase()}. Real expenditure varies with
            fitness, effort, equipment, and terrain.
          </p>
        </section>
      )}

      {/* Compare in same category */}
      {activity && sameCategory.length > 1 && weightKg > 0 && typeof minutes === 'number' && (
        <section>
          <h2 className="text-lg font-bold text-white mb-1">Compare similar activities</h2>
          <p className="text-sm text-zinc-400 mb-4">
            Same duration ({minutes} min) and same body weight, different intensities.
          </p>
          <div className="overflow-x-auto rounded-2xl border border-zinc-800">
            <table className="w-full text-sm">
              <thead className="bg-zinc-900 border-b border-zinc-800">
                <tr>
                  <th className="text-left px-4 py-3 font-semibold text-zinc-300">Activity</th>
                  <th className="text-right px-4 py-3 font-semibold text-zinc-300">MET</th>
                  <th className="text-right px-4 py-3 font-semibold text-zinc-300">kcal</th>
                </tr>
              </thead>
              <tbody>
                {sameCategory.map((a) => {
                  const kcal = caloriesBurned(a.met, weightKg, minutes);
                  const isCurrent = a.key === activity.key;
                  return (
                    <tr
                      key={a.key}
                      className={`border-b border-zinc-800 last:border-b-0 ${
                        isCurrent ? 'bg-emerald-950/30' : 'bg-zinc-950'
                      }`}
                    >
                      <td className="px-4 py-3 text-white">{a.name}</td>
                      <td className="px-4 py-3 text-right font-mono text-zinc-300">{a.met}</td>
                      <td className="px-4 py-3 text-right font-mono font-semibold text-white">
                        {kcal}
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
        slug="calories-burned-calculator"
        result={{ activity: activityKey, weightKg, minutes, kcal: total }}
        primary="Log your workouts and auto-track calories burned in Zealova"
        secondary="Every set, every run, every ride logs into your daily energy total automatically, with adjustments based on your actual weight trend."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'Ainsworth BE, Haskell WL, Herrmann SD et al. (2011). 2011 Compendium of Physical Activities: a second update of codes and MET values. Med Sci Sports Exerc 43(8):1575-1581.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/21681120/',
          },
          {
            text: 'Jetté M, Sidney K, Blümchen G (1990). Metabolic equivalents in exercise testing, exercise prescription, and evaluation. Clin Cardiol 13(8).',
            url: 'https://pubmed.ncbi.nlm.nih.gov/2204507/',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
