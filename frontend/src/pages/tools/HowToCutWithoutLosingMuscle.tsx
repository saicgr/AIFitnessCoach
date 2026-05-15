// /free-tools/how-to-cut-without-losing-muscle
//
// Muscle-preservation cutting protocol. Inputs: current 1RMs (bench/squat/deadlift),
// bodyweight, target bf %. Output: max safe deficit (250-500 cal), protein floor
// (1.1 g/lb minimum), week-by-week target weights for the 3 lifts (hold within
// 5%), volume reduction schedule (cut accessories first), diet-break protocol
// (1 break every 6-8 weeks).

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import ResultHero from '../../components/tools/ResultHero';

interface PreserveInputs {
  bodyweightLb: number;
  currentBfPct: number;
  targetBfPct: number;
  benchLb: number;
  squatLb: number;
  deadliftLb: number;
}

interface LiftCurveRow {
  week: number;
  bench: number;
  squat: number;
  deadlift: number;
}

interface PreserveResult {
  fatToLoseLb: number;
  weeks: number;
  dailyDeficitCal: number;
  dailyTargetCal: number;
  tdeeCal: number;
  proteinG: number;
  liftCurve: LiftCurveRow[];
  liftFloorPct: number;
  volumePlan: { phase: string; weeks: string; setsPct: string; cue: string }[];
  dietBreaks: number[];
  endBenchLb: number;
  endSquatLb: number;
  endDeadliftLb: number;
}

const LB_PER_KG = 0.453592;
const CAL_PER_LB_FAT = 3500;
const SAFE_LOSS_PCT_BW_PER_WK = 0.5; // conservative end of Helms 2014 for max muscle preservation
const LIFT_FLOOR_PCT = 0.95;          // hold within 5% (Pellegrino 2016 + Hulmi 2017)

function calculatePreserve(i: PreserveInputs): PreserveResult {
  const weightKg = i.bodyweightLb * LB_PER_KG;
  // Estimate LBM from current bf%. Assumes all loss is fat (the goal).
  const lbmKg = weightKg * (1 - i.currentBfPct / 100);

  const fatNow = i.bodyweightLb * (i.currentBfPct / 100);
  const fatTarget = i.bodyweightLb * (i.targetBfPct / 100);
  const fatToLoseLb = Math.max(0, fatNow - fatTarget);

  const weeklyLossLb = i.bodyweightLb * (SAFE_LOSS_PCT_BW_PER_WK / 100);
  const weeks = Math.ceil(fatToLoseLb / weeklyLossLb);
  const dailyDeficitCal = Math.round((weeklyLossLb * CAL_PER_LB_FAT) / 7);

  // TDEE Katch-McArdle.
  const bmr = 370 + 21.6 * lbmKg;
  // Assume moderate activity given user is training and tracking 3 lifts.
  const tdeeCal = Math.round(bmr * 1.55);
  // Cap deficit at 500 cal/day per Helms 2014 muscle-preservation cap.
  const cappedDeficit = Math.min(dailyDeficitCal, 500);
  const dailyTargetCal = Math.max(Math.round(bmr), tdeeCal - cappedDeficit);

  // Protein at 1.1 g/lb minimum, push to 1.3 if leaner. Helms 2014.
  const proteinFactor = i.currentBfPct < 15 ? 1.3 : 1.1;
  const proteinG = Math.round(i.bodyweightLb * proteinFactor);

  // Lift curve: hold within 5%. Bottom out at week 50% of duration, then plateau.
  // This is the realistic "lose 5%, hold" trajectory not "linear drop to zero".
  const liftCurve: LiftCurveRow[] = [];
  for (let w = 0; w <= weeks; w++) {
    const dipPct = w <= weeks / 2 ? 1 - (0.05 * w) / (weeks / 2) : LIFT_FLOOR_PCT;
    liftCurve.push({
      week: w,
      bench: Math.round(i.benchLb * dipPct),
      squat: Math.round(i.squatLb * dipPct),
      deadlift: Math.round(i.deadliftLb * dipPct),
    });
  }

  // Volume cut schedule. Israetel 2017 + Helms 2014: cut accessories first,
  // keep main lifts heavy and low-volume to preserve strength signaling.
  const volumePlan = [
    {
      phase: 'Weeks 1-2',
      weeks: '1-2',
      setsPct: '100%',
      cue: 'Full volume. Establish the deficit, watch performance, do not change training yet.',
    },
    {
      phase: 'Weeks 3-' + Math.floor(weeks / 2),
      weeks: '3 to mid',
      setsPct: '85%',
      cue: 'Drop 1-2 sets from accessory lifts (curls, lateral raises, leg extensions). Main lifts untouched.',
    },
    {
      phase: 'Mid-cut to week ' + (weeks - 2),
      weeks: 'Mid to late',
      setsPct: '70%',
      cue: 'Further accessory trim. Bench, squat, deadlift stay at 3-5 working sets, 3-6 reps, RIR 1-2.',
    },
    {
      phase: 'Final 2 weeks',
      weeks: 'Last 2',
      setsPct: '60%',
      cue: 'Maintenance volume only. Goal is to preserve strength signal, not drive adaptation.',
    },
  ];

  // Diet breaks: 1 break every 6-8 weeks per Byrne 2018 (MATADOR).
  const dietBreaks: number[] = [];
  for (let w = 7; w < weeks; w += 7) dietBreaks.push(w);

  return {
    fatToLoseLb: +fatToLoseLb.toFixed(1),
    weeks,
    dailyDeficitCal: cappedDeficit,
    dailyTargetCal,
    tdeeCal,
    proteinG,
    liftCurve,
    liftFloorPct: LIFT_FLOOR_PCT,
    volumePlan,
    dietBreaks,
    endBenchLb: liftCurve[liftCurve.length - 1].bench,
    endSquatLb: liftCurve[liftCurve.length - 1].squat,
    endDeadliftLb: liftCurve[liftCurve.length - 1].deadlift,
  };
}

export default function HowToCutWithoutLosingMuscle() {
  const [bodyweightLb, setBodyweightLb] = useState(185);
  const [currentBfPct, setCurrentBfPct] = useState(18);
  const [targetBfPct, setTargetBfPct] = useState(12);
  const [benchLb, setBenchLb] = useState(225);
  const [squatLb, setSquatLb] = useState(315);
  const [deadliftLb, setDeadliftLb] = useState(405);

  const r = useMemo(
    () =>
      calculatePreserve({
        bodyweightLb,
        currentBfPct,
        targetBfPct: Math.min(targetBfPct, currentBfPct - 1),
        benchLb,
        squatLb,
        deadliftLb,
      }),
    [bodyweightLb, currentBfPct, targetBfPct, benchLb, squatLb, deadliftLb],
  );

  return (
    <CalculatorShell
      slug="how-to-cut-without-losing-muscle"
      title="How to Cut Without Losing Muscle"
      metaDescription="Muscle preservation cutting protocol with a 250 to 500 calorie deficit, 1.1 g per pound protein floor, week-by-week strength targets for bench, squat, and deadlift, and a volume reduction schedule that cuts accessories first. Free, no sign-up."
      intro="The lift floors that tell you it is working. Cap your deficit at 500 calories, hold your three main lifts within 5% of where they started, cut accessory volume not main work. The plan generates your daily target, protein floor, and a week-by-week strength curve you can hit."
      emailCaptureResult={{
        bodyweightLb,
        currentBfPct,
        targetBfPct,
        weeks: r.weeks,
        dailyTargetCal: r.dailyTargetCal,
        proteinG: r.proteinG,
        endBenchLb: r.endBenchLb,
        endSquatLb: r.endSquatLb,
        endDeadliftLb: r.endDeadliftLb,
      }}
      faqs={[
        {
          q: 'Why cap the deficit at 500 calories per day?',
          a: 'Above 500 calories per day, lean mass loss accelerates per Helms 2014 and Garthe 2011. The 500 cal cap produces roughly 1 lb of fat loss per week, which is the established muscle-preserving rate for resistance-trained lifters. Going harder might lose more total weight but a chunk of that weight is muscle.',
        },
        {
          q: 'Why hold lifts within 5% of starting numbers?',
          a: 'Hulmi 2017 and Pellegrino 2016 found that maintaining heavy load signaling preserves muscle even in a deficit. A 5% drop is the realistic floor for natural lifters mid-cut. Drop more than 10% and you are likely losing fast-twitch fiber or central nervous system drive, both of which point to under-recovery from too aggressive a deficit.',
        },
        {
          q: 'Why cut accessory volume before main lift volume?',
          a: 'Heavy compound work is the primary signal for muscle retention. Israetel 2017 and Helms 2014 both prioritize keeping bench, squat, deadlift, row, and overhead press intensities high. Curls, lateral raises, and leg extensions can drop without compromising preservation because the main lifts already train the same muscles indirectly.',
        },
        {
          q: 'Why diet breaks every 6 to 8 weeks?',
          a: 'Byrne 2018 (MATADOR study) randomized obese men to continuous 33% deficit vs intermittent 2-week diet breaks at maintenance every 2 weeks. The diet-break group lost more total fat and showed less metabolic adaptation. We schedule a maintenance day or week every 7 weeks because long cuts erode performance and adherence.',
        },
        {
          q: 'Will I still feel strong on this protocol?',
          a: 'Mostly yes. Expect a 5-10% performance dip mid-cut, especially on squat and deadlift which are most energy-intensive. Bench is usually preserved better because it is less systemically taxing. By week 2 after the cut ends, when calories return to maintenance, lifts typically rebound to pre-cut numbers within 2 to 3 sessions.',
        },
        {
          q: 'Should I do cardio?',
          a: 'Yes, but keep it low-impact and short. 100-180 min per week of Zone 2 walking or cycling is plenty. High-intensity cardio cuts into recovery you need for lifting and can drive lean mass loss. Helms 2014 explicitly warns against high-volume HIIT during contest prep for this reason.',
        },
        {
          q: 'What if my lifts drop more than 5%?',
          a: 'Two options. One, ease the deficit by 100-200 cal and see if lifts recover in 1-2 weeks. Two, take an early diet break at maintenance for 5-7 days. If neither works, your sleep or stress is the bottleneck, not the diet.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 sm:p-7 space-y-6">
        <h2 className="text-lg font-bold text-white">Your stats</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
          <NumberField label="Body weight" value={bodyweightLb} onChange={setBodyweightLb} suffix="lb" min={90} max={500} />
          <RangeField label="Current body fat" value={currentBfPct} onChange={setCurrentBfPct} min={8} max={40} suffix="%" />
          <RangeField
            label="Target body fat"
            value={Math.min(targetBfPct, currentBfPct - 1)}
            onChange={setTargetBfPct}
            min={5}
            max={Math.max(5, currentBfPct - 1)}
            suffix="%"
          />
          <div />
          <NumberField label="Bench 1RM" value={benchLb} onChange={setBenchLb} suffix="lb" min={45} max={800} />
          <NumberField label="Squat 1RM" value={squatLb} onChange={setSquatLb} suffix="lb" min={45} max={1000} />
          <NumberField label="Deadlift 1RM" value={deadliftLb} onChange={setDeadliftLb} suffix="lb" min={45} max={1100} />
        </div>
      </section>

      <section className="bg-gradient-to-br from-emerald-900/40 via-zinc-900 to-zinc-950 border border-emerald-500/30 rounded-2xl p-6 sm:p-10">
        <ResultHero
          label="Cut duration with full muscle preservation"
          value={r.weeks}
          suffix="wk"
          decimals={0}
          emphasis="emerald"
          size="xl"
          subLabel={`Lose ${r.fatToLoseLb} lbs of fat at 0.5% bodyweight per week, the muscle-preserving rate. Cap deficit at 500 cal per day.`}
        />
      </section>

      <section>
        <h2 className="text-lg font-bold text-white mb-1">Your daily numbers</h2>
        <p className="text-sm text-zinc-400 mb-4">Deficit floors at BMR. Protein is non-negotiable.</p>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <StatCard label="Maintenance" value={r.tdeeCal.toLocaleString()} unit="cal" />
          <StatCard label="Daily target" value={r.dailyTargetCal.toLocaleString()} unit="cal" emphasis />
          <StatCard label="Deficit" value={`-${r.dailyDeficitCal}`} unit="cal" />
          <StatCard label="Protein" value={r.proteinG.toString()} unit="g" emphasis />
        </div>
      </section>

      <section>
        <h2 className="text-lg font-bold text-white mb-1">Lift floors over the cut</h2>
        <p className="text-sm text-zinc-400 mb-4">
          Hold these or higher. Drop below week-over-week and your deficit is too steep.
        </p>
        <div className="overflow-x-auto rounded-2xl border border-zinc-800 bg-zinc-900">
          <table className="w-full text-sm">
            <thead className="bg-zinc-950 text-zinc-400">
              <tr>
                <th className="text-left px-4 py-3 font-semibold">Week</th>
                <th className="text-right px-4 py-3 font-semibold">Bench (lb)</th>
                <th className="text-right px-4 py-3 font-semibold">Squat (lb)</th>
                <th className="text-right px-4 py-3 font-semibold">Deadlift (lb)</th>
              </tr>
            </thead>
            <tbody>
              {r.liftCurve.map((row) => (
                <tr key={row.week} className="border-t border-zinc-800">
                  <td className="px-4 py-2.5 text-white">Week {row.week}</td>
                  <td className="px-4 py-2.5 text-right tabular-nums text-emerald-400">{row.bench}</td>
                  <td className="px-4 py-2.5 text-right tabular-nums text-emerald-400">{row.squat}</td>
                  <td className="px-4 py-2.5 text-right tabular-nums text-emerald-400">{row.deadlift}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <p className="text-xs text-zinc-500 mt-3">
          Held within 5% of starting numbers per Hulmi 2017 + Pellegrino 2016. Mid-cut floor, then flat.
        </p>
      </section>

      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 sm:p-7">
        <h2 className="text-lg font-bold text-white mb-4">Volume reduction schedule</h2>
        <p className="text-sm text-zinc-400 mb-5">
          Cut accessories first, never main compounds. Main lifts stay heavy to preserve strength signaling.
        </p>
        <div className="space-y-3">
          {r.volumePlan.map((p) => (
            <div key={p.phase} className="rounded-xl border border-zinc-800 bg-zinc-950 px-4 py-3">
              <div className="flex justify-between items-baseline">
                <p className="text-sm font-semibold text-white">{p.phase}</p>
                <p className="text-sm font-bold text-emerald-400 tabular-nums">{p.setsPct} sets</p>
              </div>
              <p className="text-xs text-zinc-400 mt-1.5">{p.cue}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 sm:p-7">
        <h2 className="text-lg font-bold text-white mb-2">Diet break schedule</h2>
        <p className="text-sm text-zinc-400 mb-4">
          Eat at maintenance for one day every 7 days. Refeeds restore leptin, reduce metabolic adaptation per Byrne 2018.
        </p>
        {r.dietBreaks.length > 0 ? (
          <div className="flex flex-wrap gap-2">
            {r.dietBreaks.map((w) => (
              <span
                key={w}
                className="px-3 py-1.5 rounded-lg bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-sm font-semibold"
              >
                Week {w}
              </span>
            ))}
          </div>
        ) : (
          <p className="text-sm text-zinc-500">
            Cut too short for a scheduled break. Just hold the deficit through.
          </p>
        )}
      </section>

      <InstallCta
        slug="how-to-cut-without-losing-muscle"
        result={{
          bodyweightLb,
          dailyTargetCal: r.dailyTargetCal,
          proteinG: r.proteinG,
          endBenchLb: r.endBenchLb,
          endSquatLb: r.endSquatLb,
          endDeadliftLb: r.endDeadliftLb,
        }}
        primary="Run this preservation cut in Zealova"
        secondary="Zealova compares your logged sets against the volume reduction schedule, flags when a lift drops below the 5% floor, and auto-schedules diet breaks."
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
            text: 'Hulmi JJ et al. (2017). The effects of intensive weight reduction on body composition and serum hormones in female fitness competitors. Front Physiol 7:689.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/28119632/',
          },
          {
            text: 'Pellegrino JK et al. (2016). The exercise metabolic syndrome: preventing the loss of fat-free mass during caloric restriction. Curr Opin Clin Nutr Metab Care 19(6):444-449.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/27585105/',
          },
          {
            text: 'Israetel M, Hoffmann J, Smith C (2017). Scientific Principles of Hypertrophy Training. Renaissance Periodization.',
            url: 'https://renaissanceperiodization.com/',
          },
          {
            text: 'Byrne NM et al. (2018). Intermittent energy restriction improves weight loss efficiency in obese men: the MATADOR study. Int J Obes 42(2):129-138.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/28925405/',
          },
        ]}
        lastUpdated="2026-05-15"
      />
    </CalculatorShell>
  );
}

function NumberField({
  label,
  value,
  onChange,
  suffix,
  min,
  max,
}: {
  label: string;
  value: number;
  onChange: (v: number) => void;
  suffix: string;
  min: number;
  max: number;
}) {
  return (
    <label className="block">
      <span className="block text-sm font-medium text-zinc-300 mb-2">{label}</span>
      <div className="relative">
        <input
          type="number"
          inputMode="decimal"
          value={value}
          min={min}
          max={max}
          step={1}
          onChange={(e) => onChange(parseFloat(e.target.value) || 0)}
          className="w-full px-4 py-3.5 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-lg font-semibold focus:outline-none focus:ring-2 focus:ring-emerald-500"
        />
        <span className="absolute right-4 top-1/2 -translate-y-1/2 text-sm text-zinc-500">{suffix}</span>
      </div>
    </label>
  );
}

function RangeField({
  label,
  value,
  onChange,
  min,
  max,
  suffix,
}: {
  label: string;
  value: number;
  onChange: (v: number) => void;
  min: number;
  max: number;
  suffix: string;
}) {
  return (
    <label className="block">
      <div className="flex justify-between items-baseline mb-2">
        <span className="text-sm font-medium text-zinc-300">{label}</span>
        <span className="text-lg font-bold text-emerald-400 tabular-nums">
          {value}
          {suffix}
        </span>
      </div>
      <input
        type="range"
        min={min}
        max={max}
        value={value}
        onChange={(e) => onChange(parseInt(e.target.value, 10))}
        className="w-full accent-emerald-500 h-2"
      />
    </label>
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
