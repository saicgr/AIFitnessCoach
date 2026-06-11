// Auto-playing demo scenes rendered inside the hero phone — recreations of
// the REAL Zealova app UI, built from the Flutter source of truth:
//   lib/core/constants/app_colors.dart  (palette below)
//   lib/screens/chat/chat_screen.dart + chat_quick_pills.dart
//   lib/screens/workout/active_workout_screen_refactored.dart
//   lib/screens/nutrition/log_meal_sheet_ui.dart
//
// App palette (light theme): accent orange #F97316, user-bubble cyan
// #06B6D4 (white text), coach bubble #1A1A1A, macro colors protein #A855F7 /
// carbs #06B6D4 / fat #F97316, success #22C55E, surfaces #F4F4F5/#F8F8FA,
// CTAs = #F97316 fill, white text, radius 14.
//
// Scenes receive `t` (ms into the scene). When the demo is static
// (prerender / reduced motion) ChatScene renders its COMPLETED state so the
// prerendered HTML contains a full, real coach conversation.

const COACH_MSG =
  'Last week you hit 8 reps at 175 lb. Bump bench to 185 lb for 2 sets of 5 today. Keep your shoulder blades pinned.';
const USER_MSG = 'What about my sore shoulder?';
const COACH_REPLY = 'Swapping incline dumbbell press in. Lighter load, neutral grip.';

const ACCENT = '#F97316';
const USER_CYAN = '#06B6D4';
const COACH_BG = '#1A1A1A';

function clamp01(v: number) {
  return Math.max(0, Math.min(1, v));
}

/* App-style chat header: avatar + name + Online + trailing icons. */
function ChatHeader({ sub }: { sub?: string }) {
  return (
    <div className="absolute top-0 inset-x-0 z-[1] rounded-t-[2rem] bg-white px-3 pt-8 pb-2 border-b border-zinc-100">
      <div className="flex items-center gap-2">
        <span className="text-zinc-500 text-[13px]">‹</span>
        <span className="flex h-6 w-6 items-center justify-center rounded-full text-[10px] font-bold text-white" style={{ background: ACCENT }}>Z</span>
        <div className="min-w-0">
          <p className="text-[11px] font-semibold text-zinc-900 leading-tight">Coach Mike</p>
          {sub ? (
            <p className="text-[8px] uppercase tracking-[0.15em] text-zinc-400 leading-tight">{sub}</p>
          ) : (
            <p className="flex items-center gap-1 text-[8px] text-emerald-600 leading-tight">
              <span className="h-1 w-1 rounded-full bg-emerald-500" /> Online
            </p>
          )}
        </div>
        <span className="ml-auto flex items-center gap-2 text-zinc-400 text-[11px]">
          <span>ⓘ</span>
          <span>⋮</span>
        </span>
      </div>
    </div>
  );
}

/* Coach bubble — #1A1A1A, radius 12, orange name label inside. */
function CoachBubble({ children, labeled }: { children: React.ReactNode; labeled?: boolean }) {
  return (
    <div className="max-w-[88%] rounded-xl px-3 py-2 text-zinc-50" style={{ background: COACH_BG }}>
      {labeled && <p className="mb-0.5 text-[8px] font-semibold" style={{ color: ACCENT }}>🧡 Coach Mike</p>}
      {children}
    </div>
  );
}

/* App-style input bar: gallery/attach icons, "Ask Coach Mike…", mic + send. */
function ChatInputBar() {
  return (
    <div className="flex items-center gap-1.5">
      <span className="text-[12px] text-zinc-400">📷</span>
      <span className="text-[12px] text-zinc-400">📎</span>
      <span className="flex flex-1 items-center rounded-[14px] bg-[#F4F4F5] px-3 py-2 text-zinc-400">
        Ask Coach Mike…
      </span>
      <span className="text-[12px] text-zinc-400">🎙</span>
      <span className="flex h-6 w-6 items-center justify-center rounded-full text-[10px] font-bold text-white" style={{ background: ACCENT }}>↑</span>
    </div>
  );
}

/* ---------------------------------- Chat ---------------------------------- */

// Custom metric trend card the coach can surface inline in chat (the app's
// "see the trend" metric cards). SVG sparkline, accent line + soft fill.
function TrendCard({ shown }: { shown: boolean }) {
  return (
    <div
      className={`rounded-xl border border-zinc-200 bg-white p-2.5 shadow-[0_2px_10px_rgba(0,0,0,0.05)] transition-all duration-500 ${
        shown ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-2'
      }`}
    >
      <div className="flex items-center justify-between">
        <div>
          <p className="text-[7px] uppercase tracking-[0.15em] text-zinc-400">Custom trend</p>
          <p className="text-[10px] font-bold text-zinc-900">Bench Press · est. 1RM</p>
        </div>
        <span className="rounded-full bg-emerald-50 border border-emerald-200 px-1.5 py-0.5 text-[8px] font-bold text-emerald-600">+15%</span>
      </div>
      <svg viewBox="0 0 220 56" className="mt-1.5 h-12 w-full" aria-hidden="true">
        <defs>
          <linearGradient id="trendFill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={ACCENT} stopOpacity="0.25" />
            <stop offset="100%" stopColor={ACCENT} stopOpacity="0" />
          </linearGradient>
        </defs>
        <path d="M0 46 L30 44 L60 40 L90 41 L120 32 L150 28 L180 18 L214 10 L214 56 L0 56 Z" fill="url(#trendFill)" />
        <path d="M0 46 L30 44 L60 40 L90 41 L120 32 L150 28 L180 18 L214 10" fill="none" stroke={ACCENT} strokeWidth="2" strokeLinecap="round" />
        <circle cx="214" cy="10" r="3" fill={ACCENT} />
        <circle cx="214" cy="10" r="5.5" fill={ACCENT} opacity="0.25" />
      </svg>
      <div className="flex items-center justify-between">
        <span className="vl-tabular text-[8px] text-zinc-400">Mar · 195 lb</span>
        <div className="flex gap-1">
          {['1M', '3M', '6M'].map((r) => (
            <span
              key={r}
              className={`rounded-full px-1.5 py-0.5 text-[7px] font-semibold ${
                r === '3M' ? 'text-white' : 'bg-zinc-100 text-zinc-500'
              }`}
              style={r === '3M' ? { background: ACCENT } : undefined}
            >
              {r}
            </span>
          ))}
        </div>
        <span className="vl-tabular text-[8px] font-semibold text-zinc-700">Today · 225 lb</span>
      </div>
    </div>
  );
}

export function ChatScene({ t, isStatic }: { t: number; isStatic: boolean }) {
  const coachChars = isStatic ? COACH_MSG.length : Math.floor(clamp01(t / 2600) * COACH_MSG.length);
  const showUser = isStatic || t > 3200;
  const showDots = !isStatic && t > 3600 && t < 5000;
  const replyChars = isStatic ? COACH_REPLY.length : Math.floor(clamp01((t - 5000) / 1800) * COACH_REPLY.length);
  const showReply = isStatic || t > 5000;
  const showTrend = isStatic || t > 6400;

  return (
    <div className="flex h-full flex-col bg-white px-3 pt-[4.5rem] pb-3 text-[10px] leading-snug">
      <ChatHeader />

      <div className="mt-auto space-y-1.5">
        <CoachBubble labeled>
          {COACH_MSG.slice(0, coachChars)}
          {!isStatic && coachChars < COACH_MSG.length && <span className="opacity-60">▍</span>}
        </CoachBubble>
        <p className="pl-1 text-[7px] text-zinc-400">Yesterday, 20:59</p>

        {/* User bubble — cyan #06B6D4, white text (app_colors.dart).
            Conditionally rendered so the chat stays bottom-anchored. */}
        {showUser && (
          <div
            className="vl-pop-in ml-auto max-w-[78%] rounded-xl px-3 py-2 font-medium text-white"
            style={{ background: USER_CYAN }}
          >
            {USER_MSG}
          </div>
        )}
        {showUser && <p className="pr-1 text-right text-[7px] text-zinc-400">Yesterday, 21:00 ✓</p>}

        {showDots && (
          <div className="flex w-14 items-center justify-center gap-1 rounded-xl px-3 py-2.5" style={{ background: COACH_BG }}>
            <span className="vl-typing-dot inline-block h-1.5 w-1.5 rounded-full bg-zinc-300" />
            <span className="vl-typing-dot inline-block h-1.5 w-1.5 rounded-full bg-zinc-300" />
            <span className="vl-typing-dot inline-block h-1.5 w-1.5 rounded-full bg-zinc-300" />
          </div>
        )}

        {showReply && !showDots && (
          <div className="vl-pop-in">
            <CoachBubble labeled>
              {COACH_REPLY.slice(0, Math.max(0, replyChars))}
              {!isStatic && replyChars < COACH_REPLY.length && <span className="opacity-60">▍</span>}
            </CoachBubble>
          </div>
        )}

        {/* Coach surfaces the custom bench trend inline */}
        {showTrend && (
          <div className="vl-pop-in">
            <TrendCard shown />
          </div>
        )}

        <p className="text-center text-[7px] text-zinc-400">AI-generated content · not medical advice</p>

        {/* Quick pills row (chat_quick_pills.dart) */}
        <div className="flex gap-1.5 overflow-hidden">
          <span className="shrink-0 rounded-[20px] border border-black/5 bg-black/[0.04] px-2.5 py-1 text-[8px] font-medium text-zinc-700">
            <span style={{ color: ACCENT }}>🎥</span> Check My Form
          </span>
          <span className="shrink-0 rounded-[20px] border border-black/5 bg-black/[0.04] px-2.5 py-1 text-[8px] font-medium text-zinc-700">
            <span className="text-emerald-600">📷</span> Scan Food
          </span>
          <span className="shrink-0 rounded-[20px] border border-black/5 bg-black/[0.04] px-2.5 py-1 text-[8px] font-medium text-zinc-700">
            <span className="text-amber-500">⚡</span> Quick Workout
          </span>
        </div>

        <ChatInputBar />
      </div>
    </div>
  );
}

/* ----------------------- Coach builds a program ----------------------- */

const PROGRAM_DAYS = [
  { day: 'Mon', name: 'Push · chest, shoulders, triceps', at: 0.45 },
  { day: 'Tue', name: 'Pull · back, biceps', at: 0.58 },
  { day: 'Thu', name: 'Legs · quads, glutes, hams', at: 0.71 },
  { day: 'Sat', name: 'Upper · volume + arms', at: 0.84 },
];

const PROGRAM_ASK = 'Build me a 4-day program for a home gym';

export function ProgramScene({ t, isStatic }: { t: number; isStatic: boolean }) {
  const p = isStatic ? 1 : clamp01(t / 6600);
  const askChars = isStatic ? PROGRAM_ASK.length : Math.floor(clamp01(t / 1400) * PROGRAM_ASK.length);
  const generating = !isStatic && p > 0.25 && p < 0.42;
  const showPlan = isStatic || p >= 0.42;

  return (
    <div className="flex h-full flex-col bg-white px-3 pt-[4.5rem] pb-3 text-[10px]">
      <ChatHeader sub="Program builder" />

      <div className="ml-auto max-w-[88%] rounded-xl px-3 py-2 font-medium text-white" style={{ background: USER_CYAN }}>
        {PROGRAM_ASK.slice(0, askChars)}
        {!isStatic && askChars < PROGRAM_ASK.length && <span className="opacity-60">▍</span>}
      </div>

      {generating && (
        <div className="mt-2 flex w-fit items-center gap-2 rounded-xl px-3 py-2.5 text-zinc-300" style={{ background: COACH_BG }}>
          <span className="vl-typing-dot inline-block h-1.5 w-1.5 rounded-full" style={{ background: ACCENT }} />
          <span className="vl-typing-dot inline-block h-1.5 w-1.5 rounded-full" style={{ background: ACCENT }} />
          <span className="vl-typing-dot inline-block h-1.5 w-1.5 rounded-full" style={{ background: ACCENT }} />
          <span className="text-[9px]" style={{ color: ACCENT }}>Thinking… (3s)</span>
        </div>
      )}

      {showPlan && (
        <div className="mt-2 rounded-xl border border-zinc-200 bg-[#F8F8FA] p-3">
          <p className="text-[8px] uppercase tracking-[0.18em] font-semibold" style={{ color: ACCENT }}>✨ Your new program</p>
          <p className="mt-0.5 text-[12px] font-bold text-zinc-900">Home Gym Power Split</p>
          <div className="mt-2 space-y-1.5">
            {PROGRAM_DAYS.map((d) => {
              const on = p >= d.at;
              return (
                <div
                  key={d.day}
                  className={`flex items-center gap-2 rounded-[10px] border px-2.5 py-2 transition-all duration-300 ${
                    on ? 'border-orange-200 bg-white opacity-100' : 'border-zinc-100 bg-white/60 opacity-40'
                  }`}
                >
                  <span className={`w-7 text-[9px] font-bold ${on ? '' : 'text-zinc-400'}`} style={on ? { color: ACCENT } : undefined}>{d.day}</span>
                  <span className="text-[9px] text-zinc-700">{d.name}</span>
                  <span className={`ml-auto text-[9px] ${on ? 'text-emerald-500' : 'text-transparent'}`}>✓</span>
                </div>
              );
            })}
          </div>
          <div
            className={`mt-2.5 rounded-[14px] py-2 text-center text-[9px] font-semibold text-white transition-opacity duration-300 ${
              p >= 0.92 ? 'opacity-100' : 'opacity-0'
            }`}
            style={{ background: ACCENT }}
          >
            Start Monday
          </div>
        </div>
      )}

      <div className="mt-auto">
        <ChatInputBar />
      </div>
    </div>
  );
}

/* -------------------------------- Log a set -------------------------------- */

// Pyramid loading: weight climbs across sets (185 -> 215 -> 225), the way
// the app programs ascending sets.
const SETS = [
  { prev: '180 × 8', target: '185 lb × 8', lb: '185', reps: '8', rir: 'RIR 4', rirCls: 'bg-emerald-100 text-emerald-700', done: 0.3 },
  { prev: '205 × 5', target: '215 lb × 5', lb: '215', reps: '5', rir: 'RIR 2', rirCls: 'bg-amber-100 text-amber-700', done: 0.6 },
  { prev: '220 × 3', target: '225 lb × 3', lb: '225', reps: '3', rir: 'RIR 0', rirCls: 'bg-red-100 text-red-600', done: 0.88 },
];

export function LogSetScene({ t, isStatic }: { t: number; isStatic: boolean }) {
  const p = isStatic ? 1 : clamp01(t / 5600);

  return (
    <div className="flex h-full flex-col bg-white px-3 pt-[4.5rem] pb-3 text-[10px]">
      <div className="absolute top-0 inset-x-0 z-[1] rounded-t-[2rem] bg-white px-3 pt-8 pb-2 border-b border-zinc-100">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-[8px] uppercase tracking-[0.15em] text-zinc-400">Push Day · Set 2 of 3</p>
            <p className="text-[12px] font-bold text-zinc-900">Barbell Bench Press</p>
          </div>
          <span className="rounded-full bg-[#F4F4F5] px-2 py-0.5 text-[8px] font-semibold text-zinc-600">⏱ 01:52</span>
        </div>
      </div>

      {/* Feature chips — Pyramid active (ascending loads) */}
      <div className="flex gap-1.5">
        <span className="rounded-full bg-sky-50 border border-sky-200 px-2 py-0.5 text-[8px] font-medium text-sky-600">≋ Breathing</span>
        <span className="rounded-full border px-2 py-0.5 text-[8px] font-semibold" style={{ color: ACCENT, background: '#FFF7ED', borderColor: '#FED7AA' }}>▲ Pyramid</span>
        <span className="rounded-full bg-[#F8F8FA] border border-zinc-200 px-2 py-0.5 text-[8px] text-zinc-600">±10 lbs</span>
        <span className="rounded-full px-2 py-0.5 text-[8px] font-medium" style={{ color: ACCENT, background: '#FFF7ED' }}>Skip</span>
      </div>

      {/* Progressive overload — the engine bumped the load vs last week */}
      <div className="mt-1.5 flex items-center gap-1.5 rounded-[10px] border border-orange-200 bg-orange-50/70 px-2 py-1">
        <span className="text-[9px]">📈</span>
        <span className="text-[8px] font-semibold text-zinc-800">Progressive overload</span>
        <span className="vl-tabular ml-auto rounded-full px-1.5 py-0.5 text-[7.5px] font-bold text-white" style={{ background: ACCENT }}>+5 lb vs last week</span>
      </div>

      {/* Set table — SET / PREVIOUS / TARGET headers (uppercase, tracked) */}
      <div className="mt-2.5">
        <div className="grid grid-cols-[22px_34px_1fr_38px_30px_20px] items-center gap-1 rounded-t-[12px] bg-[#F8F8FA] px-1.5 py-1.5 text-[7px] font-semibold uppercase tracking-[0.05em] text-zinc-400">
          <span>Set</span><span>Prev</span><span>Target</span><span className="text-center">lb</span><span className="text-center">Reps</span><span />
        </div>
        <div className="divide-y divide-zinc-100 border-x border-b border-zinc-100 rounded-b-[12px]">
          {SETS.map((s, i) => {
            const checked = p >= s.done;
            return (
              <div
                key={i}
                className={`grid grid-cols-[22px_34px_1fr_38px_30px_20px] items-center gap-1 px-1.5 py-1.5 transition-colors duration-300 ${
                  checked ? 'bg-emerald-50/50' : 'bg-white'
                }`}
              >
                <span className="flex h-4 w-4 items-center justify-center rounded-full border border-zinc-200 bg-white text-[8px] text-zinc-500">{i + 1}</span>
                <span className="vl-tabular text-[8px] text-zinc-400">{s.prev}</span>
                <span className="text-[8.5px] text-zinc-700">
                  {s.target} <span className={`rounded px-1 text-[7px] font-semibold ${s.rirCls}`}>{s.rir}</span>
                </span>
                <span className={`vl-tabular rounded-md border border-zinc-200 bg-white py-0.5 text-center text-[9px] font-semibold ${checked ? 'text-zinc-900' : 'text-zinc-300'}`}>
                  {checked ? s.lb : '–'}
                </span>
                <span className={`vl-tabular rounded-md border border-zinc-200 bg-white py-0.5 text-center text-[9px] font-semibold ${checked ? 'text-zinc-900' : 'text-zinc-300'}`}>
                  {checked ? s.reps : '–'}
                </span>
                <span
                  className={`flex h-4.5 w-4.5 items-center justify-center rounded-md text-[9px] font-bold transition-all duration-300 ${
                    checked ? 'bg-emerald-500 text-white scale-100' : 'bg-white border border-zinc-200 text-transparent scale-95'
                  }`}
                  style={{ height: 17, width: 17 }}
                >
                  ✓
                </span>
              </div>
            );
          })}
        </div>
        <p className="mt-1 pl-1 text-[7px] text-zinc-400">set 1: 49s · rested 1:30</p>
      </div>

      {/* RIR picker row (colored soft chips, 3 selected) */}
      <div className="mt-1.5 flex items-center gap-1 px-1">
        <span className="mr-1 text-[7px] uppercase tracking-wider text-zinc-400">RIR</span>
        {['0', '1', '2', '3', '4', '5+'].map((r, i) => (
          <span
            key={r}
            className={`flex w-6 items-center justify-center rounded-md text-[8px] font-semibold ${
              i === 3 && p > 0.45
                ? 'bg-emerald-500 text-white'
                : ['bg-red-50 text-red-500', 'bg-orange-50 text-orange-500', 'bg-amber-50 text-amber-600', 'bg-emerald-50 text-emerald-600', 'bg-emerald-50 text-emerald-600', 'bg-emerald-50 text-emerald-600'][i]
            }`}
            style={{ height: 17 }}
          >
            {r}
          </span>
        ))}
      </div>

      <div className="mt-auto space-y-1.5">
        <div className="rounded-[12px] border py-2 text-center text-[10px] font-semibold" style={{ borderColor: '#FED7AA', background: '#FFF7ED', color: ACCENT }}>
          + Add Set
        </div>
        <div className="rounded-[12px] border border-zinc-200 bg-[#F8F8FA] px-2.5 py-1.5 text-[8px] text-zinc-500">
          ✨ Add exercises with AI…
        </div>
        <div className="flex gap-1.5">
          <span className="flex-1 rounded-full bg-violet-50 border border-violet-200 py-1.5 text-center text-[8px] font-medium text-violet-600">▶ Video</span>
          <span className="flex-1 rounded-full bg-sky-50 border border-sky-200 py-1.5 text-center text-[8px] font-medium text-sky-600">💧 Log Drink</span>
          <span className="flex-1 rounded-full bg-amber-50 border border-amber-200 py-1.5 text-center text-[8px] font-medium text-amber-600">📝 Note</span>
        </div>
        {/* Exercise strip — the workout's exercise thumbnails carousel at
            the very bottom of the real screen, current exercise highlighted */}
        <div className="flex items-center gap-1.5 border-t border-zinc-100 pt-1.5">
          {['🏋️', '🦾', '🚣', '🧱', '🛠'].map((icon, i) => (
            <span
              key={i}
              className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-[8px] border text-[12px] ${
                i === 1 ? 'bg-orange-50' : 'border-zinc-200 bg-[#F8F8FA] opacity-70'
              }`}
              style={i === 1 ? { borderColor: ACCENT, borderWidth: 1.5 } : undefined}
            >
              {icon}
            </span>
          ))}
          <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-[8px] border border-dashed border-zinc-300 text-[11px] text-zinc-400">+</span>
        </div>
      </div>
    </div>
  );
}

/* ------------------------------ PR celebration ------------------------------
 * Full-screen takeover: epic gold->orange->coral gradient, trophy, the new
 * 1RM, improvement vs previous, and share CTA. */

export function PRScene({ t, isStatic }: { t: number; isStatic: boolean }) {
  const popped = isStatic || t > 300;
  const detail = isStatic || t > 900;
  return (
    <div
      className="relative flex h-full flex-col items-center justify-center overflow-hidden px-5 text-center"
      style={{ background: 'linear-gradient(160deg, #FFD700 0%, #FFA500 45%, #FF6B35 100%)' }}
    >
      {/* Soft radial glow rings */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-0"
        style={{ background: 'radial-gradient(55% 40% at 50% 38%, rgba(255,255,255,0.35), transparent 70%)' }}
      />
      {/* Confetti dots */}
      {['12%/18%', '82%/14%', '20%/72%', '88%/64%', '50%/8%', '8%/45%', '92%/40%'].map((pos, i) => {
        const [left, top] = pos.split('/');
        return (
          <span
            key={pos}
            className={`absolute h-1.5 w-1.5 rounded-full bg-white transition-all duration-700 ${popped ? 'opacity-80' : 'opacity-0'}`}
            style={{ left, top, transitionDelay: `${i * 70}ms` }}
          />
        );
      })}

      <div className={`relative transition-all duration-500 ${popped ? 'scale-100 opacity-100' : 'scale-50 opacity-0'}`}>
        <span className="flex h-16 w-16 items-center justify-center rounded-full bg-white/25 text-[34px] shadow-[0_0_40px_rgba(255,255,255,0.45)]">🏆</span>
      </div>

      <p className={`mt-4 text-[10px] font-bold uppercase tracking-[0.3em] text-white/85 transition-opacity duration-500 ${detail ? 'opacity-100' : 'opacity-0'}`}>
        New personal record
      </p>
      <p className={`mt-1 text-[26px] font-extrabold leading-tight text-white drop-shadow-[0_2px_8px_rgba(0,0,0,0.25)] transition-all duration-500 ${detail ? 'translate-y-0 opacity-100' : 'translate-y-3 opacity-0'}`}>
        NEW 1RM!
      </p>
      <p className={`text-[14px] font-bold text-white transition-opacity duration-500 ${detail ? 'opacity-100' : 'opacity-0'}`}>
        Bench Press 225 lbs
      </p>
      <div className={`mt-1.5 flex items-center gap-1.5 transition-opacity duration-500 ${detail ? 'opacity-100' : 'opacity-0'}`}>
        <span className="rounded-full bg-white/25 px-2 py-0.5 text-[8px] font-bold text-white">+6%</span>
        <span className="text-[9px] text-white/85">↑ 5 lbs from 220</span>
      </div>

      <div className={`mt-5 flex w-full max-w-[200px] flex-col gap-1.5 transition-all duration-500 ${detail ? 'translate-y-0 opacity-100' : 'translate-y-3 opacity-0'}`}>
        <span className="rounded-[14px] bg-white py-2 text-[10px] font-bold" style={{ color: '#FF6B35' }}>↗ Share it</span>
        <span className="rounded-[14px] border border-white/50 py-2 text-[10px] font-semibold text-white">Keep lifting</span>
      </div>
    </div>
  );
}

/* ------------------------------ Photo nutrition ------------------------------ */

const FOOD_ITEMS = [
  { name: 'Roast Chicken Thigh', rating: 'GOOD', dot: '#22C55E', kcal: '290 cal', protein: '26g P', at: 0.5 },
  { name: 'Roasted Vegetables', rating: 'GOOD', dot: '#22C55E', kcal: '110 cal', protein: '4g P', at: 0.62 },
];

export function NutritionScene({ t, isStatic }: { t: number; isStatic: boolean }) {
  const p = isStatic ? 1 : clamp01(t / 5600);
  const scanning = !isStatic && p < 0.38;
  const analyzed = p >= 0.38;

  return (
    <div className="flex h-full flex-col bg-white px-3 pt-[5.2rem] pb-3 text-[10px]">
      <div className="absolute top-0 inset-x-0 z-[1] rounded-t-[2rem] bg-white px-3 pt-8 pb-2 border-b border-zinc-100">
        {/* Time + meal-type pills (log_meal_sheet_ui.dart header) */}
        <div className="flex items-center gap-1.5">
          <span className="rounded-[14px] bg-[#F8F8FA] px-2 py-1 text-[8px] font-medium text-zinc-700">🕐 6:50 PM ⌄</span>
          <span className="rounded-[14px] bg-[#F8F8FA] px-2 py-1 text-[8px] font-medium text-zinc-700">🌙 Dinner ⌄</span>
        </div>
        <div className="mt-1.5 flex items-center gap-1.5">
          <p className="text-[11px] font-bold text-zinc-900">✨ Estimated Nutrition</p>
          <span className={`rounded-md bg-emerald-50 border border-emerald-200 px-1.5 py-0.5 text-[8px] font-bold text-emerald-600 transition-opacity duration-300 ${analyzed ? 'opacity-100' : 'opacity-0'}`}>9/10</span>
          <span className={`text-[8px] text-zinc-400 transition-opacity duration-300 ${analyzed ? 'opacity-100' : 'opacity-0'}`}>(1.8s)</span>
        </div>
        <p className="text-[8px] italic text-zinc-400">"roast chicken and vegetables"</p>
      </div>

      {/* Photo being scanned — real meal photo, full frame (Wikimedia
          Commons, "Liat Portal - Grilled Chicken with Roasted Vegetables",
          CC BY-SA 4.0) */}
      <div className="relative aspect-[8/5] overflow-hidden rounded-[10px] border border-zinc-200">
        <img
          src="/screenshots/demo-food.webp"
          alt=""
          title="Photo: Liat Portal, Wikimedia Commons, CC BY-SA 4.0"
          className="h-full w-full object-cover"
          loading="lazy"
          decoding="async"
        />
        {scanning && (
          <div className="vl-scan-sweep absolute inset-x-0 top-0 h-5 bg-gradient-to-b from-transparent via-[rgba(249,115,22,0.45)] to-transparent" />
        )}
      </div>

      {/* Macro chips row — fire/protein/carbs/fat, app colors */}
      <div className={`mt-2 grid grid-cols-4 rounded-[12px] bg-[#F4F4F5] px-2 py-2 text-center transition-opacity duration-500 ${analyzed ? 'opacity-100' : 'opacity-30'}`}>
        {[
          { v: '400', label: 'kcal', icon: '🔥', color: '#F43F5E' },
          { v: '30g', label: 'Protein', icon: '💪', color: '#A855F7' },
          { v: '14g', label: 'Carbs', icon: '🌾', color: '#06B6D4' },
          { v: '22g', label: 'Fat', icon: '💧', color: '#F97316' },
        ].map((m) => (
          <div key={m.label}>
            <p className="text-[8px]">{m.icon}</p>
            <p className="vl-tabular text-[11px] font-bold" style={{ color: m.color }}>{analyzed ? m.v : '–'}</p>
            <p className="text-[7px] text-zinc-400">{m.label}</p>
          </div>
        ))}
      </div>

      {/* Food items — rating dot + label, name, cal, protein, delete */}
      <p className="mt-2 px-0.5 text-[7px] font-semibold uppercase tracking-[0.12em] text-zinc-400">2 Food Items</p>
      <div className="mt-1 space-y-1.5">
        {FOOD_ITEMS.filter((f) => p >= f.at).map((f) => {
          return (
            <div
              key={f.name}
              className="vl-pop-in flex items-center gap-1.5 rounded-[10px] border border-zinc-100 bg-white px-2 py-1.5 shadow-[0_1px_4px_rgba(0,0,0,0.04)]"
            >
              <span className="h-1.5 w-1.5 shrink-0 rounded-full" style={{ background: f.dot }} />
              <span className="text-[7px] font-semibold" style={{ color: f.dot }}>{f.rating}</span>
              <span className="truncate text-[9px] font-medium text-zinc-800">{f.name}</span>
              <span className="vl-tabular ml-auto shrink-0 text-[8px] text-zinc-500">{f.kcal}</span>
              <span className="vl-tabular shrink-0 text-[8px] font-medium text-emerald-600">{f.protein}</span>
              <span className="shrink-0 text-[8px] text-red-400">✕</span>
            </div>
          );
        })}
      </div>

      {/* Coach Mike's Tip — teal-tinted card, purple sparkle (log_meal_sheet_ui) */}
      {p >= 0.75 && (
        <div
          className="vl-pop-in mt-2 rounded-[12px] border px-2.5 py-1.5"
          style={{ background: 'rgba(20,184,166,0.08)', borderColor: 'rgba(20,184,166,0.2)' }}
        >
          <p className="text-[8px] font-bold text-zinc-800"><span className="text-purple-500">✨</span> Coach Mike's Tip</p>
          <p className="text-[8px] text-zinc-700">👍 Great protein hit. Skin adds fat, still inside your budget today</p>
        </div>
      )}

      {/* Vitamins accordion stub */}
      <div className="mt-1.5 flex items-center justify-between rounded-[10px] bg-[#F8F8FA] px-2.5 py-1.5">
        <span className="text-[8px] font-semibold uppercase tracking-wide text-zinc-500">🧪 Vitamins & Minerals</span>
        <span className="text-[8px] text-zinc-400">⌄</span>
      </div>

      <div
        className={`mt-auto rounded-[14px] py-2.5 text-center text-[10px] font-semibold text-white transition-opacity duration-300 ${p >= 0.85 ? 'opacity-100' : 'opacity-50'}`}
        style={{ background: ACCENT }}
      >
        ✓ Log This Meal
      </div>
    </div>
  );
}

/* ----------------------------- Menu scan -----------------------------
 * The real app opens a "Menu Analysis" sheet (menu_analysis_sheet.dart):
 * title + bookmark/history/close, counts line, sort pills, per-dish cards
 * with checkbox + macro chips (protein #9C27B0 / carbs #FF9800 / fat
 * #E91E63) + health badge (Recommended green / OK yellow / Avoid red),
 * "Coach Recommends" highlight, and a "Log N items" CTA. */

// Realistic menu "photo" shown while scanning (dotted price leaders, like
// a real trattoria menu page) and as a thumbnail in the results header.
const MENU_SECTIONS: Array<[string, Array<[string, string]>]> = [
  ['· MAINS ·', [
    ['Carbonara', '18'],
    ['Grilled chicken bowl', '16'],
    ['Bistecca alla griglia', '26'],
    ['Margherita', '15'],
    ['Risotto ai funghi', '17'],
  ]],
  ['· INSALATE ·', [
    ['Caesar salad', '14'],
    ['Caprese', '12'],
  ]],
  ['· DOLCI ·', [
    ['Tiramisu', '9'],
    ['Panna cotta', '8'],
  ]],
];

function MenuPhoto({ small }: { small?: boolean }) {
  return (
    <div className={`h-full overflow-hidden rounded-[10px] border border-zinc-200 bg-[#faf6ec] text-[#3a2f1d] ${small ? 'p-1' : 'flex flex-col justify-between p-3.5'}`}>
      <div>
        <p className={`text-center font-semibold tracking-[0.25em] text-[#9c8a64] ${small ? 'text-[3px]' : 'text-[9px]'}`}>TRATTORIA</p>
        <p className={`text-center tracking-[0.2em] text-[#bba87e] ${small ? 'text-[2.5px]' : 'text-[5.5px]'}`}>EST. 1987 · CUCINA ITALIANA</p>
      </div>
      {MENU_SECTIONS.map(([section, dishes]) => (
        <div key={section}>
          <p className={`text-center tracking-[0.2em] text-[#bba87e] ${small ? 'text-[2.5px]' : 'mb-1.5 text-[6.5px] font-semibold'}`}>{section}</p>
          <div className={small ? 'space-y-0.5' : 'space-y-1.5'}>
            {dishes.map(([name, price]) => (
              <div key={name} className="flex items-baseline gap-1">
                <span className={small ? 'text-[3px]' : 'text-[8.5px] font-medium'}>{name}</span>
                <span className={`flex-1 border-b border-dotted border-[#cbb88e] ${small ? '' : 'mb-0.5'}`} />
                <span className={small ? 'text-[3px]' : 'text-[8.5px]'}>{price}</span>
              </div>
            ))}
          </div>
        </div>
      ))}
      {!small && (
        <p className="text-center text-[5px] tracking-[0.15em] text-[#bba87e]">VINO DELLA CASA · 8 / GLASS</p>
      )}
    </div>
  );
}

// All 8 dishes from the scanned menu, with macros driving two sort orders.
const MENU_DISHES = [
  { name: 'Grilled chicken bowl', p: 52, c: 38, badge: 'Recommended', color: '#4CAF50', pick: true },
  { name: 'Bistecca alla griglia', p: 46, c: 2, badge: 'Recommended', color: '#4CAF50', pick: false },
  { name: 'Carbonara', p: 28, c: 96, badge: 'Avoid', color: '#F44336', pick: false },
  { name: 'Margherita', p: 24, c: 80, badge: 'OK', color: '#FFC107', pick: false },
  { name: 'Caesar salad', p: 18, c: 22, badge: 'OK', color: '#FFC107', pick: false },
  { name: 'Caprese', p: 14, c: 8, badge: 'OK', color: '#FFC107', pick: false },
  { name: 'Risotto ai funghi', p: 12, c: 74, badge: 'OK', color: '#FFC107', pick: false },
  { name: 'Panna cotta', p: 6, c: 32, badge: 'Avoid', color: '#F44336', pick: false },
];

const ROW_STEP = 51;

export function MenuScanScene({ t, isStatic }: { t: number; isStatic: boolean }) {
  const p = isStatic ? 1 : clamp01(t / 7000);
  const scanning = !isStatic && p < 0.24;
  // Live re-sort: protein-first, then the carbs pill takes over mid-scene
  const sortKey: 'p' | 'c' = !isStatic && t > 4200 ? 'c' : 'p';
  const picked = p >= 0.85;

  /* Phase 1 — the camera is pointed at a REAL menu, scan sweep running */
  if (scanning) {
    return (
      <div className="flex h-full flex-col bg-[#101012] px-3 pt-12 pb-3 text-[10px]">
        <div className="absolute top-0 inset-x-0 z-[1] rounded-t-[2rem] bg-[#101012] px-3 pt-8 pb-2">
          <p className="text-center text-[10px] font-medium text-zinc-300">📷 Scan Menu</p>
        </div>
        <div className="relative mt-2 flex-1">
          <div className="absolute -inset-1 rounded-[14px] border-2 border-white/20" />
          <div className="relative h-full overflow-hidden rounded-[12px]">
            <MenuPhoto />
            <div className="vl-scan-sweep absolute inset-x-0 top-0 h-8 bg-gradient-to-b from-transparent via-[rgba(255,107,53,0.5)] to-transparent" />
          </div>
        </div>
        <div className="mt-3 flex items-center justify-center gap-2 text-[10px] text-zinc-400">
          <span className="vl-typing-dot inline-block h-1.5 w-1.5 rounded-full" style={{ background: '#FF6B35' }} />
          Analyzing menu…
        </div>
      </div>
    );
  }

  /* Phase 2 — the Menu Analysis results sheet with live re-sorting */
  const order = [...MENU_DISHES].sort((a, b) => (sortKey === 'p' ? b.p - a.p : b.c - a.c));
  const indexOf = new Map(order.map((d, i) => [d.name, i]));

  return (
    <div className="flex h-full flex-col bg-white px-3 pt-[7.6rem] pb-3 text-[11px]">
      {/* Sheet header: title + icons + counts + sort pills */}
      <div className="absolute top-0 inset-x-0 z-20 rounded-t-[2rem] bg-white px-3 pt-8 pb-2 border-b border-zinc-100">
        <div className="flex items-center justify-between">
          <p className="text-[14px] font-extrabold text-zinc-900">Menu Analysis</p>
          <span className="flex items-center gap-2 text-[11px] text-zinc-400">🔖 ⏱ ✕</span>
        </div>
        <div className="mt-0.5 flex items-center gap-1.5">
          <span className="h-7 w-7 shrink-0 overflow-hidden rounded-[6px]"><MenuPhoto small /></span>
          <p className="text-[9px] text-zinc-400">8 items · 2 sections · 2.4s</p>
        </div>
        <div className="mt-1.5 flex items-center gap-1.5">
          <span className="text-[9px] text-zinc-400">Sort:</span>
          <span
            className="rounded-full px-2 py-0.5 text-[9.5px] font-semibold transition-all duration-300"
            style={sortKey === 'p'
              ? { background: 'rgba(255,107,53,0.15)', border: '1px solid rgba(255,107,53,0.55)', color: '#FF6B35' }
              : { background: 'rgba(0,0,0,0.05)', border: '1px solid transparent', color: '#71717a' }}
          >
            Protein {sortKey === 'p' ? '↓' : ''}
          </span>
          <span
            className="rounded-full px-2 py-0.5 text-[9.5px] font-semibold transition-all duration-300"
            style={sortKey === 'c'
              ? { background: 'rgba(255,107,53,0.15)', border: '1px solid rgba(255,107,53,0.55)', color: '#FF6B35' }
              : { background: 'rgba(0,0,0,0.05)', border: '1px solid transparent', color: '#71717a' }}
          >
            Carbs {sortKey === 'c' ? '↓' : ''}
          </span>
          <span className="rounded-full bg-black/5 px-2 py-0.5 text-[9.5px] text-zinc-500">Inflammation</span>
        </div>
      </div>

      {/* All 8 dishes — absolutely positioned rows so re-sorts ANIMATE */}
      <div className="relative" style={{ height: MENU_DISHES.length * ROW_STEP }}>
        {MENU_DISHES.map((d, i) => {
          const idx = indexOf.get(d.name) ?? 0;
          const on = isStatic || t > 1900 + i * 130;
          return (
            <div
              key={d.name}
              className={`absolute inset-x-0 flex items-center gap-2 rounded-[12px] border px-2.5 transition-all duration-500 ${
                on ? 'opacity-100' : 'opacity-0'
              } ${d.pick ? 'border-amber-300 bg-[#FFF8E9]' : 'border-zinc-100 bg-[#F6F6F8]'}`}
              style={{
                height: ROW_STEP - 6,
                transform: `translateY(${idx * ROW_STEP}px)`,
                zIndex: d.pick ? 9 : 8 - idx,
                transitionDelay: `${idx * 35}ms`,
              }}
            >
              <span
                className={`flex h-4 w-4 shrink-0 items-center justify-center rounded border text-[9px] transition-colors duration-300 ${
                  d.pick && picked ? 'border-transparent text-white' : 'border-zinc-300 bg-white text-transparent'
                }`}
                style={d.pick && picked ? { background: '#FF6B35' } : undefined}
              >
                ✓
              </span>
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-1.5">
                  <span className="truncate text-[11px] font-semibold text-zinc-900">{d.name}</span>
                  <span className="shrink-0 rounded px-1 py-0.5 text-[7.5px] font-bold text-white" style={{ background: d.color }}>{d.badge}</span>
                </div>
                <div className="mt-0.5 flex gap-1.5">
                  <span className="vl-tabular rounded px-1 text-[8.5px] font-semibold" style={{ color: '#9C27B0', background: '#9C27B01f' }}>{d.p}g P</span>
                  <span className="vl-tabular rounded px-1 text-[8.5px] font-semibold" style={{ color: '#FF9800', background: '#FF98001f' }}>{d.c}g C</span>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Bottom: selected totals + CTA */}
      <div className="mt-auto space-y-1.5">
        <div className={`flex items-center justify-between rounded-[10px] bg-[#F8F8FA] px-2.5 py-1.5 transition-opacity duration-300 ${picked ? 'opacity-100' : 'opacity-0'}`}>
          <span className="text-[9px] text-zinc-500">Selected</span>
          <span className="flex gap-1.5 text-[8.5px] font-semibold">
            <span style={{ color: '#9C27B0' }}>52g P</span>
            <span style={{ color: '#FF9800' }}>38g C</span>
            <span className="text-zinc-600">640 cal</span>
          </span>
        </div>
        <div
          className={`rounded-[14px] py-2.5 text-center text-[11px] font-semibold text-white transition-opacity duration-300 ${picked ? 'opacity-100' : 'opacity-40'}`}
          style={{ background: '#FF6B35' }}
        >
          Log 1 item
        </div>
      </div>
    </div>
  );
}

/* ------------------------ Coach changes a setting ------------------------ */

export function SettingsScene({ t, isStatic }: { t: number; isStatic: boolean }) {
  const p = isStatic ? 1 : clamp01(t / 4600);
  const flipped = isStatic || p >= 0.5; // light -> dark moment
  const askDone = isStatic || p >= 0.2;

  return (
    <div
      className={`flex h-full flex-col px-3 pt-[4.5rem] pb-3 text-[10px] transition-colors duration-700 ${
        flipped ? 'bg-[#000000]' : 'bg-white'
      }`}
    >
      <div className={`absolute top-0 inset-x-0 z-[1] rounded-t-[2rem] px-3 pt-8 pb-2 border-b transition-colors duration-700 ${
        flipped ? 'bg-[#000000] border-white/10' : 'bg-white border-zinc-100'
      }`}>
        <div className="flex items-center gap-2">
          <span className="flex h-6 w-6 items-center justify-center rounded-full text-[10px] font-bold text-white" style={{ background: ACCENT }}>Z</span>
          <div>
            <p className={`text-[11px] font-semibold leading-tight transition-colors duration-700 ${flipped ? 'text-zinc-50' : 'text-zinc-900'}`}>Coach Mike</p>
            <p className="text-[8px] uppercase tracking-[0.15em] text-zinc-400 leading-tight">App actions</p>
          </div>
        </div>
      </div>

      {/* User ask — cyan bubble, white text */}
      <div
        className={`ml-auto max-w-[80%] rounded-xl px-3 py-2 font-medium text-white transition-opacity duration-300 ${
          askDone ? 'opacity-100' : 'opacity-60'
        }`}
        style={{ background: USER_CYAN }}
      >
        Switch the app to dark mode
      </div>

      {/* Settings card that actually flips (#141414 elevated, like the app) */}
      <div
        className={`mt-3 rounded-[12px] border p-3 transition-colors duration-700 ${
          flipped ? 'border-white/10 bg-[#141414]' : 'border-zinc-200 bg-[#F4F4F5]'
        }`}
      >
        <p className="text-[8px] uppercase tracking-[0.15em] text-zinc-400">
          Settings · Appearance
        </p>
        <div className="mt-2 flex items-center justify-between">
          <span className={`text-[10px] font-medium transition-colors duration-700 ${flipped ? 'text-zinc-50' : 'text-zinc-800'}`}>
            🌙 Dark mode
          </span>
          <span
            className="relative inline-flex items-center rounded-full transition-colors duration-500"
            style={{ height: 18, width: 32, background: flipped ? ACCENT : '#D4D4D8' }}
          >
            <span
              className="absolute h-3.5 w-3.5 rounded-full bg-white shadow transition-transform duration-500"
              style={{ transform: flipped ? 'translateX(16px)' : 'translateX(2px)' }}
            />
          </span>
        </div>
      </div>

      {/* Coach confirmation */}
      <div
        className={`mt-3 max-w-[88%] rounded-xl px-3 py-2 transition-all duration-500 ${
          p >= 0.62 ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-2'
        } ${flipped ? 'bg-[#1A1A1A] text-zinc-100' : 'text-zinc-50'}`}
        style={!flipped ? { background: COACH_BG } : undefined}
      >
        <p className="mb-0.5 text-[8px] font-semibold" style={{ color: ACCENT }}>🧡 Coach Mike</p>
        Done, dark mode is on. I can also flip units, rest timers, and reminders. Just ask.
      </div>

      <div className={`mt-auto flex items-center gap-1.5 transition-colors duration-700`}>
        <span className="text-[12px] text-zinc-400">📷</span>
        <span className="text-[12px] text-zinc-400">📎</span>
        <span className={`flex flex-1 items-center rounded-[14px] px-3 py-2 transition-colors duration-700 ${flipped ? 'bg-[#141414] text-zinc-500' : 'bg-[#F4F4F5] text-zinc-400'}`}>
          Ask Coach Mike…
        </span>
        <span className="flex h-6 w-6 items-center justify-center rounded-full text-[10px] font-bold text-white" style={{ background: ACCENT }}>↑</span>
      </div>
    </div>
  );
}

/* -------------------------- Progress photo comparison --------------------------
 * Shows the REAL progress-photo customize screen (the founder's actual
 * before/after) via the optimized store screenshot. */

export function PhotoComparisonScene({ t, isStatic }: { t: number; isStatic: boolean }) {
  const p = isStatic ? 1 : clamp01(t / 5200);
  const settled = p >= 0.15;

  return (
    <div className="relative h-full overflow-hidden bg-white">
      <picture>
        <source
          type="image/avif"
          srcSet="/screenshots/opt/intro_phone_5-480.avif 480w, /screenshots/opt/intro_phone_5-768.avif 768w"
          sizes="300px"
        />
        <source
          type="image/webp"
          srcSet="/screenshots/opt/intro_phone_5-480.webp 480w, /screenshots/opt/intro_phone_5-768.webp 768w"
          sizes="300px"
        />
        <img
          src="/screenshots/intro_phone_5.png"
          alt=""
          className={`h-full w-full object-cover object-top transition-opacity duration-700 ${settled ? 'opacity-100' : 'opacity-0'}`}
          loading="lazy"
          decoding="async"
        />
      </picture>
    </div>
  );
}
