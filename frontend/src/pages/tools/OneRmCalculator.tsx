// /tools/1rm-calculator
//
// Reference implementation for all 26+ calculator pages. Future calc pages
// should follow this structure:
//   1. Local state for inputs
//   2. Pure-function math from frontend/src/lib/calc/
//   3. Results table from <ResultsTable>
//   4. Method explanation cards
//   5. InstallCta with calc-specific copy
//   6. Methodology citations
//
// Anything that diverges from this pattern needs justification.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import ResultsTable, { type ResultRow } from '../../components/tools/ResultsTable';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import {
  calculateAllOneRm,
  recommendedFormula,
  REP_PERCENTAGE_TABLE,
  repsAtPercent,
} from '../../lib/calc/oneRm';
import type { WeightUnit } from '../../lib/calc/units';
import { round } from '../../lib/calc/units';

export default function OneRmCalculator() {
  const [weight, setWeight] = useState<number | ''>(225);
  const [reps, setReps] = useState<number | ''>(5);
  const [unit, setUnit] = useState<WeightUnit>('lb');

  const results = useMemo(() => {
    if (typeof weight !== 'number' || typeof reps !== 'number') return [];
    return calculateAllOneRm(weight, reps);
  }, [weight, reps]);

  const recommended = typeof reps === 'number' ? recommendedFormula(reps) : null;

  const tableRows: ResultRow[] = results.map((r) => ({
    name: r.name,
    value: `${r.value} ${unit}`,
    note: r.bestFor,
    recommended: r.formula === recommended,
  }));

  // Use Epley value (most popular default) for the percentage chart.
  const epleyResult = results.find((r) => r.formula === 'epley');
  const epleyOneRm = epleyResult?.value ?? 0;

  return (
    <CalculatorShell
      slug="1rm-calculator"
      title="1RM Calculator"
      metaDescription="Estimate your one-rep max from any submaximal set using all 7 major formulas (Epley, Brzycki, Lombardi, Lander, O'Connor, Mayhew, Wathen) side-by-side. Free 1RM calculator."
      intro="Enter the weight you lifted and how many reps you completed. We'll show you what every major 1RM formula predicts, side-by-side, so you can pick the most accurate one for your rep range."
      faqs={[
        {
          q: 'Which 1RM formula is most accurate?',
          a: 'It depends on the rep range. Brzycki is most accurate for low reps (2-5). Epley works well for moderate reps (5-10). Above 10 reps, all formulas lose accuracy because muscular endurance becomes a larger factor than maximal strength. We highlight the recommended formula for your rep count.',
        },
        {
          q: 'How many reps should I use for the most accurate estimate?',
          a: 'Between 3 and 6 reps gives the most accurate prediction. Above 10 reps, error rates climb significantly. For your competition lifts, performing a true 1RM attempt is still the gold standard.',
        },
        {
          q: 'Can I use this for all exercises?',
          a: 'Yes, but accuracy varies. The formulas were originally validated on bench press and similar barbell lifts. They work reasonably well for squat, deadlift, overhead press, and most compound lifts. Single-joint and machine exercises produce less reliable estimates.',
        },
        {
          q: 'Why do different formulas give different results?',
          a: 'Each formula was developed from a different study population (often college athletes) and a specific exercise. The differences across formulas reflect those original samples, not which one is "right" in an absolute sense. Looking at the range across formulas gives you a confidence interval rather than a single point estimate.',
        },
      ]}
    >
      {/* Inputs */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <div className="flex justify-between items-center mb-6 flex-wrap gap-3">
          <h2 className="text-lg font-bold text-white">Your set</h2>
          <UnitToggle
            value={unit}
            options={[
              { value: 'lb', label: 'lb' },
              { value: 'kg', label: 'kg' },
            ]}
            onChange={setUnit}
          />
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <NumberInput
            label="Weight lifted"
            value={weight}
            onChange={setWeight}
            unit={unit}
            min={1}
            step={2.5}
            placeholder="225"
          />
          <NumberInput
            label="Reps completed"
            value={reps}
            onChange={setReps}
            min={1}
            max={20}
            step={1}
            placeholder="5"
            help="2-10 reps gives the most accurate estimate"
          />
        </div>
      </section>

      {/* Results */}
      {results.length > 0 && (
        <section>
          <h2 className="text-lg font-bold text-white mb-1">Estimated 1RM</h2>
          <p className="text-sm text-zinc-400 mb-4">
            All 7 formulas compared. The recommended formula for your rep count is highlighted.
          </p>
          <ResultsTable rows={tableRows} valueLabel="1RM" />
        </section>
      )}

      {/* Percentage chart */}
      {epleyOneRm > 0 && (
        <section>
          <h2 className="text-lg font-bold text-white mb-1">% of 1RM chart</h2>
          <p className="text-sm text-zinc-400 mb-4">
            Working sets at common training percentages, based on Epley estimate of {round(epleyOneRm, 0)} {unit}.
          </p>
          <div className="overflow-x-auto rounded-2xl border border-zinc-800">
            <table className="w-full text-sm">
              <thead className="bg-zinc-900 border-b border-zinc-800">
                <tr>
                  <th className="text-left px-4 py-3 font-semibold text-zinc-300">Target reps</th>
                  <th className="text-right px-4 py-3 font-semibold text-zinc-300">% of 1RM</th>
                  <th className="text-right px-4 py-3 font-semibold text-zinc-300">Weight ({unit})</th>
                </tr>
              </thead>
              <tbody>
                {REP_PERCENTAGE_TABLE.map((row) => (
                  <tr key={row.reps} className="border-b border-zinc-800 last:border-b-0 bg-zinc-950">
                    <td className="px-4 py-2.5 text-white">{row.reps}</td>
                    <td className="px-4 py-2.5 text-right font-mono text-zinc-300">{row.pct}%</td>
                    <td className="px-4 py-2.5 text-right font-mono font-semibold text-white">
                      {repsAtPercent(epleyOneRm, row.pct)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}

      {/* Install CTA */}
      <InstallCta
        slug="1rm-calculator"
        result={{ weight, reps, unit, oneRm: epleyOneRm }}
        primary="Track your 1RM progress over time"
        secondary="Zealova logs every set, calculates an updated 1RM after each workout, and adjusts your next plan around the new number."
      />

      {/* Methodology */}
      <MethodologyFooter
        citations={[
          { text: 'Epley B (1985). Poundage Chart. Boyd Epley Workout, Lincoln, NE.' },
          { text: 'Brzycki M (1993). Strength testing: predicting a one-rep max. JOPERD 64(1).', url: 'https://www.tandfonline.com/doi/abs/10.1080/07303084.1993.10606684' },
          { text: 'Lombardi VP (1989). Beginning Weight Training: The Safe and Effective Way.' },
          { text: 'Wathen D (1994). Load assignment. NSCA Essentials of Strength Training and Conditioning.' },
          { text: 'Mayhew JL et al. (1992). Relative muscular endurance performance as a predictor of bench press strength. JASSR 6(4).', url: 'https://pubmed.ncbi.nlm.nih.gov/19265932/' },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
