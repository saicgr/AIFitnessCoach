import { useCallback, useEffect, useRef, useState } from 'react';
import type { FormEvent, ReactNode } from 'react';
import { submitWaitlist } from '../../lib/waitlist';
import { BRANDING } from '../../lib/branding';

/**
 * Full-bleed waitlist hero — spinning volt-gradient backdrop, pill email
 * field with an inline submit, and a 3D flip into a confetti success state.
 *
 * Posts through `submitWaitlist` (the real POST /api/v1/waitlist/ path) —
 * there is no simulated delay or fake success anywhere in here.
 *
 * SSG note: /waitlist is Puppeteer-prerendered, so the headline, subhead and
 * form render in the initial HTML with no hidden entrance state. Only the
 * success panel starts hidden, which is correct for a crawler snapshot.
 */

type Status = 'idle' | 'loading' | 'success' | 'error';

interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  life: number;
  color: string;
  size: number;
}

const CONFETTI_COLORS = ['#FF7A00', '#FF9A3C', '#FFB266', '#10B981', '#FFFFFF'];

// Brand tokens, resolved here so the component stays self-contained.
const C = {
  textMain: '#FFFFFF',
  textSecondary: 'rgba(255,255,255,0.55)',
  accent: '#FF7A00', // volt-500 — THE brand orange
  success: '#10B981', // emerald-500
  inputBg: '#161616', // ink-800
  baseBg: '#050505', // ink-950
  inputShadow: 'rgba(255,255,255,0.10)',
} as const;

function prefersReducedMotion(): boolean {
  return (
    typeof window !== 'undefined' &&
    typeof window.matchMedia === 'function' &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches
  );
}

export interface WaitlistHeroProps {
  /** Page-default attribution source; ?utm_source= / referrer can override it. */
  source: string;
  platformInterest?: 'ios' | 'android' | 'both';
  eyebrow?: string;
  headline?: ReactNode;
  subhead?: string;
  buttonLabel?: string;
  successMessage?: string;
  /** Small footnote under the field. */
  footnote?: string;
  className?: string;
}

export function WaitlistHero({
  source,
  platformInterest = 'both',
  eyebrow = 'Launching soon',
  headline = (
    <>
      Be first when <span style={{ color: C.accent }}>iOS drops.</span>
    </>
  ),
  subhead = 'Android goes out the moment Google approves. iOS lands right after — the waitlist gets it first.',
  buttonLabel = 'Join waitlist',
  successMessage = "You're on the list!",
  footnote = 'One email at launch. Unsubscribe anytime.',
  className = '',
}: WaitlistHeroProps) {
  const [email, setEmail] = useState('');
  // Honeypot — bots fill every input; humans never see this one.
  const [website, setWebsite] = useState('');
  const [status, setStatus] = useState<Status>('idle');
  const [errorMsg, setErrorMsg] = useState('');

  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const rafRef = useRef<number | null>(null);

  // Kill any in-flight confetti loop when the hero unmounts.
  useEffect(() => {
    return () => {
      if (rafRef.current !== null) cancelAnimationFrame(rafRef.current);
    };
  }, []);

  const fireConfetti = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas || prefersReducedMotion()) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Match the backing store to the laid-out box (DPR-aware so it isn't blurry).
    const dpr = typeof window !== 'undefined' ? window.devicePixelRatio || 1 : 1;
    const cssW = canvas.offsetWidth;
    const cssH = canvas.offsetHeight;
    canvas.width = Math.round(cssW * dpr);
    canvas.height = Math.round(cssH * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

    const particles: Particle[] = Array.from({ length: 60 }, () => ({
      x: cssW / 2,
      y: cssH / 2,
      vx: (Math.random() - 0.5) * 12,
      vy: (Math.random() - 2) * 10,
      life: 100,
      color: CONFETTI_COLORS[Math.floor(Math.random() * CONFETTI_COLORS.length)],
      size: Math.random() * 4 + 2,
    }));

    const animate = () => {
      ctx.clearRect(0, 0, cssW, cssH);

      for (let i = particles.length - 1; i >= 0; i--) {
        const p = particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.5; // gravity
        p.life -= 2;

        if (p.life <= 0) {
          particles.splice(i, 1);
          continue;
        }

        ctx.globalAlpha = Math.max(0, p.life / 100);
        ctx.fillStyle = p.color;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.globalAlpha = 1;

      if (particles.length === 0) {
        ctx.clearRect(0, 0, cssW, cssH);
        rafRef.current = null;
        return;
      }
      rafRef.current = requestAnimationFrame(animate);
    };

    if (rafRef.current !== null) cancelAnimationFrame(rafRef.current);
    rafRef.current = requestAnimationFrame(animate);
  }, []);

  const onSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (status === 'loading') return;

    setStatus('loading');
    setErrorMsg('');

    const result = await submitWaitlist({ email, source, platformInterest, website });

    if (result.ok) {
      setStatus('success');
      setEmail('');
      fireConfetti();
      return;
    }
    setStatus('error');
    setErrorMsg(result.message);
  };

  return (
    <section
      className={`relative w-full min-h-[100svh] overflow-hidden ${className}`}
      style={{ backgroundColor: C.baseBg }}
      aria-labelledby="waitlist-hero-heading"
    >
      <style>{`
        @keyframes wh-spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
        @keyframes wh-spin-reverse { from { transform: rotate(0deg); } to { transform: rotate(-360deg); } }
        .wh-spin { animation: wh-spin 60s linear infinite; }
        .wh-spin-reverse { animation: wh-spin-reverse 60s linear infinite; }
        .wh-spin-fast { animation: wh-spin 38s linear infinite; }

        @keyframes wh-bounce-in {
          0% { transform: scale(0.8); opacity: 0; }
          50% { transform: scale(1.05); opacity: 1; }
          100% { transform: scale(1); opacity: 1; }
        }
        .wh-bounce-in { animation: wh-bounce-in 0.5s cubic-bezier(0.175,0.885,0.32,1.275) forwards; }

        @keyframes wh-success-glow {
          0%, 100% { box-shadow: 0 0 20px rgba(16,185,129,0.40); }
          50% { box-shadow: 0 0 60px rgba(16,185,129,0.80), 0 0 100px rgba(16,185,129,0.40); }
        }
        .wh-success-glow { animation: wh-success-glow 2s ease-in-out infinite; }

        @keyframes wh-checkmark { 0% { stroke-dashoffset: 24; } 100% { stroke-dashoffset: 0; } }
        .wh-checkmark { stroke-dasharray: 24; stroke-dashoffset: 24; animation: wh-checkmark 0.4s ease-out 0.3s forwards; }

        @keyframes wh-ring {
          0% { transform: translate(-50%,-50%) scale(0.8); opacity: 1; }
          100% { transform: translate(-50%,-50%) scale(2); opacity: 0; }
        }
        .wh-ring { animation: wh-ring 0.8s ease-out forwards; }

        @media (prefers-reduced-motion: reduce) {
          .wh-spin, .wh-spin-reverse, .wh-spin-fast, .wh-bounce-in,
          .wh-success-glow, .wh-checkmark, .wh-ring { animation: none !important; }
          .wh-checkmark { stroke-dashoffset: 0; }
        }
      `}</style>

      {/* ── Decorative backdrop: tilted, counter-rotating volt gradient rings.
          Pure CSS — no third-party image hotlinks, nothing to 404 or block the
          prerender crawl. */}
      {/* Insets are negative on purpose: a rotateX'd plane renders as a
          trapezoid, and at inset-0 its own edges show as hard diagonals. */}
      <div
        aria-hidden
        className="absolute pointer-events-none"
        style={{
          top: '-35%',
          bottom: '-15%',
          left: '-30%',
          right: '-30%',
          perspective: '1200px',
          transform: 'perspective(1200px) rotateX(15deg)',
          transformOrigin: 'center bottom',
        }}
      >
        {/* Back ring — widest, slowest, clockwise */}
        <div className="absolute inset-0 wh-spin">
          <div
            className="absolute top-1/2 left-1/2 rounded-full"
            style={{
              width: 'min(2000px, 190vw)',
              height: 'min(2000px, 190vw)',
              transform: 'translate(-50%, -50%)',
              background:
                'conic-gradient(from 0deg, rgba(255,122,0,0.00) 0deg, rgba(255,122,0,0.16) 70deg, rgba(255,178,102,0.05) 150deg, rgba(255,122,0,0.00) 230deg, rgba(16,185,129,0.09) 300deg, rgba(255,122,0,0.00) 360deg)',
              filter: 'blur(70px)',
            }}
          />
        </div>

        {/* Middle ring — counter-clockwise */}
        <div className="absolute inset-0 wh-spin-reverse">
          <div
            className="absolute top-1/2 left-1/2 rounded-full"
            style={{
              width: 'min(1100px, 115vw)',
              height: 'min(1100px, 115vw)',
              transform: 'translate(-50%, -50%)',
              background:
                'conic-gradient(from 120deg, rgba(255,122,0,0.00) 0deg, rgba(255,122,0,0.42) 90deg, rgba(255,154,60,0.16) 190deg, rgba(255,122,0,0.00) 300deg)',
              filter: 'blur(56px)',
            }}
          />
        </div>

        {/* Front core — tight hot glow behind the app icon */}
        <div className="absolute inset-0 wh-spin-fast">
          <div
            className="absolute top-1/2 left-1/2 rounded-full"
            style={{
              width: 'min(640px, 78vw)',
              height: 'min(640px, 78vw)',
              transform: 'translate(-50%, -50%)',
              background:
                'radial-gradient(circle at 50% 50%, rgba(255,178,102,0.42) 0%, rgba(255,122,0,0.24) 42%, rgba(255,122,0,0) 72%)',
              filter: 'blur(28px)',
            }}
          />
        </div>

        {/* Hairline orbit rings — give the glow some structure */}
        <div className="absolute inset-0 wh-spin-reverse">
          <div
            className="absolute top-1/2 left-1/2 rounded-full border"
            style={{
              width: 'min(880px, 96vw)',
              height: 'min(880px, 96vw)',
              transform: 'translate(-50%, -50%)',
              borderColor: 'rgba(255,122,0,0.14)',
            }}
          />
          <div
            className="absolute top-1/2 left-1/2 rounded-full border"
            style={{
              width: 'min(560px, 64vw)',
              height: 'min(560px, 64vw)',
              transform: 'translate(-50%, -50%)',
              borderColor: 'rgba(255,255,255,0.06)',
            }}
          />
        </div>
      </div>

      {/* Bottom-weighted scrim so the copy always sits on near-black */}
      <div
        aria-hidden
        className="absolute inset-0 z-10 pointer-events-none"
        style={{
          background: `linear-gradient(to top, ${C.baseBg} 10%, rgba(5,5,5,0.82) 42%, transparent 100%)`,
        }}
      />

      {/* ── Content */}
      <div className="relative z-20 w-full min-h-[100svh] flex flex-col items-center justify-end gap-6 px-6 pt-28 pb-20 sm:pb-24">
        <div className="w-16 h-16 rounded-2xl shadow-lg overflow-hidden mb-2 ring-1 ring-white/10 bg-[#0D0D0D]">
          <img
            src="/zealova-logo.png"
            alt={`${BRANDING.appName} app icon`}
            width={64}
            height={64}
            className="w-full h-full object-contain"
          />
        </div>

        <span className="condensed-kicker inline-flex items-center gap-2 rounded-full border border-volt-500/30 bg-volt-500/5 px-4 py-2 text-xs text-volt-400 uppercase tracking-wider">
          <span className="relative inline-flex w-2 h-2 rounded-full bg-volt-400" />
          {eyebrow}
        </span>

        <h1
          id="waitlist-hero-heading"
          className="display-heading text-center text-4xl sm:text-6xl md:text-7xl tracking-tight max-w-[16ch]"
          style={{ color: C.textMain }}
        >
          {headline}
        </h1>

        <p
          className="text-center text-base sm:text-lg font-medium max-w-[54ch] leading-relaxed"
          style={{ color: C.textSecondary }}
        >
          {subhead}
        </p>

        {/* Form ↔ success, flipped on the X axis */}
        <div className="w-full max-w-md mt-4 h-[60px] relative" style={{ perspective: '1000px' }}>
          {/* Confetti — overlays everything, ignores clicks */}
          <canvas
            ref={canvasRef}
            aria-hidden
            className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] max-w-[100vw] pointer-events-none z-50"
          />

          {/* SUCCESS STATE */}
          <div
            className={`absolute inset-0 flex items-center justify-center rounded-full transition-all duration-500 ease-[cubic-bezier(0.23,1,0.32,1)] ${
              status === 'success'
                ? 'opacity-100 scale-100 wh-success-glow'
                : 'opacity-0 scale-95 pointer-events-none'
            }`}
            style={{
              backgroundColor: C.success,
              transform: status === 'success' ? 'rotateX(0deg)' : 'rotateX(-90deg)',
            }}
            aria-hidden={status !== 'success'}
          >
            {status === 'success' && (
              <>
                <span
                  aria-hidden
                  className="absolute top-1/2 left-1/2 w-full h-full rounded-full border-2 border-emerald-400 wh-ring"
                />
                <span
                  aria-hidden
                  className="absolute top-1/2 left-1/2 w-full h-full rounded-full border-2 border-emerald-300 wh-ring"
                  style={{ animationDelay: '0.15s' }}
                />
                <span
                  aria-hidden
                  className="absolute top-1/2 left-1/2 w-full h-full rounded-full border-2 border-emerald-200 wh-ring"
                  style={{ animationDelay: '0.3s' }}
                />
              </>
            )}
            <div
              className={`flex items-center gap-2 text-black font-semibold text-lg ${
                status === 'success' ? 'wh-bounce-in' : ''
              }`}
            >
              <span className="bg-black/15 p-1 rounded-full">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    className={status === 'success' ? 'wh-checkmark' : ''}
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={3}
                    d="M5 13l4 4L19 7"
                  />
                </svg>
              </span>
              <span>{successMessage}</span>
            </div>
          </div>

          {/* FORM STATE */}
          <form
            onSubmit={onSubmit}
            noValidate
            className={`relative w-full h-full transition-all duration-500 ease-[cubic-bezier(0.23,1,0.32,1)] ${
              status === 'success'
                ? 'opacity-0 scale-95 pointer-events-none'
                : 'opacity-100 scale-100'
            }`}
            style={{ transform: status === 'success' ? 'rotateX(90deg)' : 'rotateX(0deg)' }}
          >
            {/* Honeypot — visually hidden but still rendered. */}
            <label className="sr-only" aria-hidden="true">
              Don't fill this out if you're human
              <input
                type="text"
                tabIndex={-1}
                autoComplete="off"
                value={website}
                onChange={(e) => setWebsite(e.target.value)}
              />
            </label>

            <input
              type="email"
              inputMode="email"
              autoComplete="email"
              required
              placeholder="you@email.com"
              aria-label="Email address"
              aria-invalid={status === 'error'}
              value={email}
              disabled={status === 'loading'}
              onChange={(e) => {
                setEmail(e.target.value);
                if (status === 'error') setStatus('idle');
              }}
              className="w-full h-[60px] pl-6 pr-[140px] sm:pr-[150px] rounded-full outline-none transition-all duration-200 placeholder-zinc-500 focus:ring-2 focus:ring-volt-500/40 disabled:opacity-70 disabled:cursor-not-allowed"
              style={{
                backgroundColor: C.inputBg,
                color: C.textMain,
                boxShadow: `inset 0 0 0 1px ${C.inputShadow}`,
              }}
            />

            <div className="absolute top-[6px] right-[6px] bottom-[6px]">
              <button
                type="submit"
                disabled={status === 'loading'}
                className="h-full px-5 sm:px-6 rounded-full font-semibold text-black transition-all active:scale-95 hover:brightness-110 disabled:hover:brightness-100 disabled:active:scale-100 disabled:cursor-wait flex items-center justify-center min-w-[120px] sm:min-w-[130px]"
                style={{ backgroundColor: C.accent }}
              >
                {status === 'loading' ? (
                  <>
                    <svg
                      className="animate-spin h-5 w-5 text-black"
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      aria-hidden
                    >
                      <circle
                        className="opacity-25"
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="currentColor"
                        strokeWidth="4"
                      />
                      <path
                        className="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                      />
                    </svg>
                    <span className="sr-only">Joining…</span>
                  </>
                ) : (
                  buttonLabel
                )}
              </button>
            </div>
          </form>
        </div>

        {/* Live region: errors + success both announced */}
        <p
          role="status"
          aria-live="polite"
          className={`text-sm text-center min-h-[1.25rem] ${
            status === 'error' ? 'text-rose-400' : 'text-emerald-400'
          }`}
        >
          {status === 'error' ? errorMsg : ''}
          {status === 'success'
            ? "You're in. Check your inbox — we sent you what's next."
            : ''}
        </p>

        <p className="text-xs text-center" style={{ color: 'rgba(255,255,255,0.40)' }}>
          {footnote}
        </p>
      </div>
    </section>
  );
}

export default WaitlistHero;
