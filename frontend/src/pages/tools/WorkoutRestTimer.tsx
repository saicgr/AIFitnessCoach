// /free-tools/workout-rest-timer
//
// Between-sets countdown timer. Web Audio synth (no audio files), browser
// notification, vibration on mobile, named training-style presets. Tick loop
// stores a start timestamp and computes elapsed in a rAF callback so it
// doesn't drift with setInterval.

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

interface Preset {
  label: string;
  seconds: number;
  note: string;
}

const PRESETS: Preset[] = [
  { label: 'Endurance', seconds: 30, note: '15-20 reps, light' },
  { label: 'Hypertrophy', seconds: 75, note: '8-12 reps, moderate' },
  { label: 'Strength', seconds: 180, note: '3-5 reps, heavy' },
  { label: 'Powerlifting', seconds: 300, note: '1-3 reps, max effort' },
];

const QUICK_SECONDS = [60, 90, 120, 180, 240, 300];

function beep(freq: number, durationMs: number, startOffsetMs = 0) {
  try {
    const Ctx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    const ctx = new Ctx();
    const startAt = ctx.currentTime + startOffsetMs / 1000;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.frequency.value = freq;
    osc.type = 'sine';
    osc.connect(gain);
    gain.connect(ctx.destination);
    gain.gain.setValueAtTime(0.3, startAt);
    gain.gain.exponentialRampToValueAtTime(0.001, startAt + durationMs / 1000);
    osc.start(startAt);
    osc.stop(startAt + durationMs / 1000);
  } catch {
    // Audio is best-effort; never break the timer.
  }
}

function completionSound() {
  beep(880, 250, 0);
  beep(880, 250, 350);
}

function fmt(seconds: number): string {
  const s = Math.max(0, Math.ceil(seconds));
  const m = Math.floor(s / 60);
  const r = s % 60;
  return `${m}:${r.toString().padStart(2, '0')}`;
}

export default function WorkoutRestTimer() {
  const [duration, setDuration] = useState(90);
  const [customSeconds, setCustomSeconds] = useState<number | ''>('');
  const [autoRepeat, setAutoRepeat] = useState(false);
  const [remaining, setRemaining] = useState(90);
  const [running, setRunning] = useState(false);
  const startedAtRef = useRef<number | null>(null);
  const baseRemainingRef = useRef<number>(90);
  const rafRef = useRef<number | null>(null);
  const completedRef = useRef(false);

  const progress = useMemo(() => {
    if (duration <= 0) return 0;
    return 1 - remaining / duration;
  }, [duration, remaining]);

  const fireCompletion = useCallback(() => {
    completionSound();
    if ('vibrate' in navigator) navigator.vibrate(200);
    if ('Notification' in window && Notification.permission === 'granted') {
      try {
        new Notification('Rest complete', {
          body: 'Back to the bar.',
          icon: '/favicon.ico',
          silent: false,
        });
      } catch {
        // ignore
      }
    }
  }, []);

  const tick = useCallback(() => {
    if (startedAtRef.current == null) return;
    const elapsed = (performance.now() - startedAtRef.current) / 1000;
    const next = baseRemainingRef.current - elapsed;
    if (next <= 0) {
      setRemaining(0);
      if (!completedRef.current) {
        completedRef.current = true;
        fireCompletion();
      }
      if (autoRepeat) {
        baseRemainingRef.current = duration;
        startedAtRef.current = performance.now();
        completedRef.current = false;
        setRemaining(duration);
        rafRef.current = requestAnimationFrame(tick);
      } else {
        setRunning(false);
        startedAtRef.current = null;
      }
      return;
    }
    setRemaining(next);
    rafRef.current = requestAnimationFrame(tick);
  }, [autoRepeat, duration, fireCompletion]);

  useEffect(() => {
    return () => {
      if (rafRef.current != null) cancelAnimationFrame(rafRef.current);
    };
  }, []);

  // Sync remaining when duration changes while idle.
  useEffect(() => {
    if (!running) setRemaining(duration);
  }, [duration, running]);

  const requestNotificationPermission = () => {
    if ('Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission().catch(() => undefined);
    }
  };

  const handleStart = () => {
    requestNotificationPermission();
    if (remaining <= 0) baseRemainingRef.current = duration;
    else baseRemainingRef.current = remaining;
    setRemaining(baseRemainingRef.current);
    startedAtRef.current = performance.now();
    completedRef.current = false;
    setRunning(true);
    if (rafRef.current != null) cancelAnimationFrame(rafRef.current);
    rafRef.current = requestAnimationFrame(tick);
  };

  const handlePause = () => {
    setRunning(false);
    if (rafRef.current != null) cancelAnimationFrame(rafRef.current);
    startedAtRef.current = null;
  };

  const handleReset = () => {
    setRunning(false);
    if (rafRef.current != null) cancelAnimationFrame(rafRef.current);
    startedAtRef.current = null;
    completedRef.current = false;
    setRemaining(duration);
  };

  const applyPreset = (seconds: number) => {
    setDuration(seconds);
    setRemaining(seconds);
    completedRef.current = false;
    if (running) handlePause();
  };

  const applyCustom = () => {
    if (typeof customSeconds === 'number' && customSeconds > 0) {
      applyPreset(Math.min(3600, Math.round(customSeconds)));
    }
  };

  // Circular progress geometry
  const radius = 90;
  const circumference = 2 * Math.PI * radius;
  const dashOffset = circumference * (1 - progress);

  return (
    <CalculatorShell
      slug="workout-rest-timer"
      title="Workout Rest Timer"
      metaDescription="Free between-sets rest timer with audible beep, browser notification, vibration, and presets for strength, hypertrophy, endurance, and powerlifting. Auto-repeat for circuits."
      intro="Pick a rest period, hit start, get back to the bar. Audible beep, browser notification, and a vibration on mobile when the timer ends. Auto-repeat handles circuits and supersets."
      faqs={[
        {
          q: 'How long should I rest between sets?',
          a: 'For heavy strength work (1-5 reps), 3-5 minutes. For hypertrophy (8-12 reps), 60-90 seconds for isolation, up to 2 minutes for compounds. For endurance (15+ reps), 30-60 seconds. The new ACSM and NSCA guidelines support longer rests even for hypertrophy if absolute load matters.',
        },
        {
          q: 'Will the beep play if my screen is off?',
          a: 'Browsers throttle background tabs. On a phone with the screen off, audio may be cut. Keep the tab visible during your set, or use the browser notification which fires even when backgrounded. In Zealova the timer runs natively and survives the screen lock.',
        },
        {
          q: 'What is auto-repeat for?',
          a: 'Circuit training and supersets. Turn it on and the timer restarts itself each cycle, so you do not have to tap start between rounds.',
        },
        {
          q: 'Does this work offline?',
          a: 'Yes, once the page loads. Everything runs in the browser. No data is sent anywhere.',
        },
      ]}
    >
      {/* Big visual countdown */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-10">
        <div className="flex flex-col items-center">
          <div className="relative" style={{ width: 220, height: 220 }}>
            <svg width={220} height={220} className="-rotate-90">
              <circle
                cx={110}
                cy={110}
                r={radius}
                stroke="rgb(39 39 42)"
                strokeWidth={12}
                fill="none"
              />
              <circle
                cx={110}
                cy={110}
                r={radius}
                stroke="rgb(16 185 129)"
                strokeWidth={12}
                fill="none"
                strokeLinecap="round"
                strokeDasharray={circumference}
                strokeDashoffset={dashOffset}
                style={{ transition: running ? 'stroke-dashoffset 0.2s linear' : 'none' }}
              />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center">
              <span className="font-mono text-5xl sm:text-6xl font-bold text-white tabular-nums">
                {fmt(remaining)}
              </span>
              <span className="text-xs text-zinc-500 mt-1">
                {running ? 'resting' : remaining === 0 ? 'done' : 'ready'}
              </span>
            </div>
          </div>

          {/* Controls */}
          <div className="flex gap-3 mt-8">
            {!running ? (
              <button
                onClick={handleStart}
                className="px-8 py-3 rounded-xl bg-emerald-500 text-zinc-900 font-bold hover:bg-emerald-400 transition shadow-lg shadow-emerald-500/20"
              >
                Start
              </button>
            ) : (
              <button
                onClick={handlePause}
                className="px-8 py-3 rounded-xl bg-amber-500 text-zinc-900 font-bold hover:bg-amber-400 transition"
              >
                Pause
              </button>
            )}
            <button
              onClick={handleReset}
              className="px-6 py-3 rounded-xl bg-zinc-800 text-white font-semibold border border-zinc-700 hover:bg-zinc-700 transition"
            >
              Reset
            </button>
          </div>

          <label className="flex items-center gap-2 mt-6 text-sm text-zinc-400 cursor-pointer">
            <input
              type="checkbox"
              checked={autoRepeat}
              onChange={(e) => setAutoRepeat(e.target.checked)}
              className="w-4 h-4 accent-emerald-500"
            />
            Auto-repeat (circuits)
          </label>
        </div>
      </section>

      {/* Quick presets */}
      <section>
        <h2 className="text-lg font-bold text-white mb-3">Quick durations</h2>
        <div className="flex flex-wrap gap-2">
          {QUICK_SECONDS.map((s) => (
            <button
              key={s}
              onClick={() => applyPreset(s)}
              className={`px-4 py-2 rounded-lg text-sm font-medium border transition ${
                duration === s
                  ? 'bg-emerald-500 text-zinc-900 border-emerald-500'
                  : 'bg-zinc-900 text-zinc-300 border-zinc-700 hover:border-zinc-600 hover:text-white'
              }`}
            >
              {fmt(s)}
            </button>
          ))}
        </div>

        <div className="mt-4 flex items-end gap-2 flex-wrap">
          <label className="block">
            <span className="block text-sm font-medium text-zinc-300 mb-1.5">Custom (seconds)</span>
            <input
              type="number"
              inputMode="numeric"
              value={customSeconds === '' ? '' : customSeconds}
              onChange={(e) => {
                const raw = e.target.value;
                if (raw === '') setCustomSeconds('');
                else {
                  const n = parseInt(raw, 10);
                  if (Number.isFinite(n)) setCustomSeconds(n);
                }
              }}
              min={1}
              max={3600}
              placeholder="e.g. 150"
              className="w-40 px-4 py-3 rounded-xl bg-zinc-900 border border-zinc-700 text-white text-base placeholder-zinc-600 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
            />
          </label>
          <button
            onClick={applyCustom}
            className="px-5 py-3 rounded-xl bg-zinc-800 text-white font-semibold border border-zinc-700 hover:bg-zinc-700 transition"
          >
            Apply
          </button>
        </div>
      </section>

      {/* Training-style presets */}
      <section>
        <h2 className="text-lg font-bold text-white mb-3">By training style</h2>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {PRESETS.map((p) => (
            <button
              key={p.label}
              onClick={() => applyPreset(p.seconds)}
              className={`text-left p-4 rounded-xl border transition ${
                duration === p.seconds
                  ? 'bg-emerald-500/10 border-emerald-500'
                  : 'bg-zinc-900 border-zinc-800 hover:border-zinc-700'
              }`}
            >
              <div className="text-base font-bold text-white">{p.label}</div>
              <div className="font-mono text-emerald-400 text-sm mt-1">{fmt(p.seconds)}</div>
              <div className="text-xs text-zinc-500 mt-1">{p.note}</div>
            </button>
          ))}
        </div>
      </section>

      <InstallCta
        slug="workout-rest-timer"
        result={{ seconds: duration }}
        primary="Get a smart rest timer that adjusts to your lift in Zealova"
        secondary="Rest periods auto-set per exercise based on rep range and load. The timer runs in the background and survives a screen lock, with a coach prompt when it ends."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'Schoenfeld BJ et al. (2016). Longer interset rest periods enhance muscle strength and hypertrophy in resistance-trained men. JSCR 30(7).',
            url: 'https://pubmed.ncbi.nlm.nih.gov/26605807/',
          },
          {
            text: 'de Salles BF et al. (2009). Rest interval between sets in strength training. Sports Med 39(9):765-77.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/19691365/',
          },
          {
            text: 'NSCA Essentials of Strength Training and Conditioning, 4th ed. (2016). Rest interval prescription per training goal.',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
