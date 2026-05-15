// /free-tools/how-to-get-jacked
//
// 16-week hypertrophy plan calculator. Inputs: bodyweight (lb), body-fat %,
// lifting age (months), training days/wk. Output: per-muscle weekly volume
// (MEV/MAV/MRV per Schoenfeld 2017), calorie surplus (200-500 above TDEE),
// protein target (1.6-2.2 g/kg), realistic gain timeline (Lyle McDonald natty
// model), checkpoint weights at week 4/8/12/16.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import ResultHero from '../../components/tools/ResultHero';

// Lyle McDonald's natural muscle-gain model. Annual lean mass added per
// training year for a male natural lifter. Halved for female lifters
// in line with McDonald's original framework.
const MCDONALD_MALE_LB_PER_YEAR = [22, 11, 5, 2];

// Schoenfeld 2017 + RP Mesocycle volume landmarks (sets per muscle per week)
// MV = maintenance, MEV = minimum effective, MAV = maximum adaptive, MRV = max recoverable.
interface VolumeRow {
  muscle: string;
  mv: number;
  mev: number;
  mav: [number, number];
  mrv: number;
}

const VOLUME_LANDMARKS: VolumeRow[] = [
  { muscle: 'Chest', mv: 8, mev: 10, mav: [12, 20], mrv: 22 },
  { muscle: 'Back', mv: 8, mev: 10, mav: [14, 22], mrv: 25 },
  { muscle: 'Shoulders (side delts)', mv: 8, mev: 8, mav: [16, 22], mrv: 26 },
  { muscle: 'Quads', mv: 6, mev: 8, mav: [12, 18], mrv: 20 },
  { muscle: 'Hamstrings', mv: 4, mev: 6, mav: [10, 16], mrv: 20 },
  { muscle: 'Glutes', mv: 0, mev: 4, mav: [8, 16], mrv: 20 },
  { muscle: 'Biceps', mv: 5, mev: 8, mav: [12, 20], mrv: 26 },
  { muscle: 'Triceps', mv: 4, mev: 6, mav: [10, 18], mrv: 22 },
  { muscle: 'Calves', mv: 6, mev: 8, mav: [10, 16], mrv: 20 },
  { muscle: 'Abs', mv: 0, mev: 0, mav: [10, 25], mrv: 30 },
];

const LB_PER_KG = 0.453592;

interface JackedInputs {
  bodyweightLb: number;
  bodyFatPct: number;
  liftingAgeMonths: number;
  daysPerWeek: number;
}

interface JackedResult {
  trainingYear: number; // 1, 2, 3, 4+
  realistic16wkGainLb: number;
  realistic16wkGainKg: number;
  tdeeCal: number;
  surplusLow: number;
  surplusHigh: number;
  dailyTargetLow: number;
  dailyTargetHigh: number;
  proteinLowG: number;
  proteinHighG: number;
  checkpoints: { week: number; weightLb: number }[];
  volumeStartMev: VolumeRow[]; // shown as table
  weeklyGainLb: number;
}

function calculateJacked(i: JackedInputs): JackedResult {
  // Training year buckets. Year 1 = months 0-11, year 2 = 12-23, etc.
  const yearIndex = Math.min(
    Math.floor(i.liftingAgeMonths / 12),
    MCDONALD_MALE_LB_PER_YEAR.length - 1,
  );
  const annualGainLb = MCDONALD_MALE_LB_PER_YEAR[yearIndex];
  // 16 weeks is roughly 30.7% of a year.
  const realistic16wkGainLb = +(annualGainLb * (16 / 52)).toFixed(1);
  const realistic16wkGainKg = +(realistic16wkGainLb * LB_PER_KG).toFixed(2);

  // TDEE via Katch-McArdle when bf% is provided. LBM in kg.
  const weightKg = i.bodyweightLb * LB_PER_KG;
  const lbmKg = weightKg * (1 - i.bodyFatPct / 100);
  const bmr = 370 + 21.6 * lbmKg; // Katch-McArdle

  // Activity multiplier scales with training days/wk (1.45 at 3d, 1.55 at 4d, 1.65 at 5d, 1.75 at 6d).
  const activity = 1.35 + i.daysPerWeek * 0.07;
  const tdeeCal = Math.round(bmr * activity);

  // Lean-bulk surplus: 200-500 cal above TDEE. Lower for advanced lifters,
  // upper end only useful for true beginners.
  const surplusLow = yearIndex >= 2 ? 150 : 200;
  const surplusHigh = yearIndex >= 2 ? 300 : 500;

  // Protein target: 1.6-2.2 g/kg per Morton 2018 meta-analysis.
  const proteinLowG = Math.round(weightKg * 1.6);
  const proteinHighG = Math.round(weightKg * 2.2);

  // Checkpoint weights. Linear gain assumption is rough but useful as a target.
  const weeklyGainLb = +(realistic16wkGainLb / 16).toFixed(2);
  const checkpoints = [4, 8, 12, 16].map((w) => ({
    week: w,
    weightLb: +(i.bodyweightLb + weeklyGainLb * w).toFixed(1),
  }));

  return {
    trainingYear: yearIndex + 1,
    realistic16wkGainLb,
    realistic16wkGainKg,
    tdeeCal,
    surplusLow,
    surplusHigh,
    dailyTargetLow: tdeeCal + surplusLow,
    dailyTargetHigh: tdeeCal + surplusHigh,
    proteinLowG,
    proteinHighG,
    checkpoints,
    volumeStartMev: VOLUME_LANDMARKS,
    weeklyGainLb,
  };
}

export default function HowToGetJacked() {
  const [bodyweightLb, setBodyweightLb] = useState(170);
  const [bodyFatPct, setBodyFatPct] = useState(15);
  const [liftingAgeMonths, setLiftingAgeMonths] = useState(12);
  const [daysPerWeek, setDaysPerWeek] = useState(4);

  const r = useMemo(
    () => calculateJacked({ bodyweightLb, bodyFatPct, liftingAgeMonths, daysPerWeek }),
    [bodyweightLb, bodyFatPct, liftingAgeMonths, daysPerWeek],
  );

  return (
    <CalculatorShell
      slug="how-to-get-jacked"
      title="How to Get Jacked, A 16-Week Plan"
      metaDescription="Realistic 16-week hypertrophy plan with weekly per-muscle set targets from Schoenfeld 2017, surplus calories, 1.6 to 2.2 g/kg protein, and a Lyle McDonald natural muscle gain projection. Free, no sign-up."
      intro="The honest version. Real muscle gain rates, real weekly set volumes per muscle group from the Schoenfeld 2017 dose-response review, and a calorie surplus you can actually sustain. Adjust your inputs and the plan recalculates live."
      emailCaptureResult={{
        bodyweightLb,
        bodyFatPct,
        liftingAgeMonths,
        daysPerWeek,
        realistic16wkGainLb: r.realistic16wkGainLb,
        dailyTargetLow: r.dailyTargetLow,
        dailyTargetHigh: r.dailyTargetHigh,
        proteinLowG: r.proteinLowG,
        proteinHighG: r.proteinHighG,
      }}
      faqs={[
        {
          q: 'Why only 6 to 7 pounds of muscle in 16 weeks for a first-year lifter?',
          a: 'Lyle McDonald\'s natural muscle gain model places a year-one male lifter at about 22 lbs of lean mass per year, which is roughly 6.7 lbs in 16 weeks. Anything advertised faster is either water, glycogen, fat regain, or steroids. Women gain at roughly half that rate. By year 4 you are looking at 2 lbs per year, hence why advanced lifters chase fractional gains.',
        },
        {
          q: 'Why a small surplus instead of a large one?',
          a: 'Garthe 2013 and Helms 2014 both show that gaining at 0.25 to 0.5% of bodyweight per week minimizes fat regain while still maximizing muscle gain. Above 500 calorie surplus, the extra calories go to fat. The body has a hard ceiling on how fast it can build muscle protein and a hard surplus does not move that ceiling.',
        },
        {
          q: 'Why 1.6 to 2.2 g/kg protein, not 1 g/lb?',
          a: 'Morton et al. 2018 meta-analysis of 49 studies and 1,863 subjects found 1.62 g/kg as the optimal threshold above which additional protein produced no further hypertrophy benefit. 1 g/lb equals 2.2 g/kg, which is the upper end and totally fine but not magic.',
        },
        {
          q: 'What does MEV, MAV, and MRV mean?',
          a: 'From Schoenfeld 2017 and Renaissance Periodization volume landmarks. MEV is Minimum Effective Volume, the lowest weekly sets that produce growth. MAV is Maximum Adaptive Volume, the range where most growth happens. MRV is Maximum Recoverable Volume, beyond which fatigue outpaces recovery. Start a mesocycle at MEV, progress to MAV by week 4 to 6, deload before MRV.',
        },
        {
          q: 'How many training days per week is best?',
          a: 'For hypertrophy, frequency matters less than total weekly sets per muscle if both fall in the MAV range. Schoenfeld 2019 meta-analysis: 2x per week per muscle beats 1x, but 3x is no better than 2x at matched volume. 4 to 5 day splits work well because you can hit each muscle twice weekly without massive single sessions.',
        },
        {
          q: 'Why does the plan use Katch-McArdle for TDEE?',
          a: 'Katch-McArdle uses lean body mass directly, which is more accurate than Mifflin-St Jeor for lifters who carry significant muscle relative to their height. If you do not know your body fat percentage, set it to 15 to 20 percent for males and 22 to 28 percent for females.',
        },
        {
          q: 'Do I need to track every single rep?',
          a: 'No, but you should track sets per muscle per week and the bar weights on your main compounds. Add 2.5 to 5 lbs to compounds every 1 to 2 weeks. If you cannot, you are either undereating, undersleeping, or near your MRV and need a deload.',
        },
      ]}
    >
      {/* Inputs */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 sm:p-7 space-y-6">
        <h2 className="text-lg font-bold text-white">Your stats</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
          <label className="block">
            <span className="block text-sm font-medium text-zinc-300 mb-2">Body weight</span>
            <div className="relative">
              <input
                type="number"
                inputMode="decimal"
                value={bodyweightLb}
                min={90}
                max={400}
                step={1}
                onChange={(e) => setBodyweightLb(parseFloat(e.target.value) || 0)}
                className="w-full px-4 py-3.5 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-lg font-semibold focus:outline-none focus:ring-2 focus:ring-emerald-500"
              />
              <span className="absolute right-4 top-1/2 -translate-y-1/2 text-sm text-zinc-500 font-medium">lb</span>
            </div>
          </label>
          <label className="block">
            <div className="flex justify-between items-baseline mb-2">
              <span className="text-sm font-medium text-zinc-300">Body fat</span>
              <span className="text-lg font-bold text-emerald-400 tabular-nums">{bodyFatPct}%</span>
            </div>
            <input
              type="range"
              min={5}
              max={40}
              value={bodyFatPct}
              onChange={(e) => setBodyFatPct(parseInt(e.target.value, 10))}
              className="w-full accent-emerald-500 h-2"
            />
          </label>
          <label className="block">
            <div className="flex justify-between items-baseline mb-2">
              <span className="text-sm font-medium text-zinc-300">Lifting age</span>
              <span className="text-lg font-bold text-emerald-400 tabular-nums">
                {liftingAgeMonths} mo
              </span>
            </div>
            <input
              type="range"
              min={0}
              max={120}
              step={1}
              value={liftingAgeMonths}
              onChange={(e) => setLiftingAgeMonths(parseInt(e.target.value, 10))}
              className="w-full accent-emerald-500 h-2"
            />
            <p className="text-xs text-zinc-500 mt-1.5">
              Year {r.trainingYear} natural lifter. Expect{' '}
              <span className="text-emerald-400 font-semibold">
                {MCDONALD_MALE_LB_PER_YEAR[Math.min(r.trainingYear - 1, 3)]} lb
              </span>{' '}
              of new muscle this year if everything is dialed.
            </p>
          </label>
          <label className="block">
            <div className="flex justify-between items-baseline mb-2">
              <span className="text-sm font-medium text-zinc-300">Training days per week</span>
              <span className="text-lg font-bold text-emerald-400 tabular-nums">{daysPerWeek}</span>
            </div>
            <input
              type="range"
              min={3}
              max={6}
              value={daysPerWeek}
              onChange={(e) => setDaysPerWeek(parseInt(e.target.value, 10))}
              className="w-full accent-emerald-500 h-2"
            />
          </label>
        </div>
      </section>

      {/* Hero */}
      <section className="bg-gradient-to-br from-emerald-900/40 via-zinc-900 to-zinc-950 border border-emerald-500/30 rounded-2xl p-6 sm:p-10">
        <ResultHero
          label="Realistic muscle gain over 16 weeks"
          value={r.realistic16wkGainLb}
          suffix="lbs"
          decimals={1}
          emphasis="emerald"
          size="xl"
          subLabel={`About ${r.weeklyGainLb} lbs per week. Year ${r.trainingYear} natural lifter pace from the Lyle McDonald model.`}
        />
      </section>

      {/* Daily numbers */}
      <section>
        <h2 className="text-lg font-bold text-white mb-1">Your daily numbers</h2>
        <p className="text-sm text-zinc-400 mb-4">
          A lean surplus, not a dirty bulk. Hit the protein floor every day.
        </p>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <StatCard label="Maintenance" value={r.tdeeCal.toLocaleString()} unit="cal" />
          <StatCard
            label="Daily target"
            value={`${r.dailyTargetLow.toLocaleString()} to ${r.dailyTargetHigh.toLocaleString()}`}
            unit="cal"
            emphasis
          />
          <StatCard
            label="Protein"
            value={`${r.proteinLowG} to ${r.proteinHighG}`}
            unit="g"
            emphasis
          />
          <StatCard
            label="Surplus"
            value={`+${r.surplusLow} to ${r.surplusHigh}`}
            unit="cal"
          />
        </div>
      </section>

      {/* Checkpoints */}
      <section>
        <h2 className="text-lg font-bold text-white mb-1">Bodyweight checkpoints</h2>
        <p className="text-sm text-zinc-400 mb-4">
          Hit these scale weights to know you are on pace. Weigh in same time, same day each week.
        </p>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {r.checkpoints.map((c) => (
            <div key={c.week} className="rounded-xl border border-zinc-800 bg-zinc-900 px-4 py-4 text-center">
              <p className="text-[10px] text-zinc-500 uppercase tracking-wider font-semibold">Week {c.week}</p>
              <p className="text-2xl font-bold text-white mt-1 tabular-nums">{c.weightLb}</p>
              <p className="text-xs text-zinc-500">lb</p>
            </div>
          ))}
        </div>
      </section>

      {/* Volume table */}
      <section>
        <h2 className="text-lg font-bold text-white mb-1">Weekly volume per muscle group</h2>
        <p className="text-sm text-zinc-400 mb-4">
          Start at MEV in week 1, ramp toward MAV through weeks 4 to 6, deload before MRV. Sets are working sets, RIR 1 to 3.
        </p>
        <div className="overflow-x-auto rounded-2xl border border-zinc-800 bg-zinc-900">
          <table className="w-full text-sm">
            <thead className="bg-zinc-950 text-zinc-400">
              <tr>
                <th className="text-left px-4 py-3 font-semibold">Muscle</th>
                <th className="text-right px-3 py-3 font-semibold">MV</th>
                <th className="text-right px-3 py-3 font-semibold text-emerald-400">MEV start</th>
                <th className="text-right px-3 py-3 font-semibold text-emerald-400">MAV target</th>
                <th className="text-right px-3 py-3 font-semibold">MRV cap</th>
              </tr>
            </thead>
            <tbody>
              {r.volumeStartMev.map((row) => (
                <tr key={row.muscle} className="border-t border-zinc-800">
                  <td className="px-4 py-3 text-white">{row.muscle}</td>
                  <td className="px-3 py-3 text-right text-zinc-400 tabular-nums">{row.mv}</td>
                  <td className="px-3 py-3 text-right text-emerald-400 tabular-nums">{row.mev}</td>
                  <td className="px-3 py-3 text-right text-emerald-400 tabular-nums">
                    {row.mav[0]} to {row.mav[1]}
                  </td>
                  <td className="px-3 py-3 text-right text-zinc-400 tabular-nums">{row.mrv}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <p className="text-xs text-zinc-500 mt-3">
          Source: Schoenfeld, Ogborn, Krieger 2017 dose-response meta-analysis plus Renaissance Periodization volume landmarks.
        </p>
      </section>

      <InstallCta
        slug="how-to-get-jacked"
        result={{
          bodyweightLb,
          bodyFatPct,
          daysPerWeek,
          dailyTargetLow: r.dailyTargetLow,
          dailyTargetHigh: r.dailyTargetHigh,
          proteinHighG: r.proteinHighG,
        }}
        primary="Run this 16-week plan inside Zealova"
        secondary="Zealova auto-generates the training week, tracks per-muscle set counts against MEV and MAV, logs your meals, and bumps your surplus if you stop gaining."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'Schoenfeld BJ, Ogborn D, Krieger JW (2017). Dose-response relationship between weekly resistance training volume and increases in muscle mass: A systematic review and meta-analysis. J Sports Sci 35(11):1073-1082.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/27433992/',
          },
          {
            text: 'Morton RW et al. (2018). A systematic review, meta-analysis and meta-regression of the effect of protein supplementation on resistance training-induced gains in muscle mass and strength in healthy adults. BJSM 52(6):376-384.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/28698222/',
          },
          {
            text: 'Garthe I et al. (2013). Effect of nutritional intervention on body composition and performance in elite athletes. EJSS 13(3):295-303.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/23679146/',
          },
          {
            text: 'Helms ER, Aragon AA, Fitschen PJ (2014). Evidence-based recommendations for natural bodybuilding contest preparation: nutrition and supplementation. JISSN 11:20.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/24864135/',
          },
          {
            text: 'McDonald L. The genetic potential for muscular size and strength in men. Bodyrecomposition (2008).',
            url: 'https://bodyrecomposition.com/muscle-gain/genetic-muscular-potential',
          },
        ]}
        lastUpdated="2026-05-15"
      />
    </CalculatorShell>
  );
}

function StatCard({
  label,
  value,
  unit,
  emphasis = false,
}: {
  label: string;
  value: string;
  unit: string;
  emphasis?: boolean;
}) {
  const border = emphasis ? 'border-emerald-500/30 bg-emerald-500/5' : 'border-zinc-800 bg-zinc-900';
  const valueClass = emphasis ? 'text-emerald-400' : 'text-white';
  return (
    <div className={`rounded-xl border ${border} px-4 py-3.5`}>
      <p className="text-[10px] text-zinc-500 uppercase tracking-wider font-semibold">{label}</p>
      <p className={`text-xl sm:text-2xl font-bold mt-1 tabular-nums ${valueClass}`}>
        {value}
        {unit && <span className="text-sm text-zinc-500 ml-1 font-medium">{unit}</span>}
      </p>
    </div>
  );
}
