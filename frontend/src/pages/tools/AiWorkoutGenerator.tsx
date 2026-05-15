// /free-tools/ai-workout-generator
//
// Free AI workout generator. User picks goal, days/week, session length,
// experience, equipment, optional focus area — we POST to
// /api/v1/free-tools/ai-workout-generator and render a structured session
// (warmup, main, cooldown). Rate-limited to 2 calls per IP per day.

import { useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import RateLimitModal from '../../components/tools/RateLimitModal';
import EmailCapture from '../../components/tools/EmailCapture';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import { callAiTool, isRateLimitError, type RateLimitError } from '../../lib/aiToolsClient';

type Goal = 'build_muscle' | 'lose_fat' | 'get_stronger' | 'general_fitness';
type Experience = 'beginner' | 'intermediate' | 'advanced';

interface WarmupItem {
  exercise: string;
  duration_or_reps: string;
  notes?: string;
}
interface MainItem {
  exercise: string;
  sets: number;
  reps: string | number;
  rest_s: number;
  rir?: number;
  notes?: string;
}
interface WorkoutResponse {
  title: string;
  duration_min: number;
  warmup: WarmupItem[];
  main: MainItem[];
  cooldown: WarmupItem[];
  uses_remaining_today: number;
}

const GOALS: { value: Goal; label: string; emoji: string }[] = [
  { value: 'build_muscle', label: 'Build muscle', emoji: '🏋️' },
  { value: 'lose_fat', label: 'Lose fat', emoji: '🔥' },
  { value: 'get_stronger', label: 'Get stronger', emoji: '💪' },
  { value: 'general_fitness', label: 'General fitness', emoji: '⚡' },
];
const DURATIONS = [30, 45, 60, 75, 90];
const LEVELS: { value: Experience; label: string }[] = [
  { value: 'beginner', label: 'Beginner' },
  { value: 'intermediate', label: 'Intermediate' },
  { value: 'advanced', label: 'Advanced' },
];
const EQUIPMENT = [
  'Barbell',
  'Dumbbells',
  'Kettlebell',
  'Pull-up bar',
  'Bench',
  'Cable machine',
  'Resistance bands',
  'Bodyweight only',
];

const PLAY_STORE = 'https://play.google.com/store/apps/details?id=com.aifitnesscoach.app&referrer=utm_source%3Dtools%26utm_medium%3Dai-workout-generator';

export default function AiWorkoutGenerator() {
  const [goal, setGoal] = useState<Goal>('build_muscle');
  const [days, setDays] = useState(4);
  const [minutes, setMinutes] = useState(60);
  const [exp, setExp] = useState<Experience>('intermediate');
  const [equipment, setEquipment] = useState<string[]>(['Dumbbells', 'Bench']);
  const [focus, setFocus] = useState('');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<WorkoutResponse | null>(null);
  const [rateLimit, setRateLimit] = useState<RateLimitError | null>(null);
  const [error, setError] = useState<string | null>(null);

  const toggleEquip = (item: string) => {
    setEquipment((prev) => (prev.includes(item) ? prev.filter((e) => e !== item) : [...prev, item]));
  };

  const generate = async () => {
    if (equipment.length === 0) {
      setError('Pick at least one equipment option, or select "Bodyweight only".');
      return;
    }
    setLoading(true);
    setError(null);
    setRateLimit(null);
    try {
      const data = await callAiTool<WorkoutResponse>('/ai-workout-generator', {
        goal,
        days_per_week: days,
        minutes_per_session: minutes,
        experience: exp,
        equipment,
        focus: focus.trim() || undefined,
      });
      setResult(data);
    } catch (e) {
      if (isRateLimitError(e)) setRateLimit(e);
      else setError('Could not generate that workout. Try again in a moment.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <CalculatorShell
      slug="ai-workout-generator"
      title="Free AI Workout Generator"
      metaDescription="Free AI-powered workout generator. Pick your goal, days per week, equipment, and get a structured session with warm-up, working sets, and cooldown. No sign-up."
      intro="Tell us your goal, how long you have, and what equipment you can reach. We'll build a complete session with warm-up, working sets, and cooldown. No account needed."
      installPrimary="Zealova generates this every day."
      installSecondary="Auto-progression. Adaptive to your training history. Built around what you have and how you recovered last week."
      emailCaptureResult={
        result
          ? {
              title: result.title,
              duration_min: result.duration_min,
              main_count: result.main.length,
              goal,
              experience: exp,
            }
          : undefined
      }
      faqs={[
        {
          q: 'How does this compare to a real coach?',
          a: 'It is closer to a smart starting template than a real coach. A good coach watches your form, adjusts week-to-week based on your recovery, and knows your injury history. This tool gives you a structured starting point. Zealova does the recovery-aware progression part for you.',
        },
        {
          q: 'Can I save the workout?',
          a: 'Not on the web tool. Screenshot or copy what you need. In the Zealova app every generated workout is auto-saved, logged, and progressed for you across weeks.',
        },
        {
          q: 'Why only 2 generations per day?',
          a: 'Each generation calls Google Gemini, which costs money. The 2-per-day cap keeps the tool free for the community. Unlimited generations in the Zealova app.',
        },
        {
          q: 'What is RIR?',
          a: 'Reps in Reserve. RIR 2 means stop a set when you have 2 good reps left in the tank. It is the most reliable way to autoregulate intensity without a 1RM test.',
        },
      ]}
    >
      <div className="rounded-xl border border-emerald-500/20 bg-emerald-500/5 px-4 py-2.5 text-xs text-emerald-300 flex items-center justify-between flex-wrap gap-2">
        <span>Free, 2 generations per day per device. No sign-up.</span>
        {result && (
          <span className="font-semibold">{result.uses_remaining_today} use{result.uses_remaining_today === 1 ? '' : 's'} left today</span>
        )}
      </div>

      {/* Form */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8 space-y-6">
        <div>
          <label className="block text-sm font-semibold text-white mb-2">Goal</label>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
            {GOALS.map((g) => (
              <button
                key={g.value}
                type="button"
                onClick={() => setGoal(g.value)}
                className={`px-3 py-3 rounded-xl text-sm font-medium border transition ${
                  goal === g.value
                    ? 'bg-emerald-500 text-zinc-900 border-emerald-500'
                    : 'bg-zinc-950 text-zinc-300 border-zinc-800 hover:border-zinc-700'
                }`}
              >
                <span className="block text-lg mb-0.5">{g.emoji}</span>
                {g.label}
              </button>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
          <div>
            <label className="block text-sm font-semibold text-white mb-2">
              Days per week: <span className="text-emerald-400">{days}</span>
            </label>
            <input
              type="range"
              min={3}
              max={6}
              value={days}
              onChange={(e) => setDays(Number(e.target.value))}
              className="w-full accent-emerald-500"
            />
            <div className="flex justify-between text-xs text-zinc-500 mt-1">
              <span>3</span><span>4</span><span>5</span><span>6</span>
            </div>
          </div>

          <div>
            <label className="block text-sm font-semibold text-white mb-2">Session length</label>
            <div className="inline-flex flex-wrap gap-1 rounded-lg border border-zinc-700 bg-zinc-950 p-0.5">
              {DURATIONS.map((m) => (
                <button
                  key={m}
                  type="button"
                  onClick={() => setMinutes(m)}
                  className={`px-3 py-1.5 text-xs font-medium rounded-md transition ${
                    minutes === m ? 'bg-emerald-500 text-zinc-900' : 'text-zinc-400 hover:text-white'
                  }`}
                >
                  {m} min
                </button>
              ))}
            </div>
          </div>
        </div>

        <div>
          <label className="block text-sm font-semibold text-white mb-2">Experience</label>
          <div className="inline-flex rounded-lg border border-zinc-700 bg-zinc-950 p-0.5">
            {LEVELS.map((lvl) => (
              <button
                key={lvl.value}
                type="button"
                onClick={() => setExp(lvl.value)}
                className={`px-4 py-1.5 text-xs font-medium rounded-md transition ${
                  exp === lvl.value ? 'bg-emerald-500 text-zinc-900' : 'text-zinc-400 hover:text-white'
                }`}
              >
                {lvl.label}
              </button>
            ))}
          </div>
        </div>

        <div>
          <label className="block text-sm font-semibold text-white mb-2">Equipment</label>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
            {EQUIPMENT.map((item) => (
              <label
                key={item}
                className={`cursor-pointer rounded-lg border px-3 py-2 text-xs transition ${
                  equipment.includes(item)
                    ? 'bg-emerald-500/10 border-emerald-500/50 text-emerald-200'
                    : 'bg-zinc-950 border-zinc-800 text-zinc-400 hover:border-zinc-700'
                }`}
              >
                <input
                  type="checkbox"
                  checked={equipment.includes(item)}
                  onChange={() => toggleEquip(item)}
                  className="sr-only"
                />
                {item}
              </label>
            ))}
          </div>
        </div>

        <div>
          <label className="block text-sm font-semibold text-white mb-2">
            Specific focus <span className="text-zinc-500 font-normal">(optional)</span>
          </label>
          <textarea
            value={focus}
            onChange={(e) => setFocus(e.target.value)}
            placeholder="e.g. emphasize back and rear delts, avoid overhead pressing"
            rows={2}
            className="w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 placeholder:text-zinc-600"
          />
        </div>

        <button
          type="button"
          onClick={generate}
          disabled={loading}
          className="w-full sm:w-auto px-6 py-3 rounded-xl bg-emerald-500 text-zinc-900 font-semibold hover:bg-emerald-400 transition shadow-lg shadow-emerald-500/20 disabled:bg-zinc-700 disabled:text-zinc-500 disabled:cursor-not-allowed disabled:shadow-none"
        >
          {loading ? 'Generating…' : 'Generate workout (free, 2 per day)'}
        </button>
      </section>

      {loading && (
        <div className="grid gap-3 sm:grid-cols-2">
          <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 animate-pulse space-y-3">
            <div className="h-5 w-1/2 bg-zinc-800 rounded" />
            <div className="h-4 w-2/3 bg-zinc-800 rounded" />
            <div className="h-4 w-1/3 bg-zinc-800 rounded" />
            <div className="h-4 w-3/4 bg-zinc-800 rounded" />
            <p className="text-xs text-zinc-500 pt-2">Building your session. Usually 5 to 12 seconds.</p>
          </section>
          <EmailCapture
            toolSlug="ai-workout-generator"
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
        slug="ai-workout-generator"
        toolName="workout generation"
        resetWindow="24 hours"
      />

      {error && (
        <div className="rounded-xl border border-red-500/30 bg-red-500/5 px-4 py-3 text-sm text-red-300">
          {error}
        </div>
      )}

      {result && (
        <section className="space-y-6">
          <div>
            <h2 className="text-2xl font-bold text-white">{result.title}</h2>
            <p className="text-sm text-zinc-400 mt-1">{result.duration_min} minutes total</p>
          </div>

          <BlockSection title="Warm-up" tone="amber" items={result.warmup.map((w) => ({
            primary: w.exercise,
            secondary: w.duration_or_reps,
            note: w.notes,
          }))} />

          <div>
            <h3 className="text-sm font-semibold uppercase tracking-wide text-emerald-400 mb-3">Main session</h3>
            <div className="space-y-2">
              {result.main.map((m, i) => (
                <div key={i} className="rounded-xl border border-zinc-800 bg-zinc-950 p-4">
                  <div className="flex justify-between items-start gap-3 flex-wrap">
                    <h4 className="font-semibold text-white">
                      <span className="text-zinc-500 font-mono mr-2">{String(i + 1).padStart(2, '0')}</span>
                      {m.exercise}
                    </h4>
                  </div>
                  <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-sm">
                    <Stat label="Sets" value={m.sets.toString()} />
                    <Stat label="Reps" value={m.reps.toString()} />
                    <Stat label="Rest" value={`${m.rest_s}s`} />
                    {m.rir !== undefined && <Stat label="RIR" value={m.rir.toString()} />}
                  </div>
                  {m.notes && <p className="text-xs text-zinc-500 mt-2">{m.notes}</p>}
                </div>
              ))}
            </div>
          </div>

          <BlockSection title="Cooldown" tone="sky" items={result.cooldown.map((w) => ({
            primary: w.exercise,
            secondary: w.duration_or_reps,
            note: w.notes,
          }))} />

          <p className="text-xs text-zinc-500">
            {result.uses_remaining_today} free generation{result.uses_remaining_today === 1 ? '' : 's'} left today.
          </p>
        </section>
      )}

      <MethodologyFooter
        citations={[
          { text: 'Powered by Google Gemini. Free use limited to 2 calls per IP per 24 hours to prevent abuse. Get unlimited in the Zealova app.' },
          { text: 'Set, rep, and rest prescriptions follow NSCA Essentials of Strength Training and Conditioning (4th ed.) frameworks for hypertrophy and strength.' },
          { text: 'RIR-based intensity: Zourdos MC et al. (2016). Novel resistance-training-specific rating of perceived exertion scale measuring repetitions in reserve. JSCR 30(1).', url: 'https://pubmed.ncbi.nlm.nih.gov/26049792/' },
        ]}
        lastUpdated="2026-05-15"
      />

      <a href={PLAY_STORE} className="sr-only">Install Zealova on Google Play</a>
    </CalculatorShell>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <span className="text-zinc-300">
      <span className="text-zinc-500 text-xs uppercase tracking-wide mr-1">{label}</span>
      <span className="font-mono font-semibold">{value}</span>
    </span>
  );
}

function BlockSection({
  title,
  tone,
  items,
}: {
  title: string;
  tone: 'amber' | 'sky';
  items: { primary: string; secondary: string; note?: string }[];
}) {
  if (items.length === 0) return null;
  const accent = tone === 'amber' ? 'text-amber-400' : 'text-sky-400';
  return (
    <div>
      <h3 className={`text-sm font-semibold uppercase tracking-wide mb-3 ${accent}`}>{title}</h3>
      <div className="space-y-1.5">
        {items.map((it, i) => (
          <div key={i} className="rounded-lg border border-zinc-800 bg-zinc-950 px-4 py-2.5 flex justify-between items-center gap-3 flex-wrap">
            <div>
              <p className="text-sm text-white font-medium">{it.primary}</p>
              {it.note && <p className="text-xs text-zinc-500">{it.note}</p>}
            </div>
            <span className="text-xs font-mono text-zinc-400">{it.secondary}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function RateLimitCard({ err }: { err: RateLimitError }) {
  const resetCopy = err.resetsAtIso ? formatReset(err.resetsAtIso) : 'tomorrow';
  return (
    <section className="rounded-2xl border-2 border-amber-500/40 bg-gradient-to-br from-amber-500/10 to-emerald-500/5 p-6 sm:p-8">
      <h2 className="text-xl font-bold text-white mb-1">Daily limit reached.</h2>
      <p className="text-sm text-zinc-300">You've used both free generations today. Resets {resetCopy}.</p>
      <p className="text-sm text-zinc-300 mt-3">
        Get unlimited generations in Zealova. Plus progression that adapts week to week, full exercise videos, and tracking.
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
