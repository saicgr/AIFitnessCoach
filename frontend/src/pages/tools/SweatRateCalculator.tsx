// /tools/sweat-rate-calculator
//
// Sweat rate via pre/post weight + fluid intake. ACSM 2007 fluid replacement
// protocol. Returns L/hr, recommended replacement, and electrolyte warning.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import ResultsTable, { type ResultRow } from '../../components/tools/ResultsTable';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import { calculateSweatRate } from '../../lib/calc/sweatRate';
import type { WeightUnit } from '../../lib/calc/units';

type FluidUnit = 'L' | 'oz';

const OZ_PER_L = 33.814;

export default function SweatRateCalculator() {
  const [preWeight, setPreWeight] = useState<number | ''>(170);
  const [postWeight, setPostWeight] = useState<number | ''>(168);
  const [weightUnit, setWeightUnit] = useState<WeightUnit>('lb');

  const [fluid, setFluid] = useState<number | ''>(16);
  const [fluidUnit, setFluidUnit] = useState<FluidUnit>('oz');

  const [duration, setDuration] = useState<number | ''>(60);

  const result = useMemo(() => {
    if (
      typeof preWeight !== 'number' ||
      typeof postWeight !== 'number' ||
      typeof fluid !== 'number' ||
      typeof duration !== 'number'
    ) {
      return null;
    }
    const fluidL = fluidUnit === 'oz' ? fluid / OZ_PER_L : fluid;
    return calculateSweatRate({
      preWeight,
      postWeight,
      weightUnit,
      fluidIntakeL: fluidL,
      durationMin: duration,
    });
  }, [preWeight, postWeight, weightUnit, fluid, fluidUnit, duration]);

  const displayFluid = (l: number) =>
    fluidUnit === 'oz' ? `${(l * OZ_PER_L).toFixed(1)} oz` : `${l.toFixed(2)} L`;

  const tableRows: ResultRow[] = result
    ? [
        {
          name: 'Sweat rate',
          value: `${result.sweatRateLPerHr} L/hr`,
          note: result.classification,
          recommended: true,
        },
        {
          name: 'Total sweat loss',
          value: displayFluid(result.totalSweatLossL),
          note: 'Body water lost during the session.',
        },
        {
          name: 'Recommended replacement',
          value: displayFluid(result.recommendedReplaceL),
          note: 'Drink within 4-6 hours post-session.',
        },
        {
          name: 'Electrolytes needed?',
          value: result.needsElectrolytes ? 'Yes' : 'Not required',
          note: result.needsElectrolytes
            ? 'High sweat rate plus long session. Add sodium 300-700 mg per liter.'
            : 'Water alone is sufficient for this session length and rate.',
        },
      ]
    : [];

  return (
    <CalculatorShell
      slug="sweat-rate-calculator"
      title="Sweat Rate Calculator"
      metaDescription="Calculate your sweat rate in L/hr from pre and post workout weight. Free sweat rate and hydration calculator built on the ACSM 2007 fluid replacement protocol."
      intro="Weigh in before and after your workout, then enter how much you drank. We compute sweat rate in liters per hour and tell you exactly how much to replace."
      faqs={[
        {
          q: 'Why electrolytes for long workouts?',
          a: 'Sweat carries sodium (around 1 gram per liter on average). When you replace heavy fluid losses with plain water across a session over 2 hours, blood sodium drops. That causes exercise-associated hyponatremia, which feels like nausea and confusion and can be dangerous. Adding 300-700 mg sodium per liter prevents the dilution.',
        },
        {
          q: 'How often should I weigh?',
          a: 'For a single sweat-rate baseline, weigh before and after one representative session. To dial in long-term hydration, repeat the measurement across different conditions (hot vs cool, indoor vs outdoor, easy vs intense) and track the spread. Sweat rate changes with heat acclimation, fitness level, and humidity.',
        },
        {
          q: 'What is a high sweat rate?',
          a: 'Under 0.5 L/hr is low, 0.5-1.0 L/hr is moderate, 1.0-1.5 L/hr is high, and above 1.5 L/hr is very high. Endurance athletes in hot conditions routinely hit 1.5-2.5 L/hr. Heavily acclimated marathoners can exceed 3 L/hr in race conditions.',
        },
      ]}
    >
      {/* Inputs */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8 space-y-6">
        <div className="flex justify-between items-center flex-wrap gap-3">
          <h2 className="text-lg font-bold text-white">Your session</h2>
          <UnitToggle
            value={weightUnit}
            options={[
              { value: 'lb', label: 'lb' },
              { value: 'kg', label: 'kg' },
            ]}
            onChange={setWeightUnit}
            label="Weight"
          />
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <NumberInput
            label="Pre-workout weight"
            value={preWeight}
            onChange={setPreWeight}
            unit={weightUnit}
            min={20}
            step={0.1}
            placeholder="170"
          />
          <NumberInput
            label="Post-workout weight"
            value={postWeight}
            onChange={setPostWeight}
            unit={weightUnit}
            min={20}
            step={0.1}
            placeholder="168"
            help="Towel-dry first. Same scale, same clothing (or none)."
          />
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <NumberInput
              label="Fluid consumed during workout"
              value={fluid}
              onChange={setFluid}
              unit={fluidUnit}
              min={0}
              step={fluidUnit === 'oz' ? 1 : 0.05}
              placeholder={fluidUnit === 'oz' ? '16' : '0.5'}
            />
            <div className="mt-2">
              <UnitToggle
                value={fluidUnit}
                options={[
                  { value: 'oz', label: 'oz' },
                  { value: 'L', label: 'L' },
                ]}
                onChange={setFluidUnit}
              />
            </div>
          </div>
          <NumberInput
            label="Workout duration"
            value={duration}
            onChange={setDuration}
            unit="min"
            min={1}
            max={600}
            step={5}
            placeholder="60"
          />
        </div>
      </section>

      {/* Results */}
      {result && (
        <section>
          <h2 className="text-lg font-bold text-white mb-1">Your sweat rate</h2>
          <p className="text-sm text-zinc-400 mb-4">
            Based on the ACSM 2007 fluid replacement protocol.
          </p>
          <ResultsTable rows={tableRows} valueLabel="Value" />
          {result.notes.length > 0 && (
            <ul className="mt-4 space-y-2 text-sm text-zinc-400">
              {result.notes.map((n, i) => (
                <li key={i} className="flex gap-2">
                  <span className="text-emerald-500 mt-0.5">•</span>
                  <span>{n}</span>
                </li>
              ))}
            </ul>
          )}
        </section>
      )}

      {/* Install CTA */}
      <InstallCta
        slug="sweat-rate-calculator"
        result={
          result
            ? {
                sweatRateLPerHr: result.sweatRateLPerHr,
                recommendedReplaceL: result.recommendedReplaceL,
                durationMin: duration,
              }
            : undefined
        }
        primary="Log workouts and get personalized hydration reminders"
        secondary="Zealova learns your sweat rate across sessions and pings you with replacement targets before your next workout."
      />

      {/* Methodology */}
      <MethodologyFooter
        citations={[
          {
            text: 'Sawka MN, Burke LM, Eichner ER, Maughan RJ, Montain SJ, Stachenfeld NS (2007). American College of Sports Medicine position stand. Exercise and fluid replacement. Medicine and Science in Sports and Exercise 39(2):377-390.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/17277604/',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
