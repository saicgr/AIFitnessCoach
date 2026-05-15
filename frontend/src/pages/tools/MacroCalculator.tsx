// /tools/macro-calculator

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import {
  calculateMacros,
  estimateTdee,
  MACRO_PRESETS,
  type MacroGoal,
  type MacroPreset,
} from '../../lib/calc/macros';
import { type WeightUnit, lbToKg, kgToLb, inToCm, round } from '../../lib/calc/units';

type InputMode = 'tdee' | 'estimate';

export default function MacroCalculator() {
  const [mode, setMode] = useState<InputMode>('tdee');
  const [unit, setUnit] = useState<WeightUnit>('lb');
  const [tdeeInput, setTdeeInput] = useState<number | ''>(2500);
  const [bodyweight, setBodyweight] = useState<number | ''>(180);
  const [heightIn, setHeightIn] = useState<number | ''>(70);
  const [age, setAge] = useState<number | ''>(30);
  const [sex, setSex] = useState<'male' | 'female'>('male');
  const [activity, setActivity] = useState<number>(1.55);
  const [goal, setGoal] = useState<MacroGoal>('maintain');
  const [preset, setPreset] = useState<MacroPreset>('balanced');

  const result = useMemo(() => {
    if (typeof bodyweight !== 'number') return null;
    const bwKg = unit === 'lb' ? lbToKg(bodyweight) : bodyweight;

    let tdee: number;
    if (mode === 'tdee' && typeof tdeeInput === 'number') {
      tdee = tdeeInput;
    } else if (mode === 'estimate' && typeof heightIn === 'number' && typeof age === 'number') {
      const heightCm = unit === 'lb' ? inToCm(heightIn) : heightIn;
      tdee = estimateTdee(bwKg, heightCm, age, sex, activity);
    } else {
      return null;
    }

    return { ...calculateMacros({ tdee, bodyweightKg: bwKg, goal, preset }), tdee };
  }, [mode, tdeeInput, bodyweight, heightIn, age, sex, activity, goal, preset, unit]);

  return (
    <CalculatorShell
      slug="macro-calculator"
      title="Macro Calculator"
      metaDescription="Calculate daily protein, carbs, and fat targets based on your goal (cut, maintain, bulk), bodyweight, and diet preference. Research-backed splits, free."
      intro="Set protein and fat to bodyweight-anchored targets, then let carbs fill the calorie budget. Pick a goal and a preset to see exactly what to eat per day."
      faqs={[
        {
          q: 'How much protein do I really need?',
          a: 'For active adults the research consensus is 1.6 to 2.2 grams per kilogram of bodyweight per day. The high end of that range matters most during a cut, when extra protein protects lean mass. In a surplus, 1.6 to 1.8 g/kg is enough to support muscle gain alongside training stimulus.',
        },
        {
          q: 'Why are carbs so high if I lift?',
          a: 'Glycolytic training (any set in the 5 to 15 rep range) burns muscle glycogen as the main fuel. Adequate carbs let you hit your prescribed reps and recover for the next session. Cutting carbs too low usually reduces training quality before it reduces body fat.',
        },
        {
          q: 'Should I track macros or just calories?',
          a: 'Calories drive weight change. Macros drive what kind of weight changes. Tracking only calories on a cut often costs you muscle. Tracking only protein and calories is the practical minimum. Full macro tracking is most valuable on aggressive cuts or for physique competitors.',
        },
        {
          q: 'What if I do keto?',
          a: 'The keto preset sets fat at 75% of calories. Protein stays at 2 g/kg because too much protein converts to glucose via gluconeogenesis. Carbs are whatever is left, usually under 50 g per day. This is the standard well-formulated ketogenic split.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <div className="flex justify-between items-center mb-6 flex-wrap gap-3">
          <h2 className="text-lg font-bold text-white">Your inputs</h2>
          <UnitToggle
            value={unit}
            options={[{ value: 'lb', label: 'lb / in' }, { value: 'kg', label: 'kg / cm' }]}
            onChange={setUnit}
          />
        </div>

        <div className="mb-6">
          <span className="block text-sm font-medium text-zinc-300 mb-2">How do you want to set calories?</span>
          <div className="grid grid-cols-2 gap-2">
            <button
              type="button"
              onClick={() => setMode('tdee')}
              className={`px-3 py-2 rounded-lg text-sm font-medium border transition ${mode === 'tdee' ? 'bg-emerald-500 text-zinc-900 border-emerald-500' : 'border-zinc-700 text-zinc-300 hover:border-zinc-500'}`}
            >
              I know my TDEE
            </button>
            <button
              type="button"
              onClick={() => setMode('estimate')}
              className={`px-3 py-2 rounded-lg text-sm font-medium border transition ${mode === 'estimate' ? 'bg-emerald-500 text-zinc-900 border-emerald-500' : 'border-zinc-700 text-zinc-300 hover:border-zinc-500'}`}
            >
              Estimate from stats
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {mode === 'tdee' && (
            <NumberInput
              label="TDEE (maintenance calories)"
              value={tdeeInput}
              onChange={setTdeeInput}
              unit="kcal"
              min={1000}
              max={6000}
              step={10}
              placeholder="2500"
              help="Use our TDEE calculator if unsure"
            />
          )}
          <NumberInput
            label="Bodyweight"
            value={bodyweight}
            onChange={setBodyweight}
            unit={unit}
            min={1}
            step={0.5}
          />
          {mode === 'estimate' && (
            <>
              <NumberInput
                label={unit === 'lb' ? 'Height' : 'Height'}
                value={heightIn}
                onChange={setHeightIn}
                unit={unit === 'lb' ? 'in' : 'cm'}
                min={1}
                step={0.5}
              />
              <NumberInput
                label="Age"
                value={age}
                onChange={setAge}
                unit="yrs"
                min={13}
                max={100}
                step={1}
              />
              <label className="block">
                <span className="block text-sm font-medium text-zinc-300 mb-1.5">Sex</span>
                <select
                  value={sex}
                  onChange={(e) => setSex(e.target.value as 'male' | 'female')}
                  className="w-full px-4 py-3 rounded-xl bg-zinc-900 border border-zinc-700 text-white focus:outline-none focus:ring-2 focus:ring-emerald-500"
                >
                  <option value="male">Male</option>
                  <option value="female">Female</option>
                </select>
              </label>
              <label className="block">
                <span className="block text-sm font-medium text-zinc-300 mb-1.5">Activity level</span>
                <select
                  value={activity}
                  onChange={(e) => setActivity(parseFloat(e.target.value))}
                  className="w-full px-4 py-3 rounded-xl bg-zinc-900 border border-zinc-700 text-white focus:outline-none focus:ring-2 focus:ring-emerald-500"
                >
                  <option value={1.2}>Sedentary</option>
                  <option value={1.375}>Lightly active</option>
                  <option value={1.55}>Moderately active</option>
                  <option value={1.725}>Very active</option>
                  <option value={1.9}>Athlete</option>
                </select>
              </label>
            </>
          )}
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-4">
          <label className="block">
            <span className="block text-sm font-medium text-zinc-300 mb-1.5">Goal</span>
            <select
              value={goal}
              onChange={(e) => setGoal(e.target.value as MacroGoal)}
              className="w-full px-4 py-3 rounded-xl bg-zinc-900 border border-zinc-700 text-white focus:outline-none focus:ring-2 focus:ring-emerald-500"
            >
              <option value="cut">Cut (-20%)</option>
              <option value="maintain">Maintain</option>
              <option value="bulk">Bulk (+10%)</option>
            </select>
          </label>
          <label className="block">
            <span className="block text-sm font-medium text-zinc-300 mb-1.5">Preset</span>
            <select
              value={preset}
              onChange={(e) => setPreset(e.target.value as MacroPreset)}
              className="w-full px-4 py-3 rounded-xl bg-zinc-900 border border-zinc-700 text-white focus:outline-none focus:ring-2 focus:ring-emerald-500"
            >
              {MACRO_PRESETS.map((p) => (
                <option key={p.key} value={p.key}>{p.name}</option>
              ))}
            </select>
          </label>
        </div>
      </section>

      {result && (
        <section>
          <h2 className="text-lg font-bold text-white mb-1">Your daily macros</h2>
          <p className="text-sm text-zinc-400 mb-4">
            Target: <span className="font-mono text-white">{result.calories} kcal/day</span> from a base TDEE of {result.tdee} kcal.
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <MacroCard label="Protein" grams={result.protein_g} pct={result.protein_pct} perKg={result.protein_per_kg} color="bg-rose-500/10 border-rose-500/30 text-rose-300" />
            <MacroCard label="Carbs" grams={result.carbs_g} pct={result.carbs_pct} perKg={null} color="bg-amber-500/10 border-amber-500/30 text-amber-300" />
            <MacroCard label="Fat" grams={result.fat_g} pct={result.fat_pct} perKg={result.fat_per_kg} color="bg-sky-500/10 border-sky-500/30 text-sky-300" />
          </div>
          <p className="text-xs text-zinc-500 mt-3">
            Protein at {result.protein_per_kg} g/kg, fat at {result.fat_per_kg} g/kg. Carbs absorb the remainder.
          </p>
        </section>
      )}

      <InstallCta
        slug="macro-calculator"
        result={result ?? undefined}
        primary="Get these macros applied to your daily food log automatically"
        secondary="Zealova logs your meals against this target, tracks weekly averages, and warns you before you blow protein or hit a fat surplus."
      />

      <MethodologyFooter
        citations={[
          { text: 'Helms ER, Aragon AA, Fitschen PJ (2014). Evidence-based recommendations for natural bodybuilding contest preparation: nutrition and supplementation. JISSN 11:20.', url: 'https://jissn.biomedcentral.com/articles/10.1186/1550-2783-11-20' },
          { text: 'Aragon AA, Schoenfeld BJ (2013). Nutrient timing revisited. JISSN 10:5.', url: 'https://jissn.biomedcentral.com/articles/10.1186/1550-2783-10-5' },
          { text: 'Mettler S, Mitchell N, Tipton KD (2010). Increased protein intake reduces lean body mass loss during weight loss in athletes. MSSE 42(2):326-37.', url: 'https://pubmed.ncbi.nlm.nih.gov/19927027/' },
          { text: 'Morton RW et al. (2018). Meta-analysis: protein supplementation and resistance training. Br J Sports Med 52(6):376-384.', url: 'https://bjsm.bmj.com/content/52/6/376' },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}

function MacroCard({ label, grams, pct, perKg, color }: { label: string; grams: number; pct: number; perKg: number | null; color: string }) {
  return (
    <div className={`rounded-2xl border p-4 ${color}`}>
      <p className="text-xs uppercase tracking-wide font-semibold opacity-80">{label}</p>
      <p className="text-3xl font-bold text-white mt-1">{grams}<span className="text-base text-zinc-400 font-normal"> g</span></p>
      <p className="text-xs text-zinc-400 mt-1">{pct}% of calories{perKg !== null ? ` • ${perKg} g/kg` : ''}</p>
    </div>
  );
}

// Suppress unused import warning if user picks units other than lb-to-kg path
void kgToLb;
void round;
