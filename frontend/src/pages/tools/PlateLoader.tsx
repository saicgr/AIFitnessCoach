// /tools/plate-loader
//
// Given a target barbell weight, bar weight, and plate inventory, shows the
// optimal per-side plate combination. Math from lib/calc/plateLoader.ts.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import {
  loadPlates,
  PLATES_LB,
  PLATES_KG,
  PLATES_LB_WITH_FRACTIONAL,
  PLATES_KG_WITH_FRACTIONAL,
  BAR_LB,
  BAR_KG,
} from '../../lib/calc/plateLoader';
import { type WeightUnit, round } from '../../lib/calc/units';

// Visual plate styling. Diameter and color per denomination (US gym standard).
function plateStyle(plate: number, unit: WeightUnit): { color: string; size: string; text: string } {
  if (unit === 'lb') {
    if (plate >= 45) return { color: 'bg-blue-600 border-blue-700', size: 'h-32 w-8', text: 'text-white' };
    if (plate >= 35) return { color: 'bg-yellow-500 border-yellow-600', size: 'h-28 w-7', text: 'text-zinc-900' };
    if (plate >= 25) return { color: 'bg-emerald-600 border-emerald-700', size: 'h-24 w-6', text: 'text-white' };
    if (plate >= 15) return { color: 'bg-orange-500 border-orange-600', size: 'h-20 w-5', text: 'text-white' };
    if (plate >= 10) return { color: 'bg-zinc-700 border-zinc-800', size: 'h-16 w-5', text: 'text-white' };
    if (plate >= 5) return { color: 'bg-zinc-600 border-zinc-700', size: 'h-12 w-4', text: 'text-white' };
    return { color: 'bg-zinc-500 border-zinc-600', size: 'h-10 w-3', text: 'text-white' };
  }
  // kg colors (IPF standard)
  if (plate >= 25) return { color: 'bg-red-600 border-red-700', size: 'h-32 w-8', text: 'text-white' };
  if (plate >= 20) return { color: 'bg-blue-600 border-blue-700', size: 'h-28 w-7', text: 'text-white' };
  if (plate >= 15) return { color: 'bg-yellow-500 border-yellow-600', size: 'h-24 w-6', text: 'text-zinc-900' };
  if (plate >= 10) return { color: 'bg-emerald-600 border-emerald-700', size: 'h-20 w-5', text: 'text-white' };
  if (plate >= 5) return { color: 'bg-zinc-300 border-zinc-400', size: 'h-16 w-4', text: 'text-zinc-900' };
  if (plate >= 2.5) return { color: 'bg-zinc-500 border-zinc-600', size: 'h-12 w-3', text: 'text-white' };
  return { color: 'bg-zinc-400 border-zinc-500', size: 'h-10 w-3', text: 'text-zinc-900' };
}

export default function PlateLoader() {
  const [unit, setUnit] = useState<WeightUnit>('lb');
  const [target, setTarget] = useState<number | ''>(225);
  const [bar, setBar] = useState<number | ''>(45);
  const [includeFractional, setIncludeFractional] = useState(false);

  // Reset defaults when unit changes
  const handleUnitChange = (u: WeightUnit) => {
    setUnit(u);
    if (u === 'kg') {
      setBar(BAR_KG);
      setTarget(100);
    } else {
      setBar(BAR_LB);
      setTarget(225);
    }
  };

  const plates = useMemo(() => {
    if (unit === 'lb') return includeFractional ? PLATES_LB_WITH_FRACTIONAL : PLATES_LB;
    return includeFractional ? PLATES_KG_WITH_FRACTIONAL : PLATES_KG;
  }, [unit, includeFractional]);

  const result = useMemo(() => {
    if (typeof target !== 'number' || typeof bar !== 'number') return null;
    return loadPlates(target, bar, plates);
  }, [target, bar, plates]);

  // Count plates by denomination for the "use" summary
  const plateCounts = useMemo(() => {
    if (!result) return [];
    const counts = new Map<number, number>();
    for (const p of result.perSide) counts.set(p, (counts.get(p) ?? 0) + 1);
    return Array.from(counts.entries()).sort((a, b) => b[0] - a[0]);
  }, [result]);

  return (
    <CalculatorShell
      slug="plate-loader"
      title="Barbell Plate Loader"
      metaDescription="Free barbell plate loader. Enter a target weight and we show the exact plates to load on each side using a standard lb or kg inventory."
      intro="Tell me what you're loading and I'll show you the exact stack per side. Works with the standard US 45 lb set and standard IPF 25 kg set, with optional fractional change plates for precise progressions."
      faqs={[
        {
          q: "What if I'm short on plates?",
          a: 'If the math leaves a remainder we show it so you can decide: drop the weight to the next loadable number, or add a fractional plate. Most home gyms benefit from a pair of 2.5 lb or 1.25 kg change plates to hit any target.',
        },
        {
          q: 'Do you support fractional plates?',
          a: 'Yes. Toggle the fractional option to include 0.25, 0.5, and 1.25 lb / kg plates in the inventory. Recommended for press and accessory progression where 2.5 lb jumps are too aggressive.',
        },
        {
          q: 'Why is my answer different from what is on the bar?',
          a: 'Two common causes: your bar is not the standard 45 lb / 20 kg weight (women\'s bars are 35 lb / 15 kg, technique bars are lighter), or you have collars. Most spring collars weigh less than a pound; competition collars are 2.5 kg each.',
        },
        {
          q: 'Does this work for trap bars and specialty bars?',
          a: 'Set the bar weight manually. Trap bars range from 45 to 75 lb. Safety squat bars are typically 60 to 70 lb. Cambered bars vary widely. Check yours before loading.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <div className="flex justify-between items-center mb-6 flex-wrap gap-3">
          <h2 className="text-lg font-bold text-white">Your bar</h2>
          <UnitToggle
            value={unit}
            options={[
              { value: 'lb', label: 'lb' },
              { value: 'kg', label: 'kg' },
            ]}
            onChange={handleUnitChange}
          />
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <NumberInput
            label="Target weight"
            value={target}
            onChange={setTarget}
            unit={unit}
            min={0}
            step={unit === 'lb' ? 5 : 2.5}
          />
          <NumberInput
            label="Bar weight"
            value={bar}
            onChange={setBar}
            unit={unit}
            min={0}
            step={unit === 'lb' ? 5 : 2.5}
            help={unit === 'lb' ? "Men's: 45 lb. Women's: 35 lb." : "Men's: 20 kg. Women's: 15 kg."}
          />
        </div>

        <label className="flex items-center gap-3 mt-5 cursor-pointer">
          <input
            type="checkbox"
            checked={includeFractional}
            onChange={(e) => setIncludeFractional(e.target.checked)}
            className="w-4 h-4 accent-emerald-500"
          />
          <span className="text-sm text-zinc-300">Include fractional change plates ({unit === 'lb' ? '0.25, 0.5, 1.25 lb' : '0.25, 0.5 kg'})</span>
        </label>
      </section>

      {result && (
        <section>
          <h2 className="text-lg font-bold text-white mb-1">Load each side</h2>
          <p className="text-sm text-zinc-400 mb-4">
            Mirror this stack on both ends of the bar.
          </p>

          {/* Visual bar */}
          <div className="rounded-2xl border border-zinc-800 bg-zinc-950 p-6 sm:p-8 overflow-x-auto">
            <div className="flex items-center justify-center min-w-max">
              {/* Plates */}
              <div className="flex items-center gap-0.5">
                {result.perSide.length === 0 ? (
                  <span className="text-sm text-zinc-500 italic px-4">No plates needed</span>
                ) : (
                  result.perSide.map((p, i) => {
                    const s = plateStyle(p, unit);
                    return (
                      <div
                        key={i}
                        className={`${s.color} ${s.size} rounded-md border-2 flex items-center justify-center`}
                      >
                        <span className={`text-[10px] font-bold ${s.text} -rotate-90 whitespace-nowrap`}>
                          {p}
                        </span>
                      </div>
                    );
                  })
                )}
              </div>
              {/* Sleeve + collar gap */}
              <div className="h-3 w-3 bg-zinc-600" />
              {/* Bar */}
              <div className="h-3 w-32 sm:w-48 bg-gradient-to-r from-zinc-500 to-zinc-400" />
              <div className="h-3 w-3 bg-zinc-600" />
              {/* Plates mirror */}
              <div className="flex items-center gap-0.5">
                {result.perSide.map((p, i) => {
                  const s = plateStyle(p, unit);
                  return (
                    <div
                      key={`r${i}`}
                      className={`${s.color} ${s.size} rounded-md border-2 flex items-center justify-center`}
                    >
                      <span className={`text-[10px] font-bold ${s.text} -rotate-90 whitespace-nowrap`}>
                        {p}
                      </span>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>

          {/* Summary */}
          <div className="mt-4 grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="rounded-xl border border-zinc-800 bg-zinc-900 p-4">
              <p className="text-xs text-zinc-500 uppercase tracking-wide mb-1">Per side</p>
              <div className="space-y-1">
                {plateCounts.length === 0 ? (
                  <p className="text-sm text-zinc-500">Bar only</p>
                ) : (
                  plateCounts.map(([plate, count]) => (
                    <p key={plate} className="text-sm text-white">
                      <span className="font-mono font-semibold">{count}</span>
                      <span className="text-zinc-500"> x </span>
                      <span className="font-mono">{plate} {unit}</span>
                    </p>
                  ))
                )}
              </div>
            </div>
            <div className="rounded-xl border border-zinc-800 bg-zinc-900 p-4">
              <p className="text-xs text-zinc-500 uppercase tracking-wide mb-1">Total loaded</p>
              <p className="text-2xl font-mono font-bold text-white">
                {round(result.loaded, 2)} {unit}
              </p>
              {!result.exact && (
                <p className="text-xs text-orange-400 mt-1">
                  Short {round(result.remaining, 2)} {unit}. Add change plates or drop weight.
                </p>
              )}
            </div>
          </div>
        </section>
      )}

      <InstallCta
        slug="plate-loader"
        result={result ? { target, bar, perSide: result.perSide, loaded: result.loaded } : undefined}
        primary="Save your gym's plate inventory in Zealova"
        secondary="Zealova remembers your bar and plate set, then pre-computes the load for every working set in your program. No mental math on the gym floor."
      />

      <MethodologyFooter
        citations={[
          { text: 'IWF Technical and Competition Rules (2024). Standard barbell and plate specifications.' },
          { text: 'Greedy algorithm. Provably optimal for canonical plate denominations.' },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
