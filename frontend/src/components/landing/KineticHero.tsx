import { lazy, Suspense, useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import gsap from 'gsap';
import { isPrerender, prefersReducedMotion, canWebGL, motionAllowed } from '../../lib/runtimeEnv';
import { FREE_TOOL_COUNT } from '../../lib/toolStats';
import { useOnScreen } from './useOnScreen';
import PhoneDemo from './phone-demo/PhoneDemo';

// The WebGL backdrop is a separate lazy chunk (three.js lives only there).
// It never loads during prerender / reduced motion / missing WebGL — the
// static .vl-hero-base gradient below is the fallback everyone else sees.
const VoltBackdrop = lazy(() => import('./VoltBackdrop'));

// Rolling headline word — calm vertical roll (one moving element in the
// type block). Static on the first word for prerender / reduced motion;
// paused offscreen. All words are real DOM text (crawlable).
const ROLL_WORDS = ['REP.', 'MEAL.', 'SET.', 'PR.', 'DAY.'];

function RollingWord() {
  const { ref, onScreen } = useOnScreen<HTMLSpanElement>('0px');
  const [motionOk, setMotionOk] = useState(false);
  const [idx, setIdx] = useState(0);

  useEffect(() => {
    setMotionOk(motionAllowed());
  }, []);

  useEffect(() => {
    if (!motionOk || !onScreen) return;
    const id = window.setInterval(() => setIdx((i) => (i + 1) % ROLL_WORDS.length), 2400);
    return () => window.clearInterval(id);
  }, [motionOk, onScreen]);

  return (
    <span ref={ref} className="vl-roller">
      {/* Invisible widest word reserves the box so nothing below jumps */}
      <span className="invisible">MEAL.</span>
      <span
        className="vl-roller-track"
        style={{ transform: `translateY(${-idx * 100}%)` }}
      >
        {ROLL_WORDS.map((w) => (
          <span key={w} className="vl-roller-word">{w}</span>
        ))}
      </span>
    </span>
  );
}

export default function KineticHero() {
  const rootRef = useRef<HTMLDivElement>(null);
  const [showBackdrop, setShowBackdrop] = useState(false);

  // Mount the WebGL backdrop lazily, after idle, only when allowed.
  useEffect(() => {
    if (isPrerender() || prefersReducedMotion() || !canWebGL()) return;
    const w = window as Window & {
      requestIdleCallback?: (cb: () => void, opts?: { timeout: number }) => number;
      cancelIdleCallback?: (handle: number) => void;
    };
    const useIdle = typeof w.requestIdleCallback === 'function';
    const handle = useIdle
      ? w.requestIdleCallback!(() => setShowBackdrop(true), { timeout: 2500 })
      : window.setTimeout(() => setShowBackdrop(true), 600);
    return () => {
      if (useIdle) w.cancelIdleCallback?.(handle);
      else window.clearTimeout(handle);
    };
  }, []);

  // Intro reveal — initial CSS state is fully visible (prerender-safe);
  // GSAP sets the hidden state and animates in only when motion is allowed.
  useEffect(() => {
    if (isPrerender() || prefersReducedMotion() || !rootRef.current) return;
    const ctx = gsap.context(() => {
      const tl = gsap.timeline({ defaults: { ease: 'expo.out' } });
      tl.from('.vl-line > span', {
        yPercent: 110,
        duration: 1.0,
        stagger: 0.09,
      })
        .from('.vl-hero-sub', { autoAlpha: 0, y: 18, duration: 0.7 }, '-=0.55')
        .from('.vl-hero-ctas', { autoAlpha: 0, y: 18, duration: 0.7 }, '-=0.5')
        .from('.vl-hero-phone', { autoAlpha: 0, y: 32, duration: 0.9 }, '-=0.6')
        .from('.vl-hero-meta', { autoAlpha: 0, duration: 0.6 }, '-=0.4');
    }, rootRef);
    return () => ctx.revert();
  }, []);

  return (
    <header
      ref={rootRef}
      className="vl-hero-base vl-grain relative isolate flex min-h-[100svh] flex-col justify-center overflow-hidden"
    >
      {/* WebGL volt flow field (lazy, gated) */}
      {showBackdrop && (
        <Suspense fallback={null}>
          <VoltBackdrop />
        </Suspense>
      )}

      <div className="relative z-[3] mx-auto grid w-full max-w-[1200px] items-center gap-12 px-6 pb-16 pt-28 sm:pt-32 lg:grid-cols-[minmax(0,1fr)_auto] lg:gap-8">
        {/* Type block */}
        <div>
          <p className="vl-hero-meta condensed-kicker mb-5 text-xs text-volt-400">
            AI workout + meal coach · Android live · iOS soon
          </p>

          <h1
            className="display-heading text-white"
            style={{ fontSize: 'clamp(3.4rem, 10.5vw, 9rem)' }}
          >
            {/* Stable string for crawlers + screen readers; the animated
                visual (rolling word) is aria-hidden. */}
            <span className="sr-only">Your AI coach. Every rep. Every meal.</span>
            <span aria-hidden="true">
              <span className="vl-line"><span>Your AI coach.</span></span>
              <span className="vl-line">
                <span className="text-volt-500">Every <RollingWord /></span>
              </span>
            </span>
          </h1>

          <p className="vl-hero-sub mt-6 max-w-xl text-base leading-relaxed text-zinc-300 sm:text-lg">
            Zealova builds your training plan, coaches you mid-set, logs meals
            from a photo or a restaurant menu scan, and adapts every week to
            how you actually train. 1,722 exercises. Real progression. No
            generic plans.
          </p>

          {/* Android is live: store install is the primary path. The
              waitlist is explicitly iOS-framed so ready-to-install Android
              visitors never bounce off a "waitlist" button. */}
          <div className="vl-hero-ctas mt-8 flex flex-wrap items-center gap-4">
            <a
              href="https://play.google.com/store/apps/details?id=com.aifitnesscoach.app&referrer=utm_source%3Dsite%26utm_medium%3Dhero"
              target="_blank"
              rel="noopener noreferrer"
              className="btn-volt rounded-full px-7 py-3.5 text-sm"
            >
              Get it on Google Play
            </a>
            <Link
              to="/free-tools"
              className="rounded-full border border-white/15 px-7 py-3.5 text-sm font-medium text-white transition-colors hover:border-volt-500/50 hover:text-volt-300"
            >
              Try {FREE_TOOL_COUNT} free tools
            </Link>
          </div>

          <p className="vl-hero-meta mt-6 text-xs text-zinc-500">
            7-day free trial · No credit card to start · iPhone?{' '}
            <Link to="/waitlist" className="text-volt-400 hover:text-volt-300 transition-colors">
              Join the iOS waitlist
            </Link>
          </p>
        </div>

        {/* Live phone demo */}
        <div className="vl-hero-phone">
          <PhoneDemo />
        </div>
      </div>

      {/* Scroll hint */}
      <div
        aria-hidden="true"
        className="vl-hero-meta absolute bottom-6 left-1/2 z-[3] -translate-x-1/2 text-zinc-600"
      >
        <svg className="h-5 w-5 animate-bounce" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" />
        </svg>
      </div>
    </header>
  );
}
