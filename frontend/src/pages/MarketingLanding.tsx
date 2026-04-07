import { useRef } from 'react';
import { motion, useInView } from 'framer-motion';
import { Link } from 'react-router-dom';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import { CinematicHero } from '../components/ui/cinematic-landing-hero';

const fadeUp = {
  hidden: { opacity: 0, y: 24 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: [0.25, 0.1, 0.25, 1] as const } },
};

const stagger = {
  visible: { transition: { staggerChildren: 0.08 } },
};

const appScreenshots = [
  { src: '/screenshots/intro_phone_1.png', label: 'AI Coach', description: 'Real-time coaching mid-workout' },
  { src: '/screenshots/intro_phone_2.png', label: 'Nutrition', description: 'Photo-based meal scoring' },
  { src: '/screenshots/intro_phone_3.png', label: 'Workouts', description: 'AI-designed training plans' },
  { src: '/screenshots/intro_phone_4.png', label: 'Tracking', description: 'Sets, reps, weight logging' },
  { src: '/screenshots/intro_phone_5.png', label: 'Progress', description: 'Side-by-side transformations' },
  { src: '/screenshots/intro_phone_6.png', label: 'Stats', description: 'Heatmaps, streaks, PRs' },
  { src: '/screenshots/intro_phone_7.png', label: 'Library', description: '1,722 exercises' },
];

const freeFeatures = [
  '1,722 exercises with videos',
  'Unlimited workout logging',
  'Manual food logging & barcode scanner',
  'Habit tracking & streaks',
  'Progress photos & measurements',
  '5 AI chat messages/day',
  'No ads, ever',
];

const premiumFeatures = [
  'Everything in Free, plus:',
  'Unlimited AI chat (5 specialist agents)',
  'AI workout generation',
  'AI photo food logging',
  'Adaptive TDEE & smart suggestions',
  'Advanced charts (all-time history)',
  'Muscle heatmap & balance analysis',
  'Voice guidance & coach personas',
];

export default function MarketingLanding() {
  const showcaseRef = useRef<HTMLDivElement>(null);
  const pricingRef = useRef<HTMLDivElement>(null);
  const showcaseInView = useInView(showcaseRef, { once: true, margin: '-80px' });
  const pricingInView = useInView(pricingRef, { once: true, margin: '-80px' });

  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)] selection:bg-emerald-500/20 overflow-x-hidden">
      <MarketingNav />

      {/* Cinematic Hero */}
      <CinematicHero
        brandName="FitWiz"
        tagline1="Train smarter,"
        tagline2="not just harder."
        cardHeading="AI coaching, redefined."
        cardDescription={<><span className="text-white font-semibold">FitWiz</span> gives you personalized workout plans, real-time AI coaching, intelligent progress tracking, and nutrition guidance — all powered by advanced AI.</>}
        metricValue={365}
        metricLabel="Workouts Done"
        ctaHeading="Start your journey."
        ctaDescription="Join thousands of athletes training with their personal AI coach. Personalized workouts, real-time guidance, and intelligent progress tracking."
        phoneScreenshot="/screenshots/intro_phone_1.png"
        badges={[
          {
            emoji: "💪",
            title: "New PR Unlocked",
            subtitle: "Bench Press 185 lbs",
            color: "from-emerald-500/20 to-emerald-900/10",
            borderColor: "border-emerald-400/30",
          },
          {
            emoji: "🤖",
            title: "AI Coach",
            subtitle: "Form check complete",
            color: "from-green-500/20 to-green-900/10",
            borderColor: "border-green-400/30",
          },
        ]}
      />

      {/* ── Screenshot Showcase ── */}
      <section ref={showcaseRef} className="py-20 sm:py-28 px-6">
        <div className="max-w-[1200px] mx-auto">
          <motion.div
            initial="hidden"
            animate={showcaseInView ? 'visible' : 'hidden'}
            variants={stagger}
            className="text-center mb-14"
          >
            <motion.p variants={fadeUp} className="text-[15px] text-[var(--color-text-muted)] mb-2 uppercase tracking-wider font-medium">
              Inside the app
            </motion.p>
            <motion.h2
              variants={fadeUp}
              className="text-[32px] sm:text-[48px] font-semibold tracking-[-0.02em]"
              style={{ fontFamily: 'var(--font-heading)' }}
            >
              Everything you need. One app.
            </motion.h2>
          </motion.div>

          {/* Horizontal scroll gallery */}
          <motion.div
            initial="hidden"
            animate={showcaseInView ? 'visible' : 'hidden'}
            variants={stagger}
            className="flex gap-6 overflow-x-auto pb-6 snap-x snap-mandatory scrollbar-hide"
            style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}
          >
            {appScreenshots.map((item) => (
              <motion.div
                key={item.label}
                variants={fadeUp}
                className="flex-shrink-0 snap-center w-[220px] sm:w-[260px] group"
              >
                {/* Phone frame */}
                <div
                  className="relative rounded-[2.2rem] p-[8px] mb-4 transition-transform duration-300 group-hover:scale-[1.03]"
                  style={{
                    background: 'linear-gradient(145deg, #3a3a3c 0%, #1c1c1e 50%, #0a0a0a 100%)',
                    boxShadow: '0 30px 60px -15px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.08)',
                  }}
                >
                  {/* Notch */}
                  <div className="absolute top-[10px] left-1/2 -translate-x-1/2 w-20 h-6 bg-black rounded-full z-20" />

                  {/* Screen */}
                  <div className="relative rounded-[1.8rem] overflow-hidden bg-black" style={{ aspectRatio: '9/19.5' }}>
                    <img
                      src={item.src}
                      alt={item.label}
                      className="absolute inset-0 w-full h-full object-cover"
                      loading="lazy"
                    />
                  </div>
                </div>

                {/* Label */}
                <div className="text-center px-2">
                  <p className="text-[15px] font-semibold text-[var(--color-text)] mb-0.5">{item.label}</p>
                  <p className="text-[13px] text-[var(--color-text-secondary)]">{item.description}</p>
                </div>
              </motion.div>
            ))}

            {/* See all features card */}
            <motion.div variants={fadeUp} className="flex-shrink-0 snap-center w-[220px] sm:w-[260px] flex items-center justify-center">
              <Link
                to="/features"
                className="flex flex-col items-center justify-center gap-4 w-full h-full min-h-[380px] rounded-[2.2rem] border-2 border-dashed border-[var(--color-border)] hover:border-emerald-500/50 transition-colors group"
              >
                <div className="w-14 h-14 rounded-full bg-emerald-500/10 flex items-center justify-center group-hover:bg-emerald-500/20 transition-colors">
                  <svg className="w-6 h-6 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                  </svg>
                </div>
                <div className="text-center">
                  <p className="text-[15px] font-semibold text-[var(--color-text)]">See all features</p>
                  <p className="text-[13px] text-[var(--color-text-secondary)]">With full screenshots</p>
                </div>
              </Link>
            </motion.div>
          </motion.div>
        </div>
      </section>

      {/* ── Pricing ── */}
      <section ref={pricingRef} className="py-20 sm:py-28 px-6 bg-[var(--color-surface-muted)]">
        <div className="max-w-[900px] mx-auto">
          <motion.div
            initial="hidden"
            animate={pricingInView ? 'visible' : 'hidden'}
            variants={stagger}
            className="text-center mb-14"
          >
            <motion.p variants={fadeUp} className="text-[15px] text-[var(--color-text-muted)] mb-2 uppercase tracking-wider font-medium">
              Simple pricing
            </motion.p>
            <motion.h2
              variants={fadeUp}
              className="text-[32px] sm:text-[48px] font-semibold tracking-[-0.02em]"
              style={{ fontFamily: 'var(--font-heading)' }}
            >
              Free forever. Premium for power.
            </motion.h2>
          </motion.div>

          <motion.div
            initial="hidden"
            animate={pricingInView ? 'visible' : 'hidden'}
            variants={stagger}
            className="grid grid-cols-1 md:grid-cols-2 gap-6"
          >
            {/* Free Plan */}
            <motion.div
              variants={fadeUp}
              className="p-8 rounded-3xl bg-[var(--color-surface)] border border-[var(--color-border)]"
            >
              <h3 className="text-2xl font-semibold mb-1">Free</h3>
              <p className="text-[var(--color-text-secondary)] text-sm mb-6">Everything to get started</p>
              <div className="flex items-baseline gap-1 mb-8">
                <span className="text-[48px] font-bold tracking-tight">$0</span>
                <span className="text-[var(--color-text-secondary)] text-sm">/forever</span>
              </div>
              <ul className="space-y-3 mb-8">
                {freeFeatures.map((f) => (
                  <li key={f} className="flex items-start gap-3 text-[15px]">
                    <svg className="w-5 h-5 text-emerald-500 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                    <span className="text-[var(--color-text)]">{f}</span>
                  </li>
                ))}
              </ul>
              <a
                href="https://play.google.com/store"
                target="_blank"
                rel="noopener noreferrer"
                className="block w-full text-center py-3 rounded-full border border-[var(--color-border)] hover:border-emerald-500/50 text-[var(--color-text)] font-medium transition-colors"
              >
                Get Started Free
              </a>
            </motion.div>

            {/* Premium Plan */}
            <motion.div
              variants={fadeUp}
              className="relative p-8 rounded-3xl bg-gradient-to-b from-emerald-500/10 to-[var(--color-surface)] border-2 border-emerald-500/30"
            >
              <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-4 py-1 bg-emerald-500 text-white text-xs font-bold uppercase tracking-wider rounded-full">
                Most Popular
              </div>
              <h3 className="text-2xl font-semibold mb-1">Premium</h3>
              <p className="text-[var(--color-text-secondary)] text-sm mb-6">Full AI-powered fitness</p>
              <div className="flex items-baseline gap-1 mb-2">
                <span className="text-[48px] font-bold tracking-tight bg-gradient-to-r from-emerald-400 to-green-400 bg-clip-text text-transparent">$4.99</span>
                <span className="text-[var(--color-text-secondary)] text-sm">/month</span>
              </div>
              <p className="text-[13px] text-[var(--color-text-muted)] mb-8">7-day free trial included</p>
              <ul className="space-y-3 mb-8">
                {premiumFeatures.map((f) => (
                  <li key={f} className="flex items-start gap-3 text-[15px]">
                    <svg className="w-5 h-5 text-emerald-500 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                    <span className="text-[var(--color-text)]">{f}</span>
                  </li>
                ))}
              </ul>
              <a
                href="https://play.google.com/store"
                target="_blank"
                rel="noopener noreferrer"
                className="block w-full text-center py-3 rounded-full bg-emerald-500 hover:bg-emerald-400 text-white font-medium transition-colors"
              >
                Start 7-Day Free Trial
              </a>
            </motion.div>
          </motion.div>

          {/* Comparison link */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={pricingInView ? { opacity: 1 } : {}}
            transition={{ delay: 0.5 }}
            className="text-center mt-8"
          >
            <Link to="/pricing" className="text-sm text-emerald-500 hover:underline">
              See full feature comparison →
            </Link>
          </motion.div>
        </div>
      </section>

      <MarketingFooter />
    </div>
  );
}
