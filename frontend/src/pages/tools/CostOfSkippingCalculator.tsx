// /free-tools/cost-of-skipping-calculator
//
// Humor-angle calculator. Inputs: gym cost, age, retirement age, skipped
// workouts per month. Outputs: lifetime $ wasted, hours skipped, equivalent
// in pizza / Netflix subs, estimated physiological cost, and a motivational
// reverse-flip showing what consistency would produce.
//
// Downloadable result card via <canvas> toBlob(), following the
// PhotoComparison.tsx pattern. Nothing leaves the device.

import { useEffect, useMemo, useRef, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

interface Outputs {
  yearsRemaining: number;
  totalSpent: number;
  totalWasted: number;
  totalSkipped: number;
  hoursSkipped: number;
  pizzaSlices: number;
  netflixYears: number;
  proteinTubs: number;
  muscleLossLb: number;
  vo2DropPct: number;
  flipMonths: number;
  flipMuscleGainLb: number;
  flipStrengthGainPct: number;
}

function computeOutputs(
  monthlyCost: number,
  age: number,
  retireAt: number,
  skipsPerMonth: number,
  totalWorkoutsPerMonth: number,
): Outputs | null {
  if (
    !Number.isFinite(monthlyCost) ||
    !Number.isFinite(age) ||
    !Number.isFinite(retireAt) ||
    !Number.isFinite(skipsPerMonth) ||
    retireAt <= age ||
    totalWorkoutsPerMonth <= 0
  ) {
    return null;
  }
  const yearsRemaining = retireAt - age;
  const monthsRemaining = yearsRemaining * 12;
  const totalSpent = monthlyCost * monthsRemaining;
  const skipRatio = Math.min(1, skipsPerMonth / totalWorkoutsPerMonth);
  const totalWasted = totalSpent * skipRatio;
  const totalSkipped = skipsPerMonth * monthsRemaining;
  const hoursSkipped = totalSkipped * 1; // 1 hour per session
  // Equivalents
  const pizzaSlices = Math.round(totalWasted / 3); // ~$3/slice
  const netflixYears = totalWasted / (15.49 * 12); // standard plan
  const proteinTubs = Math.round(totalWasted / 50); // ~$50/tub
  // Physiological — lifetime sedentary-vs-active gap, scaled by skip ratio.
  // ACSM literature: ~3-8% muscle mass loss per decade after 30 when sedentary.
  const decadesRemaining = yearsRemaining / 10;
  const muscleLossLb = Math.round(decadesRemaining * 5 * skipRatio * 10) / 10;
  // VO2 max declines roughly 10% per decade sedentary, half that if active.
  const vo2DropPct = Math.round(decadesRemaining * 5 * skipRatio * 10) / 10;
  // Flip — what 12 months of consistency would produce for an intermediate trainee.
  const flipMonths = 12;
  const flipMuscleGainLb = 6;
  const flipStrengthGainPct = 30;
  return {
    yearsRemaining,
    totalSpent: Math.round(totalSpent),
    totalWasted: Math.round(totalWasted),
    totalSkipped: Math.round(totalSkipped),
    hoursSkipped: Math.round(hoursSkipped),
    pizzaSlices,
    netflixYears: Math.round(netflixYears * 10) / 10,
    proteinTubs,
    muscleLossLb,
    vo2DropPct,
    flipMonths,
    flipMuscleGainLb,
    flipStrengthGainPct,
  };
}

function fmtMoney(n: number): string {
  return n.toLocaleString('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });
}

export default function CostOfSkippingCalculator() {
  const [monthlyCost, setMonthlyCost] = useState<number | ''>(50);
  const [age, setAge] = useState<number | ''>(30);
  const [retireAt, setRetireAt] = useState<number | ''>(65);
  const [skipsPerMonth, setSkipsPerMonth] = useState<number | ''>(8);
  const [totalWorkoutsPerMonth] = useState<number>(16); // baseline: 4/week
  const canvasRef = useRef<HTMLCanvasElement>(null);

  const out = useMemo(() => {
    if (
      typeof monthlyCost !== 'number' ||
      typeof age !== 'number' ||
      typeof retireAt !== 'number' ||
      typeof skipsPerMonth !== 'number'
    )
      return null;
    return computeOutputs(monthlyCost, age, retireAt, skipsPerMonth, totalWorkoutsPerMonth);
  }, [monthlyCost, age, retireAt, skipsPerMonth, totalWorkoutsPerMonth]);

  // Draw the share card whenever outputs change.
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || !out) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    const W = 1080;
    const H = 1350; // 4:5 portrait
    canvas.width = W;
    canvas.height = H;
    // Background gradient
    const grad = ctx.createLinearGradient(0, 0, 0, H);
    grad.addColorStop(0, '#022c22');
    grad.addColorStop(1, '#09090b');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, W, H);

    // Header
    ctx.fillStyle = '#10b981';
    ctx.font = '600 32px system-ui, -apple-system, sans-serif';
    ctx.fillText('THE COST OF SKIPPING', 60, 100);

    // Main number
    ctx.fillStyle = '#ffffff';
    ctx.font = '800 140px system-ui, -apple-system, sans-serif';
    ctx.fillText(fmtMoney(out.totalWasted), 60, 260);

    ctx.fillStyle = '#a1a1aa';
    ctx.font = '500 28px system-ui, -apple-system, sans-serif';
    ctx.fillText(`wasted on a gym I will not use over ${out.yearsRemaining} years.`, 60, 310);

    // Divider
    ctx.fillStyle = '#27272a';
    ctx.fillRect(60, 380, W - 120, 2);

    // Stats grid
    const drawStat = (label: string, value: string, x: number, y: number) => {
      ctx.fillStyle = '#71717a';
      ctx.font = '500 24px system-ui, -apple-system, sans-serif';
      ctx.fillText(label.toUpperCase(), x, y);
      ctx.fillStyle = '#ffffff';
      ctx.font = '700 44px system-ui, -apple-system, sans-serif';
      ctx.fillText(value, x, y + 60);
    };

    drawStat('Hours skipped', out.hoursSkipped.toLocaleString(), 60, 440);
    drawStat('Workouts skipped', out.totalSkipped.toLocaleString(), 560, 440);
    drawStat('Pizza slices', out.pizzaSlices.toLocaleString(), 60, 580);
    drawStat('Netflix years', out.netflixYears.toString(), 560, 580);
    drawStat('Muscle lost', `${out.muscleLossLb} lb`, 60, 720);
    drawStat('VO2 decline', `${out.vo2DropPct}%`, 560, 720);

    // Flip
    ctx.fillStyle = '#27272a';
    ctx.fillRect(60, 850, W - 120, 2);
    ctx.fillStyle = '#10b981';
    ctx.font = '700 36px system-ui, -apple-system, sans-serif';
    ctx.fillText('But here is the flip.', 60, 920);
    ctx.fillStyle = '#ffffff';
    ctx.font = '500 32px system-ui, -apple-system, sans-serif';
    ctx.fillText(`${out.flipMonths} months of showing up:`, 60, 980);
    ctx.fillStyle = '#d4d4d8';
    ctx.font = '500 28px system-ui, -apple-system, sans-serif';
    ctx.fillText(`+ ${out.flipMuscleGainLb} lb of muscle`, 60, 1030);
    ctx.fillText(`+ ${out.flipStrengthGainPct}% stronger on the big lifts`, 60, 1075);
    ctx.fillText('+ resting heart rate down 5-10 bpm', 60, 1120);
    ctx.fillText('+ the receipt above, ripped up', 60, 1165);

    // Footer
    ctx.fillStyle = '#52525b';
    ctx.font = '500 22px system-ui, -apple-system, sans-serif';
    ctx.fillText('zealova.com / free-tools / cost-of-skipping-calculator', 60, H - 60);
  }, [out]);

  const handleDownload = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    canvas.toBlob(
      (blob) => {
        if (!blob) return;
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `zealova-cost-of-skipping-${Date.now()}.png`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      },
      'image/png',
      0.95,
    );
  };

  return (
    <CalculatorShell
      slug="cost-of-skipping-calculator"
      title="Cost of Skipping Calculator"
      metaDescription="Calculate the lifetime cost of skipping the gym. Money wasted, hours missed, muscle lost, and what 12 months of consistency would change. Free, no signup."
      intro="Enter the gym membership you barely use. We show you the lifetime tab. Then we flip it and show you what consistency for the next twelve months would actually do."
      faqs={[
        {
          q: 'Is this meant to make me feel bad?',
          a: 'Half yes, half no. The waste numbers are real. The flip section is also real. Both halves matter. Guilt without a path forward is useless. We give you both.',
        },
        {
          q: 'Where do the physiological estimates come from?',
          a: 'Muscle loss with sedentary aging is roughly 3 to 8 percent per decade after 30 (ACSM, sarcopenia literature). VO2 max declines ~10 percent per decade sedentary, roughly half that if you train. The flip numbers reflect a realistic intermediate-trainee 12-month outcome from controlled studies.',
        },
        {
          q: 'How accurate is the dollar number?',
          a: 'It is a straight projection. Monthly cost × months until retirement × your skip ratio. No inflation, no interest. The point is the order of magnitude, not the exact figure.',
        },
        {
          q: 'Can I download the result card?',
          a: 'Yes. Hit Download. We render a portrait-format PNG locally on your device. Nothing is uploaded. Post it, save it, send it to your past self.',
        },
      ]}
    >
      {/* Inputs */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <h2 className="text-lg font-bold text-white mb-1">The receipt</h2>
        <p className="text-sm text-zinc-400 mb-6">
          Plug in the membership you are paying for and the workouts you keep meaning to do.
        </p>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <NumberInput
            label="Monthly gym cost"
            value={monthlyCost}
            onChange={setMonthlyCost}
            unit="$"
            min={0}
            step={1}
            placeholder="50"
          />
          <NumberInput
            label="Current age"
            value={age}
            onChange={setAge}
            min={14}
            max={100}
            step={1}
            placeholder="30"
          />
          <NumberInput
            label="Retirement age"
            value={retireAt}
            onChange={setRetireAt}
            min={20}
            max={100}
            step={1}
            placeholder="65"
            help="Or whatever age you plan to stop paying for a gym."
          />
          <NumberInput
            label="Workouts skipped per month"
            value={skipsPerMonth}
            onChange={setSkipsPerMonth}
            min={0}
            max={31}
            step={1}
            placeholder="8"
            help="Out of an assumed 16 per month at 4 sessions per week."
          />
        </div>
      </section>

      {/* Outputs */}
      {out && (
        <>
          <section className="bg-gradient-to-br from-rose-950 to-zinc-900 border border-rose-500/30 rounded-2xl p-6 sm:p-8">
            <p className="text-xs uppercase tracking-wide text-rose-400 font-semibold mb-2">
              Lifetime tab
            </p>
            <p className="text-5xl sm:text-6xl font-extrabold text-white tracking-tight mb-2">
              {fmtMoney(out.totalWasted)}
            </p>
            <p className="text-sm text-zinc-400">
              wasted on a gym you barely show up to, over the next {out.yearsRemaining} years.
            </p>
          </section>

          <section className="grid grid-cols-2 md:grid-cols-3 gap-3">
            <Stat label="Hours skipped" value={out.hoursSkipped.toLocaleString()} />
            <Stat label="Workouts skipped" value={out.totalSkipped.toLocaleString()} />
            <Stat label="Total spent" value={fmtMoney(out.totalSpent)} />
            <Stat label="Pizza slices equivalent" value={out.pizzaSlices.toLocaleString()} />
            <Stat label="Netflix years equivalent" value={`${out.netflixYears} yrs`} />
            <Stat label="Protein tubs equivalent" value={out.proteinTubs.toLocaleString()} />
          </section>

          <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
            <p className="text-xs uppercase tracking-wide text-zinc-500 font-semibold mb-3">
              The real cost (not money)
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <p className="text-3xl font-bold text-white">{out.muscleLossLb} lb</p>
                <p className="text-sm text-zinc-400 mt-1">
                  estimated lean mass lost over those {out.yearsRemaining} years if you stay sedentary.
                </p>
              </div>
              <div>
                <p className="text-3xl font-bold text-white">{out.vo2DropPct}%</p>
                <p className="text-sm text-zinc-400 mt-1">
                  decline in cardiorespiratory fitness vs an active baseline.
                </p>
              </div>
            </div>
          </section>

          {/* Flip */}
          <section className="bg-gradient-to-br from-emerald-950 to-zinc-900 border border-emerald-500/30 rounded-2xl p-6 sm:p-8">
            <p className="text-xs uppercase tracking-wide text-emerald-400 font-semibold mb-2">
              But here is the flip
            </p>
            <h3 className="text-2xl font-bold text-white mb-4">
              {out.flipMonths} months of showing up would give you:
            </h3>
            <ul className="space-y-3 text-zinc-200">
              <FlipItem>
                <span className="font-semibold text-emerald-400">+{out.flipMuscleGainLb} lb of muscle</span>
                {' '}for an intermediate trainee with decent nutrition.
              </FlipItem>
              <FlipItem>
                <span className="font-semibold text-emerald-400">+{out.flipStrengthGainPct}% stronger</span>
                {' '}on the big compound lifts, conservatively.
              </FlipItem>
              <FlipItem>
                <span className="font-semibold text-emerald-400">Resting heart rate down 5 to 10 bpm</span>
                {' '}and a measurable VO2 bump.
              </FlipItem>
              <FlipItem>
                <span className="font-semibold text-emerald-400">The receipt above, ripped up.</span>
                {' '}You are now using the thing you pay for.
              </FlipItem>
            </ul>
          </section>

          {/* Downloadable card */}
          <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
            <div className="flex items-center justify-between flex-wrap gap-3 mb-4">
              <div>
                <h3 className="text-lg font-bold text-white">Share card</h3>
                <p className="text-sm text-zinc-400">Rendered locally. Nothing uploaded.</p>
              </div>
              <button
                onClick={handleDownload}
                className="px-5 py-2.5 rounded-xl bg-emerald-500 text-zinc-900 font-semibold hover:bg-emerald-400 transition shadow-lg shadow-emerald-500/20"
              >
                Download PNG
              </button>
            </div>
            <div className="rounded-xl overflow-hidden border border-zinc-800 bg-zinc-950">
              <canvas
                ref={canvasRef}
                className="w-full h-auto max-w-md mx-auto block"
                aria-label="Cost of skipping share card preview"
              />
            </div>
          </section>

          <InstallCta
            slug="cost-of-skipping-calculator"
            result={{
              monthlyCost,
              skipsPerMonth,
              totalWasted: out.totalWasted,
            }}
            primary="Hit your monthly workout target in Zealova. Set reminders, track streaks."
            secondary="Zealova schedules each workout, nudges you the morning of, and tracks the streak. Cut your skip rate in half and the lifetime tab above gets cut in half too."
          />
        </>
      )}

      <MethodologyFooter
        citations={[
          { text: 'ACSM Position Stand (2009). Progression Models in Resistance Training for Healthy Adults. MSSE 41(3).', url: 'https://pubmed.ncbi.nlm.nih.gov/19204579/' },
          { text: 'Fleg JL et al. (2005). Accelerated Longitudinal Decline of Aerobic Capacity in Healthy Older Adults. Circulation 112(5).', url: 'https://pubmed.ncbi.nlm.nih.gov/16061740/' },
          { text: 'Cruz-Jentoft AJ et al. (2019). Sarcopenia: revised European consensus on definition and diagnosis. Age and Ageing 48(1).', url: 'https://pubmed.ncbi.nlm.nih.gov/30312372/' },
          { text: 'Morton RW et al. (2018). A systematic review on protein supplementation and resistance training adaptations. BJSM 52(6).', url: 'https://pubmed.ncbi.nlm.nih.gov/28698222/' },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-4">
      <p className="text-xs uppercase tracking-wide text-zinc-500 font-semibold mb-1.5">{label}</p>
      <p className="text-xl font-bold text-white">{value}</p>
    </div>
  );
}

function FlipItem({ children }: { children: React.ReactNode }) {
  return (
    <li className="flex gap-3 text-sm leading-relaxed">
      <span className="text-emerald-500 mt-0.5">▸</span>
      <span>{children}</span>
    </li>
  );
}
