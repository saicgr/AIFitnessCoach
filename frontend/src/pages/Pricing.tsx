import { useState } from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';

const fadeUp = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.5 } },
};

const stagger = {
  visible: { transition: { staggerChildren: 0.1 } },
};

interface PricingPlan {
  name: string;
  description: string;
  monthlyPrice: string;
  yearlyPrice: string;
  yearlyTotal: string;
  oneTimePrice?: string;
  savings?: string;
  features: string[];
  highlight?: boolean;
  badge?: string;
  cta: string;
}

const plans: PricingPlan[] = [
  {
    name: 'Free',
    description: 'Get started with essential features',
    monthlyPrice: '$0',
    yearlyPrice: '$0',
    yearlyTotal: '$0',
    features: [
      '5 AI chat messages/day',
      '1 workout generation/week',
      '1 food photo scan/day',
      'Basic stats (volume, duration)',
      'Streak tracking',
      '1700+ exercise library',
      'Senior Mode',
      '24-hour Demo Day access',
    ],
    cta: 'Get Started Free',
  },
  {
    name: 'Premium',
    description: 'For dedicated fitness enthusiasts',
    monthlyPrice: '$5.99',
    yearlyPrice: '$4.00',
    yearlyTotal: '$47.99',
    savings: 'Save 33%',
    features: [
      '30 AI chat messages/day',
      'Daily workout generation',
      '5 food photo scans/day',
      'Full macro tracking',
      '1RM & PR tracking',
      '5 favorite workouts',
      'Weekly summaries & trends',
      '90-day chat history',
      'Edit workouts in real-time',
      'No ads',
      'Email support',
    ],
    highlight: true,
    badge: 'Most Popular',
    cta: 'Start 7-Day Free Trial',
  },
  {
    name: 'Premium Plus',
    description: 'Maximum features for serious athletes',
    monthlyPrice: '$9.99',
    yearlyPrice: '$6.67',
    yearlyTotal: '$79.99',
    savings: 'Save 33%',
    features: [
      '100+ AI chat messages/day',
      'Unlimited workout generation',
      '10 food photo scans/day',
      'Restaurant menu help',
      'Strength standards',
      'Progressive overload suggestions',
      'Unlimited favorites',
      'Save as template',
      'Forever chat history',
      'Shareable workout links',
      'Friends & leaderboards',
      'Priority support',
    ],
    cta: 'Start 7-Day Free Trial',
  },
  {
    name: 'Lifetime',
    description: 'All Premium Plus features, pay once',
    monthlyPrice: '$99.99',
    yearlyPrice: '$99.99',
    yearlyTotal: '$99.99',
    oneTimePrice: '$99.99',
    features: [
      'All Premium Plus features forever',
      'No renewal charges',
      'Lifetime member tier recognition',
      'Estimated value display',
      'Never expires',
      'All future updates included',
    ],
    badge: 'Best Value',
    cta: 'Get Lifetime Access',
  },
];

const comparisonFeatures = [
  { feature: 'AI Chat Messages', free: '5/day', premium: '30/day', premiumPlus: '100+/day', lifetime: '100+/day' },
  { feature: 'Workout Generation', free: '1/week', premium: 'Daily', premiumPlus: 'Unlimited', lifetime: 'Unlimited' },
  { feature: 'Food Photo Scans', free: '1/day', premium: '5/day', premiumPlus: '10/day', lifetime: '10/day' },
  { feature: 'Chat History', free: '7 days', premium: '90 days', premiumPlus: 'Forever', lifetime: 'Forever' },
  { feature: 'Macro Tracking', free: 'Calories only', premium: 'Full', premiumPlus: 'Full', lifetime: 'Full' },
  { feature: 'PR Tracking', free: '-', premium: 'Yes', premiumPlus: 'Yes', lifetime: 'Yes' },
  { feature: 'Favorite Workouts', free: '-', premium: '5', premiumPlus: 'Unlimited', lifetime: 'Unlimited' },
  { feature: 'Edit Workouts', free: '-', premium: 'Yes', premiumPlus: 'Yes', lifetime: 'Yes' },
  { feature: 'Shareable Links', free: '-', premium: '-', premiumPlus: 'Yes', lifetime: 'Yes' },
  { feature: 'Leaderboards', free: '-', premium: '-', premiumPlus: 'Yes', lifetime: 'Yes' },
  { feature: 'Ads', free: 'Yes', premium: 'No', premiumPlus: 'No', lifetime: 'No' },
];

const faqs = [
  {
    question: 'Is there really a free plan?',
    answer: 'Yes! The Free plan gives you access to core features including 5 AI chat messages daily, weekly workout generation, the full 1700+ exercise library, and Senior Mode. No credit card required.',
  },
  {
    question: 'How does the 7-day free trial work?',
    answer: 'You get full access to Premium or Premium Plus features for 7 days, no payment required. After the trial, you can choose to subscribe or continue with the Free plan.',
  },
  {
    question: 'Can I cancel anytime?',
    answer: 'Yes, you can cancel your subscription anytime through the app or your device\'s subscription settings. You\'ll keep access until the end of your billing period.',
  },
  {
    question: 'What payment methods do you accept?',
    answer: 'We accept all major payment methods through the App Store (iOS) and Google Play (Android), including credit cards, debit cards, and digital wallets.',
  },
  {
    question: 'Is the Lifetime plan really forever?',
    answer: 'Yes! Once you purchase Lifetime, you have access to all Premium Plus features forever with no recurring charges. This includes all future updates and features.',
  },
  {
    question: 'Can I upgrade or downgrade my plan?',
    answer: 'Yes, you can change your plan anytime. When upgrading, you get immediate access to new features. When downgrading, the change takes effect at the end of your billing period.',
  },
  {
    question: 'Why does FitWiz cost what it does?',
    answer: 'Running advanced AI for personalized workouts, nutrition analysis, and real-time coaching requires significant infrastructure. Your subscription directly supports server costs, AI compute, and continuous improvements. We\'re also working on adding professional workout videos from real trainers. Unlike competitors charging $15-20/month, we keep prices affordable while delivering premium AI-powered fitness coaching.',
  },
];

export default function Pricing() {
  const [isYearly, setIsYearly] = useState(true);
  const [expandedFaq, setExpandedFaq] = useState<number | null>(null);

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
          className="max-w-[1200px] mx-auto grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6"
        >
          {plans.map((plan) => (
            <motion.div
              key={plan.name}
              variants={fadeUp}
              className={`relative p-6 rounded-3xl border transition-all ${
                plan.highlight
                  ? 'bg-gradient-to-br from-emerald-900/50 to-green-900/30 border-emerald-500/50 scale-105 lg:scale-110'
                  : 'bg-[#1d1d1f] border-white/[0.05] hover:border-white/10'
              }`}
            >
              {plan.badge && (
                <div className={`absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-1 text-[10px] font-semibold rounded-full ${
                  plan.highlight
                    ? 'bg-emerald-500 text-white'
                    : 'bg-lime-400 text-black'
                }`}>
                  {plan.badge}
                </div>
              )}

              <h3 className="text-[21px] font-semibold text-white mb-1">{plan.name}</h3>
              <p className="text-[13px] text-[#86868b] mb-4">{plan.description}</p>

              <div className="mb-6">
                {plan.oneTimePrice ? (
                  <div className="flex items-baseline gap-1">
                    <span className="text-[40px] font-bold text-white">{plan.oneTimePrice}</span>
                    <span className="text-[15px] text-[#86868b]">one-time</span>
                  </div>
                ) : (
                  <>
                    <div className="flex items-baseline gap-1">
                      <span className="text-[40px] font-bold text-white">
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
                  </>
                )}
              </div>

              <Link
                to="/login"
                className={`block w-full py-3 rounded-xl text-center text-[15px] font-medium transition-colors mb-6 ${
                  plan.highlight
                    ? 'bg-emerald-500 text-white hover:bg-emerald-400'
                    : 'bg-[#2d2d2f] text-white hover:bg-[#3d3d3f]'
                }`}
              >
                {plan.cta}
              </Link>

              <ul className="space-y-3">
                {plan.features.map((feature, i) => (
                  <li key={i} className="flex items-start gap-2 text-[13px] text-[#86868b]">
                    <svg className="w-4 h-4 text-emerald-400 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                    </svg>
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
        <div className="max-w-[1200px] mx-auto">
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-[32px] sm:text-[40px] font-semibold tracking-[-0.02em] text-center mb-12"
          >
            Compare plans
          </motion.h2>

          <div className="overflow-x-auto">
            <table className="w-full min-w-[600px]">
              <thead>
                <tr className="border-b border-white/10">
                  <th className="text-left py-4 px-4 text-[15px] font-semibold text-white">Feature</th>
                  <th className="text-center py-4 px-4 text-[15px] font-semibold text-white">Free</th>
                  <th className="text-center py-4 px-4 text-[15px] font-semibold text-emerald-400">Premium</th>
                  <th className="text-center py-4 px-4 text-[15px] font-semibold text-white">Premium Plus</th>
                  <th className="text-center py-4 px-4 text-[15px] font-semibold text-white">Lifetime</th>
                </tr>
              </thead>
              <tbody>
                {comparisonFeatures.map((row, index) => (
                  <tr key={index} className="border-b border-white/5">
                    <td className="py-4 px-4 text-[14px] text-white">{row.feature}</td>
                    <td className="py-4 px-4 text-center text-[14px] text-[#86868b]">
                      {row.free === '-' ? (
                        <svg className="w-4 h-4 mx-auto text-white/20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      ) : row.free === 'Yes' ? (
                        <svg className="w-4 h-4 mx-auto text-emerald-400" fill="currentColor" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                        </svg>
                      ) : (
                        row.free
                      )}
                    </td>
                    <td className="py-4 px-4 text-center text-[14px] text-white bg-emerald-500/5">
                      {row.premium === '-' ? (
                        <svg className="w-4 h-4 mx-auto text-white/20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      ) : row.premium === 'Yes' || row.premium === 'No' ? (
                        row.premium === 'Yes' ? (
                          <svg className="w-4 h-4 mx-auto text-emerald-400" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                          </svg>
                        ) : (
                          <svg className="w-4 h-4 mx-auto text-emerald-400" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                          </svg>
                        )
                      ) : (
                        row.premium
                      )}
                    </td>
                    <td className="py-4 px-4 text-center text-[14px] text-[#86868b]">
                      {row.premiumPlus === '-' ? (
                        <svg className="w-4 h-4 mx-auto text-white/20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      ) : row.premiumPlus === 'Yes' || row.premiumPlus === 'No' ? (
                        row.premiumPlus === 'Yes' ? (
                          <svg className="w-4 h-4 mx-auto text-emerald-400" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                          </svg>
                        ) : (
                          <svg className="w-4 h-4 mx-auto text-emerald-400" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                          </svg>
                        )
                      ) : (
                        row.premiumPlus
                      )}
                    </td>
                    <td className="py-4 px-4 text-center text-[14px] text-[#86868b]">
                      {row.lifetime === '-' ? (
                        <svg className="w-4 h-4 mx-auto text-white/20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      ) : row.lifetime === 'Yes' || row.lifetime === 'No' ? (
                        row.lifetime === 'Yes' ? (
                          <svg className="w-4 h-4 mx-auto text-emerald-400" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                          </svg>
                        ) : (
                          <svg className="w-4 h-4 mx-auto text-emerald-400" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                          </svg>
                        )
                      ) : (
                        row.lifetime
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      {/* Why It Costs This Much Section */}
      <section className="px-6 py-20">
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
              { icon: '🤖', title: 'AI Infrastructure', desc: 'GPT-powered workout generation, nutrition analysis, and real-time coaching' },
              { icon: '☁️', title: 'Cloud Servers', desc: 'Fast, reliable servers running 24/7 to sync your data and workouts' },
              { icon: '📱', title: 'App Development', desc: 'Continuous updates, bug fixes, and new features based on your feedback' },
              { icon: '💪', title: 'Exercise Library', desc: '1700+ exercises with videos, instructions, and AI-powered alternatives' },
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
            Competitors charge $15-20/month. We deliver premium AI coaching at 60% less.
          </motion.p>
        </div>
      </section>

      {/* FAQs */}
      <section className="px-6 py-20 bg-[#0a0a0a]">
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
