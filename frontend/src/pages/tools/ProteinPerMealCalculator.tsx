// /tools/protein-per-meal-calculator

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import { calculateProteinPerMeal, PROTEIN_BANDS } from '../../lib/calc/proteinPerMeal';
import { type WeightUnit, lbToKg } from '../../lib/calc/units';

export default function ProteinPerMealCalculator() {
  const [unit, setUnit] = useState<WeightUnit>('lb');
  const [totalProtein, setTotalProtein] = useState<number | ''>(180);
  const [meals, setMeals] = useState<number | ''>(4);
  const [bodyweight, setBodyweight] = useState<number | ''>(180);

  const result = useMemo(() => {
    if (typeof totalProtein !== 'number' || typeof meals !== 'number' || typeof bodyweight !== 'number') return null;
    const bwKg = unit === 'lb' ? lbToKg(bodyweight) : bodyweight;
    return calculateProteinPerMeal({ totalProteinG: totalProtein, meals, bodyweightKg: bwKg });
  }, [totalProtein, meals, bodyweight, unit]);

  return (
    <CalculatorShell
      slug="protein-per-meal-calculator"
      title="Protein-Per-Meal Optimizer"
      metaDescription="Find the optimal protein split per meal to maximize muscle protein synthesis. Based on Schoenfeld & Aragon 2018 research. Free."
      intro="Total daily protein matters, but so does distribution. Each meal should hit 0.4 to 0.55 grams per kilogram of bodyweight to fully trigger muscle protein synthesis. Enter your numbers and we will tell you whether your current split lands in that window."
      faqs={[
        {
          q: 'Is the 40g per meal cap real?',
          a: 'The original 20-30g cap was based on a 2009 Moore study using whey alone after leg exercise. A 2016 Macnaughton trial using whole-body resistance training showed 40g produced a greater MPS response than 20g. The current consensus: 0.4 to 0.55 g/kg per meal is the dose that maximally stimulates MPS. Above that, extra protein still counts toward daily totals but adds little to that meal\'s anabolic response.',
        },
        {
          q: 'Does meal timing actually matter for muscle?',
          a: 'Total daily protein is the dominant variable. Distribution is secondary, but not negligible. The Areta 2013 trial showed 4 meals of 20g each beat 8 meals of 10g or 2 meals of 40g for 24-hour MPS, even when total protein was matched. Spreading protein into 3 to 5 well-dosed meals is a free upgrade if you can do it.',
        },
        {
          q: 'What about pre-sleep protein?',
          a: 'A 30 to 40 gram casein-rich serving before bed extends MPS through the overnight fast. This is one of the rare cases where timing produces a measurable advantage over even distribution. Include it as your last "meal" in this calculator if you eat it.',
        },
        {
          q: 'Does this apply if I am not lifting?',
          a: 'The MPS response is much smaller without resistance training, so per-meal optimization matters less. For sedentary adults, hitting 1.0 to 1.2 g/kg per day in any reasonable distribution is fine.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <div className="flex justify-between items-center mb-6 flex-wrap gap-3">
          <h2 className="text-lg font-bold text-white">Your protein plan</h2>
          <UnitToggle value={unit} options={[{ value: 'lb', label: 'lb' }, { value: 'kg', label: 'kg' }]} onChange={setUnit} />
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <NumberInput label="Total daily protein" value={totalProtein} onChange={setTotalProtein} unit="g" min={20} max={500} step={5} />
          <NumberInput label="Meals per day" value={meals} onChange={setMeals} min={2} max={6} step={1} help="2-6" />
          <NumberInput label="Bodyweight" value={bodyweight} onChange={setBodyweight} unit={unit} min={1} step={0.5} />
        </div>
      </section>

      {result && (
        <>
          <section>
            <h2 className="text-lg font-bold text-white mb-1">Your current split</h2>
            <p className="text-sm text-zinc-400 mb-4">
              {typeof meals === 'number' ? meals : ''} meals at <span className="font-mono text-white">{result.evenSplit[0]?.proteinG} g each</span> ({result.perKgEven} g/kg per meal).
              {result.withinOptimalBand ? ' Sits in the optimal MPS-stimulating range.' : ' Outside the optimal range.'}
            </p>
            <div className={`rounded-2xl border p-4 ${result.withinOptimalBand ? 'bg-emerald-500/10 border-emerald-500/30' : 'bg-amber-500/10 border-amber-500/30'}`}>
              <p className={`text-sm ${result.withinOptimalBand ? 'text-emerald-300' : 'text-amber-300'}`}>
                {result.recommendation}
              </p>
            </div>
          </section>

          <section>
            <h2 className="text-lg font-bold text-white mb-1">Per-meal breakdown</h2>
            <p className="text-sm text-zinc-400 mb-4">
              Optimal band: {PROTEIN_BANDS.leucineThresholdPerKg} to {PROTEIN_BANDS.optimalCapPerKg} g/kg per meal (Schoenfeld & Aragon 2018).
            </p>
            <div className="overflow-x-auto rounded-2xl border border-zinc-800">
              <table className="w-full text-sm">
                <thead className="bg-zinc-900 border-b border-zinc-800">
                  <tr>
                    <th className="text-left px-4 py-3 font-semibold text-zinc-300">Meal</th>
                    <th className="text-right px-4 py-3 font-semibold text-zinc-300">Protein</th>
                    <th className="text-right px-4 py-3 font-semibold text-zinc-300">g/kg</th>
                    <th className="text-center px-4 py-3 font-semibold text-zinc-300">MPS trigger</th>
                  </tr>
                </thead>
                <tbody>
                  {result.evenSplit.map((m) => (
                    <tr key={m.mealNum} className="border-b border-zinc-800 last:border-b-0 bg-zinc-950">
                      <td className="px-4 py-3 font-medium text-white">Meal {m.mealNum}</td>
                      <td className="px-4 py-3 text-right font-mono text-white">{m.proteinG} g</td>
                      <td className="px-4 py-3 text-right font-mono text-zinc-300">{m.perKg}</td>
                      <td className="px-4 py-3 text-center">
                        {m.hitsOptimal ? (
                          <span className="text-emerald-400 text-xs font-semibold">Optimal</span>
                        ) : m.hitsLeucineThreshold ? (
                          <span className="text-amber-400 text-xs font-semibold">Above cap</span>
                        ) : (
                          <span className="text-rose-400 text-xs font-semibold">Below threshold</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>

          {result.cappedSplit && (
            <section>
              <h2 className="text-lg font-bold text-white mb-1">Recommended split</h2>
              <p className="text-sm text-zinc-400 mb-4">
                Capped at 0.55 g/kg per meal. Requires {result.cappedSplit.length} meals.
              </p>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                {result.cappedSplit.map((m) => (
                  <div key={m.mealNum} className="rounded-xl bg-emerald-500/10 border border-emerald-500/30 p-3 text-center">
                    <p className="text-xs text-emerald-400">Meal {m.mealNum}</p>
                    <p className="text-xl font-bold text-white mt-0.5">{m.proteinG}<span className="text-xs text-zinc-400 font-normal"> g</span></p>
                    <p className="text-xs text-zinc-500">{m.perKg} g/kg</p>
                  </div>
                ))}
              </div>
            </section>
          )}
        </>
      )}

      <InstallCta
        slug="protein-per-meal-calculator"
        result={result ? { ...result } as unknown as Record<string, unknown> : undefined}
        primary="Log meals and auto-track if you hit your per-meal target"
        secondary="Zealova flags meals that miss the leucine threshold and suggests easy add-ons (whey, Greek yogurt, egg whites) to bring them into range."
      />

      <MethodologyFooter
        citations={[
          { text: 'Schoenfeld BJ, Aragon AA (2018). How much protein can the body use in a single meal for muscle-building? JISSN 15:10.', url: 'https://jissn.biomedcentral.com/articles/10.1186/s12970-018-0215-1' },
          { text: 'Moore DR et al. (2009). Ingested protein dose response of muscle and albumin protein synthesis. AJCN 89(1):161-8.', url: 'https://pubmed.ncbi.nlm.nih.gov/19056590/' },
          { text: 'Macnaughton LS et al. (2016). The response of muscle protein synthesis following whole-body resistance exercise is greater following 40 g than 20 g of ingested whey protein. Physiol Rep 4(15):e12893.', url: 'https://pubmed.ncbi.nlm.nih.gov/27511985/' },
          { text: 'Areta JL et al. (2013). Timing and distribution of protein ingestion during prolonged recovery from resistance exercise alters myofibrillar protein synthesis. J Physiol 591(9):2319-31.', url: 'https://pubmed.ncbi.nlm.nih.gov/23459753/' },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
