// /tools/bmr-calculator

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import ResultsTable, { type ResultRow } from '../../components/tools/ResultsTable';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import { calculateAllBmr, recommendedBmrMethod } from '../../lib/calc/bmr';
import {
  lbToKg,
  ftInToCm,
  type Sex,
  type WeightUnit,
  type HeightUnit,
} from '../../lib/calc/units';

export default function BmrCalculator() {
  const [weight, setWeight] = useState<number | ''>(180);
  const [weightUnit, setWeightUnit] = useState<WeightUnit>('lb');
  const [heightUnit, setHeightUnit] = useState<HeightUnit>('ft');
  const [feet, setFeet] = useState<number | ''>(5);
  const [inches, setInches] = useState<number | ''>(10);
  const [heightCm, setHeightCm] = useState<number | ''>(178);
  const [age, setAge] = useState<number | ''>(30);
  const [sex, setSex] = useState<Sex>('male');
  const [bodyFat, setBodyFat] = useState<number | ''>('');

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
    const res = calculateAllBmr({
      weightKg: kg,
      heightCm: cm,
      age,
      sex,
      bodyFatPct: bfNum,
    });
    return {
      results: res,
      recommended: recommendedBmrMethod(bfNum !== undefined),
    };
  }, [weight, weightUnit, heightUnit, feet, inches, heightCm, age, sex, bodyFat]);

  const tableRows: ResultRow[] = results.map((r) => ({
    name: r.name,
    value: r.available ? `${r.value} kcal/day` : 'Needs body fat %',
    note: r.bestFor,
    recommended: r.method === recommended && r.available,
    citation: r.citation,
  }));

  const mifflinValue = results.find((r) => r.method === 'mifflin')?.value ?? 0;

  return (
    <CalculatorShell
      slug="bmr-calculator"
      title="BMR Calculator"
      metaDescription="Calculate your Basal Metabolic Rate (BMR) using all 4 major equations: Mifflin-St Jeor, Harris-Benedict, Katch-McArdle, and Cunningham. Free, side-by-side comparison."
      intro="Enter your weight, height, age, and sex. We calculate your BMR with every major equation in clinical use, so you can see the disagreement between them at a glance. Add body fat percent for the most accurate equations."
      faqs={[
        {
          q: 'Which BMR equation is most accurate?',
          a: 'For the general population, Mifflin-St Jeor (1990) is the current gold standard. It outperformed Harris-Benedict in a 2005 American Dietetic Association meta-analysis. For lean and athletic users with a known body fat percent, Katch-McArdle is more accurate because it scales with lean mass.',
        },
        {
          q: 'Should I use Katch-McArdle or Mifflin?',
          a: 'If you know your body fat percent within a few points, use Katch-McArdle. It accounts for the fact that muscle burns more calories at rest than fat does. If you do not have a recent body fat measurement, stick with Mifflin-St Jeor.',
        },
        {
          q: 'Why do the equations disagree by 100 to 300 kcal?',
          a: 'Each equation was fit on a different study population in a different era. Harris-Benedict (1919, revised 1984) used a smaller, older sample. Mifflin used a larger, more representative sample in 1990. Katch-McArdle assumes you have an accurate body fat measurement. The spread across equations is roughly your real measurement uncertainty.',
        },
        {
          q: 'Do I add my workouts on top of BMR?',
          a: 'No. BMR is the resting baseline only. To get your full daily calorie burn, multiply BMR by an activity factor. Use our TDEE calculator for that.',
        },
        {
          q: 'How accurate is any equation versus a metabolic cart?',
          a: 'Indirect calorimetry (the lab gold standard) has an error of around 2 percent. Predictive equations have an error of 5 to 15 percent at the individual level. They are good enough to set a starting point and adjust from weekly weight trend.',
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
          <NumberInput
            label="Weight"
            value={weight}
            onChange={setWeight}
            unit={weightUnit}
            min={1}
            step={0.5}
            placeholder="180"
          />
          {heightUnit === 'ft' ? (
            <div className="grid grid-cols-2 gap-2">
              <NumberInput
                label="Height (ft)"
                value={feet}
                onChange={setFeet}
                unit="ft"
                min={3}
                max={8}
                step={1}
                placeholder="5"
              />
              <NumberInput
                label="Height (in)"
                value={inches}
                onChange={setInches}
                unit="in"
                min={0}
                max={11.9}
                step={0.5}
                placeholder="10"
              />
            </div>
          ) : (
            <NumberInput
              label="Height"
              value={heightCm}
              onChange={setHeightCm}
              unit="cm"
              min={100}
              max={250}
              step={0.5}
              placeholder="178"
            />
          )}
          <NumberInput
            label="Age"
            value={age}
            onChange={setAge}
            unit="yrs"
            min={10}
            max={100}
            step={1}
            placeholder="30"
          />
          <NumberInput
            label="Body fat % (optional)"
            value={bodyFat}
            onChange={setBodyFat}
            unit="%"
            min={3}
            max={60}
            step={0.5}
            placeholder="20"
            help="Required for Katch-McArdle and Cunningham"
          />
        </div>
      </section>

      {/* Results */}
      {results.length > 0 && (
        <section>
          <h2 className="text-lg font-bold text-white mb-1">Estimated BMR</h2>
          <p className="text-sm text-zinc-400 mb-4">
            All 4 equations compared. The recommended equation for your inputs is highlighted.
          </p>
          <ResultsTable rows={tableRows} valueLabel="BMR" />
        </section>
      )}

      {/* Install CTA */}
      <InstallCta
        slug="bmr-calculator"
        result={{ bmr: mifflinValue, sex }}
        primary="Auto-update your BMR as your weight changes"
        secondary="Zealova recalculates your BMR every time you log weight, then adjusts your daily calorie and macro targets the same day."
      />

      {/* Methodology */}
      <MethodologyFooter
        citations={[
          {
            text: 'Mifflin MD, St Jeor ST et al. (1990). A new predictive equation for resting energy expenditure in healthy individuals. Am J Clin Nutr 51(2):241-7.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/2305711/',
          },
          {
            text: 'Roza AM, Shizgal HM (1984). The Harris Benedict equation reevaluated. Am J Clin Nutr 40(1):168-82.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/6741850/',
          },
          { text: 'Katch FI, McArdle WD (1996). Exercise Physiology: Energy, Nutrition, and Human Performance.' },
          {
            text: 'Cunningham JJ (1991). Body composition as a determinant of energy expenditure. Am J Clin Nutr 54(6):963-9.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/1957828/',
          },
          {
            text: 'Frankenfield D et al. (2005). Comparison of predictive equations for resting metabolic rate in healthy adults. J Am Diet Assoc 105(5):775-89.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/15883556/',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
