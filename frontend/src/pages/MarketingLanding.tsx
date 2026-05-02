import { useRef } from 'react';
import { motion, useInView } from 'framer-motion';
import { Link } from 'react-router-dom';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import { CinematicHero } from '../components/ui/cinematic-landing-hero';
import GalleryHoverCarousel from '../components/ui/gallery-hover-carousel';
import { BRANDING } from '../lib/branding';

const fadeUp = {
  hidden: { opacity: 0, y: 24 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: [0.25, 0.1, 0.25, 1] as const } },
};

const stagger = {
  visible: { transition: { staggerChildren: 0.08 } },
};

const PLAY_STORE = 'https://play.google.com/store/apps/details?id=com.aifitnesscoach.app';

const premiumFeatures = [
  '1,722 exercises with video demos',
  'Unlimited AI coach chat',
  'AI workout generation',
  'AI photo food logging',
  'Unlimited workout logging',
  'Manual food logging & barcode scanner',
  'Environment aware (gym, home, hotel, outdoors)',
  'Adaptive TDEE & smart suggestions',
  'Advanced charts (all-time history)',
  'Muscle heatmap & balance analysis',
  'Skill progressions (52+ exercises)',
  'Injury tracking & body part exclusion',
  'Coach personas (5+ AI personalities)',
  'Hell Mode — max intensity',
  'No ads, ever',
];

export default function MarketingLanding() {
  const pricingRef = useRef<HTMLDivElement>(null);
  const pricingInView = useInView(pricingRef, { once: true, margin: '-80px' });

  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)] selection:bg-emerald-500/20 overflow-x-hidden">
      <MarketingNav />

      {/* Cinematic Hero */}
      <CinematicHero
        brandName={BRANDING.appName}
        tagline1="Train smarter,"
        tagline2="not just harder."
        cardHeading="AI coaching, redefined."
        cardDescription={<><span className="text-white font-semibold">{BRANDING.appName}</span> gives you personalized workout plans, real-time AI coaching, intelligent progress tracking, and nutrition guidance — all powered by advanced AI.</>}
        metricValue={365}
        metricLabel="Workouts Done"
        ctaHeading="Start your journey."
        ctaDescription="Join thousands of athletes training with their personal AI coach. Personalized workouts, real-time guidance, and intelligent progress tracking."
        phoneScreenshot="/screenshots/intro_phone_1.png"
        sideScreenshots={["/screenshots/intro_phone_4.png", "/screenshots/intro_phone_6.png"]}
        badges={[
          { emoji: "💪", title: "New PR Unlocked", subtitle: "Bench Press 185 lbs", color: "from-emerald-500/20 to-emerald-900/10", borderColor: "border-emerald-400/30" },
          { emoji: "🤖", title: "AI Coach", subtitle: "Form check complete", color: "from-green-500/20 to-green-900/10", borderColor: "border-green-400/30" },
        ]}
        cardSlides={[
          {
            screenshot: "/screenshots/intro_phone_1.png",
            sideScreenshots: ["/screenshots/intro_phone_4.png", "/screenshots/intro_phone_6.png"],
            heading: "AI coaching, redefined.",
            description: `${BRANDING.appName} gives you personalized workout plans, real-time AI coaching, intelligent progress tracking, and nutrition guidance — all powered by advanced AI.`,
            badges: [
              { emoji: "💪", title: "New PR Unlocked", subtitle: "Bench Press 185 lbs", color: "from-emerald-500/20 to-emerald-900/10", borderColor: "border-emerald-400/30" },
              { emoji: "🤖", title: "AI Coach", subtitle: "Form check complete", color: "from-green-500/20 to-green-900/10", borderColor: "border-green-400/30" },
            ],
          },
          {
            screenshot: "/screenshots/intro_phone_2.png",
            sideScreenshots: ["/screenshots/intro_phone_1.png", "/screenshots/intro_phone_3.png"],
            heading: "Nutrition made simple.",
            description: "Snap a photo of any meal and get instant macro breakdowns, a nutrition score out of 10, and personalized tips from Coach Mike.",
            badges: [
              { emoji: "📸", title: "Meal Logged", subtitle: "9/10 nutrition score", color: "from-orange-500/20 to-orange-900/10", borderColor: "border-orange-400/30" },
              { emoji: "🥗", title: "Daily Goal", subtitle: "142g protein hit", color: "from-green-500/20 to-green-900/10", borderColor: "border-green-400/30" },
            ],
          },
          {
            screenshot: "/screenshots/intro_phone_5.png",
            sideScreenshots: ["/screenshots/intro_phone_6.png", "/screenshots/intro_phone_7.png"],
            heading: "See your transformation.",
            description: "Track progress with side-by-side photos, heatmaps, streaks, achievements, and 1RM records — all your data in one beautiful dashboard.",
            badges: [
              { emoji: "🔥", title: "52 Workouts", subtitle: "3-month streak", color: "from-rose-500/20 to-rose-900/10", borderColor: "border-rose-400/30" },
              { emoji: "📈", title: "Strength Up", subtitle: "+15% this quarter", color: "from-blue-500/20 to-blue-900/10", borderColor: "border-blue-400/30" },
            ],
          },
        ]}
      />

      {/* ── Screenshot Showcase (Gallery Hover Carousel) ── */}
      <GalleryHoverCarousel
        heading="Everything you need. One app."
        subtitle="Real screenshots. No mockups."
        items={[
          { id: 'ai-coach', title: 'AI Coach', summary: 'Real-time coaching mid-workout. Ask about form, get exercise swaps, and motivation from Coach Mike.', url: '/features', image: '/screenshots/intro_phone_1.png' },
          { id: 'nutrition', title: 'Smart Nutrition', summary: 'Snap a photo and get instant macro breakdowns, nutrition scores, and personalized tips.', url: '/features', image: '/screenshots/intro_phone_2.png' },
          { id: 'workouts', title: 'AI Workout Plans', summary: 'AI-designed workouts for your goals, equipment, and experience level with full exercise reasoning.', url: '/features', image: '/screenshots/intro_phone_3.png' },
          { id: 'tracking', title: 'Exercise Tracking', summary: 'Log sets, reps, and weight in real time. Track RIR, pyramids, supersets, and breathing cues.', url: '/features', image: '/screenshots/intro_phone_4.png' },
          { id: 'progress', title: 'Progress Photos', summary: 'Side-by-side transformation photos with customizable layouts, overlays, and sharing.', url: '/features', image: '/screenshots/intro_phone_5.png' },
          { id: 'stats', title: 'Stats & Scores', summary: 'Heatmaps, streaks, achievements, body measurements, weekly summaries, and 1RM tracking.', url: '/features', image: '/screenshots/intro_phone_6.png' },
          { id: 'library', title: 'Exercise Library', summary: 'Browse 1,722 exercises. Set favorites, staples, avoids, queue exercises, and weight increments.', url: '/features', image: '/screenshots/intro_phone_7.png' },
        ]}
      />

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
              One plan. Everything included.
            </motion.h2>
            <motion.p variants={fadeUp} className="text-[17px] text-[var(--color-text-secondary)] mt-4 max-w-[500px] mx-auto">
              Try every feature free for 7 days. No credit card required.
            </motion.p>
          </motion.div>

          <motion.div
            initial="hidden"
            animate={pricingInView ? 'visible' : 'hidden'}
            variants={stagger}
            className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-[700px] mx-auto"
          >
            {/* Premium Yearly — Best Value */}
            <motion.div
              variants={fadeUp}
              className="relative p-8 rounded-3xl bg-gradient-to-b from-emerald-500/10 to-[var(--color-surface)] border-2 border-emerald-500/30"
            >
              <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-4 py-1 bg-emerald-500 text-white text-xs font-bold uppercase tracking-wider rounded-full">
                Best Value
              </div>
              <h3 className="text-2xl font-semibold mb-1">Yearly</h3>
              <p className="text-[var(--color-text-secondary)] text-sm mb-6">Full AI-powered fitness</p>
              <div className="flex items-baseline gap-1 mb-1">
                <span className="text-[48px] font-bold tracking-tight bg-gradient-to-r from-emerald-400 to-green-400 bg-clip-text text-transparent">$5</span>
                <span className="text-[var(--color-text-secondary)] text-sm">/month</span>
              </div>
              <p className="text-[13px] text-[var(--color-text-muted)] mb-2">Billed as $59.99/year — 38% off</p>
              <p className="text-[13px] text-emerald-500 font-medium mb-6">7-day free trial included</p>
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
                href={PLAY_STORE}
                target="_blank"
                rel="noopener noreferrer"
                className="block w-full text-center py-3 rounded-full bg-emerald-500 hover:bg-emerald-400 text-white font-medium transition-colors"
              >
                Start 7-Day Free Trial
              </a>
            </motion.div>

            {/* Premium Monthly */}
            <motion.div
              variants={fadeUp}
              className="p-8 rounded-3xl bg-[var(--color-surface)] border border-[var(--color-border)]"
            >
              <h3 className="text-2xl font-semibold mb-1">Monthly</h3>
              <p className="text-[var(--color-text-secondary)] text-sm mb-6">Pay as you go</p>
              <div className="flex items-baseline gap-1 mb-2">
                <span className="text-[48px] font-bold tracking-tight">$7.99</span>
                <span className="text-[var(--color-text-secondary)] text-sm">/month</span>
              </div>
              <p className="text-[13px] text-[var(--color-text-muted)] mb-8">Billed monthly, cancel anytime</p>
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
                href={PLAY_STORE}
                target="_blank"
                rel="noopener noreferrer"
                className="block w-full text-center py-3 rounded-full border border-[var(--color-border)] hover:border-emerald-500/50 text-[var(--color-text)] font-medium transition-colors"
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
