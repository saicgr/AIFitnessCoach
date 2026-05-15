// /free-tools/fasting-timer
//
// Self-contained intermittent fasting timer. All state in localStorage so
// the user can close the tab and resume. Sound on completion via Web Audio
// API (no audio file dependencies). Optional browser notification.
//
// Strategic placement: fasting is one of the highest-volume health queries
// (per Search Console / Ahrefs free tier). Cal AI and Zero both built
// large user bases off free fasting trackers. The CTA gets users into
// Zealova to track fasts long-term + see them in their Wrapped.

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

// ─── Protocols ────────────────────────────────────────────────────────

interface Protocol {
  id: string;
  name: string;
  fastHours: number;
  eatHours: number;
  description: string;
  goodFor: string;
}

const PROTOCOLS: Protocol[] = [
  { id: '12:12', name: '12:12', fastHours: 12, eatHours: 12, description: 'Beginner', goodFor: 'New to fasting, daily circadian rhythm support' },
  { id: '14:10', name: '14:10', fastHours: 14, eatHours: 10, description: 'Gentle', goodFor: 'Slightly tighter window, sustainable for most people' },
  { id: '16:8',  name: '16:8',  fastHours: 16, eatHours: 8,  description: 'Most popular', goodFor: 'Fat loss + metabolic flexibility, well-studied' },
  { id: '18:6',  name: '18:6',  fastHours: 18, eatHours: 6,  description: 'Intermediate', goodFor: 'Deeper ketosis, more autophagy time' },
  { id: '20:4',  name: '20:4',  fastHours: 20, eatHours: 4,  description: 'Warrior diet', goodFor: 'Advanced fasters, one large meal + light snacks' },
  { id: '23:1',  name: 'OMAD (23:1)', fastHours: 23, eatHours: 1, description: 'One Meal A Day', goodFor: 'Experienced fasters, peak autophagy claims' },
  { id: '36',    name: '36-hour Extended', fastHours: 36, eatHours: 0, description: 'Weekly long fast', goodFor: 'Done 1-2x/wk for deeper autophagy. Hydrate + electrolytes.' },
  { id: 'custom', name: 'Custom', fastHours: 16, eatHours: 8, description: 'Set your own', goodFor: 'Match your schedule' },
];

// ─── Metabolic phases (approximate, hours into fast) ─────────────────

interface Phase {
  id: string;
  label: string;
  description: string;
  startHr: number;
  endHr: number; // exclusive
  color: string; // Tailwind text class
}

const PHASES: Phase[] = [
  { id: 'fed',         label: 'Fed state',      description: 'Insulin elevated, glucose primary fuel, digestion ongoing.', startHr: 0,  endHr: 4,  color: 'text-zinc-400' },
  { id: 'postabs',     label: 'Post-absorptive', description: 'Blood glucose stabilizing, glycogen primary fuel.',         startHr: 4,  endHr: 12, color: 'text-emerald-400' },
  { id: 'lipolysis',   label: 'Fat-burning (lipolysis)', description: 'Glycogen depleting, fat becoming primary fuel.',    startHr: 12, endHr: 16, color: 'text-emerald-500' },
  { id: 'ketosis',     label: 'Ketosis',        description: 'Ketone production rising. Brain switches partially to ketones.', startHr: 16, endHr: 24, color: 'text-emerald-500' },
  { id: 'autophagy',   label: 'Autophagy onset', description: 'Cellular cleanup processes increasing (Sinclair 2019; Mizushima 2011).', startHr: 24, endHr: 36, color: 'text-emerald-400' },
  { id: 'deep-autophagy', label: 'Deep autophagy + GH spike', description: 'Growth hormone peaks. Use under medical supervision.', startHr: 36, endHr: 100, color: 'text-emerald-300' },
];

function phaseAt(hr: number): Phase {
  return PHASES.find((p) => hr >= p.startHr && hr < p.endHr) ?? PHASES[PHASES.length - 1];
}

// ─── Sound ────────────────────────────────────────────────────────────

function playCompletionChime(): void {
  try {
    const ctxClass = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    const ctx = new ctxClass();
    const playTone = (freq: number, startOffset: number, durationMs: number, peakGain = 0.25) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.value = freq;
      osc.connect(gain);
      gain.connect(ctx.destination);
      const t0 = ctx.currentTime + startOffset;
      gain.gain.setValueAtTime(0, t0);
      gain.gain.linearRampToValueAtTime(peakGain, t0 + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.0001, t0 + durationMs / 1000);
      osc.start(t0);
      osc.stop(t0 + durationMs / 1000);
    };
    // Three-tone ascending chime (resembling iOS/Android positive completion)
    playTone(523.25, 0.0,  450); // C5
    playTone(659.25, 0.18, 450); // E5
    playTone(783.99, 0.36, 600); // G5
  } catch (err) {
    console.warn('Audio failed', err);
  }
}

// ─── State persistence ───────────────────────────────────────────────

const STORAGE_KEY = 'zealova-fasting-timer-v1';

interface PersistedState {
  startTime: number | null;     // ms epoch
  protocolId: string;
  customFastHours: number;
  goalHours: number;
  totalCompleted: number;
  longestFastMs: number;
}

function loadState(): PersistedState {
  if (typeof window === 'undefined') return defaultState();
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return defaultState();
    const parsed = JSON.parse(raw);
    return { ...defaultState(), ...parsed };
  } catch {
    return defaultState();
  }
}

function defaultState(): PersistedState {
  return {
    startTime: null,
    protocolId: '16:8',
    customFastHours: 16,
    goalHours: 16,
    totalCompleted: 0,
    longestFastMs: 0,
  };
}

function saveState(s: PersistedState): void {
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(s));
  } catch {
    // Quota or private mode — silently ignore.
  }
}

// ─── Formatting helpers ──────────────────────────────────────────────

function formatDuration(ms: number): string {
  const total = Math.max(0, Math.floor(ms / 1000));
  const h = Math.floor(total / 3600);
  const m = Math.floor((total % 3600) / 60);
  const s = total % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
}

function formatHrMin(ms: number): string {
  const total = Math.max(0, Math.floor(ms / 60000));
  const h = Math.floor(total / 60);
  const m = total % 60;
  return `${h}h ${m}m`;
}

// ─── Component ────────────────────────────────────────────────────────

export default function FastingTimer() {
  const [state, setState] = useState<PersistedState>(() => loadState());
  const [now, setNow] = useState<number>(() => Date.now());
  const completedRef = useRef<boolean>(false);
  const tickRef = useRef<number | null>(null);

  const currentProtocol = useMemo(
    () => PROTOCOLS.find((p) => p.id === state.protocolId) ?? PROTOCOLS[2],
    [state.protocolId],
  );

  const goalMs = state.goalHours * 3600 * 1000;
  const elapsedMs = state.startTime ? now - state.startTime : 0;
  const remainingMs = Math.max(0, goalMs - elapsedMs);
  const progressPct = state.startTime ? Math.min(100, (elapsedMs / goalMs) * 100) : 0;
  const elapsedHours = elapsedMs / 3600000;
  const currentPhase = phaseAt(elapsedHours);
  const isRunning = state.startTime !== null;
  const isComplete = isRunning && elapsedMs >= goalMs;

  // Tick every second.
  useEffect(() => {
    if (!isRunning) return;
    const id = window.setInterval(() => setNow(Date.now()), 1000);
    tickRef.current = id;
    return () => {
      window.clearInterval(id);
      tickRef.current = null;
    };
  }, [isRunning]);

  // Fire completion side-effects ONCE when threshold crossed.
  useEffect(() => {
    if (!isComplete || completedRef.current) return;
    completedRef.current = true;
    playCompletionChime();
    try {
      if ('Notification' in window && Notification.permission === 'granted') {
        new Notification('Fast complete', {
          body: `You hit your ${state.goalHours}h goal. Tap to log it.`,
          icon: '/zealova-logo.png',
        });
      }
    } catch {
      /* notifications optional */
    }
    if ('vibrate' in navigator) {
      navigator.vibrate([200, 100, 200, 100, 400]);
    }
  }, [isComplete, state.goalHours]);

  // Persist state changes.
  useEffect(() => {
    saveState(state);
  }, [state]);

  // ─── Actions ───────────────────────────────────────────────────────

  const handleProtocolPick = useCallback((p: Protocol) => {
    if (isRunning) return;
    setState((s) => ({
      ...s,
      protocolId: p.id,
      goalHours: p.id === 'custom' ? s.customFastHours : p.fastHours,
    }));
  }, [isRunning]);

  const handleCustomHours = useCallback((hr: number) => {
    setState((s) => ({
      ...s,
      customFastHours: hr,
      goalHours: s.protocolId === 'custom' ? hr : s.goalHours,
    }));
  }, []);

  const handleStart = useCallback(async () => {
    completedRef.current = false;
    // Try to request notification permission. Don't block on it.
    if ('Notification' in window && Notification.permission === 'default') {
      try {
        await Notification.requestPermission();
      } catch {
        /* user denied — that's fine */
      }
    }
    setState((s) => ({ ...s, startTime: Date.now() }));
    setNow(Date.now());
  }, []);

  const handleStop = useCallback(() => {
    setState((s) => {
      const fastMs = s.startTime ? Date.now() - s.startTime : 0;
      return {
        ...s,
        startTime: null,
        totalCompleted: s.totalCompleted + (fastMs > 0 ? 1 : 0),
        longestFastMs: Math.max(s.longestFastMs, fastMs),
      };
    });
    completedRef.current = false;
  }, []);

  const handleReset = useCallback(() => {
    setState((s) => ({ ...s, startTime: null }));
    completedRef.current = false;
  }, []);

  // ─── Render ────────────────────────────────────────────────────────

  return (
    <CalculatorShell
      slug="fasting-timer"
      title="Intermittent Fasting Timer"
      metaDescription="Free intermittent fasting timer. 8 protocols (12:12, 14:10, 16:8, 18:6, 20:4, OMAD, 36-hour, custom). Sound and notification when fast complete. Metabolic phase tracking. Nothing uploaded."
      intro="Pick a protocol, hit start, and we will track your fast with a sound and notification when you hit your goal. The timer keeps running even if you close the tab. Nothing leaves your device."
      faqs={[
        {
          q: 'Will the timer keep running if I close the tab?',
          a: 'Yes. Your start time is saved to your browser. Reopen this page anytime and the timer picks up where you left off. The clock keeps ticking based on real elapsed wall-clock time, not just while the tab is open.',
        },
        {
          q: 'How does the sound and notification work?',
          a: 'When you hit your fasting goal, a 3-tone chime plays through your speakers and (if you allow it) a browser notification appears. Both work even if the tab is in the background. Phones vibrate too.',
        },
        {
          q: 'Which fasting protocol should I start with?',
          a: '12:12 if you are new to fasting. 16:8 is the most-studied and most-popular protocol. 18:6 and 20:4 are for experienced fasters. Extended 36-hour fasts should be done under medical supervision if you have any health conditions.',
        },
        {
          q: 'Are the metabolic phases accurate?',
          a: 'The hour markers (fed, lipolysis, ketosis, autophagy onset) are based on average response curves from clinical fasting research (Anton et al. 2018; Mattson et al. 2017). Individual response varies based on insulin sensitivity, last meal composition, and exercise.',
        },
        {
          q: 'Can I log this fast somewhere?',
          a: 'In Zealova. The app saves every fast you complete, shows your streak and longest fast, integrates with your training (training fasted vs fed), and shows your fasting data in your monthly Wrapped recap.',
        },
        {
          q: 'Is fasting safe for me?',
          a: 'Most people can safely do 12-16 hour fasts. Talk to a doctor first if you are pregnant, have diabetes, take medications that require food, have a history of disordered eating, or are under 18. This tool is not medical advice.',
        },
      ]}
    >
      {/* Protocol picker */}
      <section>
        <h2 className="text-lg font-bold text-white mb-3">Pick a protocol</h2>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
          {PROTOCOLS.map((p) => {
            const active = state.protocolId === p.id;
            return (
              <button
                key={p.id}
                type="button"
                disabled={isRunning}
                onClick={() => handleProtocolPick(p)}
                className={`text-left p-3 rounded-xl border transition ${
                  active
                    ? 'border-emerald-500 bg-emerald-500/10'
                    : 'border-zinc-800 bg-zinc-900 hover:border-zinc-700'
                } ${isRunning ? 'opacity-50 cursor-not-allowed' : ''}`}
              >
                <p className="text-sm font-bold text-white">{p.name}</p>
                <p className="text-xs text-zinc-500 mt-0.5">{p.description}</p>
              </button>
            );
          })}
        </div>

        {state.protocolId === 'custom' && (
          <div className="mt-3 p-4 rounded-xl border border-zinc-800 bg-zinc-900">
            <label className="block text-xs text-zinc-400 mb-2">Custom fast length (hours)</label>
            <input
              type="number"
              min={1}
              max={120}
              step={0.5}
              value={state.customFastHours}
              disabled={isRunning}
              onChange={(e) => handleCustomHours(parseFloat(e.target.value) || 16)}
              className="w-full px-4 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white focus:outline-none focus:ring-2 focus:ring-emerald-500"
            />
          </div>
        )}

        <p className="text-xs text-zinc-500 mt-3">{currentProtocol.goodFor}</p>
      </section>

      {/* Big timer */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-10 text-center">
        <ProgressRing percent={progressPct} elapsedMs={elapsedMs} goalMs={goalMs} isComplete={isComplete} />

        <div className="mt-6 space-y-1">
          <p className="text-xs text-zinc-500 uppercase tracking-wider font-semibold">
            {!isRunning ? 'Ready' : isComplete ? 'Goal reached' : 'Fasting'}
          </p>
          <p className={`text-2xl font-bold ${currentPhase.color}`}>{currentPhase.label}</p>
          <p className="text-xs text-zinc-500 max-w-md mx-auto">{currentPhase.description}</p>
        </div>

        <div className="mt-6 grid grid-cols-2 gap-3 max-w-md mx-auto">
          <div className="rounded-xl bg-zinc-950 border border-zinc-800 p-3">
            <p className="text-[10px] text-zinc-500 uppercase tracking-wide">Elapsed</p>
            <p className="text-base font-bold text-white">{formatHrMin(elapsedMs)}</p>
          </div>
          <div className="rounded-xl bg-zinc-950 border border-zinc-800 p-3">
            <p className="text-[10px] text-zinc-500 uppercase tracking-wide">
              {isComplete ? 'Past goal' : 'Remaining'}
            </p>
            <p className="text-base font-bold text-white">
              {isComplete ? formatHrMin(elapsedMs - goalMs) : formatHrMin(remainingMs)}
            </p>
          </div>
        </div>

        <div className="mt-6 flex justify-center gap-3 flex-wrap">
          {!isRunning ? (
            <button
              type="button"
              onClick={handleStart}
              className="px-8 py-3 rounded-xl bg-emerald-500 text-zinc-900 font-bold hover:bg-emerald-400 transition shadow-lg shadow-emerald-500/20"
            >
              Start fast
            </button>
          ) : (
            <>
              <button
                type="button"
                onClick={handleStop}
                className="px-8 py-3 rounded-xl bg-zinc-100 text-zinc-900 font-bold hover:bg-white transition"
              >
                End fast
              </button>
              <button
                type="button"
                onClick={handleReset}
                className="px-5 py-3 rounded-xl bg-zinc-800 text-zinc-300 font-medium hover:bg-zinc-700 transition"
              >
                Reset
              </button>
            </>
          )}
        </div>
      </section>

      {/* Metabolic phases timeline */}
      <section>
        <h2 className="text-lg font-bold text-white mb-1">Metabolic phases</h2>
        <p className="text-sm text-zinc-400 mb-4">
          Approximate timing for most people. Your actual response depends on insulin sensitivity, last meal, and training.
        </p>
        <div className="space-y-2">
          {PHASES.map((p) => {
            const active = elapsedHours >= p.startHr && elapsedHours < p.endHr;
            const past = elapsedHours >= p.endHr;
            return (
              <div
                key={p.id}
                className={`flex items-center gap-3 p-3 rounded-xl border ${
                  active
                    ? 'border-emerald-500 bg-emerald-500/10'
                    : past
                    ? 'border-zinc-800 bg-zinc-900/50 opacity-60'
                    : 'border-zinc-800 bg-zinc-900'
                }`}
              >
                <div className="w-2 h-2 rounded-full bg-emerald-500 shrink-0" style={{ opacity: active ? 1 : past ? 0.4 : 0.15 }} />
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-white">{p.label}</p>
                  <p className="text-xs text-zinc-500">{p.description}</p>
                </div>
                <p className="text-xs text-zinc-500 shrink-0 font-mono">
                  {p.startHr}h{p.endHr < 100 ? `–${p.endHr}h` : '+'}
                </p>
              </div>
            );
          })}
        </div>
      </section>

      {/* Local stats */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5">
        <h2 className="text-base font-bold text-white mb-3">Your local stats</h2>
        <div className="grid grid-cols-2 gap-3">
          <div className="rounded-xl bg-zinc-950 border border-zinc-800 p-4">
            <p className="text-xs text-zinc-500">Fasts completed</p>
            <p className="text-2xl font-bold text-white mt-1">{state.totalCompleted}</p>
          </div>
          <div className="rounded-xl bg-zinc-950 border border-zinc-800 p-4">
            <p className="text-xs text-zinc-500">Longest fast</p>
            <p className="text-2xl font-bold text-white mt-1">{formatHrMin(state.longestFastMs)}</p>
          </div>
        </div>
        <p className="text-xs text-zinc-500 mt-3">
          These stats are saved in this browser only. Switch devices or clear cookies, and they reset. To track fasts across devices, use Zealova.
        </p>
      </section>

      <InstallCta
        slug="fasting-timer"
        result={{ protocolId: state.protocolId, goalHours: state.goalHours }}
        primary="Track every fast across devices in Zealova"
        secondary="Zealova logs every fast you complete, shows your streak across devices, syncs with your training (fasted vs fed sessions), and includes fasting in your monthly Wrapped recap."
      />

      <MethodologyFooter
        citations={[
          { text: 'Anton SD et al. (2018). Flipping the metabolic switch: understanding and applying the health benefits of fasting. Obesity 26(2):254-268.', url: 'https://pubmed.ncbi.nlm.nih.gov/29086496/' },
          { text: 'Mattson MP et al. (2017). Impact of intermittent fasting on health and disease processes. Ageing Research Reviews 39:46-58.', url: 'https://pubmed.ncbi.nlm.nih.gov/27810402/' },
          { text: 'Mizushima N, Komatsu M (2011). Autophagy: renovation of cells and tissues. Cell 147(4):728-741.', url: 'https://pubmed.ncbi.nlm.nih.gov/22078875/' },
          { text: 'Phase timing references: Cahill GF Jr (2006). Fuel metabolism in starvation. Annual Review of Nutrition 26:1-22.' },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}

// ─── Progress ring ────────────────────────────────────────────────────

interface ProgressRingProps {
  percent: number;
  elapsedMs: number;
  goalMs: number;
  isComplete: boolean;
}

function ProgressRing({ percent, elapsedMs, isComplete }: ProgressRingProps) {
  const size = 240;
  const stroke = 14;
  const radius = (size - stroke) / 2;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference - (Math.min(percent, 100) / 100) * circumference;
  return (
    <div className="relative inline-block">
      <svg width={size} height={size} className="-rotate-90">
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke="rgb(39 39 42)"
          strokeWidth={stroke}
          fill="transparent"
        />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke={isComplete ? 'rgb(16 185 129)' : 'rgb(52 211 153)'}
          strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          fill="transparent"
          style={{ transition: 'stroke-dashoffset 1s linear' }}
        />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <p className="text-4xl sm:text-5xl font-bold text-white font-mono tabular-nums">
          {formatDuration(elapsedMs)}
        </p>
        <p className="text-xs text-zinc-500 mt-1">{Math.round(percent)}% of goal</p>
      </div>
    </div>
  );
}
