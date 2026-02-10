import { useState, useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import { motion, useInView } from 'framer-motion';

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
  { feature: 'Adaptive TDEE', free: '-', premium: 'MacroFactor-grade' },
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

// Competitor data for "Why FitWiz"
const competitors = [
  {
    name: 'Hevy',
    price: '$3.99/mo',
    yearlyPrice: '$23.99/yr',
    focus: 'Workout Tracking',
    limitations: ['No nutrition tracking', 'No fasting', 'No AI coaching', 'Limited free exercises (400+)'],
    color: 'from-blue-500 to-blue-600',
  },
  {
    name: 'MyFitnessPal',
    price: '$19.99/mo',
    yearlyPrice: '$79.99/yr',
    focus: 'Calorie Counting',
    limitations: ['No workout generation', 'No AI coach', 'No fasting', 'Barcode scanner now paid', 'Ads on free tier'],
    color: 'from-sky-500 to-sky-600',
  },
  {
    name: 'MacroFactor',
    price: '$11.99/mo',
    yearlyPrice: '$71.99/yr',
    focus: 'Adaptive Nutrition',
    limitations: ['No free tier at all', 'No workouts', 'No fasting', 'No AI chat', 'No social features'],
    color: 'from-violet-500 to-violet-600',
  },
  {
    name: 'Gravl',
    price: '$10.99/mo',
    yearlyPrice: '$59.99/yr',
    focus: 'AI Workouts',
    limitations: ['Only 3 free workouts', 'No nutrition tracking', 'No fasting', 'Limited exercise library (300+)', 'No social features'],
    color: 'from-rose-500 to-rose-600',
  },
];

const whyFitwizFeatures = [
  { category: 'AI Workout Generation', fitwiz: true, hevy: false, mfp: false, macrofactor: false, gravl: true },
  { category: 'Nutrition Tracking', fitwiz: true, hevy: false, mfp: true, macrofactor: true, gravl: false },
  { category: 'Intermittent Fasting', fitwiz: true, hevy: false, mfp: false, macrofactor: false, gravl: false },
  { category: 'AI Coach (5 agents)', fitwiz: true, hevy: false, mfp: false, macrofactor: false, gravl: false },
  { category: 'Workout Logging', fitwiz: true, hevy: true, mfp: false, macrofactor: false, gravl: true },
  { category: 'Adaptive TDEE', fitwiz: true, hevy: false, mfp: false, macrofactor: true, gravl: false },
  { category: 'Habit Tracking', fitwiz: true, hevy: false, mfp: false, macrofactor: false, gravl: false },
  { category: 'Hormonal Health', fitwiz: true, hevy: false, mfp: false, macrofactor: false, gravl: false },
  { category: 'Free Barcode Scanner', fitwiz: true, hevy: false, mfp: false, macrofactor: false, gravl: false },
  { category: 'No Ads (Free Tier)', fitwiz: true, hevy: true, mfp: false, macrofactor: false, gravl: true },
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
    question: 'Why is FitWiz so much cheaper than competitors?',
    answer: "We believe premium fitness coaching shouldn't cost $20/month. By leveraging cutting-edge AI efficiently, we deliver more features at a fraction of the cost. FitWiz Premium at $5.99/mo gives you workouts + nutrition + fasting + AI coaching, while competitors charge $10-20/mo for just one of those.",
  },
];

const CheckIcon = () => (
  <svg className="w-4 h-4 text-emerald-400 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
  </svg>
);

const XIcon = () => (
  <svg className="w-4 h-4 text-white/20 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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
    <div className="min-h-screen bg-black text-white">
      {/* Navigation */}
      <nav className="fixed top-0 left-0 right-0 z-50 bg-black/80 backdrop-blur-xl backdrop-saturate-150 border-b border-white/[0.04]">
        <div className="max-w-[1200px] mx-auto px-6 lg:px-4">
          <div className="flex items-center justify-between h-12">
            <Link to="/" className="text-[21px] font-semibold tracking-[-0.01em] text-white/90 hover:text-white transition-colors">
              FitWiz
            </Link>

            <div className="hidden md:flex items-center gap-7">
              <Link to="/" className="text-xs text-white/80 hover:text-white transition-colors">
                Home
              </Link>
              <Link to="/features" className="text-xs text-white/80 hover:text-white transition-colors">
                Features
              </Link>
              <Link to="/pricing" className="text-xs text-emerald-400 transition-colors">
                Pricing
              </Link>
              <Link to="/store" className="text-xs text-white/80 hover:text-white transition-colors">
                Store
              </Link>
              <Link to="/login" className="text-xs text-white/80 hover:text-white transition-colors">
                Sign In
              </Link>
              <Link to="/login" className="text-xs px-4 py-1.5 bg-emerald-500 text-white rounded-full hover:bg-emerald-400 transition-colors">
                Get Started
              </Link>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="pt-24 pb-12 px-6">
        <div className="max-w-[980px] mx-auto text-center">
          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-[40px] sm:text-[56px] font-semibold tracking-[-0.02em] mb-4"
          >
            Simple, transparent pricing
          </motion.h1>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="text-[17px] sm:text-[21px] text-[#86868b] max-w-[600px] mx-auto mb-8"
          >
            Start free, upgrade when you're ready. No hidden fees.
          </motion.p>

          {/* Billing Toggle */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="inline-flex items-center p-1 rounded-full bg-[#1d1d1f] border border-white/10"
          >
            <button
              onClick={() => setIsYearly(false)}
              className={`px-6 py-2 rounded-full text-sm font-medium transition-all ${
                !isYearly
                  ? 'bg-emerald-500 text-white'
                  : 'text-white/60 hover:text-white'
              }`}
            >
              Monthly
            </button>
            <button
              onClick={() => setIsYearly(true)}
              className={`px-6 py-2 rounded-full text-sm font-medium transition-all flex items-center gap-2 ${
                isYearly
                  ? 'bg-emerald-500 text-white'
                  : 'text-white/60 hover:text-white'
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
                  ? 'bg-gradient-to-br from-emerald-900/50 to-green-900/30 border-emerald-500/50 md:scale-105'
                  : 'bg-[#1d1d1f] border-white/[0.05] hover:border-white/10'
              }`}
            >
              {plan.badge && (
                <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-1 text-[10px] font-semibold rounded-full bg-emerald-500 text-white">
                  {plan.badge}
                </div>
              )}

              <h3 className="text-[24px] font-semibold text-white mb-1">{plan.name}</h3>
              <p className="text-[14px] text-[#86868b] mb-5">{plan.description}</p>

              <div className="mb-6">
                <div className="flex items-baseline gap-1">
                  <span className="text-[48px] font-bold text-white">
                    {isYearly ? plan.yearlyPrice : plan.monthlyPrice}
                  </span>
                  <span className="text-[15px] text-[#86868b]">/mo</span>
                </div>
                {isYearly && plan.yearlyTotal !== '$0' && (
                  <p className="text-[13px] text-[#86868b]">
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
                    : 'bg-[#2d2d2f] text-white hover:bg-[#3d3d3f]'
                }`}
              >
                {plan.cta}
              </Link>

              <ul className="space-y-3">
                {plan.features.map((feature, i) => (
                  <li key={i} className={`flex items-start gap-2 text-[13px] ${
                    feature.startsWith('Everything') ? 'text-emerald-400 font-medium' : 'text-[#86868b]'
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
      <section className="px-6 py-20 bg-[#0a0a0a]">
        <div className="max-w-[800px] mx-auto">
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-[32px] sm:text-[40px] font-semibold tracking-[-0.02em] text-center mb-12"
          >
            Compare plans
          </motion.h2>

          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-white/10">
                  <th className="text-left py-4 px-4 text-[15px] font-semibold text-white">Feature</th>
                  <th className="text-center py-4 px-4 text-[15px] font-semibold text-white w-[140px]">Free</th>
                  <th className="text-center py-4 px-4 text-[15px] font-semibold text-emerald-400 w-[180px]">Premium</th>
                </tr>
              </thead>
              <tbody>
                {comparisonFeatures.map((row, index) => (
                  <tr key={index} className="border-b border-white/5">
                    <td className="py-4 px-4 text-[14px] text-white">{row.feature}</td>
                    <td className="py-4 px-4 text-center text-[14px] text-[#86868b]">
                      {row.free === '-' ? <XIcon /> : row.free === 'Yes' ? <CheckIcon /> : row.free}
                    </td>
                    <td className="py-4 px-4 text-center text-[14px] text-white bg-emerald-500/5">
                      {row.premium === 'Yes' ? <CheckIcon /> : row.premium}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      {/* Why FitWiz - Competitor Comparison Section */}
      <section className="px-6 py-20">
        <div className="max-w-[1100px] mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <h2 className="text-[32px] sm:text-[48px] font-semibold tracking-[-0.02em] mb-4">
              <span className="bg-gradient-to-r from-emerald-400 via-green-400 to-lime-400 bg-clip-text text-transparent">
                Why FitWiz?
              </span>
            </h2>
            <p className="text-[17px] sm:text-[21px] text-[#86868b] max-w-[600px] mx-auto">
              The only app that combines workouts + nutrition + fasting + AI coaching.
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
            <div className="text-center p-6 rounded-2xl bg-[#1d1d1f] border border-white/[0.05]">
              <div className="text-[36px] sm:text-[48px] font-bold bg-gradient-to-r from-emerald-400 to-green-400 bg-clip-text text-transparent leading-none mb-1">
                {exerciseCount}+
              </div>
              <div className="text-[13px] text-[#86868b]">Exercises</div>
            </div>
            <div className="text-center p-6 rounded-2xl bg-[#1d1d1f] border border-white/[0.05]">
              <div className="text-[36px] sm:text-[48px] font-bold bg-gradient-to-r from-emerald-400 to-green-400 bg-clip-text text-transparent leading-none mb-1">
                {agentCount}
              </div>
              <div className="text-[13px] text-[#86868b]">AI Agents</div>
            </div>
            <div className="text-center p-6 rounded-2xl bg-[#1d1d1f] border border-white/[0.05]">
              <div className="text-[36px] sm:text-[48px] font-bold bg-gradient-to-r from-emerald-400 to-green-400 bg-clip-text text-transparent leading-none mb-1">
                {featureCount}+
              </div>
              <div className="text-[13px] text-[#86868b]">Features</div>
            </div>
          </motion.div>

          {/* Price Comparison Banner */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="mb-16 p-6 sm:p-8 rounded-3xl bg-gradient-to-r from-emerald-900/40 via-green-900/30 to-lime-900/20 border border-emerald-500/20"
          >
            <h3 className="text-[21px] font-semibold text-center mb-6">
              Premium pricing compared
            </h3>
            <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
              {[
                { name: 'FitWiz', price: '$5.99', highlight: true },
                { name: 'Hevy Pro', price: '$3.99', highlight: false },
                { name: 'Gravl', price: '$10.99', highlight: false },
                { name: 'MacroFactor', price: '$11.99', highlight: false },
                { name: 'MFP', price: '$19.99', highlight: false },
              ].map((app) => (
                <div
                  key={app.name}
                  className={`text-center p-4 rounded-2xl transition-all ${
                    app.highlight
                      ? 'bg-emerald-500/20 border-2 border-emerald-500/50 ring-2 ring-emerald-500/20'
                      : 'bg-white/5 border border-white/10'
                  }`}
                >
                  <div className={`text-[13px] font-medium mb-1 ${app.highlight ? 'text-emerald-400' : 'text-[#86868b]'}`}>
                    {app.name}
                  </div>
                  <div className={`text-[24px] sm:text-[28px] font-bold ${app.highlight ? 'text-white' : 'text-white/60'}`}>
                    {app.price}
                  </div>
                  <div className="text-[11px] text-[#86868b]">/month</div>
                </div>
              ))}
            </div>
            <p className="text-center text-[14px] text-emerald-400 mt-6 font-medium">
              FitWiz gives you 10x the features at 60% less cost than MFP
            </p>
          </motion.div>

          {/* Competitor Cards */}
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="grid grid-cols-1 sm:grid-cols-2 gap-5 mb-16"
          >
            {competitors.map((comp) => (
              <motion.div
                key={comp.name}
                variants={fadeUp}
                className="p-6 rounded-2xl bg-[#1d1d1f] border border-white/[0.05] hover:border-white/10 transition-all"
              >
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <h4 className="text-[17px] font-semibold text-white">{comp.name}</h4>
                    <p className="text-[13px] text-[#86868b]">{comp.focus}</p>
                  </div>
                  <div className="text-right">
                    <div className="text-[17px] font-bold text-white/60">{comp.price}</div>
                    <div className="text-[11px] text-[#86868b]">{comp.yearlyPrice}</div>
                  </div>
                </div>
                <div className="space-y-2">
                  <p className="text-[11px] text-white/40 uppercase tracking-wider">What it's missing</p>
                  {comp.limitations.map((limit, i) => (
                    <div key={i} className="flex items-center gap-2 text-[13px] text-[#86868b]">
                      <XIcon />
                      {limit}
                    </div>
                  ))}
                </div>
              </motion.div>
            ))}
          </motion.div>

          {/* Feature Matrix */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
          >
            <h3 className="text-[24px] font-semibold text-center mb-8">
              FitWiz vs the competition
            </h3>
            <div className="overflow-x-auto">
              <table className="w-full min-w-[600px]">
                <thead>
                  <tr className="border-b border-white/10">
                    <th className="text-left py-3 px-3 text-[13px] font-semibold text-white">Feature</th>
                    <th className="text-center py-3 px-3 text-[13px] font-semibold text-emerald-400">FitWiz</th>
                    <th className="text-center py-3 px-3 text-[13px] font-semibold text-white/60">Hevy</th>
                    <th className="text-center py-3 px-3 text-[13px] font-semibold text-white/60">MFP</th>
                    <th className="text-center py-3 px-3 text-[13px] font-semibold text-white/60">MacroFactor</th>
                    <th className="text-center py-3 px-3 text-[13px] font-semibold text-white/60">Gravl</th>
                  </tr>
                </thead>
                <tbody>
                  {whyFitwizFeatures.map((row, index) => (
                    <tr key={index} className="border-b border-white/5">
                      <td className="py-3 px-3 text-[13px] text-white">{row.category}</td>
                      <td className="py-3 px-3 text-center bg-emerald-500/5">
                        {row.fitwiz ? <span className="inline-flex justify-center"><CheckIcon /></span> : <span className="inline-flex justify-center"><XIcon /></span>}
                      </td>
                      <td className="py-3 px-3 text-center">
                        {row.hevy ? <span className="inline-flex justify-center"><CheckIcon /></span> : <span className="inline-flex justify-center"><XIcon /></span>}
                      </td>
                      <td className="py-3 px-3 text-center">
                        {row.mfp ? <span className="inline-flex justify-center"><CheckIcon /></span> : <span className="inline-flex justify-center"><XIcon /></span>}
                      </td>
                      <td className="py-3 px-3 text-center">
                        {row.macrofactor ? <span className="inline-flex justify-center"><CheckIcon /></span> : <span className="inline-flex justify-center"><XIcon /></span>}
                      </td>
                      <td className="py-3 px-3 text-center">
                        {row.gravl ? <span className="inline-flex justify-center"><CheckIcon /></span> : <span className="inline-flex justify-center"><XIcon /></span>}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Why It Costs This Much Section */}
      <section className="px-6 py-20 bg-[#0a0a0a]">
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
            <h2 className="text-[32px] sm:text-[40px] font-semibold tracking-[-0.02em] mb-4">
              Why does it cost this much?
            </h2>
            <p className="text-[17px] text-[#86868b] max-w-[600px] mx-auto">
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
              <div key={i} className="p-5 rounded-2xl bg-[#1d1d1f] border border-white/[0.05]">
                <span className="text-2xl mb-3 block">{item.icon}</span>
                <h3 className="text-[15px] font-semibold text-white mb-1">{item.title}</h3>
                <p className="text-[13px] text-[#86868b]">{item.desc}</p>
              </div>
            ))}
          </motion.div>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.2 }}
            className="text-center text-[15px] text-[#86868b] mt-8"
          >
            Competitors charge $10-20/month for a single feature. We deliver everything at $5.99.
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
                className="rounded-2xl bg-[#1d1d1f] border border-white/[0.05] overflow-hidden"
              >
                <button
                  onClick={() => setExpandedFaq(expandedFaq === index ? null : index)}
                  className="w-full flex items-center justify-between p-6 text-left"
                >
                  <span className="text-[17px] font-medium text-white">{faq.question}</span>
                  <svg
                    className={`w-5 h-5 text-white/60 transition-transform ${expandedFaq === index ? 'rotate-180' : ''}`}
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                  </svg>
                </button>
                {expandedFaq === index && (
                  <div className="px-6 pb-6">
                    <p className="text-[15px] text-[#86868b] leading-relaxed">{faq.answer}</p>
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
          <h2 className="text-[32px] sm:text-[40px] font-semibold tracking-[-0.02em] mb-4">
            Ready to transform your fitness?
          </h2>
          <p className="text-[17px] text-[#86868b] mb-8">
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
      <footer className="py-8 px-6 border-t border-[#424245]">
        <div className="max-w-[1200px] mx-auto">
          <div className="flex flex-col gap-6">
            <div className="flex flex-col sm:flex-row items-center justify-between gap-4 text-[12px] text-[#86868b]">
              <p>Copyright {new Date().getFullYear()} FitWiz. All rights reserved.</p>
              <div className="flex items-center gap-6">
                <Link to="/" className="hover:text-[#f5f5f7] transition-colors">Home</Link>
                <Link to="/features" className="hover:text-[#f5f5f7] transition-colors">Features</Link>
                <Link to="/pricing" className="hover:text-[#f5f5f7] transition-colors">Pricing</Link>
                <Link to="/store" className="hover:text-[#f5f5f7] transition-colors">Store</Link>
                <Link to="/login" className="hover:text-[#f5f5f7] transition-colors">Sign In</Link>
              </div>
            </div>
            <div className="flex items-center justify-center gap-6 text-[11px] text-[#6e6e73]">
              <Link to="/terms" className="hover:text-[#86868b] transition-colors">Terms of Service</Link>
              <span>•</span>
              <Link to="/privacy" className="hover:text-[#86868b] transition-colors">Privacy Policy</Link>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
