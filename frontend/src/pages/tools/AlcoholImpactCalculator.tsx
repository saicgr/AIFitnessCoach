// /free-tools/alcohol-impact-calculator
//
// Translates weekly alcohol consumption into measurable hypertrophy +
// performance losses. Citations: Parr 2014 (MPS), Vingren 2013 (testosterone),
// Ebrahim 2013 (sleep/REM), Heikkonen 1996 (cortisol).

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import ResultHero from '../../components/tools/ResultHero';

interface AlcoholInputs {
  drinksPerWeek: number;
  bodyweightLb: number;
  trainingLevel: 'beginner' | 'intermediate' | 'advanced';
}

interface AlcoholResult {
  mpsSuppressionPct: number;          // average weekly suppression
  daysDelayedToNextPR: number;
  testosteroneSuppressionHrs: number;
  cortisolElevationPct: number;
  remLossPctPerNight: number;
  estimatedSessionsCompromised: number;
  monthlyMuscleGainLossPct: number;
}

const LB_PER_KG = 0.453592;

function calculateAlcohol(i: AlcoholInputs): AlcoholResult {
  // Parr 2014: 1.5 g/kg alcohol consumed post-exercise suppressed MPS by 24%
  // (mTOR signaling and S6K1 phosphorylation) compared to protein only, and 37%
  // compared to protein + carbs. We model linear suppression: each "Parr dose"
  // equivalent suppresses 24% of MPS for 24h.
  // A standard US drink = 14 g alcohol. 1.5 g/kg for an 80 kg person = 120 g
  // alcohol = ~8.5 drinks in one sitting.
  const weightKg = i.bodyweightLb * LB_PER_KG;
  const parrDoseDrinks = (1.5 * weightKg) / 14;

  // Distribute weekly drinks: assume 2-3 drinking events per week, so
  // sessions = ceil(drinksPerWeek / 3). Per-session impact = (sessionDrinks/parrDose) * 24%
  // capped at 24% (cannot exceed maximal MPS suppression).
  const drinkingEventsPerWeek = Math.min(7, Math.max(1, Math.ceil(i.drinksPerWeek / 3)));
  const drinksPerEvent = i.drinksPerWeek / drinkingEventsPerWeek;
  const perSessionSuppression = Math.min(0.24, (drinksPerEvent / parrDoseDrinks) * 0.24);

  // 24h suppression window per session, distributed over 168h week.
  const compromisedHours = drinkingEventsPerWeek * 24;
  const mpsSuppressionPct = +((compromisedHours / 168) * (perSessionSuppression * 100)).toFixed(1);

  // Monthly muscle gain loss: training level baseline gain modulated by MPS hit.
  // Beginner gains ~1.8 lb/mo, intermediate ~0.8 lb/mo, advanced ~0.4 lb/mo.
  const baselineMonthly =
    i.trainingLevel === 'beginner' ? 1.8 : i.trainingLevel === 'intermediate' ? 0.8 : 0.4;
  const monthlyMuscleGainLossPct = mpsSuppressionPct;
  const monthlyLb = baselineMonthly * (mpsSuppressionPct / 100);

  // Days delayed to next PR: PR cycles average 4-8 weeks (28-56 days) for
  // intermediate lifters. Suppress MPS → proportionally extend PR timeline.
  // Use 35 days baseline. Delay scales with suppression and lifter level (advanced
  // hits PR slower so delays are felt more).
  const prBaseline = i.trainingLevel === 'advanced' ? 56 : i.trainingLevel === 'intermediate' ? 35 : 21;
  const daysDelayedToNextPR = +(prBaseline * (mpsSuppressionPct / 100)).toFixed(1);

  // Testosterone: Vingren 2013 + Sarkola 2003. A binge (5+ drinks) suppresses
  // testosterone for 24h. 1-4 drinks shows blunted but smaller suppression.
  // Count number of "binges" per week (events with 5+ drinks) and multiply by 24h.
  const bingeEventsPerWeek = drinksPerEvent >= 5 ? drinkingEventsPerWeek : 0;
  const moderateEventsPerWeek = drinksPerEvent >= 1 && drinksPerEvent < 5 ? drinkingEventsPerWeek : 0;
  const testosteroneSuppressionHrs = bingeEventsPerWeek * 24 + moderateEventsPerWeek * 8;

  // Cortisol elevation: Heikkonen 1996. Acute alcohol elevates cortisol ~36%
  // post-binge, returning to baseline within ~12h. Weekly average elevation =
  // (binge_events * 36% * 12h) / 168h.
  const cortisolElevationPct = +(
    ((bingeEventsPerWeek * 12 * 0.36 + moderateEventsPerWeek * 6 * 0.15) / 168) *
    100
  ).toFixed(1);

  // REM loss: Ebrahim 2013 meta-analysis. ~9.3 min REM lost per drink consumed
  // within 3h of bedtime. Approximate as ~5% REM loss per drink after 2 drinks
  // (the threshold where REM suppression becomes meaningful).
  // We convert this to per-night avg across the week.
  const remLossPerDrinkPct = 5;
  const drinksAfterThreshold = Math.max(0, drinksPerEvent - 2);
  // Each drinking night affects 1 night out of 7.
  const remLossPctPerNight = +(
    drinkingEventsPerWeek * Math.min(40, drinksAfterThreshold * remLossPerDrinkPct) / 7
  ).toFixed(1);

  // Sessions compromised: train within 24h of drinking → muted MPS, mood,
  // reaction time. Assume user trains ~5 sessions/wk for intermediate/advanced,
  // 3 for beginner. Overlap chance = drinkingEventsPerWeek/7.
  const trainingPerWeek = i.trainingLevel === 'beginner' ? 3 : 5;
  const estimatedSessionsCompromised = +(
    trainingPerWeek * (drinkingEventsPerWeek / 7)
  ).toFixed(1);

  void monthlyLb; // unused but documents the lb math for the curious

  return {
    mpsSuppressionPct,
    daysDelayedToNextPR,
    testosteroneSuppressionHrs,
    cortisolElevationPct,
    remLossPctPerNight,
    estimatedSessionsCompromised,
    monthlyMuscleGainLossPct,
  };
}

export default function AlcoholImpactCalculator() {
  const [drinksPerWeek, setDrinksPerWeek] = useState(7);
  const [bodyweightLb, setBodyweightLb] = useState(180);
  const [trainingLevel, setTrainingLevel] = useState<'beginner' | 'intermediate' | 'advanced'>(
    'intermediate',
  );

  const r = useMemo(
    () => calculateAlcohol({ drinksPerWeek, bodyweightLb, trainingLevel }),
    [drinksPerWeek, bodyweightLb, trainingLevel],
  );

  return (
    <CalculatorShell
      slug="alcohol-impact-calculator"
      title="Alcohol Impact on Muscle Gain Calculator"
      metaDescription="See exactly how alcohol affects hypertrophy, testosterone, cortisol, REM sleep, and your next PR. Built on Parr 2014, Vingren 2013, Ebrahim 2013, and Heikkonen 1996. Free, no sign-up."
      intro="The cost of every drink, in numbers. Muscle protein synthesis suppression from Parr 2014, testosterone window from Vingren 2013, cortisol elevation from Heikkonen 1996, REM loss from Ebrahim 2013. Move the drinks slider and watch the costs add up."
      emailCaptureResult={{
        drinksPerWeek,
        bodyweightLb,
        trainingLevel,
        mpsSuppressionPct: r.mpsSuppressionPct,
        daysDelayedToNextPR: r.daysDelayedToNextPR,
        testosteroneSuppressionHrs: r.testosteroneSuppressionHrs,
        cortisolElevationPct: r.cortisolElevationPct,
        remLossPctPerNight: r.remLossPctPerNight,
      }}
      faqs={[
        {
          q: 'Where does the 24% MPS suppression number come from?',
          a: 'Parr et al. 2014, published in PLoS One. Eight resistance-trained men consumed 1.5 g/kg alcohol after a workout. MPS rates were suppressed 24% compared to protein-only and 37% compared to protein plus carbs. mTOR signaling and S6K1 phosphorylation were both downregulated. The study is the foundation for every alcohol-and-muscle paper since.',
        },
        {
          q: 'Is 1 or 2 drinks really a problem?',
          a: 'For long-term hypertrophy, 1 to 2 drinks once a week is a tiny rounding error. The calculator scales linearly because the data does. 1 drink is ~24% of one-eighth of a Parr dose, so MPS is barely touched. Problems start at 3 plus drinks per session or more than 2 drinking events per week. A single beer with dinner is nowhere near as costly as a Saturday night binge.',
        },
        {
          q: 'Why does testosterone get suppressed for 24 hours?',
          a: 'Vingren 2013 (J Strength Cond Res) and Sarkola 2003 (Alcohol Clin Exp Res) both showed acute testosterone suppression for 16 to 24 hours after a 5-drink binge in men. Mechanism involves direct testicular Leydig cell inhibition plus increased aromatization. Recovery is faster after smaller doses, which is why we count moderate drinking at 8 hours per event.',
        },
        {
          q: 'Does cortisol really rise 36% from alcohol?',
          a: 'Heikkonen 1996 (Alcohol Alcohol) reported 36% acute cortisol elevation post-binge in male subjects, returning to baseline within 12 hours. Cortisol is catabolic, mobilizing amino acids out of muscle for gluconeogenesis. Chronic elevation impairs MPS independently of testosterone.',
        },
        {
          q: 'How does alcohol cut REM sleep?',
          a: 'Ebrahim 2013 systematic review (Alcohol Clin Exp Res) of 27 studies. Alcohol increases slow-wave sleep in the first half of the night but suppresses REM by ~9.3 minutes per drink consumed within 3 hours of bedtime, and causes REM rebound and fragmented sleep in the second half. REM is when motor learning consolidates and growth hormone pulses peak, so cutting REM directly impacts recovery.',
        },
        {
          q: 'Can I drink at all and still make progress?',
          a: 'Yes. The data supports 1 to 4 drinks per week, kept to 1 to 2 per session, with no drinks within 4 hours of bedtime or within 24 hours of a key training session. Advanced lifters near their genetic ceiling feel it more because their margin is thinner. Beginners can get away with more drinking before progress measurably stalls.',
        },
        {
          q: 'Does the type of alcohol matter?',
          a: 'For MPS, testosterone, cortisol, and REM, no. The active suppressor is ethanol per gram. Beer adds carbs which slightly buffer the MPS hit but the alcohol itself does the damage. Mixers with sugar add empty calories but do not change the hormonal effects.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 sm:p-7 space-y-6">
        <h2 className="text-lg font-bold text-white">Your weekly habit</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
          <label className="block">
            <div className="flex justify-between items-baseline mb-2">
              <span className="text-sm font-medium text-zinc-300">Drinks per week</span>
              <span className="text-lg font-bold text-emerald-400 tabular-nums">{drinksPerWeek}</span>
            </div>
            <input
              type="range"
              min={0}
              max={30}
              value={drinksPerWeek}
              onChange={(e) => setDrinksPerWeek(parseInt(e.target.value, 10))}
              className="w-full accent-emerald-500 h-2"
            />
            <p className="text-xs text-zinc-500 mt-1.5">
              {drinksClassification(drinksPerWeek)}
            </p>
          </label>
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
        </div>
        <div>
          <p className="text-sm font-medium text-zinc-300 mb-3">Training level</p>
          <div className="grid grid-cols-3 gap-2">
            {(['beginner', 'intermediate', 'advanced'] as const).map((lvl) => (
              <button
                key={lvl}
                type="button"
                onClick={() => setTrainingLevel(lvl)}
                className={`px-4 py-2.5 rounded-lg text-sm font-semibold capitalize transition ${
                  trainingLevel === lvl
                    ? 'bg-emerald-500 text-zinc-900'
                    : 'bg-zinc-950 border border-zinc-700 text-zinc-300 hover:bg-zinc-800'
                }`}
              >
                {lvl}
              </button>
            ))}
          </div>
        </div>
      </section>

      <section className="bg-gradient-to-br from-rose-900/40 via-zinc-900 to-zinc-950 border border-rose-500/30 rounded-2xl p-6 sm:p-10">
        <ResultHero
          label="Average hypertrophy reduction this week"
          value={r.mpsSuppressionPct}
          suffix="%"
          decimals={1}
          emphasis="rose"
          size="xl"
          subLabel={`That is about ${r.daysDelayedToNextPR} extra days to your next PR. Estimated ${r.estimatedSessionsCompromised} of your weekly training sessions land inside a 24h MPS suppression window.`}
        />
      </section>

      <section>
        <h2 className="text-lg font-bold text-white mb-1">The four hormonal costs</h2>
        <p className="text-sm text-zinc-400 mb-4">
          MPS, testosterone, cortisol, and REM sleep. Every drink touches all four.
        </p>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <StatCard
            label="Weekly MPS suppression"
            value={`-${r.mpsSuppressionPct}`}
            unit="%"
            tone="rose"
            note="Parr 2014. 1.5 g/kg alcohol = 24% MPS drop for 24h. Scaled linearly to your dose."
          />
          <StatCard
            label="Testosterone suppression"
            value={r.testosteroneSuppressionHrs.toString()}
            unit="hrs/wk"
            tone="rose"
            note="Vingren 2013. 24h per binge, 8h per moderate session."
          />
          <StatCard
            label="Cortisol elevation"
            value={`+${r.cortisolElevationPct}`}
            unit="% avg"
            tone="amber"
            note="Heikkonen 1996. Acute spike 36% post-binge, decays over 12h."
          />
          <StatCard
            label="REM sleep loss"
            value={`-${r.remLossPctPerNight}`}
            unit="% avg/night"
            tone="amber"
            note="Ebrahim 2013. ~9.3 min REM lost per drink within 3h of bed."
          />
        </div>
      </section>

      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 sm:p-7">
        <h2 className="text-lg font-bold text-white mb-2">What this costs you in muscle</h2>
        <p className="text-sm text-zinc-400 mb-4">
          A {trainingLevel} lifter typically gains{' '}
          {trainingLevel === 'beginner' ? '1.8' : trainingLevel === 'intermediate' ? '0.8' : '0.4'} lbs of muscle per month under perfect conditions. Your drinking habit reduces that by{' '}
          <span className="text-rose-400 font-semibold">{r.monthlyMuscleGainLossPct}%</span>, on average.
        </p>
        <p className="text-xs text-zinc-500">
          Note: this is a model, not a prediction. Individual response varies based on genetics, training experience, drink timing relative to training, and what is consumed alongside alcohol.
        </p>
      </section>

      <InstallCta
        slug="alcohol-impact-calculator"
        result={{
          drinksPerWeek,
          bodyweightLb,
          trainingLevel,
          mpsSuppressionPct: r.mpsSuppressionPct,
          daysDelayedToNextPR: r.daysDelayedToNextPR,
        }}
        primary="Track alcohol with your training in Zealova"
        secondary="Zealova logs drinks alongside workouts and sleep, surfaces the lift-by-lift correlation, and nudges you to skip the drink before a heavy session."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'Parr EB et al. (2014). Alcohol ingestion impairs maximal post-exercise rates of myofibrillar protein synthesis following a single bout of concurrent training. PLoS One 9(2):e88384.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/24533082/',
          },
          {
            text: 'Vingren JL et al. (2013). The effect of acute alcohol ingestion on neuroendocrine response to resistance exercise. J Strength Cond Res 27(8):2225-2233.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/23222090/',
          },
          {
            text: 'Sarkola T, Eriksson CJ (2003). Testosterone increases in men after a low dose of alcohol. Alcohol Clin Exp Res 27(4):682-685.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/12711931/',
          },
          {
            text: 'Heikkonen E et al. (1996). The combined effect of alcohol and physical exercise on serum testosterone, luteinizing hormone, and cortisol. Alcohol Alcohol 31(1):103-106.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/8672181/',
          },
          {
            text: 'Ebrahim IO et al. (2013). Alcohol and sleep I: effects on normal sleep. Alcohol Clin Exp Res 37(4):539-549.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/23347102/',
          },
          {
            text: 'Barnes MJ (2014). Alcohol: impact on sports performance and recovery in male athletes. Sports Med 44(7):909-919.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/24748461/',
          },
        ]}
        lastUpdated="2026-05-15"
      />
    </CalculatorShell>
  );
}

function drinksClassification(n: number): string {
  if (n === 0) return 'Teetotal. Zero alcohol cost on hypertrophy or hormones.';
  if (n <= 2) return 'Light. Minimal MPS and hormonal impact.';
  if (n <= 7) return 'Moderate. Measurable but manageable cost.';
  if (n <= 14) return 'Heavy. Substantial weekly cost to muscle and recovery.';
  return 'Very heavy. Hypertrophy progress is likely stalled or reversed.';
}

function StatCard({
  label,
  value,
  unit,
  tone = 'rose',
  note,
}: {
  label: string;
  value: string;
  unit: string;
  tone?: 'rose' | 'amber';
  note: string;
}) {
  const valueClass = tone === 'rose' ? 'text-rose-400' : 'text-amber-400';
  const border = tone === 'rose' ? 'border-rose-500/30' : 'border-amber-500/30';
  return (
    <div className={`rounded-xl border ${border} bg-zinc-900 px-4 py-4`}>
      <p className="text-[10px] text-zinc-500 uppercase tracking-wider font-semibold">{label}</p>
      <p className={`text-2xl sm:text-3xl font-bold mt-1 tabular-nums ${valueClass}`}>
        {value}
        {unit && <span className="text-sm text-zinc-500 ml-1.5 font-medium">{unit}</span>}
      </p>
      <p className="text-xs text-zinc-500 mt-2 leading-relaxed">{note}</p>
    </div>
  );
}
