import { useState, useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import { motion, useInView } from 'framer-motion';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';

const fadeUp = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.5 } },
};

const stagger = {
  visible: { transition: { staggerChildren: 0.1 } },
};

// Animated counter hook
function useCounter(target: number, duration: number = 2000, shouldStart: boolean = false) {
  const [count, setCount] = useState(0);
  useEffect(() => {
    if (!shouldStart) return;
    let startTime: number | null = null;
    let frame: number;
    const animate = (ts: number) => {
      if (!startTime) startTime = ts;
      const progress = Math.min((ts - startTime) / duration, 1);
      const ease = 1 - Math.pow(1 - progress, 3);
      setCount(Math.floor(ease * target));
      if (progress < 1) frame = requestAnimationFrame(animate);
    };
    frame = requestAnimationFrame(animate);
    return () => cancelAnimationFrame(frame);
  }, [target, duration, shouldStart]);
  return count;
}

interface PricingPlan {
  name: string;
  description: string;
  monthlyPrice: string;
  yearlyPrice: string;
  yearlyTotal: string;
  savings?: string;
  features: string[];
  highlight?: boolean;
  badge?: string;
  cta: string;
}

const plans: PricingPlan[] = [
  {
    name: 'Free',
    description: 'Everything you need to get started',
    monthlyPrice: '$0',
    yearlyPrice: '$0',
    yearlyTotal: '$0',
    features: [
      '1,722 exercises with video demos',
      'Unlimited workout logging',
      'Manual food logging & barcode scanner',
      'Fasting timer (3 protocols)',
      'Habit tracking & streaks',
      'Progress photos & 15 body measurements',
      'Social feed, leaderboards & challenges',
      '5 AI chat messages/day',
      'Achievement badges & XP system',
      'Apple Health & Google Fit sync',
      'No ads, ever',
    ],
    cta: 'Get Started Free',
  },
  {
    name: 'Premium',
    description: 'Full AI-powered fitness & nutrition',
    monthlyPrice: '$5.99',
    yearlyPrice: '$4.00',
    yearlyTotal: '$47.99',
    savings: 'Save 33%',
    features: [
      'Everything in Free, plus:',
      'Unlimited AI chat (5 specialist agents)',
      'AI workout generation (monthly/weekly/quick)',
      'AI photo food logging (Vision)',
      'Adaptive TDEE & smart weight suggestions',
      'All 10 fasting protocols + AI insights',
      'Advanced charts (all-time history)',
      'Muscle group heatmap & balance analysis',
      'Skill progressions (7 chains, 52+ exercises)',
      'Hormonal health & diabetes tracking',
      'Voice guidance & coach personas',
      'Priority support',
    ],
    highlight: true,
    badge: 'Most Popular',
    cta: 'Start 7-Day Free Trial',
  },
];

const comparisonFeatures = [
  { feature: 'Exercise Library', free: '1,722 with videos', premium: '1,722 with videos' },
  { feature: 'Workout Logging', free: 'Unlimited', premium: 'Unlimited' },
  { feature: 'AI Chat Messages', free: '5/day', premium: 'Unlimited' },
  { feature: 'AI Workout Generation', free: '-', premium: 'Monthly/Weekly/Quick' },
  { feature: 'AI Food Photo Scanning', free: '-', premium: 'Yes (Gemini Vision)' },
  { feature: 'Manual Food Logging', free: 'Yes', premium: 'Yes' },
  { feature: 'Barcode Scanner', free: 'Yes', premium: 'Yes' },
  { feature: 'Macro Tracking', free: 'Full (P/C/F)', premium: 'Full + Micronutrients' },
  { feature: 'Adaptive TDEE', free: '-', premium: 'Research-grade' },
  { feature: 'Fasting Protocols', free: '3 (16:8, 18:6, 20:4)', premium: 'All 10 + Custom' },
  { feature: 'Charts & Analytics', free: '3-month history', premium: 'All-time history' },
  { feature: 'Muscle Heatmap', free: '-', premium: 'Yes' },
  { feature: 'Skill Progressions', free: '-', premium: '7 chains (52+ exercises)' },
  { feature: 'Coach Personas', free: '-', premium: '5+ personalities' },
  { feature: 'Voice Guidance (TTS)', free: '-', premium: 'Yes' },
  { feature: 'Hormonal Health', free: '-', premium: 'Cycle-aware workouts' },
  { feature: 'Social Feed & Leaderboards', free: 'Yes', premium: 'Yes' },
  { feature: 'Ads', free: 'None', premium: 'None' },
];

// What FitWiz includes in one app
const fitwizIncludes = [
  { category: 'AI Workout Generation', icon: '🤖' },
  { category: 'Nutrition Tracking', icon: '🥗' },
  { category: 'Intermittent Fasting', icon: '⏱️' },
  { category: 'AI Coach (5 agents)', icon: '💬' },
  { category: 'Workout Logging', icon: '📋' },
  { category: 'Adaptive TDEE', icon: '📊' },
  { category: 'Habit Tracking', icon: '✅' },
  { category: 'Hormonal Health', icon: '🧬' },
  { category: 'Free Barcode Scanner', icon: '📷' },
  { category: 'No Ads (Free Tier)', icon: '🚫' },
];

const faqs = [
  {
    question: 'Is there really a free plan?',
    answer: 'Yes! The Free plan gives you unlimited workout logging, 1,722 exercises with videos, manual food logging with barcode scanner, fasting timer, habit tracking, social features, and 5 AI chat messages daily. No credit card required.',
  },
  {
    question: 'How does the 7-day free trial work?',
    answer: 'You get full access to all Premium features for 7 days. After the trial, you can choose to subscribe or continue with the Free plan. No payment required to start.',
  },
  {
    question: 'Can I cancel anytime?',
    answer: "Yes, you can cancel your subscription anytime through the app or your device's subscription settings. You'll keep access until the end of your billing period.",
  },
  {
    question: 'What payment methods do you accept?',
    answer: 'We accept all major payment methods through the App Store (iOS) and Google Play (Android), including credit cards, debit cards, and digital wallets.',
  },
  {
    question: 'Can I upgrade or downgrade my plan?',
    answer: 'Yes, you can change your plan anytime. When upgrading, you get immediate access to new features. When downgrading, the change takes effect at the end of your billing period.',
  },
  {
    question: 'How can FitWiz offer so much for $5.99/month?',
    answer: "We believe premium fitness coaching shouldn't cost $20/month. By leveraging cutting-edge AI efficiently, we deliver workouts + nutrition + fasting + AI coaching all in one app at a price that's accessible to everyone.",
  },
];

const CheckIcon = () => (
  <svg className="w-4 h-4 text-emerald-400 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
  </svg>
);

const XIcon = () => (
  <svg className="w-4 h-4 text-[var(--color-text-muted)] flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
  </svg>
);

export default function Pricing() {
  const [isYearly, setIsYearly] = useState(true);
  const [expandedFaq, setExpandedFaq] = useState<number | null>(null);

  const statsRef = useRef<HTMLDivElement>(null);
  const statsInView = useInView(statsRef, { once: true, margin: '-100px' });

  const exerciseCount = useCounter(1722, 2000, statsInView);
  const agentCount = useCounter(5, 1500, statsInView);
  const featureCount = useCounter(1000, 2000, statsInView);

  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)]">
      {/* Navigation */}
      <MarketingNav />

      {/* Hero Section */}
      <section className="pt-28 pb-12 px-6">
        <div className="max-w-[980px] mx-auto text-center">
          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-[40px] sm:text-[56px] font-semibold tracking-[-0.02em] mb-4"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Simple, transparent pricing
          </motion.h1>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="text-[17px] sm:text-[21px] text-[var(--color-text-secondary)] max-w-[600px] mx-auto mb-8"
          >
            Start free, upgrade when you're ready. No hidden fees.
          </motion.p>

          {/* Billing Toggle */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="inline-flex items-center p-1 rounded-full bg-[var(--color-surface-muted)] border border-[var(--color-border)]"
          >
            <button
              onClick={() => setIsYearly(false)}
              className={`px-6 py-2 rounded-full text-sm font-medium transition-all ${
                !isYearly
                  ? 'bg-emerald-500 text-white'
                  : 'text-[var(--color-text-secondary)] hover:text-[var(--color-text)]'
              }`}
            >
              Monthly
            </button>
            <button
              onClick={() => setIsYearly(true)}
              className={`px-6 py-2 rounded-full text-sm font-medium transition-all flex items-center gap-2 ${
                isYearly
                  ? 'bg-emerald-500 text-white'
                  : 'text-[var(--color-text-secondary)] hover:text-[var(--color-text)]'
              }`}
            >
              Yearly
              <span className="px-2 py-0.5 text-[10px] bg-lime-400 text-black rounded-full font-semibold">
                SAVE 33%
              </span>
            </button>
          </motion.div>
        </div>
      </section>

      {/* Pricing Cards */}
      <section className="px-6 pb-20">
        <motion.div
          initial="hidden"
          animate="visible"
          variants={stagger}
          className="max-w-[800px] mx-auto grid grid-cols-1 md:grid-cols-2 gap-6"
        >
          {plans.map((plan) => (
            <motion.div
              key={plan.name}
              variants={fadeUp}
              className={`relative p-8 rounded-3xl border transition-all ${
                plan.highlight
                  ? 'bg-[var(--color-surface)] border-2 border-emerald-500/50 md:scale-105'
                  : 'bg-[var(--color-surface)] border-[var(--color-border)] hover:border-[var(--color-border)]'
              }`}
            >
              {plan.badge && (
                <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-1 text-[10px] font-semibold rounded-full bg-emerald-500 text-white">
                  {plan.badge}
                </div>
              )}

              <h3 className="text-[24px] font-semibold text-[var(--color-text)] mb-1">{plan.name}</h3>
              <p className="text-[14px] text-[var(--color-text-secondary)] mb-5">{plan.description}</p>

              <div className="mb-6">
                <div className="flex items-baseline gap-1">
                  <span className="text-[48px] font-bold text-[var(--color-text)]">
                    {isYearly ? plan.yearlyPrice : plan.monthlyPrice}
                  </span>
                  <span className="text-[15px] text-[var(--color-text-secondary)]">/mo</span>
                </div>
                {isYearly && plan.yearlyTotal !== '$0' && (
                  <p className="text-[13px] text-[var(--color-text-secondary)]">
                    {plan.yearlyTotal}/year
                    {plan.savings && (
                      <span className="ml-2 text-emerald-400">{plan.savings}</span>
                    )}
                  </p>
                )}
              </div>

              <Link
                to="/login"
                className={`block w-full py-3.5 rounded-xl text-center text-[15px] font-medium transition-colors mb-6 ${
                  plan.highlight
                    ? 'bg-emerald-500 text-white hover:bg-emerald-400'
                    : 'bg-[var(--color-surface-elevated)] text-[var(--color-text)] hover:bg-[var(--color-surface-elevated)]'
                }`}
              >
                {plan.cta}
              </Link>

              <ul className="space-y-3">
                {plan.features.map((feature, i) => (
                  <li key={i} className={`flex items-start gap-2 text-[13px] ${
                    feature.startsWith('Everything') ? 'text-emerald-400 font-medium' : 'text-[var(--color-text-secondary)]'
                  }`}>
                    <CheckIcon />
                    {feature}
                  </li>
                ))}
              </ul>
            </motion.div>
          ))}
        </motion.div>
      </section>

      {/* Feature Comparison Table */}
      <section className="px-6 py-20 bg-[var(--color-surface-muted)]">
        <div className="max-w-[800px] mx-auto">
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-[32px] sm:text-[40px] font-semibold tracking-[-0.02em] text-center mb-12"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Compare plans
          </motion.h2>

          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[var(--color-border)]">
                  <th className="text-left py-4 px-4 text-[15px] font-semibold text-[var(--color-text)]">Feature</th>
                  <th className="text-center py-4 px-4 text-[15px] font-semibold text-[var(--color-text)] w-[140px]">Free</th>
                  <th className="text-center py-4 px-4 text-[15px] font-semibold text-emerald-400 w-[180px]">Premium</th>
                </tr>
              </thead>
              <tbody>
                {comparisonFeatures.map((row, index) => (
                  <tr key={index} className="border-b border-[var(--color-border)]">
                    <td className="py-4 px-4 text-[14px] text-[var(--color-text)]">{row.feature}</td>
                    <td className="py-4 px-4 text-center text-[14px] text-[var(--color-text-secondary)]">
                      {row.free === '-' ? <XIcon /> : row.free === 'Yes' ? <CheckIcon /> : row.free}
                    </td>
                    <td className="py-4 px-4 text-center text-[14px] text-[var(--color-text)] bg-emerald-500/5">
                      {row.premium === 'Yes' ? <CheckIcon /> : row.premium}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      {/* Why FitWiz - Before & After Section */}
      <section className="px-6 py-20">
        <div className="max-w-[1100px] mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <h2
              className="text-[32px] sm:text-[48px] font-semibold tracking-[-0.02em] mb-4"
              style={{ fontFamily: 'var(--font-heading)' }}
            >
              <span className="bg-gradient-to-r from-emerald-400 via-green-400 to-lime-400 bg-clip-text text-transparent">
                Before & After FitWiz
              </span>
            </h2>
            <p className="text-[17px] sm:text-[21px] text-[var(--color-text-secondary)] max-w-[600px] mx-auto">
              Stop juggling multiple apps. Get everything in one place.
            </p>
          </motion.div>

          {/* Animated Stats */}
          <motion.div
            ref={statsRef}
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="grid grid-cols-3 gap-6 mb-16 max-w-[700px] mx-auto"
          >
            <div className="text-center p-6 rounded-2xl bg-[var(--color-surface)] border border-[var(--color-border)]">
              <div className="text-[36px] sm:text-[48px] font-bold bg-gradient-to-r from-emerald-400 to-green-400 bg-clip-text text-transparent leading-none mb-1">
                {exerciseCount}+
              </div>
              <div className="text-[13px] text-[var(--color-text-secondary)]">Exercises</div>
            </div>
            <div className="text-center p-6 rounded-2xl bg-[var(--color-surface)] border border-[var(--color-border)]">
              <div className="text-[36px] sm:text-[48px] font-bold bg-gradient-to-r from-emerald-400 to-green-400 bg-clip-text text-transparent leading-none mb-1">
                {agentCount}
              </div>
              <div className="text-[13px] text-[var(--color-text-secondary)]">AI Agents</div>
            </div>
            <div className="text-center p-6 rounded-2xl bg-[var(--color-surface)] border border-[var(--color-border)]">
              <div className="text-[36px] sm:text-[48px] font-bold bg-gradient-to-r from-emerald-400 to-green-400 bg-clip-text text-transparent leading-none mb-1">
                {featureCount}+
              </div>
              <div className="text-[13px] text-[var(--color-text-secondary)]">Features</div>
            </div>
          </motion.div>

          {/* Before / After Cards */}
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-16"
          >
            {/* Before */}
            <motion.div variants={fadeUp} className="p-6 sm:p-8 rounded-3xl bg-[var(--color-surface)] border border-[var(--color-border)]">
              <div className="flex items-center gap-3 mb-6">
                <div className="w-10 h-10 rounded-full bg-[var(--color-surface-muted)] flex items-center justify-center">
                  <svg className="w-5 h-5 text-[var(--color-text-muted)]" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </div>
                <h3 className="text-[21px] font-semibold text-[var(--color-text-secondary)]">Before FitWiz</h3>
              </div>
              <div className="space-y-3">
                {[
                  'One app for workouts, another for nutrition, another for fasting',
                  'Generic programs that ignore your injuries and equipment',
                  'Paying $15-20/month and still not getting AI coaching',
                  'No idea if you\'re actually progressing',
                  'Googling exercises and hoping for the best',
                ].map((item, i) => (
                  <div key={i} className="flex items-start gap-3">
                    <XIcon />
                    <span className="text-[14px] text-[var(--color-text-secondary)]">{item}</span>
                  </div>
                ))}
              </div>
            </motion.div>

            {/* After */}
            <motion.div variants={fadeUp} className="p-6 sm:p-8 rounded-3xl bg-gradient-to-br from-emerald-900/40 to-green-900/20 border border-emerald-500/20">
              <div className="flex items-center gap-3 mb-6">
                <div className="w-10 h-10 rounded-full bg-emerald-500/20 flex items-center justify-center">
                  <svg className="w-5 h-5 text-emerald-400" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                </div>
                <h3 className="text-[21px] font-semibold text-emerald-400">After FitWiz</h3>
              </div>
              <div className="space-y-3">
                {[
                  'Workouts + nutrition + fasting + coaching in one $5.99/mo app',
                  'AI generates plans around your goals, equipment, and injuries',
                  '5 specialist AI agents for coaching, nutrition, and recovery',
                  'Track every rep and see clear progress analytics',
                  '1,722 exercises with video demos and smart alternatives',
                ].map((item, i) => (
                  <div key={i} className="flex items-start gap-3">
                    <CheckIcon />
                    <span className="text-[14px] text-[var(--color-text)]">{item}</span>
                  </div>
                ))}
              </div>
            </motion.div>
          </motion.div>

          {/* Everything Included Grid */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
          >
            <h3 className="text-[24px] font-semibold text-center mb-8">
              Everything included with FitWiz
            </h3>
            <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
              {fitwizIncludes.map((feature, index) => (
                <div
                  key={index}
                  className="text-center p-4 rounded-2xl bg-[var(--color-surface)] border border-[var(--color-border)] hover:border-emerald-500/30 transition-colors"
                >
                  <span className="text-2xl block mb-2">{feature.icon}</span>
                  <div className="text-[12px] sm:text-[13px] text-[var(--color-text)] font-medium">{feature.category}</div>
                </div>
              ))}
            </div>
          </motion.div>
        </div>
      </section>

      {/* Why It Costs This Much Section */}
      <section className="px-6 py-20 bg-[var(--color-surface-muted)]">
        <div className="max-w-[800px] mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-center mb-8"
          >
            <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-emerald-500/10 mb-6">
              <svg className="w-8 h-8 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <h2
              className="text-[32px] sm:text-[40px] font-semibold tracking-[-0.02em] mb-4"
              style={{ fontFamily: 'var(--font-heading)' }}
            >
              Why does it cost this much?
            </h2>
            <p className="text-[17px] text-[var(--color-text-secondary)] max-w-[600px] mx-auto">
              Transparency matters to us. Here's where your subscription goes.
            </p>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="grid grid-cols-1 sm:grid-cols-2 gap-4"
          >
            {[
              { icon: '🤖', title: 'AI Infrastructure', desc: 'Gemini-powered workout generation, nutrition analysis, and real-time coaching with 5 specialist agents' },
              { icon: '☁️', title: 'Cloud Servers', desc: 'Fast, reliable servers running 24/7 to sync your data, workouts, and chat history' },
              { icon: '📱', title: 'App Development', desc: 'Continuous updates, bug fixes, and new features based on your feedback' },
              { icon: '💪', title: 'Exercise Library', desc: '1,722 exercises with video demos, instructions, and AI-powered alternatives' },
            ].map((item, i) => (
              <div key={i} className="p-5 rounded-2xl bg-[var(--color-surface)] border border-[var(--color-border)]">
                <span className="text-2xl mb-3 block">{item.icon}</span>
                <h3 className="text-[15px] font-semibold text-[var(--color-text)] mb-1">{item.title}</h3>
                <p className="text-[13px] text-[var(--color-text-secondary)]">{item.desc}</p>
              </div>
            ))}
          </motion.div>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.2 }}
            className="text-center text-[15px] text-[var(--color-text-secondary)] mt-8"
          >
            Most fitness apps charge $10-20/month for a single feature. FitWiz delivers everything at $5.99.
          </motion.p>
        </div>
      </section>

      {/* FAQs */}
      <section className="px-6 py-20">
        <div className="max-w-[800px] mx-auto">
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-[32px] sm:text-[40px] font-semibold tracking-[-0.02em] text-center mb-12"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Frequently asked questions
          </motion.h2>

          <div className="space-y-4">
            {faqs.map((faq, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: index * 0.1 }}
                className="rounded-2xl bg-[var(--color-surface)] border border-[var(--color-border)] overflow-hidden"
              >
                <button
                  onClick={() => setExpandedFaq(expandedFaq === index ? null : index)}
                  className="w-full flex items-center justify-between p-6 text-left"
                >
                  <span className="text-[17px] font-medium text-[var(--color-text)]">{faq.question}</span>
                  <svg
                    className={`w-5 h-5 text-[var(--color-text-secondary)] transition-transform ${expandedFaq === index ? 'rotate-180' : ''}`}
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                  </svg>
                </button>
                {expandedFaq === index && (
                  <div className="px-6 pb-6">
                    <p className="text-[15px] text-[var(--color-text-secondary)] leading-relaxed">{faq.answer}</p>
                  </div>
                )}
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="px-6 py-20 bg-gradient-to-br from-emerald-900/30 to-green-900/20">
        <div className="max-w-[680px] mx-auto text-center">
          <h2
            className="text-[32px] sm:text-[40px] font-semibold tracking-[-0.02em] mb-4"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Ready to transform your fitness?
          </h2>
          <p className="text-[17px] text-[var(--color-text-secondary)] mb-8">
            Start free today. No credit card required.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link
              to="/login"
              className="px-8 py-3.5 bg-emerald-500 text-white text-[17px] rounded-full hover:bg-emerald-400 transition-colors"
            >
              Get started free
            </Link>
            <Link
              to="/features"
              className="px-8 py-3.5 text-emerald-400 text-[17px] hover:underline transition-all"
            >
              View all features
            </Link>
          </div>
        </div>
      </section>

      {/* Footer */}
      <MarketingFooter />
    </div>
  );
}
