// /tools/tdee-calculator

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import ResultsTable, { type ResultRow } from '../../components/tools/ResultsTable';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import { recommendedBmrMethod } from '../../lib/calc/bmr';
import {
  calculateAllTdee,
  goalTargets,
  ACTIVITY_LEVELS,
  type ActivityLevel,
} from '../../lib/calc/tdee';
import {
  lbToKg,
  ftInToCm,
  type Sex,
  type WeightUnit,
  type HeightUnit,
} from '../../lib/calc/units';

export default function TdeeCalculator() {
  const [weight, setWeight] = useState<number | ''>(180);
  const [weightUnit, setWeightUnit] = useState<WeightUnit>('lb');
  const [heightUnit, setHeightUnit] = useState<HeightUnit>('ft');
  const [feet, setFeet] = useState<number | ''>(5);
  const [inches, setInches] = useState<number | ''>(10);
  const [heightCm, setHeightCm] = useState<number | ''>(178);
  const [age, setAge] = useState<number | ''>(30);
  const [sex, setSex] = useState<Sex>('male');
  const [bodyFat, setBodyFat] = useState<number | ''>('');
  const [activity, setActivity] = useState<ActivityLevel>('moderate');

  const { results, recommended } = useMemo(() => {
    if (typeof weight !== 'number' || typeof age !== 'number') {
      return { results: [], recommended: null };
    }
    const kg = weightUnit === 'lb' ? lbToKg(weight) : weight;
    let cm = 0;
    if (heightUnit === 'ft') {
      if (typeof feet !== 'number' || typeof inches !== 'number') {
        return { results: [], recommended: null };
      }
      cm = ftInToCm(feet, inches);
    } else {
      if (typeof heightCm !== 'number') {
        return { results: [], recommended: null };
      }
      cm = heightCm;
    }
    const bfNum = typeof bodyFat === 'number' && bodyFat > 0 ? bodyFat : undefined;
    const res = calculateAllTdee(
      { weightKg: kg, heightCm: cm, age, sex, bodyFatPct: bfNum },
      activity,
    );
    return {
      results: res,
      recommended: recommendedBmrMethod(bfNum !== undefined),
    };
  }, [weight, weightUnit, heightUnit, feet, inches, heightCm, age, sex, bodyFat, activity]);

  const tableRows: ResultRow[] = results.map((r) => ({
    name: r.name,
    value: r.available ? `${r.tdee} kcal/day` : 'Needs body fat %',
    note: r.available ? `BMR: ${r.bmr} kcal × ${ACTIVITY_LEVELS.find((a) => a.key === activity)?.multiplier}` : r.bestFor,
    recommended: r.method === recommended && r.available,
    citation: r.citation,
  }));

  const recommendedTdee = results.find((r) => r.method === recommended)?.tdee ?? 0;
  const goals = recommendedTdee > 0 ? goalTargets(recommendedTdee) : null;

  return (
    <CalculatorShell
      slug="tdee-calculator"
      title="TDEE Calculator"
      metaDescription="Calculate your Total Daily Energy Expenditure using 4 BMR equations and 5 activity multipliers. Free TDEE calculator with cut, maintenance, and bulk targets."
      intro="Your TDEE is total calories burned per day, including workouts and daily movement. We calculate it across all 4 major BMR equations, then apply your activity factor, so you can see the full uncertainty range."
      faqs={[
        {
          q: 'What activity level should I pick?',
          a: 'Be honest. Most people overestimate this. If you sit at a desk and lift 3 days a week, that is "moderately active", not "very active". If you walk under 7,500 steps a day and only train hard 2-3 days, you are closer to "lightly active". When in doubt, pick one lower than you think and adjust from weekly weight trend.',
        },
        {
          q: 'Why does my fitness tracker show a different number?',
          a: 'Trackers measure heart-rate variation and movement, then run their own black-box estimate. They are often 10 to 30 percent off the truth, especially for resistance training. The published activity-multiplier method is more conservative and tends to be more reliable as a starting point.',
        },
        {
          q: 'Should I add my workouts as additional calories?',
          a: 'No. The activity multipliers already include average weekly training. Adding tracker calories on top is the most common reason a "1,800 kcal diet" stalls. Set TDEE once, then adjust based on what the scale actually does over 2-3 weeks.',
        },
        {
          q: 'How much should I subtract for a cut?',
          a: 'A 300 to 500 kcal deficit produces around 0.5 to 1 lb per week of weight loss. We pre-calculate that target below. For aggressive cuts, go up to 750 kcal but expect muscle loss and lower training quality.',
        },
        {
          q: 'How often should I recalculate?',
          a: 'Every 2 to 3 weeks during a cut or bulk, or whenever your weight has changed by 5 pounds. BMR drops as you lose weight, so static numbers stop working.',
        },
      ]}
    >
      {/* Inputs */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <div className="flex justify-between items-center mb-6 flex-wrap gap-3">
          <h2 className="text-lg font-bold text-white">Your body</h2>
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
              value={weightUnit}
              options={[
                { value: 'lb', label: 'lb' },
                { value: 'kg', label: 'kg' },
              ]}
              onChange={setWeightUnit}
            />
            <UnitToggle
              value={heightUnit}
              options={[
                { value: 'ft', label: 'ft/in' },
                { value: 'cm', label: 'cm' },
              ]}
              onChange={setHeightUnit}
            />
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <NumberInput label="Weight" value={weight} onChange={setWeight} unit={weightUnit} min={1} step={0.5} />
          {heightUnit === 'ft' ? (
            <div className="grid grid-cols-2 gap-2">
              <NumberInput label="Height (ft)" value={feet} onChange={setFeet} unit="ft" min={3} max={8} step={1} />
              <NumberInput label="Height (in)" value={inches} onChange={setInches} unit="in" min={0} max={11.9} step={0.5} />
            </div>
          ) : (
            <NumberInput label="Height" value={heightCm} onChange={setHeightCm} unit="cm" min={100} max={250} step={0.5} />
          )}
          <NumberInput label="Age" value={age} onChange={setAge} unit="yrs" min={10} max={100} step={1} />
          <NumberInput
            label="Body fat % (optional)"
            value={bodyFat}
            onChange={setBodyFat}
            unit="%"
            min={3}
            max={60}
            step={0.5}
            help="Unlocks Katch-McArdle and Cunningham"
          />
        </div>

        <div className="mt-6">
          <h3 className="text-sm font-semibold text-zinc-300 mb-3">Activity level</h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
            {ACTIVITY_LEVELS.map((a) => {
              const active = a.key === activity;
              return (
                <button
                  key={a.key}
                  type="button"
                  onClick={() => setActivity(a.key)}
                  className={`text-left px-4 py-3 rounded-xl border transition ${
                    active
                      ? 'border-emerald-500 bg-emerald-500/10'
                      : 'border-zinc-700 bg-zinc-950 hover:border-zinc-600'
                  }`}
                >
                  <div className="flex items-baseline justify-between gap-2">
                    <span className="font-semibold text-white text-sm">{a.name}</span>
                    <span className="font-mono text-xs text-emerald-400">×{a.multiplier}</span>
                  </div>
                  <p className="text-xs text-zinc-400 mt-0.5">{a.description}</p>
                </button>
              );
            })}
          </div>
        </div>
      </section>

      {/* Results */}
      {results.length > 0 && (
        <section>
          <h2 className="text-lg font-bold text-white mb-1">Estimated TDEE</h2>
          <p className="text-sm text-zinc-400 mb-4">
            All 4 equations compared, multiplied by your activity factor. The recommended equation is highlighted.
          </p>
          <ResultsTable rows={tableRows} valueLabel="TDEE" />
        </section>
      )}

      {/* Goal targets */}
      {goals && (
        <section>
          <h2 className="text-lg font-bold text-white mb-1">Daily calorie targets</h2>
          <p className="text-sm text-zinc-400 mb-4">
            Based on your recommended TDEE of {recommendedTdee} kcal/day.
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <GoalCard label="Cut" value={goals.cut} note="≈ 0.7-1 lb/week loss" tone="emerald" />
            <GoalCard label="Maintenance" value={goals.maintenance} note="Hold current weight" tone="zinc" />
            <GoalCard label="Lean bulk" value={goals.bulk} note="≈ 0.4-0.6 lb/week gain" tone="amber" />
          </div>
        </section>
      )}

      {/* Install CTA */}
      <InstallCta
        slug="tdee-calculator"
        result={{ tdee: recommendedTdee, activity, sex }}
        primary="Adapt your calorie target weekly based on actual weight trend"
        secondary="Zealova watches your 7-day weight trend and quietly nudges your daily target up or down. No more guessing whether you need a refeed."
      />

      {/* Methodology */}
      <MethodologyFooter
        citations={[
          {
            text: 'Mifflin MD, St Jeor ST et al. (1990). A new predictive equation for resting energy expenditure. Am J Clin Nutr 51(2):241-7.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/2305711/',
          },
          {
            text: 'Frankenfield D et al. (2005). Comparison of predictive equations for resting metabolic rate. J Am Diet Assoc 105(5):775-89.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/15883556/',
          },
          { text: 'Roza AM, Shizgal HM (1984). The Harris Benedict equation reevaluated. Am J Clin Nutr 40(1):168-82.' },
          { text: 'Katch FI, McArdle WD (1996). Exercise Physiology.' },
          { text: 'Cunningham JJ (1991). Body composition as a determinant of energy expenditure. Am J Clin Nutr 54(6):963-9.' },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}

function GoalCard({
  label,
  value,
  note,
  tone,
}: {
  label: string;
  value: number;
  note: string;
  tone: 'emerald' | 'zinc' | 'amber';
}) {
  const toneClass =
    tone === 'emerald'
      ? 'border-emerald-500/40 bg-emerald-950/40'
      : tone === 'amber'
        ? 'border-amber-500/40 bg-amber-950/40'
        : 'border-zinc-700 bg-zinc-900';
  return (
    <div className={`rounded-2xl border p-5 ${toneClass}`}>
      <p className="text-xs uppercase tracking-wide text-zinc-400 font-semibold">{label}</p>
      <p className="text-2xl font-bold text-white mt-1 font-mono">{value}</p>
      <p className="text-xs text-zinc-400 mt-1">kcal / day. {note}.</p>
    </div>
  );
}
