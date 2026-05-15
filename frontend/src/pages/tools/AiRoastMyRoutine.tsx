// /free-tools/ai-roast-my-routine
//
// User pastes their weekly routine, picks tone (spicy or constructive), and
// gets back a letter-grade verdict + wins/concerns/suggestions + a roast
// paragraph. Brand-voice tool, slight humor allowed.
//
// Backend: POST /api/v1/free-tools/ai-roast-routine. Rate-limited 2/day.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import RateLimitModal from '../../components/tools/RateLimitModal';
import EmailCapture from '../../components/tools/EmailCapture';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import { callAiTool, isRateLimitError, type RateLimitError } from '../../lib/aiToolsClient';

type Tone = 'spicy' | 'constructive';

interface RoastResponse {
  verdict: string; // e.g. "B+" or "F"
  summary_one_liner: string;
  wins: string[];
  concerns: string[];
  suggestions: string[];
  roast: string;
  uses_remaining_today: number;
}

const PLAY_STORE = 'https://play.google.com/store/apps/details?id=com.aifitnesscoach.app&referrer=utm_source%3Dtools%26utm_medium%3Dai-roast-my-routine';

const PLACEHOLDER = `Mon: Bench 5x5, OHP 3x8, Tricep pushdowns 3x12
Tue: Squat 5x5, Leg press 3x10, Calf raises 3x15
Wed: Rest
Thu: Deadlift 1x5, Pull-ups 4x6, Rows 3x10
Fri: Arms day. Curls until I cry.
Sat-Sun: Whatever feels right`;

export default function AiRoastMyRoutine() {
  const [routine, setRoutine] = useState('');
  const [tone, setTone] = useState<Tone>('spicy');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<RoastResponse | null>(null);
  const [rateLimit, setRateLimit] = useState<RateLimitError | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  const canSubmit = routine.trim().length >= 20;

  const roast = async () => {
    if (!canSubmit) {
      setError('Paste a bit more of your routine. We need at least a few lines to roast it fairly.');
      return;
    }
    setLoading(true);
    setError(null);
    setRateLimit(null);
    try {
      const data = await callAiTool<RoastResponse>('/ai-roast-routine', {
        routine_text: routine,
        tone,
      });
      setResult(data);
    } catch (e) {
      if (isRateLimitError(e)) setRateLimit(e);
      else setError('Could not roast that routine. Try again in a moment.');
    } finally {
      setLoading(false);
    }
  };

  const verdictTone = useMemo(() => gradeTone(result?.verdict), [result]);

  const share = async () => {
    if (!result) return;
    const text = `My training routine got a ${result.verdict} from Zealova's AI.\n\n"${result.summary_one_liner}"\n\nGet roasted: zealova.com/free-tools/ai-roast-my-routine`;
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 2000);
    } catch {
      setCopied(false);
    }
  };

  return (
    <CalculatorShell
      slug="ai-roast-my-routine"
      title="Roast My Workout Routine"
      metaDescription="Free AI roast for your workout routine. Paste your weekly split, pick spicy or constructive, get a letter-grade verdict and brutally honest feedback. No sign-up."
      intro="Paste your weekly routine below. We'll grade it, list what's working, what's not, and either roast it or coach it. Your call."
      installPrimary="Get a routine Zealova actually generated."
      installSecondary="No roast required. Personalized, progressive, and updated weekly based on what you actually do."
      emailCaptureResult={
        result
          ? {
              verdict: result.verdict,
              summary: result.summary_one_liner,
              tone,
            }
          : undefined
      }
      faqs={[
        {
          q: 'Will the AI actually call my program bad?',
          a: 'Yes, if it deserves it. On spicy tone the verdict can be harsh. On constructive tone it stays warmer but still flags the real problems. Both modes are honest. Neither mode insults you, only the program.',
        },
        {
          q: 'What does it look for?',
          a: 'Volume balance across muscle groups, push-pull ratio, leg-day reality check, rest distribution, progression cues, exercise selection, and recovery placement. The same stuff a competent coach looks at.',
        },
        {
          q: 'Why a letter grade?',
          a: 'Because "your routine has imbalanced volume" is forgettable. A "C minus" is not. The grade is calibrated against published programming standards (NSCA, Helms, Israetel), not against random Reddit advice.',
        },
        {
          q: 'Can I get a fixed version?',
          a: 'Not from this tool. The roast tells you what is wrong. Zealova generates a fixed version for you, then updates it weekly based on your actual training. That is the difference between feedback and a coach.',
        },
      ]}
    >
      <div className="rounded-xl border border-emerald-500/20 bg-emerald-500/5 px-4 py-2.5 text-xs text-emerald-300 flex items-center justify-between flex-wrap gap-2">
        <span>Free, 2 roasts per day per device. No sign-up.</span>
        {result && (
          <span className="font-semibold">{result.uses_remaining_today} use{result.uses_remaining_today === 1 ? '' : 's'} left today</span>
        )}
      </div>

      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8 space-y-5">
        <div>
          <label className="block text-sm font-semibold text-white mb-2">Your weekly routine</label>
          <textarea
            value={routine}
            onChange={(e) => setRoutine(e.target.value)}
            placeholder={PLACEHOLDER}
            rows={10}
            className="w-full px-3 py-2.5 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-sm font-mono leading-relaxed focus:outline-none focus:ring-2 focus:ring-emerald-500 placeholder:text-zinc-600"
          />
          <p className="text-xs text-zinc-500 mt-1.5">
            {routine.length} characters. Paste it however you write it. Bullets, abbreviations, mess. All fine.
          </p>
        </div>

        <div>
          <label className="block text-sm font-semibold text-white mb-2">Tone</label>
          <div className="inline-flex rounded-lg border border-zinc-700 bg-zinc-950 p-0.5">
            <button
              type="button"
              onClick={() => setTone('spicy')}
              className={`px-4 py-2 text-sm font-medium rounded-md transition ${
                tone === 'spicy' ? 'bg-red-500 text-white' : 'text-zinc-400 hover:text-white'
              }`}
            >
              🔥 Spicy
            </button>
            <button
              type="button"
              onClick={() => setTone('constructive')}
              className={`px-4 py-2 text-sm font-medium rounded-md transition ${
                tone === 'constructive' ? 'bg-emerald-500 text-zinc-900' : 'text-zinc-400 hover:text-white'
              }`}
            >
              📊 Constructive
            </button>
          </div>
          <p className="text-xs text-zinc-500 mt-2">
            {tone === 'spicy' ? 'Brutal but fair. The roast hurts a little.' : 'Honest but warm. Coach-mode, not comedian-mode.'}
          </p>
        </div>

        <button
          type="button"
          onClick={roast}
          disabled={loading || !canSubmit}
          className="w-full sm:w-auto px-6 py-3 rounded-xl bg-emerald-500 text-zinc-900 font-bold hover:bg-emerald-400 transition shadow-lg shadow-emerald-500/20 disabled:bg-zinc-700 disabled:text-zinc-500 disabled:cursor-not-allowed disabled:shadow-none"
        >
          {loading ? 'Reading your routine…' : 'Roast my routine (free, 2 per day)'}
        </button>
      </section>

      {loading && (
        <div className="grid gap-3 sm:grid-cols-2">
          <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 animate-pulse space-y-3">
            <div className="h-8 w-24 bg-zinc-800 rounded mx-auto" />
            <div className="h-4 w-3/4 bg-zinc-800 rounded mx-auto" />
            <p className="text-xs text-zinc-500 pt-2 text-center">Lacing up the gloves.</p>
          </section>
          <EmailCapture
            toolSlug="ai-roast-my-routine"
            variant="inline-processing"
            source="during_processing"
          />
        </div>
      )}

      {rateLimit && <RateLimitCard err={rateLimit} />}
      <RateLimitModal
        open={!!rateLimit}
        onClose={() => setRateLimit(null)}
        kind={rateLimit?.kind}
        slug="ai-roast-my-routine"
        toolName="routine roast"
        resetWindow="24 hours"
      />

      {error && (
        <div className="rounded-xl border border-red-500/30 bg-red-500/5 px-4 py-3 text-sm text-red-300">
          {error}
        </div>
      )}

      {result && (
        <section className="space-y-5">
          {/* Verdict hero */}
          <div className={`rounded-2xl border-2 ${verdictTone.border} ${verdictTone.bg} p-6 sm:p-8 text-center`}>
            <p className="text-xs uppercase tracking-widest text-zinc-400 mb-2">Verdict</p>
            <p className={`text-6xl sm:text-7xl font-black ${verdictTone.text} leading-none`}>{result.verdict}</p>
            <p className="text-base sm:text-lg text-white mt-4 max-w-2xl mx-auto leading-snug">
              {result.summary_one_liner}
            </p>
            <button
              type="button"
              onClick={share}
              className="mt-5 inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-zinc-700 bg-zinc-950 text-zinc-300 text-sm font-medium hover:bg-zinc-900 hover:text-white transition"
            >
              {copied ? '✓ Copied' : 'Copy as tweet'}
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            <ListCard title="Wins" symbol="✓" tone="emerald" items={result.wins} />
            <ListCard title="Concerns" symbol="⚠" tone="amber" items={result.concerns} />
            <ListCard title="Suggestions" symbol="►" tone="sky" items={result.suggestions} />
          </div>

          <div className="rounded-2xl border border-zinc-800 bg-gradient-to-br from-zinc-900 to-zinc-950 p-6 sm:p-8">
            <p className="text-xs uppercase tracking-widest text-red-400 font-semibold mb-3">The roast</p>
            <p className="text-lg sm:text-xl text-zinc-100 leading-relaxed whitespace-pre-wrap">{result.roast}</p>
          </div>

          <p className="text-xs text-zinc-500">
            {result.uses_remaining_today} free roast{result.uses_remaining_today === 1 ? '' : 's'} left today.
          </p>
        </section>
      )}

      <MethodologyFooter
        citations={[
          { text: 'Powered by Google Gemini. Free use limited to 2 calls per IP per 24 hours to prevent abuse. Get unlimited in the Zealova app.' },
          { text: 'Programming evaluation rubric draws on Helms et al. (2019) The Muscle and Strength Pyramid (Training), Israetel et al. RP Hypertrophy Guides, and NSCA Essentials of Strength Training and Conditioning.' },
        ]}
        lastUpdated="2026-05-15"
      />

      <a href={PLAY_STORE} className="sr-only">Install Zealova on Google Play</a>
    </CalculatorShell>
  );
}

function ListCard({
  title,
  symbol,
  tone,
  items,
}: {
  title: string;
  symbol: string;
  tone: 'emerald' | 'amber' | 'sky';
  items: string[];
}) {
  const palette = {
    emerald: { border: 'border-emerald-500/30', text: 'text-emerald-400', dot: 'text-emerald-400' },
    amber: { border: 'border-amber-500/30', text: 'text-amber-400', dot: 'text-amber-400' },
    sky: { border: 'border-sky-500/30', text: 'text-sky-400', dot: 'text-sky-400' },
  }[tone];
  return (
    <div className={`rounded-2xl border ${palette.border} bg-zinc-950 p-5`}>
      <h3 className={`text-sm font-bold uppercase tracking-wide mb-3 ${palette.text}`}>{title}</h3>
      <ul className="space-y-2">
        {items.length === 0 ? (
          <li className="text-xs text-zinc-500">Nothing flagged here.</li>
        ) : (
          items.map((it, i) => (
            <li key={i} className="text-sm text-zinc-200 leading-snug flex gap-2">
              <span className={`${palette.dot} font-bold mt-0.5`}>{symbol}</span>
              <span>{it}</span>
            </li>
          ))
        )}
      </ul>
    </div>
  );
}

function gradeTone(grade?: string): { border: string; bg: string; text: string } {
  if (!grade) return { border: 'border-zinc-700', bg: 'bg-zinc-900', text: 'text-white' };
  const letter = grade.trim()[0]?.toUpperCase();
  switch (letter) {
    case 'A':
      return { border: 'border-emerald-500/50', bg: 'bg-gradient-to-br from-emerald-500/10 to-zinc-900', text: 'text-emerald-400' };
    case 'B':
      return { border: 'border-sky-500/50', bg: 'bg-gradient-to-br from-sky-500/10 to-zinc-900', text: 'text-sky-400' };
    case 'C':
      return { border: 'border-amber-500/50', bg: 'bg-gradient-to-br from-amber-500/10 to-zinc-900', text: 'text-amber-400' };
    case 'D':
      return { border: 'border-orange-500/50', bg: 'bg-gradient-to-br from-orange-500/10 to-zinc-900', text: 'text-orange-400' };
    case 'F':
      return { border: 'border-red-500/50', bg: 'bg-gradient-to-br from-red-500/15 to-zinc-900', text: 'text-red-400' };
    default:
      return { border: 'border-zinc-700', bg: 'bg-zinc-900', text: 'text-white' };
  }
}

function RateLimitCard({ err }: { err: RateLimitError }) {
  const resetCopy = err.resetsAtIso ? formatReset(err.resetsAtIso) : 'tomorrow';
  return (
    <section className="rounded-2xl border-2 border-amber-500/40 bg-gradient-to-br from-amber-500/10 to-emerald-500/5 p-6 sm:p-8">
      <h2 className="text-xl font-bold text-white mb-1">Daily limit reached.</h2>
      <p className="text-sm text-zinc-300">You've used both free roasts today. Resets {resetCopy}.</p>
      <p className="text-sm text-zinc-300 mt-3">
        Skip the roast. Get a routine Zealova generated for you, updated every week.
      </p>
      <a
        href={PLAY_STORE}
        className="mt-5 inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-emerald-500 text-zinc-900 font-bold hover:bg-emerald-400 transition shadow-xl shadow-emerald-500/30"
      >
        Get Zealova on Google Play
      </a>
    </section>
  );
}

function formatReset(iso: string): string {
  try {
    const d = new Date(iso);
    const hours = Math.max(1, Math.round((d.getTime() - Date.now()) / 3600000));
    return `in about ${hours} hour${hours === 1 ? '' : 's'}`;
  } catch {
    return 'tomorrow';
  }
}
