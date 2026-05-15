// /free-tools/fat-loss-protocol-calculator
//
// Variable-duration fat-loss protocol calculator. Inputs: bodyweight,
// body-fat %, sex, duration (4-26 weeks), optional habit additions
// (walking, cutting weekday alcohol). Output: daily calorie target,
// daily protein, projected weekly weight trajectory.
//
// New polished UI template — animated hero number, live recalc, visual
// progression bar, projection chart, optional habit toggles, comparison
// to safe-loss-rate caps.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import ResultHero from '../../components/tools/ResultHero';
import UnitToggle from '../../components/tools/UnitToggle';
import {
  calculateProtocol,
  type ProtocolInputs,
  type ProtocolResult,
} from '../../lib/calc/fatLossProtocol';
import { kgToLb, lbToKg, round, type WeightUnit } from '../../lib/calc/units';

const DURATION_PRESETS = [4, 6, 8, 12, 16];

export default function FatLossProtocolCalculator() {
  const [unit, setUnit] = useState<WeightUnit>('lb');
  const [weightInput, setWeightInput] = useState<number>(200);
  const [bodyFatPct, setBodyFatPct] = useState<number>(22);
  const [durationWeeks, setDurationWeeks] = useState<number>(6);
  const [addWalking, setAddWalking] = useState<boolean>(true);
  const [cutAlcohol, setCutAlcohol] = useState<boolean>(true);

  const weightLb = unit === 'lb' ? weightInput : round(kgToLb(weightInput), 1);

  const inputs: ProtocolInputs = useMemo(
    () => ({
      bodyweightLb: weightLb,
      bodyFatPct,
      durationWeeks,
      addWalking,
      cutWeekdayAlcohol: cutAlcohol,
    }),
    [weightLb, bodyFatPct, durationWeeks, addWalking, cutAlcohol],
  );

  const r: ProtocolResult = useMemo(() => calculateProtocol(inputs), [inputs]);

  const projectedEndDisplay =
    unit === 'lb' ? r.projectedEndWeightLb : round(lbToKg(r.projectedEndWeightLb), 1);
  const totalLossDisplay =
    unit === 'lb' ? r.totalLossLb : round(lbToKg(r.totalLossLb), 1);
  const weeklyLossDisplay =
    unit === 'lb' ? r.weeklyLossLb : round(lbToKg(r.weeklyLossLb), 2);
  const unitLabel = unit === 'lb' ? 'lbs' : 'kg';

  const handleWeightChange = (v: number) => {
    if (v <= 0) return;
    setWeightInput(v);
  };

  const handleUnitChange = (u: WeightUnit) => {
    if (u === unit) return;
    // Convert the current input value to the new unit.
    const converted = u === 'kg' ? lbToKg(weightInput) : kgToLb(weightInput);
    setWeightInput(round(converted, 1));
    setUnit(u);
  };

  return (
    <CalculatorShell
      slug="fat-loss-protocol-calculator"
      title="Fat Loss Protocol Calculator"
      metaDescription="Variable-duration fat-loss calculator with daily calorie target, protein floor based on lean body mass, walking and alcohol bonus, and projected weekly weight loss over 4 to 26 weeks. Evidence-based, free, no sign-up."
      intro="The protocol used by athletic-physique coaches: bodyweight × 15 minus 500 for daily calories, 1 gram of protein per pound of lean body mass, two short walks per week, and cutting weekday alcohol. Pick a duration and see your daily numbers plus realistic weekly fat loss."
      emailCaptureResult={{
        weightLb,
        bodyFatPct,
        durationWeeks,
        addWalking,
        cutAlcohol,
        totalLossLb: r.totalLossLb,
        projectedEndWeightLb: r.projectedEndWeightLb,
      }}
      faqs={[
        {
          q: 'Why bodyweight times 15 for maintenance calories?',
          a: 'It is a rule-of-thumb starting point that works well for moderately active people. It assumes a TDEE around 14 to 16 calories per pound. If you are sedentary, drop to 13. If you do hard manual labor or train 6+ days per week, use 16 or 17. After 2 weeks of tracking, adjust based on your actual weight trend.',
        },
        {
          q: 'Why is the deficit 500 calories?',
          a: 'A 3,500 calorie deficit equals roughly 1 pound of fat. 500 per day for 7 days produces a 1-pound-per-week loss. This is the safe upper end for natural lifters per Helms et al. 2014. Faster loss rates risk muscle loss and metabolic adaptation.',
        },
        {
          q: 'Why calculate protein from lean body mass, not total weight?',
          a: 'Body fat is metabolically inert. Calculating protein from total weight at high body-fat levels gives unrealistically high targets that are unnecessary and expensive. Lean body mass is the muscle and organs that actually need amino acids.',
        },
        {
          q: 'Do the walking and alcohol bonuses really add up?',
          a: 'Yes, the math checks out. Two 20 to 30 minute walks per week burn roughly 350 calories. Over 6 weeks that is 2,100 calories or about 0.6 pounds. Cutting weekday drinks saves 1,500 to 3,500 calories per week which scales to 1.5 to 2 pounds over 6 weeks. The numbers compound over longer durations.',
        },
        {
          q: 'Can I lose more weight by cutting deeper?',
          a: 'You can but you should not for long. Loss rates above 1 percent of bodyweight per week start eating into muscle and crashing your metabolic rate. The 500 calorie deficit hits this safe rate for most people. Add habit changes for more loss, not deeper cuts.',
        },
        {
          q: 'How accurate is the projection?',
          a: 'The projection assumes linear loss which never quite happens. Real loss is bumpy because of water retention, sodium, glycogen, menstrual cycle, and adaptation. Over 6 to 12 weeks the average usually lands within 15 percent of the projection if you stay compliant with calorie and protein targets.',
        },
      ]}
    >
      {/* ─── Inputs ─── */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 sm:p-7 space-y-6">
        <div className="flex justify-between items-center flex-wrap gap-3">
          <h2 className="text-lg font-bold text-white">Your stats</h2>
          <UnitToggle
            value={unit}
            options={[
              { value: 'lb', label: 'lb' },
              { value: 'kg', label: 'kg' },
            ]}
            onChange={handleUnitChange}
          />
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
          {/* Body weight */}
          <label className="block">
            <span className="block text-sm font-medium text-zinc-300 mb-2">
              Body weight
            </span>
            <div className="relative">
              <input
                type="number"
                inputMode="decimal"
                value={weightInput}
                onChange={(e) => handleWeightChange(parseFloat(e.target.value) || 0)}
                min={unit === 'lb' ? 80 : 36}
                max={unit === 'lb' ? 700 : 320}
                step={unit === 'lb' ? 1 : 0.5}
                className="w-full px-4 py-3.5 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-lg font-semibold focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
              />
              <span className="absolute right-4 top-1/2 -translate-y-1/2 text-sm text-zinc-500 font-medium pointer-events-none">
                {unitLabel}
              </span>
            </div>
          </label>

          {/* Body fat slider */}
          <label className="block">
            <div className="flex justify-between items-baseline mb-2">
              <span className="text-sm font-medium text-zinc-300">Body fat</span>
              <span className="text-lg font-bold text-emerald-400 tabular-nums">
                {bodyFatPct}%
              </span>
            </div>
            <input
              type="range"
              min={5}
              max={45}
              step={1}
              value={bodyFatPct}
              onChange={(e) => setBodyFatPct(parseInt(e.target.value, 10))}
              className="w-full accent-emerald-500 h-2"
            />
            <p className="text-xs text-zinc-500 mt-1.5">
              {bodyFatCategory(bodyFatPct)}
            </p>
          </label>
        </div>

        {/* Duration */}
        <div>
          <div className="flex justify-between items-baseline mb-3">
            <span className="text-sm font-medium text-zinc-300">Duration</span>
            <span className="text-lg font-bold text-emerald-400 tabular-nums">
              {durationWeeks} weeks
            </span>
          </div>
          <div className="flex flex-wrap gap-2 mb-3">
            {DURATION_PRESETS.map((w) => (
              <button
                key={w}
                type="button"
                onClick={() => setDurationWeeks(w)}
                className={`px-4 py-2 rounded-lg text-sm font-semibold transition ${
                  durationWeeks === w
                    ? 'bg-emerald-500 text-zinc-900'
                    : 'bg-zinc-950 border border-zinc-700 text-zinc-300 hover:bg-zinc-800'
                }`}
              >
                {w}w
              </button>
            ))}
          </div>
          <input
            type="range"
            min={2}
            max={26}
            step={1}
            value={durationWeeks}
            onChange={(e) => setDurationWeeks(parseInt(e.target.value, 10))}
            className="w-full accent-emerald-500 h-2"
          />
          <p className="text-xs text-zinc-500 mt-1.5">
            Tip: 6 to 12 weeks is the realistic sweet spot. Longer cuts get psychologically harder.
          </p>
        </div>

        {/* Habit toggles */}
        <div>
          <p className="text-sm font-medium text-zinc-300 mb-3">Habit additions</p>
          <div className="space-y-2">
            <HabitToggle
              label="Add 2 short walks per week (20 to 30 min)"
              detail={`+ ${round((2 / 6) * durationWeeks, 2)} lbs over ${durationWeeks} weeks`}
              checked={addWalking}
              onChange={setAddWalking}
            />
            <HabitToggle
              label="Cut weekday alcohol"
              detail={`+ ${round((1.75 / 6) * durationWeeks, 2)} lbs over ${durationWeeks} weeks`}
              checked={cutAlcohol}
              onChange={setCutAlcohol}
            />
          </div>
        </div>
      </section>

      {/* ─── Hero result ─── */}
      <section className="bg-gradient-to-br from-emerald-900/40 via-zinc-900 to-zinc-950 border border-emerald-500/30 rounded-2xl p-6 sm:p-10">
        <ResultHero
          label={`Expected fat loss over ${durationWeeks} weeks`}
          value={totalLossDisplay}
          suffix={unitLabel}
          decimals={1}
          emphasis="emerald"
          size="xl"
          subLabel={`From ${unit === 'lb' ? weightInput : round(lbToKg(weightInput), 1)} ${unitLabel} to ${projectedEndDisplay} ${unitLabel}.  About ${weeklyLossDisplay} ${unitLabel} per week on average.`}
        />

        {/* Loss breakdown bars */}
        <div className="mt-8 space-y-3">
          <LossBar
            label="Calorie deficit (500 cal/day)"
            value={r.baseLossLb}
            total={r.totalLossLb}
            color="bg-emerald-500"
            displayUnit={unitLabel}
            displayValue={unit === 'lb' ? r.baseLossLb : round(lbToKg(r.baseLossLb), 2)}
          />
          {addWalking && (
            <LossBar
              label="+ 2 walks per week"
              value={r.walkingBonusLb}
              total={r.totalLossLb}
              color="bg-emerald-400"
              displayUnit={unitLabel}
              displayValue={unit === 'lb' ? r.walkingBonusLb : round(lbToKg(r.walkingBonusLb), 2)}
            />
          )}
          {cutAlcohol && (
            <LossBar
              label="+ Cut weekday alcohol"
              value={r.alcoholBonusLb}
              total={r.totalLossLb}
              color="bg-lime-400"
              displayUnit={unitLabel}
              displayValue={unit === 'lb' ? r.alcoholBonusLb : round(lbToKg(r.alcoholBonusLb), 2)}
            />
          )}
        </div>

        {r.unsafeLossRate && (
          <div className="mt-6 rounded-xl border border-amber-500/30 bg-amber-500/5 px-4 py-3">
            <p className="text-sm font-semibold text-amber-400">
              Loss rate exceeds 1% of bodyweight per week
            </p>
            <p className="text-xs text-zinc-400 mt-1">
              At this pace you risk muscle loss and metabolic adaptation. Consider extending the duration or scaling back the habit additions. Reference: Helms et al. 2014.
            </p>
          </div>
        )}
      </section>

      {/* ─── Daily targets ─── */}
      <section>
        <h2 className="text-lg font-bold text-white mb-1">Your daily numbers</h2>
        <p className="text-sm text-zinc-400 mb-4">
          Hit these every day for {durationWeeks} weeks.
        </p>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <StatCard
            label="Maintenance"
            value={`${r.maintenanceCal.toLocaleString()}`}
            unit="cal"
            tone="zinc"
          />
          <StatCard
            label="Daily target"
            value={`${r.dailyCalTarget.toLocaleString()}`}
            unit="cal"
            tone="emerald"
            emphasis
          />
          <StatCard
            label="Lean body mass"
            value={`${unit === 'lb' ? r.lbmLb : round(lbToKg(r.lbmLb), 1)}`}
            unit={unitLabel}
            tone="zinc"
          />
          <StatCard
            label="Fat mass"
            value={`${unit === 'lb' ? r.fatMassLb : round(lbToKg(r.fatMassLb), 1)}`}
            unit={unitLabel}
            tone="zinc"
          />
        </div>
      </section>

      {/* ─── Protein plan ─── */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 sm:p-7">
        <h2 className="text-lg font-bold text-white mb-1">Protein plan</h2>
        <p className="text-sm text-zinc-400 mb-5">
          Built around your {r.lbmLb} lbs of lean body mass.
        </p>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <StatCard
            label="Daily protein"
            value={`${r.dailyProteinG}`}
            unit="g"
            tone="emerald"
            emphasis
          />
          <StatCard
            label="Per meal"
            value={`${r.perMealProteinMinG} to ${r.perMealProteinMaxG}`}
            unit="g"
            tone="zinc"
          />
          <StatCard
            label="Meals per day"
            value={`${r.recommendedMeals}`}
            unit=""
            tone="zinc"
          />
        </div>
        <div className="mt-5 grid grid-cols-3 gap-2">
          {Array.from({ length: r.recommendedMeals }).map((_, i) => (
            <div
              key={i}
              className="rounded-lg border border-zinc-800 bg-zinc-950 px-3 py-3 text-center"
            >
              <p className="text-[10px] text-zinc-500 uppercase tracking-wider">Meal {i + 1}</p>
              <p className="text-base font-bold text-white mt-0.5">
                {Math.round(r.dailyProteinG / r.recommendedMeals)}g
              </p>
            </div>
          ))}
        </div>
        <p className="text-xs text-zinc-500 mt-4">
          30 to 40 g of protein per meal hits about 3 g of leucine, the threshold to trigger muscle protein synthesis. Spread across {r.recommendedMeals} meals.
        </p>
      </section>

      {/* ─── Projection chart ─── */}
      <section>
        <h2 className="text-lg font-bold text-white mb-1">
          Your {durationWeeks}-week projection
        </h2>
        <p className="text-sm text-zinc-400 mb-4">
          Linear projection. Real loss is bumpier but averages here within 15% if you stay compliant.
        </p>
        <ProjectionChart
          projection={r.weeklyProjection.map((p) => ({
            week: p.week,
            weight: unit === 'lb' ? p.weightLb : round(lbToKg(p.weightLb), 1),
          }))}
          unit={unitLabel}
        />
      </section>

      {/* ─── CTA ─── */}
      <InstallCta
        slug="fat-loss-protocol-calculator"
        result={{
          weightLb,
          bodyFatPct,
          durationWeeks,
          totalLossLb: r.totalLossLb,
          dailyCalTarget: r.dailyCalTarget,
          dailyProteinG: r.dailyProteinG,
        }}
        primary="Run this protocol inside Zealova"
        secondary="Zealova logs your meals, tracks protein per meal, auto-adjusts your daily target as your weight changes, and generates training that matches the cut."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'Helms ER, Aragon AA, Fitschen PJ (2014). Evidence-based recommendations for natural bodybuilding contest preparation: nutrition and supplementation. JISSN 11:20.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/24864135/',
          },
          {
            text: 'Aragon AA, Schoenfeld BJ (2013). Nutrient timing revisited: is there a post-exercise anabolic window? JISSN 10:5.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/23360586/',
          },
          {
            text: 'Schoenfeld BJ, Aragon AA (2018). How much protein can the body use in a single meal for muscle-building? Implications for daily protein distribution. JISSN 15:10.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/29497353/',
          },
          {
            text: 'Garthe I et al. (2011). Effect of two different weight-loss rates on body composition and strength and power-related performance in elite athletes. IJSNEM 21(2):97-104.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/21558571/',
          },
        ]}
        lastUpdated="2026-05-15"
      />
    </CalculatorShell>
  );
}

// ─── Sub-components ───────────────────────────────────────────────

function HabitToggle({
  label,
  detail,
  checked,
  onChange,
}: {
  label: string;
  detail: string;
  checked: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <label
      className={`flex items-start gap-3 p-3 rounded-xl border cursor-pointer transition ${
        checked
          ? 'border-emerald-500/40 bg-emerald-500/10'
          : 'border-zinc-800 bg-zinc-950 hover:border-zinc-700'
      }`}
    >
      <input
        type="checkbox"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
        className="mt-1 w-4 h-4 accent-emerald-500"
      />
      <div className="flex-1">
        <p className="text-sm text-white font-medium">{label}</p>
        <p className="text-xs text-emerald-400 mt-0.5 font-semibold">{detail}</p>
      </div>
    </label>
  );
}

function StatCard({
  label,
  value,
  unit,
  tone = 'zinc',
  emphasis = false,
}: {
  label: string;
  value: string;
  unit: string;
  tone?: 'zinc' | 'emerald';
  emphasis?: boolean;
}) {
  const border =
    tone === 'emerald' ? 'border-emerald-500/30 bg-emerald-500/5' : 'border-zinc-800 bg-zinc-900';
  const valueClass = emphasis ? 'text-emerald-400' : 'text-white';
  return (
    <div className={`rounded-xl border ${border} px-4 py-3.5`}>
      <p className="text-[10px] text-zinc-500 uppercase tracking-wider font-semibold">
        {label}
      </p>
      <p className={`text-2xl font-bold mt-1 tabular-nums ${valueClass}`}>
        {value}
        {unit && <span className="text-sm text-zinc-500 ml-1 font-medium">{unit}</span>}
      </p>
    </div>
  );
}

function LossBar({
  label,
  value,
  total,
  color,
  displayUnit,
  displayValue,
}: {
  label: string;
  value: number;
  total: number;
  color: string;
  displayUnit: string;
  displayValue: number;
}) {
  const pct = total > 0 ? (value / total) * 100 : 0;
  return (
    <div>
      <div className="flex justify-between items-baseline mb-1">
        <span className="text-sm text-zinc-300">{label}</span>
        <span className="text-sm font-semibold text-white tabular-nums">
          {displayValue} {displayUnit}
        </span>
      </div>
      <div className="w-full h-2 rounded-full bg-zinc-800 overflow-hidden">
        <div
          className={`h-full ${color} transition-all duration-500 ease-out`}
          style={{ width: `${pct}%` }}
        />
      </div>
    </div>
  );
}

function ProjectionChart({
  projection,
  unit,
}: {
  projection: Array<{ week: number; weight: number }>;
  unit: string;
}) {
  if (projection.length === 0) return null;
  const maxWeight = Math.max(...projection.map((p) => p.weight));
  const minWeight = Math.min(...projection.map((p) => p.weight));
  const range = Math.max(0.1, maxWeight - minWeight);
  const PAD_TOP = 12;
  const PAD_BOTTOM = 24;
  const PAD_X = 8;
  const W = 600;
  const H = 220;
  const innerW = W - PAD_X * 2;
  const innerH = H - PAD_TOP - PAD_BOTTOM;

  const points = projection.map((p, i) => {
    const x = PAD_X + (i / (projection.length - 1 || 1)) * innerW;
    const y = PAD_TOP + (1 - (p.weight - minWeight) / range) * innerH;
    return { x, y, week: p.week, weight: p.weight };
  });
  const path = points
    .map((pt, i) => `${i === 0 ? 'M' : 'L'}${pt.x.toFixed(1)},${pt.y.toFixed(1)}`)
    .join(' ');
  const area = `${path} L${points[points.length - 1].x},${H - PAD_BOTTOM} L${points[0].x},${H - PAD_BOTTOM} Z`;

  return (
    <div className="rounded-2xl border border-zinc-800 bg-zinc-900 p-4 sm:p-6">
      <svg
        viewBox={`0 0 ${W} ${H}`}
        className="w-full h-auto"
        preserveAspectRatio="xMidYMid meet"
      >
        <defs>
          <linearGradient id="lossGradient" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="rgb(16 185 129)" stopOpacity="0.4" />
            <stop offset="100%" stopColor="rgb(16 185 129)" stopOpacity="0.0" />
          </linearGradient>
        </defs>
        <path d={area} fill="url(#lossGradient)" />
        <path
          d={path}
          fill="none"
          stroke="rgb(52 211 153)"
          strokeWidth="2.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        {points.map((pt) =>
          pt.week === 0 || pt.week === points[points.length - 1].week ? (
            <g key={pt.week}>
              <circle cx={pt.x} cy={pt.y} r={5} fill="rgb(16 185 129)" />
              <text
                x={pt.x}
                y={pt.y - 10}
                textAnchor="middle"
                className="fill-white text-xs font-bold"
              >
                {pt.weight}
              </text>
            </g>
          ) : null,
        )}
        {/* X-axis labels */}
        <text x={PAD_X} y={H - 6} className="fill-zinc-500 text-[11px]">
          Week 0
        </text>
        <text x={W - PAD_X} y={H - 6} textAnchor="end" className="fill-zinc-500 text-[11px]">
          Week {points[points.length - 1].week}
        </text>
      </svg>
      <p className="text-xs text-zinc-500 text-center mt-2">
        Weight ({unit}) over time. Linear projection from current to end weight.
      </p>
    </div>
  );
}

function bodyFatCategory(pct: number): string {
  if (pct < 8) return 'Essential / shredded contest-prep range';
  if (pct < 14) return 'Athletic / visible abs in good lighting';
  if (pct < 20) return 'Fit / lean cover-model range';
  if (pct < 26) return 'Average / typical adult range';
  if (pct < 32) return 'Overweight / soft midsection';
  if (pct < 40) return 'Obese / health concerns rising';
  return 'High-risk / consult a doctor';
}
