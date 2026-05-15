// /tools/carb-cycling-calculator

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import { calculateCarbCycling, type DayType } from '../../lib/calc/carbCycling';
import { type WeightUnit, lbToKg } from '../../lib/calc/units';

const DAY_COLORS: Record<DayType, string> = {
  high: 'bg-amber-500/10 border-amber-500/30 text-amber-300',
  medium: 'bg-sky-500/10 border-sky-500/30 text-sky-300',
  low: 'bg-zinc-800 border-zinc-700 text-zinc-300',
};

export default function CarbCyclingCalculator() {
  const [unit, setUnit] = useState<WeightUnit>('lb');
  const [bodyweight, setBodyweight] = useState<number | ''>(180);
  const [trainingDays, setTrainingDays] = useState<number | ''>(4);
  const [goal, setGoal] = useState<'cut' | 'maintain'>('cut');

  const result = useMemo(() => {
    if (typeof bodyweight !== 'number' || typeof trainingDays !== 'number') return null;
    const bwKg = unit === 'lb' ? lbToKg(bodyweight) : bodyweight;
    return calculateCarbCycling({ bodyweightKg: bwKg, trainingDaysPerWeek: trainingDays, goal });
  }, [bodyweight, trainingDays, goal, unit]);

  return (
    <CalculatorShell
      slug="carb-cycling-calculator"
      title="Carb Cycling Calculator"
      metaDescription="Calculate high, medium, and low carb day macros matched to your training schedule. Free carb cycling calculator with sample weekly plan."
      intro="Match carb intake to training load. High carbs on heavy days, lower carbs on rest days. Protein stays constant. Fat fills the calorie budget. Here is your weekly plan."
      faqs={[
        {
          q: 'Does carb cycling actually work?',
          a: 'For body composition specifically, no controlled trial has shown carb cycling beats a steady macro split when total weekly calories and protein are matched. What it does well: align carb intake with the days you need them most (heavy training, long cardio), which often improves training quality and adherence. Most lifters find it psychologically easier than a flat low-carb diet.',
        },
        {
          q: 'Why train on high carb days?',
          a: 'Sets of 5 to 15 reps and high-intensity intervals burn muscle glycogen as the dominant fuel. Adequate carbs let you hit your prescribed reps and recover for the next session. Trying to push heavy compound work on a 50 g/day rest-day allocation usually tanks performance.',
        },
        {
          q: 'How is this different from keto?',
          a: 'Keto stays below ~50 g carbs every day. Carb cycling alternates between high-carb training days (300 to 500 g) and low-carb rest days (~80 g). You stay primarily glucose-fueled but you avoid carb intake on days where the body cannot store the glycogen anyway.',
        },
        {
          q: 'What if I train every day?',
          a: 'You will see fewer rest days in the schedule. Most of your week will be high or medium carb. The protein and fat numbers stay the same. If you train hard 7 days a week and you are running a cut, expect to add a deload week every 4 to 6 weeks regardless of how you cycle carbs.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <div className="flex justify-between items-center mb-6 flex-wrap gap-3">
          <h2 className="text-lg font-bold text-white">Your training schedule</h2>
          <UnitToggle value={unit} options={[{ value: 'lb', label: 'lb' }, { value: 'kg', label: 'kg' }]} onChange={setUnit} />
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <NumberInput label="Bodyweight" value={bodyweight} onChange={setBodyweight} unit={unit} min={1} step={0.5} />
          <NumberInput label="Training days per week" value={trainingDays} onChange={setTrainingDays} min={0} max={7} step={1} help="0-7" />
          <label className="block">
            <span className="block text-sm font-medium text-zinc-300 mb-1.5">Goal</span>
            <select value={goal} onChange={(e) => setGoal(e.target.value as 'cut' | 'maintain')} className="w-full px-4 py-3 rounded-xl bg-zinc-900 border border-zinc-700 text-white focus:outline-none focus:ring-2 focus:ring-emerald-500">
              <option value="cut">Cut</option>
              <option value="maintain">Maintain</option>
            </select>
          </label>
        </div>
      </section>

      {result && (
        <>
          <section>
            <h2 className="text-lg font-bold text-white mb-1">Day-type macros</h2>
            <p className="text-sm text-zinc-400 mb-4">
              Weekly carb total: <span className="font-mono text-white">{result.weeklyCarbsG} g</span>. Average daily calories: <span className="font-mono text-white">{result.weeklyCaloriesAvg} kcal</span>.
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              {result.days.map((d) => (
                <div key={d.dayType} className={`rounded-2xl border p-4 ${DAY_COLORS[d.dayType]}`}>
                  <p className="text-xs uppercase tracking-wide font-semibold opacity-80">{d.label}</p>
                  <p className="text-xs text-zinc-400 mt-0.5">{d.daysPerWeek} {d.daysPerWeek === 1 ? 'day' : 'days'} per week</p>
                  <p className="text-3xl font-bold text-white mt-3">{d.calories}<span className="text-sm text-zinc-400 font-normal"> kcal</span></p>
                  <div className="mt-3 space-y-1 text-sm">
                    <div className="flex justify-between"><span className="text-zinc-400">Protein</span><span className="font-mono text-white">{d.proteinG} g</span></div>
                    <div className="flex justify-between"><span className="text-zinc-400">Carbs</span><span className="font-mono text-white">{d.carbsG} g <span className="text-xs text-zinc-500">({d.carbsPerKg} g/kg)</span></span></div>
                    <div className="flex justify-between"><span className="text-zinc-400">Fat</span><span className="font-mono text-white">{d.fatG} g</span></div>
                  </div>
                </div>
              ))}
            </div>
          </section>

          <section>
            <h2 className="text-lg font-bold text-white mb-1">Example weekly schedule</h2>
            <p className="text-sm text-zinc-400 mb-4">
              One way to arrange your week. Adjust to your real training days.
            </p>
            <div className="grid grid-cols-2 sm:grid-cols-7 gap-2">
              {result.exampleSchedule.map((s, i) => {
                const [dayName, label] = s.split(': ');
                const dayType: DayType = label.includes('Heavy') ? 'high' : label.includes('Light') ? 'medium' : 'low';
                return (
                  <div key={i} className={`rounded-xl border p-3 text-center ${DAY_COLORS[dayType]}`}>
                    <p className="text-xs font-bold text-white">{dayName}</p>
                    <p className="text-[10px] mt-1 opacity-80">{label.replace(' day', '')}</p>
                  </div>
                );
              })}
            </div>
          </section>
        </>
      )}

      <InstallCta
        slug="carb-cycling-calculator"
        result={result ? { ...result } as unknown as Record<string, unknown> : undefined}
        primary="Switch macro modes automatically on training vs rest days in Zealova"
        secondary="Your workout plan and your food plan stay in sync. High day on heavy lift days, low day on rest, all automatic."
      />

      <MethodologyFooter
        citations={[
          { text: 'Mata F, Valenzuela PL et al. (2019). Carbohydrate availability and physical performance: practical recommendations. Nutrients 11(5):1084.', url: 'https://www.mdpi.com/2072-6643/11/5/1084' },
          { text: 'Helms ER, Aragon AA, Fitschen PJ (2014). Evidence-based recommendations for natural bodybuilding contest preparation. JISSN 11:20.', url: 'https://jissn.biomedcentral.com/articles/10.1186/1550-2783-11-20' },
          { text: 'Burke LM, Hawley JA et al. (2018). Toward a common understanding of diet-exercise strategies to manipulate fuel availability for training and competition. IJSNEM 28(5):451-463.', url: 'https://pubmed.ncbi.nlm.nih.gov/30260257/' },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
