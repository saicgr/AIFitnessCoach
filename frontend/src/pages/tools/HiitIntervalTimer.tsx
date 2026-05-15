// /free-tools/hiit-interval-timer
//
// Multi-mode interval timer: Tabata, HIIT custom, EMOM, AMRAP, For Time.
// Web Audio synth for phase cues, browser notification on full completion,
// vibration on phase changes. Tick loop tracks a single start timestamp and
// re-derives current phase + remaining each frame, so the clock never drifts.

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

type Mode = 'tabata' | 'hiit' | 'emom' | 'amrap' | 'fortime';

function beep(freq: number, durationMs: number, startOffsetMs = 0, volume = 0.3) {
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
    gain.gain.setValueAtTime(volume, startAt);
    gain.gain.exponentialRampToValueAtTime(0.001, startAt + durationMs / 1000);
    osc.start(startAt);
    osc.stop(startAt + durationMs / 1000);
  } catch {
    // best-effort
  }
}

const cues = {
  work: () => beep(880, 300),
  rest: () => beep(440, 300),
  countdown: () => beep(660, 120, 0, 0.2),
  roundComplete: () => {
    beep(880, 200, 0);
    beep(880, 200, 250);
  },
  workoutComplete: () => {
    beep(880, 250, 0);
    beep(880, 250, 300);
    beep(1320, 500, 600);
  },
};

function fmt(seconds: number): string {
  const s = Math.max(0, Math.ceil(seconds));
  const m = Math.floor(s / 60);
  const r = s % 60;
  return `${m}:${r.toString().padStart(2, '0')}`;
}

function vibrate(pattern: number | number[]) {
  if ('vibrate' in navigator) navigator.vibrate(pattern);
}

interface PhaseInfo {
  phase: 'work' | 'rest' | 'round' | 'amrap' | 'fortime' | 'done';
  remaining: number;
  round: number;
  totalRounds: number;
}

export default function HiitIntervalTimer() {
  const [mode, setMode] = useState<Mode>('tabata');
  // HIIT custom config
  const [hiitWork, setHiitWork] = useState(40);
  const [hiitRest, setHiitRest] = useState(20);
  const [hiitRounds, setHiitRounds] = useState(8);
  // EMOM config
  const [emomRounds, setEmomRounds] = useState(10);
  // AMRAP config (total minutes)
  const [amrapMinutes, setAmrapMinutes] = useState(12);

  const [running, setRunning] = useState(false);
  const [elapsedMs, setElapsedMs] = useState(0);
  const startedAtRef = useRef<number | null>(null);
  const baseElapsedRef = useRef(0);
  const rafRef = useRef<number | null>(null);
  const lastPhaseRef = useRef<string>('idle');
  const lastCountdownSecondRef = useRef<number>(-1);

  // For "For Time" mode we count UP. User stops manually.
  const forTimeStopRef = useRef<number | null>(null);
  const [forTimeStopped, setForTimeStopped] = useState<number | null>(null);

  // Build phase plan per mode.
  const config = useMemo(() => {
    if (mode === 'tabata') return { work: 20, rest: 10, rounds: 8 };
    if (mode === 'hiit') return { work: hiitWork, rest: hiitRest, rounds: hiitRounds };
    return null;
  }, [mode, hiitWork, hiitRest, hiitRounds]);

  const totalDurationSec = useMemo(() => {
    if (mode === 'tabata' || mode === 'hiit') {
      if (!config) return 0;
      // First work has no leading rest. Pattern: work, rest, work, rest, ... rounds total.
      return config.rounds * config.work + (config.rounds - 1) * config.rest;
    }
    if (mode === 'emom') return emomRounds * 60;
    if (mode === 'amrap') return amrapMinutes * 60;
    return Infinity; // for time
  }, [mode, config, emomRounds, amrapMinutes]);

  const computePhase = useCallback(
    (elapsedSec: number): PhaseInfo => {
      if (mode === 'tabata' || mode === 'hiit') {
        if (!config) return { phase: 'done', remaining: 0, round: 0, totalRounds: 0 };
        const cycle = config.work + config.rest;
        let t = elapsedSec;
        for (let r = 1; r <= config.rounds; r++) {
          if (t < config.work) {
            return { phase: 'work', remaining: config.work - t, round: r, totalRounds: config.rounds };
          }
          t -= config.work;
          if (r === config.rounds) break;
          if (t < config.rest) {
            return { phase: 'rest', remaining: config.rest - t, round: r, totalRounds: config.rounds };
          }
          t -= config.rest;
          // continue
          void cycle;
        }
        return { phase: 'done', remaining: 0, round: config.rounds, totalRounds: config.rounds };
      }
      if (mode === 'emom') {
        if (elapsedSec >= emomRounds * 60) {
          return { phase: 'done', remaining: 0, round: emomRounds, totalRounds: emomRounds };
        }
        const round = Math.floor(elapsedSec / 60) + 1;
        const into = elapsedSec - (round - 1) * 60;
        return { phase: 'round', remaining: 60 - into, round, totalRounds: emomRounds };
      }
      if (mode === 'amrap') {
        const total = amrapMinutes * 60;
        if (elapsedSec >= total) return { phase: 'done', remaining: 0, round: 0, totalRounds: 0 };
        return { phase: 'amrap', remaining: total - elapsedSec, round: 0, totalRounds: 0 };
      }
      // for time
      return { phase: 'fortime', remaining: elapsedSec, round: 0, totalRounds: 0 };
    },
    [mode, config, emomRounds, amrapMinutes]
  );

  const stopRaf = () => {
    if (rafRef.current != null) {
      cancelAnimationFrame(rafRef.current);
      rafRef.current = null;
    }
  };

  const tick = useCallback(() => {
    if (startedAtRef.current == null) return;
    const now = performance.now();
    const elapsed = baseElapsedRef.current + (now - startedAtRef.current);
    setElapsedMs(elapsed);
    const elapsedSec = elapsed / 1000;

    if (mode === 'fortime') {
      rafRef.current = requestAnimationFrame(tick);
      return;
    }

    const info = computePhase(elapsedSec);

    // Phase transition cues
    const phaseKey = `${info.phase}:${info.round}`;
    if (phaseKey !== lastPhaseRef.current) {
      const prev = lastPhaseRef.current;
      lastPhaseRef.current = phaseKey;
      if (prev !== 'idle') {
        if (info.phase === 'work') {
          cues.work();
          vibrate(150);
        } else if (info.phase === 'rest') {
          cues.rest();
          vibrate([80, 60, 80]);
        } else if (info.phase === 'round') {
          // EMOM: top of each minute
          cues.work();
          vibrate(150);
        } else if (info.phase === 'done') {
          cues.workoutComplete();
          vibrate([200, 100, 200, 100, 400]);
          if ('Notification' in window && Notification.permission === 'granted') {
            try {
              new Notification('Workout complete', { body: 'Nice work. Log it in Zealova.' });
            } catch {
              // ignore
            }
          }
        }
      }
    }

    // 3-2-1 countdown cues into next phase
    if (info.phase === 'work' || info.phase === 'rest' || info.phase === 'round' || info.phase === 'amrap') {
      const secLeft = Math.ceil(info.remaining);
      if (secLeft <= 3 && secLeft >= 1 && secLeft !== lastCountdownSecondRef.current) {
        lastCountdownSecondRef.current = secLeft;
        cues.countdown();
      }
      if (secLeft > 3) lastCountdownSecondRef.current = -1;
    }

    if (info.phase === 'done') {
      setRunning(false);
      stopRaf();
      startedAtRef.current = null;
      return;
    }

    rafRef.current = requestAnimationFrame(tick);
  }, [computePhase, mode]);

  useEffect(() => {
    return () => stopRaf();
  }, []);

  // Reset on mode/config change while idle
  useEffect(() => {
    if (!running) {
      baseElapsedRef.current = 0;
      setElapsedMs(0);
      lastPhaseRef.current = 'idle';
      lastCountdownSecondRef.current = -1;
      setForTimeStopped(null);
      forTimeStopRef.current = null;
    }
  }, [mode, hiitWork, hiitRest, hiitRounds, emomRounds, amrapMinutes, running]);

  const handleStart = () => {
    if ('Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission().catch(() => undefined);
    }
    startedAtRef.current = performance.now();
    lastPhaseRef.current = 'idle'; // first transition is silent into first phase
    // Pre-prime first phase cue
    if (mode === 'tabata' || mode === 'hiit' || mode === 'emom') {
      cues.work();
      vibrate(150);
      lastPhaseRef.current = mode === 'emom' ? 'round:1' : 'work:1';
    }
    setRunning(true);
    rafRef.current = requestAnimationFrame(tick);
  };

  const handlePause = () => {
    if (startedAtRef.current != null) {
      baseElapsedRef.current += performance.now() - startedAtRef.current;
    }
    startedAtRef.current = null;
    stopRaf();
    setRunning(false);
  };

  const handleReset = () => {
    stopRaf();
    startedAtRef.current = null;
    baseElapsedRef.current = 0;
    setElapsedMs(0);
    lastPhaseRef.current = 'idle';
    lastCountdownSecondRef.current = -1;
    setForTimeStopped(null);
    forTimeStopRef.current = null;
    setRunning(false);
  };

  const handleStopForTime = () => {
    if (mode !== 'fortime') return;
    forTimeStopRef.current = elapsedMs;
    setForTimeStopped(elapsedMs);
    cues.workoutComplete();
    vibrate([200, 100, 200, 100, 400]);
    handlePause();
  };

  const elapsedSec = elapsedMs / 1000;
  const info: PhaseInfo =
    mode === 'fortime'
      ? { phase: 'fortime', remaining: elapsedSec, round: 0, totalRounds: 0 }
      : computePhase(elapsedSec);

  const phaseLabel =
    info.phase === 'work'
      ? 'WORK'
      : info.phase === 'rest'
        ? 'REST'
        : info.phase === 'round'
          ? `ROUND ${info.round} of ${info.totalRounds}`
          : info.phase === 'amrap'
            ? 'AMRAP'
            : info.phase === 'fortime'
              ? forTimeStopped != null ? 'FINISHED' : 'FOR TIME'
              : 'DONE';

  const phaseColor =
    info.phase === 'work' || info.phase === 'round'
      ? 'text-emerald-400'
      : info.phase === 'rest'
        ? 'text-amber-400'
        : info.phase === 'amrap' || info.phase === 'fortime'
          ? 'text-sky-400'
          : 'text-white';

  const displayTime =
    mode === 'fortime'
      ? fmt(forTimeStopped != null ? forTimeStopped / 1000 : elapsedSec)
      : fmt(info.remaining);

  const totalElapsedPct =
    mode === 'fortime' || !Number.isFinite(totalDurationSec)
      ? 0
      : Math.min(1, elapsedSec / totalDurationSec);

  const radius = 90;
  const circumference = 2 * Math.PI * radius;
  const dashOffset = circumference * (1 - totalElapsedPct);

  return (
    <CalculatorShell
      slug="hiit-interval-timer"
      title="HIIT, Tabata, EMOM, AMRAP Timer"
      metaDescription="Free interval timer with five modes: Tabata, custom HIIT, EMOM, AMRAP, For Time. Audible phase cues, browser notification, vibration. No login, no ads."
      intro="Five modes in one timer. Tabata is preset at 20s on, 10s off, 8 rounds. Custom HIIT lets you set any work/rest split. EMOM beeps at the top of each minute. AMRAP and For Time handle anything else."
      faqs={[
        {
          q: 'What is Tabata vs HIIT?',
          a: 'Tabata is a specific protocol: 20 seconds work, 10 seconds rest, 8 rounds, 4 minutes total, originally tested by Izumi Tabata on speed skaters at supramaximal intensity. HIIT is any high-intensity interval training. All Tabata is HIIT, but not all HIIT is Tabata.',
        },
        {
          q: 'What does EMOM mean?',
          a: 'Every Minute On the Minute. At the top of each minute you do a fixed amount of work, then rest until the next minute starts. Common in CrossFit and conditioning blocks.',
        },
        {
          q: 'What is AMRAP?',
          a: 'As Many Rounds (or Reps) As Possible in a fixed time window. The timer counts down, you count rounds, you stop when the buzzer hits.',
        },
        {
          q: 'What is For Time?',
          a: 'You have a fixed amount of work to complete and you race the clock. Timer counts up. Hit stop when you finish.',
        },
        {
          q: 'Does the timer keep ticking if I lock my phone?',
          a: 'Browsers throttle background tabs and many mobile browsers stop JS timers when the screen sleeps. Keep the tab in the foreground during a session. Zealova handles this natively when installed.',
        },
      ]}
    >
      {/* Mode tabs */}
      <section>
        <div className="grid grid-cols-5 gap-2">
          {(['tabata', 'hiit', 'emom', 'amrap', 'fortime'] as Mode[]).map((m) => (
            <button
              key={m}
              onClick={() => { if (!running) setMode(m); }}
              disabled={running}
              className={`px-2 py-2.5 rounded-lg text-xs sm:text-sm font-bold border transition ${
                mode === m
                  ? 'bg-emerald-500 text-zinc-900 border-emerald-500'
                  : 'bg-zinc-900 text-zinc-300 border-zinc-800 hover:border-zinc-700 hover:text-white disabled:opacity-50'
              }`}
            >
              {m === 'tabata' && 'Tabata'}
              {m === 'hiit' && 'HIIT'}
              {m === 'emom' && 'EMOM'}
              {m === 'amrap' && 'AMRAP'}
              {m === 'fortime' && 'For Time'}
            </button>
          ))}
        </div>
      </section>

      {/* Per-mode config */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6">
        {mode === 'tabata' && (
          <div className="text-sm text-zinc-400">
            <p className="text-white font-semibold mb-1">Tabata protocol (locked)</p>
            <p>20 seconds work, 10 seconds rest, 8 rounds. 4 minutes total.</p>
          </div>
        )}

        {mode === 'hiit' && (
          <div className="grid grid-cols-3 gap-3">
            <NumField label="Work (s)" value={hiitWork} onChange={setHiitWork} min={5} max={600} disabled={running} />
            <NumField label="Rest (s)" value={hiitRest} onChange={setHiitRest} min={0} max={600} disabled={running} />
            <NumField label="Rounds" value={hiitRounds} onChange={setHiitRounds} min={1} max={50} disabled={running} />
          </div>
        )}

        {mode === 'emom' && (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <NumField label="Rounds (minutes)" value={emomRounds} onChange={setEmomRounds} min={1} max={60} disabled={running} />
            <div className="text-sm text-zinc-400 self-end pb-3">
              Beep at the top of every minute. Total: {emomRounds} min.
            </div>
          </div>
        )}

        {mode === 'amrap' && (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <NumField label="Duration (minutes)" value={amrapMinutes} onChange={setAmrapMinutes} min={1} max={120} disabled={running} />
            <div className="text-sm text-zinc-400 self-end pb-3">
              Counts down. You count rounds.
            </div>
          </div>
        )}

        {mode === 'fortime' && (
          <div className="text-sm text-zinc-400">
            <p className="text-white font-semibold mb-1">For Time</p>
            <p>Timer counts up from zero. Hit stop when your work is done. Final time stays on screen.</p>
          </div>
        )}
      </section>

      {/* Big visual */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-10">
        <div className="flex flex-col items-center">
          <div className={`text-sm font-bold tracking-widest uppercase mb-3 ${phaseColor}`}>
            {phaseLabel}
          </div>
          <div className="relative" style={{ width: 220, height: 220 }}>
            <svg width={220} height={220} className="-rotate-90">
              <circle cx={110} cy={110} r={radius} stroke="rgb(39 39 42)" strokeWidth={12} fill="none" />
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
                {displayTime}
              </span>
              {(mode === 'tabata' || mode === 'hiit') && info.totalRounds > 0 && (
                <span className="text-xs text-zinc-500 mt-1">
                  Round {info.round} of {info.totalRounds}
                </span>
              )}
            </div>
          </div>

          <div className="flex gap-3 mt-8 flex-wrap justify-center">
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
            {mode === 'fortime' && running && (
              <button
                onClick={handleStopForTime}
                className="px-6 py-3 rounded-xl bg-rose-500 text-white font-semibold hover:bg-rose-400 transition"
              >
                Finished
              </button>
            )}
            <button
              onClick={handleReset}
              className="px-6 py-3 rounded-xl bg-zinc-800 text-white font-semibold border border-zinc-700 hover:bg-zinc-700 transition"
            >
              Reset
            </button>
          </div>
        </div>
      </section>

      <InstallCta
        slug="hiit-interval-timer"
        result={{ mode }}
        primary="Use this timer mid-workout in Zealova with auto-logging and full history"
        secondary="Pick a HIIT, Tabata, or EMOM block from your plan and the timer launches inline, logs the session, and writes to your weekly volume."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'Tabata I et al. (1996). Effects of moderate-intensity endurance and high-intensity intermittent training on anaerobic capacity and VO2max. MSSE 28(10):1327-30.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/8897392/',
          },
          {
            text: 'Gibala MJ et al. (2012). Physiological adaptations to low-volume, high-intensity interval training in health and disease. J Physiol 590(5):1077-84.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/22289907/',
          },
          {
            text: 'ACSM (2014). High-intensity interval training position statement. ACSMs Health Fit J 18(3):14-17.',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}

function NumField({
  label,
  value,
  onChange,
  min,
  max,
  disabled,
}: {
  label: string;
  value: number;
  onChange: (n: number) => void;
  min: number;
  max: number;
  disabled?: boolean;
}) {
  return (
    <label className="block">
      <span className="block text-sm font-medium text-zinc-300 mb-1.5">{label}</span>
      <input
        type="number"
        inputMode="numeric"
        value={value}
        min={min}
        max={max}
        disabled={disabled}
        onChange={(e) => {
          const n = parseInt(e.target.value, 10);
          if (Number.isFinite(n)) onChange(Math.max(min, Math.min(max, n)));
        }}
        className="w-full px-4 py-3 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-base focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 disabled:opacity-50"
      />
    </label>
  );
}
