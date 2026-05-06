import { useEffect, useMemo, useRef, useState } from 'react';
import { motion, AnimatePresence, useReducedMotion } from 'framer-motion';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import { BRANDING } from '../lib/branding';

/* ────────────────────────────────────────────────────────────
   Architecture page — sanitized, public-facing.
   Diagrams are hand-built in React/SVG (not embedded mmd PNGs)
   so they animate and respond to the user.
   ──────────────────────────────────────────────────────────── */

// ─────────── 1. Layered stack data ───────────
const STACK_LAYERS = [
  {
    id: 'client',
    title: 'Client',
    subtitle: 'Flutter — iOS · Android · Widgets',
    accent: '#22C55E',
    points: [
      'Single Flutter codebase, native widgets on both platforms',
      'Riverpod state, Drift for local cache, on-device AI for offline',
      'Streaming chat over SSE, optimistic UI everywhere',
    ],
  },
  {
    id: 'edge',
    title: 'Edge',
    subtitle: 'TLS · CDN · Push',
    accent: '#10B981',
    points: [
      'Every request authenticated with a short-lived JWT',
      'Rate-limited at the edge before reaching application code',
      'Push delivered through APNs and FCM, never via custom sockets',
    ],
  },
  {
    id: 'api',
    title: 'API',
    subtitle: 'FastAPI · async Python',
    accent: '#06B6D4',
    points: [
      'Layered middleware: security headers → body limits → auth → routing',
      'Background tasks for non-blocking writes; parallel queries on hot paths',
      'Structured request IDs propagate end-to-end for tracing',
    ],
  },
  {
    id: 'ai',
    title: 'AI',
    subtitle: 'Multi-agent · RAG · Vision',
    accent: '#A855F7',
    points: [
      'A router picks one of five domain agents per turn',
      'Vision model classifies media before routing — no guessing',
      'RAG grounds answers in your history, not generic web data',
    ],
  },
  {
    id: 'data',
    title: 'Data',
    subtitle: 'Postgres · Object store · Vectors',
    accent: '#F97316',
    points: [
      'Postgres with row-level security as the source of truth',
      'Vector store for retrieval; object store for media',
      'Encrypted in transit and at rest; you can delete everything any time',
    ],
  },
];

// ─────────── 2. Request-flow animation steps ───────────
type FlowStep = {
  id: string;
  title: string;
  detail: string;
  // node id that lights up at this step
  active: 'user' | 'edge' | 'classify' | 'router' | 'agent' | 'tools' | 'db' | 'response';
};

const FLOW_STEPS: FlowStep[] = [
  {
    id: 's1',
    title: 'You snap a photo of dinner',
    detail: 'Image uploaded directly to object storage with a short-lived signed URL. The server never sees your raw bytes through its own bandwidth.',
    active: 'user',
  },
  {
    id: 's2',
    title: 'Edge verifies you',
    detail: 'JWT is checked, rate limits applied, request gets a unique ID for tracing.',
    active: 'edge',
  },
  {
    id: 's3',
    title: 'Vision classifies what it sees',
    detail: 'Before any agent runs, a tiny vision call decides: food plate, exercise form, progress photo, screenshot? Mis-routes are eliminated upfront.',
    active: 'classify',
  },
  {
    id: 's4',
    title: 'Router picks the right specialist',
    detail: 'Five agents specialize in coaching, nutrition, workouts, injuries, and hydration. The router uses mention → media → intent — in that order.',
    active: 'router',
  },
  {
    id: 's5',
    title: 'Agent reasons with your context',
    detail: 'Your goals, schedule, and recent history are pulled from a vector store and grounded into the prompt — not memorized, retrieved.',
    active: 'agent',
  },
  {
    id: 's6',
    title: 'Tools do the actual work',
    detail: 'The agent calls real functions: log this meal, swap that exercise, flag an injury. No hallucinated database writes.',
    active: 'tools',
  },
  {
    id: 's7',
    title: 'Result lands back in your app',
    detail: 'The final reply streams back token-by-token over SSE, with a structured payload your UI can render — chips, charts, confirmations.',
    active: 'response',
  },
];

// ─────────── 3. Agent orbit data ───────────
const AGENTS = [
  { id: 'coach', label: 'Coach', tools: 'General Q&A · navigation · settings', angle: -90 },
  { id: 'nutrition', label: 'Nutrition', tools: 'Photo logging · macros · meal plans', angle: -18 },
  { id: 'workout', label: 'Workout', tools: 'Add / swap / reschedule · form review', angle: 54 },
  { id: 'injury', label: 'Injury', tools: 'Report · adapt plan · clear when healed', angle: 126 },
  { id: 'hydration', label: 'Hydration', tools: 'Log water · daily targets', angle: 198 },
];

// ─────────── 4. Data-locality cards ───────────
const DATA_HOMES = [
  { title: 'On your device', body: 'Cached schedule, offline workouts, on-device AI fallback.', chip: 'Local' },
  { title: 'In transit', body: 'TLS 1.3 only. JWT bearer per request, rotated on refresh.', chip: 'Encrypted' },
  { title: 'In the API', body: 'Stateless workers. No long-lived per-user storage.', chip: 'Ephemeral' },
  { title: 'In your row', body: 'Postgres with row-level security: only your user_id reads your data.', chip: 'Isolated' },
  { title: 'In the vectors', body: 'Embeddings for retrieval — never your raw text in plaintext form to third parties.', chip: 'Retrieval' },
  { title: 'Yours to delete', body: 'One-tap delete account wipes Postgres, vectors, and stored media.', chip: 'Reversible' },
];

// ─────────── 5. Principles ───────────
const PRINCIPLES = [
  { title: 'No mock data in production', body: 'If the AI does not return it, we do not invent it. Bugs surface immediately.' },
  { title: 'Specialists over generalists', body: 'Five focused agents beat one giant prompt. Fewer hallucinations, better tools.' },
  { title: 'Retrieval over memorization', body: 'Your context is fetched fresh each turn. Models stay small; answers stay grounded.' },
  { title: 'Offline is a first-class mode', body: 'Pre-cached plans and on-device generation keep training going on a plane.' },
  { title: 'Stream by default', body: 'Replies render as they are produced. Nothing waits for a full response to start.' },
  { title: 'Privacy is the default', body: 'Row-level security, signed URLs, full delete — not bolt-on toggles.' },
];

// ─────────── 6. Tech badges ───────────
const TECH = [
  { name: 'Flutter', role: 'iOS · Android · Widgets' },
  { name: 'FastAPI', role: 'Async Python API' },
  { name: 'Supabase', role: 'Postgres · Auth · RLS' },
  { name: 'Google Gemini', role: 'LLM · Vision' },
  { name: 'LangGraph', role: 'Agent orchestration' },
  { name: 'ChromaDB', role: 'Vector retrieval' },
  { name: 'Render', role: 'Backend hosting' },
  { name: 'Vercel', role: 'Marketing site' },
  { name: 'RevenueCat', role: 'Subscriptions' },
  { name: 'AWS S3', role: 'Media storage' },
  { name: 'FCM · APNs', role: 'Push delivery' },
  { name: 'SendGrid', role: 'Lifecycle email' },
];

/* ──────────────── Subcomponents ──────────────── */

function TopologyBackdrop() {
  // Subtle animated dot grid for the hero. Pure SVG, GPU-friendly.
  const dots = useMemo(() => {
    const out: { x: number; y: number; d: number }[] = [];
    for (let y = 0; y < 14; y++) {
      for (let x = 0; x < 22; x++) {
        out.push({ x: x * 60, y: y * 60, d: (x + y) * 0.08 });
      }
    }
    return out;
  }, []);
  return (
    <svg
      className="absolute inset-0 w-full h-full pointer-events-none opacity-[0.35]"
      viewBox="0 0 1320 840"
      preserveAspectRatio="xMidYMid slice"
      aria-hidden
    >
      <defs>
        <radialGradient id="fade" cx="50%" cy="50%" r="60%">
          <stop offset="0%" stopColor="#ffffff" stopOpacity="0.25" />
          <stop offset="100%" stopColor="#ffffff" stopOpacity="0" />
        </radialGradient>
      </defs>
      <rect width="1320" height="840" fill="url(#fade)" />
      {dots.map((p, i) => (
        <motion.circle
          key={i}
          cx={p.x}
          cy={p.y}
          r={1.2}
          fill="#10B981"
          initial={{ opacity: 0.15 }}
          animate={{ opacity: [0.15, 0.55, 0.15] }}
          transition={{ duration: 5, delay: p.d, repeat: Infinity, ease: 'easeInOut' }}
        />
      ))}
    </svg>
  );
}

function LayeredStack() {
  const [open, setOpen] = useState<string | null>('ai');
  return (
    <div className="grid gap-3 max-w-[920px] mx-auto">
      {STACK_LAYERS.map((l, idx) => {
        const isOpen = open === l.id;
        return (
          <motion.button
            key={l.id}
            onClick={() => setOpen(isOpen ? null : l.id)}
            initial={{ opacity: 0, y: 12 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: '-80px' }}
            transition={{ delay: idx * 0.06 }}
            className="group text-left relative overflow-hidden rounded-2xl border border-[var(--color-border)] bg-[var(--color-surface-elevated)] hover:border-[var(--color-border-light)] transition-colors"
            style={{
              boxShadow: isOpen ? `0 12px 40px ${l.accent}22` : undefined,
            }}
          >
            {/* Accent rail */}
            <div
              className="absolute left-0 top-0 bottom-0 w-1"
              style={{ background: `linear-gradient(180deg, ${l.accent}, ${l.accent}33)` }}
            />
            <div className="flex items-center justify-between px-6 py-5 pl-7">
              <div className="flex items-baseline gap-4">
                <span
                  className="text-[11px] tracking-[0.18em] uppercase font-semibold opacity-60"
                  style={{ color: l.accent }}
                >
                  Layer {idx + 1}
                </span>
                <h3
                  className="text-[20px] sm:text-[22px] font-semibold tracking-[-0.01em]"
                  style={{ fontFamily: 'var(--font-heading)' }}
                >
                  {l.title}
                </h3>
                <span className="text-[13px] text-[var(--color-text-muted)] hidden sm:inline">
                  {l.subtitle}
                </span>
              </div>
              <motion.span
                animate={{ rotate: isOpen ? 45 : 0 }}
                className="text-[var(--color-text-muted)] text-xl"
              >
                +
              </motion.span>
            </div>
            <AnimatePresence initial={false}>
              {isOpen && (
                <motion.div
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: 'auto', opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  transition={{ duration: 0.28 }}
                  className="overflow-hidden"
                >
                  <ul className="px-7 pb-6 pt-1 space-y-2">
                    {l.points.map((p) => (
                      <li
                        key={p}
                        className="text-[14.5px] text-[var(--color-text-secondary)] flex gap-3"
                      >
                        <span
                          className="mt-[9px] block w-1.5 h-1.5 rounded-full shrink-0"
                          style={{ background: l.accent }}
                        />
                        <span>{p}</span>
                      </li>
                    ))}
                  </ul>
                </motion.div>
              )}
            </AnimatePresence>
          </motion.button>
        );
      })}
    </div>
  );
}

/* Animated request flow.
   Geometry: 8 nodes in a 2-row arrangement. A glowing packet travels
   the path; the "active" node lights up per step. Auto-plays and loops,
   but the user can scrub via the step list. */
function RequestFlow() {
  const reduce = useReducedMotion();
  const [stepIdx, setStepIdx] = useState(0);
  const [playing, setPlaying] = useState(true);
  const timer = useRef<number | null>(null);

  useEffect(() => {
    if (!playing || reduce) return;
    timer.current = window.setTimeout(() => {
      setStepIdx((i) => (i + 1) % FLOW_STEPS.length);
    }, 2400);
    return () => {
      if (timer.current) window.clearTimeout(timer.current);
    };
  }, [stepIdx, playing, reduce]);

  const active = FLOW_STEPS[stepIdx].active;

  // 8 named coordinates (in 800x340 viewBox)
  const NODES: Record<FlowStep['active'], { x: number; y: number; label: string; sub: string }> = {
    user:     { x: 60,  y: 80,  label: 'You',          sub: 'Flutter app' },
    edge:     { x: 200, y: 80,  label: 'Edge',         sub: 'JWT · rate limit' },
    classify: { x: 340, y: 80,  label: 'Vision',       sub: 'media classifier' },
    router:   { x: 480, y: 80,  label: 'Router',       sub: 'mention · media · intent' },
    agent:    { x: 620, y: 80,  label: 'Agent',        sub: 'specialist for the turn' },
    tools:    { x: 620, y: 240, label: 'Tools',        sub: 'log · swap · adapt' },
    db:       { x: 480, y: 240, label: 'Postgres',     sub: 'your row · RLS' },
    response: { x: 60,  y: 240, label: 'Reply',        sub: 'streamed back' },
  };
  const ORDER: FlowStep['active'][] = [
    'user', 'edge', 'classify', 'router', 'agent', 'tools', 'db', 'response',
  ];

  // build connecting path
  const path = ORDER.map((k, i) => {
    const n = NODES[k];
    return `${i === 0 ? 'M' : 'L'} ${n.x} ${n.y}`;
  }).join(' ');

  return (
    <div className="grid lg:grid-cols-[1.4fr_1fr] gap-8 items-start">
      {/* Diagram */}
      <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-5 sm:p-7 overflow-hidden">
        <svg viewBox="0 0 800 340" className="w-full h-auto">
          {/* Connecting path */}
          <path d={path} stroke="var(--color-border-light)" strokeWidth="1.5" fill="none" />
          {/* Animated dashed glow trail */}
          <motion.path
            d={path}
            stroke="#10B981"
            strokeWidth="2"
            fill="none"
            strokeDasharray="4 8"
            initial={{ pathLength: 0 }}
            animate={{ pathLength: 1 }}
            transition={{ duration: 4, repeat: Infinity, ease: 'linear' }}
            opacity={reduce ? 0 : 0.55}
          />

          {/* Nodes */}
          {ORDER.map((k) => {
            const n = NODES[k];
            const isActive = active === k;
            return (
              <g key={k}>
                <motion.circle
                  cx={n.x}
                  cy={n.y}
                  r={isActive ? 38 : 30}
                  fill={isActive ? '#10B98122' : 'transparent'}
                  stroke={isActive ? '#10B981' : 'var(--color-border-light)'}
                  strokeWidth={isActive ? 2 : 1.4}
                  animate={{ r: isActive ? 38 : 30 }}
                  transition={{ type: 'spring', stiffness: 200, damping: 18 }}
                />
                {isActive && !reduce && (
                  <motion.circle
                    cx={n.x}
                    cy={n.y}
                    r={30}
                    fill="none"
                    stroke="#10B981"
                    strokeWidth="2"
                    initial={{ r: 30, opacity: 0.6 }}
                    animate={{ r: 60, opacity: 0 }}
                    transition={{ duration: 1.4, repeat: Infinity, ease: 'easeOut' }}
                  />
                )}
                <text
                  x={n.x}
                  y={n.y + 4}
                  textAnchor="middle"
                  fontSize="13"
                  fontWeight="600"
                  fill="var(--color-text)"
                  style={{ fontFamily: 'var(--font-heading)' }}
                >
                  {n.label}
                </text>
                <text
                  x={n.x}
                  y={n.y + (k === 'user' || k === 'edge' || k === 'classify' || k === 'router' || k === 'agent' ? -42 : 56)}
                  textAnchor="middle"
                  fontSize="10.5"
                  fill="var(--color-text-muted)"
                >
                  {n.sub}
                </text>
              </g>
            );
          })}
        </svg>
      </div>

      {/* Step list / controls */}
      <div className="space-y-2">
        <div className="flex items-center gap-2 mb-3">
          <button
            onClick={() => setPlaying((p) => !p)}
            className="text-[12px] font-medium px-3 py-1.5 rounded-full border border-[var(--color-border)] hover:bg-[var(--color-surface-muted)] transition-colors"
          >
            {playing ? 'Pause' : 'Play'}
          </button>
          <span className="text-[12px] text-[var(--color-text-muted)]">
            Step {stepIdx + 1} / {FLOW_STEPS.length}
          </span>
        </div>
        {FLOW_STEPS.map((s, i) => {
          const isActive = i === stepIdx;
          return (
            <button
              key={s.id}
              onClick={() => {
                setStepIdx(i);
                setPlaying(false);
              }}
              className="w-full text-left rounded-xl border px-4 py-3 transition-all"
              style={{
                borderColor: isActive ? '#10B981' : 'var(--color-border)',
                background: isActive ? 'rgba(16,185,129,0.06)' : 'transparent',
              }}
            >
              <div className="flex items-baseline gap-3">
                <span
                  className="text-[11px] tabular-nums w-5 shrink-0"
                  style={{ color: isActive ? '#10B981' : 'var(--color-text-muted)' }}
                >
                  {String(i + 1).padStart(2, '0')}
                </span>
                <div>
                  <p className="text-[14px] font-semibold text-[var(--color-text)]">{s.title}</p>
                  {isActive && (
                    <motion.p
                      initial={{ opacity: 0, height: 0 }}
                      animate={{ opacity: 1, height: 'auto' }}
                      className="text-[13px] text-[var(--color-text-secondary)] mt-1.5 leading-relaxed"
                    >
                      {s.detail}
                    </motion.p>
                  )}
                </div>
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
}

/* AI brain — radial agents around a router. Hover an agent to see its tools. */
function AgentOrbit() {
  const [hover, setHover] = useState<string | null>(null);
  const reduce = useReducedMotion();
  const radius = 165;

  return (
    <div className="relative w-full max-w-[560px] aspect-square mx-auto">
      {/* Rotating ring */}
      <motion.div
        className="absolute inset-8 rounded-full border border-dashed border-[var(--color-border-light)]"
        animate={reduce ? {} : { rotate: 360 }}
        transition={{ duration: 60, repeat: Infinity, ease: 'linear' }}
      />
      <motion.div
        className="absolute inset-20 rounded-full border border-dashed border-[var(--color-border)]"
        animate={reduce ? {} : { rotate: -360 }}
        transition={{ duration: 90, repeat: Infinity, ease: 'linear' }}
      />

      {/* Center node = Router */}
      <div className="absolute inset-0 flex items-center justify-center">
        <div
          className="relative w-[150px] h-[150px] rounded-full flex flex-col items-center justify-center text-center px-4"
          style={{
            background:
              'radial-gradient(circle at 30% 30%, rgba(16,185,129,0.25), rgba(16,185,129,0.05) 60%)',
            border: '1px solid rgba(16,185,129,0.45)',
            boxShadow: '0 0 40px rgba(16,185,129,0.18)',
          }}
        >
          <p
            className="text-[14px] font-semibold text-[var(--color-text)]"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Router
          </p>
          <p className="text-[11px] text-[var(--color-text-muted)] mt-1 leading-tight">
            mention → media →<br />intent → keyword
          </p>
        </div>
      </div>

      {/* Agent satellites */}
      {AGENTS.map((a, i) => {
        const rad = (a.angle * Math.PI) / 180;
        const x = 50 + (radius / 5.6) * Math.cos(rad);
        const y = 50 + (radius / 5.6) * Math.sin(rad);
        const isHover = hover === a.id;
        return (
          <motion.button
            key={a.id}
            onMouseEnter={() => setHover(a.id)}
            onMouseLeave={() => setHover(null)}
            onFocus={() => setHover(a.id)}
            onBlur={() => setHover(null)}
            initial={{ opacity: 0, scale: 0.7 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 + i * 0.08 }}
            className="absolute -translate-x-1/2 -translate-y-1/2 group"
            style={{ left: `${x}%`, top: `${y}%` }}
          >
            <div
              className="rounded-full px-4 py-2.5 backdrop-blur-md transition-all"
              style={{
                background: isHover
                  ? 'rgba(16,185,129,0.18)'
                  : 'var(--color-surface-elevated)',
                border: `1px solid ${isHover ? '#10B981' : 'var(--color-border)'}`,
                boxShadow: isHover ? '0 8px 30px rgba(16,185,129,0.25)' : 'var(--shadow-card)',
              }}
            >
              <p className="text-[13px] font-semibold text-[var(--color-text)]">{a.label}</p>
            </div>
            <AnimatePresence>
              {isHover && (
                <motion.div
                  initial={{ opacity: 0, y: 4 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: 4 }}
                  className="absolute left-1/2 -translate-x-1/2 mt-2 whitespace-nowrap rounded-md px-3 py-1.5 text-[11px] font-medium z-10"
                  style={{
                    background: 'var(--color-text)',
                    color: 'var(--color-background)',
                  }}
                >
                  {a.tools}
                </motion.div>
              )}
            </AnimatePresence>
          </motion.button>
        );
      })}
    </div>
  );
}

/* ──────────────── Page ──────────────── */
export default function Architecture() {
  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)]">
      <MarketingNav />

      {/* HERO */}
      <section className="relative pt-32 pb-24 px-6 overflow-hidden">
        <TopologyBackdrop />
        <div className="relative max-w-[1100px] mx-auto text-center">
          <motion.span
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            className="inline-block text-[11px] tracking-[0.2em] uppercase font-semibold text-emerald-500 mb-5"
          >
            Architecture
          </motion.span>
          <motion.h1
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.05 }}
            className="text-[40px] sm:text-[64px] font-semibold tracking-[-0.025em] leading-[1.05]"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            How {BRANDING.appName} thinks,
            <br />
            learns, and adapts.
          </motion.h1>
          <motion.p
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.12 }}
            className="mt-6 text-[17px] sm:text-[19px] text-[var(--color-text-secondary)] leading-relaxed max-w-[640px] mx-auto"
          >
            A multi-agent AI coach, a streaming Python API, an offline-capable Flutter
            client, and a privacy model that lets you delete everything. Here is the
            full picture — without the marketing fog.
          </motion.p>
        </div>
      </section>

      {/* SECTION — STACK */}
      <Section
        eyebrow="The stack"
        title="Five layers, one product"
        body="Click any layer to see what lives there. Designed so a request can fail loudly at one boundary instead of silently corrupting the next."
      >
        <LayeredStack />
      </Section>

      {/* SECTION — REQUEST FLOW */}
      <Section
        eyebrow="Anatomy of a message"
        title="What happens when you ask the coach something"
        body="A single chat turn fans out across eight services. The animation below shows the same path a real food-photo message takes — start to finish."
        tone="dim"
      >
        <RequestFlow />
      </Section>

      {/* SECTION — AI BRAIN */}
      <Section
        eyebrow="The AI brain"
        title="A router and five specialists"
        body="One giant prompt is a leaky abstraction. We split coaching into focused agents — each with its own tools — and let a router pick the right one per turn."
      >
        <AgentOrbit />
      </Section>

      {/* SECTION — DATA HOMES */}
      <Section
        eyebrow="Where your data lives"
        title="Six places, one tap to delete them all"
        body="Every byte has a home and a reason for being there. We do not hoard data — and you do not have to email us to leave."
        tone="dim"
      >
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4 max-w-[1100px] mx-auto">
          {DATA_HOMES.map((d, i) => (
            <motion.div
              key={d.title}
              initial={{ opacity: 0, y: 14 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: '-60px' }}
              transition={{ delay: i * 0.05 }}
              className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-5"
            >
              <div className="flex items-baseline justify-between mb-2">
                <h3
                  className="text-[16px] font-semibold"
                  style={{ fontFamily: 'var(--font-heading)' }}
                >
                  {d.title}
                </h3>
                <span className="text-[10px] tracking-[0.16em] uppercase font-semibold text-emerald-500">
                  {d.chip}
                </span>
              </div>
              <p className="text-[13.5px] text-[var(--color-text-secondary)] leading-relaxed">
                {d.body}
              </p>
            </motion.div>
          ))}
        </div>
      </Section>

      {/* SECTION — PRINCIPLES */}
      <Section
        eyebrow="Engineering principles"
        title="Six rules we wrote down so we would not break them"
      >
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4 max-w-[1100px] mx-auto">
          {PRINCIPLES.map((p, i) => (
            <motion.div
              key={p.title}
              initial={{ opacity: 0, y: 14 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: '-60px' }}
              transition={{ delay: i * 0.04 }}
              className="rounded-2xl p-5 relative overflow-hidden"
              style={{
                background:
                  'linear-gradient(135deg, rgba(16,185,129,0.08), rgba(168,85,247,0.04))',
                border: '1px solid var(--color-border)',
              }}
            >
              <span
                className="absolute -top-6 -right-4 text-[80px] font-bold tracking-tighter opacity-[0.06]"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                {String(i + 1).padStart(2, '0')}
              </span>
              <h3
                className="text-[17px] font-semibold mb-2"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                {p.title}
              </h3>
              <p className="text-[13.5px] text-[var(--color-text-secondary)] leading-relaxed">
                {p.body}
              </p>
            </motion.div>
          ))}
        </div>
      </Section>

      {/* SECTION — TECH */}
      <Section
        eyebrow="Built with"
        title="The stack, on a single line"
        tone="dim"
      >
        <div className="flex flex-wrap gap-2.5 justify-center max-w-[1000px] mx-auto">
          {TECH.map((t) => (
            <div
              key={t.name}
              className="group rounded-full px-4 py-2 border border-[var(--color-border)] bg-[var(--color-surface-elevated)] text-[13px] flex items-center gap-2"
            >
              <span className="font-semibold text-[var(--color-text)]">{t.name}</span>
              <span className="text-[var(--color-text-muted)]">·</span>
              <span className="text-[var(--color-text-secondary)]">{t.role}</span>
            </div>
          ))}
        </div>
      </Section>

      {/* CTA */}
      <section className="px-6 pb-28">
        <div className="max-w-[820px] mx-auto rounded-3xl p-10 sm:p-14 text-center relative overflow-hidden border border-[var(--color-border)] bg-[var(--color-surface-elevated)]">
          <div
            aria-hidden
            className="absolute inset-0 opacity-50 pointer-events-none"
            style={{
              background:
                'radial-gradient(ellipse at top, rgba(16,185,129,0.18), transparent 60%)',
            }}
          />
          <h2
            className="relative text-[28px] sm:text-[36px] font-semibold tracking-[-0.02em]"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            See the architecture in motion.
          </h2>
          <p className="relative text-[15px] text-[var(--color-text-secondary)] mt-3 max-w-[520px] mx-auto">
            The fastest way to understand how it all fits together is to use it.
          </p>
          <div className="relative mt-7 flex flex-wrap gap-3 justify-center">
            <a
              href="https://play.google.com/store/apps/details?id=com.aifitnesscoach.app"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 rounded-full px-6 py-3 text-[14px] font-semibold text-white bg-emerald-500 hover:bg-emerald-600 transition-colors"
            >
              Try the app
            </a>
            <a
              href="/features"
              className="inline-flex items-center gap-2 rounded-full px-6 py-3 text-[14px] font-semibold border border-[var(--color-border)] text-[var(--color-text)] hover:bg-[var(--color-surface-muted)] transition-colors"
            >
              See features
            </a>
          </div>
        </div>
      </section>

      <MarketingFooter />
    </div>
  );
}

/* Generic section wrapper */
function Section({
  eyebrow,
  title,
  body,
  children,
  tone = 'plain',
}: {
  eyebrow: string;
  title: string;
  body?: string;
  children: React.ReactNode;
  tone?: 'plain' | 'dim';
}) {
  return (
    <section
      className="px-6 py-20"
      style={{
        background:
          tone === 'dim'
            ? 'linear-gradient(180deg, transparent, var(--color-surface-muted) 30%, var(--color-surface-muted) 70%, transparent)'
            : undefined,
      }}
    >
      <div className="max-w-[1100px] mx-auto">
        <div className="max-w-[720px] mb-10">
          <p className="text-[11px] tracking-[0.2em] uppercase font-semibold text-emerald-500 mb-3">
            {eyebrow}
          </p>
          <h2
            className="text-[28px] sm:text-[40px] font-semibold tracking-[-0.02em] leading-[1.1]"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            {title}
          </h2>
          {body && (
            <p className="text-[16px] text-[var(--color-text-secondary)] leading-relaxed mt-4 max-w-[640px]">
              {body}
            </p>
          )}
        </div>
        {children}
      </div>
    </section>
  );
}
