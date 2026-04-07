import { motion } from 'framer-motion';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';

const fadeUp = {
  hidden: { opacity: 0, y: 30 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: [0.25, 0.1, 0.25, 1] as const } },
};

const stagger = {
  visible: { transition: { staggerChildren: 0.12 } },
};

const features = [
  {
    title: 'AI Coach Chat',
    description: 'Get real-time coaching during your workout. Ask about form, get exercise swaps, or request motivation — your coach knows your full context.',
    screenshot: '/screenshots/intro_phone_1.png',
    accent: 'from-emerald-500 to-green-500',
  },
  {
    title: 'Smart Nutrition',
    description: 'Snap a photo of your meal and get instant macro breakdowns, nutrition scores, and personalized tips from Coach Mike.',
    screenshot: '/screenshots/intro_phone_2.png',
    accent: 'from-orange-500 to-amber-500',
  },
  {
    title: 'AI Workout Plans',
    description: 'Every workout is designed by AI for your specific goals, equipment, and experience level. Complete with exercise reasoning and insights.',
    screenshot: '/screenshots/intro_phone_3.png',
    accent: 'from-green-500 to-lime-500',
  },
  {
    title: 'Exercise Tracking',
    description: 'Log sets, reps, and weight in real time. Track RIR, use pyramid sets, supersets, and breathing cues — all in one clean interface.',
    screenshot: '/screenshots/intro_phone_4.png',
    accent: 'from-teal-500 to-emerald-500',
  },
  {
    title: 'Progress Photos',
    description: 'Side-by-side transformation photos with customizable layouts, overlays, and sharing — see how far you\'ve come.',
    screenshot: '/screenshots/intro_phone_5.png',
    accent: 'from-rose-500 to-orange-500',
  },
  {
    title: 'Stats & Scores',
    description: 'Heatmaps, streaks, achievements, body measurements, weekly summaries, and 1RM tracking — all your data in one place.',
    screenshot: '/screenshots/intro_phone_6.png',
    accent: 'from-blue-500 to-cyan-500',
  },
  {
    title: 'Exercise Library',
    description: 'Browse and customize your exercise preferences. Set favorites, staples, avoids, queue exercises, and configure weight increments.',
    screenshot: '/screenshots/intro_phone_7.png',
    accent: 'from-amber-500 to-yellow-500',
  },
];

export default function Features() {
  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)]">
      <MarketingNav />

      {/* Hero */}
      <section className="pt-28 pb-16 px-6">
        <div className="max-w-[800px] mx-auto text-center">
          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-[40px] sm:text-[56px] font-semibold tracking-[-0.02em] mb-5"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            See it in action.
          </motion.h1>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="text-[17px] sm:text-[21px] text-[var(--color-text-secondary)] max-w-[550px] mx-auto leading-relaxed"
          >
            Real screenshots from the app. No mockups, no placeholders — this is what you get.
          </motion.p>
        </div>
      </section>

      {/* Feature Sections — alternating layout */}
      <section className="px-6 pb-24">
        <motion.div
          className="max-w-[1100px] mx-auto space-y-24 sm:space-y-32"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: '-50px' }}
          variants={stagger}
        >
          {features.map((feature, i) => {
            const isReversed = i % 2 === 1;
            return (
              <motion.div
                key={feature.title}
                variants={fadeUp}
                className={`flex flex-col ${isReversed ? 'lg:flex-row-reverse' : 'lg:flex-row'} items-center gap-12 lg:gap-20`}
              >
                {/* Phone mockup */}
                <div className="relative flex-shrink-0">
                  {/* Glow behind phone */}
                  <div className={`absolute inset-0 bg-gradient-to-br ${feature.accent} opacity-15 blur-3xl scale-110 rounded-full`} />

                  {/* Phone frame */}
                  <div
                    className="relative w-[260px] sm:w-[280px] rounded-[2.8rem] p-[10px] shadow-2xl"
                    style={{
                      background: 'linear-gradient(145deg, #3a3a3c 0%, #1c1c1e 50%, #0a0a0a 100%)',
                      boxShadow: '0 40px 80px -20px rgba(0,0,0,0.6), 0 20px 40px -10px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.1)',
                    }}
                  >
                    {/* Screen */}
                    <div className="relative rounded-[2.2rem] overflow-hidden bg-black" style={{ aspectRatio: '9/19.5' }}>
                      <img
                        src={feature.screenshot}
                        alt={feature.title}
                        className="absolute inset-0 w-full h-full object-cover"
                        loading="lazy"
                      />
                    </div>

                    {/* Home indicator */}
                    <div className="absolute bottom-[8px] left-1/2 -translate-x-1/2 w-28 h-1 bg-white/20 rounded-full" />
                  </div>
                </div>

                {/* Text content */}
                <div className={`flex-1 text-center lg:text-left ${isReversed ? 'lg:text-right' : ''}`}>
                  <div className={`inline-block px-3 py-1 rounded-full bg-gradient-to-r ${feature.accent} text-white text-[11px] font-bold uppercase tracking-wider mb-4`}>
                    {String(i + 1).padStart(2, '0')}
                  </div>
                  <h2 className="text-[28px] sm:text-[36px] font-semibold tracking-[-0.02em] mb-4" style={{ fontFamily: 'var(--font-heading)' }}>
                    {feature.title}
                  </h2>
                  <p className="text-[16px] sm:text-[18px] text-[var(--color-text-secondary)] leading-relaxed max-w-md mx-auto lg:mx-0">
                    {feature.description}
                  </p>
                </div>
              </motion.div>
            );
          })}
        </motion.div>
      </section>

      {/* Bottom CTA */}
      <section className="px-6 pb-24">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="max-w-[600px] mx-auto text-center"
        >
          <h2 className="text-[28px] sm:text-[36px] font-semibold tracking-[-0.02em] mb-4" style={{ fontFamily: 'var(--font-heading)' }}>
            Ready to start?
          </h2>
          <p className="text-[16px] text-[var(--color-text-secondary)] mb-8">
            $4.99/month. Cancel anytime. Your AI coach is waiting.
          </p>
          <a
            href="https://play.google.com/store"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-3 px-8 py-4 bg-emerald-500 hover:bg-emerald-400 text-white rounded-full transition-colors text-[17px] font-medium"
          >
            <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 512 512">
              <path d="M325.3 234.3L104.6 13l280.8 161.2-60.1 60.1zM47 0C34 6.8 25.3 19.2 25.3 35.3v441.3c0 16.1 8.7 28.5 21.7 35.3l256.6-256L47 0zm425.2 225.6l-58.9-34.1-65.7 64.5 65.7 64.5 60.1-34.1c18-14.3 18-46.5-1.2-60.8zM104.6 499l280.8-161.2-60.1-60.1L104.6 499z"/>
            </svg>
            Get it on Google Play
          </a>
        </motion.div>
      </section>

      <MarketingFooter />
    </div>
  );
}
