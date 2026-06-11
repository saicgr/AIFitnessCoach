import { lazy, Suspense, useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { isPrerender, prefersReducedMotion, canWebGL, motionAllowed } from '../../lib/runtimeEnv';
import { FREE_TOOL_COUNT } from '../../lib/toolStats';
import { useOnScreen } from './useOnScreen';
import { useMagnetic } from './useMagnetic';
import PhoneDemo from './phone-demo/PhoneDemo';

// Cursor-reactive 3D tilt for the phone demo: perspective container,
// rAF-lerped rotateX/rotateY (transform-only — unlike the old hero this
// never queues tweens; one lerp per frame, listeners cleaned up).
function useTilt<T extends HTMLElement>(maxDeg = 7) {
  const ref = useRef<T | null>(null);
  useEffect(() => {
    const el = ref.current;
    if (!el || !motionAllowed() || window.matchMedia('(hover: none)').matches) return;
    let raf = 0;
    let tx = 0, ty = 0, cx = 0, cy = 0;
    const tick = () => {
      cx += (tx - cx) * 0.08;
      cy += (ty - cy) * 0.08;
      el.style.transform = `perspective(1100px) rotateY(${cx.toFixed(2)}deg) rotateX(${cy.toFixed(2)}deg)`;
      raf = Math.abs(tx - cx) + Math.abs(ty - cy) > 0.02 ? requestAnimationFrame(tick) : 0;
    };
    const onMove = (e: PointerEvent) => {
      tx = ((e.clientX / window.innerWidth) - 0.5) * 2 * maxDeg;
      ty = -((e.clientY / window.innerHeight) - 0.5) * 2 * (maxDeg * 0.7);
      if (!raf) raf = requestAnimationFrame(tick);
    };
    window.addEventListener('pointermove', onMove, { passive: true });
    return () => {
      window.removeEventListener('pointermove', onMove);
      cancelAnimationFrame(raf);
      el.style.transform = '';
    };
  }, [maxDeg]);
  return ref;
}

// Chrome sheen that follows the cursor across the Anton headline
// (background-clip:text + radial highlight at --mx/--my). Updates are
// rAF-throttled and only run while the hero is on screen.
function useHeadlineSheen<T extends HTMLElement>(active: boolean) {
  const ref = useRef<T | null>(null);
  useEffect(() => {
    const el = ref.current;
    if (!el || !active || !motionAllowed() || window.matchMedia('(hover: none)').matches) return;
    el.classList.add('vl-sheen');
    let raf = 0;
    const onMove = (e: PointerEvent) => {
      if (raf) return;
      raf = requestAnimationFrame(() => {
        const r = el.getBoundingClientRect();
        el.style.setProperty('--mx', `${(((e.clientX - r.left) / r.width) * 100).toFixed(1)}%`);
        el.style.setProperty('--my', `${(((e.clientY - r.top) / r.height) * 100).toFixed(1)}%`);
        raf = 0;
      });
    };
    window.addEventListener('pointermove', onMove, { passive: true });
    return () => {
      window.removeEventListener('pointermove', onMove);
      cancelAnimationFrame(raf);
      el.classList.remove('vl-sheen');
    };
  }, [active]);
  return ref;
}

// The WebGL backdrop is a separate lazy chunk (three.js lives only there).
// It never loads during prerender / reduced motion / missing WebGL — the
// static .vl-hero-base gradient below is the fallback everyone else sees.
const VoltBackdrop = lazy(() => import('./VoltBackdrop'));

// Rolling headline word — calm vertical roll (one moving element in the
// type block). Static on the first word for prerender / reduced motion;
// paused offscreen. All words are real DOM text (crawlable).
const ROLL_WORDS = ['REP.', 'MEAL.', 'SET.', 'PR.', 'MENU.', 'DAY.'];

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
      <span className="invisible">MENU.</span>
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
  const rootRef = useRef<HTMLElement | null>(null);
  const [showBackdrop, setShowBackdrop] = useState(false);
  const { ref: heroOnScreenRef, onScreen: heroOnScreen } = useOnScreen<HTMLElement>('0px');
  const playCtaRef = useMagnetic<HTMLAnchorElement>(8);
  const toolsCtaRef = useMagnetic<HTMLAnchorElement>(8);
  const phoneTiltRef = useTilt<HTMLDivElement>(6);
  const sheenRef = useHeadlineSheen<HTMLSpanElement>(heroOnScreen);

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
  // The product gets keynote choreography: it rises in with a slight 3D
  // turn, then scroll scrubs a slow rotation as the hero exits.
  useEffect(() => {
    if (isPrerender() || prefersReducedMotion() || !rootRef.current) return;
    gsap.registerPlugin(ScrollTrigger);
    const ctx = gsap.context(() => {
      const tl = gsap.timeline({ defaults: { ease: 'expo.out' } });
      tl.from('.vl-line > span', {
        yPercent: 110,
        duration: 1.0,
        stagger: 0.09,
      })
        .from('.vl-hero-sub', { autoAlpha: 0, y: 18, duration: 0.7 }, '-=0.55')
        .from('.vl-hero-ctas', { autoAlpha: 0, y: 18, duration: 0.7 }, '-=0.5')
        .from(
          '.vl-product',
          { autoAlpha: 0, y: 70, rotateY: -22, scale: 0.94, duration: 1.3, ease: 'power3.out' },
          '-=0.7'
        )
        .from('.vl-hero-meta', { autoAlpha: 0, duration: 0.6 }, '-=0.6');

      gsap.fromTo(
        '.vl-product',
        { rotateY: -9, rotateX: 2 },
        {
          rotateY: 9,
          rotateX: -3,
          y: -36,
          ease: 'none',
          immediateRender: false,
          scrollTrigger: {
            trigger: rootRef.current,
            start: 'top top',
            end: 'bottom top',
            scrub: 0.6,
          },
        }
      );
    }, rootRef);
    return () => ctx.revert();
  }, []);

  return (
    <header
      ref={(el) => {
        rootRef.current = el;
        heroOnScreenRef.current = el;
      }}
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
            style={{ fontSize: 'clamp(3.1rem, 8.2vw, 7.4rem)' }}
          >
            {/* Stable string for crawlers + screen readers; the animated
                visual (rolling word) is aria-hidden. */}
            <span className="sr-only">Your AI coach. Every rep. Every meal.</span>
            {/* Sheen attaches to the line's own text span — background-clip:
                text does not reach into children that have their own
                compositing layer, so the wrapper is the wrong target. */}
            <span aria-hidden="true">
              <span className="vl-line"><span ref={sheenRef}>Your AI coach.</span></span>
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
            {/* Official Google Play badge (brand-guideline compliant) */}
            <a
              ref={playCtaRef}
              href="https://play.google.com/store/apps/details?id=com.aifitnesscoach.app&referrer=utm_source%3Dsite%26utm_medium%3Dhero"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-block transition-[filter] hover:brightness-125"
              aria-label="Get it on Google Play"
            >
              <img
                src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg"
                alt="Get it on Google Play"
                className="h-[52px] w-auto"
                width={646}
                height={250}
                decoding="async"
              />
            </a>
            <Link
              ref={toolsCtaRef}
              to="/free-tools"
              className="inline-block rounded-full border border-white/15 px-7 py-3.5 text-sm font-medium text-white transition-colors hover:border-volt-500/50 hover:text-volt-300"
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

        {/* The product, staged: spotlight above, light pooling on the
            floor, contact shadow, scroll-scrubbed 3D rotation outside,
            cursor tilt inside. */}
        <div className="vl-hero-phone">
          <div className="vl-stage">
            <PhoneDemo
              frameWrapper={(frame) => (
                <div className="vl-product" style={{ perspective: 1300, transformStyle: 'preserve-3d' }}>
                  <div ref={phoneTiltRef} style={{ transformStyle: 'preserve-3d' }}>{frame}</div>
                </div>
              )}
            />
            <div className="vl-contact-shadow" aria-hidden="true" />
          </div>
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
