// /tools/adaptive-calorie-calculator

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import { calculateAdaptiveCalories } from '../../lib/calc/adaptiveCalories';
import { type WeightUnit, lbToKg, kgToLb, round } from '../../lib/calc/units';

export default function AdaptiveCalorieCalculator() {
  const [unit, setUnit] = useState<WeightUnit>('lb');
  const [avgCalories, setAvgCalories] = useState<number | ''>(2400);
  const [weightStart, setWeightStart] = useState<number | ''>(180);
  const [weightToday, setWeightToday] = useState<number | ''>(179.1);
  const [goalChange, setGoalChange] = useState<number | ''>(-1);  // signed, lb/wk or kg/wk
  const [assumedTdee, setAssumedTdee] = useState<number | ''>(2900);

  const result = useMemo(() => {
    if (typeof avgCalories !== 'number' || typeof weightStart !== 'number' || typeof weightToday !== 'number' || typeof goalChange !== 'number') {
      return null;
    }
    const startKg = unit === 'lb' ? lbToKg(weightStart) : weightStart;
    const todayKg = unit === 'lb' ? lbToKg(weightToday) : weightToday;
    const goalKg = unit === 'lb' ? lbToKg(goalChange) : goalChange;
    return calculateAdaptiveCalories({
      avgDailyCalories: avgCalories,
      weight7DaysAgoKg: startKg,
      weightTodayKg: todayKg,
      goalWeeklyChangeKg: goalKg,
      assumedTdee: typeof assumedTdee === 'number' ? assumedTdee : undefined,
    });
  }, [avgCalories, weightStart, weightToday, goalChange, assumedTdee, unit]);

  const displayChange = (kg: number) => {
    const v = unit === 'lb' ? kgToLb(kg) : kg;
    const sign = v >= 0 ? '+' : '';
    return `${sign}${round(v, 2)} ${unit}`;
  };

  return (
    <CalculatorShell
      slug="adaptive-calorie-calculator"
      title="Adaptive Calorie Calculator"
      metaDescription="Recalculate your true TDEE from 7 days of actual food intake and weight change. Break plateaus with math, not guesswork. Free."
      intro="Predictive TDEE equations have a ±300 kcal error per person. The only way to know your real maintenance is to measure energy in versus weight change out. Enter 7 days of data and we will tell you what you actually burn."
      faqs={[
        {
          q: 'Why does my TDEE keep changing?',
          a: 'NEAT (non-exercise activity) is the largest variable in daily energy expenditure, and it adapts. As you lose weight your body moves less, fidgets less, and burns slightly less per step. BMR also drops in proportion to lost mass. A TDEE that was correct in week 1 is often 100 to 200 kcal too high by week 6.',
        },
        {
          q: 'What is metabolic adaptation?',
          a: 'Beyond the predictable drops in BMR and NEAT, prolonged dieting triggers further adaptive thermogenesis: thyroid hormones decline, sympathetic tone drops, and leptin falls. This adds another 5 to 15% reduction in daily energy expenditure beyond what BMR equations predict. It is reversible with diet breaks and refeeds.',
        },
        {
          q: 'How accurate is this with 7 days of data?',
          a: 'Accurate enough to outperform any predictive equation. A 7-day rolling window filters most water-weight noise. For best results weigh in at the same time of day, in the same conditions, for the full 7 days. Track every calorie honestly. The math is only as good as your inputs.',
        },
        {
          q: 'What if my weight went the wrong direction?',
          a: 'That is exactly what this calculator was built for. If you gained weight while in what should have been a deficit, your assumed TDEE was wrong. The new target accounts for the real number and gets you back on trajectory.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <div className="flex justify-between items-center mb-6 flex-wrap gap-3">
          <h2 className="text-lg font-bold text-white">Last 7 days</h2>
          <UnitToggle value={unit} options={[{ value: 'lb', label: 'lb' }, { value: 'kg', label: 'kg' }]} onChange={setUnit} />
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <NumberInput label="Average daily calories (last 7 days)" value={avgCalories} onChange={setAvgCalories} unit="kcal" min={800} max={6000} step={10} />
          <NumberInput label="Weight 7 days ago" value={weightStart} onChange={setWeightStart} unit={unit} min={1} step={0.1} />
          <NumberInput label="Weight today" value={weightToday} onChange={setWeightToday} unit={unit} min={1} step={0.1} />
          <NumberInput label="Goal weekly change" value={goalChange} onChange={setGoalChange} unit={`${unit}/wk`} step={0.1} help="Negative for cut, positive for bulk" />
          <NumberInput label="Previously assumed TDEE (optional)" value={assumedTdee} onChange={setAssumedTdee} unit="kcal" min={1000} max={6000} step={10} help="What you thought your TDEE was" />
        </div>
      </section>

      {result && (
        <section>
          <h2 className="text-lg font-bold text-white mb-4">Your numbers</h2>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <StatCard label="Actual weekly change" value={displayChange(result.actualWeightChange)} sub={`${result.actualEnergyBalance >= 0 ? '+' : ''}${result.actualEnergyBalance} kcal/day balance`} />
            <StatCard label="True maintenance" value={`${result.trueMaintenance} kcal`} sub={result.previousAssumedTdee !== null ? `You assumed ${result.previousAssumedTdee} kcal` : 'Use this as your new TDEE'} highlight />
            <StatCard label="New daily target" value={`${result.newDailyTarget} kcal`} sub={`To hit ${displayChange(result.expectedWeeklyChange)} per week`} />
          </div>
          <p className="mt-4 text-sm text-emerald-300 bg-emerald-950/30 border border-emerald-500/20 rounded-xl px-4 py-3">
            {result.note}
          </p>
        </section>
      )}

      <InstallCta
        slug="adaptive-calorie-calculator"
        result={result ? { ...result } as Record<string, unknown> : undefined}
        primary="Get this recalculation every Sunday in Zealova, automatic"
        secondary="We pull your week of food log entries and weigh-ins, run the math, and push the updated calorie target into your plan."
      />

      <MethodologyFooter
        citations={[
          { text: 'Hall KD (2007). Body fat and fat-free mass inter-relationships: Forbes\'s theory revisited. NEJM 357:1611.', url: 'https://www.nejm.org/doi/full/10.1056/NEJMc072781' },
          { text: 'Hall KD (2008). What is the required energy deficit per unit weight loss? Int J Obes 32(3):573-6.', url: 'https://pubmed.ncbi.nlm.nih.gov/17848938/' },
          { text: 'Trexler ET, Smith-Ryan AE, Norton LE (2014). Metabolic adaptation to weight loss: implications for the athlete. JISSN 11:7.', url: 'https://jissn.biomedcentral.com/articles/10.1186/1550-2783-11-7' },
          { text: 'Frankenfield D et al. (2005). Comparison of predictive equations for resting metabolic rate. J Am Diet Assoc 105(5):775-89.', url: 'https://pubmed.ncbi.nlm.nih.gov/15883556/' },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}

function StatCard({ label, value, sub, highlight }: { label: string; value: string; sub: string; highlight?: boolean }) {
  return (
    <div className={`rounded-2xl border p-4 ${highlight ? 'bg-emerald-500/10 border-emerald-500/30' : 'bg-zinc-900 border-zinc-800'}`}>
      <p className="text-xs uppercase tracking-wide font-semibold text-zinc-400">{label}</p>
      <p className={`text-2xl sm:text-3xl font-bold mt-1 ${highlight ? 'text-emerald-300' : 'text-white'}`}>{value}</p>
      <p className="text-xs text-zinc-500 mt-1">{sub}</p>
    </div>
  );
}
