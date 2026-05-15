// /tools/lean-body-mass-calculator

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import ResultsTable, { type ResultRow } from '../../components/tools/ResultsTable';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import { calculateAllLbm, proteinTargetFromLbm } from '../../lib/calc/leanBodyMass';
import {
  lbToKg,
  kgToLb,
  ftInToCm,
  round,
  type Sex,
  type WeightUnit,
  type HeightUnit,
} from '../../lib/calc/units';

export default function LeanBodyMassCalculator() {
  const [weight, setWeight] = useState<number | ''>(180);
  const [weightUnit, setWeightUnit] = useState<WeightUnit>('lb');
  const [heightUnit, setHeightUnit] = useState<HeightUnit>('ft');
  const [feet, setFeet] = useState<number | ''>(5);
  const [inches, setInches] = useState<number | ''>(10);
  const [heightCm, setHeightCm] = useState<number | ''>(178);
  const [sex, setSex] = useState<Sex>('male');

  const results = useMemo(() => {
    if (typeof weight !== 'number') return [];
    const kg = weightUnit === 'lb' ? lbToKg(weight) : weight;
    let cm = 0;
    if (heightUnit === 'ft') {
      if (typeof feet !== 'number' || typeof inches !== 'number') return [];
      cm = ftInToCm(feet, inches);
    } else {
      if (typeof heightCm !== 'number') return [];
      cm = heightCm;
    }
    return calculateAllLbm({ weightKg: kg, heightCm: cm, sex });
  }, [weight, weightUnit, heightUnit, feet, inches, heightCm, sex]);

  // Display LBM in the user's chosen weight unit.
  const displayLbm = (kg: number) =>
    weightUnit === 'lb' ? `${round(kgToLb(kg), 1)} lb` : `${round(kg, 1)} kg`;

  const tableRows: ResultRow[] = results.map((r) => ({
    name: r.name,
    value: displayLbm(r.lbmKg),
    note: `${r.bodyFatPct}% body fat implied. ${r.bestFor}`,
    recommended: r.method === 'boer',
    citation: r.citation,
  }));

  const boer = results.find((r) => r.method === 'boer');
  const protein = boer ? proteinTargetFromLbm(boer.lbmKg) : null;

  return (
    <CalculatorShell
      slug="lean-body-mass-calculator"
      title="Lean Body Mass Calculator"
      metaDescription="Estimate your lean body mass (LBM, fat-free mass) using Boer, James, and Hume formulas. Free LBM calculator with daily protein target."
      intro="Your lean body mass is everything except fat: muscle, bone, organs, water. It is a better anchor for protein targets than total body weight, and a more stable progress metric than the scale alone."
      faqs={[
        {
          q: 'Why do I need to know my LBM?',
          a: 'Two reasons. First, protein needs scale with lean mass, not total weight. A 200 lb person at 30 percent body fat needs less protein than a 200 lb person at 12 percent. Second, LBM is the part of you that lifting builds. Tracking LBM over months tells you whether your training is actually adding muscle.',
        },
        {
          q: 'How is LBM different from body fat?',
          a: 'They are complements. Body weight equals lean body mass plus fat mass. If you weigh 180 lb and your LBM is 144 lb, your fat mass is 36 lb, which is 20 percent body fat. Knowing one gives you the other.',
        },
        {
          q: 'Why do the formulas disagree?',
          a: 'Each was fit on a different study population. Boer (1984) is the most cited modern formula and is our default. James (1976) is more conservative for very heavy individuals. Hume (1966) was the original regression from cadaver data and is still used in pharmacology dosing.',
        },
        {
          q: 'How accurate is this versus DEXA?',
          a: 'These formulas use only height, weight, and sex, so they cannot account for individual body composition. Expect a 5 to 10 percent error at the individual level. For more accurate LBM, measure your body fat with skinfolds or DEXA and compute LBM as weight times (1 minus body fat percent).',
        },
        {
          q: 'How much protein do I need based on LBM?',
          a: 'For resistance trainees, around 2.0 to 2.7 g per kg of LBM per day. That is the ISSN 2017 position-stand range translated from total-weight to LBM-based at typical body fat. We show your target below.',
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
        </div>
        <p className="text-xs text-zinc-500 mt-4">
          These formulas use height, weight, and sex only. For higher accuracy, measure body fat directly and compute LBM as weight × (1 − body fat %).
        </p>
      </section>

      {/* Results */}
      {results.length > 0 && (
        <section>
          <h2 className="text-lg font-bold text-white mb-1">Estimated lean body mass</h2>
          <p className="text-sm text-zinc-400 mb-4">
            All 3 formulas compared. Boer is highlighted as the modern default.
          </p>
          <ResultsTable rows={tableRows} valueLabel="LBM" />
        </section>
      )}

      {/* Protein target */}
      {boer && protein && (
        <section className="rounded-2xl border border-emerald-500/30 bg-gradient-to-br from-emerald-950/60 to-zinc-900 p-6">
          <p className="text-xs uppercase tracking-wide text-emerald-400 font-semibold">
            Daily protein target
          </p>
          <p className="text-3xl font-bold text-white mt-1 font-mono">
            {protein.low} – {protein.high} g
          </p>
          <p className="text-sm text-zinc-400 mt-2">
            Based on Boer LBM of {displayLbm(boer.lbmKg)}, using ISSN 2017 position stand. Split across 3 to 5 meals for best results.
          </p>
        </section>
      )}

      {/* Install CTA */}
      <InstallCta
        slug="lean-body-mass-calculator"
        result={{ lbmKg: boer?.lbmKg ?? 0, sex }}
        primary="Calculate protein needs from your lean mass automatically"
        secondary="Zealova logs your weight trend, re-derives LBM weekly, and updates your protein and macro targets without you touching a calculator again."
      />

      {/* Methodology */}
      <MethodologyFooter
        citations={[
          {
            text: 'Boer P (1984). Estimated lean body mass as an index for normalization of body fluid volumes in humans. Am J Physiol 247(4 Pt 2):F632-6.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/6496691/',
          },
          { text: 'James W (1976). Research on Obesity: A Report of the DHSS/MRC Group. HMSO London.' },
          {
            text: 'Hume R (1966). Prediction of lean body mass from height and weight. J Clin Pathol 19(4):389-91.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/5929341/',
          },
          {
            text: 'Jäger R et al. (2017). ISSN Position Stand: protein and exercise. J Int Soc Sports Nutr 14:20.',
            url: 'https://jissn.biomedcentral.com/articles/10.1186/s12970-017-0177-8',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
