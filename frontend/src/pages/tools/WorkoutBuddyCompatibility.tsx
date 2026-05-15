// /free-tools/workout-buddy-compatibility
//
// 8-question quiz produces an 8-char code (one digit per answer index 0-3).
// Comparison mode counts matching answers, with schedule + style 2x weighted.
// Shareable result card rendered to canvas at 1080x1350.

import { useMemo, useRef, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

interface Question {
  id: string;
  prompt: string;
  options: string[];
  weight: number;
}

const QUESTIONS: Question[] = [
  {
    id: 'time',
    prompt: 'Preferred workout time',
    options: ['Morning', 'Midday', 'Evening', 'Late night'],
    weight: 2,
  },
  {
    id: 'style',
    prompt: 'Training style',
    options: ['Powerlifting', 'Bodybuilding', 'CrossFit', 'Cardio-focused'],
    weight: 2,
  },
  {
    id: 'goal',
    prompt: 'Primary goal',
    options: ['Strength', 'Muscle', 'Endurance', 'General health'],
    weight: 1,
  },
  {
    id: 'vibe',
    prompt: 'Gym vibe',
    options: ['Silent grinder', 'Chatty', 'Music-blasting', 'Influencer mode'],
    weight: 1,
  },
  {
    id: 'rest',
    prompt: 'Rest between sets',
    options: ['30 seconds', '1 minute', '2-3 minutes', '5+ minutes'],
    weight: 1,
  },
  {
    id: 'pre',
    prompt: 'Pre-workout snack',
    options: ['Full meal', 'Banana', 'Pre-workout drink', 'Nothing'],
    weight: 1,
  },
  {
    id: 'days',
    prompt: 'Days per week',
    options: ['3', '4', '5', '6-7'],
    weight: 1,
  },
  {
    id: 'push',
    prompt: 'When you are struggling on a set',
    options: ['Spot me hard', 'Let me fail safely', 'Encourage, do not touch', 'Just film it for the gram'],
    weight: 1,
  },
];

function encodeAnswers(answers: number[]): string {
  return answers.map((a) => a.toString()).join('');
}

function decodeCode(code: string): number[] | null {
  if (code.length !== QUESTIONS.length) return null;
  const arr: number[] = [];
  for (const c of code) {
    const n = parseInt(c, 10);
    if (Number.isNaN(n) || n < 0 || n > 3) return null;
    arr.push(n);
  }
  return arr;
}

function compatibilityScore(a: number[], b: number[]): number {
  let matched = 0;
  let total = 0;
  QUESTIONS.forEach((q, i) => {
    total += q.weight;
    if (a[i] === b[i]) matched += q.weight;
  });
  return Math.round((matched / total) * 100);
}

function compatibilityLabel(pct: number): { label: string; tone: 'green' | 'amber' | 'red' } {
  if (pct >= 80) return { label: 'Soulmate spotters', tone: 'green' };
  if (pct >= 60) return { label: 'Solid gym pair', tone: 'green' };
  if (pct >= 40) return { label: 'Workable, with compromise', tone: 'amber' };
  if (pct >= 20) return { label: 'Different planets', tone: 'amber' };
  return { label: 'Train alone, friend', tone: 'red' };
}

const toneStyles = {
  green: 'border-emerald-500/40 bg-emerald-950/30 text-emerald-400',
  amber: 'border-amber-500/40 bg-amber-950/30 text-amber-400',
  red: 'border-rose-500/40 bg-rose-950/30 text-rose-400',
};

export default function WorkoutBuddyCompatibility() {
  const [answers, setAnswers] = useState<(number | null)[]>(Array(QUESTIONS.length).fill(null));
  const [compareCode, setCompareCode] = useState('');
  const canvasRef = useRef<HTMLCanvasElement>(null);

  const allAnswered = answers.every((a) => a !== null);
  const myCode = useMemo(() => (allAnswered ? encodeAnswers(answers as number[]) : ''), [allAnswered, answers]);

  const otherAnswers = useMemo(() => decodeCode(compareCode.trim()), [compareCode]);
  const compareResult = useMemo(() => {
    if (!allAnswered || !otherAnswers) return null;
    const pct = compatibilityScore(answers as number[], otherAnswers);
    return { pct, ...compatibilityLabel(pct) };
  }, [allAnswered, answers, otherAnswers]);

  const setAnswer = (qIdx: number, oIdx: number) => {
    const next = [...answers];
    next[qIdx] = oIdx;
    setAnswers(next);
  };

  const downloadCard = () => {
    const canvas = canvasRef.current;
    if (!canvas || !allAnswered) return;
    canvas.width = 1080;
    canvas.height = 1350;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Background gradient
    const g = ctx.createLinearGradient(0, 0, 1080, 1350);
    g.addColorStop(0, '#064e3b');
    g.addColorStop(1, '#09090b');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, 1080, 1350);

    // Header
    ctx.fillStyle = '#10b981';
    ctx.font = 'bold 36px system-ui, -apple-system, sans-serif';
    ctx.fillText('GYM BUDDY CODE', 60, 120);

    // Big code
    ctx.fillStyle = '#ffffff';
    ctx.font = 'bold 180px ui-monospace, monospace';
    const codeText = myCode;
    ctx.fillText(codeText, 60, 320);

    // Compatibility section if comparing
    if (compareResult && otherAnswers) {
      ctx.fillStyle = '#a1a1aa';
      ctx.font = '32px system-ui, sans-serif';
      ctx.fillText('vs', 60, 440);

      ctx.fillStyle = '#ffffff';
      ctx.font = 'bold 120px ui-monospace, monospace';
      ctx.fillText(encodeAnswers(otherAnswers), 60, 580);

      ctx.fillStyle = '#10b981';
      ctx.font = 'bold 220px system-ui, sans-serif';
      ctx.fillText(`${compareResult.pct}%`, 60, 850);

      ctx.fillStyle = '#ffffff';
      ctx.font = 'bold 56px system-ui, sans-serif';
      ctx.fillText('compatibility', 60, 920);

      ctx.fillStyle = '#a1a1aa';
      ctx.font = '40px system-ui, sans-serif';
      ctx.fillText(compareResult.label, 60, 990);
    } else {
      ctx.fillStyle = '#a1a1aa';
      ctx.font = '36px system-ui, sans-serif';
      ctx.fillText('Share your code. Find your gym match.', 60, 440);
    }

    // Footer watermark
    ctx.fillStyle = '#10b981';
    ctx.font = 'bold 32px system-ui, sans-serif';
    ctx.fillText('zealova.com', 60, 1280);

    ctx.fillStyle = '#71717a';
    ctx.font = '24px system-ui, sans-serif';
    ctx.fillText('Find a real workout buddy in the app', 60, 1320);

    const link = document.createElement('a');
    link.download = `buddy-code-${myCode}.png`;
    link.href = canvas.toDataURL('image/png');
    link.click();
  };

  return (
    <CalculatorShell
      slug="workout-buddy-compatibility"
      title="Workout Buddy Compatibility Quiz"
      metaDescription="Eight questions, one 8-character gym compatibility code. Compare codes with a friend to see if you would survive lifting together. Shareable result card with your match percentage."
      intro="Answer eight questions. Get an eight-character code. Swap codes with someone, paste theirs below, and we will tell you if you are a real gym pair or a guaranteed argument about rest times."
      faqs={[
        {
          q: 'How is the compatibility percentage calculated?',
          a: 'We count matching answers across all eight questions, with schedule and training style weighted 2x because mismatched timing or style is a dealbreaker. Maximum weight is 10, so a perfect match is 10/10 = 100 percent.',
        },
        {
          q: 'What does the 8-character code actually encode?',
          a: 'Each character is the index (0-3) of your answer to one question, in order. So 12031203 means you picked option 1 for question 1, option 2 for question 2, and so on. The code is lossless. Two people with the same code answered every question identically.',
        },
        {
          q: 'Can I share my code on social?',
          a: 'Yes. Hit the download button after completing the quiz. You get a 1080x1350 card sized for Instagram and Twitter, with your code, your match score if you compared, and a Zealova watermark.',
        },
        {
          q: 'What does a low score actually mean?',
          a: 'It means you train differently. That is not bad, but it does mean you will struggle to share sessions productively. A powerlifter and a CrossFitter can both be excellent training partners, just not for each other. Find someone whose plan looks like yours.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8 space-y-6">
        <h2 className="text-lg font-bold text-white">The quiz</h2>
        {QUESTIONS.map((q, qIdx) => (
          <div key={q.id}>
            <p className="text-sm font-medium text-zinc-300 mb-2">
              <span className="text-emerald-400 mr-2">{qIdx + 1}.</span>
              {q.prompt}
              {q.weight === 2 && (
                <span className="ml-2 text-[10px] uppercase tracking-wide px-1.5 py-0.5 rounded bg-emerald-500/15 text-emerald-400 font-semibold">
                  2x weight
                </span>
              )}
            </p>
            <div className="grid grid-cols-2 gap-2">
              {q.options.map((opt, oIdx) => (
                <button
                  key={opt}
                  onClick={() => setAnswer(qIdx, oIdx)}
                  className={`px-3 py-2 rounded-lg text-sm font-medium border transition text-left ${
                    answers[qIdx] === oIdx
                      ? 'bg-emerald-500 text-zinc-900 border-emerald-500'
                      : 'bg-zinc-950 border-zinc-700 text-zinc-300 hover:border-zinc-500'
                  }`}
                >
                  {opt}
                </button>
              ))}
            </div>
          </div>
        ))}
      </section>

      {allAnswered && (
        <section className="rounded-2xl border border-emerald-500/40 bg-emerald-950/30 p-6 sm:p-8">
          <p className="text-xs uppercase tracking-widest text-emerald-400 font-bold mb-2">Your code</p>
          <p className="font-mono text-5xl sm:text-6xl font-bold text-white tracking-wider mb-3">
            {myCode}
          </p>
          <button
            onClick={() => {
              navigator.clipboard?.writeText(myCode);
            }}
            className="text-xs text-emerald-400 hover:text-emerald-300 underline"
          >
            Copy code
          </button>
        </section>
      )}

      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <h2 className="text-lg font-bold text-white mb-3">Compare with a friend</h2>
        <p className="text-sm text-zinc-400 mb-4">
          Paste their 8-character code below to see your compatibility.
        </p>
        <input
          type="text"
          value={compareCode}
          onChange={(e) => setCompareCode(e.target.value.replace(/[^0-3]/g, '').slice(0, 8))}
          placeholder="12031203"
          maxLength={8}
          className="w-full px-4 py-3 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-base font-mono tracking-widest focus:outline-none focus:ring-2 focus:ring-emerald-500"
        />
        {compareCode && !otherAnswers && (
          <p className="text-xs text-amber-400 mt-2">Code must be 8 digits, each 0-3.</p>
        )}
      </section>

      {compareResult && (
        <section className={`rounded-2xl border p-6 sm:p-8 ${toneStyles[compareResult.tone]}`}>
          <p className="text-xs uppercase tracking-widest font-bold mb-2">Compatibility</p>
          <p className="text-6xl font-bold text-white mb-2">{compareResult.pct}%</p>
          <p className="text-lg text-white font-semibold mb-1">{compareResult.label}</p>
          <p className="text-sm text-zinc-300">
            You match on{' '}
            {QUESTIONS.filter((_, i) => (answers[i] as number) === (otherAnswers as number[])[i])
              .map((q) => q.prompt.toLowerCase())
              .join(', ') || 'nothing, somehow'}
            .
          </p>
        </section>
      )}

      {allAnswered && (
        <section>
          <button
            onClick={downloadCard}
            className="w-full sm:w-auto px-6 py-3 rounded-xl bg-zinc-800 border border-zinc-700 text-white font-semibold hover:bg-zinc-700 transition"
          >
            Download share card (1080×1350)
          </button>
          <canvas ref={canvasRef} className="hidden" />
        </section>
      )}

      <InstallCta
        slug="workout-buddy-compatibility"
        result={{ myCode, compareCode, compatibility: compareResult?.pct }}
        primary="Find a real workout buddy through Zealova's community"
        secondary="Zealova matches you with lifters near you who share your split, schedule, and goals. No more guessing."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'Carron AV, Hausenblas HA, Mack D (1996). Social influence and exercise: a meta-analysis. Journal of Sport and Exercise Psychology 18(1):1-16. Schedule alignment is the strongest predictor of training-partner adherence.',
          },
          {
            text: 'Plante TG et al. (2011). Does exercising with another enhance the stress-reducing benefits of exercise? International Journal of Stress Management 8(3):201-213.',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
