// /free-tools/how-to-get-ripped
//
// Cutting plan calculator. Inputs: bodyweight (lb), current bf %, target bf %,
// optional deadline weeks, activity level. Output: required daily deficit,
// week-by-week loss curve, protein floor (1.1 g/lb), cardio dose, refeed
// schedule (1 day every 7-14 days), realistic timeline if no deadline.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import ResultHero from '../../components/tools/ResultHero';

interface RippedInputs {
  bodyweightLb: number;
  currentBfPct: number;
  targetBfPct: number;
  deadlineWeeks: number | null;   // null = compute realistic timeline
  activityLevel: number;          // 1.2 sedentary - 1.725 hard active
}

interface WeekRow {
  week: number;
  weightLb: number;
  bfPct: number;
}

interface RippedResult {
  fatToLoseLb: number;
  weeks: number;
  weeklyLossLb: number;
  weeklyLossPctBw: number;
  dailyDeficitCal: number;
  tdeeCal: number;
  dailyTargetCal: number;
  proteinG: number;
  cardioMinPerWeek: number;
  refeedFrequencyDays: number;
  unsafe: boolean;
  curve: WeekRow[];
  endWeightLb: number;
}

const LB_PER_KG = 0.453592;
// Mifflin-St Jeor needs height + sex. We use Katch-McArdle as it only needs LBM.
// 3500 cal = 1 lb fat (textbook rule). Schoenfeld and others have argued the
// number ranges 3,436 to 3,752 but 3,500 is the established convention.
const CAL_PER_LB_FAT = 3500;

function calculateRipped(i: RippedInputs): RippedResult {
  const weightKg = i.bodyweightLb * LB_PER_KG;
  const lbmKg = weightKg * (1 - i.currentBfPct / 100);
  // Fat-mass loss math. (bw * cur_bf) - (bw * target_bf) treats LBM as held constant,
  // which is the goal of a protein-supported cut.
  const fatNow = i.bodyweightLb * (i.currentBfPct / 100);
  const fatTarget = i.bodyweightLb * (i.targetBfPct / 100);
  const fatToLoseLb = Math.max(0, fatNow - fatTarget);

  // TDEE via Katch-McArdle.
  const bmr = 370 + 21.6 * lbmKg;
  const tdeeCal = Math.round(bmr * i.activityLevel);

  // Two paths:
  //   1. Deadline given: deficit = fat_to_lose * 3500 / (weeks * 7).
  //   2. No deadline: static 0.75% bw/week (the midpoint of Helms 2014's safe 0.5-1% range).
  let weeklyLossPctBw: number;
  let weeks: number;
  let weeklyLossLb: number;
  let dailyDeficitCal: number;

  if (i.deadlineWeeks && i.deadlineWeeks > 0) {
    weeks = i.deadlineWeeks;
    weeklyLossLb = fatToLoseLb / weeks;
    weeklyLossPctBw = (weeklyLossLb / i.bodyweightLb) * 100;
    dailyDeficitCal = Math.round((weeklyLossLb * CAL_PER_LB_FAT) / 7);
  } else {
    weeklyLossPctBw = 0.75; // midpoint of safe range
    weeklyLossLb = i.bodyweightLb * (weeklyLossPctBw / 100);
    weeks = Math.ceil(fatToLoseLb / weeklyLossLb);
    dailyDeficitCal = Math.round((weeklyLossLb * CAL_PER_LB_FAT) / 7);
  }

  const unsafe = weeklyLossPctBw > 1.0;

  // Floor the target so we never recommend below BMR.
  const minIntakeCal = Math.max(1200, Math.round(bmr));
  const dailyTargetCal = Math.max(minIntakeCal, tdeeCal - dailyDeficitCal);

  // Protein floor: 1.1 g/lb per Helms 2014 for natural lifters in a deficit.
  const proteinG = Math.round(i.bodyweightLb * 1.1);

  // Cardio dose. Helms 2014 + ISSN: ~150-300 min/week moderate for fat loss.
  // Scale with size of deficit. Small deficit, less cardio needed.
  const cardioMinPerWeek = dailyDeficitCal > 600 ? 240 : dailyDeficitCal > 400 ? 180 : 120;

  // Refeed frequency: every 7 days if cutting hard or leaner than 12% bf,
  // every 14 days otherwise. Trexler 2014 metabolic-adaptation review.
  const refeedFrequencyDays = i.currentBfPct < 14 || weeklyLossPctBw > 0.85 ? 7 : 14;

  // Build week-by-week curve (linear).
  const curve: WeekRow[] = [];
  for (let w = 0; w <= weeks; w++) {
    const lostFat = weeklyLossLb * w;
    const newWeight = +(i.bodyweightLb - lostFat).toFixed(1);
    // Assume all loss is fat (the goal of high-protein cut).
    const newBf = +Math.max(
      i.targetBfPct,
      ((fatNow - lostFat) / newWeight) * 100,
    ).toFixed(1);
    curve.push({ week: w, weightLb: newWeight, bfPct: newBf });
  }

  return {
    fatToLoseLb: +fatToLoseLb.toFixed(1),
    weeks,
    weeklyLossLb: +weeklyLossLb.toFixed(2),
    weeklyLossPctBw: +weeklyLossPctBw.toFixed(2),
    dailyDeficitCal,
    tdeeCal,
    dailyTargetCal,
    proteinG,
    cardioMinPerWeek,
    refeedFrequencyDays,
    unsafe,
    curve,
    endWeightLb: curve[curve.length - 1].weightLb,
  };
}

const ACTIVITY_OPTIONS = [
  { value: 1.2, label: 'Sedentary, desk job' },
  { value: 1.375, label: 'Light, walks + 1-2 lifts' },
  { value: 1.55, label: 'Moderate, 3-5 sessions/wk' },
  { value: 1.725, label: 'Hard, 6+ sessions/wk' },
];

export default function HowToGetRipped() {
  const [bodyweightLb, setBodyweightLb] = useState(190);
  const [currentBfPct, setCurrentBfPct] = useState(22);
  const [targetBfPct, setTargetBfPct] = useState(12);
  const [useDeadline, setUseDeadline] = useState(false);
  const [deadlineWeeks, setDeadlineWeeks] = useState(12);
  const [activity, setActivity] = useState(1.55);

  const r = useMemo(
    () =>
      calculateRipped({
        bodyweightLb,
        currentBfPct,
        targetBfPct: Math.min(targetBfPct, currentBfPct - 1),
        deadlineWeeks: useDeadline ? deadlineWeeks : null,
        activityLevel: activity,
      }),
    [bodyweightLb, currentBfPct, targetBfPct, useDeadline, deadlineWeeks, activity],
  );

  return (
    <CalculatorShell
      slug="how-to-get-ripped"
      title="How to Get Ripped, Cutting Calculator"
      metaDescription="Cut from your current body fat percentage to your target with a science-based deficit, 1.1 g per pound protein floor, weekly cardio dose, and refeed schedule. Plus a realistic week-by-week trajectory. Free, no sign-up."
      intro="The math behind getting lean. Pick a target body fat percentage and either a deadline or a sustainable rate. The calculator returns your daily calorie target, protein floor, cardio dose, refeed cadence, and a week-by-week weight curve you can hold yourself to."
      emailCaptureResult={{
        bodyweightLb,
        currentBfPct,
        targetBfPct,
        weeks: r.weeks,
        dailyTargetCal: r.dailyTargetCal,
        proteinG: r.proteinG,
        endWeightLb: r.endWeightLb,
      }}
      faqs={[
        {
          q: 'Why 0.5 to 1% of bodyweight per week?',
          a: 'Garthe 2011 randomized elite athletes to slow (0.5%/wk) versus fast (1.4%/wk) cuts. Both lost weight, but the slow group preserved lean mass and improved strength on bench, squat, and vertical jump. The fast group lost lean mass and dropped performance. Helms 2014 backs this with the 0.5 to 1% guideline.',
        },
        {
          q: 'Why 1.1 g of protein per pound during a cut?',
          a: 'Helms 2014 raises the bar from a normal 0.8 g/lb to 1.0-1.4 g/lb during contest prep because protein needs go up in a deficit. The body breaks down lean tissue when calories are low and protein is the buffer. Pellegrino 2016 showed 1.1 g/lb plus resistance training preserves nearly all lean mass during a 25% deficit.',
        },
        {
          q: 'Do I really need refeeds?',
          a: 'Trexler 2014 and the MATADOR study (Byrne 2018) both found that intermittent diet breaks or refeeds reduce metabolic adaptation versus continuous cuts. We default to one higher-carb day every 14 days at moderate body fat, and every 7 days under 14% or when cutting harder than 0.85% per week.',
        },
        {
          q: 'How much cardio?',
          a: 'Less than most people think. ACSM 2018 recommends 150-300 minutes of moderate-intensity weekly cardio for weight management. The calculator scales this with deficit size. A 600+ calorie deficit gets 240 min/week, a smaller deficit gets less because diet already does the work. Lifting always comes first.',
        },
        {
          q: 'Why does my target floor at BMR?',
          a: 'Eating below BMR triggers larger metabolic adaptation, more muscle catabolism, sleep disruption, and hormonal downregulation. We floor the daily target at the higher of 1,200 cal or your calculated BMR. If the math wants you below that, the calculator extends the timeline instead.',
        },
        {
          q: 'Is my deadline realistic?',
          a: 'If the calculator shows a weekly loss rate above 1% of bodyweight, you will see a warning. Push longer. A 20-pound fat loss takes around 5 to 6 months at safe rates, not 8 weeks. Crash cuts cost muscle and metabolic rate that takes months to recover.',
        },
        {
          q: 'Why use Katch-McArdle for TDEE?',
          a: 'Katch-McArdle uses lean body mass directly. Mifflin-St Jeor uses weight, height, and age, which works fine on average but underestimates TDEE for muscular lifters and overestimates for high body fat individuals. If you know your body fat percentage, Katch is more accurate.',
        },
      ]}
    >
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
                max={500}
                step={1}
                onChange={(e) => setBodyweightLb(parseFloat(e.target.value) || 0)}
                className="w-full px-4 py-3.5 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-lg font-semibold focus:outline-none focus:ring-2 focus:ring-emerald-500"
              />
              <span className="absolute right-4 top-1/2 -translate-y-1/2 text-sm text-zinc-500">lb</span>
            </div>
          </label>
          <label className="block">
            <span className="block text-sm font-medium text-zinc-300 mb-2">Activity level</span>
            <select
              value={activity}
              onChange={(e) => setActivity(parseFloat(e.target.value))}
              className="w-full px-4 py-3.5 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-base font-medium focus:outline-none focus:ring-2 focus:ring-emerald-500"
            >
              {ACTIVITY_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
          </label>
          <label className="block">
            <div className="flex justify-between items-baseline mb-2">
              <span className="text-sm font-medium text-zinc-300">Current body fat</span>
              <span className="text-lg font-bold text-emerald-400 tabular-nums">{currentBfPct}%</span>
            </div>
            <input
              type="range"
              min={6}
              max={45}
              value={currentBfPct}
              onChange={(e) => setCurrentBfPct(parseInt(e.target.value, 10))}
              className="w-full accent-emerald-500 h-2"
            />
          </label>
          <label className="block">
            <div className="flex justify-between items-baseline mb-2">
              <span className="text-sm font-medium text-zinc-300">Target body fat</span>
              <span className="text-lg font-bold text-emerald-400 tabular-nums">{targetBfPct}%</span>
            </div>
            <input
              type="range"
              min={5}
              max={Math.max(5, currentBfPct - 1)}
              value={Math.min(targetBfPct, currentBfPct - 1)}
              onChange={(e) => setTargetBfPct(parseInt(e.target.value, 10))}
              className="w-full accent-emerald-500 h-2"
            />
          </label>
        </div>

        <div>
          <label className="flex items-center gap-3 mb-3 cursor-pointer">
            <input
              type="checkbox"
              checked={useDeadline}
              onChange={(e) => setUseDeadline(e.target.checked)}
              className="w-4 h-4 accent-emerald-500"
            />
            <span className="text-sm font-medium text-zinc-300">Set a deadline</span>
          </label>
          {useDeadline ? (
            <div>
              <div className="flex justify-between items-baseline mb-2">
                <span className="text-sm text-zinc-400">Deadline</span>
                <span className="text-base font-bold text-emerald-400 tabular-nums">
                  {deadlineWeeks} weeks
                </span>
              </div>
              <input
                type="range"
                min={4}
                max={32}
                value={deadlineWeeks}
                onChange={(e) => setDeadlineWeeks(parseInt(e.target.value, 10))}
                className="w-full accent-emerald-500 h-2"
              />
            </div>
          ) : (
            <p className="text-xs text-zinc-500">
              No deadline. We will pick the realistic 0.75% per week rate.
            </p>
          )}
        </div>
      </section>

      <section className="bg-gradient-to-br from-emerald-900/40 via-zinc-900 to-zinc-950 border border-emerald-500/30 rounded-2xl p-6 sm:p-10">
        <ResultHero
          label="Weeks to your target body fat"
          value={r.weeks}
          suffix="wk"
          decimals={0}
          emphasis="emerald"
          size="xl"
          subLabel={`Lose ${r.fatToLoseLb} lbs of fat. End around ${r.endWeightLb} lbs at ${targetBfPct}% body fat. About ${r.weeklyLossLb} lbs per week (${r.weeklyLossPctBw}% bw).`}
        />
        {r.unsafe && (
          <div className="mt-6 rounded-xl border border-amber-500/30 bg-amber-500/5 px-4 py-3">
            <p className="text-sm font-semibold text-amber-400">
              Loss rate exceeds 1% bodyweight per week
            </p>
            <p className="text-xs text-zinc-400 mt-1">
              Push your deadline. At this pace you risk muscle loss and metabolic adaptation per Garthe 2011 and Helms 2014.
            </p>
          </div>
        )}
      </section>

      <section>
        <h2 className="text-lg font-bold text-white mb-1">Your daily numbers</h2>
        <p className="text-sm text-zinc-400 mb-4">Hit these every day to land on schedule.</p>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <StatCard label="Maintenance" value={r.tdeeCal.toLocaleString()} unit="cal" />
          <StatCard
            label="Daily target"
            value={r.dailyTargetCal.toLocaleString()}
            unit="cal"
            emphasis
          />
          <StatCard label="Deficit" value={`-${r.dailyDeficitCal}`} unit="cal" />
          <StatCard label="Protein" value={r.proteinG.toString()} unit="g" emphasis />
        </div>
      </section>

      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 sm:p-7">
        <h2 className="text-lg font-bold text-white mb-4">Cardio + refeed plan</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div className="rounded-xl border border-zinc-800 bg-zinc-950 px-4 py-4">
            <p className="text-[10px] uppercase tracking-wider text-zinc-500 font-semibold">
              Weekly cardio dose
            </p>
            <p className="text-2xl font-bold text-emerald-400 mt-1 tabular-nums">
              {r.cardioMinPerWeek} min
            </p>
            <p className="text-xs text-zinc-400 mt-2">
              Split across 3 to 5 sessions. Zone 2 walking or cycling preferred. Lifting stays the priority.
            </p>
          </div>
          <div className="rounded-xl border border-zinc-800 bg-zinc-950 px-4 py-4">
            <p className="text-[10px] uppercase tracking-wider text-zinc-500 font-semibold">
              Refeed cadence
            </p>
            <p className="text-2xl font-bold text-emerald-400 mt-1 tabular-nums">
              Every {r.refeedFrequencyDays} days
            </p>
            <p className="text-xs text-zinc-400 mt-2">
              Eat at maintenance with carbs at ~3 g/kg. Reduces metabolic adaptation per Trexler 2014.
            </p>
          </div>
        </div>
      </section>

      <section>
        <h2 className="text-lg font-bold text-white mb-1">Week-by-week curve</h2>
        <p className="text-sm text-zinc-400 mb-4">
          Linear projection. Real weight bounces 1 to 3 lbs daily, so weigh in same morning each week.
        </p>
        <div className="overflow-x-auto rounded-2xl border border-zinc-800 bg-zinc-900">
          <table className="w-full text-sm">
            <thead className="bg-zinc-950 text-zinc-400">
              <tr>
                <th className="text-left px-4 py-3 font-semibold">Week</th>
                <th className="text-right px-4 py-3 font-semibold">Weight (lb)</th>
                <th className="text-right px-4 py-3 font-semibold">Body fat</th>
              </tr>
            </thead>
            <tbody>
              {r.curve.map((row) => (
                <tr key={row.week} className="border-t border-zinc-800">
                  <td className="px-4 py-2.5 text-white">Week {row.week}</td>
                  <td className="px-4 py-2.5 text-right text-zinc-200 tabular-nums">
                    {row.weightLb}
                  </td>
                  <td className="px-4 py-2.5 text-right text-emerald-400 tabular-nums">
                    {row.bfPct}%
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <InstallCta
        slug="how-to-get-ripped"
        result={{
          bodyweightLb,
          currentBfPct,
          targetBfPct,
          weeks: r.weeks,
          dailyTargetCal: r.dailyTargetCal,
          proteinG: r.proteinG,
        }}
        primary="Run this cut inside Zealova"
        secondary="Zealova logs meals against your target, schedules refeeds, tracks lift performance to catch muscle loss early, and recalculates your deficit weekly based on real weight trend."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'Helms ER, Aragon AA, Fitschen PJ (2014). Evidence-based recommendations for natural bodybuilding contest preparation: nutrition and supplementation. JISSN 11:20.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/24864135/',
          },
          {
            text: 'Garthe I et al. (2011). Effect of two different weight-loss rates on body composition and strength and power-related performance in elite athletes. IJSNEM 21(2):97-104.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/21558571/',
          },
          {
            text: 'Trexler ET, Smith-Ryan AE, Norton LE (2014). Metabolic adaptation to weight loss: implications for the athlete. JISSN 11:7.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/24571926/',
          },
          {
            text: 'Byrne NM et al. (2018). Intermittent energy restriction improves weight loss efficiency in obese men: the MATADOR study. Int J Obes 42(2):129-138.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/28925405/',
          },
          {
            text: 'ACSM (2018). Physical Activity Guidelines for Americans, 2nd edition.',
            url: 'https://health.gov/our-work/nutrition-physical-activity/physical-activity-guidelines',
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
