import { useEffect, useRef, useState } from 'react';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { isPrerender, prefersReducedMotion } from '../../lib/runtimeEnv';

// The teardown, reimagined for software: Zealova's product is the
// interface itself, so the device explodes into six PIXEL-CRISP DOM layers
// in real CSS 3D — glass, the live chat UI, the burning AI core, exercise
// cards, the adaptive engine readout, and a titanium plate. A sticky stage
// inside a 300vh runway; scroll scrubs the stack's rotation and the
// translateZ separation (transform-only, composited).
//
// Prerender / reduced-motion: collapses to a static section — heading +
// callouts as plain crawlable text, layers shown flat.

const CALLOUTS = [
  {
    k: '01',
    title: 'Live coach UI',
    body: 'The chat that knows your exercise, your weight on the bar, and how many sets are left.',
    window: [0.26, 0.37] as const,
  },
  {
    k: '02',
    title: 'Menu scan',
    body: 'Point it at any restaurant menu. Every dish analyzed, your best pick flagged.',
    window: [0.37, 0.48] as const,
  },
  {
    k: '03',
    title: 'AI coach core',
    body: 'A context engine trained on how you actually train. It programs, watches, and adapts.',
    window: [0.48, 0.59] as const,
  },
  {
    k: '04',
    title: 'Live workout logging',
    body: 'Pyramid sets, RIR, rest timers. Logged in two taps mid-set.',
    window: [0.59, 0.7] as const,
  },
  {
    k: '05',
    title: '1,722-exercise library',
    body: 'Every movement with video, progressions, and the reasoning for why it is in your plan.',
    window: [0.7, 0.81] as const,
  },
  {
    k: '06',
    title: 'Adaptive engine',
    body: 'TDEE, load, and volume retuned every week from what you log. No static templates.',
    window: [0.81, 0.92] as const,
  },
];

/* ----------------------------- the six layers ----------------------------- */

function GlassLayer() {
  return (
    <div className="relative h-full w-full overflow-hidden rounded-[2.2rem] border border-white/25 bg-gradient-to-br from-white/12 via-white/[0.04] to-transparent">
      <div className="absolute -left-1/4 top-0 h-[160%] w-1/3 -rotate-12 bg-gradient-to-r from-transparent via-white/15 to-transparent" />
      <span className="vl-layer-cap condensed-kicker absolute bottom-4 left-1/2 -translate-x-1/2 text-[9px] text-white/40">
        Glass
      </span>
    </div>
  );
}

function UiLayer() {
  return (
    <div className="flex h-full w-full flex-col rounded-[2.2rem] bg-[#0b0b0d] p-4 text-[10px] shadow-[0_0_60px_rgba(255,122,0,0.12)]">
      <div className="flex items-center gap-2 border-b border-white/10 pb-2">
        <span className="flex h-6 w-6 items-center justify-center rounded-full bg-volt-500 text-[10px] font-bold text-white">Z</span>
        <div>
          <p className="text-[11px] font-semibold text-white leading-tight">Coach Mike</p>
          <p className="flex items-center gap-1 text-[8px] text-emerald-500 leading-tight">
            <span className="h-1 w-1 rounded-full bg-emerald-500" /> Online
          </p>
        </div>
      </div>
      <div className="mt-3 space-y-2">
        <div className="max-w-[85%] rounded-xl bg-[#1d1d20] px-3 py-2 text-zinc-200">
          <p className="mb-0.5 text-[8px] font-semibold text-volt-400">🧡 COACH MIKE</p>
          Bench 185 lb for 2×5 today. Shoulder blades pinned.
        </div>
        <div className="ml-auto max-w-[70%] rounded-xl bg-[#06B6D4] px-3 py-2 font-medium text-white">
          What about my shoulder?
        </div>
      </div>
      <div className="mt-3 rounded-xl border border-white/10 bg-[#121214] p-3">
        <div className="flex justify-between text-[8px] text-zinc-400">
          <span className="font-bold tracking-wider">BENCH · EST. 1RM</span>
          <span className="font-bold text-emerald-500">+15%</span>
        </div>
        <svg viewBox="0 0 200 44" className="mt-1 h-10 w-full" aria-hidden="true">
          <path
            d="M0 38 L30 36 L60 31 L90 32 L120 24 L155 18 L195 8"
            fill="none"
            stroke="#FF7A00"
            strokeWidth="2.5"
            strokeLinecap="round"
          />
          <circle cx="195" cy="8" r="3.5" fill="#FF7A00" />
        </svg>
      </div>
      <div className="mt-auto rounded-full bg-volt-500 py-2 text-center text-[10px] font-bold text-white">
        Start workout
      </div>
    </div>
  );
}

function CoreLayer() {
  return (
    <div className="relative flex h-full w-full items-center justify-center rounded-[2.2rem]">
      {/* Orb */}
      <div
        className="relative h-32 w-32 rounded-full"
        style={{
          background:
            'radial-gradient(circle at 34% 30%, #ffd9a8 0%, #ff9a3c 32%, #ff7a00 55%, #7a3500 100%)',
          boxShadow: '0 0 80px rgba(255,122,0,0.55), 0 0 200px rgba(255,122,0,0.25)',
        }}
      />
      {/* Orbital rings */}
      <div className="vl-orbit absolute h-48 w-48 rounded-full border border-volt-500/60" style={{ transform: 'rotateX(72deg)' }} />
      <div className="vl-orbit-rev absolute h-60 w-60 rounded-full border border-volt-300/30" style={{ transform: 'rotateX(72deg) rotateY(18deg)' }} />
      <span className="vl-layer-cap condensed-kicker absolute bottom-6 left-1/2 -translate-x-1/2 text-[9px] text-volt-400">
        Coach core
      </span>
    </div>
  );
}

function HomeLayer() {
  return (
    <div className="flex h-full w-full flex-col rounded-[2.2rem] bg-[#0a0a0c] p-4 text-[10px]">
      {/* Greeting + streak */}
      <div className="flex items-center justify-between">
        <div>
          <p className="text-[8px] text-zinc-500">Tuesday, Jun 10</p>
          <p className="text-[14px] font-bold text-white">Morning, Sai</p>
        </div>
        <span className="rounded-full bg-volt-500/15 px-2 py-1 text-[9px] font-bold text-volt-400">🔥 12-day streak</span>
      </div>

      {/* Coach hero card — the daily brief, like the real home */}
      <div className="mt-2.5 rounded-2xl border border-white/8 bg-white/[0.04] p-3">
        <p className="text-[8px] font-semibold text-volt-400">🧡 COACH MIKE</p>
        <p className="mt-0.5 text-[9px] leading-snug text-zinc-300">
          Sleep ran short. I trimmed today's volume 10% and moved bench first.
        </p>
      </div>

      {/* Today's workout hero card */}
      <div className="mt-2.5 rounded-2xl border border-volt-500/25 bg-gradient-to-br from-volt-500/15 to-transparent p-3">
        <p className="condensed-kicker text-[8px] text-volt-400">Today's workout</p>
        <p className="mt-0.5 text-[13px] font-bold text-white">Push Day</p>
        <p className="text-[8.5px] text-zinc-400">6 exercises · 42 min · chest focus</p>
        <div className="mt-2 rounded-full bg-volt-500 py-1.5 text-center text-[9px] font-bold text-white">▶ Start workout</div>
      </div>

      {/* Rings + macros */}
      <div className="mt-2.5 flex items-center gap-3 rounded-2xl border border-white/8 bg-white/[0.03] p-2.5">
        <svg viewBox="0 0 48 48" className="h-10 w-10 shrink-0" aria-hidden="true">
          <circle cx="24" cy="24" r="19" fill="none" stroke="rgba(255,255,255,0.1)" strokeWidth="5" />
          <circle cx="24" cy="24" r="19" fill="none" stroke="#FF7A00" strokeWidth="5" strokeLinecap="round" strokeDasharray="119.4" strokeDashoffset="46" transform="rotate(-90 24 24)" />
        </svg>
        <div>
          <p className="vl-tabular text-[11px] font-bold text-white">1,490 <span className="text-[8px] font-normal text-zinc-500">/ 2,410 kcal</span></p>
          <p className="text-[8px] text-zinc-400"><span className="font-semibold" style={{ color: '#A855F7' }}>96g P</span> · <span style={{ color: '#06B6D4' }}>132g C</span> · <span style={{ color: '#F97316' }}>41g F</span></p>
        </div>
      </div>

      {/* Quick actions row */}
      <div className="mt-2.5 grid grid-cols-4 gap-1.5">
        {['📷', '🍽', '📈', '💬'].map((icon) => (
          <span key={icon} className="flex h-8 items-center justify-center rounded-xl border border-white/8 bg-white/[0.03] text-[12px]">{icon}</span>
        ))}
      </div>

      <span className="vl-layer-cap condensed-kicker mx-auto mt-auto text-[9px] text-white/40">Home</span>
    </div>
  );
}

function MenuScanLayer() {
  return (
    <div className="flex h-full w-full flex-col justify-center gap-2 rounded-[2.2rem] bg-[#101012] p-5 text-[10px] shadow-[0_0_40px_rgba(255,122,0,0.08)]">
      <p className="text-[12px] font-extrabold text-white">Menu Analysis</p>
      <p className="text-[8px] text-zinc-500">8 items · 2 sections · 2.4s</p>

      <div className="mt-1 rounded-xl border border-amber-500/30 bg-amber-500/5 p-3">
        <div className="flex items-center gap-1.5">
          <span className="text-[10px] font-semibold text-white">Grilled chicken bowl</span>
          <span className="rounded bg-[#4CAF50] px-1 py-0.5 text-[7px] font-bold text-white">Recommended</span>
        </div>
        <div className="mt-1.5 flex gap-1">
          <span className="rounded px-1 py-0.5 text-[7px] font-semibold" style={{ color: '#9C27B0', background: '#9C27B026' }}>52g Protein</span>
          <span className="rounded px-1 py-0.5 text-[7px] font-semibold" style={{ color: '#FF9800', background: '#FF980026' }}>38g Carbs</span>
          <span className="rounded px-1 py-0.5 text-[7px] font-semibold" style={{ color: '#E91E63', background: '#E91E6326' }}>14g Fat</span>
        </div>
      </div>

      <div className="rounded-xl border border-white/8 bg-white/[0.03] p-3 opacity-60">
        <div className="flex items-center gap-1.5">
          <span className="text-[10px] font-semibold text-zinc-300">Carbonara</span>
          <span className="rounded bg-[#F44336] px-1 py-0.5 text-[7px] font-bold text-white">Avoid</span>
        </div>
      </div>

      <div className="mt-1 rounded-full bg-volt-500 py-2 text-center text-[9px] font-bold text-white">
        Log 1 item
      </div>
      <span className="vl-layer-cap condensed-kicker mx-auto mt-1 text-[9px] text-white/40">Menu scan</span>
    </div>
  );
}

const WORKOUT_SETS = [
  { set: '1', target: '185 × 8', done: true },
  { set: '2', target: '215 × 5', done: true },
  { set: '3', target: '225 × 3', done: false },
];

function WorkoutLayer() {
  return (
    <div className="flex h-full w-full flex-col justify-center gap-2 rounded-[2.2rem] bg-[#0d0d0f] p-5 text-[10px]">
      <p className="text-[8px] uppercase tracking-[0.15em] text-zinc-500">Push Day · ▲ Pyramid</p>
      <p className="text-[12px] font-bold text-white">Barbell Bench Press</p>
      <div className="mt-1 space-y-1.5">
        {WORKOUT_SETS.map((s) => (
          <div
            key={s.set}
            className={`flex items-center justify-between rounded-lg border px-2.5 py-2 ${
              s.done ? 'border-emerald-500/30 bg-emerald-500/10' : 'border-volt-500/40 bg-volt-500/10'
            }`}
          >
            <span className="text-zinc-400">Set {s.set}</span>
            <span className="vl-tabular font-semibold text-white">{s.target}</span>
            <span className={`flex h-4 w-4 items-center justify-center rounded text-[9px] font-bold ${s.done ? 'bg-emerald-500 text-white' : 'bg-white/10 text-transparent'}`}>✓</span>
          </div>
        ))}
      </div>
      <div className="mt-1 flex items-center gap-1">
        <span className="mr-1 text-[7px] uppercase tracking-wider text-zinc-500">RIR</span>
        {['0', '1', '2', '3'].map((r, i) => (
          <span key={r} className={`flex w-6 items-center justify-center rounded text-[8px] font-semibold ${i === 2 ? 'bg-emerald-500 text-white' : 'bg-white/8 text-zinc-400'}`} style={{ height: 16 }}>{r}</span>
        ))}
        <span className="ml-auto rounded-full bg-white/8 px-2 py-0.5 text-[8px] text-zinc-400">⏱ 01:52</span>
      </div>
      <span className="vl-layer-cap condensed-kicker mx-auto mt-1 text-[9px] text-white/40">Live logging</span>
    </div>
  );
}

const LIB_CARDS = [
  { name: 'Barbell Bench Press', tag: 'Chest · barbell' },
  { name: 'Bulgarian Split Squat', tag: 'Quads · dumbbell' },
  { name: 'Seated Cable Row', tag: 'Back · cable' },
];

function LibraryLayer() {
  return (
    <div className="relative flex h-full w-full flex-col items-center justify-center gap-3 rounded-[2.2rem]">
      {LIB_CARDS.map((c, i) => (
        <div
          key={c.name}
          className="w-[78%] rounded-xl border border-white/10 bg-[#141416] px-3.5 py-2.5 shadow-[0_8px_24px_rgba(0,0,0,0.5)]"
          style={{ transform: `rotate(${(i - 1) * 3.5}deg) translateX(${(i - 1) * 8}px)` }}
        >
          <div className="flex items-center justify-between">
            <p className="text-[10px] font-semibold text-white">{c.name}</p>
            <span className="flex h-4.5 w-4.5 items-center justify-center rounded-full bg-volt-500/15 text-[8px] text-volt-400" style={{ height: 18, width: 18 }}>▶</span>
          </div>
          <p className="text-[8px] text-zinc-500">{c.tag}</p>
        </div>
      ))}
      <span className="vl-layer-cap condensed-kicker absolute bottom-6 left-1/2 -translate-x-1/2 text-[9px] text-white/40">
        1,722 exercises
      </span>
    </div>
  );
}

const ENGINE_ROWS = [
  ['TDEE', '2,410 kcal', '↻ weekly'],
  ['Bench next', '+5 lb', 'scheduled'],
  ['Chest volume', '18 sets', 'optimal'],
  ['Recovery', '86%', 'train today'],
];

function EngineLayer() {
  return (
    <div className="flex h-full w-full flex-col justify-center gap-2 rounded-[2.2rem] border border-white/10 bg-[#0e0e10] p-5">
      <div className="kinetic-rule mb-2" />
      {ENGINE_ROWS.map(([label, value, note]) => (
        <div key={label} className="flex items-baseline justify-between border-b border-white/5 pb-1.5">
          <span className="text-[9px] uppercase tracking-[0.14em] text-zinc-500">{label}</span>
          <span className="vl-tabular text-[12px] font-bold text-white">{value}</span>
          <span className="text-[8px] text-volt-400">{note}</span>
        </div>
      ))}
      <div className="kinetic-rule mt-2" />
      <span className="vl-layer-cap condensed-kicker mx-auto mt-1 text-[9px] text-white/40">Adaptive engine</span>
    </div>
  );
}

function TitaniumLayer() {
  return (
    <div className="vl-titanium relative flex h-full w-full items-center justify-center overflow-hidden rounded-[2.2rem]">
      <span
        className="display-heading select-none text-[11rem] text-black/15"
        style={{ textShadow: '0 1px 0 rgba(255,255,255,0.12)' }}
      >
        Z
      </span>
      <span className="vl-layer-cap condensed-kicker absolute bottom-4 left-1/2 -translate-x-1/2 text-[9px] text-black/40">
        Titanium
      </span>
    </div>
  );
}

// zStep: how far each layer travels (in px of translateZ) at full explosion
const LAYERS: Array<{ node: React.ReactNode; z: number; dim?: number }> = [
  { node: <TitaniumLayer />, z: -415, dim: 0.5 },
  { node: <EngineLayer />, z: -310, dim: 0.65 },
  { node: <LibraryLayer />, z: -205, dim: 0.8 },
  { node: <WorkoutLayer />, z: -105, dim: 0.9 },
  { node: <CoreLayer />, z: -10 },
  { node: <MenuScanLayer />, z: 85 },
  { node: <UiLayer />, z: 180 },
  { node: <HomeLayer />, z: 280 },
  { node: <GlassLayer />, z: 385 },
];

export default function InsideTheCoach() {
  const runwayRef = useRef<HTMLElement>(null);
  const stackRef = useRef<HTMLDivElement>(null);
  const layerRefs = useRef<Array<HTMLDivElement | null>>([]);
  const calloutRefs = useRef<Array<HTMLDivElement | null>>([]);
  const [live, setLive] = useState(false);

  useEffect(() => {
    if (isPrerender() || prefersReducedMotion()) return;
    setLive(true);
  }, []);

  useEffect(() => {
    if (!live) return;
    const runway = runwayRef.current;
    const stack = stackRef.current;
    if (!runway || !stack) return;

    gsap.registerPlugin(ScrollTrigger);
    const smooth = (a: number, b: number, x: number) => {
      const t = Math.max(0, Math.min(1, (x - a) / (b - a)));
      return t * t * (3 - 2 * t);
    };

    const trigger = ScrollTrigger.create({
      trigger: runway,
      start: 'top top',
      end: 'bottom bottom',
      scrub: 0.5,
      onUpdate(self) {
        const p = self.progress;
        const turn = smooth(0, 0.26, p);
        const explode = smooth(0.22, 0.8, p);

        stack.style.transform = `rotateY(${-2 + turn * 30 + p * 6}deg) rotateX(${turn * 7}deg)`;
        stack.style.setProperty('--capop', String(explode));

        LAYERS.forEach((layer, i) => {
          const el = layerRefs.current[i];
          if (!el) return;
          el.style.transform = `translate(-50%, -50%) translateZ(${layer.z * explode}px)`;
        });

        CALLOUTS.forEach((c, i) => {
          const el = calloutRefs.current[i];
          if (!el) return;
          const [a, b] = c.window;
          const vis = Math.max(0, Math.min(1, (p - a) / (b - a)));
          el.style.opacity = String(0.25 + vis * 0.75);
          el.style.transform = `translateX(${(1 - vis) * 18}px)`;
        });
      },
    });

    return () => {
      trigger.kill();
    };
  }, [live]);

  return (
    <section
      ref={runwayRef}
      className={`relative border-t border-white/5 ${live ? 'h-[300vh]' : ''}`}
      aria-labelledby="inside-heading"
    >
      <div className={`${live ? 'sticky top-0 flex h-screen items-center overflow-hidden' : 'py-24 sm:py-32'}`}>
        {/* Heading */}
        <div className={`${live ? 'absolute left-0 top-0 z-10 p-6 sm:p-12' : 'mx-auto max-w-[1100px] px-6'}`}>
          <p className="condensed-kicker mb-4 text-xs text-volt-500">The teardown</p>
          <h2 id="inside-heading" className="display-heading text-4xl text-white sm:text-6xl">
            Anatomy of<br />a coach.
          </h2>
          {!live && (
            <p className="mt-5 max-w-xl text-zinc-400">
              One device carries the whole coaching stack. Here is what it is
              made of.
            </p>
          )}
        </div>

        {/* The exploded stack — crisp DOM layers in true CSS 3D */}
        {live && (
          <div
            className="mx-auto"
            style={{ perspective: 1500, width: 'min(46vw, 420px)' }}
            aria-hidden="true"
          >
            <div
              ref={stackRef}
              className="relative"
              style={{ transformStyle: 'preserve-3d', height: 'min(72vh, 580px)', ['--capop' as string]: 0 }}
            >
              {LAYERS.map((layer, i) => (
                <div
                  key={i}
                  ref={(el) => {
                    layerRefs.current[i] = el;
                  }}
                  className="absolute left-1/2 top-1/2 h-full w-[290px]"
                  style={{
                    transform: 'translate(-50%, -50%) translateZ(0px)',
                    transformStyle: 'preserve-3d',
                    filter: layer.dim ? `brightness(${layer.dim})` : undefined,
                  }}
                >
                  {layer.node}
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Callouts */}
        <div
          className={`${
            live
              ? 'absolute right-0 top-1/2 z-10 hidden w-full max-w-sm -translate-y-1/2 space-y-7 p-6 sm:p-12 lg:block'
              : 'mx-auto mt-12 grid max-w-[1100px] grid-cols-1 gap-8 px-6 sm:grid-cols-2'
          }`}
        >
          {CALLOUTS.map((c, i) => (
            <div
              key={c.k}
              ref={(el) => {
                calloutRefs.current[i] = el;
              }}
              className={live ? 'opacity-25' : ''}
            >
              <div className="flex items-baseline gap-3">
                <span className="condensed-kicker text-[11px] text-volt-500">{c.k}</span>
                <h3 className="text-base font-semibold text-white sm:text-lg">{c.title}</h3>
              </div>
              <div className="kinetic-rule mt-2 mb-2 w-24" />
              <p className="text-sm leading-relaxed text-zinc-400">{c.body}</p>
            </div>
          ))}
        </div>

        {live && (
          <p className="condensed-kicker absolute bottom-6 left-1/2 -translate-x-1/2 text-[10px] text-zinc-600">
            Keep scrolling · the device opens up
          </p>
        )}
      </div>
    </section>
  );
}
