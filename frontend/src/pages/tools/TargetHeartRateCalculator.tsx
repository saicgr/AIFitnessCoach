// /tools/target-heart-rate-calculator
//
// HRmax across Fox, Tanaka, Gulati (women), plus Karvonen reserve method
// when the user supplies resting HR. Returns 5 ACSM-style zones.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import ResultsTable, { type ResultRow } from '../../components/tools/ResultsTable';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import {
  HR_FORMULAS,
  computeZones,
  hrMax,
  type HrFormula,
} from '../../lib/calc/targetHr';
import type { Sex } from '../../lib/calc/units';
import { round } from '../../lib/calc/units';

// Zone color tints. Stays within zinc + emerald palette per design rules.
const ZONE_TINT: Record<number, string> = {
  1: 'bg-zinc-800/60 border-zinc-700',
  2: 'bg-emerald-950/40 border-emerald-900/60',
  3: 'bg-emerald-900/40 border-emerald-800/60',
  4: 'bg-emerald-800/40 border-emerald-700/60',
  5: 'bg-emerald-700/40 border-emerald-600/60',
};

export default function TargetHeartRateCalculator() {
  const [age, setAge] = useState<number | ''>(30);
  const [sex, setSex] = useState<Sex>('male');
  const [restHr, setRestHr] = useState<number | ''>('');

  const restHrNum = typeof restHr === 'number' && restHr > 0 ? restHr : undefined;

  const hrMaxRows: ResultRow[] = useMemo(() => {
    if (typeof age !== 'number' || age <= 0) return [];
    // Tanaka is the recommended default. Gulati only when sex is female.
    const recommended: HrFormula = sex === 'female' ? 'gulati' : 'tanaka';
    return HR_FORMULAS.filter((f) => !(f.key === 'gulati' && sex === 'male')).map((f) => ({
      name: f.name,
      value: `${round(hrMax(f.key, age, sex), 0)} bpm`,
      note: f.bestFor,
      citation: f.citation,
      recommended: f.key === recommended,
    }));
  }, [age, sex]);

  const zones = useMemo(() => {
    if (typeof age !== 'number' || age <= 0) return [];
    const formula: HrFormula = sex === 'female' ? 'gulati' : 'tanaka';
    return computeZones(age, { formula, sex, restHr: restHrNum });
  }, [age, sex, restHrNum]);

  return (
    <CalculatorShell
      slug="target-heart-rate-calculator"
      title="Target Heart Rate Calculator"
      metaDescription="Calculate your max heart rate and 5 training zones using Fox, Tanaka, Gulati, and Karvonen formulas. Free target heart rate calculator."
      intro="Enter your age. We compare every major HRmax formula and map your 5 training zones. Add resting HR and we switch to Karvonen heart-rate reserve for more accurate zones."
      faqs={[
        {
          q: 'Which HRmax formula is most accurate?',
          a: 'Tanaka (208 - 0.7 × age) outperforms the classic 220 - age rule across nearly every age group. For women under 40, Gulati (206 - 0.88 × age) is even tighter. The original Fox formula is fine as a rough rule of thumb but has an error margin of ±10-12 bpm. Lab-measured HRmax is still the gold standard for serious athletes.',
        },
        {
          q: 'Why does Karvonen need resting HR?',
          a: 'Karvonen calculates zones from heart rate reserve (HRmax minus resting HR), which scales each zone to your individual cardiovascular fitness. A 30-year-old with a resting HR of 50 lands in zone 2 at very different absolute bpm than a 30-year-old with a resting HR of 75. Without resting HR, we have to fall back on simple percentages of HRmax.',
        },
        {
          q: 'What zone burns fat?',
          a: 'Zone 2 (60-70% of HRmax) maximizes the percentage of fuel coming from fat. But total calories burned matters far more than fuel mix for body composition. A hard zone 4 session burns more total calories and more fat in absolute terms than an easy zone 2 session of the same duration. Use zone 2 for aerobic base, not for "fat burning" in isolation.',
        },
      ]}
    >
      {/* Inputs */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <h2 className="text-lg font-bold text-white mb-6">About you</h2>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <NumberInput
            label="Age"
            value={age}
            onChange={setAge}
            min={10}
            max={100}
            step={1}
            placeholder="30"
          />
          <div>
            <span className="block text-sm font-medium text-zinc-300 mb-1.5">Sex</span>
            <UnitToggle
              value={sex}
              options={[
                { value: 'male', label: 'Male' },
                { value: 'female', label: 'Female' },
              ]}
              onChange={setSex}
            />
          </div>
          <NumberInput
            label="Resting HR (optional)"
            value={restHr}
            onChange={setRestHr}
            unit="bpm"
            min={30}
            max={120}
            step={1}
            placeholder="60"
            help="Add this for Karvonen reserve zones."
          />
        </div>
      </section>

      {/* HRmax across formulas */}
      {hrMaxRows.length > 0 && (
        <section>
          <h2 className="text-lg font-bold text-white mb-1">Max heart rate across formulas</h2>
          <p className="text-sm text-zinc-400 mb-4">
            Recommended formula for your profile is highlighted.
          </p>
          <ResultsTable rows={hrMaxRows} valueLabel="HRmax" />
        </section>
      )}

      {/* Training zones */}
      {zones.length > 0 && (
        <section>
          <h2 className="text-lg font-bold text-white mb-1">Your 5 training zones</h2>
          <p className="text-sm text-zinc-400 mb-4">
            {restHrNum
              ? 'Computed via Karvonen heart-rate reserve using your resting HR.'
              : 'Computed as percentages of HRmax. Add resting HR above for Karvonen zones.'}
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {zones.map((z) => (
              <div
                key={z.zone}
                className={`rounded-2xl border p-4 ${ZONE_TINT[z.zone] ?? 'bg-zinc-900 border-zinc-800'}`}
              >
                <div className="flex items-baseline justify-between gap-3 mb-1">
                  <div>
                    <span className="text-xs font-mono text-zinc-400">Zone {z.zone}</span>
                    <h3 className="text-base font-bold text-white">{z.name}</h3>
                  </div>
                  <span className="font-mono font-semibold text-white whitespace-nowrap">
                    {z.low} - {z.high} bpm
                  </span>
                </div>
                <p className="text-xs text-zinc-400 leading-relaxed">{z.description}</p>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Install CTA */}
      <InstallCta
        slug="target-heart-rate-calculator"
        result={{ age, sex, restHr: restHrNum, zones }}
        primary="Get real-time zone alerts during cardio in Zealova"
        secondary="Connect your watch and Zealova vibrates when you drift out of your target zone."
      />

      {/* Methodology */}
      <MethodologyFooter
        citations={[
          {
            text: 'Fox SM, Naughton JP, Haskell WL (1971). Physical activity and the prevention of coronary heart disease. Annals of Clinical Research 3(6):404-432.',
          },
          {
            text: 'Tanaka H, Monahan KD, Seals DR (2001). Age-predicted maximal heart rate revisited. Journal of the American College of Cardiology 37(1):153-156.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/11153730/',
          },
          {
            text: 'Gulati M, Shaw LJ, Thisted RA, Black HR, Bairey Merz CN, Arnsdorf MF (2010). Heart rate response to exercise stress testing in asymptomatic women. Circulation 122(2):130-137.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/20585008/',
          },
          {
            text: 'Karvonen MJ, Kentala E, Mustala O (1957). The effects of training on heart rate. Annales Medicinae Experimentalis et Biologiae Fenniae 35(3):307-315.',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
