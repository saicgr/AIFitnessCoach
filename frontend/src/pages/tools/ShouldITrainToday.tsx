// /free-tools/should-i-train-today
//
// Five-question subjective readiness quiz. Weighted score maps to one of three
// recommendations: train, modify, rest. Mirrors the perceived-stress and
// session-RPE methodology used in athlete-monitoring research.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

type Fueled = 'yes' | 'no' | 'unsure';
type DaysSince = '0' | '1' | '2' | '3+';

interface Breakdown {
  factor: string;
  value: string;
  score: number;
}

function score(sleep: number, soreness: number, stress: number, days: DaysSince, fueled: Fueled): {
  total: number;
  breakdown: Breakdown[];
} {
  const breakdown: Breakdown[] = [];

  let sleepScore = 0;
  if (sleep < 5) sleepScore = -3;
  else if (sleep < 7) sleepScore = -1;
  else if (sleep >= 9) sleepScore = 1;
  breakdown.push({ factor: 'Sleep', value: `${sleep} h`, score: sleepScore });

  let soreScore = 0;
  if (soreness >= 8) soreScore = -2;
  else if (soreness >= 5) soreScore = -1;
  breakdown.push({ factor: 'Soreness', value: `${soreness}/10`, score: soreScore });

  let stressScore = 0;
  if (stress >= 8) stressScore = -2;
  else if (stress >= 5) stressScore = -1;
  breakdown.push({ factor: 'Stress', value: `${stress}/10`, score: stressScore });

  let daysScore = 0;
  if (days === '0') daysScore = -1;
  else if (days === '1' || days === '2') daysScore = 1;
  else daysScore = 2;
  breakdown.push({ factor: 'Days since training', value: days, score: daysScore });

  let fuelScore = 0;
  if (fueled === 'unsure') fuelScore = -1;
  else if (fueled === 'no') fuelScore = -2;
  breakdown.push({ factor: 'Fueled', value: fueled, score: fuelScore });

  const total = breakdown.reduce((sum, b) => sum + b.score, 0);
  return { total, breakdown };
}

interface Verdict {
  label: string;
  tone: 'go' | 'warn' | 'stop';
  headline: string;
  detail: string;
  actions: string[];
}

function getVerdict(total: number): Verdict {
  if (total >= 1) {
    return {
      label: 'TRAIN',
      tone: 'go',
      headline: 'You are good to go',
      detail: 'Your readiness signals add up. Run your planned session as written.',
      actions: [
        'Stick to your planned weights and rep targets',
        'Warm up thoroughly, you have full clearance to push',
        'Log RPE on top sets so tomorrow has data',
      ],
    };
  }
  if (total >= -2) {
    return {
      label: 'MODIFY',
      tone: 'warn',
      headline: 'Train, but pull back',
      detail: 'Recovery is partial. Reduce intensity or volume rather than skipping.',
      actions: [
        'Cap top sets at RPE 7. Leave 3 reps in reserve',
        'Drop one working set per exercise',
        'Skip the accessory finisher if you usually do one',
        'Reassess between exercises. If something hurts, stop',
      ],
    };
  }
  return {
    label: 'REST',
    tone: 'stop',
    headline: 'Take the day off training',
    detail: 'Multiple recovery systems are flagging. Pushing through compounds fatigue and slows progress.',
    actions: [
      '20-30 minutes of light walking',
      '10 minutes of mobility, focus on tight areas',
      'Eat to fuel tomorrow, not to compensate today',
      'Sleep priority tonight. Phone out of the bedroom',
    ],
  };
}

const toneStyles = {
  go: 'border-emerald-500/40 bg-emerald-950/30',
  warn: 'border-amber-500/40 bg-amber-950/30',
  stop: 'border-rose-500/40 bg-rose-950/30',
};

const toneLabel = {
  go: 'text-emerald-400',
  warn: 'text-amber-400',
  stop: 'text-rose-400',
};

export default function ShouldITrainToday() {
  const [sleep, setSleep] = useState(7);
  const [soreness, setSoreness] = useState(4);
  const [stress, setStress] = useState(4);
  const [days, setDays] = useState<DaysSince>('1');
  const [fueled, setFueled] = useState<Fueled>('yes');

  const { total, breakdown } = useMemo(
    () => score(sleep, soreness, stress, days, fueled),
    [sleep, soreness, stress, days, fueled],
  );
  const verdict = getVerdict(total);

  const negativeFactors = breakdown.filter((b) => b.score < 0);

  return (
    <CalculatorShell
      slug="should-i-train-today"
      title="Should I Train Today?"
      metaDescription="Five-question decision tool that tells you whether to train, modify, or rest today. Scores sleep, soreness, stress, training frequency, and fueling against athlete-monitoring research."
      intro="Five questions. One answer. Built on the perceived recovery scales used by sports scientists to monitor athlete readiness, scaled down for everyday lifters."
      faqs={[
        {
          q: 'Is this scientifically validated?',
          a: 'The individual inputs come from validated monitoring tools used with athletes: total sleep time, perceived muscle soreness, perceived stress, time since last session, and energy availability. The weighting is a practical heuristic informed by Halson 2014 and Coutts 2008, not a clinically validated composite score.',
        },
        {
          q: 'When should I never train, regardless of score?',
          a: 'Sharp localized pain, fever, dizziness, chest pain, recent injury that has not been cleared, or symptoms of overreaching like persistent elevated resting heart rate. This tool measures readiness for normal training, not whether you should see a doctor.',
        },
        {
          q: 'I scored TRAIN but I feel terrible. Should I still go?',
          a: 'No. Subjective feel beats any calculator. If the math says go but your gut says no, listen to your gut. The score is a prompt for honest reflection, not a court order.',
        },
        {
          q: 'How does this compare to Whoop or Oura recovery scores?',
          a: 'Whoop and Oura use heart-rate variability, resting heart rate, and respiratory rate as objective inputs. Those are gold-standard signals if you wear a device. This tool covers the same conceptual ground using subjective inputs anyone can answer, no hardware required.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8 space-y-6">
        <h2 className="text-lg font-bold text-white">Quick check-in</h2>

        <label className="block">
          <span className="flex items-center justify-between text-sm font-medium text-zinc-300 mb-2">
            <span>1. Hours of sleep last night</span>
            <span className="font-mono text-emerald-400">{sleep} h</span>
          </span>
          <input
            type="range"
            min={0}
            max={12}
            step={0.5}
            value={sleep}
            onChange={(e) => setSleep(parseFloat(e.target.value))}
            className="w-full accent-emerald-500"
          />
        </label>

        <label className="block">
          <span className="flex items-center justify-between text-sm font-medium text-zinc-300 mb-2">
            <span>2. Soreness level</span>
            <span className="font-mono text-emerald-400">{soreness}/10</span>
          </span>
          <input
            type="range"
            min={1}
            max={10}
            step={1}
            value={soreness}
            onChange={(e) => setSoreness(parseFloat(e.target.value))}
            className="w-full accent-emerald-500"
          />
          <p className="text-xs text-zinc-500 mt-1">1 = no soreness. 10 = walking hurts.</p>
        </label>

        <label className="block">
          <span className="flex items-center justify-between text-sm font-medium text-zinc-300 mb-2">
            <span>3. Stress level</span>
            <span className="font-mono text-emerald-400">{stress}/10</span>
          </span>
          <input
            type="range"
            min={1}
            max={10}
            step={1}
            value={stress}
            onChange={(e) => setStress(parseFloat(e.target.value))}
            className="w-full accent-emerald-500"
          />
          <p className="text-xs text-zinc-500 mt-1">1 = calm. 10 = wired and fried.</p>
        </label>

        <div className="block">
          <span className="block text-sm font-medium text-zinc-300 mb-2">4. Days since your last training day</span>
          <div className="grid grid-cols-4 gap-2">
            {(['0', '1', '2', '3+'] as DaysSince[]).map((d) => (
              <button
                key={d}
                onClick={() => setDays(d)}
                className={`px-3 py-2 rounded-lg text-sm font-medium border transition ${
                  days === d
                    ? 'bg-emerald-500 text-zinc-900 border-emerald-500'
                    : 'bg-zinc-950 border-zinc-700 text-zinc-300 hover:border-zinc-500'
                }`}
              >
                {d}
              </button>
            ))}
          </div>
        </div>

        <div className="block">
          <span className="block text-sm font-medium text-zinc-300 mb-2">5. Ate enough to fuel a workout today?</span>
          <div className="grid grid-cols-3 gap-2">
            {([
              { v: 'yes' as Fueled, label: 'Yes' },
              { v: 'unsure' as Fueled, label: 'Not sure' },
              { v: 'no' as Fueled, label: 'No' },
            ]).map((opt) => (
              <button
                key={opt.v}
                onClick={() => setFueled(opt.v)}
                className={`px-3 py-2 rounded-lg text-sm font-medium border transition ${
                  fueled === opt.v
                    ? 'bg-emerald-500 text-zinc-900 border-emerald-500'
                    : 'bg-zinc-950 border-zinc-700 text-zinc-300 hover:border-zinc-500'
                }`}
              >
                {opt.label}
              </button>
            ))}
          </div>
        </div>
      </section>

      <section className={`rounded-2xl border p-6 sm:p-8 ${toneStyles[verdict.tone]}`}>
        <p className={`text-xs uppercase tracking-widest font-bold mb-2 ${toneLabel[verdict.tone]}`}>
          {verdict.label}
        </p>
        <h2 className="text-2xl sm:text-3xl font-bold text-white mb-2">{verdict.headline}</h2>
        <p className="text-sm text-zinc-300 mb-4">{verdict.detail}</p>
        <ul className="space-y-1.5">
          {verdict.actions.map((a) => (
            <li key={a} className="text-sm text-zinc-200 flex gap-2">
              <span className="text-emerald-400">›</span>
              <span>{a}</span>
            </li>
          ))}
        </ul>
        <div className="mt-5 pt-4 border-t border-white/10 flex items-center justify-between">
          <span className="text-xs text-zinc-400">Readiness score</span>
          <span className="font-mono font-bold text-white text-lg">
            {total > 0 ? `+${total}` : total}
          </span>
        </div>
      </section>

      <section>
        <h2 className="text-lg font-bold text-white mb-4">Score breakdown</h2>
        <div className="overflow-x-auto rounded-2xl border border-zinc-800">
          <table className="w-full text-sm">
            <thead className="bg-zinc-900 border-b border-zinc-800">
              <tr>
                <th className="text-left px-4 py-3 font-semibold text-zinc-300">Factor</th>
                <th className="text-left px-4 py-3 font-semibold text-zinc-300">Your answer</th>
                <th className="text-right px-4 py-3 font-semibold text-zinc-300">Impact</th>
              </tr>
            </thead>
            <tbody>
              {breakdown.map((b) => (
                <tr key={b.factor} className="border-b border-zinc-800 last:border-b-0 bg-zinc-950">
                  <td className="px-4 py-2.5 text-white font-medium">{b.factor}</td>
                  <td className="px-4 py-2.5 text-zinc-400">{b.value}</td>
                  <td
                    className={`px-4 py-2.5 text-right font-mono font-semibold ${
                      b.score > 0 ? 'text-emerald-400' : b.score < 0 ? 'text-rose-400' : 'text-zinc-500'
                    }`}
                  >
                    {b.score > 0 ? `+${b.score}` : b.score}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {negativeFactors.length > 0 && (
          <p className="text-xs text-zinc-500 mt-3">
            What is hurting your score: {negativeFactors.map((b) => b.factor.toLowerCase()).join(', ')}.
          </p>
        )}
      </section>

      <InstallCta
        slug="should-i-train-today"
        result={{ total, sleep, soreness, stress, days, fueled }}
        primary="Zealova auto-adjusts your daily plan based on logged sleep, soreness, and stress"
        secondary="Skip the daily quiz. Zealova reads your sleep, soreness logs, and check-ins to grade readiness, then trims sets and load automatically."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'Halson SL (2014). Monitoring training load to understand fatigue in athletes. Sports Medicine 44(Suppl 2):S139-S147.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/25200666/',
          },
          {
            text: "Coutts AJ, Reaburn P (2008). Monitoring changes in rugby league players' perceived stress and recovery during intensified training. Perceptual and Motor Skills 106(3):904-916.",
            url: 'https://pubmed.ncbi.nlm.nih.gov/18712214/',
          },
          {
            text: 'Saw AE, Main LC, Gastin PB (2016). Monitoring the athlete training response: subjective self-reported measures trump commonly used objective measures. British Journal of Sports Medicine 50(5):281-291.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/26423706/',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
