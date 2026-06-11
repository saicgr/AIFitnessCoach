import { useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { isPrerender, prefersReducedMotion } from '../../lib/runtimeEnv';

interface Story {
  id: string;
  word: string;        // oversized kinetic background word
  kicker: string;
  heading: string;
  paragraphs: string[];
  bullets: string[];
  link: { label: string; to: string };
}

// The SEO meat of the homepage: real product copy, crawlable at all times.
const STORIES: Story[] = [
  {
    id: 'coach',
    word: 'COACH',
    kicker: 'Real-time AI coaching',
    heading: 'A coach that knows what set you are on',
    paragraphs: [
      'Ask Coach Mike anything mid-workout and he answers with your live context: the exercise you are doing, the weight on the bar, how many sets are left, and what you lifted last week.',
      'Form questions, exercise swaps for a sore shoulder, motivation when the last set feels impossible. Five coach personas, one of them yours.',
    ],
    bullets: ['Knows your active workout context', 'Video form checks', '5 coach personalities'],
    link: { label: 'See the AI coach', to: '/features' },
  },
  {
    id: 'engine',
    word: 'ENGINE',
    kicker: 'AI workout generation',
    heading: 'Plans built for your gym, not a template',
    paragraphs: [
      'Zealova generates your program from your goals, experience, schedule, and the equipment you actually have. Home, hotel, outdoors, or a packed commercial gym.',
      'Every exercise comes with reasoning, video demos from a 1,722-exercise library, and progressive overload that reacts to what you log: RIR, pyramids, supersets, breathing cues.',
    ],
    bullets: ['1,722 exercises with video', 'Environment aware', '52+ skill progressions'],
    link: { label: 'How generation works', to: '/features' },
  },
  {
    id: 'fuel',
    word: 'FUEL',
    kicker: 'Photo nutrition',
    heading: 'Point your camera at lunch. Logged.',
    paragraphs: [
      'Snap a photo of any meal and get calories, full macros, and a nutrition score out of 10 in seconds. Scan restaurant menus, barcodes, and nutrition labels too.',
      'An adaptive TDEE engine learns your real burn rate from your weight trend and adjusts your targets weekly, the way a human coach would.',
    ],
    bullets: ['Photo + barcode + menu scan', 'Nutrition score per meal', 'Adaptive TDEE targets'],
    link: { label: 'See nutrition tracking', to: '/features' },
  },
  {
    id: 'proof',
    word: 'PROOF',
    kicker: 'Progress analytics',
    heading: 'Watch the work turn into numbers',
    paragraphs: [
      'Muscle heatmaps show what you have trained and what you have neglected. Strength scores, 1RM records, streaks, and side-by-side transformation photos keep the receipts.',
      'All-time charts for every lift and every measurement. When the bar moves, you will know exactly why.',
    ],
    bullets: ['Muscle heatmap + balance', '1RM and strength scores', 'Transformation photos'],
    link: { label: 'See the analytics', to: '/features' },
  },
];

export default function FeatureStory() {
  const rootRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (isPrerender() || prefersReducedMotion() || !rootRef.current) return;
    gsap.registerPlugin(ScrollTrigger);

    const ctx = gsap.context(() => {
      // Content reveals — once, transform/opacity only, no pinning.
      gsap.utils.toArray<HTMLElement>('.vl-story').forEach((section) => {
        gsap.from(section.querySelectorAll('.vl-story-reveal'), {
          autoAlpha: 0,
          y: 36,
          duration: 0.8,
          stagger: 0.1,
          ease: 'power3.out',
          scrollTrigger: { trigger: section, start: 'top 75%', once: true },
        });

        // Kinetic background word — scrub-linked horizontal drift (transform only).
        const word = section.querySelector('.vl-story-word');
        if (word) {
          gsap.fromTo(
            word,
            { xPercent: 6 },
            {
              xPercent: -6,
              ease: 'none',
              scrollTrigger: { trigger: section, start: 'top bottom', end: 'bottom top', scrub: 1 },
            }
          );
        }
      });
    }, rootRef);

    return () => ctx.revert();
  }, []);

  return (
    <div ref={rootRef} className="relative">
      {STORIES.map((story, i) => (
        <section
          key={story.id}
          className="vl-story relative overflow-hidden border-b border-white/5 py-24 sm:py-32"
        >
          {/* Oversized kinetic word */}
          <div
            aria-hidden="true"
            className="vl-story-word display-heading vl-outline-text pointer-events-none absolute top-6 left-0 w-full select-none whitespace-nowrap leading-none"
            style={{ fontSize: 'clamp(7rem, 22vw, 20rem)' }}
          >
            {story.word}&nbsp;{story.word}
          </div>

          <div
            className={`relative z-[1] mx-auto grid max-w-[1100px] items-center gap-12 px-6 lg:grid-cols-2 ${
              i % 2 === 1 ? 'lg:[&>*:first-child]:order-2' : ''
            }`}
          >
            {/* Copy */}
            <div>
              <p className="vl-story-reveal condensed-kicker mb-4 text-xs text-volt-500">{story.kicker}</p>
              <h2 className="vl-story-reveal display-heading text-4xl text-white sm:text-5xl md:text-6xl">
                {story.heading}
              </h2>
              {story.paragraphs.map((p) => (
                <p key={p.slice(0, 24)} className="vl-story-reveal mt-5 text-base leading-relaxed text-zinc-300 sm:text-lg">
                  {p}
                </p>
              ))}
              <Link
                to={story.link.to}
                className="vl-story-reveal mt-6 inline-flex items-center gap-2 text-sm font-medium text-volt-400 transition-colors hover:text-volt-300"
              >
                {story.link.label}
                <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5L21 12l-7.5 7.5M21 12H3" />
                </svg>
              </Link>
            </div>

            {/* Bullet stack vignette */}
            <div className="vl-story-reveal">
              <div className="space-y-3">
                {story.bullets.map((b, bi) => (
                  <div
                    key={b}
                    className="flex items-center gap-4 rounded-2xl border border-white/10 bg-[#0e0c0a]/80 px-5 py-4 backdrop-blur-sm transition-colors hover:border-volt-500/30"
                    style={{ marginLeft: `${bi * 14}px` }}
                  >
                    <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-volt-500/15 text-volt-400">
                      <svg className="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2.5}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                      </svg>
                    </span>
                    <span className="text-sm font-medium text-zinc-200 sm:text-base">{b}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>
      ))}
    </div>
  );
}
