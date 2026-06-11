import { useEffect } from 'react';
import { Link } from 'react-router-dom';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';

interface Feature {
  kicker: string;
  title: string;
  watermark: string;
  paragraphs: string[];
  /** intro_phone_N index for /screenshots and /screenshots/opt variants */
  shot: number;
  alt: string;
}

const FEATURES: Feature[] = [
  {
    kicker: 'AI Coach Chat',
    title: 'A coach in your corner, mid-set',
    watermark: 'COACH',
    paragraphs: [
      'Get real-time coaching during your workout. Ask about form, request an exercise swap, or ask for motivation when the last set gets heavy.',
      'Your coach knows your full context: your plan, your history, your goals. No copy-pasting your situation into a generic chatbot.',
    ],
    shot: 1,
    alt: 'AI coach chat screen in the Zealova app',
  },
  {
    kicker: 'Smart Nutrition',
    title: 'Snap a photo. Know your macros.',
    watermark: 'FUEL',
    paragraphs: [
      'Point your camera at any meal and get an instant macro breakdown, plus a nutrition score so you know how the plate stacks up.',
      'Coach Mike follows up with personalized tips, so every meal becomes a small coaching moment instead of a spreadsheet chore.',
    ],
    shot: 2,
    alt: 'Smart nutrition photo logging screen in the Zealova app',
  },
  {
    kicker: 'AI Workout Plans',
    title: 'Workouts built for you, not a template',
    watermark: 'PLAN',
    paragraphs: [
      'Every workout is designed by AI for your specific goals, your equipment, and your experience level. Nothing generic, nothing recycled.',
      'Each session comes complete with exercise reasoning and insights, so you understand why every movement made the cut.',
    ],
    shot: 3,
    alt: 'AI generated workout plan screen in the Zealova app',
  },
  {
    kicker: 'Exercise Tracking',
    title: 'Log everything without breaking flow',
    watermark: 'TRACK',
    paragraphs: [
      'Log sets, reps, and weight in real time from one clean interface that stays out of your way between sets.',
      'Track RIR, run pyramid sets and supersets, and follow breathing cues. The serious tools are all there when you want them.',
    ],
    shot: 4,
    alt: 'Live exercise tracking screen in the Zealova app',
  },
  {
    kicker: 'Progress Photos',
    title: 'See how far you have come',
    watermark: 'PROOF',
    paragraphs: [
      'Side-by-side transformation photos make slow progress impossible to miss. The mirror lies day to day. Photos do not.',
      'Customizable layouts, overlays, and sharing let you frame the comparison your way and show it off when you are ready.',
    ],
    shot: 5,
    alt: 'Progress photo comparison screen in the Zealova app',
  },
  {
    kicker: 'Stats & Scores',
    title: 'All your data in one place',
    watermark: 'DATA',
    paragraphs: [
      'Heatmaps, streaks, and achievements turn consistency into something you can see and chase week after week.',
      'Body measurements, weekly summaries, and 1RM tracking live alongside them, so your whole training picture sits on one screen.',
    ],
    shot: 6,
    alt: 'Stats, streaks, and scores screen in the Zealova app',
  },
  {
    kicker: 'Exercise Library',
    title: 'Your library, your rules',
    watermark: 'LIBRARY',
    paragraphs: [
      'Browse the full exercise library and customize your preferences: set favorites, staples, and avoids so plans match how you actually train.',
      'Queue exercises you want to see soon and configure weight increments per movement. The AI builds around your choices.',
    ],
    shot: 7,
    alt: 'Exercise library and preferences screen in the Zealova app',
  },
];

function PhoneShot({ feature, glowLeft }: { feature: Feature; glowLeft: boolean }) {
  const base = `/screenshots/opt/intro_phone_${feature.shot}`;
  const srcSet = (ext: string) => `${base}-480.${ext} 480w, ${base}-768.${ext} 768w, ${base}-1080.${ext} 1080w`;
  return (
    <div className="relative flex-shrink-0">
      {/* static volt bloom behind the device */}
      <div
        aria-hidden="true"
        className={`absolute top-1/2 -translate-y-1/2 h-[70%] w-[140%] pointer-events-none ${glowLeft ? '-left-[30%]' : '-right-[30%]'}`}
        style={{ background: 'radial-gradient(ellipse at center, rgba(255,122,0,0.10) 0%, transparent 65%)' }}
      />
      <div
        className={`relative w-[240px] sm:w-[280px] overflow-hidden rounded-[2.5rem] border border-white/10 bg-black p-2 ${glowLeft ? 'shadow-[var(--shadow-volt)]' : 'shadow-[0_40px_80px_-20px_rgba(0,0,0,0.6)]'}`}
      >
        <picture>
          <source type="image/avif" srcSet={srcSet('avif')} sizes="280px" />
          <source type="image/webp" srcSet={srcSet('webp')} sizes="280px" />
          <img
            src={`/screenshots/intro_phone_${feature.shot}.png`}
            alt={feature.alt}
            width={1080}
            height={2400}
            loading="lazy"
            decoding="async"
            className="h-auto w-full rounded-[2rem]"
          />
        </picture>
      </div>
    </div>
  );
}

export default function Features() {
  useEffect(() => {
    const title = 'Features | Zealova: AI Workout & Meal Coach';
    const description =
      'Real screenshots from Zealova: AI coach chat, photo meal logging with macro breakdowns, AI workout plans, set-by-set tracking, progress photos, stats, and a customizable exercise library.';
    document.title = title;
    const setMeta = (key: string, value: string, isProperty = false) => {
      const attr = isProperty ? 'property' : 'name';
      let el = document.head.querySelector<HTMLMetaElement>(`meta[${attr}="${key}"]`);
      if (!el) {
        el = document.createElement('meta');
        el.setAttribute(attr, key);
        document.head.appendChild(el);
      }
      el.content = value;
    };
    setMeta('description', description);
    setMeta('og:title', title, true);
    setMeta('og:description', description, true);
    setMeta('og:url', 'https://zealova.com/features', true);
    setMeta('og:type', 'website', true);

    let canonicalLink = document.head.querySelector<HTMLLinkElement>('link[rel="canonical"]');
    if (!canonicalLink) {
      canonicalLink = document.createElement('link');
      canonicalLink.rel = 'canonical';
      document.head.appendChild(canonicalLink);
    }
    canonicalLink.href = 'https://zealova.com/features';
  }, []);

  return (
    <div className="min-h-screen overflow-x-clip bg-[#050505] text-white">
      <MarketingNav />

      {/* ============ HERO ============ */}
      <section className="relative px-6 pb-20 pt-32 sm:pt-40">
        <div
          aria-hidden="true"
          className="pointer-events-none absolute inset-x-0 top-0 h-[480px]"
          style={{ background: 'radial-gradient(ellipse 70% 50% at 50% 0%, rgba(255,122,0,0.08) 0%, transparent 70%)' }}
        />
        <div className="relative mx-auto max-w-[1100px]">
          <p className="condensed-kicker mb-5 text-sm text-volt-500">The full stack coach</p>
          <h1 className="display-heading text-5xl sm:text-7xl">
            Every rep. Every meal.
            <br />
            <span className="text-volt-300">One coach.</span>
          </h1>
          <p className="mt-7 max-w-[560px] text-base leading-relaxed text-white/70 sm:text-lg">
            Real screenshots from the app. No mockups, no placeholders. This is exactly what you get: an AI coach that
            plans your training, reads your meals, and tracks everything in between.
          </p>
          <div className="mt-9 flex flex-wrap items-center gap-4">
            <Link to="/waitlist" className="btn-volt inline-flex items-center rounded-full px-8 py-4 text-base">
              Join the waitlist
            </Link>
            <Link
              to="/free-tools"
              className="condensed-kicker inline-flex items-center rounded-full border border-white/20 px-8 py-4 text-sm text-white/90 transition-colors hover:border-volt-500/50 hover:text-volt-300"
            >
              Try the free tools
            </Link>
          </div>
        </div>
      </section>

      <div className="kinetic-rule mx-auto max-w-[1100px]" />

      {/* ============ FEATURE SECTIONS ============ */}
      <div className="px-6">
        <div className="mx-auto max-w-[1100px]">
          {FEATURES.map((feature, i) => {
            const reversed = i % 2 === 1;
            return (
              <section key={feature.kicker} className="relative py-20 sm:py-28">
                {/* oversized watermark */}
                <span
                  aria-hidden="true"
                  className={`display-heading pointer-events-none absolute top-6 select-none text-[7rem] leading-none text-white/[0.03] sm:text-[12rem] ${reversed ? 'right-0' : 'left-0'}`}
                >
                  {feature.watermark}
                </span>

                <div
                  className={`relative flex flex-col items-center gap-12 lg:gap-20 ${reversed ? 'lg:flex-row-reverse' : 'lg:flex-row'}`}
                >
                  <PhoneShot feature={feature} glowLeft={!reversed} />

                  <div className="flex-1">
                    <p className="condensed-kicker mb-4 text-sm text-volt-500">
                      {String(i + 1).padStart(2, '0')} / {feature.kicker}
                    </p>
                    <h2 className="display-heading text-4xl sm:text-6xl">{feature.title}</h2>
                    <div className="mt-6 max-w-[520px] space-y-4">
                      {feature.paragraphs.map((p) => (
                        <p key={p.slice(0, 24)} className="text-base leading-relaxed text-white/70 sm:text-lg">
                          {p}
                        </p>
                      ))}
                    </div>
                  </div>
                </div>
              </section>
            );
          })}
        </div>
      </div>

      {/* ============ CTA BAND ============ */}
      <section className="relative px-6 py-24 sm:py-32">
        <div
          aria-hidden="true"
          className="pointer-events-none absolute inset-0"
          style={{ background: 'radial-gradient(ellipse 60% 70% at 50% 100%, rgba(255,122,0,0.10) 0%, transparent 70%)' }}
        />
        <div className="relative mx-auto max-w-[800px] text-center">
          <p className="condensed-kicker mb-5 text-sm text-volt-500">Ready to start?</p>
          <h2 className="display-heading text-4xl sm:text-6xl">Train like it is built for you</h2>
          <p className="mx-auto mt-6 max-w-[480px] text-base leading-relaxed text-white/70">
            From $5/month (yearly) or $7.99/month. 7-day free trial, cancel anytime.
          </p>
          <div className="mt-9 flex flex-wrap items-center justify-center gap-4">
            <Link to="/waitlist" className="btn-volt inline-flex items-center rounded-full px-8 py-4 text-base">
              Join the waitlist
            </Link>
            <a
              href="https://play.google.com/store/apps/details?id=com.aifitnesscoach.app"
              target="_blank"
              rel="noopener noreferrer"
              className="condensed-kicker inline-flex items-center gap-3 rounded-full border border-white/20 px-8 py-4 text-sm text-white/90 transition-colors hover:border-volt-500/50 hover:text-volt-300"
            >
              <svg className="h-5 w-5" fill="currentColor" viewBox="0 0 512 512" aria-hidden="true">
                <path d="M325.3 234.3L104.6 13l280.8 161.2-60.1 60.1zM47 0C34 6.8 25.3 19.2 25.3 35.3v441.3c0 16.1 8.7 28.5 21.7 35.3l256.6-256L47 0zm425.2 225.6l-58.9-34.1-65.7 64.5 65.7 64.5 60.1-34.1c18-14.3 18-46.5-1.2-60.8zM104.6 499l280.8-161.2-60.1-60.1L104.6 499z" />
              </svg>
              Get it on Google Play
            </a>
          </div>
        </div>
      </section>

      <MarketingFooter />
    </div>
  );
}
