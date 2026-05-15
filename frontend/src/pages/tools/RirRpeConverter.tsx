// /tools/rir-rpe-converter
//
// RIR / RPE / %1RM converter built on the Zourdos 2016 chart. Four modes:
// convert from RPE, convert from RIR, convert from %1RM, calculate target weight.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import ResultsTable, { type ResultRow } from '../../components/tools/ResultsTable';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import {
  REPS_RANGE,
  RPE_PCT_TABLE,
  RPE_VALUES,
  loadFromOneRm,
  pctOfOneRm,
  rirToRpe,
  rpeFromPct,
  rpeToRir,
} from '../../lib/calc/rirRpe';
import type { WeightUnit } from '../../lib/calc/units';
import { round } from '../../lib/calc/units';

type Mode = 'fromRpe' | 'fromRir' | 'fromPct' | 'targetWeight';

const MODE_OPTIONS: { value: Mode; label: string }[] = [
  { value: 'fromRpe', label: 'Convert from RPE' },
  { value: 'fromRir', label: 'Convert from RIR' },
  { value: 'fromPct', label: 'Convert from %1RM' },
  { value: 'targetWeight', label: 'Calculate target weight' },
];

export default function RirRpeConverter() {
  const [mode, setMode] = useState<Mode>('targetWeight');
  const [unit, setUnit] = useState<WeightUnit>('lb');

  const [reps, setReps] = useState<number | ''>(5);
  const [rpe, setRpe] = useState<number | ''>(8);
  const [rir, setRir] = useState<number | ''>(2);
  const [pct, setPct] = useState<number | ''>(80);
  const [oneRm, setOneRm] = useState<number | ''>(315);

  const rows: ResultRow[] = useMemo(() => {
    if (typeof reps !== 'number' || reps < 1 || reps > 12) return [];

    if (mode === 'fromRpe') {
      if (typeof rpe !== 'number') return [];
      const p = pctOfOneRm(reps, rpe);
      if (p == null) return [];
      return [
        { name: 'RPE', value: String(rpe), note: 'Rating of perceived exertion (out of 10).', recommended: true },
        { name: 'RIR', value: String(rpeToRir(rpe)), note: 'Reps left in reserve at this effort.' },
        { name: '% of 1RM', value: `${p}%`, note: 'Per the Zourdos 2016 chart for this rep count.' },
      ];
    }

    if (mode === 'fromRir') {
      if (typeof rir !== 'number') return [];
      const rpeVal = rirToRpe(rir);
      const p = pctOfOneRm(reps, rpeVal);
      if (p == null) return [];
      return [
        { name: 'RIR', value: String(rir), note: 'Reps left in reserve.', recommended: true },
        { name: 'RPE', value: String(rpeVal), note: 'Equivalent rating of perceived exertion.' },
        { name: '% of 1RM', value: `${p}%`, note: 'Per the Zourdos 2016 chart for this rep count.' },
      ];
    }

    if (mode === 'fromPct') {
      if (typeof pct !== 'number') return [];
      const rpeVal = rpeFromPct(reps, pct);
      if (rpeVal == null) return [];
      return [
        { name: '% of 1RM', value: `${pct}%`, note: 'Working weight as a fraction of true 1RM.', recommended: true },
        { name: 'Nearest RPE', value: String(rpeVal), note: 'Closest match in the Zourdos chart.' },
        { name: 'RIR', value: String(rpeToRir(rpeVal)), note: 'Reps left in reserve at this effort.' },
      ];
    }

    // Calculate target weight
    if (typeof oneRm !== 'number' || typeof rpe !== 'number') return [];
    const load = loadFromOneRm(oneRm, reps, rpe);
    const p = pctOfOneRm(reps, rpe);
    if (load == null || p == null) return [];
    return [
      {
        name: 'Target weight',
        value: `${load} ${unit}`,
        note: `${reps} reps at RPE ${rpe} (${rpeToRir(rpe)} RIR).`,
        recommended: true,
      },
      { name: '% of 1RM', value: `${p}%`, note: 'Loading intensity for this prescription.' },
      { name: '1RM used', value: `${oneRm} ${unit}`, note: 'Your supplied one-rep max.' },
    ];
  }, [mode, reps, rpe, rir, pct, oneRm, unit]);

  return (
    <CalculatorShell
      slug="rir-rpe-converter"
      title="RIR / RPE / %1RM Converter"
      metaDescription="Free RIR and RPE converter built on the Zourdos 2016 chart. Convert between RPE, reps in reserve, and percent of 1RM. Calculate target weights for any prescribed effort."
      intro="Convert between RPE, RIR, and percent of 1RM. Or enter your 1RM with a target effort and we compute the exact weight to load."
      faqs={[
        {
          q: 'What is the difference between RIR and RPE?',
          a: 'RIR (reps in reserve) counts how many more reps you could have completed before failure. RPE (rating of perceived exertion) is a 0-10 effort scale where 10 means absolute failure. They map directly: RPE 8 = 2 RIR, RPE 9 = 1 RIR, RPE 10 = 0 RIR. RIR is more concrete for prescription. RPE is more flexible for autoregulation.',
        },
        {
          q: 'Should beginners use RPE?',
          a: 'Not for the first 3-6 months. Novices systematically underestimate effort because they have not trained close enough to failure to know what a true RPE 9 or 10 feels like. Stick with prescribed sets-and-reps at fixed percentages until you have hit at least one true rep-max. Then layer RPE on top.',
        },
        {
          q: 'How accurate is RPE for hypertrophy work?',
          a: 'Self-reported RPE in 8-15 rep sets is reliably off by 1-2 reps versus actual failure, especially for lower-body movements and untrained lifters. For hypertrophy, that error is acceptable. For strength work in the 1-5 rep range, RPE accuracy improves substantially with experience.',
        },
      ]}
    >
      {/* Mode picker */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <div className="flex flex-wrap justify-between items-center gap-3 mb-6">
          <h2 className="text-lg font-bold text-white">What do you want to convert?</h2>
          {mode === 'targetWeight' && (
            <UnitToggle
              value={unit}
              options={[
                { value: 'lb', label: 'lb' },
                { value: 'kg', label: 'kg' },
              ]}
              onChange={setUnit}
            />
          )}
        </div>
        <div className="flex flex-wrap gap-2 mb-6">
          {MODE_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              type="button"
              onClick={() => setMode(opt.value)}
              className={`px-3 py-2 rounded-lg text-sm font-medium transition ${
                mode === opt.value
                  ? 'bg-emerald-500 text-zinc-900'
                  : 'bg-zinc-800 text-zinc-300 hover:bg-zinc-700'
              }`}
            >
              {opt.label}
            </button>
          ))}
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <NumberInput
            label="Reps"
            value={reps}
            onChange={setReps}
            min={1}
            max={12}
            step={1}
            placeholder="5"
            help="The Zourdos chart covers 1-12 reps."
          />

          {mode === 'fromRpe' && (
            <NumberInput
              label="RPE"
              value={rpe}
              onChange={setRpe}
              min={5}
              max={10}
              step={0.5}
              placeholder="8"
            />
          )}

          {mode === 'fromRir' && (
            <NumberInput
              label="RIR (reps in reserve)"
              value={rir}
              onChange={setRir}
              min={0}
              max={5}
              step={1}
              placeholder="2"
            />
          )}

          {mode === 'fromPct' && (
            <NumberInput
              label="% of 1RM"
              value={pct}
              onChange={setPct}
              unit="%"
              min={50}
              max={100}
              step={1}
              placeholder="80"
            />
          )}

          {mode === 'targetWeight' && (
            <NumberInput
              label="Your 1RM"
              value={oneRm}
              onChange={setOneRm}
              unit={unit}
              min={1}
              step={2.5}
              placeholder="315"
            />
          )}
        </div>

        {mode === 'targetWeight' && (
          <div className="mt-4">
            <NumberInput
              label="Target RPE"
              value={rpe}
              onChange={setRpe}
              min={5}
              max={10}
              step={0.5}
              placeholder="8"
              help="RPE 8 leaves 2 reps in reserve. RPE 10 is failure."
            />
          </div>
        )}
      </section>

      {/* Results */}
      {rows.length > 0 && (
        <section>
          <h2 className="text-lg font-bold text-white mb-4">Result</h2>
          <ResultsTable rows={rows} valueLabel="Value" />
        </section>
      )}

      {/* Zourdos chart reference */}
      <section>
        <h2 className="text-lg font-bold text-white mb-1">Zourdos 2016 RPE chart</h2>
        <p className="text-sm text-zinc-400 mb-4">
          Each cell is the percent of 1RM you can lift for that many reps at that RPE.
        </p>
        <div className="overflow-x-auto rounded-2xl border border-zinc-800">
          <table className="w-full text-xs sm:text-sm">
            <thead className="bg-zinc-900 border-b border-zinc-800">
              <tr>
                <th className="text-left px-3 py-3 font-semibold text-zinc-300">RPE</th>
                {REPS_RANGE.map((r) => (
                  <th key={r} className="text-right px-3 py-3 font-semibold text-zinc-300">{r}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {RPE_VALUES.map((rpeRow) => (
                <tr key={rpeRow} className="border-b border-zinc-800 last:border-b-0 bg-zinc-950">
                  <td className="px-3 py-2 font-mono font-semibold text-white">{rpeRow}</td>
                  {REPS_RANGE.map((r) => {
                    const v = RPE_PCT_TABLE[rpeRow]?.[r];
                    return (
                      <td key={r} className="px-3 py-2 text-right font-mono text-zinc-300">
                        {typeof v === 'number' ? `${round(v, 1)}%` : '-'}
                      </td>
                    );
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <p className="text-xs text-zinc-500 mt-3">
          Row labels are RPE. Column labels are reps. RIR = 10 - RPE.
        </p>
      </section>

      {/* Install CTA */}
      <InstallCta
        slug="rir-rpe-converter"
        result={{ mode, reps, rpe, rir, pct, oneRm, unit }}
        primary="Log every set with RPE in Zealova and get smarter load suggestions"
        secondary="Zealova tracks your RPE-to-load curve across every lift and adjusts next week's weights automatically."
      />

      {/* Methodology */}
      <MethodologyFooter
        citations={[
          {
            text: 'Zourdos MC, Klemp A, Dolan C, Quiles JM, Schau KA, Jo E, Helms E, Esgro B, Duncan S, Garcia Merino S, Blanco R (2016). Novel resistance training-specific rating of perceived exertion scale measuring repetitions in reserve. Journal of Strength and Conditioning Research 30(1):267-275.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/26049792/',
          },
          {
            text: 'Helms ER, Brown SR, Cross MR, Storey A, Cronin J, Zourdos MC (2018). Self-rated accuracy of rating of perceived exertion-based load prescription in powerlifters. Journal of Strength and Conditioning Research 32(8):2278-2288.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/29742752/',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
