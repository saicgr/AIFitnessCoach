import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';

// Apple-style animations - very subtle, purposeful
const fade = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { duration: 1, ease: [0.25, 0.1, 0.25, 1] as const } },
};

const fadeUp = {
  hidden: { opacity: 0, y: 8 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.8, ease: [0.25, 0.1, 0.25, 1] as const } },
};

const stagger = {
  visible: { transition: { staggerChildren: 0.15 } },
};

export default function Landing() {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => setIsScrolled(window.scrollY > 10);
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const scrollTo = (id: string) => {
    document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' });
    setMobileMenuOpen(false);
  };

  return (
    <div className="min-h-screen bg-black text-white selection:bg-white/20">
      {/* Navigation - Apple style */}
      <motion.nav
        className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
          isScrolled
            ? 'bg-black/80 backdrop-blur-xl backdrop-saturate-150 border-b border-white/[0.04]'
            : 'bg-transparent'
        }`}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.5 }}
      >
        <div className="max-w-[980px] mx-auto px-6 lg:px-4">
          <div className="flex items-center justify-between h-12">
            {/* Logo */}
            <Link to="/" className="text-[21px] font-semibold tracking-[-0.01em] text-white/90 hover:text-white transition-colors">
              BLive
            </Link>

            {/* Desktop Nav - Apple style minimal */}
            <div className="hidden md:flex items-center gap-7">
              <button
                onClick={() => scrollTo('features')}
                className="text-xs text-white/80 hover:text-white transition-colors"
              >
                Features
              </button>
              <button
                onClick={() => scrollTo('how-it-works')}
                className="text-xs text-white/80 hover:text-white transition-colors"
              >
                How It Works
              </button>
              <Link
                to="/login"
                className="text-xs text-white/80 hover:text-white transition-colors"
              >
                Sign In
              </Link>
              <Link
                to="/login"
                className="text-xs px-4 py-1.5 bg-white text-black rounded-full hover:bg-white/90 transition-colors"
              >
                Get Started
              </Link>
            </div>

            {/* Mobile Menu Toggle */}
            <button
              className="md:hidden text-white/80 hover:text-white"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              aria-label="Menu"
            >
              <svg className="w-[18px] h-[18px]" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                {mobileMenuOpen ? (
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                ) : (
                  <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
                )}
              </svg>
            </button>
          </div>
        </div>

        {/* Mobile Menu - Apple style overlay */}
        {mobileMenuOpen && (
          <motion.div
            className="md:hidden absolute top-12 left-0 right-0 bg-black/95 backdrop-blur-xl border-b border-white/[0.04]"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.2 }}
          >
            <div className="max-w-[980px] mx-auto px-6 py-4 flex flex-col gap-4">
              <button onClick={() => scrollTo('features')} className="text-sm text-white/80 hover:text-white text-left py-2">Features</button>
              <button onClick={() => scrollTo('how-it-works')} className="text-sm text-white/80 hover:text-white text-left py-2">How It Works</button>
              <Link to="/login" className="text-sm text-white/80 hover:text-white py-2">Sign In</Link>
              <Link to="/login" className="text-sm text-center py-2.5 bg-white text-black rounded-full mt-2">Get Started</Link>
            </div>
          </motion.div>
        )}
      </motion.nav>

      {/* Hero Section - Apple style large typography */}
      <section className="relative min-h-screen flex flex-col items-center justify-center px-6 pt-12">
        <motion.div
          className="max-w-[680px] mx-auto text-center"
          initial="hidden"
          animate="visible"
          variants={stagger}
        >
          <motion.p
            variants={fade}
            className="text-[17px] text-[#6e6e73] mb-3"
          >
            Introducing
          </motion.p>

          <motion.h1
            variants={fadeUp}
            className="text-[56px] sm:text-[80px] md:text-[96px] font-semibold tracking-[-0.03em] leading-[1.05] mb-4"
          >
            BLive
          </motion.h1>

          <motion.p
            variants={fadeUp}
            className="text-[28px] sm:text-[32px] md:text-[40px] font-semibold tracking-[-0.02em] leading-[1.1] text-[#86868b] mb-6"
          >
            Your AI fitness coach.
          </motion.p>

          <motion.p
            variants={fadeUp}
            className="text-[17px] sm:text-[19px] text-[#86868b] max-w-[500px] mx-auto leading-[1.47] mb-10"
          >
            Personalized workouts. Real-time guidance. Intelligent progress tracking.
          </motion.p>

          <motion.div variants={fadeUp} className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link
              to="/login"
              className="min-w-[160px] px-7 py-3 bg-[#0071e3] text-white text-[17px] rounded-full hover:bg-[#0077ed] transition-colors"
            >
              Get started
            </Link>
            <button
              onClick={() => scrollTo('features')}
              className="min-w-[160px] px-7 py-3 text-[#2997ff] text-[17px] hover:underline transition-all"
            >
              Learn more →
            </button>
          </motion.div>
        </motion.div>

        {/* Scroll indicator - very subtle */}
        <motion.div
          className="absolute bottom-8 left-1/2 -translate-x-1/2"
          initial={{ opacity: 0 }}
          animate={{ opacity: 0.3 }}
          transition={{ delay: 1.5, duration: 1 }}
        >
          <svg className="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24">
            <path stroke="currentColor" strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round" d="M19 14l-7 7m0 0l-7-7m7 7V3" />
          </svg>
        </motion.div>
      </section>

      {/* Features Section - Apple style cards */}
      <section id="features" className="py-20 sm:py-28 px-6">
        <div className="max-w-[980px] mx-auto">
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: '-100px' }}
            variants={stagger}
            className="text-center mb-16"
          >
            <motion.h2 variants={fadeUp} className="text-[32px] sm:text-[48px] font-semibold tracking-[-0.02em] mb-4">
              Built for results.
            </motion.h2>
            <motion.p variants={fadeUp} className="text-[17px] sm:text-[21px] text-[#86868b] max-w-[600px] mx-auto">
              Everything you need to transform your training, beautifully designed and incredibly intuitive.
            </motion.p>
          </motion.div>

          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: '-50px' }}
            variants={stagger}
            className="grid grid-cols-1 md:grid-cols-2 gap-5"
          >
            {/* Feature Card 1 */}
            <motion.div
              variants={fadeUp}
              className="group p-8 sm:p-10 rounded-3xl bg-[#1d1d1f] hover:bg-[#2d2d2f] transition-colors duration-500"
            >
              <div className="w-12 h-12 mb-6 rounded-2xl bg-gradient-to-br from-blue-500 to-cyan-400 flex items-center justify-center">
                <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z" />
                </svg>
              </div>
              <h3 className="text-[24px] sm:text-[28px] font-semibold tracking-[-0.01em] mb-3">Personalized Plans</h3>
              <p className="text-[15px] sm:text-[17px] text-[#86868b] leading-[1.47]">
                AI creates workouts tailored to your goals, equipment, and schedule. Auto-generates warmups and cool-downs.
              </p>
            </motion.div>

            {/* Feature Card 2 */}
            <motion.div
              variants={fadeUp}
              className="group p-8 sm:p-10 rounded-3xl bg-[#1d1d1f] hover:bg-[#2d2d2f] transition-colors duration-500"
            >
              <div className="w-12 h-12 mb-6 rounded-2xl bg-gradient-to-br from-green-500 to-emerald-400 flex items-center justify-center">
                <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z" />
                </svg>
              </div>
              <h3 className="text-[24px] sm:text-[28px] font-semibold tracking-[-0.01em] mb-3">Real-time Tracking</h3>
              <p className="text-[15px] sm:text-[17px] text-[#86868b] leading-[1.47]">
                Log sets, reps, and weights as you train. Rest timers and exercise videos keep you on track.
              </p>
            </motion.div>

            {/* Feature Card 3 */}
            <motion.div
              variants={fadeUp}
              className="group p-8 sm:p-10 rounded-3xl bg-[#1d1d1f] hover:bg-[#2d2d2f] transition-colors duration-500"
            >
              <div className="w-12 h-12 mb-6 rounded-2xl bg-gradient-to-br from-purple-500 to-violet-400 flex items-center justify-center">
                <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M20.25 8.511c.884.284 1.5 1.128 1.5 2.097v4.286c0 1.136-.847 2.1-1.98 2.193-.34.027-.68.052-1.02.072v3.091l-3-3c-1.354 0-2.694-.055-4.02-.163a2.115 2.115 0 01-.825-.242m9.345-8.334a2.126 2.126 0 00-.476-.095 48.64 48.64 0 00-8.048 0c-1.131.094-1.976 1.057-1.976 2.192v4.286c0 .837.46 1.58 1.155 1.951m9.345-8.334V6.637c0-1.621-1.152-3.026-2.76-3.235A48.455 48.455 0 0011.25 3c-2.115 0-4.198.137-6.24.402-1.608.209-2.76 1.614-2.76 3.235v6.226c0 1.621 1.152 3.026 2.76 3.235.577.075 1.157.14 1.74.194V21l4.155-4.155" />
                </svg>
              </div>
              <h3 className="text-[24px] sm:text-[28px] font-semibold tracking-[-0.01em] mb-3">AI Coach</h3>
              <p className="text-[15px] sm:text-[17px] text-[#86868b] leading-[1.47]">
                Chat with your coach 24/7. Get form tips, swap exercises, and track nutrition from photos.
              </p>
            </motion.div>

            {/* Feature Card 4 */}
            <motion.div
              variants={fadeUp}
              className="group p-8 sm:p-10 rounded-3xl bg-[#1d1d1f] hover:bg-[#2d2d2f] transition-colors duration-500"
            >
              <div className="w-12 h-12 mb-6 rounded-2xl bg-gradient-to-br from-orange-500 to-amber-400 flex items-center justify-center">
                <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 18L9 11.25l4.306 4.307a11.95 11.95 0 015.814-5.519l2.74-1.22m0 0l-5.94-2.28m5.94 2.28l-2.28 5.941" />
                </svg>
              </div>
              <h3 className="text-[24px] sm:text-[28px] font-semibold tracking-[-0.01em] mb-3">Progress Analytics</h3>
              <p className="text-[15px] sm:text-[17px] text-[#86868b] leading-[1.47]">
                Track personal records, streaks, and strength trends. See your progress visualized over time.
              </p>
            </motion.div>
          </motion.div>
        </div>
      </section>

      {/* How It Works - Apple style numbered steps */}
      <section id="how-it-works" className="py-20 sm:py-28 px-6 bg-[#000000]">
        <div className="max-w-[980px] mx-auto">
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: '-100px' }}
            variants={stagger}
            className="text-center mb-16"
          >
            <motion.h2 variants={fadeUp} className="text-[32px] sm:text-[48px] font-semibold tracking-[-0.02em] mb-4">
              Start in minutes.
            </motion.h2>
            <motion.p variants={fadeUp} className="text-[17px] sm:text-[21px] text-[#86868b]">
              Three simple steps to your first workout.
            </motion.p>
          </motion.div>

          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: '-50px' }}
            variants={stagger}
            className="grid grid-cols-1 md:grid-cols-3 gap-8 md:gap-12"
          >
            {[
              { num: '1', title: 'Sign up', desc: 'Create your account with Google. Takes seconds.' },
              { num: '2', title: 'Tell us about you', desc: 'Quick conversation to understand your goals.' },
              { num: '3', title: 'Start training', desc: 'Get your first AI workout instantly.' },
            ].map((step, i) => (
              <motion.div key={i} variants={fadeUp} className="text-center">
                <div className="text-[64px] sm:text-[80px] font-semibold text-[#1d1d1f] leading-none mb-4">
                  {step.num}
                </div>
                <h3 className="text-[21px] sm:text-[24px] font-semibold tracking-[-0.01em] mb-2">{step.title}</h3>
                <p className="text-[15px] sm:text-[17px] text-[#86868b]">{step.desc}</p>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Coach Preview - Apple style product showcase */}
      <section className="py-20 sm:py-28 px-6">
        <div className="max-w-[980px] mx-auto">
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: '-100px' }}
            variants={stagger}
            className="grid grid-cols-1 lg:grid-cols-2 gap-12 lg:gap-16 items-center"
          >
            <motion.div variants={fadeUp}>
              <h2 className="text-[32px] sm:text-[48px] font-semibold tracking-[-0.02em] mb-6">
                Your coach,<br />always available.
              </h2>
              <p className="text-[17px] sm:text-[19px] text-[#86868b] leading-[1.47] mb-8">
                Get instant answers about your training, nutrition, and recovery. Your AI coach knows your goals, schedule, and limitations.
              </p>
              <div className="space-y-4">
                {[
                  'Understands your fitness context',
                  'Analyzes meals from photos',
                  'Suggests exercise alternatives',
                  'Available around the clock',
                ].map((item, i) => (
                  <div key={i} className="flex items-center gap-3">
                    <svg className="w-5 h-5 text-[#30d158]" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                    </svg>
                    <span className="text-[15px] sm:text-[17px] text-[#f5f5f7]">{item}</span>
                  </div>
                ))}
              </div>
            </motion.div>

            {/* Chat UI - Apple style card */}
            <motion.div variants={fadeUp}>
              <div className="p-6 rounded-3xl bg-[#1d1d1f]">
                {/* Header */}
                <div className="flex items-center gap-3 pb-4 border-b border-white/[0.05]">
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-purple-500 to-blue-500 flex items-center justify-center">
                    <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z" />
                    </svg>
                  </div>
                  <div>
                    <div className="text-[15px] font-medium text-[#f5f5f7]">AI Coach</div>
                    <div className="text-[13px] text-[#30d158]">Online</div>
                  </div>
                </div>

                {/* Messages */}
                <div className="py-5 space-y-4">
                  <div className="flex justify-end">
                    <div className="max-w-[80%] px-4 py-2.5 rounded-2xl rounded-br-md bg-[#0071e3] text-[15px] text-white">
                      My shoulder feels tight today
                    </div>
                  </div>
                  <div className="flex justify-start">
                    <div className="max-w-[80%] px-4 py-2.5 rounded-2xl rounded-bl-md bg-[#2d2d2f] text-[15px] text-[#f5f5f7]">
                      I've adjusted your workout to focus on lower body today. Added some shoulder mobility work for your cooldown.
                    </div>
                  </div>
                </div>

                {/* Input */}
                <div className="pt-4 border-t border-white/[0.05]">
                  <div className="px-4 py-3 rounded-xl bg-[#2d2d2f] text-[15px] text-[#86868b]">
                    Message
                  </div>
                </div>
              </div>
            </motion.div>
          </motion.div>
        </div>
      </section>

      {/* Final CTA - Apple style */}
      <section className="py-20 sm:py-32 px-6">
        <motion.div
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
          className="max-w-[680px] mx-auto text-center"
        >
          <motion.h2 variants={fadeUp} className="text-[40px] sm:text-[56px] md:text-[64px] font-semibold tracking-[-0.02em] leading-[1.05] mb-6">
            Start training<br />smarter today.
          </motion.h2>
          <motion.div variants={fadeUp}>
            <Link
              to="/login"
              className="inline-flex px-8 py-3.5 bg-[#0071e3] text-white text-[17px] rounded-full hover:bg-[#0077ed] transition-colors"
            >
              Get started free
            </Link>
            <p className="mt-5 text-[13px] text-[#86868b]">No credit card required.</p>
          </motion.div>
        </motion.div>
      </section>

      {/* Footer - Apple style minimal */}
      <footer className="py-5 px-6 border-t border-[#424245]">
        <div className="max-w-[980px] mx-auto">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-4 text-[12px] text-[#86868b]">
            <p>Copyright © {new Date().getFullYear()} BLive. All rights reserved.</p>
            <div className="flex items-center gap-6">
              <button onClick={() => scrollTo('features')} className="hover:text-[#f5f5f7] transition-colors">Features</button>
              <button onClick={() => scrollTo('how-it-works')} className="hover:text-[#f5f5f7] transition-colors">How It Works</button>
              <Link to="/login" className="hover:text-[#f5f5f7] transition-colors">Sign In</Link>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
